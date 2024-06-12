//
//  DownloadImage.swift
//  APIServiceExample
//
//  Created by Tuan Truong on 4/6/24.
//

import SwiftUI
import Combine
import APIService

struct DownloadImageView: View {
    @ObservedObject private var viewModel = ViewModel()

    var body: some View {
        VStack {
            ForEach(viewModel.progressDict.keys.sorted(by: { $0.absoluteString < $1.absoluteString }), id: \.self) { url in
                VStack {
                    Text(url.absoluteString)
                        .font(.caption)
                    ProgressView(value: viewModel.progressDict[url]?.0 ?? 0.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding()
                    if let data = viewModel.progressDict[url]?.1 {
                        Text("Data received: \(data.count) bytes")
                    }
                }
            }
            Button("Start Downloads") {
                let urls = [
//                    URL(string: "https://file-examples.com/storage/fe4e1227086659fa1a24064/2017/10/file_example_JPG_2500kB.jpg")!
                    URL(string: "https://file-examples.com/storage/fe3cb26995666504a8d6180/2017/04/file_example_MP4_640_3MG.mp4")!
                ]
                viewModel.startDownload(urls: urls)
            }
            
            Button("Cancel") {
                viewModel.cancelDownload()
            }
        }
        .padding()
    }
}

class ViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    @Published var progressDict: [URL: (Double?, Data?)] = [:]
    
    private let apiService = DefaultAPIService.shared

    func startDownload(urls: [URL]) {
        for url in urls {
//            apiService.download(DownloadFileEndpoint.image(url: url.absoluteString))
//                .sink(receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        print("Download finished for \(url)")
//                    case .failure(let error):
//                        print("Download failed for \(url): \(error)")
//                    }
//                }, receiveValue: { [weak self] fileURL, progress in
//                    self?.progressDict[url] = (progress, fileURL)
//                    
//                    if let fileURL {
//                        print("File downloaded", fileURL)
//                    }
//                })
//                .store(in: &cancellables)
            
            apiService.requestData(DownloadFileEndpoint.image(url: url.absoluteString))
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("Download finished for \(url)")
                    case .failure(let error):
                        print("Download failed for \(url): \(error)")
                    }
                }, receiveValue: { [weak self] data, progress in
                    self?.progressDict[url] = (progress, data)
                })
                .store(in: &cancellables)
            
        }
    }
    
    func cancelDownload() {
        cancellables = Set<AnyCancellable>()
    }
}
