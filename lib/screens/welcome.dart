import 'dart:convert';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mutual/screens/dio.dart';
import 'package:mutual/screens/number_verification.dart';
import 'package:shared_preferences/shared_preferences.dart';
//final apiProvider = Provider((ref) => DioInterceptor());
 int state = 0;
class Welcome extends ConsumerStatefulWidget {
  const Welcome({super.key});

  @override
  ConsumerState<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends ConsumerState<Welcome> {
  Future? _future;
  List<Contact> contacts = [];
  List contactNumber = [];
  List contactGID = [];
  List contactInvite = [];
  List group = [];
  List<Widget> displayWidget = [];
  List network = [];
  @override
  Future<String> getAccessTokens() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    print(await pref.getString("accessToken").toString());
    return await pref.getString("accessToken").toString();
  }

  Future<String> getRefreshTokens() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    print(await pref.getString("refreshToken").toString());
    return await pref.getString("refreshToken").toString();
  }

  Future apiContactSync() async {
    contacts = await ContactsService.getContacts();
    DioClient d = DioClient();
    List<ContactClass> tags = [];
    var temp;
    for (int i = 0; i < contacts.length; i++) {
      print(contacts[i].phones?.length);
      print(contacts[i].givenName);
      if (contacts[i].givenName != null && contacts[i].phones?.length != 0) {
        tags.add(ContactClass(contacts[i].givenName.toString(),
            contacts[i].phones![0].value.toString()));
      }

      temp = jsonEncode(tags);
    }
    // print(request.data.toString());
    final response = await d.dio
        .post('http://3.110.164.26/v1/api/user/contacts', data: temp);
    //print(response.data.toString());
    if (response.statusCode == 200) {
      String res = response.data.toString();
      print(response.data['data']['HR']['users'][0]);
      List names = [];
      List profiles = [];
      List division = [];
      response.data['data'].forEach((key, value) {
        division.add(key);
      });
      for (var grp in response.data['data']['groups']) {
        setState(() {
          group.add(Groupcard(count: grp['totalMembers'], name: grp['name']));
        });
      }
      for (int a = 0; a < division.length - 1; a++) {
        for (var b in response.data['data'][division[a]]['users']) {
          setState(() {
            names.add(b['name']);
            profiles.add(b['profilePic']);
          });
        }
        setState(() {
          network.add(NetworkCard(
            name: division[a],
            nameList: names,
            profile: profiles,
            count: response.data['data'][division[a]]['mutualCount'] +
                names.length,
          ));
          displayWidget.add(ListCardU(
            heading: division[a],
            name: names,
            profile: profiles,
            mutual: response.data['data'][division[a]]['mutualCount'],
          ));
          names = [];
          profiles = [];
        });
      }

      for (var sd in response.data['data']['contactList']) {
        setState(() {
          contactNumber.add(sd['phoneNumber']);
          contactGID.add(sd['graphId']);
        });
      }
      for (int i = 0; i < contacts.length; i++) {
        if (contacts[i].givenName != null && contacts[i].phones?.length != 0) {
          print('nvc');
          if (!contactNumber
              .contains(contacts[i].phones![0].value.toString())) {
            setState(() {
              contactInvite.add(contacts[i].givenName);
            });
          }
        }
      }
    } else {
      print(response);
    }
  }

  void fetchContacts() async {
    // apiContactSync(contacts);
  }

  @override
  void initState() {
    //Api();
    _future = apiContactSync();
    fetchContacts();
    // TODO: implement initState
    super.initState();
  }

  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            bottomNavigationBar: Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.025,
                  bottom: MediaQuery.of(context).size.height * 0.025,
                  left: MediaQuery.of(context).size.width * 0.06,
                  right: MediaQuery.of(context).size.width * 0.06),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.06,
                width: MediaQuery.of(context).size.width * 0.85,
                child: Container(
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xff3795F1), Color(0xff3E6CE9)]),
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "NEXT",
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height * 0.019),
                    ),
                  ),
                ),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.04,
                          left: MediaQuery.of(context).size.width * 0.13,
                          right: MediaQuery.of(context).size.width * 0.05),
                      child: RichText(
                        text: TextSpan(
                          text: 'Wow , You have a Powerful ',
                          style: GoogleFonts.roboto(
                              textStyle: TextStyle(
                                  color: Color(0xff373737),
                                  fontWeight: FontWeight.w500,
                                  fontSize: MediaQuery.of(context).size.height *
                                      0.021)),
                          children: <TextSpan>[
                            TextSpan(
                                text: 'Network',
                                style: GoogleFonts.roboto(
                                    textStyle: TextStyle(
                                        color: Color(0xff336FD7),
                                        fontWeight: FontWeight.w600,
                                        fontSize:
                                            MediaQuery.of(context).size.height *
                                                0.021))),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      height: 40,
                      thickness: 0.1,
                      color: Colors.grey,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * 0.05),
                      child: Text(
                        'Recommendation',
                        style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                                color: Color(0xff373737),
                                fontWeight: FontWeight.w500,
                                fontSize: MediaQuery.of(context).size.height *
                                    0.021)),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * 0.05,
                          right: MediaQuery.of(context).size.width * 0.07),
                      child: Divider(
                        height: 30,
                        thickness: 0.1,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.087 *
                          group.length,
                      width: 500,
                      child: ListView.separated(
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.grey.withOpacity(0.6),
                          endIndent: 20,
                          indent: 80,
                        ),
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return group[index];
                        },
                        itemCount: group.length,
                      ),
                    ),
                //     Padding(
                //       padding: EdgeInsets.only(
                //           left: MediaQuery.of(context).size.width * 0.05),
                //       child: Text(
                //         'Your Network + Mutual Connections',
                //         style: GoogleFonts.roboto(
                //             textStyle: TextStyle(
                //                 color: Color(0xff373737),
                //                 fontWeight: FontWeight.w500,
                //                 fontSize: MediaQuery.of(context).size.height *
                //                     0.021)),
                //       ),
                //     ),
                //     Padding(
                //       padding: EdgeInsets.only(
                //           left: MediaQuery.of(context).size.width * 0.05,
                //           right: MediaQuery.of(context).size.width * 0.07),
                //       child: Divider(
                //         height: 30,
                //         thickness: 0.1,
                //         color: Colors.grey,
                //       ),
                //     ),
                //     Container(
                //       constraints: BoxConstraints(
                // minHeight: MediaQuery.of(context).size.height *
                //           0.09 *
                //           network.length,
                // minWidth: double.infinity,
                // maxHeight: MediaQuery.of(context).size.height *
                //           0.34 *
                //           network.length,
                // maxWidth: double.infinity), //BoxConstraints
                //       child: ListView.builder(
                //         shrinkWrap: true,
                //         physics: NeverScrollableScrollPhysics(),
                //         itemBuilder: (context, index) {
                //           return network[index];
                //         },
                //         itemCount: network.length,
                //       ),
                //     ),

                    // SizedBox(
                    //   height: MediaQuery.of(context).size.height *
                    //       0.42 *
                    //       displayWidget.length,
                    //   width: 500,
                    //   child: ListView.builder(
                    //     physics: NeverScrollableScrollPhysics(),
                    //     itemBuilder: (context, index) {
                    //       return displayWidget[index];
                    //     },
                    //     itemCount: displayWidget.length,
                    //   ),
                    // ),
                    // Padding(
                    //   padding: EdgeInsets.only(
                    //       top: MediaQuery.of(context).size.height * 0.0,
                    //       left: MediaQuery.of(context).size.width * 0.09,
                    //       bottom: MediaQuery.of(context).size.height * 0.02),
                    //   child: Text(
                    //     "Invite",
                    //     style: GoogleFonts.roboto(
                    //         textStyle: TextStyle(
                    //             color: Color(0xff3E6CE9),
                    //             fontSize:
                    //                 MediaQuery.of(context).size.height * 0.022,
                    //             fontWeight: FontWeight.bold)),
                    //   ),
                    // ),
                    // ListContact(name: contactInvite),
                    // const SizedBox(
                    //   height: 40,
                    // ),
                  ],
                ),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
                  color: Color(0xff3E6CE9),
                ),
              ),
            ),
          );
        }
        return Container();
      },
    );
  }
}

class Groupcard extends StatelessWidget {
  String count;
  String name;
  Groupcard({required this.count, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: MediaQuery.of(context).size.width * 0.05,
          bottom: MediaQuery.of(context).size.height * 0.008),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: MediaQuery.of(context).size.width * 0.06,
                backgroundColor: Color(0xff336FD7).withOpacity(0.07),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("$count ",
                        style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                          color: Color(0xff336FD7),
                          fontWeight: FontWeight.w600,
                          fontSize: MediaQuery.of(context).size.height * 0.02,
                        ))),
                  ),
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                            color: Colors.black,
                            fontSize: MediaQuery.of(context).size.height * 0.02,
                            fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    "your connection are in this group",
                    style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                      color: Color(0xff336FD7),
                      fontSize: MediaQuery.of(context).size.height * 0.013,
                    )),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
                right: MediaQuery.of(context).size.width * 0.06,
                bottom: MediaQuery.of(context).size.height * 0.0),
            child: Container(
              height: 42,
              width: 76,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xff3795F1), Color(0xff3E6CE9)]),
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: Center(
                child: Text(
                  'JOIN',
                  style: GoogleFonts.roboto(
                      textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.height * 0.02,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NetworkCard extends StatefulWidget {
  String name;
  List nameList;
  List profile;
  int count;
 
  NetworkCard(
      {required this.name,
      required this.nameList,
      required this.profile,
      required this.count});

  @override
  State<NetworkCard> createState() => _NetworkCardState();
}

class _NetworkCardState extends State<NetworkCard> {
  @override
  Widget build(BuildContext context) {
    List<Widget> url = [
      Image.network(widget.profile[0]),
      Image.network(widget.profile[1]),
      Image.network(widget.profile[2]),
      Text('${widget.count.toString()}+',
          style: GoogleFonts.roboto(
              textStyle: TextStyle(
            color: Color(0xff336FD7),
            fontWeight: FontWeight.w600,
            fontSize: MediaQuery.of(context).size.height * 0.02,
          ))),
    ];
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width * 0.07),
                child: Text(widget.name,
                    style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: MediaQuery.of(context).size.height * 0.019,
                    ))),
              ),
              Row(
                children: [
                  for (int i = 0; i < url.length; i++)
                      state==0?Align(
                        widthFactor: 0.8,
                        child: CircleAvatar(
                          radius: MediaQuery.of(context).size.width * 0.055,
                          backgroundColor: Color(0xff336FD7).withOpacity(0.07),
                          child: url[i],
                        ),
                      ):Container(height: 0,width: 0,),
                  state == 0
                      ? InkWell(
                          onTap: () {
                            setState(() {
                              state = 1;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.06,
                                right:
                                    MediaQuery.of(context).size.width * 0.04),
                            child: CircleAvatar(
                              backgroundColor: Color(0xff336FD7),
                              radius: MediaQuery.of(context).size.width * 0.026,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius:
                                    MediaQuery.of(context).size.width * 0.022,
                                child: Center(
                                  child: Icon(
                                    Icons.keyboard_arrow_down_sharp,
                                    size: 18,
                                    weight: 20,
                                    color: Color(0xff336FD7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : InkWell(
                          onTap: () {
                            setState(() {
                              state = 0;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.06,
                                right:
                                    MediaQuery.of(context).size.width * 0.04),
                            child: CircleAvatar(
                              backgroundColor: Color(0xff336FD7),
                              radius: MediaQuery.of(context).size.width * 0.026,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius:
                                    MediaQuery.of(context).size.width * 0.022,
                                child: Center(
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    weight: 20,
                                    color: Color(0xff336FD7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                ],
              )
            ],
          ),
         if(state==1) ListCardU(
              name: widget.nameList,
              profile: widget.profile,
              mutual: widget.count,
              heading: "")
        ],
      ),
    );
  }
}

class ListCardU extends StatelessWidget {
  String heading;
  List name;
  List profile;
  int mutual;
  ListCardU(
      {required this.name,
      required this.profile,
      required this.mutual,
      required this.heading});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.23,
                width: MediaQuery.of(context).size.width,
                child: ListView.separated(
                    physics: NeverScrollableScrollPhysics(),
                    separatorBuilder: (context, index) => Divider(
                          color: Colors.grey.withOpacity(0.5),
                          endIndent: 40,
                          indent: 60,
                        ),
                    itemCount: profile.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.01,
                            left: MediaQuery.of(context).size.width * 0.01),
                        child: Row(
                          children: [
                            Image.network(
                              profile[index].toString(),
                              height:
                                  MediaQuery.of(context).size.height * 0.055,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              name[index],
                              style: GoogleFonts.roboto(
                                  textStyle:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      );
                    }),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
              left: 40.0,
              right: 40,
              bottom: MediaQuery.of(context).size.height * 0.025),
          child: Divider(
            height: 10,
            color: Colors.black,
            thickness: 0.4,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
              right: MediaQuery.of(context).size.width * 0.28,
              bottom: MediaQuery.of(context).size.height * 0.02),
          child: Text(
            "+$mutual Mutual Entrepreneur",
            style: GoogleFonts.roboto(
                textStyle: TextStyle(color: Color(0xff3E6CE9))),
          ),
        )
      ],
    );
  }
}

class ListContact extends StatelessWidget {
  List name;
  ListContact({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.04),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            width: MediaQuery.of(context).size.width,
            child: ListView.separated(
                separatorBuilder: (context, index) => const Divider(
                      color: Colors.black,
                      endIndent: 20,
                      indent: 33,
                    ),
                itemCount: name.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.007,
                        left: MediaQuery.of(context).size.width * 0.07,
                        right: MediaQuery.of(context).size.width * 0.07),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_circle_outlined,
                              color: Colors.grey,
                              size: MediaQuery.of(context).size.height * 0.055,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              name[index],
                              style: GoogleFonts.roboto(
                                  textStyle:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        Text(
                          "Invite",
                          style: GoogleFonts.roboto(
                              textStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  color: Color(0xff3E6CE9))),
                        ),
                      ],
                    ),
                  );
                }),
          ),
        ),
      ],
    );
  }
}
