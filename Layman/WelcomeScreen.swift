import SwiftUI

struct WelcomeScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var shouldNavigate = false
    private let accentOrange = Color(red: 0.82, green: 0.40, blue: 0.17)
    private var primaryText: Color {
        colorScheme == .dark ? Color.white : Color(red: 0.12, green: 0.12, blue: 0.12)
    }

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

           VStack(spacing: 0) {
                Text("Layman")
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .tracking(-0.8)
                    .foregroundStyle(primaryText)
                    .padding(.top, 52)

                Spacer(minLength: 0)

                VStack(spacing: -2) {
                    Text("Business,")
                    Text("tech & startups")
                    Text("made simple")
                        .foregroundStyle(accentOrange)
                }
                .font(.system(size: 56, weight: .black, design: .rounded))
                .tracking(-1)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
                .foregroundStyle(primaryText)
                .padding(.horizontal, 30)

                Spacer(minLength: 0)

                SwipeToStart(shouldNavigate: $shouldNavigate)
                    .padding(.horizontal, 38)
                    .padding(.bottom, 36)
            }
        }
        .fullScreenCover(isPresented: $shouldNavigate) {
        ContentView()
            
        }
    }
}

private struct SwipeToStart: View {
    @Binding var shouldNavigate: Bool

    @State private var dragOffset: CGFloat = 0
    @State private var isComplete = false

    private let accentOrange = Color(red: 0.82, green: 0.40, blue: 0.17)
    private let height: CGFloat = 58

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let knobSize = height - 8
            let maxOffset = width - knobSize - 8

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(accentOrange)

                Text("Swipe to get started")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.leading, knobSize + 6)

                Circle()
                    .fill(.white)
                    .overlay(
                        Image(systemName: "chevron.right.2")
                            .font(.system(size: 26, weight: .black))
                            .foregroundStyle(accentOrange)
                    )
                    .frame(width: knobSize, height: knobSize)
                    .offset(x: dragOffset + 4)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard !isComplete else { return }
                                let translation = max(0, value.translation.width)
                                dragOffset = min(translation, maxOffset)
                            }
                            .onEnded { _ in
                                guard !isComplete else { return }
                                let threshold = maxOffset * 0.75
                                if dragOffset >= threshold {
                                    isComplete = true
                                    dragOffset = maxOffset
                                    shouldNavigate = true
                                } else {
                                    dragOffset = 0
                                }
                            }
                    )
            }
            .frame(height: height)
            .animation(.easeOut(duration: 0.25), value: dragOffset)
            .animation(.easeOut(duration: 0.25), value: isComplete)
        }
        .frame(height: height)
    }
}

#Preview {
    WelcomeScreen()
        .environment(ViewModel())
}
