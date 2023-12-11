//
//  ContentView.swift
//  BreathMeasuring
//
//  Created by Quân Đinh on 21.06.23.
//

import SwiftUI

struct ContentView: View {
  
  @State private var selectedView: Int? = 0
  private let defaultText = "..."
  
  var body: some View {
    
    NavigationSplitView {
      
      List(0..<2, selection: $selectedView) { value in
        NavigationLink(value: value) {
          switch value {
          case 0:
            Text("􀪷 Experiment")
          case 1:
            Text("􀍟 Setting")
          default:
            Text(defaultText)
          }
        }
      }
      .listStyle(.sidebar)
    } detail: {
      switch selectedView ?? 0 {
      case 0:
        StartView()
      case 1:
        SettingView()
      default:
        Text(defaultText)
      }
    }
    /*
    VStack {
      amplitudeView
        .frame(height: 80 * offSet)
        .scenePadding([.leading, .trailing])
        .padding()
      
      Spacer()
      
      startView
    }
    .onReceive(
      observer.amplitudeSubject.withLatestFrom(tobii.avgPupilDiameter)
    ) { (amplitude, pupilDiameter) in
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
     */
  }
}


struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
