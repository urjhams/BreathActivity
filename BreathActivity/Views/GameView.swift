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

struct MakeKeyPressSilentView: NSViewRepresentable {
  
  class KeyView: NSView {
    func isManagedByThisView(_ event: NSEvent) -> Bool {
      // just a work around so we always return true
      return true
    }
    
    override var acceptsFirstResponder: Bool { true }
    override func keyDown(with event: NSEvent) {
      guard isManagedByThisView(event) else {
        // in `super.keyDown(with: event)`,
        // the event goes up through the responder chain
        // and if no other responders process it, causes beep sound.
        return super.keyDown(with: event)
      }
      // print("pressed \(event.keyCode)")
    }
  }
  
  func makeNSView(context: Context) -> NSView {
    let view = KeyView()
    DispatchQueue.main.async { // wait till next event cycle
      view.window?.makeFirstResponder(view)
    }
    return view
  }
  
  func updateNSView(_ nsView: NSView, context: Context) { }
  
}

struct GameView: View {
  
  @Binding var state: ExperimentalState
  
  @Binding var enableLabel: Bool
    
  @State var screenBackground: Color = .background
  
  @State var running = false
  
  @Binding var showAmplitude: Bool
  
  private let offSet: CGFloat = 3
  
  /// debug text
  @State private var tobiiInfoText: String = ""
  
  @State private var amplitudes = [Float]()
    
  @State private var description = "description"
  
  @Binding var levelSequences: [Level]
    
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
          //TODO: stop session function
          // TODO: make the order as array, so after finish one level, remove the first element, and set level as the first one left
          state = .instruction(level: .easy)
        }
      }
      .padding()
    }
    .background(screenBackground)
    .onReceive(engine.responseEvent) { response in
      Task {
        // correct when pressing space: green
        // correct by not select the un-matched image: blue
        // any kind of incorrect: red
        switch response.type {
        case .correct(let selected):
          let color: Color = selected ? .green : .blue
          withAnimation(.easeInOut(duration: 0.2)) {
            screenBackground = color
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
        storage.responses.append(response)
      }
    }
    .onReceive(
      tobii.avgPupilDiameter.withLatestFrom(observer.amplitudeSubject)
    ) { tobiiData, amplitude in
      
    }
    .onAppear {
      // set level for storage
      storage.level = engine.stack.level.name
      // key pressed notification register
      NSEvent.addLocalMonitorForEvents(matching: [.keyUp]) { event in
        self.setupKeyPress(from: event)
        return event
      }
      
      // TODO: start a session with level, remove the engine state.
      engine.running = true
    }
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
      state = .start
    case 49: // space
      guard engine.running else {
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
  @State var label: Bool = true
  @State var showAmplitude: Bool = false
  @State var sound = false
  @State var state: ExperimentalState = .running(level: .easy)
  @Bindable var engine = ExperimentalEngine(level: .easy)
  @Bindable var storage = DataStorage()
  @StateObject var breathObserver = BreathObsever()
  @State var sequence = [Level]()
  
  return GameView(
    state: $state,
    enableLabel: $label,
    showAmplitude: $showAmplitude,
    levelSequences: $sequence,
    engine: engine,
    storage: storage
  )
  .frame(minWidth: 500)
  .environmentObject(breathObserver)
}
