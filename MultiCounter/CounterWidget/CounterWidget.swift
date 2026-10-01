//
//  CounterWidget.swift
//  CounterWidget
//
//  홈 화면·잠금화면에서 앱을 열지 않고 카운트
//

import AppIntents
import SwiftUI
import WidgetKit

struct CounterEntry: TimelineEntry {
  let date: Date
  let counter: CountModel?
  let isPro: Bool
}

struct CounterProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> CounterEntry {
    CounterEntry(date: .now, counter: CountModel(value: 7), isPro: true)
  }

  func snapshot(for configuration: SelectCounterIntent, in context: Context) async -> CounterEntry {
    entry(for: configuration)
  }

  func timeline(for configuration: SelectCounterIntent, in context: Context) async -> Timeline<CounterEntry> {
    // 값은 카운트할 때마다 갱신을 요청하므로 주기적으로 다시 그릴 필요 없음
    Timeline(entries: [entry(for: configuration)], policy: .never)
  }

  private func entry(for configuration: SelectCounterIntent) -> CounterEntry {
    let counters = SharedStorage.loadCounters()
    let selected = counters.first { $0.id == configuration.counter?.id } ?? counters.first
    return CounterEntry(date: .now, counter: selected, isPro: SharedStorage.isPro)
  }
}

struct CounterWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: CounterEntry

  var body: some View {
    Group {
      if let counter = entry.counter {
        if entry.isPro {
          content(for: counter)
        } else {
          locked(for: counter)
            .widgetURL(URL(string: "count://pro"))
        }
      } else {
        Image(systemName: "plus.circle")
          .font(.title)
      }
    }
    .containerBackground(for: .widget) {
      if let counter = entry.counter {
        counter.backgroundColor
      } else {
        Color.black
      }
    }
  }

  @ViewBuilder
  private func content(for counter: CountModel) -> some View {
    switch family {
    case .systemMedium:
      HStack(spacing: 0) {
        countButton(counter, mode: .minus, symbol: "minus.circle")
        valueStack(counter)
          .frame(maxWidth: .infinity)
        countButton(counter, mode: .plus, symbol: "plus.circle")
      }
    case .accessoryCircular:
      Button(intent: CountIntent(counterID: counter.id, mode: .plus)) {
        ZStack {
          AccessoryWidgetBackground()
          Text("\(counter.value)")
            .font(.system(size: 24, weight: .semibold))
            .minimumScaleFactor(0.4)
            .padding(4)
        }
      }
      .buttonStyle(.plain)
    case .accessoryRectangular:
      Button(intent: CountIntent(counterID: counter.id, mode: .plus)) {
        HStack {
          VStack(alignment: .leading, spacing: 0) {
            if !counter.label.isEmpty {
              Text(counter.label)
                .font(.headline)
                .lineLimit(1)
            }
            Text("\(counter.value)")
              .font(.system(size: 32, weight: .semibold))
              .minimumScaleFactor(0.5)
          }
          Spacer(minLength: 0)
          Image(systemName: "plus.circle")
            .font(.title2)
        }
      }
      .buttonStyle(.plain)
    case .accessoryInline:
      Text(counter.label.isEmpty ? "\(counter.value)" : "\(counter.label) \(counter.value)")
    default:
      Button(intent: CountIntent(counterID: counter.id, mode: .plus)) {
        valueStack(counter)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
  }

  private func valueStack(_ counter: CountModel) -> some View {
    VStack(spacing: 2) {
      if !counter.label.isEmpty {
        Text(counter.label)
          .font(.system(size: 15, weight: .medium))
          .lineLimit(1)
      }
      Text("\(counter.value)")
        .font(.system(size: 64, weight: .regular))
        .lineLimit(1)
        .minimumScaleFactor(0.3)
        .contentTransition(.numericText(value: Double(counter.value)))
    }
    .foregroundStyle(counter.foregroundColor)
  }

  private func countButton(_ counter: CountModel, mode: CountMode, symbol: String) -> some View {
    Button(intent: CountIntent(counterID: counter.id, mode: mode)) {
      Image(systemName: symbol)
        .font(.system(size: 36))
        .foregroundStyle(counter.foregroundColor)
        .frame(maxHeight: .infinity)
        .frame(width: 64)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  /// Pro가 아니면 값만 보여주고, 누르면 앱의 Pro 안내로 이동
  @ViewBuilder
  private func locked(for counter: CountModel) -> some View {
    switch family {
    case .accessoryCircular, .accessoryRectangular, .accessoryInline:
      Image(systemName: "lock.fill")
    default:
      valueStack(counter)
        .overlay(alignment: .topTrailing) {
          Image(systemName: "lock.fill")
            .font(.caption)
            .foregroundStyle(counter.foregroundColor.opacity(0.6))
        }
    }
  }
}

struct CounterWidget: Widget {
  let kind = "CounterWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: SelectCounterIntent.self, provider: CounterProvider()) { entry in
      CounterWidgetView(entry: entry)
    }
    .configurationDisplayName("Count")
    .supportedFamilies([
      .systemSmall,
      .systemMedium,
      .accessoryCircular,
      .accessoryRectangular,
      .accessoryInline,
    ])
  }
}

#Preview(as: .systemSmall) {
  CounterWidget()
} timeline: {
  CounterEntry(date: .now, counter: CountModel(value: 12, label: "Water"), isPro: true)
}
