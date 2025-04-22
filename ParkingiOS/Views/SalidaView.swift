//
//  SalidaView.swift
//  ParkingiOS
//
//  Created by mac on 4/17/25.
//

import SwiftUI

struct SalidaView: View {
    var body: some View {
        VStack {
            Text("Salida de Vehículos")
                .font(.title)
                .padding()
            Spacer()
        }
        .navigationTitle("Salida")
    }
}

#Preview {
    SalidaView()
}
