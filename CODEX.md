# CODEX.md

## Project Overview

- This repository contains the `APIService` networking library (Swift Package) and the `APIServiceExample` sample app.
- The library is organized around three main areas:
  - `Endpoint`: defines requests, query/body parameters, and multipart data.
  - `Service`: executes requests, downloads, and data tasks using `URLSession`.
  - `Logger`: standardizes request/response logging at multiple verbosity levels.

## Repository Layout

- `Package.swift`: package manifest at root; target points to `APIService/Sources`.
- `APIService/Sources`: main library source code.
- `APIService/Tests`: location for unit tests (currently mostly empty; add tests for new behavior).
- `APIServiceExample`: sample app that integrates the library.
- `Networking.xcworkspace`: workspace for building with Xcode/xcodebuild.

## Build And Validation

- List schemes:
  - `xcodebuild -list -workspace Networking.xcworkspace`
- Build the library:
  - `xcodebuild -workspace Networking.xcworkspace -scheme APIService -destination 'generic/platform=iOS' build`
- Build the sample app:
  - `xcodebuild -workspace Networking.xcworkspace -scheme APIServiceExample -destination 'generic/platform=iOS' build`

## Editing Guidelines

- Keep compatibility with `iOS 13+` and `Swift 5` as defined in `Package.swift`.
- Avoid breaking existing public APIs in `APIService/Sources`.
- When changing `URLRequest` construction behavior in `Endpoint`, preserve body priority:
  - `parts` > `bodyData` > `body`.
- When adding new features, update usage examples in `README.md`.
- Any behavior change should include new tests in `APIService/Tests/APIServiceTests`.

## PR Checklist

- Ensure the project builds successfully with the `xcodebuild` commands above.
- Verify that changes do not break exposed public APIs.
- Update documentation (`README.md` or related files) when usage changes.
