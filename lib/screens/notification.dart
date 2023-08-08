import 'dart:convert';

import 'package:build_context_provider/build_context_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mutual/provider/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';
import 'feed.dart';

MyDb mydb = new MyDb();
late Database db;

class NotificationServices {
  AndroidNotificationChannel channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.high,
      playSound: true);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> intializeDB() async {
    db = await mydb.open();
  }

  void setNotification() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  var notificationMessage;
  void onMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      notificationMessage = message.data;
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        print(message.data);
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                color: Colors.blue,
                playSound: true,
                icon: '@mipmap/ic_launcher',
              ),
            ));
        intializeDB();
        //flutterLocalNotificationsPlugin.initialize()
      }
    });
  }

  void onNotificationOpened(BuildContext context) {
    intializeDB();
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      intializeDB();
      print('A new onMessageOpenedApp event was published!');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        // if (notificationMessage) {
        print(notificationMessage);
        List chat = [];
        Map map = Map();
        map = json.decode(notificationMessage['data']);
        print('as');
        final cp = Provider.of<ChatProvider>(context, listen: false);
        chat = await db.rawQuery('SELECT * FROM chat WHERE chatId = ?',
            [map['chatId']]);
        cp.setData(
            nameData: chat[0]['authorName'],
            postData: chat[0]['post'],
            postIDData: chat[0]['postId'],
            professionData: "",
            timeData: "",
            graphData: map['authorGraphId'],
            socketData: socket,
            chatsId: [],
            chatId: chat[0]['chatId'],
            mutual: "",
            profileData: "");

        Navigator.pushNamed(context, '/chat');
      }
      // }
    });
  }

  void initMessafe(BuildContext context) async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    var androidInit = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosInit = DarwinInitializationSettings();
    var initSetting =
        InitializationSettings(android: androidInit, iOS: iosInit);
    flutterLocalNotificationsPlugin.initialize(
      initSetting,
      onDidReceiveNotificationResponse: (details) async {
        List chat = [];
        print(notificationMessage);
        Map map = Map();
        map = json.decode(notificationMessage['data']);

        final cp = Provider.of<ChatProvider>(context, listen: false);
        chat = await db
            .rawQuery('SELECT * FROM chat WHERE chatId = ?', [map['chatId']]);
        cp.setData(
            nameData: chat[0]['authorName'],
            postData: chat[0]['post'],
            postIDData: chat[0]['postId'],
            professionData: "",
            timeData: "",
            graphData: map['authorGraphId'],
            socketData: socket,
            chatsId: [],
            chatId: chat[0]['chatId'],
            mutual: "",
            profileData: "");

        Navigator.pushNamed(context, '/chat');
      },
    );
  }
}
