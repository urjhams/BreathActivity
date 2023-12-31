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

internal class DataStorage {
  var collectedData: [CollectedData] = []
}

// TODO: do the simple stack to keep n latest image (name)
// The size of the stack will be equal to the step (n)
// then we just need to check the top of the stack to match with the bottom
// when the user select "yes"
struct ExperimentalView: View {
  
  let images: [String]
  
  var stack: ImageStack
  
  @State var levelTime: Int
  
  let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  
  @State var level: Level = .easy
    
  @FocusState private var focused: Bool
  
  @State var running = false
  
  var currentImage: String? = nil
  
  @State var amplitudes = [Float]()
  
  private let offSet: CGFloat = 3
  
  /// debug text
  @State var debugContent: String = ""
  
  // use an array to store, construct the respiratory rate from amplitudes
  let storage = DataStorage()
  
  /// Tobii tracker object that read the python script
  @EnvironmentObject var tobii: TobiiTracker
  
  /// breath observer
  @EnvironmentObject var observer: BreathObsever
  
  var body: some View {
    VStack {
      // focus state have a border so we apply the focus and keypress receiver
      // on a spacer
      Spacer()
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
      
      if running, let imageName = currentImage {
        Image(imageName)
      }
      
      debugView
      
      Spacer()
      
      if !running {
        startView
      }
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
          tobii.stopReadPupilDiameter()
          observer.stopAnalyzing()
          running = false
        } else {
          // start process
          do {
            try observer.startAnalyzing()
            tobii.startReadPupilDiameter()
            amplitudes = []
            running = true
          } catch {
            running = false
          }
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

#Preview {
  
  @StateObject var tobii = TobiiTracker()
  @StateObject var breathObserver = BreathObsever()
  
  return ExperimentalView(images: [], stack: .init(level: .easy), levelTime: 180)
    .frame(minWidth: 500)
    .environmentObject(tobii)
    .environmentObject(breathObserver)
}
