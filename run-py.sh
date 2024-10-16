#!/bin/bash
#
# This file is part of harbour-dashboard
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2024 Mirian Margiani

# ------------------------------------------------------------------------------

tiles=

for i in "$PWD/qml/tiles/"{day_times,weather_mch,weather_yrn}; do
    tiles+="$i/private:"
done

export PYTHONPATH="$PWD/qml/py:$PWD/qml/py/libs:$tiles$PYTHONPATH"

# ------------------------------------------------------------------------------

case "$1" in
    "") python3; exit $?;;
    test)
        script="test-py/test_$2.py"

        if [[ -f "$script" ]]; then
            python3 "$script"
            exit $?
        else
            printf -- "%s\n" "error: no test script found at $script"
            exit 1
        fi
    ;;
    *) printf -- "%s\n" "usage: run-py.sh [test-<module>]"; exit 1;;
esac

# ------------------------------------------------------------------------------

exit 0
