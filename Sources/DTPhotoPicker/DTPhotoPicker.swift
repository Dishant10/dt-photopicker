import Foundation
import SwiftUI
import PhotosUI

// MARK: - Controller
@MainActor class DTPhotoPickerViewModel: ObservableObject {
    
    enum ImageState {
        case empty
        case loading
        case success(Image, Data)
        case failure(Error)
    }
    
    @Published private(set) var imageState: ImageState = .empty
    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            if let imageSelection {
                loadTransferable(from: imageSelection)
                imageState = .loading
            } else {
                imageState = .empty
            }
        }
    }
    
    private func loadTransferable(from imageSelection: PhotosPickerItem) {
        imageSelection.loadTransferable(type: DTPhotoPickerModel.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    
                    return
                }
                
                switch result {
                case .success(let photoPickerModel?):
                    self.imageState = .success(photoPickerModel.image, photoPickerModel.data)
                case .success(nil):
                    self.imageState = .empty
                case .failure(let error):
                    self.imageState = .failure(error)
                }
            }
        }
    }
}

// MARK: - Model
struct DTPhotoPickerModel: Transferable {
    let image: Image
    let data: Data
    
    enum TransferError: Error {
        case importFailed
    }
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let uiImage = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            
            let image = Image(uiImage: uiImage)
            
            return Self(image: image, data: data)
        }
    }
}

// MARK: - Views
public struct DTPhotoPicker<Content: View>: View {
    @StateObject var viewModel = DTPhotoPickerViewModel()
    
    let initialState: (image: Image?, data: Data?)
    let content: (Image, Data) -> Content
    
    public init(initialState: (image: Image?, data: Data?), content: @escaping (Image, Data) -> Content) {
        self.initialState = initialState
        self.content = content
    }
    
    public var body: some View {
        Group {
            switch viewModel.imageState {
            case .success(let image, let data):
                DTPhotoContainer(backgroundColor: Color(.tertiarySystemBackground)) {
                    content(image, data)
                }
                
            case .loading:
                DTPhotoContainer(backgroundColor: Color(.tertiarySystemBackground)) {
                    ProgressView()
                }
                
            case .empty:
                if let image = initialState.image, let data = initialState.data {
                    DTPhotoContainer(backgroundColor: Color(.tertiarySystemBackground)) {
                        content(image, data)
                    }
                } else {
                    DTPhotoContainer(backgroundColor: Color(.tertiarySystemBackground)) {
                        DTPhotoEmptyPlaceholder()
                    }
                }
                
            case .failure:
                DTPhotoContainer(backgroundColor: Color(.tertiarySystemBackground)) {
                    DTPhotoFailurePlaceholder()
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            PhotosPicker(
                selection: $viewModel.imageSelection,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Image(systemName: "plus")
                    .font(.title3)
                    .padding()
            }
        }
    }
}

public struct DTPhotoEmptyPlaceholder: View {
    
    public init() { }
    
    public var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "mountain.2.fill")
                .font(.title2.bold())
            
            Text("No image")
        }
        .foregroundColor(.secondary)
    }
}

public struct DTPhotoFailurePlaceholder: View {
    
    public init() { }
    
    public var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2.bold())
            
            Text("Couldn't load image")
        }
        .foregroundColor(.secondary)
    }
}

// MARK: Container
public struct DTPhotoContainer<Content: View>: View {
    let backgroundColor: Color
    var content: () -> Content
    
    public init(backgroundColor: Color, @ViewBuilder content: @escaping () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content
    }
    
    public var body: some View {
        Rectangle()
            .foregroundColor(backgroundColor)
            .overlay {
                content()
            }
    }
}
