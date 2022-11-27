# DTPhotoPicker

A SwiftUI photo picker library using `PhotosUI`. 

## Usage

```swift
import DTPhotoPicker

struct ContentView: View {
var body: some View {
        DTPhotoPicker { data, image in
            image
                .resizable()
                .scaledToFill()
        }
    }
}
```
