//
//  ContentView.swift
//  RadiateOS
//
//  Created by Mostafa Nasr on 27/08/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        DesktopEnvironment()
            .environment(\.managedObjectContext, viewContext)
    }
}

// MARK: - Legacy Data Management (for CoreData compatibility)
struct LegacyDataView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var kernel = Kernel.shared
    @State private var executionResult: ExecutionResult?
    @State private var isExecuting = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // RadiateOS Kernel Status
                GroupBox("RadiateOS Kernel Status") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "cpu")
                                .foregroundColor(.blue)
                            Text("Optical CPU: Active")
                                .font(.headline)
                        }
                        
                        HStack {
                            Image(systemName: "memorychip")
                                .foregroundColor(.green)
                            Text("Memory Manager: Initialized")
                        }
                        
                        HStack {
                            Image(systemName: "opticaldiscdrive")
                                .foregroundColor(.orange)
                            Text("ROM Modules: Mounted")
                        }
                        
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.purple)
                            Text("x86/x64 Translation: Ready")
                        }
                    }
                    .padding()
                }
                
                // Kernel Execution
                GroupBox("Kernel Execution") {
                    VStack(spacing: 16) {
                        Button(action: executeKernel) {
                            HStack {
                                if isExecuting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "play.fill")
                                }
                                Text(isExecuting ? "Executing..." : "Execute Sample Binary")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isExecuting)
                        
                        if let result = executionResult {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Execution Result:")
                                    .font(.headline)
                                
                                Text("Exit Code: \(result.exitCode)")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(result.exitCode == 0 ? .green : .red)
                                
                                Text("Output: \(result.output)")
                                    .font(.system(.body, design: .monospaced))
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                                
                                Text("Execution Time: \(result.executionTime, specifier: "%.3f")s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }
                
                // Data Storage
                GroupBox("Data Storage") {
                    VStack {
                        List {
                            ForEach(items) { item in
                                NavigationLink(destination: ItemDetailView(item: item)) {
                                    VStack(alignment: .leading) {
                                        Text(item.timestamp!, formatter: itemFormatter)
                                            .font(.headline)
                                        Text("RadiateOS Data Entry")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .onDelete(perform: deleteItems)
                        }
                        .frame(height: 200)
                        
                        Button(action: addItem) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Data Entry")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: addItem) {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .navigationTitle("RadiateOS")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func executeKernel() {
        isExecuting = true
        
        Task {
            let startTime = Date()
            
            do {
                // Simulate kernel execution
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                let result = ExecutionResult(
                    exitCode: 0,
                    output: "Optical kernel executed successfully!\nProcessed 1,048,576 photonic operations\nMemory bandwidth: 1TB/s\nCPU frequency: 2.5THz",
                    executionTime: Date().timeIntervalSince(startTime)
                )
                
                await MainActor.run {
                    executionResult = result
                    isExecuting = false
                }
            } catch {
                let result = ExecutionResult(
                    exitCode: 1,
                    output: "Execution failed: \(error.localizedDescription)",
                    executionTime: Date().timeIntervalSince(startTime)
                )
                
                await MainActor.run {
                    executionResult = result
                    isExecuting = false
                }
            }
        }
    }
}

// ExecutionResult moved to Kernel.swift to avoid naming conflict

struct ItemDetailView: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Item Details")
                .font(.largeTitle)
                .bold()
            
            GroupBox("Timestamp") {
                Text(item.timestamp!, formatter: itemFormatter)
                    .font(.title2)
                    .padding()
            }
            
            GroupBox("System Information") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Created by RadiateOS Kernel")
                    }
                    HStack {
                        Image(systemName: "lightbulb")
                        Text("Optical Processing Compatible")
                    }
                    HStack {
                        Image(systemName: "gear")
                        Text("x86/x64 Translation Layer")
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Item Detail")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}