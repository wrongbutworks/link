import SwiftUI

/// LinkBar — the review gate in your menu bar.
///
/// Link's promise is that nothing becomes durable memory without your
/// approval; LinkBar makes approving ambient instead of a chore. The badge
/// is your pending-review count, the popover is the inbox, and quick recall
/// answers "what do I know about X" from anywhere. The `lnk` CLI's --json
/// output is the entire backend.
@main
struct LinkBarApp: App {
    @StateObject private var store = LinkStore()

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environmentObject(store)
                .onAppear { store.start() }
        } label: {
            Label(badgeText, systemImage: "brain")
        }
        .menuBarExtraStyle(.window)
    }

    private var badgeText: String {
        let count = store.inbox?.reviewCount ?? 0
        return count > 0 ? "\(count)" : ""
    }
}
