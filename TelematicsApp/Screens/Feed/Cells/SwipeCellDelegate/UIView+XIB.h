//
//  UIView+XIB.h
//  TelematicsApp
//
//  Created by DATA MOTION PTE. LTD. on 11.09.21.
//  Copyright © 2021 DATA MOTION PTE. LTD. All rights reserved.
//

@import UIKit;

@interface UIView (XIB)

+ (instancetype)initFromNib;
+ (instancetype)initWithNib:(NSString *)nibName bundle:(NSBundle *)bundle;

@end
