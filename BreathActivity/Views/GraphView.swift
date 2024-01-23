import SwiftUI
import Charts

struct GraphView: View {
  
  @State var amplitudeData = [Float]()
  @State var pupilData = [Float]()
  
  var body: some View {
    VStack {
      Chart(Array(amplitudeData.enumerated()), id: \.0) { index, magnitude in
        LineMark(x: .value("id", index), y: .value("amplitude", magnitude))
          .foregroundStyle(.red)
      }
      .chartXAxis(.hidden)
      .padding(.all)
      
      Chart(Array(pupilData.enumerated()), id: \.0) { index, magnitude in
        LineMark(x: .value("id", index), y: .value("pupil", magnitude))
          .foregroundStyle(.green)
      }
      .chartXAxis(.hidden)
      .padding(.all)
    }
    .onAppear {
      if let storage = IOManager.tryToRead(from: "Ngoc Anh - easy") {
        amplitudeData = storage.collectedData.map(\.amplitude)
        pupilData = storage.collectedData.map(\.pupilSize)
      }
    }
  }
}

#Preview {
  GraphView()
}
