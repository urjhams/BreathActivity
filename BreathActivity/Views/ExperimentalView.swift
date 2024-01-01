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

internal class ExperimentalEngine: ObservableObject {
  @Published var stack = ImageStack(level: .easy)
  
  var current: String? {
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

}

// TODO: do the simple stack to keep n latest image (name)
// The size of the stack will be equal to the step (n)
// then we just need to check the top of the stack to match with the bottom
// when the user select "yes"
struct ExperimentalView: View {
  
  let images: [String] = []
    
  @State var levelTime: Int = 180
  
  let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  
  @State var level: Level = .easy
      
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
  
  private let offSet: CGFloat = 3
  
  var body: some View {
    VStack {
      
      if running {
        if let currentImage = engine.current {
          Image(currentImage)
        }
        if showAmplitude {
          Spacer()
          debugView
        }
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
        print("\(amplitude) - \(data) - \(level.rawValue)")
        // store the data into the storage
        let collected = CollectedData(
          amplitude: amplitude,
          pupilSize: data,
          currentLevel: level.name
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
  
  private var debugView: some View {
    VStack {
      Text(tobiiInfoText)
      
      amplitudeView
        .frame(height: 80 * offSet)
        .scenePadding([.leading, .trailing])
        .padding()
    }
  }
  
  private var amplitudeView: some View {
    ScrollView(.vertical) {
      HStack(spacing: 1) {
        ForEach(amplitudes, id: \.self) { amplitude in
          RoundedRectangle(cornerRadius: 2)
            .frame(width: offSet, height: CGFloat(amplitude) * offSet)
            .foregroundColor(.white)
        }
      }
    }
  }
  
  func startButtonClick() {
    if running {
      // stop process
      stopSession()
    } else {
      // start process
      startSession()
    }
  }
}

extension ExperimentalView {
  private func startSession() {
    // start analyze process
    do {
      try observer.startAnalyzing()
      tobii.startReadPupilDiameter()
      amplitudes = []
      running = true
    } catch {
      running = false
      return
    }
    
    // show the first few images (less than the number of target/ stack capacity)
    
    // show a random image and the yes no buttons, do the check when recieve answer
    
    // record the correction
    
    // when the remaining time is 0
    // if the current level is not "hard", stop the session, store the data
    
    // else reset it and increase level and start a new session
  }
  
  private func stopSession() {
    // stop analyze process
    tobii.stopReadPupilDiameter()
    observer.stopAnalyzing()
    running = false
    
    // stop the session
    
    // reset the storage
    storage.reset()
  }
}

struct StartView: View {
  
  @Binding var showAmplitude: Bool
  
  // the engine that store the stack to check
  @ObservedObject var engine: ExperimentalEngine
  
  // use an array to store, construct the respiratory rate from amplitudes
  @ObservedObject var storage: DataStorage
  
  var startButtonClick: () -> Void
  
  var body: some View {
    VStack {
      TextField("Candidate Name", text: $storage.candidateName)
        .padding(.all)
        .clipShape(.rect(cornerRadius: 10))
      Picker("Level", selection: $engine.stack.level) {
        ForEach(Level.allCases, id: \.self) { level in
          Text(level.name)
        }
      }
      .pickerStyle(.radioGroup)
      .horizontalRadioGroupLayout()
      .frame(maxWidth: .infinity)
      .padding(.leading)
    }
    .padding(20)
    
    Text("Each Level will be 2 minutes (180 seconds)")
    Text("Press left arrow button for \"Yes\"")
    Text("and right arrow button for \"No\".")
    
    Spacer()
    
    Picker("Show amplitude", selection: $showAmplitude) {
      Text("Yes").tag(true)
      Text("No").tag(false)
    }
    .pickerStyle(.radioGroup)
    .horizontalRadioGroupLayout()
    
    Button(action: startButtonClick) {
      Image(systemName: "play.fill")
        .font(.largeTitle)
    }
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
