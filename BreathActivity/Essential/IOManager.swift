import Foundation

public class IOManager {
  static func tryToWrite(_ storage: DataStorage) {
    let fileName = "\(storage.userData.name)"
    let fileUrl = try? FileManager
      .default
      .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent(fileName, conformingTo: .json)
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    
    if let fileUrl {
      try? encoder.encode(storage).write(to: fileUrl)
    }
  }
  
  static func tryToRead(from fileName: String) -> DataStorage? {
    let fileUrl = try? FileManager
      .default
      .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent(fileName, conformingTo: .json)
    
    guard let fileUrl, let data = try? Data(contentsOf: fileUrl) else {
      return nil
    }
    
    let decoder = JSONDecoder()
    return try? decoder.decode(DataStorage.self, from: data)
  }
}
