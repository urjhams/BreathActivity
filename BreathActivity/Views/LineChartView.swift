//
//  LineChartView.swift
//  BreathMeasuring
//
//  Created by Quân Đinh on 27.07.23.
//

import SwiftUI
import Charts
import Combine

struct LineChartView: View {
  @State var data: [Int] = []
  
  @State var timer: AnyPublisher<Date, Never>
  
  /// we will use 0 as the mark of no new data, so just accept the value that higher than 0
  @Binding var latestData: Int
  
  let dataRange: UInt
  
  @Binding var tracking: Bool
    
  var body: some View {
    
    GroupBox("Breathing peaks") {
      Chart(Array(data.enumerated()), id: \.0) { index, magnitude in
        LineMark(x: .value("index", String(index)) , y: .value("power", magnitude))
          .interpolationMethod(.catmullRom)
          .accessibilityLabel("\(index.description)")
      }
      .chartXAxis(.hidden)
      .onReceive(timer, perform: updateData(_:))
      .padding()
    }
  }
  
  public func updateData(_ date: Date) {
    
    guard tracking else {
      if !data.isEmpty {
        clearData()
      }
      return
    }
    
    guard latestData > 0 else {
      return
    }
    
    if data.count == Int(dataRange) {
      data.removeFirst()
    }
    // TODO: might use Fourier transform?
    // TODO: https://medium.com/theengineeringgecko/finding-a-peak-f2d833525d31
    data.append(latestData)
    
    // reset the latestData
    latestData = 0
  }
  
  public func clearData() {
    data = []
  }
}
