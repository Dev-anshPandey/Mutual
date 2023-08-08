import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mutual/screens/dio.dart';

List<Contact> contacts = [];
Future? _future;
List display = [];
List contactsPresnet = [];
DioClient d = DioClient();

class AddContact extends StatefulWidget {
  const AddContact({super.key});

  @override
  State<AddContact> createState() => _AddContactState();
}

class _AddContactState extends State<AddContact> {
  Future apigetUser() async {
    display.clear();
    await getContact();
    var request = await d.dio.get('http://3.110.164.26/v1/api/user/exists');
    print(request);
    if (request.statusCode == 200) {
      for (var sd in request.data['data']['userExist']) {
        print(sd['phoneNumber']);
        contactsPresnet.add(sd['phoneNumber']);
        setState(() {
          display.add(ListContact(
              name: sd['firstName'],
              phoneNo: sd['phoneNumber'],
              profilePic: sd['profilePic'],
              onPlatform: true));
        });
      }
      for (int i = 0; i < contacts.length; i++) {
        try {
          if (contacts[i].givenName != null &&
              contacts[i].phones?.length != 0) {
            String pNo = contacts[i].phones![0].value.toString();
            if (pNo.contains('+91')) {
              pNo = pNo.substring(3, 13);
              print("pNo is $pNo");
            }
            if (!contactsPresnet.contains(pNo)) {
              setState(() {
                display.add(ListContact(
                    name: contacts[i].givenName ?? "",
                    phoneNo: contacts[i].phones![0].value.toString(),
                    profilePic: "",
                    onPlatform: false));
              });
            }
          }
        } catch (e) {
          print(e);
        }
      }
    } else {
      print(request.statusMessage);
    }
  }

  getContact() async {
    contacts = await ContactsService.getContacts();
  }

  @override
  void initState() {
    _future = apigetUser();

    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(
              elevation: 0.4,
              backgroundColor: Colors.white,
              leading: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.width * 0.036,
                        right: 0),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                    ),
                  )),
              titleSpacing: MediaQuery.of(context).size.width * 0.04,
              title: Text("Select Contact ",
                  style: GoogleFonts.roboto(
                      textStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: MediaQuery.of(context).size.height * 0.023,
                  ))),
            ),
            body: SafeArea(
              child: ListView.separated(
                  itemBuilder: (context, index) {
                    return display[index];
                  },
                  separatorBuilder: (context, index) {
                    return Divider(
                      height: 1,
                      endIndent: 0,
                      indent: 0,
                    );
                  },
                  itemCount: display.length),
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

class ListContact extends StatelessWidget {
  String name;
  String phoneNo;
  String profilePic;
  bool onPlatform;
  ListContact(
      {required this.name,
      required this.phoneNo,
      required this.profilePic,
      required this.onPlatform});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.007,
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
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/feed',arguments: {'indexNo':1});
            },
            child: Text(
              onPlatform == true ? "Add to chat" : "Invite",
              style: GoogleFonts.roboto(
                  textStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      color: Color(0xff3E6CE9))),
            ),
          ),
        ],
      ),
    );
  }
}
