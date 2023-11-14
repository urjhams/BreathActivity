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
import Foundation
import PythonKit

struct ContentView: View {
  
  @State var running = false
  
  @State var amplitudes = [Float]()
  
  private let offSet: CGFloat = 3
  
  @State var available = true
  
  @State var timer: AnyCancellable?
    
  // breath observer
  let observer = BreathObsever()
  
  var body: some View {
    VStack {
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
      HStack(spacing: 1) {
        ForEach(amplitudes, id: \.self) { amplitude in
          RoundedRectangle(cornerRadius: 2)
            .frame(width: offSet, height: CGFloat(amplitude) * offSet)
            .foregroundColor(.white)
        }
      }
      .frame(height: 80 * offSet)
    }
    // TODO: could we try to implement Tobii pro python sdk and combine the data with this?
    .onReceive(observer.amplitudeSubject) { value in
      // scale up with 1000 because the data is something like 0,007. 
      // So we would like it to start from 1 to around 80
      amplitudes.append(value * 1000)
    }
    .onAppear {
      
      let process = Process()
      guard 
        let scriptPath = Bundle.main.path(forResource: "Python/script", ofType: "py")
      else {
        return
      }
      // because the python script will need to run as x86_64 architechture
      // we need a bit config for the command
      let python = "/usr/local/bin/python3"
      let command = "arch -x86_64 \(python) \(scriptPath)"
      process.arguments = ["-c", command]
      process.executableURL = URL(fileURLWithPath: "/bin/zsh")
      
      let pipe = Pipe()
      process.standardOutput = pipe
      
      let fileHandle = pipe.fileHandleForReading
      fileHandle.waitForDataInBackgroundAndNotify()
                  
      NotificationCenter.default.addObserver(
        forName: .NSFileHandleDataAvailable,
        object: fileHandle,
        queue: nil
      ) { _ in
        let data = fileHandle.availableData
        if data.count > 0 {
          // we expect the echo command will show something like '{value}\n'
          // so we need to remove the newLine by dropLast
          if let echoWithoutNewLine = String(data: data, encoding: .utf8)?.dropLast(),
             let double = Double(String(echoWithoutNewLine)) {
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
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
