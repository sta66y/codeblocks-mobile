//
//  ResultView.swift
//  mobileAlg
//
//  Created by Hitsenok on 02.05.2025.
//

import SwiftUI

struct ResultView: View {
    var body: some View {
        VStack {
            Text("Результат программы")
                .font(.title)
                .padding()
        }
        .navigationTitle("Результат")
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ResultView()
        }
    }
}
