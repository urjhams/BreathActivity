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

private struct TobiiKey: EnvironmentKey {
  static let defaultValue = TobiiTracker()
}

extension EnvironmentValues {
  var tobiiTracker: TobiiTracker {
    get {
      return self[TobiiKey.self]
    }
    set {
      self[TobiiKey.self] = newValue
    }
  }
}

@main
struct BreathActivityApp: App {
  
  @StateObject var breathObserver = BreathObsever()
    
  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(minWidth: 800, minHeight: 600)
        .environmentObject(breathObserver)
    }
    .windowStyle(.hiddenTitleBar)
  }
}
