import AppKit
import Foundation
import SwiftUI

/// App state: review inbox, capture inbox, recent activity, quick recall —
/// all refreshed from the CLI's --json output.
@MainActor
final class LinkStore: ObservableObject {
    @Published var inbox: MemoryInbox?
    @Published var captures: CaptureInbox?
    @Published var activity: [LogEntry] = []
    @Published var recallResults: [RecalledMemory] = []
    @Published var abstention: Abstention?
    @Published var lastError: String?
    @Published var flash: String?
    @Published var busy = false

    var pendingCount: Int {
        (inbox?.reviewCount ?? 0) + (captures?.count ?? 0)
    }

    private var timer: Timer?

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        busy = true
        Task.detached(priority: .userInitiated) {
            let workspace = LinkCLI.workspace
            let inbox = try? LinkCLI.runJSON(MemoryInbox.self, ["memory-inbox", workspace, "--json"])
            let captures = try? LinkCLI.runJSON(CaptureInbox.self, ["capture-inbox", workspace, "--json"])
            let log = try? LinkCLI.runJSON(MemoryLog.self, ["memory-log", workspace, "--json", "--limit", "4"])
            await MainActor.run {
                if inbox == nil && captures == nil {
                    self.lastError = "Could not reach lnk — is Link installed? (brew install gowtham0992/link/link)"
                } else {
                    self.lastError = nil
                }
                self.inbox = inbox ?? self.inbox
                self.captures = captures ?? self.captures
                self.activity = log?.entries ?? self.activity
                self.busy = false
            }
        }
    }

    func recall(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        busy = true
        Task.detached(priority: .userInitiated) {
            do {
                let payload = try LinkCLI.runJSON(
                    RecallPayload.self,
                    ["recall", query, LinkCLI.workspace, "--json"]
                )
                await MainActor.run {
                    self.recallResults = payload.memories
                    self.abstention = payload.abstention
                    self.busy = false
                }
            } catch {
                await MainActor.run {
                    self.lastError = String(describing: error)
                    self.busy = false
                }
            }
        }
    }

    /// Approve: mark the memory reviewed. The gate, one click.
    func markReviewed(_ item: InboxItem) {
        act(["review-memory", item.name, LinkCLI.workspace])
    }

    /// Reject: archive the memory (never silent deletion).
    func archive(_ item: InboxItem) {
        act(["archive-memory", item.name, LinkCLI.workspace])
    }

    /// Accept a session capture's first proposal into reviewed memory flow.
    func acceptCapture(_ capture: CaptureItem) {
        act(["accept-capture", capture.path, LinkCLI.workspace, "--index", "1"])
    }

    func deleteCapture(_ capture: CaptureItem) {
        act(["delete-capture", capture.path, LinkCLI.workspace, "--confirm"])
    }

    /// Save the clipboard as a memory — review-gated like every other write:
    /// it lands as pending review, never silently trusted.
    func rememberClipboard() {
        guard let text = NSPasteboard.general.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty
        else {
            flash = "Clipboard has no text."
            return
        }
        let bounded = String(text.prefix(2000))
        busy = true
        Task.detached(priority: .userInitiated) {
            do {
                _ = try LinkCLI.run(["remember", bounded, LinkCLI.workspace])
                await MainActor.run {
                    self.flash = "Saved from clipboard — pending your review."
                    self.refresh()
                }
            } catch {
                await MainActor.run {
                    self.lastError = String(describing: error)
                    self.busy = false
                }
            }
        }
    }

    func openWorkspace() {
        NSWorkspace.shared.open(URL(fileURLWithPath: LinkCLI.workspace))
    }

    private func act(_ args: [String]) {
        busy = true
        Task.detached(priority: .userInitiated) {
            do {
                _ = try LinkCLI.run(args)
                await MainActor.run { self.refresh() }
            } catch {
                await MainActor.run {
                    self.lastError = String(describing: error)
                    self.busy = false
                }
            }
        }
    }
}
