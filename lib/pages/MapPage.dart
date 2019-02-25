import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:location/location.dart';
import 'package:osm_map/services/OSMAPIService.dart';

enum _MapSource {
  GIS,
  OSM,
  MAPSURFER,
  MAPBOX,
}

class _MapSourceConfig {
  final String mapUrl;
  final List<String> domains;

  const _MapSourceConfig(this.mapUrl, this.domains);
}

final Map<_MapSource, _MapSourceConfig> _mapConfigs = {
  _MapSource.GIS: const _MapSourceConfig(
      'https://{s}.maps.2gis.com/tiles?x={x}&y={y}&z={z}&v=1.5&r=g&ts=online_sd',
      ['tile3', 'tile2', 'tile1']),
  _MapSource.OSM: const _MapSourceConfig(
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', ['a', 'b', 'c']),
  _MapSource.MAPSURFER: const _MapSourceConfig('https://api.openrouteservice.org/mapsurfer/{z}/{x}/{y}.png?api_key=5b3ce3597851110001cf6248536ac8c6ad974ca4819e3bf315dc61c6', []),
  _MapSource.MAPBOX: const _MapSourceConfig('https://api.tiles.mapbox.com/v4/mapbox.streets/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiZmF4dG9yIiwiYSI6ImNqaGw0N3Y0ZDJ6Z2QzMGw4NDdpYnRtMzMifQ.foAAmOA9gi06AGkfy2cjcA', []),
};

class MapPage extends StatefulWidget {
  static String route = '/map';

  @override
  State<StatefulWidget> createState() => new _MapPageState();
}

class _MapPageState extends State<MapPage> {
  _MapSource _currentSource;
  LatLng _position;
  MapController _mapController;
  List<LatLng> _route = [];
  Marker _user;
  Marker _from;
  Marker _to;
  int _clickTimes = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();


  @override
  void initState() {
    super.initState();
    _route = [];
    _currentSource = _MapSource.GIS;
    _position = new LatLng(48.233826, 8.344268);
    _mapController = new MapController();
    StreamSubscription<Map<String, double>> sub = Location().onLocationChanged().listen((data) {});

    sub.onData((Map<String, double> pos) {
      LatLng user = new LatLng(pos['latitude'], pos['longitude']);

      setState(() {
        _user = buildMarker(user, Icons.person_pin_circle, Colors.blueAccent);
        _mapController.move(user, 14.0);
        sub.cancel();
      });
    });
  }

  Marker buildMarker(LatLng pos, IconData icon, Color color, [double size = 50.0]) {
    return new Marker(
      width: 80.0,
      height: 80.0,
      point: pos,
      builder: (context) => new Icon(icon, color: color, size: size),
    );
  }

  void loadRoute() {
    if (_to == null || _from == null) {
      return;
    }
    LatLng from = _from.point;
    LatLng to = _to.point;
    String fromStr = '${from.longitude.toString()},${from.latitude.toString()}';
    String toStr = '${to.longitude.toString()},${to.latitude.toString()}';
    String coords = '$fromStr|$toStr';

    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: Text('Route calculation, please wait...'),
    ));
    OSMAPIService.getInstance().request('GET', '/directions', params: {
      'profile': 'driving-car',
      'geometry_format': 'polyline',
      'coordinates': coords,
    })
      .then((data) {
        if (data != null && !data['routes'].isEmpty && !data['routes'][0]['geometry'].isEmpty) {
          _scaffoldKey.currentState.hideCurrentSnackBar();
          setState(() {
            _route.clear();
            data['routes'][0]['geometry'].forEach((item) {
              if (item is List) {
                _route.add(new LatLng(item[1], item[0]));
              }
            });
          });
        } else {
          _scaffoldKey.currentState.showSnackBar(new SnackBar(
            content: Text('No routes were found'),
            duration: Duration(seconds: 3),
          ));
        }
      })
      .catchError((err) {
        _scaffoldKey.currentState.showSnackBar(new SnackBar(
          content: Text('Error occured, try again later'),
          duration: Duration(seconds: 3),
        ));
        print(err);
      });
  }

  void onMapTap(LatLng pos) {
    if (_clickTimes % 2 == 0) {
      setState(() {
        _from = buildMarker(pos, Icons.pin_drop, Colors.purple, 40.0);
        _route = [];
        _to = null;
        _clickTimes = (_clickTimes + 1) % 2;
      });
    } else {
      setState(() {
        _to = buildMarker(pos, Icons.pin_drop, Colors.green, 40.0);
        _clickTimes = (_clickTimes + 1) % 2;
        loadRoute();
      });
    }
  }

  void selectMap(_MapSource src) {
    setState(() {
      _currentSource = src;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _MapSourceConfig config = _mapConfigs[_currentSource];
    final List<Marker> markers = [];

    if (_user != null) {
      markers.add(_user);
    }
    if (_from != null) {
      markers.add(_from);
    }
    if (_to != null) {
      markers.add(_to);
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Map'),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Flexible(
              child: new FlutterMap(
                mapController: _mapController,
                options: new MapOptions(
                  center: _position,
                  zoom: 5.0,
                  onTap: onMapTap,
                ),
                layers: [
                  new TileLayerOptions(
                    urlTemplate: config.mapUrl,
                    subdomains: config.domains,
                  ),
                  new PolylineLayerOptions(
                    polylines: [
                      new Polyline(
                        points: _route,
                        strokeWidth: 4.0,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  new MarkerLayerOptions(markers: markers),
                ],
              ),
            ),
            Row(
              children: <Widget>[
                FlatButton(
                  color: _currentSource == _MapSource.GIS ? Colors.blueGrey : Colors.grey,
                  child: Text('2 GIS'),
                  onPressed: () => selectMap(_MapSource.GIS),
                ),
                FlatButton(
                  color: _currentSource == _MapSource.OSM ? Colors.blueGrey : Colors.grey,
                  child: Text('OpenStreetMap'),
                  onPressed: () => selectMap(_MapSource.OSM),
                ),
                // FlatButton(
                //   color: _currentSource == _MapSource.MAPSURFER ? Colors.blueGrey : Colors.grey,
                //   child: Text('Map surfer'),
                //   onPressed: () => selectMap(_MapSource.MAPSURFER),
                // ),
                FlatButton(
                  color: _currentSource == _MapSource.MAPBOX ? Colors.blueGrey : Colors.grey,
                  child: Text('Mapbox'),
                  onPressed: () => selectMap(_MapSource.MAPBOX),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
