/*
 * Socket.swift
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

extension CFSocketContext {
    static func fromInfoPointer<T: AnyObject>(opaque: COpaquePointer) -> T {
        return Unmanaged<T>.fromOpaque(opaque).takeUnretainedValue()
    }

    static func fromInfoPointer<T: AnyObject>(pointer: UnsafeMutablePointer<Void>) -> T {
        return fromInfoPointer(COpaquePointer.init(pointer))
    }

    static func fromInfoPointer<T: AnyObject>(pointer: UnsafePointer<Void>) -> T {
        return fromInfoPointer(COpaquePointer.init(pointer))
    }

    init(infoObject: AnyObject) {
        self.version = 0
        self.retain = { infoPointer in
            let opaque = COpaquePointer.init(infoPointer)
            Unmanaged<AnyObject>.fromOpaque(opaque).retain()
            return infoPointer
        }
        self.release = { infoPointer in
            let opaque = COpaquePointer.init(infoPointer)
            Unmanaged<AnyObject>.fromOpaque(opaque).release()
        }
        self.copyDescription = { infoPointer in
            let object : AnyObject = CFSocketContext.fromInfoPointer(infoPointer)
            let description = object.debugDescription
            return Unmanaged.passUnretained(description as! NSString)
        }
        let infoUnmanaged = Unmanaged.passUnretained(infoObject)
        let infoOpaque = infoUnmanaged.toOpaque()
        self.info = UnsafeMutablePointer.init(infoOpaque)
    }
}

class Socket {

    static let socketCallBack : CFSocketCallBack = {
        (socketRef, callBackType, addressData, dataPtr, infoPtr) in

        let socket : Socket = CFSocketContext.fromInfoPointer(infoPtr)

        switch callBackType {

        case CFSocketCallBackType.AcceptCallBack:
            let handlePointer = UnsafePointer<CFSocketNativeHandle>.init(dataPtr)
            socket.connectionAccepted(handlePointer.memory)

        case CFSocketCallBackType.DataCallBack:
            let dataOpaque = COpaquePointer.init(dataPtr)
            let data = Unmanaged<NSData>.fromOpaque(dataOpaque).takeUnretainedValue()
            socket.dataReceived(data)

        default:
            print("Socket: unimplemented callback:", callBackType)
            break
        }
    }

    var _socket : CFSocket!

    var connectionAcceptedHandler : ((Socket, Socket) -> Void)?

    var dataReceivedHandler : ((Socket, NSData) -> Void)?

    init(socketMaker: (CFSocketContext) -> CFSocket) {
        let context = CFSocketContext.init(infoObject: self)
        _socket = socketMaker(context)
    }

    static func nativeSocket(nativeHandle: CFSocketNativeHandle) -> Socket {
        return Socket.init { (var context) -> CFSocket in
            CFSocketCreateWithNative(kCFAllocatorDefault,
                nativeHandle,
                CFSocketCallBackType.DataCallBack.rawValue,
                Socket.socketCallBack,
                &context)
        }
    }

    static func serverSocket() -> Socket {
        return Socket.init { (var context) in
            CFSocketCreate(kCFAllocatorDefault,
                PF_LOCAL, SOCK_STREAM, 0,
                CFSocketCallBackType.AcceptCallBack.rawValue,
                Socket.socketCallBack,
                &context)
        }
    }

    func setAddress(path: String) {
        let pathData = path.dataUsingEncoding(NSASCIIStringEncoding)!

        var length = UInt8(sizeof(UInt8) + sizeof(sa_family_t) + pathData.length)
        var type = sa_family_t(AF_LOCAL)

        if let addressData = NSMutableData.init(capacity: sizeof(sockaddr_un)) {
            addressData.appendBytes(&length, length: sizeof(UInt8))
            addressData.appendBytes(&type, length: sizeof(sa_family_t))
            addressData.appendData(pathData)
            CFSocketSetAddress(_socket, addressData)
        }
    }

    func isValid() -> Bool {
        return CFSocketIsValid(_socket)
    }

    func addToRunLoop(runLoop: CFRunLoop) {
        let source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0)
        CFRunLoopAddSource(runLoop, source, kCFRunLoopCommonModes)
    }

    func addToMainRunLoop() {
        addToRunLoop(CFRunLoopGetMain())
    }

    func getSocketOptionInt(option_name: Int32) -> Int {
        let handle = CFSocketGetNative(_socket)
        var option_value = 0
        var option_size = socklen_t(sizeof(Int))
        getsockopt(handle, SOL_SOCKET, option_name, &option_value, &option_size)
        return option_value
    }

    func getSendBufferSize() -> Int {
        return getSocketOptionInt(SO_SNDBUF)
    }

    func getReceiveBufferSize() -> Int {
        return getSocketOptionInt(SO_RCVBUF)
    }

    func sendData(data: NSData) -> CFSocketError {
       return CFSocketSendData(_socket, nil, data, 0)
    }

    func invalidate() {
        CFSocketInvalidate(_socket)
    }

    func connectionAccepted(nativeHandle: CFSocketNativeHandle) {
        if let handler = self.connectionAcceptedHandler {
            let connection = Socket.nativeSocket(nativeHandle)
            handler(self, connection)
        }
    }

    func dataReceived(data: NSData) {
        if let handler = self.dataReceivedHandler {
            handler(self, data)
        }
    }
}
