//
//  RFNotification.swift
//  RFKit
//
//  Created by Rasmus Krämer on 15.12.24.
//

import Foundation
import OSLog
import Combine

@usableFromInline
let RFNotificationPayloadKey = "RFNotificationPayload"

public struct RFNotification {
    public static subscript<P>(_ notification: IsolatedNotification<P>) -> IsolatedNotification<P> {
        notification
    }
    public static subscript<P>(_ notification: NonIsolatedNotification<P>) -> NonIsolatedNotification<P> {
        notification
    }
    
    public final class MarkerStash {
        var markers: [Marker]
        
        public init() {
            markers = []
        }
        
        public func add(_ marker: consuming Marker) {
            markers.append(marker)
        }
        public func clear() {
            while !markers.isEmpty {
                markers.removeFirst().callAsFunction()
            }
        }
        
        deinit {
            for marker in markers {
                marker()
            }
        }
    }
    
    // Can be copied: https://forums.swift.org/t/review-sf-0011-concurrency-safe-notifications/75975/18
    // According to the Apple docs the notification center removes invalid observers, as long as you subscribe using [weak self]
    public struct Marker {
        public let token: NSObjectProtocol
        
        public init(token: NSObjectProtocol) {
            self.token = token
        }
        
        public func store(in stash: inout MarkerStash) {
            stash.add(self)
        }
        
        public func callAsFunction() {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    public enum RFOperationQueue {
        case sender
        case other(_ queue: OperationQueue)
        
        @usableFromInline
        var operationQueue: OperationQueue? {
            switch self {
            case .sender:
                nil
            case .other(let queue):
                queue
            }
        }
    }
}

public struct RFNotificationEmptyPayload: Sendable {}

// MARK: Notification

public extension RFNotification {
    protocol Notification: Sendable {
        typealias IsolatedNotification = RFNotification.IsolatedNotification
        typealias NonIsolatedNotification = RFNotification.NonIsolatedNotification
        
        associatedtype Payload
        
        var name: NSNotification.Name { get }
        var requiresMainActor: Bool { get }
    }
    
    struct IsolatedNotification<P>: Notification {
        public typealias Payload = P
        
        public let name: NSNotification.Name
        
        public init(_ name: String) {
            self.name = .init(name)
        }
        public init(_ name: NSNotification.Name) {
            self.name = name
        }
        
        public var requiresMainActor: Bool {
            true
        }
    }
    struct NonIsolatedNotification<P>: Notification {
        public typealias Payload = P
        
        public let name: NSNotification.Name
        
        public init(_ name: String) {
            self.name = .init(name)
        }
        public init(_ name: NSNotification.Name) {
            self.name = name
        }
        
        public var requiresMainActor: Bool {
            false
        }
    }
}

// MARK: Empty

public extension RFNotification.IsolatedNotification where Payload == RFNotificationEmptyPayload {
    @inlinable @MainActor
    func send(object: Any? = nil) {
        NotificationCenter.default.post(name: name, object: object)
    }
    @inlinable
    func send(object: Sendable? = nil) async {
        await MainActor.run {
            send(object: object)
        }
    }
    
    @inlinable
    func dispatch(object: Sendable? = nil) {
        Task { @MainActor in
            send(object: object)
        }
    }
}
public extension RFNotification.NonIsolatedNotification where Payload == RFNotificationEmptyPayload {
    @inlinable
    func send(object: Any? = nil) {
        NotificationCenter.default.post(name: name, object: object)
    }
}

public extension RFNotification.Notification where Payload == RFNotificationEmptyPayload {
    @inlinable @discardableResult
    func subscribe(object: Any? = nil, queue: RFNotification.RFOperationQueue, using handler: @escaping @Sendable () -> Void) -> RFNotification.Marker {
        let token = NotificationCenter.default.addObserver(forName: name, object: object, queue: queue.operationQueue) { _ in
            handler()
        }
        
        return .init(token: token)
    }
    
    @inlinable @discardableResult
    func subscribe(object: Any? = nil, @_inheritActorContext using handler: @Sendable @escaping () async -> Void) -> RFNotification.Marker {
        let token = NotificationCenter.default.addObserver(forName: name, object: object, queue: .current) { _ in
            Task {
                await handler()
            }
        }
        
        return .init(token: token)
    }
    
    func publisher(object: AnyObject? = nil) -> some Publisher<Void, Never> {
        NotificationCenter.default.publisher(for: name, object: object)
            .compactMap { _ in }
    }
}

// MARK: Payload

public extension RFNotification.IsolatedNotification where Payload : Sendable {
    @inlinable @MainActor
    func send(payload: P, object: Any? = nil) {
        NotificationCenter.default.post(name: name, object: object, userInfo: [
            RFNotificationPayloadKey: payload,
        ])
    }
    @inlinable
    func send(payload: P, object: Sendable? = nil) async {
        await MainActor.run {
            send(payload: payload, object: object)
        }
    }
    @inlinable
    func dispatch(payload: P, object: Sendable? = nil) {
        Task { @MainActor in
            send(payload: payload, object: object)
        }
    }
}
public extension RFNotification.NonIsolatedNotification where Payload : Sendable {
    @inlinable
    func send(payload: P, object: Any? = nil) {
        NotificationCenter.default.post(name: name, object: object, userInfo: [
            RFNotificationPayloadKey: payload,
        ])
    }
}

public extension RFNotification.Notification where Payload : Sendable {
    @inlinable @discardableResult
    func subscribe(object: Any? = nil, queue: RFNotification.RFOperationQueue, using handler: @escaping @Sendable (Payload) -> Void) -> RFNotification.Marker {
        let token = NotificationCenter.default.addObserver(forName: name, object: object, queue: queue.operationQueue) {
            guard let payload = $0.userInfo?[RFNotificationPayloadKey] as? Payload else {
                return
            }
            
            handler(payload)
        }
        
        return .init(token: token)
    }
    
    @inlinable @discardableResult
    func subscribe(object: Any? = nil, @_inheritActorContext using handler: @Sendable @escaping (Payload) async -> Void) -> RFNotification.Marker {
        let token = NotificationCenter.default.addObserver(forName: name, object: object, queue: .main) {
            guard let payload = $0.userInfo?[RFNotificationPayloadKey] as? Payload else {
                return
            }
            
            Task {
                await handler(payload)
            }
        }
        
        return .init(token: token)
    }
    
    @inlinable
    func publisher(object: AnyObject? = nil) -> some Publisher<Payload, Never> {
        NotificationCenter.default.publisher(for: name, object: object)
            .compactMap {
                guard let payload = $0.userInfo?[RFNotificationPayloadKey] as? Payload else {
                    return nil
                }
                
                return payload
            }
    }
}
