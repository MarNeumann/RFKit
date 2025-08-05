//
//  Color+Contrast.swift
//  RFKit
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import SwiftUI

// https://stackoverflow.com/questions/42355778/how-to-compute-color-contrast-ratio-between-two-uicolor-instances

internal extension Color {
    func luminance() -> CGFloat {
        #if os(macOS)
        let ciColor = CIColor(color: RFKVisuals.PlatformColor(self))!
        #else
        let ciColor = CIColor(color: RFKVisuals.PlatformColor(self))
        #endif
        return 0.2126 * adjust(colorComponent: ciColor.red) + 0.7152 * adjust(colorComponent: ciColor.green) + 0.0722 * adjust(colorComponent: ciColor.blue)
    }
    func adjust(colorComponent: CGFloat) -> CGFloat {
        (colorComponent < 0.04045) ? (colorComponent / 12.92) : pow((colorComponent + 0.055) / 1.055, 2.4)
    }
    
    func contrastRatio(with other: Color) -> CGFloat {
        let lhsLuminance = self.luminance()
        let rhsLuminance = other.luminance()
        
        let darker = min(lhsLuminance, rhsLuminance)
        let lighter = max(lhsLuminance, rhsLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
}
