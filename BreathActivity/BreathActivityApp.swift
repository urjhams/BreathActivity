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

public extension Color {
  
#if os(macOS)
  static let background = Color(NSColor.windowBackgroundColor)
  static let secondaryBackground = Color(NSColor.underPageBackgroundColor)
  static let tertiaryBackground = Color(NSColor.controlBackgroundColor)
#else
  static let background = Color(UIColor.systemBackground)
  static let secondaryBackground = Color(UIColor.secondarySystemBackground)
  static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
#endif
}



@main
struct BreathActivityApp: App {
  
  @StateObject var tobii = TobiiTracker()
  @StateObject var breathObserver = BreathObsever()
    
  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(minWidth: 800, minHeight: 600)
        .environmentObject(tobii)
        .environmentObject(breathObserver)
    }
    .windowStyle(.hiddenTitleBar)
  }
}
