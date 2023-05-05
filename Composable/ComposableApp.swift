//
//  ComposableApp.swift
//  Composable
//
//  Created by Pasca Alberto, IT on 05/05/23.
//

import SwiftUI

@main
struct ComposableApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: .init(
                    initialState: Stepper.State(elapsedTime: 0),
                    reducer: Stepper()._printChanges()
                )
            )
        }
    }
}
