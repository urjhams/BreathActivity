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
  
  private let offSet: CGFloat = 3
  
  /// debug text
  @State private var tobiiInfoText: String = ""
  
  @State private var amplitudes = [Float]()
      
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
        if showAmplitude {
          debugView
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
        switch response.type {
        case .correct:
          withAnimation(.easeInOut(duration: 0.2)) {
            switch response.reaction {
            case .doNothing:
              screenBackground = .blue
            case .pressedSpace:
              screenBackground = .green
            }
          }
          try? await Task.sleep(nanoseconds: 300_000_000)
          withAnimation(.easeInOut(duration: 0.2)) {
            screenBackground = .background
          }
          
        case .incorrect:
          withAnimation(.easeInOut(duration: 0.2)) {
            screenBackground = .red
          }
          try? await Task.sleep(nanoseconds: 300_000_000)
          withAnimation(.easeInOut(duration: 0.2)) {
            screenBackground = .background
          }
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
        tobii.startReadPupilDiameter()
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
    
    // show the survey
    state = .survey
  }
}

extension GameView {
  private enum AudioCase {
    case correct
    case incorrect
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
  
  private var debugView: some View {
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
      // scale up with 1000 because the data is something like 0,007.
      // So we would like it to start from 1 to around 80
      // add amplutudes value to draw
      amplitudes.append(value * 1000)
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
