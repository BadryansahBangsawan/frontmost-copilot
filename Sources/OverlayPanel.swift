import AppKit
import SwiftUI

final class OverlayPanelController: NSObject, NSWindowDelegate {
    static let shared = OverlayPanelController()

    private var panel: NSPanel?
    private var hosting: NSHostingView<AnyView>?

    var isVisible: Bool {
        panel?.isVisible == true
    }

    func setup() {
        guard panel == nil else { return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 384, height: 560),
            styleMask: [.titled, .closable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Frontmost Copilot"
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.delegate = self

        let root = AnyView(
            OverlayHost()
                .environmentObject(CopilotStore.shared)
        )
        let hosting = NSHostingView(rootView: root)
        hosting.frame = NSRect(x: 0, y: 0, width: 384, height: 560)
        panel.contentView = hosting
        panel.setContentSize(NSSize(width: 384, height: 560))

        self.panel = panel
        self.hosting = hosting
    }

    func toggle() {
        setup()
        guard let panel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
            CopilotStore.shared.overlayVisible = false
        } else {
            show()
        }
    }

    func show() {
        setup()
        guard let panel else { return }
        CopilotStore.shared.refreshContext()
        position(panel)
        panel.orderFrontRegardless()
        CopilotStore.shared.overlayVisible = true
    }

    func hide() {
        panel?.orderOut(nil)
        CopilotStore.shared.overlayVisible = false
    }

    func windowWillClose(_ notification: Notification) {
        CopilotStore.shared.overlayVisible = false
    }

    private func position(_ panel: NSPanel) {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let frame = screen?.visibleFrame else { return }
        let size = panel.frame.size
        let origin = NSPoint(
            x: frame.midX - size.width / 2,
            y: frame.midY - size.height / 2
        )
        panel.setFrameOrigin(origin)
    }
}

struct OverlayHost: View {
    var body: some View {
        CopilotPanel(showsOverlayToggle: false)
            .funPanel()
    }
}
