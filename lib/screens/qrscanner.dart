import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bcard3/screens/readCard.dart';
import 'package:bcard3/screens/defaultHome.dart';

class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String result = "Leia um c";

  @override
  void initState() {
    super.initState();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData.code ?? "No QR code found";
      });

      if (result != "No QR code found") {
        await _navigateToReadCardUI(result);
      }
    });
  }

  Future<void> _navigateToReadCardUI(String scannedUserId) async {
    try {
      // Stop the QR scanner before navigating
      await controller?.pauseCamera();

      // Navigate to ReadCardUI and replace the current route
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReadCardUI(
            userId: scannedUserId,
            onClose: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => CardHome()),
                    (route) => false,
              );
            },
          ),
        ),
      );
    } catch (e) {
      print("Error navigating to ReadCardUI: $e");
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR Code Scanner')),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(child: Text(result)),
          ),
        ],
      ),
    );
  }
}
