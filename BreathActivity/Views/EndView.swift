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
      
      iconButton(
        text: "Finish",
        iconSystemName: "party.popper.fill",
        action: finish
      ).padding()
    }
    .padding([.leading, .trailing], 32)
    .padding()
  }
}

extension EndView {
  
  private func finish() {
    
    guard case .end = state else {
      return
    }
    
    do {
      try IOManager.tryToWrite(storage.asCodable())
      state = .start
    } catch {
      print(error.localizedDescription)
      state = .start
    }
  }
}

#Preview {
  @State var state: ExperimentalState = .end
  @Bindable var storage = DataStorage()
  
  return EndView(state: $state, storage: storage)
    .frame(minWidth: 500, minHeight: 400)
}
