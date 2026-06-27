import SwiftUI
import SwiftData

struct ManageEventsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Event.name) var events: [Event]
    
    @State private var showingAddEventAlert = false
    @State private var newEventName = ""
    
    var body: some View {
        List {
            ForEach(events) { event in
                Text(event.name ?? "")
                    .disabled(event.specialCase != nil)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let event = events[index]
                    if event.specialCase == nil {
                        modelContext.delete(event)
                    }
                }
            }
            
            Button("New Event", systemImage: "plus") {
                showingAddEventAlert = true
            }
        }
        .navigationTitle("Manage Events")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Done", systemImage: "xmark") { dismiss() }
            }
        }
        .alert("Create New Event", isPresented: $showingAddEventAlert) {
            TextField("Event Name", text: $newEventName)
            
            Button("Create", action: {
                let trimmedName = newEventName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty && events.allSatisfy({ $0.name != trimmedName }) else { return }
                let event = Event(name: trimmedName, date: nil, specialCase: nil)
                modelContext.insert(event)
                newEventName = ""
            })
            .keyboardShortcut(.defaultAction)
            .disabled(newEventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || events.contains(where: { $0.name == newEventName.trimmingCharacters(in: .whitespacesAndNewlines) }))
            
            Button("Cancel", role: .cancel, action: {
                newEventName = ""
            })
        }
    }
}

#Preview {
    ManageEventsView()
    #if DEBUG
        .modelContainer(previewContainer)
    #endif
}
