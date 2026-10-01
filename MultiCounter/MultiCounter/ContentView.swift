//
//  ContentView.swift
//  MultiCounter
//
//  Created by  유 주연 on 8/25/24.
//

import SwiftUI
import SwiftData
import AVFoundation

struct CountModel: Codable, Identifiable {
  var id: UUID = UUID()
  var value: Int = 0
  var backgroundColorHex: String = "000000"
  var foregroundColorHex: String = "ffffff"
  var label: String = ""

  var backgroundColor: Color {
    get {
      Color(hex: backgroundColorHex) ?? .black
    }
    set {
      backgroundColorHex = newValue.toHex() ?? ""
    }
  }
  var foregroundColor: Color {
    get {
      Color(hex: foregroundColorHex) ?? .white
    }
    set {
      foregroundColorHex = newValue.toHex() ?? ""
    }
  }
}

extension CountModel {
  // 이전 버전에 저장된 데이터에는 없는 필드가 있어도 읽을 수 있도록 기본값으로 디코딩
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
    value = try container.decodeIfPresent(Int.self, forKey: .value) ?? 0
    backgroundColorHex = try container.decodeIfPresent(String.self, forKey: .backgroundColorHex) ?? "000000"
    foregroundColorHex = try container.decodeIfPresent(String.self, forKey: .foregroundColorHex) ?? "ffffff"
    label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
  }
}


struct ContentView: View {
  @State private var isPressing: Bool = false
  @State private var timer: Timer?

  
  @AppStorage("CountModels") private var countsData: Data = Data()
  @AppStorage("HapticsEnabled") private var hapticsEnabled: Bool = true
  @FocusState private var isEditingLabel: Bool
  @State private var counts: [CountModel] = [
    CountModel(),
    CountModel(),
    CountModel(),
    CountModel(),
    CountModel(),
    CountModel(),
    CountModel(),
    CountModel(),
    CountModel(),
    CountModel()
  ]
  
  @State var count: Int = 0
  @State var mode: CountMode = .plus
  @State var header: String = ""
  @State var backgroundColor: Color = .gray
  @State var foregroundColor: Color = .white
  
  var body: some View {
    TabView {
      ForEach($counts) { $count in
        ZStack {
          VStack( spacing: 0) {
            GeometryReader { geo in
              ZStack(alignment: .top) {
                // 숫자는 전체 영역의 정가운데에 고정
                Text("\(count.value)")
                  .foregroundStyle(count.foregroundColor)
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
                    commonAction(count: $count)
                  }
                  .onLongPressGesture(minimumDuration: 0.4, perform: {
                    isEditingLabel = false
                    stopRepeating()
                    // 리셋은 반복할 필요가 없으므로 한 번만 실행
                    guard mode != .reset else {
                      commonAction(count: $count)
                      return
                    }
                    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                      commonAction(count: $count)
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
                    switch mode {
                    case .plus:
                      Image(systemName: "plus.circle")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .tint(.red)
                        .padding()
                    case .minus:
                      Image(systemName: "minus.circle")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .tint(.blue)
                        .padding()
                    case .reset:
                      Image(systemName: "arrow.clockwise.circle")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .tint(count.backgroundColor.opposite)
                        .padding()
                    }
                  })

                  // 비어 있으면 보이지 않고, 이 자리를 탭하면 바로 입력
                  TextField("", text: $count.label)
                    .font(.system(size: 28, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(count.foregroundColor)
                    .tint(count.foregroundColor)
                    .lineLimit(1)
                    .submitLabel(.done)
                    .focused($isEditingLabel)
                    .frame(height: 44)
                    .padding(.horizontal)
                    .onChange(of: count.label) {
                      saveMyStructArray()
                    }
                }
                .padding(.top, 34)
              }
            }

            HStack {
              ColorPicker("", selection: $count.foregroundColor)
                .labelsHidden()
                .onChange(of: count.foregroundColor) {
                  saveMyStructArray()
                }
              Spacer()

              Button(action: {
                hapticsEnabled.toggle()
                if hapticsEnabled {
                  UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
              }, label: {
                Image(systemName: hapticsEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                  .font(.system(size: 24))
                  .foregroundStyle(count.foregroundColor)
                  .opacity(hapticsEnabled ? 1 : 0.4)
                  .frame(width: 44, height: 44)
              })
              // 터치 영역은 유지하되 하단 바 높이는 늘리지 않아 숫자 위치가 바뀌지 않게 함
              .padding(.vertical, -8)

              Spacer()

              ColorPicker("", selection: $count.backgroundColor)
                .labelsHidden()
                .onChange(of: count.backgroundColor) {
                  saveMyStructArray()
                }
            }
            .padding()
            
          }
          .safeAreaPadding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(count.backgroundColor)
        }
      }
    }
    .ignoresSafeArea(.all)
    .ignoresSafeArea(.keyboard)
    .tabViewStyle(.page(indexDisplayMode: .always))
    
    .onAppear(perform: {
      loadMyStructArray()
    })
  }
    
    
  private func commonAction(count: Binding<CountModel>) {
    if hapticsEnabled {
      let generator = UIImpactFeedbackGenerator(style: .medium)
      generator.impactOccurred()
    }
    switch mode {
    case .plus:
      count.wrappedValue.value += 1
    case .minus:
      count.wrappedValue.value -= 1
    case .reset:
      count.wrappedValue.value = 0
    }
    
    saveMyStructArray()
  }
  private func stopRepeating() {
    timer?.invalidate()
    timer = nil
  }
  private func saveMyStructArray() {
    do {
      let encoder = JSONEncoder()
      let data = try encoder.encode(counts)
      countsData = data
    } catch {
      print("Failed to encode MyStruct array: \(error.localizedDescription)")
    }
  }
  
  private func loadMyStructArray() {
    do {
      let decoder = JSONDecoder()
      counts = try decoder.decode([CountModel].self, from: countsData)
    } catch {
      print("Failed to decode MyStruct array: \(error.localizedDescription)")
    }
  }
}

#Preview {
  ContentView()
}
