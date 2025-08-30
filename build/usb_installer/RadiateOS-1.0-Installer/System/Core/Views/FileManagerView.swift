//
//  FileManagerView.swift
//  RadiateOS
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

public struct FileManagerView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var path: [String] = ["Home"]
    @State private var items: [String] = ["Documents", "Downloads", "Pictures", "Music", "Videos", "Notes.txt"]

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(.white.opacity(0.06))
            content
        }
        .background(RadiateColors.background(for: scheme))
    }

    private var header: some View {
        HStack(spacing: 8) {
            RadiateIconButton(systemName: "chevron.left") {}
            RadiateIconButton(systemName: "chevron.right") {}
            RadiateIconButton(systemName: "arrow.clockwise") {}
            Text(path.joined(separator: "/"))
                .font(RadiateTypography.title(scheme))
            Spacer()
            TextField("Search", text: .constant(""))
                .textFieldStyle(RadiateTextFieldStyle())
                .frame(maxWidth: 320)
        }
        .padding(12)
        .foregroundStyle(RadiateColors.textPrimary(for: scheme))
    }

    private var content: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: RadiateSpacing.md), count: 4), spacing: RadiateSpacing.md) {
                ForEach(items, id: \.self) { item in
                    RadiateCard {
                        HStack(spacing: RadiateSpacing.md) {
                            Image(systemName: icon(for: item))
                                .font(.system(size: 28))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item).radiateBody()
                                Text("Modified · Today").radiateCaption().foregroundStyle(RadiateColors.textSecondary(for: scheme))
                            }
                            Spacer()
                        }
                    }
                    .contextMenu {
                        Button("Open") {}
                        Button("Rename") {}
                        Button(role: .destructive) { } label: { Text("Delete") }
                    }
                }
            }
            .padding(12)
        }
        .background(RadiateColors.surface(for: scheme))
    }

    private func icon(for item: String) -> String {
        item.contains(".") ? "doc.text" : "folder.fill"
    }
}

#else
public struct FileManagerView {}
#endif


