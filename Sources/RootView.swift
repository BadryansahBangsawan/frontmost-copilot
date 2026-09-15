import SwiftUI

struct RootView: View {
    var body: some View {
        CopilotPanel(showsOverlayToggle: true)
            .background(.regularMaterial)
            .funPanel()
    }
}

struct CopilotPanel: View {
    var showsOverlayToggle: Bool

    @EnvironmentObject private var store: CopilotStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            banners
            if !store.accessibilityTrusted {
                accessibilityCTA
            }
            contextSection
            promptSection
            actions
            responseSection
            historySection
        }
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.isSending)
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.response)
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.actionError)
        .onAppear {
            store.start()
            store.refreshContext()
            store.refreshKeyStatus()
        }
    }

    private var header: some View {
        HStack {
            Text("Frontmost Copilot")
                .font(.headline)
            Spacer()
            if showsOverlayToggle {
                Button(store.overlayVisible ? "Hide overlay" : "Show overlay") {
                    store.toggleOverlay()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    private var banners: some View {
        if let actionError = store.actionError, !actionError.isEmpty {
            Label(actionError, systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
        if let contextError = store.contextError, !contextError.isEmpty {
            Label(contextError, systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
        if let historyError = store.historyError, !historyError.isEmpty {
            Label(historyError, systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
        if let status = store.statusMessage, !status.isEmpty {
            Text(status)
                .foregroundStyle(.secondary)
        }
        if !store.hasAPIKey {
            Text("Add an API key in Settings")
                .foregroundStyle(.secondary)
        }
    }

    private var accessibilityCTA: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Accessibility is required to read the frontmost selection.")
            Button("Open Accessibility Settings") {
                store.requestAccessibility()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(store.appName.isEmpty ? "No frontmost app" : store.appName)
                .font(.subheadline.weight(.semibold))
            if !store.documentPath.isEmpty {
                Text(store.documentPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if store.selection.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Select text in another app, then send.")
                    Button("Refresh context") {
                        store.refreshContext()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text(store.selection)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    private var promptSection: some View {
        Picker("Prompt", selection: $store.prompt) {
            ForEach(CopilotPrompt.allCases) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var actions: some View {
        HStack {
            Button("Send") {
                store.send()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!store.hasAPIKey || store.isSending)

            Button("Copy context") {
                store.copyContext()
            }
            .buttonStyle(.bordered)
            .disabled(store.selection.isEmpty)

            Button("Refresh") {
                store.refreshContext()
            }
            .buttonStyle(.bordered)

            if store.isSending {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private var responseSection: some View {
        if !store.response.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Response")
                    .font(.subheadline.weight(.semibold))
                ScrollView {
                    Text(store.response)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 160)
                HStack {
                    Button("Copy response") {
                        store.copyResponse()
                    }
                    .buttonStyle(.bordered)
                    Button("Insert") {
                        store.insertResponse()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    @ViewBuilder
    private var historySection: some View {
        if !store.history.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("History")
                    .font(.subheadline.weight(.semibold))
                ForEach(Array(store.history.prefix(5).enumerated()), id: \.offset) { _, entry in
                    Button {
                        store.response = entry.response
                        store.statusMessage = nil
                    } label: {
                        HStack {
                            Text(entry.prompt)
                            Spacer()
                            Text(entry.time, style: .time)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
