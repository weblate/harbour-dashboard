import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    id: root
    height: childrenRect.height
    width: parent.width

    property int alignment: Qt.AlignRight
    property string label
    property string value
    property int padding: Theme.paddingMedium
    property int valueWidth: parent.hasOwnProperty('alignedLabelValueWidth') ?
        parent.alignedLabelValueWidth : 0

    Item {
        id: paddingLeft
        width: padding
        height: parent.height
        anchors.left: parent.left
    }

    Item {
        id: paddingRight
        width: padding
        height: parent.height
        anchors.right: parent.right
    }

    Label {
        id: labelLabel

        anchors {
            left: paddingLeft.right
            right: valueLabel.left
            leftMargin: 0
            rightMargin: Theme.paddingMedium
        }

        horizontalAlignment: Text.AlignRight

        color: Theme.secondaryHighlightColor
        text: label
        font.pixelSize: Theme.fontSizeSmall
        minimumPixelSize: Theme.fontSizeTiny
        fontSizeMode: Text.Fit
        truncationMode: TruncationMode.Fade
    }

    Label {
        id: valueLabel

        anchors.right: paddingRight.left

        horizontalAlignment: Text.AlignLeft
        width: valueWidth > 0 ? valueWidth : implicitWidth
        color: Theme.highlightColor
        text: value
    }

    states: [
        State {
            name: "left"
            when: alignment == Qt.AlignLeft

            AnchorChanges {
                target: valueLabel
                anchors {
                    right: undefined
                    left: paddingLeft.right
                }
            }

            PropertyChanges {
                target: valueLabel
                horizontalAlignment: Text.AlignRight
            }

            AnchorChanges {
                target: labelLabel
                anchors {
                    left: valueLabel.right
                    right: paddingRight.left
                }
            }

            PropertyChanges {
                target: labelLabel
                anchors {
                    leftMargin: Theme.paddingMedium
                    rightMargin: 0
                }

                horizontalAlignment: Text.AlignLeft
            }
        },

        State {
            name: "center"
            when: alignment == Qt.AlignCenter

            AnchorChanges {
                target: valueLabel
                anchors {
                    left: parent.horizontalCenter
                    right: paddingRight.left
                }
            }

            PropertyChanges {
                target: valueLabel
                anchors {
                    rightMargin: 0
                    leftMargin: Theme.paddingMedium / 2
                }

                horizontalAlignment: Text.AlignLeft
            }

            AnchorChanges {
                target: labelLabel
                anchors {
                    left: paddingLeft.right
                    right: parent.horizontalCenter
                }
            }

            PropertyChanges {
                target: labelLabel
                anchors {
                    leftMargin: 0
                    rightMargin: Theme.paddingMedium / 2
                }

                horizontalAlignment: Text.AlignRight
            }
        }
    ]
}

