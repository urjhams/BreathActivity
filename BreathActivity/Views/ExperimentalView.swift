//
//  ExperimentalView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 14.11.23.
//

import SwiftUI
import Combine
import BreathObsever

public enum ExperimentalState {
  case start
  case running(level: Level)
  case instruction(level: Level)
  case survey
}

public let levelSequences: [[Level]] = [
  [.easy, .normal, .hard],
  [.easy, .hard, .normal],
  [.normal, .easy, .hard],
  [.normal, .hard, .easy],
  [.hard, .easy, .normal],
  [.hard, .normal, .easy]
]

struct ExperimentalView: View {
  
  @State var selection: Int = 0
  
  @State var levelSequence: [Level] = [.easy, .normal, .hard]
  
  @State var isTrial = false
    
  @State var labelEnable = false
  
  @State var state: ExperimentalState = .start
  
  @Bindable var storage = DataStorage()
  
  @State var showAmplitude: Bool = false
  
  var body: some View {
    VStack {
      switch state {
      case .start:
        StartView(
          selection: $selection,
          showAmplitude: $showAmplitude,
          storage: storage,
          startButtonClick: startButtonClick,
          trialButtonClick: trialButtonClick
        )
        .onAppear {
          storage.candidateName = ""
          storage.reset()
        }
      case .running(let level):
        GameView(
          isTrial: isTrial,
          state: $state,
          showAmplitude: $showAmplitude,
          levelSequence: $levelSequence,
          engine: ExperimentalEngine(level: level),
          storage: storage
        )
      case .instruction(let level):
        // instruction view
        InstructionView(
          isTrial: isTrial,
          nBack: level.nBack,
          state: $state,
          levelSequence: $levelSequence
        )
      case .survey:
        // create survey for level
        // questions: 
        // rate the difficulity of the task (0 to 5 scale)
        // how stressful is the user (0 to 5 scale)
        SurveyView(
          isTrial: $isTrial,
          state: $state,
          levelSequence: $levelSequence,
          storage: storage
        )
      }
    }
  }
}

extension ExperimentalView {
  
  func startButtonClick() {
    
    isTrial = false
    
    guard case .start = state else {
      return
    }
    
    // set the level sequences
    levelSequence = levelSequences[selection]
        
    if let first = levelSequence.first {
      // change the state to running with the first element of the array
      state = .instruction(level: first)
    }
  }
  
  func trialButtonClick() {
    
    isTrial = true
    // in trial, we always start from easy, normal, then hard
    levelSequence = levelSequences[0]
    
    if let first = levelSequence.first {
      state = .instruction(level: first)
    }
  }
}

#Preview {
  
  @StateObject var breathObserver = BreathObsever()
  
  return ExperimentalView()
    .frame(minWidth: 500)
    .environmentObject(breathObserver)
}
