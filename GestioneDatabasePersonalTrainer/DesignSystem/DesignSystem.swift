import SwiftUI

enum DesignSystem {
    enum Colors {
        static let bgMain = Color(hex: "FAF8F3")
        static let bgCard = Color(hex: "FFFEFB")
        static let bgLine = Color(hex: "ECE8DF")

        static let txtPrimary = Color(hex: "1A1D21")
        static let txtSecondary = Color(hex: "6B7280")

        static let lime = Color(hex: "A3C940")
        static let limeDark = Color(hex: "6F8F1E")
        static let limeBg = Color(hex: "EEF4DC")

        static let indigo = Color(hex: "5B6CE0")
        static let indigoBg = Color(hex: "E9ECFB")

        static let amber = Color(hex: "E8954A")
        static let amberBg = Color(hex: "FBEEE0")
        static let teal = Color(hex: "3FB8A0")
        static let tealBg = Color(hex: "E1F4EF")
        static let trend = Color(hex: "2FA36B")
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let xl: CGFloat = 24
    }

    enum Typography {
        static func titleXL() -> Font { .custom("Archivo-ExtraBold", size: 28) }
        static func titleLG() -> Font { .custom("Archivo-ExtraBold", size: 24) }
        static func titleMD() -> Font { .custom("Archivo-ExtraBold", size: 20) }
        static func numberXL() -> Font { .custom("Archivo-Black", size: 32) }
        static func numberLG() -> Font { .custom("Archivo-Black", size: 26) }
        static func bodyMD() -> Font { .custom("Sora-Regular", size: 14) }
        static func bodySM() -> Font { .custom("Sora-Regular", size: 12) }
        static func labelMD() -> Font { .custom("Sora-SemiBold", size: 13) }
        static func labelSM() -> Font { .custom("Sora-SemiBold", size: 11) }
        static func sectionLabel() -> Font { .custom("Sora-SemiBold", size: 11) }
    }
}

enum AppColors {
    static let appBackground = DesignSystem.Colors.bgMain
    static let background = DesignSystem.Colors.bgMain
    static let surface = DesignSystem.Colors.bgCard
    static let surfaceSecondary = DesignSystem.Colors.bgLine.opacity(0.65)
    static let elevatedSurface = DesignSystem.Colors.bgCard
    static let border = DesignSystem.Colors.bgLine

    static let textPrimary = DesignSystem.Colors.txtPrimary
    static let textSecondary = DesignSystem.Colors.txtSecondary
    static let textMuted = DesignSystem.Colors.txtSecondary.opacity(0.72)

    static let primaryBlack = DesignSystem.Colors.txtPrimary
    static let primaryBlackPressed = Color(hex: "0D0F12")

    static let successGreen = DesignSystem.Colors.teal
    static let dangerRed = Color(hex: "E57373")
    static let warningYellow = DesignSystem.Colors.amber
    static let infoBlue = DesignSystem.Colors.indigo
    static let energyOrange = DesignSystem.Colors.amber

    static let muscleRed = Color(hex: "E57373")
    static let progressGreen = DesignSystem.Colors.trend
    static let nutritionYellow = DesignSystem.Colors.lime
    static let calendarBlue = DesignSystem.Colors.indigo
    static let workoutBlack = DesignSystem.Colors.txtPrimary

    static let accent = DesignSystem.Colors.txtPrimary
    static let success = DesignSystem.Colors.teal
    static let violet = DesignSystem.Colors.indigo
    static let warning = DesignSystem.Colors.amber
    static let divider = DesignSystem.Colors.bgLine
}

enum AppSpacing {
    static let xs = DesignSystem.Spacing.xs
    static let sm = DesignSystem.Spacing.sm
    static let md = DesignSystem.Spacing.md
    static let lg = DesignSystem.Spacing.lg
    static let xl = DesignSystem.Spacing.xl
}

enum AppRadius {
    static let sm = DesignSystem.Radius.sm
    static let md = DesignSystem.Radius.md
    static let lg = DesignSystem.Radius.lg
    static let xl = DesignSystem.Radius.xl
}

enum AppTypography {
    static let hero = DesignSystem.Typography.titleXL()
    static let title = DesignSystem.Typography.titleLG()
    static let section = DesignSystem.Typography.titleMD()
    static let body = DesignSystem.Typography.bodyMD()
    static let caption = DesignSystem.Typography.bodySM()
    static let badge = DesignSystem.Typography.labelSM()
    static let number = DesignSystem.Typography.numberXL()
}

struct AppCardStyle: ViewModifier {
    var cornerRadius: CGFloat = DesignSystem.Radius.lg

    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(DesignSystem.Colors.bgLine, lineWidth: 1)
            )
            .shadow(color: Color(red: 40 / 255, green: 44 / 255, blue: 54 / 255).opacity(0.04), radius: 10, x: 0, y: 2)
    }
}

struct AppScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DesignSystem.Colors.bgMain.ignoresSafeArea())
            .scrollContentBackground(.hidden)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Archivo-ExtraBold", size: 15))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isEnabled ? (configuration.isPressed ? AppColors.primaryBlackPressed : DesignSystem.Colors.txtPrimary) : AppColors.textMuted)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.labelMD())
            .foregroundStyle(isEnabled ? DesignSystem.Colors.txtPrimary : AppColors.textMuted)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(configuration.isPressed ? DesignSystem.Colors.bgLine.opacity(0.8) : DesignSystem.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DesignSystem.Colors.bgLine, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.labelMD())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isEnabled ? AppColors.dangerRed.opacity(configuration.isPressed ? 0.78 : 1) : AppColors.textMuted)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

extension View {
    func appCard() -> some View {
        modifier(AppCardStyle())
    }

    func appScreen() -> some View {
        modifier(AppScreenBackground())
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(hex: String, alpha: Double = 1) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: value).scanHexInt64(&int)

        let red: UInt64
        let green: UInt64
        let blue: UInt64

        switch value.count {
        case 3:
            red = ((int >> 8) & 0xF) * 17
            green = ((int >> 4) & 0xF) * 17
            blue = (int & 0xF) * 17
        default:
            red = (int >> 16) & 0xFF
            green = (int >> 8) & 0xFF
            blue = int & 0xFF
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: alpha
        )
    }
}
