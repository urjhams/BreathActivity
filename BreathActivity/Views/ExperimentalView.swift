//
//  ExperimentalView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 14.11.23.
//

import SwiftUI
import Combine
import BreathObsever

internal struct CollectedData {
  let amplitude: Float
  let pupilSize: Float
}

internal class DataStorage: ObservableObject {
  @Published var candidateName: String = ""
  var level: String = ""
  var collectedData: [CollectedData] = []
  
  public func reset() {
    level = ""
    collectedData = []
  }
}

public class ExperimentalEngine: ObservableObject {
  
  public enum State {
    case start
    case running
    case stop
  }
  
  @Published var state: State = .stop
  
  @Published var stack = ImageStack(level: .easy)
  
  let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  
  @Published var levelTime: Int = 180
  
  // TODO: maybe add 2 more set of images
  let images: [ImageResource] = [
    .animalfaceCheetah,
    .animalfaceDuck,
    .animalfaceNiwatori,
    .animalfacePanda,
    .animalfaceTora,
    .animalfaceUma,
    .animalfaceUsagi,
    .animalfaceZou
  ]
    
  var current: ImageResource? {
    stack.peek()
  }
  
  // check the current image is matched with the target image or not
  // current image is the last image, which added latest into the stack
  // target image is the first image in the bottom of the stack
  func matched() throws -> Bool {
    
    guard let peak = stack.peek(), let bottom = stack.bottom() else {
      throw ImageStack.StackError.noPeakNorBottom
    }
    
    return peak == bottom
  }
  
  func reset() {
    levelTime = 180
    stack.setEmpty()
    state = .stop
  }
  
  func addImage() {
    guard let image = images.randomElement() else {
      return
    }
    
    stack.add(image)
  }
  
  /// add image when not in at capacity
  func goNext() {
    guard !stack.atCapacity else {
      return
    }
    
    addImage()
  }
  
  /// When click yes, check does it match the target image
  func answerYesCheck() throws -> Bool {
    try matched()
  }
  
  /// When click  no, check does it NOT match the target image
  func answerNoCheck() throws -> Bool {
    try !matched()
  }

}

struct ExperimentalView: View {
          
  @State var running = false
    
  // the engine that store the stack to check
  @StateObject var engine = ExperimentalEngine()
  
  // use an array to store, construct the respiratory rate from amplitudes
  @StateObject var storage = DataStorage()
  
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
    .padding()
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
    
    // show the first few images (less than the number of target/ stack capacity)
    
    // show a random image and the yes no buttons, do the check when recieve answer
    
    // record the correction
    
    // when the remaining time is 0, stop the session, store the data
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
