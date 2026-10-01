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

  /// WCAG 상대 휘도 (0 = 검정, 1 = 흰색)
  var relativeLuminance: Double {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

    func linear(_ value: CGFloat) -> Double {
      let c = Double(min(max(value, 0), 1))
      return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
  }

  func contrastRatio(with other: Color) -> Double {
    let a = relativeLuminance
    let b = other.relativeLuminance
    return (max(a, b) + 0.05) / (min(a, b) + 0.05)
  }

  /// 배경 위에서 잘 보이면 이 색을, 아니면 대체 색을, 그것도 아니면 흰색·검정 중 잘 보이는 색을 반환
  func readable(on background: Color, fallback: Color) -> Color {
    // 아이콘 같은 비텍스트 요소의 최소 대비 기준 (WCAG 1.4.11)
    let minimumContrast = 3.0
    if contrastRatio(with: background) >= minimumContrast { return self }
    if fallback.contrastRatio(with: background) >= minimumContrast { return fallback }
    return Color.white.contrastRatio(with: background) >= Color.black.contrastRatio(with: background) ? .white : .black
  }
}
