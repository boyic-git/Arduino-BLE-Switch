//
//  Entity+CoreDataProperties.swift
//  Arduino BLE Switch
//
//  Created by Boyi Chen on 2/18/21.
//
//

import Foundation
import CoreData


extension Entity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entity> {
        return NSFetchRequest<Entity>(entityName: "Entity")
    }

    @NSManaged public var ble_name: String?

}

extension Entity : Identifiable {

}
