import SwiftUI

struct MakeKeyPressSilentView: NSViewRepresentable {
  
  class KeyView: NSView {
    func isManagedByThisView(_ event: NSEvent) -> Bool {
      // just a work around so we always return true
      return true
    }
    
    override var acceptsFirstResponder: Bool { true }
    override func keyDown(with event: NSEvent) {
      guard isManagedByThisView(event) else {
        // in `super.keyDown(with: event)`,
        // the event goes up through the responder chain
        // and if no other responders process it, causes beep sound.
        return super.keyDown(with: event)
      }
      // print("pressed \(event.keyCode)")
    }
  }
  
  func makeNSView(context: Context) -> NSView {
    let view = KeyView()
    DispatchQueue.main.async { // wait till next event cycle
      view.window?.makeFirstResponder(view)
    }
    return view
  }
  
  func updateNSView(_ nsView: NSView, context: Context) { }
  
}
