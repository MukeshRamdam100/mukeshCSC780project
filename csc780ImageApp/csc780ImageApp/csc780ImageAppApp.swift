
import SwiftUI
import Firebase
@main
struct csc780ImageAppApp: App {
    init() {
            FirebaseApp.configure()
        }
        
        var body: some Scene {
            WindowGroup {
                ContentView()
            }
        }
}
