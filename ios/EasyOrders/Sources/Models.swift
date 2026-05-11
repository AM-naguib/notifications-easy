import Foundation

struct OrderQueueItem: Codable, Identifiable, Hashable, Sendable {
    private enum NotificationFormat {
        static let isolateStart = "\u{2068}"
        static let isolateEnd = "\u{2069}"
        static let cashMarker = "💵💵"
    }

    let id: String
    let orderNumber: String
    let customerName: String
    let amount: String
    let status: String
    let createdAt: String
    let acknowledgedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case orderNumber = "order_number"
        case customerName = "customer_name"
        case amount
        case status
        case createdAt = "created_at"
        case acknowledgedAt = "acknowledged_at"
    }

    private func isolated(_ value: String) -> String {
        "\(NotificationFormat.isolateStart)\(value)\(NotificationFormat.isolateEnd)"
    }

    var notificationTitle: String {
        "Order #\(isolated(orderNumber)) \(NotificationFormat.cashMarker) \(isolated(amount))"
    }

    var notificationBody: String {
        "\(isolated(customerName)) placed an order \(isolated(amount)) \(NotificationFormat.cashMarker)"
    }
}

struct PendingOrdersResponse: Codable, Sendable {
    let items: [OrderQueueItem]
    let count: Int
}

struct AckRequest: Encodable, Sendable {
    let ids: [String]
}

struct AckResponse: Decodable, Sendable {
    let acknowledgedIDs: [String]
    let count: Int

    enum CodingKeys: String, CodingKey {
        case acknowledgedIDs = "acknowledged_ids"
        case count
    }
}

struct SyncSummary: Sendable {
    let orders: [OrderQueueItem]
    let acknowledgedIDs: [String]
    let trigger: String
    let executedAt: Date

    var scheduledCount: Int {
        orders.count
    }

    static func empty(trigger: String) -> SyncSummary {
        SyncSummary(orders: [], acknowledgedIDs: [], trigger: trigger, executedAt: .now)
    }
}
