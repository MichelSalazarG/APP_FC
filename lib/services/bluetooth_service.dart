import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService {
  BluetoothConnection? connection;

  Future<void> conectar(String address) async {
    connection = await BluetoothConnection.toAddress(address);
    print("Conectado al ESP32");
  }

  void escuchar(Function(String) onData) {
    connection?.input?.listen((data) {
      String mensaje = String.fromCharCodes(data);
      onData(mensaje);
    });
  }

  void desconectar() {
    connection?.dispose();
  }
}