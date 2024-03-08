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

struct GameView: View {
  
  let isTrial: Bool
  
  @Binding var state: ExperimentalState
      
  @State var screenBackground: Color = .background
  
  @State var running = false
  
  @Binding var showAmplitude: Bool
  
  /// The flag to make sure we observe the data after the a bit of inital time
  @State var processing = false
  
  /// debug text
  @State private var tobiiInfoText: String = ""
  
  @State private var amplitudes = [Float]()
  
  /// Container to store the current level and the next levels
  @Binding var levelSequence: [Level]
    
  // the engine that store the stack to check
  @State var engine: ExperimentalEngine
  
  // use an array to store, construct the respiratory rate from amplitudes
  @Bindable var storage: DataStorage
  
  /// Tobii tracker object that read the python script
  @Environment(\.tobiiTracker) var tobii
  
  /// breath observer
  @EnvironmentObject var observer: BreathObsever
  
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
        switch (isTrial, showAmplitude) {
        case (true, _):
          debugView()
        case (false, let showAmplitude):
          if showAmplitude {
            debugView()
          }
        }
        // work-around view to disable the "funk" error sound when click on keyboard on macOS
        MakeKeyPressSilentView()
          .frame(height: 0)
      }
      .onReceive(engine.sessionTimer) { _ in
        guard engine.running else {
          return
        }
        engine.reduceTime()
        // stop the session when end of time
        if engine.timeLeft == 0 {
          endSession()
        }
      }
      .onReceive(engine.analyzeTimer) { _ in
        guard engine.running, !isTrial else {
          return
        }
        engine.reduceAnalyzeTime()
      }
      .padding()
    }
    .background(screenBackground)
    .onReceive(engine.responseEvent) { response in
      Task {
        guard case .pressedSpace = response.reaction else {
          return
        }
        
        switch response.type {
        case .correct:
          screenBackground = .green
        case .incorrect:
          screenBackground = .red
        }
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        withAnimation(.easeInOut(duration: 0.2)) {
          screenBackground = .background
        }
        
        if !isTrial {
          storage.responses.append(response)
        }
      }
    }
    .onReceive(
      tobii.avgPupilDiameter.withLatestFrom(observer.amplitudeSubject)
    ) { tobiiData, amplitude in
      guard !isTrial else {
        return
      }
    }
    .onAppear {
      // key pressed notification register
      NSEvent.addLocalMonitorForEvents(matching: [.keyUp]) { event in
        self.setupKeyPress(from: event)
        return event
      }
      
      // set level for storage
      storage.level = engine.stack.level.name
      
      // start the session
      startSession()
    }
  }
}

extension GameView {
  private func startSession() {
    do {
      // in trial mode we still do the breath observer to see the amplitude view
      try observer.startAnalyzing()
      
      if !isTrial {
        // start read pupilDiameter after one seconds to match the observer
        // because we actually collect the data after first second on the audio session start.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          tobii.startReadPupilDiameter()
        }
      }
    } catch {
      running = false
      return
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
    
    handleCollectedData()
    
    // show the survey
    state = .survey
  }
}

extension GameView {
  
  private func handleCollectedData() {
    // TODO: in the breath observer, we use another passthroughSubject that store the respiratory rate data
    // TODO: append the data of this level in the storage
    
  }
  
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

extension GameView {
  
  private var offSet: CGFloat {
    1
  }
  
  @ViewBuilder
  private func debugView() -> some View {
    VStack {
      Text(tobiiInfoText)
      
      amplitudeView
        .frame(height: 80 * offSet)
        .scenePadding([.leading, .trailing])
        .padding()
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
      amplitudes.append(value)
      let amplitudesInOneSec = Int(Int(BreathObsever.sampleRate) / BreathObsever.samples)
      // keep only data of 5 seconds of amplirudes
      if amplitudes.count >= BreathObsever.windowTime * amplitudesInOneSec {
        amplitudes.removeFirst()
      }
    }
    .padding()
  }
  
  private var amplitudeView: some View {
    HStack(spacing: 1) {
      ForEach(0..<amplitudes.count, id: \.self) { index in
        RoundedRectangle(cornerRadius: 2)
          .frame(width: offSet, height: CGFloat(amplitudes[index]) / 10)
          .foregroundColor(.white)
      }
    }
    .frame(height: 250)
  }
}

#Preview {
  @State var showAmplitude: Bool = false
  @State var sound = false
  @State var state: ExperimentalState = .running(level: .easy)
  @Bindable var engine = ExperimentalEngine(level: .easy)
  @Bindable var storage = DataStorage()
  @StateObject var breathObserver = BreathObsever()
  @State var sequence = [Level]()
  
  return GameView(
    isTrial: false,
    state: $state,
    showAmplitude: $showAmplitude,
    levelSequence: $sequence,
    engine: engine,
    storage: storage
  )
  .frame(minWidth: 500)
  .environmentObject(breathObserver)
}
