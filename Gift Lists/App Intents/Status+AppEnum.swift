import AppIntents

/// Exposes the gift lifecycle to Siri and Shortcuts so it can be spoken,
/// picked, and matched as an intent parameter.
extension Status: AppEnum {

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Gift Status"
    }

    static var caseDisplayRepresentations: [Status: DisplayRepresentation] {
        [
            .idea: DisplayRepresentation(title: "Idea", image: .init(systemName: "lightbulb")),
            .inTransit: DisplayRepresentation(title: "In Transit", image: .init(systemName: "truck.box")),
            .acquired: DisplayRepresentation(title: "Acquired", image: .init(systemName: "house")),
            .wrapped: DisplayRepresentation(title: "Wrapped", image: .init(systemName: "gift")),
            .given: DisplayRepresentation(title: "Given", image: .init(systemName: "face.smiling"))
        ]
    }
}
