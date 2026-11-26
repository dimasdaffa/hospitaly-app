//
//  HomeView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct HomeView: View {
    struct Shortcut: Identifiable {
        let title: String
        let symbol: String
        let action: () -> Void

        var id: String { title }
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @FocusState private var searchFocused: Bool
    @State private var viewModel = HomeViewModel()
    @State private var carePlan = CarePlanViewModel()
    @State private var search = ""

    let patientName: String
    let isActive: Bool
    let hasUnreadNotifications: Bool
    let loadAppointments: @MainActor () async throws -> [Appointment]
    let onBook: () -> Void
    let onSearchDoctors: (String) -> Void
    let onSeeAll: () -> Void
    let onOpenAppointment: (AppointmentPresentation) -> Void
    let onOpenNotifications: (() -> Void)?
    var shortcuts: [Shortcut] = []
    var carePlanActions: CarePlanActions? = nil

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: -Theme.searchOverlap) {
                    hero(topInset: geometry.safeAreaInsets.top)
                    services
                }
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .refreshable { await refresh() }
            .ignoresSafeArea(.container, edges: .top)
        }
        .background { Theme.dashboardCanvas.ignoresSafeArea() }
        .task(id: isActive) {
            if isActive { await refresh() }
        }
    }

    private func hero(topInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            nextAppointment
        }
        .padding(.horizontal, Theme.contentInset)
        .padding(.top, topInset + 21)
        .padding(.bottom, Theme.searchOverlap + 21)
        .frame(maxWidth: Theme.dashboardWidth)
        .frame(maxWidth: .infinity)
        .background { HomeHeaderBackdrop() }
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: Theme.heroRadius, bottomTrailingRadius: Theme.heroRadius
            )
        )
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("RS Permata Sehat")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.themeSurface.opacity(0.85))

                Text("Hello, \(patientFirstName)")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.themeSurface)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GlassEffectContainer(spacing: 7) {
                HStack(spacing: 9) {
                    if let onOpenNotifications {
                        headerButton(
                            "Notifications", symbol: "bell", hasIndicator: hasUnreadNotifications,
                            action: onOpenNotifications
                        )
                    }
                }
            }
            .environment(\.colorScheme, .dark)
        }
    }

    private var patientFirstName: String {
        patientName.split(whereSeparator: \.isWhitespace).first.map { String($0) } ?? "Patient"
    }

    private func headerButton(
        _ title: String, symbol: String, hasIndicator: Bool = false, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .labelStyle(.iconOnly)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.themeSurface)
                .frame(width: 44, height: 44)
                .glassEffect(.regular.tint(Color.themeCrimsonDeep.opacity(0.35)).interactive(), in: Circle())
                .overlay(alignment: .topTrailing) {
                    if hasIndicator {
                        Circle()
                            .fill(Color.themePrimaryHighlight)
                            .frame(width: 8, height: 8)
                            .overlay { Circle().strokeBorder(Color.themeSurface, lineWidth: 1) }
                            .offset(x: -4, y: 4)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var nextAppointment: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Next Appointment")
                    .font(.headline)
                    .foregroundStyle(Color.themeSurface)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button(action: onSeeAll) {
                    Label("See All", systemImage: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.themeSurface)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }

            appointmentContent
        }
    }

    @ContentBuilder
    private var appointmentContent: some View {
        switch viewModel.phase {
        case .loading:
            ProgressView("Loading appointments…")
                .tint(.themeSurface)
                .foregroundStyle(Color.themeSurface)
                .frame(maxWidth: .infinity, minHeight: 125)
                .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius), tone: .crimson)
        case .loaded(let appointment):
            if let appointment {
                HomeAppointmentCardView(
                    appointment: appointment,
                    onDetails: { onOpenAppointment(.details(appointment)) },
                    onReschedule: appointment.canBeChanged ? { onOpenAppointment(.reschedule(appointment)) } : nil
                )
            } else {
                appointmentState(
                    "No Upcoming Appointments", detail: "Book a visit to see it here.",
                    symbol: "calendar", actionTitle: "Find a Doctor", action: onBook
                )
            }
        case .failed(let error):
            appointmentState(
                "Couldn’t Load Appointments", detail: error, symbol: "exclamationmark.circle",
                actionTitle: "Retry", action: retryAppointment
            )
        }
    }

    private func appointmentState(
        _ title: String, detail: String, symbol: String, actionTitle: String, action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Color.themeSurface)
                .frame(width: 44, height: 44)
                .background(Color.themeSurface.opacity(0.13), in: .rect(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.themeSurface)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Color.themeSurface.opacity(0.88))
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themeSurface)
                    .frame(minHeight: 44)
                    .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius), tone: .crimson)
    }

    private var services: some View {
        VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
            doctorSearch

            if !shortcuts.isEmpty { careShortcuts }

            if let carePlanActions {
                CarePlanView(
                    viewModel: carePlan,
                    onRetry: { Task { await carePlan.load(using: carePlanActions.load) } },
                    onMarkTaken: { entry in
                        Task { await carePlan.markTaken(entry, using: carePlanActions.markTaken) }
                    }
                )
            }
        }
        .padding(.horizontal, Theme.contentInset)
        .padding(.bottom, Theme.sectionSpacing)
        .frame(maxWidth: Theme.dashboardWidth)
        .frame(maxWidth: .infinity)
    }

    private var doctorSearch: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.themeCrimsonInk)

            TextField(
                "Search doctors or specialties", text: $search,
                prompt: Text("Search doctors or specialties").foregroundStyle(Color.themeSecondaryText)
            )
            .font(.subheadline)
            .foregroundStyle(Color.themeText)
            .focused($searchFocused)
            .submitLabel(.search)
            .autocorrectionDisabled()
            .onSubmit(searchDoctors)

            Button(action: searchDoctors) {
                Label(search.isEmpty ? "Find a Doctor" : "Search", systemImage: "arrow.right")
                    .labelStyle(.iconOnly)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.themeCrimsonInk)
                    .frame(width: 44, height: 44)
                    .background(Color.themeGlassRose, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 17)
        .padding(.trailing, 6)
        .frame(minHeight: Theme.searchOverlap * 2)
        .hospitalyGlassSurface(in: Capsule())
    }

    private var careShortcuts: some View {
        let columnCount = dynamicTypeSize.isAccessibilitySize ? 2 : 4
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Care Shortcuts")
                .font(.title3.bold())
                .foregroundStyle(Color.themeText)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: columns, alignment: .center, spacing: 14) {
                ForEach(shortcuts) { shortcut in
                    Button(action: shortcut.action) {
                        VStack(spacing: 7) {
                            Image(systemName: shortcut.symbol)
                                .font(.system(size: 19, weight: .medium))
                                .foregroundStyle(Color.themeCrimsonInk)
                                .frame(width: 44, height: 44)
                                .background(Color.themeGlassRose, in: .rect(cornerRadius: 15))

                            Text(shortcut.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.themeText)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
    }

    private func searchDoctors() {
        searchFocused = false
        onSearchDoctors(search.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func retryAppointment() {
        Task { await viewModel.loadNextAppointment(using: loadAppointments) }
    }

    private func refresh() async {
        async let appointmentRefresh: Void = viewModel.loadNextAppointment(using: loadAppointments)
        if let carePlanActions {
            await carePlan.load(using: carePlanActions.load)
        }
        _ = await appointmentRefresh
    }
}

#Preview("Next Appointment") {
    HomeView(
        patientName: "Demo Patient", isActive: true, hasUnreadNotifications: true,
        loadAppointments: { Appointment.samples },
        onBook: {}, onSearchDoctors: { _ in }, onSeeAll: {}, onOpenAppointment: { _ in },
        onOpenNotifications: {},
        shortcuts: [
            .init(title: "Appointments", symbol: "calendar.badge.clock", action: {}),
            .init(title: "Health Tracker", symbol: "waveform.path.ecg", action: {}),
            .init(title: "Records", symbol: "folder", action: {}),
            .init(title: "Documents", symbol: "doc.text", action: {})
        ],
        carePlanActions: .preview
    )
    .tint(.themePrimary)
}

#Preview("No Upcoming Appointments") {
    HomeView(
        patientName: "Demo Patient", isActive: true, hasUnreadNotifications: false,
        loadAppointments: { [] },
        onBook: {}, onSearchDoctors: { _ in }, onSeeAll: {}, onOpenAppointment: { _ in },
        onOpenNotifications: {}
    )
    .tint(.themePrimary)
}

#Preview("Couldn’t Load Appointments") {
    HomeView(
        patientName: "Demo Patient", isActive: true, hasUnreadNotifications: false,
        loadAppointments: { throw APIError.connectionFailed },
        onBook: {}, onSearchDoctors: { _ in }, onSeeAll: {}, onOpenAppointment: { _ in },
        onOpenNotifications: {}
    )
    .tint(.themePrimary)
}
