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
  
  @Environment(\.dismissWindow) var closeWindow
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(minWidth: 500, minHeight: 300)
        .onReceive(
          NotificationCenter
            .default
            .publisher(for: NSApplication.willTerminateNotification)
        ) { _ in
          // make sure close the experiment windows when the app is terminated
          closeWindow(id: "Experiment")
        }
    }
    WindowGroup(id: "Experiment") {
      ExperimentalView()
        .environmentObject(tobii)
        .environmentObject(breathObserver)
        .onAppear {
          Task { @MainActor in
            // open this view in full screen
            if let last = NSApplication.shared.windows.last {
              last.toggleFullScreen(nil)
            }
          }
        }
    }
  }
}
