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
import 'package:mutual/screens/db.dart';
import 'package:mutual/screens/feed.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';

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
    var request = await d.dio.get('http://3.110.164.26/v1/api/user/details');

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
        'http://3.110.164.26/v1/api/active/chatids?graphId=${cp.authorGraphId}');

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
        'http://3.110.164.26/v1/api/chat/get?after=$cursor&chatId=${cp.chatID}');
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
        .get('http://3.110.164.26/v1/api/chat/get?chatId=${cp.chatID}');
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
        'http://3.110.164.26/v1/api/chat/get?before=$cursor&chatId=${cp.chatID}');

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
                    // Positioned(
                    //   top: 0,
                    //   left: 5,
                    //   child: description == true
                    //       ? InkWell(
                    //           onTap: () {
                    //             setState(() {
                    //               description = false;
                    //             });
                    //           },
                    //           child: Container(
                    //             color: Colors.white,
                    //             height:
                    //                 MediaQuery.of(context).size.height * 0.052,
                    //             width: MediaQuery.of(context).size.width,
                    //             child: Column(
                    //               children: [
                    //                 Divider(
                    //                   height: 10,
                    //                   thickness: 0.2,
                    //                   color: Colors.grey,
                    //                 ),
                    //                 Padding(
                    //                   padding: EdgeInsets.only(
                    //                     top:
                    //                         MediaQuery.of(context).size.height *
                    //                             0.006,
                    //                   ),
                    //                   child: Row(
                    //                     //  mainAxisAlignment: M,
                    //                     crossAxisAlignment:
                    //                         CrossAxisAlignment.start,
                    //                     children: [
                    //                       Padding(
                    //                         padding: EdgeInsets.only(
                    //                             top: MediaQuery.of(context)
                    //                                     .size
                    //                                     .height *
                    //                                 0.0,
                    //                             bottom: 2.0,
                    //                             right: 10,
                    //                             left: 18),
                    //                         child: Icon(
                    //                           Icons.info_outline,
                    //                           size: MediaQuery.of(context)
                    //                                   .size
                    //                                   .height *
                    //                               0.0202,
                    //                         ),
                    //                       ),
                    //                       Padding(
                    //                         padding: EdgeInsets.only(
                    //                           top: MediaQuery.of(context)
                    //                                   .size
                    //                                   .height *
                    //                               0.00,
                    //                         ),
                    //                         child: Text("Description : ",
                    //                             style: GoogleFonts.roboto(
                    //                                 textStyle: TextStyle(
                    //                               color: Colors.black,
                    //                               fontWeight: FontWeight.w600,
                    //                               fontSize:
                    //                                   MediaQuery.of(context)
                    //                                           .size
                    //                                           .height *
                    //                                       0.018,
                    //                             ))),
                    //                       ),
                    //                       Padding(
                    //                         padding: EdgeInsets.only(
                    //                           top: MediaQuery.of(context)
                    //                                   .size
                    //                                   .height *
                    //                               0.00,
                    //                         ),
                    //                         child: Text(" Tap here to expand !",
                    //                             style: GoogleFonts.roboto(
                    //                                 textStyle: TextStyle(
                    //                               color: Colors.black,
                    //                               fontWeight: FontWeight.w400,
                    //                               fontSize:
                    //                                   MediaQuery.of(context)
                    //                                           .size
                    //                                           .height *
                    //                                       0.018,
                    //                             ))),
                    //                       )
                    //                     ],
                    //                   ),
                    //                 ),
                    //                 Divider(
                    //                   height: 10,
                    //                   thickness: 0.2,
                    //                   color: Colors.grey,
                    //                 ),
                    //               ],
                    //             ),
                    //           ),
                    //         )
                    //       : InkWell(
                    //           onTap: () {
                    //             setState(() {
                    //               description = true;
                    //             });
                    //           },
                    //           child: Container(
                    //             color: Colors.white,
                    //             width: MediaQuery.of(context).size.width,
                    //             child: Column(
                    //               children: [
                    //                 Divider(
                    //                   height: 10,
                    //                   thickness: 0.2,
                    //                   color: Colors.grey,
                    //                 ),
                    //                 Padding(
                    //                     padding: EdgeInsets.only(
                    //                       top: MediaQuery.of(context)
                    //                               .size
                    //                               .height *
                    //                           0.006,
                    //                     ),
                    //                     child: Container(
                    //                       width: MediaQuery.of(context)
                    //                               .size
                    //                               .width *
                    //                           0.9,
                    //                       child: Text(
                    //                         cp.post!,
                    //                         maxLines: 200,
                    //                         overflow: TextOverflow.ellipsis,
                    //                         textAlign: TextAlign.start,
                    //                         softWrap: true,
                    //                         style: GoogleFonts.roboto(
                    //                           textStyle: TextStyle(
                    //                               color: Color(0xff373737),
                    //                               fontWeight: FontWeight.w400,
                    //                               fontSize:
                    //                                   MediaQuery.of(context)
                    //                                           .size
                    //                                           .height *
                    //                                       0.018),
                    //                         ),
                    //                       ),
                    //                     )),
                    //                 Divider(
                    //                   height: 10,
                    //                   thickness: 0.2,
                    //                   color: Colors.grey,
                    //                 ),
                    //               ],
                    //             ),
                    //           ),
                    //         ),
                    // )
                  ]);

                  // SizedBox(
                  //   height: 10,
                  // )
                  //SizedBox(height:MediaQuery.of(context).viewInsets.bottom,child: Container(height: 10,width: 10,),)
                }));
          },
        ),
      ),
    );
  }
}

class FeedCard3 extends StatelessWidget {
  String firstName;
  String profilePic;
  String post;
  String profession;
  String? mutual;
  String time;
  int? cursor;
  int authorGraphId;
  String postId;
  FeedCard3(
      {required this.firstName,
      required this.post,
      required this.profilePic,
      required this.profession,
      required this.time,
      required this.authorGraphId,
      required this.postId,
      this.cursor,
      this.mutual});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, value, child) {
        final cp = Provider.of<ChatProvider>(context, listen: false);
        return InkWell(
          onTap: () {
            // cp.setData(
            //     nameData: firstName,
            //     postData: post,
            //     postIDData: postId,
            //     professionData: profession,
            //     timeData: time,
            //     graphData: authorGraphId,
            //     socketData: socket,
            //     profileData: profilePic);
            // selfCreated==true?Navigator.pushNamed(context, '/self'):Navigator.pushNamed(context, '/chat');
          },
          child: Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.00,
                left: MediaQuery.of(context).size.width * 0.0,
                right: MediaQuery.of(context).size.width * 0.0),
            child: Container(
              color: Colors.grey.withOpacity(0.036),
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.00,
                    left: MediaQuery.of(context).size.width * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Consumer<GraphID>(
                        //   builder: (context, value, child) {
                        //     final gp =
                        //         Provider.of<GraphID>(context, listen: false);
                        //     return Padding(
                        //       padding: EdgeInsets.only(
                        //         left: MediaQuery.of(context).size.width * 0.00,
                        //         top: MediaQuery.of(context).size.height * 0.00,
                        //       ),
                        //       child: InkWell(
                        //         onTap: () {
                        //           Navigator.pushNamed(context, '/seeProfile',
                        //               arguments: {'graphID': authorGraphId});
                        //           gp.setGID(authorGraphId);
                        //         },
                        //         child: CircleAvatar(
                        //           backgroundImage: NetworkImage(
                        //             profilePic,
                        //           ),
                        //           radius: 28,
                        //         ),
                        //       ),
                        //     );
                        //   },
                        // ),
                        Padding(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.0,
                              bottom: MediaQuery.of(context).size.height * 0.02,
                              left: MediaQuery.of(context).size.width * 0.03),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.72,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Text(
                                        //   firstName,
                                        //   style: GoogleFonts.roboto(
                                        //     textStyle: TextStyle(
                                        //         color: Colors.black,
                                        //         fontWeight: FontWeight.w600,
                                        //         fontSize: MediaQuery.of(context)
                                        //                 .size
                                        //                 .height *
                                        //             0.019),
                                        //   ),
                                        // ),
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
                                                      radius: 5,
                                                      child: CircleAvatar(
                                                        radius: 4,
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
                                                                0.008,
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
                                                              0.011,
                                                        )))
                                                  ],
                                                ),
                                              ),
                                      ],
                                    ),
                                    // Padding(
                                    //   padding: EdgeInsets.only(
                                    //       top: MediaQuery.of(context)
                                    //               .size
                                    //               .height *
                                    //           0.0),
                                    //   child: Text(
                                    //     time,
                                    //     style: GoogleFonts.roboto(
                                    //       textStyle: TextStyle(
                                    //           fontWeight: FontWeight.w400,
                                    //           color: Color(0xffA8A8A8),
                                    //           // fontWeight: FontWeight.bold,
                                    //           fontSize: MediaQuery.of(context)
                                    //                   .size
                                    //                   .height *
                                    //               0.013),
                                    //     ),
                                    //   ),
                                    // )
                                  ],
                                ),
                              ),
                              // Padding(
                              //   padding: const EdgeInsets.only(top: 1.0),
                              //   child: Text(
                              //     profession,
                              //     style: GoogleFonts.roboto(
                              //       textStyle: TextStyle(
                              //           fontWeight: FontWeight.w400,
                              //           color: Color(0xff336FD7),
                              //           fontSize:
                              //               MediaQuery.of(context).size.height *
                              //                   0.011),
                              //     ),
                              //   ),
                              // ),
                              // SizedBox(
                              //   height: 18,
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Text(
                        post,
                        maxLines: 200,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        softWrap: true,
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                              color: Color(0xff373737),
                              fontWeight: FontWeight.w400,
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.018),
                        ),
                      ),
                    ),
                    // SizedBox(
                    //   height: 10,
                    // ),
                    // Divider(color: Colors.grey,height: 10,)
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

class ChatCard extends StatelessWidget {
  //const ChatCard({super.key});
  String text;
  bool right = true;
  String profilePic;
  String name;
  String postId2;
  String time;
  String profession;
  String mutual;
  String chatId;
  int cursor;
  int graphId;
  ChatCard(
      {required this.text,
      required this.graphId,
      required this.cursor,
      required this.profession,
      required this.time,
      required this.right,
      required this.chatId,
      required this.profilePic,
      required this.postId2,
      required this.mutual,
      required this.name});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: right == true
              ? MediaQuery.of(context).size.width * 0.0
              : MediaQuery.of(context).size.width * 0.03,
          top: MediaQuery.of(context).size.height * 0.004,
          bottom: MediaQuery.of(context).size.height * 0.0,
          right: right == true
              ? MediaQuery.of(context).size.width * 0.03
              : MediaQuery.of(context).size.width * 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            right == true ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Consumer(
            builder: (context, value, child) {
              final gp = Provider.of<GraphID>(context, listen: false);
              return Visibility(
                visible: !right,
                child: Padding(
                  padding: EdgeInsets.only(left: 2, right: 2),
                  child: InkWell(
                    onTap: () {
                      gp.setGID(graphId);
                      Navigator.pushNamed(context, '/seeProfile');
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.grey,
                      radius: MediaQuery.of(context).size.height * 0.014,
                      backgroundImage: NetworkImage(
                        profilePic,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Stack(children: [
                Container(
                  constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width * 0.2,
                      maxWidth: MediaQuery.of(context).size.width * 0.72),
                  decoration: BoxDecoration(
                      gradient: right == true
                          ? const LinearGradient(
                              colors: [Color(0xffE5EEFF), Color(0xffE5EEFF)])
                          : const LinearGradient(
                              colors: [Color(0xffEFEFEF), Color(0xffEFEFEF)]),
                      borderRadius: right == true
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              topRight: Radius.circular(12),
                              // bottomRight: Radius.circular(8)
                            )
                          : const BorderRadius.only(
                              topRight: Radius.circular(16),
                              topLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                              //bottomLeft: Radius.circular(24)
                            )),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        //crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          right == false
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                      left: 12.0, right: 10, top: 8, bottom: 0),
                                  child: Text(name,
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.roboto(
                                          textStyle: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                        fontSize:
                                            MediaQuery.of(context).size.height *
                                                0.0175,
                                      ))),
                                )
                              : Container(
                                  height: 0,
                                ),
                          right == false
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, right: 12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Color(0xff336FD7),
                                        radius: 5,
                                        child: CircleAvatar(
                                          radius: 4,
                                          backgroundColor: Colors.white,
                                          child: Text(
                                            'm',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.roboto(
                                                textStyle: TextStyle(
                                              color: Color(0xff336FD7),
                                              fontWeight: FontWeight.w400,
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.008,
                                            )),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Text("$mutual",
                                          style: GoogleFonts.roboto(
                                              textStyle: TextStyle(
                                            color: Color(0xff336FD7),
                                            fontWeight: FontWeight.w400,
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.011,
                                          )))
                                    ],
                                  ),
                                )
                              : Container(
                                  height: 0,
                                  width: 0,
                                )
                        ],
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.only(
                      //       left: 12.0, right: 0, top: 1, bottom: 0),
                      //   child: Text(profession,
                      //       textAlign: TextAlign.start,
                      //       style: GoogleFonts.roboto(
                      //           textStyle: TextStyle(
                      //         color: Color(0xff336FD7),
                      //         // fontWeight: FontWeight.w700,
                      //         fontSize:
                      //             MediaQuery.of(context).size.height * 0.011,
                      //       ))),
                      // ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 12.0, right: 20, top: 6, bottom: 14),
                        child: Text(text,
                            textAlign: TextAlign.start,
                            style: GoogleFonts.roboto(
                                textStyle: TextStyle(
                              color: Color(0xff373737),
                              fontWeight: FontWeight.w400,
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.0165,
                            ))),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 6,
                  child: Padding(
                    padding: EdgeInsets.only(
                        //  left: MediaQuery.of(context).size.width * 0.3,
                        right: 1,
                        top: 0,
                        bottom: 4),
                    child: Text(time,
                        textAlign: TextAlign.start,
                        style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                          color: right == true ? Colors.grey : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: MediaQuery.of(context).size.height * 0.01,
                        ))),
                  ),
                )
              ]),
            ],
          ),
          // Visibility(
          //   visible: right,
          //   child: Padding(
          //     padding: EdgeInsets.only(left: 6),
          //     child: CircleAvatar(
          //       backgroundColor: Colors.grey,
          //       backgroundImage: NetworkImage(profilePic),
          //     ),
          //   ),
          // )
        ],
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    Key? key,
    this.showIndicator = false,
    this.bubbleColor = const Color(0xffEFEFEF),
    this.flashingCircleDarkColor = const Color(0xFF333333),
    this.flashingCircleBrightColor = const Color(0xFFaec1dd),
  }) : super(key: key);

  final bool showIndicator;
  final Color bubbleColor;
  final Color flashingCircleDarkColor;
  final Color flashingCircleBrightColor;

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _appearanceController;

  late Animation<double> _indicatorSpaceAnimation;

  late Animation<double> _smallBubbleAnimation;
  late Animation<double> _mediumBubbleAnimation;
  late Animation<double> _largeBubbleAnimation;

  late AnimationController _repeatingController;
  final List<Interval> _dotIntervals = const [
    Interval(0.25, 0.8),
    Interval(0.35, 0.9),
    Interval(0.45, 1.0),
  ];

  @override
  void initState() {
    super.initState();

    _appearanceController = AnimationController(
      vsync: this,
    )..addListener(() {
        setState(() {});
      });

    _indicatorSpaceAnimation = CurvedAnimation(
      parent: _appearanceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    ).drive(Tween<double>(
      begin: 0.0,
      end: 60.0,
    ));

    _smallBubbleAnimation = CurvedAnimation(
      parent: _appearanceController,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      reverseCurve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _mediumBubbleAnimation = CurvedAnimation(
      parent: _appearanceController,
      curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      reverseCurve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    );
    _largeBubbleAnimation = CurvedAnimation(
      parent: _appearanceController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    _repeatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.showIndicator) {
      _showIndicator();
    }
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.showIndicator != oldWidget.showIndicator) {
      if (widget.showIndicator) {
        _showIndicator();
      } else {
        _hideIndicator();
      }
    }
  }

  @override
  void dispose() {
    _appearanceController.dispose();
    _repeatingController.dispose();
    super.dispose();
  }

  void _showIndicator() {
    _appearanceController
      ..duration = const Duration(milliseconds: 750)
      ..forward();
    _repeatingController.repeat();
  }

  void _hideIndicator() {
    _appearanceController
      ..duration = const Duration(milliseconds: 150)
      ..reverse();
    _repeatingController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _indicatorSpaceAnimation,
      builder: (context, child) {
        return SizedBox(
          height: _indicatorSpaceAnimation.value,
          child: child,
        );
      },
      child: Stack(
        children: [
          _buildAnimatedBubble(
            animation: _smallBubbleAnimation,
            left: 8,
            bottom: 8,
            bubble: _buildCircleBubble(8),
          ),
          _buildAnimatedBubble(
            animation: _mediumBubbleAnimation,
            left: 10,
            bottom: 10,
            bubble: _buildCircleBubble(16),
          ),
          _buildAnimatedBubble(
            animation: _largeBubbleAnimation,
            left: 12,
            bottom: 12,
            bubble: _buildStatusBubble(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBubble({
    required Animation<double> animation,
    required double left,
    required double bottom,
    required Widget bubble,
  }) {
    return Positioned(
      left: left,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.scale(
            scale: animation.value,
            alignment: Alignment.bottomLeft,
            child: child,
          );
        },
        child: bubble,
      ),
    );
  }

  Widget _buildCircleBubble(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.bubbleColor,
      ),
    );
  }

  Widget _buildStatusBubble() {
    return Container(
      width: 85,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        color: widget.bubbleColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFlashingCircle(0),
          _buildFlashingCircle(1),
          _buildFlashingCircle(2),
        ],
      ),
    );
  }

  Widget _buildFlashingCircle(int index) {
    return AnimatedBuilder(
      animation: _repeatingController,
      builder: (context, child) {
        final circleFlashPercent =
            _dotIntervals[index].transform(_repeatingController.value);
        final circleColorPercent = sin(pi * circleFlashPercent);

        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(widget.flashingCircleDarkColor,
                widget.flashingCircleBrightColor, circleColorPercent),
          ),
        );
      },
    );
  }
}

@immutable
class FakeMessage extends StatelessWidget {
  const FakeMessage({
    Key? key,
    required this.isBig,
  }) : super(key: key);

  final bool isBig;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
      height: isBig ? 128.0 : 36.0,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        color: Colors.white,
      ),
    );
  }
}

// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter/src/widgets/framework.dart';
// import 'package:flutter/src/widgets/placeholder.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:mutual/provider/chat_provider.dart';
// import 'package:mutual/provider/graphID_provider.dart';
// import 'package:mutual/screens/feed.dart';
// import 'package:provider/provider.dart';

// List<Widget> chat = [];
// class Chat extends StatefulWidget {
//   @override
//   State<Chat> createState() => _ChatState();
// }

// class _ChatState extends State<Chat> {
//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   _onSearchChanged(String query) {
//     final cp = Provider.of<ChatProvider>(context, listen: false);
//     if (_debounce?.isActive ?? false) {
//       _debounce!.cancel();
//     }
//     _debounce = Timer(const Duration(milliseconds: 300), () {
//       print('object');
//       socket.emit('typing', {'postId': cp.postId, 'firstName': cp.name});

//       // do something with query
//     });
//     socket.emit('stop_typing', {'postId': cp.postId, 'firstName': cp.name});
//   }

//   //const Chat({super.key});
//   Timer? _debounce;
//   bool isTyping = false;
//   @override
//   Widget build(BuildContext context) {
//   final cp = Provider.of<ChatProvider>(context, listen: false);
//     //socket.onevent({'typing': {'postId': cp.postId, 'firstName': cp.name}});
//     socket.on('typing', (data) {
//       setState(() {
//         isTyping = true;
//       });
//       print(data);
//     });
//     socket.on('stop_typing', (data) {
//       setState(() {
//         isTyping = false;
//       });
//       print("stop typing $data");
//     });
//     socket.on('chat', (data) {
//       setState(() {
//         chat.add(
//           ChatCard(text: data, right: false)
//         );
//       });
//     });
//     return SafeArea(
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: Consumer<ChatProvider>(
//           builder: (context, value, child) {
//             return SingleChildScrollView(
//               scrollDirection: Axis.vertical,
//               child: Column(
//                 children: [
//                   Padding(
//                     padding: EdgeInsets.only(
//                         top: MediaQuery.of(context).size.height * 0.04,
//                         bottom: MediaQuery.of(context).size.height * 0.08,
//                         left: MediaQuery.of(context).size.width * 0.095),
//                     child: Row(
//                       children: [
//                         Icon(Icons.arrow_back_ios),
//                         SizedBox(
//                           width: MediaQuery.of(context).size.width * 0.15,
//                         ),
//                         Text("${value.name!}'s Chat ",
//                             style: GoogleFonts.roboto(
//                                 textStyle: TextStyle(
//                               color: Color(0xff4666ED),
//                               fontWeight: FontWeight.w600,
//                               fontSize:
//                                   MediaQuery.of(context).size.height * 0.023,
//                             ))),
//                       ],
//                     ),
//                   ),
//                   FeedCard(
//                     firstName: value.name!,
//                     post: value.post!,
//                     profilePic: value.profilePic!,
//                     profession: value.profession!,
//                     time: value.time!,
//                     postId: value.postId!,
//                     authorGraphId: value.authorGraphId!,
//                   ),
//                   Divider(
//                     height: 10,
//                     thickness: 0.1,
//                     color: Colors.grey,
//                   ),
//                   SizedBox(
//                     height: MediaQuery.of(context).size.height * 0.55,
//                     child: ListView.builder(
//                       //  scrollDirection: Axis.vertical,
//                       physics: NeverScrollableScrollPhysics(),
//                       itemBuilder: (context, index) {
//                         return chat[index];
//                       },
//                       itemCount: chat.length,
//                     ),
//                   ),
//                   Visibility(
//                     visible: isTyping,
//                     maintainSize: true,
//                     maintainState: true,
//                     maintainAnimation: true,
//                     child: SizedBox(
//                       height: 60,
//                       child: TypingIndicator(
//                         showIndicator: isTyping,
//                       ),
//                     ),
//                   ),
//                   Padding(
//                     padding: EdgeInsets.only(
//                         left: MediaQuery.of(context).size.width * 0.06,
//                         bottom: MediaQuery.of(context).size.height * 0.0,
//                         right: MediaQuery.of(context).size.width * 0.06),
//                     child: SizedBox(
//                       height: 55,
//                       child: TextField(
//                         onSubmitted: (value) {
//                           setState(() {
//                             chat.add(ChatCard(
//                               right: true,
//                               text: value,
//                             ));
//                             socket.emit('chat', {
//                               'postId': cp.postId,
//                               'graphId': cp.authorGraphId,
//                               'chat': value
//                             });
//                           });
//                         },
//                         onChanged: _onSearchChanged,
//                         decoration: InputDecoration(
//                           isDense: true,
//                           filled: true,
//                           hintText: " ",
//                           fillColor: const Color(0xffEFEFEF),
//                           enabledBorder: const OutlineInputBorder(
//                               borderRadius:
//                                   BorderRadius.all(Radius.circular(16)),
//                               borderSide: BorderSide(
//                                 color: Colors.white,
//                               )),
//                           border: const OutlineInputBorder(
//                               borderRadius:
//                                   BorderRadius.all(Radius.circular(16)),
//                               borderSide: BorderSide(color: Colors.white)),
//                           disabledBorder: const OutlineInputBorder(
//                               borderRadius:
//                                   BorderRadius.all(Radius.circular(16)),
//                               borderSide: BorderSide(color: Colors.black)),
//                           suffixIcon: Padding(
//                             padding:
//                                 const EdgeInsets.only(right: 23.0, left: 5),
//                             child: Icon(Icons.send,
//                                 size: MediaQuery.of(context).size.height * 0.03,
//                                 color: Colors.blue),
//                           ),
//                           contentPadding: const EdgeInsets.only(
//                               top: 20, bottom: 20, left: 20, right: 0),
//                           // prefixIconConstraints: BoxConstraints(minWidth: 40,maxHeight: 45)
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class ChatCard extends StatelessWidget {
//   // const ChatCard({super.key});
//   String text;
//   bool right;

//   ChatCard({required this.text, required this.right});
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(
//           left: right == true
//               ? MediaQuery.of(context).size.width * 0.0
//               : MediaQuery.of(context).size.width * 0.03,
//           top: MediaQuery.of(context).size.height * 0.02,
//           bottom: MediaQuery.of(context).size.height * 0.0,
//           right: right == true
//               ? MediaQuery.of(context).size.width * 0.03
//               : MediaQuery.of(context).size.width * 0),
//       child: Row(
//         mainAxisAlignment:
//             right == true ? MainAxisAlignment.end : MainAxisAlignment.start,
//         children: [
//           Visibility(
//             visible: !right,
//             child: Padding(
//               padding: EdgeInsets.only(right: 6),
//               child: CircleAvatar(
//                 backgroundColor: Colors.grey,
//                 backgroundImage: NetworkImage(profilePic ?? ""),
//               ),
//             ),
//           ),
//           Container(
//             decoration: BoxDecoration(
//                 gradient: right == true
//                     ? const LinearGradient(
//                         colors: [Color(0xff3795F1), Color(0xff3E6CE9)])
//                     : const LinearGradient(
//                         colors: [Color(0xffEFEFEF), Color(0xffEFEFEF)]),
//                 borderRadius: BorderRadius.all(Radius.circular(81))),
//             child: Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Text(text,
//                   style: GoogleFonts.roboto(
//                       textStyle: TextStyle(
//                     color: right == true ? Colors.white : Colors.black,
//                     fontWeight: FontWeight.w600,
//                     fontSize: MediaQuery.of(context).size.height * 0.018,
//                   ))),
//             ),
//           ),
//           Visibility(
//             visible: right,
//             child: Padding(
//               padding: EdgeInsets.only(left: 6),
//               child: CircleAvatar(
//                 backgroundColor: Colors.grey,
//                 backgroundImage: NetworkImage(profilePic ?? ""),
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

// class FeedCard extends StatelessWidget {
//   String firstName;
//   String profilePic;
//   String post;
//   String profession;
//   String? mutual;
//   String time;
//   int? cursor;
//   int authorGraphId;
//   String postId;
//   FeedCard(
//       {required this.firstName,
//       required this.post,
//       required this.profilePic,
//       required this.profession,
//       required this.time,
//       required this.authorGraphId,
//       required this.postId,
//       this.cursor,
//       this.mutual});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ChatProvider>(
//       builder: (context, value, child) {
//         final cp = Provider.of<ChatProvider>(context, listen: false);
//         return InkWell(
//           onTap: () {
//             // cp.setData(
//             //     nameData: firstName,
//             //     postData: post,
//             //     postIDData: postId,
//             //     professionData: profession,
//             //     timeData: time,
//             //     socketData: socket,
//             //     graphData: authorGraphId,
//             //     profileData: profilePic);
//             // Navigator.pushNamed(context, '/chat');
//           },
//           child: Padding(
//             padding: EdgeInsets.only(
//                 top: MediaQuery.of(context).size.height * 0.0,
//                 left: MediaQuery.of(context).size.width * 0.04,
//                 right: MediaQuery.of(context).size.width * 0.04),
//             child: Container(
//               color: Colors.white,
//               width: MediaQuery.of(context).size.width,
//               child: Padding(
//                 padding: EdgeInsets.only(
//                     top: MediaQuery.of(context).size.height * 0.004,
//                     left: MediaQuery.of(context).size.width * 0.02),
//                 child: Column(
//                   children: [
//                     mutual == null || mutual == ""
//                         ? Container(
//                             height: 0,
//                             width: 0,
//                           )
//                         : Padding(
//                             padding: EdgeInsets.only(
//                                 top:
//                                     MediaQuery.of(context).size.height * 0.0024,
//                                 left: MediaQuery.of(context).size.width * 0.14),
//                             child: Row(
//                               children: [
//                                 CircleAvatar(
//                                   backgroundColor: Colors.black,
//                                   radius: 7,
//                                   child: CircleAvatar(
//                                     radius: 6,
//                                     backgroundColor: Colors.white,
//                                     child: Text(
//                                       'm',
//                                       textAlign: TextAlign.center,
//                                       style: GoogleFonts.roboto(
//                                           textStyle: TextStyle(
//                                         color: Colors.black,
//                                         fontWeight: FontWeight.w700,
//                                         fontSize:
//                                             MediaQuery.of(context).size.height *
//                                                 0.009,
//                                       )),
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(
//                                   width: 4,
//                                 ),
//                                 Text("$mutual Mutual",
//                                     style: GoogleFonts.roboto(
//                                         textStyle: TextStyle(
//                                       color: Colors.black,
//                                       fontWeight: FontWeight.w700,
//                                       fontSize:
//                                           MediaQuery.of(context).size.height *
//                                               0.012,
//                                     )))
//                               ],
//                             ),
//                           ),
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       // mainAxisAlignment: MainAxisAlignment.start,
//                       children: [
//                         Consumer<GraphID>(
//                           builder: (context, value, child) {
//                             final gp =
//                                 Provider.of<GraphID>(context, listen: false);
//                             return Padding(
//                               padding: EdgeInsets.only(
//                                 top: MediaQuery.of(context).size.height * 0.00,
//                               ),
//                               child: InkWell(
//                                 onTap: () {
//                                   Navigator.pushNamed(context, '/seeProfile',
//                                       arguments: {'graphID': authorGraphId});
//                                   gp.setGID(authorGraphId);
//                                 },
//                                 child: CircleAvatar(
//                                   backgroundImage: NetworkImage(
//                                     profilePic,
//                                   ),
//                                   radius: 28,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                         Padding(
//                           padding: EdgeInsets.only(
//                               top: MediaQuery.of(context).size.height * 0.0,
//                               bottom: MediaQuery.of(context).size.height * 0.02,
//                               left: MediaQuery.of(context).size.width * 0.035),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             children: [
//                               Container(
//                                 width: MediaQuery.of(context).size.width * 0.68,
//                                 child: Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(
//                                       firstName,
//                                       style: GoogleFonts.roboto(
//                                         textStyle: TextStyle(
//                                             color: Color(0xff4666ED),
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: MediaQuery.of(context)
//                                                     .size
//                                                     .height *
//                                                 0.017),
//                                       ),
//                                     ),
//                                     Padding(
//                                       padding: EdgeInsets.only(
//                                           top: MediaQuery.of(context)
//                                                   .size
//                                                   .height *
//                                               0.0),
//                                       child: Text(
//                                         time,
//                                         style: GoogleFonts.roboto(
//                                           textStyle: TextStyle(
//                                               fontWeight: FontWeight.w600,
//                                               color: Color(0xff567AF3),
//                                               // fontWeight: FontWeight.bold,
//                                               fontSize: MediaQuery.of(context)
//                                                       .size
//                                                       .height *
//                                                   0.014),
//                                         ),
//                                       ),
//                                     )
//                                   ],
//                                 ),
//                               ),
//                               Text(
//                                 profession,
//                                 style: GoogleFonts.roboto(
//                                   textStyle: TextStyle(
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.black,
//                                       fontSize:
//                                           MediaQuery.of(context).size.height *
//                                               0.012),
//                                 ),
//                               ),
//                               SizedBox(
//                                 height: 5,
//                               ),
//                               Container(
//                                 width: MediaQuery.of(context).size.width * 0.63,
//                                 child: Text(
//                                   post,
//                                   maxLines: 3,
//                                   overflow: TextOverflow.ellipsis,
//                                   textAlign: TextAlign.start,
//                                   softWrap: true,
//                                   style: GoogleFonts.roboto(
//                                     textStyle: TextStyle(
//                                         color: Colors.black,
//                                         fontWeight: FontWeight.w400,
//                                         fontSize:
//                                             MediaQuery.of(context).size.height *
//                                                 0.016),
//                                   ),
//                                 ),
//                               )
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class TypingIndicator extends StatefulWidget {
//   const TypingIndicator({
//     Key? key,
//     this.showIndicator = false,
//     this.bubbleColor = const Color(0xffEFEFEF),
//     this.flashingCircleDarkColor = const Color(0xFF333333),
//     this.flashingCircleBrightColor = const Color(0xFFaec1dd),
//   }) : super(key: key);

//   final bool showIndicator;
//   final Color bubbleColor;
//   final Color flashingCircleDarkColor;
//   final Color flashingCircleBrightColor;

//   @override
//   _TypingIndicatorState createState() => _TypingIndicatorState();
// }

// class _TypingIndicatorState extends State<TypingIndicator>
//     with TickerProviderStateMixin {
//   late AnimationController _appearanceController;

//   late Animation<double> _indicatorSpaceAnimation;

//   late Animation<double> _smallBubbleAnimation;
//   late Animation<double> _mediumBubbleAnimation;
//   late Animation<double> _largeBubbleAnimation;

//   late AnimationController _repeatingController;
//   final List<Interval> _dotIntervals = const [
//     Interval(0.25, 0.8),
//     Interval(0.35, 0.9),
//     Interval(0.45, 1.0),
//   ];

//   @override
//   void initState() {
//     super.initState();

//     _appearanceController = AnimationController(
//       vsync: this,
//     )..addListener(() {
//         setState(() {});
//       });

//     _indicatorSpaceAnimation = CurvedAnimation(
//       parent: _appearanceController,
//       curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
//       reverseCurve: const Interval(0.0, 1.0, curve: Curves.easeOut),
//     ).drive(Tween<double>(
//       begin: 0.0,
//       end: 60.0,
//     ));

//     _smallBubbleAnimation = CurvedAnimation(
//       parent: _appearanceController,
//       curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
//       reverseCurve: const Interval(0.0, 0.3, curve: Curves.easeOut),
//     );
//     _mediumBubbleAnimation = CurvedAnimation(
//       parent: _appearanceController,
//       curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
//       reverseCurve: const Interval(0.2, 0.6, curve: Curves.easeOut),
//     );
//     _largeBubbleAnimation = CurvedAnimation(
//       parent: _appearanceController,
//       curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
//       reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeOut),
//     );

//     _repeatingController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     );

//     if (widget.showIndicator) {
//       _showIndicator();
//     }
//   }

//   @override
//   void didUpdateWidget(TypingIndicator oldWidget) {
//     super.didUpdateWidget(oldWidget);

//     if (widget.showIndicator != oldWidget.showIndicator) {
//       if (widget.showIndicator) {
//         _showIndicator();
//       } else {
//         _hideIndicator();
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _appearanceController.dispose();
//     _repeatingController.dispose();
//     super.dispose();
//   }

//   void _showIndicator() {
//     _appearanceController
//       ..duration = const Duration(milliseconds: 750)
//       ..forward();
//     _repeatingController.repeat();
//   }

//   void _hideIndicator() {
//     _appearanceController
//       ..duration = const Duration(milliseconds: 150)
//       ..reverse();
//     _repeatingController.stop();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _indicatorSpaceAnimation,
//       builder: (context, child) {
//         return SizedBox(
//           height: _indicatorSpaceAnimation.value,
//           child: child,
//         );
//       },
//       child: Stack(
//         children: [
//           _buildAnimatedBubble(
//             animation: _smallBubbleAnimation,
//             left: 8,
//             bottom: 8,
//             bubble: _buildCircleBubble(8),
//           ),
//           _buildAnimatedBubble(
//             animation: _mediumBubbleAnimation,
//             left: 10,
//             bottom: 10,
//             bubble: _buildCircleBubble(16),
//           ),
//           _buildAnimatedBubble(
//             animation: _largeBubbleAnimation,
//             left: 12,
//             bottom: 12,
//             bubble: _buildStatusBubble(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAnimatedBubble({
//     required Animation<double> animation,
//     required double left,
//     required double bottom,
//     required Widget bubble,
//   }) {
//     return Positioned(
//       left: left,
//       bottom: bottom,
//       child: AnimatedBuilder(
//         animation: animation,
//         builder: (context, child) {
//           return Transform.scale(
//             scale: animation.value,
//             alignment: Alignment.bottomLeft,
//             child: child,
//           );
//         },
//         child: bubble,
//       ),
//     );
//   }

//   Widget _buildCircleBubble(double size) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: widget.bubbleColor,
//       ),
//     );
//   }

//   Widget _buildStatusBubble() {
//     return Container(
//       width: 85,
//       height: 44,
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(27),
//         color: widget.bubbleColor,
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           _buildFlashingCircle(0),
//           _buildFlashingCircle(1),
//           _buildFlashingCircle(2),
//         ],
//       ),
//     );
//   }

//   Widget _buildFlashingCircle(int index) {
//     return AnimatedBuilder(
//       animation: _repeatingController,
//       builder: (context, child) {
//         final circleFlashPercent =
//             _dotIntervals[index].transform(_repeatingController.value);
//         final circleColorPercent = sin(pi * circleFlashPercent);

//         return Container(
//           width: 12,
//           height: 12,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Color.lerp(widget.flashingCircleDarkColor,
//                 widget.flashingCircleBrightColor, circleColorPercent),
//           ),
//         );
//       },
//     );
//   }
// }

// @immutable
// class FakeMessage extends StatelessWidget {
//   const FakeMessage({
//     Key? key,
//     required this.isBig,
//   }) : super(key: key);

//   final bool isBig;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
//       height: isBig ? 128.0 : 36.0,
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.all(Radius.circular(8.0)),
//         color: Colors.white,
//       ),
//     );
//   }
// }


// SliverAppBar(
//                         stretch: true,
//                         backgroundColor: Colors.white,
//                         pinned: true,
//                         elevation: 10,
//                         title: Column(
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Consumer(
//                                   builder: (context, value, child) {
//                                     final gp = Provider.of<GraphID>(context,
//                                         listen: false);
//                                     return InkWell(
//                                       onTap: () {
//                                         gp.setGID(graphId);
//                                         Navigator.pushNamed(
//                                             context, '/seeProfile');
//                                       },
//                                       child: CircleAvatar(
//                                         backgroundColor: Colors.grey,
//                                         backgroundImage:
//                                             NetworkImage(cp.profilePic!),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                                 SizedBox(
//                                   width: 10,
//                                 ),
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(cp.name!,
//                                         style: TextStyle(color: Colors.black)),
//                                     Visibility(
//                                       visible: isOnline,
//                                       child: Text(
//                                           isTyping == false
//                                               ? "Online"
//                                               : "typing...",
//                                           style: GoogleFonts.roboto(
//                                               textStyle: TextStyle(
//                                             color: Colors.grey,
//                                             fontWeight: FontWeight.w600,
//                                             fontSize: MediaQuery.of(context)
//                                                     .size
//                                                     .height *
//                                                 0.013,
//                                           ))),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                             // Padding(
//                             //   padding: const EdgeInsets.only(left: 50),
//                             //   child:
//                             // )
//                           ],
//                         ),
//                         leading: InkWell(
//                           onTap: () {
//                             Navigator.pop(context);
//                           },
//                           child: Icon(
//                             Icons.arrow_back,
//                             color: Colors.black,
//                           ),
//                         ),
//                         //expandedHeight: 150,
//                         expandedHeight: FeedCard3(
//                                         firstName: cp.name ?? "",
//                                         post: cp.post ?? "",
//                                         profilePic: cp.profilePic ?? "",
//                                         profession: cp.profession ?? "",
//                                         time: cp.time ?? "",
//                                         authorGraphId: cp.authorGraphId ?? 2,
//                                         postId: cp.postId ?? "")
//                                     .post
//                                     .length >=
//                                 160
//                             ? FeedCard3(
//                                         firstName: cp.name ?? "",
//                                         post: cp.post ?? "",
//                                         profilePic: cp.profilePic ?? "",
//                                         profession: cp.profession ?? "",
//                                         time: cp.time ?? "",
//                                         authorGraphId: cp.authorGraphId ?? 2,
//                                         postId: cp.postId ?? "")
//                                     .post
//                                     .length *
//                                 0.8
//                             : FeedCard3(
//                                             firstName: cp.name ?? "",
//                                             post: cp.post ?? "",
//                                             profilePic: cp.profilePic ?? "",
//                                             profession: cp.profession ?? "",
//                                             time: cp.time ?? "",
//                                             authorGraphId:
//                                                 cp.authorGraphId ?? 2,
//                                             postId: cp.postId ?? "")
//                                         .post
//                                         .length <=
//                                     130
//                                 ? 130
//                                 : FeedCard3(
//                                             firstName: cp.name ?? "",
//                                             post: cp.post ?? "",
//                                             profilePic: cp.profilePic ?? "",
//                                             profession: cp.profession ?? "",
//                                             time: cp.time ?? "",
//                                             authorGraphId:
//                                                 cp.authorGraphId ?? 2,
//                                             postId: cp.postId ?? "")
//                                         .post
//                                         .length *
//                                     4,
//                         floating: true,
//                         flexibleSpace: Padding(
//                           padding: const EdgeInsets.only(top: kToolbarHeight),
//                           child: Padding(
//                             padding: const EdgeInsets.all(0.0),
//                             child: FlexibleSpaceBar(
//                               background: cp.authorGraphId != graphId
//                                   ? FeedCard3(
//                                       firstName: cp.name ?? "",
//                                       post: cp.post ?? "",
//                                       profilePic: cp.profilePic ?? "",
//                                       profession: cp.profession ?? "",
//                                       time: cp.time ?? "",
//                                       authorGraphId: cp.authorGraphId ?? 2,
//                                       postId: cp.postId ?? "")
//                                   : SizedBox(
//                                       height: 0,
//                                     ),
//                             ),
//                           ),
//                         ),
//                         scrolledUnderElevation: 2,
//                       ),