//
//  StartView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 01.01.24.
//

import SwiftUI

struct StartView: View {
  
  @Binding var selection: Int
          
  @Binding var showAmplitude: Bool
  
  // use an array to store, construct the respiratory rate from amplitudes
  @Bindable var storage: DataStorage
  
  @State var showAlert = false
  
  // TODO: add another information of the candidate (age, sex), also add it into the DataStorage
  // TODO: change the response only when click space.
  
  var startButtonClick: () -> Void
  
  var trialButtonClick: () -> Void
  
  var body: some View {
    VStack {
      Text("N-back Task")
        .font(.largeTitle)
        .fontWeight(.heavy)
      HStack {
        Spacer()
        TextField("Your Name", text: $storage.candidateName)
          .frame(minWidth: 150, maxWidth: 300)
          .padding(.all)
          .clipShape(.rect(cornerRadius: 10))
          .alert(isPresented: $showAlert) {
            Alert(title: Text("Please enter your name"))
          }
        Spacer()
      }
    }
    .padding(20)
    
    Text("Welcome to my Experiment. \nI really appraciate you for participating 🤗")
      .font(.title2)
      .multilineTextAlignment(.center)
    
    Picker("Level sequences", selection: $selection) {
      ForEach(0...5, id: \.self) { index in
        Text(text(for: levelSequences[index]))
      }
    }
    .frame(maxWidth: 300)
    .pickerStyle(.menu)
    
    Spacer()
    
    Picker("Show amplitude (for debugging purpose)", selection: $showAmplitude) {
      Text("Yes").tag(true)
      Text("No").tag(false)
    }
    .pickerStyle(.radioGroup)
    .horizontalRadioGroupLayout()
    
    HStack {
      Button(action: {
        guard storage.candidateName != "" else {
          return showAlert = true
        }
        startButtonClick()
      }) {
        Image(systemName: "play.circle.fill")
          .font(.largeTitle)
      }
      .controlSize(.extraLarge)
      .buttonStyle(.borderless)
      .padding()
      
      Button(action: trialButtonClick) {
        Image(systemName: "questionmark.circle.fill")
          .font(.largeTitle)
      }
      .controlSize(.extraLarge)
      .buttonStyle(.borderless)
      .padding()
    }
    .padding()
  }
}

extension StartView {
  private func text(for sequence: [Level]) -> String {
    var result = ""
    sequence.forEach { level in
      if result == "" {
        result = level.name
      } else {
        result += " \(level.name)"
      }
    }
    return result
  }
}

#Preview {
  @State var selection = 1
  @State var label: Bool = true
  @State var showAmplitude: Bool = false
  @Bindable var storage = DataStorage()
  
  return StartView(
    selection: $selection,
    showAmplitude: $showAmplitude,
    storage: storage,
    startButtonClick: {},
    trialButtonClick: {}
  )
}
