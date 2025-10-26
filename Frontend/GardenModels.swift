//
//  GardenModels.swift
//  Frontend
//
//  Created for Trickle App
//

import Foundation

// MARK: - Garden State Response
struct GardenStateResponse: Codable {
    let currentState: String  // "focusing" or "distracted"
    let sessionSummary: SessionSummary
    let appUsage: AppUsage

    // Keep backward compatibility with old property name
    var todaySummary: SessionSummary {
        return sessionSummary
    }

    // Optional garden field for backend compatibility (we ignore it now)
    let garden: Garden?

    // Custom decoder to make garden optional
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentState = try container.decode(String.self, forKey: .currentState)
        sessionSummary = try container.decode(SessionSummary.self, forKey: .sessionSummary)
        appUsage = try container.decode(AppUsage.self, forKey: .appUsage)
        garden = try? container.decode(Garden.self, forKey: .garden)
    }

    private enum CodingKeys: String, CodingKey {
        case currentState, sessionSummary, appUsage, garden
    }
}

// MARK: - Garden (deprecated but kept for backend compatibility)
struct Garden: Codable {
    let tree: Tree?
}

struct Tree: Codable {
    let level: Int?
    let health: Double?
    let progressToNextLevel: Double?
}

// MARK: - Session Summary (renamed from TodaySummary to match backend)
struct SessionSummary: Codable {
    let totalFocusTime: Int        // seconds
    let totalDistractionTime: Int  // seconds
    let longestFocusStreak: Int    // seconds
    let lastUpdated: String        // ISO date string
}

// Type alias for backward compatibility
typealias TodaySummary = SessionSummary

// MARK: - App Usage
struct AppUsage: Codable {
    let focus: AppCategory
    let distraction: AppCategory
}

struct AppCategory: Codable {
    let totalTime: Int  // seconds
    let apps: [AppDetail]
}

struct AppDetail: Codable {
    let name: String
    let time: Int  // seconds
}

// MARK: - Focus State Enum
enum FocusState: String, Codable {
    case focusing = "focusing"
    case distracted = "distracted"

    var isFocusing: Bool {
        return self == .focusing
    }
}
