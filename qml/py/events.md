<!--
This file is part of harbour-dashboard
SPDX-License-Identifier: GPL-3.0-or-later
SPDX-FileCopyrightText: 2020-2024  Mirian Margiani
-->

# Signals and Events

## Events

### Class: fatal

| Event                | Description                                              | Arguments |
|----------------------|----------------------------------------------------------|-----------|
| fatal.local-data.inaccessible | | directory_type, path, error_message |
| fatal.local-data.database-broken | | |

### Class: error

| Event                | Description                                              | Arguments |
|----------------------|----------------------------------------------------------|-----------|
| error.backup.failed  | | |

### Class: warning

| Event                | Description                                              | Arguments |
|----------------------|----------------------------------------------------------|-----------|
| warning.providers.broken | | |

### Class: info

| Event                | Description                                              | Arguments |
|----------------------|----------------------------------------------------------|-----------|
| info.*    | | |

### Class: main

| Event                | Description                                              | Arguments |
|----------------------|----------------------------------------------------------|-----------|
| main.store-cache    | | |
