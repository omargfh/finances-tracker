//
//  GlobalHelpers.swift
//  FManger
//
//  Created by Omar Ibrahim on 3/11/22.
//

import SwiftUI
import Foundation
import CoreData

let hourlyRate: Double = 15.3

func timeBetween(fromDate: Date, toDate: Date) -> Double {
    let seconds = Calendar.current.dateComponents([.second], from: fromDate, to: toDate).second ?? 0
    return Double(seconds) / 60.0
}

func totalMinutes(sessions: FetchedResults<Session>) -> Double {
    var time: Double = 0.0
    for session in sessions {
        if (session.end != nil) {
            time = time + timeBetween(fromDate: session.start!, toDate: session.end!)
        }
    }
    return time
}

 func getTotal(perHour: Double, minutes: Double) -> Double {
    return perHour * (minutes / 60)
}

func fromMinutes(minutes: Double) -> Double {
    return (hourlyRate / 60) * minutes
}
