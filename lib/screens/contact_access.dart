import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactAccess extends StatelessWidget {
  // const ContactAccess({super.key});

 

  @override
  Widget build(BuildContext context) {
     

     void getContactPermission() async {
    if (await Permission.contacts.isGranted) {
      Navigator.pushNamed(context, '/welcome');
    } else {
      await Permission.contacts.request();
      if (await Permission.contacts.isGranted) Navigator.pushNamed(context, '/welcome');
    }
  }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
         scrollDirection: Axis.vertical,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.03,
                    top: MediaQuery.of(context).size.height * 0.1,
                    left: MediaQuery.of(context).size.width*0.15,
                    right: MediaQuery.of(context).size.width*0.15,
                    ),
                child: Center(
                  child: Text(
                    "Allow Contact Access",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: MediaQuery.of(context).size.height * 0.037,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width * 0.15,
                    right: MediaQuery.of(context).size.width * 0.15),
                child:  Text(
                  'Please grant contact access for connecting to gain access your mutual network',
                  textAlign: TextAlign.center,
                  style:GoogleFonts.poppins(
                    textStyle: const  TextStyle(color: Color(0xff5975EF))
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.06,
                  bottom: MediaQuery.of(context).size.height * 0.15,
                ),
                child: Image.asset("assets/Frame.png",height: MediaQuery.of(context).size.height * 0.32,),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.06,
                width: MediaQuery.of(context).size.width * 0.58,
                child: Container(
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xff3795F1), Color(0xff3E6CE9)]),
                      borderRadius: BorderRadius.all(Radius.circular(81))),
                  child: ElevatedButton(
                    onPressed: () {
                      getContactPermission();
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 10,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(81),
                      ),
                    ),
                    child: Text(
                      "ALLOW",
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height * 0.019),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
