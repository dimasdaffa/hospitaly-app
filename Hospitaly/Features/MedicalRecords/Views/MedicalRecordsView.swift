//
//  MedicalRecordsView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import SwiftUI

struct MedicalRecordsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model = MedicalRecordsViewModel()
    @State private var loadAttempt = 0

    let actions: MedicalRecordsActions
    let onFollowUp: (Doctor) -> Void
    var onChat: ((Doctor) -> Void)? = nil

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: -Theme.heroOverlap) {
                    header
                        .hospitalyPageHero(topInset: geometry.safeAreaInsets.top)

                    LazyVStack(alignment: .leading, spacing: 16) {
                        searchBar
                        filters
                        content
                    }
                    .padding(.horizontal, Theme.contentInset)
                    .frame(maxWidth: Theme.dashboardWidth)
                    .padding(.bottom, 24)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable { await model.load(using: actions.loadHistory) }
            .ignoresSafeArea(.container, edges: .top)
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .navigationDestination(for: MedicalRecordEntry.Route.self, destination: destination)
        .task(id: loadAttempt) { await model.load(using: actions.loadHistory) }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Medical Records")
                .font(.largeTitle.bold())
                .tracking(-0.8)
                .foregroundStyle(Color.themeSurface)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                dismiss()
            } label: {
                Label("Close", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.headline)
                    .foregroundStyle(Color.themeSurface)
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.tint(Color.themeCrimsonDeep.opacity(0.35)).interactive(), in: Circle())
                    .environment(\.colorScheme, .dark)
            }
            .buttonStyle(.plain)
        }
    }

    private var searchBar: some View {
        @Bindable var model = model

        return HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.themeCrimsonInk)

            TextField("Search medical records", text: $model.query)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .foregroundStyle(Color.themeText)

            if !model.query.isEmpty {
                Button {
                    model.query = ""
                } label: {
                    Label("Clear Search", systemImage: "xmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(Color.themeSecondaryText)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .font(.subheadline)
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .frame(minHeight: Theme.heroOverlap * 2)
        .hospitalyGlassSurface(in: Capsule())
        .environment(\.colorScheme, .light)
    }

    private var filters: some View {
        @Bindable var model = model

        return Picker("Record Type", selection: $model.filter) {
            Text("All").tag(nil as MedicalRecordEntry.Kind?)
            Text("Diagnosis").tag(Optional(MedicalRecordEntry.Kind.diagnosis))
            Text("Labs").tag(Optional(MedicalRecordEntry.Kind.lab))
            Text("Vaccines").tag(Optional(MedicalRecordEntry.Kind.vaccination))
        }
        .pickerStyle(.segmented)
    }

    @ContentBuilder
    private var content: some View {
        switch model.phase {
        case .loading:
            LoadingStateView(model.entries.isEmpty ? "Loading medical records…" : "Refreshing medical records…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, model.entries.isEmpty ? 38 : 6)
        case .failed(let message):
            if model.entries.isEmpty {
                ContentUnavailableView {
                    Label("Couldn’t Load Records", systemImage: "exclamationmark.circle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry") { loadAttempt += 1 }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                RefreshFailureView(message: message) { loadAttempt += 1 }
            }
        case .loaded:
            EmptyView()
        }

        if !model.entries.isEmpty || model.phase == .loaded {
            history
        }
    }

    @ContentBuilder
    private var history: some View {
        let latest = model.latestVisit
        let months = model.months

        if model.entries.isEmpty {
            ContentUnavailableView(
                "No Medical Records", systemImage: "folder",
                description: Text("Your diagnoses, vaccinations, and published lab results will appear here.")
            )
        } else if latest == nil && months.isEmpty {
            ContentUnavailableView(
                "No Matching Records", systemImage: "magnifyingglass",
                description: Text("Try a different keyword or select All Records.")
            )
        } else {
            if let latest {
                NavigationLink(value: latest.id) { latestCard(latest) }
                    .buttonStyle(.plain)
            }

            if !months.isEmpty {
                Text(latest == nil ? "Records" : "Past Records")
                    .font(.title3.bold())
                    .foregroundStyle(Color.themeText)
                    .padding(.top, 4)
            }

            ForEach(months) { month in
                Section {
                    ForEach(month.entries) { entry in
                        NavigationLink(value: entry.id) { MedicalRecordCard(entry: entry) }
                            .buttonStyle(.plain)
                    }
                } header: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.themeCrimsonInk)
                            .frame(width: 7, height: 7)
                        Text(month.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.themeSecondaryText)
                        Rectangle()
                            .fill(Color.themeGlassRose)
                            .frame(height: 1)
                    }
                }
            }
        }
    }

    private func latestCard(_ entry: MedicalRecordEntry) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 12) {
                Label("Last Visit", systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themeCrimsonInk)
                Spacer()
                if let date = entry.date {
                    Text(ClinicDate.label(date, as: .dateTime.day().month(.abbreviated).year()))
                        .font(.subheadline)
                        .foregroundStyle(Color.themeSecondaryText)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.title2.bold())
                    .foregroundStyle(Color.themeText)

                if let provider = entry.provider {
                    Text(provider)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themeText)
                }

                if let specialty = entry.subtitle {
                    Text(specialty)
                        .font(.subheadline)
                        .foregroundStyle(Color.themeSecondaryText)
                }
            }

            HStack(spacing: 8) {
                Text("View Full Report")
                Spacer()
                Image(systemName: "arrow.right")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.themeCrimsonInk)
            .padding(12)
            .background(Color.themeGlassRose, in: .rect(cornerRadius: 14))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .contentShape(.rect(cornerRadius: Theme.cardRadius))
    }

    @ContentBuilder
    private func destination(_ route: MedicalRecordEntry.Route) -> some View {
        switch route {
        case .record(let id):
            DiagnosisDetailView(recordID: id, actions: actions, onFollowUp: onFollowUp, onChat: onChat)
        case .lab(let id):
            LabResultDetailView(resultID: id, actions: actions)
        }
    }
}

#Preview("Medical Records") {
    NavigationStack {
        MedicalRecordsView(actions: .preview, onFollowUp: { _ in })
    }
    .tint(Color.themePrimary)
}

#Preview("Empty History") {
    NavigationStack {
        MedicalRecordsView(actions: .previewEmpty, onFollowUp: { _ in })
    }
    .tint(Color.themePrimary)
}
