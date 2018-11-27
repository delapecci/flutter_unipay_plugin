#import <Flutter/Flutter.h>

static FlutterBasicMessageChannel *msgChannel;

@interface FlutterUnipayPlugin : NSObject<FlutterPlugin>
@property (nonatomic, retain) UIViewController *viewController;
@end
