//
//  CountModel.swift
//  MultiCounter
//
//  앱·위젯·워치가 함께 쓰는 카운터 모델
//

import SwiftUI

struct CountModel: Codable, Identifiable, Hashable {
  var id: UUID = UUID()
  var value: Int = 0
  var backgroundColorHex: String = "000000"
  var foregroundColorHex: String = "ffffff"
  var label: String = ""

  var backgroundColor: Color {
    get {
      Color(hex: backgroundColorHex) ?? .black
    }
    set {
      backgroundColorHex = newValue.toHex() ?? ""
    }
  }
  var foregroundColor: Color {
    get {
      Color(hex: foregroundColorHex) ?? .white
    }
    set {
      foregroundColorHex = newValue.toHex() ?? ""
    }
  }

  mutating func apply(_ mode: CountMode) {
    switch mode {
    case .plus:
      value += 1
    case .minus:
      value -= 1
    case .reset:
      value = 0
    }
  }
}

extension CountModel {
  // 이전 버전에 저장된 데이터에는 없는 필드가 있어도 읽을 수 있도록 기본값으로 디코딩
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
    value = try container.decodeIfPresent(Int.self, forKey: .value) ?? 0
    backgroundColorHex = try container.decodeIfPresent(String.self, forKey: .backgroundColorHex) ?? "000000"
    foregroundColorHex = try container.decodeIfPresent(String.self, forKey: .foregroundColorHex) ?? "ffffff"
    label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
  }
}

enum CountMode: String, CaseIterable, Codable {
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
