import Foundation

public enum Level: Int, CaseIterable  {
  case easy = 2
  case normal = 3
  case hard = 4
  
  var steps: Int {
    rawValue
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

public class ImageStack: ObservableObject {
  
  public enum StackError: Error {
    case notAtCap
    case noPeakNorBottom
  }
  
  private var images: [String] = []
  
  @Published var level: Level
  
  init(level: Level) {
    self.level = level
  }
  
  func add(_ image: String) {
    images.append(image)
    
    // Check if the stack size exceeds the specified level's steps
    while images.count > level.steps {
      images.removeFirst()
    }
  }
  
  func peek() -> String? {
    guard atCapacity else {
      return nil
    }
    return images.last
  }
  
  func bottom() -> String? {
    guard atCapacity else {
      return nil
    }
    return images.first
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
  
  func setEmpty() {
    images = []
  }
}
