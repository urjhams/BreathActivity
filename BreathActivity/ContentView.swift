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
//      print(Python.versionInfo.description)
//      let sys = Python.import("sys")
//      let scriptPath = Bundle.main.bundlePath + "/Contents/Resources/Python/"
//      sys.path.append(scriptPath)
//      let script = Python.import("script")
//      timer = Timer.publish(every: 1, on: .main, in: .common)
//        .autoconnect()
//        .sink(receiveValue: { _ in
//          let response = script.test()
//          print(String(response) ?? "")
//        })
      
      let process = Process()
      guard 
        let scriptPath = Bundle.main.path(forResource: "Python/script", ofType: "py")
      else {
        return
      }
      process.launchPath = "/usr/local/bin/"
      process.arguments = ["python3", scriptPath]
      
      let pipe = Pipe()
      process.standardOutput = pipe
      do {
        try process.run()
      } catch {
        print(error.localizedDescription)
      }
      
//      let fileHandle = pipe.fileHandleForReading
//      fileHandle.waitForDataInBackgroundAndNotify()
//      
//      var output = Data()
//      
//      NotificationCenter.default.addObserver(
//        forName: .NSFileHandleDataAvailable,
//        object: fileHandle,
//        queue: nil
//      ) { _ in
//        let data = fileHandle.availableData
//        output.append(data)
//        fileHandle.waitForDataInBackgroundAndNotify()
//        
//        if let result = String(data: output, encoding: .utf8) {
//          print("output from python script: \(result)")
//        }
//      }
    }
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
