#!/bin/bash
#
# This file is part of Opal and has been released into the public domain.
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: 2021-2023 Mirian Margiani
#
# See https://github.com/Pretty-SFOS/opal/blob/main/snippets/opal-render-icons.md
# for documentation.
#
# @@@ keep this line: based on template v1.0.0
#
c__FOR_RENDER_LIB__="1.0.0"

# Run this script from the same directory where your icon sources are located,
# e.g. <app>/icon-src.
source ../libs/opal-render-icons.sh
cFORCE=false

for i in raw/*.svg; do
    if [[ "$i" -nt "${i#raw/}" ]]; then
        scour "$i" > "${i#raw/}"
    fi
done

cMY_APP=harbour-dashboard

cNAME="app: app icon"
cITEMS=("$cMY_APP")
cRESOLUTIONS=(86 108 128 172)
cTARGETS=(../icons/RESXxRESY)
render_batch

cNAME="app: details icon"
cITEMS=("$cMY_APP")
cRESOLUTIONS=(256)
cTARGETS=(../qml/images)
render_batch

cNAME="app: store icon"
cITEMS=("$cMY_APP")
cRESOLUTIONS=(172)
cTARGETS=(../dist)
render_batch

cNAME="app: banner image"
cITEMS=(../dist/banner)
cRESOLUTIONS=(
    1080x540++-large
    540x270++-small
)
cTARGETS=(../dist)
render_batch

cNAME="tiles: clock faces"
cITEMS=(
    clock-face-arabic
    clock-face-roman
    clock-face-plain
)
cRESOLUTIONS=(350)
cTARGETS=(../qml/tiles/clock/private)
render_batch

cNAME="tiles: common icons"
cITEMS=(
    icon-l-warning
)
cRESOLUTIONS=(168)
cTARGETS=(../qml/tiles/common/private)
render_batch

cNAME="tiles: common icons"
cITEMS=(
    icon-l-warning
)
cRESOLUTIONS=(168)
cTARGETS=(../qml/tiles/common/private)
render_batch

cNAME="tiles: base icons"
cITEMS=(
    icon-s-drop
)
cRESOLUTIONS=(56)
cTARGETS=(../qml/tiles/base/private)
render_batch
