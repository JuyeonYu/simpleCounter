//
//  SharedStorage.swift
//  MultiCounter
//
//  앱과 위젯·제어 센터가 같은 데이터를 보도록 App Group 저장소에 저장
//

import Foundation

enum SharedStorage {
  static let appGroupID = "group.com.chaechae.count"
  static let defaults = UserDefaults(suiteName: appGroupID) ?? .standard

  static let freeCounterLimit = 3
  // 유료화 이전부터 쓰던 사용자는 원래 쓰던 10개를 그대로 유지
  static let legacyCounterLimit = 10

  private static let countersKey = "CountModels"
  private static let isProKey = "IsPro"
  private static let isLegacyUserKey = "IsLegacyUser"

  // MARK: - 카운터

  static func loadCounters() -> [CountModel] {
    guard let data = defaults.data(forKey: countersKey),
          let counters = try? JSONDecoder().decode([CountModel].self, from: data) else {
      return []
    }
    return counters
  }

  static func saveCounters(_ counters: [CountModel]) {
    guard let data = try? JSONEncoder().encode(counters) else { return }
    defaults.set(data, forKey: countersKey)
  }

  /// 저장소에서 최신 값을 읽어 한 카운터에만 적용 (다른 프로세스가 바꾼 값을 덮어쓰지 않도록)
  @discardableResult
  static func apply(_ mode: CountMode, to id: UUID) -> CountModel? {
    var counters = loadCounters()
    guard let index = counters.firstIndex(where: { $0.id == id }) else { return nil }
    counters[index].apply(mode)
    saveCounters(counters)
    return counters[index]
  }

  /// 처음 실행 시 기존 앱 저장소의 데이터를 공유 저장소로 옮김
  static func migrateIfNeeded() {
    guard defaults.data(forKey: countersKey) == nil else { return }

    if let legacyData = UserDefaults.standard.data(forKey: countersKey),
       let legacyCounters = try? JSONDecoder().decode([CountModel].self, from: legacyData),
       !legacyCounters.isEmpty {
      saveCounters(legacyCounters)
      isLegacyUser = true
    } else {
      saveCounters((0..<freeCounterLimit).map { _ in CountModel() })
    }
  }

  // MARK: - Pro

  /// 앱이 StoreKit으로 확인한 결과를 위젯·제어 센터도 볼 수 있게 저장
  static var isPro: Bool {
    get { defaults.bool(forKey: isProKey) }
    set { defaults.set(newValue, forKey: isProKey) }
  }

  static var isLegacyUser: Bool {
    get { defaults.bool(forKey: isLegacyUserKey) }
    set { defaults.set(newValue, forKey: isLegacyUserKey) }
  }

  static var counterLimit: Int {
    if isPro { return .max }
    return isLegacyUser ? legacyCounterLimit : freeCounterLimit
  }

  // MARK: - Pro 안내

  private static let pendingPaywallKey = "PendingPaywall"

  /// 제어 센터처럼 URL로 앱을 열 수 없는 곳에서 Pro 안내를 요청할 때 사용
  static func requestPaywall() {
    defaults.set(true, forKey: pendingPaywallKey)
  }

  static func consumePendingPaywall() -> Bool {
    guard defaults.bool(forKey: pendingPaywallKey) else { return false }
    defaults.removeObject(forKey: pendingPaywallKey)
    return true
  }
}
