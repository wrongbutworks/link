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
            if let captures = store.captures, !captures.captures.isEmpty {
                Divider()
                capturesSection(captures)
            }
            if !store.activity.isEmpty {
                Divider()
                activitySection
            }
            footer
        }
        .padding(12)
        .frame(width: 380)
    }

    private var header: some View {
        HStack {
            Text("Link").font(.headline)
            Spacer()
            if store.busy { ProgressView().controlSize(.small) }
            Button {
                store.rememberClipboard()
            } label: { Image(systemName: "doc.on.clipboard") }
                .buttonStyle(.borderless)
                .help("Remember clipboard — saved as pending review")
            Button {
                store.openWorkspace()
            } label: { Image(systemName: "folder") }
                .buttonStyle(.borderless)
                .help("Open the workspace in Finder")
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

    private func capturesSection(_ captures: CaptureInbox) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Session captures").font(.subheadline).bold()
                Spacer()
                Text("\(captures.count)").font(.caption).foregroundStyle(.secondary)
            }
            ForEach(captures.captures.prefix(3)) { capture in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(capture.displayTitle).font(.callout).lineLimit(1)
                        if let project = capture.project, !project.isEmpty {
                            Text(project).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button("Accept") { store.acceptCapture(capture) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .help("Accept the first proposal into reviewed memory")
                    Button {
                        store.deleteCapture(capture)
                    } label: { Image(systemName: "trash") }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Discard this capture")
                }
            }
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent activity").font(.subheadline).bold()
            ForEach(store.activity.prefix(3)) { entry in
                HStack(spacing: 6) {
                    Text(entry.operation)
                        .font(.caption2)
                        .padding(.horizontal, 5)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                    Text(entry.description ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let flash = store.flash {
                Text(flash).font(.caption2).foregroundStyle(.green).lineLimit(1)
            }
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
