/*
 * This file is part of harbour-dashboard
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2024  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

import "../../../modules/qchart/"
import "../../../modules/qchart/QChart.js" as Charts

QChart {
    property var dataGetter: function(){}

    property double _calculatedYearOffset: {
        var d = new Date()
        var ret = 0.0

        ret += d.getMonth() * (1/12)
        ret += d.getDate() * (1/12/30)

        return ret
    }

    chartAnimated: false
    chartData: { 'labels': ['', '', '', '', '', '', ''], 'datasets': [
        { data: [0, 0, 0, 0, 0, 0, 24] }
    ]}

    chartType: Charts.ChartType.LINE
    chartOptions: ({
        scaleFontSize: Theme.fontSizeExtraSmall * (4/5),
        scaleFontFamily: 'Sail Sans Pro',
        scaleFontColor: Theme.secondaryColor,
        scaleLineColor: Theme.secondaryColor,
        scaleOverlay: false,
        bezierCurve: false,
        datasetStrokeWidth: 2,
        datasetFill: false,
        datasetFillDiff23: true,
        pointDotRadius: 6,
        currentHourLine: true,
        currentHourPosition: _calculatedYearOffset,
        asOverview: false,

        scaleOverride: true,
        scaleStartValue: 0,
        scaleStepWidth: 6,
        scaleSteps: 4,
        scaleShowGridLines: true,

        fillColor:        ["rgba(255, 195, 77,0)", "rgba(255, 195, 77,0.2)", "rgba(255, 195, 77,0.2)"],
        strokeColor:      ["rgba(255, 195, 77,1)", "rgba(255, 195, 77,0.6)", "rgba(255, 195, 77,0.6)"],
        pointColor:       ["rgba(255, 195, 77,1)", "rgba(255, 195, 77,0.3)", "rgba(255, 195, 77,0.3)"],
        pointStrokeColor: ["rgba(255, 195, 77,1)", "rgba(255, 195, 77,0.3)", "rgba(255, 195, 77,0.3)"],
    })

    Component.onCompleted: {
        dataGetter(function(_, __, data){
            chartData = {
                'labels': data['days'],
                'datasets': [
                    {'data': data['noon']},
                    {'data': data['sunset']},
                    {'data': data['sunrise']}
                ]
            }
        })
    }
}
