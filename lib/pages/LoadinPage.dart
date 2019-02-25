import 'dart:async';

import 'package:flutter/material.dart';
import 'package:osm_map/pages/MapPage.dart';

class LoadingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Timer.run(() => Navigator.push(context, ScaleRoute(widget: MapPage())));
    Timer.run(() => Navigator.pushReplacementNamed(context, MapPage.route));

    return Center(
      child: Text('Loading...'),
    );
  }
}