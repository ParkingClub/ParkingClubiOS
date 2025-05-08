import Foundation
import CoreBluetooth
import UIKit  // para generar el QR con CoreImage

@objcMembers
final class PrinterSDKManager: NSObject {
    static let shared = PrinterSDKManager()
    private let ble = POSBLEManager.sharedInstance()!
    private var pendingData: Data?
    private var connectionCompletion: ((Bool) -> Void)?
    private var scanTimeoutTimer: Timer?
    private var writeTimeoutTimer: Timer?

    /// Sólo intentar con estos nombres exactos
    private let targetPrinterNames = ["Parking001", "Printer001"]
    
    /// Tiempo máximo para escanear (en segundos)
    private let scanTimeoutInterval: TimeInterval = 10.0
    /// Tiempo máximo para escribir datos (en segundos)
    private let writeTimeoutInterval: TimeInterval = 1.0
    /// Máximo número de reintentos para enviar datos
    private let maxWriteRetries = 2

    private override init() {
        super.init()
        ble.delegate = self
        let state = (ble.value(forKey: "manager") as? CBCentralManager)?
                     .state.rawValue ?? -1
        print("⚡️ initial BT state =", state)
    }

    func printTicket(
        placa: String,
        fecha: String,
        hora: String,
        ubicacion: String,
        sucName: String
    ) {
        // Prepare print data
        let cmd = NSMutableData()

        // — ENCABEZADO —
        cmd.append(POSCommand.initializePrinter())           // Reinicia el motor de impresión
        cmd.append(POSCommand.selectAlignment(1))            // Centra el texto (0=izquierda,1=centro,2=derecha)
        cmd.append(POSCommand.selectOrCancleBoldModel(1))    // Activa negrita
        cmd.append(POSCommand.selectCharacterSize(0x10))     // Doble ancho y alto
//        cmd.append("PARKING CLUB\n".data(using: .utf8)!)      // Título
        cmd.append("\(sucName)\n".data(using: .utf8)!)
        // Restauramos tamaño normal
        cmd.append(POSCommand.selectCharacterSize(0))
        cmd.append(POSCommand.selectOrCancleBoldModel(0))

        // — DATOS SUCURSAL —
        cmd.append("Parking Club\n".data(using: .utf8)!)
        cmd.append("\(ubicacion)\n".data(using: .utf8)!)
        
        cmd.append("-------------------------\n".data(using: .utf8)!)

        // Título en negrilla
        cmd.append(POSCommand.selectOrCancleBoldModel(1))
        cmd.append("TICKET DE INGRESO\n".data(using: .utf8)!)
        cmd.append(POSCommand.selectOrCancleBoldModel(0))

        // Delimitador inferior
        cmd.append("-------------------------\n".data(using: .utf8)!)
        // — CUERPO DEL TICKET —
        cmd.append(POSCommand.selectAlignment(0))
        cmd.append("Placa: \(placa)\n".data(using: .utf8)!)
        cmd.append("Fecha: \(fecha)  Hora: \(hora)\n".data(using: .utf8)!)
        cmd.append(POSCommand.printAndFeedForwardWhitN(1))   // Avanza 3 líneas
        cmd.append(POSCommand.selectAlignment(1))
        // — CÓDIGO QR de la placa —
        if let qrCmd = escposQRCodeCommands(for: placa) {
            cmd.append(qrCmd)
            cmd.append(POSCommand.printAndFeedLine())
        }
        
        cmd.append(POSCommand.selectCharacterSize(0x00))
        // Si tu SDK soporta cambio de fuente, podrías usar Font B (más pequeña):
        cmd.append(Data([0x1B, 0x4D, 0x01])) // ESC M 1

        let info = """
        *Si excede 10 minutos despues de la  \
        hora registrada se cobrara la tarifa \
        completa de la siguiente hora.* \
        Este ticket acredita el ingreso de su vehiculo y \
        debe ser entregado al momento de retirarlo. \
        La empresa no se responsabiliza por los bienes \
        dejados dentro del vehiculo.
        """
        if let infoData = (info + "\n").data(using: .utf8) {
            cmd.append(infoData)
        }
        cmd.append(POSCommand.printAndFeedForwardWhitN(2))

        pendingData = cmd as Data

        // Start connection process and wait for result
        var retryCount = 0
        func attemptPrint() {
            scanAndConnect { [weak self] success in
                guard let self = self else { return }
                if success {
                    print("✅ Impresión iniciada")
                    self.sendPendingIfPossible {
                        if !$0 && retryCount < self.maxWriteRetries {
                            retryCount += 1
                            print("🔄 Reintentando impresión (\(retryCount)/\(self.maxWriteRetries))")
                            attemptPrint()
                        } else if !$0 {
                            print("❌ Falló la impresión después de \(self.maxWriteRetries) intentos")
                            self.connectionCompletion?(false)
                            self.connectionCompletion = nil
                        }
                    }
                } else {
                    print("❌ Falló la conexión a la impresora")
                    self.connectionCompletion?(false)
                    self.connectionCompletion = nil
                }
            }
        }
        attemptPrint()
    }

    
    
    func scanAndConnect(completion: @escaping (Bool) -> Void) {
        // Store completion handler
        connectionCompletion = completion

        if ble.printerIsConnect() {
            print("✅ Impresora ya conectada")
            completion(true)
            connectionCompletion = nil
        } else {
            print("🔍 startScan()")
            ble.startScan()
            // Start timeout timer
            scanTimeoutTimer?.invalidate()
            scanTimeoutTimer = Timer.scheduledTimer(withTimeInterval: scanTimeoutInterval, repeats: false) { [weak self] _ in
                print("⏳ Escaneo agotado")
                self?.ble.stopScan()
                self?.connectionCompletion?(false)
                self?.connectionCompletion = nil
                self?.scanTimeoutTimer = nil
            }
        }
    }

    private func sendPendingIfPossible(completion: @escaping (Bool) -> Void) {
        guard let data = pendingData else {
            print("❌ No hay datos para imprimir")
            completion(false)
            return
        }
        guard ble.printerIsConnect() else {
            print("❌ Impresora no conectada")
            completion(false)
            return
        }
        print("📤 Enviando datos a la impresora")
        ble.writeCommand(with: data)
        // Start write timeout timer
        writeTimeoutTimer?.invalidate()
        writeTimeoutTimer = Timer.scheduledTimer(withTimeInterval: writeTimeoutInterval, repeats: false) { [weak self] _ in
            print("⏳ Tiempo de escritura agotado")
            self?.writeTimeoutTimer = nil
            completion(false)
        }
    }

    /// Genera la secuencia ESC/POS para imprimir un QR code de la cadena dada
    private func escposQRCodeCommands(for text: String) -> Data? {
        guard let payload = text.data(using: .utf8) else { return nil }
        var d = Data()

        // 1) Select model: 2
        d.append(contentsOf: [0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x02, 0x00])
        // 2) Store data in symbol storage area
        let pL = UInt8((payload.count + 3) & 0xFF)
        let pH = UInt8((payload.count + 3) >> 8)
        d.append(contentsOf: [0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30])
        d.append(payload)
        // 3) Set module size (pixel size of each dot)
        d.append(contentsOf: [0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x09])
        // 4) Print the QR Code
        d.append(contentsOf: [0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30])

        return d
    }
}

extension PrinterSDKManager: POSBLEManagerDelegate {
    func poSbleCentralManagerDidUpdateState(_ state: Int) {
        print("⚡️ BT state =", state)
        if state == 5 { // PoweredOn
            ble.startScan()
        }
    }

    func poSbleUpdatePeripheralList(_ peripherals: [Any]!, rssiList: [Any]!) {
        for (i, pAny) in peripherals.enumerated() {
            let per = pAny as! CBPeripheral
            let name = per.name ?? "-"
            let rssi = (rssiList[i] as? NSNumber)?.intValue ?? 0
            print("🎯 \(i) – \(name)  RSSI \(rssi)")
        }
        for pAny in peripherals {
            let per = pAny as! CBPeripheral
            if let name = per.name, targetPrinterNames.contains(name) {
                print("✅ [scan] Coincidencia '\(name)', conectando…")
                ble.stopScan()
                scanTimeoutTimer?.invalidate()
                scanTimeoutTimer = nil
                ble.connectDevice(per)
                return
            }
        }
    }

    func poSbleConnect(_ peripheral: CBPeripheral!) {
        print("✅ Conectado a \(peripheral.name ?? "impresora")")
        scanTimeoutTimer?.invalidate()
        scanTimeoutTimer = nil
        connectionCompletion?(true)
        connectionCompletion = nil
    }

    func poSbleWriteValue(for characteristic: CBCharacteristic!, error: Error!) {
        writeTimeoutTimer?.invalidate()
        writeTimeoutTimer = nil
        if let e = error {
            print("❌ Error imprimiendo:", e.localizedDescription)
            connectionCompletion?(false)
            connectionCompletion = nil
        } else {
            print("✅ Ticket enviado")
            pendingData = nil
            connectionCompletion?(true)
            connectionCompletion = nil
        }
        ble.disconnectRootPeripheral()
    }

    func poSbleDisconnectPeripheral(_ peripheral: CBPeripheral!, error: Error!) {
        print("🔌 Desconectado –", error?.localizedDescription ?? "ok")
        if error != nil {
            writeTimeoutTimer?.invalidate()
            writeTimeoutTimer = nil
            connectionCompletion?(false)
            connectionCompletion = nil
        }
    }
}
