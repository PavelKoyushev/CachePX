# CachePX

[![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2014.0%2B%20%7C%20macOS%2011.0%2B-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

CachePX is a lightweight image caching framework for SwiftUI.  
It provides a convenient `ImageView` for SwiftUI to load and cache images, as well as a powerful `CacheManager` for managing the cache storage.

---

## Features

- 🚀 SwiftUI `ImageView` for easy image loading with caching  
- 💾 Disk caching 
- 📊 Cache size info (MB, %) 
- 🧹 Clean cache on demand (`cleanCache`)  
- 🪵 Extensible logging system (`ExternalLogger`)  

---

## Requirements

- Xcode 14+
- iOS 14.0+
- macOS 11.0+
- Swift 5.10+

---

## Installation

### Swift Package Manager

You can install `CachePX` via **Swift Package Manager**:

```swift
dependencies: [
    .package(url: "https://github.com/PavelKoyushev/CachePX", from: "1.0.0")
]

## Using ImageView to load network image

```swift
var body: some View {
    ImageView(url: URL(string: "https://example.com/picture.jpeg")) {
          Color.gray
    } errorContent: {
          Color.red
    } imageContent: { image in
          Image(uiImage: image)
              .resizable()
    }
    .scaledToFit()
    .frame(width: 300, height: 300)
}
```

## Cache Manager

```swift
import CachePX

// Get cache size
let size = CacheManager.shared.cacheSize()
print("Cache size: \(size.0)mb bytes \(size.1)% of disk size")

// Clean cache on disk
CacheManager.shared.cleanCache()
```

## Logging

You can subscribe to ExternalLogger to enable logging:


```swift
import CachePX

struct ConsoleLogger: ExternalLogger {
    
    let name = "CachePX"
    
    func logEvent(event: String) {
        print(event)
    }
}

Logger.shared.subscribe(ConsoleLogger())
```

## License

CachePX is released under the MIT license.
