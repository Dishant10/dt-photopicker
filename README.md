# DTPhotoPicker

A SwiftUI photo picker library using `PhotosUI`. 

## Usage

```swift
import DTPhotoPicker

struct ContentView: View {
var body: some View {
        DTPhotoPicker(initialState: viewModel.initialState) { image, data in
            image
                .resizable()
                .scaledToFill()
        }
    }
}
```
