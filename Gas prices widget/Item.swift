//
//  Item.swift
//  Gas prices widget
//
//  Created by Max Max on 24.10.2024.
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
