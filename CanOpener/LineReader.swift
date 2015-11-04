/*
 * LineReader.swift
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

class LineReader {
    let fileHandle : NSFileHandle
    let encoding : NSStringEncoding

    private var lineHandlers : [ (dispatch_queue_t, ((String) -> ())) ] = []
    private let bufferedData = NSMutableData.init()

    init(fileHandle: NSFileHandle, encoding: NSStringEncoding = NSASCIIStringEncoding) {
        self.fileHandle = fileHandle
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
            let data = handle.availableData

            self.bufferedData.appendData(data)

            if let lines = self.readLines() {
                for (queue, handler) in self.lineHandlers {
                    dispatch_async(queue) {
                        for s in lines {
                            handler(s)
                        }
                    }
                }
            }
            
            if data.length == 0 {
                self.stopReading()
            }
        }
    }

    func stopReading() {
        fileHandle.readabilityHandler = nil
    }

    private static let terminatorByte = CChar(0x0a)

    private func readLines() -> [String]? {
        let bytes = UnsafePointer<CChar>(bufferedData.bytes)
        let terminatorIndices = (0 ..< bufferedData.length)
            .filter { bytes[$0] == LineReader.terminatorByte }

        if terminatorIndices.isEmpty { return nil }

        let lineIndices = [0] + terminatorIndices.map { $0.successor() }
        let lines = zip(lineIndices, terminatorIndices)
            .map { bufferedData.subdataWithRange(NSRange.init($0 ..< $1)) }
            .flatMap { String.init(data: $0, encoding: self.encoding) }

        let remainderIndex = terminatorIndices.last!.successor()
        if remainderIndex < bufferedData.length {
            let remainderRange = remainderIndex ..< bufferedData.length
            bufferedData.setData(bufferedData.subdataWithRange(NSRange.init(remainderRange)))
        } else {
            bufferedData.length = 0
        }

        return lines
    }
}
