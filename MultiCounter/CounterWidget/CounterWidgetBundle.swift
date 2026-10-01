//
//  CounterWidgetBundle.swift
//  CounterWidget
//

import SwiftUI
import WidgetKit

@main
struct CounterWidgetBundle: WidgetBundle {
  var body: some Widget {
    CounterWidget()
    if #available(iOS 18.0, *) {
      CounterControl()
    }
  }
}
