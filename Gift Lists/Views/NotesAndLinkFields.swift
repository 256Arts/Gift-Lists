import SwiftUI

/// A gift's notes and product link, laid out the way Reminders does it: the link field stays out of
/// the way until either field has something in it or the notes are being edited.
///
/// Setting a link fetches its preview, which supplies the thumbnail and — for a gift that hasn't
/// been named yet — the title.
struct NotesAndLinkFields: View {

    @Binding var notes: String
    @Binding var url: URL?
    @Binding var imageData: Data?
    /// Filled from the link's preview, but only while it's empty.
    @Binding var title: String

    @State private var linkText: String
    @State private var previewTask: Task<Void, Never>?
    @FocusState private var focus: Field?

    private enum Field { case notes, link }

    init(notes: Binding<String>, url: Binding<URL?>, imageData: Binding<Data?>, title: Binding<String>) {
        _notes = notes
        _url = url
        _imageData = imageData
        _title = title
        _linkText = State(initialValue: url.wrappedValue?.absoluteString ?? "")
    }

    private var showsLink: Bool {
        !notes.isEmpty || !linkText.isEmpty || focus != nil
    }

    var body: some View {
        Group {
            TextEditor(text: $notes)
                .focused($focus, equals: .notes)
                .overlay(alignment: .leading) {
                    if notes.isEmpty {
                        Text("Notes")
                            .foregroundStyle(.secondary)
                            .allowsHitTesting(false)
                    }
                }
                .privacySensitive()

            if showsLink {
                HStack {
                    TextField("URL", text: $linkText)
                        .focused($focus, equals: .link)
                        .textContentType(.URL)
                        #if os(iOS) || os(visionOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled()
                        .onSubmit(commitLink)
                        .privacySensitive()

                    accessory
                }
            }
        }
        .animation(.default, value: showsLink)
        .onChange(of: focus) { oldValue, newValue in
            if oldValue == .link, newValue != .link {
                commitLink()
            }
        }
    }

    @ViewBuilder
    private var accessory: some View {
        if linkText.isEmpty {
            PasteButton(payloadType: URL.self) { urls in
                guard let pasted = urls.first else { return }
                Task { @MainActor in
                    linkText = pasted.absoluteString
                    commitLink()
                }
            }
            .labelStyle(.iconOnly)
            .buttonBorderShape(.capsule)
        } else if let imageData {
            GiftThumbnail(data: imageData)
        } else if previewTask != nil {
            ProgressView()
                .controlSize(.small)
        }
    }

    /// Saves the typed link once editing ends, and fetches its preview if it changed. Text that
    /// isn't a web address reverts to the saved link.
    private func commitLink() {
        let newURL: URL?
        if linkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            newURL = nil
        } else if let parsed = Gift.url(fromUserInput: linkText) {
            newURL = parsed
        } else {
            linkText = url?.absoluteString ?? ""
            return
        }
        linkText = newURL?.absoluteString ?? ""
        guard newURL != url else { return }

        url = newURL
        imageData = nil
        previewTask?.cancel()
        previewTask = nil
        guard let newURL else { return }

        previewTask = Task {
            let preview = try? await LinkPreview.fetch(for: newURL)
            guard !Task.isCancelled else { return }
            previewTask = nil
            guard let preview else { return }
            if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let previewTitle = preview.title {
                title = previewTitle
            }
            imageData = preview.imageData
        }
    }
}
