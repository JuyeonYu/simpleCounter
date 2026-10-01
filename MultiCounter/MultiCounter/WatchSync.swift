//
//  WatchSync.swift
//  MultiCounter
//
//  아이폰 쪽 워치 동기화. 상태는 아이폰이 기준이고, 워치는 동작만 보냄
//

import WatchConnectivity

final class WatchSync: NSObject, WCSessionDelegate {
  static let shared = WatchSync()

  func activate() {
    guard WCSession.isSupported() else { return }
    WCSession.default.delegate = self
    WCSession.default.activate()
  }

  func push(counters: [CountModel], isPro: Bool) {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    guard session.activationState == .activated,
          session.isPaired,
          session.isWatchAppInstalled else { return }
    try? session.updateApplicationContext(WatchMessage.context(counters: counters, isPro: isPro))
  }

  // MARK: - WCSessionDelegate

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    guard activationState == .activated else { return }
    Task { @MainActor in
      let store = CounterStore.shared
      self.push(counters: store.counters, isPro: store.isPro)
    }
  }

  /// 워치 앱을 나중에 설치하거나 다른 워치로 바꿨을 때도 바로 최신 상태를 보냄
  func sessionWatchStateDidChange(_ session: WCSession) {
    Task { @MainActor in
      let store = CounterStore.shared
      self.push(counters: store.counters, isPro: store.isPro)
    }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {}

  func sessionDidDeactivate(_ session: WCSession) {
    // 워치를 바꾼 경우 새 워치와 다시 연결
    session.activate()
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    handle(userInfo)
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    handle(message)
  }

  private func handle(_ payload: [String: Any]) {
    guard let action = WatchMessage.action(from: payload) else { return }
    Task { @MainActor in
      let store = CounterStore.shared
      // 워치 기능은 Pro 전용
      guard store.isPro else { return }
      store.apply(action.mode, to: action.id)
    }
  }
}
