//
//  RFNotification+Test.swift
//  RFKit
//
//  Created by Rasmus Krämer on 15.12.24.
//

import Foundation
import RFNotifications

extension RFNotification.NonIsolatedNotification {
    static var test: NonIsolatedNotification<RFNotificationEmptyPayload> { .init("io.rfk.RFKit.test.\(UUID())") }
    static var testPayload: NonIsolatedNotification<UUID> { .init("io.rfk.RFKit.testPayload.\(UUID())") }
    static var testActor: NonIsolatedNotification<RFNotificationEmptyPayload> { .init("io.rfk.RFKit.testActor.\(UUID())") }
}
extension RFNotification.IsolatedNotification {
    static var testMainActor: IsolatedNotification<RFNotificationEmptyPayload> { .init("io.rfk.RFKit.testMainActor.\(UUID())") }
}
