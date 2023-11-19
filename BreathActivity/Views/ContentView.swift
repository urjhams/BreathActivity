//
//  ContentView.swift
//  BreathMeasuring
//
//  Created by Quân Đinh on 21.06.23.
//

import SwiftUI
import BreathObsever
import Combine
import CombineExt

struct ContentView: View {
  
  @State var running = false
  
  @State var amplitudes = [Float]()
  
  private let offSet: CGFloat = 3
  
  @State var available = true
  
  @EnvironmentObject var tobii: TobiiTracker
      
  // breath observer
  @EnvironmentObject var observer: BreathObsever
  
  var body: some View {
    VStack {
      ScrollView(.vertical) {
        HStack(spacing: 1) {
          ForEach(amplitudes, id: \.self) { amplitude in
            RoundedRectangle(cornerRadius: 2)
              .frame(width: offSet, height: CGFloat(amplitude) * offSet)
              .foregroundColor(.white)
          }
        }
      }
      .frame(height: 80 * offSet)
      .scenePadding([.leading, .trailing])
      .padding()
      
      Spacer()
      
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
    .onReceive(
      observer.amplitudeSubject.withLatestFrom(
        tobii.avgPupilDiameter,
        resultSelector: {
          ($0, $1)
        }
      )
    ) { (amplitude, pupilDiameter) in
      // TODO: test this when connect to tobii, otherwise this closure will never be executed
      // scale up with 1000 because the data is something like 0,007.
      // So we would like it to start from 1 to around 80
      // add amplutudes value to draw
      amplitudes.append(amplitude * 1000)
      
      Task { @MainActor in
        print("\(amplitude) - \(pupilDiameter)")
      }
    }
//    .onReceive(observer.amplitudeSubject) { value in
//      // scale up with 1000 because the data is something like 0,007.
//      // So we would like it to start from 1 to around 80
//      amplitudes.append(value * 1000)
//    }
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
