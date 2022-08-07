#
# This file is part of Forecasts for SailfishOS.
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
    config_dir: Path = Path()

    name: str = ''
    handle: str = ''
    capabilities: Capability = 0

    def __init__(self, signal_callback, log_callback):
        self._signal_callback = signal_callback
        self._log_callback = log_callback
        self._log(f'initializing provider {self.name} ({self.handle})...')

        self.ready = False

        for k, v in {'data': self.data_path, 'cache': self.cache_path, 'config': self.config_path}.items():
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

    @property
    @lru_cache
    def config_path(self):
        return self.config_dir / self.handle

    def call_command(self, command, tile_id, sequence, data) -> None:
        """ Execute a command from the frontend.

            Results are passed back to the frontend using signals.

            Implementations must include the 'tile_id' and 'sequence' arguments
            as the first (tile_id) and second (sequence) argument of the signal.

            Which signals are sent and how they are handled is completely up to
            the provider-specific backend and frontend implementations.
        """
        raise NotImplementedError()

    def refresh(self, ident: str, force: bool) -> None:
        """ Refresh forecast for a given location.
            Implementations must call self._pre_refresh() before doing anything else.
        """
        raise NotImplementedError()

    def _pre_refresh(self, ident: str, force: bool) -> None:
        if not ident:
            self._signal_send('error.refresh.empty-id', ident, force)
            return

    def _setup(self):
        raise NotImplementedError()

    def _signal_send(self, event, *args):
        self._signal_callback(event, self.handle, *args)

    def _log(self, *args, scope=''):
        subscope = f':{scope}' if scope else ''
        self._log_callback(*args, scope=f'provider:{self.handle}{subscope}')
