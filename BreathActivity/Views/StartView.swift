//
//  StartView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 01.01.24.
//

import SwiftUI

struct StartView: View {
  
  @Binding var showAmplitude: Bool
  
  // the engine that store the stack to check
  @ObservedObject var engine: ExperimentalEngine
  
  // use an array to store, construct the respiratory rate from amplitudes
  @ObservedObject var storage: DataStorage
  
  var startButtonClick: () -> Void
  
  var body: some View {
    VStack {
      TextField("Candidate Name", text: $storage.candidateName)
        .padding(.all)
        .clipShape(.rect(cornerRadius: 10))
      Picker("Level", selection: $engine.stack.level) {
        ForEach(Level.allCases, id: \.self) { level in
          Text(level.name)
        }
      }
      .pickerStyle(.radioGroup)
      .horizontalRadioGroupLayout()
      .frame(maxWidth: .infinity)
      .padding(.leading)
    }
    .padding(20)
    
    Text("Each Level will be 3 minutes (180 seconds)")
    Text("Press left arrow button for \"Yes\"")
    Text("and right arrow button for \"No\".")
    
    Spacer()
    
    Picker("Show amplitude", selection: $showAmplitude) {
      Text("Yes").tag(true)
      Text("No").tag(false)
    }
    .pickerStyle(.radioGroup)
    .horizontalRadioGroupLayout()
    
    Button(action: startButtonClick) {
      Image(systemName: "play.fill")
        .font(.largeTitle)
    }
  }
}

#Preview {
  
  @State var showAmplitude: Bool = false
  @StateObject var engine = ExperimentalEngine()
  @StateObject var storage = DataStorage()
  
  return StartView(
    showAmplitude: $showAmplitude,
    engine: engine,
    storage: storage,
    startButtonClick: {}
  )
}