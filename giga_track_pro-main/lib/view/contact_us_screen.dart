import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  Future<void> _launchURLBrowser(String link) async {
    final Uri url = link.contains('@')
        ? Uri(scheme: 'mailto', path: link)
        : Uri.parse(link);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (kDebugMode) {
        print('Could not launch $link');
      } // Simple console log
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Contact Us',
            style: AppColors.appTitleTextStyle,
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding:
                    EdgeInsets.only(top: 50.0, left: 50, right: 50, bottom: 30),
                child: Transform.scale(
                  scale: 4,
                  child: Image(
                    width: 180,
                    height: 100,
                    image: AssetImage("assets/images/company_logo.png"),
                  ),
                ),
              ),
              const SizedBox(
                height: 0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [


                  //
                  /// Landline Number
                  InkWell(
                    onTap: () => _launchURLBrowser('tel:+923129665107'),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[100],
                      child: const Image(
                        image: AssetImage('assets/images/Phone_96px.png'),
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),

                  /// Gmail Account
                  InkWell(
                    onTap: () => _launchURLBrowser('gigatrack786@gmail.com'),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[100],
                      child: const Image(
                        image: AssetImage('assets/images/Send Email_96px.png'),
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),

                  /// Website Info
                  InkWell(
                    onTap: () => _launchURLBrowser('https://gigatrack.com.pk/'),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[100],
                      child: const Image(
                        image: AssetImage('assets/images/Globe_96px.png'),
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [

                  /// Whatsapp Account
                  InkWell(
                    onTap: () => _launchURLBrowser(
                        'https://wa.me/923129665107?text=I need information on tracker services'),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[100],
                      child: const Image(
                        image: AssetImage('assets/images/WhatsApp_96px.png'),
                        width: 48,
                        height: 48,
                      ),
                    ),
                  ),

                  /// Facebook Info
                  InkWell(
                    onTap: () => _launchURLBrowser(
                        'https://www.facebook.com/share/1EwRgDYCDp/'),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[100],
                      child: const Image(
                        image: AssetImage('assets/images/facebook.png'),
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),

                  /// Instagram Info
                  InkWell(
                    onTap: () => _launchURLBrowser(
                        'https://www.instagram.com/giga_track?igsh=ZHNjZHV4MXl3Zmcy'),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[100],
                      child: const Image(
                        image: AssetImage('assets/images/Instagram_96px.png'),
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width - 15,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _launchURLBrowser(
                          'https://autotel.pk/privacy-and-policy/'),
                      child: Card(
                        shape: AppColors.cardBorderShape,
                        child: const ListTile(
                          title: Text(
                            'Terms and Conditions',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width - 15,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _launchURLBrowser(
                          'https://autotel.pk/privacy-and-policy/'),
                      child: Card(
                        shape: AppColors.cardBorderShape,
                        child: const ListTile(
                          title: Text(
                            'Privacy Policy',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width - 15,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () =>
                          _launchURLBrowser('https://autotel.pk/news/'),
                      child: Card(
                        shape: AppColors.cardBorderShape,
                        child: const ListTile(
                          title: Text(
                            'Company News',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),

              /// Office Address
              const Text(
                'Office Address',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  textAlign: TextAlign.center,
                  'Office # S-2,2nd floor Rehara Complex,Bahria Enclave Road Islamabad',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black54),
                ),
              ),

              /// Powered By
              const Text(
                'Powered By Giga Track Pvt. Ltd.',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: AppColors.buttonColor),
              ),
              SizedBox(height:15,),
            ],
          ),
        ),
      ),
    );
  }
}
