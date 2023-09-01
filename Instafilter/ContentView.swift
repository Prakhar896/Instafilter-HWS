//
//  ContentView.swift
//  Instafilter
//
//  Created by Prakhar Trivedi on 29/8/23.
//

import SwiftUI

struct ContentView: View {
    @State var image: Image?
    @State var inputImage: UIImage?
    @State var showingPhotoPicker = false
    
    var body: some View {
        VStack(spacing: 10) {
            image?
                .resizable()
                .scaledToFit()
                .cornerRadius(10)
                .padding()
            
            Button("Pick Photo") {
                showingPhotoPicker = true
            }
            .padding()
            
            Button("Save Photo") {
                guard let inputImage = inputImage else { return }
                ImageSaver().writeToPhotoAlbum(image: inputImage)
            }
            .padding()
        }
        .sheet(isPresented: $showingPhotoPicker) {
            ImagePicker(image: $inputImage)
        }
        .onChange(of: inputImage) { _ in
            loadImage()
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
