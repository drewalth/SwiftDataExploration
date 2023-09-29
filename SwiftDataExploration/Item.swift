//
//  Item.swift
//  SwiftDataExploration
//
//  Created by Andrew Althage on 9/29/23.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
