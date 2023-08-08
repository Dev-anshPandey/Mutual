// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:moment_dart/moment_dart.dart';
// import 'package:mutual/screens/chat.dart';
// import 'package:mutual/screens/dio.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../provider/chat_response_provider.dart';
// import 'feed.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:shared_preferences/shared_preferences.dart';
// DioClient d = DioClient();
// List<ChatCard> chat = [];
// ScrollController _scrollController = new ScrollController();
// String name = "";
// String profilePic = "";
// String profession = "";
// String? search = "";
// String? postId = "";
// int graphId = 0;
// String currentText = tec.text;
// List<Widget> postChat = [];
// late IO.Socket socket;

// class ChatResponse extends StatefulWidget {
//   const ChatResponse({super.key});

//   @override
//   State<ChatResponse> createState() => _ChatResponseState();
// }

// class _ChatResponseState extends State<ChatResponse> {
//   Future<String> getAccessTokens() async {
//     SharedPreferences pref = await SharedPreferences.getInstance();
//     return await pref.getString("accessToken").toString();
//   }

//   Future apigetUser() async {
//     var request = await d.dio.get('http://3.110.164.26/v1/api/user/details');
//     print('firstaName issss');
//     print(request.data['data']['firstName']);
//     if (request.statusCode == 200) {
//       setState(() {
//         name = request.data['data']['firstName'];
//         profilePic = request.data['data']['profilePic'];
//         profession = request.data['data']['profession'];
//         graphId = request.data['data']['graphId'];
//       });
//     } else {
//       print(request.statusMessage);
//     }
//   }
//    initSocket() async {
//     print(await getAccessTokens());

//     socket = IO.io('ws://3.110.164.26/', <String, dynamic>{
//       'transports': ['websocket'],
//       'autoConnect': false,
//       'query': {'accessToken': await getAccessTokens()}
//     });
//     socket.connect();
//     socket.onConnect((_) {
//       print('Connection established');
//     });
//     socket.onDisconnect((_) => print('Connection Disconnection'));
//     socket.onConnectError((err) => print(err));
//     socket.onError((err) => print(err));
//   }


//   @override
//   void dispose() {
//     _debounce?.cancel();
//     // TODO: implement dispose
//     super.dispose();
//   }

//   @override
//   void initState() {
//    initSocket();
//     apigetUser();
//     count = 0;
    
//     // TODO: implement initState
//     super.initState();
//   }

//   Timer? _debounce;
//   int count = 0;
//   bool isTyping = false;

//   @override
//   Widget build(BuildContext context) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//             _scrollController.position.maxScrollExtent + 200,
//             duration: const Duration(milliseconds: 500),
//             curve: Curves.linear);
//       }
//     });
//     final cp = Provider.of<ChatRProvider>(context, listen: false);
//     _onSearchChanged(String query) {
//       final cp = Provider.of<ChatRProvider>(context, listen: false);
//       if (_debounce?.isActive ?? false) {
//         _debounce!.cancel();
//       }
//       _debounce = Timer(const Duration(milliseconds: 300), () {
//         print('object');
//         socket.emit('stop_typing', {'chatId': cp.chatID, 'firstName': cp.name});

//         // do something with query
//       });
//       socket.emit('typing', {'chatId': cp.chatID, 'firstName': cp.name});
//     }

//     void submit() {
//       setState(() {
//         print(Moment.now());
//         chat.add(ChatCard(
//           text: tec.text,
//           chatId: cp.chatID!,
//           profession: profession,
//           time: DateFormat("HH:mm a").format(DateTime.now()).toString(),
//           right: true,
//           name: name,
//           postId2: cp.postId!,
//           profilePic: profilePic,
//           mutual: "",
//         ));
//       });
//       count--;
//       print(cp.mutuals);
//       print("name is $name");
//       print(cp.chatID);
//       socket.emit('chat', {
//         'firstName': name,
//         'profilePic': profilePic,
//         'postId': cp.postId,
//         'graphId': graphId,
//         'message': tec.text,
//         'profession': cp.profession,
//         'mutual': cp.mutuals,
//         'chatId': cp.chatID,
//         'cursorId': DateTime.now().millisecondsSinceEpoch
//         // 'createdAt':Moment.now()
//       });
//       tec.clear();
//     }

//     socket.on('typing', (data) {
//       if (this.mounted) {
//         if (data['postId'] == cp.postId) {
//           setState(() {
//             isTyping = true;
//           });
//         }
//       }
//       print(data);
//     });
//     socket.on('stop_typing', (data) {
//       if (this.mounted) {
//         if (data['postId'] == cp.postId) {
//           setState(() {
//             isTyping = false;
//           });
//         }
//       }
//       print("stop typing $data");
//     });

//     socket.on('chat', (data) {
//     //if (this.mounted) {
//         // setState(() {
//           print("data is ");
//           print("is it exectiuing");
//           print(data);
//           print(cp.postId);
//           String time = Moment.parse(DateTime.parse((data['createdAt']))
//                   .add(Duration(hours: 5, minutes: 30))
//                   .toString())
//               .toString();
//           print("time is ${data['createdAt']}");
//           chat.add(ChatCard(
//             profession: data['profession'] ?? "",
//             postId2: data['postId'],
//             text: data['message'],
//             right: false,
//             chatId: data['chatId'],
//             time: time,
//             name: data['firstName'],
//             profilePic: data['profilePic'],
//             mutual: data['mutual'] ?? "",
//           ));
//           print('donee');
//         // });
//     //  }
//     });
//     postChat.clear();
//     postChat.add(ChatCard(
//         text: cp.post ?? "",
//         profession: profession,
//         time: cp.time ?? "",
//         right: false,
//         chatId: cp.chatID!,
//         profilePic: cp.profilePic ?? "",
//         postId2: cp.postId!,
//         mutual: cp.mutuals ?? "",
//         name: cp.name ?? ""));
//     for (ChatCard element in chat) {
//       if (cp.postId == element.postId2) postChat.add(element);
//     }

//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//           backgroundColor: Colors.white,
//           elevation: 0.5,
//           leading: InkWell(
//               onTap: () => Navigator.pop(context),
//               child: Padding(
//                 padding: EdgeInsets.only(
//                   left: MediaQuery.of(context).size.width * 0.08,
//                 ),
//                 child: Icon(
//                   Icons.arrow_back,
//                   color: Colors.black,
//                 ),
//               )),
//           title: Center(
//             child: Consumer<ChatRProvider>(
//               builder: (context, value, child) {
//                 return Text("${value.name}'s Chat ",
//                     style: GoogleFonts.roboto(
//                         textStyle: TextStyle(
//                       color: Colors.black,
//                       fontWeight: FontWeight.w600,
//                       fontSize: MediaQuery.of(context).size.height * 0.023,
//                     )));
//               },
//             ),
//           )),
//       bottomNavigationBar: Material(
//         elevation: 20,
//         child: Padding(
//           padding: EdgeInsets.only(
//               left: MediaQuery.of(context).size.width * 0.0,
//               bottom: MediaQuery.of(context).viewInsets.bottom + 10,
//               right: MediaQuery.of(context).size.width * 0.0),
//           child: ConstrainedBox(
//             constraints: BoxConstraints(
//               minWidth: MediaQuery.of(context).size.width,
//               maxWidth: MediaQuery.of(context).size.width,
//               minHeight: 30.0,
//               maxHeight: 60.0,
//             ),
//             child: Scrollbar(
//               child: TextField(
//                 onChanged: _onSearchChanged,
//                 controller: tec,
//                 maxLines: 30,
//                 keyboardType: TextInputType.multiline,
//                 scrollPadding: EdgeInsets.only(
//                     bottom: MediaQuery.of(context).viewInsets.bottom),
//                 // onSubmitted: (value) {
//                 //   //submit();
//                 //   // setState(() {
//                 //   //   currentText = "";
//                 //   // });
//                 // },
//                 decoration: InputDecoration(
//                   isDense: true,
//                   filled: true,
//                   hintText: "Type here... ",

//                   fillColor: Colors.white,
//                   enabledBorder: const OutlineInputBorder(
//                       borderRadius: BorderRadius.all(Radius.circular(8)),
//                       borderSide: BorderSide(
//                         color: Colors.white,
//                       )),
//                   border: const OutlineInputBorder(
//                       borderRadius: BorderRadius.all(Radius.circular(8)),
//                       borderSide: BorderSide(color: Colors.white)),
//                   disabledBorder: const OutlineInputBorder(
//                       borderRadius: BorderRadius.all(Radius.circular(8)),
//                       borderSide: BorderSide(color: Colors.black)),
//                   prefixIcon: Padding(
//                     padding: const EdgeInsets.only(
//                         right: 27.0, left: 23, top: 7, bottom: 7),
//                     child: Container(
//                       height: 0,
//                       width: 30,
//                       decoration: const BoxDecoration(
//                           gradient: LinearGradient(
//                               colors: [Color(0xff4988EF), Color(0xff476DEE)]),
//                           borderRadius: BorderRadius.all(Radius.circular(8))),
//                       child: const Icon(
//                         Icons.add,
//                         color: Colors.white,
//                         size: 30,
//                       ),
//                     ),
//                   ),
//                   suffixIcon: GestureDetector(
//                     onTap: () {
//                       submit();
//                     },
//                     child: Padding(
//                       padding: const EdgeInsets.only(right: 23.0, left: 5),
//                       child: Icon(Icons.send,
//                           size: MediaQuery.of(context).size.height * 0.033,
//                           color: Color(0xff336FD7)),
//                     ),
//                   ),
//                   contentPadding: const EdgeInsets.only(
//                       top: 25, bottom: 15, left: 35, right: 0),
//                   // prefixIconConstraints: BoxConstraints(minWidth: 40,maxHeight: 45)
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             //height: MediaQuery.of(context).size.height * 0.55,
//             child: ListView.builder(
//               controller: _scrollController,
//               scrollDirection: Axis.vertical,
//               keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
//               // reverse: true,
//               shrinkWrap: true,
//               // physics: NeverScrollableScrollPhysics(),
//               itemBuilder: (context, index) {
//                 return postChat[index];
//               },
//               itemCount: postChat.length,
//             ),
//           ),
//           SizedBox(
//             height: 61,
//             child: Visibility(
//               visible: isTyping,
//               maintainSize: true,
//               maintainState: true,
//               maintainAnimation: true,
//               child: SizedBox(
//                 height: 60,
//                 child: TypingIndicator(
//                   showIndicator: isTyping,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
