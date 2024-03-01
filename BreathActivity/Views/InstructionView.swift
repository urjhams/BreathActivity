//
//  InstructionView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 01.03.24.
//

import SwiftUI

struct InstructionView: View {
  
  @State var content: String
  
  var body: some View {
    Text(content)
  }
}

#Preview {
  InstructionView(content: "Content to show")
    .frame(minWidth: 500, minHeight: 300)
}
