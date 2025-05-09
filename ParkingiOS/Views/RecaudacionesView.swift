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

// ─── Desglose por empleado, ahora con subtotales por tipo de pago ──
struct EmployeeBreakdown: Identifiable {
    let id = UUID()
    let name: String
    let total: Double
    let tickets: Int
    let efectivo: Double       // suma de pagos "E"
    let transferencia: Double  // suma de pagos "T"
    let tarjeta: Double        // suma de pagos "TC"
}

// ─── Modal sencillo de desglose ────────────────────────
//private struct BreakdownView: View {
//    let breakdown: [EmployeeBreakdown]
//    @Environment(\.dismiss) private var dismiss
//
//    var body: some View {
//        NavigationStack {
//            List(breakdown) { row in
//                VStack(alignment: .leading, spacing: 8) {
//                    HStack {
//                        Text(row.name).bold()
//                        Spacer()
//                        Text("$\(row.total, specifier: "%.2f")")
//                    }
//                    // Sub-desglose por forma de pago
//                    HStack(spacing: 16) {
//                        Text("Efectivo: $\(row.efectivo, specifier: "%.2f")")
//                        Text("Transferencia: $\(row.transferencia, specifier: "%.2f")")
//                        Text("Tarjeta: $\(row.tarjeta, specifier: "%.2f")")
//                    }
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                }
//                .padding(.vertical, 4)
//            }
//            .navigationTitle("Por Empleado")
//            .toolbar {
//                ToolbarItem(placement: .confirmationAction) {
//                    Button("Cerrar") { dismiss() }
//                }
//            }
//        }
//    }
//}
private struct BreakdownView: View {
    let breakdown: [EmployeeBreakdown]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(breakdown) { row in
                        VStack(spacing: 12) {
                            // Encabezado con nombre y total
                            HStack {
                                Text(row.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("$\(row.total, specifier: "%.2f")")
                                    .font(.title3).bold()
                                    .foregroundColor(.primary)
                            }

                            Divider()

                            // Desglose por forma de pago
                            HStack(spacing: 12) {
                                paymentItem(label: "Efectivo", amount: row.efectivo, color: .green)
                                paymentItem(label: "Transferencia", amount: row.transferencia, color: .blue)
                                paymentItem(label: "Tarjeta", amount: row.tarjeta, color: .orange)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            //.navigationTitle("Desglose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 1) Título personalizado
                    ToolbarItem(placement: .principal) {
                        Text("Desglose")
                            .font(.title2.weight(.bold))        // tipo y peso de fuente
                            .foregroundColor(Color("Primary"))   // tu color personalizado
                    }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Cerrar", systemImage: "xmark.circle.fill")
                            .font(.body)
                    }
                    .tint(Color("Primary"))
                }
            }
        }
    }

    // Componente reutilizable para cada forma de pago
    @ViewBuilder
    private func paymentItem(label: String, amount: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption).bold()
                .foregroundColor(color)
            Text("$\(amount, specifier: "%.2f")")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
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

    // — Lista de tickets (pre-filtrada por API) —
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

    // — Cómputo del desglose por empleado y tipo de pago —
    private func computeBreakdown() -> [EmployeeBreakdown] {
        let grouped = Dictionary(grouping: tickets, by: { $0.empleadoCierre })
        return grouped.map { name, list in
            let totE  = list.filter { $0.tipoPago == "E"  }.reduce(0) { $0 + $1.monto }
            let totT  = list.filter { $0.tipoPago == "T"  }.reduce(0) { $0 + $1.monto }
            let totTC = list.filter { $0.tipoPago == "TC" }.reduce(0) { $0 + $1.monto }
            let total = totE + totT + totTC
            return EmployeeBreakdown(
                name: name,
                total: total,
                tickets: list.count,
                efectivo: totE,
                transferencia: totT,
                tarjeta: totTC
            )
        }
        .sorted { $0.total > $1.total }
    }

    // — Formateador de fecha reutilizable —
    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df
    }
}

#Preview {
    RecaudacionesView()
}
