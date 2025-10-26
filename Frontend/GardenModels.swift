//
//  GardenModels.swift
//  Frontend
//
//  Created for Trickle App
//

import Foundation

// MARK: - Garden State Response
struct GardenStateResponse: Codable {
    let garden: Garden
    let currentState: String  // "focusing" or "distracted"
    let todaySummary: TodaySummary
    let appUsage: AppUsage
}

// MARK: - Garden
struct Garden: Codable {
    let tree: Tree
}

struct Tree: Codable {
    let level: Int
    let health: Double
    let progressToNextLevel: Double
}

// MARK: - Today Summary
struct TodaySummary: Codable {
    let totalFocusTime: Int        // seconds
    let totalDistractionTime: Int  // seconds
    let longestFocusStreak: Int    // seconds
    let lastUpdated: String        // ISO date string
}

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
