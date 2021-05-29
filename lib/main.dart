import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';

String verName = "1.1";
bool USE_FIRESTORE_EMULATOR = false;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (USE_FIRESTORE_EMULATOR) {
    FirebaseFirestore.instance.settings = const Settings(
        host: 'localhost:8080', sslEnabled: false, persistenceEnabled: false);
  }
  FirebaseFirestore.instance
      .collection('version')
      .doc('IepUEy4OKfKax0BgYK9z')
      .get()
      .then((DocumentSnapshot documentSnapshot) async {
    if (documentSnapshot.exists) {
      Map<String, dynamic> querySnapshot = documentSnapshot.data();
      if (verName != querySnapshot['verName']) {
        String _url = querySnapshot['link'];
        await canLaunch(_url)
            ? await launch(_url)
            : throw 'Could not launch $_url';
      }
    }
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web Gallery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        // When navigating to the "/" route, build the FirstScreen widget.
        '/': (context) => MyHomePage(title: 'Web Gallery'),
        // When navigating to the "/second" route, build the SecondScreen widget.
        '/addLink': (context) => AddLink(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    Query query =
        FirebaseFirestore.instance.collection('link') /*.orderBy('priority')*/;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, stream) {
          if (stream.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (stream.hasError) {
            return Center(child: Text(stream.error.toString()));
          }

          QuerySnapshot querySnapshot = stream.data;

          return ListView.builder(
            itemCount: querySnapshot.size,
            itemBuilder: (context, index) => Web(querySnapshot.docs[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/addLink', arguments: {'link': query});
        },
        tooltip: 'Add Link',
        child: Icon(Icons.add),
      ),
    );
  }
}

class Web extends StatelessWidget {
  /// Contains all snapshot data for a given web.
  final DocumentSnapshot snapshot;

  /// Initialize a [Move] instance with a given [DocumentSnapshot].
  Web(this.snapshot);

  /// Returns the [DocumentSnapshot] data as a a [Map].
  Map<String, dynamic> get web {
    return snapshot.data();
  }

  /// Returns the web image.
  Widget get image {
    return SizedBox(
      width: 100,
      child: Center(
          child: Image.network(
              /*"http://shachikuengineer.tk/" +*/ web['image'], errorBuilder:
                  (BuildContext context, Object exception,
                      StackTrace stackTrace) {
        return Container();
      })),
    );
  }

  /// Return the web title.
  Widget get title {
    return Text('${web['title']}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  /// Return the web url.
  String get url {
    return web['url'];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: GestureDetector(
          onLongPress: () async {
            showDialog(
              context: context,
              barrierDismissible: false, // user must tap button!
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('刪除'),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: <Widget>[
                        Text('確定刪除嗎？'),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text('取消'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text('確定'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        snapshot.reference.delete();
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: InkWell(
              onTap: () async {
                String _url = url;
                await canLaunch(_url)
                    ? await launch(_url)
                    : throw 'Could not launch $_url';
              },
              child: Container(
                  height: 100,
                  child: Row(
                    children: [
                      image,
                      Padding(
                          padding: EdgeInsets.only(left: 30.0), child: title)
                    ],
                  )))),
    );
  }
}

class AddLink extends StatelessWidget {
  final List<TextEditingController> controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(text: '1')
  ];

  Future<void> addLink(link) {
    List<String> input = [
      controllers[0].text,
      controllers[1].text,
      controllers[2].text,
      controllers[3].text
    ];
    for (TextEditingController controller in controllers) controller.clear();
    controllers[3].text = '1';

    return link.add({
      'title': input[0],
      'url': input[1],
      'image': input[2],
      'priority': int.parse(input[3])
    }).then((value) {
      print("Link Added");
      Fluttertoast.showToast(
          msg: "新增成功",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black87,
          textColor: Colors.white,
          fontSize: 16.0);
    }).catchError((error) {
      print("Failed to add link: $error");
      Fluttertoast.showToast(
          msg: "新增失敗: $error",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context).settings.arguments;
    return Scaffold(
        appBar: AppBar(
          title: Text('新增連結'),
        ),
        body: Center(
            child: SizedBox(
          width: 600,
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text('標題', style: const TextStyle(fontSize: 18)),
                  ),
                  Flexible(
                    child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: TextField(
                            controller: controllers[0],
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(16.0),
                                hintText: 'title'))),
                  )
                ],
              ),
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text('連結', style: const TextStyle(fontSize: 18)),
                  ),
                  Flexible(
                    child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: TextField(
                            controller: controllers[1],
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(16.0),
                                hintText: 'link'))),
                  )
                ],
              ),
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text('圖片連結', style: const TextStyle(fontSize: 18)),
                  ),
                  Flexible(
                    child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: TextField(
                            controller: controllers[2],
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(16.0),
                                hintText: 'image link'))),
                  )
                ],
              ),
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text('優先序', style: const TextStyle(fontSize: 18)),
                  ),
                  Flexible(
                    child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: TextField(
                            controller: controllers[3],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(16.0),
                                hintText: 'priority'))),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      onPressed: () {
                        addLink(args['link']);
                      },
                      child: Text('確定'),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.red, // background
                        onPrimary: Colors.white, // foreground
                      ),
                      onPressed: () {
                        for (TextEditingController controller in controllers)
                          controller.clear();

                        controllers[3].text = '1';
                      },
                      child: Text('清除'),
                    ),
                  )
                ],
              )
            ],
          ),
        )));
  }
}
