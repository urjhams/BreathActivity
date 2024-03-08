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
  
  /// Container to store the current level and the next levels
  var levelSequence: [Level]
  
  var body: some View {
    Text(content)
      .onAppear {
        // TODO: based on the storage, get the result (% correction) and show the content with it
      }
    
    Spacer()
    Text("Press space to continue")
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
      guard case .result = state else {
        return
      }
      state = .survey
    }
  }
}

#Preview {
  ResultView(state: <#Binding<ExperimentalState>#>, storage: <#DataStorage#>, levelSequence: <#[Level]#>)
}
