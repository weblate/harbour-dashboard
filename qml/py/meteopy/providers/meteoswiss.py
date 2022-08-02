#
# This file is part of Forecasts for SailfishOS.
# SPDX-FileCopyrightText: 2022 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#

import requests
import locale
import json

from .provider_base import Capability
from .provider_base import Provider as ProviderBase

from ..util import DatabaseBase


HEADERS = {
    # FIXME Check if requests are allowed if we use our own user agent string.
    #       Requests with an empty user agent string are always blocked.
    # or: 'something something meteo for SailfishOS (v2.0.0) - https://sources...'
    'User-Agent': 'MeteoSwissApp-2.16-Android',
    'Accept-Language': locale.getlocale()[0].split('_')[0] if locale.getlocale()[0] is not None else 'en'
}


class _MeteoDb(DatabaseBase):
    URL_DB = 'https://s3-eu-central-1.amazonaws.com/app-prod-static-fra.meteoswiss-app.ch/v1/db.sqlite'
    SUPPORTED_DATA_DB_VERSIONS = ['139']

    def _setup(self):
        if not self._db_path.exists():
            # download locations database if it does not exists
            self._signal_send('info.providers.local-data.database-download-started', self._db_path)

            try:
                r = requests.get(self.URL_DB, headers=HEADERS, timeout=1)
                print(r.headers)
                print(r.status_code)

                # TODO: analyse reply headers
                r.raise_for_status()

                with open(self._db_path, 'wb') as fd:
                    for chunk in r.iter_content(chunk_size=128):
                        fd.write(chunk)

            # except (requests.ConnectionError, requests.ConnectTimeout):
            except requests.exceptions.RequestException as e:
                self._signal_send('warning.providers.local-data.database-download-failed', self._db_path, r.status_code, r.headers, e)
                return
            except Exception as e:
                self._signal_send('warning.providers.local-data.database-download-failed', self._db_path, e)
                return

            self._signal_send('info.providers.local-data.database-download-finished', self._db_path)

        if self._db_path.exists() and not self._db_path.is_file():
            self._signal_send('warning.providers.local-data.database-broken', self._db_path)
            return
        elif not self._db_path.exists():
            self._signal_send('warning.providers.local-data.database-download-failed', self._db_path)
            return
        else:
            self._signal_send('info.providers.local-data.database-ready', self._db_path)

    def _upgrade_schema(self, from_version):
        if from_version in self.SUPPORTED_DATA_DB_VERSIONS:
            raise self.UpToDate

        raise self.InvalidVersion


class _CacheDb(DatabaseBase):
    def _setup(self):
        pass

    def _upgrade_schema(self, from_version):
        if from_version == '0':
            # setup data tables...
            return '1'  # next version number
        elif from_version == '1':
            raise self.UpToDate

        raise self.InvalidVersion


class Provider(ProviderBase):
    name = 'MeteoSwiss'
    handle = 'mch'
    capabilities = Capability.ALL

    URL_STRINGS = 'https://www.meteoschweiz.admin.ch/etc.clientlibs/internet/clientlibs/meteoswiss/clientlibs/lang/{lang}.min.js'
    URL_ICONS = 'https://www.meteoschweiz.admin.ch/etc.clientlibs/internet/clientlibs/meteoswiss/resources/assets/images/icons/meteo/weather-symbols/{num}.svg'
    URL_FORECAST = 'https://app-prod-ws.meteoswiss-app.ch/v1/plzDetail?plz={ident}'

    def __init__(self, signal_callback, log_callback):
        super().__init__(signal_callback, log_callback)

        self._setup()

    def refresh(self, ident: str, force: bool) -> None:
        self._pre_refresh(ident, force)
        self._signal_send('info.refresh.started', ident, force)

        # TODO verify ident in db
        new_data = {}

        try:
            r = requests.get(self.URL_FORECAST.format(ident=ident), headers=HEADERS, timeout=1)
            print(r.headers)
            print(r.status_code)
            r.raise_for_status()
            new_data = r.json()

            with open(self.data_path / 'forecast.json', 'w') as fd:
                fd.write(json.dumps(new_data, indent=2))

            # TODO analyse reply headers

        except requests.exceptions.RequestException as e:
            self._signal_send('warning.refresh.download-failed', self._data_db, r.status_code, r.headers, e)
            return
        except Exception as e:
            self._signal_send('warning.refresh.download-failed', self._data_db, e)
            return

        self._signal_send('meteo.store-cache', ident, new_data)
        self._signal_send('info.refresh.finished', ident, new_data)

    def _setup(self):
        # TODO:
        # - store database in self.cache_path (it's not user generated data)
        # - add separate cache database for saving timestamps and icon
        #   description strings
        # - generalise database initialisation in ProviderBase

        try:
            self._meteo_db = _MeteoDb(self.cache_path, 'meteo', self._signal_send, self._log)
        except _MeteoDb.InvalidVersion as e:
            self._signal_send('warning.providers.local-data.invalid', e.path, e.version)
            return

        self._cache_db = _CacheDb(self.cache_path, 'cache', self._signal_send, self._log)

        self.ready = True
