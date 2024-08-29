//
//  extensions.swift
//  MultiCounter
//
//  Created by  유 주연 on 8/29/24.
//

import Foundation

import SwiftUI

extension Color {
  init?(hex: String) {
    let r, g, b: CGFloat
    var hexColor = hex
    
    if hexColor.hasPrefix("#") {
      hexColor.remove(at: hexColor.startIndex)
    }
    
    guard hexColor.count == 6,
          let hexNumber = Int(hexColor, radix: 16) else {
      return nil
    }
    
    r = CGFloat((hexNumber >> 16) & 0xFF) / 255
    g = CGFloat((hexNumber >> 8) & 0xFF) / 255
    b = CGFloat(hexNumber & 0xFF) / 255
    
    self.init(red: r, green: g, blue: b)
  }
  
  func toHex() -> String? {
    let uiColor = UIColor(self)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    
    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    
    let r = Int(red * 255)
    let g = Int(green * 255)
    let b = Int(blue * 255)
    
    return String(format: "#%02X%02X%02X", r, g, b)
  }
}
