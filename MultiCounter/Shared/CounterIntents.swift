//
//  CounterIntents.swift
//  MultiCounter
//
//  앱을 열지 않고 위젯·잠금화면·제어 센터에서 카운트하기 위한 App Intent
//

import AppIntents
import WidgetKit

// MARK: - 카운터 선택

struct CounterEntity: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Counter"
  static var defaultQuery = CounterQuery()

  var id: UUID
  /// 레이블이 없을 때 구분용으로 쓰는 페이지 번호 (1부터)
  var number: Int
  var label: String
  var value: Int

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: "\(label.isEmpty ? "\(number)" : label)",
      subtitle: "\(value)"
    )
  }

  static func all() -> [CounterEntity] {
    SharedStorage.loadCounters().enumerated().map { index, counter in
      CounterEntity(id: counter.id, number: index + 1, label: counter.label, value: counter.value)
    }
  }
}

struct CounterQuery: EntityQuery {
  func entities(for identifiers: [UUID]) async throws -> [CounterEntity] {
    CounterEntity.all().filter { identifiers.contains($0.id) }
  }

  func suggestedEntities() async throws -> [CounterEntity] {
    CounterEntity.all()
  }

  func defaultResult() async -> CounterEntity? {
    CounterEntity.all().first
  }
}

struct SelectCounterIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Counter"

  @Parameter(title: "Counter")
  var counter: CounterEntity?
}

@available(iOS 18.0, *)
struct SelectCounterControlIntent: ControlConfigurationIntent {
  static var title: LocalizedStringResource = "Counter"

  @Parameter(title: "Counter")
  var counter: CounterEntity?
}

// MARK: - 카운트

struct CountIntent: AppIntent {
  static var title: LocalizedStringResource = "Count"
  static var isDiscoverable = false

  @Parameter(title: "Counter")
  var counterID: String

  @Parameter(title: "Mode")
  var modeRawValue: String

  init() {}

  init(counterID: UUID, mode: CountMode) {
    self.counterID = counterID.uuidString
    self.modeRawValue = mode.rawValue
  }

  func perform() async throws -> some IntentResult {
    // 앱 밖에서 카운트하는 기능은 Pro 전용.
    // 확장에서는 앱을 직접 열 수 없으므로, 다음에 앱을 열 때 Pro 안내를 보여줌
    guard SharedStorage.isPro else {
      SharedStorage.requestPaywall()
      return .result()
    }
    guard let id = UUID(uuidString: counterID),
          let mode = CountMode(rawValue: modeRawValue) else {
      return .result()
    }
    SharedStorage.apply(mode, to: id)
    WidgetCenter.shared.reloadAllTimelines()
    if #available(iOS 18.0, *) {
      ControlCenter.shared.reloadAllControls()
    }
    return .result()
  }
}
