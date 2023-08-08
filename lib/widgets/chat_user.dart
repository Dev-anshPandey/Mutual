import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatUser extends StatelessWidget {
  String name;
  String phoneNo;
  String profilePic;
  bool onPlatform;
  ChatUser(
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
          
        ],
      ),
    );
  }
}
