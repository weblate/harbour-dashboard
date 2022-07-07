#
# This file is part of Swiss Meteo.
# SPDX-FileCopyrightText: 2022 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#

import enum
from pathlib import Path
from functools import lru_cache


class Capability(enum.IntFlag):
    SUMMARY_FORECAST = 1
    DETAILED_FORECAST = 2
    TEMPERATURE = 4
    PRECIPITATION = 8
    WIND_SPEED = 16
    WIND_DIRECTION = 32
    POLLEN = 64
    DANGERS = 128

    ALL = SUMMARY_FORECAST + DETAILED_FORECAST + TEMPERATURE + \
        PRECIPITATION + WIND_SPEED + WIND_DIRECTION + POLLEN + DANGERS


class Provider:
    data_dir: Path = Path()
    cache_dir: Path = Path()

    name: str = ''
    handle: str = ''
    capabilities: Capability = 0

    def __init__(self, signal_callback, log_callback):
        self._signal_callback = signal_callback
        self._log_callback = log_callback
        self._log(f'initializing provider {self.name} ({self.handle})...')

        self.ready = False

        for k, v in {'data': self.data_path, 'cache': self.cache_path}.items():
            try:
                self._log(f"preparing {k} path in '{v}'")
                v.mkdir(parents=True, exist_ok=True)
            except (FileExistsError, PermissionError) as e:
                self._signal_send(f'warning.providers.local-{k}.inaccessible', v, e)
                return

    @property
    @lru_cache
    def data_path(self):
        return self.data_dir / self.handle

    @property
    @lru_cache
    def cache_path(self):
        return self.cache_dir / self.handle

    def _setup(self):
        raise NotImplementedError()

    def _load(self):
        pass

    def _signal_send(self, event, *args):
        self._signal_callback(event, self.handle, *args)

    def _log(self, *args):
        self._log_callback(*args, scope=f'provider:{self.handle}')
