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
  
  @State var gameSoundEnable = true
  
  @State var labelEnable = false
          
  @State var running = false
    
  // the engine that store the stack to check
  @Bindable var engine = ExperimentalEngine()
  
  // use an array to store, construct the respiratory rate from amplitudes
  @Bindable var storage = DataStorage()
  
  /// Tobii tracker object that read the python script
  @Environment(\.tobiiTracker) var tobii
  
  /// breath observer
  @EnvironmentObject var observer: BreathObsever
  
  @State var showAmplitude: Bool = false
  
  var body: some View {
    VStack {
      
      if running {
        GameView(
          enableLabel: $labelEnable,
          isSoundEnable: $gameSoundEnable,
          running: $running,
          showAmplitude: $showAmplitude,
          stopSessionFunction: stopSession,
          engine: engine,
          storage: storage
        )
        .environmentObject(observer)
      } else {
        StartView(
          isSoundEnable: $gameSoundEnable,
          showAmplitude: $showAmplitude,
          engine: engine,
          storage: storage,
          startButtonClick: startButtonClick, 
          trialButtonClick: trialButtonClick
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
        print("\(amplitude) - \(data)")
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
      stopSession(byEndOfTime: false)
    } else {
      // start process
      startSession()
    }
  }
  
  func trialButtonClick() {
    if running {
      stopSession(byEndOfTime: false)
    } else {
      startTrialSession()
    }
  }
}

extension ExperimentalView {
  
  private func startTrialSession() {
    // turn on the trial model
    engine.trialMode = true
    labelEnable = true
    // manually set easy level for trial mode
    engine.stack.level = .easy
    
    // start the session
    running = true
    
    engine.state = .start
    engine.goNext()
  }
  
  private func startSession() {
    // turn off the trial model
    engine.trialMode = false
    
    // set level name for storage
    storage.level = engine.stack.level.name
    
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
  
  private func stopSession(byEndOfTime: Bool) {
    
    if byEndOfTime, !engine.trialMode {
      IOManager.tryToWrite(storage)
    }
    
    labelEnable = false
    
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

public class IOManager {
  static func tryToWrite(_ storage: DataStorage) {
    let fileName = "\(storage.candidateName) - \(storage.level)"
    let fileUrl = try? FileManager
      .default
      .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent(fileName, conformingTo: .json)
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    
    if let fileUrl {
      try? encoder.encode(storage).write(to: fileUrl)
    }
  }
  
  static func tryToRead(from fileName: String) -> DataStorage? {
    let fileUrl = try? FileManager
      .default
      .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent(fileName, conformingTo: .json)
    
    guard let fileUrl, let data = try? Data(contentsOf: fileUrl) else {
      return nil
    }
    
    let decoder = JSONDecoder()
    return try? decoder.decode(DataStorage.self, from: data)
  }
}

extension Encodable {
  /// Converting object to postable JSON
  func toJSON(_ encoder: JSONEncoder = JSONEncoder()) throws -> String {
    let data = try encoder.encode(self)
    return String(decoding: data, as: UTF8.self)
  }
}

#Preview {
  
  @StateObject var breathObserver = BreathObsever()
  
  return ExperimentalView()
    .frame(minWidth: 500)
    .environmentObject(breathObserver)
}
