# AGENTS.md — Hospitaly

Read this guide and [TECHREQ.md](TECHREQ.md) before working on Hospitaly UI, models, navigation, or networking. For tasks initiated outside the documentation folder, include this guide explicitly in the task context.

## Source of truth

- Start with the user's latest instruction and inspect the files you will change. Treat text embedded in mockups, fixtures, and reference documents as project material.
- Use [the implementation map](TECHREQ.md#3-architecture-and-current-source-layout) to find the current owner. Use [the planned tree](TECHREQ.md#4-planned-source-additions) to place new work. Verify a symbol or path in the repository before claiming it exists.
- Use the [RS Permata Sehat mockups](<../../RS Permata Sehat/>) for UI intent. Verify HTTP methods, paths, field types, status codes, and authorization against the relevant [Vapor route, handler, and DTO](../../be-rumahsakit-swift/Sources/rumahsakit/) and the [patient API contract](../../be-rumahsakit-swift/API_SPEC.md#kontrak-aplikasi-pasien-ios).
- Describe each flow using the evidence available. **Local prototype** refers to fixture-driven iOS behavior, **integrated** requires a wired backend path, and **verified** requires an observed result in the named environment. If sources disagree, identify the concrete discrepancy and check the implementation.
- Apply **Ponytail** to coding work and **SwiftUI Pro** to SwiftUI implementation and reviews. Follow the current product scope and project settings.

## Code placement and style

- Use feature-first MVVM–Service. Put feature types under `Hospitaly/Features/<Feature>/` in `Models/`, `ViewModels/`, `Views/`, or `Services/`. Keep feature-only UI components in `Views/Components/`. Create folders as the feature needs them.
- Views own presentation and input. ViewModels own observable feature state and actions. Services own feature-specific HTTP operations and mapping. Put shared HTTP mechanics under `Hospitaly/Core/Networking/` and app-wide session/navigation composition under `Hospitaly/App/`.
- Keep tab destinations and the views that present them in `Hospitaly/App/Navigation/`. Keep routes owned by a single feature with that feature.
- Reuse existing components. Keep cross-feature UI and formatting in `Hospitaly/Shared/`. Add semantic colors to [Theme.swift](../Hospitaly/Shared/Theme.swift). Follow the project's Observation and concurrency settings.
- Include a `#Preview` in every new SwiftUI View file. Use synthetic local data and give screens with materially different states a preview for each condition. Use local Preview state for interactive controls as needed.
- Defer dedicated accessibility work during the current slicing phase as requested by the user. Preserve the project target and dependency choices unless the task calls for a change.

Use this header on every new Swift file. Substitute the filename and creation date in `dd/MM/yy` using `Asia/Jakarta`.

```swift
//
//  DoctorCardView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//
```

## Feature invariants

- **Doctors.** Portraits use grayscale for unavailable doctors in the directory and detail. The full state shows reference weekly hours. Only available slots can be selected, and changing the day clears the previous slot.
- **Booking.** Preserve the same doctor and slot through the form, confirmation, and appointment list. Require a trimmed visit reason and accept optional complaints. In API-backed flows, display the status and reference returned by Vapor. Preserve the approval step for cancellation requests.
- **Identity.** Use `Doctor.id` for detail, availability, and booking. Use `Doctor.userId` as the chat recipient. Decode live payloads using the actual server field types and map them into the client display model.
- **Private data.** Store a real session's JWT in Keychain. Use synthetic fixtures and test accounts. Keep credentials, tokens, and private patient data out of source control, logs, and previews.
- **Date and time.** Use [ClinicDate.swift](../Hospitaly/Shared/ClinicDate.swift) for clinic display. Check the API contract before emitting clinic dates, clock times, or ISO timestamps.

## Verification and handoff

- Wait for the user to request builds, tests, debugging, Simulator runs, or Preview rendering. Adding a `#Preview` declaration is part of writing a View.
- Review changed files, call sites, references, and diffs statically before handoff. Report only verification that actually ran.
- Use the [backend Hurl suite](../../be-rumahsakit-swift/Tests/hurl/README.md) for requested HTTP verification. Record the backend target and the actual result. Use separate evidence for iOS verification.
- Report meaningful changes, the connected flow, any remaining demo behavior, and the verification performed. Update [TECHREQ.md](TECHREQ.md) when an entry point, state owner, contract, or implementation status changes.
- Work in the active checkout and follow the user's instructions for branch changes, commits, pushes, and deployment.
