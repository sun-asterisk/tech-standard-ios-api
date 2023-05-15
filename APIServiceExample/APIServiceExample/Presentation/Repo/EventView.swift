//
//  EventView.swift
//  APIServiceExample
//
//  Created by Tuan Truong on 15/05/2023.
//

import SwiftUI

struct EventView: View {
    let event: Event
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: event.actor?.avatarUrl ?? ""), scale: 2) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.5)
            }
            .frame(width: 32, height: 32)
            .cornerRadius(5)

            Text(event.actor?.login ?? "")
            Spacer()
        }
        .badge(event.type.name)
    }
}
