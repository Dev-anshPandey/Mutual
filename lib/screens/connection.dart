import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class Connection extends StatefulWidget {
  const Connection({super.key});

  @override
  State<Connection> createState() => _ConnectionState();
}

class _ConnectionState extends State<Connection> {
  Future<String> getAccessTokens() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return await pref.getString("accessToken").toString();
  }

  initSocket() async {
    print(await getAccessTokens());
    IO.Socket socket;
    socket = IO.io('ws://13.233.59.60/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'accessToken': await getAccessTokens()}
    });
    socket.connect();

    socket.onConnect((a) {
      print('Connection established');
      socket.emit('joinRoom',{'roomId':123});
      // print(a);
      // a.joinRoom({'roomId': 123});
    });
    socket.onDisconnect((_) => print('Connection Disconnection'));
    socket.onConnectError((err) => print(err));
    socket.onError((err) => print(err));
  }

  @override
  void initState() {
    initSocket();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text("hey"),
    );
  }
}
