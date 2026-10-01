//
//  ContentView.swift
//  MultiCounter
//
//  Created by  유 주연 on 8/25/24.
//

import SwiftUI

struct ContentView: View {
  private static let addPageID = UUID()

  @State private var store = CounterStore.shared
  @State private var proStore = ProStore.shared
  @Environment(\.scenePhase) private var scenePhase

  @State private var timer: Timer?
  @AppStorage("HapticsEnabled") private var hapticsEnabled: Bool = true
  @FocusState private var isEditingLabel: Bool

  @State var mode: CountMode = .plus
  @State private var selection: UUID?
  @State private var deletingCounterID: UUID?
  @State private var showPaywall = false

  var body: some View {
    TabView(selection: $selection) {
      ForEach($store.counters) { $count in
        counterPage($count)
          .tag(Optional(count.id))
      }
      addPage
        .tag(Optional(Self.addPageID))
    }
    .ignoresSafeArea(.all)
    .ignoresSafeArea(.keyboard)
    .tabViewStyle(.page(indexDisplayMode: .always))
    .onAppear {
      if selection == nil {
        selection = store.counters.first?.id
      }
    }
    .task {
      proStore.start()
    }
    .onChange(of: selection) {
      deletingCounterID = nil
      isEditingLabel = false
    }
    .onChange(of: scenePhase) {
      guard scenePhase == .active else { return }
      // 위젯·제어 센터·워치에서 바뀐 값 반영
      store.reload()
      if SharedStorage.consumePendingPaywall() {
        showPaywall = true
      }
      Task { await proStore.refreshEntitlement() }
    }
    .onOpenURL { url in
      if url.host == "pro" {
        showPaywall = true
      }
    }
    .sheet(isPresented: $showPaywall) {
      PaywallView()
    }
  }

  // MARK: - 카운터 페이지

  private func counterPage(_ count: Binding<CountModel>) -> some View {
    ZStack {
      VStack(spacing: 0) {
        GeometryReader { geo in
          ZStack(alignment: .top) {
            // 숫자는 전체 영역의 정가운데에 고정
            Text("\(count.wrappedValue.value)")
              .foregroundStyle(count.wrappedValue.foregroundColor)
              .lineLimit(1)
              .font(.system(size: geo.size.width))
              .minimumScaleFactor(0.1)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .contentShape(Rectangle())
              .onTapGesture {
                // 레이블 입력 중이면 키보드만 내림
                if isEditingLabel {
                  isEditingLabel = false
                  return
                }
                commonAction(id: count.wrappedValue.id)
              }
              .onLongPressGesture(minimumDuration: 0.4, perform: {
                isEditingLabel = false
                stopRepeating()
                let id = count.wrappedValue.id
                // 리셋은 반복할 필요가 없으므로 한 번만 실행
                guard mode != .reset else {
                  commonAction(id: id)
                  return
                }
                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                  commonAction(id: id)
                }
              }, onPressingChanged: { isPressing in
                // 손을 떼거나 스와이프로 제스처가 취소되면 반복 중단
                if !isPressing {
                  stopRepeating()
                }
              })

            // 모드 버튼과 레이블은 숫자 위에 겹쳐서 배치
            VStack(spacing: 0) {
              Button(action: {
                mode = mode.next()
              }, label: {
                Image(systemName: mode.symbolName)
                  .resizable()
                  .frame(width: 100, height: 100)
                  .tint(mode.color(on: count.wrappedValue.backgroundColor,
                                   foreground: count.wrappedValue.foregroundColor))
                  .padding()
              })

              // 비어 있으면 보이지 않고, 이 자리를 탭하면 바로 입력
              TextField("", text: count.label)
                .font(.system(size: 28, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(count.wrappedValue.foregroundColor)
                .tint(count.wrappedValue.foregroundColor)
                .lineLimit(1)
                .submitLabel(.done)
                .focused($isEditingLabel)
                .frame(height: 44)
                .padding(.horizontal)
                .onChange(of: count.wrappedValue.label) {
                  store.save()
                }
            }
            .padding(.top, 34)
          }
        }

        HStack {
          ColorPicker("", selection: count.foregroundColor)
            .labelsHidden()
            .onChange(of: count.wrappedValue.foregroundColor) {
              store.save()
            }
          Spacer()

          centerControl(for: count.wrappedValue)
            // 터치 영역은 유지하되 하단 바 높이는 늘리지 않아 숫자 위치가 바뀌지 않게 함
            .padding(.vertical, -8)

          Spacer()

          ColorPicker("", selection: count.backgroundColor)
            .labelsHidden()
            .onChange(of: count.wrappedValue.backgroundColor) {
              store.save()
            }
        }
        .padding()
      }
      .safeAreaPadding()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(count.wrappedValue.backgroundColor)
    }
  }

  /// 평소엔 진동 토글, 길게 누르면 삭제 버튼으로 바뀜
  @ViewBuilder
  private func centerControl(for count: CountModel) -> some View {
    if deletingCounterID == count.id {
      Image(systemName: "trash.circle.fill")
        .font(.system(size: 28))
        .foregroundStyle(.red)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .onTapGesture {
          deleteCounter(id: count.id)
        }
        .accessibilityLabel("Delete")
    } else {
      Image(systemName: hapticsEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash")
        .font(.system(size: 24))
        .foregroundStyle(count.foregroundColor)
        .opacity(hapticsEnabled ? 1 : 0.4)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .onTapGesture {
          hapticsEnabled.toggle()
          if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
          }
        }
        .onLongPressGesture(minimumDuration: 0.6) {
          guard store.counters.count > 1 else { return }
          UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
          withAnimation { deletingCounterID = count.id }
          // 누르지 않으면 잠시 후 원래대로
          DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation {
              if deletingCounterID == count.id { deletingCounterID = nil }
            }
          }
        }
        .accessibilityAddTraits(.isButton)
    }
  }

  // MARK: - 카운터 추가 페이지

  private var addPage: some View {
    ZStack {
      Color.black
      Button(action: addCounter) {
        Image(systemName: "plus.circle")
          .resizable()
          .frame(width: 100, height: 100)
          .foregroundStyle(.white.opacity(0.8))
          .overlay(alignment: .bottomTrailing) {
            // 더 추가하려면 Pro가 필요하다는 표시
            if !store.canAddCounter {
              Image(systemName: "lock.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.yellow, .black)
                .offset(x: 8, y: 8)
            }
          }
      }
      .accessibilityLabel("Add")
    }
    .ignoresSafeArea()
  }

  // MARK: - 동작

  private func commonAction(id: UUID) {
    if hapticsEnabled {
      let generator = UIImpactFeedbackGenerator(style: .medium)
      generator.impactOccurred()
    }
    store.apply(mode, to: id)
  }

  private func stopRepeating() {
    timer?.invalidate()
    timer = nil
  }

  private func addCounter() {
    guard let counter = store.addCounter() else {
      showPaywall = true
      return
    }
    withAnimation {
      selection = counter.id
    }
  }

  private func deleteCounter(id: UUID) {
    guard let index = store.counters.firstIndex(where: { $0.id == id }) else { return }
    // 삭제 후에는 옆 카운터로 이동
    let neighbor = index > 0 ? store.counters[index - 1] : store.counters[index + 1]
    deletingCounterID = nil
    withAnimation {
      selection = neighbor.id
    }
    // 페이지 이동과 삭제가 동시에 일어나면 엉뚱한 페이지로 가므로, 이동이 끝난 뒤 삭제
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
      store.deleteCounter(id: id)
    }
  }
}

#Preview {
  ContentView()
}
