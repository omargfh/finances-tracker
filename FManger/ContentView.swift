//
//  ContentView.swift
//  FManger
//
//  Created by Omar Ibrahim on 3/2/22.
//

import SwiftUI
import CoreData
import WidgetKit
import Foundation

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors:[],
        animation: .default)
    private var udata: FetchedResults<Userdata>
    
    @FetchRequest(
        sortDescriptors:[NSSortDescriptor(key: "start", ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<Session>
    
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    @State var isIn: Bool = false
    @State var sessionTotal: Double = 0
    @State var total: Double = 0
    @State var sessionTime: Double = 20
    @State var currentSession: UUID = UUID()
    @State var hourly: Double = 15.3
    
    
    var body: some View {
        ZStack {
            Color(UIColor(named: "Black")!)
                .ignoresSafeArea(.all, edges: .all)
            VStack {
                VStack {
                    VStack {
                        Text("Session Total")
                            .font(.headline)
                            .foregroundColor(Color("textColor"))
                        Text("$\(String(format: "%.2f", sessionTotal))")
                            .font(.system(size: 45, weight: .bold, design: .default))
                            .foregroundColor(Color("textColor"))
                    }
                    .padding(5)
                    
                    
                    HStack {
                        Text("Grand Total:")
                            .font(.body)
                            .foregroundColor(Color("textColor"))
                        
                        Text("$\(String(format: "%.2f", total))")
                            .font(.headline)
                            .foregroundColor(Color("textColor"))
                    }
                    
                }.padding()
                    .onAppear {
                        updateUI()
                    }
                    .onReceive(timer) { time in
                        updateUI()
                    }
                    .onDisappear() {
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                
                Button(isIn ? "Check Out" : "Check In") {
                    if (!isIn) {
                        logSession()
                    }
                    else {
                        endSession(session: sessions[0])
                        updateUI()
                    }
                    isIn.toggle()
                    
                    
                }
                .foregroundColor(.white)
                .padding()
                .background(isIn ? Color.red : Color.blue)
                .cornerRadius(8)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0))
                .onAppear(perform: {
                    if (sessions.count > 0) {
                        if (sessions[0].end == nil) {
                            isIn = true
                            currentSession = sessions[0].id!
                        }
                    }
                })
                if (isIn) {
                    HStack {
                        Text("Session Time:")
                            .font(.body)
                            .foregroundColor(Color("textColor"))
                        
                        Text("\(String(format: "%.0f", floor(sessionTime / 60.0))) hours and \(String(format: "%.0f", ((sessionTime / 60.0) - floor(sessionTime / 60.0)) * 60.0)) minutes")
                            .font(.body)
                            .foregroundColor(Color("textColor"))
                    }
                    HStack {
                        Text("Checked in at: \(sessions[0].start!, formatter: itemFormatter)")
                            .foregroundColor(Color("textColor"))
                            .font(.body)
                            .transition(AnyTransition.opacity.animation(.easeInOut(duration:1.0)))
                    }
                }
                
            }
            .edgesIgnoringSafeArea(.all)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
    }
    
    private func logSession() {
        withAnimation {
            // CoreData
            let newSession = Session(context: viewContext)
            let currentDate = Date()
            newSession.id = currentSession
            newSession.start = currentDate
            newSession.end = nil
            do {
                try viewContext.save()
                
                // WidgetData
                let newEntry = WidgetData(checkedIn: true, startDate: currentDate, historyMinutes: totalMinutes(sessions: sessions), paycheckDay: Date())
                let serialized = try! JSONEncoder().encode(newEntry)
                UserDefaults(suiteName: "group.com.omaribrahim-uchicago.FManger")!
                    .set(serialized, forKey: "widgetData")
                WidgetCenter.shared.reloadAllTimelines()
                
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func endSession(session: Session) {
        let updatedSession = Date()
        viewContext.performAndWait {
            session.end = updatedSession
            try? viewContext.save()
        }
        // WidgetData
        let newEntry = WidgetData(checkedIn: false, startDate: Date(), historyMinutes: totalMinutes(sessions: sessions), paycheckDay: Date())
        let serialized = try! JSONEncoder().encode(newEntry)
        UserDefaults(suiteName: "group.com.omaribrahim-uchicago.FManger")!
            .set(serialized, forKey: "widgetData")
        WidgetCenter.shared.reloadAllTimelines()
        currentSession = UUID()
    }
    
    private func updateUI() {
        if (sessions.count > 0 && sessions[0].start != nil) {
            if (sessions[0].end == nil) {
                let currentSessionDumb = getTotal(perHour: hourly, minutes: timeBetween(fromDate: sessions[0].start!, toDate: Date()))
                sessionTime = timeBetween(fromDate: sessions[0].start!, toDate: Date())
                total = getTotal(perHour: hourly, minutes: totalMinutes(sessions: sessions)) + currentSessionDumb
                sessionTotal = currentSessionDumb
            }
            else {
                total = getTotal(perHour: hourly, minutes: totalMinutes(sessions: sessions))
                sessionTime = 0
                sessionTotal = 0.0
            }
        }
    }
    //
    //    private func deleteItems(offsets: IndexSet) {
    //        withAnimation {
    //            offsets.map { items[$0] }.forEach(viewContext.delete)
    //
    //            do {
    //                try viewContext.save()
    //            } catch {
    //                // Replace this implementation with code to handle the error appropriately.
    //                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
    //                let nsError = error as NSError
    //                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    //            }
    //        }
    //    }
    
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
