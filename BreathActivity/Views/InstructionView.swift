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
  
  var body: some View {
    VStack {
      switch nBack {
      case 1:
        Text("Press Space if the image matchs with the previous image")
      default:
        Text("Press Space if the image matchs with the \(nBack) previous images")
      }
      Text("Press Space to start")
      MakeKeyPressSilentView()
        .frame(height: 0)
    }
    .onAppear {
      NSEvent.addLocalMonitorForEvents(matching: [.keyUp]) { event in
        self.setupKeyPress(from: event)
        return event
      }
    }
  }
}

extension InstructionView {
  private func setupKeyPress(from event: NSEvent) {
    switch event.keyCode {
    case 49: // space
      guard case .instruction(let level) = state else {
        return
      }
      
      state = .running(level: level)
      
    default:
      break
    }
  }
}

#Preview {
  
  @State var state: ExperimentalState = .instruction(level: .easy)
  
  return InstructionView(isTrial: false, nBack: 1, state: $state)
    .frame(minWidth: 500, minHeight: 300)
}
