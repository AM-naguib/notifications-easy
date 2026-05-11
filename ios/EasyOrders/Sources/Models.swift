import Foundation

struct OrderQueueItem: Codable, Identifiable, Hashable, Sendable {
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

    var notificationTitle: String {
        "Order #\(orderNumber) - \(amount)"
    }

    var notificationBody: String {
        "\(customerName) placed an order \(amount)"
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
