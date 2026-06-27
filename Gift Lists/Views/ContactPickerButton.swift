import SwiftUI
import Contacts
import ContactsUI

#if canImport(UIKit)
struct SomeView: View {
    @State var contact: CNContact?
    
    var body: some View {
        VStack {
            Text("Selected: \(contact?.givenName ?? "")")
            ContactPickerButton(contact: $contact) {
                Label("Select Contact", systemImage: "person.crop.circle.fill")
                    .fixedSize()
            }
            .fixedSize()
            .buttonStyle(.borderedProminent)
        }
    }
}

struct SomeView_Previews: PreviewProvider {
    static var previews: some View {
        SomeView()
    }
}

struct ContactPickerButton<Label: View>: UIViewControllerRepresentable {
    class Coordinator: NSObject, CNContactPickerDelegate {
        var onCancel: () -> Void
        var viewController: UIViewController = .init()
        var picker = CNContactPickerViewController()
        
        @Binding var contact: CNContact?
        
        // Possible take a binding
        init<Label2: View>(contact: Binding<CNContact?>, onCancel: @escaping () -> Void, @ViewBuilder content: @escaping () -> Label2) {
            self._contact = contact
            self.onCancel = onCancel
            super.init()
            let button = Button<Label2>(action: showContactPicker, label: content)
            
            let hostingController = UIHostingController(rootView: button)
            
            hostingController.view?.backgroundColor = .clear
            hostingController.view?.sizeToFit()
            
            #if os(visionOS)
            (viewController.view?.frame).map {
                hostingController.view!.widthAnchor.constraint(equalToConstant: $0.width).isActive = true
                hostingController.view!.heightAnchor.constraint(equalToConstant: hostingController.view!.frame.height).isActive = true
                viewController.preferredContentSize = CGSize(width: viewController.view!.frame.width, height: hostingController.view!.frame.height)
            }
            #else
            (hostingController.view?.frame).map {
                hostingController.view!.widthAnchor.constraint(equalToConstant: $0.width).isActive = true
                hostingController.view!.heightAnchor.constraint(equalToConstant: $0.height).isActive = true
                viewController.preferredContentSize = $0.size
            }
            #endif
                
            hostingController.willMove(toParent: viewController)
            viewController.addChild(hostingController)
            viewController.view.addSubview(hostingController.view)

            hostingController.view.anchor(to: viewController.view)
            
            picker.delegate = self

        }
        
        func showContactPicker() {
            viewController.present(picker, animated: true)
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            onCancel()
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            self.contact = contact
        }
        
        func makeUIViewController() -> UIViewController {
            return viewController
        }
        
        func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<ContactPickerButton>) {
        }
    }
    
    @Binding var contact: CNContact?
    
    @ViewBuilder
    var content: () -> Label

    var onCancel: () -> Void
    
    init(contact: Binding<CNContact?>, onCancel: @escaping () -> () = {}, @ViewBuilder content: @escaping () -> Label) {
        self._contact = contact
        self.onCancel = onCancel
        self.content = content
    }
    
    func makeCoordinator() -> Coordinator {
        .init(contact: $contact, onCancel: onCancel, content: content)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        context.coordinator.makeUIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.updateUIViewController(uiViewController, context: context)
    }

}

fileprivate extension UIView {
    func anchor(to other: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.topAnchor.constraint(equalTo: other.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: other.bottomAnchor).isActive = true
        self.leadingAnchor.constraint(equalTo: other.leadingAnchor).isActive = true
        self.trailingAnchor.constraint(equalTo: other.trailingAnchor).isActive = true
    }
}
#endif
