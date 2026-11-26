//
//  AppointmentSlotPicker.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct AppointmentSlotPicker: View {
    let days: [Date]
    let dateRange: ClosedRange<Date>
    @Binding var selectedDate: Date
    let slots: [AppointmentSlot]
    let selectedSlot: AppointmentSlot?
    let onSelectSlot: (AppointmentSlot) -> Void
    var isCompact = false

    @State private var showsCalendar = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(isCompact ? "Available Date & Time" : "Schedules")
                    .font(.title3.bold())
                    .foregroundStyle(Color.themeText)

                Spacer()

                Button {
                    showsCalendar = true
                } label: {
                    HStack(spacing: 5) {
                        Text(ClinicDate.label(selectedDate, as: .dateTime.month(.abbreviated).year()))
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.themePrimary)
                    .frame(minHeight: isCompact ? 44 : nil)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(days, id: \.self) { date in
                            dayButton(date)
                        }
                    }
                    .padding(.bottom, 6)
                }
                .scrollIndicators(.hidden)
                .onChange(of: selectedDate, initial: true) {
                    let day = ClinicDate.calendar.startOfDay(for: selectedDate)
                    proxy.scrollTo(day, anchor: .center)
                }
            }

            if slots.isEmpty {
                ContentUnavailableView(
                    "No Slots on This Date", systemImage: "calendar",
                    description: Text("Choose another date to check available times.")
                )
            } else if !slots.contains(where: \.isAvailable) {
                Text("All times for this date are unavailable. Choose another date.")
                    .font(.subheadline)
                    .foregroundStyle(Color.themeSecondaryText)
            }

            let morning = slots.filter(\.isMorning)
            let afternoon = slots.filter { !$0.isMorning }
            if !morning.isEmpty {
                slotSection("Morning", slots: morning)
            }
            if !afternoon.isEmpty {
                slotSection("Afternoon", slots: afternoon)
            }
        }
        .sheet(isPresented: $showsCalendar) {
            NavigationStack {
                DatePicker("Schedule date", selection: $selectedDate, in: dateRange, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .environment(\.calendar, ClinicDate.calendar)
                    .environment(\.timeZone, ClinicDate.calendar.timeZone)
                    .padding()
                    .navigationTitle("Choose a date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showsCalendar = false }
                        }
                    }
            }
            .tint(Color.themePrimary)
        }
    }

    private func dayButton(_ date: Date) -> some View {
        let selected = ClinicDate.calendar.isDate(date, inSameDayAs: selectedDate)
        let shape = RoundedRectangle(cornerRadius: isCompact ? 16 : 24)

        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: isCompact ? 4 : 8) {
                Text(ClinicDate.label(date, as: .dateTime.weekday(.abbreviated)))
                    .font(.caption)
                    .foregroundStyle(selected ? Color.themeSurface : Color.themeMutedText)

                Text(ClinicDate.label(date, as: .dateTime.day()))
                    .font(.title2.bold())
                    .foregroundStyle(selected ? Color.themeSurface : Color.themeText)
            }
            .frame(width: isCompact ? 54 : 65, height: isCompact ? 66 : 89)
            .background(selected ? Color.themePrimary : Color.themeSurface, in: shape)
            .overlay { shape.strokeBorder(Color.themeCardBorder, lineWidth: selected ? 0 : 1) }
            .shadow(color: selected ? Color.themePrimary.opacity(0.22) : .clear, radius: 4, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func slotSection(_ title: LocalizedStringKey, slots: [AppointmentSlot]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(Color.themeText)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(slots) { slot in
                    let selected = selectedSlot?.id == slot.id
                    let filled = selected && isCompact
                    let shape = RoundedRectangle(cornerRadius: isCompact ? 22 : 14)
                    let selectedLabelColor = filled ? Color.themeSurface : Color.themePrimary
                    let labelColor = slot.isAvailable ? Color.themeText : Color.themeMutedText.opacity(0.65)

                    Button {
                        onSelectSlot(slot)
                    } label: {
                        Text(slot.timeLabel)
                            .font(.subheadline.weight(selected ? .semibold : .medium))
                            .foregroundStyle(selected ? selectedLabelColor : labelColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(filled ? Color.themePrimary : Color.themeSurface, in: shape)
                            .overlay {
                                shape.strokeBorder(
                                    selected ? Color.themePrimary : Color.themeCardBorder,
                                    lineWidth: selected ? 2 : 1
                                )
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(!slot.isAvailable)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var model = DoctorDetailViewModel(doctor: Doctor.samples[2], appointments: [])
    @Bindable var viewModel = model

    ScrollView {
        AppointmentSlotPicker(
            days: viewModel.days, dateRange: viewModel.dateRange, selectedDate: $viewModel.selectedDate,
            slots: viewModel.slots, selectedSlot: viewModel.selectedSlot, onSelectSlot: viewModel.selectSlot
        )
        .padding()
    }
    .background(Color.themeDetailCanvas)
}
