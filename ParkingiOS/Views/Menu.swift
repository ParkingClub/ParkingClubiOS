import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var userManager: UserManager
    @State private var isLoggedIn: Bool = true

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        ZStack {
            // 1) Fondo blanco que rellena TODO el área, incluso notch/home‑indicator
            Color(.systemBackground)
                .ignoresSafeArea()

            NavigationStack {
                VStack(spacing: 20) {
                    // Header con bienvenida y avatar
                    HStack {
                        Text("Bienvenido, \(userManager.nombreEmpleado ?? "Usuario")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Spacer()
                        ZStack {
                            Circle()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color("Primary"))
                            Text(userManager.nombreEmpleado?.prefix(2).uppercased() ?? "US")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Grid de opciones
                    LazyVGrid(columns: columns, spacing: 20) {
                        NavigationLink(destination: IngresoView()) {
                            MenuOptionView(icon: "car", title: "Ingreso")
                        }
                        NavigationLink(destination: SalidaView()) {
                            MenuOptionView(icon: "car.fill", title: "Salida")
                        }
                        NavigationLink(destination: ControlView()) {
                            MenuOptionView(icon: "doc.text", title: "Control")
                        }
                        NavigationLink(destination: RecaudacionesView()) {
                            MenuOptionView(icon: "dollarsign.circle", title: "Recaudaciones")
                        }
                    }
                    .padding(.horizontal, 20)

                    // Botón de cerrar sesión
                    Button {
                        userManager.clearUserData()
                        isLoggedIn = false
                    } label: {
                        Text("Cerrar Sesión")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Primary"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)

                    Spacer()
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.light, for: .navigationBar)
                .toolbarBackground(Color.white, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .navigationDestination(isPresented: Binding(
                    get: { !isLoggedIn },
                    set: { isLoggedIn = !$0 }
                )) {
                    LoginView()
                }
            }
        }
        // 2) Oculta la barra de estado para que no quede espacio arriba
        .statusBar(hidden: true)
    }
}

struct MenuOptionView: View {
    let icon: String
    let title: String

    var body: some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(Color("Primary"))
                .padding()
                .background(Circle().fill(Color.white).shadow(radius: 2))

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    MenuView()
        .environmentObject(UserManager.shared)
}
