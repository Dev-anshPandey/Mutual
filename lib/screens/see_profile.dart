import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mutual/provider/graphID_provider.dart';
import 'package:mutual/screens/chat.dart';
import 'package:mutual/interceptor/dio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/ip_address.dart';

String _dropDownValue = " ";
String? imageGlobal;
String profileUrl = "";
String name = "";
String profession = "";
String profilePic = "";
DioClient d = DioClient();
int? garphID;
int count = 0;
String mutual = "";
String myName = "";
String myProfilePic = "";
String myProfession = "";
int myGraphId = 0;

class SeeProfile extends StatefulWidget {
  const SeeProfile({super.key});

  @override
  State<SeeProfile> createState() => _SeeProfileState();
}

class _SeeProfileState extends State<SeeProfile> {
  File? image;
  Future apigetUser() async {
    // final arguments = (ModalRoute.of(context)?.settings.arguments ??
    //     <String, dynamic>{}) as Map;
    final fp = Provider.of<GraphID>(context, listen: false);

    garphID = fp.graphID;
    print('object $garphID');

    var request = await d.dio
        .get('http://${IP.ipAddress}/v1/api/user/details?graphId=$garphID');
    print('firstaName issss $garphID');
    print(request.data['data']['firstName']);
    if (request.statusCode == 200) {
      setState(() {
        name = request.data['data']['firstName'];
        profileUrl = request.data['data']['profilePic'];
        profession = request.data['data']['profession'];
        try {
          mutual = request.data['data']['mutuals'][0]['firstName'];
        } catch (e) {
          print(e);
        }
      });
    } else {
      print(request.statusMessage);
    }
  }

  Future apiMyDetail() async {
    var request = await d.dio.get('http://${IP.ipAddress}/v1/api/user/details');

    if (request.statusCode == 200) {
      setState(() {
        myName = request.data['data']['firstName'];
        myProfilePic = request.data['data']['profilePic'];
        myProfession = request.data['data']['profession'];
        myGraphId = request.data['data']['graphId'];
      });
    } else {
      print(request.statusMessage);
    }
  }

  Future apiblockUser() async {
    // final arguments = (ModalRoute.of(context)?.settings.arguments ??
    //     <String, dynamic>{}) as Map;
    final fp = Provider.of<GraphID>(context, listen: false);

    garphID = fp.graphID;

    var data = jsonEncode({"graphId": garphID});
    var response = await d.dio
        .post('http://${IP.ipAddress}/v1/api/user/block/user', data: data);
    if (response.statusCode == 200) {
    } else {
      print(response.statusMessage);
    }
  }

  Future PickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final imageTemp = File(image.path);
      setState(() {
        this.image = imageTemp;
        imageGlobal = image.path;
      });
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
    apiCallUploadImage();
  }

  Future apiCallUploadImage() async {
    print('for image');

    //print(mime(imageGlobal));
    // String? mimeType = mime(imageGlobal);
    // String mimee = mimeType!.split('/')[0];
    // String type = mimeType.split('/')[1];

    FormData formData = await FormData.fromMap({
      'image': await MultipartFile.fromFile(imageGlobal!),
      'path': imageGlobal
    });
    // formData.files.add(MapEntry(imageGlobal!,
    //     MultipartFile.fromFileSync(imageGlobal!, filename: 'image')));
    print(formData.fields);
    SharedPreferences pref = await SharedPreferences.getInstance();
    var option = Options(headers: {
      'accessToken': pref.getString('accessToken'),
      'contentType': 'multipart/form-data'
    });
    try {
      var response = await d.dio.post(
        'http://${IP.ipAddress}/v1/api/user/image/upload',
        data: formData,
        options: option,
      );
      print(response);

      //Map mapResponse = jsonDecode(res);
      if (response.statusCode == 200) {
        String res = await response.data.toString();
        setState(() {
          print(response.data['data']['profilePic']);
          profileUrl = response.data['data']['profilePic'];
        });
        print(await res);
      } else {
        print(response.statusCode);
      }
    } on DioError catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    apigetUser();
    apiMyDetail();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('rebuild');
    print(profileUrl);
    final fp = Provider.of<GraphID>(context, listen: false);
    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.white,
          body: Consumer<GraphID>(
            builder: (context, value, child) {
              final fp = Provider.of<GraphID>(context, listen: false);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.02,
                            left: MediaQuery.of(context).size.width * 0.04),
                        child: InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.arrow_back_ios)),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.02,
                            left: MediaQuery.of(context).size.width * 0.24),
                        child: Text(
                          "Contact Info",
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize:
                                    MediaQuery.of(context).size.height * 0.022),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.02,
                            left: MediaQuery.of(context).size.width * 0.21),
                        child: PopupMenuButton<int>(
                          itemBuilder: (context) => [
                            if (fp.graphID != myGraphId)
                              const PopupMenuItem(
                                height: 30,
                                value: 1,
                                child: Text("Block User"),
                              ),
                            if (fp.graphID != myGraphId)
                              const PopupMenuItem(
                                height: 30,
                                value: 2,
                                child: Text("Direct Message"),
                              ),
                            PopupMenuItem(
                              height: 30,
                              onTap: () {
                                Navigator.pushNamed(context, '/setting');
                              },
                              value: 3,
                              child: InkWell(
                                  onTap: () {
                                    Future.delayed(
                                        Duration.zero,
                                        () => Navigator.pushNamed(
                                            context, '/setting'));
                                  },
                                  child: Text("Setting")),
                            ),
                            // PopupMenuItem 2
                          ],
                          //offset: Offset(0, 100),
                          color: Colors.white,
                          elevation: 2,
                          onSelected: (value) {
                            if (value == 1) {
                              // _showDialog(context);
                              // if value 2 show dialog
                            }
                          },
                          child: Container(
                            height: 36,
                            width: 48,
                            alignment: Alignment.centerRight,
                            child: const Icon(
                              Icons.more_vert,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.08,
                        left: MediaQuery.of(context).size.width * 0.0),
                    child: Stack(children: [
                      profileUrl == ""
                          ? CircleAvatar(
                              radius:
                                  MediaQuery.of(context).size.height * 0.1008,
                              backgroundColor: Colors.black,
                              child: CircleAvatar(
                                radius:
                                    MediaQuery.of(context).size.height * 0.1,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.account_circle_outlined,
                                  size:
                                      MediaQuery.of(context).size.height * 0.08,
                                  color: Color(0xff3E6CE9).withOpacity(0.5),
                                ),
                              ),
                            )
                          : CircleAvatar(
                              radius: MediaQuery.of(context).size.height * 0.1,
                              backgroundImage: NetworkImage(profileUrl)),
                    ]),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.01,
                        left: MediaQuery.of(context).size.width * 0.0),
                    child: Text(
                      name,
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                            color: Color(0xff4666ED),
                            fontWeight: FontWeight.w700,
                            fontSize:
                                MediaQuery.of(context).size.height * 0.022),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.0,
                        left: MediaQuery.of(context).size.width * 0.0),
                    child: Text(
                      profession,
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                            fontSize:
                                MediaQuery.of(context).size.height * 0.015),
                      ),
                    ),
                  ),
                  mutual == ""
                      ? Container(
                          height: 0,
                          width: 0,
                        )
                      : Padding(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.02,
                              left: MediaQuery.of(context).size.width * 0.0),
                          child: Text(
                            "$mutual's Mutaul",
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: MediaQuery.of(context).size.height *
                                      0.017),
                            ),
                          ),
                        ),
                  fp.graphID == myGraphId
                      ? Padding(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.02,
                              left: MediaQuery.of(context).size.width * 0.0),
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/editProfile')
                                  .then((value) => setState(() {}));
                            },
                            child: Container(
                              height:
                                  MediaQuery.of(context).size.height * 0.034,
                              width: MediaQuery.of(context).size.width * 0.38,
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Text(
                                  "Edit profile",
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                        fontSize:
                                            MediaQuery.of(context).size.height *
                                                0.015),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 0,
                        ),
                  // fp.graphID != myGraphId
                  //     ? Padding(
                  //         padding: EdgeInsets.only(
                  //             top: MediaQuery.of(context).size.height * 0.02,
                  //             left: MediaQuery.of(context).size.width * 0.0),
                  //         child: InkWell(
                  //           onTap: () async {
                  //             await apiblockUser();
                  //           },
                  //           child: Container(
                  //             height: MediaQuery.of(context).size.height * 0.06,
                  //             width: MediaQuery.of(context).size.width * 0.6,
                  //             color: Colors.white,
                  //             child: Center(
                  //               child: Text(
                  //                 "Block User",
                  //                 style: GoogleFonts.poppins(
                  //                   textStyle: TextStyle(
                  //                       color: Colors.black,
                  //                       fontWeight: FontWeight.w500,
                  //                       fontSize:
                  //                           MediaQuery.of(context).size.height *
                  //                               0.015),
                  //                 ),
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //       )
                  //     : Container(
                  //         height: 0,
                  //       ),
                ],
              );
            },
          )),
    );
  }
}
