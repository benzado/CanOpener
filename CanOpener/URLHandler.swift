/*
 * URLHandler.swift
 * Created by Benjamin Ragheb on 10/30/15.
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

struct URLHandler : Hashable, StringLiteralConvertible {

    // MARK: - Class Properties

    static var frontmost : URLHandler? {
        let workspace = NSWorkspace.sharedWorkspace()
        if let frontAppID = workspace.frontmostApplication?.bundleIdentifier {
            return URLHandler.init(bundleIdentifier: frontAppID)
        } else {
            return nil
        }
    }

    static var current : URLHandler? {
        if let bundleIDString = NSBundle.mainBundle().bundleIdentifier {
            return URLHandler.init(bundleIdentifier: bundleIDString)
        } else {
            return nil
        }
    }

    static var running : Set<URLHandler> {
        var set = Set<URLHandler>()
        for app in NSWorkspace.sharedWorkspace().runningApplications {
            if let string = app.bundleIdentifier {
                if let bundleID = URLHandler.init(bundleIdentifier: string) {
                    set.insert(bundleID)
                }
            }
        }
        return set
    }

    // MARK: - Class Functions

    static func encodeSequence<S: SequenceType where S.Generator.Element == URLHandler>(seq: S) -> String {
        return seq.map { $0.bundleIdentifier }.joinWithSeparator(":")
    }

    static func defaultForURLScheme(scheme: String) -> URLHandler? {
        if let handlerID = LSCopyDefaultHandlerForURLScheme(scheme)?.takeRetainedValue() {
            return URLHandler.init(bundleIdentifier: handlerID as String)
        } else {
            return nil
        }
    }

    static func allForURLScheme(scheme: String) -> Set<URLHandler> {
        var set = Set<URLHandler>()
        if let unmanagedArray = LSCopyAllHandlersForURLScheme(scheme) {
            let array = unmanagedArray.takeRetainedValue() as [AnyObject]
            for object in array {
                if let string = object as? String {
                    if let bundleID = URLHandler.init(bundleIdentifier: string) {
                        set.insert(bundleID)
                    }
                }
            }
        }
        return set
    }

    // MARK: - Initializers

    init?(bundleIdentifier: String) {
        // return nil if invalid
        self.bundleIdentifier = bundleIdentifier
    }

    // MARK: StringLiteralConvertible

    init(stringLiteral value: String) {
        self.init(bundleIdentifier: value)!
    }

    init(extendedGraphemeClusterLiteral value: String) {
        self.init(bundleIdentifier: value)!
    }

    init(unicodeScalarLiteral value: String) {
        self.init(bundleIdentifier: value)!
    }

    // MARK: - Instance Properties

    let bundleIdentifier: String

    var hashValue: Int {
        return bundleIdentifier.hashValue
    }

    var URL : NSURL? {
        let workspace = NSWorkspace.sharedWorkspace()
        return workspace.URLForApplicationWithBundleIdentifier(bundleIdentifier)
    }

    var icon : NSImage? {
        let workspace = NSWorkspace.sharedWorkspace()
        if let path = URL?.path {
            return workspace.iconForFile(path)
        } else {
            return nil
        }
    }

    var localizedTitle : String {
        // TODO: find localized title
        return bundleIdentifier
    }

    // MARK: - Instance Functions

    func open(URL: NSURL) -> Bool {
        return NSWorkspace.sharedWorkspace().openURLs([URL],
            withAppBundleIdentifier: bundleIdentifier,
            options: .Default,
            additionalEventParamDescriptor: nil,
            launchIdentifiers: nil)
    }
}

@warn_unused_result func ==(lhs: URLHandler, rhs: URLHandler) -> Bool {
    return lhs.bundleIdentifier == rhs.bundleIdentifier
}
