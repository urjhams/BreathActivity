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
      
      TextEditor(text: $storage.comment)
        .clipShape(.rect(cornerRadius: 5))
        .padding()
      
      Spacer()
      
      iconButton(
        text: "Finish",
        iconSystemName: "party.popper.fill",
        action: finish
      )
      .foregroundStyle(.pink)
      .padding()
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
      
      print("🙆🏻 Will save the following data:")
      print("🙆🏻 user:", storage.userData)
      storage.data.forEach { experimentData in
        print("🙆🏻 ----------------- \(experimentData.level) ----------------------")
        print("🙆🏻 pupil:", experimentData.collectedData.map(\.pupilSize))
        print("🙆🏻 respiratoryRate:", experimentData.collectedData.compactMap(\.respiratoryRate))
        print("🙆🏻 serial pupil size:", experimentData.serialData.pupilSizes)
        print("🙆🏻 correctionRate:", experimentData.correctRate ?? "0")
        let q1 = experimentData.surveyData?.q1Answer ?? 0
        let q2 = experimentData.surveyData?.q2Answer ?? 0
        print("🙆🏻 answered: \(q1) - \(q2)")
      }
      print("🙆🏻 comment:", storage.comment)
      
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
