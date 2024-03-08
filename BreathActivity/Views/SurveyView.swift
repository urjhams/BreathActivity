import SwiftUI

struct SurveyView: View {
  
  @Binding var isTrial: Bool
  
  @Binding var state: ExperimentalState
  
  @Binding var levelSequence: [Level]
  
  @Bindable var storage: DataStorage
  
  @State var question1Selection: Int?
  
  @State var question2Selection: Int?
  
  @State var showAlert = false
  
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
        .onAppear {
          NSEvent.addLocalMonitorForEvents(matching: [.keyUp]) { event in
            self.setupKeyPress(from: event)
            return event
          }
        }
    }
    .padding()
    .alert(isPresented: $showAlert) {
      Alert(title: Text("Please select the answer for the questions above"))
    }
  }
}

extension SurveyView {
  
  private func setupKeyPress(from event: NSEvent) {
    if case 49 = event.keyCode {  // space
      guard case .survey = state else {
        return
      }
      
      guard question1Selection != nil, question2Selection != nil else {
        return showAlert = true
      }
            
      finishSurvey()
    }
  }
  
  private func finishSurvey() {
    
    if !isTrial, let currentLevel = levelSequence.first {
      // TODO: append the survey data of current level to storage
            
      // TODO: make sure to have at least 10 matches -> need minimum not match threshold and maximum not match threshold -> rework on the condition to make random image: if it guarantee not to match, check the 1st element of the stack and make a random in an image array that does not contain the matched image name.
    }
    
    // remove the current level to the sequence
    levelSequence.removeFirst()
    
    // move to the next stage if possible
    if let nextLevel = levelSequence.first {
      state = .instruction(level: nextLevel)
    } else {
      // save data of the all sessions
      if !isTrial {
        IOManager.tryToWrite(storage)
      }
      
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
