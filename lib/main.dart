import 'dart:io';
import 'dart:developer' as dev;

import 'package:fh5_helper/forza_display.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppBackend(),
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const MyHome(),
      ),
    ),
  );
}

class AppBackend with ChangeNotifier {
  int port = 0;
  RawDatagramSocket? socket;

  Future<RawDatagramSocket>? startSocket() {
    socket?.close();
    if (port == 0) {
      return null;
    }
    try {
      return RawDatagramSocket.bind(InternetAddress.anyIPv4, port)
          .then((clientSocket) {
        socket = clientSocket;
        return clientSocket;
      });
    } catch (e) {
      return null;
    }
  }
}

class MyHome extends StatefulWidget {
  const MyHome({Key? key}) : super(key: key);

  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  Future<RawDatagramSocket>? udpSocket;
  String socketStatusText = "inactivate";

  startDisplayPage() {
    var socket = context.read<AppBackend>().startSocket();
    if (socket == null) {
      dev.log("Failed to start display page");
      return;
    }
    socket.then((s) async {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return const DisplayPage();
        }),
      );
      // close socket when return from display page
      context.read<AppBackend>().socket?.close();
    });
  }

  setPort(String inputPort) {
    try {
      var appdata = context.read<AppBackend>();
      appdata.port = int.parse(inputPort);
    } on FormatException catch (e) {
      Fluttertoast.showToast(
        msg: 'port must be number!',
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FH5'),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Port',
              ),
              onSubmitted: (str) => setPort(str),
              onChanged: (str) => setPort(str),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: startDisplayPage,
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

class DisplayPage extends StatefulWidget {
  const DisplayPage({Key? key}) : super(key: key);

  @override
  _DisplayPageState createState() => _DisplayPageState();
}

class _DisplayPageState extends State<DisplayPage> {
  late var port = context.read<AppBackend>().port;
  double engine = 0;
  double accel = 0;
  double brake = 0;
  String receivedJsonData = "Waiting for data...";
  ForzaData forzaData = ForzaData();

  handleFH5Data(Datagram? d) {
    if (d == null) return;
    var jsonStr = String.fromCharCodes(d.data);
    forzaData.parseJsonStr(jsonStr);
    setState(() {
      receivedJsonData = jsonStr;
      engine = forzaData.currentEngineRpm / forzaData.engineMaxRpm;
      accel = forzaData.accel / 255;
      brake = forzaData.brake / 255;
    });
  }

  @override
  void initState() {
    super.initState();
    var socket = context.read<AppBackend>().socket;
    if (socket == null) {
      Navigator.pop(context);
      return;
    }
    socket.listen((event) => handleFH5Data(socket.receive()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data display'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              DashBoard(
                config: DashboardConfig(engine,
                    text: "Engine: ${forzaData.currentEngineRpm.toInt()} rpm"),
              ),
            ]),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BarDisplay(
                  config: BarDisplayConfig(
                    brake,
                    text: "Brake",
                  ),
                ),
                const SizedBox(width: 100),
                BarDisplay(
                  config: BarDisplayConfig(
                    accel,
                    text: "Accel",
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            Text('Port: $port'),
            Text('Data: \n$receivedJsonData'),
          ],
        ),
      ),
    );
  }
}
