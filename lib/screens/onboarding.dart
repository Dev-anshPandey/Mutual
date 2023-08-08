import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';

Map? mapResponse;
List<Column> onboarding = [];


class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  int dotposition = 0;
  int totaldots = 0;
  Future apiCall() async {
    
    http.Response response;
    response =
        await http.get(Uri.parse("http://3.110.164.26/v1/api/user/onboarding"));
    if (response.statusCode == 200) {
      setState(() {
        mapResponse = jsonDecode(response.body);
        totaldots = mapResponse!["data"].length;
        Map<String, HighlightedWord> words = {
    "Mutuals": HighlightedWord(
        textStyle: GoogleFonts.poppins(
                      textStyle: TextStyle(
                          color: Color(0xff407BFF),
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).size.height * 0.02
                          ))
    ),
    "Contacts": HighlightedWord(
        textStyle: GoogleFonts.poppins(
                      textStyle: TextStyle(
                          color: Color(0xff407BFF),
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).size.height * 0.02))
    ),
    "Ask": HighlightedWord(
        textStyle: GoogleFonts.poppins(
                      textStyle: TextStyle(
                          color: Color(0xff407BFF),
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).size.height * 0.02))
    ),
    "Trustful": HighlightedWord(
        textStyle: GoogleFonts.poppins(
                      textStyle: TextStyle(
                          color: Color(0xff407BFF),
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).size.height * 0.02))
    ),
   
    
};
        for (var arr in mapResponse!["data"]) {
          onboarding.add(Column(
            children: [
              
              Container(
                width: MediaQuery.of(context).size.width*0.65,
                child: TextHighlight(
                  words: words,
                 text: arr["text"].toString(),
                  textAlign: TextAlign.center,

                  textStyle: GoogleFonts.poppins(
                      textStyle: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).size.height * 0.02)),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.06,
                  bottom: MediaQuery.of(context).size.height * 0.0,
                ),
                child: Image.network(arr["imgUrl"]),
              ),
            ],
          ));
        }
      });
    }
    print(mapResponse!["data"].length);
  }

  @override
  void initState() {
    apiCall();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.19),
            child: CarouselSlider.builder(
              itemBuilder: (context, index, realIndex) {
                return onboarding[index];
              },
              itemCount: onboarding.length,
              options: CarouselOptions(
                  autoPlay: true,
                  autoPlayInterval: Duration(seconds: 2),
                  height: MediaQuery.of(context).size.height * 0.55,
                  onPageChanged: (index, reason) {
                    setState(() {
                      dotposition = index;
                    });
                  },
                  enableInfiniteScroll: false,
                  pauseAutoPlayInFiniteScroll: true,
                  viewportFraction: 1),
            ),
          ),
          
          Padding(
           padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.01,
                  bottom: MediaQuery.of(context).size.height * 0.0,
                ),
            child: Center(
                child: DotIndicator(
              dotposition: dotposition,
              totaldots: totaldots,
            )),
          ),
          Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.1,
                bottom: MediaQuery.of(context).size.height * 0.0),
            child: Visibility(
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              visible:  true ,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.06,
                width: MediaQuery.of(context).size.width * 0.8,
                child: Container(
                  decoration: BoxDecoration(
                      gradient:  LinearGradient(
                          colors: [Color(0xff3795F1), Color(0xff3E6CE9)]),
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/number');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(81),
                      ),
                    ),
                    child: const Text("LET'S START"),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DotIndicator extends StatelessWidget {
  int dotposition = 0;
  int totaldots = 0;

  DotIndicator({required this.dotposition, required this.totaldots});
  @override
  Widget build(BuildContext context) {
    return AnimatedSmoothIndicator(
      count: totaldots,
      activeIndex: dotposition,
      effect: ScaleEffect(
          activeDotColor: Color(0xff336FD7),
          dotColor: Color(0xff336FD7).withOpacity(0.2),
          dotHeight: 7,
          dotWidth: 7),
    );
  }
}
