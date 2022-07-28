#
# This file is part of Swiss Meteo.
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




_PROVIDERS_REGISTRY = [
    'meteoswiss',
    'yrno',
    'dwd',
]

METEO = None
INITIALIZED = False


class Meteo:
    class DataDb(DatabaseBase):
        def _setup(self):
            pass  # no special setup needed

        def _upgrade_schema(self, from_version):
            if from_version == '0':
                # setup data tables
                self.cur.execute("""
                    CREATE TABLE IF NOT EXISTS active_locations(
                        location_id TEXT NOT NULL PRIMARY KEY,
                        name TEXT NOT NULL,
                        zip INTEGER NOT NULL,
                        regionId TEXT NOT NULL,
                        region TEXT NOT NULL,
                        latitude REAL NOT NULL,
                        longitude REAL NOT NULL,
                        altitude INTEGER NOT NULL
                    );""")
                return '1'
            elif from_version == '1':
                raise self.UpToDate

            raise self.InvalidVersion

    class CacheDb(DatabaseBase):
        def _setup(self):
            pass  # no special setup needed

        def _upgrade_schema(self, from_version):
            if from_version == '0':
                self.cur.execute("""
                    CREATE TABLE IF NOT EXISTS data(
                        timestamp INTEGER NOT NULL,
                        location_id INTEGER NOT NULL,
                        data_json TEXT NOT NULL,
                        day_count INTEGER NOT NULL,
                        day_dates TEXT NOT NULL,
                        PRIMARY KEY(timestamp, location_id)
                    );""")
                self.cur.execute("""
                    CREATE TABLE IF NOT EXISTS overview(
                        datestring STRING NOT NULL,
                        location_id INTEGER NOT NULL,
                        symbol INTEGER NOT NULL,
                        precipitation INTEGER NOT NULL,
                        temp_max INTEGER NOT NULL,
                        temp_min INTEGER NOT NULL,
                        age INTEGER NOT NULL,
                        PRIMARY KEY(datestring, location_id)
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
