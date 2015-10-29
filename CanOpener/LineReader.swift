//
//  LineReader.swift
//  CanOpener
//
//  Created by Benjamin Ragheb on 10/27/15.
//  Copyright © 2015 Heroic Software Inc. All rights reserved.
//

import Cocoa

class LineReader {
    let fileHandle : NSFileHandle
    let encoding : NSStringEncoding

    var lineHandlers : [ (dispatch_queue_t, ((String) -> ())) ] = []
    let buffer : NSMutableData

    init(fileHandle: NSFileHandle, encoding: NSStringEncoding = NSASCIIStringEncoding) {
        self.fileHandle = fileHandle
        self.buffer = NSMutableData.init()
        self.encoding = encoding
    }

    func addLineHandler(queue: dispatch_queue_t, handler: (String) -> ()) {
        lineHandlers.append((queue, handler))
    }

    func addLineHandler(handler: (String) -> ()) {
        addLineHandler(dispatch_get_main_queue(), handler: handler)
    }

    func startReading() {
        // This will create a retain cycle: self -> fileHandle -> block -> self,
        // however that will be broken by a call to stopReading()
        fileHandle.readabilityHandler = { handle in
            self.buffer.appendData(handle.availableData)
            while let line = self.readLine() {
                for (queue, handler) in self.lineHandlers {
                    dispatch_async(queue) {
                        handler(line)
                    }
                }
            }
        }
    }

    func stopReading() {
        fileHandle.readabilityHandler = nil
    }

    private func readLine() -> String? {
        var lineTerminatorByte = 0x0a
        let lineTerminatorData = NSData.init(bytesNoCopy: &lineTerminatorByte, length: 1, freeWhenDone: false)

        let wholeRange = NSRange.init(location: 0, length: buffer.length)
        let options = NSDataSearchOptions.init(rawValue: 0)
        let foundRange = buffer.rangeOfData(lineTerminatorData, options: options, range: wholeRange)

        if foundRange.location == NSNotFound {
            return nil
        }

        let lineRange = NSRange.init(location: 0, length: foundRange.location)
        let lineData = buffer.subdataWithRange(lineRange)

        let line = String.init(data: lineData, encoding: encoding)

        let replacementRange = NSRange.init(location: 0, length: lineRange.length + 1)
        buffer.replaceBytesInRange(replacementRange, withBytes: nil, length: 0)

        return line
    }
}
