import SwiftUI

struct LaunchpadView: View {
    @ObservedObject var osManager: OSManager
    @Binding var selectedApp: OSApplication?
    @Binding var showLaunchpad: Bool
    @Binding var searchText: String
    @State private var selectedCategory: OSApplication.AppCategory? = nil
    @State private var animateIcons = false
    
    var filteredApps: [OSApplication] {
        let apps = selectedCategory == nil ? osManager.applications :
            osManager.applications.filter { $0.category == selectedCategory }
        
        if searchText.isEmpty {
            return apps
        } else {
            return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    let columns = Array(repeating: GridItem(.fixed(120), spacing: 40), count: 7)
    
    var body: some View {
        ZStack {
            // Blurred Background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(RadiateDesign.Animations.spring) {
                        showLaunchpad = false
                    }
                }
            
            VStack(spacing: RadiateDesign.Spacing.xl) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(RadiateDesign.Colors.textSecondary)
                    
                    TextField("Search Applications", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(RadiateDesign.Typography.title2)
                        .foregroundColor(RadiateDesign.Colors.text)
                }
                .padding(RadiateDesign.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.md)
                        .fill(RadiateDesign.Colors.glassDark)
                        .overlay(
                            RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.md)
                                .stroke(RadiateDesign.Colors.glassBorder, lineWidth: 1)
                        )
                )
                .frame(width: 500)
                .shadow(color: .black.opacity(0.2), radius: 10)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RadiateDesign.Spacing.md) {
                        CategoryPill(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            gradient: RadiateDesign.Colors.ultraviolet
                        ) {
                            selectedCategory = nil
                        }
                        
                        ForEach(OSApplication.AppCategory.allCases, id: \.self) { category in
                            CategoryPill(
                                title: category.rawValue,
                                isSelected: selectedCategory == category,
                                gradient: gradientForCategory(category)
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .frame(width: 900)
                
                // Application Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 40) {
                        ForEach(Array(filteredApps.enumerated()), id: \.element.id) { index, app in
                            LaunchpadAppIcon(
                                app: app,
                                delay: Double(index) * 0.02
                            ) {
                                osManager.launchApplication(app)
                                selectedApp = app
                                withAnimation(RadiateDesign.Animations.spring) {
                                    showLaunchpad = false
                                }
                            }
                            .scaleEffect(animateIcons ? 1 : 0.8)
                            .opacity(animateIcons ? 1 : 0)
                            .animation(
                                RadiateDesign.Animations.spring.delay(Double(index) * 0.02),
                                value: animateIcons
                            )
                        }
                    }
                    .padding(40)
                }
                .frame(maxHeight: 500)
                
                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { page in
                        Circle()
                            .fill(page == 0 ? RadiateDesign.Colors.text : RadiateDesign.Colors.textTertiary)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, RadiateDesign.Spacing.lg)
            }
        }
        .onAppear {
            withAnimation {
                animateIcons = true
            }
        }
        .onDisappear {
            animateIcons = false
            searchText = ""
            selectedCategory = nil
        }
    }
    
    func gradientForCategory(_ category: OSApplication.AppCategory) -> LinearGradient {
        switch category {
        case .productivity:
            return RadiateDesign.Colors.azure
        case .communication:
            return RadiateDesign.Colors.emerald
        case .media:
            return RadiateDesign.Colors.amber
        case .developer:
            return RadiateDesign.Colors.indigo
        case .utilities:
            return RadiateDesign.Colors.ultraviolet
        case .system:
            return RadiateDesign.Colors.crimson
        case .games:
            return RadiateDesign.Colors.infrared
        case .education:
            return RadiateDesign.Colors.azure
        }
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RadiateDesign.Typography.callout)
                .foregroundColor(isSelected ? .white : RadiateDesign.Colors.text)
                .padding(.horizontal, RadiateDesign.Spacing.md)
                .padding(.vertical, RadiateDesign.Spacing.sm)
                .background(
                    Group {
                        if isSelected {
                            gradient
                        } else {
                            RadiateDesign.Colors.glassDark
                        }
                    }
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : RadiateDesign.Colors.glassBorder, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Launchpad App Icon
struct LaunchpadAppIcon: View {
    let app: OSApplication
    let delay: Double
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    @State private var wiggle = false
    
    var body: some View {
        VStack(spacing: RadiateDesign.Spacing.sm) {
            ZStack {
                // Icon Background
                RoundedRectangle(cornerRadius: RadiateDesign.CornerRadius.xl)
                    .fill(app.accentColor)
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: app.accentColor.gradient.stops.first?.color.opacity(0.5) ?? .clear,
                        radius: isHovered ? 20 : 10,
                        x: 0,
                        y: isHovered ? 10 : 5
                    )
                    .scaleEffect(isPressed ? 0.9 : (isHovered ? 1.1 : 1.0))
                
                // Icon
                Image(systemName: app.icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
            .rotationEffect(.degrees(wiggle ? -2 : 2))
            .animation(
                wiggle ? Animation.easeInOut(duration: 0.15).repeatForever(autoreverses: true) : .default,
                value: wiggle
            )
            
            // App Name
            Text(app.name)
                .font(RadiateDesign.Typography.callout)
                .foregroundColor(RadiateDesign.Colors.text)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 100)
        }
        .onHover { hovering in
            withAnimation(RadiateDesign.Animations.spring) {
                isHovered = hovering
                if hovering {
                    wiggle = true
                } else {
                    wiggle = false
                }
            }
        }
        .onTapGesture {
            action()
        }
        .onLongPressGesture(minimumDuration: 0) {
        } onPressingChanged: { pressing in
            withAnimation(RadiateDesign.Animations.fast) {
                isPressed = pressing
            }
        }
    }
}