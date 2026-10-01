//
//  WatchContentView.swift
//  MultiCounterWatch
//

import SwiftUI

struct WatchContentView: View {
  @State private var store = WatchStore.shared
  @State private var mode: CountMode = .plus

  var body: some View {
    if !store.isPro {
      // Pro는 아이폰에서 구매
      VStack(spacing: 12) {
        Image(systemName: "crown.fill")
          .font(.system(size: 40))
          .foregroundStyle(.yellow)
        Image(systemName: "iphone")
          .font(.system(size: 28))
          .foregroundStyle(.secondary)
      }
    } else if store.counters.isEmpty {
      Image(systemName: "iphone")
        .font(.system(size: 36))
        .foregroundStyle(.secondary)
    } else {
      TabView {
        ForEach(store.counters) { counter in
          page(for: counter)
        }
      }
      .tabViewStyle(.verticalPage)
    }
  }

  private func page(for counter: CountModel) -> some View {
    ZStack {
      counter.backgroundColor
        .ignoresSafeArea()

      VStack(spacing: 2) {
        Button {
          mode = mode.next()
        } label: {
          Image(systemName: modeSymbol)
            .font(.system(size: 26))
            .foregroundStyle(modeColor(for: counter))
            .frame(width: 44, height: 36)
        }
        .buttonStyle(.plain)

        if !counter.label.isEmpty {
          Text(counter.label)
            .font(.system(size: 15, weight: .medium))
            .lineLimit(1)
            .foregroundStyle(counter.foregroundColor)
        }

        Text("\(counter.value)")
          .font(.system(size: 80))
          .lineLimit(1)
          .minimumScaleFactor(0.3)
          .foregroundStyle(counter.foregroundColor)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .contentShape(Rectangle())
          .onTapGesture {
            store.apply(mode, to: counter.id)
          }
      }
    }
  }

  private var modeSymbol: String {
    switch mode {
    case .plus: "plus.circle"
    case .minus: "minus.circle"
    case .reset: "arrow.clockwise.circle"
    }
  }

  private func modeColor(for counter: CountModel) -> Color {
    switch mode {
    case .plus: .red
    case .minus: .blue
    case .reset: counter.backgroundColor.opposite
    }
  }
}

#Preview {
  WatchContentView()
}
