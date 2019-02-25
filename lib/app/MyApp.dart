import 'package:flutter/material.dart';
import 'package:osm_map/pages/LoadinPage.dart';
import 'package:osm_map/pages/MapPage.dart';

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    String title = 'OpenStreen map';

    return MaterialApp(
      title: title,
      initialRoute: '/',
      routes: {
        '/': (context) => new LoadingPage(),
        MapPage.route: (context) => new MapPage(),
      },
    );
  }
}