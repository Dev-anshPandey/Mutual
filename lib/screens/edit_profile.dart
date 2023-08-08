import 'dart:convert';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_native_splash/cli_commands.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mutual/interceptor/api.dart';
import 'package:mutual/interceptor/dio.dart';
import 'package:mutual/screens/see_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/ip_address.dart';

var items = [];
String _dropDownValue = " ";
String? imageGlobal;


String selected = "";

TextEditingController myController = TextEditingController();
DioClient d = DioClient();



class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  Future apigetUser() async {
    var request = await d.dio.get('http://${IP.ipAddress}/v1/api/user/details');
    print('firstaName issss');
    print(request.data['data']['firstName']);
    if (request.statusCode == 200) {
      setState(() {
        name = request.data['data']['firstName'];
        profileUrl = request.data['data']['profilePic'];
        profession = request.data['data']['profession'];
        // graphId = request.data['data']['graphId'];
      });
    } else {
      print(request.statusMessage);
    }
   
  }

  File? image;
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

  Future<String> getAccessTokens() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return await pref.getString("accessToken").toString();
  }

  Future apiCallOptions() async {
    var request = await d.dio.get(
      'http://${IP.ipAddress}/v1/api/user/list/options',
    );

    final response = await d.dio.get(
      'http://${IP.ipAddress}/v1/api/user/list/options',
    );
    if (response.statusCode == 200) {
      String res = await response.data.toString();
      print(response.data);
      for (var data in response.data["data"]) {
        print(data);
        setState(() {
          items.add(data);
        });
      }
    } else {
      print(response);
    }
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

//    request.add(await http.MultipartFile.fromPath('image', imageGlobal!));

    // final response =
    //     await d.dio.post('http://65.1.147.175/v1/api/user/image/upload');
  }

  Future apiCallUpdateData() async {
    var data = json.encode({
      "firstName": name,
      "profession": profession,
      "profilePic": profileUrl,
    });
    print(selected);
    final response = await d.dio
        .post('http://${IP.ipAddress}/v1/api/user/profile/update', data: data);
    if (response.statusCode == 200) {
      print(await response.data.toString());
    } else {
      print(response.statusCode);
    }
  }

  _printLatestValue() {
    print("Textfield value: ${myController.text}");
  }

  @override
  void initState() {
    apigetUser();
    apiCallOptions();
    // TODO: implement initState
    super.initState();
    myController.addListener(_printLatestValue);
  }

  @override
  Widget build(BuildContext context) {
    //String dropdownvalue = "Item 1";

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.03,
            bottom: MediaQuery.of(context).viewInsets.bottom + 5,
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
                apiCallUpdateData();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "SAVE PROFILE",
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.height * 0.019),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SafeArea(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.04,
                  left: MediaQuery.of(context).size.width * 0),
              child: Text(
                'Edit Profile',
                style: GoogleFonts.roboto(
                    textStyle: TextStyle(
                        color: Color(0xff373737),
                        fontWeight: FontWeight.w500,
                        fontSize: MediaQuery.of(context).size.height * 0.021)),
              ),
            ),
            Divider(
              height: 40,
              thickness: 0.1,
              color: Colors.grey,
            ),
            Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.007,
                  left: MediaQuery.of(context).size.width * 0),
              child: Stack(children: [
                profileUrl == ""
                    ? InkWell(
                        onTap: PickImage,
                        child: Icon(
                          Icons.account_circle,
                          size: MediaQuery.of(context).size.height * 0.22,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                      )
                    : CircleAvatar(
                        radius: MediaQuery.of(context).size.height * 0.1,
                        backgroundImage: NetworkImage(profileUrl)),
                Positioned(
                    top: MediaQuery.of(context).size.height * 0.15,
                    left: MediaQuery.of(context).size.width * 0.32,
                    child: InkWell(
                      onTap: PickImage,
                      child: CircleAvatar(
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                        ),
                        backgroundColor: Color(0xff336FD7),
                      ),
                    ))
              ]),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.024,
                left: MediaQuery.of(context).size.width * 0.11,
                right: MediaQuery.of(context).size.width * 0.11,
                bottom: MediaQuery.of(context).size.height * 0.019,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Name',
                    style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                            color: Colors.black,
                            //fontWeight: FontWeight.bold,
                            fontSize:
                                MediaQuery.of(context).size.height * 0.016)),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  TextFormField(
                    keyboardType: TextInputType.name,
                    inputFormatters: [],
                    onChanged: (value) {
                      setState(() {
                        name = value;
                      });
                    },
                    initialValue: name,
                    
                    style: GoogleFonts.poppins(
                        textStyle:
                            const TextStyle(fontWeight: FontWeight.normal)),
                    decoration: InputDecoration(
                      fillColor: Color(0xffF5F5F5),
                      filled: true,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: const EdgeInsets.only(
                          top: 16, bottom: 16, left: 10, right: 10),
                      hintText: "Enter Name",
                      hintStyle: TextStyle(
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          width: 0,
                          color: Color(0xffF5F5F5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.014,
                left: MediaQuery.of(context).size.width * 0.11,
                right: MediaQuery.of(context).size.width * 0.11,
                bottom: MediaQuery.of(context).size.height * 0.019,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profession , Passion & Interest',
                    style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                            color: Colors.black,
                            //fontWeight: FontWeight.bold,
                            fontSize:
                                MediaQuery.of(context).size.height * 0.016)),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  TextFormField(
                    keyboardType: TextInputType.name,
                    initialValue: profession,
                    
                    inputFormatters: [],
                    onChanged: (value) {
                      setState(() {
                        profession = value;
                      });
                    },
                    style: GoogleFonts.poppins(
                        textStyle:
                            const TextStyle(fontWeight: FontWeight.normal)),
                    decoration: InputDecoration(
                      fillColor: Color(0xffF5F5F5),
                      filled: true,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: const EdgeInsets.only(
                          top: 16, bottom: 16, left: 10, right: 10),
                      hintText: "Choose Multiple",
                      hintStyle: TextStyle(
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          width: 0,
                          color: Color(0xffF5F5F5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
