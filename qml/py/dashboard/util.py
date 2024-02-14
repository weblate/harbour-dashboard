#
# This file is part of Forecasts for SailfishOS.
# SPDX-FileCopyrightText: 2022 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#

import sqlite3
from pathlib import Path


def log(*args, scope=''):
    scope = f'[py:{scope}]' if scope else '[py]'
    print(scope, *args)


def signal_send(event, *args):
    log(f'[{event}]', *args, scope='signal')


class DatabaseBase:
    HANDLE: str = 'database'

    _ROW_FACTORY = sqlite3.Row

    class UpToDate(Exception):
        pass

    class InvalidVersion(Exception):
        def __init__(self, path=None, version=None, **args):
            self.path = path
            self.version = version
            super().__init__(**args)

    class FileBroken(Exception):
        pass

    def __init__(self, path: Path, signal_callback, log_callback):
        self.con = None  # connection
        self.cur = None  # cursor

        self.path = Path(path)
        self._signal_callback = signal_callback
        self._log_callback = log_callback

        if self.HANDLE.endswith('.db'):
            self.HANDLE = self.HANDLE[:-3]

        self._db_path = self.path / (self.HANDLE + '.db')

        if self._db_path.exists() and not self._db_path.is_file():
            raise self.FileBroken()
            return

        self._setup()
        self._open_db()
        initial_version = self._load_version()
        self._outer_upgrade_schema(initial_version)

    def _open_db(self):
        self.con = sqlite3.connect(self._db_path)
        self.con.row_factory = self._ROW_FACTORY
        self.cur = self.con.cursor()

    def _load_version(self):
        # may be reimplemented if necessary

        try:
            row = self.cur.execute('SELECT version FROM metadata;').fetchone()
            version = row['version'] if row and row['version'] else 'none'
        except sqlite3.OperationalError:
            version = 'none'
        return version

    def _prepare_initial_version(self):
        # may be reimplemented if necessary

        # setup metadata table
        to_version = "0"  # initial version number
        self.cur.execute('CREATE TABLE metadata(version TEXT);')
        self.cur.execute('INSERT INTO metadata VALUES (?);', (to_version, ))
        return to_version

    def _save_version(self, version):
        # may be reimplemented if necessary

        self.cur.execute('UPDATE metadata SET version=?;', (version, ))
        self.con.commit()
        self.cur.execute('VACUUM;')

    def _setup(self):
        raise NotImplementedError  # reimplement

    def _outer_upgrade_schema(self, from_version, start_version=None):
        to_version = ""
        start_version = start_version if start_version is not None else from_version

        if from_version == "none":
            to_version = self._prepare_initial_version()
        else:
            try:
                to_version = self._upgrade_schema(from_version)
            except self.InvalidVersion:
                self._log("error: cannot use invalid schema version '{}' for database '{}'".format(from_version, self._db_path))
                raise self.InvalidVersion(self._db_path, from_version)
                return
            except self.UpToDate:
                # we arrived at the most recent version; save it and return
                if from_version != start_version:
                    self._save_version(from_version)
                self._log("schema '{}' is up-to-date (version: {})".format(self._db_path, from_version))
                return

        self._log("upgrading schema '{}' from {} to {}...".format(self._db_path, from_version, to_version))
        self._outer_upgrade_schema(to_version, start_version)

    def _upgrade_schema(self, from_version):
        raise NotImplementedError  # reimplement

        # simply follow this structure:

        if from_version == '0':
            # setup data tables...
            return '1'  # next version number
        elif from_version == '1':
            raise self.UpToDate

        raise self.InvalidVersion

    def _signal_send(self, event, *args):
        self._signal_callback(event, self.HANDLE, *args)

    def _log(self, *args, scope=''):
        subscope = f':{scope}' if scope else ''
        self._log_callback(*args, scope=f'database:{self.HANDLE}{subscope}')


class KeyValueBase(DatabaseBase):
    """
    Data database.

    This database provides a sectioned key-value storage. Keys can repeat in
    different sections.

    Using sections is optional. If no section is specified, the default
    section will be used for all keys. Sections are integers.
    """
    HANDLE = 'kv-database'
    DEFAULT_SECTION: int = 0

    def _setup(self):
        pass

    def _upgrade_schema(self, from_version):
        if from_version == '0':
            self.cur.execute("""
                CREATE TABLE IF NOT EXISTS keyvalue (
                    section INTEGER NOT NULL,
                    key TEXT NOT NULL,
                    value TEXT NOT NULL
                );""")
            return '1'
        elif from_version == '1':
            raise self.UpToDate

        raise self.InvalidVersion

    def get_value(self, key: str, section: int = DEFAULT_SECTION) -> str:
        """
        Get data from the key-value store.

        All data is stored as string.
        """
        row = self.con.execute("""
            SELECT value FROM keyvalue WHERE section = ?, key = ? LIMIT 1;
        """, (section, key)).fetchone()
        return row['value']

    def set_value(self, key: str, value: str, section: int = DEFAULT_SECTION, commit: bool = True) -> None:
        """
        Set data in the key-value store.

        Values will be forcefully converted to string.
        The key will be deleted if value is None.
        """
        if value is None:
            self.con.execute("""
                DELETE FROM keyvalue WHERE section = ?, key = ?;
            """, (section, key))
        else:
            self.con.execute("""
                INSERT OR REPLACE INTO keyvalue(section, key, value) VALUES (?, ?, ?);
            """, (section, key, str(value)))

        if commit:
            self.con.commit()
