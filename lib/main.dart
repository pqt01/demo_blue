import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      home: BluetoothApp(),
    );
  }
}

class BluetoothApp extends StatelessWidget {
  const BluetoothApp({super.key});

  @override
  Widget build(BuildContext context) {
    final BluetoothController bluetoothController =
        Get.put(BluetoothController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth App'),
      ),
      body: Obx(() {
        return SingleChildScrollView(
            child: Column(
          children: [
            bluetoothController.connectedDevice.value == null
                ? const Center(child: Text('Scanning for devices...'))
                : ListView.builder(
                    itemCount: bluetoothController.services.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(bluetoothController.services[index].uuid
                            .toString()),
                      );
                    },
                  ),
            Column(
                children: bluetoothController.list
                    .map((e) => Text(e.device.name))
                    .toList()),
          ],
        ));
      }),
    );
  }
}

class BluetoothController extends GetxController {
  static const scanTimeoutSeconds = 4; // Constant for scan timeout
  RxList<ScanResult> list = <ScanResult>[].obs;
  FlutterBlue flutterBlue = FlutterBlue.instance;
  var connectedDevice = Rx<BluetoothDevice?>(null);
  var services = <BluetoothService>[].obs;

  @override
  void onInit() {
    super.onInit();
    scanForDevices();
  }

  /// Initiates scanning for Bluetooth devices.
  void scanForDevices() async {
    if (!await _requestBluetoothScanPermission()) {
      print("Bluetooth scan permission is denied.");
      return;
    }

    _startScanning();
  }

  /// Requests the user's permission to scan for Bluetooth devices.
  Future<bool> _requestBluetoothScanPermission() async {
    var status = await Permission.bluetoothScan.status;
    if (!status.isGranted) {
      status = await Permission.bluetoothScan.request();
    }
    return status.isGranted;
  }

  /// Starts scanning for Bluetooth devices.
  void _startScanning() {
    list.clear();
    flutterBlue
        .scan(timeout: const Duration(seconds: scanTimeoutSeconds))
        .listen(
      (scanResult) {
        // Add your scanning logic here
      },
      onError: (err) {
        // Handle errors related to scanning
        print("Error scanning for devices: $err");
      },
    );
  }

  /// Connects to a specified Bluetooth device.
  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      connectedDevice.value = device;
      discoverServices();
    } catch (e) {
      print("Failed to connect to device: $e");
    }
  }

  /// Discovers services offered by the connected Bluetooth device.
  void discoverServices() async {
    if (connectedDevice.value == null) return;

    try {
      var servicesList = await connectedDevice.value!.discoverServices();
      services.assignAll(servicesList);
    } catch (e) {
      print("Failed to discover services: $e");
    }
  }
}
