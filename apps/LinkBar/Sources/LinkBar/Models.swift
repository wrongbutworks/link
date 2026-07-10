import Foundation

/// Decodable views over `lnk ... --json` payloads. Tolerant on purpose:
/// only the fields the popover renders are required.

struct MemoryInbox: Decodable {
    let reviewCount: Int
    let items: [InboxItem]

    enum CodingKeys: String, CodingKey {
        case reviewCount = "review_count"
        case items
    }
}

struct InboxItem: Decodable, Identifiable {
    let name: String
    let title: String
    let memoryType: String
    let tldr: String?
    let highestSeverity: String?

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name, title, tldr
        case memoryType = "memory_type"
        case highestSeverity = "highest_severity"
    }
}

struct CaptureInbox: Decodable {
    let count: Int
    let captures: [CaptureItem]
}

struct CaptureItem: Decodable, Identifiable {
    let path: String
    let title: String?
    let project: String?

    var id: String { path }
    var displayTitle: String {
        title ?? (path as NSString).lastPathComponent
    }
}

struct MemoryLog: Decodable {
    let entries: [LogEntry]
}

struct LogEntry: Decodable, Identifiable {
    let timestamp: String
    let operation: String
    let description: String?

    var id: String { timestamp + operation }
}

struct RecallPayload: Decodable {
    let memories: [RecalledMemory]
    let abstention: Abstention?
}

struct Abstention: Decodable {
    let recommended: Bool
    let reason: String?
}

struct RecalledMemory: Decodable, Identifiable {
    let name: String
    let title: String
    let memoryType: String?
    let confidence: String?
    let tldr: String?

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name, title, confidence, tldr
        case memoryType = "memory_type"
    }
}
