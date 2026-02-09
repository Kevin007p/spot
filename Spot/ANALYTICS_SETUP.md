# Analytics & Crash Reporting Setup

spot. uses PostHog for analytics and Sentry for crash reporting. Both are optional — the app works fine without them, logging events to the console in debug mode.

## PostHog (Analytics)

Free tier: 1M events/month — more than enough for ~50 users.

### Setup

1. Go to [posthog.com](https://posthog.com) and sign up (free)
2. Create a project
3. Copy your **API Key** from Project Settings

### Add the SDK

In Xcode:
1. File → Add Package Dependencies
2. URL: `https://github.com/PostHog/posthog-ios`
3. Dependency Rule: Up to Next Major → `3.0.0`
4. Add **PostHog** to the Spot target

### Configure

Open `Spot/Services/AnalyticsService.swift` and uncomment the PostHog section in `configurePostHog()`:

```swift
import PostHog

let config = PostHogConfig(apiKey: "phc_YOUR_API_KEY_HERE")
config.host = "https://us.i.posthog.com"
PostHogSDK.shared.setup(config)
posthogEnabled = true
```

Also uncomment the tracking calls in `track()`, `identify()`, and `reset()`.

### What's tracked

| Event | When | Properties |
|---|---|---|
| `sign_in_completed` | User signs in | provider |
| `signed_out` | User signs out | — |
| `account_delete_requested` | User requests deletion | — |
| `place_saved` | Place saved | place_name, category, cuisine, has_note |
| `place_deleted` | Place deleted | place_name |
| `note_edited` | Note updated | place_name |
| `duplicate_blocked` | Duplicate save blocked | place_name |
| `search_performed` | Search autocomplete | query, result_count |
| `search_result_tapped` | Tapped a search result | place_name, category |
| `filter_used` | Category filter applied | category |
| `tab_switched` | Tab bar navigation | tab |
| `onboarding_completed` | Finished onboarding | — |
| `sync_completed` | Remote sync done | — |

---

## Sentry (Crash Reporting)

Free tier: 5K errors/month, 10K performance transactions.

### Setup

1. Go to [sentry.io](https://sentry.io) and sign up (free)
2. Create a project → select **iOS** / **Swift**
3. Copy your **DSN** from Project Settings → Client Keys

### Add the SDK

In Xcode:
1. File → Add Package Dependencies
2. URL: `https://github.com/getsentry/sentry-cocoa`
3. Dependency Rule: Up to Next Major → `8.0.0`
4. Add **Sentry** to the Spot target

### Configure

Open `Spot/Services/AnalyticsService.swift` and uncomment the Sentry section in `configureSentry()`:

```swift
import Sentry

SentrySDK.start { options in
    options.dsn = "https://YOUR_DSN@o0.ingest.sentry.io/0"
    options.tracesSampleRate = 0.2
    options.profilesSampleRate = 0.2
    options.enableAutoSessionTracking = true
    options.attachScreenshot = true
    options.environment = "production"
}
sentryEnabled = true
```

Also uncomment the Sentry user identification in `identify()` and `reset()`.

### What Sentry captures automatically
- Crashes and unhandled exceptions
- App hang detection
- HTTP request performance
- Session tracking (daily/monthly active users)
- Screenshots on crash

---

## Testing

In debug mode, all events are printed to the Xcode console:
```
[Analytics] place_saved ["place_name": "Sugarfish", "category": "Restaurant", ...]
[Analytics] filter_used ["category": "Cafe"]
```

Once PostHog is configured, check the PostHog dashboard → Activity tab to see real events.

## Package Summary

| Package | URL | Purpose |
|---|---|---|
| PostHog iOS | `https://github.com/PostHog/posthog-ios` | Analytics |
| Sentry Cocoa | `https://github.com/getsentry/sentry-cocoa` | Crash reporting |
