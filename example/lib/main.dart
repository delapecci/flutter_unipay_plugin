import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_unipay_plugin/flutter_unipay_plugin.dart';

import 'package:dio/dio.dart';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _tn = '';
  String _payResult = '';

  @override
  void initState() {
    super.initState();
    initPlatformState();
    getTestTn();
    const channel = BasicMessageChannel<String>(FlutterUnipayPlugin.MESSAGE_CHANNEL_NAME,
        StringCodec());
    channel.setMessageHandler((String message) async {
//      Map<String, String> payResult = jsonDecode(message); // 解析返回报文(json)格式
      print('支付结果: $message');
      setState(() {
        _payResult = message;
      });
      return '已收到支付结果';
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await FlutterUnipayPlugin.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> getTestTn() async {
    Dio dio = new Dio();
    dio.options.connectTimeout = 120000;
    Response response = await dio.get("http://101.231.204.84:8091/sim/getacptn");
    if (!mounted) return;

    setState(() {
      _tn = response.data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Running on: $_platformVersion\n'),
              Text('Tx Seq No: $_tn\n'),
              Text('Pay Result: $_payResult\n'),
              new RaisedButton(
                onPressed: () {
                  FlutterUnipayPlugin.upPay(this._tn, "01");
                },
                child: const Text('Pay'),
              )
            ]
        )
      ),
    );
  }
}
