//
//  BreathActivityApp.swift
//  BreathActivity
//
//  Created by Quân Đinh on 13.11.23.
//

import SwiftUI
import Foundation
import Combine
import BreathObsever

@main
struct BreathActivityApp: App {
  
  @StateObject var tobii = TobiiTracker()
  @StateObject var breathObserver = BreathObsever()
    
  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(minWidth: 1000, minHeight: 800)
        .environmentObject(tobii)
        .environmentObject(breathObserver)
    }
    .windowStyle(.hiddenTitleBar)
  }
}
