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
  case trial(level: Level)
  case instruction(level: Level)
}

struct ExperimentalView: View {
    
  @State var labelEnable = false
  
  @State var state: ExperimentalState = .start
          
  @State var running = false
    
  // TODO: we don't need to bind engine anymore, create the engine whenever we present a GameView instead to defind which level it is
  // the engine that store the stack to check
//  @Bindable var engine = ExperimentalEngine()
  
  // use an array to store, construct the respiratory rate from amplitudes
  @Bindable var storage = DataStorage()
  
  /// Tobii tracker object that read the python script
  @Environment(\.tobiiTracker) var tobii
  
  /// breath observer
  @EnvironmentObject var observer: BreathObsever
  
  @State var showAmplitude: Bool = false
  
  var body: some View {
    VStack {
      switch state {
      case .start:
        StartView(
          showAmplitude: $showAmplitude,
          storage: storage,
          startButtonClick: startButtonClick,
          trialButtonClick: trialButtonClick
        )
      case .running(let level):
        GameView(
          state: $state,
          enableLabel: $labelEnable,
          running: $running,
          showAmplitude: $showAmplitude,
          engine: ExperimentalEngine(level: level),
          storage: storage
        )
        .environmentObject(observer)
      case .instruction(let level):
        // TODO: create instruction view
        Spacer()
      case .trial(let level):
        // TODO: create trial view seperate with game view
        Spacer()
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
//    if running {
//      // stop process
//      stopSession(endOfTime: false)
//    } else {
//      // start process
//      startSession()
//    }
  }
  
  func trialButtonClick() {
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
