//
//  ExperimentalView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 14.11.23.
//

import SwiftUI
import Combine
import BreathObsever

public enum ExperimentalState {
  case start
  case running(level: Level)
  case instruction(level: Level)
  case survey
}

public let levelSequences: [[Level]] = [
  [.easy, .normal, .hard],
  [.easy, .hard, .normal],
  [.normal, .easy, .hard],
  [.normal, .hard, .easy],
  [.hard, .easy, .normal],
  [.hard, .normal, .easy]
]

struct ExperimentalView: View {
  
  @State var selection: Int = 0
  
  @State var levelSequence: [Level] = [.easy, .normal, .hard]
  
  @State var isTrial = false
    
  @State var labelEnable = false
  
  @State var state: ExperimentalState = .start
  
  //TODO: use an array to store, construct the respiratory rate from amplitudes
  @Bindable var storage = DataStorage()
  
  /// breath observer
  @EnvironmentObject var observer: BreathObsever
  
  @State var showAmplitude: Bool = false
  
  var body: some View {
    VStack {
      switch state {
      case .start:
        StartView(
          selection: $selection,
          showAmplitude: $showAmplitude,
          storage: storage,
          startButtonClick: startButtonClick,
          trialButtonClick: trialButtonClick
        )
      case .running(let level):
        GameView(
          isTrial: isTrial,
          state: $state,
          showAmplitude: $showAmplitude,
          levelSequence: $levelSequence,
          engine: ExperimentalEngine(level: level),
          storage: storage
        )
        .environmentObject(observer)
      case .instruction(let level):
        // instruction view
        InstructionView(
          isTrial: isTrial,
          nBack: level.nBack,
          state: $state,
          levelSequence: $levelSequence
        )
      case .survey:
        // create survey for level
        // question: 
        // rate the difficulity of the task (0 to 5 scale)
        // how stressful is the user (0 to 5 scale)
        SurveyView(isTrial: $isTrial, levelSequence: $levelSequence, storage: storage)
      }
    }
//    .onReceive(
//      tobii.avgPupilDiameter.withLatestFrom(observer.amplitudeSubject)
//    ) { tobiiData, amplitude in
//      <#code#>
//    }
//    .onReceive(
//      observer.amplitudeSubject.withLatestFrom(tobii.avgPupilDiameter)
//    ) { (amplitude, tobiiData) in
//      
//      guard case .data(let data) = tobiiData else {
//        return
//      }
//      
//      Task { @MainActor in
//        print("\(amplitude) - \(data)")
//        // store the data into the storage
//        let collected = CollectedData(
//          amplitude: amplitude,
//          pupilSize: data
//        )
//        storage.collectedData.append(collected)
//      }
//    }
  }
}

extension ExperimentalView {
  
  func startButtonClick() {
    
    isTrial = false
    
    guard case .start = state else {
      return
    }
    
    // set the level sequences
    levelSequence = levelSequences[selection]
        
    if let first = levelSequence.first {
      // change the state to running with the first element of the array
      state = .instruction(level: first)
    }
  }
  
  func trialButtonClick() {
    
    isTrial = true
//    if running {
//      stopSession(endOfTime: false)
//    } else {
//      startTrialSession()
//    }
  }
}

extension ExperimentalView {
  
//  private func startTrialSession() {
//    // turn on the trial model
//    engine.trialMode = true
//    labelEnable = true
//    // manually set easy level for trial mode
//    engine.stack.level = .easy
//    
//    // start the session
//    running = true
//    
//    engine.state = .start
//    engine.goNext()
//  }
//  
//  private func startSession() {
//    // turn off the trial model
//    engine.trialMode = false
//    
//    // set level name for storage
//    storage.level = engine.stack.level.name
//    
//    // start analyze process
//    do {
//      try observer.startAnalyzing()
//      tobii.startReadPupilDiameter()
//    } catch {
//      running = false
//      return
//    }
//    
//    // start the session
//    running = true
//    
//    engine.state = .start
//    engine.goNext()
//  }
//  
//  private func stopSession(endOfTime: Bool) {
//    
//    if endOfTime, !engine.trialMode {
//      IOManager.tryToWrite(storage)
//    }
//    
//    labelEnable = false
//    
//    // stop analyze process
//    tobii.stopReadPupilDiameter()
//    observer.stopAnalyzing()
//    
//    // stop the session
//    running = false
//    
//    // reset the storage
//    storage.reset()
//    
//    engine.state = .stop
//    
//    // reset engine
//    engine.reset()
//  }
}

#Preview {
  
  @StateObject var breathObserver = BreathObsever()
  
  return ExperimentalView()
    .frame(minWidth: 500)
    .environmentObject(breathObserver)
}
