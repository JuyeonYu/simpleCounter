//
//  WatchMessage.swift
//  MultiCounter
//
//  아이폰과 워치가 WatchConnectivity로 주고받는 데이터 형식
//

import Foundation

enum WatchMessage {
  // 아이폰 → 워치: 전체 상태 (applicationContext)
  static let countersKey = "counters"
  static let isProKey = "isPro"

  // 워치 → 아이폰: 카운터 하나에 대한 동작 (userInfo)
  static let counterIDKey = "counterID"
  static let modeKey = "mode"

  static func context(counters: [CountModel], isPro: Bool) -> [String: Any] {
    [
      countersKey: (try? JSONEncoder().encode(counters)) ?? Data(),
      isProKey: isPro,
    ]
  }

  static func counters(from context: [String: Any]) -> [CountModel]? {
    guard let data = context[countersKey] as? Data else { return nil }
    return try? JSONDecoder().decode([CountModel].self, from: data)
  }

  static func action(id: UUID, mode: CountMode) -> [String: Any] {
    [counterIDKey: id.uuidString, modeKey: mode.rawValue]
  }

  static func action(from userInfo: [String: Any]) -> (id: UUID, mode: CountMode)? {
    guard let idString = userInfo[counterIDKey] as? String,
          let id = UUID(uuidString: idString),
          let modeString = userInfo[modeKey] as? String,
          let mode = CountMode(rawValue: modeString) else { return nil }
    return (id, mode)
  }
}
