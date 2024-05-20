//
//  StartView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 01.01.24.
//

import SwiftUI
import BreathObsever
import Combine

@Observable
class StartViewModel {
  var showAlert = false
  
  var alertContent = ""
  
  var currentAudioInput = ""
  
  var showAmplitude = false
  
  var amplitudes = [Float]()
  
  let genders = ["Male", "Female", "Other"]
}

struct StartView: View {
  
  @Binding var selection: Int
  
  @Bindable var viewModel = StartViewModel()
  
  // use an array to store, construct the respiratory rate from amplitudes
  @Bindable var storage: DataStorage
  
  /// breath observer
  @Environment(BreathObsever.self) var observer: BreathObsever
  
  var checkTimer = Timer.publish(every: 0.1, on: .current, in: .common).autoconnect()
    
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
        
        Text(viewModel.currentAudioInput)
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
            ForEach(viewModel.genders, id: \.self) { gender in
              Text(gender)
            }
          }
          .frame(maxWidth: 300)
          .pickerStyle(.menu)
        }
        Spacer()
      }
      .alert(isPresented: $viewModel.showAlert) {
        Alert(title: Text(viewModel.alertContent))
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
      
      Toggle(isOn: $viewModel.showAmplitude) {
        Label {
          Text("Show amplitudes 􀙫")
            .font(.title3)
            .foregroundStyle(.gray)
        } icon: { Text("") }
      }
      .padding()
      .toggleStyle(.switch)
      .onChange(of: viewModel.showAmplitude) { oldValue, newValue in
        if newValue {
          try? observer.startAnalyzing()
        } else {
          observer.stopAnalyzing()
          viewModel.amplitudes = []
        }
      }
      Spacer()
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
      .opacity(viewModel.showAmplitude ? 0 : 1)
      .overlay {
        if viewModel.showAmplitude {
          amplitudeView(
            $viewModel.amplitudes,
            subject: observer.amplitudeSubject.eraseToAnyPublisher()
          )
          .frame(minHeight: 80 * offSet)
          .padding()
        }
      }
      Spacer()
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
      viewModel.alertContent = "Please Enter the correct information."
      return viewModel.showAlert = true
    }
    
    guard viewModel.currentAudioInput == "􀪷" else {
      viewModel.alertContent = "Please make sure airPod is connected."
      return viewModel.showAlert = true
    }
    
    storage.userData.levelTried = text(for: levelSequences[selection])
    
    startButtonClick()
  }
  
  private func trialClick() {
    guard viewModel.currentAudioInput == "􀪷" else {
      viewModel.alertContent = "Please make sure airPod is connected."
      return viewModel.showAlert = true
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
      viewModel.alertContent = "Cannot open Data folder.\n\(error.localizedDescription)"
      viewModel.showAlert = true
    }
  }
}

extension StartView {
  private func text(for sequence: [Level]) -> String {
    var result = ""
    sequence.forEach { level in
      result = result == "" ? level.name : result + " \(level.name)"
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
      viewModel.currentAudioInput = "􀟛"
    case "200e 4c": // 200e 4c is the modelID of airpod pro
      viewModel.currentAudioInput = "􀪷"
    case "iPhone Mic":
      viewModel.currentAudioInput = "􀬩"
    default:
      viewModel.currentAudioInput = "􀭉"
    }
  }
}

extension StartView {
  
  private var offSet: CGFloat { 1 }
  
  @ViewBuilder
  private func amplitudeView(
    _ amplitudes: Binding<[Float]>,
    subject: AnyPublisher<Float, Never>
  ) -> some View {
    HStack(spacing: 1) {
      ForEach(0..<amplitudes.count, id: \.self) { index in
        RoundedRectangle(cornerRadius: 2)
          .frame(width: offSet, height: CGFloat(amplitudes[index].wrappedValue) / 10)
          .foregroundColor(.white)
      }
    }
    .onReceive(subject) { value in
      amplitudes.wrappedValue.append(value)
      let amplitudesInOneSec = Int(Int(BreathObsever.sampleRate) / BreathObsever.samples)
      // keep only data of 5 seconds of amplirudes
      if amplitudes.count >= BreathObsever.windowTime * amplitudesInOneSec {
        amplitudes.wrappedValue.removeFirst()
      }
    }
  }
}

#Preview {
  @State var selection = 1
  @State var label: Bool = true
  @State var showAmplitude: Bool = false
  @Bindable var storage = DataStorage()
  @State var breathObserver = BreathObsever()
  
  return StartView(
    selection: $selection,
    storage: storage,
    startButtonClick: {},
    trialButtonClick: {},
    aboutButtonClick: {}
  )
  .frame(minHeight: 500)
  .environment(breathObserver)
}
