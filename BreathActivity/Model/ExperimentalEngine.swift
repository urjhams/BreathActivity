//
//  ExperimentalEngine.swift
//  BreathActivity
//
//  Created by Quân Đinh on 15.01.24.
//

import SwiftUI
import Combine
import AVFAudio

internal struct CollectedData {
  let amplitude: Float
  let pupilSize: Float
}

public enum Response {
  // selected means the answer is correctd when the user pressed space on matched image
  // not selected means the answer is corrected to ignore the un-matched image
  
  case correct(selected: Bool)
  case incorrect(selected: Bool)
}

// TODO: make a threshold (around 3 or 5 for maximum?) of minimum step before the matched image will be shown back
// store a bool to indicate that must show matched as false
// store one value of unmatched count, raise it up every time a new image show, if it reach 3 (or 5?), the next image show will be the match (the variable above will be true), and reset after we show the match (just in goNext function with condition as the bool variable, if it true, show the matched and turn that value back to false, reset the unmatched count)

@Observable internal class DataStorage {
  var candidateName: String = ""
  var level: String = ""
  var collectedData: [CollectedData] = []
  
  public func reset() {
    level = ""
    collectedData = []
  }
}

@Observable public class ExperimentalEngine {
  
  let maximumUnmatched = 5
  
  var unmatchedCount = 0
  
  var audioPlayer: AVAudioPlayer?
  
  public enum State: String, Equatable, Identifiable {
    public var id: State { self }
    
    case start
    case running
    case stop
  }
  
  var state: State = .stop
  
  var stack = ImageStack(level: .easy)
  
  let sessionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  
  static let mili = 0.01
  // this timer will publish every 10 milisecond
  var analyzeTimer = Timer.publish(every: mili, on: .main, in: .default).autoconnect()
  
  private static let limitReactionTime: Double = 5
  
  private var analyzeTime: Double = limitReactionTime {
    didSet {
      if analyzeTime <= 0 {
        if !stack.atCapacity {
          // keep fufill the stack
          goNext()
        } else {
          // when the limited time passed, check:
          // if it is matched but the user didn't press space,
          // which mean they missed it so we counted as the wrong answer
          responseEvent.send(matched() ? .incorrect(selected: false) : .correct(selected: false))
          // go to next Image
          goNext()
        }
      }
    }
  }
  
  private var levelTime: Int = 180
  
  var timeLeft: Int {
    levelTime
  }
  
  public var responseEvent = PassthroughSubject<Response, Never>()
  
  // TODO: maybe add 2 more set of images
  let images: [ImageResource] = [
    .animalfaceCheetah,
    .animalfaceDuck,
    .animalfaceNiwatori,
    .animalfacePanda,
    .animalfaceTora,
    .animalfaceUma,
    .animalfaceUsagi,
    .animalfaceZou
  ]
  
  var current: ImageResource? {
    stack.peek()
  }
  
  /// This workaround make sure each time an image is push to the stack, it emits an unique Id so the transition
  /// for the image view based on Id will always fire up even the same image is pushed
  var currentImageId = UUID()
  
  // check the current image is matched with the target image or not
  // current image is the last image, which added latest into the stack
  // target image is the first image in the bottom of the stack
  func matched() -> Bool {
    
    guard let peak = stack.peek(), let bottom = stack.bottom() else {
      return false
    }
    
    return peak == bottom
  }
  
  func reset() {
    levelTime = 180
    stack.setEmpty()
    state = .stop
  }
  
  private func addImage() {
    
    // random adding the image
    func randomImage() -> ImageResource? {
      if let current = stack.peek(), let index = images.firstIndex(of: current) {
        var copy = images
        copy.remove(at: index)
        return copy.randomElement()
      } else {
        return images.randomElement()
      }
    }
    
    let image = if unmatchedCount == maximumUnmatched {
      // guarantee to add the matched image
      stack.bottom()
    } else {
      randomImage()
    }
    
    guard let image else {
      return
    }
    
    stack.add(image)
    
    // generate the id for animation no matter if the same image appear
    currentImageId = UUID()
  }
  
  /// add image when not in at capacity
  func goNext() {
    
    addImage()
    
    if stack.atCapacity {
      switch state {
      case .start:
        // switch the state to running
        state = .running
      case .running:
        unmatchedCount = matched() ? 0 : unmatchedCount + 1
      case .stop:
        break
      }
    }
    
    // be sure to reset the analyze timer each time we switch the image
    analyzeTime = Self.limitReactionTime
  }
  
  /// When click yes, check does it match the target image
  @discardableResult
  func answerYesCheck() -> Double {
    // define the reaction time because the goNext will reset the analyze time
    let reactionTime = Self.limitReactionTime - analyzeTime
    responseEvent.send(matched() ? .correct(selected: true) : .incorrect(selected: true))
    goNext()
    return reactionTime
  }
  
  func reduceTime() {
    levelTime -= 1
  }
  
  func reduceAnalyzeTime() {
    analyzeTime -= Self.mili
  }
  
}
