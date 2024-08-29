//
//  ContentView.swift
//  MultiCounter
//
//  Created by  유 주연 on 8/25/24.
//

import SwiftUI
import SwiftData

struct CountModel: Codable, Identifiable {
  var id: UUID = UUID()
  var value: Int = 0
  var backgroundColorHex: String = "000000"
  var foregroundColorHex: String = "ffffff"
  
  var backgroundColor: Color {
    get {
      Color(hex: backgroundColorHex)!
    }
    set {
      backgroundColorHex = newValue.toHex() ?? ""
    }
  }
  var foregroundColor: Color {
    get {
      Color(hex: foregroundColorHex)!
    }
    set {
      foregroundColorHex = newValue.toHex() ?? ""
    }
  }
}


struct ContentView: View {
  @AppStorage("CountModels") private var countsData: Data = Data()
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
            VStack {
              
              GeometryReader { geo in
                Group {
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
                }.position(x: geo.size.width / 2, y: 100)
                Text("\(count.value)")
                  .foregroundStyle(count.foregroundColor)
                  .lineLimit(1)
                  .font(.system(size: geo.size.width))
                  .minimumScaleFactor(0.1)
                  .foregroundColor(.white)
                  .frame(maxWidth: .infinity, maxHeight: .infinity)
              }
              
            }
            .contentShape(Rectangle())
            .onTapGesture {
              
              switch mode {
              case .plus:
                count.value += 1
              case .minus:
                count.value -= 1
              case .reset:
                count.value = 0
              }
              
              saveMyStructArray()
            }
            
            HStack {
              ColorPicker("", selection: $count.foregroundColor)
                .labelsHidden()
                .onChange(of: count.foregroundColor) {
                  saveMyStructArray()
                }
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
    .tabViewStyle(.page(indexDisplayMode: .always))
//    .tabViewStyle(.page)
    
    .onAppear(perform: {
      loadMyStructArray()
    })
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
