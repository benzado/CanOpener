/*
 * ErrorWindowController.swift
 * Created by Benjamin Ragheb on 10/27/15.
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

class ErrorWindowController: NSWindowController, NSWindowDelegate {

    @IBOutlet weak var titleField: NSTextField!
    @IBOutlet weak var messageField: NSTextField!
    @IBOutlet var transcriptView: NSTextView!

    private var message : String!
    private var transcript : NSAttributedString!

    static func show(message: String, transcript: NSAttributedString) {
        let controller = ErrorWindowController.init(windowNibName: "ErrorWindowController")
        controller.message = message
        controller.transcript = transcript
        AppDelegate.activeWindowControllers.insert(controller)
        controller.showWindow(nil)
        NSBeep()
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
//        NSApplication.sharedApplication().requestUserAttention(.InformationalRequest)
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.center()

        let textView = self.transcriptView
        if let scrollView = textView.enclosingScrollView {
            textView.minSize = scrollView.bounds.size
            textView.maxSize = NSSize.init(width: CGFloat.max, height: CGFloat.max)
            textView.verticallyResizable = scrollView.hasVerticalScroller
            textView.horizontallyResizable = scrollView.hasHorizontalScroller
            textView.autoresizingMask = NSAutoresizingMaskOptions.ViewWidthSizable.union(.ViewHeightSizable)
            textView.textContainer?.containerSize = CGSize.init(width: CGFloat.max, height: CGFloat.max)
            textView.textContainer?.widthTracksTextView = false
        }

        self.titleField.stringValue = "CanOpener Script Error"
        self.messageField.stringValue = message
        self.transcriptView.textStorage?.setAttributedString(transcript)
    }

    func windowWillClose(notification: NSNotification) {
        AppDelegate.activeWindowControllers.remove(self)
    }
}
