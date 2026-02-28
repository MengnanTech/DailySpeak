//
//  ContentView.swift
//  spoken englist
//
//  Created by levi on 2026/2/28.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        StageListView()
    }
}

#Preview {
    ContentView()
        .environment(ProgressManager())
}
