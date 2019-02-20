//
//  dicomHelper.h
//  DTK
//
//  Created by Min Han on 2019/2/18.
//  Copyright © 2019 Luojm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

typedef void(^ImgBlock)(UIImage* image);
@interface dicomHelper : NSObject
// 加载文件
-(void)loadFiled:(NSString *)filePath;
//
-(void)getDicImage:(SInt32)frame withCenter:(Float64)Wcenter withWidth:(Float64)Wwidth withImg:(ImgBlock)imgBlock;

-(Float64)getWindowCenter;
-(Float64)getWindowWidth;
//
@end
NS_ASSUME_NONNULL_END
