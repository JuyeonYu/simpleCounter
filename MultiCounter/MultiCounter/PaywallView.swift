//
//  PaywallView.swift
//  MultiCounter
//
//  글자 대신 아이콘으로 Pro 기능을 보여주는 구매 화면
//

import SwiftUI

struct PaywallView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var store = CounterStore.shared
  @State private var proStore = ProStore.shared

  // 잠금화면 · 위젯 · 제어 센터 · 애플워치 · 카운터 여러 개
  private let features = [
    "lock.iphone",
    "widget.small",
    "switch.2",
    "applewatch",
    "plus.rectangle.on.rectangle",
  ]

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Spacer()
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 30))
            .foregroundStyle(.white.opacity(0.4))
        }
        .accessibilityLabel("Close")
      }

      Spacer()

      Image(systemName: "crown.fill")
        .font(.system(size: 80))
        .foregroundStyle(.yellow)
        .padding(.bottom, 48)

      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 36) {
        ForEach(features, id: \.self) { symbol in
          Image(systemName: symbol)
            .font(.system(size: 40))
            .foregroundStyle(.white)
            .frame(height: 48)
        }
      }

      Spacer()

      if store.isPro {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 64))
          .foregroundStyle(.green)
          .padding(.bottom, 40)
      } else {
        Button {
          Task { await proStore.purchase() }
        } label: {
          ZStack {
            if let product = proStore.product, !proStore.isPurchasing {
              Text(product.displayPrice)
                .font(.title2.bold())
            } else {
              // 가격을 불러오는 중이거나 구매 진행 중
              ProgressView()
                .tint(.black)
            }
          }
          .frame(maxWidth: .infinity, minHeight: 60)
          .background(Capsule().fill(.yellow))
          .foregroundStyle(.black)
        }
        .disabled(proStore.product == nil || proStore.isPurchasing)

        Button {
          Task { await proStore.restore() }
        } label: {
          Image(systemName: "arrow.clockwise")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white.opacity(0.6))
            .frame(width: 44, height: 44)
        }
        .accessibilityLabel("Restore Purchases")
        .padding(.top, 12)
      }
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.ignoresSafeArea())
    .task {
      if proStore.product == nil {
        await proStore.loadProduct()
      }
    }
    .onChange(of: store.isPro) {
      guard store.isPro else { return }
      // 구매 완료 표시를 잠깐 보여준 뒤 닫기
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        dismiss()
      }
    }
  }
}

#Preview {
  PaywallView()
}
