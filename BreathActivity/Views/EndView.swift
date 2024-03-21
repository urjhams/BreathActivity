//
//  EndView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 21.03.24.
//

import SwiftUI

struct EndView: View {
  
  @Binding var state: ExperimentalState
  
  @Bindable var storage: DataStorage
  
  @State private var pressedSpace = false
  
  var body: some View {
    VStack {
      Spacer()
      Text("Thank you!!! 🙆🏻")
        .font(.largeTitle)
        .fontWeight(.bold)
      
      HStack {
        Text("Do you have any feedback (What to improve, anything uncomfortable to you, etc.)?")
          .font(.title3)
          .padding([.leading, .trailing])
          
        Spacer()
      }
      .padding(.top)
      
      TextField(text: $storage.comment) {
        Text("Answer (optional)")
      }
      .textFieldStyle(.roundedBorder)
      
      
      Spacer()
      MakeKeyPressSilentView()
        .frame(height: 0)
        .onAppear {
          NSEvent.addLocalMonitorForEvents(matching: [.keyUp]) { event in
            self.setupKeyPress(from: event)
            return event
          }
        }
      Text("Press Space to finish")
        .font(.title2)
        .padding()
    }
    .padding([.leading, .trailing], 24)
    .padding()
  }
}

extension EndView {
  private func setupKeyPress(from event: NSEvent) {
    if case 49 = event.keyCode {  // space
      guard case .end = state, !pressedSpace else {
        return
      }
      
      pressedSpace = true
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        IOManager.tryToWrite(storage.convertToCodable())
        
        state = .start
      }
    }
  }
}

#Preview {
  @State var state: ExperimentalState = .end
  @Bindable var storage = DataStorage()
  
  return EndView(state: $state, storage: storage)
    .frame(minWidth: 500, minHeight: 500)
}
