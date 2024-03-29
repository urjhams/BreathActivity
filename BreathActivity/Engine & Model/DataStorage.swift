import SwiftUI

public struct CollectedData: Codable {
  let pupilSize: Float
  let respiratoryRate: UInt8?
}

public struct SerialData: Codable {
  var pupilSizes: [Float] = []
  var respiratoryRates: [UInt8] = []
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
  var gender: String = "Other"
  var levelTried: String = ""
}

public struct SurveyData: Codable {
  var q1Answer: Int?
  var q2Answer: Int?
}

public struct ExperimentalData: Codable {
  let level: String
  var response: [Response]
  var collectedData: [CollectedData]
  var serialData = SerialData()
  var correctRate: Double?
  var surveyData: SurveyData?
}

extension ExperimentalData {
  public mutating func computeCorrectRate() {
    let correct = Double(response.filter { $0.type == .correct }.count)
    let total = Double(response.count)
    correctRate = (correct * 100) ?/ total
  }
}

@Observable
internal class DataStorage {
  var userData = UserData()
  var data = [ExperimentalData]()
  var comment: String = ""
  
  func reset() {
    userData = UserData()
    data = []
    comment = ""
  }
  
  func asCodable() -> StorageData {
    StorageData(userData: userData, data: data, comment: comment)
  }
}

internal struct StorageData: Codable {
  let userData: UserData
  let data: [ExperimentalData]
  let comment: String
}
