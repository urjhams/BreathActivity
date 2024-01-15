//
//  ExperimentalEngine.swift
//  BreathActivity
//
//  Created by Quân Đinh on 15.01.24.
//

import SwiftUI

internal struct CollectedData {
  let amplitude: Float
  let pupilSize: Float
}

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
  
  public enum State {
    case start
    case running
    case stop
  }
  
  var state: State = .stop {
    didSet {
      if case .start = state {
        // initial image
        goNext()
      }
    }
  }
  
  var stack = ImageStack(level: .easy)
  
  let sessionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  
  var analyzeTimer = Timer()  // this timer will publish every milisecond
  
  var analyzeTime: Float = 5 {
    didSet {
      if analyzeTime == 0 {
        if !stack.atCapacity {
          // keep fufill the stack
          goNext()
        } else {
          // TODO: count as cannot answer
          // go to next Image
          goNext()
        }
      }
    }
  }
  
  var levelTime: Int = 180
  
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
  
  // check the current image is matched with the target image or not
  // current image is the last image, which added latest into the stack
  // target image is the first image in the bottom of the stack
  func matched() throws -> Bool {
    
    guard let peak = stack.peek(), let bottom = stack.bottom() else {
      throw ImageStack.StackError.noPeakNorBottom
    }
    
    return peak == bottom
  }
  
  func reset() {
    levelTime = 180
    stack.setEmpty()
    state = .stop
  }
  
  func addImage() {
    guard let image = images.randomElement() else {
      return
    }
    
    stack.add(image)
  }
  
  /// add image when not in at capacity
  func goNext() {
    guard !stack.atCapacity else {
      return
    }
    
    addImage()
    
    if stack.atCapacity {
      state = .running
    }
  }
  
  /// When click yes, check does it match the target image
  func answerYesCheck() throws -> Bool {
    try matched()
  }
  
}
