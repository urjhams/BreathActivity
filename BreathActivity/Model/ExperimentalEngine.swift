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

public enum Response: String {
  case correct
  case incorrect
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
          // count as cannot answer
          responseEvent.send(.incorrect)
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
  
  private func addImage() {
    guard let image = images.randomElement() else {
      return
    }
    
    stack.add(image)
    currentImageId = UUID()
  }
  
  /// add image when not in at capacity
  func goNext() {
    
    addImage()
    
    if stack.atCapacity, case .start = state {
      state = .running
    }
    
    // be sure to reset the analyze timer each time we switch the image
    analyzeTime = Self.limitReactionTime
  }
  
  /// When click yes, check does it match the target image
  @discardableResult
  func answerYesCheck() -> Double {
    let reactionTime = Self.limitReactionTime - analyzeTime
    guard let matched = try? matched() else {
      return reactionTime
    }
    responseEvent.send(matched ? .correct : .incorrect)
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
