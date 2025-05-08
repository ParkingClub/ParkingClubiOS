//  ParkingiOS
//
//  Created by mac on 4/17/25.
//

import SwiftUI
// ─── Filtro de fecha ───────────────────────────────────
enum DateFilter: String, CaseIterable, Identifiable {
    case hoy, ayer, semana
    var id: String { rawValue }
    var title: String {
        switch self {
        case .hoy:    return "Hoy"
        case .ayer:   return "Ayer"
        case .semana: return "Semana"
        }
    }
}

// ─── Desglose por empleado ─────────────────────────────
struct EmployeeBreakdown: Identifiable {
    let id = UUID()
    let name: String
    let total: Double
    let tickets: Int
}

// ─── Modal sencillo de desglose ────────────────────────
private struct BreakdownView: View {
    let breakdown: [EmployeeBreakdown]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(breakdown) { row in
                HStack {
                    Text(row.name)
                    Spacer()
                    Text("$\(row.total, specifier: "%.2f")")
                    Text("(\(row.tickets))")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Por Empleado")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

// ─── Vista principal ───────────────────────────────────
struct RecaudacionesView: View {
    @State private var tickets: [TicketRecord] = []
    @State private var filter: DateFilter      = .hoy
    @State private var errorMsg: String?       = nil
    @State private var showBreakdown           = false

    @StateObject private var loginVM = LoginViewModel()
    private let userManager = UserManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header
                filterButtons
                ticketList
            }
            .navigationTitle("Recaudaciones")
            .onAppear(perform: loadData)
            .sheet(isPresented: $showBreakdown) {
                BreakdownView(breakdown: computeBreakdown())
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { errorMsg != nil },
                set: { if !$0 { errorMsg = nil } }
            )) {
                Button("OK") { errorMsg = nil }
            } message: {
                Text(errorMsg ?? "")
            }
        }
    }

    // — Header con total y botón de desglose —
    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Registros")
                    .font(.caption).foregroundColor(.secondary)
                Text("\(tickets.count)")
                    .font(.title2).bold()
            }
            Spacer()
            HStack(spacing: 4) {
                VStack(alignment: .trailing) {
                    Text("Total Recaudado")
                        .font(.caption).foregroundColor(.secondary)
                    Text("$\(totalSum, specifier: "%.2f")")
                        .font(.title2).bold()
                }
                Button {
                    showBreakdown = true
                } label: {
                    Image(systemName: "eye.fill")
                        .font(.title2)
                        .padding(8)
                }
            }
        }
        .padding(.horizontal)
    }

    // — Botones Hoy/Ayer/Semana que recargan datos —
    private var filterButtons: some View {
        HStack {
            ForEach(DateFilter.allCases) { f in
                Button(action: {
                    filter = f
                    loadData()
                }) {
                    Text(f.title)
                        .font(.subheadline).bold()
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(filter == f ? Color("Primary") : Color.gray.opacity(0.2))
                        .foregroundColor(filter == f ? .white : .primary)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
    }

    // — Lista de tickets (ya filtrados por la API) —
    private var ticketList: some View {
        List(tickets) { t in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(t.placa).bold()
                    Text("Entrada: \(t.hentrada, formatter: dateFormatter)")
                        .font(.caption).foregroundColor(.secondary)
                    Text("Salida:  \(t.hsalida, formatter: dateFormatter)")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(t.monto, specifier: "%.2f")").bold()
                    Text(t.tipoPago)
                        .font(.caption)
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.plain)
    }

    // — Suma total de monto —
    private var totalSum: Double {
        tickets.reduce(0) { $0 + $1.monto }
    }

    // — Llamada al servicio según el filter seleccionado —
    private func loadData() {
        guard let sucursalId = userManager.idsucursal,
              let jwt        = loginVM.getJWT() else {
            errorMsg = "Faltan credenciales"
            return
        }
        RecaudacionesService.shared.fetchTickets(
            estado: 1,
            sucursalId: sucursalId,
            periodo: filter.rawValue,
            jwt: jwt
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let arr):
                    tickets = arr
                case .failure(let err):
                    errorMsg = err.localizedDescription
                }
            }
        }
    }

    // — Formateador de fecha reutilizable —
    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df
    }

    // — Cómputo del desglose por empleado —
    private func computeBreakdown() -> [EmployeeBreakdown] {
        let grouped = Dictionary(grouping: tickets, by: { $0.empleadoCierre })
        return grouped.map { name, list in
            let tot = list.reduce(0) { $0 + $1.monto }
            return EmployeeBreakdown(
                name: name,
                total: tot,
                tickets: list.count
            )
        }
        .sorted { $0.total > $1.total }
    }
}

#Preview {
    RecaudacionesView()
}
