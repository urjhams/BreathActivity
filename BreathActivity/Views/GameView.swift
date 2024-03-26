//
//  GameView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 01.01.24.
//

import SwiftUI
import GameController
import BreathObsever
import AVFAudio
import Combine

struct GameView: View {
  
  let isTrial: Bool
  
  /// The experiment data of this current stage to store in `storage`
  @State var data: ExperimentalData
      
  @State var screenBackground: Color = .background
  
  @State var running = false
  
  /// The flag to make sure we observe the data after the a bit of inital time
  @State var processing = false
  
  /// debug text
  @State private var tobiiInfoText: String = ""
    
  // the engine that store the stack to check
  @State var engine: ExperimentalEngine
  
  @Binding var state: ExperimentalState
    
  /// Container to store the current level and the next levels
  @Binding var levelSequence: [Level]
  
  // data container
  @Bindable var storage: DataStorage
  
  /// Tobii tracker object that read the python script
  @Environment(\.tobiiTracker) var tobii
  
  /// breath observer
  @Environment(BreathObsever.self) var observer: BreathObsever
  
  @State var showAlert = false
  
  @State var alertContent = ""
  
  var body: some View {
    ZStack {
      VStack {
        if let currentImage = engine.current {
          HStack {
            Spacer()
            Image(currentImage)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 400, height: 400)
              .background(.clear)
              .id(engine.currentImageId)
              .transition(.scale.animation(.easeInOut))
            Spacer()
          }
          .frame(maxHeight: .infinity, alignment: .center)
        } else {
          Color(.clear)
        }
        
        Spacer()
        
        if tobiiInfoText.last == "0" {
          debugView
        }
        
        // work-around view to disable the "funk" error sound when click on keyboard on macOS
        MakeKeyPressSilentView()
          .frame(height: 0)
          .onAppear {
            // key pressed notification register
            NSEvent.addLocalMonitorForEvents(matching: [.keyUp]) { event in
              self.setupKeyPress(from: event)
              return event
            }
          }
      }
      .onReceive(engine.sessionTimer) { _ in handleSessionTimer() }
      .onReceive(engine.analyzeTimer) { _ in handleAnalyzeTimer() }
      .padding()
    }
    .background(screenBackground)
    .onAppear {
      /// config tobii's custom frequency
      /// Here we set frequency to 1Hz which mean the custom data we receive with be each 1 second
      tobii.customFrequency = 1
      
      // start the session
      startSession()
    }
    .onReceive(engine.responseEvent, perform: handleResponse)
    .onReceive(observer.respiratoryRate, perform: handleRespiratoryRate)
    .onReceive(tobii.avgPupilSizeByFrequency, perform: handleTobiiSerialData)
    .alert(isPresented: $showAlert) {
      Alert(title: Text(alertContent))
    }
  }
}

// MARK: Observer session
extension GameView {
  private func startSession() {
    do {
      // in trial mode we still do the breath observer to see the amplitude view
      try observer.startAnalyzing()
      
      if !isTrial {
        // start read pupilDiameter after one seconds to match the observer
        // because we actually collect the data after first second on the audio session start.
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
          tobii.startReadPupilDiameter()
        }
      }
    } catch {
      running = false
      return
    }
    
    if isTrial {
      engine.setTrialTime()
    }
    
    // start the session
    engine.running = true
    
    engine.goNext()
  }
  
  private func endSession() {
    
    engine.running = false
    
    if !isTrial {
      tobii.stopReadPupilDiameter()
    }
    
    observer.stopAnalyzing()
    
    // set the correction percentage to the data
    data.computeCorrectRate()
    
    if !isTrial {
      guard !data.serialData.pupilSizes.isEmpty, !data.serialData.respiratoryRates.isEmpty else {
        alertContent = "Uh Oh.... there is no serial data 🤔, call me (Quan) please!"
        showAlert = true
        return
      }
    }
    
    // save this stage data to storage
    storage.data.append(data)
        
    // show the survey
    state = .result
  }
}

// MARK: setup key press
extension GameView {
  
  private func setupKeyPress(from event: NSEvent) {
    switch event.keyCode {
    case 53:  // escape
      // perform the stop action
      // erase the level sequence
      levelSequence = []
      
      // shut down the observers
      tobii.stopReadPupilDiameter()
      observer.stopAnalyzing()
      
      // go back to start page
      state = .start
    case 49: // space
      guard engine.running, engine.stack.atCapacity else {
        return
      }
      engine.answerYesCheck()
    default:
      break
    }
  }
}

// MARK: setup view
extension GameView {
  
  private var debugView: some View {
    VStack {
      Text(tobiiInfoText)
        .onReceive(tobii.avgPupilDiameter) { tobiiData in
          switch tobiiData {
          case .message(let content):
            self.tobiiInfoText = content
          default:
            break
          }
        }
    }
  }
}

// MARK: handle observed data subjects
extension GameView {
  
  /// Handle the received serial tobii data by the prefered frequency
  private func handleTobiiSerialData(_ pupilDialect: TobiiData) {
    guard case .data(let value) = pupilDialect else {
      return
    }
    
    data.serialData.pupilSizes.append(value)
  }
  
  /// Handle the received respiratory rate
  private func handleRespiratoryRate(_ rr: UInt8?) {
    
    print("🙆🏻", rr ?? "nil")
    
    guard !isTrial else {
      return
    }
    
    /// The serial data store continous data from the respiratory rate calculation
    /// So if the respiratory rate is not `nil`, store it in this session `StorageData`
    if let nonNilRespiratoryRate = rr {
      data.serialData.respiratoryRates.append(nonNilRespiratoryRate)
    }
    
    let pupilSize = tobii.currentPupilDialect.value
    
    guard pupilSize != -1 else {
      return
    }
    
    /// When the array is still empty, we just append the new data immidiately
    guard !data.collectedData.isEmpty else {
      return data.collectedData.append(CollectedData(pupilSize: pupilSize, respiratoryRate: rr))
    }
    
    let lastIndex = data.collectedData.count - 1
  
    /// If there is a reserved `nil` respiratory rate
    if data.collectedData[lastIndex].respiratoryRate == nil {
      /// replace the `nil` value we that set at the moment of calculation requested that we reserved
      let reservedPupilSize = data.collectedData[lastIndex].pupilSize
      let dataToReplace = CollectedData(pupilSize: reservedPupilSize, respiratoryRate: rr)
      data.collectedData[lastIndex] = dataToReplace
    } else {
      /// Otherwise, we just append the new respiratory value no matter what
      /// (we expected `nil` in this context but doesn't matter since the latest was filled), so if it is `nil`,
      /// it will be new the reserved data.
      let dataToAdd = CollectedData(pupilSize: pupilSize, respiratoryRate: rr)
      data.collectedData.append(dataToAdd)
    }
    
  }
  
  private func handleResponse(_ response: Response) {
    Task {
      if case .pressedSpace = response.reaction {
        switch response.type {
        case .correct:
          screenBackground = .green
        case .incorrect:
          screenBackground = .red
        }
      }
            
      try? await Task.sleep(nanoseconds: 300_000_000)
      withAnimation(.easeInOut(duration: 0.2)) {
        screenBackground = .background
      }
      
      data.response.append(response)
    }
  }
  
  private func handleAnalyzeTimer() {
    guard engine.running, !isTrial else {
      return
    }
    engine.reduceAnalyzeTime()
  }
  
  private func handleSessionTimer() {
    guard engine.running else {
      return
    }
    engine.reduceTime()
    // stop the session when end of time
    if engine.timeLeft == 0 {
      endSession()
    }
  }
}

#Preview {
//  @State var showAmplitude: Bool = true
  @State var state: ExperimentalState = .running(level: .easy)
  @Bindable var engine = ExperimentalEngine(level: .easy)
  @Bindable var storage = DataStorage()
  @State var breathObserver = BreathObsever()
  @State var sequence = [Level]()
  
  return GameView(
    isTrial: false, 
    data: .init(level: engine.level.name, response: [], collectedData: []),
    engine: engine, 
    state: $state,
//    showAmplitude: $showAmplitude,
    levelSequence: $sequence,
    storage: storage
  )
  .frame(minWidth: 500)
  .environment(breathObserver)
}
