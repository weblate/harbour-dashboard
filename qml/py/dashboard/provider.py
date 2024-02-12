#
# This file is part of Forecasts for SailfishOS.
# SPDX-FileCopyrightText: 2022 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#

# import enum
from pathlib import Path
from functools import lru_cache
from dataclasses import dataclass
from typing import Callable, Dict


_INITIALIZED_PROVIDERS: Dict[str, 'ProviderBase'] = {}


def _raise_callback_missing(*args, **kwargs):
    raise NotImplementedError()


# class Capability(enum.IntFlag):
#     SUMMARY_FORECAST = 1
#     DETAILED_FORECAST = 2
#     TEMPERATURE = 4
#     PRECIPITATION = 8
#     WIND_SPEED = 16
#     WIND_DIRECTION = 32
#     POLLEN = 64
#     DANGERS = 128
#
#     ALL = SUMMARY_FORECAST + DETAILED_FORECAST + TEMPERATURE + \
#         PRECIPITATION + WIND_SPEED + WIND_DIRECTION + POLLEN + DANGERS


def do_execute_command(*args, provider_class, **kwargs) -> None:
    if provider_class.handle not in _INITIALIZED_PROVIDERS:
        _INITIALIZED_PROVIDERS[provider_class.handle] = provider_class()

    _INITIALIZED_PROVIDERS[provider_class.handle].execute_command(*args, **kwargs)


class ProviderBase:
    data_dir: Path = Path()
    cache_dir: Path = Path()
    config_dir: Path = Path()

    signal_callback: Callable = _raise_callback_missing
    log_callback: Callable = _raise_callback_missing

    name: str = ''
    handle: str = ''  # must match the module name
    # capabilities: Capability = 0

    def __init__(self):
        self._log(f'initializing provider {self.name} ({self.handle})...')

        self.ready = False

        for k, v in {'data': self.data_path, 'cache': self.cache_path, 'config': self.config_path}.items():
            try:
                self._log(f"preparing {k} path in '{v}'")
                v.mkdir(parents=True, exist_ok=True)
            except (FileExistsError, PermissionError) as e:
                self._signal_send_global(f'warning.providers.local-{k}.inaccessible', v, e)
                return

    def make_cache_database(self, db_class):
        return self._make_database(db_class, self.cache_path)

    def make_data_database(self, db_class):
        return self._make_database(db_class, self.data_path)

    def make_config_database(self, db_class):
        return self._make_database(db_class, self.config_path)

    def _make_database(self, db_class, path):
        try:
            db = db_class(path, self._signal_send_global, self._log)
        except db_class.InvalidVersion as e:
            self._signal_send_global('warning.providers.database-broken', e.path, e.version)
            raise ValueError

        return db

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

    @dataclass
    class Command:
        command: str
        tile_id: int
        sequence: int
        data: dict
        send_result: Callable[[dict], None]

        def __eq__(self, other):
            if isinstance(other, ProviderBase.Command):
                return self.command == other.command and \
                    self.tile_id == other.tile_id and \
                    self.sequence == other.sequence
            elif isinstance(other, str):
                return self.command == other
            return False

    def execute_command(self, command, tile_id, sequence, data) -> None:
        """
        Execute a command from the frontend.
        """
        if not self.ready:
            self._signal_send_global('error.provider-not-ready', tile_id, command, sequence, data)
            return

        def send_result(result: dict) -> None:
            self._signal_send(f'result:{command}', tile_id, sequence, command, result)

        self._signal_send_global('info.main.provider-command.started', tile_id, command, sequence, data)
        self._handle_command(self.Command(command, tile_id, sequence, data, send_result))
        self._signal_send_global('info.main.provider-command.finished', tile_id, command, sequence, data)

    def _handle_command(self, command: 'ProviderBase.Command') -> None:
        """
        Handle commands from the frontend.

        Implementations must override this function, while send_command() must not
        be changed by implementations.

        Results are passed back to the frontend using signals.

        Implementations must include the 'tile_id' and 'sequence' arguments
        as the first (tile_id) and second (sequence) argument of the signal.

        Which signals are sent and how they are handled is completely up to
        the provider-specific backend and frontend implementations.
        """
        raise NotImplementedError()

    def _handle_unknown_command(self, command: 'ProviderBase.Command') -> None:
        """
        Notify the frontend that the provider received and unknown command.
        Implementations must not overwrite this method.
        """
        self._signal_send_global('warning.unknown-command', command.tile_id, command.sequence, command.command, command.data)

    def _setup(self):
        raise NotImplementedError()

    def _signal_send(self, event, *args):
        ProviderBase.signal_callback(f"provider.{self.handle}.{event}@{self.handle}", *args)

    def _signal_send_global(self, event, *args):
        ProviderBase.signal_callback(f"{event}@{self.handle}", *args)

    def _log(self, *args, scope=''):
        subscope = f':{scope}' if scope else ''
        self.log_callback(*args, scope=f'provider:{self.handle}{subscope}')
