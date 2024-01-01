//
//  ExperimentalView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 14.11.23.
//

import SwiftUI
import Combine
import BreathObsever
import GameController

internal struct CollectedData {
  let amplitude: Float
  let pupilSize: Float
  let currentLevel: String
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
    case starting
    case started
    case stopped
  }
  
  @Published var state: State = .stopped
  
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
    state = .stopped
  }
  
  func addImage() {
    guard let image = images.randomElement() else {
      return
    }
    
    stack.add(image)
  }

}

// TODO: do the simple stack to keep n latest image (name)
// The size of the stack will be equal to the step (n)
// then we just need to check the top of the stack to match with the bottom
// when the user select "yes"
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
  
  /// debug text
  @State var tobiiInfoText: String = ""
  
  @State var amplitudes = [Float]()
  
  var body: some View {
    VStack {
      
      if running {
        GameView(
          tobiiInfoText: $tobiiInfoText,
          amplitudes: $amplitudes,
          showAmplitude: $showAmplitude,
          engine: engine,
          storage: storage
        )
      } else {
        StartView(
          showAmplitude: $showAmplitude,
          engine: engine,
          storage: storage,
          startButtonClick: startButtonClick
        )
      }
    }
    .onAppear {
      // key pressed
      NSEvent.addLocalMonitorForEvents(matching: [.keyUp]) { event in
        self.setupKeyPress(from: event)
        return event
      }
      
      // xbox controller key pressed
      NotificationCenter.default.addObserver(
        forName: .GCControllerDidConnect,
        object: nil,
        queue: nil
      ) { notification in
        if let controller = notification.object as? GCController {
          self.setupController(controller)
        }
      }
      
      for controller in GCController.controllers() {
        self.setupController(controller)
      }
    }
    .onReceive(tobii.avgPupilDiameter) { tobiiData in
      switch tobiiData {
      case .message(let content):
        self.tobiiInfoText = content
      default:
        break
      }
    }
    .onReceive(observer.amplitudeSubject) { value in
      // scale up with 1000 because the data is something like 0,007.
      // So we would like it to start from 1 to around 80
      amplitudes.append(value * 1000)
    }
    .onReceive(
      observer.amplitudeSubject.withLatestFrom(tobii.avgPupilDiameter)
    ) { (amplitude, tobiiData) in
      
      guard case .data(let data) = tobiiData else {
        return
      }
      
      // scale up with 1000 because the data is something like 0,007.
      // So we would like it to start from 1 to around 80
      // add amplutudes value to draw
      amplitudes.append(amplitude * 1000)
      
      Task { @MainActor in
        print("\(amplitude) - \(data) - \( engine.stack.level.rawValue)")
        // store the data into the storage
        let collected = CollectedData(
          amplitude: amplitude,
          pupilSize: data,
          currentLevel: engine.stack.level.name
        )
        storage.collectedData.append(collected)
      }
    }
    .padding()
  }
}

extension ExperimentalView {
  private func setupKeyPress(from event: NSEvent) {
    switch event.keyCode {
    case 53:  // escape
      // perform the stop action
      stopSession()
    case 123: // left arrow
      if self.running {
        // TODO: active the "Yes" selected state
        print("pressed left")
      }
    case 124: // right arrow
      if self.running {
        // TODO: active the "No" selected state
        print("pressed right")
      }
    default:
      break
    }
  }
  
  private func setupController(_ controller: GCController) {
    controller.extendedGamepad?.buttonA.valueChangedHandler = {  _, _, pressed in
      guard pressed, running else {
        return
      }
      // TODO: active the "Yes" selected state
       print("pressed Yes (A)")
    }
    
    controller.extendedGamepad?.buttonB.valueChangedHandler = { _, _, pressed in
      guard pressed, running else {
        return
      }
      // TODO: active the "No" selected state
       print("pressed No (B)")
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
    // start analyze process
    do {
      try observer.startAnalyzing()
      tobii.startReadPupilDiameter()
      amplitudes = []
    } catch {
      running = false
      return
    }
    
    // start the session
    running = true
    
    engine.state = .starting
    
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
