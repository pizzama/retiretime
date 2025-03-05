//
//  ContentView.swift
//  retiretime
//
//  Created by pizzaman on 2025/3/5.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var eventStore = EventStore()
    
    var body: some View {
        EventListView(eventStore: eventStore)
    }
}

#Preview {
    ContentView()
}
