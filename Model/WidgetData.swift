//
//  WidgetData.swift
//  FManger
//
//  Created by Omar Ibrahim on 3/11/22.
//

import Foundation

struct WidgetData: Encodable, Decodable {
    let checkedIn: Bool
    let startDate: Date
    let historyMinutes: Double
    let paycheckDay: Date
    
    var daysUntilPaycheck: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: paycheckDay).day!
    }
    
    var sessionTotal: Double {
        if (checkedIn) {
            return fromMinutes(minutes: timeBetween(fromDate: startDate, toDate: Date()))
        }
        else { return 0 }
    }
    
    var grossTotal: Double {
        if (checkedIn) {
            return fromMinutes(minutes: historyMinutes + timeBetween(fromDate: startDate, toDate: Date()))
        }
        else {
            return fromMinutes(minutes: historyMinutes)
        }
    }
    
    static let preview = WidgetData(checkedIn: true, startDate: Date() - (60 * 60 * 5), historyMinutes: 60 * 5, paycheckDay: Date())
    static let error = WidgetData(checkedIn: false, startDate: Date(), historyMinutes: 0.0, paycheckDay: Date())

}
