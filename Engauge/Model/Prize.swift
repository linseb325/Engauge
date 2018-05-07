//
//  Prize.swift
//  Engauge
//
//  Created by Brennan Linse on 5/5/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//

import Foundation

struct Prize {
    var prizeID: String
    var name: String
    var price: Int
    var quantityAvailable: Int
    var description: String
    var imageURL: String
    var schoolID: String
    
    // Constants
    static var minPrice = 1
    static var maxPrice = Int.max
    
    static var minQuantity = 0
    static var maxQuantity = Int.max
}
