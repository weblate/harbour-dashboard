#
# This file is part of Forecasts for SailfishOS.
# SPDX-FileCopyrightText: 2022 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#

from typing import Dict
from pathlib import Path

from meteopy.providers import provider_base
import importlib

from meteopy.util import log
from meteopy.util import signal_send
from meteopy.util import DatabaseBase


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


_PROVIDERS_REGISTRY = [
    'meteoswiss',
    'yrno',
    'dwd',
]

METEO = None
INITIALIZED = False


class Meteo:
    class DataDb(DatabaseBase):
        """
        Data database.

        This database is intended to be used for storing user-generated data.
        User-generated configuration goes into the config database.
        """

        def _setup(self):
            pass

        def _upgrade_schema(self, from_version):
            if from_version == '0':
                raise self.UpToDate

            raise self.InvalidVersion

    class ConfigDb(DatabaseBase):
        """
        Configuration database.

        The config database contains all user-generated, provider-indepentend
        configuration. Configuration that is only relevant for certain providers
        must be handled by the provider implementation. Other data has to be
        stored in the cache database or the data database.
        """
        def _setup(self):
            pass

        def _upgrade_schema(self, from_version):
            if from_version == '0':
                # Active data view tiles:
                # - tile_id: unique identifier
                # - sequence: sequence number of the tile (0, 1, 2, 3...)
                #       Tiles will be shown in this order.
                # - tile_type: string identifier of the data type
                #       Must be one of:
                #       - weather
                #       - pollen
                #       - clock
                #
                #       The tile type defines which tile implementation will be loaded.
                #       Tile implementations must handle missing capabilities / missing
                #       data. For example, some providers may not provide precipitation
                #       forecasts, but they are still grouped in the "weather" category.
                self.cur.execute("""
                    CREATE TABLE IF NOT EXISTS mainscreen_tiles(
                        tile_id INTEGER NOT NULL PRIMARY KEY,
                        sequence INTEGER NOT NULL UNIQUE,
                        tile_type TEXT NOT NULL,
                    );""")

                # Weather forecast tile:
                # - tile_id: see above
                # - location_id: provider-dependent location identifier
                # - provider_id: provider token string
                #
                # Actual forecast data is stored in the cache database.
                #
                # TODO: decide how to best store additional location details.
                #       Locations have names and other related information that
                #       a) might have to be configurable by the user
                #       b) might change and should therefore be handled by the provider
                #
                #       In case of a), it would make sense to store details in the
                #       settings database (i.e. here). In case of b), it would be
                #       better to find a way to request these details from the provider.
                #
                #       Some details fields:
                #       - name TEXT NOT NULL,
                #       - zip INTEGER NOT NULL,
                #       - regionId TEXT NOT NULL,
                #       - region TEXT NOT NULL,
                #       - latitude REAL NOT NULL,
                #       - longitude REAL NOT NULL,
                #       - altitude INTEGER NOT NULL
                #
                #       The same problem applies to other location-bound forecasts. There
                #       also might be a lot of duplication if the user has tiles for different
                #       forecasts but for the same location.
                self.cur.execute("""
                    CREATE TABLE IF NOT EXISTS weather_forecast_details(
                        tile_id INTEGER NOT NULL PRIMARY KEY,
                        location_id TEXT NOT NULL,
                        provider_id TEXT NOT NULL
                    );""")

                # Pollen forecast tile:
                # cf. weather forecast documentation
                self.cur.execute("""
                    CREATE TABLE IF NOT EXISTS pollen_forecast_details(
                        tile_id INTEGER NOT NULL PRIMARY KEY,
                        location_id TEXT NOT NULL,
                        provider_id TEXT NOT NULL
                    );""")

                # World clock tile:
                # - tile_id: see above
                # - utcOffsetMinutes: difference to UTC for this clock
                #       Negative means west of UTC, positive means east of UTC.
                # - showLocalTime: (bool) whether this clock shows global time or local time
                #       If showLocalTime == 1, the value set in utcOffsetMinutes is ignored.
                # - label: user-defined name of this clock, could e.g. be a city or a timezone
                # - showNumbers: (bool) whether to show numbers on the clock face
                #       TODO: support translated clock faces. Currently, there is only one
                #             numbered clock face using arabic numbers. There should be
                #             translated versions using different scripts.
                self.cur.execute("""
                    CREATE TABLE IF NOT EXISTS worldclock_details(
                        tile_id INTEGER NOT NULL PRIMARY KEY,
                        utcOffsetMinutes INTEGER DEFAULT 0,
                        showLocalTime INTEGER DEFAULT 0,
                        label TEXT DEFAULT "",
                        showNumbers INTEGER DEFAULT 0
                    );""")
                return '1'
            elif from_version == '1':
                raise self.UpToDate

            raise self.InvalidVersion

    class CacheDb(DatabaseBase):
        """
        Cache database.

        The cache database stores all automatically accumulated data in a
        provider-independent form. Data that is only relevant for a certain provider
        must be stored by the provider.

        TODO: document how data can be stored here by providers using signals.
        """

        def _setup(self):
            pass  # no special setup needed

        def _upgrade_schema(self, from_version):
            if from_version == '0':
                # Detailed weather forecast data
                self.cur.execute("""
                    CREATE TABLE IF NOT EXISTS weather_forecast_data(
                        timestamp INTEGER NOT NULL,
                        location_id TEXT NOT NULL,
                        data_json TEXT NOT NULL,
                        day_count INTEGER NOT NULL,
                        day_dates TEXT NOT NULL,
                        PRIMARY KEY(timestamp, location_id)
                    );""")

                # Summarised weather forecast data
                self.cur.execute("""
                    CREATE TABLE IF NOT EXISTS weather_forecast_overview(
                        datestring STRING NOT NULL,
                        location_id TEXT NOT NULL,
                        symbol INTEGER NOT NULL,
                        precipitation INTEGER NOT NULL,
                        temp_max INTEGER NOT NULL,
                        temp_min INTEGER NOT NULL,
                        age INTEGER NOT NULL,
                        PRIMARY KEY(datestring, location_id)
                    );""")

                # Detailed pollen forecast data
                self.cur.execute("""
                    CREATE TABLE IF NOT EXISTS pollen_forecast_data(
                        timestamp INTEGER NOT NULL,
                        location_id TEXT NOT NULL,
                        data_json TEXT NOT NULL,
                        day_count INTEGER NOT NULL,
                        day_dates TEXT NOT NULL,
                        PRIMARY KEY(timestamp, location_id)
                    );""")
                return "1"
            elif from_version == '1':
                raise self.UpToDate

            raise self.InvalidVersion

    def __init__(self, data_path: str, cache_path: str, config_path: str):
        self.ready = False
        self._data_path = Path(data_path)
        self._cache_path = Path(cache_path)
        self._config_path = Path(config_path)
        self._providers: Dict[str, provider_base.Provider] = {}
        self._broken_providers: Dict[str, provider_base.Provider] = {}

        for k, v in {'data': self._data_path, 'cache': self._cache_path, 'config': self._config_path}.items():
            try:
                log(f"preparing local {k} path in '{v}'")
                v.mkdir(parents=True, exist_ok=True)
            except (FileExistsError, PermissionError) as e:
                signal_send(f'fatal.local-{k}.inaccessible', v, e)
                return

            # set base paths for all provider classes derived from Provider
            setattr(provider_base.Provider, f'{k}_dir', v)

        self._data_db = self.DataDb(self._data_path, 'meteo_data', signal_send, log)
        self._cache_db = self.CacheDb(self._cache_path, 'meteo_cache', signal_send, log)
        self._config_db = self.ConfigDb(self._config_path, 'meteo_config', signal_send, log)

        self._init_providers()
        self.ready = True

    def refresh(self, provider: str, ident: str, force: bool) -> None:
        if provider in self._broken_providers:
            signal_send('error.refresh.broken-provider', provider, ident, force)
            return
        elif provider not in self._providers:
            signal_send('error.refresh.unknown-provider', provider, ident, force)
            return

        self._providers[provider].refresh(ident, force)

    def _init_providers(self):
        for i in _PROVIDERS_REGISTRY:
            try:
                m = importlib.import_module('meteopy.providers.' + i)
                m = m.Provider(self._handle_provider_signal, log)

                if m.handle in self._providers:
                    raise Exception(f'Duplicate provider with handle {m.handle}')

                if not m.ready:
                    self._broken_providers[m.handle] = m
                    raise Exception(f'Provider {m.handle} failed to initialize')

                self._providers[m.handle] = m
            except Exception as e:
                signal_send('warning.providers.broken', f'{i}: {e}')

    def _handle_provider_signal(self, event, *args):
        if event == 'meteo.store-cache':
            log(f'[not implemented] storing cache from [{args[0]}]:', *args[1:], scope='meteo')
            # TODO implement
        else:
            signal_send(event, *args)

    def _backup_file(self, filepath):
        filepath = Path(filepath)

        if not filepath.exists():
            return

        turn = 0
        while True:
            try:
                filepath.rename(str(filepath) + '.bak' + (f'~{turn}~' if turn > 0 else ''))
                break
            except FileExistsError:
                turn += 1
            except PermissionError as e:
                signal_send('error.backup.failed', filepath, e)  # TODO handle this...?


def initialize(data_path, cache_path, config_path):
    global METEO
    global INITIALIZED

    METEO = Meteo(data_path, cache_path, config_path)

    if METEO.ready:
        INITIALIZED = True
        return True

    return False


def get_active_locations():
    return []


def get_providers():
    return []


def search_locations(provider, query):
    return []


def activate_location(ident):
    pass


def deactivate_location(ident):
    pass


def move_location(ident, direction):
    pass  # should be stored in dconf from QML


def refresh(location: str, force: bool) -> None:
    if not location:
        signal_send('bug.refresh.location.empty', location, force)
        return
    elif type(location) is not str:
        signal_send('bug.refresh.location.invalid-type', location, force)
        return
    elif '|' not in location:
        signal_send('bug.refresh.location.invalid-format', location, force)
        return

    provider = location.split('|')[0]
    ident = '|'.join(location.split('|')[1:])
    METEO.refresh(provider, ident, force)


if __name__ == '__main__':
    log('running standalone')

    # TODO remove test lines
    initialize('test-data/data', 'test-data/cache', 'test-data/config')
    # refresh('mch|400100', True)

else:
    log('running as library')
    import pyotherside

    def _signal_send_proxy(event, *args):
        log(f'[{event}]', *args, scope='signal')
        pyotherside.send(event, *args)

    # overwrite the global signal handler
    signal_send = _signal_send_proxy
