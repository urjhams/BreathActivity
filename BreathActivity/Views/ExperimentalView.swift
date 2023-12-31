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
  let currentLevel: String
}

internal class DataStorage: ObservableObject {
  @Published var candidateName: String = ""
  var level: String = ""
  var collectedData: [CollectedData] = []
  
  public func reset() {
    candidateName = ""
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
  
  let images: [String]
  
  // the engine that store the stack to check
  @StateObject var engine = ExperimentalEngine()
    
  @State var levelTime: Int
  
  let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  
  @State var level: Level = .easy
    
  @FocusState private var focused: Bool
  
  @State var running = false
  
  var currentImage: String? = nil
  
  @State var amplitudes = [Float]()
  
  private let offSet: CGFloat = 3
  
  @State var showDebbug: Bool
  
  /// debug text
  @State var debugContent: String = ""
  
  // use an array to store, construct the respiratory rate from amplitudes
  @StateObject var storage = DataStorage()
  
  /// Tobii tracker object that read the python script
  @EnvironmentObject var tobii: TobiiTracker
  
  /// breath observer
  @EnvironmentObject var observer: BreathObsever
  
  var body: some View {
    VStack {
      
      if running {
        if let currentImage {
          Image(currentImage)
        }
        if showDebbug {
          Spacer()
          debugView
        }
      } else {
        HStack {
          TextField("Candidate", text: $storage.candidateName)
            .padding(.all)
            .clipShape(.rect(cornerRadius: 10))
        }
        Spacer()
        startView
      }
    }
    // focus state have a border so we apply the focus and keypress receiver
    // on a spacer
    .focusable()
    .focused($focused)
    .onAppear {
      focused = true
    }
    .onDisappear {
      focused = false
    }
    .onKeyPress(.space) {
      print("pressed space")
      return .handled
    }
    .onReceive(tobii.avgPupilDiameter) { tobiiData in
      switch tobiiData {
      case .message(let content):
        self.debugContent = content
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
          currentLevel: level.rawValue
        )
        storage.collectedData.append(collected)
      }
    }
    .padding()
  }
}

extension ExperimentalView {
  
  private var debugView: some View {
    VStack {
      Text(debugContent)
      
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
  
  private var startView: some View {
    HStack {
      Button {
        if running {
          // stop process
          stopSession()
        } else {
          // start process
          startSession()
        }
      } label: {
        Image(systemName: "play.fill")
          .font(.largeTitle)
          .foregroundStyle(.mint)
      }
    }
    .padding()
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

#Preview {
  
  @StateObject var tobii = TobiiTracker()
  @StateObject var breathObserver = BreathObsever()
  
  return ExperimentalView(images: [], levelTime: 180, showDebbug: false)
    .frame(minWidth: 500)
    .environmentObject(tobii)
    .environmentObject(breathObserver)
}
