import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';

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
  RxList<ScanResult> list = <ScanResult>[].obs;
  FlutterBlue flutterBlue = FlutterBlue.instance;
  var connectedDevice = Rx<BluetoothDevice?>(null);
  var services = <BluetoothService>[].obs;

  @override
  void onInit() {
    super.onInit();
    scanForDevices();
  }

  void scanForDevices() {
    list.clear();
    flutterBlue.scan(timeout: Duration(seconds: 4)).listen((scanResult) {
      list.add(scanResult);
      if (scanResult.device.name == 'gDevice-beacon') {
        connectToDevice(scanResult.device);
      }
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    connectedDevice.value = device;
    discoverServices();
  }

  void discoverServices() async {
    if (connectedDevice.value != null) {
      var servicesList = await connectedDevice.value!.discoverServices();
      services.assignAll(servicesList);
    }
  }
}
