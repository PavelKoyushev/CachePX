import SwiftUI

public struct ImageView<Loading: View, ErrorContent: View, ImageContent: View>: View {
    
    @StateObject private var manager: ImageViewManager
    
    let url: URL
    let loadingContent: Loading
    let errorContent: ErrorContent
    let imageContent: (UIImage) -> ImageContent
    
    public init(url: URL,
                options: LoadOptions? = nil,
                @ViewBuilder loadingContent: () -> Loading,
                @ViewBuilder errorContent: () -> ErrorContent,
                @ViewBuilder imageContent: @escaping (UIImage) -> ImageContent) {
        
        self.url = url
        self.loadingContent = loadingContent()
        self.errorContent = errorContent()
        self.imageContent = imageContent
        
        self._manager = StateObject(wrappedValue: ImageViewManager(options: options))
    }
    
    public var body: some View {
        content
            .onAppear(perform: onAppear)
            .onDisappear(perform: onDisappear)
            .onChange(of: url) { _ in
                manager.loadImage(from: url)
            }
    }
}

private extension ImageView {
    
    @ViewBuilder
    var content: some View {
        switch manager.state {
        case .loading:
            loadingContent
        case let .image(image):
            imageContent(image)
        case .error:
            errorContent
        }
    }
    
    func onAppear() {
        manager.loadImage(from: url)
    }
    
    func onDisappear() {
        manager.cancelTask()
    }
}
