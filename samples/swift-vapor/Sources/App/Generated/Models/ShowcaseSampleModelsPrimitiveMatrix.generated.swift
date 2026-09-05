// Generated code. Do not edit.
import Foundation
import Vapor

public struct ShowcaseSampleModelsPrimitiveMatrix: Codable, Sendable, Equatable, Hashable {
    public var uuid: UUID
    public var title: String
    public var count: Int
    public var largeCount: Int64
    public var mediumCount: Int32
    public var smallCount: Int16
    public var tinyCount: Int8
    public var unsignedCount: UInt
    public var unsignedLargeCount: UInt64
    public var unsignedMediumCount: UInt32
    public var unsignedSmallCount: UInt16
    public var unsignedTinyCount: UInt8
    public var ratio: Double
    public var enabled: Bool
    public var createdAt: Date
    public var businessDate: TimelessDate
    public var businessTime: Time
    public var callbackUrl: URL?
    public var payload: Data
    public var metadata: [String: String?]
    public var aliases: [String]
    public var steps: [Int]
    public var visibility: ShowcaseSampleVisibility
    public var score: ShowcaseSampleModelsPrimitiveMatrixSampleScore
    public var audit: AuditStamp
    public var related: [NamedObject]
    public var externalWindow: DateInterval
    public var archived: Bool

    public init(
        uuid: UUID,
        title: String = "Untitled",
        count: Int = 1,
        largeCount: Int64 = 1,
        mediumCount: Int32 = 1,
        smallCount: Int16 = 1,
        tinyCount: Int8 = 1,
        unsignedCount: UInt = 1,
        unsignedLargeCount: UInt64 = 1,
        unsignedMediumCount: UInt32 = 1,
        unsignedSmallCount: UInt16 = 1,
        unsignedTinyCount: UInt8 = 1,
        ratio: Double = 0.5,
        enabled: Bool = true,
        createdAt: Date,
        businessDate: TimelessDate,
        businessTime: Time,
        callbackUrl: URL? = nil,
        payload: Data,
        metadata: [String: String?],
        aliases: [String],
        steps: [Int],
        visibility: ShowcaseSampleVisibility,
        score: ShowcaseSampleModelsPrimitiveMatrixSampleScore,
        audit: AuditStamp,
        related: [NamedObject],
        externalWindow: DateInterval,
        archived: Bool = false,
    ) {
        self.uuid = uuid
        self.title = title
        self.count = count
        self.largeCount = largeCount
        self.mediumCount = mediumCount
        self.smallCount = smallCount
        self.tinyCount = tinyCount
        self.unsignedCount = unsignedCount
        self.unsignedLargeCount = unsignedLargeCount
        self.unsignedMediumCount = unsignedMediumCount
        self.unsignedSmallCount = unsignedSmallCount
        self.unsignedTinyCount = unsignedTinyCount
        self.ratio = ratio
        self.enabled = enabled
        self.createdAt = createdAt
        self.businessDate = businessDate
        self.businessTime = businessTime
        self.callbackUrl = callbackUrl
        self.payload = payload
        self.metadata = metadata
        self.aliases = aliases
        self.steps = steps
        self.visibility = visibility
        self.score = score
        self.audit = audit
        self.related = related
        self.externalWindow = externalWindow
        self.archived = archived
    }

    public enum CodingKeys: String, CodingKey {
        case uuid
        case title
        case count
        case largeCount = "large_count"
        case mediumCount = "medium_count"
        case smallCount = "small_count"
        case tinyCount = "tiny_count"
        case unsignedCount = "unsigned_count"
        case unsignedLargeCount = "unsigned_large_count"
        case unsignedMediumCount = "unsigned_medium_count"
        case unsignedSmallCount = "unsigned_small_count"
        case unsignedTinyCount = "unsigned_tiny_count"
        case ratio
        case enabled
        case createdAt = "created_at"
        case businessDate = "business_date"
        case businessTime = "business_time"
        case callbackUrl = "callback_url"
        case payload
        case metadata
        case aliases
        case steps
        case visibility
        case score
        case audit
        case related
        case externalWindow = "external_window"
        case archived
    }

    public static func == (lhs: ShowcaseSampleModelsPrimitiveMatrix, rhs: ShowcaseSampleModelsPrimitiveMatrix) -> Bool {
        lhs.uuid == rhs.uuid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}
