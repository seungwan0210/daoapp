import Flutter
import UIKit

class GripStreamBus: NSObject, FlutterStreamHandler {
    static let shared = GripStreamBus()
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    static func send(_ payload: [String: Any]) {
        DispatchQueue.main.async {
            shared.eventSink?(payload)
        }
    }
}