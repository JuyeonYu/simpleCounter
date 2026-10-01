//
//  extensions.swift
//  MultiCounter
//
//  Created by  유 주연 on 8/29/24.
//

import Foundation

import SwiftUI

extension Color {
  var opposite: Color {
    let uiColor = UIColor(self)
    
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    
    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    
    return Color(red: 1.0 - red, green: 1.0 - green, blue: 1.0 - blue, opacity: alpha)
  }
  
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

    // Display P3 등 넓은 색역의 색은 0~1 범위를 벗어나므로 잘라낸 뒤 반올림
    func toByte(_ value: CGFloat) -> Int {
      Int((min(max(value, 0), 1) * 255).rounded())
    }
    let r = toByte(red)
    let g = toByte(green)
    let b = toByte(blue)
    
    return String(format: "#%02X%02X%02X", r, g, b)
  }
}
