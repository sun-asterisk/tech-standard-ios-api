//
//  Publisher+.swift
//  APIServiceExample
//
//  Created by Tuan Truong on 15/05/2023.
//

import Combine
import SwiftUI

extension Publisher {
    func ignoreFailure() -> AnyPublisher<Output, Never> {
        self.catch { _ in Empty() }
            .eraseToAnyPublisher()
    }
    
    func handleFailure(error: Binding<IDError?>) -> AnyPublisher<Output, Never> {
        self.handleEvents(receiveCompletion: { completion in
            switch completion {
            case .failure(let err):
                error.wrappedValue = IDError(error: err)
            case .finished:
                break
            }
        })
        .ignoreFailure()
    }
    
    func sink() -> AnyCancellable {
        return self.sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }
}
