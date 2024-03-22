//
//  StartView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 01.01.24.
//

import SwiftUI
import BreathObsever
import Combine

struct StartView: View {
  
  @State var showAlert = false
  
  @State var alertContent = ""
  
  @State var currentAudioInput = ""
  
  @Binding var selection: Int
          
  @Binding var showAmplitude: Bool
  
  // use an array to store, construct the respiratory rate from amplitudes
  @Bindable var storage: DataStorage
  
  var checkTimer = Timer.publish(every: 0.1, on: .current, in: .common).autoconnect()
      
  let genders = ["Male", "Female", "Other"]
    
  var startButtonClick: () -> Void
  
  var trialButtonClick: () -> Void
  
  var aboutButtonClick: () -> Void
  
  var body: some View {
    VStack {
      
      Text("N-back Task")
        .font(.largeTitle)
        .fontWeight(.heavy)
      
      HStack {
        Text("Current audio source:")
          .font(.title2)
        
        Text(currentAudioInput)
          .font(.title)
          .foregroundStyle(.brown)
          .baselineOffset(8)
          .onReceive(checkTimer) { _ in
            withAnimation {  checkCurrentAudioInput() }
          }
      }
      
      Text("Welcome to my Experiment. \nI really appraciate you for participating 🤗")
        .font(.title2)
        .foregroundStyle(.teal)
        .multilineTextAlignment(.center)
        .padding([.bottom, .top])
      
      HStack {
        Spacer()
        VStack(spacing: 10) {
          TextField("Your Name", text: $storage.userData.name)
            .frame(minWidth: 150, maxWidth: 300)
            .padding([.leading, .trailing])
            .clipShape(.rect(cornerRadius: 10))
          
          TextField("Age", text: $storage.userData.age)
            .frame(minWidth: 150, maxWidth: 300)
            .padding([.leading, .trailing])
            .clipShape(.rect(cornerRadius: 10))
          
          Picker("Gender", selection: $storage.userData.gender) {
            ForEach(genders, id: \.self) { gender in
              Text(gender)
            }
          }
          .frame(maxWidth: 300)
          .pickerStyle(.menu)
        }
        Spacer()
      }
      .alert(isPresented: $showAlert) {
        Alert(title: Text(alertContent))
      }
      .padding()
      
      Picker("Level sequences", selection: $selection) {
        ForEach(0...5, id: \.self) { index in
          Text(text(for: levelSequences[index]))
        }
      }
      .frame(maxWidth: 300)
      .pickerStyle(.menu)
      
      Spacer()
      
      Toggle(isOn: $showAmplitude) {
        Label {
          Text("Show amplitudes 􀙫")
            .foregroundStyle(.gray)
        } icon: { Text("") }
      }
      
      HStack {
        iconButton(
          text: "Start",
          iconSystemName: "play.circle.fill",
          action: startClick
        )
        .foregroundStyle(.red)
        .padding()
        
        iconButton(
          text: "Trial",
          iconSystemName: "questionmark.circle.fill",
          action: trialClick
        )
        .foregroundStyle(.indigo)
        .padding()
        
        iconButton(
          text: "Data",
          iconSystemName: "folder.circle.fill",
          action: dataClick
        )
        .foregroundStyle(.blue)
        .padding()
        
        iconButton(
          text: "About",
          iconSystemName: "info.circle.fill",
          action: aboutClick
        )
        .foregroundStyle(.orange)
        .padding()
      }
    }
    .padding()
  }
}

extension StartView {
  private func startClick() {
    guard
      storage.userData.name != "",
      storage.userData.age != "",
      storage.userData.age.isNumeric
    else {
      alertContent = "Please Enter the correct information."
      return showAlert = true
    }
    
    guard currentAudioInput == "􀪷" else {
      alertContent = "Please make sure airPod is connected."
      return showAlert = true
    }
    
    storage.userData.levelTried = text(for: levelSequences[selection])
    
    startButtonClick()
  }
  
  private func trialClick() {
    guard currentAudioInput == "􀪷" else {
      alertContent = "Please make sure airPod is connected."
      return showAlert = true
    }
    
    trialButtonClick()
  }
  
  private func aboutClick() {
    aboutButtonClick()
  }
  
  private func dataClick() {
    do {
      try IOManager.openDataFolder()
    } catch {
      alertContent = "Cannot open Data folder.\n\(error.localizedDescription)"
      showAlert = true
    }
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

@ViewBuilder func iconButton(
  text: String,
  iconSystemName: String,
  action: @escaping () -> Void
) -> some View {
  Button(action: action) {
    VStack {
      Image(systemName: iconSystemName)
        .font(.largeTitle)
      
      Text(text)
        .fontWeight(.bold)
        .padding(2)
    }
  }
  .controlSize(.extraLarge)
  .buttonStyle(.borderless)
}

import AVFoundation

extension StartView {
  private func checkCurrentAudioInput() {
    
    let current = AVCaptureDevice.default(for: .audio)
        
    switch current?.modelID {
    case "Digital Mic":
      currentAudioInput = "􀟛"
    case "200e 4c": // 200e 4c is the modelID of airpod pro
      currentAudioInput = "􀪷"
    case "iPhone Mic":
      currentAudioInput = "􀬩"
    default:
      currentAudioInput = "􀭉"
    }
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
    trialButtonClick: {},
    aboutButtonClick: {}
  )
  .frame(minHeight: 500)
}
