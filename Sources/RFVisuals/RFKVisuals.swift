//
//  RFKVisuals.swift
//  RFKit
//
//  Created by Rasmus Krämer on 26.08.24.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct RFKVisuals: Sendable {
    #if canImport(UIKit)
    public typealias PlatformImage = UIImage
    public typealias PlatformColor = UIColor
    #elseif canImport(AppKit)
    public typealias PlatformImage = NSImage
    public typealias PlatformColor = NSColor
    #endif
    
    enum VisualError: Error {
        case fetchFailed
    }
}
