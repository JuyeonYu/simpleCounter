//
//  CounterControl.swift
//  CounterWidget
//
//  제어 센터·잠금화면 버튼 (iOS 18 이상)
//

import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct CounterControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    AppIntentControlConfiguration(
      kind: "com.chaechae.count.CounterControl",
      provider: CounterControlProvider()
    ) { value in
      // Pro가 아니면 자물쇠를 보여주고, 누르면 앱에서 Pro 안내를 띄움 (CountIntent에서 처리)
      ControlWidgetButton(action: CountIntent(counterID: value.counterID ?? UUID(), mode: .plus)) {
        Label {
          Text(value.title)
          Text("\(value.count)")
        } icon: {
          Image(systemName: value.isPro ? "plus.circle" : "lock.fill")
        }
      }
    }
    .displayName("Count")
  }
}

@available(iOS 18.0, *)
struct CounterControlProvider: AppIntentControlValueProvider {
  struct Value {
    var counterID: UUID?
    var title: String
    var count: Int
    var isPro: Bool
  }

  func previewValue(configuration: SelectCounterControlIntent) -> Value {
    Value(counterID: nil, title: "Count", count: 0, isPro: true)
  }

  func currentValue(configuration: SelectCounterControlIntent) async throws -> Value {
    let counters = SharedStorage.loadCounters()
    let index = counters.firstIndex { $0.id == configuration.counter?.id } ?? (counters.isEmpty ? nil : 0)
    guard let index else {
      return Value(counterID: nil, title: "Count", count: 0, isPro: SharedStorage.isPro)
    }
    let counter = counters[index]
    return Value(
      counterID: counter.id,
      title: counter.label.isEmpty ? "\(index + 1)" : counter.label,
      count: counter.value,
      isPro: SharedStorage.isPro
    )
  }
}
