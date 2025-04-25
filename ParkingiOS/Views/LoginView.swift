import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var userManager: UserManager
    @StateObject private var viewModel = LoginViewModel()
    @State private var showPassword = false
    
    // Ancho máximo de los campos / botón
    private let formWidth: CGFloat = 300          // cámbialo si quieres más / menos

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer(minLength: 0)

                // Logo + título
                VStack(spacing: 16) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)

                    Text("Parking Club")
                        .font(.system(size: 28, weight: .bold))
                }
                
                // ---------- CAMPOS ----------
                VStack(spacing: 20) {
                    inputField(
                        systemIcon: "person.fill",
                        placeholder: "Usuario",
                        text: $viewModel.username,
                        isSecure: false
                    )
                    
                    inputField(
                        systemIcon: "lock.fill",
                        placeholder: "Contraseña",
                        text: $viewModel.password,
                        isSecure: !showPassword,
                        trailingIcon: showPassword ? "eye.slash.fill" : "eye.fill",
                        trailingAction: { showPassword.toggle() }
                    )
                }
                // Fija el ancho aquí para que todo esté centrado
                .frame(maxWidth: formWidth)
                
                // ---------- BOTÓN ----------
                Button(action: viewModel.login) {
                    Text("Ingresar")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(viewModel.isLoading ? Color.gray : Color("Primary"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .frame(maxWidth: formWidth)
                .disabled(viewModel.isLoading)
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal)   // margen lateral global
        }
        .navigationBarHidden(true)
        .alert("Error de autenticación", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Credenciales inválidas")
        }
    }
    
    // MARK: - Campo reutilizable
    @ViewBuilder
    private func inputField(systemIcon: String,
                            placeholder: String,
                            text: Binding<String>,
                            isSecure: Bool,
                            trailingIcon: String? = nil,
                            trailingAction: (() -> Void)? = nil) -> some View {
        
        HStack {
            Image(systemName: systemIcon)
                .foregroundColor(.gray)
            
            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            // Relleno visual para que los dos campos queden iguales
            if let trailingIcon {
                Button(action: trailingAction ?? {}) {
                    Image(systemName: trailingIcon)
                        .foregroundColor(.gray)
                }
            } else {
                // “icono fantasma” invisible para igualar el ancho
                Image(systemName: systemIcon)
                    .opacity(0)
                    .frame(width: 24)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
}

#Preview {
    LoginView()
        .environmentObject(UserManager.shared)
}
