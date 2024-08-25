//
//  Item.swift
//  MultiCounter
//
//  Created by  유 주연 on 8/25/24.
//

import Foundation
import SwiftData
import SwiftUI

enum CountMode: String, CaseIterable, Codable  {
  case plus
  case minus
  case reset
  
  func next() -> CountMode {
      let allModes = CountMode.allCases
      if let currentIndex = allModes.firstIndex(of: self) {
          let nextIndex = (currentIndex + 1) % allModes.count
          return allModes[nextIndex]
      }
      return self
  }

}

@Model
class CountState {
    var count: Int
    
    var modeRawValue: String
    var header: String
    
//    var backgroundColor: Color
//    var foregroundColor: Color
    var mode: CountMode {
        get {
            CountMode(rawValue: modeRawValue) ?? .plus
        }
        set {
            modeRawValue = newValue.rawValue
        }
    }

    // Initializer
    init(count: Int = 0, mode: CountMode = .plus, header: String = "", backgroundColor: Color = .gray, foregroundColor: Color = .white) {
        self.count = count
        self.modeRawValue = mode.rawValue
        self.header = header
//        self.backgroundColor = backgroundColor
//        self.foregroundColor = foregroundColor
    }
}
