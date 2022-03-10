import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppBackend(),
      child: const MaterialApp(
        home: MyHome(),
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
      log("Failed to start display page");
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
  String receivedJsonData = "Waiting for data...";

  handleFH5Data(Datagram? d) {
    if (d == null) return;
    setState(() {
      receivedJsonData = String.fromCharCodes(d.data);
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
            Text('Port: $port'),
            Text('Data: \n$receivedJsonData'),
          ],
        ),
      ),
    );
  }
}
