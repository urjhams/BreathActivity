import SwiftUI

struct SurveyView: View {
  
  @Binding var isTrial: Bool
  
  @Binding var levelSequence: [Level]
  
  @Bindable var storage: DataStorage
  
  var body: some View {
    Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
  }
}

#Preview {
  @Bindable var storage = DataStorage()
  @State var isTrial = false
  @State var sequence = [Level]()
  
  return SurveyView(isTrial: $isTrial, levelSequence: $sequence, storage: storage)
    .frame(minWidth: 500, minHeight: 300)
}
