//
//  EventFunctions.swift
//  labX-ios
//
//  Created by Avyan Mehra on 1/7/25.
//

import Foundation
import EventKit

func requestCalendarAccess() {
    let eventStore = EKEventStore()
    
    eventStore.requestFullAccessToEvents() { (granted, error) in
        if granted && error == nil {

        } else {
            print("Error")
            print("Access to the calendar was denied.")
        }
    }
}

func requestEvent(_ event: Event) {
    let eventStore = EKEventStore()
    let calendarEvent = EKEvent(eventStore: eventStore)
    
    calendarEvent.title = event.title
    calendarEvent.startDate = event.date
    calendarEvent.endDate = event.date.addingTimeInterval(3600)
    calendarEvent.notes = event.description
    calendarEvent.calendar = eventStore.defaultCalendarForNewEvents
    
    do {
        try eventStore.save(calendarEvent, span: .thisEvent)
        print("Event Added")
        print("The event has been successfully added to your calendar.")
    } catch {
        print("Error")
        print("There was an error adding the event to your calendar: \(error.localizedDescription)")
    }
}

func fetchEvents(date: Date) -> [EKEvent] {
    let eventStore = EKEventStore()
    let calendars = eventStore.calendars(for: .event)
    
    let startDate = Calendar.current.startOfDay(for: date)
    let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
    
    let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
    let events = eventStore.events(matching: predicate)
    
    print(events)
    return events.sorted { $0.startDate < $1.startDate }
}

