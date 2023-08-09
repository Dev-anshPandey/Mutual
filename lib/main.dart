import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mutual/provider/chat_provider.dart';
import 'package:mutual/provider/chat_response_provider.dart';
import 'package:mutual/provider/chat_scroll_provider.dart';
import 'package:mutual/provider/feed_provider.dart';
import 'package:mutual/provider/graphID_provider.dart';
import 'package:mutual/provider/logincheck_provider.dart';
import 'package:mutual/provider/post_provider.dart';
import 'package:mutual/screens/account_setting.dart';
import 'package:mutual/screens/add_contact.dart';
import 'package:mutual/screens/chat.dart';
import 'package:mutual/screens/contact_access.dart';
import 'package:mutual/screens/edit_profile.dart';
import 'package:mutual/screens/feed.dart';
import 'package:mutual/screens/number_verification.dart';
import 'package:mutual/screens/profile.dart';
import 'package:mutual/screens/onboarding.dart';
import 'package:mutual/screens/see_profile.dart';
import 'package:mutual/screens/self_post.dart';
import 'package:mutual/screens/setting.dart';
import 'package:mutual/screens/welcome.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

String? isloggedIn;
bool notificationState = false;

const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
    playSound: true);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('A bg message just showed up :  ${message.messageId}');
}

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    // App received a notification when it was killed
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  SharedPreferences pref = await SharedPreferences.getInstance();
  pref.reload();
  isloggedIn = pref.getString('isloggedIn').toString();
  await Permission.notification.isDenied.then(
    (bool value) {
      if (value) {
        Permission.notification.request();
      }
    },
  );

  ChuckerFlutter.showOnRelease = false;
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.

  @override
  void initState() {
    _getStoragePermission();
    loggedIn();

    super.initState();
  }

  Future _getStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      setState(() {
        // permissionGranted = true;
      });
    } else if (await Permission.storage.request().isPermanentlyDenied) {
      await openAppSettings();
    } else if (await Permission.storage.request().isDenied) {
      setState(() {
        //permissionGranted = false;
      });
    }
  }

  Future<String> loggedIn() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    print(pref.getString("isloggedIn").toString());
    setState(() {
      isloggedIn = pref.getString("isloggedIn").toString();
    });
    return isloggedIn!;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FeedProvider>(
            create: (context) => FeedProvider()),
        ChangeNotifierProvider(
          create: (context) => PostProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => LoginCheck(),
        ),
        ChangeNotifierProvider(
          create: (context) => GraphID(),
        ),
        ChangeNotifierProvider(
          create: (context) => ChatProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ChatRProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ChatScroll(),
        )
      ],
      child: MaterialApp(
        navigatorObservers: [ChuckerFlutter.navigatorObserver],
        title: 'Mutual',
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        theme: ThemeData(
            primarySwatch: Colors.blue,
            appBarTheme: AppBarTheme(
               
                systemOverlayStyle:
                    SystemUiOverlayStyle(statusBarColor: Colors.white,))),
        routes: {
          '/': (context) => isloggedIn == 'true' ? Feed() : Onboarding(),
          //  '/': (context) => Onboarding(),
          '/number': (context) => Number(),
          '/profile': (context) => ProfileScreen(),
          '/contactAccess': (context) => ContactAccess(),
          '/welcome': (context) => Welcome(),
          '/feed': (context) => Feed(),
          '/seeProfile': (context) => SeeProfile(),
          '/chat': (context) => Chat(),
          '/self': (context) => SelfPost(),
          '/setting': (context) => Setting(),
          '/accountSetting': (context) => AccountSetting(),
          '/addContact': (context) => AddContact(),
          '/editProfile':(context) => EditProfile()
          // '/chatResponse': (context) => ChatResponse()
        },
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Image.asset("assets/logo.jpg")),
    );
  }
}
