import Combine
import Foundation

public class TobiiTracker: ObservableObject {
  /// Store the average value of Pupil diameters (left and right eye)
  public var avgPupilDiameter = PassthroughSubject<Float, Never>()
  
  let process = Process()
  
  init() {
    setupProcess()
  }
}

extension TobiiTracker {
  private func setupProcess() {
    /* Bash command:
     arch -x86_64 /usr/local/homebrew/bin/python3.10 [script.py in the bundle]
     */
    
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
  }
  
  public func startReadPupilDiameter() {
    prepareToReadPupilDiameter()
    
    do {
      try process.run()
    } catch {
      print(error.localizedDescription)
      return
    }
  }
  
  private func prepareToReadPupilDiameter() {
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
    ) { [weak self] _ in
      let data = fileHandle.availableData
      if data.count > 0 {
        // we expect the echo command will show something like '{value}\n'
        // so we need to remove the newLine by dropLast
        if let output = String(data: data, encoding: .utf8)?.dropLast() {
          if let float = Float(String(output)) {
            self?.avgPupilDiameter.send(float)
          } else {
            print("the output is not the pupil diameter, probably the error")
            print(output)
          }
        }
        fileHandle.waitForDataInBackgroundAndNotify()
      } else {
        // terminated state or fail state
        print("terminated state or fail state")
      }
    }

  }
  
  public func stopReadPupilDiameter() {
    process.terminate()
  }
}
