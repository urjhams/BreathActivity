import Foundation

public class IOManager {
  static func tryToWrite(_ storage: StorageData) throws {
    let fileName = "\(storage.userData.name)(\(storage.userData.levelTried))"
    
    let manager = FileManager.default
    
    let documentURL = try manager
      .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    
    let folderURL = documentURL.appending(path: "BreathActivity")
    
    let existed = (try? folderURL.checkResourceIsReachable()) ?? false
    
    if !existed {
      try manager.createDirectory(at: folderURL, withIntermediateDirectories: false)
    }
    
    let fileURL = folderURL.appending(path: fileName).appendingPathExtension("json")
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    
    try encoder.encode(storage).write(to: fileURL)
  }
  
  static func tryToRead(from fileName: String, from fileURL: URL) -> StorageData? {
    
    guard let data = try? Data(contentsOf: fileURL) else {
      return nil
    }
    
    let decoder = JSONDecoder()
    return try? decoder.decode(StorageData.self, from: data)
  }
}
