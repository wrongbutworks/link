import SwiftUI

/// LinkBar — the review gate in your menu bar.
///
/// Link's promise is that nothing becomes durable memory without your
/// approval; LinkBar makes approving ambient instead of a chore. The icon
/// is Link's memory-graph mark, the badge is everything pending your
/// judgment (memories to review + captures to accept), the popover is the
/// inbox. The `lnk` CLI's --json output is the entire backend.
@main
struct LinkBarApp: App {
    @StateObject private var store = LinkStore()

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environmentObject(store)
                .onAppear { store.start() }
        } label: {
            HStack(spacing: 3) {
                if let icon = Self.menuIcon {
                    Image(nsImage: icon)
                } else {
                    Image(systemName: "circle.hexagongrid")
                }
                if store.pendingCount > 0 {
                    Text("\(store.pendingCount)")
                        .font(.system(size: 11, weight: .semibold))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }

    /// The Link mark as a template image so it adapts to menu bar appearance.
    private static let menuIcon: NSImage? = {
        guard let url = Bundle.module.url(forResource: "MenuIcon", withExtension: "png"),
              let image = NSImage(contentsOf: url)
        else { return nil }
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }()
}
