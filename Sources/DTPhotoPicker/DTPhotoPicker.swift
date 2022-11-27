import Foundation
import AVFoundation
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
    let data: Data
    let image: Image
    
    enum TransferError: Error {
        case importFailed, resizeFailed
    }
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let uiImage = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            
            // Resize image
            let maxSize = CGSize(width: 1000, height: 1000)
            let availableRect = AVMakeRect(aspectRatio: uiImage.size, insideRect: CGRect(origin: .zero, size: maxSize))
            let targetSize = availableRect.size

            let format = UIGraphicsImageRendererFormat()
            format.scale = 1

            let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

            let resizedUIImage = renderer.image { context in
                uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
            }
            
            // Get Data and Image from resized UIImage
            guard let resizedData = resizedUIImage.pngData() else {
                throw TransferError.resizeFailed
            }
            
            let resizedImage = Image(uiImage: resizedUIImage)
            
            return DTPhotoPickerModel(data: resizedData, image: resizedImage)
        }
    }
}

// MARK: - Views
public struct DTPhotoPicker<Content: View>: View {
    @StateObject var viewModel = DTPhotoPickerViewModel()
    
    let initialState: (image: Image?, data: Data?)?
    let backgroundColor: Color
    
    let content: (Data, Image) -> Content
    
    public init(
        initialState: (image: Image?, data: Data?)? = nil,
        backgroundColor: Color = Color(.tertiarySystemBackground),
        content: @escaping (Data, Image) -> Content)
    {
        self.initialState = initialState
        self.backgroundColor = backgroundColor
        self.content = content
    }
    
    public var body: some View {
        Group {
            switch viewModel.imageState {
            case .success(let image, let data):
                DTPhotoContainer(backgroundColor: backgroundColor) {
                    content(data, image)
                }
                
            case .loading:
                DTPhotoContainer(backgroundColor: backgroundColor) {
                    ProgressView()
                }
                
            case .empty:
                if let data = initialState?.data, let image = initialState?.image {
                    DTPhotoContainer(backgroundColor: backgroundColor) {
                        content(data, image)
                    }
                } else {
                    DTPhotoContainer(backgroundColor: backgroundColor) {
                        DTPhotoEmptyPlaceholder()
                    }
                }
                
            case .failure:
                DTPhotoContainer(backgroundColor: backgroundColor) {
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
                    .padding(10)
                    .background(Circle().opacity(0.3))
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
