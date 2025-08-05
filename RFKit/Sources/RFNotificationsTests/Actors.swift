//
//  Actors.swift
//  RFKit
//
//  Created by Rasmus Krämer on 25.04.25.
//

import Testing
import Foundation
import RFNotifications

actor Actors {
    var someID = UUID()
    
    @Test func currentToCurrent() async {
        let notification = RFNotification[.testActor]
        
        await confirmation { didPost in
            notification.subscribe {
                let _ = self.someID
                didPost()
            }
            
            notification.send()
            
            try? await Task.sleep(for: .seconds(1))
        }
    }
    @Test func mainToCurrent() async {
        let notification = RFNotification[.testMainActor]
        
        await confirmation { didPost in
            notification.subscribe {
                let _ = self.someID
                didPost()
            }
            
            await MainActor.run {
                notification.send()
            }
            
            try? await Task.sleep(for: .seconds(1))
        }
    }
}
