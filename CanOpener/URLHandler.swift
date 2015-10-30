//
//  URLHandler.swift
//  CanOpener
//
//  Created by Benjamin Ragheb on 10/30/15.
//  Copyright © 2015 Heroic Software Inc. All rights reserved.
//

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
