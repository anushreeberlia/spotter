import AVFoundation

@Observable
class CuePlayer {
    private let synthesizer = AVSpeechSynthesizer()
    private var lastCueTime: [String: Date] = [:]
    private let minimumInterval: TimeInterval = 3.0

    func speak(_ message: String, ruleId: String) {
        let now = Date()
        if let lastTime = lastCueTime[ruleId],
           now.timeIntervalSince(lastTime) < minimumInterval {
            return
        }

        lastCueTime[ruleId] = now

        let utterance = AVSpeechUtterance(string: message)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.1
        utterance.volume = 0.8
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        lastCueTime.removeAll()
    }
}
