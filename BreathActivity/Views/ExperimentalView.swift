//
//  ExperimentalView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 14.11.23.
//

import SwiftUI
import Combine
import BreathObsever

enum Mode {
  
}

struct ExperimentalView: View {
    
  @FocusState private var focused: Bool
  
  @State var running = false
  
  @State var amplitudes = [Float]()
  
  private let offSet: CGFloat = 3
  
  @State var available = true
  
  @State var content: String = ""
  
  // TODO: use an array to store, construct the respiratory rate from amplitudes
  
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
      
      LazyHGrid(
        rows: Array(repeating: GridItem(.flexible(), spacing: 15), count: 3),
        spacing: 40
      ) {
        ForEach(0..<9, id:\.self) { index in
          ZStack {
            Color.white
          }
          .cornerRadius(10)
          .frame(width: 100, height: 100)
        }
      }
      .padding(15)
      .frame(width: 400, height: 400)
      
      debugView
    }
    .onReceive(tobii.avgPupilDiameter) { tobiiData in
      switch tobiiData {
      case .message(let content):
        self.content = content
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
        print("\(amplitude) - \(data)")
      }
    }
    .padding()
  }
}

extension ExperimentalView {
  
  private var debugView: some View {
    VStack {
      Text(content)
      
      amplitudeView
        .frame(height: 80 * offSet)
        .scenePadding([.leading, .trailing])
        .padding()
      
      Spacer()
      
      startView
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
            available = true
          } catch {
            available = false
          }
        }
      } label: {
        Image(systemName: running ? "square.fill" : "play.fill")
          .font(.largeTitle)
          .foregroundColor(available ? .accentColor : .red)
      }
    }
    .padding()
  }
}

#Preview {
  ExperimentalView()
}
