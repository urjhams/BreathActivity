import SwiftUI
import Charts

struct GraphView: View {
  
  @State var amplitudeData = [Float]()
  @State var pupilData = [Float]()
  
  var body: some View {
    VStack {
      Chart(Array(amplitudeData.enumerated()), id: \.0) { index, magnitude in
        LineMark(x: .value("id", index), y: .value("amplitude", magnitude))
          .interpolationMethod(.catmullRom)
          .foregroundStyle(.red)
      }
      .chartXAxis(.hidden)
//      .chartYAxis(.hidden)
      .padding(.all)
      
      Chart(Array(pupilData.enumerated()), id: \.0) { index, magnitude in
        LineMark(x: .value("id", index), y: .value("pupil", magnitude))
          .interpolationMethod(.catmullRom)
          .foregroundStyle(.green)
      }
      .chartXAxis(.hidden)
//      .chartYAxis(.hidden)
      .padding(.all)
    }
    .onAppear {
      if let storage = IOManager.tryToRead(from: "Ngoc Anh - easy") {
        let amplitude = storage.collectedData.map(\.amplitude).map { $0 * 1000 }
        let pupil = storage.collectedData.map(\.pupilSize)
        
        func movingAverage(_ data: [Float], windowSize: Int) -> [Float] {
          var smoothedData = [Float]()
          
          for index in 0..<data.count {
            let lowerBound = max(0, index - windowSize / 2)
            let upperBound = min(data.count - 1, index + windowSize / 2)
            let valuesInRange = data[lowerBound...upperBound]
            let average = valuesInRange.reduce(0, +) / Float(valuesInRange.count)
            smoothedData.append(average)
          }
          
          return smoothedData
        }
        
//        let data = amplitude.map{ Double($0) }
//        let shared = Smooth.shared
//        print(amplitude)
//        let (signals, avgFilter, stdFilter) = shared.ThresholdingAlgo(
//          y: data, 
//          lag: 10,
//          threshold: 3,
//          influence: 0.2
//        )
        
        amplitudeData = movingAverage(amplitude, windowSize: 10)
        
        pupilData = movingAverage(pupil, windowSize: 3)
        
//        amplitudeData = storage.collectedData.map(\.amplitude)
//        pupilData = storage.collectedData.map(\.pupilSize)
      }
    }
  }
}

#Preview {
  GraphView()
}

class Smooth {
  public static let shared = Smooth()
  
  // Function to calculate the arithmetic mean
  func arithmeticMean(array: [Double]) -> Double {
    var total: Double = 0
    for number in array {
      total += number
    }
    return total / Double(array.count)
  }
  
  // Function to calculate the standard deviation
  func standardDeviation(array: [Double]) -> Double
  {
  let length = Double(array.count)
  let avg = array.reduce(0, {$0 + $1}) / length
  let sumOfSquaredAvgDiff = array.map { pow($0 - avg, 2.0)}.reduce(0, {$0 + $1})
  return sqrt(sumOfSquaredAvgDiff / length)
  }
  
  // Function to extract some range from an array
  func subArray<T>(array: [T], s: Int, e: Int) -> [T] {
    if e > array.count {
      return []
    }
    return Array(array[s..<min(e, array.count)])
  }
  
  // Smooth z-score thresholding filter
  func ThresholdingAlgo(y: [Double],lag: Int,threshold: Double,influence: Double) -> ([Int],[Double],[Double]) {
    
    // Create arrays
    var signals   = Array(repeating: 0, count: y.count)
    var filteredY = Array(repeating: 0.0, count: y.count)
    var avgFilter = Array(repeating: 0.0, count: y.count)
    var stdFilter = Array(repeating: 0.0, count: y.count)
    
    // Initialise variables
    for i in 0...lag-1 {
      signals[i] = 0
      filteredY[i] = y[i]
    }
    
    // Start filter
    avgFilter[lag-1] = arithmeticMean(array: subArray(array: y, s: 0, e: lag-1))
    stdFilter[lag-1] = standardDeviation(array: subArray(array: y, s: 0, e: lag-1))
    
    for i in lag...y.count-1 {
      if abs(y[i] - avgFilter[i-1]) > threshold*stdFilter[i-1] {
        if y[i] > avgFilter[i-1] {
          signals[i] = 1      // Positive signal
        } else {
          // Negative signals are turned off for this application
          //signals[i] = -1       // Negative signal
        }
        filteredY[i] = influence*y[i] + (1-influence)*filteredY[i-1]
      } else {
        signals[i] = 0          // No signal
        filteredY[i] = y[i]
      }
      // Adjust the filters
      avgFilter[i] = arithmeticMean(array: subArray(array: filteredY, s: i-lag, e: i))
      stdFilter[i] = standardDeviation(array: subArray(array: filteredY, s: i-lag, e: i))
    }
    
    return (signals,avgFilter,stdFilter)
  }

}
