#
# This file is part of harbour-dashboard
# SPDX-FileCopyrightText: 2022 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#

import locale
import re
import json
import enum
import datetime
import math

from copy import deepcopy
from pathlib import Path
from functools import partial
from random import randrange

from dateutil import parser as dateparser
from dashboard.provider import ProviderBase
from dashboard.provider import do_execute_command
from dashboard.util import DatabaseBase
from dashboard.util import KeyValueBase


# TODO
# - detect broken/changed API and if the app is blocked
# - if so, stop all requests (-> cache entry) and wait for an update of the app
# - make sure there are no repeated and/or failing requests to the API


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

        - weather data:
                                                                           single ID    ID list      ID list
            call("https://app-prod-ws.meteoswiss-app.ch/v1/plzOverview?plz=300100&small=400100&large=100200")
            > 200
            > most of it is empty
            > ID lists are comma separated: 400100,300100

            call("https://app-prod-ws.meteoswiss-app.ch/v1/plzOverview?plz=300100")
            > gives 400 client error

            call("https://app-prod-ws.meteoswiss-app.ch/v1/plzOverview?small=400100")
            > gives 400 client error

            call("https://app-prod-ws.meteoswiss-app.ch/v1/plzOverview?plz=400100&small=400100")
            > gives 400 client error

            call("https://app-prod-ws.meteoswiss-app.ch/v1/plzOverview?plz=400100&small=400100&large=400100")
            > 200
            > with data

            call("https://app-prod-ws.meteoswiss-app.ch/v1/plzOverview?plz=400100&small=&large=")
            > 200
            > with data

            call("https://app-prod-ws.meteoswiss-app.ch/v1/plzOverview?plz=&small=400100&large=")
            > 200
            > some data

            call("https://app-prod-ws.meteoswiss-app.ch/v1/plzOverview?plz=&small=&large=400100,300100")
            > 200
            > week overview + graph; current is empty

            call("https://app-prod-ws.meteoswiss-app.ch/v2/plzDetail?plz=400100")
            > gives 200
            > with lots of data

            call("https://app-prod-ws.meteoswiss-app.ch/v2/plzDetail?plz=400100,300100")
            > gives 500 server error

            call("https://app-prod-ws.meteoswiss-app.ch/v1/vorortdetail?plz=100200")
            > gives 400 client error

            call("https://app-prod-ws.meteoswiss-app.ch/v1/forecast?plz=300100")
            > gives 200
            > but all data fields are empty

            call("https://app-prod-ws.meteoswiss-app.ch/v2/plzDetail?plz=400100")
            > gives 200
            > with lots of data
            >>> best one: ~30kb, week overview, graphs, sunrise, symbols, current weather
            >>> refreshed every ~10 minutes


def call(url):
    print("CALL --------------------------------------------------------------------")
    print(url)

    try:
        r = requests.get(url, headers=HEADERS, timeout=1)

        print("HEADER --------------------------------------------------------------------")
        print(json.dumps(dict(r.headers), indent=2))
        print("STATUS --------------------------------------------------------------------")
        print(r.status_code)

        print("RAISE --------------------------------------------------------------------")
        r.raise_for_status()

        print("JSON --------------------------------------------------------------------")
        print(json.dumps(dict(r.json()), indent=2))

    except (requests.ConnectionError, requests.ConnectTimeout) as e:
        self._signal_send('timeout', e)
    except requests.exceptions.RequestException as e:
        self._signal_send('requests exception', e)
        return
    except Exception as e:
        self._signal_send('any exception', e)
        return
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

    def make_db_path(self, basename: str) -> Path:
        return self.path / (basename + '.db')


class _MetadataDb(DatabaseBase):
    HANDLE = 'metadata'
    SUPPORTED_DATA_DB_VERSIONS = ['165']

    def _setup(self):
        pass

    def _upgrade_schema(self, from_version):
        if from_version in self.SUPPORTED_DATA_DB_VERSIONS:
            raise self.UpToDate

        raise self.InvalidVersion

    def get_search_suggestions(self, query: str):
        if re.match('^[0-9]+$', query):
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

            command.log(suggestions)
            command.send_result(result)
        elif command == 'get-weather-data':
            if command.tile_id < 0:
                command.log('warning: cannot fetch weather data without a valid tile ID, got', command.tile_id)

            if cached_data := self._get_cached_weather_data(command):
                command.log(f'using cached data for {command.data["key"]}')
                command.send_result(self._convert_weather_data(cached_data))
                return

            command.log(f'no cache for {command.data["key"]}, fetching new data')

            if new_data := self._get_remote_weather_data(command):
                command.log(f'fetched weather data for {command.data["key"]}')
                command.send_result(self._convert_weather_data(new_data))
                return
            else:
                command.log('failed to fetch updated data, retrying with outdated cache')

            if cached_data := self._get_cached_weather_data(command, allow_outdated=True):
                command.log(f'falling back to outdated cached data for {command.data["key"]}')
                command.send_result(self._convert_weather_data(cached_data))
                return

            command.log(f"error: failed to load cache or fetch new data for {command.data['key']}")
        elif command == 'refresh':
            # ...do stuff
            # send result:
            command.send_result(command.data)
        else:
            self._handle_unknown_command(command)

    def _convert_weather_data(self, raw_data: dict) -> dict:
        wind_labels = []

        for i in range(0, 24, 3):
            wind_labels += [f'{i:d}', '', '']

        wind_labels = wind_labels[0:-1] + ['23']

        hourly_labels = [f'{x:d}' for x in range(0, 24)]
        high_res_labels = [f"{x:d}'" for x in range(0, 90, 10)]

        day_template = {
            'isValid': False,
            'date': '',
            'temperature': {
                'haveData': False,
                'labels': hourly_labels,
                'datasets': [
                    {  # mean
                        'data': [],
                        'symbols': []
                    },
                    {  # minimum
                        'data': [],
                    },
                    {  # maximum
                        'data': [],
                    },
                ],
            },
            'precipitation': {
                'haveData': False,
                'labels': hourly_labels,
                'datasets': [
                    {  # mean
                        'data': [],
                        'symbols': []
                    },
                    {  # minimum
                        'data': [],
                    },
                    {  # maximum
                        'data': [],
                    },
                ],
            },
            'precipitationHighRes': {
                'haveData': False,
                'labels': high_res_labels,
                'datasets': [
                    {  # mean
                        'data': [],
                        'symbols': []
                    },
                    {  # minimum
                        'data': [],
                    },
                    {  # maximum
                        'data': [],
                    },
                ]
            },
            'wind': {
                'haveData': False,
                'labels': wind_labels,
                'datasets': [
                    {  # speed
                        'data': [],
                        'direction': [],
                    },
                ],
            },
        }

        def convert_ts(ts: int) -> datetime.datetime:
            ts_str = f'{ts:013d}'[0:10]  # reduce from 13 to 10 digits
            return datetime.datetime.fromtimestamp(int(ts_str))

        graphs = []
        day_count = math.floor(len(raw_data['graph']['temperatureMean1h']) / 24)
        start = convert_ts(raw_data['graph']['start'])
        now = datetime.datetime.now()

        raw_current_ts = raw_data['currentWeather']['time']

        current_temp = None
        current_icon = 0

        # It can happen that the 'currentWeather' field contains empty or
        # greatly outdated data (e.g. data from two years ago).
        # In that case, we fall back to deducing the current weather from the
        # forecast dataset.
        if raw_current_ts:
            raw_current_time = convert_ts(raw_current_ts)

            if raw_current_time.date() == now.date() and \
                    round(raw_current_time.hour + raw_current_time.minute / 60) == \
                    round(now.hour + now.minute / 60):
                current_temp = raw_data['currentWeather']['temperature']
                current_icon = raw_data['currentWeather']['icon']

        # build low-resolution forecast from high-resolution data, if available
        if len(raw_data['graph']['precipitation10m']) > 0:
            # the startLowResolution key is missing if there is no high-res data
            low_res_start_ts = raw_data['graph']['startLowResolution']
            low_res_start = convert_ts(low_res_start_ts)

            self._log('LOW RES START', low_res_start)

        for i in range(0, day_count):
            day = deepcopy(day_template)

            date = start + datetime.timedelta(days=i)
            day['date'] = date.strftime('%Y-%m-%d')

            # -------- current weather
            if current_temp is None and date.date() == now.date():
                current_hour = now.hour + (now.minute / 60)
                current_temp = raw_data['graph']['temperatureMean1h'][i * 24 + round(current_hour)]
                current_icon = raw_data['graph']['weatherIcon3h'][i * 8 + round(current_hour / 3)]

            # -------- temperature
            # note: we assume data starts at 00:00 and is available for 24 hours
            # TODO: handle changes to/from daylight saving time
            day['temperature']['datasets'][0]['data'] = raw_data['graph']['temperatureMean1h'][i * 24:i * 24 + 24]
            day['temperature']['datasets'][1]['data'] = raw_data['graph']['temperatureMin1h'][i * 24:i * 24 + 24]
            day['temperature']['datasets'][2]['data'] = raw_data['graph']['temperatureMax1h'][i * 24:i * 24 + 24]

            raw_symbols = raw_data['graph']['weatherIcon3h'][i * 8:i * 8 + 8]

            for i in raw_symbols:
                day['temperature']['datasets'][0]['symbols'] += [i, 0, 0]

            # -------- precipitation
            pass

            # -------- wind
            raw_speed = raw_data['graph']['windSpeed3h'][i * 8:i * 8 + 8]

            for i in raw_speed:
                day['wind']['datasets'][0]['data'] += [i, i, i]

            raw_direction = raw_data['graph']['windDirection3h'][i * 8:i * 8 + 8]

            for i in raw_direction:
                day['wind']['datasets'][0]['direction'] += [i, i, i]

            # -------- save
            graphs.append(day)

        converted = {
            'currentWeather': {
                'temperature': current_temp,
                'icon': current_icon,
            },
            'overview': raw_data['forecast'],
            'graphs': graphs,
        }

        return converted

    def _get_cached_weather_data(self, command: ProviderBase.Command, allow_outdated: bool = False) -> [None, dict]:
        if command.tile_id < 0:
            command.log('cache miss: invalid tile id', command.tile_id)
            return None

        get_cache = partial(self._cache_db.get_value, section=CacheSection.TILES + command.tile_id)
        last_key = get_cache('key')

        if last_key != command.data['key']:
            command.log(f'cache miss: cached key is {last_key}, expected {command.data["key"]}')
            return None

        now = datetime.datetime.now(datetime.timezone.utc)
        next_refresh = get_cache('next-refresh')
        load_level_interval = randrange(10)

        try:
            downloaded_parsed = dateparser.parse(get_cache('downloaded'))
            next_refresh_parsed = dateparser.parse(next_refresh)
        except ValueError as e:
            command.log('cache miss: invalid cached timestamp')
            command.log(f'warning: failed to parse data timestamp "{next_refresh}", error:', e)
            return None

        if now > next_refresh_parsed + datetime.timedelta(minutes=load_level_interval):
            if allow_outdated:
                command.log('cache hit: using outdated cache is explicitly allowed this time')
            else:
                command.log(f'cache miss: cache is outdated, have {now}, next refresh at {next_refresh_parsed} + interval {load_level_interval}')
                return None

        last_data = get_cache('data')

        if not last_data:
            command.log('cache miss: cached data is empty')
            return None

        try:
            loaded = json.loads(last_data)
        except json.JSONDecodeError as e:
            command.log('cache miss: cached data is invalid')
            command.log(f'warning: failed to decode cached data for {command.data["key"]}, error:', e)
            return None

        command.log(f'cache hit: returning cached data for {command.data["key"]}')
        command.log(f'cache hit: downloaded {downloaded_parsed}, valid until {next_refresh_parsed}')
        return loaded

    def _get_remote_weather_data(self, command: ProviderBase.Command) -> [None, dict]:
        response = self._fetch("https://app-prod-ws.meteoswiss-app.ch/v2/plzDetail",
                               params={'plz': command.data['key']}, headers=HEADERS,
                               logger=command.log)

        if not response.ok:
            command.log(f"failed to fetch data for {command.data['key']}, status {response.status}, error:", response.error)
            return None

        """
        expected headers:
        {
            "Date": "Wed, 14 Feb 2024 13:52:27 GMT",
            "Content-Type": "application/json",
            "Transfer-Encoding": "chunked",
            "Connection": "keep-alive",
            "Server": "nginx",
            "Vary": "Accept-Encoding",
            "x-amz-meta-next-refresh": "Wed, 14 Feb 2024 14:02:30 GMT",
            "x-amz-meta-best-before": "Wed, 14 Feb 2024 15:52:27 GMT",
            "x-amz-meta-backoff": "120",
            "x-amz-meta-minimum-api-version": "32",
            "Content-Encoding": "gzip"
        }
        """

        set_cache = partial(self._cache_db.set_value, section=CacheSection.TILES + command.tile_id)
        set_cache('key', command.data['key'])
        set_cache('downloaded', response.headers['Date'])
        set_cache('next-refresh', response.headers['x-amz-meta-next-refresh'])
        set_cache('best-before', response.headers['x-amz-meta-best-before'])
        set_cache('data', response.text)

        return response.json

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

    def _fetch_metadata_database(self) -> bool:
        db_path: Path = self._cache_db.make_db_path(_MetadataDb.HANDLE)

        if not db_path.exists():
            # download locations database if it does not exists
            self._signal_send_global('info.providers.local-data.database-download-started', db_path)

            response = self._fetch('https://app-prod-static.meteoswiss-app.ch/v1/db.sqlite',
                                   headers=HEADERS, logger=partial(self._log, scope='metadata-download'))

            """
            Expected headers: status 200

            {
                "x-amz-id-2": "HOG3FIlYQVk1yInMV9HvvZzJcGgvkaK3PPGitN4faV1EsrP9zwZreO1Xmq7l/MCubTkdz5Nw2C4=",
                "x-amz-request-id": "4E4H2KWBGQ9B2W75",
                "Date": "Tue, 13 Feb 2024 14:28:21 GMT",
                "Last-Modified": "Fri, 15 Dec 2023 15:27:26 GMT",
                "ETag": "\"bd86233b3f95e7e2d121ff56fe2fb847\"",
                "x-amz-server-side-encryption": "AES256",
                "x-amz-meta-minimum-api-version": "32",
                "x-amz-meta-best-before": "Sat, 14 Dec 2024 15:27:25 GMT",
                "Content-Encoding": "gzip",
                "x-amz-meta-backoff": "21600",
                "Expires": "Fri, 15 Dec 2023 21:27:25 GMT",
                "x-amz-version-id": "hMKD0xgZ1mxqnu09GbLXrz5NsaqKGikZ",
                "x-amz-meta-next-refresh": "Fri, 15 Dec 2023 21:27:25 GMT",
                "Accept-Ranges": "bytes",
                "Content-Type": "application/x-sqlite3",
                "Server": "AmazonS3",
                "Content-Length": "267147"
            }

            Or:

            {
                "Date": "Wed, 14 Feb 2024 23:35:50 GMT",
                "Content-Type": "application/x-sqlite3",
                "Content-Length": "267147",
                "Connection": "keep-alive",
                "last-modified": "Fri, 15 Dec 2023 15:27:26 GMT",
                "etag": "\"bd86233b3f95e7e2d121ff56fe2fb847\"",
                "x-amz-server-side-encryption": "AES256",
                "x-amz-meta-minimum-api-version": "32",
                "x-amz-meta-best-before": "Sat, 14 Dec 2024 15:27:25 GMT",
                "Content-Encoding": "gzip",
                "x-amz-meta-backoff": "21600",
                "expires": "Fri, 15 Dec 2023 21:27:25 GMT",
                "x-amz-version-id": "hMKD0xgZ1mxqnu09GbLXrz5NsaqKGikZ",
                "x-amz-meta-next-refresh": "Fri, 15 Dec 2023 21:27:25 GMT",
                "x-cache": "Miss from cloudfront",
                "via": "1.1 a2cac9c5f0e90f8b7fede4ac9aca75ca.cloudfront.net (CloudFront)",
                "x-amz-cf-pop": "FRA56-P4",
                "x-amz-cf-id": "Lp9u42cFwmapfEU33AKoxYNuoRy_edznwOukA9QapzqWvO7g3jlTuA==",
                "CF-Cache-Status": "REVALIDATED",
                "Accept-Ranges": "bytes",
                "Report-To": "{\"endpoints\":[{\"url\":\"https:\\/\\/a.nel.cloudflare.com\\/report\\/v3?s=Ip5eDw6DAhc5djeo0q31R4LhSZmvA12OrXLB6DjrELI009UVdTipuSJRxvKxxrWKu%2BNZvvcWswXeeV0DPQ7a%2B8%2B5HraYBxTECPVcv2Ag%2BV2bkkCiwx9654mRGodWUgl3DPdAJOHRbpT91QGUePz4H3W6MQ%3D%3D\"}],\"group\":\"cf-nel\",\"max_age\":604800}",
                "NEL": "{\"success_fraction\":0,\"report_to\":\"cf-nel\",\"max_age\":604800}",
                "Vary": "Accept-Encoding",
                "Server": "cloudflare",
                "CF-RAY": "8559213b8aee1c22-FRA"
            }
            """

            if not response.ok:
                self._signal_send('warning.providers.local-data.database-download-failed', db_path, response.status, response.headers, response.error)
                return False

            with open(db_path, 'wb') as fd:
                for chunk in response.r.iter_content(chunk_size=128):
                    fd.write(chunk)

            set_cache = partial(self._cache_db.set_value, section=CacheSection.METADATA)
            set_cache('downloaded', response.headers['Date'])
            set_cache('last-modified', response.headers['Last-Modified'])
            set_cache('best-before', response.headers['x-amz-meta-best-before'])

            self._signal_send('info.providers.local-data.database-download-finished', db_path)

        if db_path.exists() and not db_path.is_file():
            self._signal_send('warning.providers.local-data.database-broken', db_path)
            return False
        else:
            self._signal_send('info.providers.local-data.database-ready', db_path)

        return True

    def _setup(self):
        try:
            # cache must be initialized before preparing the metadata database
            self._cache_db = self.make_cache_database(_CacheDb)

            if not self._fetch_metadata_database():
                raise ValueError()

            self._meteo_db = self.make_cache_database(_MetadataDb)
        except ValueError:
            return

        self.ready = True


def execute_command(*args, **kwargs) -> None:
    do_execute_command(*args, **kwargs, provider_class=Provider)
