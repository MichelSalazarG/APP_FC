import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/bluetooth_service.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  BluetoothService bluetooth = BluetoothService();
  bool conectado = false;

  String tiempoFinal = "--";
  String fcFinal = "--";
  String dxFinal = "--";

  bool mostrarResultado = false;

  int tiempoRestante = 60;
  bool corriendo = false;

  List<FlSpot> puntos = [];
  double tiempoGrafica = 0;

  bool latido = false;

  String buffer = "";

  // 🔥 COLOR DINÁMICO
  Color colorActual = Colors.greenAccent;

  final List<double> ecgWave = [
    0, 1, 2, 1, 0,
    -1, 3, -2,
    1, 2, 1, 0
  ];
  int ecgIndex = 0;

  // 🔥 ANIMACIÓN DE COLOR
  void animarColor(Color nuevoColor) {
    Color inicio = colorActual;

    int pasos = 20;
    int duracion = 300;

    for (int i = 1; i <= pasos; i++) {
      Future.delayed(Duration(milliseconds: (duracion ~/ pasos) * i), () {
        if (!mounted) return;

        setState(() {
          colorActual = Color.lerp(inicio, nuevoColor, i / pasos)!;
        });
      });
    }
  }

  // 🔵 BLUETOOTH
  void mostrarDispositivos() async {
    List<BluetoothDevice> dispositivos =
        await FlutterBluetoothSerial.instance.getBondedDevices();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (context) {
        return ListView(
          children: dispositivos.map((d) {
            return ListTile(
              title: Text(d.name ?? "Sin nombre",
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(d.address,
                  style: TextStyle(color: Colors.green)),
              onTap: () async {
                Navigator.pop(context);
                await conectarBluetooth(d.address);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> conectarBluetooth(String address) async {
    await bluetooth.conectar(address);

    if (bluetooth.connection != null &&
        bluetooth.connection!.isConnected) {

      bluetooth.escuchar(procesarDatos);

      setState(() => conectado = true);
    }
  }

  void desconectarBluetooth() {
    bluetooth.desconectar();
    setState(() => conectado = false);
  }

  // 🔥 PROCESAR DATOS
  void procesarDatos(String data) {

    buffer += data;

    if (buffer.contains("\n")) {

      String mensaje = buffer.trim();
      buffer = "";

      print("📥 COMPLETO: [$mensaje]");

      // 📊 PULSOS
      if (mensaje.contains("PULSO")) {

        if (!corriendo) {
          corriendo = true;

          setState(() {
            dxFinal = "--";
            mostrarResultado = false;
          });

          // 🔥 RESET COLOR SUAVE
          animarColor(Colors.greenAccent);
        }

        setState(() => latido = true);

        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) setState(() => latido = false);
        });

        double valor =
            ecgWave[ecgIndex] + Random().nextDouble() * 0.3;

        setState(() {

          tiempoGrafica++;
          puntos.add(FlSpot(tiempoGrafica, valor));

          if (puntos.length > 100) {
            puntos.removeAt(0);
          }
        });

        ecgIndex = (ecgIndex + 1) % ecgWave.length;
      }

      // 🧠 RESULTADO FINAL
      if (mensaje.contains("Tiempo:")) {

        print("🔥 RESULTADO DETECTADO");

        try {
          List<String> partes = mensaje.split(',');

          String t = partes[0].split(':')[1];
          String f = partes[1].split(':')[1];
          String d = partes[2].split(':')[1];

          Color nuevoColor;

          if (d == "Bradicardia") nuevoColor = Colors.yellow;
          else if (d == "Taquicardia") nuevoColor = Colors.red;
          else nuevoColor = Colors.green;

          setState(() {
            tiempoFinal = t;
            fcFinal = f;
            dxFinal = d;
            mostrarResultado = true;
          });

          // 🔥 TRANSICIÓN AL RESULTADO
          animarColor(nuevoColor);

        } catch (e) {
          print("❌ ERROR PARSING: $e");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
         title: Text(
        "Monitor Cardíaco",
        style: TextStyle(
          color: Colors.white, // 🔥 aquí cambias el color
          fontWeight: FontWeight.bold,
        ),
      ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(
              Icons.bluetooth,
              color: conectado ? Colors.blue : Colors.white,
            ),
            onPressed: () {
              if (conectado) {
                desconectarBluetooth();
              } else {
                mostrarDispositivos();
              }
            },
          ),
        ],
      ),

      body: Column(
        children: [

          SizedBox(height: 10),

          // 💓 CORAZÓN DINÁMICO
          AnimatedScale(
            scale: latido ? 1.5 : 1.0,
            duration: Duration(milliseconds: 200),
            child: Icon(
              Icons.favorite,
              size: 70,
              color: colorActual,
            ),
          ),

          SizedBox(height: 10),

          // 📊 ECG
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: LineChart(
                LineChartData(
                  minY: -3,
                  maxY: 4,
                  minX: tiempoGrafica - 100,
                  maxX: tiempoGrafica,

                  backgroundColor: Colors.black,

                  gridData: FlGridData(show: true),

                  titlesData: FlTitlesData(show: false),

                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: colorActual),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: puntos,
                      isCurved: true,
                      barWidth: 3,

                      // 🔥 GRADIENTE DINÁMICO
                      gradient: LinearGradient(
                        colors: [
                          Colors.greenAccent,
                          colorActual,
                        ],
                      ),

                      dotData: FlDotData(show: false),

                      // 🔥 EFECTO GLOW
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            colorActual.withOpacity(0.3),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 10),

          // 📟 RESULTADOS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              columnaDato("Tiempo", mostrarResultado ? "$tiempoFinal s" : "--"),
              columnaDato("FC", mostrarResultado ? "$fcFinal ppm" : "--"),
              columnaDato("DX", mostrarResultado ? dxFinal : "--"),
            ],
          ),
        ],
      ),
    );
  }

  Widget columnaDato(String titulo, String valor) {
    return Column(
      children: [
        Text(titulo,
            style: TextStyle(color: Colors.green, fontSize: 16)),
        SizedBox(height: 5),
        Text(valor,
            style: TextStyle(
                color: colorActual,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}