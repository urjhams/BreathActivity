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

public struct Response {
  public enum ReactionType {
    case passive(waitedTime: Double)
    case direct(reactionTime: Double)
    
    var time: Double {
      switch self {
      case .passive(let waitedTime):
        return waitedTime
      case .direct(let reactionTime):
        return reactionTime
      }
    }
  }
  public enum ResponseType {
    // selected means the answer is correctd when the user pressed space on matched image
    // not selected means the answer is corrected to ignore the un-matched image
    
    case correct(selected: Bool)
    case incorrect(selected: Bool)
  }
  
  var type: ResponseType
  var reaction: ReactionType
}

@Observable internal class DataStorage {
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

@Observable public class ExperimentalEngine {
  
  var maximumUnmatched = 5
  
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
          
          let response: Response.ResponseType =
            matched() ?  .incorrect(selected: false) : .correct(selected: false)
          
          let reactionType: Response.ReactionType = 
            .passive(waitedTime: Self.limitReactionTime)
          
          let result = Response(type: response, reaction: reactionType)
          
          responseEvent.send(result)
          // go to next Image
          goNext()
        }
      }
    }
  }
  
  var trialMode = false {
    didSet {
      levelTime = trialMode ? trialLimit : experimentalLimit
    }
  }
  
  private let trialLimit: Int = 60
  private let experimentalLimit: Int = 300
  
  private var levelTime: Int = 180
  
  var timeLeft: Int {
    levelTime
  }
  
  public var responseEvent = PassthroughSubject<Response, Never>()
  
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
    trialMode = false
    stack.setEmpty()
    state = .stop
  }
  
  private func addImage() {
    
    // random adding the image
    var randomImage: ImageResource? {
      if let current = stack.peek(), let index = images.firstIndex(of: current) {
        var copy = images
        copy.remove(at: index)
        return copy.randomElement()
      } else {
        return images.randomElement()
      }
    }
    
    // guarantee to add the matched image to the next bottom
    // if we reach the maximum unmatched cases
    // otherwise just add a random image
    let image = if unmatchedCount >= maximumUnmatched { stack.nextBottom } else { randomImage }
    
    stack.add(image)
    
    // generate the id for animation no matter if the same image appear
    currentImageId = UUID()
  }
  
  /// add next image to the stack
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
  func answerYesCheck() {
    // define the reaction time because the goNext will reset the analyze time
    let reactionTime = Self.limitReactionTime - analyzeTime
    
    let response: Response.ResponseType =
      matched() ? .correct(selected: true) : .incorrect(selected: true)
    
    let reactionType: Response.ReactionType =
      reactionTime == Self.limitReactionTime ?
      .passive(waitedTime: reactionTime) :
      .direct(reactionTime: reactionTime)
    
    let result = Response(type: response, reaction: reactionType)
    
    responseEvent.send(result)
    
    goNext()
  }
  
  func reduceTime() {
    levelTime -= 1
  }
  
  func reduceAnalyzeTime() {
    analyzeTime -= Self.mili
  }
  
}
