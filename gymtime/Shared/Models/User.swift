/*
 * 👤 What is this file for?
 * -------------------------
 * This is like a digital ID card for each user of your app.
 * It stores important information about the user (like name, settings, preferences).
 * Think of it as a membership card that contains all the user's personal gym information.
 */



import Foundation

struct User: Codable {
    enum CodingKeys: String, CodingKey {
        case id, login, name, bio, followers, following
        case htmlURL = "html_url"
        case publicRepos = "public_repos"
        case publicGists = "public_gists"
    }
    
    var id: Int?
    var login: String?
    var name: String?
    var bio: String?
    var htmlURL: URL?
    var publicRepos: Int?
    var publicGists: Int?
    var followers: Int?
    var following: Int?
}
