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
  
  @Binding var enableLabel: Bool
  private var opacity: Double {
    switch engine.state {
    case .start:
      return 1
    default:
      return enableLabel ? 1 : 0
    }
  }
  
  @Binding var isSoundEnable: Bool
  
  @State var screenBackground: Color = .background
  
  @Binding var running: Bool
  
  @Binding var showAmplitude: Bool
  
  private let offSet: CGFloat = 3
  
  /// debug text
  @State private var tobiiInfoText: String = ""
  
  @State private var amplitudes = [Float]()
    
  @State private var description = "description"
  
  var stopSessionFunction: (Bool) -> ()
  
  // the engine that store the stack to check
  @Bindable var engine: ExperimentalEngine
  
  // use an array to store, construct the respiratory rate from amplitudes
  @Bindable var storage: DataStorage
  
  /// Tobii tracker object that read the python script
  @Environment(\.tobiiTracker) var tobii
  
  /// breath observer
  @EnvironmentObject var observer: BreathObsever
  
  var promtText: String {
    switch engine.state {
    case .running:
      "Does this image matches the first of the last \(engine.stack.level.rawValue) images were shown?"
    case .start:
      "Remember this Image"
    case .stop:
      "stop state (this screen should not appear in this state)"
    }
  }
  
  var body: some View {
    ZStack {
      VStack {
        Text("Time left: \(engine.timeLeft)s")
          .onReceive(engine.sessionTimer) { _ in
            guard case .running = engine.state else {
              return
            }
            engine.reduceTime()
            // stop the session when end of time
            if engine.timeLeft == 0 {
              stopSessionFunction(true)
            }
          }
          .padding()
          .onReceive(engine.analyzeTimer) { _ in
            guard [.running, .start].contains(engine.state) else {
              return
            }
            engine.reduceAnalyzeTime()
          }
          .opacity(engine.trialMode ? 1 : 0)
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
        Text(promtText)
          .opacity(opacity)
        if case .running = engine.state {
          Text("Press space if they are matched")
            .opacity(opacity)
        }
        Spacer()
        if showAmplitude {
          debugView
        }
        // work-around view to disable the "funk" error sound when click on keyboard on macOS
        MakeKeyPressSilentView()
          .frame(height: 0)
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
          if isSoundEnable {
            playSound(.correct)
          }
          withAnimation(.easeInOut(duration: 0.2)) {
            screenBackground = color
          }
          try? await Task.sleep(nanoseconds: 300_000_000)
          withAnimation(.easeInOut(duration: 0.2)) {
            screenBackground = .background
          }
          
        case .incorrect:
          if isSoundEnable {
            playSound(.incorrect)
          }
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
    .onAppear {
      // set level for storage
      storage.level = engine.stack.level.name
      // key pressed notification register
      NSEvent.addLocalMonitorForEvents(matching: [.keyUp]) { event in
        self.setupKeyPress(from: event)
        return event
      }
    }
  }
}

extension GameView {
  private enum AudioCase {
    case correct
    case incorrect
  }
  
  private func playSound(_ kind: AudioCase) {
    let audio = switch kind {
    case .correct:
      NSDataAsset(name: "correct")?.data
    case .incorrect:
      NSDataAsset(name: "failure")?.data
    }
    
    guard let audio else {
      return
    }
    engine.audioPlayer = try? AVAudioPlayer(data: audio)
    engine.audioPlayer?.volume = 0.02  // set the volume as low as possible
    engine.audioPlayer?.play()
  }
  
  private func setupKeyPress(from event: NSEvent) {
    switch event.keyCode {
    case 53:  // escape
              // perform the stop action
      stopSessionFunction(false)
    case 49: // space
      guard self.running else {
        return
      }
      if case .running = engine.state {
        engine.answerYesCheck()
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
  @State var label: Bool = true
  @State var running: Bool = true
  @State var showAmplitude: Bool = false
  @State var sound = false
  @Bindable var engine = ExperimentalEngine()
  @Bindable var storage = DataStorage()
  
  return GameView(
    enableLabel: $label,
    isSoundEnable: $sound,
    running: $running,
    showAmplitude: $showAmplitude,
    stopSessionFunction: {_ in },
    engine: engine,
    storage: storage
  )
  .frame(minWidth: 500)
}
