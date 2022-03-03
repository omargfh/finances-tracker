//
//  Session+CoreDataProperties.swift
//  FManger
//
//  Created by Omar Ibrahim on 3/2/22.
//
//

import Foundation
import CoreData


extension Session {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Session> {
        return NSFetchRequest<Session>(entityName: "Session")
    }

    @NSManaged public var start: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var end: Date?

}

extension Session : Identifiable {

}
