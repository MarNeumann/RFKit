//
//  Basic.swift
//  RFKit
//
//  Created by Rasmus Krämer on 15.12.24.
//

import Foundation
import Testing
import RFNotifications


@Suite
struct TestSuite {
    var stash = RFNotification.MarkerStash()
    
    @Test
    mutating func emptyPayload() async {
        let notification = RFNotification[.test]
        
        await confirmation { didPost in
            notification.subscribe {
                didPost()
            }.store(in: &stash)
            
            notification.send()
            
            try? await Task.sleep(for: .seconds(1))
        }
    }
    
    @Test mutating func payload() async {
        let notification = RFNotification[.testPayload]
        let payload = UUID()
        
        await confirmation { didPost in
            notification.subscribe {
                if $0 == payload {
                    didPost()
                }
            }.store(in: &stash)
            
            notification.send(payload: payload)
            
            try? await Task.sleep(for: .seconds(1))
        }
    }
    
    @Test mutating func retention() async {
        let notification = RFNotification[.test]
        
        await confirmation { didPost in
            notification.subscribe {
                didPost()
            }.store(in: &stash)
            
            let marker: RFNotification.Marker? = notification.subscribe {
                didPost()
            }
            marker?()
            
            notification.send()
            
            try? await Task.sleep(for: .seconds(1))
        }
    }
}
