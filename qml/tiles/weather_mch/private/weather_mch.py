#
# This file is part of Forecasts for SailfishOS.
# SPDX-FileCopyrightText: 2022 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#

import requests
import locale
import re
# import json
import enum
# from dataclasses import dataclass

# from dashboard.provider import Capability
from dashboard.provider import ProviderBase
from dashboard.provider import do_execute_command
from dashboard.util import DatabaseBase
from dashboard.util import KeyValueBase


"""

API:
- website:
      - weather icons: https://www.meteoschweiz.admin.ch/static/resources/weather-symbols/X.svg
          as of 2024-02-13, there are 42 icons for day and night: X is {1..42} and {101..142}

          was: https://www.meteoschweiz.admin.ch/etc.clientlibs/internet/clientlibs/meteoswiss/resources/assets/images/icons/meteo/weather-symbols/{num}.svg

      - strings:
          as of 2024-02-13 no longer available here, must be extracted from the app
          was: https://www.meteoschweiz.admin.ch/etc.clientlibs/internet/clientlibs/meteoswiss/clientlibs/lang/{lang}.min.js

- App:
      APKs are available here: https://www.apkmirror.com/apk/bundesamt-fur-meteorologie-und-klimatologie/meteoswiss/meteoswiss-3-0-6-release/

      - v2.16 / 2.18.1:
          - UA: MeteoSwissApp-2.16-Android / MeteoSwissApp-2.18.1-Android
          - database: https://s3-eu-central-1.amazonaws.com/app-prod-static-fra.meteoswiss-app.ch/v1/db.sqlite

      - v3.0.6:
          - UA: MeteoSwissApp-3.0.6-Android
          - database: https://app-prod-static.meteoswiss-app.ch/v1/db.sqlite
          - strings:
               - extract the APK (zip)
               - extract resources using: jadx resources.arsc
               - locate resources/resources/res/values{,-de,-fr,-it}/strings.xml
               - extract weather symbol descriptions:

                      for i in "" de it fr; do
                          echo "{" > ${i:-en}.json
                          echo '    "app-version": "MeteoSwissApp-3.0.6-Android",' >> ${i:-en}.json
                          hxselect "resources > string[name^='wettersymboltexte']" -s '\n' < resources/resources/res/values${i:+-}$i/strings.xml |\
                              sed -Ee 's@<string name="wettersymboltexte_([0-9]+)">(.*)</string>@    "\1": "\2",@g' |\
                              sort -t'"' --key=2n >> ${i:-en}.json
                          echo "}" >> ${i:-en}.json
                          mv "${i:-en}.json" "symbols_${i:-en}.json"
                      done

               - remove the trailing comma in the last line
"""


MCH_LOCALES = ['de', 'it', 'fr', 'en']
SYSTEM_LOCALE = locale.getlocale()[0].split('_')[0] if locale.getlocale()[0] is not None else 'en'
LOCALE = SYSTEM_LOCALE if SYSTEM_LOCALE in MCH_LOCALES else 'en'

PLACE_TYPE_CITY_STRINGS = {
    # key "local_forecast_nearby_location_subtitle" in strings.xml
    'de': 'Ortschaft',
    'it': 'Località',
    'fr': 'Lieu',
    'en': 'Town',
}


HEADERS = {
    # FIXME Check if requests are allowed if we use our own user agent string.
    #       Requests with an empty user agent string are always blocked.
    # or: 'something something meteo for SailfishOS (v2.0.0) - https://sources...'
    'User-Agent': 'MeteoSwissApp-3.0.6-Android',
    'Accept-Language': LOCALE
}


class CacheSection(enum.IntEnum):
    GENERAL = 0
    METADATA = 1

    # tile-specific data is stored as CacheSection.TILES + tile_id
    TILES = 1000


class _CacheDb(KeyValueBase):
    HANDLE = 'cache'


class _MetadataDb(DatabaseBase):
    HANDLE = 'metadata'
    URL_DB = 'https://app-prod-static.meteoswiss-app.ch/v1/db.sqlite'
    SUPPORTED_DATA_DB_VERSIONS = ['165']

    CACHE: _CacheDb = None

    def _setup(self):
        if self.CACHE is None:
            raise ValueError('bug: cache must be defined before initializing the database')

        if not self._db_path.exists():
            # download locations database if it does not exists
            self._signal_send('info.providers.local-data.database-download-started', self._db_path)

            try:
                r = requests.get(self.URL_DB, headers=HEADERS, timeout=1)

                # >>> print(r.headers)
                # {
                #     "x-amz-id-2": "HOG3FIlYQVk1yInMV9HvvZzJcGgvkaK3PPGitN4faV1EsrP9zwZreO1Xmq7l/MCubTkdz5Nw2C4=",
                #     "x-amz-request-id": "4E4H2KWBGQ9B2W75",
                #     "Date": "Tue, 13 Feb 2024 14:28:21 GMT",
                #     "Last-Modified": "Fri, 15 Dec 2023 15:27:26 GMT",
                #     "ETag": "\"bd86233b3f95e7e2d121ff56fe2fb847\"",
                #     "x-amz-server-side-encryption": "AES256",
                #     "x-amz-meta-minimum-api-version": "32",
                #     "x-amz-meta-best-before": "Sat, 14 Dec 2024 15:27:25 GMT",
                #     "Content-Encoding": "gzip",
                #     "x-amz-meta-backoff": "21600",
                #     "Expires": "Fri, 15 Dec 2023 21:27:25 GMT",
                #     "x-amz-version-id": "hMKD0xgZ1mxqnu09GbLXrz5NsaqKGikZ",
                #     "x-amz-meta-next-refresh": "Fri, 15 Dec 2023 21:27:25 GMT",
                #     "Accept-Ranges": "bytes",
                #     "Content-Type": "application/x-sqlite3",
                #     "Server": "AmazonS3",
                #     "Content-Length": "267147"
                # }
                #
                # >>> print(r.status_code)
                # 200

                r.raise_for_status()

                with open(self._db_path, 'wb') as fd:
                    for chunk in r.iter_content(chunk_size=128):
                        fd.write(chunk)

                self.CACHE.set_value('downloaded', r.headers['Date'], section=CacheSection.METADATA)
                self.CACHE.set_value('last-modified', r.headers['Last-Modified'], section=CacheSection.METADATA)
                self.CACHE.set_value('best-before', r.headers['x-amz-meta-best-before'], section=CacheSection.METADATA)
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

    def get_search_suggestions(self, query: str):
        if re.match('^[0-9]+$', query):
            """
            SELECT plz_pk AS plz, name, altitude, ? AS type
            FROM plz
            JOIN plz_names ON plz_names.plz = plz.plz_pk
            WHERE plz_pk LIKE ?
            LIMIT 50;

            SELECT plz AS zip, kind, primary_name as name, GROUP_CONCAT(name, ', ') AS alt_name, altitude
            FROM (SELECT plz, name, primary_name, altitude, "Ort" AS kind FROM plz_names
            JOIN plz ON plz.plz_pk = plz_names.plz
            WHERE plz_pk LIKE "40%")
            GROUP BY plz

            SELECT plz AS zip, kind, primary_name as name, GROUP_CONCAT(name, ', ') AS alt_name, altitude
            FROM (
                SELECT plz, name, primary_name, altitude, ? AS kind FROM plz_names
                JOIN plz ON plz.plz_pk = plz_names.plz
                WHERE plz_pk LIKE ?
            )
            GROUP BY plz
            LIMIT 50;
            """
            self.cur.execute("""
                SELECT plz AS key, SUBSTR(plz, 0, 5) as zip, kind, primary_name as name, GROUP_CONCAT(name, ', ') AS alt_name, altitude, x, y
                FROM (
                    SELECT plz, name, primary_name, altitude, :kind AS kind, x, y FROM plz_names
                    JOIN plz ON plz.plz_pk = plz_names.plz
                    WHERE plz_pk LIKE :query
                )
                GROUP BY plz
                LIMIT 20;
            """, {'kind': PLACE_TYPE_CITY_STRINGS[LOCALE], 'query': f'{query}%'})
        else:
            """
            SELECT plz, name, altitude, ? as type
            FROM plz_names
            JOIN plz ON plz.plz_pk = plz_names.plz
            WHERE name LIKE ?
            LIMIT 50;

            SELECT plz_pk AS plz, alt_name, primary_name, altitude, ? AS type
            FROM (
                SELECT plz AS plz_pk, GROUP_CONCAT(name, ', ') AS alt_name
                FROM plz_names
                GROUP BY plz
            )
            JOIN plz USING(plz_pk)
            WHERE primary_name LIKE ?
            LIMIT 50;

            SELECT plz, GROUP_CONCAT(name, ', ') AS alt_name
            FROM (SELECT plz, name, altitude, "Ort" as type
            FROM plz_names
            JOIN plz ON plz.plz_pk = plz_names.plz
            WHERE name LIKE "Bas%"
            LIMIT 50)
            GROUP BY plz

            SELECT plz AS zip, kind, primary_name as name, GROUP_CONCAT(name, ', ') AS alt_name, altitude
            FROM (SELECT plz, name, primary_name, altitude, "Ort" AS kind FROM plz_names
            JOIN plz ON plz.plz_pk = plz_names.plz
            WHERE name LIKE "Del%" LIMIT 10)
            GROUP BY plz

            SELECT plz AS zip, kind, primary_name as name, GROUP_CONCAT(name, ', ') AS alt_name, altitude
            FROM (
                SELECT plz, name, primary_name, altitude, ? AS kind FROM plz_names
                JOIN plz ON plz.plz_pk = plz_names.plz
                WHERE name LIKE ?
            )
            GROUP BY plz
            LIMIT 50;


            SELECT poi_pk AS key, '' as zip, type_de as kind, primary_name as name, GROUP_CONCAT(name, ', ') AS alt_name, altitude
            FROM (
                SELECT poi_pk, name, primary_name, altitude, type_de FROM poi_names
                JOIN poi ON poi.poi_pk = poi_names.poi
                WHERE name LIKE "E%"
            )
            GROUP BY poi_pk
            LIMIT 50;

            SELECT plz AS key, SUBSTR(plz, 0, 5) as zip, kind, primary_name as name, GROUP_CONCAT(name, ', ') AS alt_name, altitude
            FROM (
                SELECT plz, name, primary_name, altitude, ? AS kind FROM plz_names
                JOIN plz ON plz.plz_pk = plz_names.plz
                WHERE name LIKE ?
            )
            GROUP BY plz
            LIMIT 50;
            """

            lang = f"type_{LOCALE}"

            if LOCALE not in ['de', 'it', 'fr', 'en']:
                lang = "type_en"

            self.cur.execute(f"""
                SELECT plz AS key, SUBSTR(plz, 0, 5) as zip, kind, primary_name as name, GROUP_CONCAT(name, ', ') AS alt_name, altitude, x, y
                FROM (
                    SELECT plz, name, primary_name, altitude, :kind AS kind, x, y FROM plz_names
                    JOIN plz ON plz.plz_pk = plz_names.plz
                    WHERE name LIKE :query
                )
                GROUP BY plz

                UNION

                SELECT poi_pk AS key, '' as zip, {lang} as kind, primary_name as name, GROUP_CONCAT(name, ', ') AS alt_name, altitude, x, y
                FROM (
                    SELECT poi_pk, name, primary_name, altitude, {lang}, x, y FROM poi_names
                    JOIN poi ON poi.poi_pk = poi_names.poi
                    WHERE name LIKE :query
                )
                GROUP BY poi_pk

                LIMIT 20;
            """, {'kind': PLACE_TYPE_CITY_STRINGS[LOCALE], 'query': f'{query}%'})

        rows = self.cur.fetchall()
        rows = [{n: x[n] for n in ['key', 'zip', 'kind', 'name', 'alt_name', 'altitude', 'x', 'y']} for x in rows]

        for i in rows:
            lat, lon = self._convert_coordinates(i['y'], i['x'])

            del i['y']
            del i['x']

            i['latitude'] = lat
            i['longitude'] = lon

        return rows

    def _convert_coordinates(self, northern, eastern):
        """
        Convert LV03 to international coordinates
        """

        y = (eastern - 600000) / 1000000
        x = (northern - 200000) / 1000000

        lam = 2.6779094
        lam += 4.728982 * y
        lam += 0.791484 * y * x
        lam += 0.1306 * y * x * x
        lam -= 0.0436 * y * y * y
        lam *= 100 / 36

        phi = 16.9023892
        phi += 3.238272 * x
        phi -= 0.270978 * y * y
        phi -= 0.002528 * x * x
        phi -= 0.0447 * y * y * x
        phi -= 0.0140 * x * x * x
        phi *= 100 / 36

        latitude = phi
        longitude = lam

        return (latitude, longitude)


class Provider(ProviderBase):
    NAME = 'MeteoSwiss'
    HANDLE = 'weather_mch'

    URL_STRINGS = 'https://www.meteoschweiz.admin.ch/etc.clientlibs/internet/clientlibs/meteoswiss/clientlibs/lang/{lang}.min.js'
    URL_ICONS = 'https://www.meteoschweiz.admin.ch/etc.clientlibs/internet/clientlibs/meteoswiss/resources/assets/images/icons/meteo/weather-symbols/{num}.svg'
    URL_FORECAST = 'https://app-prod-ws.meteoswiss-app.ch/v1/plzDetail?plz={ident}'

    def __init__(self):
        super().__init__()
        self._setup()

    def _handle_command(self, command: ProviderBase.Command) -> None:
        if command == 'get-search-suggestions':
            query = command.data['query']

            if not query:
                command.send_result({})

            suggestions = self._meteo_db.get_search_suggestions(query)

            result = {
                'count': len(suggestions),
                'items': suggestions
            }

            self._signal_send('log.search', suggestions)
            command.send_result(result)
        elif command == 'get-weather':
            # ...do stuff
            # send result:
            command.send_result(command.data)
        elif command == 'refresh':
            # ...do stuff
            # send result:
            command.send_result(command.data)
        else:
            self._handle_unknown_command(command)

    # def refresh(self, ident: str, force: bool) -> None:
    #     self._pre_refresh(ident, force)
    #     self._signal_send_global('info.refresh.started', ident, force)
    #
    #     # TODO verify ident in db
    #     new_data = {}
    #
    #     try:
    #         r = requests.get(self.URL_FORECAST.format(ident=ident), headers=HEADERS, timeout=1)
    #         print(r.headers)
    #         print(r.status_code)
    #         r.raise_for_status()
    #         new_data = r.json()
    #
    #         with open(self.data_path / 'forecast.json', 'w') as fd:
    #             fd.write(json.dumps(new_data, indent=2))
    #
    #         # TODO analyse reply headers
    #
    #     except requests.exceptions.RequestException as e:
    #         self._signal_send_global('warning.refresh.download-failed', self._data_db, r.status_code, r.headers, e)
    #         return
    #     except Exception as e:
    #         self._signal_send_global('warning.refresh.download-failed', self._data_db, e)
    #         return
    #
    #     self._signal_send_global('meteo.store-cache', ident, new_data)
    #     self._signal_send_global('info.refresh.finished', ident, new_data)

    def _setup(self):
        try:
            self._cache_db = self.make_cache_database(_CacheDb)
            _MetadataDb.CACHE = self._cache_db
            self._meteo_db = self.make_cache_database(_MetadataDb)
        except ValueError:
            return

        self.ready = True


def execute_command(*args, **kwargs) -> None:
    do_execute_command(*args, **kwargs, provider_class=Provider)
