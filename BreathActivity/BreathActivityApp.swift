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
import TobiiEyeTrackerSilicon

private struct TobiiKey: EnvironmentKey {
  static let defaultValue = TobiiTracker()
}

extension EnvironmentValues {
  var tobiiTracker: TobiiTracker {
    get {
      self[TobiiKey.self]
    }
    set {
      self[TobiiKey.self] = newValue
    }
  }
}

@main
struct BreathActivityApp: App {
  
  @State var breathObserver = BreathObsever()
    
  var body: some Scene {
    WindowGroup {
      ExperimentalView()
        .frame(minWidth: 800, minHeight: 600)
    }
    .environment(breathObserver)
    .windowStyle(.hiddenTitleBar)
  }
}
