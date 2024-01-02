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
  
  @Binding var running: Bool
  
  @Binding var showAmplitude: Bool
  
  private let offSet: CGFloat = 3
  
  /// debug text
  @State private var tobiiInfoText: String = ""
  
  @State private var amplitudes = [Float]()
    
  @State private var description = "description"
  
  @State private var nextClicked = false {
    didSet {
      if nextClicked {
        // wait for 0.5 seconds then switch back to false
        withAnimation(.easeInOut(duration: 0.5)) {
          nextClicked = false
        }
        
        // submit command
        engine.goNext()
      }
    }
  }
  
  @State private var yesClicked = false {
    didSet {
      if yesClicked {
        // submit command
        
        let result = try? engine.answerYesCheck()
        
        if let result {
          // blink the background
          
          // play audio
          
          // record the result
          
        }
        
        // wait for 0.5 seconds then switch back to false
        withAnimation(.easeInOut(duration: 0.5)) {
          yesClicked = false
        }
        
        // go next image
        engine.addImage()
      }
    }
  }
  
  @State private var noClicked = false {
    didSet {
      if noClicked {
        // submit command
        let result = try? engine.answerNoCheck()
        if let result {
          //blink the background
          
          // play audio
          
          //record the result
          
        }
        
        // wait for 0.5 seconds then switch back to false
        withAnimation(.easeInOut(duration: 0.5)) {
          noClicked = false
        }
        
        // go next image
        engine.addImage()
      }
    }
  }
  
  var stopSessionFunction: () -> ()
  
  // the engine that store the stack to check
  @ObservedObject var engine: ExperimentalEngine
  
  // use an array to store, construct the respiratory rate from amplitudes
  @ObservedObject var storage: DataStorage
  
  /// Tobii tracker object that read the python script
  @EnvironmentObject var tobii: TobiiTracker
  
  /// breath observer
  @EnvironmentObject var observer: BreathObsever
  
  var body: some View {
    VStack {
      Text("Time left: \(engine.levelTime)s")
        .onReceive(engine.timer) { _ in
          guard case .running = engine.state else {
            return
          }
          engine.levelTime -= 1
        }
      if let currentImage = engine.current {
        Image(currentImage)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 400, height: 400)
      } else {
        Color(.clear)
      }
      Text(description)
      switch engine.state {
      case .start:
        Button("Next") {
          nextClicked = true
        }
        .backgroundStyle(nextClicked ? .blue : .white)
        .animation(.easeInOut, value: nextClicked)
      case .running:
        HStack {
          Button("Yes") {
            yesClicked = true
          }
          .backgroundStyle(yesClicked ? .blue : .white)
          .animation(.easeInOut, value: yesClicked)
          Button("No") {
            noClicked = true
          }
          .backgroundStyle(noClicked ? .blue : .white)
          .animation(.easeInOut, value: noClicked)
        }
      case .stop:
        Spacer()
      }
      if showAmplitude {
        Spacer()
        debugView
      }
    }
    .padding()
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
  }
}

extension GameView {
  private func setupKeyPress(from event: NSEvent) {
    switch event.keyCode {
    case 53:  // escape
              // perform the stop action
      stopSessionFunction()
    case 123: // left arrow
      if self.running {
        yesClicked = true
      }
    case 124: // right arrow
      if self.running {
        noClicked = true
      }
    default:
      break
    }
  }
  
  private func setupController(_ controller: GCController) {
    controller.extendedGamepad?.buttonA.valueChangedHandler = { _, _, pressed in
      guard pressed, running else {
        return
      }
      
      switch engine.state {
      case .start:
        // active the "Next Image" selected state
        nextClicked = true
      case .running:
        // active the "Yes" selected state
        yesClicked = true
      case .stop:
        break
      }
      
    }
    
    controller.extendedGamepad?.buttonB.valueChangedHandler = { _, _, pressed in
      guard pressed, running else {
        return
      }
      guard case .running = engine.state else {
        return
      }
      
      // active the "No" selected state
      noClicked = true
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
  @StateObject var engine = ExperimentalEngine()
  @StateObject var storage = DataStorage()
  
  return GameView(
    running: $running,
    showAmplitude: $showAmplitude,
    stopSessionFunction: {},
    engine: engine,
    storage: storage
  )
  .frame(minWidth: 500)
}
