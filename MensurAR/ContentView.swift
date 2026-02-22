//
//  ContentView.swift
//  MensurAR
//
//  Created by Cem Akkaya on 22/02/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        
        ARViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
