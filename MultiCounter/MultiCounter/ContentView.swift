//
//  ContentView.swift
//  MultiCounter
//
//  Created by  유 주연 on 8/25/24.
//

import SwiftUI
import SwiftData



struct ContentView: View {
  @State var count: Int = 0
  @State var mode: CountMode = .plus
  @State var header: String = ""
  @State var backgroundColor: Color = .gray
  @State var foregroundColor: Color = .white

    var body: some View {
          VStack(spacing: 0) {
            HStack {
              Spacer()
              Button("add") {
                
              }
              EditButton()
            }
            TextField("", text: $header, prompt: Text("title"))
              .padding()
            
            Group {
              GeometryReader { geo in
                Text("\(count)")
                  .foregroundStyle(foregroundColor)
                  .lineLimit(1)
                  .font(.system(size: geo.size.width))
                  .minimumScaleFactor(0.1)
                  .foregroundColor(.white)
                  .frame(maxWidth: .infinity, maxHeight: .infinity)
              }
            }
            
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
              switch mode {
              case .plus:
                count += 1
              case .minus:
                count -= 1
              case .reset:
                count = 0
              }
            }
            
            
            HStack {
              
              ColorPicker("", selection: $foregroundColor)
                .labelsHidden()
              Button(action: {
                mode = mode.next()
              }, label: {
                switch mode {
                case .plus:
                  Image(systemName: "plus")
                    .tint(.red)
                    .padding()
                case .minus:
                  Image(systemName: "minus")
                    .tint(.blue)
                    .padding()
                case .reset:
                  Image(systemName: "arrow.clockwise")
                    .tint(.white)
                    .padding()
                }
              })
              
              ColorPicker("", selection: $backgroundColor)
                .labelsHidden()
            }
            .frame(height: 50)
            .padding()
          }.safeAreaPadding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor)
    }
}

#Preview {
    ContentView()
}
