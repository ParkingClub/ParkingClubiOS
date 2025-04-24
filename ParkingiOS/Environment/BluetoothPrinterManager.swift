import CoreBluetooth

class BluetoothPrinterManager: NSObject, ObservableObject {
    static let shared = BluetoothPrinterManager()
    private var central: CBCentralManager!
    private var printer: CBPeripheral?
    private var writeChar: CBCharacteristic?
    private var pendingData: Data?
    
    // Si luego usas estos UUIDs para discoverServices, guárdalos para más adelante:
    private let printerServiceUUID   = CBUUID(string: "0000FFE0-0000-1000-8000-00805F9B34FB")
    private let printerWriteCharUUID = CBUUID(string: "0000FFE1-0000-1000-8000-00805F9B34FB")
    
    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }
    
    func send(data: Data) {
        pendingData = data
        if let p = printer, let c = writeChar {
            Swift.print("➡️ Ya conectado: enviando datos…")
            p.writeValue(data, for: c, type: .withResponse)
        } else {
            Swift.print("🟡 Iniciando scan sin filtrar servicios…")
            startScan()
        }
    }
    
    private func startScan() {
        guard central.state == .poweredOn else {
            Swift.print("🔴 Bluetooth no está listo: \(central.state.rawValue)")
            return
        }
        // Escanear TODOs los peripherals BLE
        central.scanForPeripherals(withServices: nil, options: nil)
        
        // Opcional: si en 5s no descubrimos nada, volver a filtrar…
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if self.printer == nil {
                Swift.print("🟡 Fallback: re-escanear sin filtro de servicio")
                self.central.scanForPeripherals(withServices: nil, options: nil)
            }
        }
    }
}

extension BluetoothPrinterManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Swift.print("🔄 centralManagerDidUpdateState: \(central.state.rawValue)")
        if central.state == .poweredOn, pendingData != nil {
            startScan()
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "sin nombre")
        Swift.print("✅ Descubierto peripheral: \(name) — RSSI: \(RSSI)")
        Swift.print("   advertisementData:", advertisementData)
        
        // Filtrar por el nombre que tu impresora realmente use:
        if name.contains("Printer") || name == "NombreDeTuImpresora" {
            printer = peripheral
            central.stopScan()
            central.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        Swift.print("➡️ Conectado a \(peripheral.name ?? "impresora"), descubriendo servicios…")
        peripheral.delegate = self
        peripheral.discoverServices([printerServiceUUID])
    }
}

extension BluetoothPrinterManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        if let err = error {
            Swift.print("❌ Error descubriendo servicios:", err)
            return
        }
        guard let services = peripheral.services else { return }
        Swift.print("🛎️ Servicios encontrados:", services.map(\.uuid))
        for s in services where s.uuid == printerServiceUUID {
            peripheral.discoverCharacteristics([printerWriteCharUUID], for: s)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        if let err = error {
            Swift.print("❌ Error discovering characteristics:", err)
            return
        }
        guard let chars = service.characteristics else { return }
        Swift.print("🔑 Characteristics en \(service.uuid):", chars.map(\.uuid))
        for c in chars where c.uuid == printerWriteCharUUID {
            writeChar = c
            Swift.print("➡️ Write characteristic encontrada: \(c.uuid), enviando pendingData…")
            if let d = pendingData {
                peripheral.writeValue(d, for: c, type: .withResponse)
                pendingData = nil
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let err = error {
            Swift.print("❌ Error writting value:", err)
        } else {
            Swift.print("✅ Valor escrito correctamente en \(characteristic.uuid)")
        }
    }
}
