import SwiftUI
import Combine

extension Encodable {
  /// Converting object to postable JSON
  func toJSON(_ encoder: JSONEncoder = JSONEncoder()) throws -> String {
    let data = try encoder.encode(self)
    return String(decoding: data, as: UTF8.self)
  }
}

extension Collection {
  /// Returns the element at the specified index if it is within bounds, otherwise nil.
  subscript (safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

public extension Color {
  
#if os(macOS)
  static let background = Color(NSColor.windowBackgroundColor)
  static let secondaryBackground = Color(NSColor.underPageBackgroundColor)
  static let tertiaryBackground = Color(NSColor.controlBackgroundColor)
#else
  static let background = Color(UIColor.systemBackground)
  static let secondaryBackground = Color(UIColor.secondarySystemBackground)
  static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
#endif
}


extension Publisher {
  func withLatestFrom<P>(
    _ other: P
  ) -> AnyPublisher<(Self.Output, P.Output), Failure> where P: Publisher, Self.Failure == P.Failure {
    let other = other
    // Note: Do not use `.map(Optional.some)` and `.prepend(nil)`.
    // There is a bug in iOS versions prior 14.5 in `.combineLatest`. If P.Output itself is Optional.
    // In this case prepended `Optional.some(nil)` will become just `nil` after `combineLatest`.
      .map { (value: $0, ()) }
      .prepend((value: nil, ()))
    
    return map { (value: $0, token: UUID()) }
      .combineLatest(other)
      .removeDuplicates { (old, new) in
        let lhs = old.0, rhs = new.0
        return lhs.token == rhs.token
      }
      .map { ($0.value, $1.value) }
      .compactMap { (left, right) in
        right.map { (left, $0) }
      }
      .eraseToAnyPublisher()
  }
}

//                       _oo0oo_
//                      o8888888o
//                      88" . "88
//                      (| -_- |)
//                      0\  =  /0
//                    ___/`---'\___
//                  .' \\|     |// '.
//                 / \\|||  :  |||// \
//                / _||||| -:- |||||- \
//               |   | \\\  -  /// |   |
//               | \_|  ''\---/''  |_/ |
//               \  .-\__  '-'  ___/-. /
//             ___'. .'  /--.--\  `. .'___
//          ."" '<  `.___\_<|>_/___.' >' "".
//         | | :  `- \`.;`\ _ /`;.`/ - ` : | |
//         \  \ `_.   \_ __\ /__ _/   .-` /  /
//     =====`-.____`.___ \_____/___.-`___.-'=====
//                       `=---='
//
//     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//            Phật phù hộ, không bao giờ BUG
//     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
