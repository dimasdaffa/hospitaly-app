# Hospitaly — Technical Requirements

**RS Permata Sehat · 27 November 2026 · iOS working tree**

## 1. Product scope and sources

Hospitaly is a SwiftUI patient app for the RS Permata Sehat learning project. The signed-in shell opens on Home and has Doctors, Chat, and Profile tabs with a central Quick Access button. The app connects to Vapor for appointments, the care plan, vitals, clinical history, patient messages, and account settings. Home features the next appointment, doctor search, care shortcuts, and today's scheduled doses.

| Question | Source of truth |
| --- | --- |
| What does the iOS project currently implement? | [Hospitaly source](../Hospitaly/) and the feature owners in [Architecture](#3-architecture-and-current-source-layout). |
| What should the screens look like? | [RS Permata Sehat mockups](<../../RS Permata Sehat/>). Names, prices, dates, and results in the images are design examples. |
| What guides the redesign? | [Hospitaly design direction](DESIGN.md) defines the crimson glass theme and dashboard rollout. |
| What does the backend accept and return? | [Patient API contract](../../be-rumahsakit-swift/API_SPEC.md#kontrak-aplikasi-pasien-ios), [Vapor routes](../../be-rumahsakit-swift/Sources/rumahsakit/routes.swift), and the relevant handlers and DTOs. |
| How is HTTP behavior verified? | [Backend Hurl suite](../../be-rumahsakit-swift/Tests/hurl/README.md). |
| What conventions apply to future work? | [Hospitaly agent guide](AGENTS.md). |

The mockup folder, iOS repo, and Vapor repo are siblings in the current workspace. Cross-project links assume that layout.

## 2. Technology and configuration

| Area | Current configuration |
| --- | --- |
| Xcode | The `Hospitaly` app target uses bundle ID `com.dimasdaffa.Hospitaly` and an iOS 27.2 deployment target. The project sets `SWIFT_VERSION = 5.0`, `MainActor` default isolation, and approachable concurrency. The configured language mode and installed compiler are separate settings. [Project file](../Hospitaly.xcodeproj/project.xcproj) |
| Presentation | SwiftUI, Observation through `@Observable`, typed navigation, a custom tab bar, and local `#Preview` fixtures. |
| Loading animation | Lottie via Swift Package Manager. The Hospitaly target bundles `Resources/Animations/loading.json`. |
| Networking | [APIClient.swift](../Hospitaly/Core/Networking/APIClient.swift) sends HTTP requests using `URLSession`, adds Bearer authorization when requested, and decodes JSON responses. Session tokens are stored in Keychain per API base URL. |
| Local backend | Vapor and MySQL behind Nginx. Docker Compose publishes the API at `http://localhost:8081`, the default for the Debug build in Simulator. [Compose configuration](../../be-rumahsakit-swift/docker-compose.yml) |
| Local design system | `Theme.swift` holds semantic colors, dashboard spacing, and shared glass surfaces. `ClinicDate.swift` formats clinic dates and times in `Asia/Jakarta`. Bundled sample portraits live in the app asset catalog. |

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
│   │   │   │   ├── LoginResponse.swift      # JWT field from the login response
│   │   │   │   ├── AccountInput.swift       # Client validation for email and new passwords
│   │   │   │   ├── RegisterRequest.swift    # Patient-only account creation payload
│   │   │   │   └── ChangePasswordRequest.swift # Current and new password payload
│   │   │   ├── Services/AuthService.swift   # Login, registration, password, and reachability calls
│   │   │   ├── ViewModels/
│   │   │   │   ├── LoginViewModel.swift     # Login form and registration handoff
│   │   │   │   └── RegisterViewModel.swift  # Account creation validation and request feedback
│   │   │   └── Views/
│   │   │       ├── LoginView.swift          # Patient sign-in form
│   │   │       └── RegisterView.swift       # Patient registration form
│   │   ├── Profile/
│   │   │   ├── Models/
│   │   │   │   ├── UserProfile.swift          # Authenticated patient identity and biodata
│   │   │   │   ├── ProfileUpdateRequest.swift # Changed profile fields
│   │   │   │   ├── ProfilePhoto.swift         # Selected image thumbnail and JPEG upload
│   │   │   │   ├── HelpTopic.swift            # Server-provided question and answer
│   │   │   │   └── ProfileSettingsActions.swift # Authenticated settings callbacks
│   │   │   ├── Services/ProfileService.swift  # Read and update biodata, upload photo, and fetch help
│   │   │   ├── ViewModels/
│   │   │   │   ├── ProfileViewModel.swift      # Biodata and profile photo edits
│   │   │   │   └── ChangePasswordViewModel.swift # Password form and confirmation
│   │   │   └── Views/
│   │   │       ├── ProfileView.swift          # Account settings navigation and logout
│   │   │       ├── PersonalInfoView.swift     # Edit biodata and choose a photo
│   │   │       ├── SecuritySettingsView.swift # Change password
│   │   │       ├── HelpCenterView.swift      # Browse help topics
│   │   │       └── Components/ProfileAvatar.swift # Profile photo and fallback
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
│   │   │       ├── AppointmentChangeConfirmationView.swift # Show the server result of rescheduling or cancellation
│   │   │       └── Components/
│   │   │           ├── AppointmentCardView.swift    # Featured upcoming visit and compact history row
│   │   │           ├── AppointmentSlotPicker.swift  # Date and slot controls shared with Doctors
│   │   │           ├── AppointmentStatusBadge.swift # Status styling
│   │   │           └── AppointmentSummaryView.swift # Doctor, time, location, and server visit metadata
│   │   ├── Home/
│   │   │   ├── Models/
│   │   │   │   ├── CarePlanActions.swift              # Authenticated reads and dose updates
│   │   │   │   └── CarePlanEntry.swift                # Scheduled medication dose and taken time
│   │   │   ├── Services/CarePlanService.swift         # Fetch daily plan and record doses
│   │   │   ├── ViewModels/
│   │   │   │   ├── HomeViewModel.swift                # Load and select the next appointment
│   │   │   │   └── CarePlanViewModel.swift            # Daily loading, error, and saving state
│   │   │   └── Views/
│   │   │       ├── HomeView.swift                    # Crimson dashboard, next visit, search, and shortcuts
│   │   │       ├── CarePlanView.swift                # Scheduled doses and Mark as Taken
│   │   │       └── Components/
│   │   │           └── HomeAppointmentCardView.swift # Next visit date, status, and actions
│   │   ├── HealthTracker/
│   │   │   ├── Models/
│   │   │   │   ├── HealthMetric.swift                  # Metric filters, units, and display formatting
│   │   │   │   ├── HealthReading.swift                 # Decode a reading and resolve its timestamp
│   │   │   │   ├── HealthReadingRequest.swift          # Create one vital measurement
│   │   │   │   └── HealthTrackerActions.swift           # Authenticated load and save callbacks
│   │   │   ├── Services/HealthService.swift             # Fetch and log health updates
│   │   │   ├── ViewModels/
│   │   │   │   ├── HealthTrackerViewModel.swift          # Date filters and reading state
│   │   │   │   └── LogVitalViewModel.swift               # Wheel values, previous readings, and save state
│   │   │   └── Views/
│   │   │       ├── HealthTrackerView.swift               # Metric tabs, date ranges, and history
│   │   │       ├── LogVitalView.swift                    # Bottom sheet for entering one measurement
│   │   │       └── Components/
│   │   │           ├── VitalChartView.swift              # Selectable trend chart and summary tiles
│   │   │           ├── VitalLogRow.swift                 # Value, unit, and date of a reading
│   │   │           ├── VitalMetricTabs.swift             # Metric switcher for the tracker and entry sheet
│   │   │           └── VitalNumberWheel.swift            # Scrollable numeric input with centered selection
│   │   ├── MedicalRecords/
│   │   │   ├── Models/
│   │   │   │   ├── MedicalRecord.swift                 # Diagnosis, vaccination, visit, and prescriptions
│   │   │   │   ├── LabResult.swift                     # Published lab report, panels, and measurements
│   │   │   │   ├── MedicalRecordEntry.swift            # Combined timeline entry and typed detail route
│   │   │   │   ├── MedicalRecordsActions.swift         # Authenticated record and file actions
│   │   │   │   ├── RecordAttachment.swift              # Clinical attachment metadata
│   │   │   │   └── MedicalRecordsPreviewData.swift     # Synthetic records and action fixtures
│   │   │   ├── Services/MedicalRecordsService.swift    # Fetch history, details, attachments, and private files
│   │   │   ├── ViewModels/MedicalRecordsViewModel.swift # Search, filter, and group the combined history
│   │   │   └── Views/
│   │   │       ├── MedicalRecordsView.swift            # Last visit, filters, and monthly history
│   │   │       ├── DiagnosisDetailView.swift           # Clinical details, attachments, and follow-up
│   │   │       ├── LabResultDetailView.swift           # Lab panels, staff note, and PDF export
│   │   │       └── Components/
│   │   │           └── MedicalRecordCard.swift         # Timeline row for a record or lab result
│   │   ├── Documents/
│   │   │   ├── Models/
│   │   │   │   ├── DocumentCategory.swift              # Insurance, identity, and supporting file categories
│   │   │   │   ├── PatientDocument.swift               # Listed metadata and private download reference
│   │   │   │   ├── UploadDocumentFile.swift            # Coordinated file read, byte limit, and type check
│   │   │   │   ├── DocumentDraft.swift                  # Validated metadata and optional file bytes
│   │   │   │   ├── DocumentsActions.swift              # Authenticated file operations
│   │   │   │   └── DocumentsPreviewData.swift          # Synthetic files and in-memory mutation fixture
│   │   │   ├── Services/DocumentService.swift           # List, history, uploads, updates, and downloads
│   │   │   ├── ViewModels/
│   │   │   │   ├── DocumentsViewModel.swift             # List loading and confirmed mutations
│   │   │   │   └── UploadDocumentViewModel.swift        # Create and edit drafts, file selection, and confirmation
│   │   │   └── Views/
│   │   │       ├── DocumentsView.swift                # Insurance, recent files, and management actions
│   │   │       ├── UploadDocumentView.swift           # Shared create and edit form
│   │   │       ├── DocumentHistoryView.swift          # Active and deleted document history
│   │   │       └── Components/DocumentCategoryIcon.swift # Category icon and color
│   │   ├── Messages/
│   │   │   ├── Models/
│   │   │   │   ├── Conversation.swift                    # Inbox row, latest message, and unread count
│   │   │   │   ├── Message.swift                         # Authenticated message payload
│   │   │   │   ├── MessagePeer.swift                     # Account ID and conversation destination
│   │   │   │   ├── MessageActions.swift                  # Authenticated inbox and thread callbacks
│   │   │   │   └── MessagePreviewData.swift              # Synthetic inbox and thread fixtures
│   │   │   ├── Services/MessageService.swift             # Search, pagination, send, and mark as read
│   │   │   ├── ViewModels/
│   │   │   │   ├── InboxViewModel.swift                   # Shared unread state and server-backed search
│   │   │   │   └── ConversationViewModel.swift            # History, draft, and delivery state
│   │   │   └── Views/
│   │   │       ├── InboxView.swift                        # Searchable conversation list
│   │   │       ├── ConversationView.swift                 # Message bubbles, older pages, and composer
│   │   │       ├── MessageDoctorPickerView.swift          # Choose a doctor with a linked account
│   │   │       └── Components/
│   │   │           ├── ConversationRow.swift             # Preview, time, and unread badge
│   │   │           └── MessageAvatar.swift               # Portrait and missing-image fallback
│   │   └── Notifications/
│   │       ├── Models/PatientNotification.swift       # Notification identity, event, and read state
│   │       ├── Models/AppointmentNotificationSettings.swift # Appointment preference payload
│   │       ├── Services/NotificationService.swift     # Inbox, read state, and preferences
│   │       ├── ViewModels/NotificationsViewModel.swift # Inbox loading and unread badge state
│   │       ├── ViewModels/NotificationSettingsViewModel.swift # Preference loading and save
│   │       ├── Views/NotificationsView.swift          # Patient appointment notification inbox
│   │       └── Views/NotificationSettingsView.swift   # Appointment notification preference
│   └── Shared/
│       ├── Logic/
│       │   ├── ClinicDate.swift               # Clinic time zone and date formatting
│       │   └── PrivateDocumentDownload.swift  # Authenticated download descriptor and safe filename
│       └── UI/
│           ├── Theme.swift                    # Color palette, layout tokens, and glass surfaces
│           ├── Components/
│           │   ├── CrimsonHeaderBackdrop.swift # Crimson gradient and curved highlights
│           │   ├── LoadingStateView.swift       # Bundled Lottie loop with a system progress fallback
│           │   ├── PrimaryActionButton.swift    # Shared primary action button
│           │   └── RefreshFailureView.swift     # Recoverable error above previously loaded content
│           └── FileExport/
│               ├── PrivateExportDocument.swift    # SwiftUI document writer for downloaded bytes
│               └── PrivateFileExportModifier.swift # Download status, Files exporter, and errors
└── docs/
    ├── TECHREQ.md                          # Product and implementation reference
    ├── DESIGN.md                           # Crimson glass redesign and rollout
    └── AGENTS.md                           # Working conventions
```

| Behavior | Entry point | Current owner |
| --- | --- | --- |
| Sign in and restore the session | [RootView.swift](../Hospitaly/App/RootView.swift) | [SessionStore.swift](../Hospitaly/App/SessionStore.swift) owns sign-in, the loaded profile, and Keychain restoration. [LoginViewModel.swift](../Hospitaly/Features/Auth/ViewModels/LoginViewModel.swift) owns the form state and request feedback. |
| Edit the patient profile and account settings | [ProfileView.swift](../Hospitaly/Features/Profile/Views/ProfileView.swift) | [ProfileViewModel.swift](../Hospitaly/Features/Profile/ViewModels/ProfileViewModel.swift) builds biodata and photo changes. [SessionStore.swift](../Hospitaly/App/SessionStore.swift) applies the confirmed profile across tabs, changes passwords, and clears the token at logout. Settings also link to documents, appointment notification preferences, and Help Center. |
| Create a patient account | Create Patient Account in [LoginView.swift](../Hospitaly/Features/Auth/Views/LoginView.swift) | [RegisterViewModel.swift](../Hospitaly/Features/Auth/ViewModels/RegisterViewModel.swift) validates the form and hands the registered email back to sign-in after Vapor confirms creation. |
| Open tabs and Quick Access | [MainTabBar.swift](../Hospitaly/App/Navigation/MainTabBar.swift) | [MainTabView.swift](../Hospitaly/App/Navigation/MainTabView.swift) owns the selected tab, the Doctors navigation path, and [QuickAccessSheet.swift](../Hospitaly/App/Navigation/QuickAccessSheet.swift) presentation. The custom bar appears at tab roots. |
| Navigate Doctors | Doctors tab or Quick Access in [MainTabView.swift](../Hospitaly/App/Navigation/MainTabView.swift) | [DoctorListView.swift](../Hospitaly/Features/Doctors/Views/DoctorListView.swift) uses the shared path to open details, booking, confirmation, and appointments. |
| Load, search, filter, and favorite doctors | [DoctorListView.swift](../Hospitaly/Features/Doctors/Views/DoctorListView.swift) | [DoctorService.swift](../Hospitaly/Features/Doctors/Services/DoctorService.swift) reads and writes favorites in Vapor. [DoctorListViewModel.swift](../Hospitaly/Features/Doctors/ViewModels/DoctorListViewModel.swift) owns loading, filters, and the confirmed favorite state. |
| Load a doctor and pick a slot | [DoctorDetailView.swift](../Hospitaly/Features/Doctors/Views/DoctorDetailView.swift) | [DoctorService.swift](../Hospitaly/Features/Doctors/Services/DoctorService.swift) loads the profile, slots, and weekly hours. [DoctorDetailViewModel.swift](../Hospitaly/Features/Doctors/ViewModels/DoctorDetailViewModel.swift) filters the loaded slots by clinic date, blocks unavailable slots, and clears the selection when the day changes. [DoctorAvatarView.swift](../Hospitaly/Features/Doctors/Views/Components/DoctorAvatarView.swift) styles unavailable doctors in grayscale. |
| Submit a booking request | [BookingFormView.swift](../Hospitaly/Features/Appointments/Views/BookingFormView.swift) | [BookingViewModel.swift](../Hospitaly/Features/Appointments/ViewModels/BookingViewModel.swift) validates input and reuses the submission on retry. [AppointmentService.swift](../Hospitaly/Features/Appointments/Services/AppointmentService.swift) sends it to Vapor. [BookingConfirmationView.swift](../Hospitaly/Features/Appointments/Views/BookingConfirmationView.swift) displays the returned appointment. |
| View appointments again | [MyAppointmentsView.swift](../Hospitaly/Features/Appointments/Views/MyAppointmentsView.swift) | [AppointmentsViewModel.swift](../Hospitaly/Features/Appointments/ViewModels/AppointmentsViewModel.swift) loads patient appointments. The view groups them by status and time. It opens from confirmation, the directory calendar, or Quick Access. |
| Change an appointment | Actions on upcoming cards or in [Appointment Details](../Hospitaly/Features/Appointments/Views/AppointmentDetailView.swift) after tapping a card | [RescheduleView.swift](../Hospitaly/Features/Appointments/Views/RescheduleView.swift) loads replacement times. [CancelAppointmentView.swift](../Hospitaly/Features/Appointments/Views/CancelAppointmentView.swift) collects the reason and shows the submission result. [AppointmentsViewModel.swift](../Hospitaly/Features/Appointments/ViewModels/AppointmentsViewModel.swift) applies the returned appointment by ID. |
| Read appointment updates | Bell on Home in [MainTabView.swift](../Hospitaly/App/Navigation/MainTabView.swift) | [NotificationsViewModel.swift](../Hospitaly/Features/Notifications/ViewModels/NotificationsViewModel.swift) shares unread and loading state between the bell and [NotificationsView.swift](../Hospitaly/Features/Notifications/Views/NotificationsView.swift). |
| Open the dashboard and next visit | [HomeView.swift](../Hospitaly/Features/Home/Views/HomeView.swift) | [HomeViewModel.swift](../Hospitaly/Features/Home/ViewModels/HomeViewModel.swift) selects the earliest upcoming start from patient appointments. The card opens details or reschedule. [MainTabView.swift](../Hospitaly/App/Navigation/MainTabView.swift) forwards Home search to the doctor directory and opens existing patient features through care shortcuts. |
| View today's care plan and record a dose | [CarePlanView.swift](../Hospitaly/Features/Home/Views/CarePlanView.swift) on Home | [CarePlanViewModel.swift](../Hospitaly/Features/Home/ViewModels/CarePlanViewModel.swift) loads the clinic's current day and applies the response for the same scheduled dose. [CarePlanService.swift](../Hospitaly/Features/Home/Services/CarePlanService.swift) calls Vapor. |
| Review and log vitals | Health Tracker in [QuickAccessSheet.swift](../Hospitaly/App/Navigation/QuickAccessSheet.swift) | [HealthTrackerViewModel.swift](../Hospitaly/Features/HealthTracker/ViewModels/HealthTrackerViewModel.swift) filters and loads readings. [LogVitalViewModel.swift](../Hospitaly/Features/HealthTracker/ViewModels/LogVitalViewModel.swift) validates input and submits the selected metric through [HealthService.swift](../Hospitaly/Features/HealthTracker/Services/HealthService.swift). |
| Review medical records and lab reports | Records in [QuickAccessSheet.swift](../Hospitaly/App/Navigation/QuickAccessSheet.swift) | [MedicalRecordsViewModel.swift](../Hospitaly/Features/MedicalRecords/ViewModels/MedicalRecordsViewModel.swift) searches and groups the timeline. [MedicalRecordsService.swift](../Hospitaly/Features/MedicalRecords/Services/MedicalRecordsService.swift) fetches the patient’s records and handles authenticated clinical downloads. |
| Message a doctor | Chat tab, Quick Access, or Chat Doctor in [DiagnosisDetailView.swift](../Hospitaly/Features/MedicalRecords/Views/DiagnosisDetailView.swift) | [InboxViewModel.swift](../Hospitaly/Features/Messages/ViewModels/InboxViewModel.swift) owns the inbox and unread badge. [ConversationViewModel.swift](../Hospitaly/Features/Messages/ViewModels/ConversationViewModel.swift) loads pages, sends a draft, and marks received messages as read through [MessageService.swift](../Hospitaly/Features/Messages/Services/MessageService.swift). |
| Manage uploaded patient files | Documents & BPJS in [ProfileView.swift](../Hospitaly/Features/Profile/Views/ProfileView.swift) | [DocumentsViewModel.swift](../Hospitaly/Features/Documents/ViewModels/DocumentsViewModel.swift) loads current documents or history and applies confirmed mutations. [UploadDocumentViewModel.swift](../Hospitaly/Features/Documents/ViewModels/UploadDocumentViewModel.swift) validates drafts and checks unconfirmed saves. |

## 4. Planned source additions

Every path below is **planned**. These are proposed names and ownership boundaries for implementation. The current Doctors and Appointments views stay in their existing folders as integration is added. The names under a feature's `Views/`, `ViewModels/`, `Models/`, and `Services/` follow the same pattern shown in the current tree.

Password recovery needs backend support for issuing and consuming reset tokens and sending the recovery email.

```text
Hospitaly/
├── Hospitaly/
│   └── Shared/UI/Components/LoadErrorView.swift           # Reusable retry state when screens need it
└── HospitalyTests/                                      # Add a test target when asked
    ├── LoginViewModelTests.swift
    ├── DoctorListViewModelTests.swift
    └── Fixtures/doctors.json                            # Synthetic doctor response for tests
```

## 5. UI scope and implementation status

**Local prototype** means the SwiftUI source contains the screen or interaction using fixtures. **Design reference** means the mockup is available and the iOS screen is planned. **Backend available** means the Vapor contract exists. These labels describe implementation scope. Runtime verification is recorded separately.

| Flow | Design references | iOS status |
| --- | --- | --- |
| Doctor directory and details | [Search](<../../RS Permata Sehat/Doctor Search List.png>) · [Available](<../../RS Permata Sehat/Doctor Details.png>) · [Full](<../../RS Permata Sehat/Doctor Details Not Avail.png>) | Directory, saved favorites, profile details, weekly practice hours, and slot selection are integrated in source. The detail screen shows retry on failure, an empty state for dates without slots, and weekly hours when no slots can be booked. Missing photos and missing weekly schedules have placeholders. |
| Booking and history | [Visit form](<../../RS Permata Sehat/Appointment Details.png>) · [Confirmation](<../../RS Permata Sehat/Make Appointment.png>) · [My Appointments](<../../RS Permata Sehat/Manage Appointment.png>) | Booking and appointment history are wired to Vapor. Confirmation uses server identity, status, and reference. My Appointments groups server results into Upcoming and History, with empty and failed states. A slot conflict offers a return to refreshed availability. |
| Reschedule and cancellation | [Dashboard action](<../../RS Permata Sehat/Patient Dashboard.png>) · [Cancellation form](<../../RS Permata Sehat/Cancel Appointment.png>) · [Cancellation alert](<../../RS Permata Sehat/Cancellation Alert.png>) | Upcoming Pending and Approved cards offer both actions, and Home can open reschedule for the next eligible visit. The replacement picker handles empty schedules and conflicts. Cancellation shows the requested state until hospital review. |
| Appointment notifications | Bell in [Patient Dashboard](<../../RS Permata Sehat/Patient Dashboard.png>) | The Home bell shows an unread dot. The inbox supports refresh, retry, empty state, and marking an item as read. |
| Dashboard and care plan | [Crimson glass dashboard](DESIGN.md#home-layout-and-behavior) | Home features the next appointment inside the crimson header, a search field linked to Doctors, care shortcuts, and the daily care plan. Both data sections support pull to refresh, empty states, and Retry. A dose shows Taken after Vapor confirms the update. |
| Tab bar and shortcuts | [Quick Access](<../../RS Permata Sehat/Quick Access.png>) | Custom bar and bottom sheet are implemented. Appointments opens the existing appointment list. Find Doctors and Quick Book open the directory. Health Tracker opens vital logs. Records opens the combined medical history. Profile opens the account tab. Messages opens the inbox. |
| Medical records and lab | [Records](<../../RS Permata Sehat/Medical Record List.png>) · [Diagnosis](<../../RS Permata Sehat/Diagnosis Details.png>) · [Lab](<../../RS Permata Sehat/Lab Result.png>) | Integrated in source with search, filters, monthly groups, detail screens, and retry states. Diagnosis can open follow-up booking or a conversation with the visit’s doctor. Private attachments and published lab PDFs can be saved through the system exporter. |
| Patient documents and BPJS | [Documents](<../../RS Permata Sehat/Document Screen.png>) · [Upload](<../../RS Permata Sehat/Upload Docs.png>) | Profile opens the insurance and recent files list. Users can upload and download files, edit their own document metadata, replace attachments, and confirm deletion. History shows active and deleted records. Clinical attachments are available for download. |
| Health tracker and vital entry | [Blood pressure](<../../RS Permata Sehat/My Health.png>) · [Weight](<../../RS Permata Sehat/My Health-1.png>) · [Heart rate](<../../RS Permata Sehat/My Health-2.png>) · [BP entry](<../../RS Permata Sehat/Entry BP.png>) · [Weight entry](<../../RS Permata Sehat/Entry Weight.png>) · [Heart rate entry](<../../RS Permata Sehat/Entry Heart Rate.png>) | Quick Access opens the tracker. Metric tabs show a selectable trend, summary tiles, and logs for the selected 7, 30, or 90 clinic days. The blood pressure curve follows systolic readings and the selected point shows the full pair. The entry sheet uses scroll wheels with an optional keyboard and saves one metric at a time. Empty lists and fetch errors have dedicated states. |
| Messages | [Messages](<../../RS Permata Sehat/Message Doctor.png>) | The inbox, unread badges, server search, doctor picker, paged conversations, send, and mark-as-read are integrated in source. Incoming messages appear when the conversation opens or refreshes. |
| Profile | [Profile Settings](<../../RS Permata Sehat/Profile Screen.png>) | Biodata and photo editing, password change, appointment notification preferences, Help Center, and logout are integrated in source. The server-confirmed profile updates the Home greeting. |
| Authentication | Sign-in and registration use the app theme. | Patient registration, login, session restoration, and Debug reachability are integrated in source. Password recovery requires backend support. |

## 6. API integration requirements

Use the [patient API contract](../../be-rumahsakit-swift/API_SPEC.md#kontrak-aplikasi-pasien-ios) with the relevant route, handler, and DTO. The design files describe presentation. API authorization and persisted state come from Vapor.

| Area | Client requirement |
| --- | --- |
| Session | Debug reachability uses `GET /health`. Sign-in calls `POST /api/auth/login`, then `GET /api/users/me` with Bearer authorization. Save the JWT in Keychain after confirming the account has the patient role. Vapor issues a JWT with a 24-hour expiry. During restoration or an authenticated Doctors or Appointments request, a `401` clears the rejected session. Temporary failures offer a retry. Logout clears the local token and works offline. [Auth handler](../../be-rumahsakit-swift/Sources/rumahsakit/Controllers/AuthController.swift) |
| Doctor payload | Demo doctor IDs and availability labels are UI values. Vapor provides UUIDs and an optional `nextAvailable` slot object. Handle optional profile fields and practice metadata. Use the doctor `id` for doctor details, schedules, and booking. Use the doctor `userId` as chat `receiverId`. [Doctor DTO](../../be-rumahsakit-swift/Sources/rumahsakit/DTOs/DoctorDTOs.swift#L25) |
| Doctor favorites | Read `isFavorite` from `GET /api/doctors`. Save with `PUT /api/doctors/:id/favorite` and remove with `DELETE /api/doctors/:id/favorite`. Apply the new state after Vapor confirms the request. |
| Schedules | Read the profile from `GET /api/doctors/:id` and weekly hours from `GET /api/schedules?doctorId=…`. Load the next 14 clinic days together from `GET /api/doctors/:id/availability?from=…&to=…`. Day changes filter that response locally. The server supports up to 31 inclusive days and sends 30-minute slots with an `available` flag. Clinic days and clock times use `YYYY-MM-DD` and `HH:mm` in `Asia/Jakarta`. |
| Booking | Send `doctorId`, `date`, `time`, `reason`, and optional `complaints` to `POST /api/appointments`. Reason and complaints each have a 255-byte limit. Display the server's status, ID, and reference number. Retry in the same form with the original payload and `Idempotency-Key`. When a slot is no longer bookable, return to refreshed availability. Read the patient's appointments with `GET /api/appointments`. [Appointment DTO](../../be-rumahsakit-swift/Sources/rumahsakit/DTOs/AppointmentDTOs.swift) |
| Appointment changes | A future appointment with status `pending` or `approved` can be changed. Reschedule reads 14 days of doctor availability and submits a new `date` and `time` via `PATCH /api/appointments/:id`. The updated appointment normally returns to `pending`. Cancellation sends `reason` and optional `note` via `POST /api/appointments/:id/cancellation-requests`. It displays `cancellation_requested` while staff reviews the request. Approval produces `cancelled`. |
| Status handling | Recognize `pending`, `approved`, `rejected`, `completed`, `cancellation_requested`, and `cancelled`. Render a neutral fallback for an unfamiliar status. Appointment updates are available through the in-app notification feed. |
| Notifications | Fetch `GET /api/notifications` when selecting Home and opening the inbox, or use Refresh. Derive the unread dot from `readAt`. Mark an item as read using `PUT /api/notifications/:id/read` and update the unread state after the server acknowledges the request. Vapor emits `approved`, `rejected`, `cancelled`, and `cancellation_declined` events. |
| Daily care plan | Fetch `GET /api/care-plan?date=…` using today's date in `Asia/Jakarta`. Track each dose by `recordId`, medication ID, date, and scheduled time. `PUT /api/care-plan/:recordId/:medicationId/taken` sends that entry's `date` and `time` and returns the saved `takenAt` in ISO 8601. Repeating the same request preserves the original intake timestamp. |
| Vitals | Fetch `GET /api/health-updates` with `metric`, `from`, and `to`. The selected range covers 7, 30, or 90 days ending today in `Asia/Jakarta`. Log one selected measurement using `POST /api/health-updates` with `date`, ISO 8601 `measuredAt`, and `bloodPressure` as `systolic/diastolic`, `weight` as a positive decimal, or `heartRate` as a positive integer. Old records fall back to `createdAt`. Charts and summaries display the recorded values. An unconfirmed save sends the patient back to refresh Recent Logs before another submission. |
| Clinical history and files | Combine `GET /api/medical-records` and `GET /api/lab-results` for the timeline. Details use `GET /api/medical-records/:id`, `GET /api/medical-records/:id/documents`, and `GET /api/lab-results/:id`. Offer an authenticated export at `GET /api/documents/:id/download` or `GET /api/lab-results/:id/pdf` when the report includes the corresponding download path. |
| Messages | Load the inbox with `GET /api/messages/conversations` and search with `q`. Load a peer’s history with `GET /api/messages?peerId=…&limit=50&page=…`. For new messages, use the doctor’s account UUID from `userId` or the clinical record’s nested `user.id` and send `{receiverId,content}` with `POST /api/messages`. Limit trimmed content to 255 characters. Use `PUT /api/messages/:id/read` only for incoming unread messages. An unconfirmed send keeps the draft and refreshes the thread before allowing a retry. |
| Patient documents | List current files using `GET /api/documents` and historical records using `GET /api/documents/history`. Create a document with `POST /api/documents` and multipart `name`, `category`, `file`, and optional `cardNumber`. Update with `PUT /api/documents/:id`. Send JSON to keep the current file or multipart to replace it. Create and replacement accept PDF, JPEG, or PNG up to 5 MiB. `DELETE /api/documents/:id` returns 204 and retains history metadata. The list applies confirmed server changes and offers `GET /api/documents/:id/download` when available. For an unconfirmed save, compare server metadata and any selected file bytes before offering a retry. |
| Profile and preferences | Send changed biodata fields with `PUT /api/users/me` and apply the response to the session. Upload a selected JPEG with `POST /api/upload` and save the returned public URL as `avatarURL`. An empty `avatarURL` clears the photo from the profile. Read and save `appointmentUpdates` with `GET` and `PUT /api/users/me/notification-settings`. Load help topics with `GET /api/help-center`. |
| Registration and password | Create patient accounts using `POST /api/auth/register` with `role: "patient"`, then return to sign-in. Change passwords with authenticated `POST /api/auth/change-password`. Vapor returns 401 for a wrong current password. Recheck the JWT through `GET /api/users/me` before clearing the local session. Email-based password recovery is pending in the backend. |
| Presentation states | API-backed lists need loading, data, empty, and recoverable error states. Use API dates, availability, currency, statuses, and identifiers when the feature is integrated. Carry the server-created appointment from confirmation into refreshed history. |
| Refresh and cancellation | Dashboard refresh awaits both appointment and care-plan requests. Lists keep previously loaded data during a refresh and show an inline Retry if it fails. Keep filtered results scoped to their query or date range. Treat request cancellation as a lifecycle event, and distinguish offline and timeout errors. Mutations retain their own submit state, retry policy, and reconciliation behavior. |

## 7. Delivery sequence and verification

1. **Establish an authenticated connection.** API configuration, the shared client, sign-in, Keychain persistence, and a basic patient profile are integrated in source. iOS runtime verification is pending.
2. **Integrate Doctors and booking.** Directory, details, slot lookup, booking, and appointment history are wired in source. Verify on device that the server-created appointment appears in My Appointments with the same doctor, time, status, and reference shown in confirmation.
3. **Complete appointment management.** Rescheduling, cancellation requests, and the in-app notification inbox are wired in source. Device verification is pending.
4. **Expand patient features.** The dashboard, daily care plan, Health Tracker, medical records, lab results, Messages, patient document management, profile settings, and registration are wired in source. Password recovery is the next backend dependency.

When verification is requested, cover both doctor states, date changes, disabled slots, a blank visit reason, and a new appointment appearing in Upcoming. During API integration, also cover expired sessions, a conflicting slot, and document access boundaries. The Hurl suite verifies backend behavior. Record iOS build, Simulator, Preview, or device evidence separately with the revision and environment.

The My Appointments and MainTabView previews include synthetic appointment actions. Builds, tests, debugging, Simulator runs, and Preview rendering require a user request. [Agent guide](AGENTS.md#verification-and-handoff)
