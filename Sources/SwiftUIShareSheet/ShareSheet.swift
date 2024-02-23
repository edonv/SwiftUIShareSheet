//
//  ShareSheet.swift
//
//
//  Created by SwiftUIBackports
//


import SwiftUI

#if os(macOS) || os(iOS)
extension View {
    @ViewBuilder
    public func shareSheet<Data>(item activityItems: Binding<Data?>) -> some View where Data: RandomAccessCollection, Data.Element == Any {
        background(ShareSheet(item: activityItems))
    }
    
    @ViewBuilder
    private func shareSheet(
        item activityItem: Binding<Any?>
    ) -> some View {
        shareSheet(item: Binding<CollectionOfOne<Any>?>(get: {
            if let item = activityItem.wrappedValue {
                return CollectionOfOne(item as Any)
            } else {
                return nil as CollectionOfOne<Any>?
            }
        }, set: { newValue in
            activityItem.wrappedValue = newValue?.first
        }))
    }
    
    @ViewBuilder
    public func shareSheet<Data>(
        item activityItem: Binding<Data?>
    ) -> some View {
        shareSheet(item: .init(get: {
            (activityItem.wrappedValue != nil ? activityItem.wrappedValue : nil) as Any?
        }, set: { newValue in
            activityItem.wrappedValue = newValue as? Data
        }))
    }
}
#endif

private struct ShareSheet<Data> where Data: RandomAccessCollection /*Shareable*/ {
    @Binding var item: Data?
    
    init(item: Binding<Data?>) {
        _item = item
    }
}

#if os(macOS)
extension ShareSheet: NSViewRepresentable {
    public func makeNSView(context: Context) -> SourceView {
        SourceView(item: $item)
    }

    public func updateNSView(_ view: SourceView, context: Context) {
        view.item = $item
    }

    final class SourceView: NSView, NSSharingServicePickerDelegate, NSSharingServiceDelegate {
        var picker: NSSharingServicePicker?

        var item: Binding<Data?> {
            didSet {
                updateControllerLifecycle(
                    from: oldValue.wrappedValue,
                    to: item.wrappedValue
                )
            }
        }

        init(item: Binding<Data?>) {
            self.item = item
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func updateControllerLifecycle(from oldValue: Data?, to newValue: Data?) {
            switch (oldValue, newValue) {
            case (.none, .some):
                presentController()
            case (.some, .none):
                dismissController()
            case (.some, .some), (.none, .none):
                break
            }
        }

        func presentController() {
            picker = NSSharingServicePicker(items: item.wrappedValue?.map { $0 } ?? [])
            picker?.delegate = self
            DispatchQueue.main.async {
                guard self.window != nil else { return }
                self.picker?.show(relativeTo: self.bounds, of: self, preferredEdge: .minY)
            }
        }

        func dismissController() {
            item.wrappedValue = nil
        }

        func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, delegateFor sharingService: NSSharingService) -> NSSharingServiceDelegate? {
            return self
        }

        public func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
            sharingServicePicker.delegate = nil
            dismissController()
        }

        func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
            proposedServices
        }
    }
}

#elseif os(iOS)

extension ShareSheet: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Representable {
        Representable {
            item = nil
        }
    }

    func updateUIViewController(_ controller: Representable, context: Context) {
        controller.item = item
    }
}

private extension ShareSheet {
    final class Representable: UIViewController, UIAdaptivePresentationControllerDelegate, UISheetPresentationControllerDelegate {
        private weak var controller: UIActivityViewController?

        var item: Data? {
            didSet {
                updateControllerLifecycle(
                    from: oldValue,
                    to: item
                )
            }
        }
        
        var completion: () -> Void

        init(completion: @escaping () -> Void) {
            self.item = nil
            self.completion = completion
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func updateControllerLifecycle(from oldValue: Data?, to newValue: Data?) {
            switch (oldValue, newValue) {
            case (.none, .some):
                presentController()
            case (.some, .none):
                dismissController()
            case (.some, .some), (.none, .none):
                break
            }
        }

        private func presentController() {
            let controller = UIActivityViewController(activityItems: item?.map { $0 } ?? [], applicationActivities: nil)
            controller.presentationController?.delegate = self
            controller.popoverPresentationController?.permittedArrowDirections = .any
            controller.popoverPresentationController?.sourceRect = view.bounds
            controller.popoverPresentationController?.sourceView = view
            controller.completionWithItemsHandler = { [weak self] _, _, _, _ in
                self?.completion()
                self?.dismiss(animated: true)
            }
            present(controller, animated: true)
            self.controller = controller
        }

        private func dismissController() {
            guard let controller else { return }
            controller.presentingViewController?.dismiss(animated: true)
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            dismissController()
        }
    }
}
#endif
