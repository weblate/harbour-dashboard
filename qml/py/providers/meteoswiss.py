#
# This file is part of Swiss Meteo.
# SPDX-FileCopyrightText: 2022 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#

import sqlite3
import urllib.request
import shutil
import gzip
from pathlib import Path

from .provider_base import Capability
from .provider_base import Provider as ProviderBase


class Provider(ProviderBase):
    name = 'MeteoSwiss'
    handle = 'mch'
    capabilities = Capability.ALL

    # FIXME Check if requests are allowed if we use our own user agent string.
    #       Requests with an empty user agent string are always blocked.
    # UA = 'something something meteo for SailfishOS (v2.0.0) - https://sources...'
    UA = 'MeteoSwissApp-2.16-Android'

    URL_DB = 'https://s3-eu-central-1.amazonaws.com/app-prod-static-fra.meteoswiss-app.ch/v1/db.sqlite'
    URL_STRINGS = 'https://www.meteoschweiz.admin.ch/etc.clientlibs/internet/clientlibs/meteoswiss/clientlibs/lang/{lang}.min.js'
    URL_ICONS = 'https://www.meteoschweiz.admin.ch/etc.clientlibs/internet/clientlibs/meteoswiss/resources/assets/images/icons/meteo/weather-symbols/{num}.svg'
    URL_FORECAST = 'https://app-prod-ws.meteoswiss-app.ch/v1/plzDetail?plz={ident}'

    SUPPORTED_DATA_DB_VERSIONS = ['139']

    def __init__(self, signal_callback, log_callback):
        super().__init__(signal_callback, log_callback)

        self._setup()
        self._signal_send('meteo.store-cache', 'data...')

    def _setup(self):
        self._data_db = self.data_path / 'mch.db'
        self._data_db_temp = self.data_path / 'mch.db.temp'

        if not self._data_db.exists():
            # download locations database if it does not exists

            # FIXME use requests
            # FIXME send user agent!
            # FIXME send accept language!

            self._signal_send('warning.providers.local-data.database-download-started', self._data_db)
            with urllib.request.urlopen(self.URL_DB) as response:
                with open(str(self._data_db_temp), 'wb') as compressed_file:
                    shutil.copyfileobj(response, compressed_file)

                with open(str(self._data_db_temp), 'rb') as compressed_file:
                    with gzip.GzipFile(fileobj=compressed_file, mode='rb') as uncompressed_data:
                        with open(str(self._data_db), 'wb') as uncompressed_file:
                            shutil.copyfileobj(uncompressed_data, uncompressed_file)

        # always remove temporary database used for decompression
        Path(self._data_db_temp).unlink(missing_ok=True)

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
