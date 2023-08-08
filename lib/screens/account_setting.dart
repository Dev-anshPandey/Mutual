import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mutual/screens/db.dart';
import 'package:mutual/screens/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

DioClient d = DioClient();

class AccountSetting extends StatefulWidget {
  const AccountSetting({super.key});

  @override
  State<AccountSetting> createState() => _AccountSettingState();
}

class _AccountSettingState extends State<AccountSetting> {
  MyDb mydb = new MyDb();

  List storedchat = [];

  int cursorCount = 0;

  int cursorAdd = 0;

  late Database dbnew;
  Future apiLogout() async {
    var request = await d.dio.get('http://3.110.164.26//v1/api/user/logout');

    if (request.statusCode == 200) {
      setState(() {});
    } else {
      print(request.statusMessage);
    }
  }

  Future intializeDB() async {
    dbnew = await mydb.open();
  }

  @override
  void initState() {
    intializeDB();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Padding(
        padding:
            EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.028,
              ),
              child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(Icons.arrow_back)),
            ),
            Padding(
              padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.02,
                  top: MediaQuery.of(context).size.height * 0.02,
                  bottom: MediaQuery.of(context).size.height * 0.04),
              child: Text('Account Settings',
                  style: GoogleFonts.roboto(
                      textStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: MediaQuery.of(context).size.height * 0.028,
                  ))),
            ),
            Padding(
              padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.02,
                  bottom: MediaQuery.of(context).size.height * 0.032),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {},
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          size: MediaQuery.of(context).size.height * 0.024,
                        ),
                        SizedBox(
                          width: 18,
                        ),
                        Text('Delete Account',
                            style: GoogleFonts.roboto(
                                textStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.02,
                            ))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        right: MediaQuery.of(context).size.width * 0.04),
                    child: Icon(
                      Icons.arrow_forward_ios_outlined,
                      size: MediaQuery.of(context).size.height * 0.02,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () async {
                await apiLogout();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/number', (r) => false);
                dbnew.rawDelete("Delete * from chat");
                SharedPreferences pref = await SharedPreferences.getInstance();
                await pref.setString('isloggedIn', 'false');
              },
              child: Padding(
                padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.022,
                  top: MediaQuery.of(context).size.height * 0.02,
                ),
                child: Text('Logout',
                    style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: MediaQuery.of(context).size.height * 0.02,
                    ))),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
