/*
 * AppDelegate.swift
 * Created by Benjamin Ragheb on 10/24/15.
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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // Keep strong refrences here while the window is on the screen
    static var activeWindowControllers = Set<NSWindowController>()

    func applicationWillFinishLaunching(notification: NSNotification) {
        // Register to receive GetURL Apple Events
        NSAppleEventManager.sharedAppleEventManager().setEventHandler(self,
            andSelector: #selector(AppDelegate.handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: UInt32(kInternetEventClass),
            andEventID: UInt32(kAEGetURL))
    }

    func applicationDidFinishLaunching(notification: NSNotification) {
        // TODO: check if default handler

        let myBundle = NSBundle.mainBundle()

        let schemes = myBundle.infoDictionary?["CFBundleURLTypes"]?[0]?["CFBundleURLSchemes"] as? [String]

        print(schemes)

        let myID = myBundle.bundleIdentifier!

        print("I am \(myID)")

        schemes?.forEach { (scheme) in
            if let handler = URLHandler.defaultForURLScheme(scheme) {
                print("\(scheme) is handled by \(handler)")
            }
        }

        // Let the system terminate this app if it isn't doing anything
        NSProcessInfo().automaticTerminationSupportEnabled = true

        // Let the system mercilessly kill the app. Note that NSUserDefaults
        // is smart enough to disable sudden termination internally to ensure
        // data integrity.
        NSProcessInfo().enableSuddenTermination()
    }

    func handleGetURLEvent(event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        let directObject = event.paramDescriptorForKeyword(AEKeyword(keyDirectObject))
        if let URL = directObject?.stringValue {
            openURLString(URL)
        }
    }

    @IBAction func showPreferences(sender: NSMenuItem) {
        PreferencesWindowController.show()
    }

    @IBAction func simulateGetURLEvent(sender: NSMenuItem) {
        if let finder = NSRunningApplication.runningApplicationsWithBundleIdentifier("com.apple.finder").first {
            finder.activateWithOptions(NSApplicationActivationOptions.init(rawValue: 0))
        }
        let t = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * NSEC_PER_SEC))
        dispatch_after(t, dispatch_get_main_queue()) {
            self.openURLString(sender.title)
        }
    }

    // TODO: add a test for an absurdly long URL, make sure Chooser Window isn't crazy wide

    func openURLString(URL: String) {
        // TODO: offer to install a template

        if let path = URLOpener.scriptPath {
            if !NSFileManager.defaultManager().isExecutableFileAtPath(path) {
                let alert = NSAlert.init()
                alert.alertStyle = .WarningAlertStyle
                alert.messageText = "Can Opener Script Not Found"
                alert.informativeText = "Could not find executable script at \"\(path)\". Create one!"
                alert.runModal()
                return
            }
        } else {
            let alert = NSAlert.init()
            alert.alertStyle = .WarningAlertStyle
            alert.messageText = "No Can Opener Script Set"
            alert.informativeText = "Script not set! Go to preferences and set one."
            alert.runModal()
            return
        }

        URLOpener.init(URL: URL).run()
    }
}
