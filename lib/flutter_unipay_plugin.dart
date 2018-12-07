import 'dart:async';

import 'package:flutter/services.dart';

/// 银联全渠道-手机控件支付 flutter插件
/// 
class FlutterUnipayPlugin {

  /// 方法调用信道名称
  static const String METHOD_CHANNEL_NAME = 'com.nbp.flutter_unipay_plugin';
  /// 简单字符串消息传递信道名称
  static const String MESSAGE_CHANNEL_NAME = 'com.nbp.msg.flutter_unipay_plugin';
  /// 支付结果: 正常
  static const String UP_PAY_SUCCESS = "0000";
  /// 支付结果: 失败
  static const String UP_PAY_FAIL = "9999";
  /// 支付结果: 异常发生
  static const String UP_PAY_EXCEPTION = "8888";
  /// 支付结果: 支付完成无结果
  static const String UP_PAY_DONE = "6666";
  /// 支付结果: 支付取消
  static const String UP_PAY_CANCEL = "7777";
  /// 支付结果报文json格式 { 'code':'' [, 'data':'', 'sign':'', 'error':''] }
  static const String UP_PAY_RESULT_K_CODE = 'code';
  /// 支付结果报文json格式 { 'code':'' [, 'data':'', 'sign':'', 'error':''] }
  static const String UP_PAY_RESULT_K_DATA = 'data';
  /// 支付结果报文json格式 { 'code':'' [, 'data':'', 'sign':'', 'error':''] }
  static const String UP_PAY_RESULT_K_SIGN = 'sign';
  /// 支付结果报文json格式 { 'code':'' [, 'data':'', 'sign':'', 'error':''] }
  static const String UP_PAY_RESULT_K_ERROR = 'error';

  /// 支付环境: "01" - 连接银联测试环境
  static const String UP_PAY_MODE_TEST = "01";
  /// 支付环境: "00" - 启动银联正式环境
  static const String UP_PAY_MODE_PROD = "00";

  static const MethodChannel _channel =
      const MethodChannel(METHOD_CHANNEL_NAME);

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// 发送交易请求流水号[tn]，接入[mode]对应的银联环境，进行支付
  /// 
  /// ```dart
  /// // 调用插件支付
  /// upPay("xxxxxxxxxxx", FlutterUnipayPlugin.UP_PAY_MODE_TEST);
  /// 
  /// // 监听支付结果
  /// const channel = BasicMessageChannel<String>(FlutterUnipayPlugin.MESSAGE_CHANNEL_NAME,
  ///   StringCodec());
  /// channel.setMessageHandler((String message) async {
  ///   print('支付结果: $message');
  ///   setState(() {
  ///     _payResult = message;
  ///   });
  ///   return '已收到支付结果';
  /// });
  /// ```
  static Future upPay(String tn, String mode) async {
    return await _channel.invokeMethod("upPay", {"up_pay_tn": tn, "up_pay_mode": mode});
  }
}
