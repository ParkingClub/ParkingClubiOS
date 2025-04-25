import Foundation
import CoreBluetooth

@objcMembers
final class PrinterSDKManager: NSObject {

    static let shared = PrinterSDKManager()
    private let ble = POSBLEManager.sharedInstance()!
    private var pendingData: Data?

    private override init() {
        super.init()
        ble.delegate = self
        let state = (ble.value(forKey: "manager") as? CBCentralManager)?
                     .state.rawValue ?? -1
        print("⚡️ initial BT state =", state)
    }

    func printTicket(placa: String,
                     fecha: String,
                     hora:  String,
                     ubicacion: String,
                     sucName: String)
    {
        let cmd = NSMutableData()

        // — encabezado —
        cmd.append(POSCommand.initializePrinter())
        // 1 == POS_ALIGNMENT_CENTER
        cmd.append(POSCommand.selectAlignment(1))
        cmd.append(POSCommand.selectOrCancleBoldModel(1))
        cmd.append(POSCommand.selectCharacterSize(0x11))
        cmd.append("PARKING CLUB\n".data(using: .utf8)!)

        cmd.append(POSCommand.selectCharacterSize(0))
        cmd.append(POSCommand.selectOrCancleBoldModel(0))
        cmd.append("Sucursal: \(sucName)\n".data(using: .utf8)!)
        cmd.append("Ubicacion: \(ubicacion)\n".data(using: .utf8)!)
        cmd.append(POSCommand.printAndFeedLine())

        // — cuerpo —
        cmd.append("Placa: \(placa)\n".data(using: .utf8)!)
        cmd.append("Fecha: \(fecha)  Hora: \(hora)\n".data(using: .utf8)!)
        cmd.append(POSCommand.printAndFeedForwardWhitN(3))

        // guardamos y lanzamos escaneo/conexión
        pendingData = cmd as Data
        scanAndConnect()
    }

    private func scanAndConnect() {
        if ble.printerIsConnect() {
            sendPendingIfPossible()
        } else {
            print("🔍 startScan()")
            ble.startScan()
        }
    }

    private func sendPendingIfPossible() {
        guard let data = pendingData, ble.printerIsConnect() else { return }
        // aqui va WITH, no WITHDATA
        ble.writeCommand(with: data)
        pendingData = nil
    }
}

extension PrinterSDKManager: POSBLEManagerDelegate {

    func poSbleCentralManagerDidUpdateState(_ state: Int) {
        print("⚡️ BT state =", state)
        if state == 5 { ble.startScan() }
    }

    func poSbleUpdatePeripheralList(_ peripherals: [Any]!,
                                    rssiList: [Any]!) {
        for (i,p) in peripherals.enumerated() {
            let per = p as! CBPeripheral
            let rssi = (rssiList[i] as? NSNumber)?.intValue ?? 0
            print("🎯 \(i) – \(per.name ?? "-")  RSSI \(rssi)")
        }
        if let first = peripherals.first as? CBPeripheral {
            ble.connectDevice(first)
        }
    }

    func poSbleConnect(_ peripheral: CBPeripheral!) {
        print("✅ Conectado a \(peripheral.name ?? "impresora")")
        sendPendingIfPossible()
    }

    func poSbleWriteValue(for characteristic: CBCharacteristic!,
                          error: Error!) {
        if let e = error {
            print("❌ Error imprimiendo:", e.localizedDescription)
        } else {
            print("✅ Ticket enviado")
        }
    }

    func poSbleDisconnectPeripheral(_ peripheral: CBPeripheral!,
                                    error: Error!) {
        print("🔌 Desconectado –", error?.localizedDescription ?? "ok")
    }
}
