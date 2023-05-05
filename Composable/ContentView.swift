//
//  ContentView.swift
//  Composable
//
//  Created by Pasca Alberto, IT on 05/05/23.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {

    let store: StoreOf<Stepper>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack {
                TextField("[Initial value]", text: viewStore.binding(get: { $0.startTime }, send: Stepper.Action.indexChanged))
                    .multilineTextAlignment(.center)
                    .font(.largeTitle)
                    .background(Color.gray.opacity(0.5))
                    .padding()

                HStack(spacing: 20) {
                    Button("ADD") {
                        viewStore.send(.add)
                    }

                    Text("\(viewStore.elapsedTime)")

                    Button("SUB") {
                        viewStore.send(.subtract)
                    }
                }
                .alert(isPresented: viewStore.binding(get: { $0.limitReached }, send: .alertDismissed)) {
                    Alert(title: Text("Limit reached."))
                }
            }
            .padding()
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: .init(
                initialState: Stepper.State(),
                reducer: Stepper()
            )
        )
    }
}

struct Stepper: ReducerProtocol {

    enum Action: Equatable {
        case indexChanged(String)
        case add
        case subtract
        case alertDismissed
    }

    struct State: Equatable {
        var startTime = ""
        var elapsedTime = 0
        var limitReached = false
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .indexChanged(initialValue):
            guard let value = Int(initialValue) else {
                return .none
            }
            if !state.limitReached {
                state.elapsedTime = value
            }
            state.startTime = initialValue
            return .none
        case .add:
            state.elapsedTime += 1
            checkLimits(state: &state)
            return .none
        case .subtract:
            state.elapsedTime -= 1
            checkLimits(state: &state)
            return .none
        case .alertDismissed:
            state.limitReached = false
            return .none
        }
    }

    private func checkLimits( state: inout State) {
        if state.elapsedTime > 10 {
            state.elapsedTime = 10
            state.limitReached = true
        } else if state.elapsedTime < 0 {
            state.elapsedTime = 0
            state.limitReached = true
        }
    }
}
