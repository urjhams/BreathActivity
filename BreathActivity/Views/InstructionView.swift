//
//  InstructionView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 01.03.24.
//

import SwiftUI

struct InstructionView: View {
  
  let isTrial: Bool
  
  let nBack: Int
  
  @Binding var state: ExperimentalState
  
  @Binding var levelSequence: [Level]
  
  @State private var pressedSpace = false
  
  var content: String {
    switch nBack {
    case 1:
      "Press Space if the image matchs with the previous image."
    default:
      "Press Space if the image matchs with the \(nBack) previous images."
    }
  }
  
  var body: some View {
    VStack {
      Spacer()
      Text(content)
        .font(.title2)
      Spacer()
      Text("Press Space to start")
        .font(.title3)
        .fontWeight(.bold)
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
}

extension InstructionView {
  private func setupKeyPress(from event: NSEvent) {
    if case 49 = event.keyCode {  // space
      guard case .instruction(let level) = state, !pressedSpace else {
        return
      }
      
      pressedSpace = true
      
      DispatchQueue.main.async {
        state = .running(level: level)
      }
    }
  }
}

#Preview {
  
  @State var state: ExperimentalState = .instruction(level: .easy)
  @State var sequence = [Level]()
  
  return InstructionView(isTrial: false, nBack: 1, state: $state, levelSequence: $sequence)
    .frame(minWidth: 500, minHeight: 300)
}
