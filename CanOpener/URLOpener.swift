/*
 * URLOpener.swift
 * Created by Benjamin Ragheb on 10/26/15.
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

@warn_unused_result func ==(lhs: URLOpener, rhs: URLOpener) -> Bool {
    return unsafeAddressOf(lhs) == unsafeAddressOf(rhs)
}

class URLOpener : Hashable {

    static private let taskOutputColor = NSColor.lightGrayColor()
    static private let taskErrorColor = NSColor.orangeColor()

    static private var activeOpeners = Set<URLOpener>()

    private let _URL : String
    private let _task = NSTask.init()
    private let _taskTranscript = NSMutableAttributedString.init()

    private var _taskOutputReader : LineReader?
    private var _taskErrorReader : LineReader?

    private var URLToOpen : NSURL?
    private var URLHandlersToUse = Set<URLHandler>()
    private var scriptErrors = [String]()


    static private let scriptPathUserDefaultsKey = "CanOpenerScriptPath"

    static var scriptPath : String? {
        get {
            return NSUserDefaults().stringForKey(scriptPathUserDefaultsKey)
        }
        set(newPath) {
            NSUserDefaults().setObject(newPath, forKey: scriptPathUserDefaultsKey)
        }
    }

    init(URL: String) {
        _URL = URL
        URLToOpen = NSURL.init(string: _URL)
    }

    var hashValue = random()

    private func environment() -> [String: String] {
        var environment = [
            "URL" : _URL
        ]

        if let frontmostBundleID = URLHandler.frontmost?.bundleIdentifier {
            environment["FROM_APP"] = frontmostBundleID
        }

        // Apple documentation says:
        //   The bundle ID string must be a uniform type identifier (UTI) that
        //   contains only alphanumeric (A-Z,a-z,0-9), hyphen (-), and period (.)
        //   characters.
        // Therefore it should be safe to use ':' as a list separator.
        // (Spaces are theoretically OK, but I've seen them as part of App IDs
        // in the wild.)

        if let scheme = URLToOpen?.scheme {
            let ignorable = [ URLHandler.current! ]
            let available = URLHandler.allForURLScheme(scheme).subtract(ignorable)
            let running = URLHandler.running.intersect(available)

            environment["AVAILABLE_APPS"] = URLHandler.encodeSequence(available)
            environment["RUNNING_APPS"] = URLHandler.encodeSequence(running)
        }

        if let rubyLibPath = NSBundle.mainBundle().pathForResource("lib-ruby", ofType: nil) {
            environment["RUBYLIB"] = rubyLibPath
        }

        return environment
    }

    private func pipe(prefix: String, color: NSColor) -> (NSPipe, LineReader?) {
        let pipe = NSPipe.init()
        let reader = LineReader.init(fileHandle: pipe.fileHandleForReading)

        reader.addLineHandler { line in
            print(prefix, line)
        }

        let outputString = _taskTranscript
        let font = NSFont.userFixedPitchFontOfSize(0) ?? NSFont.systemFontOfSize(0)

        let attributes = [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: color
        ]

        reader.addLineHandler { line in
            outputString.appendAttributedString(NSAttributedString.init(string: line, attributes: attributes))
            outputString.appendAttributedString(NSAttributedString.init(string: "\n"))
        }

        return (pipe, reader)
    }

    func run() {
        if URLToOpen == nil {
            failBecause("the provided URL <\(_URL)> is invalid.")
            return
        }

        var outPipe : NSPipe
        var errPipe : NSPipe

        (outPipe, _taskOutputReader) = pipe("OUT:", color: URLOpener.taskOutputColor)
        (errPipe, _taskErrorReader) = pipe("ERR:", color: URLOpener.taskErrorColor)

        _taskOutputReader?.addLineHandler { [unowned self] line in
            self.parseScriptCommand(line)
        }

        _taskOutputReader?.startReading()
        _taskErrorReader?.startReading()

        _task.launchPath = URLOpener.scriptPath
        _task.arguments = [ _URL ]
        _task.standardOutput = outPipe
        _task.standardError = errPipe
        _task.currentDirectoryPath = NSTemporaryDirectory()
        _task.environment = environment()

        _task.terminationHandler = { _ in
            dispatch_async(dispatch_get_main_queue()) {
                self.didTerminate()
            }
        }

        // TODO: verify script path

        // TODO: figure out how to guard against exceptions here
        _task.launch()

        URLOpener.activeOpeners.insert(self)
    }

    private static func regularExpressionForParsing() -> NSRegularExpression {
        let pattern = "([[a-z][A-Z]]+): (.+)"
        let options = NSRegularExpressionOptions.init(rawValue: 0)
        do {
            return try NSRegularExpression.init(pattern: pattern, options: options)
        }
        catch {
            assertionFailure("Failed to compile built-in regular expression: \(pattern)")
            return (nil as NSRegularExpression?)!
        }
    }

    private func parseScriptCommand(line: NSString) {
        let regExp = URLOpener.regularExpressionForParsing()
        let rangeOfLine = NSRange.init(location: 0, length: line.length)
        let matchOptions = NSMatchingOptions.Anchored
        if let match = regExp.firstMatchInString(line as String, options: matchOptions, range: rangeOfLine) {
            assert(match.numberOfRanges == 3)
            let command = line.substringWithRange(match.rangeAtIndex(1))
            let directObject = line.substringWithRange(match.rangeAtIndex(2))
            executeScriptCommand(command, directObject: directObject)
        }
    }

    private func executeScriptCommand(command: String, directObject: String) {
        print("got command [\(command)] with object [\(directObject)]")
        switch command {
        case "URL":
            if let newURL = NSURL.init(string: directObject) {
                URLToOpen = newURL
            } else {
                addScriptError("\"\(directObject)\" is not a valid URL")
            }
        case "Use":
            if let newHandler = URLHandler.init(bundleIdentifier: directObject) {
                URLHandlersToUse.insert(newHandler)
            } else {
                addScriptError("\"\(directObject)\" is not a valid app identifier")
            }
        default:
            addScriptError("\"\(command)\" is not a recognized command")
        }
    }

    private static func isBundleIDValid(bundleID: String) -> Bool {
        // TODO: implement
        return true
    }

    private func addScriptError(message: String) {
        scriptErrors.append(message)
    }

    private func didTerminate() {
        // I think there might be a race condition here, where the NSTask's
        // terminationHandler is invoked before all the lines have been read
        // from the output pipes.
        _taskErrorReader?.stopReading()
        _taskOutputReader?.stopReading()

        _task.terminationHandler = nil

        if _task.terminationReason == .UncaughtSignal {
            failBecause("it was terminated by an uncaught signal.")
        }
        else if _task.terminationStatus != 0 {
            failBecause("it terminated with a nonzero exit code \(_task.terminationStatus).")
        }
        else if !scriptErrors.isEmpty {
            failBecause(scriptErrors.joinWithSeparator("; ") + ".")
        }
        else if URLHandlersToUse.isEmpty {
            failBecause("it did not specify which app to open the URL with.")
        }
        else {
            ChooserWindowController.show(URLToOpen!, handlers: URLHandlersToUse)
        }

        URLOpener.activeOpeners.remove(self)
    }
    
    private func failBecause(reason: String) {
        let scriptPath = _task.launchPath ?? "????"
        let message = "The script \"\(scriptPath)\" was asked " +
            " what to do with URL <\(_URL)>, but failed because " + reason
        let transcript = self._taskTranscript.copy() as! NSAttributedString
        dispatch_async(dispatch_get_main_queue()) {
            ErrorWindowController.show(message, transcript: transcript)
        }
    }
}
