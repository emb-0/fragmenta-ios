import Foundation

struct PageRequest: Hashable, Sendable {
    var page: Int
    var limit: Int

    init(page: Int = 1, limit: Int = 20) {
        self.page = max(page, 1)
        self.limit = max(limit, 1)
    }
}

struct PageInfo: Codable, Hashable, Sendable {
    let page: Int
    let limit: Int
    let total: Int?
    let hasMore: Bool
    let nextPage: Int?

    static func singlePage(itemCount: Int, limit: Int? = nil) -> PageInfo {
        let resolvedLimit = limit ?? max(itemCount, 1)
        return PageInfo(
            page: 1,
            limit: resolvedLimit,
            total: itemCount,
            hasMore: false,
            nextPage: nil
        )
    }

    init(
        page: Int,
        limit: Int,
        total: Int?,
        hasMore: Bool,
        nextPage: Int?
    ) {
        self.page = page
        self.limit = limit
        self.total = total
        self.hasMore = hasMore
        self.nextPage = nextPage
    }
}

struct PaginatedResponse<Item: Codable & Hashable & Sendable>: Codable, Hashable, Sendable {
    let items: [Item]
    let pageInfo: PageInfo

    init(items: [Item], pageInfo: PageInfo) {
        self.items = items
        self.pageInfo = pageInfo
    }

    init(from decoder: Decoder) throws {
        let singleValue = try decoder.singleValueContainer()
        if let items = try? singleValue.decode([Item].self) {
            self.items = items
            self.pageInfo = .singlePage(itemCount: items.count)
            return
        }

        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        let candidateItemKeys = ["items", "results", "highlights", "imports", "books", "entries", "records"]

        guard let items = try container.decodeFirstPresent([Item].self, keys: candidateItemKeys) else {
            throw DecodingError.dataCorruptedError(
                forKey: AnyCodingKey("items"),
                in: container,
                debugDescription: "Unable to decode paginated response items."
            )
        }

        self.items = items

        if let nestedPageInfo = try container.decodeFirstPresent(PageInfo.self, keys: ["pagination", "page_info", "pageInfo", "meta"]) {
            self.pageInfo = nestedPageInfo
        } else {
            let page = try container.decodeFirstPresent(Int.self, keys: ["page", "current_page"]) ?? 1
            let limit = try container.decodeFirstPresent(Int.self, keys: ["limit", "per_page"]) ?? max(items.count, 1)
            let total = try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("total"))
            let hasMore = try container.decodeFirstPresent(Bool.self, keys: ["has_more", "hasMore"])
                ?? ((total.map { page * limit < $0 }) ?? false)
            let nextPage = try container.decodeFirstPresent(Int.self, keys: ["next_page", "nextPage"])
                ?? (hasMore ? page + 1 : nil)

            self.pageInfo = PageInfo(
                page: page,
                limit: limit,
                total: total,
                hasMore: hasMore,
                nextPage: nextPage
            )
        }
    }
}
