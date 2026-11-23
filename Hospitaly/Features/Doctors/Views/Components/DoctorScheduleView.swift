//
//  DoctorScheduleView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct DoctorScheduleView: View {
    @Bindable var viewModel: DoctorDetailViewModel
    @State private var showsCalendar = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Schedules")
                    .font(.title3.bold())
                    .foregroundStyle(Color.themeText)

                Spacer()

                Button {
                    showsCalendar = true
                } label: {
                    HStack(spacing: 5) {
                        Text(ClinicDate.label(viewModel.selectedDate, as: .dateTime.month(.abbreviated).year()))
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.themePrimary)
                }
                .buttonStyle(.plain)
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.days, id: \.self) { date in
                            dayButton(date)
                        }
                    }
                    .padding(.bottom, 6)
                }
                .scrollIndicators(.hidden)
                .onChange(of: viewModel.selectedDate, initial: true) {
                    let day = ClinicDate.calendar.startOfDay(for: viewModel.selectedDate)
                    proxy.scrollTo(day, anchor: .center)
                }
            }

            let slots = viewModel.slots

            if !slots.contains(where: \.isAvailable) {
                Text("No available times for this date.")
                    .font(.subheadline)
                    .foregroundStyle(Color.themeSecondaryText)
            }

            slotSection("Morning", slots: slots.filter(\.isMorning))
            slotSection("Afternoon", slots: slots.filter { !$0.isMorning })
        }
        .sheet(isPresented: $showsCalendar) {
            NavigationStack {
                DatePicker("Schedule date", selection: $viewModel.selectedDate, in: viewModel.dateRange, displayedComponents: .date)
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
        let selected = ClinicDate.calendar.isDate(date, inSameDayAs: viewModel.selectedDate)

        return Button {
            viewModel.selectedDate = date
        } label: {
            VStack(spacing: 8) {
                Text(ClinicDate.label(date, as: .dateTime.weekday(.abbreviated)))
                    .font(.caption)
                    .foregroundStyle(selected ? Color.themeSurface : Color.themeMutedText)

                Text(ClinicDate.label(date, as: .dateTime.day()))
                    .font(.title2.bold())
                    .foregroundStyle(selected ? Color.themeSurface : Color.themeText)
            }
            .frame(width: 65, height: 89)
            .background(selected ? Color.themePrimary : Color.themeSurface, in: .rect(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Color.themeCardBorder, lineWidth: selected ? 0 : 1)
            }
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
                    let selected = viewModel.selectedSlot?.id == slot.id

                    Button {
                        viewModel.selectSlot(slot)
                    } label: {
                        Text(slot.timeLabel)
                            .font(.subheadline.weight(selected ? .semibold : .medium))
                            .foregroundStyle(
                                selected ? Color.themePrimary
                                    : slot.isAvailable ? Color.themeText : Color.themeMutedText.opacity(0.65)
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.themeSurface, in: .rect(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(
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
    ScrollView {
        DoctorScheduleView(viewModel: DoctorDetailViewModel(doctor: Doctor.samples[2], appointments: []))
            .padding()
    }
    .background(Color.themeDetailCanvas)
}
