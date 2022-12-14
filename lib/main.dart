import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:device_info/device_info.dart';
import 'package:get/get.dart';
import 'package:lightbox_tutorial/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final txtcontroller = TextEditingController();
  final namecontroller = TextEditingController();
  var logsList = [];
  var connectedDeviceId = '';
  late QualifiedCharacteristic _rxCharacteristic;
// These are the UUIDs of your device
  final Uuid serviceUuid = Uuid.parse("cb55b93d-7813-4221-ac3b-df7e3f6cadc6");
  final Uuid serviceUuid1 = Uuid.parse("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Uuid characteristicUuid =
      Uuid.parse("f51fd052-8334-46e7-b09c-973a3f0568ff");
  final Uuid characteristicUuid1 =
      Uuid.parse("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");
  final Uuid writableUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");

  final deviceslist = <DiscoveredDevice>[];

  void _startScan() async {
    bool permGranted = false;
    setState(() {
      _scanStarted = true;
    });
    // PermissionStatus permission;
    if (Platform.isAndroid) {
      var permission = await Permission.location.request();
      if (permission.isGranted) permGranted = true;
    } else if (Platform.isIOS) {
      permGranted = true;
    }

    if (permGranted) {
      log('scamnn');

      _scanStream = flutterReactiveBle.scanForDevices(
          withServices: [], scanMode: ScanMode.balanced).listen((device) {
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
          // log(device.toString());
          // if (device.name == namecontroller.text) {
          //   log('device Found');
          //   // Future.delayed(const Duration(seconds: 5), () {
          //   //   _scanStream.cancel();
          //   // });

          //   _ubiqueDevice = device;
          //   _foundDeviceWaitingToConnect = true;
          // }
        });
      });
    }
  }

  void _connectToDevice(id) {
    // We're done scanning, we can cancel it
    _scanStream.cancel();
    // Let's listen to our connection so we can make updates on a state change
    Stream<ConnectionStateUpdate> _currentConnectionStream = flutterReactiveBle
        .connectToAdvertisingDevice(
            id: id, prescanDuration: const Duration(seconds: 1),
            //     servicesWithCharacteristicsToDiscover: {
            //   serviceUuid1: [characteristicUuid1]
            // },
            withServices: [serviceUuid1, writableUuid]);
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
              connectedDeviceId = event.deviceId;
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
            setState(() {
              _connected = false;
            });
            _startScan();
            break;
          }

        case DeviceConnectionState.disconnecting:
          {
            log('disconnected');
            getSnackbar(
                bgColor: Colors.red, message: '---------disconnecting--------');
            setState(() {
              _connected = false;
            });
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
  void initState() {
    bleStatusCheck();
    _startScan();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    StreamSubscriptionSerialDisposable();
    flutterReactiveBle.clearGattCache("94:B9:7E:FB:03:6E");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
        leading: const Icon(Icons.bluetooth),
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: namecontroller,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          MaterialButton(
                            onPressed: () {},
                            child: const Text('Add Name'),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
              icon: const Icon(Icons.menu))
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
                        trailing: MaterialButton(
                          onPressed: () {
                            _connectToDevice(deviceslist[index].id);
                            log(deviceslist[index].toString());
                          },
                          color: connectedDeviceId == deviceslist[index].id
                              ? Colors.green
                              : Colors.black,
                          child: Text(
                            connectedDeviceId == deviceslist[index].id
                                ? 'Connected'
                                : 'Connect',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        onTap: () {},
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
      floatingActionButton: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
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
                print('connect to devices');
              },
              child: const Icon(Icons.bluetooth),
            ),
            const SizedBox(
              width: 10,
            ),

            ////////////////REad
            FloatingActionButton(
              onPressed: () async {
                // print('object');
                final characteristic = QualifiedCharacteristic(
                    serviceId: serviceUuid1,
                    characteristicId: writableUuid,
                    // Uuid.parse('6E400003-B5A3-F393-E0A9-E50E24DCCA9E'),
                    deviceId: "94:B9:7E:FB:03:6E");
                final response =
                    await flutterReactiveBle.readCharacteristic(characteristic);

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                      title: const Text('Read'),
                      content: Text(String.fromCharCodes(response))),
                );
                log(String.fromCharCodes(response));
                log(response.toString());
              },
              child: const Icon(Icons.read_more),
            ),
            const SizedBox(
              width: 10,
            ),
            ////////////////Write
            FloatingActionButton(
              onPressed: () {
                print('Write charactereistic');
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Write'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: txtcontroller,
                            decoration:
                                const InputDecoration(hintText: 'String'),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          MaterialButton(
                            onPressed: () {
                              try {
                                final characteristic = QualifiedCharacteristic(
                                    serviceId: serviceUuid1,
                                    characteristicId: writableUuid,
                                    // Uuid.parse('beb5483e-36e1-4688-b7f5-ea07361b26a8'),
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
                                final res = flutterReactiveBle
                                    .writeCharacteristicWithResponse(
                                        characteristic,
                                        value: txtcontroller.text.codeUnits);
                                print(String.fromCharCodes(val));
                              } on Exception catch (e) {
                                // TODO
                                log(e.toString());
                              }
                            },
                            child: const Text('Send'),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
              tooltip: 'Write characteristic',
              child: const Icon(Icons.data_exploration_outlined),
            ),
            const SizedBox(
              width: 10,
            ),

            ////////////////Subscribe
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
                  log(String.fromCharCodes(data));
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
            ),
            const SizedBox(
              width: 10,
            ),

            ////////////////Subscribe
            FloatingActionButton(
              onPressed: () async {
                var status = await Permission.bluetooth.request();
                print(status);
              },
              child: const Icon(Icons.accessible_forward_outlined),
            )
          ],
        ),
      ),
    );
  }

  late BleStatus blestatus;

  bleStatusCheck() {
    flutterReactiveBle.statusStream.listen((status) {
      //code for handling status update
      setState(() {
        blestatus = status;
        if (blestatus != BleStatus.ready) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [Text('Please Turn on bluetooth')],
              ),
            ),
          );
        }
      });
    });
  }
}
