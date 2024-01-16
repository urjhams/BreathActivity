//
//  ExperimentalView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 14.11.23.
//

import SwiftUI
import Combine
import BreathObsever

struct ExperimentalView: View {
          
  @State var running = false
    
  // the engine that store the stack to check
  @Bindable var engine = ExperimentalEngine()
  
  // use an array to store, construct the respiratory rate from amplitudes
  @Bindable var storage = DataStorage()
  
  /// Tobii tracker object that read the python script
  @EnvironmentObject var tobii: TobiiTracker
  
  /// breath observer
  @EnvironmentObject var observer: BreathObsever
  
  @State var showAmplitude: Bool = false
  
  var body: some View {
    VStack {
      
      if running {
        GameView(
          running: $running,
          showAmplitude: $showAmplitude,
          stopSessionFunction: stopSession,
          engine: engine,
          storage: storage
        )
        .environmentObject(tobii)
        .environmentObject(observer)
      } else {
        StartView(
          showAmplitude: $showAmplitude,
          engine: engine,
          storage: storage,
          startButtonClick: startButtonClick
        )
      }
    }
    .onReceive(
      observer.amplitudeSubject.withLatestFrom(tobii.avgPupilDiameter)
    ) { (amplitude, tobiiData) in
      
      guard case .data(let data) = tobiiData else {
        return
      }
      
      Task { @MainActor in
        print("\(amplitude) - \(data) - \( engine.stack.level.rawValue)")
        // store the data into the storage
        let collected = CollectedData(
          amplitude: amplitude,
          pupilSize: data
        )
        storage.collectedData.append(collected)
      }
    }
  }
}

extension ExperimentalView {
  
  func startButtonClick() {
    if running {
      // stop process
      stopSession()
    } else {
      // start process
      startSession(engine.stack.level)
    }
  }
}

extension ExperimentalView {
  private func startSession(_ level: Level) {
    // set level name for storage
    storage.level = engine.stack.level.name
    print("level: \(storage.level)")
    
    // start analyze process
    do {
      try observer.startAnalyzing()
      tobii.startReadPupilDiameter()
    } catch {
      running = false
      return
    }
    
    // start the session
    running = true
    
    engine.state = .start
    engine.goNext()
  }
  
  private func stopSession() {
    // stop analyze process
    tobii.stopReadPupilDiameter()
    observer.stopAnalyzing()
    
    // stop the session
    running = false
    
    // reset the storage
    storage.reset()
    
    engine.state = .stop
    
    // reset engine
    engine.reset()
  }
}

#Preview {
  
  @StateObject var tobii = TobiiTracker()
  @StateObject var breathObserver = BreathObsever()
  
  return ExperimentalView()
    .frame(minWidth: 500)
    .environmentObject(tobii)
    .environmentObject(breathObserver)
}
