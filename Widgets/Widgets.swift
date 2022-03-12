//
//  Widgets.swift
//  Widgets
//
//  Created by Omar Ibrahim on 3/3/22.
//

import WidgetKit
import CoreData
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: .preview, error: false, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), data: .preview, error: false, configuration: configuration)
        
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        let encodedData  = UserDefaults(suiteName: "group.com.omaribrahim-uchicago.FManger")!.object(forKey: "widgetData") as? Data
        if let encodedData = encodedData {
            let decoded = try? JSONDecoder().decode(WidgetData.self, from: encodedData)
               if let widgetData = decoded {
                   let currentDate = Date()
                   
                   for offset in 0 ..< 60 {
                       let entryDate = Calendar.current.date(byAdding: .second, value: offset * 30, to: currentDate)!
                       let newWidgetData = WidgetData(checkedIn: widgetData.checkedIn, startDate: widgetData.startDate - TimeInterval((30 * offset)), historyMinutes: widgetData.historyMinutes, paycheckDay: widgetData.paycheckDay)
                       
                       let entry = SimpleEntry(date: entryDate,
                                               data: newWidgetData,
                                               error: false,
                                               configuration: configuration)
                       entries.append(entry)
                   }
               }
        }
        else {
            entries.append(SimpleEntry(date: Date(), data: .error, error: true, configuration: configuration))
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    var date: Date
    var data: WidgetData
    var error: Bool
    let configuration: ConfigurationIntent
    
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
                Text("$\(String(format: "%0.2f", entry.data.sessionTotal))")
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
        }
        .configurationDisplayName("Pay Tracker")
        .description("Check your current shift's earning, total earnings, and the date of your next payment in a glance.")
    }
}

struct Widgets_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WidgetsEntryView(entry: SimpleEntry(date: Date(), data: .preview, error: false, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            WidgetsEntryView(entry: SimpleEntry(date: Date(), data: .preview, error: false, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            WidgetsEntryView(entry: SimpleEntry(date: Date(), data: .preview, error: false, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
        Group {
            WidgetsEntryView(entry: SimpleEntry(date: Date(), data: .preview, error: false, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.colorScheme, .dark)
            WidgetsEntryView(entry: SimpleEntry(date: Date(), data: .preview, error: false, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.colorScheme, .dark)
            WidgetsEntryView(entry: SimpleEntry(date: Date(), data: .preview, error: false, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .environment(\.colorScheme, .dark)
        }
    }
}

