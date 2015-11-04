//
//  PreferencesWindowController.swift
//  CanOpener
//
//  Created by Benjamin Ragheb on 11/4/15.
//  Copyright © 2015 Heroic Software Inc. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController, NSWindowDelegate {

    static var visibleInstance : PreferencesWindowController?

    static func show() {
        if let instance = visibleInstance {
            instance.showWindow(nil)
            return
        }
        let instance = PreferencesWindowController.init(windowNibName: "PreferencesWindowController")
        instance.showWindow(nil)
        visibleInstance = instance
    }

    @IBOutlet weak var scriptPathField: NSTextField!

    var userDefaultsObserver : NSObjectProtocol?

    func updateScriptPathField() {
        if let s = URLOpener.scriptPath {
            scriptPathField.stringValue = s
            scriptPathField.textColor = NSColor.textColor()
        } else {
            scriptPathField.stringValue = "none"
            scriptPathField.textColor = NSColor.disabledControlTextColor()
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        self.updateScriptPathField()

        userDefaultsObserver = NSNotificationCenter()
            .addObserverForName(NSUserDefaultsDidChangeNotification,
                object: nil,
                queue: NSOperationQueue.mainQueue(),
                usingBlock: { [unowned self] _ in self.updateScriptPathField() })
    }
    
    @IBAction func chooseScript(sender: NSButton) {
        // When debugging, the app will crash here if a breakpoint is set on
        // "All Exceptions"; something to do with code signature verification.
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Choose"
        openPanel.showsHiddenFiles = true
        openPanel.treatsFilePackagesAsDirectories = true
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.resolvesAliases = false
        openPanel.allowsMultipleSelection = false
        openPanel.beginSheetModalForWindow(self.window!) { buttonClicked in
            if buttonClicked == NSFileHandlingPanelOKButton {
                if let path = openPanel.URL?.path {
                    URLOpener.scriptPath = path
                    self.updateScriptPathField()
                }
            }
        }
    }

    func windowWillClose(notification: NSNotification) {
        PreferencesWindowController.visibleInstance = nil
    }
}
