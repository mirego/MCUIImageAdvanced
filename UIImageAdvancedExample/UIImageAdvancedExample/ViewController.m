//
//  ViewController.m
//  UIImageAdvancedExample
//
//  Created by Jean-Philippe Couture on 2013-03-07.
//  Copyright (c) 2013 Mirego, Inc. All rights reserved.
//

#import "ViewController.h"
#import "UIImage+Advanced.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.imageView setImage:[UIImage imageNamedRetina:@"CharlieBrown.png"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
