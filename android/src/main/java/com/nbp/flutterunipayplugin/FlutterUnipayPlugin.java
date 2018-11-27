package com.nbp.flutterunipayplugin;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.util.Log;

import com.unionpay.UPPayAssistEx;

import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.JSONUtil;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.StringCodec;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONStringer;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

/**
 * FlutterUnipayPlugin
 */
public class FlutterUnipayPlugin implements MethodCallHandler, PluginRegistry.ActivityResultListener {

    //***************************************************************************************//
    // Plugin Interface Contract for all clients
    //
    //***************************************************************************************//
    public static final String CHANNEL_NAME = "com.nbp.flutter_unipay_plugin";
    public static final String MSG_CHANNEL_NAME = "com.nbp.msg.flutter_unipay_plugin";
    public static final String UP_PAY_SUCCESS = "0000";
    public static final String UP_PAY_FAIL = "9999";
    public static final String UP_PAY_EXCEPTION = "8888";
    public static final String UP_PAY_DONE = "6666";
    public static final String UP_PAY_CANCEL = "7777";



    private static final String LOG_TAG = "FlutterUnipayPlugin";
    private static final int PLUGIN_VALID = 0;
    private static final int PLUGIN_NOT_INSTALLED = -1;
    private static final int PLUGIN_NEED_UPGRADE = 2;

    private Activity activity;
    static MethodChannel channel;
    static BasicMessageChannel<String> stringMsgChannel;

    /*****************************************************************
     * mMode参数解释： "00" - 启动银联正式环境 "01" - 连接银联测试环境
     *****************************************************************/
    private String mMode = "01";

    private FlutterUnipayPlugin(Activity activity) {
        this.activity = activity;
    }

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        channel = new MethodChannel(registrar.messenger(), CHANNEL_NAME);
        stringMsgChannel = new BasicMessageChannel<>(
                registrar.view(), MSG_CHANNEL_NAME, StringCodec.INSTANCE);
        final FlutterUnipayPlugin instance = new FlutterUnipayPlugin(registrar.activity());
        registrar.addActivityResultListener(instance);
        channel.setMethodCallHandler(instance);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {

        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;
            case "upPay":
                unPay(call, result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void unPay(MethodCall call, MethodChannel.Result result) {
        // With given arguments in call, start up Unipay prepare
        final String tn = call.argument("up_pay_tn");
        // mMode参数解释：
        // 0 - 启动银联正式环境
        // 1 - 连接银联测试环境
        final String argMode = call.argument("up_pay_mode");
        if (argMode != null) this.mMode = argMode;
        int ret = UPPayAssistEx.startPay(this.activity, null, null, tn, this.mMode);
        if (ret == PLUGIN_NEED_UPGRADE || ret == PLUGIN_NOT_INSTALLED) {
            // 需要重新安装控件
            Log.e(LOG_TAG, " plugin not found or need upgrade!!!");

            AlertDialog.Builder builder = new AlertDialog.Builder(this.activity);
            builder.setTitle("提示");
            builder.setMessage("完成购买需要安装银联支付控件，是否安装？");

            final Context ctx = this.activity;

            builder.setNegativeButton("确定",
                    new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            UPPayAssistEx.installUPPayPlugin(ctx);
                            dialog.dismiss();
                        }
                    });

            builder.setPositiveButton("取消",
                    new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            dialog.dismiss();
                        }
                    });
            builder.create().show();

        }
    }

    @Override
    public boolean onActivityResult(int i, int i1, Intent data) {
        /*************************************************
         * 步骤3：处理银联手机支付控件返回的支付结果
         ************************************************/
        if (data == null) {
            return true;
        }

        Map<String, String> payload = new HashMap<>();
        /*
         * 支付控件返回字符串:success、fail、cancel 分别代表支付成功，支付失败，支付取消
         */
        String str = data.getExtras().getString("pay_result");
        if (str.equalsIgnoreCase("success")) {

            // 如果想对结果数据验签，可使用下面这段代码，但建议不验签，直接去商户后台查询交易结果
            // result_data结构见c）result_data参数说明
            if (data.hasExtra("result_data")) {
                String result = data.getExtras().getString("result_data");
                try {
                    JSONObject resultJson = new JSONObject(result);
                    String sign = resultJson.getString("sign");
                    String dataOrg = resultJson.getString("data");
                    // 此处的verify建议送去商户后台做验签
                    // 如要放在手机端验，则代码必须支持更新证书
                    boolean ret = verify(dataOrg, sign, this.mMode);
                    if (ret) {
                        // 验签成功，显示支付结果
                        payload.put("code", UP_PAY_SUCCESS);
                        payload.put("data", dataOrg );
                        payload.put("sign", sign);
                    } else {
                        // 验签失败
                        payload.put("code", UP_PAY_FAIL);
                    }
                } catch (JSONException e) {
                    payload.put("code", UP_PAY_EXCEPTION);
                }
            } else {
                // TODO: 结果result_data为成功时，去商户后台查询一下再展示成功
                payload.put("code", UP_PAY_DONE);
            }
        } else if (str.equalsIgnoreCase("fail")) {
            payload.put("code", UP_PAY_FAIL);
        } else if (str.equalsIgnoreCase("cancel")) {
            payload.put("code", UP_PAY_CANCEL);
        }
        final JSONObject payloadJson = new JSONObject(payload);
        stringMsgChannel.send(payloadJson.toString(), new BasicMessageChannel.Reply<String>() {
            @Override
            public void reply(String s) {
                Log.i(LOG_TAG, "收到Dart端响应" + String.valueOf(s));
            }
        });

        return true;
    }

    private boolean verify(String msg, String sign64, String mode) {
        // TODO: Send message signature to backend and verify it
        return true;
    }
}
