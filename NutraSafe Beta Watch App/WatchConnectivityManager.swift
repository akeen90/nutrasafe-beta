import WatchConnectivity
import Foundation

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isConnected = false
    @Published var isReachable = false
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
        }
    }
    
    func startSession() {
        guard WCSession.isSupported() else {
            print("WatchConnectivity is not supported on this device")
            return
        }
        
        WCSession.default.activate()
    }
    
    func requestTodayData() {
        guard WCSession.default.isReachable else {
            print("iPhone app is not reachable")
            return
        }
        
        let message = ["request": "todayData"]
        WCSession.default.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async {
                self.handleTodayDataResponse(reply)
            }
        }) { error in
            print("Failed to send message: \(error.localizedDescription)")
        }
    }
    
    func requestQuickAddFood(_ foodId: String) {
        guard WCSession.default.isReachable else {
            print("iPhone app is not reachable")
            return
        }
        
        let message = ["request": "quickAdd", "foodId": foodId]
        WCSession.default.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async {
                print("Food added successfully: \(reply)")
                self.requestTodayData() // Refresh data after adding
            }
        }) { error in
            print("Failed to add food: \(error.localizedDescription)")
        }
    }
    
    private func handleTodayDataResponse(_ reply: [String: Any]) {
        // Parse the response from iPhone and update WatchDataManager
        // This would contain today's food entries, nutrition summary, etc.
        print("Received today data: \(reply)")
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
            self.isReachable = session.isReachable
        }
        
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
        print("Session reachability changed: \(session.isReachable)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received message from iPhone: \(message)")
        
        DispatchQueue.main.async {
            if let type = message["type"] as? String {
                switch type {
                case "foodAdded":
                    // Handle food addition notification
                    break
                case "dataUpdate":
                    // Handle data updates
                    self.handleTodayDataResponse(message)
                default:
                    break
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("Received message with reply handler: \(message)")
        
        // Handle any requests from iPhone app
        replyHandler(["status": "received"])
    }
}