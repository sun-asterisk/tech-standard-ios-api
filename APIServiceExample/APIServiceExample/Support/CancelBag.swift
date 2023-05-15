//
//  CancelBag.swift
//  APIServiceExample
//
//  Created by Tuan Truong on 15/05/2023.
//

import Foundation
import Combine

open class CancelBag {
    public var subscriptions = Set<AnyCancellable>()
    
    public func cancel() {
        subscriptions.forEach { $0.cancel() }
        subscriptions.removeAll()
    }
}

extension AnyCancellable {
    public func store(in cancelBag: CancelBag) {
        cancelBag.subscriptions.insert(self)
    }
}
