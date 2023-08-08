import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/ip_address.dart';
import 'otp_widget.dart';

String number = "";
bool tnCState = true;
int widgetNumber = 0;
String otp = "";
String accessToken = "";
String refreshToken = "";
String correctOtp = "";
String? fcm;
String deviceId = "";
String device = "Android";

class ContactClass {
  String name;
  String phoneNumber;

  ContactClass(this.name, this.phoneNumber);

  Map toJson() => {
        'name': name,
        'phoneNumber': phoneNumber,
      };
}

class Number extends StatefulWidget {
  const Number({super.key});

  @override
  State<Number> createState() => _NumberState();
}

class _NumberState extends State<Number> {
  @override
  void initState() {
    FirebaseMessaging.instance.getToken().then((value) {
      setState(() {
        fcm = value;
      });
      print("FCM token is $value");
    });
    widgetNumber = 0;
    number = "";
    _getId();
    // TODO: implement initState
    super.initState();
  }

  Future<String?> _getId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      // import 'dart:io'
      var iosDeviceInfo = await deviceInfo.iosInfo;
      setState(() {
        device = "IOS";
        deviceId = iosDeviceInfo.identifierForVendor!;
      }); // unique ID on iOS
    } else if (Platform.isAndroid) {
      const _androidIdPlugin = AndroidId();
      String temp = (await _androidIdPlugin.getId())!;
      setState(() {
        device = "Android";
        deviceId = temp;
      }); // unique ID on Android
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
          scrollDirection: Axis.vertical, child: NumberWidget()),
    );
  }
}

class NumberWidget extends StatefulWidget {
  const NumberWidget({
    super.key,
  });

  @override
  State<NumberWidget> createState() => _NumberWidgetState();
}

class _NumberWidgetState extends State<NumberWidget> {
  Future apiOtp(String Number) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
        'POST', Uri.parse('http://${IP.ipAddress}/v1/api/user/send/otp'));
    request.body = json.encode({"phoneNumber": Number});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  Future apiResendOtp(String Number) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
        'POST', Uri.parse('http://${IP.ipAddress}/v1/api/user/resend/otp'));
    request.body = json.encode({"phoneNumber": Number});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  void getContactPermission() async {
    if (await Permission.contacts.isGranted) {
      Navigator.pushNamed(context, '/welcome');
    } else {
      await Permission.contacts.request();
      if (await Permission.contacts.isGranted)
        Navigator.pushNamed(context, '/welcome');
    }
  }

  Future apiCallVerify(String Number, String otp) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
        'POST', Uri.parse('http://${IP.ipAddress}/v1/api/user/verify'));
    request.body = json.encode({
      "phoneNumber": Number,
      "otp": otp,
      "os": device,
      "deviceId": deviceId,
      "fcmToken": fcm
    });
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    String responseString = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      setState(() {
        Map mapResponse = jsonDecode(responseString);
        correctOtp = mapResponse['message'];

        print("correctOtp is $correctOtp");
        if (correctOtp == "Success") {
          accessToken = mapResponse['data']['accessToken'];
          refreshToken = mapResponse['data']['refreshToken'];
          setTokens();
        }
        if (mapResponse['data']['newUser'] == false) {
          Navigator.pushNamed(context, '/feed');
          return;
        }
        correctOtp == "Success"
            ? showDialog(
                context: context,
                builder: (context) {
                  return Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: AlertDialog(
                          insetPadding: EdgeInsets.all(25),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0))),
                          content: SizedBox(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.41,
                            child: Column(
                              children: [
                                SvgPicture.asset("assets/rafiki.svg"),
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.height *
                                          0.02,
                                      bottom:
                                          MediaQuery.of(context).size.height *
                                              0.02),
                                  child: Text(
                                    'We Work Best With Your Connections',
                                    style: GoogleFonts.poppins(
                                        textStyle: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.017)),
                                  ),
                                ),
                                Text(
                                  'We need access to your contacts to help you get easily connect in Mutual',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                          color: Colors.black,
                                          // fontWeight: FontWeight.bold,
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.014)),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.height *
                                          0.025),
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.06,
                                    width: MediaQuery.of(context).size.width *
                                        0.85,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                          gradient: LinearGradient(colors: [
                                            Color(0xff3795F1),
                                            Color(0xff3E6CE9)
                                          ]),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8))),
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (await Permission
                                              .contacts.isGranted) {
                                            Navigator.pushNamed(
                                                context, '/welcome');
                                          } else {
                                            await Permission.contacts.request();
                                            if (await Permission
                                                .contacts.isGranted)
                                              Navigator.pushNamed(
                                                  context, '/welcome');
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          "CONTINUE",
                                          style: TextStyle(
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.019),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  );
                })
            : print("Wrong Otp Entered");
      });
    } else {
      print(response.reasonPhrase);
    }
  }

  setTokens() async {
    // SharedPreferences.setMockInitialValues({});
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString("accessToken", await accessToken);
    await pref.setString("refreshToken", await refreshToken);
    if (correctOtp == "Success") {
      await pref.setString('isloggedIn', 'true');
      print("islogged in is ");
      print(pref.getString('isloggedIn'));
    }
    await apiFCM();
    getAccessTokens();
  }

  Future apiFCM() async {
    var headers = {
      'accessToken': await getAccessTokens(),
      'Content-Type': 'application/json'
    };
    print("fcm token is $fcm");

    var request = http.Request(
        'POST', Uri.parse('http://${IP.ipAddress}/v1/api/user/update/fcm'));
    request.body = json.encode({"fcmToken": fcm});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<String> getAccessTokens() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return await pref.getString("accessToken").toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.11,
              left: MediaQuery.of(context).size.width * 0.08,
              bottom: MediaQuery.of(context).size.height * 0.02,
              right: MediaQuery.of(context).size.width * 0.05),
          child: Image.asset('assets/splash.png',
              height: MediaQuery.of(context).size.height * 0.16),
        )
        // : Stack(
        //     children: [
        //       Padding(
        //         padding: EdgeInsets.only(
        //           top: MediaQuery.of(context).size.height * 0.2,
        //           left: MediaQuery.of(context).size.width * 0.12,
        //           right: MediaQuery.of(context).size.width * 0.14,
        //           bottom: MediaQuery.of(context).size.height * 0.01,
        //         ),
        //         child: IgnorePointer(
        //           child: TextField(
        //             style: GoogleFonts.poppins(
        //                 textStyle:
        //                     TextStyle(fontWeight: FontWeight.normal)),
        //             keyboardType: TextInputType.number,
        //             controller: TextEditingController(text: number),
        //             onChanged: (value) {
        //               setState(() {
        //                 number = value;
        //               });
        //             },
        //             decoration: InputDecoration(
        //               floatingLabelBehavior: FloatingLabelBehavior.always,
        //               contentPadding: EdgeInsets.only(
        //                   top: 16, bottom: 16, left: 42, right: 10),
        //               hintText: " ",
        //               labelText: "Phone Number",
        //               labelStyle: TextStyle(
        //                   fontSize:
        //                       MediaQuery.of(context).size.height * 0.022,
        //                   fontWeight: FontWeight.w100,
        //                   color: Color(0xff5975EF)),
        //               enabledBorder: OutlineInputBorder(
        //                 borderRadius: BorderRadius.circular(81),
        //                 borderSide:
        //                     BorderSide(width: 1, color: Color(0xffbADADAD)),
        //               ),
        //               focusedBorder: OutlineInputBorder(
        //                 borderRadius: BorderRadius.circular(81),
        //                 borderSide:
        //                     BorderSide(width: 1, color: Color(0xffbADADAD)),
        //               ),
        //               border: OutlineInputBorder(
        //                 borderRadius: BorderRadius.circular(81),
        //                 borderSide: const BorderSide(
        //                     width: 1,
        //                     style: BorderStyle.none,
        //                     color: Color(0xffbADADAD)),
        //               ),
        //             ),
        //           ),
        //         ),
        //       ),
        //       Positioned(
        //           top: MediaQuery.of(context).size.height * 0.218,
        //           left: MediaQuery.of(context).size.width * 0.14,
        //           child: Text(
        //             "+91",
        //             style: GoogleFonts.poppins(
        //                 textStyle: TextStyle(
        //                     fontSize:
        //                         MediaQuery.of(context).size.height * 0.019,
        //                     color: Color(0xffADADAD))),
        //           )),
        //       Positioned(
        //           top: MediaQuery.of(context).size.height * 0.22,
        //           left: MediaQuery.of(context).size.width * 0.77,
        //           child: InkWell(
        //               onTap: () {
        //                 setState(() {
        //                   widgetNumber = 0;
        //                   number = "";
        //                 });
        //               },
        //               child: const Icon(
        //                 Icons.edit,
        //                 color: Color(0xff626262),
        //               )))
        //     ],
        //   )
        ,
        widgetNumber == 0
            ? Text(
                'Login',
                style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                        color: Color(0xff373737),
                        //fontWeight: FontWeight.bold,
                        fontSize: MediaQuery.of(context).size.height * 0.018)),
              )
            : Text(
                'OTP Verification',
                style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                        color: Color(0xff373737),
                        // fontWeight: FontWeight.bold,
                        fontSize: MediaQuery.of(context).size.height * 0.018)),
              ),
        widgetNumber == 0
            ? Stack(children: [
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
                        'Mobile Number',
                        style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                                color: Colors.grey,
                                //fontWeight: FontWeight.bold,
                                fontSize: MediaQuery.of(context).size.height *
                                    0.014)),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      TextField(
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onChanged: (value) {
                          setState(() {
                            number = value;
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
                              top: 16, bottom: 16, left: 100, right: 10),
                          hintText: " ",
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
                Positioned(
                    top: MediaQuery.of(context).size.height * 0.053,
                    left: MediaQuery.of(context).size.width * 0.1,
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          gradient: LinearGradient(
                              colors: [Color(0xff3795F1), Color(0xff3E6CE9)])),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Row(
                          children: [
                            Text(
                              "+91",
                              style: GoogleFonts.poppins(
                                  textStyle: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.height *
                                              0.019,
                                      color: Colors.white)),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_outlined,
                              color: Colors.white,
                            )
                          ],
                        ),
                      ),
                    ))
              ])
            : Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.02,
                    left: MediaQuery.of(context).size.width * 0.1,
                    right: MediaQuery.of(context).size.width * 0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Enter the verification code sent via sms to you.",
                      style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.014,
                              color: Color(0xff373737))),
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    OTPTextField(
                        length: 4,
                        onCompleted: (pin) {
                          setState(() {
                            otp = pin;
                          });
                        }),
                  ],
                ),
              ),
        widgetNumber == 0
            ? Padding(
                padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.12,
                  bottom: MediaQuery.of(context).size.height * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'You will recieve OTP to given number. \t\t\t',
                      style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                              color: Color(0xff373737),
                              //fontWeight: FontWeight.bold,
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.014)),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        Checkbox(
                            value: tnCState,
                            activeColor: Color(0xff336FD7),
                            onChanged: (value) {
                              setState(() {
                                tnCState = value!;
                              });
                            }),
                        RichText(
                          text: TextSpan(
                            text: 'I Agree with the ',
                            style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                    color: Color(0xff373737),
                                    //fontWeight: FontWeight.bold,
                                    fontSize:
                                        MediaQuery.of(context).size.height *
                                            0.014)),
                            children: <TextSpan>[
                              TextSpan(
                                  text: 'Terms',
                                  style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                          color: Color(0xff336FD7),
                                          //fontWeight: FontWeight.bold,
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.014))),
                              TextSpan(
                                  text: ' and',
                                  style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                          color: Color(0xff373737),
                                          //fontWeight: FontWeight.bold,
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.014))),
                              TextSpan(
                                  text: ' Conditions',
                                  style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                          color: Color(0xff336FD7),
                                          //fontWeight: FontWeight.bold,
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.014))),
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              )
            : Container(
                height: MediaQuery.of(context).size.height * 0.06,
                width: 0,
              ),
        widgetNumber == 0
            ? SizedBox(
                height: MediaQuery.of(context).size.height * 0.06,
                width: MediaQuery.of(context).size.width * 0.8,
                child: number.length == 10 && tnCState == true
                    ? Container(
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                colors: [Color(0xff3795F1), Color(0xff3E6CE9)]),
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              widgetNumber = 1;
                            });
                            apiOtp(number);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text("SEND OTP"),
                        ),
                      )
                    : IgnorePointer(
                        child: Container(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.withOpacity(0.9),
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text("SEND OTP"),
                          ),
                        ),
                      ))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.06,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Container(
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Color(0xff3795F1), Color(0xff3E6CE9)]),
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                      child: ElevatedButton(
                        onPressed: () {
                          // setState(() {
                          //   //widgetNumber = 0;
                          // });
                          // widgetNumber = 0;
                          // tnCState = false;
                          apiCallVerify(number, otp);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Next",
                          style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.019),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Text(
                    "If don’t get OTP yet,",
                    style: TextStyle(
                        color: Color(0xff373737),
                        fontSize: MediaQuery.of(context).size.height * 0.018),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.06,
                    width: MediaQuery.of(context).size.width * 0.38,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          widgetNumber = 1;
                        });
                        apiResendOtp(number);
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        backgroundColor: Colors.transparent,
                        side: BorderSide(color: Colors.transparent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(81),
                        ),
                      ),
                      child: Text(
                        "RESEND",
                        style: TextStyle(
                            color: Color(0xff3E6CE9),
                            fontSize:
                                MediaQuery.of(context).size.height * 0.019),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                ],
              ),
      ],
    );
  }
}
