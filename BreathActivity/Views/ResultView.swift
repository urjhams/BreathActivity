//
//  ResultView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 08.03.24.
//

import SwiftUI

struct ResultView: View {
  
  @Binding var state: ExperimentalState
  
  // data container
  @Bindable var storage: DataStorage
  
  @State var content = "Correction: xxx %"
  
  @State private var pressedSpace = false
  
  /// Container to store the current level and the next levels
  var levelSequence: [Level]
  
  var body: some View {
    Spacer()
    Text(content)
      .font(.title)
      .onAppear {
        if let correctionRate = storage.data.last?.correctRate {
          let rounded = correctionRate.roundToDecimal(2)
          switch rounded {
          case 0...50:
            content = "Not bad, you have \(rounded) % correction."
          default:
            content = "Wow, you have \(rounded) % correction."
          }
        }
      }
    
    Spacer()
    Text("Press space to continue")
      .font(.title3)
      .fontWeight(.bold)
      .foregroundStyle(.indigo)
      .padding()
    MakeKeyPressSilentView()
      .frame(height: 0)
      .onAppear {
        NSEvent.addLocalMonitorForEvents(matching: [.keyUp]) { event in
          self.setupKeyPress(from: event)
          return event
        }
      }
  }
}

extension ResultView {
  
  private func setupKeyPress(from event: NSEvent) {
    if case 49 = event.keyCode {  // space
      guard case .result = state, !pressedSpace else {
        return
      }
      
      pressedSpace = true
      
      DispatchQueue.main.async {
        state = .survey
      }
    }
  }
}

#Preview {
  @State var state: ExperimentalState = .survey
  @Bindable var storage = DataStorage()
  @State var sequence: [Level] = [.easy]
  
  return ResultView(state: $state, storage: storage, levelSequence: sequence)
}
