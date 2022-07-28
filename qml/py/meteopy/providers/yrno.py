#
# This file is part of Swiss Meteo.
# SPDX-FileCopyrightText: 2022 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#

from .provider_base import Capability
from .provider_base import Provider as ProviderBase


class Provider(ProviderBase):
    name = 'Yr.no'
    handle = 'yrn'
    capabilities = Capability.SUMMARY_FORECAST | Capability.DETAILED_FORECAST |\
        Capability.PRECIPITATION | Capability.TEMPERATURE

    def __init__(self, signal_callback, log_callback):
        super().__init__(signal_callback, log_callback)
        self._setup()

    def refresh(self, ident: str, force: bool) -> None:
        raise NotImplementedError("Provider backend is not yet implemented")

    def _setup(self):
        self.ready = False
        raise NotImplementedError("Provider backend is not yet implemented")
