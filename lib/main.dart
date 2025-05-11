import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: NFCReaderScreen());
  }
}

class NFCReaderScreen extends StatefulWidget {
  @override
  _NFCReaderScreenState createState() => _NFCReaderScreenState();
}

class _NFCReaderScreenState extends State<NFCReaderScreen> {
  @override
  void initState() {
    super.initState();
  }

  String nfcData = '';

  Future<void> startNFC() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    print("Checking NFC availability...");
    if (!isAvailable) {
      setState(() {
        nfcData = "NFC is not available on this device";
      });
      return;
    }

    setState(() {
      nfcData = "Scanning...";
    });

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            setState(() {
              nfcData = "Not an NDEF tag";
            });
            NfcManager.instance.stopSession();
            return;
          }

          final ndefMessage = await ndef.read();
          final records = ndefMessage.records;

          // Look for URI records
          for (var record in records) {
            final uri = Uri.decodeFull(
              String.fromCharCodes(record.payload.sublist(1)),
            );
            setState(() {
              nfcData = uri;
            });
            NfcManager.instance.stopSession();
            return;
          }

          setState(() {
            nfcData = "No URL found on the tag";
          });
          NfcManager.instance.stopSession();
        } catch (e) {
          setState(() {
            nfcData = "Error reading tag: $e";
          });
          NfcManager.instance.stopSession();
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> writeUrlToNfcTag(String url) async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      throw Exception("NFC is not available on this device.");
    }

    await NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            throw Exception('Tag is not NDEF writable');
          }

          // Create a URI NDEF record
          final uriRecord = NdefRecord.createUri(Uri.parse(url));
          final message = NdefMessage([uriRecord]);

          // Write the message
          await ndef.write(message);

          debugPrint("✅ URL written to NFC tag successfully.");
          NfcManager.instance.stopSession();
        } catch (e) {
          debugPrint("❌ Failed to write: $e");
          NfcManager.instance.stopSession(errorMessage: e.toString());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("NFC Reader")),
      body: Column(
        children: [
          Text(nfcData),
          Center(
            child: ElevatedButton(
              onPressed: startNFC, // Trigger the emulator when pressed
              child: Text("Read NFC"),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed:
                  () => writeUrlToNfcTag("https://github.com/naimulhassan2001"),
              // Trigger the emulator when pressed
              child: Text("Write NFC"),
            ),
          ),
        ],
      ),
    );
  }
}
