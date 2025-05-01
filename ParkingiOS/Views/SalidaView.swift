import SwiftUI
import CodeScanner

// ─── 1) Métodos de pago ────────────────────────────────
enum PaymentMethod: String, CaseIterable, Identifiable {
    case transferencia = "Transferencia"
    case efectivo      = "Efectivo"
    case tarjeta       = "Tarjeta"
    
    var id: String { rawValue }
    var iconName: String {
        switch self {
        case .transferencia: return "building.columns"
        case .efectivo:      return "dollarsign.circle"
        case .tarjeta:       return "creditcard"
        }
    }
    var tpagoCode: String {
        switch self {
        case .transferencia: return "T"
        case .efectivo:      return "E"
        case .tarjeta:       return "TC"
        }
    }
}

// ─── 2) Fila de detalle ─────────────────────────────────
private struct DetailRow: View {
    let icon: String, label: String, value: String
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(Color("Primary"))
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .bold()
            }
            Spacer()
        }
    }
}

// ─── 3) Modal de detalle ──────────────────────────────
private struct DetalleModalView: View {
    let detalle: TarifaMontoDetalle
    @Binding var selectedMethod: PaymentMethod?
    let onClose: () -> Void
    let onProcess: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Encabezado
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Detalles de Salida")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color("Primary"))

            // Detalles
            VStack(spacing: 16) {
                DetailRow(icon: "car.fill",      label: "Placa",         value: detalle.placa)
                DetailRow(icon: "clock.fill",    label: "Entrada",      value: dateFormatter.string(from: detalle.hentrada))
                DetailRow(icon: "arrow.right",   label: "Salida",       value: dateFormatter.string(from: detalle.hsalida))
                DetailRow(icon: "dollarsign",    label: "Monto a Pagar", value: String(format: "$%.2f", detalle.monto))
            }
            .padding()
            .background(Color(.systemBackground))

            Divider().padding(.vertical, 8)

            // Selección de pago
            Text("Método de Pago")
                .font(.subheadline).bold()
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                ForEach(PaymentMethod.allCases) { method in
                    HStack {
                        Image(systemName: method.iconName)
                        Text(method.rawValue)
                        Spacer()
                        if selectedMethod == method {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("Primary"))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedMethod == method
                                    ? Color("Primary")
                                    : Color.gray.opacity(0.3),
                                    lineWidth: 1)
                    )
                    .onTapGesture { selectedMethod = method }
                }
            }
            .padding(.horizontal)

            Spacer(minLength: 0)

            // Botones
            HStack {
                Button(action: onClose) {
                    Label("Cerrar", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: onProcess) {
                    Label("Procesar", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedMethod != nil
                                    ? Color("Primary")
                                    : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedMethod == nil)
            }
            .padding()
        }
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding()
    }

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df
    }
}

// ─── 4) SalidaView completo con overlay mejorado ────────
struct SalidaView: View {
    @State private var placaText: String = ""
    @State private var tarifaDetalle: TarifaMontoDetalle?
    @State private var errorMsg: String?
    @State private var isShowingScanner: Bool = false
    @State private var selectedMethod: PaymentMethod? = nil

    @State private var showSuccessOverlay: Bool = false
    @State private var navigateToMenu: Bool = false

    @StateObject private var loginVM = LoginViewModel()
    private let userManager = UserManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
                    // … tu UI principal (icono, campo, botones) …
                    Image(systemName: "car.2.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .foregroundColor(Color("Primary"))
                        .padding(.vertical, 20)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ingrese la Placa:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        TextField("ABC123", text: $placaText)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            .autocapitalization(.allCharacters)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 15) {
                        Button(action: buscarTarifa) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Buscar")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Primary"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        Button(action: { isShowingScanner = true }) {
                            HStack {
                                Image(systemName: "camera")
                                Text("Cámara")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Primary"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .navigationTitle("Salida de Vehículos")
                .sheet(isPresented: $isShowingScanner) {
                    CodeScannerView(codeTypes: [.qr], completion: handleScan)
                }
                .sheet(item: $tarifaDetalle) { detalle in
                    DetalleModalView(
                        detalle: detalle,
                        selectedMethod: $selectedMethod,
                        onClose: {
                            tarifaDetalle = nil
                            selectedMethod = nil
                        },
                        onProcess: {
                            procesar(detalle: detalle)
                        }
                    )
                }
                .alert("Error", isPresented: Binding<Bool>(
                    get: { errorMsg != nil },
                    set: { if !$0 { errorMsg = nil } }
                )) {
                    Button("OK") { errorMsg = nil }
                } message: {
                    Text(errorMsg ?? "")
                }

                // ─── overlay de éxito ─────────────────
                if showSuccessOverlay {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)

                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.green)
                            .scaleEffect(showSuccessOverlay ? 1.2 : 0.8)
                            .animation(.easeInOut(duration: 0.6)
                                        .repeatCount(2, autoreverses: true),
                                       value: showSuccessOverlay)
                        Text("¡Salida procesada!")
                            .font(.title2).bold()
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .shadow(radius: 20)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            // nueva navegación
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
        }
    }

    // MARK: – Escaneo QR
    private func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        switch result {
        case .success(let scanResult):
            placaText = scanResult.string
            buscarTarifa()
        case .failure(let error):
            errorMsg = "Error de escaneo: \(error.localizedDescription)"
        }
    }

    // MARK: – Petición de tarifa
    private func buscarTarifa() {
        let placa = placaText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !placa.isEmpty else { errorMsg = "Ingresa una placa."; return }
        guard let sucursalId = userManager.idsucursal else {
            errorMsg = "No se encontró la sucursal."; return
        }
        guard let jwt = loginVM.getJWT() else {
            errorMsg = "No se encontró token JWT."; return
        }

        SalidaService.shared.fetchTarifaMontoDetalle(
            sucursalId: sucursalId,
            placa: placa,
            jwt: jwt
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let detalle): tarifaDetalle = detalle
                case .failure(let err):     errorMsg = err.localizedDescription
                }
            }
        }
    }

    // MARK: – Procesar y animar
    private func procesar(detalle: TarifaMontoDetalle) {
        guard let method = selectedMethod else { return }
        guard let jwt = loginVM.getJWT() else {
            errorMsg = "No se encontró token JWT."; return
        }
        guard let empleadoId = userManager.idEmpleado else {
            errorMsg = "No se encontró ID de empleado."; return
        }

        SalidaService.shared.procesarSalida(
            ticketId: detalle.id,
            mfinal: detalle.monto,
            tpago: method.tpagoCode,
            empleadoCierreId: empleadoId,
            jwt: jwt
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // cierra modal & resetea selección
                    tarifaDetalle = nil
                    selectedMethod = nil
                    // muestra overlay y luego navega
                    withAnimation { showSuccessOverlay = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation { showSuccessOverlay = false }
                        navigateToMenu = true
                    }
                case .failure(let err):
                    errorMsg = err.localizedDescription
                }
            }
        }
    }
}

#Preview {
    SalidaView()
}
