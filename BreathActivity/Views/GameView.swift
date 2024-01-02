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
  
  private let offSet: CGFloat = 3
  
  /// debug text
  @State var tobiiInfoText: String = ""
  
  @State var amplitudes = [Float]()
  
  @Binding var showAmplitude: Bool
  
  @State var timeLeftContent = "Time left"
  
  @State var description = "description"
  
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
      Text(timeLeftContent)
      if let currentImage = engine.current {
        Image(currentImage)
      } else {
        Color(.clear)
      }
      Text(description)
      switch engine.state {
      case .starting:
        Button("Next") {
          
        }
      case .started:
        HStack {
          Button("Yes") {
            
          }
          Button("No") {
            
          }
        }
      case .stopped:
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
    controller.extendedGamepad?.buttonA.valueChangedHandler = { _, _, pressed in
      guard pressed, running else {
        return
      }
      
      switch engine.state {
      case .starting:
        // TODO: active the "Next Image" selected state
        print("pressed Yes (A)")
      case .started:
        // TODO: active the "Yes" selected state
        print("pressed Yes (A)")
      case .stopped:
        break
      }
      
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
