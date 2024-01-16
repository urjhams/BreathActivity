//
//  ContentView.swift
//  BreathMeasuring
//
//  Created by Quân Đinh on 21.06.23.
//

import BreathObsever
import SwiftUI

struct ContentView: View {
  
  /// breath observer
  @EnvironmentObject var observer: BreathObsever
  
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
            Text("􁌵 Information")
          default:
            Text(defaultText)
          }
        }
      }
      .listStyle(.sidebar)
    } detail: {
      switch selectedView ?? 0 {
      case 0:
        ExperimentalView()
      case 1:
        InfomationView()
      default:
        Text(defaultText)
      }
    }
  }
}


struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    
    @StateObject var breathObserver = BreathObsever()
    
    return ContentView()
      .frame(minWidth: 500)
      .environmentObject(breathObserver)
  }
}
