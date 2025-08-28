import SwiftUI

struct NotificationCenterView: View {
    @ObservedObject var osManager: OSManager
    @Binding var isShowing: Bool
    @State private var selectedTab = "Notifications"
    @State private var showDoNotDisturb = false
    @State private var doNotDisturbDuration = "1 hour"
    
    let tabs = ["Notifications", "Widgets"]
    
    var body: some View {
        HStack(spacing: 0) {
            // Invisible tap area to dismiss
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(RadiateDesign.Animations.spring) {
                        isShowing = false
                    }
                }
            
            // Notification Center Panel
            VStack(spacing: 0) {
                // Header
                VStack(spacing: RadiateDesign.Spacing.md) {
                    // Date and Time
                    VStack(spacing: 4) {
                        Text(Date(), style: .date)
                            .font(RadiateDesign.Typography.title2)
                            .foregroundColor(RadiateDesign.Colors.text)
                        
                        Text(Date(), style: .time)
                            .font(RadiateDesign.Typography.largeTitle)
                            .foregroundColor(RadiateDesign.Colors.text)
                    }
                    .padding(.top, RadiateDesign.Spacing.lg)
                    
                    // Tab Selector
                    HStack(spacing: 0) {
                        ForEach(tabs, id: \.self) { tab in
                            Button(action: { selectedTab = tab }) {
                                Text(tab)
                                    .font(RadiateDesign.Typography.headline)
                                    .foregroundColor(selectedTab == tab ? RadiateDesign.Colors.text : RadiateDesign.Colors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, RadiateDesign.Spacing.sm)
                                    .background(
                                        selectedTab == tab ? RadiateDesign.Colors.glassDark : Color.clear
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .background(RadiateDesign.Colors.surfaceLight)
                    .cornerRadius(RadiateDesign.CornerRadius.sm)
                    .padding(.horizontal, RadiateDesign.Spacing.md)
                    
                    // Do Not Disturb
                    DoNotDisturbToggle(
                        isEnabled: $showDoNotDisturb,
                        duration: $doNotDisturbDuration
                    )
                    .padding(.horizontal, RadiateDesign.Spacing.md)
                }
                
                Divider()
                    .background(RadiateDesign.Colors.glassBorder)
                
                // Content
                ScrollView {
                    if selectedTab == "Notifications" {
                        NotificationsContent(osManager: osManager)
                    } else {
                        WidgetsContent()
                    }
                }
                
                // Clear All Button
                if selectedTab == "Notifications" && !osManager.notifications.isEmpty {
                    Button(action: {
                        withAnimation(RadiateDesign.Animations.spring) {
                            osManager.notifications.removeAll()
                            osManager.markNotificationsAsRead()
                        }
                    }) {
                        Text("Clear All")
                            .font(RadiateDesign.Typography.callout)
                            .foregroundColor(RadiateDesign.Colors.error)
                            .frame(maxWidth: .infinity)
                            .padding(RadiateDesign.Spacing.sm)
                            .background(RadiateDesign.Colors.glassDark)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(RadiateDesign.Spacing.md)
                }
            }
            .frame(width: 380)
            .frame(maxHeight: .infinity)
            .background(
                RadiateDesign.Colors.surface
                    .glassMorphism(cornerRadius: 0)
            )
        }
        .onAppear {
            osManager.markNotificationsAsRead()
        }
    }
}

// MARK: - Do Not Disturb Toggle
struct DoNotDisturbToggle: View {
    @Binding var isEnabled: Bool
    @Binding var duration: String
    
    let durations = ["1 hour", "Until tomorrow", "Until I turn it off"]
    
    var body: some View {
        VStack(spacing: RadiateDesign.Spacing.sm) {
            HStack {
                Image(systemName: isEnabled ? "moon.fill" : "moon")
                    .font(.system(size: 20))
                    .foregroundColor(isEnabled ? RadiateDesign.Colors.accentPrimary : RadiateDesign.Colors.textSecondary)
                
                Text("Do Not Disturb")
                    .font(RadiateDesign.Typography.headline)
                    .foregroundColor(RadiateDesign.Colors.text)
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .toggleStyle(SwitchToggleStyle())
                    .labelsHidden()
            }
            .padding(RadiateDesign.Spacing.sm)
            .background(RadiateDesign.Colors.glassDark)
            .cornerRadius(RadiateDesign.CornerRadius.sm)
            
            if isEnabled {
                Picker("Duration", selection: $duration) {
                    ForEach(durations, id: \.self) { dur in
                        Text(dur).tag(dur)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
            }
        }
    }
}

// MARK: - Notifications Content
struct NotificationsContent: View {
    @ObservedObject var osManager: OSManager
    
    var groupedNotifications: [(String, [SystemNotification])] {
        let grouped = Dictionary(grouping: osManager.notifications) { $0.app.name }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        VStack(spacing: RadiateDesign.Spacing.md) {
            if osManager.notifications.isEmpty {
                EmptyNotificationsView()
                    .padding(.top, 100)
            } else {
                ForEach(groupedNotifications, id: \.0) { appName, notifications in
                    NotificationGroup(
                        appName: appName,
                        notifications: notifications,
                        icon: notifications.first?.app.icon ?? "app",
                        accentColor: notifications.first?.app.accentColor ?? RadiateDesign.Colors.azure
                    )
                }
            }
        }
        .padding(RadiateDesign.Spacing.md)
    }
}

// MARK: - Empty Notifications View
struct EmptyNotificationsView: View {
    var body: some View {
        VStack(spacing: RadiateDesign.Spacing.md) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(RadiateDesign.Colors.textTertiary)
            
            Text("No Notifications")
                .font(RadiateDesign.Typography.title2)
                .foregroundColor(RadiateDesign.Colors.textSecondary)
            
            Text("You're all caught up!")
                .font(RadiateDesign.Typography.caption1)
                .foregroundColor(RadiateDesign.Colors.textTertiary)
        }
    }
}

// MARK: - Notification Group
struct NotificationGroup: View {
    let appName: String
    let notifications: [SystemNotification]
    let icon: String
    let accentColor: LinearGradient
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Group Header
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(accentColor)
                    
                    Text(appName)
                        .font(RadiateDesign.Typography.headline)
                        .foregroundColor(RadiateDesign.Colors.text)
                    
                    Spacer()
                    
                    if notifications.count > 1 {
                        Text("\(notifications.count)")
                            .font(RadiateDesign.Typography.caption1)
                            .foregroundColor(RadiateDesign.Colors.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RadiateDesign.Colors.glassDark)
                            .clipShape(Capsule())
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(RadiateDesign.Colors.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(RadiateDesign.Spacing.sm)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 1) {
                    ForEach(notifications) { notification in
                        NotificationCard(notification: notification)
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
        .background(RadiateDesign.Colors.surfaceLight)
        .cornerRadius(RadiateDesign.CornerRadius.md)
    }
}

// MARK: - Notification Card
struct NotificationCard: View {
    let notification: SystemNotification
    @State private var isHovered = false
    @State private var showActions = false
    
    var body: some View {
        HStack(alignment: .top, spacing: RadiateDesign.Spacing.sm) {
            // Notification Icon
            notificationIcon
                .font(.system(size: 12))
                .foregroundColor(iconColor)
                .frame(width: 20, height: 20)
                .background(iconColor.opacity(0.2))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(RadiateDesign.Typography.callout)
                    .foregroundColor(RadiateDesign.Colors.text)
                    .lineLimit(1)
                
                Text(notification.message)
                    .font(RadiateDesign.Typography.caption1)
                    .foregroundColor(RadiateDesign.Colors.textSecondary)
                    .lineLimit(2)
                
                Text(timeAgo(from: notification.timestamp))
                    .font(RadiateDesign.Typography.caption2)
                    .foregroundColor(RadiateDesign.Colors.textTertiary)
            }
            
            Spacer()
            
            // Actions
            if isHovered {
                HStack(spacing: 4) {
                    Button(action: {}) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundColor(RadiateDesign.Colors.textTertiary)
                            .frame(width: 20, height: 20)
                            .background(RadiateDesign.Colors.glassDark)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(RadiateDesign.Spacing.sm)
        .background(isHovered ? RadiateDesign.Colors.glassDark : Color.clear)
        .onHover { hovering in
            withAnimation(RadiateDesign.Animations.fast) {
                isHovered = hovering
            }
        }
    }
    
    var notificationIcon: Image {
        switch notification.type {
        case .info:
            return Image(systemName: "info.circle.fill")
        case .warning:
            return Image(systemName: "exclamationmark.triangle.fill")
        case .error:
            return Image(systemName: "xmark.circle.fill")
        case .success:
            return Image(systemName: "checkmark.circle.fill")
        }
    }
    
    var iconColor: Color {
        switch notification.type {
        case .info:
            return RadiateDesign.Colors.info
        case .warning:
            return RadiateDesign.Colors.warning
        case .error:
            return RadiateDesign.Colors.error
        case .success:
            return RadiateDesign.Colors.success
        }
    }
    
    func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}

// MARK: - Widgets Content
struct WidgetsContent: View {
    var body: some View {
        VStack(spacing: RadiateDesign.Spacing.md) {
            // Weather Widget
            WeatherWidget()
            
            // Calendar Widget
            CalendarWidget()
            
            // System Stats Widget
            SystemStatsWidget()
            
            // Stock Market Widget
            StockMarketWidget()
        }
        .padding(RadiateDesign.Spacing.md)
    }
}

// MARK: - Weather Widget
struct WeatherWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: RadiateDesign.Spacing.sm) {
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 20))
                    .foregroundColor(RadiateDesign.Colors.amber.gradient.stops.first?.color)
                
                Text("Weather")
                    .font(RadiateDesign.Typography.headline)
                    .foregroundColor(RadiateDesign.Colors.text)
                
                Spacer()
                
                Text("San Francisco")
                    .font(RadiateDesign.Typography.caption1)
                    .foregroundColor(RadiateDesign.Colors.textSecondary)
            }
            
            HStack(alignment: .top) {
                Text("72°")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(RadiateDesign.Colors.text)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Partly Cloudy")
                        .font(RadiateDesign.Typography.callout)
                        .foregroundColor(RadiateDesign.Colors.text)
                    
                    Text("H: 78° L: 62°")
                        .font(RadiateDesign.Typography.caption1)
                        .foregroundColor(RadiateDesign.Colors.textSecondary)
                }
            }
            
            // Forecast
            HStack(spacing: RadiateDesign.Spacing.md) {
                ForEach(["Mon", "Tue", "Wed", "Thu", "Fri"], id: \.self) { day in
                    VStack(spacing: 4) {
                        Text(day)
                            .font(RadiateDesign.Typography.caption2)
                            .foregroundColor(RadiateDesign.Colors.textTertiary)
                        
                        Image(systemName: ["sun.max.fill", "cloud.fill", "cloud.sun.fill"].randomElement()!)
                            .font(.system(size: 16))
                            .foregroundColor(RadiateDesign.Colors.amber.gradient.stops.first?.color)
                        
                        Text("\(Int.random(in: 65...80))°")
                            .font(RadiateDesign.Typography.caption1)
                            .foregroundColor(RadiateDesign.Colors.text)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(RadiateDesign.Spacing.md)
        .background(RadiateDesign.Colors.glassDark)
        .cornerRadius(RadiateDesign.CornerRadius.md)
    }
}

// MARK: - Calendar Widget
struct CalendarWidget: View {
    let today = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: RadiateDesign.Spacing.sm) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundColor(RadiateDesign.Colors.crimson.gradient.stops.first?.color)
                
                Text("Calendar")
                    .font(RadiateDesign.Typography.headline)
                    .foregroundColor(RadiateDesign.Colors.text)
                
                Spacer()
                
                Text(today, format: .dateTime.month(.wide).year())
                    .font(RadiateDesign.Typography.caption1)
                    .foregroundColor(RadiateDesign.Colors.textSecondary)
            }
            
            // Events
            VStack(alignment: .leading, spacing: RadiateDesign.Spacing.sm) {
                EventRow(time: "9:00 AM", title: "Team Standup", color: RadiateDesign.Colors.azure)
                EventRow(time: "11:00 AM", title: "Design Review", color: RadiateDesign.Colors.emerald)
                EventRow(time: "2:00 PM", title: "Product Launch", color: RadiateDesign.Colors.crimson)
            }
        }
        .padding(RadiateDesign.Spacing.md)
        .background(RadiateDesign.Colors.glassDark)
        .cornerRadius(RadiateDesign.CornerRadius.md)
    }
}

struct EventRow: View {
    let time: String
    let title: String
    let color: LinearGradient
    
    var body: some View {
        HStack(spacing: RadiateDesign.Spacing.sm) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(RadiateDesign.Typography.callout)
                    .foregroundColor(RadiateDesign.Colors.text)
                
                Text(time)
                    .font(RadiateDesign.Typography.caption2)
                    .foregroundColor(RadiateDesign.Colors.textTertiary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - System Stats Widget
struct SystemStatsWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: RadiateDesign.Spacing.sm) {
            HStack {
                Image(systemName: "cpu")
                    .font(.system(size: 20))
                    .foregroundColor(RadiateDesign.Colors.emerald.gradient.stops.first?.color)
                
                Text("System")
                    .font(RadiateDesign.Typography.headline)
                    .foregroundColor(RadiateDesign.Colors.text)
                
                Spacer()
            }
            
            VStack(spacing: RadiateDesign.Spacing.sm) {
                StatRow(label: "CPU", value: 23, color: RadiateDesign.Colors.emerald)
                StatRow(label: "Memory", value: 45, color: RadiateDesign.Colors.azure)
                StatRow(label: "Disk", value: 67, color: RadiateDesign.Colors.amber)
            }
        }
        .padding(RadiateDesign.Spacing.md)
        .background(RadiateDesign.Colors.glassDark)
        .cornerRadius(RadiateDesign.CornerRadius.md)
    }
}

struct StatRow: View {
    let label: String
    let value: Int
    let color: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(RadiateDesign.Typography.caption1)
                    .foregroundColor(RadiateDesign.Colors.textSecondary)
                
                Spacer()
                
                Text("\(value)%")
                    .font(RadiateDesign.Typography.caption1)
                    .foregroundColor(RadiateDesign.Colors.text)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(RadiateDesign.Colors.surfaceLight)
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value) / 100, height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Stock Market Widget
struct StockMarketWidget: View {
    let stocks = [
        ("AAPL", "Apple Inc.", 178.23, 2.34),
        ("GOOGL", "Alphabet", 142.56, -1.23),
        ("MSFT", "Microsoft", 378.91, 5.67),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: RadiateDesign.Spacing.sm) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20))
                    .foregroundColor(RadiateDesign.Colors.indigo.gradient.stops.first?.color)
                
                Text("Stocks")
                    .font(RadiateDesign.Typography.headline)
                    .foregroundColor(RadiateDesign.Colors.text)
                
                Spacer()
            }
            
            VStack(spacing: RadiateDesign.Spacing.sm) {
                ForEach(stocks, id: \.0) { stock in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stock.0)
                                .font(RadiateDesign.Typography.callout)
                                .foregroundColor(RadiateDesign.Colors.text)
                            
                            Text(stock.1)
                                .font(RadiateDesign.Typography.caption2)
                                .foregroundColor(RadiateDesign.Colors.textTertiary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "$%.2f", stock.2))
                                .font(RadiateDesign.Typography.callout)
                                .foregroundColor(RadiateDesign.Colors.text)
                            
                            HStack(spacing: 2) {
                                Image(systemName: stock.3 > 0 ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 10))
                                
                                Text(String(format: "%.2f", abs(stock.3)))
                                    .font(RadiateDesign.Typography.caption2)
                            }
                            .foregroundColor(stock.3 > 0 ? RadiateDesign.Colors.success : RadiateDesign.Colors.error)
                        }
                    }
                }
            }
        }
        .padding(RadiateDesign.Spacing.md)
        .background(RadiateDesign.Colors.glassDark)
        .cornerRadius(RadiateDesign.CornerRadius.md)
    }
}