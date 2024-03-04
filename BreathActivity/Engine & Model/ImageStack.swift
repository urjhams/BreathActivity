import Foundation
import SwiftUI

public enum Level: Int, CaseIterable  {
  case easy = 1
  case normal = 2
  case hard = 3
  
  var nBack: Int {
    rawValue
  }
  
  var stackCapacity: Int {
    rawValue + 1
  }
  
  var name: String {
    switch self {
    case .easy:
      return "easy"
    case .normal:
      return "normal"
    case .hard:
      return "hard"
    }
  }
}

@Observable public class ImageStack {
  
  public enum StackError: Error {
    case notAtCap
    case noPeakNorBottom
  }
  
  private var images: [ImageResource] = []
  
  var level: Level
  
  init(level: Level) {
    self.level = level
  }
  
  func add(_ image: ImageResource?) {
    guard let image else {
      return
    }
    images.append(image)
    
    // Check if the stack size exceeds the specified level's steps
    while images.count > level.stackCapacity {
      images.removeFirst()
    }
  }
  
  func peak() -> ImageResource? {
    return images.last
  }
  
  func bottom() -> ImageResource? {
    return images.first
  }
  
  var isEmpty: Bool {
    images.isEmpty
  }
  
  var size: Int {
    images.count
  }
  
  /// return the image that gonna be the bottom of the stack  if the next image is adding to the stack
  var nextBottom: ImageResource? {
    atCapacity ? images[safe: 1] : images.first
  }
  
  /// indicate that the stack is at its capacity
  ///
  /// This is used for let say we have 3 steps, so first and 2nd images we check this to be false
  /// then those images will show in few secs instead of start to show yes or no to compare target
  var atCapacity: Bool {
    images.count == level.stackCapacity
  }
  
  func setEmpty() {
    images = []
  }
}
