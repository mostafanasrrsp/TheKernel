import SwiftUI

// MARK: - Browser View
struct BrowserView: View {
    @State private var urlText = "https://radiateos.com"
    @State private var isLoading = false
    @State private var currentPage = "RadiateOS - Home"
    @State private var canGoBack = false
    @State private var canGoForward = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            HStack(spacing: 10) {
                Button(action: { /* Go back */ }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                .disabled(!canGoBack)
                
                Button(action: { /* Go forward */ }) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
                .disabled(!canGoForward)
                
                Button(action: { isLoading.toggle() }) {
                    Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                }
                .buttonStyle(.plain)
                
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    TextField("Enter URL", text: $urlText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            loadPage()
                        }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
                
                Button(action: { /* Bookmarks */ }) {
                    Image(systemName: "star")
                }
                .buttonStyle(.plain)
                
                Button(action: { /* Downloads */ }) {
                    Image(systemName: "arrow.down.circle")
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.black.opacity(0.3))
            
            // Progress bar
            if isLoading {
                ProgressView()
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 2)
            }
            
            // Web content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Welcome to RadiateOS Browser")
                        .font(.largeTitle)
                        .padding()
                    
                    Text("Experience the web with optical speed")
                        .font(.title2)
                        .foregroundColor(.cyan)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Features:")
                            .font(.headline)
                        
                        Text("• Optical rendering engine")
                        Text("• Quantum encryption")
                        Text("• AI-powered ad blocking")
                        Text("• Privacy-first design")
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                    .padding()
                    
                    Spacer(minLength: 200)
                }
            }
            .background(Color.black.opacity(0.2))
        }
    }
    
    private func loadPage() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            currentPage = "Page Loaded"
        }
    }
}

// MARK: - Notes View
struct NotesView: View {
    @State private var notes: [Note] = [
        Note(title: "Welcome to Notes", content: "Start writing your thoughts here..."),
        Note(title: "RadiateOS Features", content: "- Optical Computing\n- Advanced Memory Management\n- Multi-level Scheduler")
    ]
    @State private var selectedNote: Note?
    @State private var noteContent = ""
    @State private var searchText = ""
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.4))
                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color.white.opacity(0.05))
                
                // Notes list
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(filteredNotes) { note in
                            NoteRow(note: note, isSelected: selectedNote?.id == note.id)
                                .onTapGesture {
                                    selectedNote = note
                                    noteContent = note.content
                                }
                        }
                    }
                }
                
                // Add button
                HStack {
                    Button(action: addNewNote) {
                        Label("New Note", systemImage: "plus")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(10)
                .background(Color.white.opacity(0.05))
            }
            .frame(width: 250)
            .background(Color.white.opacity(0.02))
            
            Divider()
            
            // Editor
            if let note = selectedNote {
                VStack(alignment: .leading, spacing: 0) {
                    // Title
                    TextField("Title", text: .constant(note.title))
                        .font(.title2)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white.opacity(0.05))
                    
                    // Content
                    TextEditor(text: $noteContent)
                        .font(.body)
                        .padding()
                        .onChange(of: noteContent) { newValue in
                            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                                notes[index].content = newValue
                            }
                        }
                }
            } else {
                VStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("Select a note or create a new one")
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.black.opacity(0.2))
    }
    
    private var filteredNotes: [Note] {
        if searchText.isEmpty {
            return notes
        } else {
            return notes.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func addNewNote() {
        let newNote = Note(title: "New Note", content: "")
        notes.insert(newNote, at: 0)
        selectedNote = newNote
        noteContent = ""
    }
}

struct NoteRow: View {
    let note: Note
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
            
            Text(note.content)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(2)
            
            Text(note.modifiedDate, style: .date)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
        .contentShape(Rectangle())
    }
}

struct Note: Identifiable {
    let id = UUID()
    var title: String
    var content: String
    var modifiedDate = Date()
}

// MARK: - Calculator View
struct CalculatorView: View {
    @State private var display = "0"
    @State private var previousValue: Double = 0
    @State private var currentOperation: Operation?
    @State private var shouldResetDisplay = false
    
    enum Operation {
        case add, subtract, multiply, divide
    }
    
    let buttons: [[CalcButton]] = [
        [.clear, .negate, .percent, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .subtract],
        [.one, .two, .three, .add],
        [.zero, .decimal, .equals]
    ]
    
    var body: some View {
        VStack(spacing: 10) {
            // Display
            Text(display)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(10)
            
            // Buttons
            VStack(spacing: 10) {
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { button in
                            CalculatorButtonView(button: button) {
                                handleButtonTap(button)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(width: 350)
        .background(Color.black.opacity(0.2))
    }
    
    private func handleButtonTap(_ button: CalcButton) {
        switch button {
        case .clear:
            display = "0"
            previousValue = 0
            currentOperation = nil
            
        case .negate:
            if let value = Double(display) {
                display = String(-value)
            }
            
        case .percent:
            if let value = Double(display) {
                display = String(value / 100)
            }
            
        case .decimal:
            if !display.contains(".") {
                display += "."
            }
            
        case .equals:
            calculate()
            
        case .add:
            setOperation(.add)
            
        case .subtract:
            setOperation(.subtract)
            
        case .multiply:
            setOperation(.multiply)
            
        case .divide:
            setOperation(.divide)
            
        default:
            // Number buttons
            if shouldResetDisplay {
                display = ""
                shouldResetDisplay = false
            }
            
            if display == "0" {
                display = button.rawValue
            } else {
                display += button.rawValue
            }
        }
    }
    
    private func setOperation(_ operation: Operation) {
        if let value = Double(display) {
            if currentOperation != nil {
                calculate()
            }
            previousValue = value
            currentOperation = operation
            shouldResetDisplay = true
        }
    }
    
    private func calculate() {
        guard let operation = currentOperation,
              let currentValue = Double(display) else { return }
        
        var result: Double = 0
        
        switch operation {
        case .add:
            result = previousValue + currentValue
        case .subtract:
            result = previousValue - currentValue
        case .multiply:
            result = previousValue * currentValue
        case .divide:
            result = currentValue != 0 ? previousValue / currentValue : 0
        }
        
        display = String(format: "%g", result)
        currentOperation = nil
        shouldResetDisplay = true
    }
}

enum CalcButton: String {
    case zero = "0", one = "1", two = "2", three = "3", four = "4"
    case five = "5", six = "6", seven = "7", eight = "8", nine = "9"
    case add = "+", subtract = "-", multiply = "×", divide = "÷"
    case equals = "=", decimal = ".", clear = "C", negate = "±", percent = "%"
    
    var backgroundColor: Color {
        switch self {
        case .clear, .negate, .percent:
            return Color.white.opacity(0.2)
        case .add, .subtract, .multiply, .divide, .equals:
            return Color.cyan.opacity(0.3)
        default:
            return Color.white.opacity(0.1)
        }
    }
}

struct CalculatorButtonView: View {
    let button: CalcButton
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(button.rawValue)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: button == .zero ? 160 : 75, height: 75)
                .background(button.backgroundColor)
                .cornerRadius(37.5)
        }
        .buttonStyle(.plain)
    }
}