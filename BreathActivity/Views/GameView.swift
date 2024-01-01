//
//  GameView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 01.01.24.
//

import SwiftUI

struct GameView: View {
  
  private let offSet: CGFloat = 3
  
  /// debug text
  @Binding var tobiiInfoText: String
  
  @Binding var amplitudes: [Float]
  
  @Binding var showAmplitude: Bool
  
  // the engine that store the stack to check
  @ObservedObject var engine: ExperimentalEngine
  
  // use an array to store, construct the respiratory rate from amplitudes
  @ObservedObject var storage: DataStorage
  
  var body: some View {
    if let currentImage = engine.current {
      Image(currentImage)
    } else {
      Color(.clear)
    }
    if showAmplitude {
      Spacer()
      debugView
    }
  }
}

extension GameView {
  
  private var debugView: some View {
    VStack {
      Text(tobiiInfoText)
      
      amplitudeView
        .frame(height: 80 * offSet)
        .scenePadding([.leading, .trailing])
        .padding()
    }
  }
  
  private var amplitudeView: some View {
    ScrollView(.vertical) {
      HStack(spacing: 1) {
        ForEach(amplitudes, id: \.self) { amplitude in
          RoundedRectangle(cornerRadius: 2)
            .frame(width: offSet, height: CGFloat(amplitude) * offSet)
            .foregroundColor(.white)
        }
      }
    }
  }
}

#Preview {
  @State var showAmplitude: Bool = false
  @State var amplitudes = [Float]()
  @State var tobiiInfoText: String = "tobii info"
  @StateObject var engine = ExperimentalEngine()
  @StateObject var storage = DataStorage()
  
  return GameView(
    tobiiInfoText: $tobiiInfoText,
    amplitudes: $amplitudes,
    showAmplitude: $showAmplitude,
    engine: engine,
    storage: storage
  )
  .frame(minWidth: 500)
}
