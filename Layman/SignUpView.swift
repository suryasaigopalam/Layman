import SwiftUI

struct SignUpView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ViewModel.self) var viewModel

    @Binding var isSignIn: Bool
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    private let accentOrange = Color(red: 0.82, green: 0.40, blue: 0.17)
    private var primaryText: Color {
        colorScheme == .dark ? Color.white : Color(red: 0.12, green: 0.12, blue: 0.12)
    }

    var body: some View {
        VStack(spacing: 22) {
            Text("Layman")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .tracking(-0.8)
                .foregroundStyle(primaryText)
                .padding(.top, 36)

            VStack(spacing: 6) {
                Text("Create Account")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .tracking(-0.8)
                    .foregroundStyle(primaryText)

                Text("Business, tech & startups made simple")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(accentOrange)
            }

            VStack(spacing: 14) {
                TextField("Name", text: $name)
                    .padding(.horizontal, 18)
                    .frame(height: 56)
                    .glassEffect(.regular, in: .rect(cornerRadius: 18))

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 18)
                    .frame(height: 56)
                    .glassEffect(.regular, in: .rect(cornerRadius: 18))

                SecureField("Password", text: $password)
                    .padding(.horizontal, 18)
                    .frame(height: 56)
                    .glassEffect(.regular, in: .rect(cornerRadius: 18))
            }
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(primaryText)

            Button("Sign Up") {
                Task {
                    await onSignUpTapped()
                }
            }
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(accentOrange, in: Capsule())
            .glassEffect(.regular.tint(accentOrange).interactive(), in: Capsule())

            HStack(spacing: 6) {
                Text("Already have an account?")
                    .foregroundStyle(primaryText.opacity(0.8))

                Button("Sign In") {
                    isSignIn = true
                }
                .foregroundStyle(accentOrange)
                .fontWeight(.bold)
            }
            .font(.system(size: 17, weight: .semibold, design: .rounded))

            Spacer()
        }
        .padding(.horizontal, 28)
        .alert("Sign Up Failed", isPresented: $showErrorAlert) {
            Button("Try Again", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func onSignUpTapped() async {
        do {
            try await viewModel.signUp(name: name, email: email, password: password)
        } catch {
            errorMessage = viewModel.authErrorMessage(from: error)
            showErrorAlert = true
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.97, green: 0.80, blue: 0.70),
                Color(red: 0.95, green: 0.90, blue: 0.82),
                Color(red: 0.96, green: 0.84, blue: 0.77)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        SignUpView(isSignIn: .constant(false))
            .environment(ViewModel())
    }
}
