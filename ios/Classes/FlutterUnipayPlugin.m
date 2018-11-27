#import "FlutterUnipayPlugin.h"
#import "UPPaymentControl.h"


@implementation FlutterUnipayPlugin 
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"com.nbp.flutter_unipay_plugin"
            binaryMessenger:[registrar messenger]];
    msgChannel = [FlutterBasicMessageChannel messageChannelWithName:@"com.nbp.msg.flutter_unipay_plugin" binaryMessenger:[registrar messenger] codec: [FlutterStringCodec sharedInstance]];
    UIViewController *viewController  = (UIViewController *)registrar.messenger;
    FlutterUnipayPlugin* instance = [[FlutterUnipayPlugin alloc] initWithViewController:viewController];
    
    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate:instance];
}

- (instancetype)initWithViewController:(UIViewController *)viewController {
    self = [super init];
    if (self) {
        self.viewController = viewController;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ([@"upPay" isEqualToString:call.method]){
    [self startPayAction:call];
    result(nil);
  }else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)startPayAction:(FlutterMethodCall *)call {
    NSString *tnStr = call.arguments[@"up_pay_tn"];
    NSString *tnModeStr = call.arguments[@"up_pay_mode"];
    [[UPPaymentControl defaultControl] startPay:tnStr fromScheme:@"renpinhui" mode:tnModeStr viewController:self.viewController];
}

// UIApplicationDelegate 
- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    [[UPPaymentControl defaultControl] handlePaymentResult:url completeBlock:^(NSString *code, NSDictionary *data) {
        NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
        if([code isEqualToString:@"success"]) {
            if(data != nil){
                [payload setValue:@"0000" forKey:@"code"];
                [payload setValue:data[@"sign"] forKey:@"sign"];
                [payload setValue:data[@"data"] forKey:@"data"];
            } else {
                //结果code为成功时，去商户后台查询一下确保交易是成功的再展示成功
                [payload setValue:@"6666" forKey:@"code"];
            }
        }
        else if([code isEqualToString:@"fail"]) {
            //交易失败
            [payload setValue:@"9999" forKey:@"code"];
        }
        else if([code isEqualToString:@"cancel"]) {
            //交易取消
            [payload setValue:@"7777" forKey:@"code"];
        }
        NSData *payloadData = [NSJSONSerialization dataWithJSONObject:payload
                                                           options:0
                                                             error:nil];
        NSString *payloadMsg = [[NSString alloc] initWithData:payloadData encoding:NSUTF8StringEncoding];
        [msgChannel sendMessage:payloadMsg reply:^(id  _Nullable reply) {
            NSLog(@"%@", reply);
        }];
    }];
    
    return YES;
}

// NOTE: 9.0以后使用新API接口
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options
{
    [[UPPaymentControl defaultControl] handlePaymentResult:url completeBlock:^(NSString *code, NSDictionary *data) {
        
        NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
        if([code isEqualToString:@"success"]) {
            //如果想对结果数据验签，可使用下面这段代码，但建议不验签，直接去商户后台查询交易结果
            if(data != nil){
                [payload setValue:@"0000" forKey:@"code"];
                [payload setValue:data[@"sign"] forKey:@"sign"];
                [payload setValue:data[@"data"] forKey:@"data"];
            } else {
                //结果code为成功时，去商户后台查询一下确保交易是成功的再展示成功
                [payload setValue:@"6666" forKey:@"code"];
            }
        }
        else if([code isEqualToString:@"fail"]) {
            //交易失败
            [payload setValue:@"9999" forKey:@"code"];
        }
        else if([code isEqualToString:@"cancel"]) {
            //交易取消
            [payload setValue:@"7777" forKey:@"code"];
        }
        NSData *payloadData = [NSJSONSerialization dataWithJSONObject:payload
                                                              options:0
                                                                error:nil];
        NSString *payloadMsg = [[NSString alloc] initWithData:payloadData encoding:NSUTF8StringEncoding];
        [msgChannel sendMessage:payloadMsg reply:^(id  _Nullable reply) {
            NSLog(@"%@", reply);
        }];
    }];
    
    return YES;
}

@end
