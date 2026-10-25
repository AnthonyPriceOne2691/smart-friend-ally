import Foundation

/// The model's answer by the template: every value «N: …» with the number of her turn.
struct ModelAnswer: Decodable {
    struct She: Decodable {
        let name, age, birthday: String?, favorites, likes, can: [String]?

        enum CodingKeys: String, CodingKey {
            case name = "имя", age = "возраст", birthday = "день_рождения", favorites = "любимое", likes = "любит"
            case can = "умеет"
        }
    }

    struct Person: Decodable {
        let who, name, age: String?, details: [String]?

        enum CodingKeys: String, CodingKey { case who = "кто", name = "имя", age = "возраст", details = "подробности" }
    }

    /// A pet (вид, кличка, окрас) or a creation (что, имя): its kind, name, colour and details.
    struct Thing: Decodable {
        let kind, name, color: String?, details: [String]?

        enum CodingKeys: String, CodingKey {
            case kind = "вид", what = "что", name = "имя", nick = "кличка", color = "окрас", details = "подробности"
        }

        init(from decoder: Decoder) throws {
            let box = try decoder.container(keyedBy: CodingKeys.self)
            kind = try box.decodeIfPresent(String.self, forKey: .kind)
                ?? box.decodeIfPresent(String.self, forKey: .what)
            name = try box.decodeIfPresent(String.self, forKey: .nick)
                ?? box.decodeIfPresent(String.self, forKey: .name)
            color = try box.decodeIfPresent(String.self, forKey: .color)
            details = try box.decodeIfPresent([String].self, forKey: .details)
        }
    }

    let she: She?, people: [Person]?, pets: [Thing]?, creations: [Thing]?

    enum CodingKeys: String, CodingKey {
        case she = "она", people = "близкие", pets = "питомцы", creations = "придумала"
    }

    /// The answer in the model's text; garbage throws the reason for the retry.
    static func parse(_ text: String) throws -> ModelAnswer {
        guard let open = text.firstIndex(of: "{"), let close = text.lastIndex(of: "}"), open < close else {
            throw Garbage.noJSON
        }
        let bytes = Data(text[open...close].utf8)
        guard (try? JSONSerialization.jsonObject(with: bytes)) is [String: Any] else { throw Garbage.noJSON }
        guard let answer = try? JSONDecoder().decode(ModelAnswer.self, from: bytes),
              answer.she != nil || answer.people != nil || answer.pets != nil || answer.creations != nil else {
            throw Garbage.notTemplate
        }
        return answer
    }
}

/// Why an answer is garbage; the words go to the retry and to the parent.
enum Garbage: Error {
    case noJSON, notTemplate

    var reason: String {
        self == .noJSON ? ExtractTexts.shared.errors.noJson : ExtractTexts.shared.errors.notTemplate
    }
}
