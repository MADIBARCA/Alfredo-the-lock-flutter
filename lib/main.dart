import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'device_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final title = 'Alfredo the lock BLE';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      home: MyHomePage(title: title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Specify the device name so that only that device is displayed
  final String targetDeviceName = 'BLGate';

  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<ScanResult> scanResultList = [];
  bool _isScanning = false;

  @override
  initState() {
    super.initState();
    // reset bluetooth
    initBle();
  }

  void initBle() {
    // BLE Listener to get scan status
    flutterBlue.isScanning.listen((isScanning) {
      _isScanning = isScanning;
      setState(() {});
    });
  }

  /*
  Scan start/stop functions
  */
  scan() async {
    //Declare variable for initial rssi
    int lowestRssi = 1000;

    if (!_isScanning) {
      // If it is not being scanned,
      // delete the previously scanned list
      scanResultList.clear();
      // Start scanning, timeout 4 seconds
      flutterBlue.startScan(timeout: Duration(seconds: 4));
      // Scan result listener
      flutterBlue.scanResults.listen((results) {
        // Loop through the resulting value
        // scanResultList = results;
        results.asMap().forEach((index, element) {
          // Check if the device name is being searched for
          if (element.device.name.contains(targetDeviceName)) {
            // Compare the ID of the device to see if it is already registered
            if (scanResultList
                    .indexWhere((e) => e.device.id == element.device.id) <
                0) {
              // Find If it is a device name, it has lowest Rssi value and has never been registered in scanResultList, it is added to the list
              if (lowestRssi > element.rssi) {
                scanResultList.clear();
                lowestRssi = element.rssi;
                scanResultList.add(element);
              }
            }
          }
        });
        // UI update
        setState(() {});
      });
    } else {
      // If scanning, stop scanning
      flutterBlue.stopScan();
    }
  }

  /*
  * Functions for device-specific output from here on */
  /* Device signal value widget */
  Widget deviceSignal(ScanResult r) {
    return Text(r.rssi.toString());
  }

  /* device's MAC address widget */
  Widget deviceMacAddress(ScanResult r) {
    return Text(r.device.id.id);
  }

  /*Name of the device widget  */
  Widget deviceName(ScanResult r) {
    String name = '';

    if (r.device.name.isNotEmpty) {
      // If device name has a value
      name = r.device.name;
    } else if (r.advertisementData.localName.isNotEmpty) {
      // if advertisementData.localName has a value
      name = r.advertisementData.localName;
    } else {
      // if neither, name unknown...
      name = 'N/A';
    }
    return Text(name);
  }

  /* BLE icon widget */
  Widget leading(ScanResult r) {
    return CircleAvatar(
      child: Icon(
        Icons.bluetooth,
        color: Colors.white,
      ),
      backgroundColor: Colors.cyan,
    );
  }

  /* Function called when a device item is tapped */
  void onTap(ScanResult r) {
    // just print the name
    print('${r.device.name}');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceScreen(device: r.device)),
    );
  }

  /* Device item widget */
  Widget listItem(ScanResult r) {
    return ListTile(
      onTap: () => onTap(r),
      leading: leading(r),
      title: deviceName(r),
      subtitle: deviceMacAddress(r),
      trailing: deviceSignal(r),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        /* output device list */
        child: ListView.separated(
          itemCount: scanResultList.length,
          itemBuilder: (context, index) {
            return listItem(scanResultList[index]);
          },
          separatorBuilder: (BuildContext context, int index) {
            return Divider();
          },
        ),
      ),
      /* Search for devices or stop searching */
      floatingActionButton: FloatingActionButton(
        onPressed: scan,
        // Show stop icon if scanning, search icon if stopped
        child: Icon(_isScanning ? Icons.stop : Icons.search),
      ),
    );
  }
}
