import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var store: LinkStore
    @State private var query = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            recallField
            if !store.recallResults.isEmpty || store.abstention?.recommended == true {
                recallSection
                Divider()
            }
            inboxSection
            footer
        }
        .padding(12)
        .frame(width: 360)
    }

    private var header: some View {
        HStack {
            Image(systemName: "brain")
            Text("Link").font(.headline)
            Spacer()
            if store.busy { ProgressView().controlSize(.small) }
            Button {
                store.refresh()
            } label: { Image(systemName: "arrow.clockwise") }
                .buttonStyle(.borderless)
                .help("Refresh")
        }
    }

    private var recallField: some View {
        TextField("What do I know about…", text: $query)
            .textFieldStyle(.roundedBorder)
            .onSubmit { store.recall(query) }
    }

    private var recallSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let abstention = store.abstention, abstention.recommended {
                Label(
                    "Nothing reliable on this — the honest answer is \"don't know\".",
                    systemImage: "questionmark.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            ForEach(store.recallResults.prefix(4)) { memory in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(memory.title).font(.callout).lineLimit(1)
                        Spacer()
                        if let confidence = memory.confidence {
                            Text(confidence)
                                .font(.caption2)
                                .padding(.horizontal, 5)
                                .background(confidenceColor(confidence).opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    if let tldr = memory.tldr {
                        Text(tldr).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                }
            }
        }
    }

    private var inboxSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            let items = store.inbox?.items ?? []
            HStack {
                Text("Review inbox").font(.subheadline).bold()
                Spacer()
                Text("\(store.inbox?.reviewCount ?? 0)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if items.isEmpty {
                Text("Nothing waiting — your memory is fully reviewed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(items.prefix(5)) { item in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title).font(.callout).lineLimit(1)
                        HStack(spacing: 6) {
                            Text(item.memoryType).font(.caption2).foregroundStyle(.secondary)
                            if let tldr = item.tldr {
                                Text(tldr).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                            }
                        }
                    }
                    Spacer()
                    Button("✓") { store.markReviewed(item) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .help("Mark reviewed — confirm this memory is accurate")
                    Button {
                        store.archive(item)
                    } label: { Image(systemName: "archivebox") }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Archive — keep it out of recall, never deleted")
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let error = store.lastError {
                Text(error).font(.caption2).foregroundStyle(.red).lineLimit(2)
            }
            Divider()
            HStack {
                Text(LinkCLI.workspace)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.head)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.borderless)
                    .font(.caption)
            }
        }
    }

    private func confidenceColor(_ value: String) -> Color {
        switch value {
        case "strong": return .green
        case "moderate": return .orange
        default: return .gray
        }
    }
}
