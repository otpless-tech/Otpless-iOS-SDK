//
//  MerchantTimer.swift
//  Pods
//
//  Created by Sparsh on 17/01/25.
//


import Foundation

class RequestTimer {
    static let shared = RequestTimer()
    
    private var timer: Timer?
    private var timerInterval: TimeInterval = 30.0
    private var onTimeout: (() -> Void)?
    
    /// Starts the timer with a custom interval and timeout action.
    /// - Parameters:
    ///   - interval: The duration of the timer in seconds. Default is 30 seconds.
    ///   - onTimeout: Closure to execute when the timer ends.
    func startTimer(interval: TimeInterval = 30.0, onTimeout: @escaping () -> Void) {
        cancelTimer() // Stop existing timer
        self.timerInterval = interval
        self.onTimeout = onTimeout
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.handleTimeout()
        }
        
        OtplessLogger.log(string: "Timer started for \(interval) seconds", type: "REQUEST_TIMER")
    }
    
    /// Cancels the timer if it's running.
    func cancelTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
            OtplessLogger.log(string: "Timer cancelled", type: "REQUEST_TIMER")
        }
    }
    
    /// Handles the timeout action.
    private func handleTimeout() {
        OtplessLogger.log(string: "Timer ended", type: "REQUEST_TIMER")
        onTimeout?()
    }
}
