#
# This file is part of Forecasts for SailfishOS.
# SPDX-FileCopyrightText: 2022 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#

import requests
import json

from pathlib import Path
from functools import lru_cache
from dataclasses import dataclass
from typing import Callable, Dict, Iterable, Any


_INITIALIZED_PROVIDERS: Dict[str, 'ProviderBase'] = {}


def _raise_callback_missing(*args, **kwargs):
    raise NotImplementedError("bug: the ProviderBase class callback methods have not been initialized")


def do_execute_command(*args, provider_class, **kwargs) -> None:
    if provider_class.HANDLE not in _INITIALIZED_PROVIDERS:
        _INITIALIZED_PROVIDERS[provider_class.HANDLE] = provider_class()

    _INITIALIZED_PROVIDERS[provider_class.HANDLE].execute_command(*args, **kwargs)


class ProviderBase:
    DATA_DIR: Path = Path()
    CACHE_DIR: Path = Path()
    CONFIG_DIR: Path = Path()

    signal_callback: Callable = _raise_callback_missing
    log_callback: Callable = _raise_callback_missing

    NAME: str = ''
    HANDLE: str = ''  # must match the module name
    # capabilities: Capability = 0

    def __init__(self):
        self._log(f'initializing {self}...')

        self.ready = False

        for k, v in {'data': self.data_path, 'cache': self.cache_path, 'config': self.config_path}.items():
            try:
                self._log(f"preparing {k} path in '{v}'")
                v.mkdir(parents=True, exist_ok=True)
            except (FileExistsError, PermissionError) as e:
                self._signal_send_global(f'warning.providers.local-{k}.inaccessible', v, e)
                return

    def __str__(self):
        return f"Provider {self.NAME} ({self.HANDLE})"

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
        return self.DATA_DIR / self.HANDLE

    @property
    @lru_cache
    def cache_path(self):
        return self.CACHE_DIR / self.HANDLE

    @property
    @lru_cache
    def config_path(self):
        return self.CONFIG_DIR / self.HANDLE

    @dataclass
    class RequestResponse:
        r: requests.Response
        error: Exception

        @property
        def ok(self) -> bool:
            return self.error is None and self.status == 200

        @property
        def headers(self) -> dict:
            return self.r.headers

        @property
        def json(self) -> dict:
            return dict(self.r.json())

        @property
        def text(self) -> dict:
            return self.r.text

        @property
        def status(self) -> int:
            return self.r.status_code

    def _fetch(self, command: 'ProviderBase.Command', url: str, params: dict = {},
               headers: dict = {}, timeout: int = 1) -> ['ProviderBase.RequestResponse', None]:
        command.log('fetching:', url, 'params:', params, 'timeout:', timeout)

        try:
            r = requests.get(url, headers=headers, timeout=1, params=params)

            command.log('received headers:\n', json.dumps(dict(r.headers), indent=2))
            command.log('received status:', r.status_code)

            r.raise_for_status()

            command.log('received data:\n', json.dumps(dict(r.json()), indent=2))
        except (requests.ConnectionError, requests.ConnectTimeout) as e:
            # TODO handle broken API and don't retry endlessly
            self._signal_send('error:web-request-timeout', e)
            return self.RequestResponse(r, e)
        except requests.exceptions.RequestException as e:
            self._signal_send('error:web-request-failed', e)
            return self.RequestResponse(r, e)
        except Exception as e:
            self._signal_send('error:web-request-failed', e)
            return self.RequestResponse(r, e)

        return self.RequestResponse(r, None)

    @dataclass
    class Command:
        command: str
        tile_id: int
        sequence: int
        data: dict
        send_result: Callable[[dict], None]
        log: Callable[[Iterable[Any]], None]

        def __eq__(self, other):
            if isinstance(other, ProviderBase.Command):
                return self.command == other.command and \
                    self.tile_id == other.tile_id and \
                    self.sequence == other.sequence
            elif isinstance(other, str):
                return self.command == other
            return False

    def execute_command(self, command: str, tile_id: int, sequence: int, data: dict) -> None:
        """
        Execute a command from the frontend.
        """
        if not self.ready:
            self._signal_send_global('error.provider-not-ready', tile_id, command, sequence, data)
            return

        def send_result(result: dict) -> None:
            self._signal_send(f'result:{command}', tile_id, sequence, command, result)

        def log(*args) -> None:
            self._log(*args, scope=f'command:{command}')

        self._signal_send_global('info.main.provider-command.started', tile_id, command, sequence, data)
        self._handle_command(self.Command(command, tile_id, sequence, data, send_result, log))
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
        ProviderBase.signal_callback(f"provider.{self.HANDLE}.{event}@{self.HANDLE}", *args)

    def _signal_send_global(self, event, *args):
        ProviderBase.signal_callback(f"{event}@{self.HANDLE}", *args)

    def _log(self, *args, scope=''):
        subscope = f':{scope}' if scope else ''
        ProviderBase.log_callback(*args, scope=f'provider:{self.HANDLE}{subscope}')
