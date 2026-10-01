//
//  MultiCounterWatchApp.swift
//  MultiCounterWatch
//

import SwiftUI

@main
struct MultiCounterWatchApp: App {
  init() {
    WatchConnector.shared.activate()
  }

  var body: some Scene {
    WindowGroup {
      WatchContentView()
    }
  }
}
