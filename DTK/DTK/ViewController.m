//
//  ViewController.m
//  DTK
//
//  Created by Min Han on 2018/12/4.
//  Copyright © 2018 Luojm. All rights reserved.
//

#import "ViewController.h"
#import "dicomHelper.h"

@interface ViewController ()

@property (nonatomic ,strong)dicomHelper *util;

@property (nonatomic ,assign)double center;
@property (nonatomic ,assign)double width;
@property (nonatomic ,strong)UILabel *textl;

@end

@implementation ViewController
{
    UIImageView *imageView;
}
- (void)viewDidLoad {
    [super viewDidLoad];
//    [DicomUtil test];
    imageView = [[UIImageView alloc] init];
    imageView.frame = CGRectMake(0, 120, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
    [self.view addSubview:imageView];
    
    self.textl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(imageView.frame), [UIScreen mainScreen].bounds.size.width, 50)];
    
    [self.view addSubview:self.textl];
    
    
//    __block typeof(self) blockSelf = self;
//    __weak typeof(self) weakSelf = self;
//    __block BOOL flag  = YES;
//    self.util.Block = ^(double width, double center) {
//        if (flag == YES) {
//            flag = false;
//            blockSelf.center = center;
//            blockSelf.width = width;
//
//            weakSelf.textl.text = [NSString stringWithFormat:@"WW:%.0f ,WL:%.0f",blockSelf.width,blockSelf.center];
//        }
//    };
    [self.util loadFiled:[[NSBundle mainBundle] pathForResource:@"12" ofType:@"dcm"]];
    
    self.center = [self.util getWindowCenter];
    self.width = [self.util getWindowWidth];
    self.textl.text = [NSString stringWithFormat:@"WW:%.0f ,WL:%.0f",self.width,self.center];
    __block typeof(imageView) blockImg = imageView;
    [self.util getDicImage:1 withCenter:0 withWidth:0 withImg:^(UIImage * _Nonnull image) {
        blockImg.image = image;
    }];
    
    
//    UIImageView *imageView = [UIImageView alloc] ini
    imageView.userInteractionEnabled = false;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    

    
//    NSArray *fullPath = [DicomUtil ];
    
//     [DicomUtil extractAllFrames];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [self.view addGestureRecognizer:pan];
    
//
//    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
//    btn.backgroundColor = [UIColor redColor];
//    [self.view addSubview:btn];
//    [btn addTarget:self action:@selector(benAction) forControlEvents:UIControlEventTouchUpInside];
}
-(void)panAction:(UIPanGestureRecognizer*)pan{
    CGPoint point = [pan translationInView:pan.view];
    if (pan.state == UIGestureRecognizerStateChanged || pan.state == UIGestureRecognizerStateBegan) {
//        CGPoint point = [pan translationInView:pan.view];
        double width = self.width +  point.y;
        double center = self.center + point.x;
        NSLog(@"begin________________%@",NSStringFromCGPoint(CGPointMake(width, center)));

        self.textl.text = [NSString stringWithFormat:@"WW:%f ,WL:%f",width,center];
        __block typeof(imageView) blockImg = imageView;
         [self.util getDicImage:1 withCenter:center withWidth:width withImg:^(UIImage * _Nonnull image) {
             blockImg.image = image;
        }];

    }else if( pan.state == UIGestureRecognizerStateEnded){
        self.width = self.width + point.y;
        self.center = self.center + point.x;
        NSLog(@"end_______________%@",NSStringFromCGPoint(CGPointMake(self.width, self.center)));
        self.textl.text = [NSString stringWithFormat:@"WW:%f ,WL:%f",self.width,self.center];
        __block typeof(imageView) blockImg = imageView;
        [self.util getDicImage:1 withCenter: self.center withWidth:self.width withImg:^(UIImage * _Nonnull image) {
            blockImg.image = image;
        }];

    }
}
-(dicomHelper *)util{
    if (!_util) {
        _util  = [[dicomHelper alloc] init];
    }
    return _util;
}
-(void)dealloc{
    NSLog(@"销毁");
}

//-(void)benAction{
////    ViewController *vc = [[ViewController alloc] init];
////    [self presentViewController:vc animated:YES completion:nil];
//    [self dismissViewControllerAnimated:YES completion:nil];
//}
@end
