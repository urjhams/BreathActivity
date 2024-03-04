import SwiftUI

struct SurveyView: View {
  
  @Binding var isTrial: Bool
  
  @Binding var state: ExperimentalState
  
  @Binding var levelSequence: [Level]
  
  @Bindable var storage: DataStorage
  
  @State var question1Selection: Int?
  
  @State var question2Selection: Int?
  
  var body: some View {
    VStack(spacing: 10) {
      Text("Question 1 content")
        .font(.title3)
      Picker("", selection: $question1Selection) {
        Text("1").tag(1)
        Text("2").tag(2)
        Text("3").tag(3)
        Text("4").tag(4)
        Text("5").tag(5)
      }
      .pickerStyle(.segmented)
      
      Divider()
      
      Text("Question 2 content")
        .font(.title3)
      Picker("", selection: $question2Selection) {
        Text("1").tag(1)
        Text("2").tag(2)
        Text("3").tag(3)
        Text("4").tag(4)
        Text("5").tag(5)
      }
      .pickerStyle(.segmented)
      
      Spacer()
      Text(
        levelSequence.count > 1 ? "Press Space to the next stage" : "Press Space to finish"
      )
      MakeKeyPressSilentView()
        .frame(height: 0)
    }
    .padding()
  }
}

extension SurveyView {
  private func finishSurvey() {
    
    // remove the current level to the sequence
    levelSequence.removeFirst()
    
    // move to the next stage if possible
    if let nextLevel = levelSequence.first {
      // TODO: set the data of current session and append into storage
      
      // TODO: Reconstruct the storage so it now stores metadata and the array that store 3 stages randomly that contain the level of each stage and its data
      
      // TODO: use image with name instead of asset
      
      // TODO: make sure to have at least 10 matches -> need minimum not match threshold and maximum not match threshold -> rework on the condition to make random image: if it guarantee not to match, check the 1st element of the stack and make a random in an image array that does not contain the matched image name.
      
      // TODO: need a survey screen as well
      
      
      state = .instruction(level: nextLevel)
      
    } else {
      // TODO: this writting step should be in the last Survey view
      // save data of the all sessions
      //      if !isTrial {
      //        IOManager.tryToWrite(storage)
      //      }
      
      // go back to start screen because the sequences now is empty
      state = .start
    }
  }
}

#Preview {
  @Bindable var storage = DataStorage()
  @State var isTrial = false
  @State var sequence = [Level]()
  @State var state: ExperimentalState = .survey
  
  return SurveyView(isTrial: $isTrial, state: $state, levelSequence: $sequence, storage: storage)
    .frame(minWidth: 500, minHeight: 300)
}
