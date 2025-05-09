#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CityManager : NSObject
  
@property (nonatomic, strong) NSDictionary *cityCodeMap;

+ (instancetype)sharedInstance;

- (nullable NSString *)getProvinceNameWithCode:(NSString *)code;
- (nullable NSString *)getCityNameWithCode:(NSString *)code;
- (nullable NSString *)getDistrictNameWithCode:(NSString *)code;
- (nullable NSString *)getStreetNameWithCode:(NSString *)code;
+ (instancetype)sharedInstance;
- (void)loadCityData;
+ (void)fetchLocationWithGeonameId:(NSString *)geonameId completionHandler:(void (^)(NSDictionary *locationInfo, NSError *error))completionHandler;
@end




NS_ASSUME_NONNULL_END
