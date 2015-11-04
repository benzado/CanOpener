/*
 * ChooserWindowController.swift
 * Created by Benjamin Ragheb on 10/28/15.
 * Copyright 2015 Benjamin Ragheb
 *
 * This file is part of CanOpener.
 *
 * CanOpener is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * CanOpener is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with CanOpener.  If not, see <http://www.gnu.org/licenses/>.
 */

import Cocoa

class ChooserWindowController: NSWindowController, NSWindowDelegate {

    static func openURL(URL: NSURL, handler: URLHandler) {
        if !handler.open(URL) {
            NSBeep()
        }
    }

    static func show(URL: NSURL, handlers: Set<URLHandler>) {
        assert(!handlers.isEmpty)

        if handlers.count == 1 {
            openURL(URL, handler: handlers.first!)
            return
        }

        let controller = ChooserWindowController.init(windowNibName: "ChooserWindowController")
        controller.URL = URL
        controller.handlers = Array(handlers)
        controller.showWindow(nil)
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
        AppDelegate.activeWindowControllers.insert(controller)
    }

    @IBOutlet weak var buttonSetView: NSStackView!
    @IBOutlet weak var URLField: NSTextField!

    private var URL : NSURL!
    private var handlers : Array<URLHandler>!

    private func centerWindowUnderMouseLocation() {
        if let window = self.window {
            let mousePoint = NSEvent.mouseLocation()
            var frame = window.frame

            frame.origin.x = mousePoint.x - round(0.5 * frame.width)
            frame.origin.y = mousePoint.y - round(0.5 * frame.height)

            window.setFrame(frame, display: false)
        }
    }

    private func createButtons() {
        let buttons : [NSButton] = handlers.map { identifier in
            let button = NSButton.init(frame: CGRect.zero)

            button.showsBorderOnlyWhileMouseInside = true

            if let cell = button.cell as? NSButtonCell {
                cell.bezelStyle = .RegularSquareBezelStyle
                cell.highlightsBy = .ChangeGrayCellMask
                cell.showsStateBy = .ChangeBackgroundCellMask
            }

            if let image = identifier.icon {
                image.size = CGSize.init(width: 128, height: 128)
                button.image = image
            } else {
                button.title = identifier.localizedTitle
            }

            button.target = self
            button.action = "buttonClicked:"
            button.tag = self.handlers.indexOf(identifier)!
            button.toolTip = identifier.URL?.path

            return button
        }

        buttonSetView.setViews(buttons, inGravity: NSStackViewGravity.Leading)
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        centerWindowUnderMouseLocation()

        self.URLField.stringValue = URL.absoluteString
        createButtons()
    }

    func buttonClicked(sender: NSButton) {
        let tag = sender.tag
        let handler = handlers[tag]

        ChooserWindowController.openURL(URL, handler: handler)

        self.close()
    }

    func windowWillClose(notification: NSNotification) {
        AppDelegate.activeWindowControllers.remove(self)
    }
}
