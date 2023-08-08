import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:mutual/provider/chat_provider.dart';
import 'package:mutual/provider/chat_scroll_provider.dart';
import 'package:mutual/provider/graphID_provider.dart';
import 'package:mutual/database/db.dart';
import 'package:mutual/screens/feed.dart';
import 'package:mutual/widgets/feed_card.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../constant/ip_address.dart';
import '../widgets/chat_card.dart';
import '../database/db.dart';

List<ChatCard> chat = [];
ScrollController _scrollController = new ScrollController();
String name = "";
String profilePic = "";
String profession = "";
String? search = "";
String? postId = "";
int graphId = 0;
String currentText = tec.text;
List<ChatCard> postChat = [];
Timer? _debounce;
bool isTyping = false;
// late IO.Socket socket;
int count = 0;
int online = 0;
int nchat = 0;
bool scroll = true;
bool description = true;
TextEditingController tec = TextEditingController();

class Chat extends StatefulWidget {
  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
    // tec.dispose();
  }

  _onSearchChanged(String query) {
    final cp = Provider.of<ChatProvider>(context, listen: false);
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      print('object');
      socket.emit('stop_typing', {'chatId': cp.chatID, 'firstName': cp.name});

      // do something with query
    });
    socket.emit('typing', {'chatId': cp.chatID, 'firstName': cp.name});
  }

  Future apigetUser() async {
    var request = await d.dio.get('http://${IP.ipAddress}/v1/api/user/details');

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

  Future apiIsOnline() async {
    final cp = Provider.of<ChatProvider>(context, listen: false);
    print("author ${cp.authorGraphId}");
    var request = await d.dio.get(
        'http://${IP.ipAddress}/v1/api/active/chatids?graphId=${cp.authorGraphId}');

    if (request.statusCode == 200) {
      setState(() {
        isOnline = request.data['data']['isActive'];
      });
    } else {
      print(request.statusMessage);
    }
  }

  Future<void> apiChatCursor(int cursor) async {
    final cp = Provider.of<ChatProvider>(context, listen: false);

    var request = await d.dio.get(
        'http://${IP.ipAddress}/v1/api/chat/get?after=$cursor&chatId=${cp.chatID}');
    print("cursor is $cursor");
    print("request data is");
    print(request.data);
    List<ChatCard> temp = [];
    setState(() {
      if (request.data['data'].length > 0) {
        for (var element in request.data['data']) {
          print('element is $element');
          String time = Moment.parse(DateTime.parse((element['createdAt']))
                  .add(Duration(hours: 5, minutes: 30))
                  .toString())
              .formatTime()
              .toString();

          setState(() {
            temp.add(ChatCard(
                text: element['chat'],
                graphId: element['graphId'],
                profession: element['profession'] ?? "",
                time: time,
                right: element['graphId'] == graphId ? true : false,
                profilePic: element['profilePic'],
                postId2: element['postId'],
                mutual: element['mutual'] ?? "",
                chatId: element['chatId'],
                cursor: element['cursor'],
                name: element['firstName']));
          });
        }
        chat.addAll(temp.reversed);
      }
    });

    if (request.statusCode == 200) {
    } else {}
  }

  Future<void> apiFetchChat() async {
    final cp = Provider.of<ChatProvider>(context, listen: false);

    var request = await d.dio
        .get('http://${IP.ipAddress}/v1/api/chat/get?chatId=${cp.chatID}');
    List<ChatCard> buffer = [];
    String? time;
    if (request.data['data'].length > 0) {
      for (var element in request.data['data']) {
        print('element is $element');
        time = Moment.parse(DateTime.parse((element['createdAt']))
                .add(Duration(hours: 5, minutes: 30))
                .toString())
            .formatTime()
            .toString();
        buffer.add(ChatCard(
            text: element['chat'],
            graphId: element['graphId'],
            profession: element['profession'] ?? "",
            time: time,
            right: element['graphId'] == graphId ? true : false,
            profilePic: element['profilePic'],
            postId2: element['postId'],
            mutual: element['mutual'] ?? "",
            chatId: element['chatId'],
            cursor: element['cursor'],
            name: element['firstName']));
      }
      setState(() {
        chat.addAll(buffer.reversed);
        for (var element in buffer.reversed) {
          dbnew.rawInsert(
              "INSERT INTO chat (postId,chatId, message ,right,profilePic,name,postId2,time,profession,mutual,cursor,graphId,post,authorName) VALUES (?,?, ?, ?,?, ?, ?,?, ?, ?,?,?,?,?);",
              [
                element.postId2,
                element.chatId,
                element.text,
                element.right,
                element.profilePic,
                element.name,
                element.postId2,
                element.time,
                element.profession,
                element.mutual ?? "",
                element.cursor,
                element.graphId,
                cp.post,
                cp.name
              ]);
        }
      });
    }

    if (request.statusCode == 200) {
    } else {}
  }

  localChatCheck() async {
    final cp = Provider.of<ChatProvider>(context, listen: false);
    String queryVar = cp.chatID!;
    List countt = await dbnew
        .rawQuery("Select count(*) from chat where chatId=?", [queryVar]);
    if (countt[0]['count(*)'] > 500) {
      await dbnew.rawQuery(
          "DELETE FROM chat WHERE cursor =(SELECT MIN(cursor) FROM chat WHERE chatId=?)",
          [queryVar]);
    }
  }

  Future<void> apiChatCursorBefore(int cursor) async {
    final cp = Provider.of<ChatProvider>(context, listen: false);
    print("dear cursor $cursor  ${cp.chatID}");
    var request = await d.dio.get(
        'http://${IP.ipAddress}/v1/api/chat/get?before=$cursor&chatId=${cp.chatID}');

    print(request.data);
    List<ChatCard> buffer = [];

    if (request.data['data'].length > 0) {
      for (var element in request.data['data']) {
        print('element is $element');
        String time = Moment.parse(DateTime.parse((element['createdAt']))
                .add(Duration(hours: 5, minutes: 30))
                .toString())
            .formatTime()
            .toString();

        //setState(() {
        scroll = false;

        buffer.add(ChatCard(
            text: element['chat'],
            profession: element['profession'] ?? "",
            time: time,
            graphId: element['graphId'],
            right: element['graphId'] == graphId ? true : false,
            profilePic: element['profilePic'],
            postId2: element['postId'],
            mutual: element['mutual'] ?? "",
            chatId: element['chatId'],
            cursor: element['cursor'],
            name: element['firstName']));
        //   });
      }
      String queryVar = cp.chatID!;
      List countt = await dbnew
          .rawQuery("Select count(*) from chat where chatId=?", [queryVar]);
      _scrollController.jumpTo(_scrollController.position.viewportDimension);
      chat.insertAll(0, buffer.reversed);
      setState(() {
        final double old = _scrollController.position.pixels;
        final double oldMax = _scrollController.position.maxScrollExtent;
        final diff = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(old + diff - 5);
        if (countt[0]['count(*)'] < 500) {
          // for (var element in buffer.reversed) {
          //   dbnew.rawInsert(
          //       "INSERT INTO chat (postId,chatId, message ,right,profilePic,name,postId2,time,profession,mutual,cursor,graphId) VALUES (?,?, ?, ?,?, ?, ?,?, ?, ?,?,?);",
          //       [
          //         element.postId2,
          //         element.chatId,
          //         element.text,
          //         element.right,
          //         element.profilePic,
          //         element.name,
          //         element.postId2,
          //         element.time,
          //         element.profession,
          //         element.mutual ?? "",
          //         element.cursor,
          //         element.graphId
          //       ]);
          // }
        }
      });
    }

    if (request.statusCode == 200) {
    } else {}
  }

  MyDb mydb = new MyDb();
  List storedchat = [];
  int cursorCount = 0;
  int cursorAdd = 0;
  late Database dbnew;
  Future intializeDB() async {
    dbnew = await mydb.open();
  }

  resteFloatState() {
    final cs = Provider.of<ChatScroll>(context, listen: false);
    cs.setFloatState(false);
  }

  @override
  void initState() {
    //  initSocket();
    resteFloatState();
    intializeDB();
    apigetUser();
    _scrollController.addListener(() {
      final cs = Provider.of<ChatScroll>(context, listen: false);
      if (_scrollController.offset >=
          _scrollController.position.minScrollExtent) {
        cs.setFloatState(true);
      }
      if (_scrollController.offset <=
          _scrollController.position.minScrollExtent) {
        cs.setFloatState(false);
      }
    });

    //  getData();
    count = 0;
    nchat = 0;
    cursorAdd = 0;
    cursorCount = 0;
    online = 0;
    chat.clear();
    apiIsOnline();
    // TODO: implement initState
    super.initState();
  }

  //const Chat({super.key});

  Future<String> getAccessTokens() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return await pref.getString("accessToken").toString();
  }

  bool floatingState = false;
  bool isOnline = false;
  @override
  Widget build(BuildContext context) {
    print(chat.length);
    final cp = Provider.of<ChatProvider>(context, listen: false);

    if (online++ == 0) {
      print("chat id iss ${cp.chatID}");
      socket.emit('joinRoom', {'chatId': cp.chatID});
      socket.emit('online', {
        'graphId': graphId,
        'chatId': cp.chatID,
      });
    }
    if (scroll == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0,
              duration: const Duration(milliseconds: 1), curve: Curves.linear);
        }
      });
    }
    scroll = true;

    Future.delayed(Duration(milliseconds: 700), () async {
      //use delay min 500 ms, because database takes time to initilize.
      storedchat = await dbnew
          .rawQuery('SELECT * FROM chat WHERE chatId = ?', [cp.chatID]);
      //count[0]['count(*)'], print(storedchat.elementAt(storedchat.length - 1));

      if (nchat++ == 0) {
        if (storedchat.length == 0) {
          apiFetchChat();
          return;
        }
        print('stored chat');
        print(storedchat.elementAt(storedchat.length - 1));
        apiChatCursor(storedchat.elementAt(storedchat.length - 1)['cursor']);
        for (var element in storedchat) {
          setState(() {
            chat.add(ChatCard(
                text: element['message'] ?? "",
                profession: element['profession'] ?? "",
                time: element['time'],
                right: (element['right'] == 1 ? true : false) ?? false,
                profilePic: element['profilePic'] ?? "",
                postId2: element['postId2'] ?? "",
                chatId: element['chatId'] ?? "",
                mutual: element['mutual'] ?? [],
                cursor: element['cursor'],
                graphId: element['graphId'],
                name: element['name'] ?? ""));
          });
        }
      }
    }); //refresh UI after getting data from table.

    void submit() async {
      int cursorValue = DateTime.now().millisecondsSinceEpoch;
      String queryVar = cp.chatID!;
      List countt = await dbnew
          .rawQuery("Select count(*) from chat where chatId=?", [queryVar]);
      if (countt[0]['count(*)'] > 500) {
        await dbnew.rawQuery(
            "DELETE FROM chat WHERE cursor =(SELECT MIN(cursor) FROM chat WHERE chatId=?)",
            [queryVar]);
      }

      dbnew.rawInsert(
          "INSERT INTO chat (postId,chatId, message ,right,profilePic,name,postId2,time,profession,mutual,cursor,graphId,post,authorName) VALUES (?,?, ?, ?,?, ?, ?,?, ?, ?,?,?,?,?);",
          [
            cp.postId,
            cp.chatID,
            tec.text,
            true,
            profilePic,
            name,
            cp.postId!,
            DateFormat("HH:mm a").format(DateTime.now()).toString(),
            profession,
            "",
            cursorValue,
            cp.authorGraphId ?? 0,
            cp.post,
            cp.name
          ]);

      print(DateTime.now().millisecondsSinceEpoch);
      bool contains = false;
      for (var e in myPost) {
        if (e.postId == cp.postId!) {
          contains = true;
          break;
        }
      }
      if (contains == false) {
        myPost.insert(
            0,
            FeedCard(
                firstName: cp.name ?? "",
                post: cp.post!,
                profilePic: cp.profilePic ?? "",
                profession: cp.profession ?? "",
                time: cp.time!,
                authorGraphId: cp.authorGraphId!,
                selfCreated: false,
                mutual: cp.mutuals,
                postUrl: "",
                chatID: cp.chatID,
                postId: cp.postId!));
      }

      setState(() {
        print(Moment.now());
        chat.add(ChatCard(
          text: tec.text,
          graphId: cp.authorGraphId!,
          profession: profession,
          time: DateFormat("HH:mm a").format(DateTime.now()).toString(),
          right: true,
          name: name,
          chatId: cp.chatID!,
          postId2: cp.postId!,
          profilePic: profilePic,
          mutual: "",
          cursor: cursorValue,
        ));
      });
      count--;
      print(cp.mutuals);
      print("name is $name");
      print("testing chat id${cp.chatID}");
      socket.emit('chat', {
        'firstName': name,
        'profilePic': profilePic,
        'postId': cp.postId,
        'graphId': graphId,
        'message': tec.text,
        'profession': cp.profession,
        'mutual': cp.mutuals,
        'chatId': cp.chatID,
        'cursor': cursorValue

        // 'createdAt':Moment.now()
      });
      tec.clear();
    }

    if (count++ == 0) {
      socket.on('typing', (data) {
        if (this.mounted) {
          if (data['chatId'] == cp.chatID) {
            setState(() {
              isTyping = true;
              print("type ho ra");
            });
          }
        }
        print(data);
      });
      socket.on('stop_typing', (data) {
        if (this.mounted) {
          if (data['chatId'] == cp.chatID) {
            setState(() {
              isTyping = false;
            });
          }
        }
        print("stop typing $data");
      });
      socket.on('online', (data) {
        if (this.mounted) {
          if (data['graphId'] != cp.authorGraphId) {
            setState(() {
              isOnline = true;
              print("set state is ecexrc");
              print(isOnline);
            });
          }
        }
      });
      socket.on('offline', (data) {
        if (this.mounted) {
          if (data['graphId'] != cp.authorGraphId) {
            setState(() {
              isOnline = false;
              print("set state is ecexrc");
              print(isOnline);
            });
          }
        }
      });
      // Moment.setGlobalLocalization(MomentLocalizations.());
      socket.on('chat', (data) {
        if (this.mounted) {
          setState(() {
            String time = Moment.parse(DateTime.parse((data['createdAt']))
                    .add(Duration(hours: 5, minutes: 30))
                    .toString())
                .formatTime()
                .toString();
            localChatCheck();

            dbnew.rawInsert(
                "INSERT INTO chat (postId, chatId,message ,right,profilePic,name,postId2,time,profession,mutual,cursor,graphId,post,authorName) VALUES (?,?, ?, ?,?, ?, ?,?, ?, ?,?,?,?,?);",
                [
                  data['postId'] ?? "",
                  data['chatId'] ?? "",
                  data['message'] ?? "",
                  false,
                  data['profilePic'] ?? "",
                  data['firstName'] ?? "",
                  data['postId'] ?? "",
                  time,
                  data['profession'] ?? "",
                  data['mutual'] ?? "",
                  data['cursor'],
                  data['graphId'],
                  cp.post,
                  cp.name
                ]);

            print("data is ");
            print("is chaatt workinggg");
            print(data);
            print(cp.postId);

            print("time is ${data['createdAt']}");
            chat.add(ChatCard(
              profession: data['profession'] ?? "",
              postId2: data['postId'],
              cursor: data['cursor'],
              graphId: data['graphId'],
              text: data['message'],
              right: false,
              chatId: data['chatId'],
              time: time,
              name: data['firstName'],
              profilePic: data['profilePic'],
              mutual: cp.mutuals ?? "",
            ));
            print('donee');
          });
        }
      });
    }
    postChat.clear();
    for (ChatCard element in chat) {
      if (cp.postId == element.postId2) postChat.add(element);
    }

    return WillPopScope(
      onWillPop: () async {
        socket.emit('offline', {
          'graphId': graphId,
          'chatId': cp.chatID,
        });

        return await true;
      },
      child: SafeArea(
        child: Consumer<ChatScroll>(
          builder: (context, value, child) {
            final cs = Provider.of<ChatScroll>(context, listen: false);
            return Scaffold(
                resizeToAvoidBottomInset: true,
                floatingActionButton: Visibility(
                  visible: value.floatstate,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    child: FloatingActionButton(
                      onPressed: () {
                        cs.setFloatState(false);
                        _scrollController.animateTo(0,
                            duration: Duration(milliseconds: 100),
                            curve: Curves.linear);
                      },
                      backgroundColor: Colors.grey.shade100,
                      elevation: 1,
                      child: CircleAvatar(
                        backgroundColor: Colors.grey.shade100,
                        child: Icon(
                          Icons.keyboard_double_arrow_down_rounded,
                          color: Colors.grey,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                appBar: AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          socket.emit('offline', {
                            'graphId': graphId,
                            'chatId': cp.chatID,
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width * 0.0,
                              right: 0),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                        )),
                    titleSpacing: 0,
                    title: Consumer<ChatProvider>(
                      builder: (context, value, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                  left: 0,
                                  right:
                                      MediaQuery.of(context).size.width * 0.04),
                              child: InkWell(
                                onTap: () {
                                  final gp = Provider.of<GraphID>(context,
                                      listen: false);
                                  gp.setGID(cp.authorGraphId!);
                                  Navigator.pushNamed(context, '/seeProfile');
                                },
                                child: CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  radius: MediaQuery.of(context).size.height *
                                      0.022,
                                  backgroundImage: NetworkImage(
                                    cp.profilePic!,
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${value.name}'s Chat ",
                                    style: GoogleFonts.roboto(
                                        textStyle: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize:
                                          MediaQuery.of(context).size.height *
                                              0.023,
                                    ))),
                                Visibility(
                                  visible: isOnline,
                                  child: Text(
                                      isTyping == false
                                          ? "Online"
                                          : "typing...",
                                      style: GoogleFonts.roboto(
                                          textStyle: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                        fontSize:
                                            MediaQuery.of(context).size.height *
                                                0.013,
                                      ))),
                                )
                              ],
                            ),
                          ],
                        );
                      },
                    )),
                backgroundColor: Colors.white,
                bottomNavigationBar: Theme(
                  data: ThemeData(
                    inputDecorationTheme: const InputDecorationTheme(
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide(width: 0.1, color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide(width: 0.1, color: Colors.grey),
                      ),
                    ),
                  ),
                  child: Material(
                    elevation: 0,
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * 0.01,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 5,
                          right: MediaQuery.of(context).size.width * 0.01),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 10, left: 4, top: 0, bottom: 0),
                            child: Container(
                              height: 34,
                              //color: Colors.black,
                              width: 30.8,
                              decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Color(0xff4988EF),
                                    Color(0xff476DEE)
                                  ]),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8))),
                              child: PopupMenuButton<int>(
                                  position: PopupMenuPosition.under,
                                  itemBuilder: (context) => [
                                        PopupMenuItem(
                                          //height: 30,
                                          value: 1,
                                          child: Row(
                                            children: [
                                              Icon(Icons.attach_file_rounded,
                                                  color: Colors.white),
                                              Text(
                                                " Add Media",
                                                style: GoogleFonts.roboto(
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.0165,
                                                    color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),

                                        PopupMenuItem(
                                          // height: 30,
                                          onTap: () {
                                            void getContactPermission() async {
                                              if (await Permission
                                                  .contacts.isGranted) {
                                                Navigator.pushNamed(
                                                    context, '/addContact');
                                              } else {
                                                await Permission.contacts
                                                    .request();
                                                if (await Permission
                                                    .contacts.isGranted)
                                                  Navigator.pushNamed(
                                                      context, '/addContact');
                                              }
                                            }
                                          },
                                          value: 2,
                                          child: InkWell(
                                            onTap: () {
                                              Future.delayed(
                                                  Duration.zero,
                                                  () => Navigator.pushNamed(
                                                      context, '/addContact'));
                                            },
                                            child: Row(
                                              children: [
                                                Icon(
                                                    Icons
                                                        .perm_contact_cal_sharp,
                                                    color: Colors.white),
                                                Text(
                                                  " Add contact",
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.0165,
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // PopupMenuItem 2
                                      ],
                                  //offset: Offset(0, 100),
                                  color: Color(0xff336FD7),
                                  elevation: 2,
                                  onSelected: (value) {
                                    if (value == 1) {
                                      // _showDialog(context);
                                      // if value 2 show dialog
                                    }
                                  },
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 28,
                                  )),
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.746,
                            child: Scrollbar(
                              controller: _scrollController,
                              child: TextFormField(
                                onChanged: _onSearchChanged,
                                controller: tec,
                                maxLines: 6,
                                minLines: 1,
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.height *
                                            0.0165),
                                keyboardType: TextInputType.multiline,
                                scrollPadding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  hintText: "",

                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(20)),
                                      borderSide: BorderSide(
                                          width: 0.1, color: Colors.grey)),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(20)),
                                      borderSide: BorderSide(
                                          width: 0.1, color: Colors.grey)),
                                  disabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(20)),
                                      borderSide: BorderSide(
                                          width: 0.1, color: Colors.grey)),

                                  contentPadding: const EdgeInsets.only(
                                      top: 8, bottom: 8, left: 16, right: 0),
                                  // prefixIconConstraints: BoxConstraints(minWidth: 40,maxHeight: 45)
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (tec.length != 0) submit();
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(right: 4, left: 10),
                              child: Icon(Icons.send,
                                  size: MediaQuery.of(context).size.height *
                                      0.036,
                                  color: Color(0xff336FD7)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                body: Consumer<ChatProvider>(builder: (context, value, child) {
                  final cp = Provider.of<ChatProvider>(context, listen: false);
                  return Stack(children: [
                    Column(
                      children: [
                        cp.authorGraphId != graphId
                            ? description == true
                                ? InkWell(
                                    onTap: () {
                                      setState(() {
                                        description = false;
                                      });
                                    },
                                    child: Container(
                                      color: Colors.white,
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.052,
                                      width: MediaQuery.of(context).size.width,
                                      child: Column(
                                        children: [
                                          Divider(
                                            height: 2,
                                            thickness: 0.2,
                                            color: Colors.grey,
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.006,
                                            ),
                                            child: Row(
                                              //  mainAxisAlignment: M,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      top:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.004,
                                                      bottom:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.002,
                                                      right: 10,
                                                      left: 18),
                                                  child: Icon(
                                                    Icons.info_outline,
                                                    size: MediaQuery.of(context)
                                                            .size
                                                            .height *
                                                        0.0202,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      top:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.002,
                                                      bottom:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.002),
                                                  child: Text("Description : ",
                                                      style: GoogleFonts.roboto(
                                                          textStyle: TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.0192,
                                                      ))),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      top:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.002,
                                                      bottom:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.002),
                                                  child: Text(
                                                      " Tap here to expand !",
                                                      style: GoogleFonts.roboto(
                                                          textStyle: TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontSize: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.0192,
                                                      ))),
                                                )
                                              ],
                                            ),
                                          ),
                                          Divider(
                                            height: 10,
                                            thickness: 0.2,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : InkWell(
                                    onTap: () {
                                      setState(() {
                                        description = true;
                                      });
                                    },
                                    child: Container(
                                      color: Colors.white,
                                      width: MediaQuery.of(context).size.width,
                                      child: Column(
                                        children: [
                                          Divider(
                                            height: 2,
                                            thickness: 0.2,
                                            color: Colors.grey,
                                          ),
                                          Padding(
                                              padding: EdgeInsets.only(
                                                  top: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.008,
                                                  bottom: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.006),
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.9,
                                                child: Text(
                                                  cp.post!,
                                                  maxLines: 200,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.start,
                                                  softWrap: true,
                                                  style: GoogleFonts.roboto(
                                                    textStyle: TextStyle(
                                                        color:
                                                            Color(0xff373737),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.0192),
                                                  ),
                                                ),
                                              )),
                                          Divider(
                                            height: 10,
                                            thickness: 0.2,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                            : SizedBox(
                                height: 0,
                              ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () {
                              scroll = false;
                              return apiChatCursorBefore(postChat[0].cursor);
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              // physics: ScrollPhysics(),
                              scrollDirection: Axis.vertical,
                              // reverse: MediaQuery.of(context).viewInsets.bottom==0? false:true,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              reverse: true,

                              shrinkWrap: true,

                              //physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                if (index == 0)
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10.0),
                                    child:
                                        postChat[postChat.length - index - 1],
                                  );
                                return postChat[postChat.length - index - 1];
                              },
                              itemCount: postChat.length,
                            ),
                          ),
                        ),
                      ],
                    ),  
                  ]);        
                }));
          },
        ),
      ),
    );
  }
}





       