//
//  ExperimentalEngine.swift
//  BreathActivity
//
//  Created by Quân Đinh on 15.01.24.
//

import SwiftUI
import Combine

@Observable public class ExperimentalEngine {
  
  let maximumUnmatched = 7
  
  let minimumUnmatched = 5
  
  var unmatchedCount = 0
    
  var running = false
  
  let level: Level
  
  let stack: ImageStack
  
  init(level: Level) {
    self.level = level
    stack = ImageStack(level: level)
  }
  
  let sessionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  
  static let mili = 0.01
  // this timer will publish every 10 milisecond
  var analyzeTimer = Timer.publish(every: mili, on: .main, in: .default).autoconnect()
  
  /// This is the maximum reaction time before swift to the new image
  private static let limitReactionTime: Double = 3
  
  /// duration of each image that be able or being show
  public var duration = Int(limitReactionTime)
  
  private var analyzeTime: Double = limitReactionTime
    
  private var levelTime: Int = 300 + 1  // extra 1 second for the audio engine to be ready to collect data
  
  var timeLeft: Int {
    levelTime
  }
  
  public var responseEvent = PassthroughSubject<Response, Never>()
  
  let images: [String] = [
    "animalface_cheetah",
    "animalface_duck",
    "animalface_niwatori",
    "animalface_panda",
    "animalface_tora",
    "animalface_uma",
    "animalface_usagi",
    "animalface_zou"
  ]
  
  var current: String? {
    stack.peak()
  }
  
  /// This workaround make sure each time an image is push to the stack, it emits an unique Id so the transition
  /// for the image view based on Id will always fire up even the same image is pushed
  var currentImageId = UUID()
  
  // check the current image is matched with the target image or not
  // current image is the last image, which added latest into the stack
  // target image is the first image in the bottom of the stack
  func matched() -> Bool {
    
    guard let peak = stack.peak(), let bottom = stack.bottom() else {
      return false
    }
    
    return peak == bottom
  }
  
  func reset() {
    stack.setEmpty()
    running = false
  }
  
  private func addImage() {
    
    // random adding the image
    var randomImage: String? {
      if stack.atCapacity, let bottom = stack.nextBottom {
        switch unmatchedCount {
        case 0..<minimumUnmatched:
          // make sure to not add image of the current bottom
          var copy = images
          if let bottomIndex = copy.firstIndex(of: bottom) {
            copy.remove(at: bottomIndex)
          }
          return copy.randomElement()
        case minimumUnmatched..<maximumUnmatched:
          // return just random image
          return images.randomElement()
        default:
          // guarantee to return the matched image
          return bottom
        }
      } else {
        // when filling
        return images.randomElement()
      }
    }
    
    stack.add(randomImage)
    
    // generate the id for animation no matter if the same image appear
    currentImageId = UUID()
  }
  
  /// add next image to the stack
  func goNext() {
    
    // add image
    addImage()
    
    // reset the duration
    duration = Int(Self.limitReactionTime)
    
    if stack.atCapacity, running {
      unmatchedCount = matched() ? 0 : unmatchedCount + 1
    }
    
    // be sure to reset the analyze timer each time we switch the image
    analyzeTime = Self.limitReactionTime
  }
  
  /// When click yes, check does it match the target image
  func answerYesCheck() {
    // only when user press space, we have the reaction time
    let reactionTime = Self.limitReactionTime - analyzeTime
    
    let response: Response.ResponseType = matched() ? .correct : .incorrect
    
    let reactionType: Response.ReactionType = .pressedSpace(reactionTime: reactionTime)
    
    let result = Response(type: response, reaction: reactionType)
    
    responseEvent.send(result)
    
    goNext()
  }
  
  /// When the user don't click anything
  func noAnswerCheck() {
    
    let responseType: Response.ResponseType = matched() ? .incorrect : .correct
    
    let result = Response(type: responseType, reaction: .doNothing)
    
    responseEvent.send(result)
    
    goNext()
  }
  
  func reduceTime() {
    levelTime -= 1
    duration -= 1
    
    // if duration for each image reach zero, -> the no scenario
    if duration == 0 {
      if stack.atCapacity {
        noAnswerCheck()
      } else {
        goNext()
      }
    }
  }
  
  func reduceAnalyzeTime() {
    analyzeTime -= Self.mili
  }
  
}
