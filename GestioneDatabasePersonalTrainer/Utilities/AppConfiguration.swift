import Foundation

enum AppConfiguration {
    // Replace these values with your Supabase project settings before running against cloud.
    static let supabaseURL = "https://ubjtnxwqrkxkttwlocfz.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVianRueHdxcmt4a3R0d2xvY2Z6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg4NTg4NTgsImV4cCI6MjA5NDQzNDg1OH0.YwgCd47xT9bqsRm3uo1gMuXXj1dRSab4kdAccDzBKGY"

    static let isDemoLoginEnabled = true
    static var useMockData = false

    // Set to true during demo sessions — forces all services to use MockDatabase instead of Supabase
    static var isDemoMode: Bool = false

    static var isSupabaseConfigured: Bool {
        guard !isDemoMode && !useMockData else { return false }
        return supabaseURL.contains(".supabase.co") &&
               !supabaseURL.contains("YOUR_PROJECT_REF") &&
               !supabaseAnonKey.contains("YOUR_SUPABASE_ANON_KEY")
    }
}
