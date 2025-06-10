import Flutter
import CoreNFC

@available(iOS 13.0, *)
class NfcHandler: NSObject, NFCNDEFReaderSessionDelegate {
    private var flutterResult: FlutterResult?
    private var methodChannel: FlutterMethodChannel
    private var session: NFCNDEFReaderSession?
    
    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        super.init()
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            result(NFCNDEFReaderSession.readingAvailable)
        case "startSession":
            startSession(result: result)
        case "stopSession":
            stopSession(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startSession(result: @escaping FlutterResult) {
        guard NFCNDEFReaderSession.readingAvailable else {
            result(FlutterError(code: "UNAVAILABLE", message: "NFC not available", details: nil))
            return
        }
        
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near the NFC tag"
        session?.begin()
        result(nil)
    }
    
    private func stopSession(result: @escaping FlutterResult) {
        session?.invalidate()
        session = nil
        result(nil)
    }
    
    // NFCNDEF delegate methods
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let message = messages.first, let record = message.records.first else { return }
        
        if let payload = String(data: record.payload, encoding: .utf8) {
            methodChannel.invokeMethod("onTagRead", arguments: payload)
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // Handle session invalidation
    }
}