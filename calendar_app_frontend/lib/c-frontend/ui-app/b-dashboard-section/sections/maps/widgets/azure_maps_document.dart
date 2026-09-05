import 'dart:convert';

import 'azure_maps_types.dart';

String buildAzureMapsDocument({
  required String instanceId,
  required String clientId,
  required String accessToken,
  required List<AzureMapPin> pins,
  required AzureMapSelection? selection,
  required AzureMapUserLocation? userLocation,
}) {
  final config = jsonEncode(<String, dynamic>{
    'instanceId': instanceId,
    'clientId': clientId,
    'accessToken': accessToken,
    'pins': pins.map((pin) => pin.toJson()).toList(growable: false),
    'selection': selection?.toJson(),
    'userLocation': userLocation?.toJson(),
  }).replaceAll('</', r'<\/');

  return '''<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
  <link rel="stylesheet" href="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.css" type="text/css">
  <script src="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.js"></script>
  <style>
    html,body,#map{width:100%;height:100%;margin:0;overflow:hidden;background:#eef2f7;font-family:Arial,sans-serif}
    .pin{width:28px;height:28px;border-radius:50% 50% 50% 0;background:#35649a;border:3px solid white;box-shadow:0 3px 10px rgba(15,23,42,.3);transform:rotate(-45deg)}
    .pin:after{content:'';position:absolute;width:8px;height:8px;border-radius:50%;background:white;top:7px;left:7px}
    .selected-pin{width:32px;height:32px;border-radius:50% 50% 50% 0;background:#ef7b45;border:3px solid white;box-shadow:0 4px 14px rgba(15,23,42,.38);transform:rotate(-45deg);cursor:grab}
    .selected-pin:after{content:'';position:absolute;width:10px;height:10px;border-radius:50%;background:white;top:8px;left:8px}
    .user-location{position:relative;display:grid;place-items:center;width:34px;height:34px;border-radius:50%;background:#1677ff;border:3px solid white;box-shadow:0 3px 12px rgba(15,23,42,.48)}
    .user-location:before{content:'';position:absolute;inset:-11px;border-radius:50%;background:rgba(22,119,255,.28);animation:pulse 1.8s ease-out infinite}
    .user-location svg{position:relative;z-index:1;width:19px;height:19px;fill:white;filter:drop-shadow(0 1px 1px rgba(0,0,0,.18))}
    @keyframes pulse{0%{transform:scale(.55);opacity:1}100%{transform:scale(1.45);opacity:0}}
    .loading{position:absolute;inset:0;display:grid;place-items:center;color:#475569;font-size:14px;background:#eef2f7}
  </style>
</head>
<body>
  <div id="map"><div class="loading">Cargando mapa...</div></div>
  <script>
    const config = $config;
    let currentToken = config.accessToken;
    let pins = config.pins || [];
    let selection = config.selection || null;
    let userLocation = config.userLocation || null;
    let map;
    let selectedMarker;
    let pinMarkers = [];
    let circleSource;
    let userMarker;

    function notify(type, payload) {
      const message = Object.assign({type:type, instanceId:config.instanceId}, payload || {});
      if (window.HexoraMapChannel && window.HexoraMapChannel.postMessage) {
        window.HexoraMapChannel.postMessage(JSON.stringify(message));
      } else if (window.parent) {
        window.parent.postMessage(JSON.stringify(message), '*');
      }
    }

    function circleCoordinates(lon, lat, radius) {
      const points = [];
      const earth = 6378137;
      const latRad = lat * Math.PI / 180;
      for (let i=0;i<=72;i++) {
        const angle = i * 2 * Math.PI / 72;
        const dLat = (radius / earth) * Math.sin(angle);
        const dLon = (radius / (earth * Math.cos(latRad))) * Math.cos(angle);
        points.push([lon + dLon * 180 / Math.PI, lat + dLat * 180 / Math.PI]);
      }
      return points;
    }

    function renderCircle() {
      if (!circleSource) return;
      circleSource.clear();
      if (!selection) return;
      circleSource.add(new atlas.data.Feature(new atlas.data.Polygon([
        circleCoordinates(selection.longitude, selection.latitude, selection.radiusMeters || 75)
      ])));
    }

    function renderSelection() {
      if (!map || !map.markers) return;
      if (selectedMarker) map.markers.remove(selectedMarker);
      selectedMarker = null;
      if (!selection) { renderCircle(); return; }
      selectedMarker = new atlas.HtmlMarker({
        position:[selection.longitude, selection.latitude],
        draggable:true,
        htmlContent:'<div class="selected-pin"></div>',
        anchor:'bottom'
      });
      map.markers.add(selectedMarker);
      map.events.add('dragend', selectedMarker, function () {
        const p = selectedMarker.getOptions().position;
        selection.latitude = p[1];
        selection.longitude = p[0];
        renderCircle();
        notify('hexora-map-selection', {latitude:p[1], longitude:p[0]});
      });
      renderCircle();
    }

    function renderPins() {
      if (!map || !map.markers) return;
      pinMarkers.forEach(function(marker){ map.markers.remove(marker); });
      pinMarkers = [];
      pins.forEach(function(pin){
        const marker = new atlas.HtmlMarker({
          position:[pin.longitude,pin.latitude],
          htmlContent:'<div class="pin"></div>',
          anchor:'bottom'
        });
        map.markers.add(marker);
        map.events.add('click', marker, function(){
          notify('hexora-map-pin', {id:pin.id});
        });
        pinMarkers.push(marker);
      });
    }

    function renderUserLocation() {
      if (!map || !map.markers) return;
      if (userMarker) map.markers.remove(userMarker);
      userMarker = null;
      if (!userLocation) return;
      userMarker = new atlas.HtmlMarker({
        position:[userLocation.longitude,userLocation.latitude],
        htmlContent:'<div class="user-location" title="Tu ubicación actual" aria-label="Tu ubicación actual"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4Zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4Z"/></svg></div>',
        anchor:'center'
      });
      map.markers.add(userMarker);
    }

    function setCamera(latitude, longitude, zoom) {
      if (!map) return;
      map.setCamera({center:[longitude,latitude],zoom:zoom || 17,duration:650,type:'ease'});
    }

    try {
      const center = selection
        ? [selection.longitude,selection.latitude]
        : userLocation
          ? [userLocation.longitude,userLocation.latitude]
          : pins.length ? [pins[0].longitude,pins[0].latitude] : [-3.7038,40.4168];
      map = new atlas.Map('map', {
        center:center,
        zoom:(selection || pins.length) ? 15 : 5,
        language:'es-ES',
        view:'Auto',
        style:'road',
        authOptions:{
          authType:'anonymous',
          clientId:config.clientId,
          getToken:function(resolve){ resolve(currentToken); }
        }
      });
      map.events.add('ready', function(){
        circleSource = new atlas.source.DataSource();
        map.sources.add(circleSource);
        map.layers.add(new atlas.layer.PolygonLayer(circleSource, null, {
          fillColor:'#3973ad',fillOpacity:0.16
        }));
        map.layers.add(new atlas.layer.LineLayer(circleSource, null, {
          strokeColor:'#2f659d',strokeWidth:2
        }));
        renderPins();
        renderUserLocation();
        renderSelection();
        map.events.add('click', function(event){
          if (!selection || !event.position) return;
          selection.latitude = event.position[1];
          selection.longitude = event.position[0];
          renderSelection();
          notify('hexora-map-selection', {latitude:event.position[1],longitude:event.position[0]});
        });
        notify('hexora-map-ready');
      });
      map.events.add('error', function(event){
        notify('hexora-map-error', {message:(event && event.error && event.error.message) || 'No se pudo cargar Azure Maps.'});
      });
      try {
        map.controls.add(new atlas.control.ZoomControl(), {position:'bottom-right'});
        map.controls.add(new atlas.control.StyleControl({mapStyles:['road','satellite','satellite_road_labels']}), {position:'top-right'});
      } catch (_) {
        // Controls are optional; the map and location picker remain usable.
      }
    } catch (error) {
      notify('hexora-map-error', {message:error && error.message ? error.message : 'No se pudo iniciar Azure Maps.'});
    }

    window.addEventListener('message', function(event){
      let data = event.data;
      if (typeof data === 'string') {
        try { data = JSON.parse(data); } catch (_) { return; }
      }
      if (!data || data.instanceId !== config.instanceId) return;
      if (data.action === 'token') currentToken = data.accessToken;
      if (data.action === 'pins') { pins = data.pins || []; renderPins(); }
      if (data.action === 'selection') { selection = data.selection || null; renderSelection(); }
      if (data.action === 'user-location') { userLocation = data.userLocation || null; renderUserLocation(); }
      if (data.action === 'camera') setCamera(data.latitude,data.longitude,data.zoom);
    });
  </script>
</body>
</html>''';
}
