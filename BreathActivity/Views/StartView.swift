//
//  StartView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 11.12.23.
//

import SwiftUI

struct StartView: View {
  @Environment(\.openWindow) var openWindow
    var body: some View {
      VStack {
        Button {
          openWindow(id: "Experiment")
        } label: {
          Image(systemName: "play.fill")
            .font(.largeTitle)
            .foregroundColor(.accentColor)
        }
      }
    }
}

#Preview {
    StartView()
}
