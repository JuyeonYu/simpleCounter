//
//  MultiCounterApp.swift
//  MultiCounter
//
//  Created by  유 주연 on 8/25/24.
//

import SwiftUI

@main
struct MultiCounterApp: App {
  init() {
    WatchSync.shared.activate()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
