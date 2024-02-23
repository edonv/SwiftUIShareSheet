//
//  ShareSheetTest.swift
//
//
//  Created by Edon Valdman on 2/23/24.
//

import SwiftUI

private struct ShareSheetTest: View {
    @State
    private var url: URL? = nil
    @State
    private var text: String = ""
    
    var body: some View {
        VStack {
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .textContentType(.URL)
            
            Button("Share") {
                url = URL(string: text)
            }
        }
        .padding()
        .shareSheet(item: $url)
    }
}

#Preview {
    ShareSheetTest()
}
