import AllyCore
import CryptoKit
import Foundation
import llama

/// Gemma 4 through llama.cpp behind `LanguageModel` (the probe's `LlamaEngine`): sequence 0 keeps the persona's system
/// turn, a conversation is its copy in sequence 1 and stays in the KV; all work runs on the model's own serial queue.
public final class LlamaModel: LanguageModel, @unchecked Sendable {
    /// Warm-up seconds (A24): `weights`, `context`, then `prefix_file` (read from its state file) or `prefix_build`.
    public private(set) var warmup: [String: Double] = [:]
    private let model: OpaquePointer, ctx: OpaquePointer, vocab: OpaquePointer, settings: LlamaSettings
    private let queue: DispatchQueue, current = Locked<StopFlag?>(nil), prompt = Locked(0)
    private var batch: llama_batch, prefixCount: Int32 = 0, position: Int32 = 0, fresh = true, open = false
    /// The last turn in sequence 1: `commit` and `retract` rewrite it (D5: the model remembers only what sounded).
    private var last: LastTurn?

    /// Weights, context and the persona prefix, on the model's queue; `cache` holds the prefix state file.
    public static func load(weights: URL, persona: String, settings: LlamaSettings,
                            cache: URL) async throws -> LlamaModel {
        // seq_rm of a tail longer than the sliding window is exact only with the full SWA cache (stand 2026-10-19)
        guard settings.runtime.swaFull else { throw LlamaError.swaFullOff }
        let queue = DispatchQueue(label: "ally.llama", qos: .userInitiated)
        return try await withCheckedThrowingContinuation { done in
            queue.async {
                done.resume(with: Result {
                    let model = try LlamaModel(weights: weights, settings: settings, queue: queue)
                    try model.preparePrefix(persona, weights: weights, cache: cache)
                    return model
                })
            }
        }
    }

    private init(weights: URL, settings: LlamaSettings, queue: DispatchQueue) throws {
        llama_backend_init()
        let start = ProcessInfo.processInfo.systemUptime, runtime = settings.runtime
        var params = llama_model_default_params()
        (params.n_gpu_layers, params.load_mode) = (runtime.gpuLayers, LLAMA_LOAD_MODE_MMAP)
        params.lazy_mode = ["on": LLAMA_LAZY_MODE_ON, "auto": LLAMA_LAZY_MODE_AUTO][runtime.lazy] ?? LLAMA_LAZY_MODE_OFF
        guard let model = llama_model_load_from_file(weights.path, params) else {
            throw LlamaError.load(weights.lastPathComponent)
        }
        let loaded = ProcessInfo.processInfo.systemUptime
        guard let ctx = llama_init_from_model(model, Self.contextParams(runtime)) else {
            llama_model_free(model)
            throw LlamaError.context
        }
        (self.model, self.ctx, self.vocab) = (model, ctx, llama_model_get_vocab(model))
        (self.settings, self.queue, batch) = (settings, queue, llama_batch_init(Int32(runtime.nBatch), 0, 1))
        warmup = ["weights": loaded - start, "context": ProcessInfo.processInfo.systemUptime - loaded]
        llama_set_abort_callback(ctx, { data in  // a raised stop aborts a decode in flight, not only the next token
            guard let data else { return false }
            return Unmanaged<Locked<StopFlag?>>.fromOpaque(data).takeUnretainedValue()({ $0?.isRaised }) ?? false
        }, Unmanaged.passUnretained(current).toOpaque())
    }

    deinit {
        llama_batch_free(batch)
        llama_free(ctx)
        llama_model_free(model)
    }

    /// Tokens of the conversation when the last reply started: the persona prefix, earlier turns, this user turn.
    public var promptTokens: Int { prompt { $0 } }

    /// The next reply starts a new conversation from a fresh copy of the persona prefix.
    public func newConversation() { queue.async { self.fresh = true } }

    public func reply(to utterance: String) -> AsyncThrowingStream<String, Error> {
        let (stream, output) = AsyncThrowingStream<String, Error>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let stop = StopFlag()
        current { $0 = stop }
        output.onTermination = { _ in stop.raise() }
        queue.async { [self] in
            do {
                try turn(utterance, stop: stop, output: output)
                output.finish()
            } catch {
                output.finish(throwing: error)
            }
        }
        return stream
    }

    public func cancel() { current { $0 }?.raise() }

    /// D5: the last turn's model part becomes what sounded — sentences played to the end, as the contract let them out;
    /// her line stays. Empty `spoken` leaves an empty model turn.
    public func commit(spoken: String) {
        queue.async { [self] in
            release()
            guard let turn = last else { return }
            forget(after: turn.reply)
            do { try said(spoken) } catch { forget(after: turn.reply) }
            open = true
        }
    }

    /// D5: the last turn leaves the memory entirely — a silent turn of speculation she went on talking after.
    public func retract() {
        queue.async { [self] in
            guard let turn = last else { return }
            forget(after: turn.start)
            (open, last) = (turn.wasOpen, nil)
        }
    }

    /// D5: a turn without the model — a router's script, the contract's canned phrase — goes into the memory as her
    /// line and what sounded.
    public func remember(heard: String, spoken: String) {
        queue.async { [self] in
            release()
            begin()
            let (start, wasOpen) = (position, open)
            do {
                try user(heard)
                last = LastTurn(start: start, reply: position, wasOpen: wasOpen)
                try said(spoken)
                open = true
            } catch {
                forget(after: start)
                (open, last) = (wasOpen, nil)
            }
        }
    }

    private static func contextParams(_ runtime: LlamaSettings.Runtime) -> llama_context_params {
        var params = llama_context_default_params()
        (params.n_ctx, params.n_batch, params.n_ubatch) = (runtime.nCtx, runtime.nBatch, runtime.nUbatch)
        (params.n_seq_max, params.kv_unified, params.swa_full) = (runtime.nSeqMax, runtime.kvUnified, runtime.swaFull)
        (params.n_threads, params.n_threads_batch) = (runtime.threads, runtime.threads)
        let flash = ["auto": LLAMA_FLASH_ATTN_TYPE_AUTO, "on": LLAMA_FLASH_ATTN_TYPE_ENABLED]
        params.flash_attn_type = flash[runtime.flashAttn] ?? LLAMA_FLASH_ATTN_TYPE_DISABLED
        return params
    }

    /// Sequence 0 ← the persona's system turn (trimmed, as the chat template renders it): read from the state file
    /// keyed by persona, weights, build and runtime, else built and written there — the only prefix file in `cache`.
    private func preparePrefix(_ persona: String, weights: URL, cache: URL) throws {
        let start = ProcessInfo.processInfo.systemUptime, files = FileManager.default
        let trimmed = persona.trimmingCharacters(in: .whitespacesAndNewlines)
        let system = try tokenize("<|turn>system\n" + trimmed + "<turn|>\n", special: true)
        let size = ((try? files.attributesOfItem(atPath: weights.path))?[.size] as? NSNumber)?.int64Value ?? 0
        let key = SHA256.hash(data: Data("\(trimmed)|\(weights.lastPathComponent)|\(size)|\(settings.runtime)".utf8))
        let file = cache.appendingPathComponent("persona-" + key.prefix(8).map { String(format: "%02x", $0) }.joined())
        prefixCount = Int32(system.count)
        if files.fileExists(atPath: file.path) {
            var read = [llama_token](repeating: 0, count: system.count + 1), count = 0
            if llama_state_seq_load_file(ctx, file.path, 0, &read, read.count, &count) > 0,
               Array(read.prefix(count)) == system {
                warmup["prefix_file"] = ProcessInfo.processInfo.systemUptime - start
                return
            }
        }
        llama_memory_seq_rm(llama_get_memory(ctx), 0, -1, -1)
        try decode(system, seq: 0, from: 0)
        let old = (try? files.contentsOfDirectory(at: cache, includingPropertiesForKeys: nil)) ?? []
        for stale in old where stale.lastPathComponent.hasPrefix("persona-") { try? files.removeItem(at: stale) }
        _ = llama_state_seq_save_file(ctx, file.path, 0, system, system.count)
        warmup["prefix_build"] = ProcessInfo.processInfo.systemUptime - start
    }

    /// One turn in sequence 1: the user turn closes the previous model turn, the reply grows token by token to the end
    /// of turn or the token limit; a stopped or failed turn leaves no trace in the KV.
    private func turn(_ utterance: String, stop: StopFlag,
                      output: AsyncThrowingStream<String, Error>.Continuation) throws {
        begin()
        let (start, wasOpen) = (position, open)
        do {
            try user(utterance)
            prompt { $0 = Int(position) }
            last = LastTurn(start: start, reply: position, wasOpen: wasOpen)
            try sample(stop: stop, output: output)
            open = true
        } catch {
            if error as? LlamaError == .stopped, let turn = last, turn.start == start {
                forget(after: turn.reply)  // a stopped reply leaves her line; what sounded comes with `commit`
                open = true
                return
            }
            forget(after: start)
            (open, last) = (wasOpen, nil)
            if error as? LlamaError != .stopped { throw error }
        }
    }

    /// A new conversation, or one about to overflow the context, starts again from the persona prefix.
    private func begin() {
        guard fresh || position + Int32(settings.sampling.maxTokens * 2) > Int32(settings.runtime.nCtx) else { return }
        let memory = llama_get_memory(ctx)
        llama_memory_seq_rm(memory, 1, -1, -1)
        llama_memory_seq_cp(memory, 0, 1, -1, -1)
        (position, open, fresh, last) = (prefixCount, false, false, nil)
    }

    /// Her line closes the open model turn and opens the model's.
    private func user(_ utterance: String) throws {
        let text = utterance.trimmingCharacters(in: .whitespacesAndNewlines)
        let tokens = try tokenize((open ? "<turn|>\n" : "") + "<|turn>user\n" + text + "<turn|>\n<|turn>model\n",
                                  special: false)
        try decode(tokens, seq: 1, from: position)
        position += Int32(tokens.count)
    }

    /// What Elly said, as it sounded, written into the open model turn.
    private func said(_ spoken: String) throws {
        let text = spoken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let tokens = try tokenize(text, special: false)
        try decode(tokens, seq: 1, from: position)
        position += Int32(tokens.count)
    }

    /// Sequence 1 from `position` on leaves the KV.
    private func forget(after position: Int32) {
        llama_memory_seq_rm(llama_get_memory(ctx), 1, position, -1)
        self.position = position
    }

    /// A stopped reply's raised flag must not abort the memory work that follows it; a new reply's flag stays.
    private func release() { current { if $0?.isRaised == true { $0 = nil } } }

    /// The bench's chain — top-k → top-p → min-p → temperature → dist(seed); accumulated text after every token.
    private func sample(stop: StopFlag, output: AsyncThrowingStream<String, Error>.Continuation) throws {
        let sampling = settings.sampling
        guard let chain = llama_sampler_chain_init(llama_sampler_chain_default_params()) else {
            throw LlamaError.context
        }
        defer { llama_sampler_free(chain) }
        for link in [llama_sampler_init_top_k(sampling.topK), llama_sampler_init_top_p(sampling.topP, 0),
                     llama_sampler_init_min_p(sampling.minP, 0),
                     llama_sampler_init_temp_ext(sampling.temperature, 0, 1), llama_sampler_init_dist(sampling.seed)] {
            llama_sampler_chain_add(chain, link)
        }
        var bytes: [UInt8] = []
        for _ in 0..<sampling.maxTokens {
            guard !stop.isRaised else { throw LlamaError.stopped }
            let token = llama_sampler_sample(chain, ctx, -1)
            if llama_vocab_is_eog(vocab, token) { return }
            var piece = [CChar](repeating: 0, count: 256)
            let count = llama_token_to_piece(vocab, token, &piece, Int32(piece.count), 0, false)
            bytes += piece.prefix(Int(max(count, 0))).map { UInt8(bitPattern: $0) }
            output.yield(Self.complete(bytes))
            try decode([token], seq: 1, from: position)
            position += 1
        }
    }

    /// Tokens into `seq` from position `from`, in n_batch chunks, logits for the last one; a raised stop aborts.
    private func decode(_ tokens: [llama_token], seq: llama_seq_id, from: Int32) throws {
        let cap = Int(settings.runtime.nBatch)
        for chunk in stride(from: 0, to: tokens.count, by: cap) {
            let end = min(chunk + cap, tokens.count)
            batch.n_tokens = Int32(end - chunk)
            for index in chunk..<end {
                let slot = index - chunk
                (batch.token[slot], batch.pos[slot], batch.n_seq_id[slot]) = (tokens[index], from + Int32(index), 1)
                batch.seq_id[slot]?[0] = seq
                batch.logits[slot] = index == tokens.count - 1 ? 1 : 0
            }
            let code = llama_decode(ctx, batch)
            if code == 2 { throw LlamaError.stopped }
            guard code == 0 else { throw LlamaError.decode(code) }
        }
    }

    /// Tokens of the text; the buffer always fits (a token covers at least one byte, plus BOS).
    private func tokenize(_ text: String, special: Bool) throws -> [llama_token] {
        let length = Int32(text.utf8.count)
        var tokens = [llama_token](repeating: 0, count: Int(length) + 8)
        let count = llama_tokenize(vocab, text, length, &tokens, Int32(tokens.count), special, true)
        guard count >= 0 else { throw LlamaError.tokenize }
        return Array(tokens.prefix(Int(count)))
    }

    /// The text so far without a trailing, not yet complete UTF-8 sequence (a token may end inside a letter); bytes
    /// that never form text give an empty reply, and the contract answers with its canned phrase.
    static func complete(_ bytes: [UInt8]) -> String {
        for cut in 0...min(3, bytes.count) {
            if let text = String(bytes: bytes.dropLast(cut), encoding: .utf8) { return text }
        }
        return ""
    }
}

/// A turn in sequence 1: where it began (before her line), where the reply began, whether a model turn was open before.
struct LastTurn {
    let start: Int32, reply: Int32, wasOpen: Bool
}
