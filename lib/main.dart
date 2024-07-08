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

class BluetoothApp extends GetView<BluetoothController> {
  const BluetoothApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(BluetoothController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth App'),
      ),
      body: Obx(() {
        return SingleChildScrollView(
            child: Column(
          children: [
            ElevatedButton(
                onPressed: () {
                  controller.scanForDevices();
                },
                child: const Text('Scan')),
            controller.connectedDevice.value == null
                ? Center(child: Text(controller.message.value))
                : ListView.builder(
                    itemCount: controller.services.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(controller.services[index].uuid.toString()),
                      );
                    },
                  ),
            Column(
                children:
                    controller.list.map((e) => Text(e.device.name)).toList()),
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
  RxString message = ''.obs;
  var connectedDevice = Rx<BluetoothDevice?>(null);
  var services = <BluetoothService>[].obs;

  Future<bool> checkPermission() async {
    bool result = await _requestBluetoothScanPermission();
    return result;
  }

  /// Initiates scanning for Bluetooth devices.
  void scanForDevices() async {
    if (await checkPermission()) {
      Get.snackbar('Thong bao', 'Da co quyen');
      startScanning();
    } else {
      Get.snackbar('Thong bao', 'Chua co quyen');
    }
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
  void startScanning() {
    message.value = 'Scanning for devices...';
    list.clear();
    flutterBlue
        .scan(timeout: const Duration(seconds: scanTimeoutSeconds))
        .listen(
      (scanResult) {
        list.add(scanResult);
      },
      onError: (err) {
        message.value = "Error scanning for devices: $err";
      },
      onDone: () {
        message.value = 'Done';
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
