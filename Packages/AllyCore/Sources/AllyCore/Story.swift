import Foundation

/// One finished exchange of the session as it sounded: her words and what Elly said.
public struct Exchange: Equatable, Sendable {
    public let heard: String, said: String
}

/// What a story turn gives the model of tales: the last exchanges, her words, the bridge its reply starts with.
public struct StoryRequest: Equatable, Sendable {
    public let recent: [Exchange], utterance: String, bridge: String
}

/// The model of tales (story-mode): the reply's accumulated text after the bridge. Today E4B with the story prefix;
/// the parent's scheme — unload E4B, load the second model and back — is another implementer of this port.
public protocol StoryModel: AnyObject, Sendable {
    func tell(_ request: StoryRequest) -> AsyncThrowingStream<String, Error>
    func cancel()
}

/// A story turn as `TurnRunner` sees a model: it asks the model of tales; what sounded goes into the memory of the
/// conversation's model as a turn it did not write (D5).
final class StoryTurn: LanguageModel, @unchecked Sendable {
    private let story: StoryModel, request: StoryRequest, memory: LanguageModel

    init(_ story: StoryModel, _ request: StoryRequest, memory: LanguageModel) {
        (self.story, self.request, self.memory) = (story, request, memory)
    }

    func reply(to utterance: String) -> AsyncThrowingStream<String, Error> { story.tell(request) }

    func cancel() { story.cancel() }

    func commit(spoken: String) { memory.remember(heard: request.utterance, spoken: spoken) }

    func retract() {}

    func remember(heard: String, spoken: String) { memory.remember(heard: heard, spoken: spoken) }
}
