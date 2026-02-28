//
//  Item.swift
//  spoken englist
//
//  Created by levi on 2026/2/28.
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
