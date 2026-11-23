# Hospitaly — Technical Requirements

**RS Permata Sehat · 23 November 2026 · iOS working tree**

## 1. Product scope and sources

Hospitaly is a SwiftUI patient app for the RS Permata Sehat learning project. The signed-in shell opens on Home and has Doctors, Chat, and Profile tabs with a central Quick Access button. Profile, doctor search, slot selection, appointment management, the notification inbox, and the care plan connect to Vapor. Home shows the patient greeting, Book Now, the next appointment, and today's scheduled doses. Chat shows a placeholder.

| Question | Source of truth |
| --- | --- |
| What does the iOS project currently implement? | [Hospitaly source](../Hospitaly/) and the feature owners in [Architecture](#3-architecture-and-current-source-layout). |
| What should the screens look like? | [RS Permata Sehat mockups](<../../RS Permata Sehat/>). Names, prices, dates, and results in the images are design examples. |
| What does the backend accept and return? | [Patient API contract](../../be-rumahsakit-swift/API_SPEC.md#kontrak-aplikasi-pasien-ios), [Vapor routes](../../be-rumahsakit-swift/Sources/rumahsakit/routes.swift), and the relevant handlers and DTOs. |
| How is HTTP behavior verified? | [Backend Hurl suite](../../be-rumahsakit-swift/Tests/hurl/README.md). |
| What conventions apply to future work? | [Hospitaly agent guide](AGENTS.md). |

The mockup folder, iOS repo, and Vapor repo are siblings in the current workspace. Cross-project links assume that layout.

## 2. Technology and configuration

| Area | Current configuration |
| --- | --- |
| Xcode | The `Hospitaly` app target uses bundle ID `com.dimasdaffa.Hospitaly` and an iOS 27.2 deployment target. The project sets `SWIFT_VERSION = 5.0`, `MainActor` default isolation, and approachable concurrency. The configured language mode and installed compiler are separate settings. [Project file](../Hospitaly.xcodeproj/project.xcproj) |
| Presentation | SwiftUI, Observation through `@Observable`, typed navigation, a custom tab bar, and local `#Preview` fixtures. |
| Networking | [APIClient.swift](../Hospitaly/Core/Networking/APIClient.swift) sends HTTP requests using `URLSession`, adds Bearer authorization when requested, and decodes JSON responses. Session tokens are stored in Keychain per API base URL. |
| Local backend | Vapor and MySQL behind Nginx. Docker Compose publishes the API at `http://localhost:8081`, the default for the Debug build in Simulator. [Compose configuration](../../be-rumahsakit-swift/docker-compose.yml) |
| Local design system | `Theme.swift` holds semantic colors. `ClinicDate.swift` formats clinic dates and times in `Asia/Jakarta`. Bundled sample portraits live in the app asset catalog. |

Override the base URL with the `HOSPITALY_API_BASE_URL` environment variable in the Xcode scheme. For a physical iPhone on the same network as the Mac, use the Mac's reachable `.local` hostname and the Compose port. Local HTTP configuration lives in the [Debug Info.plist](../Config/Hospitaly-Debug-Info.plist). A Release build requires an explicit HTTPS base URL. A distributed build can get that value from the `HospitalyAPIBaseURL` key in its Info.plist. [Apple App Transport Security](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity/nsallowslocalnetworking)

## 3. Architecture and current source layout

The architecture is feature-first MVVM–Service. A **View** renders state and receives input. A **ViewModel** owns feature state and coordinates actions. A **Service** owns endpoint selection and request or response mapping. The shared **APIClient** handles HTTP transport, headers, status handling, and decoding. **SessionStore** owns app-wide authentication state and the signed-in profile.

```text
Hospitaly/                                  # iOS repository root
├── Config/
│   └── Hospitaly-Debug-Info.plist          # Debug local networking and permission description
├── Hospitaly.xcodeproj/
│   └── project.xcproj                      # App target and build settings
├── Hospitaly/                              # Source folder included in the app target
│   ├── App/
│   │   ├── HospitalyApp.swift               # App entry and dependency composition
│   │   ├── AppConfig.swift                   # Resolve the API base URL
│   │   ├── RootView.swift                    # Restore, sign in, or open the signed-in tabs
│   │   ├── SessionStore.swift                # Patient session and Keychain lifecycle
│   │   ├── SessionError.swift                # Sign-in and patient-role errors
│   │   └── Navigation/
│   │       ├── MainTab.swift                # Tab destinations, labels, and symbols
│   │       ├── MainTabView.swift            # Signed-in tabs, doctor navigation, and modal state
│   │       ├── MainTabBar.swift             # Custom tabs and center Quick Access button
│   │       └── QuickAccessSheet.swift       # Shortcut cards and Quick Book button
│   ├── Assets.xcassets/                     # App assets and bundled demo portraits
│   ├── Core/
│   │   ├── Networking/
│   │   │   ├── APIClient.swift              # HTTP requests, authorization, and JSON
│   │   │   └── APIError.swift               # Configuration, transport, and HTTP errors
│   │   └── Security/
│   │       ├── TokenStore.swift             # Read, save, and remove the Keychain token
│   │       └── TokenStoreError.swift        # Keychain and stored-token errors
│   ├── Features/
│   │   ├── Auth/
│   │   │   ├── Models/
│   │   │   │   ├── LoginRequest.swift       # Email and password payload
│   │   │   │   └── LoginResponse.swift      # JWT field from the login response
│   │   │   ├── Services/AuthService.swift   # Login and reachability calls
│   │   │   ├── ViewModels/LoginViewModel.swift # Form input, validation, and request feedback
│   │   │   └── Views/LoginView.swift        # Patient sign-in form
│   │   ├── Profile/
│   │   │   ├── Models/UserProfile.swift    # Patient identity returned by /api/users/me
│   │   │   ├── Services/ProfileService.swift # Fetch the authenticated patient's profile
│   │   │   └── Views/ProfileView.swift     # Patient identity and logout
│   │   ├── Doctors/
│   │   │   ├── Models/
│   │   │   │   ├── Doctor.swift             # Doctor display model and local fixtures
│   │   │   │   ├── DoctorDetailData.swift   # Loaded profile, dated slots, and weekly practice hours
│   │   │   │   ├── DoctorResponse.swift     # Decode the Vapor profile and slot payloads
│   │   │   │   └── DoctorRoute.swift        # Doctor and appointment destinations
│   │   │   ├── Services/DoctorService.swift # Fetch directory, profile, slots, and weekly hours
│   │   │   ├── ViewModels/
│   │   │   │   ├── DoctorListViewModel.swift   # Loading, search, filters, and local favorites
│   │   │   │   └── DoctorDetailViewModel.swift # Detail loading, dates, and slot selection
│   │   │   └── Views/
│   │   │       ├── DoctorListView.swift     # Directory, navigation, and demo appointments
│   │   │       ├── DoctorDetailView.swift   # Available and full doctor layouts
│   │   │       └── Components/
│   │   │           ├── DoctorAvatarView.swift         # Portrait and availability styling
│   │   │           ├── DoctorCardView.swift           # Directory row
│   │   │           ├── DoctorCardMetricsView.swift    # Rating and experience badges
│   │   │           ├── DoctorSearchBar.swift          # Search and quick filters
│   │   │           ├── DoctorSpecialtyFilters.swift   # Specialty selection
│   │   │           ├── DoctorProfileHeader.swift      # Profile identity and statistics
│   │   │           ├── DoctorWeeklyScheduleView.swift # Reference hours for a full doctor
│   │   │           └── DoctorBookingBar.swift         # Selected slot, fee, and continue action
│   │   ├── Appointments/
│   │   │   ├── Models/
│   │   │   │   ├── Appointment.swift         # Appointment identity, status, and reference
│   │   │   │   ├── AppointmentManagement.swift # Authenticated actions for changing an appointment
│   │   │   │   ├── AppointmentPresentation.swift # Appointment sheet destinations shared with Home
│   │   │   │   ├── AppointmentResponse.swift # Decode Vapor booking and history
│   │   │   │   ├── AppointmentSlot.swift     # Start, end, availability, and display labels
│   │   │   │   ├── BookingRequest.swift      # Create payload and stable retry key
│   │   │   │   └── CancellationRequest.swift # Selected reason and optional note
│   │   │   ├── Services/AppointmentService.swift # Book, fetch, reschedule, and request cancellation
│   │   │   ├── ViewModels/
│   │   │   │   ├── BookingViewModel.swift    # Validation, retries, and slot conflicts
│   │   │   │   ├── AppointmentsViewModel.swift # Load history and apply server updates
│   │   │   │   ├── RescheduleViewModel.swift  # Replacement slots and reschedule submission
│   │   │   │   └── CancellationViewModel.swift # Cancellation form and submission
│   │   │   └── Views/
│   │   │       ├── BookingFormView.swift         # Visit reason, optional complaints, and submit
│   │   │       ├── BookingConfirmationView.swift # Pending request and next actions
│   │   │       ├── MyAppointmentsView.swift      # Upcoming and history
│   │   │       ├── AppointmentDetailView.swift   # Read an appointment and open available actions
│   │   │       ├── RescheduleView.swift           # Pick and confirm a replacement time
│   │   │       ├── CancelAppointmentView.swift    # Submit a cancellation reason
│   │   │       ├── CancellationSubmittedView.swift # Show the pending hospital review
│   │   │       └── Components/
│   │   │           ├── AppointmentCardView.swift    # Appointment list row
│   │   │           ├── AppointmentSlotPicker.swift  # Date and slot controls shared with Doctors
│   │   │           ├── AppointmentStatusBadge.swift # Status styling
│   │   │           └── AppointmentSummaryView.swift # Doctor and chosen time
│   │   ├── Home/
│   │   │   ├── Models/
│   │   │   │   ├── CarePlanActions.swift              # Authenticated reads and dose updates
│   │   │   │   └── CarePlanEntry.swift                # Scheduled medication dose and taken time
│   │   │   ├── Services/CarePlanService.swift         # Fetch daily plan and record doses
│   │   │   ├── ViewModels/
│   │   │   │   ├── HomeViewModel.swift                # Load and select the next appointment
│   │   │   │   └── CarePlanViewModel.swift            # Daily loading, error, and saving state
│   │   │   └── Views/
│   │   │       ├── HomeView.swift                    # Greeting, notifications, booking, and next visit
│   │   │       ├── CarePlanView.swift                # Scheduled doses and Mark as Taken
│   │   │       └── Components/HomeAppointmentCardView.swift # Next visit date, status, and actions
│   │   └── Notifications/
│   │       ├── Models/PatientNotification.swift       # Notification identity, event, and read state
│   │       ├── Services/NotificationService.swift     # List and mark as read
│   │       ├── ViewModels/NotificationsViewModel.swift # Inbox loading and unread badge state
│   │       └── Views/NotificationsView.swift          # Patient appointment notification inbox
│   └── Shared/
│       ├── Theme.swift                     # Semantic color palette
│       ├── ClinicDate.swift                # Clinic time zone and date formatting
│       └── PrimaryActionButton.swift       # Shared primary action button
└── docs/
    ├── TECHREQ.md                          # Product and implementation reference
    └── AGENTS.md                           # Working conventions
```

| Behavior | Entry point | Current owner |
| --- | --- | --- |
| Sign in and restore the session | [RootView.swift](../Hospitaly/App/RootView.swift) | [SessionStore.swift](../Hospitaly/App/SessionStore.swift) owns sign-in, the loaded profile, and Keychain restoration. [LoginViewModel.swift](../Hospitaly/Features/Auth/ViewModels/LoginViewModel.swift) owns the form state and request feedback. |
| Show the patient identity and log out | [ProfileView.swift](../Hospitaly/Features/Profile/Views/ProfileView.swift) | [ProfileService.swift](../Hospitaly/Features/Profile/Services/ProfileService.swift) fetches the profile. The session store provides it and clears the token at logout. |
| Open tabs and Quick Access | [MainTabBar.swift](../Hospitaly/App/Navigation/MainTabBar.swift) | [MainTabView.swift](../Hospitaly/App/Navigation/MainTabView.swift) owns the selected tab, the Doctors navigation path, and [QuickAccessSheet.swift](../Hospitaly/App/Navigation/QuickAccessSheet.swift) presentation. The custom bar appears at tab roots. |
| Navigate Doctors | Doctors tab or Quick Access in [MainTabView.swift](../Hospitaly/App/Navigation/MainTabView.swift) | [DoctorListView.swift](../Hospitaly/Features/Doctors/Views/DoctorListView.swift) uses the shared path to open details, booking, confirmation, and appointments. |
| Load, search, filter, and favorite doctors | [DoctorListView.swift](../Hospitaly/Features/Doctors/Views/DoctorListView.swift) | [DoctorService.swift](../Hospitaly/Features/Doctors/Services/DoctorService.swift) maps `GET /api/doctors`. [DoctorListViewModel.swift](../Hospitaly/Features/Doctors/ViewModels/DoctorListViewModel.swift) owns loading, filters, and session-local favorite changes. |
| Load a doctor and pick a slot | [DoctorDetailView.swift](../Hospitaly/Features/Doctors/Views/DoctorDetailView.swift) | [DoctorService.swift](../Hospitaly/Features/Doctors/Services/DoctorService.swift) loads the profile, slots, and weekly hours. [DoctorDetailViewModel.swift](../Hospitaly/Features/Doctors/ViewModels/DoctorDetailViewModel.swift) filters the loaded slots by clinic date, blocks unavailable slots, and clears the selection when the day changes. [DoctorAvatarView.swift](../Hospitaly/Features/Doctors/Views/Components/DoctorAvatarView.swift) styles unavailable doctors in grayscale. |
| Submit a booking request | [BookingFormView.swift](../Hospitaly/Features/Appointments/Views/BookingFormView.swift) | [BookingViewModel.swift](../Hospitaly/Features/Appointments/ViewModels/BookingViewModel.swift) validates input and reuses the submission on retry. [AppointmentService.swift](../Hospitaly/Features/Appointments/Services/AppointmentService.swift) sends it to Vapor. [BookingConfirmationView.swift](../Hospitaly/Features/Appointments/Views/BookingConfirmationView.swift) displays the returned appointment. |
| View appointments again | [MyAppointmentsView.swift](../Hospitaly/Features/Appointments/Views/MyAppointmentsView.swift) | [AppointmentsViewModel.swift](../Hospitaly/Features/Appointments/ViewModels/AppointmentsViewModel.swift) loads patient appointments. The view groups them by status and time. It opens from confirmation, the directory calendar, or Quick Access. |
| Change an appointment | Actions on upcoming cards or in [Appointment Details](../Hospitaly/Features/Appointments/Views/AppointmentDetailView.swift) after tapping a card | [RescheduleView.swift](../Hospitaly/Features/Appointments/Views/RescheduleView.swift) loads replacement times. [CancelAppointmentView.swift](../Hospitaly/Features/Appointments/Views/CancelAppointmentView.swift) collects the reason and shows the submission result. [AppointmentsViewModel.swift](../Hospitaly/Features/Appointments/ViewModels/AppointmentsViewModel.swift) applies the returned appointment by ID. |
| Read appointment updates | Bell on Home in [MainTabView.swift](../Hospitaly/App/Navigation/MainTabView.swift) | [NotificationsViewModel.swift](../Hospitaly/Features/Notifications/ViewModels/NotificationsViewModel.swift) shares unread and loading state between the bell and [NotificationsView.swift](../Hospitaly/Features/Notifications/Views/NotificationsView.swift). |
| Open the dashboard and next visit | [HomeView.swift](../Hospitaly/Features/Home/Views/HomeView.swift) | [HomeViewModel.swift](../Hospitaly/Features/Home/ViewModels/HomeViewModel.swift) selects the earliest upcoming start from patient appointments. The card opens existing appointment details or reschedule. See All opens My Appointments. |
| View today's care plan and record a dose | [CarePlanView.swift](../Hospitaly/Features/Home/Views/CarePlanView.swift) on Home | [CarePlanViewModel.swift](../Hospitaly/Features/Home/ViewModels/CarePlanViewModel.swift) loads the clinic's current day and applies the response for the same scheduled dose. [CarePlanService.swift](../Hospitaly/Features/Home/Services/CarePlanService.swift) calls Vapor. |

## 4. Planned source additions

Every path below is **planned**. These are proposed names and ownership boundaries for implementation. The current Doctors and Appointments views stay in their existing folders as integration is added. The names under a feature's `Views/`, `ViewModels/`, `Models/`, and `Services/` follow the same pattern shown in the current tree.

```text
Hospitaly/
├── Hospitaly/
│   ├── Features/
│   │   ├── Profile/
│   │   │   ├── Views/PersonalInfoView.swift    # Edit personal information
│   │   │   ├── Views/SecuritySettingsView.swift # Change password form
│   │   │   └── ViewModels/ProfileViewModel.swift # Personal information edits
│   │   ├── HealthTracker/
│   │   │   ├── Views/HealthTrackerView.swift            # Blood pressure, weight, and heart rate tabs
│   │   │   ├── Views/LogVitalView.swift                 # Enter one vital measurement
│   │   │   ├── Views/Components/VitalChartView.swift    # Chart shared by the tracker tabs
│   │   │   ├── ViewModels/HealthTrackerViewModel.swift   # Date filters and chart summaries
│   │   │   ├── Models/HealthReading.swift               # Measurement and timestamp
│   │   │   └── Services/HealthService.swift             # Read and write health updates
│   │   ├── MedicalRecords/
│   │   │   ├── Views/MedicalRecordsView.swift           # Combined history
│   │   │   ├── Views/DiagnosisDetailView.swift          # Diagnosis and attachments
│   │   │   ├── Views/LabResultDetailView.swift          # Lab panels, note, and PDF
│   │   │   ├── ViewModels/MedicalRecordsViewModel.swift # Combine and filter patient history
│   │   │   ├── Models/MedicalRecord.swift               # Diagnosis or vaccination record
│   │   │   ├── Models/LabResult.swift                   # Structured lab report
│   │   │   ├── Services/MedicalRecordService.swift      # Records and clinical attachments
│   │   │   └── Services/LabResultService.swift          # Lab details and private PDF
│   │   ├── Documents/
│   │   │   ├── Views/DocumentsView.swift                # BPJS and patient files
│   │   │   ├── Views/UploadDocumentView.swift           # Pick a file and enter metadata
│   │   │   ├── Views/DocumentHistoryView.swift          # Document history
│   │   │   ├── ViewModels/DocumentsViewModel.swift      # Document list and mutation state
│   │   │   ├── Models/PatientDocument.swift             # File metadata and download path
│   │   │   └── Services/DocumentService.swift           # Multipart upload, edits, and private download
│   │   ├── Messages/
│   │   │   ├── Views/InboxView.swift                    # Conversation list and unread badges
│   │   │   ├── Views/ConversationView.swift             # Thread and message composer
│   │   │   ├── ViewModels/InboxViewModel.swift          # List and search state
│   │   │   ├── ViewModels/ConversationViewModel.swift   # Thread and send/read actions
│   │   │   ├── Models/Conversation.swift                # Inbox item and unread count
│   │   │   ├── Models/Message.swift                     # Individual message
│   │   │   └── Services/MessageService.swift            # Inbox, messages, and read status
│   │   └── Notifications/
│   │       └── Views/NotificationSettingsView.swift     # Appointment notification preferences
│   └── Shared/LoadErrorView.swift                        # Reusable retry state when screens need it
└── HospitalyTests/                                      # Add a test target when asked
    ├── LoginViewModelTests.swift
    ├── DoctorListViewModelTests.swift
    └── Fixtures/doctors.json                            # Synthetic doctor response for tests
```

## 5. UI scope and implementation status

**Local prototype** means the SwiftUI source contains the screen or interaction using fixtures. **Design reference** means the mockup is available and the iOS screen is planned. **Backend available** means the Vapor contract exists. These labels describe implementation scope. Runtime verification is recorded separately.

| Flow | Design references | iOS status |
| --- | --- | --- |
| Doctor directory and details | [Search](<../../RS Permata Sehat/Doctor Search List.png>) · [Available](<../../RS Permata Sehat/Doctor Details.png>) · [Full](<../../RS Permata Sehat/Doctor Details Not Avail.png>) | Directory, profile details, weekly practice hours, and slot selection are integrated in source. The detail screen shows retry on failure, an empty state for dates without slots, and weekly hours when no slots can be booked. Missing photos and missing weekly schedules have placeholders. |
| Booking and history | [Visit form](<../../RS Permata Sehat/Appointment Details.png>) · [Confirmation](<../../RS Permata Sehat/Make Appointment.png>) · [My Appointments](<../../RS Permata Sehat/Manage Appointment.png>) | Booking and appointment history are wired to Vapor. Confirmation uses server identity, status, and reference. My Appointments groups server results into Upcoming and History, with empty and failed states. A slot conflict offers a return to refreshed availability. |
| Reschedule and cancellation | [Dashboard action](<../../RS Permata Sehat/Patient Dashboard.png>) · [Cancellation form](<../../RS Permata Sehat/Cancel Appointment.png>) · [Cancellation alert](<../../RS Permata Sehat/Cancellation Alert.png>) | Upcoming Pending and Approved cards offer both actions, and Home can open reschedule for the next eligible visit. The replacement picker handles empty schedules and conflicts. Cancellation shows the requested state until hospital review. |
| Appointment notifications | Bell in [Patient Dashboard](<../../RS Permata Sehat/Patient Dashboard.png>) | The Home bell shows an unread dot. The inbox supports refresh, retry, empty state, and marking an item as read. |
| Dashboard and care plan | [Dashboard](<../../RS Permata Sehat/Patient Dashboard.png>) | Home shows the signed-in patient, notification bell, Book Now, the next appointment, and the daily care plan. Both data sections support pull to refresh, empty states, and Retry. A dose shows Taken after Vapor confirms the update. |
| Tab bar and shortcuts | [Quick Access](<../../RS Permata Sehat/Quick Access.png>) | Custom bar and bottom sheet are implemented. Appointments opens the existing appointment list. Find Doctors and Quick Book open the directory. Profile opens the account tab. Messages opens the Chat placeholder. Health Tracker and Records are disabled until their screens exist. |
| Medical records and lab | [Records](<../../RS Permata Sehat/Medical Record List.png>) · [Diagnosis](<../../RS Permata Sehat/Diagnosis Details.png>) · [Lab](<../../RS Permata Sehat/Lab Result.png>) | Design references and backend available. The lab PDF comes from a staff-published attachment. |
| Patient documents and BPJS | [Documents](<../../RS Permata Sehat/Document Screen.png>) · [Upload](<../../RS Permata Sehat/Upload Docs.png>) | Design references and backend available for document CRUD, history, multipart upload, and private downloads. |
| Health tracker and vital entry | [Blood pressure](<../../RS Permata Sehat/My Health.png>) · [Weight](<../../RS Permata Sehat/My Health-1.png>) · [Heart rate](<../../RS Permata Sehat/My Health-2.png>) · [BP entry](<../../RS Permata Sehat/Entry BP.png>) · [Weight entry](<../../RS Permata Sehat/Entry Weight.png>) · [Heart rate entry](<../../RS Permata Sehat/Entry Heart Rate.png>) | Design references and backend available. The client will build chart summaries from readings. |
| Messages | [Messages](<../../RS Permata Sehat/Message Doctor.png>) | Chat shows a placeholder. The inbox and conversation screens are planned. |
| Profile | [Profile Settings](<../../RS Permata Sehat/Profile Screen.png>) | Basic patient identity and logout are integrated in source. Personal information edits, security, and notification preferences are planned. |
| Authentication | Sign-in uses the app theme. | Patient login, session restoration, and Debug reachability are integrated in source. Registration UI is planned. |

## 6. API integration requirements

Use the [patient API contract](../../be-rumahsakit-swift/API_SPEC.md#kontrak-aplikasi-pasien-ios) with the relevant route, handler, and DTO. The design files describe presentation. API authorization and persisted state come from Vapor.

| Area | Client requirement |
| --- | --- |
| Session | Debug reachability uses `GET /health`. Sign-in calls `POST /api/auth/login`, then `GET /api/users/me` with Bearer authorization. Save the JWT in Keychain after confirming the account has the patient role. Vapor issues a JWT with a 24-hour expiry. During restoration or an authenticated Doctors or Appointments request, a `401` clears the rejected session. Temporary failures offer a retry. Logout clears the local token and works offline. [Auth handler](../../be-rumahsakit-swift/Sources/rumahsakit/Controllers/AuthController.swift) |
| Doctor payload | Demo doctor IDs and availability labels are UI values. Vapor provides UUIDs and an optional `nextAvailable` slot object. Handle optional profile fields and practice metadata. Use the doctor `id` for doctor details, schedules, and booking. Use the doctor `userId` as chat `receiverId`. [Doctor DTO](../../be-rumahsakit-swift/Sources/rumahsakit/DTOs/DoctorDTOs.swift#L25) |
| Schedules | Read the profile from `GET /api/doctors/:id` and weekly hours from `GET /api/schedules?doctorId=…`. Load the next 14 clinic days together from `GET /api/doctors/:id/availability?from=…&to=…`. Day changes filter that response locally. The server supports up to 31 inclusive days and sends 30-minute slots with an `available` flag. Clinic days and clock times use `YYYY-MM-DD` and `HH:mm` in `Asia/Jakarta`. |
| Booking | Send `doctorId`, `date`, `time`, `reason`, and optional `complaints` to `POST /api/appointments`. Reason and complaints each have a 255-byte limit. Display the server's status, ID, and reference number. Retry in the same form with the original payload and `Idempotency-Key`. When a slot is no longer bookable, return to refreshed availability. Read the patient's appointments with `GET /api/appointments`. [Appointment DTO](../../be-rumahsakit-swift/Sources/rumahsakit/DTOs/AppointmentDTOs.swift) |
| Appointment changes | A future appointment with status `pending` or `approved` can be changed. Reschedule reads 14 days of doctor availability and submits a new `date` and `time` via `PATCH /api/appointments/:id`. The updated appointment normally returns to `pending`. Cancellation sends `reason` and optional `note` via `POST /api/appointments/:id/cancellation-requests`. It displays `cancellation_requested` while staff reviews the request. Approval produces `cancelled`. |
| Status handling | Recognize `pending`, `approved`, `rejected`, `completed`, `cancellation_requested`, and `cancelled`. Render a neutral fallback for an unfamiliar status. Appointment updates are available through the in-app notification feed. |
| Notifications | Fetch `GET /api/notifications` when selecting Home and opening the inbox, or use Refresh. Derive the unread dot from `readAt`. Mark an item as read using `PUT /api/notifications/:id/read` and update the unread state after the server acknowledges the request. Vapor emits `approved`, `rejected`, `cancelled`, and `cancellation_declined` events. |
| Daily care plan | Fetch `GET /api/care-plan?date=…` using today's date in `Asia/Jakarta`. Track each dose by `recordId`, medication ID, date, and scheduled time. `PUT /api/care-plan/:recordId/:medicationId/taken` sends that entry's `date` and `time` and returns the saved `takenAt` in ISO 8601. Repeating the same request preserves the original intake timestamp. |
| Private documents and lab | Upload patient documents as multipart PDF, JPEG, or PNG with a maximum file size of 5 MiB. Use authorized download endpoints for private files. Show the lab PDF action when the published result includes its download path. |
| Presentation states | API-backed lists need loading, data, empty, and recoverable error states. Use API dates, availability, currency, statuses, and identifiers when the feature is integrated. Carry the server-created appointment from confirmation into refreshed history. |

## 7. Delivery sequence and verification

1. **Establish an authenticated connection.** API configuration, the shared client, sign-in, Keychain persistence, and a basic patient profile are integrated in source. iOS runtime verification is pending.
2. **Integrate Doctors and booking.** Directory, details, slot lookup, booking, and appointment history are wired in source. Verify on device that the server-created appointment appears in My Appointments with the same doctor, time, status, and reference shown in confirmation.
3. **Complete appointment management.** Rescheduling, cancellation requests, and the in-app notification inbox are wired in source. Device verification is pending.
4. **Expand patient features.** The dashboard and daily care plan are wired in source. Continue with Health Tracker, records and lab, documents, chat, and profile settings according to user priority.

When verification is requested, cover both doctor states, date changes, disabled slots, a blank visit reason, and a new appointment appearing in Upcoming. During API integration, also cover expired sessions, a conflicting slot, and document access boundaries. The Hurl suite verifies backend behavior. Record iOS build, Simulator, Preview, or device evidence separately with the revision and environment.

The My Appointments and MainTabView previews include synthetic appointment actions. The directory reads favorite status from Vapor and keeps toggle changes in memory for the app session. Builds, tests, debugging, Simulator runs, and Preview rendering require a user request. [Agent guide](AGENTS.md#verification-and-handoff)
