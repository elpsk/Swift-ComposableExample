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
                TextField("[optional value]", text: viewStore.binding(get: { $0.startTime }, send: Stepper.Action.indexChanged))
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)

                HStack(spacing: 20) {
                    Button {
                        viewStore.send(.subtract)
                    } label: {
                        Image(systemName: "minus.square.fill")
                            .resizable()
                            .frame(maxWidth: 50, maxHeight: 50)
                            .tint(.red)
                    }

                    Text("\(viewStore.elapsedTime)")
                        .font(.largeTitle)

                    Button {
                        viewStore.send(.add)
                    } label: {
                        Image(systemName: "plus.app.fill")
                            .resizable()
                            .frame(maxWidth: 50, maxHeight: 50)
                            .tint(.green)
                    }
                    
                }
                .alert(isPresented: viewStore.binding(get: { $0.limitReached }, send: .alertDismissed)) {
                    Alert(title: Text("Limit reached."))
                }
                
                Button("GET RANDOM QUOTE") {
                    viewStore.send(.quotePressed)
                }
                .padding()
                .padding(.horizontal, 30)
                .foregroundColor(.black)
                .background(Color.orange)
                .cornerRadius(25)
                .padding(.top, 50)

                ScrollView {
                    Text(viewStore.numberQuoteMessage ?? "")
                        .fontWeight(.light)
                }
                .frame(maxHeight: 200)
                .padding(.top, 20)

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
        
        case quotePressed
        case numberQuoteResponse(TaskResult<String>)
    }

    struct State: Equatable {
        var numberQuoteMessage: String?

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
        case .quotePressed:
            return .task { [number = state.elapsedTime] in
                await .numberQuoteResponse(
                    TaskResult {
                        String(
                            decoding: try await URLSession.shared
                                .data(from: URL(string: "http://numbersapi.com/\(number)/trivia")!).0,
                            as: UTF8.self
                        )
                    }
                )
            }
        case let .numberQuoteResponse(.success(beer)):
            state.numberQuoteMessage = beer
            return .none
        case .numberQuoteResponse(.failure(_)):
            state.numberQuoteMessage = "Could not load a number beer :()"
            return .none
        }
    }

    private func checkLimits( state: inout State) {
        let limit = 10

        if state.elapsedTime > limit {
            state.elapsedTime = limit
            state.limitReached = true
        } else if state.elapsedTime < 0 {
            state.elapsedTime = 0
            state.limitReached = true
        }
    }
}
