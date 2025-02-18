/*
 * 🧠 What is this file for?
 * -------------------------
 * This is like the brain behind the Profile screen.
 * It handles all the logic, data processing, and user interactions for the profile.
 * Think of it as a personal trainer who knows all the rules and manages your profile information.
 */


import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    
    @Published var username: String?
    @Published var displayName: String?
    @Published var bio: String?
    @Published var publicReposText: String?
    @Published var publicGistsText: String?
    @Published var followersText: String?
    @Published var followingText: String?
    
    var networkClient: GithubNetworkProvider = GithubNetworkClient()
    
    init() {
        bind()
    }
    
    private func bind() {
        $user.map({ $0?.login }).assign(to: &$username)
        $user.map({ $0?.name }).assign(to: &$displayName)
        $user.map({ $0?.bio }).assign(to: &$bio)
        $user.map({ "Public repos: \($0?.publicRepos ?? 0)" }).assign(to: &$publicReposText)
        $user.map({ "Public gists: \($0?.publicGists ?? 0)" }).assign(to: &$publicGistsText)
        $user.map({ "Followers: \($0?.followers ?? 0)" }).assign(to: &$followersText)
        $user.map({ "Following: \($0?.following ?? 0)" }).assign(to: &$followingText)
    }
    
    func getUser(username: String) {
        networkClient.getUser(username: username)
            .optionalize()
            .replaceError(with: nil)
            .assign(to: &$user)
    }
}
