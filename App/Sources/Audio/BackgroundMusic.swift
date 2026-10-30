import AVFoundation
import ShellCore

/// The child screen's music (background-music): idle — its own player, the microphone closed (screen rule 4); from a
/// tap to her sleep — a node on the voice's engine, barely audible, taken out of the microphone by the echo canceller.
/// The automaton says the level and when; the loop passes between the two at that level from the same place, with
/// 20 ms edges instead of clicks. The audio session is the warm-up's: the music never sets it (L130).
@MainActor
final class BackgroundMusic {
    let line: MusicLine
    private static let edge = 0.02
    private let engine: AVAudioEngine, node = AVAudioPlayerNode()
    private var player: AVAudioPlayer?, loop: AVAudioPCMBuffer?, fader = MusicFader(), scene = MusicCue.Scene()
    private var way: Task<Void, Never>?, onEngine = false, wired = false, start: AVAudioFramePosition = 0

    /// The parent's line from the bundle; the node joins the engine's graph here, before voice processing (X9).
    init(_ bundle: URL, engine: AVAudioEngine) {
        let url = bundle.appendingPathComponent("music.json")
        (line, self.engine) = (MusicLine.decode((try? Data(contentsOf: url)) ?? Data()), engine)
        guard line.on, line.volume > 0 else { return }
        engine.attach(node)
        let format = AVAudioFormat(standardFormatWithSampleRate: Double(MusicBox.rate), channels: 2)
        wired = (try? engine.connectNode(node, to: engine.mainMixerNode, format: format)) != nil  // the iOS 27 call
    }

    /// The sound's mode known: the loop in the background, no music in a talk without an echo canceller; console lines.
    func begin(sound: String) -> [String] {
        Task { await load(cancelsEcho: sound != "half") }
        let silent = sound == "half" && line.on ? ["музыка: в разговоре молчит" + " — нет эхоподавления"] : []
        return [line.console] + line.notes + silent
    }

    /// The loop from code, off the main actor; then the music follows the scene.
    private func load(cancelsEcho: Bool) async {
        guard line.on, line.volume > 0 else { return }
        let samples = await Task.detached(priority: .utility) { MusicBox.render() }.value
        player = try? AVAudioPlayer(data: Self.wave(samples), fileTypeHint: AVFileType.wav.rawValue)
        player?.numberOfLoops = -1
        loop = Self.buffer(samples)
        update { ($0.ready, $0.cancelsEcho) = (true, cancelsEcho) }
    }

    /// A change of the scene: the screen, the app in front, the shown session's phase.
    func update(_ change: (inout MusicCue.Scene) -> Void) {
        change(&scene)
        guard let ramp = fader.cue(MusicCue.of(scene, line: line), line: line, at: now) else { return }
        way?.cancel()
        way = Task { [weak self] in
            let wait = ramp.start - ProcessInfo.processInfo.systemUptime
            if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
            guard !Task.isCancelled else { return }
            await self?.perform(ramp)
        }
    }

    /// A tap (Y2): the way down is waited out, then the loop moves to the node at the quiet level from the same place —
    /// the microphone opens after this returns. Without an echo canceller the music is simply gone (Y8).
    func duck() async {
        update { $0.waking = true }
        let wait = fader.end - now
        if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
        guard MusicCue.of(scene, line: line) == .quiet, wired, let player, let loop else { return }
        if player.isPlaying {
            player.setVolume(0, fadeDuration: Self.edge)
            try? await Task.sleep(for: .seconds(Self.edge))
            player.pause()
        }
        schedule(loop, from: AVAudioFramePosition(player.currentTime * Double(MusicBox.rate)))
    }

    /// The loop on the node from `frame` (wrapped), at the quiet level.
    private func schedule(_ loop: AVAudioPCMBuffer, from frame: AVAudioFramePosition) {
        start = frame % AVAudioFramePosition(loop.frameLength)
        if let tail = Self.tail(of: loop, from: Int(start)) { node.scheduleBuffer(tail, completionHandler: nil) }
        node.scheduleBuffer(loop, at: nil, options: .loops, completionHandler: nil)
        node.volume = Float(line.quiet)
        onEngine = true
    }

    /// The engine runs: the node sounds (the iOS 27 call; a refusal leaves the talk without music).
    func join() { if onEngine, engine.isRunning { _ = try? node.playAudio() } }

    /// The talk ended (Y4): the node fades out and gives the loop back to the idle player from the same place, unless
    /// the music is on its way to silence (the console took the screen); then the way up after the wait.
    func release() async {
        if onEngine {
            let played = node.lastRenderTime.flatMap { node.playerTime(forNodeTime: $0) }?.sampleTime ?? 0
            for step in stride(from: 3, through: 0, by: -1) {
                node.volume = Float(line.quiet) * Float(step) / 4
                try? await Task.sleep(for: .seconds(Self.edge / 4))
            }
            node.stop()
            onEngine = false
            if fader.ramp.to > 0, let player, let loop {
                player.currentTime = Double((start + played) % AVAudioFramePosition(loop.frameLength))
                    / Double(MusicBox.rate)
                player.volume = 0
                player.play()
                player.setVolume(Float(fader.level(at: now)), fadeDuration: Self.edge)
            }
        }
        update { $0.waking = false }
    }

    /// A call or Siri gave the sound back: the idle player resumes if the music was playing.
    func resume() {
        if !onEngine, fader.ramp.to > 0, let player, !player.isPlaying { player.play() }
    }

    /// One way of the level on the idle player; the node keeps its level through a talk and takes it at a tap.
    private func perform(_ ramp: MusicFader.Ramp) async {
        guard !onEngine, !(scene.waking && ramp.to > ramp.from), let player else { return }
        if !player.isPlaying {
            guard ramp.to > 0 else { return }
            player.volume = Float(ramp.from)
            player.play()
        }
        player.setVolume(Float(ramp.to), fadeDuration: ramp.length)
        guard ramp.to == 0 else { return }
        try? await Task.sleep(for: .seconds(ramp.length))
        if !Task.isCancelled { player.pause() }
    }

    private var now: Double { ProcessInfo.processInfo.systemUptime }

    /// The loop as a WAV in memory for the idle player: «RIFF», size, «WAVE», «fmt » of PCM 16-bit stereo, «data».
    private static func wave(_ samples: [Int16]) -> Data {
        let bytes = UInt32(samples.count * 2), rate = UInt32(MusicBox.rate)
        let fields: [(UInt32, Int)] = [(0x4646_4952, 4), (36 + bytes, 4), (0x4556_4157, 4), (0x2074_6D66, 4), (16, 4),
                                       (1, 2), (2, 2), (rate, 4), (rate * 4, 4), (4, 2), (16, 2), (0x6174_6164, 4),
                                       (bytes, 4)]
        var data = Data()
        for (value, size) in fields {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0.prefix(size)) }
        }
        samples.withUnsafeBytes { data.append(contentsOf: $0) }  // the phone and the Mac are little-endian
        return data
    }

    /// The loop for the node: float stereo.
    private static func buffer(_ samples: [Int16]) -> AVAudioPCMBuffer? {
        let frames = samples.count / 2
        guard let format = AVAudioFormat(standardFormatWithSampleRate: Double(MusicBox.rate), channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)),
              let channels = buffer.floatChannelData else { return nil }
        buffer.frameLength = AVAudioFrameCount(frames)
        for frame in 0..<frames {
            (channels[0][frame], channels[1][frame]) = (Float(samples[2 * frame]) / 32768,
                                                        Float(samples[2 * frame + 1]) / 32768)
        }
        return buffer
    }

    /// The rest of the loop from `first`, opening with a 20 ms edge.
    private static func tail(of loop: AVAudioPCMBuffer, from first: Int) -> AVAudioPCMBuffer? {
        let count = Int(loop.frameLength) - first, edge = Double(MusicBox.rate) * Self.edge
        guard count > 0, let tail = AVAudioPCMBuffer(pcmFormat: loop.format, frameCapacity: AVAudioFrameCount(count)),
              let source = loop.floatChannelData, let target = tail.floatChannelData else { return nil }
        tail.frameLength = AVAudioFrameCount(count)
        for channel in 0..<2 {
            for index in 0..<count {
                target[channel][index] = source[channel][first + index] * Float(min(1, Double(index) / edge))
            }
        }
        return tail
    }
}
