import SwiftUI

struct AuthView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isSignIn = true
    
    private var backgroundGradient: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.22, green: 0.14, blue: 0.12),
                Color(red: 0.16, green: 0.12, blue: 0.11),
                Color(red: 0.11, green: 0.10, blue: 0.10)
            ]
        }

        return [
            Color(red: 0.97, green: 0.80, blue: 0.70),
            Color(red: 0.95, green: 0.90, blue: 0.82),
            Color(red: 0.96, green: 0.84, blue: 0.77)
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if isSignIn {
                SignInView(isSignIn: $isSignIn)
            } else {
                SignUpView(isSignIn: $isSignIn)
            }
        }
    }
}

#Preview {
    AuthView()
        .environment(ViewModel())
}
