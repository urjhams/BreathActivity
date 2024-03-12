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
  case about
  case running(level: Level)
  case instruction(level: Level)
  case result
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
      case .about:
        AboutView(state: $state)
      case .start:
        StartView(
          selection: $selection,
          showAmplitude: $showAmplitude,
          storage: storage,
          startButtonClick: startButtonClick,
          trialButtonClick: trialButtonClick, 
          aboutButtonClick: aboutButtonClick
        )
        .onAppear {
          storage.reset()
        }
      case .instruction(let level):
        // instruction view
        InstructionView(
          isTrial: isTrial,
          nBack: level.nBack,
          state: $state,
          levelSequence: $levelSequence
        )
      case .running(let level):
        GameView(
          isTrial: isTrial,
          data: .init(level: level.name, response: [], collectedData: []),
          state: $state,
          showAmplitude: $showAmplitude,
          levelSequence: $levelSequence,
          engine: ExperimentalEngine(level: level),
          storage: storage
        )
      case .result:
        ResultView(
          state: $state,
          storage: storage,
          levelSequence: levelSequence
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
  
  private func startButtonClick() {
    
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
  
  private func trialButtonClick() {
    
    isTrial = true
    // in trial, we always start from easy, normal, then hard
    levelSequence = levelSequences[0]
    
    if let first = levelSequence.first {
      state = .instruction(level: first)
    }
  }
  
  private func aboutButtonClick() {
    state = .about
  }
}

#Preview {
  
  @StateObject var breathObserver = BreathObsever()
  
  return ExperimentalView()
    .frame(minWidth: 500)
    .environmentObject(breathObserver)
}
