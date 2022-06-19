#!/bin/bash
#
# This file is part of harbour-swissmeteo.
# Copyright (C) 2018-2020  Mirian Margiani
#
# harbour-swissmeteo is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# harbour-swissmeteo is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with harbour-swissmeteo.  If not, see <http://www.gnu.org/licenses/>.
#

for i in 86 108 128 172; do
    mkdir -p "icons/${i}x$i"
    inkscape -z -e "icons/${i}x$i/harbour-swissmeteo.png" -w "$i" -h "$i" harbour-swissmeteo.svg
done

mkdir -p "qml/weather-icons"
inkscape -z -l "qml/weather-icons/harbour-swissmeteo.svg" harbour-swissmeteo.svg
