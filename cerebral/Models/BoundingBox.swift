//
//  BoundingBox.swift
//  cerebral
//
//  Created on 27/11/2024.
//

import SwiftData
import Foundation

@Model
final class BoundingBox: @unchecked Sendable {
    var left: Double
    var top: Double
    var right: Double
    var bottom: Double
    var pageNumber: Int
    var coordOrigin: String = "BOTTOMLEFT"
    
    // Computed properties for convenience
    var width: Double { right - left }
    var height: Double { top - bottom }
    
    init(left: Double, top: Double, right: Double, bottom: Double, pageNumber: Int, coordOrigin: String = "BOTTOMLEFT") {
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
        self.pageNumber = pageNumber
        self.coordOrigin = coordOrigin
    }
    
    // Convenience initializer for API response
    convenience init(from apiResponse: BoundingBoxResponse, pageNumber: Int) {
        self.init(
            left: apiResponse.l,
            top: apiResponse.t,
            right: apiResponse.right,
            bottom: apiResponse.bottom,
            pageNumber: pageNumber,
            coordOrigin: apiResponse.coordOrigin ?? "BOTTOMLEFT"
        )
    }
} 