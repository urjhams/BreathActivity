import SwiftUI

// TODO: amplitude now should be: let respiratory rate: Float? (could be nil if we collect pupil data more oftenly)
public struct CollectedData: Codable {
  let amplitude: Float
  let pupilSize: Float
  let respiratoryRate: Float?
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

public struct UserData: Codable {
  var name: String = ""
  var age: String = ""
  var gender: String = ""
}

public struct SurveyData: Codable {
  var q1Answer: Int?
  var q2Answer: Int?
}

public struct ExperimentalData: Codable {
  let level: String
  var response: [Response]
  var collectedData: [CollectedData]
  var correctRate: Double?
  var surveyData: SurveyData?
}

extension ExperimentalData {
  public mutating func computeCorrectRate() {
    let correct = Double(response.filter { $0.type == .correct }.count)
    let total = Double(response.count)
    correctRate = (correct * 100) / total
  }
}

@Observable
internal class DataStorage: Codable {
  var userData = UserData()
  var data = [ExperimentalData]()
  
  func reset() {
    userData = UserData()
    data = []
  }
}
