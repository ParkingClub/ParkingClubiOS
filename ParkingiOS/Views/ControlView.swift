import SwiftUI

struct ControlView: View {
    @StateObject private var viewModel = ControlViewModel()
    
    // ──────────────────────────────
    // MARK: - Body
    // ──────────────────────────────
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // ----- Contador rojo -----
                    HStack {
                        Text("Ingresos")
                        Spacer()
                        Text("\(viewModel.tickets.count)")
                    }
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding()
                    .background(Color("Primary"))
                    .cornerRadius(8)
                    .padding(.vertical, 12)
                    .padding(.top, 16)
                    
                    // ----- Encabezado tabla -----
                    HStack {
                        Text("Placa")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Hora de entrada")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                            .frame(width: 40)   // lugar para el icono
                    }
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    
                    // ----- Filas -----
                    content
                        .padding(.horizontal, 16)
                    
                    Spacer()
                }
            }
            .navigationTitle("Registros Vehículos")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.fetchTickets() }
        }
    }
    
    // MARK: - Tabla dinámica
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(.circular)
                .padding()
        } else if let error = viewModel.errorMessage {
            Text(error)
                .foregroundColor(.red)
                .padding()
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.tickets) { ticket in
                        HStack {
                            Text(ticket.placa)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(viewModel.formatDate(ticket.hentrada))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button {
//                                
                                viewModel.printTicket(ticket)
                            } label: {
                                Image(systemName: "printer.fill")
                                    .foregroundColor(.red)
                            }
                            .frame(width: 40)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }
}


#Preview {
    ControlView()
}
