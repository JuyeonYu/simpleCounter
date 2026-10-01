//
//  WatchStore.swift
//  MultiCounterWatch
//
//  워치 쪽 상태. 아이폰이 보낸 상태를 보여주고, 카운트는 아이폰으로 보냄
//

import SwiftUI
import WatchConnectivity
import WatchKit

@Observable
@MainActor
final class WatchStore {
  static let shared = WatchStore()

  private(set) var counters: [CountModel] = []
  private(set) var isPro = false

  private let countersKey = "WatchCounters"
  private let isProKey = "WatchIsPro"

  private init() {
    // 아이폰과 연결되기 전에도 마지막 상태를 보여줌
    if let data = UserDefaults.standard.data(forKey: countersKey),
       let saved = try? JSONDecoder().decode([CountModel].self, from: data) {
      counters = saved
    }
    isPro = UserDefaults.standard.bool(forKey: isProKey)
  }

  func apply(_ mode: CountMode, to id: UUID) {
    guard isPro, let index = counters.firstIndex(where: { $0.id == id }) else { return }
    WKInterfaceDevice.current().play(.click)
    // 화면에는 바로 반영하고, 실제 값은 아이폰이 처리한 뒤 다시 보내줌
    counters[index].apply(mode)
    persist()
    WatchConnector.shared.send(WatchMessage.action(id: id, mode: mode))
  }

  func update(from context: [String: Any]) {
    if let received = WatchMessage.counters(from: context) {
      counters = received
    }
    if let receivedIsPro = context[WatchMessage.isProKey] as? Bool {
      isPro = receivedIsPro
    }
    persist()
  }

  private func persist() {
    if let data = try? JSONEncoder().encode(counters) {
      UserDefaults.standard.set(data, forKey: countersKey)
    }
    UserDefaults.standard.set(isPro, forKey: isProKey)
  }
}

final class WatchConnector: NSObject, WCSessionDelegate {
  static let shared = WatchConnector()

  func activate() {
    guard WCSession.isSupported() else { return }
    WCSession.default.delegate = self
    WCSession.default.activate()
  }

  func send(_ action: [String: Any]) {
    let session = WCSession.default
    guard session.activationState == .activated else { return }
    guard session.isReachable else {
      // 아이폰과 바로 연결되지 않으면 큐에 넣어 나중에 순서대로 전달
      session.transferUserInfo(action)
      return
    }
    // 연결돼 있으면 즉시 전달하고, 실패하면 큐로 다시 보냄
    session.sendMessage(action, replyHandler: nil) { _ in
      session.transferUserInfo(action)
    }
  }

  // MARK: - WCSessionDelegate

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    let context = session.receivedApplicationContext
    guard !context.isEmpty else { return }
    Task { @MainActor in
      WatchStore.shared.update(from: context)
    }
  }

  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    Task { @MainActor in
      WatchStore.shared.update(from: applicationContext)
    }
  }
}
