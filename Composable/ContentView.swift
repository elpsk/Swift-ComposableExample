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
                
                Button("GET QUOTE") {
                    viewStore.send(.quotePressed)
                }
                .padding(.top, 50)

                ScrollView {
                    Text(viewStore.numberQuoteMessage ?? "")
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



struct Brewery: Codable, Equatable {
    var id, name, breweryType, address1: String?
    var address2, address3: String?
    var city, stateProvince, postalCode, country: String?
    var longitude, latitude: String?
    var phone: String?
    var websiteURL: String?
    var state, street: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case breweryType = "brewery_type"
        case address1 = "address_1"
        case address2 = "address_2"
        case address3 = "address_3"
        case city
        case stateProvince = "state_province"
        case postalCode = "postal_code"
        case country, longitude, latitude, phone
        case websiteURL = "website_url"
        case state, street
    }
}
