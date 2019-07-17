#import "RxFlutterPlugin.h"
#import <rx_flutter_plugin/rx_flutter_plugin-Swift.h>

@implementation RxFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftRxFlutterPlugin registerWithRegistrar:registrar];
}
@end
