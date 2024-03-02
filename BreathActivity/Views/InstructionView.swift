//
//  InstructionView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 01.03.24.
//

import SwiftUI

struct InstructionView: View {
  
  let nBack: Int
  
  @Binding var state: ExperimentalState
  
  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  
  @State var time = 10
  
  var body: some View {
    switch nBack {
    case 1:
      Text("Press Space if the image matchs with the previous image")
    default:
      Text("Press Space if the image matchs with the \(nBack) previous images")
    }
    
    Text("Start in \(time)s")
      .onReceive(timer) { _ in
        guard time > 0 else {
          return
        }
        time -= 1
        
        if time == 0 {
          guard case .instruction(let level) = state else {
            return
          }
          state = .running(level: level)
        }
      }
  }
}

#Preview {
  
  @State var state: ExperimentalState = .instruction(level: .easy)
  
  return InstructionView(nBack: 1, state: $state)
    .frame(minWidth: 500, minHeight: 300)
}
