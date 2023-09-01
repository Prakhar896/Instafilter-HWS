//
//  ContentView.swift
//  Instafilter
//
//  Created by Prakhar Trivedi on 29/8/23.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @State private var image: Image?
    @State private var inputImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var saveStatus = false
    
    @State private var showingPickerSheet = false
    @State private var showingFilterSheet = false
    @State private var showingSaveStatusAlert = false
    
    @State private var filterIntensity = 0.1
    @State private var filterRadius = 0.1
    @State private var filterRadiusMultiplier = 500.0
    @State private var filterAngle = 1.0
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    
    var sliders: some View {
        VStack(spacing: 10) {
            if currentFilter.inputKeys.contains(kCIInputIntensityKey) || currentFilter.inputKeys.contains(kCIInputScaleKey) {
                HStack {
                    Text("Intensity")
                    Slider(value: $filterIntensity)
                        .onChange(of: filterIntensity) { _ in
                            applyProcessing()
                        }
                }
            }
            
            if currentFilter.inputKeys.contains(kCIInputRadiusKey) {
                HStack {
                    Text("Radius")
                    Slider(value: $filterRadius)
                        .onChange(of: filterRadius) { _ in
                            applyProcessing()
                        }
                }
                
                HStack {
                    Text("Radius Multiplier")
                    Slider(value: $filterRadiusMultiplier, in: 1...2000)
                        .onChange(of: filterRadiusMultiplier) { _ in
                            applyProcessing()
                        }
                }
            }
            
            if currentFilter.inputKeys.contains(kCIInputAngleKey) {
                HStack {
                    Text("Angle")
                    Slider(value: $filterAngle, in: 0...360)
                        .onChange(of: filterAngle) { _ in
                            applyProcessing()
                        }
                }
            }
        }
        .padding(.vertical)
    }
    
    var actionButtons: some View {
        HStack {
            Button("Change Filter") {
                showingFilterSheet = true
            }
            
            Spacer()
            
            Button("Save", action: save)
                .disabled(image == nil)
        }
    }
    
    var canvas: some View {
        ZStack {
            Rectangle()
                .fill(.secondary.opacity(image == nil ? 1: 0.4))
            
            if image == nil {
                Text("Tap to select a picture")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            
            image?
                .resizable()
                .scaledToFit()
        }
        .onTapGesture {
            showingPickerSheet = true
        }
        .cornerRadius(10)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                canvas
                    .contextMenu {
                        Button {
                            save()
                        } label: {
                            Label("Save Image", systemImage: "square.and.arrow.down")
                        }
                    }
                
                sliders
                
                actionButtons
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("Instafilter")
            .onChange(of: inputImage) { _ in
                loadImage()
            }
            .sheet(isPresented: $showingPickerSheet) {
                ImagePicker(image: $inputImage)
            }
            .confirmationDialog("Select a filter", isPresented: $showingFilterSheet) {
                Group {
                    Button("Crystallize") { setFilter(CIFilter.crystallize()) }
                    Button("Edges") { setFilter(CIFilter.edges()) }
                    Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur()) }
                    Button("Pixellate") { setFilter(CIFilter.pixellate()) }
                    Button("Sepia Tone") { setFilter(CIFilter.sepiaTone()) }
                    Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask()) }
                    Button("Vignette") { setFilter(CIFilter.vignette()) }
                    Button("Gabor Gradient") { setFilter(CIFilter.gaborGradients()) }
                    Button("Comic") { setFilter(CIFilter.comicEffect()) }
                    Button("Twirl Distortion") { setFilter(CIFilter.twirlDistortion()) }
                }
                
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Select a filter")
            }
            .alert(saveStatus ? "Filtered image saved!": "Error in saving image", isPresented: $showingSaveStatusAlert) {
                Button(saveStatus ? "Great!": "OK") {}
            } message: {
                Text(saveStatus ? "Your new processed photo has been saved to your photo library!": "An error occurred in saving your filtered photo to your library. This might be due to insufficient permissions granted to the app. Please try again!")
            }
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        
        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
    
    func applyProcessing() {
        // apply intensity with multiples where appropriate
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        }
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(filterRadius * filterRadiusMultiplier, forKey: kCIInputRadiusKey)
        }
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(filterIntensity * 200, forKey: kCIInputScaleKey)
        }
        if inputKeys.contains(kCIInputCenterKey) {
            currentFilter.setValue(CIVector(cgPoint: CGPoint(x: (inputImage?.size.width ?? 100) / 2, y: (inputImage?.size.height ?? 100) / 2)), forKey: kCIInputCenterKey)
        }
        if inputKeys.contains(kCIInputAngleKey) {
            currentFilter.setValue(filterAngle, forKey: kCIInputAngleKey)
        }
        
        guard let outputImage = currentFilter.outputImage else { return }
        
        if let cgImg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgImg)
            processedImage = uiImage
            image = Image(uiImage: uiImage)
        }
    }
    
    func setFilter(_ filter: CIFilter) {
        withAnimation {
            currentFilter = filter
            loadImage()
        }
    }
    
    func save() {
        guard let processedImage = processedImage else { return }
        
        let imageSaver = ImageSaver()
        imageSaver.successHandler = {
            print("Save successful!")
            saveStatus = true
            showingSaveStatusAlert = true
        }
        imageSaver.errorHandler = {
            print("Error in save: \($0.localizedDescription)")
            saveStatus = false
            showingSaveStatusAlert = true
        }
        imageSaver.writeToPhotoAlbum(image: processedImage)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
