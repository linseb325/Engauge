//
//  Protocols.swift
//  Engauge
//
//  Created by Brennan Linse on 5/17/18.
//  Copyright © 2018 Brennan Linse. All rights reserved.
//
//  PURPOSE: Define a protocol for types that can implement a blurring effect.

import Foundation
import UIKit

/**
 Methods for adding and removing a blur effect.
 */
protocol Blurrable {
    func addBlur(withStyle blurStyle: UIBlurEffectStyle)
    func removeBlurIfNecessary()
}
