import 'dart:async';

import 'package:flutter/services.dart';

class FlutterUnipayPlugin {

  // 方法调用信道名称
  static const String METHOD_CHANNEL_NAME = 'com.nbp.flutter_unipay_plugin';
  // 简单字符串消息传递信道名称
  static const String MESSAGE_CHANNEL_NAME = 'com.nbp.msg.flutter_unipay_plugin';
  // 支付结果
  static const String UP_PAY_SUCCESS = "0000";
  static const String UP_PAY_FAIL = "9999";
  static const String UP_PAY_EXCEPTION = "8888";
  static const String UP_PAY_DONE = "6666";
  static const String UP_PAY_CANCEL = "7777";
  // 支付结果报文json格式 { 'code':'' [, 'data':'', 'sign':'', 'error':''] }
  static const String UP_PAY_RESULT_K_CODE = 'code';
  static const String UP_PAY_RESULT_K_DATA = 'data';
  static const String UP_PAY_RESULT_K_SIGN = 'sign';
  static const String UP_PAY_RESULT_K_ERROR = 'error';

  static const MethodChannel _channel =
      const MethodChannel(METHOD_CHANNEL_NAME);

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future upPay(String tn, String mode) async {
    return await _channel.invokeMethod("upPay", {"up_pay_tn": tn, "up_pay_mode": mode});
  }
}
