import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


//--------------------------------------------------------------------------
struct ContentView: View {
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?
    @State private var uploadSuccess = false
    @State private var uploadError = false
    @State var retrievedImages = [UIImage]()
    @State private var isDisplayImagesPresented = false
    @State private var isDeleteScreenPresented = false
    
    
    var body: some View {
        VStack {
            Text("Image Management")
               .font(.largeTitle)

            Divider()
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 200, height: 200)
            } else {
                Text("No Image Selected")
            }

            Button(action: {
                isImagePickerPresented.toggle()
            }) {
                Text("Select a photo")
                    .frame(width: 150, height: 50)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }

            if selectedImage != nil {
                Button(action: {
                    uploadPhoto()
                }) {
                    Text("Upload Photo")
                        .frame(width: 150, height: 50)
                        .foregroundColor(.white)
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
            Button(action: {
                isDisplayImagesPresented.toggle()
            }) {
                Text("Display Images")
                    .frame(width: 150, height: 50)
                    .foregroundColor(.white)
                    .background(Color.purple)
                    .cornerRadius(10)
            }
            Button(action: {
                deleteLastPhoto()
                isDeleteScreenPresented = false
            }) {
                Text("Delete")
                    .frame(width: 150, height: 50)
                    .foregroundColor(.white)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            Button(action: {
                
            }) {
                Text("Update")
                    .frame(width: 150, height: 50)
                    .foregroundColor(.white)
                    .background(Color.green)
                    .cornerRadius(10)
            }
        }
            


            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .onAppear {
                retrievePhotos()
            }
            .alert(isPresented: $uploadSuccess) {
                Alert(title: Text("Success"), message: Text("Photo uploaded successfully!"), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $uploadError) {
                Alert(title: Text("Error"), message: Text("Failed to upload photo."), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $isDisplayImagesPresented) {
                DisplayImagesScreen(retrievedImages: retrievedImages)
            }
        }

    //Upload Functionality(DONE)
    func uploadPhoto() {
        guard let selectedImage = selectedImage,
              let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
            return
        }

        let path = "images/\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference()
        let fileRef = storageRef.child(path)

        fileRef.putData(imageData, metadata: nil) { metadata, error in
            if error == nil && metadata != nil{
                let db = Firestore.firestore()
                db.collection("images").document().setData(["url":path]) { error in
                    //if there are no errors, display the image
                    if error == nil{
                        DispatchQueue.main.async{
                            self.retrievedImages.append(self.selectedImage!)
                        }
                    }
                }
            }
        }
    }
    
    //Retrieve Functionality(DONE)
    func retrievePhotos() {
        let db = Firestore.firestore()
        db.collection("images").getDocuments { snapshot, error in
            if let error = error {
                print("Error getting documents: \(error.localizedDescription)")
                // Handle the error here if needed
                return
            }
            
            guard let snapshot = snapshot else {
                print("Snapshot is nil")
                return
            }
            
            var paths = [String]()
            for doc in snapshot.documents {
                // extract file path and add to array
                paths.append(doc["url"] as? String ?? "")
            }
            
            for path in paths {
                let storageRef = Storage.storage().reference()
                let fileRef = storageRef.child(path)
                
                fileRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
                    if let error = error {
                        print("Error downloading image: \(error.localizedDescription)")
                        // Handle the error here if needed
                        return
                    }
                    
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.retrievedImages.append(image)
                        }
                    }
                }
            }
        }
    }
    
    //Delete Functionality(DONE)
    func deleteLastPhoto() {
        let db = Firestore.firestore()
        db.collection("images").getDocuments { snapshot, error in
            if let error = error {
                print("Error getting documents: \(error.localizedDescription)")
                return
            } else {
                if let snapshot = snapshot {
                    let numberOfDocuments = snapshot.documents.count
                    print("Number of documents: \(numberOfDocuments)")

                    if numberOfDocuments > 0 {
                        let lastDocument = snapshot.documents[numberOfDocuments - 1]
                        lastDocument.reference.delete { error in
                            if let error = error {
                                print("Error deleting document: \(error.localizedDescription)")
                            } else {
                                print("Last document successfully deleted!")
                            }
                        }
                    } else {
                        print("No documents found.")
                    }
                }
            }
        }
    }
    //Update Functionality
    func update(){
        
    }
}





struct DisplayImagesScreen: View {
    @State private var dateAdded: String = ""
       var retrievedImages: [UIImage]

       var body: some View {
           NavigationView {
               List(retrievedImages, id: \.self) { image in
                   Image(uiImage: image)
                       .resizable()
                       .aspectRatio(contentMode: .fit)
                       .frame(width: UIScreen.main.bounds.width - 20, height: UIScreen.main.bounds.width - 20)
                       .cornerRadius(10)
                       .padding(5)

                   Text("Author: Mukesh")
                       .font(.caption)
                       .bold()
                       .foregroundColor(.gray)

                   Text("Date Added: \(dateAdded)")
                       .font(.caption)
                       .bold()
                       .foregroundColor(.gray)
               }
               .navigationBarTitle("All Images")
           }
       }

}




struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.selectedImage = selectedImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
