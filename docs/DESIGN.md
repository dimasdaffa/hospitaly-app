# Hospitaly design direction

**Patient screens · 27 November 2026**

The visual reference brings the next step into focus with a colored header, a prominent care card, a search field across the transition to the page, and compact service shortcuts. Hospitaly uses that hierarchy with its crimson brand, glass surfaces, and the patient flows already connected to Vapor.

## Theme

| Token | Value or treatment | Use |
| --- | --- | --- |
| Primary crimson | `#DB143C` | Brand, action emphasis, and selection |
| Hero gradient | `#510D2A` to `#B01B45` | Full-width headers on Home, Doctors, Profile, and Messages, plus focused panels inside pushed screens |
| Crimson ink | `#A31138` | Text and symbols on light rose surfaces |
| Rose canvas | `#FFF8FB` with a soft `#F6E2EB` wash | Patient screen backgrounds |
| Glass content | Thin material, a tint, a fine highlight, and a restrained shadow | Search, visit confirmation, charts, and other focal surfaces |
| Reading panels | Near-white fill, fine border, and soft shadow | Repeated rows, records, and form sections |
| Bottom action bars | Regular material over the canvas | Booking, form submission, file export, and message composer |
| Interactive glass | Native Liquid Glass | Header controls, including notifications, Help Center, and the appointment calendar |

Use system typography and sentence-case labels. Keep appointment facts on a light inset panel so the time and actions remain readable over the saturated header. Main screens use a shared crimson backdrop, 20 pt horizontal insets, and 24 pt cards. Place the first search field or settings panel across the transition from the header to the rose canvas. [Theme.swift](../Hospitaly/Shared/UI/Theme.swift) · [Apple guidance on materials](https://developer.apple.com/design/human-interface-guidelines/materials)

Use the system segmented picker for fixed choices such as vital metrics, appointment views, doctor detail sections, and record types. The system draws the selected segment and handles interactions.

## Home layout and behavior

1. The crimson header extends behind the status bar and Dynamic Island. The greeting, notification inbox, and Help Center controls sit below the top safe area.
2. The next-appointment card shows the actual doctor, status, clinic date and time, and existing detail and reschedule actions. The page includes loading, empty, and recoverable error states.
3. The search field overlaps the header edge and sends the entered doctor or specialty query to the existing directory.
4. Care shortcuts open Appointments, Health Tracker, Medical Records, and Documents & BPJS. Labels can wrap, and the grid uses two columns at accessibility text sizes.
5. Today’s Care Plan keeps the actual doses from Vapor, including the existing Mark as Taken action and confirmation.

The reference’s queue number, estimated turn, QR check-in, pharmacy queue, and events describe separate features. Those sections require their own product decisions and backend contracts before they can represent live patient data.

## Doctor detail layout and behavior

- The rose background extends behind the system navigation bar. The doctor’s name and specialty sit to the left of the portrait, with a glass surface underneath for experience, patient count, and rating. Unavailable portraits remain grayscale, and missing photos use the shared placeholder.
- The Appointment tab opens first. Its compact date cards and time pills use crimson for the active choice. The bottom bar shows the selected time and consultation fee, and Continue to Reason opens the existing booking form after an available time is selected.
- Schedule displays the doctor’s weekly practice hours. Appointment also shows those hours when there are no bookable slots in the next 14 clinic days.
- About holds the biography and practice address. Profile details, practice hours, and availability continue to use the existing Vapor endpoints.

## Appointment management

- My Appointments highlights the earliest future visit in Upcoming. Other visits and history use compact rows led by the clinic date and time. Eligible visits offer shortcuts to reschedule or request cancellation.
- The featured visit, details, forms, and confirmations share a crimson summary with a light panel for the date, time, location, and server reference and status when available. Details keep the reason and complaints in a separate panel. Reschedule and cancellation actions stay at the bottom of eligible details.
- Reschedule displays the current visit before the replacement picker. The action bar shows the selected time before submission. The confirmation uses the returned time, reference, and status, including pending approval when applicable.
- The cancellation form explains hospital review and makes the selected reason visible. Its confirmation shows the returned cancellation status. Both outcomes provide an action back to My Appointments.
- The Home bell opens Notifications. A crimson summary shows the unread count, and each card puts the appointment outcome and clinic timestamp first. Unread cards offer Mark as read. The full appointment reference is available in an expandable section.

## Medical records

- Medical Records uses a crimson header with an overlapping glass search field. The Last Visit card highlights the diagnosis, date, and clinician when available. The remaining records are grouped by month, with a label and icon for each record type.
- Diagnosis Details puts the diagnosis, reported severity, and symptoms first. The care provider, medicines, notes, and attachments follow in light panels. Book Follow-up and Chat Doctor stay in the bottom action bar when available.
- Lab Results shows any published alert above the result panels. Measurements show their values, units, reference ranges, and reported statuses. Download PDF stays at the bottom when the report has a file.

## Health tracker

- The tracker shows the selected metric and period above a selectable trend chart. The crimson summary contains the average and date range. The blood pressure curve follows systolic values, and selecting a point shows both pressures.
- Recent Logs shows up to three of the newest readings. View All opens the selected metric and period, with entries grouped by clinic date, newest first. Both screens support pull-to-refresh and preserve loaded readings on refresh failure.
- Log Vitals opens as a sheet with centered, scrollable number wheels. Blood pressure has one wheel for each pressure. Heart rate and weight use one wheel each, with a decimal step for weight. The sheet also shows the last reading and offers keyboard entry. If a save cannot be confirmed, Check Recent Logs opens the history and refreshes the readings.

## Other patient screens

- Our Specialists places the title and appointment shortcut in the crimson hero. A glass search field overlaps its lower edge, followed by specialty chips and the result count. Doctor cards show ratings and experience on one line when possible, with a rose booking strip that groups availability and the action.
- Documents and BPJS places the upload action first and groups insurance and recent files into readable rows with download and management actions. Upload and Edit Document show the file in a crimson picker, metadata in a glass form section, and categories in an adaptive grid. History uses separate glass groups for active and deleted files.
- Messages uses a crimson title, a glass compose button, an overlapping search field, and inset inbox cards. Conversation threads use light incoming bubbles and crimson outgoing bubbles.
- New Message places a glass search field across the bottom of its crimson header. Search matches doctor names and specialties. Each doctor card opens a conversation with the selected doctor's linked account.
- Profile combines the patient's identity and editable portrait in a full-width header. Account settings share one glass panel. Photo editing and password settings use crimson focal panels, and notification preferences use a glass settings card.
- Help Center presents the hospital's FAQ as expandable reading panels. Previously loaded topics remain visible during a refresh and after a refresh failure.
- Register pairs a crimson hospital header with a glass form. Field labels stay visible while typing, and the action bar shows submission progress. A confirmed registration returns to sign-in with the registered email filled in.

## Rollout

| Phase | Screen direction |
| --- | --- |
| 1 · Dashboard | Crimson header, next visit card, overlapping search, care shortcuts, and care plan. |
| 2 · Doctors and booking | Give the clinician’s portrait and specialty a prominent header. Keep dates and slots easy to scan, with clear selected and unavailable states. |
| 3 · Visits and clinical records | Put visit status and timing ahead of secondary actions. Use lighter surfaces for reports, attachments, and lab values. |
| 4 · Chat and account | Apply the palette to inbox navigation and account rows. Keep message threads and patient forms quiet with light reading surfaces. |
| Last · Main navigation | Revisit the tab bar and Quick Access after the patient screens have been reviewed. |

Keep route behavior, authorization, and clinical date handling consistent with [TECHREQ.md](TECHREQ.md).
