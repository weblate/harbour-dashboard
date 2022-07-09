#
# This file is part of Swiss Meteo.
# SPDX-FileCopyrightText: 2022 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#

import sqlite3
import requests
import locale
import json
# from pathlib import Path

from .provider_base import Capability
from .provider_base import Provider as ProviderBase


class Provider(ProviderBase):
    name = 'MeteoSwiss'
    handle = 'mch'
    capabilities = Capability.ALL

    URL_DB = 'https://s3-eu-central-1.amazonaws.com/app-prod-static-fra.meteoswiss-app.ch/v1/db.sqlite'
    URL_STRINGS = 'https://www.meteoschweiz.admin.ch/etc.clientlibs/internet/clientlibs/meteoswiss/clientlibs/lang/{lang}.min.js'
    URL_ICONS = 'https://www.meteoschweiz.admin.ch/etc.clientlibs/internet/clientlibs/meteoswiss/resources/assets/images/icons/meteo/weather-symbols/{num}.svg'
    URL_FORECAST = 'https://app-prod-ws.meteoswiss-app.ch/v1/plzDetail?plz={ident}'

    HEADERS = {
        # FIXME Check if requests are allowed if we use our own user agent string.
        #       Requests with an empty user agent string are always blocked.
        # or: 'something something meteo for SailfishOS (v2.0.0) - https://sources...'
        'User-Agent': 'MeteoSwissApp-2.16-Android',
        'Accept-Language': locale.getlocale()[0].split('_')[0] if locale.getlocale()[0] is not None else 'en'
    }

    SUPPORTED_DATA_DB_VERSIONS = ['139']

    def __init__(self, signal_callback, log_callback):
        super().__init__(signal_callback, log_callback)

        self._setup()

    def refresh(self, ident: str, force: bool) -> None:
        self._pre_refresh(ident, force)
        self._signal_send('info.refresh.started', ident, force)

        # TODO verify ident in db
        new_data = {}

        try:
            r = requests.get(self.URL_FORECAST.format(ident=ident), headers=self.HEADERS, timeout=1)
            print(r.headers)
            print(r.status_code)
            r.raise_for_status()
            new_data = r.json()

            with open(self.data_path / 'forecast.json', 'w') as fd:
                fd.write(json.dumps(new_data, indent=2))

        except requests.exceptions.RequestException as e:
            self._signal_send('warning.refresh.download-failed', self._data_db, r.status_code, r.headers, e)
            return
        except Exception as e:
            self._signal_send('warning.refresh.download-failed', self._data_db, e)
            return

        self._signal_send('meteo.store-cache', ident, new_data)
        self._signal_send('info.refresh.finished', ident, new_data)

    def _setup(self):
        self._data_db = self.data_path / 'mch.db'

        if not self._data_db.exists():
            # download locations database if it does not exists
            self._signal_send('warning.providers.local-data.database-download-started', self._data_db)

            try:
                r = requests.get(self.URL_DB, headers=self.HEADERS, timeout=1)
                print(r.headers)
                print(r.status_code)


                r.raise_for_status()

                with open(self._data_db, 'wb') as fd:
                    for chunk in r.iter_content(chunk_size=128):
                        fd.write(chunk)

            # except (requests.ConnectionError, requests.ConnectTimeout):
            except requests.exceptions.RequestException as e:
                self._signal_send('warning.providers.local-data.database-download-failed', self._data_db, r.status_code, r.headers, e)
                return
            except Exception as e:
                self._signal_send('warning.providers.local-data.database-download-failed', self._data_db, e)
                return

            self._signal_send('warning.providers.local-data.database-download-finished', self._data_db)

        if self._data_db.exists() and not self._data_db.is_file():
            self._signal_send('warning.providers.local-data.database-broken', self._data_db)
            return
        elif not self._data_db.exists():
            self._signal_send('warning.providers.local-data.database-download-failed', self._data_db)
            return
        else:
            self._signal_send('info.providers.local-data.database-ready', self._data_db)

        self._dcon = sqlite3.connect(self._data_db)
        self._dcon.row_factory = sqlite3.Row
        self._dcur = self._dcon.cursor()

        try:
            row = self._dcur.execute('SELECT version FROM metadata;').fetchone()
            version = row['version'] if row and row['version'] else 'none'

            if version not in self.SUPPORTED_DATA_DB_VERSIONS:
                raise RuntimeError()
        except (sqlite3.OperationalError, RuntimeError):
            self._signal_send('warning.providers.local-data.invalid', self._data_db, version)
            return

        self.ready = True
