import SwiftUI

struct SurveyView: View {
  
  @Binding var isTrial: Bool
  
  @Binding var state: ExperimentalState
  
  @Binding var levelSequence: [Level]
  
  @Bindable var storage: DataStorage
  
  @State var question1Selection: Int = 0
  
  @State var question2Selection: Int = 0
  
  @State var showAlert = false
  
  @State private var pressedSpace = false
  
  var body: some View {
    VStack(spacing: 10) {
      Text("Rating the difficulity of the task (from 1 to 5)")
        .font(.title2)
        .padding(.top)
      
      Picker("", selection: $question1Selection) {
        Text("1").tag(1)
        Text("2").tag(2)
        Text("3").tag(3)
        Text("4").tag(4)
        Text("5").tag(5)
      }
      .pickerStyle(.segmented)
      
      HStack {
        Text("Very easy")
        Spacer()
        Text("Very hard")
      }
      .padding([.leading, .trailing])
      
      Divider()
        .padding()
      
      Text("Rating the stressful you feel (from 1 to 5)")
        .font(.title2)
        .padding(.top)
      
      Picker("", selection: $question2Selection) {
        Text("1").tag(1)
        Text("2").tag(2)
        Text("3").tag(3)
        Text("4").tag(4)
        Text("5").tag(5)
      }
      .pickerStyle(.segmented)
      
      HStack {
        Text("Not stress at all")
        Spacer()
        Text("Very stressful")
      }
      .padding([.leading, .trailing])
      
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
      guard case .survey = state, !pressedSpace else {
        return
      }

      if !isTrial {
        guard question1Selection != 0, question2Selection != 0 else {
          return showAlert = true
        }
      }
      
      pressedSpace = true
     
      DispatchQueue.main.async {
        finishSurvey()
      }
    }
  }
  
  private func finishSurvey() {
    
    if !isTrial, storage.data.count > 0 {
      // append the survey data of current level to storage
      storage.data[storage.data.count - 1].surveyData = .init(
        q1Answer: question1Selection,
        q2Answer: question2Selection
      )
    }
    
    // remove the current level (which we just finished) in the sequence
    if !levelSequence.isEmpty {
      levelSequence.removeFirst()
    }
    
    // move to the next stage if possible
    if let nextLevel = levelSequence.first {
      state = .instruction(level: nextLevel)
    } else {
      // If `levelSequence` is empty, we reached the last stage,
      // so now we reach the end stage
      
      // go back to start screen because the sequences now is empty
      state = isTrial ? .start : .end
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
