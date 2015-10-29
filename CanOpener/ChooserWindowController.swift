//
//  ChooserWindowController.swift
//  CanOpener
//
//  Created by Benjamin Ragheb on 10/28/15.
//  Copyright © 2015 Heroic Software Inc. All rights reserved.
//

import Cocoa

class ChooserWindowController: NSWindowController, NSWindowDelegate {

    // Keep strong refrences here while the window is on the screen
    private static var visibleControllers = Set<NSWindowController>()

    @IBOutlet weak var buttonSetView: NSStackView!
    @IBOutlet weak var URLField: NSTextField!

    private var URL : NSURL!
    private var bundleIdentifiers : [String]!

    static func show(URL: NSURL, bundleIdentifiers: [String]) {
        assert(!bundleIdentifiers.isEmpty)

        if bundleIdentifiers.count == 1 {
            openURL(URL, bundleIdentifier: bundleIdentifiers[0])
            return
        }

        let controller = ChooserWindowController.init(windowNibName: "ChooserWindowController")
        controller.URL = URL
        controller.bundleIdentifiers = bundleIdentifiers
        controller.showWindow(nil)
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
        visibleControllers.insert(controller)
    }

    static func openURL(URL: NSURL, bundleIdentifier: String) {
        let didOpen = NSWorkspace.sharedWorkspace().openURLs([URL],
            withAppBundleIdentifier: bundleIdentifier,
            options: .Default,
            additionalEventParamDescriptor: nil,
            launchIdentifiers: nil)

        if !didOpen {
            NSBeep()
        }
    }

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
        let workspace = NSWorkspace.sharedWorkspace()

        let buttons : [NSButton] = bundleIdentifiers.map { identifier in
            let button = NSButton.init(frame: CGRect.zero)

            button.showsBorderOnlyWhileMouseInside = true

            if let cell = button.cell as? NSButtonCell {
                cell.bezelStyle = .RegularSquareBezelStyle
                cell.highlightsBy = .ChangeGrayCellMask
                cell.showsStateBy = .ChangeBackgroundCellMask
            }

            if let path = workspace.URLForApplicationWithBundleIdentifier(identifier)?.path {
                let image = workspace.iconForFile(path)
                button.image = image
            } else {
                button.title = identifier
            }

            button.target = self
            button.action = "buttonClicked:"
            button.tag = self.bundleIdentifiers.indexOf(identifier)!

            return button
        }

        buttonSetView.setViews(buttons, inGravity: NSStackViewGravity.Leading)
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.delegate = self
        centerWindowUnderMouseLocation()

        self.URLField.stringValue = URL.absoluteString
        createButtons()
    }

    func buttonClicked(sender: NSButton) {
        let tag = sender.tag
        let identifier = bundleIdentifiers[tag]

        ChooserWindowController.openURL(URL, bundleIdentifier: identifier)

        self.close()
    }

    func windowWillClose(notification: NSNotification) {
        ChooserWindowController.visibleControllers.remove(self)
    }
}
