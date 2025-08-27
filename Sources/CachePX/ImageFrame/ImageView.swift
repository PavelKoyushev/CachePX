import SwiftUI

public struct ImageView<Loading: View, Error: View, ImageContent: View>: View {
    
    @StateObject private var manager: ImageViewManager
    
    let url: URL
    let options: LoadOptions?
    let loadingContent: Loading
    let errorContent: Error
    let imageContent: (UIImage) -> ImageContent
    
    public init(url: URL,
                options: LoadOptions? = nil,
                @ViewBuilder loadingContent: () -> Loading,
                @ViewBuilder errorContent: () -> Error,
                @ViewBuilder imageContent: @escaping (UIImage) -> ImageContent) {
        
        self.url = url
        self.options = options
        self.loadingContent = loadingContent()
        self.errorContent = errorContent()
        self.imageContent = imageContent
        
        self._manager = StateObject(wrappedValue: ImageViewManager(options: options))
    }
    
    public var body: some View {
        content
            .onAppear(perform: onAppear)
            .onDisappear(perform: onDisappear)
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
}

private extension ImageView {
    
    func onAppear() {
        manager.loadImage(from: url)
    }
    
    func onDisappear() {
        manager.cancelTask()
    }
}
