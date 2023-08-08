import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:mutual/provider/chat_provider.dart';
import 'package:mutual/provider/feed_provider.dart';
import 'package:mutual/provider/graphID_provider.dart';
import 'package:mutual/screens/dio.dart';
import 'package:mutual/screens/notification.dart';
import 'package:mutual/screens/profile.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:readmore/readmore.dart';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../provider/chat_response_provider.dart';

int index = 0;
DioClient d = DioClient();
List contactsPresnet = [];
List feed = [];
List myPost = [];
String? name;
String? profilePic;
String? profession;
String search = "";
String? postId;
final now = Moment.now();
int dc = 0;
int graphId = 0;
int mc = 0;
final TextEditingController _searchController = TextEditingController();
final FocusNode _searchFocusNode = FocusNode();
late TabController tabController;
ScrollController scrollController = ScrollController();
bool skip = false;
RefreshController _refreshController = RefreshController(initialRefresh: false);
RefreshController _refreshController2 =
    RefreshController(initialRefresh: false);
late IO.Socket socket;

class Feed extends StatefulWidget {
  const Feed({super.key});

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> with SingleTickerProviderStateMixin {
  Future<String> getAccessTokens() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return await pref.getString("accessToken").toString();
  }

  initSocket() async {
    print(await getAccessTokens());

    socket = IO.io('ws://3.110.164.26/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'accessToken': await getAccessTokens()}
    });
    socket.connect();
    socket.onConnect((_) {
      print('Connection established');
    });
    socket.onDisconnect((_) => print('Connection Disconnection'));
    socket.onConnectError((err) => print(err));
    socket.onError((err) => print(err));
  }

  Future apigetUser() async {
    var request = await d.dio.get('http://3.110.164.26/v1/api/user/details');
    print('firstaName issss');
    print(request.data['data']['firstName']);
    if (request.statusCode == 200) {
      setState(() {
        name = request.data['data']['firstName'];
        profilePic = request.data['data']['profilePic'];
        profession = request.data['data']['profession'];
        graphId = request.data['data']['graphId'];
      });
    } else {
      print(request.statusMessage);
    }
  }

  Future apiGetConfig() async {
    var request = await d.dio.get('http://3.110.164.26/v1/api/user/config');
    if (request.statusCode == 200) {
      setState(() {
        dc = request.data['data']['reach']['DC'];
        mc = request.data['data']['reach']['MC'];
      });
      int sum = dc + mc;

      // SharedPreferences.setMockInitialValues({});
      SharedPreferences pref = await SharedPreferences.getInstance();
      await pref.setInt("postReach", sum);
    } else {
      print(request.statusMessage);
    }
  }

  Future apiFeed() async {
    feed.clear();
    var request = await d.dio.get(
      'http://3.110.164.26/v1/api/feed/get',
    );
    List postId = [];
    print("length is");
    print(request.data['data'].length);
    for (int i = 0; i < request.data['data'].length; i++) {
      postId.add(request.data['data'][i]['postId']);
      setState(() {
        print("post content is");
        print(request.data['data'][i]['post']);
        String mutual = "";
        String time = DateFormat.jm().format(DateTime.now());
        try {
          time = Moment.parse(DateTime.parse(
                      (request.data['data'][i]['createdAt']).toString())
                  .add(Duration(hours: 5, minutes: 30))
                  .toString())
              .fromNow(form: UnitStringForm.mid);
          if (time.toString().contains('in')) {
            time = Moment.parse(DateTime.parse(
                        (request.data['data'][i]['createdAt']).toString())
                    .add(Duration(hours: 5, minutes: 30))
                    .toString())
                .LT;
          }
          mutual = request.data['data'][i]['mutual'][0]['name'] +
                  (request.data['data'][i]['mutual'].length - 1 == 0
                          ? " 's"
                          : ("+" +
                              (request.data['data'][i]['mutual'].length - 1)
                                  .toString()))
                      .toString() ??
              "";

          print(time);
        } catch (e) {
          print(e);
        }

        feed.add(FeedCard(
          firstName: request.data['data'][i]['firstName'] ?? "Tushar",
          post: request.data['data'][i]['post'] ?? "",
          profilePic: request.data['data'][i]['profilePic'] ?? "",
          profession: request.data['data'][i]['profession'] ?? "",
          cursor: request.data['data'][i]['cursor'] ?? 4,
          time: time.toString(),
          chatID: request.data['data'][i]['chatId'] ?? null,
          postId: request.data['data'][i]['postId'],
          authorGraphId: request.data['data'][i]['authorGraphId'],
          mutual: mutual,
          selfCreated: request.data['data'][i]['selfPost'],
          postUrl: request.data['data'][i]['media'][0] != null
              ? request.data['data'][i]['media'][0]['url']
              : "",
        ));
      });
    }
    var data = jsonEncode(postId);
    var response =
        await d.dio.post('http://3.110.164.26/v1/api/post/views', data: data);

    if (request.statusCode == 200) {
      print("Response body :");
      print(await request.data.toString());
    } else {
      print(request.statusMessage);
    }
  }

  Future apiMyPost() async {
    feed.clear();
    var request = await d.dio.get(
      'http://3.110.164.26/v1/api/feed/myfeed',
    );
    print("length is");
    print(request.data['data'].length);
    for (int i = 0; i < request.data['data'].length; i++) {
      setState(() {
        print("post content is");
        print(request.data['data'][i]['post']);
        String mutual = "";
        String time = DateFormat.jm().format(DateTime.now());
        try {
          time = Moment.parse(DateTime.parse(
                      (request.data['data'][i]['createdAt']).toString())
                  .add(Duration(hours: 5, minutes: 30))
                  .toString())
              .fromNow(form: UnitStringForm.mid);
          if (time.toString().contains('in')) {
            time = Moment.parse(DateTime.parse(
                        (request.data['data'][i]['createdAt']).toString())
                    .add(Duration(hours: 5, minutes: 30))
                    .toString())
                .LT;
          }
          mutual = request.data['data'][i]['mutual'][0]['name'] +
                  (request.data['data'][i]['mutual'].length - 1 == 0
                          ? " 's"
                          : ("+" +
                              (request.data['data'][i]['mutual'].length - 1)
                                  .toString()))
                      .toString() ??
              "";
          print(time);
        } catch (e) {
          print(e);
        }

        myPost.add(
          FeedCard(
            firstName: request.data['data'][i]['firstName'] ?? "Tushar",
            post: request.data['data'][i]['post'] ?? "",
            profilePic: request.data['data'][i]['profilePic'] ?? "",
            profession: request.data['data'][i]['profession'][0] ?? "",
            cursor: request.data['data'][i]['cursor'] ?? 4,
            time: time.toString(),
            chatID: request.data['data'][i]['chatId'] ?? null,
            postId: request.data['data'][i]['postId'],
            authorGraphId: request.data['data'][i]['graphId'] ?? -1,
            mutual: mutual,
            selfCreated: request.data['data'][i]['selfPost'],
            postUrl: request.data['data'][i]['media'][0] != null
                ? request.data['data'][i]['media'][0]['url']
                : "",
          ),
        );
      });
    }

    if (request.statusCode == 200) {
      print("Response body :");
      print(await request.data.toString());
    } else {
      print(request.statusMessage);
    }
  }

  Future<void> _onRefresh() async {
    await Future.delayed(Duration(milliseconds: 1000));
    if (feed.length != 0) {
      List postId = [];
      try {
        int cId = feed[0].cursor;
        print(cId);
        var request = await d.dio.get(
          'http://3.110.164.26/v1/api/feed/get?after=$cId&before=null',
        );
        print("refreshhh");
        print(request.data.toString());
        for (int i = 0; i < request.data['data'].length; i++) {
          postId.add(request.data['data'][i]['postId']);
          setState(() {
            print("post content is");
            print(request.data['data'][i]['post']);
            print(Moment.parse((request.data['data'][i]['createdAt'])).LT);
            String mutual = "";
            String time = DateFormat.jm().format(DateTime.now());

            try {
              //   mutual = request.data['data'][i]['mutual'][i].length - 1;
              time = Moment.parse(DateTime.parse(
                          (request.data['data'][i]['createdAt']).toString())
                      .add(Duration(hours: 5, minutes: 30))
                      .toString())
                  .fromNow(form: UnitStringForm.mid);
              if (time.toString().contains('in')) {
                time = Moment.parse(DateTime.parse(
                            (request.data['data'][i]['createdAt']).toString())
                        .add(Duration(hours: 5, minutes: 30))
                        .toString())
                    .LT;
              }
              mutual = request.data['data'][i]['mutual'][0]['name'] +
                      (request.data['data'][i]['mutual'].length - 1 == 0
                              ? " 's"
                              : ("+" +
                                  (request.data['data'][i]['mutual'].length - 1)
                                      .toString()))
                          .toString() ??
                  "";
            } catch (e) {
              print(e);
            }

            feed.insert(
              0,
              FeedCard(
                firstName: request.data['data'][i]['firstName'] ?? "Tushar",
                post: request.data['data'][i]['post'] ?? "",
                profilePic: request.data['data'][i]['profilePic'] ?? "",
                profession: request.data['data'][i]['profession'] ?? "",
                cursor: request.data['data'][i]['cursor'] ?? 4,
                chatID: request.data['data'][i]['chatId'] ?? null,
                authorGraphId: request.data['data'][i]['authorGraphId'],
                time: time.toString(),
                postId: request.data['data'][i]['postId'],
                mutual: mutual,
                selfCreated: request.data['data'][i]['selfPost'],
                postUrl: request.data['data'][i]['media'][0] != null
                    ? request.data['data'][i]['media'][0]['url']
                    : "",
              ),
            );
          });
        }
        var data = jsonEncode(postId);
        var response = await d.dio
            .post('http://3.110.164.26/v1/api/post/views', data: data);

        if (request.statusCode == 200) {
          print("Response body :");
          print(await request.data.toString());
        } else {
          print(request.statusMessage);
        }
      } catch (e) {
        print(e);
      }
      //  feed.clear();
    }
    _refreshController.refreshCompleted();
  }

  Future apigetContacts() async {
    contactsPresnet.clear();
    var request = await d.dio.get('http://3.110.164.26/v1/api/user/exists');
    print(request);
    if (request.statusCode == 200) {
      for (var sd in request.data['data']['userExist']) {
        print(sd['phoneNumber']);
        // contactsPresnet.add(sd['phoneNumber']);
        setState(() {
          contactsPresnet.add(ListContact(
              name: sd['firstName'],
              phoneNo: sd['phoneNumber'],
              profilePic: sd['profilePic'],
              onPlatform: true));
        });
      }
    }
  }

  Future<void> _onRefreshPost() async {
    await Future.delayed(Duration(milliseconds: 1000));
    if (myPost.length != 0) {
      try {
        int cId = myPost[0].cursor;
        print(cId);
        var request = await d.dio.get(
          'http://3.110.164.26/v1/api/feed/myfeed?after=$cId&before=null',
        );
        print("refreshhh");
        print(request.data.toString());
        for (int i = 0; i < request.data['data'].length; i++) {
          setState(() {
            print("post content is");
            print(request.data['data'][i]['post']);
            print(Moment.parse((request.data['data'][i]['createdAt'])).LT);
            String mutual = "";
            String time = DateFormat.jm().format(DateTime.now());
            try {
              time = Moment.parse(DateTime.parse(
                          (request.data['data'][i]['createdAt']).toString())
                      .add(Duration(hours: 5, minutes: 30))
                      .toString())
                  .fromNow(form: UnitStringForm.mid);
              if (time.toString().contains('in')) {
                time = Moment.parse(DateTime.parse(
                            (request.data['data'][i]['createdAt']).toString())
                        .add(Duration(hours: 5, minutes: 30))
                        .toString())
                    .LT;
              }
              //   mutual = request.data['data'][i]['mutual'][i].length - 1;
              mutual = request.data['data'][i]['mutual'][0]['name'] +
                      (request.data['data'][i]['mutual'].length - 1 == 0
                              ? " 's"
                              : ("+" +
                                  (request.data['data'][i]['mutual'].length - 1)
                                      .toString()))
                          .toString() ??
                  "";
            } catch (e) {
              print(e);
            }

            myPost.insert(
              0,
              FeedCard(
                firstName: request.data['data'][i]['firstName'] ?? "Tushar",
                post: request.data['data'][i]['post'] ?? "",
                profilePic: request.data['data'][i]['profilePic'] ?? "",
                profession: request.data['data'][i]['profession'] ?? "",
                cursor: request.data['data'][i]['cursor'] ?? 4,
                authorGraphId: request.data['data'][i]['authorGraphId'],
                chatID: request.data['data'][i]['chatId'] ?? null,
                time: time.toString(),
                postId: request.data['data'][i]['postId'],
                mutual: mutual,
                selfCreated: request.data['data'][i]['selfPost'],
                postUrl: request.data['data'][i]['media'][0] != null
                    ? request.data['data'][i]['media'][0]['url']
                    : "",
              ),
            );
          });
        }

        if (request.statusCode == 200) {
          print("Response body :");
          print(await request.data.toString());
        } else {
          print(request.statusMessage);
        }
      } catch (e) {
        print(e);
      }
      //  feed.clear();
    }
    _refreshController2.refreshCompleted();
  }

  Future<void> _onLoading() async {
    await Future.delayed(Duration(milliseconds: 1000));
    if (feed.length != 0) {
      List postId = [];
      int cId = feed[feed.length - 1].cursor;
      // feed.clear();
      print(cId);
      var request = await d.dio.get(
        'http://3.110.164.26/v1/api/feed/get?before=$cId&after=null',
      );
      print(request.data.toString());
      for (int i = 0; i < request.data['data'].length; i++) {
        postId.add(request.data['data'][i]['postId']);
        setState(() {
          print("post content is");
          print(request.data['data'][i]['post']);
          print(Moment.parse((request.data['data'][i]['createdAt'])).LT);
          String mutual = "";
          String time = DateFormat.jm().format(DateTime.now());

          try {
            time = Moment.parse(DateTime.parse(
                        (request.data['data'][i]['createdAt']).toString())
                    .add(Duration(hours: 5, minutes: 30))
                    .toString())
                .fromNow(form: UnitStringForm.mid);
            if (time.toString().contains('in')) {
              time = Moment.parse(DateTime.parse(
                          (request.data['data'][i]['createdAt']).toString())
                      .add(Duration(hours: 5, minutes: 30))
                      .toString())
                  .LT;
            }
            //   mutual = request.data['data'][i]['mutual'][i].length - 1;
            mutual = request.data['data'][i]['mutual'][0]['name'] +
                    (request.data['data'][i]['mutual'].length - 1 == 0
                            ? " 's"
                            : ("+" +
                                (request.data['data'][i]['mutual'].length - 1)
                                    .toString()))
                        .toString() ??
                "";
          } catch (e) {
            print(e);
          }

          feed.add(
            FeedCard(
                firstName: request.data['data'][i]['firstName'] ?? "Tushar",
                post: request.data['data'][i]['post'] ?? "",
                profilePic: request.data['data'][i]['profilePic'] ?? "",
                profession: request.data['data'][i]['profession'] ?? "",
                chatID: request.data['data'][i]['chatId'] ?? null,
                cursor: request.data['data'][i]['cursor'] ?? 4,
                authorGraphId: request.data['data'][i]['authorGraphId'],
                time: time.toString(),
                postId: request.data['data'][i]['postId'],
                mutual: mutual,
                postUrl: request.data['data'][i]['media'][0] != null
                    ? request.data['data'][i]['media'][0]['url']
                    : "",
                selfCreated: request.data['data'][i]['selfPost']),
          );
        });
      }
      var data = jsonEncode(postId);
      var response =
          await d.dio.post('http://3.110.164.26/v1/api/post/views', data: data);
      if (request.statusCode == 200) {
        print("Response body :");
        print(await request.data.toString());
      } else {
        print(request.statusMessage);
      }
    }
    print('object');
    _refreshController.loadComplete();
  }

  Future<void> _onLoadingPost() async {
    await Future.delayed(Duration(milliseconds: 1000));
    if (myPost.length != 0) {
      print(myPost.length - 1);
      int cId = myPost[myPost.length - 1].cursor;
      // feed.clear();
      print(cId);
      var request = await d.dio.get(
        'http://3.110.164.26/v1/api/feed/myfeed?before=$cId&after=null',
      );
      print(request.data.toString());
      for (int i = 0; i < request.data['data'].length; i++) {
        setState(() {
          print("post content is");
          print(request.data['data'][i]['post']);
          print(Moment.parse((request.data['data'][i]['createdAt'])).LT);
          String mutual = "";
          String time = DateFormat.jm().format(DateTime.now());

          try {
            time = Moment.parse(DateTime.parse(
                        (request.data['data'][i]['createdAt']).toString())
                    .add(Duration(hours: 5, minutes: 30))
                    .toString())
                .fromNow(form: UnitStringForm.mid);
            if (time.toString().contains('in')) {
              time = Moment.parse(DateTime.parse(
                          (request.data['data'][i]['createdAt']).toString())
                      .add(Duration(hours: 5, minutes: 30))
                      .toString())
                  .LT;
            }
            //   mutual = request.data['data'][i]['mutual'][i].length - 1;
            mutual = request.data['data'][i]['mutual'][0]['name'] +
                    (request.data['data'][i]['mutual'].length - 1 == 0
                            ? " 's"
                            : ("+" +
                                (request.data['data'][i]['mutual'].length - 1)
                                    .toString()))
                        .toString() ??
                "";
          } catch (e) {
            print(e);
          }

          myPost.add(
            FeedCard(
                firstName: request.data['data'][i]['firstName'],
                post: request.data['data'][i]['post'] ?? "",
                profilePic: request.data['data'][i]['profilePic'] ?? "",
                profession:
                    request.data['data'][i]['profession'].toString() ?? "",
                cursor: request.data['data'][i]['cursor'] ?? 4,
                chatID: request.data['data'][i]['chatId'] ?? null,
                authorGraphId: request.data['data'][i]['authorGraphId'] ?? -1,
                time: time.toString() ?? "",
                postId: request.data['data'][i]['postId'],
                mutual: mutual ?? "",
                postUrl: request.data['data'][i]['media'][0] != null
                    ? request.data['data'][i]['media'][0]['url']
                    : "",
                selfCreated: request.data['data'][i]['selfPost']),
          );
        });
      }

      if (request.statusCode == 200) {
        print("Response body :");
        print(await request.data.toString());
      } else {
        print(request.statusMessage);
      }
    }
    print('object');
    _refreshController2.loadComplete();
  }

  @override
  void dispose() {
    // print('diszzconected');
    //socket.onclose(graphId);
    // TODO: implement dispose
    super.dispose();
  }

  @override
  void initState() {
    tabController = TabController(vsync: this, length: 2, initialIndex: 0);
    _refreshController = RefreshController(initialRefresh: false);
    _refreshController2 = RefreshController(initialRefresh: false);
    skip = false;
    apiGetConfig();
    initSocket();
    apigetUser();
    apiFeed();
    apiMyPost();
    NotificationServices ns = NotificationServices();
    ns.setNotification();
    ns.onMessage();
    ns.onNotificationOpened(context);
    ns.initMessafe(context);
    apigetContacts();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final arguments = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;

    if (skip == false) index = arguments['indexNo'] ?? 0;
    //print(feed[0].cursor);
    // fp.deleteAll();
    return ChangeNotifierProvider(
        create: (context) => FeedProvider(),
        child: Consumer(
          builder: (context, value, child) {
            final fp = Provider.of<FeedProvider>(context, listen: false);
            if (search == "") {
              fp.deleteAll();
              fp.deletePost();

              for (var element in feed) {
                fp.addNormal(element);
              }
              for (var element in myPost) {
                fp.addPost(element);
              }
              print("cursor");
            }
            void onsearch(String value) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  search = value;
                });
              });
              if (value.isEmpty) {
                // for (var element in feed) {
                //   fp.addNormal(element);
                // }
              } else {
                fp.deleteAll();
                for (var element in feed) {
                  print(element.firstName);
                  if (element.firstName
                      .toLowerCase()
                      .contains(value.toLowerCase())) fp.addNormal(element);
                }
              }
            }

            return WillPopScope(
              onWillPop: () async {
                SystemNavigator.pop();
                // Navigator.of(context).pop(true);
                return await true;
              },
              child: Scaffold(
                body: NestedScrollView(
                  floatHeaderSlivers: true,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      index == 0
                          ? SliverAppBar(
                              floating: true,
                              pinned: true,
                              backgroundColor: Colors.white,
                              elevation: 0,
                              bottom: TabBar(
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicatorColor: Color(0xff4988EF),
                                indicatorPadding:
                                    EdgeInsets.only(left: 10, right: 10),
                                controller: tabController,
                                tabs: const [
                                  Tab(
                                    child: Text('For You',
                                        style: TextStyle(color: Colors.black)),
                                  ),
                                  Tab(
                                    child: Text('Your Post',
                                        style: TextStyle(color: Colors.black)),
                                  ),
                                ],
                                labelColor: Colors.white,
                              ),
                              // centerTitle: false,
                              title: Image.asset(
                                'assets/splash.png',
                                height:
                                    MediaQuery.of(context).size.height * 0.082,
                              ),
                              actions: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CircleAvatar(
                                      radius: 15.4,
                                      child: InkWell(
                                        onTap: () {
                                          showModalBottomSheet(
                                              isScrollControlled: true,
                                              context: context,
                                              builder: (BuildContext context) {
                                                return BottomWidget(fp);
                                              });
                                        },
                                        child: Container(
                                          height: 56,
                                          width: 140,
                                          decoration: const BoxDecoration(
                                              gradient: LinearGradient(colors: [
                                                Color(0xff4988EF),
                                                Color(0xff476DEE)
                                              ]),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(20.5))),
                                          child: const Icon(
                                            Icons.add,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Consumer(
                                      builder: (context, value, child) {
                                        final gp = Provider.of<GraphID>(context,
                                            listen: false);
                                        return InkWell(
                                          onTap: () {
                                            gp.setGID(graphId);
                                            Navigator.pushNamed(
                                                context, '/seeProfile');
                                          },
                                          child: CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              profilePic ?? "",
                                            ),
                                            radius: 18.5,
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : SliverAppBar(
                              floating: true,
                              pinned: true,
                              backgroundColor: Colors.white,
                              elevation: 1,
                              title: Image.asset(
                                'assets/splash.png',
                                height:
                                    MediaQuery.of(context).size.height * 0.082,
                              ),
                              actions: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CircleAvatar(
                                      radius: 15.4,
                                      child: InkWell(
                                        onTap: () {
                                          showModalBottomSheet(
                                              isScrollControlled: true,
                                              context: context,
                                              builder: (BuildContext context) {
                                                return BottomWidget(fp);
                                              });
                                        },
                                        child: Container(
                                          height: 56,
                                          width: 140,
                                          decoration: const BoxDecoration(
                                              gradient: LinearGradient(colors: [
                                                Color(0xff4988EF),
                                                Color(0xff476DEE)
                                              ]),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(20.5))),
                                          child: const Icon(
                                            Icons.add,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Consumer(
                                      builder: (context, value, child) {
                                        final gp = Provider.of<GraphID>(context,
                                            listen: false);
                                        return InkWell(
                                          onTap: () {
                                            gp.setGID(graphId);
                                            Navigator.pushNamed(
                                                context, '/seeProfile');
                                          },
                                          child: CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              profilePic ?? "",
                                            ),
                                            radius: 18.5,
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                  ],
                                ),
                              ],
                            )
                    ];
                  },
                  body: index == 0
                      ? FeedMethod(context, fp, tabController.index)
                      : ChatMethod(context),
                ),
                backgroundColor: Colors.white,
                //floatingActionButton: FloatingButton(),
                bottomNavigationBar: Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: Colors.white,
                  ),
                  child: BottomNavigationBar(
                    elevation: 0,
                    unselectedFontSize: 10,
                    selectedFontSize: 12,
                    onTap: (value) => setState(() {
                      skip = true;
                      index = value;
                    }),
                    showUnselectedLabels: true,
                    selectedItemColor: Color(0xff4666ED),
                    unselectedItemColor: Colors.grey,
                    iconSize: 26.4,
                    type: BottomNavigationBarType.fixed,
                    items: const [
                      BottomNavigationBarItem(
                          backgroundColor: Color(0xffA8A8A8),
                          icon: FaIcon(
                            FontAwesomeIcons.peopleGroup,
                            size: 22,
                            color: Color(0xffA8A8A8),
                          ),
                          activeIcon: FaIcon(
                            FontAwesomeIcons.peopleGroup,
                            size: 22,
                            color: Color(0xff336FD7),
                          ),
                          label: 'Feed'),
                      BottomNavigationBarItem(
                          backgroundColor: Color(0xffA8A8A8),
                          icon: FaIcon(
                            FontAwesomeIcons.rocketchat,
                            size: 22,
                            color: Color(0xffA8A8A8),
                          ),
                          activeIcon: FaIcon(
                            FontAwesomeIcons.rocketchat,
                            size: 22,
                            color: Color(0xff336FD7),
                          ),
                          label: 'Chat'),
                      BottomNavigationBarItem(
                          backgroundColor: Color(0xffA8A8A8),
                          icon: FaIcon(
                            FontAwesomeIcons.bell,
                            size: 22,
                            color: Color(0xffA8A8A8),
                          ),
                          activeIcon: FaIcon(
                            FontAwesomeIcons.bell,
                            size: 22,
                            color: Color(0xff336FD7),
                          ),
                          label: 'Notifications'),
                      BottomNavigationBarItem(
                          backgroundColor: Color(0xffA8A8A8),
                          icon: FaIcon(
                            FontAwesomeIcons.phone,
                            size: 22,
                            color: Color(0xffA8A8A8),
                          ),
                          activeIcon: FaIcon(
                            FontAwesomeIcons.phone,
                            size: 22,
                            color: Color(0xff336FD7),
                          ),
                          label: 'Call'),
                    ],
                    currentIndex: index,
                  ),
                ),
              ),
            );
          },
        ));
  }

  Widget ChatMethod(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.016,
              bottom: MediaQuery.of(context).size.height * 0.024,
              left: MediaQuery.of(context).size.width * 0.06,
              right: MediaQuery.of(context).size.width * 0.04),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.04,
            child: TextField(
              focusNode: _searchFocusNode,
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search...',
                contentPadding: EdgeInsets.only(top: 12),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        Padding(
          padding:
              EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.06),
          child: Text(
            "Messages",
            style: GoogleFonts.roboto(
              textStyle: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                  fontSize: MediaQuery.of(context).size.height * 0.018),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemBuilder: (context, index) {
              return contactsPresnet[index];
            },
            separatorBuilder: (context, index) {
              return Divider(
                height: 1,
                endIndent: 0,
                indent: 0,
              );
            },
            itemCount: contactsPresnet.length,
          ),
        ),
      ],
    );
  }

  TabBarView FeedMethod(BuildContext context, FeedProvider fp, int index) {
    fp.changeState(index);
    return TabBarView(controller: tabController, children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.grey, height: 1, thickness: 0.2),
          Consumer<FeedProvider>(
            builder: (context, value, child) {
              final fp = Provider.of<FeedProvider>(context, listen: false);
              return fp.feedList.length != 0
                  ? Expanded(
                      child: SmartRefresher(
                        enablePullDown: true,
                        enablePullUp: true,
                        controller: _refreshController,
                        onLoading: _onLoading,
                        onRefresh: _onRefresh,
                        child: ListView.separated(
                          separatorBuilder: (context, index) {
                            return Divider(
                              height: 2,
                              endIndent: 0,
                              indent: 0,
                            );
                          },
                          //physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            if (index == fp.feedList.length) {
                              return SizedBox(height: 80);
                            }
                            return fp.feedList[index];
                          },
                          itemCount: fp.feedList.length + 1,
                        ),
                      ),
                    )
                  : Container(height: 0, width: 0);
            },
          )
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.grey, height: 1, thickness: 0.2),
          Consumer<FeedProvider>(
            builder: (context, value, child) {
              final fp = Provider.of<FeedProvider>(context, listen: false);
              return (fp.myPostList.length != 0
                  ? Expanded(
                      child: SmartRefresher(
                        enablePullDown: true,
                        enablePullUp: true,
                        controller: _refreshController2,
                        onLoading: _onLoadingPost,
                        onRefresh: _onRefreshPost,
                        child: ListView.separated(
                          separatorBuilder: (context, index) {
                            return Divider(
                              height: 2,
                              endIndent: 0,
                              thickness: 1,
                              indent: 0,
                            );
                          },
                          //physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            if (index == fp.myPostList.length) {
                              return SizedBox(height: 80);
                            }
                            return fp.myPostList[index];
                          },
                          itemCount: fp.myPostList.length + 1,
                        ),
                      ),
                    )
                  : Container(height: 0, width: 0));
            },
          )
        ],
      ),
    ]);
  }
}

// class FloatingButton extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     _FeedState feed = _FeedState();
//     return FloatingActionButton(
//         shape: const RoundedRectangleBorder(
//             borderRadius: BorderRadius.all(Radius.circular(81))),
//         onPressed: () {
//           print(MaterialLocalizations.of(context));
//           showModalBottomSheet(
//               isScrollControlled: true,
//               context: context,
//               builder: (BuildContext context) {
//                 return BottomWidget(fp);
//               });
//         },
//         child: Padding(
//           padding: const EdgeInsets.all(0),
//           child: Container(
//             height: 56,
//             width: 132,
//             decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                     colors: [Color(0xff4988EF), Color(0xff476DEE)]),
//                 borderRadius: BorderRadius.all(Radius.circular(8))),
//             child: const Icon(
//               Icons.add,
//               size: 30,
//             ),
//           ),
//         ));
//   }
// }

class BottomWidget extends StatefulWidget {
  FeedProvider fp;
  BottomWidget(this.fp);
  @override
  State<BottomWidget> createState() => _BottomWidgetState();
}

class _BottomWidgetState extends State<BottomWidget> {
//  const BottomWidget({super.key});
  String postBody = "";
  String? pId;
  String profileUrl = "";
  Future apiCreatePost() async {
    List<Map> postArr = [
      {"type": "image", "url": profileUrl}
    ];
    var data = jsonEncode({"post": postBody, "media": postArr});
    var response =
        await d.dio.post('http://3.110.164.26/v1/api/feed/post', data: data);

    setState(() {
      pId = response.data['data']['postId'];
    });
    print("PID is $pId");
    socket.emit('joinRoom', {'roomId': response.data['data']['postId']});
    if (response.statusCode == 200) {
      // print(await response.data.toString());
    } else {
      print(response.statusCode);
    }
  }

  File? image;
  int reach = 0;
  String? imageGlobal;

  Future PickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final imageTemp = File(image.path);
      setState(() {
        this.image = imageTemp;
        imageGlobal = image.path;
        print("image path");
        print(imageGlobal);
      });
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
    apiCallUploadImage();
  }

  Future apiCallUploadImage() async {
    print('for image');
    FormData formData = await FormData.fromMap({
      'image': await MultipartFile.fromFile(imageGlobal!),
      'path': imageGlobal
    });
    SharedPreferences pref = await SharedPreferences.getInstance();
    var option = Options(headers: {
      'accessToken': pref.getString('accessToken'),
      'contentType': 'multipart/form-data'
    });
    try {
      var response = await d.dio.post(
        'http://3.110.164.26/v1/api/user/image/post/image',
        data: formData,
        options: option,
      );
      print(response);
      if (response.statusCode == 200) {
        String res = await response.data.toString();
        setState(() {
          print(response.data['data']['image']);
          profileUrl = response.data['data']['image'];
        });
      } else {
        print(response);
      }
      if (response.statusCode == 400) {
        Fluttertoast.showToast(
          msg: "Invalid format",
        );
      }
    } on DioError catch (e) {
      print(e);
      Fluttertoast.showToast(
        msg: "File size too large",
      );
      // print('breakk');
    }
  }

  Future<int?> getConfig() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      reach = pref.getInt("postReach") ?? 0;
      print(reach);
    });
  }

  @override
  void initState() {
    getConfig();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
            left: MediaQuery.of(context).size.width * 0.03,
            bottom: MediaQuery.of(context).viewInsets.bottom == 0
                ? MediaQuery.of(context).size.height * 0.04
                : MediaQuery.of(context).viewInsets.bottom + 10,
            right: MediaQuery.of(context).size.width * 0.03),
        child: Consumer<FeedProvider>(
          builder: (context, value, child) {
            // var fp = Provider.of<FeedProvider>(context, listen: false);
            return InkWell(
              onTap: () async {
                if (postBody.isNotEmpty) {
                  await apiCreatePost();

                  // widget.fp.changeState(1);
                  tabController.animateTo(1);
                  print("tab index ${tabController.index}");
                  widget.fp.myPostList.insert(
                      0,
                      FeedCard(
                          firstName: name ?? "",
                          post: postBody,
                          profilePic: profilePic ?? "",
                          profession: profession ?? "",
                          time: now.LT.toString(),
                          authorGraphId: 0,
                          selfCreated: true,
                          postUrl: profileUrl,
                          chatID: null,
                          postId: pId!));

                  widget.fp.feedList.insert(
                      0,
                      FeedCard(
                          firstName: name ?? "",
                          post: postBody,
                          profilePic: profilePic ?? "",
                          profession: profession ?? "",
                          time: now.LT.toString(),
                          authorGraphId: 0,
                          selfCreated: true,
                          chatID: null,
                          postUrl: profileUrl,
                          postId: pId!));

                  Navigator.pop(context);
                }
                //fp.addList(FeedCard(post:postBody,firstName:"Devansh",));
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.26,
                child: Column(
                  //crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: profileUrl.isNotEmpty
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    profileUrl.isNotEmpty
                        ? Padding(
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height * 0.02,
                                bottom:
                                    MediaQuery.of(context).size.height * 0.06),
                            child: Stack(children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(profileUrl),
                                radius: 40,
                              ),
                              Positioned(
                                  top: 0,
                                  right: -2,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        profileUrl = "";
                                      });
                                    },
                                    child: Icon(
                                      Icons.cancel_outlined,
                                      color: Colors.black,
                                    ),
                                  ))
                            ]),
                          )
                        : Container(
                            height: 0,
                          ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * 0.32),
                      child: Text(
                        "Approx post reach is $reach",
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.normal,
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.016),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * 0.06),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.06,
                        width: MediaQuery.of(context).size.width * 0.82,
                        decoration: BoxDecoration(
                            gradient: postBody.isNotEmpty
                                ? const LinearGradient(colors: [
                                    Color(0xff4988EF),
                                    Color(0xff476DEE)
                                  ])
                                : const LinearGradient(
                                    colors: [Colors.grey, Colors.grey]),
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        child: Center(
                          child: Text(
                            'Post',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.019,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.06,
                left: MediaQuery.of(context).size.width * 0.03,
                right: MediaQuery.of(context).size.width * 0.03),
            child: Container(
              height: double.infinity,
              width: double.infinity,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              // setState(() {
                              //   postBody = "";
                              // });
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_back_rounded,
                                  size: 28,
                                  color: Color(0xff373737),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.34,
                                ),
                                Text(
                                  "Post",
                                  style: GoogleFonts.roboto(
                                    textStyle: TextStyle(
                                        color: Colors.black,
                                        //fontWeight: FontWeight.bold,
                                        fontSize:
                                            MediaQuery.of(context).size.height *
                                                0.022),
                                  ),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.34,
                                ),
                                InkWell(
                                  onTap: () {
                                    PickImage();
                                  },
                                  child: Icon(
                                    Icons.attach_file_rounded,
                                    size: 24,
                                    color: Color(0xff373737),
                                  ),
                                ),
                              ],
                            )),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "",
                          style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                                color: Color(0xff4666ED),
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    MediaQuery.of(context).size.height * 0.025),
                          ),
                        ),
                        // postBody.split(' ').length < 6 ||
                        //         postBody.split(' ').length > 600
                        //     ? Container(
                        //         height: MediaQuery.of(context).size.height * 0.04,
                        //         width: MediaQuery.of(context).size.width * 0.2,
                        //         decoration: const BoxDecoration(
                        //             gradient: LinearGradient(colors: [
                        //               Colors.grey,
                        //               Colors.grey,
                        //             ]),
                        //             borderRadius:
                        //                 BorderRadius.all(Radius.circular(81))),
                        //         child: Center(
                        //           child: Text(
                        //             'Post',
                        //             style: TextStyle(
                        //               color: Colors.white,
                        //               fontSize:
                        //                   MediaQuery.of(context).size.height * 0.019,
                        //             ),
                        //           ),
                        //         ),
                        //       )
                        //     : Consumer<FeedProvider>(
                        //         builder: (context, value, child) {
                        //           final fp =
                        //               Provider.of<FeedProvider>(context, listen: false);
                        //           return InkWell(
                        //             onTap: () {
                        //               apiCreatePost();
                        //               //fp.deleteAll();
                        //               feed.insert(
                        //                   0,
                        //                   FeedCard(
                        //                       firstName: name!,
                        //                       post: postBody,
                        //                       profilePic: profilePic!,
                        //                       profession: profession!,
                        //                       time: now.LT.toString(),
                        //                       authorGraphId: 0,
                        //                       postId: postId!));
                        //               // fp.addList(FeedCard(
                        //               //     firstName: name!,
                        //               //     post: postBody,
                        //               //     profilePic: profilePic!,
                        //               //     profession: profession!));

                        //               Navigator.pop(context);
                        //               //fp.addList(FeedCard(post:postBody,firstName:"Devansh",));
                        //             },
                        //             child: Container(
                        //               height: MediaQuery.of(context).size.height * 0.04,
                        //               width: MediaQuery.of(context).size.width * 0.2,
                        //               decoration: const BoxDecoration(
                        //                   gradient: LinearGradient(colors: [
                        //                     Color(0xff4988EF),
                        //                     Color(0xff476DEE)
                        //                   ]),
                        //                   borderRadius:
                        //                       BorderRadius.all(Radius.circular(81))),
                        //               child: Center(
                        //                 child: Text(
                        //                   'Post',
                        //                   style: TextStyle(
                        //                     color: Colors.white,
                        //                     fontSize:
                        //                         MediaQuery.of(context).size.height *
                        //                             0.019,
                        //                   ),
                        //                 ),
                        //               ),
                        //             ),
                        //           );
                        //         },
                        //       ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Divider(color: Colors.grey, height: 1, thickness: 0.2),
                    Padding(
                      padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * 0.01,
                          top: MediaQuery.of(context).size.height * 0.02),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.0,
                                top: MediaQuery.of(context).size.height * 0.01),
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(
                                profilePic!,
                              ),
                              radius: 20.5,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width * 0.05,
                              top: MediaQuery.of(context).size.height * 0.0,
                            ),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.26,
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: TextFormField(
                                keyboardType: TextInputType.multiline,
                                maxLines: 40,
                                onChanged: (value) {
                                  setState(() {
                                    postBody = value;
                                  });
                                },
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText:
                                        "Anything you want to ask to your trusted network?",
                                    hintStyle: GoogleFonts.roboto(
                                        textStyle:
                                            TextStyle(color: Colors.grey))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

class FeedCard extends StatelessWidget {
  String firstName;
  String profilePic;
  String post;
  String profession;
  String? mutual;
  String time;
  int? cursor;
  int authorGraphId;
  String postId;
  bool selfCreated;
  String? chatID;
  String? postUrl;
  FeedCard(
      {required this.firstName,
      required this.selfCreated,
      required this.post,
      required this.profilePic,
      required this.profession,
      required this.time,
      required this.authorGraphId,
      required this.postId,
      required this.chatID,
      required this.postUrl,
      this.cursor,
      this.mutual});
  Future apiFullPostView(
      String postID, bool selfTrue, int authorGId, String? chatID) async {
    print("chatt id is $chatID");
    var request = await d.dio.get(
        'http://3.110.164.26/v1/api/feed/post/view?postId=$postId&selfPost=$selfTrue&authorGraphId=$authorGId&chatID=$chatID');

    //print(request.data);
    if (request.statusCode == 200) {
    } else {
      print(request.statusMessage);
    }
    List chatIDs = [];
    String chatId;
    print(selfTrue);
    if (selfTrue == false) {
      print(request.data['data']['chatId']);
      chatId = request.data['data']['chatId'];
      return chatId;
    } else {
      if (request.data['data'].length > 0) {
        for (var cid in request.data['data']) {
          print(cid['chatId']);
          chatIDs.add(cid['chatId']);
        }
      }
    }
    return chatIDs;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, value, child) {
        final cp = Provider.of<ChatProvider>(context, listen: false);
        final cpr = Provider.of<ChatRProvider>(context, listen: false);
        return InkWell(
          onTap: () async {
            if (selfCreated == true) {
              List cId = await apiFullPostView(
                  postId, selfCreated, authorGraphId, chatID ?? null);
              print('object is $authorGraphId');
              cp.setData(
                  nameData: firstName,
                  postData: post,
                  postIDData: postId,
                  professionData: profession,
                  timeData: time,
                  graphData: authorGraphId,
                  socketData: socket,
                  chatsId: cId,
                  chatId: "",
                  mutual: mutual ?? "",
                  profileData: profilePic);
              cpr.setData(
                  postCursor: 0,
                  nameData: firstName,
                  postData: post,
                  postIDData: postId,
                  professionData: profession,
                  timeData: time,
                  graphData: authorGraphId,
                  socketData: socket,
                  postUrl: postUrl ?? "",
                  chatId: "",
                  mutual: mutual ?? "",
                  profileData: profilePic);

              Navigator.pushNamed(context, '/self');
            } else {
              String cId = await apiFullPostView(
                  postId, selfCreated, authorGraphId, chatID ?? null);
              print("graph id is $authorGraphId");
              cp.setData(
                  nameData: firstName,
                  postData: post,
                  postIDData: postId,
                  professionData: profession,
                  timeData: time,
                  graphData: authorGraphId,
                  socketData: socket,
                  chatsId: [],
                  chatId: cId,
                  mutual: mutual ?? "",
                  profileData: profilePic);
              Navigator.pushNamed(context, '/chat');
            }
          },
          child: Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.014,
                left: MediaQuery.of(context).size.width * 0.0,
                right: MediaQuery.of(context).size.width * 0.0),
            child: Container(
              color: Colors.white,
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.004,
                    left: MediaQuery.of(context).size.width * 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Consumer<GraphID>(
                          builder: (context, value, child) {
                            final gp =
                                Provider.of<GraphID>(context, listen: false);
                            return Padding(
                              padding: EdgeInsets.only(
                                  top:
                                      MediaQuery.of(context).size.height * 0.00,
                                  left:
                                      MediaQuery.of(context).size.width * 0.02),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, '/seeProfile',
                                      arguments: {'graphID': authorGraphId});
                                  gp.setGID(authorGraphId);
                                },
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    profilePic,
                                  ),
                                  radius: 18.5,
                                ),
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.0,
                              bottom: MediaQuery.of(context).size.height * 0.01,
                              left: MediaQuery.of(context).size.width * 0.03),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.82,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          firstName,
                                          style: GoogleFonts.roboto(
                                            textStyle: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600,
                                                fontSize: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.019),
                                          ),
                                        ),
                                        mutual == null || mutual == ""
                                            ? Container(
                                                height: 0,
                                                width: 0,
                                              )
                                            : Padding(
                                                padding: EdgeInsets.only(
                                                    top: MediaQuery.of(context)
                                                            .size
                                                            .height *
                                                        0.0025,
                                                    left: MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.03),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      backgroundColor:
                                                          Color(0xff336FD7),
                                                      radius: 5.5,
                                                      child: CircleAvatar(
                                                        radius: 4.5,
                                                        backgroundColor:
                                                            Colors.white,
                                                        child: Text(
                                                          'm',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: GoogleFonts
                                                              .roboto(
                                                                  textStyle:
                                                                      TextStyle(
                                                            color: Color(
                                                                0xff336FD7),
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontSize: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height *
                                                                0.009,
                                                          )),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 4,
                                                    ),
                                                    Text("$mutual Mutual",
                                                        style:
                                                            GoogleFonts.roboto(
                                                                textStyle:
                                                                    TextStyle(
                                                          color:
                                                              Color(0xff336FD7),
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              0.012,
                                                        )))
                                                  ],
                                                ),
                                              ),
                                      ],
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                          top: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Icon(
                                                Icons.remove_red_eye,
                                                color: Colors.grey,
                                                size: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.014,
                                              ),
                                              Text(
                                                " 100 ",
                                                style: GoogleFonts.roboto(
                                                  textStyle: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Color(0xffA8A8A8),
                                                      // fontWeight: FontWeight.bold,
                                                      fontSize:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.013),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 0.0, right: 4),
                                    child: Text(
                                      profession,
                                      style: GoogleFonts.roboto(
                                        textStyle: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xffA8A8A8),
                                            // fontWeight: FontWeight.bold,
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.013),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 2.0, right: 6),
                                    child: CircleAvatar(
                                      radius: 2,
                                      backgroundColor: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    time,
                                    style: GoogleFonts.roboto(
                                      textStyle: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xffA8A8A8),
                                          // fontWeight: FontWeight.bold,
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.013),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height * 0.01,
                          left: MediaQuery.of(context).size.width * 0.03),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 1,
                        child: ReadMoreText(
                          post,
                          trimLines: 3,
                          colorClickableText: Color(0xff336FD7),
                          trimMode: TrimMode.Line,

                          // overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          //softWrap: true,
                          trimCollapsedText: 'show more',
                          trimExpandedText: '  show less',
                          style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                                color: Color(0xff373737),
                                fontWeight: FontWeight.w400,
                                fontSize:
                                    MediaQuery.of(context).size.height * 0.022),
                          ),
                        ),
                      ),
                    ),
                    postUrl!.isNotEmpty
                        ? Padding(
                            padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).size.height * 0.014,
                                left: MediaQuery.of(context).size.width * 0.0),
                            child: Image.network(
                              postUrl ?? "",
                              height: MediaQuery.of(context).size.height * 0.5,
                              width: MediaQuery.of(context).size.width * 1,
                              fit: BoxFit.fill,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.2,
                                  width:
                                      MediaQuery.of(context).size.width * 0.7,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xff4666ED),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : SizedBox(
                            height: 0,
                          )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ListContact extends StatelessWidget {
  String name;
  String phoneNo;
  String profilePic;
  bool onPlatform;
  ListContact(
      {required this.name,
      required this.phoneNo,
      required this.profilePic,
      required this.onPlatform});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.00,
          left: MediaQuery.of(context).size.width * 0.04,
          bottom: MediaQuery.of(context).size.height * 0.01,
          right: MediaQuery.of(context).size.width * 0.07),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              profilePic == ""
                  ? Icon(
                      Icons.account_circle_outlined,
                      color: Colors.grey,
                      size: MediaQuery.of(context).size.height * 0.055,
                    )
                  : CircleAvatar(
                      backgroundImage: NetworkImage(profilePic),
                      radius: MediaQuery.of(context).size.height * 0.025,
                    ),
              SizedBox(
                width: 10,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.roboto(
                        textStyle: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    height: 2,
                  ),
                  Text(
                    phoneNo,
                    style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                            fontWeight: FontWeight.w400, color: Colors.grey)),
                  ),
                ],
              ),
            ],
          ),
          // InkWell(
          //   onTap: () {
          //     Navigator.pushNamed(context, '/feed',arguments: {'indexNo':1});
          //   },
          //   child: Text(
          //     onPlatform == true ? "Add to chat" : "Invite",
          //     style: GoogleFonts.roboto(
          //         textStyle: TextStyle(
          //             fontWeight: FontWeight.w700,
          //             decoration: TextDecoration.underline,
          //             color: Color(0xff3E6CE9))),
          //   ),
          // ),
        ],
      ),
    );
  }
}
