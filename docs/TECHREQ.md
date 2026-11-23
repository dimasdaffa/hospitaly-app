# Hospitaly — Technical Requirements

**RS Permata Sehat · 23 November 2026 · iOS snapshot `afe0bff`**

## 1. Product scope and sources

Hospitaly is a SwiftUI patient app for the RS Permata Sehat learning project. The first product flow takes a patient from a doctor directory to slot selection, the visit form, booking confirmation, and their appointment list. The current iOS flow uses local demo data. A separate integration milestone will connect it to the Vapor API.

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
| Presentation | SwiftUI, Observation through `@Observable`, a typed `NavigationStack`, and local `#Preview` fixtures. |
| Networking | [APIClient.swift](../Hospitaly/Core/Networking/APIClient.swift) is a Foundation-only scaffold. HTTP transport, auth and Keychain storage are planned. |
| Local backend | Vapor and MySQL behind Nginx. Docker Compose publishes the local API at `http://localhost:8081`. Use the Mac's reachable address when testing on a physical iPhone and HTTPS for a hosted API. [Compose configuration](../../be-rumahsakit-swift/docker-compose.yml) |
| Local design system | `Theme.swift` holds semantic colors. `ClinicDate.swift` formats clinic dates and times in `Asia/Jakarta`. Bundled sample portraits live in the app asset catalog. |

## 3. Architecture and current source layout

The architecture is feature-first MVVM–Service. A **View** renders state and receives input. A **ViewModel** owns feature state and coordinates actions. A **Service** owns endpoint selection and request or response mapping. The shared **APIClient** will handle HTTP transport, headers, status handling, and decoding. Add a service when its first API-backed flow needs it.

```text
Hospitaly/                                  # iOS repository root
├── Hospitaly.xcodeproj/
│   └── project.xcproj                      # App target and build settings
├── Hospitaly/                              # Source folder included in the app target
│   ├── App/
│   │   └── HospitalyApp.swift               # App entry, currently opens the doctor directory
│   ├── Assets.xcassets/                     # App assets and bundled demo portraits
│   ├── Core/Networking/
│   │   └── APIClient.swift                  # Transport scaffold
│   ├── Features/
│   │   ├── Doctors/
│   │   │   ├── Models/
│   │   │   │   ├── Doctor.swift             # Doctor display model and local fixtures
│   │   │   │   └── DoctorRoute.swift        # Doctor and appointment destinations
│   │   │   ├── ViewModels/
│   │   │   │   ├── DoctorListViewModel.swift   # Search, filters, and local favorites
│   │   │   │   └── DoctorDetailViewModel.swift # Dates, demo slots, and selection
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
│   │   │           ├── DoctorScheduleView.swift       # Date and slot controls
│   │   │           ├── DoctorWeeklyScheduleView.swift # Reference hours for a full doctor
│   │   │           └── DoctorBookingBar.swift         # Selected slot, fee, and continue action
│   │   └── Appointments/
│   │       ├── Models/
│   │       │   ├── Appointment.swift         # Demo appointment, status, and reference
│   │       │   └── AppointmentSlot.swift     # Start, end, availability, and display labels
│   │       └── Views/
│   │           ├── BookingFormView.swift         # Visit reason, optional complaints, and submit
│   │           ├── BookingConfirmationView.swift # Pending request and next actions
│   │           ├── MyAppointmentsView.swift      # Upcoming and history
│   │           └── Components/
│   │               ├── AppointmentCardView.swift    # Appointment list row
│   │               ├── AppointmentStatusBadge.swift # Status styling
│   │               └── AppointmentSummaryView.swift # Doctor and chosen time
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
| Start and navigate the demo | [HospitalyApp.swift](../Hospitaly/App/HospitalyApp.swift) | [DoctorListView.swift](../Hospitaly/Features/Doctors/Views/DoctorListView.swift) owns the navigation path and in-memory appointment collection. |
| Search, filter, and favorite doctors | [DoctorListView.swift](../Hospitaly/Features/Doctors/Views/DoctorListView.swift) | [DoctorListViewModel.swift](../Hospitaly/Features/Doctors/ViewModels/DoctorListViewModel.swift) owns the filters and favorites. [Doctor.swift](../Hospitaly/Features/Doctors/Models/Doctor.swift) provides the fixtures. |
| Pick a date and slot | [DoctorDetailView.swift](../Hospitaly/Features/Doctors/Views/DoctorDetailView.swift) | [DoctorDetailViewModel.swift](../Hospitaly/Features/Doctors/ViewModels/DoctorDetailViewModel.swift) derives demo availability, blocks occupied slots and clears the selected slot when the day changes. [DoctorAvatarView.swift](../Hospitaly/Features/Doctors/Views/Components/DoctorAvatarView.swift) applies grayscale in both list and detail when a doctor is unavailable. |
| Submit a booking request | [BookingFormView.swift](../Hospitaly/Features/Appointments/Views/BookingFormView.swift) | The form owns input and validation. The directory's navigation host creates the pending local appointment and passes it to [BookingConfirmationView.swift](../Hospitaly/Features/Appointments/Views/BookingConfirmationView.swift). |
| View appointments again | [MyAppointmentsView.swift](../Hospitaly/Features/Appointments/Views/MyAppointmentsView.swift) | The view groups demo appointments by status and time. It opens from confirmation or the calendar button in the directory. |

## 4. Planned source additions

Every path below is **planned**. These are proposed names and ownership boundaries for implementation. The current Doctors and Appointments views stay in their existing folders as integration is added. The names under a feature's `Views/`, `ViewModels/`, `Models/`, and `Services/` follow the same pattern shown in the current tree.

```text
Hospitaly/
├── Hospitaly/
│   ├── App/
│   │   ├── AppConfig.swift                     # Local and hosted API base URLs
│   │   ├── RootView.swift                      # Loading, signed-out, and signed-in entry
│   │   ├── SessionStore.swift                  # Authenticated session and logout state
│   │   ├── MainTabView.swift                   # Home, Doctors, Chat, and Profile
│   │   └── QuickAccessSheet.swift              # Local shortcuts to patient features
│   ├── Core/
│   │   ├── Networking/APIError.swift           # Transport, HTTP, and decoding errors
│   │   └── Security/TokenStore.swift           # Keychain storage for the session token
│   ├── Features/
│   │   ├── Auth/
│   │   │   ├── Views/LoginView.swift           # Patient sign-in form
│   │   │   ├── ViewModels/LoginViewModel.swift  # Validation, state, and sign-in action
│   │   │   ├── Models/LoginRequest.swift       # Login payload
│   │   │   ├── Models/LoginResponse.swift      # Token and account response
│   │   │   └── Services/AuthService.swift      # Login, logout, and change password
│   │   ├── Profile/
│   │   │   ├── Views/ProfileView.swift         # Patient identity and settings entry
│   │   │   ├── Views/PersonalInfoView.swift    # Edit personal information
│   │   │   ├── Views/SecuritySettingsView.swift # Change password form
│   │   │   ├── ViewModels/ProfileViewModel.swift # Profile fetching and edits
│   │   │   ├── Models/UserProfile.swift        # Patient profile response
│   │   │   └── Services/ProfileService.swift   # Read and update /api/users/me
│   │   ├── Doctors/
│   │   │   ├── Models/DoctorResponse.swift     # Decode the Vapor doctor and map to the UI
│   │   │   └── Services/DoctorService.swift    # Directory, details, availability, and favorites
│   │   ├── Appointments/
│   │   │   ├── Views/RescheduleView.swift              # Select a replacement slot
│   │   │   ├── Views/CancelAppointmentView.swift       # Cancellation reason and optional note
│   │   │   ├── Views/CancellationSubmittedView.swift   # Confirm an awaiting cancellation request
│   │   │   ├── ViewModels/BookingViewModel.swift       # Submit and handle a slot conflict
│   │   │   ├── ViewModels/AppointmentsViewModel.swift  # Fetch and update appointment history
│   │   │   ├── Models/BookingRequest.swift             # Create appointment payload
│   │   │   ├── Models/CancellationRequest.swift        # Cancellation request payload
│   │   │   └── Services/AppointmentService.swift       # Booking, list, detail, and change requests
│   │   ├── Home/                                       # Dashboard and next appointment
│   │   │   ├── Views/HomeView.swift                     # Patient dashboard
│   │   │   ├── Views/CarePlanView.swift                 # Today's doses and Mark as Taken
│   │   │   ├── ViewModels/HomeViewModel.swift           # Compose dashboard data
│   │   │   ├── Models/CarePlanEntry.swift               # Scheduled dose
│   │   │   └── Services/CarePlanService.swift           # Daily plan and taken-dose updates
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
│   │       ├── Views/NotificationsView.swift            # In-app appointment updates
│   │       ├── Views/NotificationSettingsView.swift     # Appointment notification preferences
│   │       ├── ViewModels/NotificationsViewModel.swift  # Inbox and read state
│   │       ├── Models/PatientNotification.swift         # In-app notification response
│   │       └── Services/NotificationService.swift       # Inbox, mark read, and preferences
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
| Doctor directory and details | [Search](<../../RS Permata Sehat/Doctor Search List.png>) · [Available](<../../RS Permata Sehat/Doctor Details.png>) · [Full](<../../RS Permata Sehat/Doctor Details Not Avail.png>) | Local prototype with search, filters, favorites, available/full states, and date and slot selection. |
| Booking and history | [Visit form](<../../RS Permata Sehat/Appointment Details.png>) · [Confirmation](<../../RS Permata Sehat/Make Appointment.png>) · [My Appointments](<../../RS Permata Sehat/Manage Appointment.png>) | Local prototype. A booking creates a pending appointment in memory and carries the chosen slot across screens. |
| Reschedule and cancellation | [Dashboard action](<../../RS Permata Sehat/Patient Dashboard.png>) · [Cancellation form](<../../RS Permata Sehat/Cancel Appointment.png>) · [Cancellation alert](<../../RS Permata Sehat/Cancellation Alert.png>) | Design references and backend available. Client actions are planned. |
| Dashboard, care plan, and shortcuts | [Dashboard](<../../RS Permata Sehat/Patient Dashboard.png>) · [Quick Access](<../../RS Permata Sehat/Quick Access.png>) | Design references and backend available for patient data. Quick Access will use local navigation. |
| Medical records and lab | [Records](<../../RS Permata Sehat/Medical Record List.png>) · [Diagnosis](<../../RS Permata Sehat/Diagnosis Details.png>) · [Lab](<../../RS Permata Sehat/Lab Result.png>) | Design references and backend available. The lab PDF comes from a staff-published attachment. |
| Patient documents and BPJS | [Documents](<../../RS Permata Sehat/Document Screen.png>) · [Upload](<../../RS Permata Sehat/Upload Docs.png>) | Design references and backend available for document CRUD, history, multipart upload, and private downloads. |
| Health tracker and vital entry | [Blood pressure](<../../RS Permata Sehat/My Health.png>) · [Weight](<../../RS Permata Sehat/My Health-1.png>) · [Heart rate](<../../RS Permata Sehat/My Health-2.png>) · [BP entry](<../../RS Permata Sehat/Entry BP.png>) · [Weight entry](<../../RS Permata Sehat/Entry Weight.png>) · [Heart rate entry](<../../RS Permata Sehat/Entry Heart Rate.png>) | Design references and backend available. The client will build chart summaries from readings. |
| Messages and profile | [Messages](<../../RS Permata Sehat/Message Doctor.png>) · [Profile](<../../RS Permata Sehat/Profile Screen.png>) | Design references and backend available. Profile settings include account security and appointment notification preferences. |
| Authentication | Patient sign-in and registration UI are planned. | Public auth endpoints are available in Vapor. The iOS session and entry flow are planned. |

## 6. API integration requirements

Use the [patient API contract](../../be-rumahsakit-swift/API_SPEC.md#kontrak-aplikasi-pasien-ios) with the relevant route, handler, and DTO. The design files describe presentation. API authorization and persisted state come from Vapor.

| Area | Client requirement |
| --- | --- |
| Session | Begin with `GET /health` for connectivity. Use `POST /api/auth/login`, store the JWT in Keychain, and send Bearer authorization to protected endpoints, including doctor and schedule reads. Read the active profile with `GET /api/users/me`. Vapor issues a JWT with a 24-hour expiry. Return to sign-in when a protected request shows the session is invalid. [Auth handler](../../be-rumahsakit-swift/Sources/rumahsakit/Controllers/AuthController.swift) |
| Doctor payload | Demo doctor IDs and availability labels are UI values. Vapor provides UUIDs and an optional `nextAvailable` slot object. Handle optional profile fields and practice metadata. Use the doctor `id` for doctor details, schedules, and booking. Use the doctor `userId` as chat `receiverId`. [Doctor DTO](../../be-rumahsakit-swift/Sources/rumahsakit/DTOs/DoctorDTOs.swift#L25) |
| Schedules | Read weekly hours from `GET /api/schedules?doctorId=…`. Read actual slots from `GET /api/doctors/:id/availability?from=…&to=…`. The server accepts an inclusive range of up to 31 days and returns 30-minute slots with an `available` flag. Clinic days and clock times are `YYYY-MM-DD` and `HH:mm` in `Asia/Jakarta`. JSON timestamps use ISO 8601. |
| Booking | Send `doctorId`, `date`, `time`, `reason`, and optional `complaints` to `POST /api/appointments`. Display the server's status, ID, and reference number. Reuse an `Idempotency-Key` when retrying the same booking submission. On `409`, reload availability and let the patient choose a different slot. [Appointment DTO](../../be-rumahsakit-swift/Sources/rumahsakit/DTOs/AppointmentDTOs.swift) |
| Appointment changes | Reschedule sends `date` and `time` via `PATCH /api/appointments/:id` and returns `pending`. The cancellation form sends `reason` and optional `note` to `POST /api/appointments/:id/cancellation-requests`. It shows `cancellation_requested` until staff decides. Approval produces `cancelled`. Use this workflow for the cancellation mockups. |
| Status handling | Recognize `pending`, `approved`, `rejected`, `completed`, `cancellation_requested`, and `cancelled`. Render a neutral fallback for an unfamiliar status. Appointment updates are available through the in-app notification feed. |
| Private documents and lab | Upload patient documents as multipart PDF, JPEG, or PNG with a maximum file size of 5 MiB. Use authorized download endpoints for private files. Show the lab PDF action when the published result includes its download path. |
| Presentation states | API-backed lists need loading, data, empty, and recoverable error states. Use API dates, availability, currency, statuses, and identifiers when the feature is integrated. Carry the server-created appointment from confirmation into refreshed history. |

## 7. Delivery sequence and verification

1. **Establish an authenticated connection.** Add configuration, the shared client, sign-in, Keychain persistence, and a basic patient profile.
2. **Integrate Doctors and booking.** Replace directory and detail fixtures, then connect slot lookup and booking. The server-created appointment must appear in My Appointments with the same doctor, time, status, and reference shown in confirmation.
3. **Complete appointment management.** Connect rescheduling, cancellation requests, history, and in-app notification status.
4. **Expand patient features.** Add the dashboard and care plan, then Health Tracker, records and lab, documents, chat, and profile settings according to user priority.

When verification is requested, cover both doctor states, date changes, disabled slots, a blank visit reason, and a new appointment appearing in Upcoming. During API integration, also cover expired sessions, a conflicting slot, and document access boundaries. The Hurl suite verifies backend behavior. Record iOS build, Simulator, Preview, or device evidence separately with the revision and environment.

The current snapshot describes source. Doctor schedules, prices, portraits, and references are demo values. New appointments and favorites live in memory for the app session. Builds, tests, debugging, Simulator runs, and Preview rendering require a user request. [Agent guide](AGENTS.md#verification-and-handoff)
