//
//  ErrorWindowController.swift
//  CanOpener
//
//  Created by Benjamin Ragheb on 10/27/15.
//  Copyright © 2015 Heroic Software Inc. All rights reserved.
//

import Cocoa

class ErrorWindowController: NSWindowController, NSWindowDelegate {

    // Keep strong refrences here while the window is on the screen
    private static var visibleControllers = Set<NSWindowController>()

    @IBOutlet weak var titleField: NSTextField!
    @IBOutlet weak var messageField: NSTextField!
    @IBOutlet var transcriptView: NSTextView!

    private var message : String!
    private var transcript : NSAttributedString!

    static func show(message: String, transcript: NSAttributedString) {
        let controller = ErrorWindowController.init(windowNibName: "ErrorWindowController")
        controller.message = message
        controller.transcript = transcript
        visibleControllers.insert(controller)
        controller.showWindow(nil)
        NSBeep()
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
//        NSApplication.sharedApplication().requestUserAttention(.InformationalRequest)
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.delegate = self
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
        ErrorWindowController.visibleControllers.remove(self)
    }
}
