//
//  GameView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 01.01.24.
//

import SwiftUI
import GameController
import BreathObsever

struct GameView: View {
  
  @State var screenBackground: Color = .background
  
  @Binding var running: Bool
  
  @Binding var showAmplitude: Bool
  
  private let offSet: CGFloat = 3
  
  /// debug text
  @State private var tobiiInfoText: String = ""
  
  @State private var amplitudes = [Float]()
    
  @State private var description = "description"
  
  var stopSessionFunction: () -> ()
  
  // the engine that store the stack to check
  @Bindable var engine: ExperimentalEngine
  
  // use an array to store, construct the respiratory rate from amplitudes
  @Bindable var storage: DataStorage
  
  /// Tobii tracker object that read the python script
  @EnvironmentObject var tobii: TobiiTracker
  
  /// breath observer
  @EnvironmentObject var observer: BreathObsever
  
  var body: some View {
    ZStack {
      VStack {
        Text("Time left: \(engine.timeLeft)s")
          .onReceive(engine.sessionTimer) { _ in
            guard case .running = engine.state else {
              return
            }
            engine.reduceTime()
          }
          .padding()
          .onReceive(engine.analyzeTimer) { _ in
            guard [.running, .start].contains(engine.state) else {
              return
            }
            engine.reduceAnalyzeTime()
          }
        if let currentImage = engine.current {
          Spacer()
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
          Spacer()
        } else {
          Color(.clear)
        }
        Text({
          switch engine.state {
          case .running:
            "running"
          case .start:
            "start"
          case .stop:
            "stop"
          }
        }())
        if showAmplitude {
          Spacer()
          debugView
        }
      }
      .padding()
    }
    .background(screenBackground)
    .onReceive(engine.responseEvent) { event in
      print("event: \(event.rawValue)")
      Task {
        switch event {
        case .correct:
          withAnimation(.easeInOut(duration: 0.2)) {
            screenBackground = .green
          }
          try? await Task.sleep(nanoseconds: 1_000_000_000)
          withAnimation(.easeInOut(duration: 0.2)) {
            screenBackground = .background
          }
          
        case .incorrect:
          withAnimation(.easeInOut(duration: 0.2)) {
            screenBackground = .red
          }
          try? await Task.sleep(nanoseconds: 1_000_000_000)
          withAnimation(.easeInOut(duration: 0.2)) {
            screenBackground = .background
          }
        }
      }
    }
    .onAppear {
      // key pressed notification register
      NSEvent.addLocalMonitorForEvents(matching: [.keyUp]) { event in
        self.setupKeyPress(from: event)
        return event
      }
    }
  }
}

extension GameView {
  private func setupKeyPress(from event: NSEvent) {
    switch event.keyCode {
    case 53:  // escape
              // perform the stop action
      stopSessionFunction()
    case 49: // space
      guard self.running else {
        return
      }
      if case .running = engine.state {
        let reactionTime = engine.answerYesCheck()
        // TODO: might to use this with the storage
        print("reaction time: \(reactionTime)")
      }
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
  @State var running: Bool = true
  @State var showAmplitude: Bool = false
  @Bindable var engine = ExperimentalEngine()
  @Bindable var storage = DataStorage()
  
  return GameView(
    running: $running,
    showAmplitude: $showAmplitude,
    stopSessionFunction: {},
    engine: engine,
    storage: storage
  )
  .frame(minWidth: 500)
}
