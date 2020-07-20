/*
 *  SPDX-FileCopyrightText: 2016 Marco Martin <mart@kde.org>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.7
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.4 as Controls
import org.kde.kirigami 2.14

Controls.ToolButton {
    id: control

    signal menuAboutToShow

    Theme.colorSet: Theme.Button
    Theme.inherit: action && action.icon.color.a === 0
    Theme.backgroundColor: action && action.icon.color.a ? action.icon.color : undefined
    Theme.textColor: action && !flat && action.icon.color.a ? Theme.highlightedTextColor : undefined

    hoverEnabled: true
    flat: !control.action || !control.action.icon.color.a

    display: Controls.ToolButton.TextBesideIcon

    property bool showMenuArrow: !(action && action.displayHint !== undefined
                                   && action.displayHintSet(DisplayHint.HideChildIndicator))

    property var menuActions: {
        if (action && action.hasOwnProperty("children")) {
            return Array.prototype.map.call(action.children, (i) => i)
        }
        return []
    }

    property Component menuComponent: ActionsMenu {
        submenuComponent: ActionsMenu { }
    }

    property QtObject menu: null

    // We create the menu instance only when there are any actual menu items.
    // This also happens in the background, avoiding slowdowns due to menu item
    // creation on the main thread.
    onMenuActionsChanged: {
        if (menuComponent && menuActions.length > 0) {
            updateMenuArrow()

            if (!menu) {
                let incubator = menuComponent.incubateObject(control, {"actions": menuActions})
                if (incubator.status != Component.Ready) {
                    incubator.onStatusChanged = function(status) {
                        if (status == Component.Ready) {
                            menu = incubator.object
                            // Important: We handle the press on parent in the parent, so ignore it here.
                            menu.closePolicy = Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutsideParent
                            menu.closed.connect(() => control.checked = false)
                        }
                    }
                } else {
                    menu = incubator.object
                }
            } else {
                menu.actions = menuActions
            }
        }
    }

    onShowMenuArrowChanged: updateMenuArrow()

    checkable: (action && action.checkable) || (menuActions && menuActions.length > 0)
    opacity: enabled ? 1 : 0.4
    visible: (action && action.hasOwnProperty("visible")) ? action.visible : true

    onToggled: {
        if (menuActions.length > 0 && menu) {
            if (checked) {
                control.menuAboutToShow();
                menu.popup(control, 0, control.height)
            } else {
                menu.dismiss()
            }
        }
    }

    Controls.ToolTip.visible: control.hovered && text.length > 0 && !(menu && menu.visible) && !control.pressed
    Controls.ToolTip.text: action ? (action.tooltip && action.tooltip.length ? action.tooltip : action.text) : ""
    Controls.ToolTip.delay: Units.toolTipDelay
    Controls.ToolTip.timeout: 5000

    // This is slightly ugly but saves us from needing to recreate the entire
    // contents of the toolbutton. When using QQC2-desktop-style, the background
    // will be an item that renders the entire control. We can simply set a
    // property on it to get a menu arrow.
    function updateMenuArrow() {
        if (background.hasOwnProperty("properties")) {
            var properties = background.properties
            properties.menu = showMenuArrow && menuActions.length > 0
            background.properties = properties
        }
        // TODO: Support other styles
    }
}
