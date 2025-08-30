//
//  TerminalView.swift
//  RadiateOS
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

public struct TerminalView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var input: String = ""
    @State private var log: [String] = ["Welcome to RadiateOS Terminal", "Type 'help' for commands"]

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(.white.opacity(0.06))
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(log.enumerated()), id: \.offset) { idx, line in
                            Text(line)
                                .font(RadiateTypography.mono(scheme))
                                .foregroundStyle(RadiateColors.textPrimary(for: scheme))
                                .id(idx)
                        }
                    }
                    .padding(12)
                }
                .background(RadiateColors.surface(for: scheme))
                .onChange(of: log.count) { _ in withAnimation { proxy.scrollTo(log.count - 1, anchor: .bottom) } }
            }
            Divider().overlay(.white.opacity(0.06))
            inputBar
        }
        .background(RadiateColors.background(for: scheme))
    }

    private var header: some View {
        HStack {
            Text("Terminal")
                .font(RadiateTypography.title(scheme))
            Spacer()
            RadiateChip("zsh")
        }
        .padding(12)
        .foregroundStyle(RadiateColors.textPrimary(for: scheme))
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Enter command", text: $input)
                .textFieldStyle(RadiateTextFieldStyle())
                .font(RadiateTypography.mono(scheme))
            Button("Run") { runCommand() }
                .buttonStyle(RadiatePrimaryButtonStyle())
        }
        .padding(12)
    }

    private func runCommand() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        log.append("$ \(trimmed)")
        if trimmed == "help" {
            log.append("Available: help, echo <text>, clear")
        } else if trimmed.hasPrefix("echo ") {
            log.append(String(trimmed.dropFirst(5)))
        } else if trimmed == "clear" {
            log.removeAll()
        } else {
            log.append("Command not found: \(trimmed)")
        }
        input = ""
    }
}

#else
public struct TerminalView {}
#endif


