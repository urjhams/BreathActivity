import Foundation

public enum Level: String {
  case easy
  case normal
  case hard
  
  var steps: Int {
    switch self {
    case .easy:
      2
    case .normal:
      3
    case .hard:
      4
    }
  }
}

public struct ImageStack {
  private var images: [String] = []
  public let level: Level
  
  init(level: Level) {
    self.level = level
  }
  
  mutating func add(_ image: String) {
    images.append(image)
    
    // Check if the stack size exceeds the specified level's steps
    while images.count > level.steps {
      images.removeFirst()
    }
  }
  
  func peek() -> String? {
    images.last
  }
  
  var isEmpty: Bool {
    images.isEmpty
  }
  
  var size: Int {
    images.count
  }
  
  /// indicate that the stack is at its capacity
  ///
  /// This is used for let say we have 3 steps, so first and 2nd images we check this to be false
  /// then those images will show in few secs instead of start to show yes or no to compare target
  var atCapacity: Bool {
    images.count == level.steps
  }
  
  // check the current image is matched with the target image or not
  // current image is the last image, which added latest into the stack
  // target image is the first image in the bottom of the stack
  public func match() -> Bool {
    guard !images.isEmpty,
          let first = images.first,
          let last = images.last,
          images.count == level.steps
    else {
      return false
    }
    return first == last
  }
}
