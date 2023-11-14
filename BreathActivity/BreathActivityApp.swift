//
//  BreathActivityApp.swift
//  BreathActivity
//
//  Created by Quân Đinh on 13.11.23.
//

import SwiftUI
import Foundation
import Combine

@main
struct BreathActivityApp: App {
  
  init() {
    readEyeTrackingData()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(maxWidth: 800, maxHeight: 400)
    }
  }
}

extension BreathActivityApp {
  private func readEyeTrackingData() {
    /* Bash command:
     arch -x86_64 /usr/local/homebrew/bin/python3.10 [script.py in the bundle]
     */
    
    let process = Process()
    guard
      let scriptPath = Bundle.main.path(forResource: "Python/script", ofType: "py")
    else {
      return
    }
    // because the python script will need to run as x86_64 architechture
    // we need a bit config for the command
    
    // mac M1 default python (installed by homebrew): "/usr/local/bin/python3"
    // this is the python we installed via x86_64 context
    let python = "/usr/local/homebrew/bin/python3.10"
    
    let command = "arch -x86_64 \(python) \(scriptPath)"
    
    // progress configuration
    process.arguments = ["-c", command]
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    
    // install pipline for data output comunication
    let pipe = Pipe()
    process.standardOutput = pipe
    
    let fileHandle = pipe.fileHandleForReading
    fileHandle.waitForDataInBackgroundAndNotify()
    
    // Notificaiton center observer for the data output
    NotificationCenter.default.addObserver(
      forName: .NSFileHandleDataAvailable,
      object: fileHandle,
      queue: nil
    ) { _ in
      let data = fileHandle.availableData
      if data.count > 0 {
        // we expect the echo command will show something like '{value}\n'
        // so we need to remove the newLine by dropLast
        if let output = String(data: data, encoding: .utf8)?.dropLast(),
           let double = Double(String(output)) {
          print(double)
        }
        fileHandle.waitForDataInBackgroundAndNotify()
      } else {
        print("fail")
      }
    }
    
    do {
      try process.run()
    } catch {
      print(error.localizedDescription)
      return
    }
  }
}
