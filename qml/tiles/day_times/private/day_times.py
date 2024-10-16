#
# This file is part of harbour-dashboard
# SPDX-FileCopyrightText: 2022 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#

import datetime

from geopy.geocoders import GeoNames
from geopy.timezone import Timezone

from dashboard.provider import ProviderBase
from dashboard.provider import do_execute_command

from astral import Location
from astral import AstralError


LOCATION_QUERIES = {}
TIMEZONE_QUERIES = {}


class Provider(ProviderBase):
    NAME = 'Day Times'
    HANDLE = 'day_times'

    def __init__(self):
        super().__init__()
        self._setup()

    def _handle_command(self, command: ProviderBase.Command) -> None:
        if command == 'get-search-suggestions':
            query = command.data['query']

            if not query:
                command.send_result({})
            elif query in LOCATION_QUERIES:
                command.send_result(LOCATION_QUERIES[query])
            else:
                locations = self.geocoder.geocode(command.data['query'], exactly_one=False)
                result = {
                    'count': len(locations),
                    'items': [
                        {
                            'address': x.address,
                            'latitude': x.latitude,
                            'longitude': x.longitude,
                        } for x in locations
                    ]
                }

                command.log(locations)
                LOCATION_QUERIES[query] = result
                command.send_result(result)
        elif command == 'lookup-timezone':
            coordinates = (command.data['latitude'], command.data['longitude'])

            if coordinates in TIMEZONE_QUERIES:
                command.send_result(TIMEZONE_QUERIES[coordinates])
            else:
                tz: Timezone = self.geocoder.reverse_timezone(coordinates)
                result = {
                    'timezone': tz.raw['timezoneId']
                }

                command.log(tz.raw, tz.pytz_timezone)
                TIMEZONE_QUERIES[coordinates] = result
                command.send_result(result)
        elif command == 'get-times':
            latitude = command.data['latitude']
            longitude = command.data['longitude']
            timezone = command.data['timezone']

            loc = Location(('<name>', '<region>', latitude, longitude, timezone, 0))
            loc.solar_depression = 'civil'
            sun = loc.sun()

            # iso format: %Y-%m-%dT%H:%M
            # time only: %H:%M

            result = {
                'dawn': sun['dawn'].strftime('%H:%M'),
                'sunrise': sun['sunrise'].strftime('%H:%M'),
                'noon': sun['noon'].strftime('%H:%M'),
                'sunset': sun['sunset'].strftime('%H:%M'),
                'dusk': sun['dusk'].strftime('%H:%M'),
                'golden_hour_morning': loc.golden_hour(1)[0].strftime('%H:%M'),
                'golden_hour_evening': loc.golden_hour(-1)[0].strftime('%H:%M'),
                'moon_phase': loc.moon_phase(),
                'zenith': loc.solar_zenith(sun['noon']),
            }

            command.send_result(result)
        elif command == 'get-year-preview':
            latitude = command.data['latitude']
            longitude = command.data['longitude']
            timezone = command.data['timezone']

            loc = Location(('<name>', '<region>', latitude, longitude, timezone, 0))
            loc.solar_depression = 'civil'

            days = []
            times = []
            year = datetime.date.today().year

            for i in range(1, 13):
                days.append(datetime.date(year, i, 1).strftime("%b"))

                try:
                    times.append(loc.sun(datetime.date(year, i, 1)))
                except AstralError:
                    times.append({'noon': None, 'sunrise': None, 'sunset': None})

            def decimalTime(time):
                if time is None:
                    return None
                return (time.hour * 60 + time.minute) / 60

            result = {
                'days': days,
                'noon': [decimalTime(x['noon']) for x in times],
                'sunrise': [decimalTime(x['sunrise']) for x in times],
                'sunset': [decimalTime(x['sunset']) for x in times]
            }

            command.send_result(result)
        elif command == 'get-week-preview':
            latitude = command.data['latitude']
            longitude = command.data['longitude']
            timezone = command.data['timezone']

            loc = Location(('<name>', '<region>', latitude, longitude, timezone, 0))
            loc.solar_depression = 'civil'

            days = []
            times = []
            today = datetime.date.today()

            for i in range(0, 7):
                times.append(loc.sun(today + datetime.timedelta(days=i)))
                days.append((today + datetime.timedelta(days=i)).strftime("%a"))

            def decimalTime(time):
                return (time.hour * 60 + time.minute) / 60

            result = {
                'days': days,
                'noon': [decimalTime(x['noon']) for x in times],
                'sunrise': [decimalTime(x['sunrise']) for x in times],
                'sunset': [decimalTime(x['sunset']) for x in times]
            }

            command.send_result(result)
        else:
            self._handle_unknown_command(command)

    def _setup(self):
        self.geocoder = GeoNames('ichthyosaurus', user_agent='MyTestApp 1.0')
        self.ready = True


def execute_command(*args, **kwargs) -> None:
    do_execute_command(*args, **kwargs, provider_class=Provider)
