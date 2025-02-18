/*
 * 📝 What is this file for?
 * -------------------------
 * This is like a blueprint for workout or exercise information in your app.
 * It defines what data we store about each workout/exercise (like name, description, etc.).
 * Think of it as a form template that gets filled out for each workout in your app.
 */

import Foundation

struct Repo: Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id, name, description, owner, fork, source
        case fullName = "full_name"
        case htmlURL = "html_url"
    }
    
    var id: Int?
    var name: String?
    var fullName: String?
    var description: String?
    var htmlURL: URL?
    var owner: User?
    var fork: Bool?
    var source: Container<Repo>?
}
