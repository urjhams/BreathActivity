//
//  StartView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 01.01.24.
//

import SwiftUI

struct StartView: View {
  
  @Binding var enableLabel: Bool
  
  @Binding var isSoundEnable: Bool
      
  @Binding var showAmplitude: Bool
  
  // the engine that store the stack to check
  @Bindable var engine: ExperimentalEngine
  
  // use an array to store, construct the respiratory rate from amplitudes
  @Bindable var storage: DataStorage
  
  var promtText: String {
    let level = engine.stack.level.name
    let steps = engine.stack.level.rawValue
    return "For \(level) mode, you will have to memorize \(steps) steps back"
  }
  
  var startButtonClick: () -> Void
  
  var body: some View {
    VStack {
      Text("N-back Task")
        .font(.largeTitle)
        .fontWeight(.heavy)
      TextField("Candidate Name", text: $storage.candidateName)
        .padding(.all)
        .clipShape(.rect(cornerRadius: 10))
      
      Toggle("Enable response sound", isOn: $isSoundEnable)
      
      // TODO: make the trial screen
      
      // TODO: save data into a json file
      
      // TODO: create a graph view for the data
      
      // TODO: make the instruction screen
      
      Toggle("Enable Label in Game", isOn: $enableLabel)
      
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
    
    Text(promtText)
      .font(.title2)
    
    Text("Each Level will be 3 minutes (180 seconds)")
      .font(.title2)
    
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
    .padding()
  }
}

#Preview {
  @State var label: Bool = true
  @State var showAmplitude: Bool = false
  @State var sound = false
  @Bindable var engine = ExperimentalEngine()
  @Bindable var storage = DataStorage()
  
  return StartView(
    enableLabel: $label, 
    isSoundEnable: $sound,
    showAmplitude: $showAmplitude,
    engine: engine,
    storage: storage,
    startButtonClick: {}
  )
}
