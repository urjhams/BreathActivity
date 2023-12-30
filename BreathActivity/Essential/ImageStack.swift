import Foundation

public enum Level: Int {
  case easy = 2
  case normal = 3
  case hard = 4
  
  var steps: Int {
    rawValue
  }
}

public struct ImageStack {
  private var images: [String] = []
  private let level: Level
  
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
