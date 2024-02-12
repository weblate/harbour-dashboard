#
# This file is part of Forecasts for SailfishOS.
# SPDX-FileCopyrightText: 2022-2024 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#

from typing import Dict, List, Any, Tuple
from pathlib import Path
import json

from dashboard import provider
from dashboard.util import log
from dashboard.util import signal_send
from dashboard.util import DatabaseBase


# - falls Code von Captain's Log verwendet wird -> dokumentieren
# x verschiedene Provider unterstützen, aber erstmal nur MeteoSchweiz
# x als erstes die Ort-Datenkbank herunterladen: https://s3-eu-central-1.amazonaws.com/app-prod-static-fra.meteoswiss-app.ch/v1/db.sqlite
# x Datenbank für Orte anlegen
# x Ordner für Cache anlegen
# x Datenbank für Wetter-Cache anlegen
# - mit einem Image-Provider (s. pyotherside) Wetter-Icons entweder aus dem Cache laden oder fehlende herunterladen:
#       https://www.meteoschweiz.admin.ch/etc.clientlibs/internet/clientlibs/meteoswiss/resources/assets/images/icons/meteo/weather-symbols/42.svg
# - Daten herunterladen: https://app-prod-ws.meteoswiss-app.ch/v1/plzDetail?plz= id
#       ('id' ist die ID eines Ortes aus der Datenbank; eine Anfrage pro Ort)
# - immer Header nicht vergessen:
#       - Accept-Language = de, fr, it, en   <-- abhängig von App-Sprache, Fallback ist Englisch
#       - User-Agent = MeteoSwissApp-2.3.3-Android  --> 2.16-Android

# - Übersetzungen laden: https://www.meteoschweiz.admin.ch/etc.clientlibs/internet/clientlibs/meteoswiss/clientlibs/lang/de.min.js <-- de, fr, it, en
#   -> vorher? -> in Kataloge integrieren?

_KNOWN_TILE_SIZES = {
    'small': 0,
    'medium': 1,
    'large': 2,
}

METEO = None
INITIALIZED = False


class Meteo:
    class DataDb(DatabaseBase):
        """
        Data database.

        This database provides a key-value storage for all tiles. Each tile can
        only access and change its own data.
        """
        HANDLE = 'main_data'

        def _setup(self):
            pass

        def _upgrade_schema(self, from_version):
            if from_version == '0':
                self.cur.execute("""
                    CREATE TABLE IF NOT EXISTS keyvalue (
                        tile_id INTEGER NOT NULL,
                        key TEXT NOT NULL,
                        value TEXT NOT NULL
                    );""")
                return '1'
            elif from_version == '1':
                raise self.UpToDate

            raise self.InvalidVersion

    class ConfigDb(DatabaseBase):
        """
        Configuration database.

        The config database contains all user-generated, provider-independent
        configuration. Configuration that is only relevant for certain providers
        must be handled by the provider implementation. Other data has to be
        stored in the cache database or the data database.
        """
        HANDLE = 'main_config'

        def _setup(self):
            pass

        def _upgrade_schema(self, from_version):
            if from_version == '0':
                # Active data view tiles:
                # - tile_id: unique identifier
                # - sequence: sequence number of the tile (0, 1, 2, 3...)
                #       Tiles will be shown in this order.
                # - size: size of the tile
                #       Must be one of 0=small, 1=medium, 2=large, as defined in
                #       _KNOWN_TILE_SIZES. There are only 3 sizes of tiles but this
                #       could change in the future.
                # - tile_type: string identifier of the data type
                #       The tile type defines which tile implementation will be loaded.
                #       Tile implementations must handle missing capabilities / missing
                #       data. For example, some providers may not provide precipitation
                #       forecasts, but they are still grouped in the "weather" category.
                # - settings_json: string defining tile settings
                #       Settings are stored as an opaque JSON object. They are not
                #       validated by the backed. Settings are an implementation detail
                #       of the tile.
                self.cur.execute("""
                    CREATE TABLE IF NOT EXISTS tiles (
                        tile_id INTEGER NOT NULL PRIMARY KEY,
                        sequence INTEGER NOT NULL UNIQUE,
                        size INTEGER NOT NULL,
                        tile_type TEXT NOT NULL,
                        settings_json TEXT
                    );""")
                return '1'
            elif from_version == '1':
                raise self.UpToDate

            raise self.InvalidVersion

    def __init__(self, data_path: str, cache_path: str, config_path: str):
        self.ready = False
        self._data_path = Path(data_path)
        self._cache_path = Path(cache_path)
        self._config_path = Path(config_path)

        # TODO test if this actually works - it probably makes it impossible to
        #      complete any transaction because we always re-open the database
        #
        # Set this to True while working with QmlLive.
        # The sqlite driver does not like multithreading and databases
        # cannot be used when they are created in a different thread.
        self.debug_reinit_db = False

        for k, v in {'data': self._data_path, 'cache': self._cache_path, 'config': self._config_path}.items():
            try:
                log(f"preparing local {k} path in '{v}'")
                v.mkdir(parents=True, exist_ok=True)
            except (FileExistsError, PermissionError) as e:
                signal_send('fatal.local-data.inaccessible', k, str(v), str(e))
                return

            # set base paths for all provider classes derived from Provider
            setattr(provider.ProviderBase, f'{k}_dir', v)

        # set base callbacks for all provider classes
        provider.ProviderBase.signal_callback = signal_send
        provider.ProviderBase.log_callback = log

        # TODO catch FileBroken exceptions
        self._config_db = self.ConfigDb(self._config_path, signal_send, log)
        self._data_db = self.DataDb(self._data_path, signal_send, log)

        self.ready = True

    @property
    def config_db(self):
        if self.debug_reinit_db:
            self._config_db = self.ConfigDb(self._config_path, signal_send, log)

        return self._config_db

    @property
    def data_db(self):
        if self.debug_reinit_db:
            self._data_db = self.DataDb(self._data_path, signal_send, log)

        return self._data_db


def _check_init() -> bool:
    """
    Check whether the API has been initialized.

    Returns True if everything is fine. If the API has *not* been initialized,
    a signal will be sent and the function returns False. In that case, API
    functions should return safe, empty data.
    """

    global INITIALIZED
    global METEO

    if not INITIALIZED or not METEO.ready:
        signal_send('bug.main.not-initialized')  # TODO add more info for debugging
        return False

    return True


# ------------------------------------------------------------------------------
# Public API:
#
# Public API is not encapsulated in the Meteo class because pyotherside can only
# be used with simple stand-alone functions.
#
# All functions are *only* safe to use after initialize(...) has been called.

def initialize(data_path, cache_path, config_path):
    global METEO
    global INITIALIZED

    METEO = Meteo(data_path, cache_path, config_path)

    if METEO.ready:
        INITIALIZED = True
        return True

    return False


def run_database_maintenance(caller: str) -> None:
    """
    Run regular database maintenance.

    Cleans caches and vacuums all databases. All providers will be requested
    to follow this order but they must implement the process individually.
    """
    if not _check_init():
        signal_send('info.main.database-maintenance.finished', caller)
        return

    signal_send('info.main.database-maintenance.started', caller)

    for kind in ["data", "cache", "config"]:
        db = getattr(METEO, f"{kind}_db", None)

        if db:
            signal_send('info.main.database-maintenance.status', caller, 'vacuum', "main-" + kind)
            db.con.execute("VACUUM")

    # TODO drop stale cache entries
    #   signal_send('info.main.database-maintenance.status', caller, 'clean-cache', 'main')

    # TODO vacuum all provider databases

    signal_send('info.main.database-maintenance.finished', caller)


def get_tiles() -> List[Tuple[str, Dict[str, Any]]]:
    """
    Get tiles and settings for the main screen.

    Returns a list of tiles. Each tile is a tuple of (tile_type, settings). Settings
    are specific to each tile type and are part of the tile implementation.
    """
    if not _check_init():
        return []

    signal_send('info.main.load-tiles.started')

    METEO.config_db.cur.execute("""SELECT * FROM tiles ORDER BY sequence ASC; """)
    rows = METEO.config_db.cur.fetchall()
    model = []

    for row in rows:
        size = row['size']
        tile_type = row['tile_type']
        tile_id = row['tile_id']
        settings_json = row['settings_json']
        settings_base = {'tile_id': tile_id, 'tile_type': tile_type, 'size': size}

        entry = {
            'tile_id': tile_id,
            'sequence': row['sequence'],
            'size': '--- set below ---',
            'tile_type': tile_type,
            'settings': {
                **settings_base,
                **json.loads(settings_json),  # TODO sanity checks
            },
        }

        if size in _KNOWN_TILE_SIZES.values():
            size = [k for k, v in _KNOWN_TILE_SIZES.items() if v == size][0]
            entry['size'] = size
        else:
            entry['size'] = 'small'
            signal_send('warning.main.load-tiles.unknown-size', size, tile_type, tile_id)

        # TODO DEBUG load tiles async here vvv
        signal_send('info.main.add-tile.finished', entry['tile_type'],
                    entry['size'], entry['settings'],
                    entry['tile_id'], entry['sequence'])
        # TODO DEBUG this is to load tiles async ^^^

        model.append(entry)

    signal_send('info.main.load-tiles.finished')

    # return model
    return []


def remove_tile(tile_id: int) -> None:
    """
    Delete a tile from the database.
    """
    if not _check_init() or tile_id < 0:
        return

    signal_send('info.main.remove-tile.started', tile_id)

    METEO.config_db.con.execute("""
        DELETE FROM tiles WHERE tile_id = ?;
    """, (tile_id, ))

    METEO.config_db.con.commit()
    signal_send('info.main.remove-tile.finished', tile_id)


def add_tile(tile_type: str, size: str, settings: dict) -> None:
    """
    Save a new tile for the main screen.

    Takes the tile's type, its size, and its settings. Settings are specific
    to each tile type and are part of their implementation.

    The size must be one of the keys defined in _KNOWN_TILE_SIZES.
    """
    if not _check_init():
        return

    signal_send('info.main.add-tile.started', tile_type, size, settings)

    if size not in _KNOWN_TILE_SIZES.keys():
        signal_send('warning.main.add-tile.unknown-tile-size', tile_type, size, settings)
        signal_send('warning.main.add-tile.failed')
        METEO.config_db.con.rollback()
        return

    tile_id = METEO.config_db.con.execute("""
        SELECT tile_id FROM tiles ORDER BY tile_id DESC LIMIT 1;
    """).fetchone()
    tile_id = int(tile_id['tile_id']) + 1 if tile_id else 0

    sequence = METEO.config_db.con.execute("""
        SELECT sequence FROM tiles ORDER BY sequence DESC LIMIT 1;
    """).fetchone()
    sequence = int(sequence['sequence']) + 1 if sequence else 0

    # the settings dict must always contain the tile ID
    settings['tile_id'] = tile_id

    METEO.config_db.con.execute("""
        INSERT INTO tiles (tile_id, sequence, size, tile_type, settings_json)
        VALUES (?, ?, ?, ?, ?);
    """, (tile_id, sequence, _KNOWN_TILE_SIZES[size], tile_type, json.dumps(settings)))

    METEO.config_db.con.commit()

    # NOTE: the 'sequence' value is not an index and there may be gaps in the counting
    signal_send('info.main.add-tile.finished', tile_type, size, settings, tile_id, sequence)


def resize_tile(tile_id: int, size: str) -> None:
    """
    Save a new size for a tile.

    Sizes must be strings defined in _KNOWN_TILE_SIZES.
    """
    if not _check_init() or tile_id < 0:
        return

    signal_send('info.main.resize-tile.started', tile_id, size)

    if size not in _KNOWN_TILE_SIZES.keys():
        signal_send('warning.main.resize-tile.unknown-tile-size', tile_id, size)
        signal_send('warning.main.resize-tile.failed')
        METEO.config_db.con.rollback()
        return

    METEO.config_db.con.execute("""
        UPDATE tiles SET size = ? WHERE tile_id = ?;
    """, (_KNOWN_TILE_SIZES[size], tile_id))

    METEO.config_db.con.commit()
    signal_send('info.main.resize-tile.finished', tile_id, size)


def update_tile(tile_id: int, settings: dict) -> None:
    """
    Update a tile's implementation-specific settings.

    Use the move_tile(...) and resize_tile(...) functions to update
    general settings.
    """
    if not _check_init() or tile_id < 0:
        return

    signal_send('info.main.update-tile.started', tile_id, settings)

    METEO.config_db.con.execute("""
        UPDATE tiles SET settings_json = ? WHERE tile_id = ?;
    """, (json.dumps(settings), tile_id))
    METEO.config_db.con.commit()

    signal_send('info.main.update-tile.finished', tile_id, settings)


def move_tile(tile_id: int, from_index: int, to_index: int) -> None:
    """
    Update tile sequence.

    Both indices must be >= 0.
    """
    if not _check_init() or tile_id < 0 or from_index < 0 or to_index < 0:
        return

    signal_send('info.main.move-tile.started', tile_id, from_index, to_index)

    METEO.config_db.cur.execute("""SELECT tile_id FROM tiles ORDER BY sequence ASC; """)
    rows = METEO.config_db.cur.fetchall()
    old_sequence = []

    for row in rows:
        old_sequence.append(row['tile_id'])

    old_count = len(old_sequence)

    if tile_id not in old_sequence:
        signal_send('warning.main.move-tile.tile-not-found', tile_id, from_index, to_index)
        signal_send('warning.main.move-tile.failed')
        METEO.config_db.con.rollback()
        return

    if from_index > old_count or to_index > old_count:
        log(f"indices are out of range: {from_index}->{to_index} > {old_count}")
        to_index = old_count
        from_index = old_sequence.index(tile_id)
    elif old_sequence[from_index] != tile_id:
        log(f"tile id {tile_id} not at expected position {from_index}")
        from_index = old_sequence.index(tile_id)

    if to_index < from_index:
        new_sequence = old_sequence[:to_index] + [tile_id] + old_sequence[to_index:from_index] + old_sequence[from_index + 1:]
    elif from_index < to_index:
        new_sequence = old_sequence[:from_index] + old_sequence[from_index + 1:to_index] + [tile_id] + old_sequence[to_index:]
    else:
        new_sequence = old_sequence  # nothing to do

    # We have to update each row twice to avoid hitting the UNIQUE constraint
    # on the sequence column while moving.

    for i, tile in enumerate(old_sequence):
        METEO.config_db.con.execute("""
            UPDATE tiles SET sequence = ? WHERE tile_id = ?;
        """, (i + old_count + 1, tile))

        signal_send('MOVE', tile, i, i + old_count + 1)

    for i, tile in enumerate(new_sequence):
        METEO.config_db.con.execute("""
            UPDATE tiles SET sequence = ? WHERE tile_id = ?;
        """, (i, tile))

        signal_send('MOVE-2', tile, i)

    METEO.config_db.con.commit()
    signal_send('info.main.move-tile.finished', tile_id, from_index, to_index)


def get_tile_data(tile_id: int, key: str) -> str:
    """
    Get data for a tile from its key-value store.
    """
    if not _check_init() or tile_id < 0:
        return

    signal_send('info.main.tile-data.get.started', tile_id, key)

    row = METEO.data_db.con.execute("""
        SELECT value FROM keyvalue WHERE tile_id = ?, key = ? LIMIT 1;
    """, (tile_id, key)).fetchone()

    signal_send('info.main.tile-data.get.finished', tile_id, key)
    return row['value']


def set_tile_data(tile_id: int, key: str, data: str) -> None:
    """
    Get data for a tile from its key-value store.
    """
    if not _check_init() or tile_id < 0:
        return

    signal_send('info.main.tile-data.set.started', tile_id, key, data)

    if data is None:
        METEO.data_db.con.execute("""
            DELETE FROM keyvalue WHERE tile_id = ?, key = ?;
        """, (tile_id, key))
    else:
        METEO.data_db.con.execute("""
            INSERT OR REPLACE INTO keyvalue(tile_id, key, value) VALUES (?, ?, ?);
        """, (tile_id, key, str(data)))

    METEO.data_db.con.commit()

    signal_send('info.main.tile-data.set.finished', tile_id, key, data)


def get_available_tiles() -> List[str]:
    """
    Get a list of available tiles.

    The returned list contains the names of each tile directory. In the future,
    this could be expanded to support user-provided tiles.
    """
    raise NotImplementedError


if __name__ == '__main__':
    log('running standalone')

    # TODO remove test lines
    initialize('test-data/data', 'test-data/cache', 'test-data/config')

else:
    log('running as library')
    import pyotherside

    def _signal_send_proxy(event, *args):
        log(f'[{event}]', *args, scope='signal')
        pyotherside.send(event, *args)

    # overwrite the global signal handler
    signal_send = _signal_send_proxy
