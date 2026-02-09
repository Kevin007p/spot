import Foundation

// MARK: - Event Definitions

enum AnalyticsEvent: String {
    // Auth
    case signUpCompleted = "sign_up_completed"
    case signInCompleted = "sign_in_completed"
    case signedOut = "signed_out"
    case accountDeleteRequested = "account_delete_requested"

    // Places
    case placeSaved = "place_saved"
    case placeDeleted = "place_deleted"
    case noteEdited = "note_edited"
    case duplicateBlocked = "duplicate_blocked"

    // Search
    case searchPerformed = "search_performed"
    case searchResultTapped = "search_result_tapped"

    // Filters
    case filterUsed = "filter_used"

    // Navigation
    case tabSwitched = "tab_switched"
    case onboardingCompleted = "onboarding_completed"

    // Sync
    case syncCompleted = "sync_completed"
}

// MARK: - Analytics Service

class AnalyticsService {
    static let shared = AnalyticsService()

    private var posthogEnabled = false
    private var sentryEnabled = false

    private init() {}

    /// Call once at app launch after configuring providers
    func configure() {
        configurePostHog()
        configureSentry()
    }

    // MARK: - PostHog (Analytics)

    private func configurePostHog() {
        // TODO: Uncomment after adding PostHog Swift SDK package
        // import PostHog
        //
        // let config = PostHogConfig(apiKey: "YOUR_POSTHOG_API_KEY")
        // config.host = "https://us.i.posthog.com"  // or eu.i.posthog.com
        // PostHogSDK.shared.setup(config)
        // posthogEnabled = true

        print("[Analytics] PostHog not configured — add API key to enable")
    }

    // MARK: - Sentry (Crash Reporting)

    private func configureSentry() {
        // TODO: Uncomment after adding Sentry Swift SDK package
        // import Sentry
        //
        // SentrySDK.start { options in
        //     options.dsn = "YOUR_SENTRY_DSN"
        //     options.tracesSampleRate = 0.2
        //     options.profilesSampleRate = 0.2
        //     options.enableAutoSessionTracking = true
        //     options.attachScreenshot = true
        //     options.environment = "production"
        // }
        // sentryEnabled = true

        print("[Analytics] Sentry not configured — add DSN to enable")
    }

    // MARK: - Tracking

    func track(_ event: AnalyticsEvent, properties: [String: Any] = [:]) {
        let props = properties.merging(["timestamp": ISO8601DateFormatter().string(from: Date())]) { _, new in new }

        #if DEBUG
        print("[Analytics] \(event.rawValue) \(props)")
        #endif

        // TODO: Uncomment after adding PostHog SDK
        // if posthogEnabled {
        //     PostHogSDK.shared.capture(event.rawValue, properties: props)
        // }
    }

    func identify(userId: String, traits: [String: Any] = [:]) {
        #if DEBUG
        print("[Analytics] identify: \(userId) \(traits)")
        #endif

        // TODO: Uncomment after adding PostHog SDK
        // if posthogEnabled {
        //     PostHogSDK.shared.identify(userId, userProperties: traits)
        // }

        // TODO: Uncomment after adding Sentry SDK
        // if sentryEnabled {
        //     let user = Sentry.User()
        //     user.userId = userId
        //     SentrySDK.setUser(user)
        // }
    }

    func reset() {
        // Call on sign out to clear user identity
        #if DEBUG
        print("[Analytics] reset")
        #endif

        // TODO: Uncomment after adding PostHog SDK
        // if posthogEnabled {
        //     PostHogSDK.shared.reset()
        // }

        // TODO: Uncomment after adding Sentry SDK
        // if sentryEnabled {
        //     SentrySDK.setUser(nil)
        // }
    }
}
