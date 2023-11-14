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
      
  // breath observer
  let observer = BreathObsever()
  
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
            observer.stopAnalyzing()
            running = false
          } else {
            // start process
            do {
              try observer.startAnalyzing()
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
    // TODO: could we try to implement Tobii pro python sdk and combine the data with this?
    .onReceive(observer.amplitudeSubject) { value in
      // scale up with 1000 because the data is something like 0,007. 
      // So we would like it to start from 1 to around 80
      amplitudes.append(value * 1000)
    }
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
