//
//  dicomHelper.m
//  DTK
//
//  Created by Min Han on 2019/2/18.
//  Copyright © 2019 Luojm. All rights reserved.
//

#import "dicomHelper.h"
#include <zlib.h>/* for zlibVersion() */
#include "dcmtk/include/dcmtk/config/osconfig.h"
#include "dctk.h"          /* for various dcmdata headers */
#include "cmdlnarg.h"      /* for prepareCmdLineArgs */
#include "dcuid.h"         /* for dcmtk version name */
#include "dcrledrg.h"      /* for DcmRLEDecoderRegistration */

#include "dcmimage.h"      /* for DicomImage */
#include "digsdfn.h"       /* for DiGSDFunction */
#include "diciefn.h"       /* for DiCIELABFunction */

#include "ofconapp.h"      /* for OFConsoleApplication */
#include "ofcmdln.h"       /* for OFCommandLine */

#include "diregist.h"      /* include to support color images */
#include "ofstd.h"         /* for OFStandard */
#include "dipitiff.h"     /* for dcmimage TIFF plugin */
#include "dipipng.h"      /* for dcmimage PNG plugin */

#include "ofstream.h"
#include "djdecode.h"
#include "dipijpeg.h"
#include "dipipng.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface dicomHelper ()
@property (nonatomic ,assign)DcmFileFormat *dcmFile;
@property (nonatomic ,assign)DcmDataset *dataSet;
@property (nonatomic ,assign)DicomImage *dicomImage;
@end

@implementation dicomHelper
-(instancetype)init{
    self = [super init];
    if (self) {
    }
    return self;
}
-(void)dealloc{
    /// 删除内存区域 释放内存
    delete _dcmFile;
//    delete _dataSet;
//    delete _dcmFile;
}
/// 加载影像文件
- (void)loadFiled:(NSString *)filePath{
    DcmDataDictionary &dict = dcmDataDict.wrlock();
    dict.loadDictionary([[[NSBundle mainBundle] pathForResource:@"private" ofType:@"dic"] cStringUsingEncoding:NSASCIIStringEncoding]);
    dcmDataDict.unlock();
    if (!dcmDataDict.isDictionaryLoaded()) {
        NSLog(@"Data dictionary not loaded");
    } else {
        NSLog(@"Data dictionary loaded!");
    }
//    DcmRLEDecoderRegistration::registerCodecs(OFFalse /*pCreateSOPInstanceUID*/, OFFalse);
//    DJDecoderRegistration::registerCodecs(EDC_never, EUC_default, EPC_default, OFFalse);
//
    self.dcmFile = new DcmFileFormat();
    OFCondition cond = self.dcmFile->loadFile([filePath cStringUsingEncoding:NSASCIIStringEncoding], EXS_Unknown, EGL_withoutGL, DCM_MaxReadLength, ERM_autoDetect);

    if (cond.bad()) {
        NSLog(@"Something wrong loading DCM file");
    }
    self.dataSet = self.dcmFile->getDataset();
    
    
    // TODO: 测试 打印的是什么
    const char *transferSyntax;
    DcmMetaInfo *dcmMetaInfo = self.dcmFile->getMetaInfo();
    OFCondition transferSyntaxOfCondition = dcmMetaInfo->findAndGetString(
                                                                          DCM_TransferSyntaxUID, transferSyntax);
    NSLog(@"transferSyntaxOfCondition  %s", transferSyntaxOfCondition.text());
    NSLog(@"transferSyntax  %s", transferSyntax);
    NSLog(@"-------#### %@", [self getSeriesUid]);
    NSLog(@"-------%@", [self getSeriesNumber]);
//    NSLog("123123")
//    NSLog("-------%@", [self getSeriesUid])
//    NSLog("-------$$$$$%@", [self getSeriesNumber])
}
/// 解析影像
-(void)getDicImage:(SInt32)frame withCenter:(Float64)Wcenter withWidth:(Float64)Wwidth withImg:(nonnull ImgBlock)imgBlock{
    DicomImage *img = [self getDicomImage:frame];
    if (img == NULL) {
        NSLog(@"Out of memory");
        return;
    }
    
    if (img->getStatus() != EIS_Normal)
    {
        const char *msg = DicomImage::getString(img->getStatus());
        NSLog(@"Some other error");
        //        OFLOG_FATAL(dcm2pnmLogger, DicomImage::getString(di->getStatus()));
        return;
    }
    /****/
    DcmStack stack;
    DcmObject *dobject = NULL;
    OFCondition status = self.dataSet->nextObject(stack, OFTrue);
    
    
    dobject = stack.top();
    
    /****/
    //const char *XferText = DcmXfer(xfer).getXferName();
    const char *SOPClassUID = NULL;
    const char *SOPInstanceUID = NULL;
    const char *SOPClassText = NULL;
    const char *colorModel;
    self.dataSet->findAndGetString(DCM_SOPClassUID, SOPClassUID);
    self.dataSet->findAndGetString(DCM_SOPInstanceUID, SOPInstanceUID);
    
    
    colorModel = img->getString(img->getPhotometricInterpretation());
    if (colorModel == NULL)
        colorModel = "unknown";
    if (SOPInstanceUID == NULL)
        SOPInstanceUID = "not present";
    if (SOPClassUID == NULL)
        SOPClassText = "not present";
    else
        SOPClassText = dcmFindNameOfUID(SOPClassUID);
    if (SOPClassText == NULL)
        SOPClassText = SOPClassUID;
    if (img->isMonochrome()) {
        NSLog(@"Is monochrome");
    }
    unsigned long count;
    
    //    di->hideAllOverlays();
    count = img->getWindowCount();
    //    di->setMinMaxWindow(1);
    if (Wwidth == 0 && Wcenter == 0) {
        img->setWindow([self getWindowCenter], [self getWindowWidth]);
    }else{
        img->setWindow(Wcenter, Wwidth);
    }
    NSLog(@"VOI windows in file %ld", count);
    int result = 0;
    
    NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *parentFolder = [cacheFolder stringByAppendingPathComponent:@"dicom"];
    
    NSString *filename = [NSString stringWithFormat:@"frame%d.jpg",frame];

    NSString *outputFile = [parentFolder stringByAppendingPathComponent:filename];
    FILE *ofile = fopen([outputFile cStringUsingEncoding:NSASCIIStringEncoding], "wb");
    DiJPEGPlugin plugin;
    plugin.setQuality(OFstatic_cast(unsigned int, 90));
    plugin.setSampling(ESS_422);
    result = img->writePluginFormat(&plugin, ofile, 0);
    fclose(ofile);
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:outputFile];
    NSLog(@"-------%@",outputFile);
    imgBlock(image);
    /// 释放内存
    delete img;
}
/*
-(void)getDicImage:(SInt32)frame withCenter:(Float64)Wcenter withWidth:(Float64)Wwidth withImg:(nonnull ImgBlock)imgBlock{
    DicomImage *img = [self getDicomImage:frame];
    if (img == nil) {
        return;
    }
    long height = img->getHeight();
    long width = img->getWidth();
    long depth = img->getDepth();
    long size = img->getOutputDataSize(8);
    if (Wcenter == 0 && Wwidth == 0) {
        img->setWindow([self getWindowCenter], [self getWindowWidth]);
    }else{
        img->setWindow(Wcenter, Wwidth);
    }
    NSLog(@"png height %ld ", height);
    NSLog(@"png width %ld ", width);
    NSLog(@"png depth %ld ", depth);
    NSLog(@"png size %ld ", size);
    NSLog(@"int size %ld",sizeof(int));
    
    unsigned char *pixelData = (unsigned char *) (img->getOutputData(8, 0, 0));

    long size1 = height * width;
    unsigned char temp = NULL;
    
    int * p = (int *)malloc(width * height * sizeof(int));
    //        int *p = new int[size1];
    
    if(strcmp([self getDicmFileModel].UTF8String,"SC") == 0){
        unsigned char r = NULL;
        unsigned char g = NULL;
        unsigned char b = NULL;
        for (int j = 0; j < size1; ++j) {
            r = pixelData[j * 3] ;
            g = pixelData[j * 3 + 1] ;
            b = pixelData[j * 3 + 2] ;
            p[j] = r  | g << 8 | b << 16 | 0xff000000;
        }
    }else{
        for (int i = 0; i < size1; ++i) {
            temp = pixelData[i];
            p[i] = temp | (temp << 8) | (temp << 16) | 0xff000000;
        }
    }
    if (pixelData != NULL) {
        NSLog(@"pixelData not null");
    }
    
    NSData *imgData = [NSData dataWithBytes:(Byte *)p length:size1 * sizeof(int)];
    
    // 释放内存
    free(pixelData);
    free(p);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)imgData);
    
    CGImageRef imageRef = CGImageCreate(width,             //width
                                        height,            //height
                                        8,                 //bits per component
                                        32,                //bits per pixel
                                        width*4,           //bytesPerRow
                                        colorSpace,        //colorspace
                                        kCGImageAlphaNone | kCGImageAlphaNoneSkipLast,        //kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder16Little,// bitmap info
                                        provider,               //CGDataProviderRef
                                        NULL,                   //decode
                                        true,                  //should interpolate
                                        kCGRenderingIntentDefault   //intent
                                        );
    
//    if (isInverse) {
//        UIImage *testImage = [UIImage imageWithCGImage:imageRef];
    
//        CGImageRelease(imageRef);
//        CGDataProviderRelease(provider);
//        CGColorSpaceRelease(colorSpace);
//        return testImage;
//    }
    
    size_t                  bytesPerRow;
    bytesPerRow = CGImageGetBytesPerRow(imageRef);
//
    CFDataRef   data;
    UInt8*      buffer;
    data = CGDataProviderCopyData(provider);
    buffer = (UInt8*)CFDataGetBytePtr(data);
    UIImage *testImage = [UIImage imageWithCGImage:imageRef];
    imgBlock(testImage);

    // 返回当前的img 数据
//    dicom(testImage, width, height);
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    CFRelease(data);
}
 */
///获取指定帧的影像对象
-(DicomImage*)getDicomImage:(Sint32)frameNumber{
    E_TransferSyntax xfer = self.dataSet->getOriginalXfer();
    DJDecoderRegistration::registerCodecs();
//    DicomImage *dicomImage = new DicomImage(self.dcmFile, xfer, CIF_CheckLutBitDepth, frameNumber,[self getDicmFileFrameNumber]);
//    _dicomImage = 0;
//    delete _dicomImage;
    _dicomImage = new DicomImage(self.dcmFile, xfer);
    
    DJDecoderRegistration::cleanup();
//    NSLog(@"-----%p",_dicomImage);
    if (_dicomImage == NULL) {
        NSLog(@"Out of memory");
        return nil;
    }
    return _dicomImage;
}

/// 获取文件影像帧数
-(Sint32)getDicmFileFrameNumber{
   Sint32 frameCount;
    
    if (self.dataSet->findAndGetSint32(DCM_NumberOfFrames, frameCount).bad()) {
        frameCount = 1;
    }
    return frameCount;
}
/// 获取i影像患者名称
-(NSString *)getpatientName{
    OFString patientName;
    OFCondition condition = self.dataSet->findAndGetOFString(DCM_PatientName, patientName);
    if (condition.good()) {
        return [NSString stringWithUTF8String:patientName.c_str()];
    }else{
        return @"NULL";
    }
}
/// 获取窗位
-(Float64)getWindowCenter{
    Float64 windowCenter;
    self.dataSet->findAndGetFloat64(DCM_WindowCenter, windowCenter);
    return windowCenter;
}
/// 获取窗宽
-(Float64)getWindowWidth{
    Float64 windowWidth;
    self.dataSet->findAndGetFloat64(DCM_WindowWidth, windowWidth);
    return windowWidth;
}
/// 获取文件影像类型 eg.CT SR...
-(NSString *)getDicmFileModel{
    const char * model;
    self.dataSet->findAndGetString(DCM_Modality, model);
    return  [NSString stringWithUTF8String:model];
}
-(NSString*)getSeriesNumber{
    const char * model;
    self.dataSet->findAndGetString(DCM_SeriesNumber, model);
    return  [NSString stringWithUTF8String:model];
}
-(NSString*)getSeriesUid{
    const char * model;
    self.dataSet->findAndGetString(DCM_SeriesInstanceUID, model);
    return  [NSString stringWithUTF8String:model];
}
@end
