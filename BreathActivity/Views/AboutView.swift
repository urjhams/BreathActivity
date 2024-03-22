//
//  DescriptionView.swift
//  BreathActivity
//
//  Created by Quân Đinh on 12.03.24.
//

import SwiftUI

struct AboutView: View {
  
  let model: [PageModel] = [
    .init(
      image: "Nback-sample",
      content: "In the n-back task, you need to remember the stimulus (image in this case) that presented n steps earlier in the sequence. For example with 2 back task in the image bellow, press the space button when you recognize the current image is matched with the image that presented 2 earlier images.",
      tag: "Page 1"
    ),
    .init(
      image: "Nback",
      content: "In this experiment, we will have easy, normal, and hard level which are 1-back, 2-back and 3-back tasks.",
      tag: "Page 2"
    )
  ]
  
  @State var selection = "Page 1"
  
  @Binding var state: ExperimentalState
  
  var body: some View {
    VStack {
      Text("About N- back task")
        .font(.title2)
        .fontWeight(.heavy)
      TabView(selection: $selection) {
        ForEach(model) {
          PageView(model: $0)
            .tag($0.tag)
        }
      }
      .tabViewStyle(DefaultTabViewStyle())
      Text("Press ESC to go back")
        .fontWeight(.bold)
      MakeKeyPressSilentView()
        .frame(height: 0)
        .onAppear {
          // key pressed notification register
          NSEvent.addLocalMonitorForEvents(matching: [.keyUp]) { event in
            self.setupKeyPress(from: event)
            return event
          }
        }
    }
    .padding()
  }
}

extension AboutView {
  private func setupKeyPress(from event: NSEvent) {
    switch event.keyCode {
    case 49:  // space
      selection = selection == "Page 1" ? "Page 2" : "Page 1"
    case 53:  // escape
      state = .start
    case 123: // left arrow
      if selection == "Page 2" {
        selection = "Page 1"
      }
    case 124: // right arrow
      if selection == "Page 1" {
        selection = "Page 2"
      }
    default:
      break
    }
  }
}

#Preview {
  @State var state: ExperimentalState = .about
  return AboutView(state: $state)
}

struct PageModel: Identifiable {
  let id = UUID()
  let image: String
  let content: String
  let tag: String
}

struct PageView: View {
  let model: PageModel
  var body: some View {
    VStack(spacing: 16) {
      Text(model.content)
      Image(model.image)
        .resizable()
        .aspectRatio(contentMode: .fit)
    }
    .padding()
  }
}
