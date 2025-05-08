import SwiftUI
import AVFoundation
import Vision

struct IngresoView: View {
    @State private var placaText: String = ""
    @State private var isShowingScanner: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var navigateToControl: Bool = false
    
    @State private var isLoading: Bool = false
        private let controlService = ControlService.shared

    
    
    private var printerSDK: PrinterSDKManager {
        PrinterSDKManager.shared
    }
    
    
    
    @StateObject private var loginVM = LoginViewModel()
    private let userManager = UserManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .autocapitalization(.allCharacters)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 15) {
                        Button(action: ingresar) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Ingresar")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(placaText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4 ? Color("Primary") : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(placaText.trimmingCharacters(in: .whitespacesAndNewlines).count < 4)
                        
                        Button(action: {
                            isShowingScanner = true
                        }) {
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
            }
            .navigationTitle("Ingreso de Vehículos")
            .sheet(isPresented: $isShowingScanner) {
                PlateScannerView(placaText: $placaText, isPresented: $isShowingScanner)
            }
            .navigationDestination(isPresented: $navigateToControl) {
                ControlView()
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func ingresar() {
            let placa = placaText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            guard placa.count >= 4 else {
                alert("La placa debe tener al menos 4 caracteres.")
                return
            }
            guard let empleadoId = userManager.idEmpleado else {
                alert("No se encontró el empleado.")
                return
            }
            guard let jwt = loginVM.getJWT() else {
                alert("No se encontró token JWT.")
                return
            }

            IngresoService.shared.ingresarTicket(placa: placa, empleadoId: empleadoId, jwt: jwt) { result in
                DispatchQueue.main.async(execute: {
                    switch result {
                    case .success:
                        self.performPrint(placa: placa)
                        navigateToControl = true
                    case .failure:
                        alert("No se pudo ingresar el ticket. Puede que ya exista uno con esa placa o haya un error en este momento.")
                    }
                })
            }
        }


    private func performPrint(placa: String) {
        guard let jwt = LoginViewModel().getJWT() else {
            // Manejo de error: no hay token
            print("❌ No se encontró el token de autenticación")
            return
        }
        guard let sucursalId = userManager.idsucursal else {
            // Manejo de error: no hay ID de sucursal
            print("❌ No se encontró el ID de sucursal")
            return
        }

       isLoading = true
        controlService.fetchSucursal(sucursalId: sucursalId, jwt: jwt) { result in
            DispatchQueue.main.async {
             self.isLoading = false

                switch result {
                case .failure(let error):
                    // Maneja el error de red o decodificación
                    print("❌ No se pudo obtener sucursal:", error.localizedDescription)

                case .success(let sucursal):
                    // Formatear fecha y hora
                    let now = Date()
                    let df = DateFormatter()
                    df.dateFormat = "dd/MM/yyyy"
                    let tf = DateFormatter()
                    tf.dateFormat = "HH:mm"

                    // Llamar al SDK con los datos de sucursal
                    self.printerSDK.printTicket(
                        placa:     placa,
                        fecha:     df.string(from: now),
                        hora:      tf.string(from: now),
                        ubicacion: sucursal.ubicacion,
                        sucName:   sucursal.nombre
                    )
                }
            }
        }
    }


        private func alert(_ message: String) {
            alertMessage = message
            showAlert = true
        }
    }

    private struct TextFieldSection: View {
        @Binding var placaText: String
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text("Ingrese la Placa:").font(.headline).foregroundColor(.primary)
                TextField("ABC123", text: $placaText)
                    .padding().background(Color.gray.opacity(0.1)).cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    .autocapitalization(.allCharacters)
            }
            .padding(.horizontal)
        }
    }

    
    
    // MARK: - PlateScannerView
    struct PlateScannerView: UIViewControllerRepresentable {
        @Binding var placaText: String
        @Binding var isPresented: Bool
        
        func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
        func makeUIViewController(context: Context) -> ScannerViewController {
            let vc = ScannerViewController()
            vc.delegate = context.coordinator
            return vc
        }
        func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
        
        class Coordinator: NSObject, ScannerDelegate {
            private let parent: PlateScannerView
            init(parent: PlateScannerView) { self.parent = parent }
            func didFind(plate: String) {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.parent.placaText = plate
                    self.parent.isPresented = false
                }
            }
        }
    }
    
    // MARK: - Scanner Delegate & Controller
    protocol ScannerDelegate: AnyObject {
        func didFind(plate: String)
    }
    
    class ScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
        weak var delegate: ScannerDelegate?
        private let session = AVCaptureSession()
        private var textRequest: VNRecognizeTextRequest!
        private var rectRequest: VNDetectRectanglesRequest!
        private var currentBuffer: CVPixelBuffer?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupCamera()
            setupVision()
            session.startRunning()
            addGuideFrame()
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            session.stopRunning()
        }
        
        private func addGuideFrame() {
            let guideLayer = CAShapeLayer()
            let size = CGSize(width: view.bounds.width * 0.8, height: view.bounds.height * 0.2)
            let origin = CGPoint(x: (view.bounds.width - size.width) / 2,
                                 y: (view.bounds.height - size.height) / 2)
            guideLayer.path = UIBezierPath(rect: CGRect(origin: origin, size: size)).cgPath
            guideLayer.lineWidth = 2.0
            guideLayer.strokeColor = UIColor.yellow.cgColor
            guideLayer.fillColor = UIColor.clear.cgColor
            view.layer.addSublayer(guideLayer)
        }
        
        private func setupCamera() {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }
            session.sessionPreset = .high
            session.addInput(input)
            try? device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
            if device.isExposureModeSupported(.continuousAutoExposure) { device.exposureMode = .continuousAutoExposure }
            device.unlockForConfiguration()
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.insertSublayer(previewLayer, at: 0)
            
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            session.addOutput(output)
        }
        
        private func setupVision() {
            textRequest = VNRecognizeTextRequest(completionHandler: handleDetectedText)
            textRequest.recognitionLevel = .accurate
            textRequest.usesLanguageCorrection = false
            
            rectRequest = VNDetectRectanglesRequest(completionHandler: handleDetectedRectangles)
            rectRequest.maximumObservations = 1
            rectRequest.minimumAspectRatio = 0.3
            rectRequest.maximumAspectRatio = 0.5
            rectRequest.quadratureTolerance = 15
            rectRequest.minimumSize = 0.2
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            currentBuffer = pixelBuffer
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            try? handler.perform([rectRequest])
        }
        
        private func handleDetectedRectangles(request: VNRequest, error: Error?) {
            guard let rectObs = (request.results as? [VNRectangleObservation])?.first,
                  let pixelBuffer = currentBuffer else { return }
            let box = rectObs.boundingBox
            let w = CVPixelBufferGetWidth(pixelBuffer)
            let h = CVPixelBufferGetHeight(pixelBuffer)
            let cropRect = CGRect(x: box.origin.x * CGFloat(w),
                                  y: (1 - box.origin.y - box.height) * CGFloat(h),
                                  width: box.width * CGFloat(w),
                                  height: box.height * CGFloat(h))
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer).cropped(to: cropRect)
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            try? handler.perform([textRequest])
        }
        
        private func handleDetectedText(request: VNRequest, error: Error?) {
            guard let obs = request.results as? [VNRecognizedTextObservation], !obs.isEmpty else { return }
            let bestCandidate = obs
                .flatMap { $0.topCandidates(3) }
                .filter { $0.confidence > 0.7 }
                .max(by: { $0.confidence < $1.confidence })
            guard let candidate = bestCandidate else { return }
            // Sanitize: eliminar espacios y guiones
            let raw = candidate.string.uppercased()
            let sanitized = raw.filter { $0.isLetter || $0.isNumber }
            // Patrón: 3 letras + 3 o 4 dígitos
            let pattern = "^[A-Z]{3}[0-9]{3,4}$"
            if sanitized.range(of: pattern, options: .regularExpression) != nil {
                delegate?.didFind(plate: sanitized)
            }
        }
    }

