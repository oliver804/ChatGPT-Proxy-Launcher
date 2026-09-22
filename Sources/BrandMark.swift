import SwiftUI

enum BrandIdentity {
    static let symbolName = "arrow.triangle.branch"
}

// The window, menu panel and generated Finder / Dock icon all use this artwork.
struct BrandMark: View {
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: BrandIdentity.symbolName)
            .font(.system(size: size * 0.46, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.16, green: 0.60, blue: 0.44), Color(red: 0.04, green: 0.35, blue: 0.29)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: size * 0.28)
            )
    }
}
