import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:device_info/device_info.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lightbox_tutorial/widgets/snackbar.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

void main() {
  return runApp(
    const GetMaterialApp(home: HomePage()),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
// Some state management stuff
  bool _foundDeviceWaitingToConnect = false;
  bool _scanStarted = false;
  bool _connected = false;
// Bluetooth related variables
  late DiscoveredDevice _ubiqueDevice;
  final flutterReactiveBle = FlutterReactiveBle();
  late StreamSubscription<DiscoveredDevice> _scanStream;
  late StreamSubscription<dynamic> _currentConnectionStream;

  var logsList = [];

  late QualifiedCharacteristic _rxCharacteristic;
// These are the UUIDs of your device
  final Uuid serviceUuid = Uuid.parse("cb55b93d-7813-4221-ac3b-df7e3f6cadc6");
  final Uuid serviceUuid1 = Uuid.parse("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Uuid characteristicUuid =
      Uuid.parse("f51fd052-8334-46e7-b09c-973a3f0568ff");
  final Uuid characteristicUuid1 =
      Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  final Uuid writableUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");

  final deviceslist = <DiscoveredDevice>[];

  void _startScan() async {
// Platform permissions handling stuff
    bool permGranted = false;
    setState(() {
      _scanStarted = true;
    });
    PermissionStatus permission;
    if (Platform.isAndroid) {
      permission = await LocationPermissions().requestPermissions();
      if (permission == PermissionStatus.granted) permGranted = true;
    } else if (Platform.isIOS) {
      permGranted = true;
    }

    // bool permGranted = true;
    // var status = await Permission.location.status;
    // if (status.isDenied) {
    //   permGranted = false;
    //   if (await Permission.location.request().isGranted) {
    //     permGranted = true;
    //   }
    // }

// Main scanning logic happens here ⤵️
    if (permGranted) {
      log('scamnn');

      _scanStream = flutterReactiveBle.scanForDevices(
          withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
        // Change this string to what you defined in Zephyr

        // print(device.name.toString());
        setState(() {
          final knownDeviceIndex =
              deviceslist.indexWhere((d) => d.id == device.id);
          if (knownDeviceIndex >= 0) {
            deviceslist[knownDeviceIndex] = device;
          } else {
            deviceslist.add(device);
          }

          // _scanStream.cancel();
        });
        if (device.name == '22050005R') {
          _ubiqueDevice = device;
          _foundDeviceWaitingToConnect = true;
        }
      });
    }
  }

  void _connectToDevice(id) {
    // We're done scanning, we can cancel it
    _scanStream.cancel();
    // Let's listen to our connection so we can make updates on a state change
    Stream<ConnectionStateUpdate> _currentConnectionStream = flutterReactiveBle
        .connectToAdvertisingDevice(
            id: id,
            prescanDuration: const Duration(seconds: 1),
            servicesWithCharacteristicsToDiscover: {
          serviceUuid1: [characteristicUuid1]
        },
            withServices: [
          serviceUuid1
        ]);
    _currentConnectionStream.listen((event) {
      switch (event.connectionState) {
        // We're connected and good to go!
        case DeviceConnectionState.connecting:
          log("-- Connecting to device --");
          getSnackbar(message: 'Connectiong.......');
          break;
        case DeviceConnectionState.connected:
          {
            _rxCharacteristic = QualifiedCharacteristic(
                serviceId: serviceUuid1,
                characteristicId: characteristicUuid1,
                deviceId: event.deviceId);
            setState(() {
              _foundDeviceWaitingToConnect = false;
              _connected = true;
            });
            log('connected');
            getSnackbar(message: 'Connected!!');
            break;
          }
        // Can add various state state updates on disconnect

        case DeviceConnectionState.disconnected:
          {
            log('disconnected');
            getSnackbar(bgColor: Colors.red, message: 'disconnected!!');

            break;
          }
        default:
      }
    });
  }

  void _partyTime() {
    if (_connected) {
      flutterReactiveBle
          .writeCharacteristicWithResponse(_rxCharacteristic, value: [
        0xff,
      ]);
    }
  }

  Future getAndroidSdk() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    print(androidInfo.version.sdkInt.toString());
  }

  @override
  void dispose() {
    // TODO: implement dispose
    StreamSubscriptionSerialDisposable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
        leading: const Icon(Icons.bluetooth),
        actions: const [
          Text('Connected', style: TextStyle(color: Colors.green)),
        ],
      ),
      body: SafeArea(
          child: Stack(
        children: [
          Column(
            children: [
              // MaterialButton(
              //     onPressed: () async {
              //       bool permGranted = true;
              //       var status = await Permission.location.status;
              //       if (status.isDenied) {
              //         permGranted = false;
              //         if (await Permission.location.request().isGranted) {
              //           permGranted = true;
              //         }
              //       }
              //     },
              //     child: const Text('data')),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: deviceslist.length,
                  padding: const EdgeInsets.only(bottom: 50),
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          border: Border.all(width: 1, color: Colors.grey),
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title:
                            Text("Name :" + deviceslist[index].name.toString()),
                        subtitle:
                            Text("Id :" + deviceslist[index].id.toString()),
                        onTap: () {
                          // _currentConnectionStream = flutterReactiveBle
                          //     .connectToDevice(
                          //   id: deviceslist[index].id,
                          //   connectionTimeout: const Duration(seconds: 15),
                          // )
                          //     .listen(
                          //   (connectionState) async {
                          //     switch (connectionState.connectionState) {
                          //       case DeviceConnectionState.connecting:
                          //         log("-- Connecting to device --");
                          //         break;

                          //       case DeviceConnectionState.connected:
                          //         log(" -- Connected --");
                          //         break;

                          //       case DeviceConnectionState.disconnecting:
                          //         log("-- disconnecting --");
                          //         break;

                          //       case DeviceConnectionState.disconnected:
                          //         log("-- disconnected --");
                          //         break;
                          //     }
                          //   },
                          //   onError: (error) {
                          //     print("error on connect $error \n");
                          //   },
                          // );
                          _connectToDevice(deviceslist[index].id);
                          log(deviceslist[index].toString());
                        },
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 2)),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 20,
                          ),
                          const Text("LOGS"),
                          ...List.generate(
                              logsList.length,
                              (index) => ListTile(
                                    title: Text('Log: ${logsList[index]}'),
                                  ))
                        ],
                      ),
                    ),
                  )),
            ],
          ),
          _connected
              ? const Align(
                  alignment: Alignment.topRight,
                  child: Text('Connected',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.green)))
              : Container(),
        ],
      )),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              deviceslist.clear();
              _startScan();
              // getAndroidSdk();
            },
            child: const Icon(Icons.search),
          ),
          const SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            onPressed: () {
              // flutterReactiveBle
              //     .connectToDevice(
              //   id: deviceslist[0].id.toString(),
              //   servicesWithCharacteristicsToDiscover: {
              //     serviceUuid: [characteristicUuid]
              //   },
              //   connectionTimeout: const Duration(seconds: 2),
              // )
              //     .listen((connectionState) {
              //   // Handle connection state updates
              //   log(connectionState.deviceId.toString());
              // }, onError: (Object error) {
              //   // Handle a possible error
              // });
              print('connect to devices');
              // flutterReactiveBle
              //     .connectToAdvertisingDevice(
              //         id: deviceslist[0].id,
              //         withServices: [serviceUuid],
              //         prescanDuration: const Duration(seconds: 5),
              //         connectionTimeout: const Duration(seconds: 2),
              //         servicesWithCharacteristicsToDiscover: {})
              //     .listen((connectionState) {
              //   // Handle connection state updates
              //   switch (connectionState.connectionState) {
              //     case DeviceConnectionState.connecting:
              //       setState(() {
              //         log('Connecting');
              //       });
              //       break;
              //     case DeviceConnectionState.disconnected:
              //       {
              //         setState(() {
              //           log('disConnected');
              //         });
              //         break;
              //       }
              //     case DeviceConnectionState.connected:
              //       {
              //         setState(() {
              //           log('Connected');
              //         });
              //         break;
              //       }
              //     default:
              //       setState(() {
              //         log('error');
              //       });
              //   }
              // }, onError: (dynamic error) {
              //   // Handle a possible error
              // });
            },
            child: const Icon(Icons.bluetooth),
          ),
          const SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            onPressed: () async {
              // print('object');
              final characteristic = QualifiedCharacteristic(
                  serviceId: serviceUuid1,
                  characteristicId: characteristicUuid1,
                  deviceId: "94:B9:7E:FB:03:6E");
              final response =
                  await flutterReactiveBle.readCharacteristic(characteristic);
              log(String.fromCharCodes(response));
              log(response.toString());
            },
            child: const Icon(Icons.read_more),
          ),
          const SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            onPressed: () {
              print('Write charactereistic');
              try {
                final characteristic = QualifiedCharacteristic(
                    serviceId: serviceUuid1,
                    characteristicId:
                        Uuid.parse('beb5483e-36e1-4688-b7f5-ea07361b26a8'),
                    deviceId: "94:B9:7E:FB:03:6E");
                List<int> val = [
                  74,
                  121,
                  111,
                  100,
                  101,
                  115,
                  104,
                  32,
                  115,
                  104,
                  97,
                  107,
                  121,
                  97
                ];
                final res = flutterReactiveBle.writeCharacteristicWithResponse(
                    characteristic,
                    value: 'aa'.codeUnits);
                print(String.fromCharCodes(val));
              } on Exception catch (e) {
                // TODO
                log(e.toString());
              }
            },
            tooltip: 'Write characteristic',
            child: const Icon(Icons.data_exploration_outlined),
          ),
          const SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            onPressed: () async {
              log('SUBSCRIBE');
              final characteristic = QualifiedCharacteristic(
                  serviceId: serviceUuid1,
                  characteristicId: characteristicUuid1,
                  // writableUuid,
                  deviceId: "94:B9:7E:FB:03:6E");
              flutterReactiveBle
                  .subscribeToCharacteristic(characteristic)
                  .listen((data) {
                // code to handle incoming data
                log(data.toString());
                // logsList.clear();

                setState(() {
                  logsList.add(data[0].toString());
                });
                // flutterReactiveBle.writeCharacteristicWithResponse(
                //     characteristic,
                //     value: [1, 0]);
              }, onError: (dynamic error) {
                // code to handle errors
              });
            },
            child: const Icon(Icons.ac_unit),
          )
        ],
      ),
    );
  }
}
