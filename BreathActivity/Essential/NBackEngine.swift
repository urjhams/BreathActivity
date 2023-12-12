import SwiftUI

public enum Mode {
  case easy     // 2 backs, just position
  case normal   // 3 backs, just position
  case hard     // 3 backs, position and digit
}

public class NBackEngine {
  static let time: TimeInterval = 0.5 // time between each "blink"
  
  let elementsRange = 0 ..< 9
  var mode: Mode
  
  init(_ mode: Mode) {
    self.mode = mode
  }
  
}
