import Foundation

// highlight-next-line
public struct User: Codable, Identifiable {
    public let id: String
    public let username: String
    public let email: String
    public let avatarUrl: String

    // highlight-start
    public init(id: String, username: String, email: String, avatarUrl: String) {
        self.id = id
        self.username = username
        self.email = email
        self.avatarUrl = avatarUrl
    }
    // highlight-end
}