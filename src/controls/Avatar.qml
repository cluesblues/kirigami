/*
 *  SPDX-FileCopyrightText: 2020 Carson Black <uhhadd@gmail.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.5
import org.kde.kirigami 2.13 as Kirigami
import QtQuick.Controls 2.13 as QQC2
import QtGraphicalEffects 1.0
import org.kde.kirigami.private 2.14

import "templates/private" as P

/**
 * An element that represents a user, either with initials, an icon, or a profile image.
 */
QQC2.Control {
    id: avatarRoot

    enum ImageMode {
        AlwaysShowImage,
        AdaptiveImageOrInitals,
        AlwaysShowInitials
    }
    enum InitialsMode {
        UseInitials,
        UseIcon
    }

    /**
    * The given name of a user.
    *
    * The user's name will be used for generating initials.
    */
    property string name

    /**
    * The source of the user's profile picture; an image.
    */
    property alias source: avatarImage.source

    /**
    * How the button should represent the user when there is no image available.
    * * `UseInitials` - Use initials when the image is not available
    * * `UseIcon` - Use an icon of a user when the image is not available
    */
    property int initialsMode: Kirigami.Avatar.InitialsMode.UseInitials

    /**
    * Whether the button should always show the image; show the image if one is
    * available and show initials when it is not; or always show initials.
    * * `AlwaysShowImage` - Always show the image; even if is not value
    * * `AdaptiveImageOrInitals` - Show the image if it is valid; or show initials if it is not
    * * `AlwaysShowInitials` - Always show initials
    */
    property int imageMode: Kirigami.Avatar.ImageMode.AdaptiveImageOrInitals

     /**
     * Whether or not the image loaded from the provided source should be cached.
     *
     */
     property alias cache: avatarImage.cache

    /**
     * color: color
     *
     * The color to use for this avatar.
     */
    property var color: undefined
    // We use a var instead of a color here to allow setting the colour
    // as undefined, which will result in a generated colour being used.

    /**
     * actions.main: Kirigami.Action
     * actions.secondary: Kirigami.Action
     *
     * Actions associated with this avatar.
     *
     * Note that the secondary action should only be used for shortcuts of actions
     * elsewhere in your application's UI, and cannot be accessed on mobile platforms.
     */
    property AvatarGroup actions: AvatarGroup {}

    property P.BorderPropertiesGroup border: P.BorderPropertiesGroup {
        width: 2
        color: Qt.rgba(0,0,0,0.2)
    }

    padding: 0
    topPadding: 0
    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0

    implicitWidth: Kirigami.Units.iconSizes.large
    implicitHeight: Kirigami.Units.iconSizes.large

    background: Rectangle {
        radius: parent.width / 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: __private.color }
            GradientStop { position: 1.0; color: Kirigami.ColorUtils.scaleColor(__private.color, {lightness: -35.0}) }
        }
        MouseArea {
            id: primaryMouse

            anchors.fill: parent
            hoverEnabled: true
            property bool mouseInCircle: {
                let x = avatarRoot.width / 2, y = avatarRoot.height / 2
                let xPrime = mouseX, yPrime = mouseY

                let distance = (x - xPrime) ** 2 + (y - yPrime) ** 2
                let radiusSquared = (Math.min(avatarRoot.width, avatarRoot.height) / 2) ** 2

                return distance < radiusSquared
            }

            onClicked: {
                if (mouseY > avatarRoot.height - secondaryRect.height && !!avatarRoot.actions.secondary) {
                    avatarRoot.actions.secondary.trigger()
                    return
                }
                if (!!avatarRoot.actions.main) {
                    avatarRoot.actions.main.trigger()
                }
            }

            enabled: !!avatarRoot.actions.main || !!avatarRoot.actions.secondary
            cursorShape: containsMouse && mouseInCircle && enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

            states: [
                State {
                    name: "secondaryRevealed"
                    when: (!Kirigami.Settings.isMobile) && (!!avatarRoot.actions.secondary) && (primaryMouse.containsMouse && primaryMouse.mouseInCircle)
                    PropertyChanges {
                        target: secondaryRect
                        visible: true
                    }
                }
            ]
        }
    }

    QtObject {
        id: __private
        // This property allows us to fall back to colour generation if
        // the root colour property is undefined.
        property color color: {
            if (!!avatarRoot.color) {
                return avatarRoot.color
            }
            return AvatarPrivate.colorsFromString(name)
        }
        property bool showImage: {
            return (avatarRoot.imageMode == Kirigami.Avatar.ImageMode.AlwaysShowImage) ||
                   (avatarImage.status == Image.Ready && avatarRoot.imageMode == Kirigami.Avatar.ImageMode.AdaptiveImageOrInitals)
        }
    }

    contentItem: Item {
        Kirigami.Heading {
            visible: avatarRoot.initialsMode == Kirigami.Avatar.InitialsMode.UseInitials &&
                    !__private.showImage &&
                    !AvatarPrivate.stringUnsuitableForInitials(avatarRoot.name)

            text: AvatarPrivate.initialsFromString(name)
            color: Kirigami.ColorUtils.brightnessForColor(__private.color) == Kirigami.ColorUtils.Light
                ? "black"
                : "white"

            anchors.centerIn: parent
        }
        Kirigami.Icon {
            visible: (avatarRoot.initialsMode == Kirigami.Avatar.InitialsMode.UseIcon && !__private.showImage) ||
                    (AvatarPrivate.stringUnsuitableForInitials(avatarRoot.name) && !__private.showImage)

            source: "user"

            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing

            Kirigami.Theme.textColor: Kirigami.ColorUtils.brightnessForColor(__private.color) == Kirigami.ColorUtils.Light
                                    ? "black"
                                    : "white"
        }
        Image {
            id: avatarImage
            visible: __private.showImage

            mipmap: true
            smooth: true

            fillMode: Image.PreserveAspectFit
            anchors.fill: parent
        }

        Rectangle {
            color: "transparent"

            radius: width / 2
            anchors.fill: parent

            border {
                width: avatarRoot.border.width
                color: avatarRoot.border.color
            }
        }

        Rectangle {
            id: secondaryRect
            visible: false

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }

            height: Kirigami.Units.iconSizes.small + Kirigami.Units.smallSpacing*2

            color: Qt.rgba(0, 0, 0, 0.6)

            Kirigami.Icon {
                Kirigami.Theme.textColor: "white"
                source: (avatarRoot.actions.secondary || {iconName: ""}).iconName

                width: Kirigami.Units.iconSizes.small
                height: Kirigami.Units.iconSizes.small

                anchors.centerIn: parent
            }
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                height: avatarRoot.height
                width: avatarRoot.width
                radius: height / 2
                color: "black"
                visible: false
            }
        }
    }
}
