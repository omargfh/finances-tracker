//
//  Widgets.swift
//  Widgets
//
//  Created by Omar Ibrahim on 3/3/22.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {

    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: .previewData, error: false, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), data: .previewData, error: false, configuration: configuration)
        
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        @FetchRequest(
            sortDescriptors:[NSSortDescriptor(key: "start", ascending: false)],
            animation: .default)
        var sessions: FetchedResults<Session>
        
        let checkedIn = sessions[0].end != nil
        let totalMinutes = totalMinutes(sessions: sessions)
        var auxMinutes = 0.0
        if (checkedIn) {
            auxMinutes = timeBetween(fromDate: sessions[0].start!, toDate: Date())
        }
        for i in 0 ..< 5 {
            let cSession = (Double(i) + (auxMinutes / 60)) * 15.3
            let data = SimpleEntry.PayData(currentSession: cSession, grossTotal: totalMinutes * 15.3 + cSession, paycheckDay: Date() + (7 * 24 * 60 * 60), checkedIn: checkedIn)
            let entry = SimpleEntry(date: Date() + TimeInterval((i * 60 * 60)), data: data, error: false, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    var date: Date
    var data: PayData
    var error: Bool
    let configuration: ConfigurationIntent

    struct PayData: Decodable {
        let currentSession: Double
        let grossTotal: Double
        let paycheckDay: Date
        var checkedIn: Bool
        
        var daysUntilPaycheck: Int {
            Calendar.current.dateComponents([.day], from: Date(), to: paycheckDay).day!
        }
        
        static let previewData = PayData(currentSession: 20.0, grossTotal: 240.12, paycheckDay: Date() + (12 * 24 * 60 * 60), checkedIn: true)
        
        static let error = PayData(currentSession: 0.0, grossTotal: 0.0, paycheckDay: Date(), checkedIn: false)
    }
}

struct WidgetsEntryView : View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var size
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        ZStack {
            Image("Background")
                .resizable()
                .scaledToFill()
            switch size {
                case .systemSmall:
                    SmallWidgetView(entry: entry)
                case .systemMedium:
                    MediumWidgetView(entry: entry)
                case .systemLarge:
                    LargeWidgetView(entry: entry)
                case .systemExtraLarge:
                    LargeWidgetView(entry: entry)
            @unknown default:
                    Text("Error")
            }
        }
    }
    
}

struct SmallWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            HStack {
                CurrentShiftView(entry: entry, scale: 1, alignment: .leading)
                Spacer()
            }
            Spacer()
            HStack {
                Spacer()
                NextPaycheckView(entry: entry, scale: 1.2)
            }
        }
            .padding()
            .foregroundColor(Color("AccentColor"))
    }
}

struct MediumWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            HStack {
                CurrentShiftView(entry: entry, scale: 1.1, alignment: .leading)
                Spacer()
            }
            HStack {
                Spacer()
                NextPaycheckView(entry: entry, scale: 1.55)
            }
        }
            .padding()
            .foregroundColor(Color("AccentColor"))
    }
}

struct LargeWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Spacer()
            CurrentShiftView(entry: entry, scale: 1.5, alignment: .center)
            Spacer()
            HStack {
                Spacer()
                NextPaycheckView(entry: entry, scale: 1.5)
            }
        }
            .padding()
            .foregroundColor(Color("AccentColor"))
    }
}

struct CurrentShiftView: View {
    var entry: Provider.Entry
    var scale: Double
    var alignment: HorizontalAlignment
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if entry.data.checkedIn {
            VStack(alignment: alignment) {
                Text("Current Shift")
                    .font(.custom("Tahoma", size: 14 * scale))
                    .fontWeight(.bold)
                Text("$\(String(format: "%0.2f", entry.data.currentSession))")
                    .font(.custom("Tahoma", size: 30 * scale))
                    .bold()
                    .minimumScaleFactor(0.6)
                    .shadow(color: colorScheme == .dark ? Color.gray : Color.clear, radius: 2, x: 0, y: 2)
                Text("Gross: $\(String(format: "%0.2f", entry.data.grossTotal))")
                    .minimumScaleFactor(0.6)
            }
        }
        else {
            VStack(alignment: alignment) {
                Text("Gross Total")
                    .font(.custom("Tahoma", size: 14 * scale))
                    .fontWeight(.bold)
                Text("$\(String(format: "%0.2f", entry.data.grossTotal))")
                    .font(.custom("Tahoma", size: 30 * scale))
                    .bold()
                    .minimumScaleFactor(0.6)
                    .shadow(color: colorScheme == .dark ? Color.gray : Color.clear, radius: 2, x: 0, y: 2)
                Text("Checked out")
                    .font(.custom("Tahoma", size: 14 * scale))
                    .bold()
                    .minimumScaleFactor(0.6)
                    .foregroundColor(Color("checkedOutColor"))
            }
        }
    }
}

struct NextPaycheckView: View {
    var entry: Provider.Entry
    var scale: Double
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .trailing, spacing: -3) {
            Text("Next Paycheck")
                .font(.custom("Tahoma", size: 8 * scale))
                .bold()
            Text("\(String(entry.data.daysUntilPaycheck)) Days")
                .font(.custom("Tahoma", size: 16 * scale))
                .bold()
        }
    }
}

@main
struct Widgets: Widget {
    let kind: String = "Widgets"
    let persistenceController = PersistenceController.shared

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            WidgetsEntryView(entry: entry)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .configurationDisplayName("Pay Tracker")
        .description("Check your current shift's earning, total earnings, and the date of your next payment in a glance.")
    }
}

struct Widgets_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WidgetsEntryView(entry: SimpleEntry(date: Date(), data: .previewData, error: false, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            WidgetsEntryView(entry: SimpleEntry(date: Date(), data: .previewData, error: false, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            WidgetsEntryView(entry: SimpleEntry(date: Date(), data: .previewData, error: false, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}

