//
//  CounterStore.swift
//  MultiCounter
//
//  앱 화면이 보는 카운터 상태. 바뀔 때마다 위젯·제어 센터·워치에 알림
//

import SwiftUI
import WidgetKit

@Observable
@MainActor
final class CounterStore {
  static let shared = CounterStore()

  var counters: [CountModel] = []
  private(set) var isPro: Bool = false
  private(set) var isLegacyUser: Bool = false

  var canAddCounter: Bool {
    counters.count < SharedStorage.counterLimit
  }

  private init() {
    SharedStorage.migrateIfNeeded()
    reload()
  }

  /// 위젯·제어 센터·워치가 바꾼 값을 다시 읽음
  func reload() {
    counters = SharedStorage.loadCounters()
    isPro = SharedStorage.isPro
    isLegacyUser = SharedStorage.isLegacyUser
  }

  func apply(_ mode: CountMode, to id: UUID) {
    guard let updated = SharedStorage.apply(mode, to: id),
          let index = counters.firstIndex(where: { $0.id == id }) else { return }
    counters[index] = updated
    notifyChange()
  }

  /// 색상·레이블처럼 화면에서 직접 바꾼 값을 저장
  func save() {
    SharedStorage.saveCounters(counters)
    notifyChange()
  }

  @discardableResult
  func addCounter() -> CountModel? {
    guard canAddCounter else { return nil }
    let counter = CountModel()
    counters.append(counter)
    save()
    return counter
  }

  func deleteCounter(id: UUID) {
    // 카운터가 하나도 없는 상태는 만들지 않음
    guard counters.count > 1 else { return }
    counters.removeAll { $0.id == id }
    save()
  }

  func setPro(_ value: Bool) {
    guard SharedStorage.isPro != value || isPro != value else { return }
    SharedStorage.isPro = value
    isPro = value
    notifyChange()
  }

  func markLegacyUser() {
    guard !SharedStorage.isLegacyUser else { return }
    SharedStorage.isLegacyUser = true
    isLegacyUser = true
  }

  private func notifyChange() {
    WidgetCenter.shared.reloadAllTimelines()
    if #available(iOS 18.0, *) {
      ControlCenter.shared.reloadAllControls()
    }
    WatchSync.shared.push(counters: counters, isPro: isPro)
  }
}
