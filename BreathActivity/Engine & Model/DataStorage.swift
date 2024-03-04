import SwiftUI

public struct CollectedData: Codable {
  let amplitude: Float
  let pupilSize: Float
}

public struct Response: Codable {
  public enum ReactionType: Codable {
    case pressedSpace(reactionTime: Double)
    case doNothing
  }
  
  public enum ResponseType: Codable {
    case correct
    case incorrect
  }
  
  var type: ResponseType
  var reaction: ReactionType
}

@Observable internal class DataStorage: Codable {
  var candidateName: String = ""
  var level: String = ""
  var collectedData: [CollectedData] = []
  var responses: [Response] = []
  
  public func reset() {
    level = ""
    collectedData = []
    responses = []
  }
}
