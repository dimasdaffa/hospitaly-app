# Hospitaly design direction

**Theme, Home dashboard, and doctor details · 27 November 2026**

The visual reference brings the next step into focus with a colored header, a prominent care card, a search field across the transition to the page, and compact service shortcuts. Hospitaly uses that hierarchy with its crimson brand, glass surfaces, and the patient flows already connected to Vapor.

## Theme

| Token | Value or treatment | Use |
| --- | --- | --- |
| Primary crimson | `#DB143C` | Brand, action emphasis, and selection |
| Hero gradient | `#510D2A` to `#B01B45` | Dashboard header with white type and subtle curved highlights |
| Crimson ink | `#A31138` | Text and symbols on light rose surfaces |
| Dashboard canvas | `#FFF8FB` with a soft `#F6E2EB` wash | Scrolling content beneath the hero |
| Glass content | Thin material, a tint, a fine highlight, and a restrained shadow | Appointment card, search surface, and care plan cards |
| Interactive glass | Native Liquid Glass | Header controls, including notifications and Help Center |

Use system typography and sentence-case labels. Keep appointment facts on a light inset panel so the time and actions remain readable over the saturated header. The dashboard uses 20 pt horizontal insets, 28 pt section spacing, and 24 pt cards. Shared theme tokens and the glass surface modifier live in [Theme.swift](../Hospitaly/Shared/Theme.swift). [Apple guidance on materials](https://developer.apple.com/design/human-interface-guidelines/materials)

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

## Rollout

| Phase | Screen direction |
| --- | --- |
| 1 · Dashboard | Crimson header, next visit card, overlapping search, care shortcuts, and care plan. |
| 2 · Doctors and booking | Give the clinician’s portrait and specialty a prominent header. Keep dates and slots easy to scan, with clear selected and unavailable states. |
| 3 · Visits and clinical records | Put visit status and timing ahead of secondary actions. Use lighter surfaces for reports, attachments, and lab values. |
| 4 · Chat and account | Apply the palette to inbox navigation and account rows. Keep message threads and patient forms quiet with light reading surfaces. |

Keep route behavior, authorization, and clinical date handling consistent with [TECHREQ.md](TECHREQ.md).
