#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "AwemeHeaders.h"
#import "DYYYManager.h"
#import "CityManager.h"

#import "DYYYBottomAlertView.h"
#import "DYYYManager.h"

#import "DYYYConstants.h"

%hook AWECommentMediaDownloadConfigLivePhoto

bool commentLivePhotoNotWaterMark = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCommentLivePhotoNotWaterMark"];

- (bool)needClientWaterMark {
	return commentLivePhotoNotWaterMark ? 0 : %orig;
}

- (bool)needClientEndWaterMark {
	return commentLivePhotoNotWaterMark ? 0 : %orig;
}

- (id)watermarkConfig {
	return commentLivePhotoNotWaterMark ? nil : %orig;
}

%end

%hook AWECommentImageModel
- (id)downloadUrl {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCommentNotWaterMark"]) {
		return self.originUrl;
	}
	return %orig;
}
%end

%hook _TtC33AWECommentLongPressPanelSwiftImpl37CommentLongPressPanelSaveImageElement

static BOOL isDownloadFlied = NO;

- (BOOL)elementShouldShow {
	BOOL DYYYForceDownloadEmotion = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYForceDownloadEmotion"];
	if (DYYYForceDownloadEmotion) {
		AWECommentLongPressPanelContext *commentPageContext = [self commentPageContext];
		AWECommentModel *selectdComment = [commentPageContext selectdComment];
		if (!selectdComment) {
			AWECommentLongPressPanelParam *params = [commentPageContext params];
			selectdComment = [params selectdComment];
		}
		AWEIMStickerModel *sticker = [selectdComment sticker];
		if (sticker) {
			AWEURLModel *staticURLModel = [sticker staticURLModel];
			NSArray *originURLList = [staticURLModel originURLList];
			if (originURLList.count > 0) {
				return YES;
			}
		}
	}
	return %orig;
}

- (void)elementTapped {
	BOOL DYYYForceDownloadEmotion = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYForceDownloadEmotion"];
	if (DYYYForceDownloadEmotion) {
		AWECommentLongPressPanelContext *commentPageContext = [self commentPageContext];
		AWECommentModel *selectdComment = [commentPageContext selectdComment];
		if (!selectdComment) {
			AWECommentLongPressPanelParam *params = [commentPageContext params];
			selectdComment = [params selectdComment];
		}
		AWEIMStickerModel *sticker = [selectdComment sticker];
		if (sticker) {
			AWEURLModel *staticURLModel = [sticker staticURLModel];
			NSArray *originURLList = [staticURLModel originURLList];
			if (originURLList.count > 0) {
				NSString *urlString = @"";
				if (isDownloadFlied) {
					urlString = originURLList[originURLList.count - 1];
					isDownloadFlied = NO;
				} else {
					urlString = originURLList[0];
				}

				NSURL *heifURL = [NSURL URLWithString:urlString];
				[DYYYManager downloadMedia:heifURL
						 mediaType:MediaTypeHeic
						completion:^(BOOL success){
						}];
				return;
			}
		}
	}
	%orig;
}
%end

%hook AWEPlayInteractionTimestampElement
- (id)timestampLabel {
    UILabel *label = %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableArea"]) {
        NSString *text = label.text;
        NSString *cityCode = self.model.cityCode;

        if (cityCode.length > 0) {
            NSString *cityName = [CityManager.sharedInstance getCityNameWithCode:cityCode];
            NSString *provinceName = [CityManager.sharedInstance getProvinceNameWithCode:cityCode];
           // 使用 GeoNames API
            if (!cityName || cityName.length == 0) {
                NSString *cacheKey = cityCode;
                
                static NSCache *geoNamesCache = nil;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    geoNamesCache = [[NSCache alloc] init];
                    geoNamesCache.name = @"com.dyyy.geonames.cache";
                    geoNamesCache.countLimit = 1000;
                });
                
                NSDictionary *cachedData = [geoNamesCache objectForKey:cacheKey];
                
                if (!cachedData) {
                    NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
                    NSString *geoNamesCacheDir = [cachesDir stringByAppendingPathComponent:@"DYYYGeoNamesCache"];
                    
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    if (![fileManager fileExistsAtPath:geoNamesCacheDir]) {
                        [fileManager createDirectoryAtPath:geoNamesCacheDir withIntermediateDirectories:YES attributes:nil error:nil];
                    }
                    
                    NSString *cacheFilePath = [geoNamesCacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", cacheKey]];
                    
                    if ([fileManager fileExistsAtPath:cacheFilePath]) {
                        cachedData = [NSDictionary dictionaryWithContentsOfFile:cacheFilePath];
                        if (cachedData) {
                            [geoNamesCache setObject:cachedData forKey:cacheKey];
                        }
                    }
                }
                
                if (cachedData) {
                    NSString *countryName = cachedData[@"countryName"];
                    NSString *adminName1 = cachedData[@"adminName1"];
                    NSString *localName = cachedData[@"name"];
                    NSString *displayLocation = @"未知";
                    
                    if (countryName.length > 0) {
                        if (adminName1.length > 0 && localName.length > 0 && 
                            ![countryName isEqualToString:@"中国"] && 
                            ![countryName isEqualToString:localName]) {
                            // 国外位置：国家 + 州/省 + 地点
                            displayLocation = [NSString stringWithFormat:@"%@ %@ %@", countryName, adminName1, localName];
                        } else if (localName.length > 0 && ![countryName isEqualToString:localName]) {
                            // 只有国家和地点名
                            displayLocation = [NSString stringWithFormat:@"%@ %@", countryName, localName];
                        } else {
                            // 只有国家名
                            displayLocation = countryName;
                        }
                    } else if (localName.length > 0) {
                        displayLocation = localName;
                    }
                  
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *currentText = label.text ?: @"";
                        
                        if ([currentText containsString:@"IP属地："]) {
                            NSRange range = [currentText rangeOfString:@"IP属地："];
                            if (range.location != NSNotFound) {
                                NSString *baseText = [currentText substringToIndex:range.location];
                                if (![currentText containsString:displayLocation]) {
                                    label.text = [NSString stringWithFormat:@"%@IP属地：%@", baseText, displayLocation];
                                }
                            }
                        } else {
                            NSString *baseText = label.text ?: @"";
                            if (baseText.length > 0) {
                                label.text = [NSString stringWithFormat:@"%@  IP属地：%@", baseText, displayLocation];
                            }
                        }
                    });
                } else {
                    [CityManager fetchLocationWithGeonameId:cityCode completionHandler:^(NSDictionary *locationInfo, NSError *error) {
                        if (locationInfo) {
                            NSString *countryName = locationInfo[@"countryName"];
                            NSString *adminName1 = locationInfo[@"adminName1"];  // 州/省级名称
                            NSString *localName = locationInfo[@"name"];         // 当前地点名称
                            NSString *displayLocation = @"未知";
                            
                            // 根据返回数据构建位置显示文本
                            if (countryName.length > 0) {
                                if (adminName1.length > 0 && localName.length > 0 && 
                                    ![countryName isEqualToString:@"中国"] && 
                                    ![countryName isEqualToString:localName]) {
                                    // 国外位置：国家 + 州/省 + 地点
                                    displayLocation = [NSString stringWithFormat:@"%@ %@ %@", countryName, adminName1, localName];
                                } else if (localName.length > 0 && ![countryName isEqualToString:localName]) {
                                    // 只有国家和地点名
                                    displayLocation = [NSString stringWithFormat:@"%@ %@", countryName, localName];
                                } else {
                                    // 只有国家名
                                    displayLocation = countryName;
                                }
                            } else if (localName.length > 0) {
                                displayLocation = localName;
                            }
       
                            [geoNamesCache setObject:locationInfo forKey:cacheKey];
                            
                            NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
                            NSString *geoNamesCacheDir = [cachesDir stringByAppendingPathComponent:@"DYYYGeoNamesCache"];
                            NSString *cacheFilePath = [geoNamesCacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", cacheKey]];
                            
                            [locationInfo writeToFile:cacheFilePath atomically:YES];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSString *currentText = label.text ?: @"";
                                
                                if ([currentText containsString:@"IP属地："]) {
                                    NSRange range = [currentText rangeOfString:@"IP属地："];
                                    if (range.location != NSNotFound) {
                                        NSString *baseText = [currentText substringToIndex:range.location];
                                        if (![currentText containsString:displayLocation]) {
                                            label.text = [NSString stringWithFormat:@"%@IP属地：%@", baseText, displayLocation];
                                        }
                                    }
                                } else {
                                    NSString *baseText = label.text ?: @"";
                                    if (baseText.length > 0) {
                                        label.text = [NSString stringWithFormat:@"%@  IP属地：%@", baseText, displayLocation];
                                    }
                                }
                            });
                        }
                    }];
                }
            } else if (![text containsString:cityName]) {;
                    }
                }
            }
        }

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnabsuijiyanse"]) {
		UIColor *color1 = [UIColor colorWithRed:(CGFloat)arc4random_uniform(256) / 255.0
						  green:(CGFloat)arc4random_uniform(256) / 255.0
						   blue:(CGFloat)arc4random_uniform(256) / 255.0
						  alpha:1.0];
		UIColor *color2 = [UIColor colorWithRed:(CGFloat)arc4random_uniform(256) / 255.0
						  green:(CGFloat)arc4random_uniform(256) / 255.0
						   blue:(CGFloat)arc4random_uniform(256) / 255.0
						  alpha:1.0];
		UIColor *color3 = [UIColor colorWithRed:(CGFloat)arc4random_uniform(256) / 255.0
						  green:(CGFloat)arc4random_uniform(256) / 255.0
						   blue:(CGFloat)arc4random_uniform(256) / 255.0
						  alpha:1.0];

		NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:label.text];
		CFIndex length = [attributedText length];
		for (CFIndex i = 0; i < length; i++) {
			CGFloat progress = (CGFloat)i / (length == 0 ? 1 : length - 1);

			UIColor *startColor;
			UIColor *endColor;
			CGFloat subProgress;

			if (progress < 0.5) {
				startColor = color1;
				endColor = color2;
				subProgress = progress * 2;
			} else {
				startColor = color2;
				endColor = color3;
				subProgress = (progress - 0.5) * 2;
			}

			CGFloat startRed, startGreen, startBlue, startAlpha;
			CGFloat endRed, endGreen, endBlue, endAlpha;
			[startColor getRed:&startRed green:&startGreen blue:&startBlue alpha:&startAlpha];
			[endColor getRed:&endRed green:&endGreen blue:&endBlue alpha:&endAlpha];

			CGFloat red = startRed + (endRed - startRed) * subProgress;
			CGFloat green = startGreen + (endGreen - startGreen) * subProgress;
			CGFloat blue = startBlue + (endBlue - startBlue) * subProgress;
			CGFloat alpha = startAlpha + (endAlpha - startAlpha) * subProgress;

			UIColor *currentColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
			[attributedText addAttribute:NSForegroundColorAttributeName value:currentColor range:NSMakeRange(i, 1)];
		}

		label.attributedText = attributedText;
	} else {
		NSString *labelColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLabelColor"];
		if (labelColor.length > 0) {
			label.textColor = [DYYYManager colorWithHexString:labelColor];
		}
	}
	return label; 

+ (BOOL)shouldActiveWithData:(id)arg1 context:(id)arg2 {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableArea"];
}

%end

// 强制启用保存他人头像
%hook AFDProfileAvatarFunctionManager
- (BOOL)shouldShowSaveAvatarItem {
	BOOL shouldEnable = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableSaveAvatar"];
	if (shouldEnable) {
		return YES;
	}
	return %orig;
}
%end

%hook AWEIMEmoticonPreviewV2

// 添加保存按钮
- (void)layoutSubviews {
	%orig;
	static char kHasSaveButtonKey;
	BOOL DYYYForceDownloadPreviewEmotion = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYForceDownloadPreviewEmotion"];
	if (DYYYForceDownloadPreviewEmotion) {
		if (!objc_getAssociatedObject(self, &kHasSaveButtonKey)) {
			UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
			UIImage *downloadIcon = [UIImage systemImageNamed:@"arrow.down.circle"];
			[saveButton setImage:downloadIcon forState:UIControlStateNormal];
			[saveButton setTintColor:[UIColor whiteColor]];
			saveButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.9 alpha:0.5];

			saveButton.layer.shadowColor = [UIColor blackColor].CGColor;
			saveButton.layer.shadowOffset = CGSizeMake(0, 2);
			saveButton.layer.shadowOpacity = 0.3;
			saveButton.layer.shadowRadius = 3;

			saveButton.translatesAutoresizingMaskIntoConstraints = NO;
			[self addSubview:saveButton];
			CGFloat buttonSize = 24.0;
			saveButton.layer.cornerRadius = buttonSize / 2;

			[NSLayoutConstraint activateConstraints:@[
				[saveButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-15], [saveButton.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-10],
				[saveButton.widthAnchor constraintEqualToConstant:buttonSize], [saveButton.heightAnchor constraintEqualToConstant:buttonSize]
			]];

			saveButton.userInteractionEnabled = YES;
			[saveButton addTarget:self action:@selector(dyyy_saveButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
			objc_setAssociatedObject(self, &kHasSaveButtonKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		}
	}
}

%new
- (void)dyyy_saveButtonTapped:(UIButton *)sender {
	// 获取表情包URL
	AWEIMEmoticonModel *emoticonModel = self.model;
	if (!emoticonModel) {
		[DYYYManager showToast:@"无法获取表情包信息"];
		return;
	}

	NSString *urlString = nil;
	MediaType mediaType = MediaTypeImage;

	// 尝试动态URL
	if ([emoticonModel valueForKey:@"animate_url"]) {
		urlString = [emoticonModel valueForKey:@"animate_url"];
	}
	// 如果没有动态URL，则使用静态URL
	else if ([emoticonModel valueForKey:@"static_url"]) {
		urlString = [emoticonModel valueForKey:@"static_url"];
	}
	// 使用animateURLModel获取URL
	else if ([emoticonModel valueForKey:@"animateURLModel"]) {
		AWEURLModel *urlModel = [emoticonModel valueForKey:@"animateURLModel"];
		if (urlModel.originURLList.count > 0) {
			urlString = urlModel.originURLList[0];
		}
	}

	if (!urlString) {
		[DYYYManager showToast:@"无法获取表情包链接"];
		return;
	}

	NSURL *url = [NSURL URLWithString:urlString];
	[DYYYManager downloadMedia:url
			 mediaType:MediaTypeHeic
			completion:^(BOOL success){
			}];
}

%end

%hook AWELongVideoControlModel
- (bool)allowDownload {
	return YES;
}
%end

%hook AWELongVideoControlModel
- (long long)preventDownloadType {
	return 0;
}
%end

%ctor {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
		%init;
	}
}
