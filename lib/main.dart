import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  FirebaseMessaging messaging;

  @override
  void initState() {
    _initialization.whenComplete(() {
      messaging = FirebaseMessaging.instance;
      _getFCMToken();
    });
    super.initState();
  }

  Future<void> _getFCMToken() async{
    // Go to Firebase console -> Project settings -> Cloud Messaging -> Web Push Certificates -> create key pair -> copy and paste
    const yourVapidKey = "YOUR_VAPID_KEY";

    String _fcmToken = await FirebaseMessaging.instance.getToken(vapidKey: yourVapidKey);
    print('_FCMToken is $_fcmToken');

    if(Platform.isIOS){
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('widget.title'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        // Initialize FlutterFire:
        future: _initialization,
        builder: (context, snapshot) {
          // Check for errors
          if (snapshot.hasError) {
            return Center(child: Text('Network error. please check your network connection'));
          }

          // Once complete, show your application
          if (snapshot.connectionState == ConnectionState.done) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FlatButton(
                    color: Colors.orange[800],
                    onPressed: () async{
                      // Go to Firebase console -> Functions -> copy and paste sendMessage URL
                      // index.js file download link: https://github.com/loydkim/Flutter_Firebase_Messasing_2021/blob/main/index.js
                      await http.get('YOUR_CLOUD_FUNCTION_URL').
                        then((value) {
                          print(value.body);
                        }
                      );
                  }, child: Text('Send a message from cloud function',style: TextStyle(color: Colors.white),)),
                  FlatButton(
                    color: Colors.green[800],
                    onPressed: () async{
                    await _sendAndRetrieveMessage();
                  }, child: Text('Send a message from http',style: TextStyle(color: Colors.white))),
                ],
              ),
            );
          }

          // Otherwise, show something whilst waiting for initialization to complete
           return Center(child: CircularProgressIndicator());
        },
      )


    );
  }

  Future<void> _sendAndRetrieveMessage() async {
    // Go to Firebase console -> Project settings -> Cloud Messaging -> copy Server key
    // the Server key will start "AAAAMEjC64Y..."

    const yourServerKey = "YOUR_SERVER_KEY";
    await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$yourServerKey',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': 'This message is from Client',
            'title': 'Hello Loyd!',
            'image': 'https://yt3.ggpht.com/ytc/AAUvwnjuH8xEOYQyRAE2NMrVieRw0GBbcJ9l5wLPpvgHDQ=s88-c-k-c0x00ffffff-no-rj'
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done'
          },
          // FCM Token lists.
          'registration_ids':["Your_FCM_Token_One", "Your_FCM_Token_Two"],
        },
      ),
    );
  }
}
