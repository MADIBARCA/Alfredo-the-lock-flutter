import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceScreen extends StatefulWidget {
  DeviceScreen({Key? key, required this.device}) : super(key: key);
  // Receive device information
  final BluetoothDevice device;

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  // flutterBlue
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  // Connection status display string
  String stateText = 'Connecting';

  // Connect button string
  String connectButtonText = 'Disconnect';

  // For saving the current connection state
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;

  // Connection state listener handle to release listener when screen is
  StreamSubscription<BluetoothDeviceState>? _stateListener;

  //Variable for storing service information of connected devices
  List<BluetoothService> bluetoothService = [];

  @override
  initState() {
    super.initState();
    // Register a state-conencted listener
    _stateListener = widget.device.state.listen((event) {
      debugPrint('event :  $event');
      if (deviceState == event) {
        // ignore if state is the same
        return;
      }
      // Change connection state information
      setBleConnectionState(event);
    });
    // start connection
    connect();
  }

  @override
  void dispose() {
    // Dispose the state
    _stateListener?.cancel();
    // Disconnect
    disconnect();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      // Only update when the screen is mounted
      super.setState(fn);
    }
  }

  /* Update connection state */
  setBleConnectionState(BluetoothDeviceState event) {
    switch (event) {
      case BluetoothDeviceState.disconnected:
        stateText = 'Disconnected';
        // change button state
        connectButtonText = 'Connect';
        break;
      case BluetoothDeviceState.disconnecting:
        stateText = 'Disconnecting';
        break;
      case BluetoothDeviceState.connected:
        stateText = 'Connected';
        // change button state
        connectButtonText = 'Disconnect';
        break;
      case BluetoothDeviceState.connecting:
        stateText = 'Connecting';
        break;
    }
    // Save previous state event
    deviceState = event;
    setState(() {});
  }

  /* start connection */
  Future<bool> connect() async {
    Future<bool>? returnValue;
    setState(() {
      /* Change state display to Connecting */
      stateText = 'Connecting';
    });

    /* 
    Set timeout to 15 seconds (15000ms) and disable autoconnect.
    Note that if autoconnect is set to true, the connection may be delayed.
     */
    await widget.device
        .connect(autoConnect: false)
        .timeout(Duration(milliseconds: 15000), onTimeout: () {
      // timeout occurs
      // set returnValue to false
      returnValue = Future.value(false);
      debugPrint('timeout failed');

      // Change the connection state to disconnected
      setBleConnectionState(BluetoothDeviceState.disconnected);
    }).then((data) async {
      bluetoothService.clear();
      if (returnValue == null) {
        // If returnValue is null, timeout did not occur, so connection suceeded
        debugPrint('connection successful');
        print('start discover service');
        List<BluetoothService> bleServices =
            await widget.device.discoverServices();
        setState(() {
          bluetoothService = bleServices;
        });
        // Print each property to debug
        for (BluetoothService service in bleServices) {
          print('============================================');
          print('Service UUID: ${service.uuid}');
          for (BluetoothCharacteristic c in service.characteristics) {
            print('\tcharacteristic UUID: ${c.uuid.toString()}');
            //Display the properties of each characteristics.
            //Data writing properties
            print('\t\twrite: ${c.properties.write}');
            // data read property
            print('\t\tread: ${c.properties.read}');
            //Get data property
            print('\t\tnotify: ${c.properties.notify}');
            // print whether receiving data is on
            print('\t\tisNotifying: ${c.isNotifying}');
            // property to check if data was written when writing
            print(
                '\t\twriteWithoutResponse: ${c.properties.writeWithoutResponse}');
            // get data (return whether or not it was received) property
            print('\t\tindicate: ${c.properties.indicate}');
          }
        }
        returnValue = Future.value(true);
      }
    });

    return returnValue ?? Future.value(false);
  }

  /* Disconnect */
  void disconnect() {
    try {
      setState(() {
        stateText = 'Disconnecting';
      });
      widget.device.disconnect();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        /* device name */
        title: Text(widget.device.name),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              /* Connected state */
              Text('$stateText'),
              /* Connect and disconnect buttons */
              OutlinedButton(
                  onPressed: () {
                    if (deviceState == BluetoothDeviceState.connected) {
                      /* Connect, if connected disconnect */
                      disconnect();
                    } else if (deviceState ==
                        BluetoothDeviceState.disconnected) {
                      /* Connect if disconnected */
                      connect();
                    }
                  },
                  child: Text(connectButtonText)),
            ],
          ),

          /* Display service information of connected BLE */
          Expanded(
            child: ListView.separated(
              itemCount: bluetoothService.length,
              itemBuilder: (context, index) {
                return listItem(bluetoothService[index]);
              },
              separatorBuilder: (BuildContext context, int index) {
                return Divider();
              },
            ),
          ),
        ],
      )),
    );
  }

  /* Each characteristic information dispay widget */
  Widget characteristicInfo(BluetoothService r) {
    String name = '';
    String properties = '';
    // Take out each characteristic and display it one by one
    for (BluetoothCharacteristic c in r.characteristics) {
      properties = '';
      name += '\t\t${c.uuid}\n';
      if (c.properties.write) {
        properties += 'Write ';
      }
      if (c.properties.read) {
        properties += 'Read ';
      }
      if (c.properties.notify) {
        properties += 'Notify ';
      }
      if (c.properties.writeWithoutResponse) {
        properties += 'WriteWR ';
      }
      if (c.properties.indicate) {
        properties += 'Indicate ';
      }
      name += '\t\t\tProperties: $properties\n';
    }
    return Text(name);
  }

  /* Service UUID widget */
  Widget serviceUUID(BluetoothService r) {
    String name = '';
    name = r.uuid.toString();
    return Text(name);
  }

  /* Service information item widget */
  Widget listItem(BluetoothService r) {
    return ListTile(
      onTap: null,
      title: serviceUUID(r),
      subtitle: characteristicInfo(r),
    );
  }
}
