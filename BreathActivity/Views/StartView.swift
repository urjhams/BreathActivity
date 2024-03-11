//
//  StartView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 01.01.24.
//

import SwiftUI
import BreathObsever

struct StartView: View {
  
  let checkTimer = Timer.publish(every: 0.1, on: .current, in: .common).autoconnect()
  
  @State var currentAudioInput = ""
  
  @Binding var selection: Int
          
  @Binding var showAmplitude: Bool
  
  // use an array to store, construct the respiratory rate from amplitudes
  @Bindable var storage: DataStorage
  
  @State var showAlert = false
  
  @State var alertContent = ""
    
  let genders = ["Male", "Female", "Other"]
    
  var startButtonClick: () -> Void
  
  var trialButtonClick: () -> Void
  
  var body: some View {
    VStack {
      ZStack {
        HStack {
          Spacer()
          Text(currentAudioInput)
            .font(.title)
            .baselineOffset(8)
            .padding()
            .onReceive(checkTimer) { _ in
              withAnimation {
                checkCurrentAudioInput()
              }
            }
        }
        
        Text("N-back Task")
          .font(.largeTitle)
          .fontWeight(.heavy)
      }
      .frame(height: 100)
      
      Text("Welcome to my Experiment. \nI really appraciate you for participating 🤗")
        .font(.title2)
        .multilineTextAlignment(.center)
        .padding(.bottom)
      
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
    }
    .padding(20)
    
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
      } icon: {
        Text("")
      }
    }
    
    HStack {
      Button(action: {
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
        
        startButtonClick()
      }) {
        VStack {
          Image(systemName: "play.circle.fill")
            .font(.largeTitle)
          
          Text("Start")
        }
      }
      .controlSize(.extraLarge)
      .buttonStyle(.borderless)
      .padding()
      
      Button(action: {
        guard currentAudioInput == "􀪷" else {
          alertContent = "Please make sure airPod is connected."
          return showAlert = true
        }
        
        trialButtonClick()
      }) {
        VStack {
          Image(systemName: "questionmark.circle.fill")
            .font(.largeTitle)
          
          Text("Trial")
        }
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
    trialButtonClick: {}
  )
}
