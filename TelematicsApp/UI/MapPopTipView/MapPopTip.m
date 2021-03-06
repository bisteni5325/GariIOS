//
//  MapPopTip.m
//  TelematicsApp
//
//  Created by DATA MOTION PTE. LTD. on 04.09.20.
//  Copyright © 2021 DATA MOTION PTE. LTD. All rights reserved.
//

#import "MapPopTip.h"
#import "MapPopTipDefaults.h"
#import "MapPopTip+Draw.h"
#import "MapPopTip+Entrance.h"
#import "MapPopTip+Exit.h"
#import "MapPopTip+Animation.h"

@interface MapPopTip()

@property (nonatomic, strong) NSString                          *text;
@property (nonatomic, strong) NSAttributedString                *attributedText;
@property (nonatomic, strong) NSMutableParagraphStyle           *paragraphStyle;
@property (nonatomic, strong) UITapGestureRecognizer            *gestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer            *tapRemoveGesture;
@property (nonatomic, strong) UISwipeGestureRecognizer          *swipeRemoveGesture;
@property (nonatomic, strong) NSTimer                           *dismissTimer;
@property (nonatomic, weak, readwrite) UIView                   *containerView;
@property (nonatomic, assign, readwrite) MapPopTipDirection     direction;
@property (nonatomic, assign, readwrite) CGPoint                arrowPosition;
@property (nonatomic, assign, readwrite) BOOL                   isVisible;
@property (nonatomic, assign, readwrite) BOOL                   isAnimating;
@property (nonatomic, assign) CGRect                            textBounds;
@property (nonatomic, assign) CGFloat                           maxWidth;
@property (nonatomic, strong) UIView                            *customView;
@property (nonatomic, strong, readwrite) UIView                 *backgroundMask;

@end

@implementation MapPopTip

+ (instancetype)popTip {
    return [[MapPopTip alloc] init];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)ignoredFrame {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (nullable UIView *)backgroundMask{
    if (!self.shouldShowMask) {
        [_backgroundMask removeFromSuperview];
        return nil;
    }
    if (_backgroundMask == nil) {
        _backgroundMask = [[UIView alloc] initWithFrame:self.containerView.bounds];
        _backgroundMask.alpha = 0.6;
        _backgroundMask.backgroundColor = self.maskColor;
    }
    return _backgroundMask;
}

- (void)commonInit {
    _paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    _textAlignment = NSTextAlignmentCenter;
    _font = kDefaultFont;
    _textColor = kDefaultTextColor;
    _popoverColor = kDefaultBackgroundColor;
    _borderColor = kDefaultBorderColor;
    _borderWidth = kDefaultBorderWidth;
    _radius = kDefaultRadius;
    _padding = kDefaultPadding;
    _arrowSize = kDefaultArrowSize;
    _animationIn = kDefaultAnimationIn;
    _animationOut = kDefaultAnimationOut;
    _shouldDismissOnTapOutside = YES;
    _edgeMargin = kDefaultEdgeMargin;
    _edgeInsets = kDefaultEdgeInsets;
    _rounded = NO;
    _offset = kDefaultOffset;
    _entranceAnimation = MapPopTipEntranceAnimationScale;
    _exitAnimation = MapPopTipExitAnimationScale;
    _actionAnimation = MapPopTipActionAnimationNone;
    _actionFloatOffset = kDefaultFloatOffset;
    _actionBounceOffset = kDefaultBounceOffset;
    _actionPulseOffset = kDefaultPulseOffset;
    _actionAnimationIn = kDefaultBounceAnimationIn;
    _actionAnimationOut = kDefaultBounceAnimationOut;
    _bubbleOffset = kDefaultBubbleOffset;
    _shouldShowMask = NO;
    _maskColor = kDefaultMaskColor;

    _tapRemoveGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRemoveGestureHandler)];
    _swipeRemoveGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRemoveGestureHandler)];
}

- (BOOL)isVisible {
    return self.superview != nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)setup {
    if (self.direction == MapPopTipDirectionLeft) {
        self.maxWidth = MIN(self.maxWidth, self.fromFrame.origin.x - self.padding * 2 - self.edgeInsets.left - self.edgeInsets.right - self.arrowSize.width);
    }
    
    if (self.direction == MapPopTipDirectionRight) {
        self.maxWidth = MIN(self.maxWidth, self.containerView.bounds.size.width - self.fromFrame.origin.x - self.fromFrame.size.width - self.padding * 2 - self.edgeInsets.left - self.edgeInsets.right - self.arrowSize.width);
    }

    if (self.text != nil) {
        self.textBounds = [self.text boundingRectWithSize:(CGSize){self.maxWidth, DBL_MAX }
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:@{NSFontAttributeName: self.font}
                                                  context:nil];
    } else if (self.attributedText != nil) {
        self.textBounds = [self.attributedText boundingRectWithSize:(CGSize){self.maxWidth, DBL_MAX }
                                                            options:NSStringDrawingUsesLineFragmentOrigin
                                                            context:nil];
    } else if (self.customView != nil) {
        self.textBounds = self.customView.frame;
    }

    _textBounds.origin = (CGPoint){self.padding + self.edgeInsets.left, self.padding + self.edgeInsets.top};

    CGRect frame = CGRectZero;
    float offset = self.offset * ((self.direction == MapPopTipDirectionUp || self.direction == MapPopTipDirectionLeft || self.direction == MapPopTipDirectionNone) ? -1 : 1);

    if (self.direction == MapPopTipDirectionUp || self.direction == MapPopTipDirectionDown) {
        frame.size = (CGSize){self.textBounds.size.width + self.padding * 2.0 + self.edgeInsets.left + self.edgeInsets.right, self.textBounds.size.height + self.padding * 2.0 + self.edgeInsets.top + self.edgeInsets.bottom + self.arrowSize.height};

        CGFloat x = self.fromFrame.origin.x + self.fromFrame.size.width / 2 - frame.size.width / 2;
        if (x < 0) { x = self.edgeMargin; }
        if (x + frame.size.width > self.containerView.bounds.size.width) { x = self.containerView.bounds.size.width - frame.size.width - self.edgeMargin; }
        if (self.direction == MapPopTipDirectionDown) {
            frame.origin = (CGPoint){ x, self.fromFrame.origin.y + self.fromFrame.size.height };
        } else {
            if ([Configurator sharedInstance].needEventsReviewButton)
                frame.origin = (CGPoint){ x, self.fromFrame.origin.y - frame.size.height - 50};
            else
                frame.origin = (CGPoint){ x, self.fromFrame.origin.y - frame.size.height};
        }

        frame.origin.y += offset;
        
        
        CGFloat yPoint = (self.direction == MapPopTipDirectionUp) ? frame.size.height : self.fromFrame.origin.y + self.fromFrame.size.height - frame.origin.y + offset;
        CGPoint arrowPosition = (CGPoint){ self.fromFrame.origin.x + self.fromFrame.size.width / 2 - frame.origin.x, yPoint };
        
        if (self.bubbleOffset > 0 && arrowPosition.x < self.bubbleOffset) {
            self.bubbleOffset = arrowPosition.x - self.arrowSize.width;
        } else if (self.bubbleOffset < 0 && frame.size.width < fabs(self.bubbleOffset)) {
            self.bubbleOffset = -(arrowPosition.x - self.arrowSize.width);
        } else if (self.bubbleOffset < 0 && (frame.origin.x - arrowPosition.x) < fabs(self.bubbleOffset)) {
            self.bubbleOffset = -(self.arrowSize.width + self.edgeMargin);
        }
        
        
        CGFloat leftSpace = frame.origin.x - self.containerView.frame.origin.x;
        CGFloat rightSpace = self.containerView.frame.size.width - leftSpace - frame.size.width;
        
        if (self.bubbleOffset < 0 && leftSpace < fabs(self.bubbleOffset)) {
            self.bubbleOffset = -leftSpace + self.edgeMargin;
        } else if (self.bubbleOffset > 0 && rightSpace < self.bubbleOffset) {
            self.bubbleOffset = rightSpace - self.edgeMargin;
        }
        
        frame.origin.x += self.bubbleOffset;

    } else if (self.direction == MapPopTipDirectionLeft || self.direction == MapPopTipDirectionRight) {
        frame.size = (CGSize){ self.textBounds.size.width + self.padding * 2.0 + self.edgeInsets.left + self.edgeInsets.right + self.arrowSize.height, self.textBounds.size.height + self.padding * 2.0 + self.edgeInsets.top + self.edgeInsets.bottom};

        CGFloat x = 0;
        if (self.direction == MapPopTipDirectionLeft) {
            x = self.fromFrame.origin.x - frame.size.width;
        }
        if (self.direction == MapPopTipDirectionRight) {
            x = self.fromFrame.origin.x + self.fromFrame.size.width;
        }

        x += offset;

        CGFloat y = self.fromFrame.origin.y + self.fromFrame.size.height / 2 - frame.size.height / 2;

        if (y < 0) { y = self.edgeMargin; }
        if (y + frame.size.height > self.containerView.bounds.size.height) { y = self.containerView.bounds.size.height - frame.size.height - self.edgeMargin; }
        frame.origin = (CGPoint){ x, y };
        
        
        CGFloat xPoint = (self.direction == MapPopTipDirectionLeft) ? self.fromFrame.origin.x - frame.origin.x + offset : self.fromFrame.origin.x + self.fromFrame.size.width - frame.origin.x + offset;
        
        CGPoint arrowPosition = (CGPoint){ xPoint, self.fromFrame.origin.y + self.fromFrame.size.height / 2 - frame.origin.y };
        
        if (self.bubbleOffset > 0 && arrowPosition.y < self.bubbleOffset) {
            self.bubbleOffset = arrowPosition.y - self.arrowSize.width;
        } else if (self.bubbleOffset < 0 && frame.size.height < fabs(self.bubbleOffset)) {
            self.bubbleOffset = -(arrowPosition.y - self.arrowSize.height);
        }
        
        
        CGFloat topSpace = frame.origin.y - self.containerView.frame.origin.y;
        CGFloat bottomSpace = self.containerView.frame.size.height - topSpace - frame.size.height;
        
        if (self.bubbleOffset < 0 && topSpace < fabs(self.bubbleOffset)) {
            self.bubbleOffset = -topSpace + self.edgeMargin;
        } else if (self.bubbleOffset > 0 && bottomSpace < self.bubbleOffset) {
            self.bubbleOffset = bottomSpace - self.edgeMargin;
        }
        
        frame.origin.y += self.bubbleOffset;
        
    } else {
        frame.size = (CGSize){ self.textBounds.size.width + self.padding * 2.0 + self.edgeInsets.left + self.edgeInsets.right, self.textBounds.size.height + self.padding * 2.0 + self.edgeInsets.top + self.edgeInsets.bottom };
        frame.origin = (CGPoint){ CGRectGetMidX(self.fromFrame) - frame.size.width / 2, CGRectGetMidY(self.fromFrame) - frame.size.height / 2 + offset };
    }

    if ([Configurator sharedInstance].needEventsReviewButton)
        frame.size = (CGSize){ frame.size.width + self.borderWidth * 2, frame.size.height + self.borderWidth * 2 + 50};
    else
        frame.size = (CGSize){ frame.size.width + self.borderWidth * 2, frame.size.height + self.borderWidth * 2};

    switch (self.direction) {
        case MapPopTipDirectionNone: {
            self.arrowPosition = CGPointZero;
            self.layer.anchorPoint = (CGPoint){ 0.5, 0.5 };
            self.layer.position = (CGPoint){ CGRectGetMidX(self.fromFrame), CGRectGetMidY(self.fromFrame) };
            break;
        }
        case MapPopTipDirectionDown: {
            self.arrowPosition = (CGPoint){
                self.fromFrame.origin.x + self.fromFrame.size.width / 2 - frame.origin.x,
                self.fromFrame.origin.y + self.fromFrame.size.height - frame.origin.y + offset
            };
            CGFloat anchor = self.arrowPosition.x / frame.size.width;
            _textBounds.origin = (CGPoint){ self.textBounds.origin.x, self.textBounds.origin.y + self.arrowSize.height };
            self.layer.anchorPoint = (CGPoint){ anchor, 0 };
            self.layer.position = (CGPoint){ self.layer.position.x + frame.size.width * anchor, self.layer.position.y - frame.size.height / 2 };

            break;
        }
        case MapPopTipDirectionUp: {
            self.arrowPosition = (CGPoint){
                self.fromFrame.origin.x + self.fromFrame.size.width / 2 - frame.origin.x,
                frame.size.height
            };
            CGFloat anchor = self.arrowPosition.x / frame.size.width;
            self.layer.anchorPoint = (CGPoint){ anchor, 1 };
            self.layer.position = (CGPoint){ self.layer.position.x + frame.size.width * anchor, self.layer.position.y + frame.size.height / 2 };

            break;
        }
        case MapPopTipDirectionLeft: {
            self.arrowPosition = (CGPoint){
                self.fromFrame.origin.x - frame.origin.x + offset,
                self.fromFrame.origin.y + self.fromFrame.size.height / 2 - frame.origin.y
            };
            CGFloat anchor = self.arrowPosition.y / frame.size.height;
            self.layer.anchorPoint = (CGPoint){ 1, anchor };
            self.layer.position = (CGPoint){ self.layer.position.x - frame.size.width / 2, self.layer.position.y + frame.size.height * anchor };

            break;
        }
        case MapPopTipDirectionRight: {
            self.arrowPosition = (CGPoint){
                self.fromFrame.origin.x + self.fromFrame.size.width - frame.origin.x + offset,
                self.fromFrame.origin.y + self.fromFrame.size.height / 2 - frame.origin.y
            };
            _textBounds.origin = (CGPoint){ self.textBounds.origin.x + self.arrowSize.height, self.textBounds.origin.y };
            CGFloat anchor = self.arrowPosition.y / frame.size.height;
            self.layer.anchorPoint = (CGPoint){ 0, anchor };
            self.layer.position = (CGPoint){ self.layer.position.x + frame.size.width / 2, self.layer.position.y + frame.size.height * anchor };

            break;
        }
    }

    self.backgroundColor = [UIColor clearColor];
    self.frame = frame;

    if (self.customView) {
        self.customView.frame = self.textBounds;
    }
    
    if ([Configurator sharedInstance].needEventsReviewButton) {
        UIButton *wrButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [wrButton addTarget:self action:@selector(submitNotEventMethod:) forControlEvents:UIControlEventTouchUpInside];
        [wrButton setTitle:localizeString(@"Review") forState:UIControlStateNormal];
        [wrButton setBackgroundColor:[Color officialOrangeColor]];
        wrButton.layer.cornerRadius = 20;
        wrButton.layer.masksToBounds = YES;
        wrButton.titleLabel.font = [Font medium14];
        wrButton.frame = CGRectMake(self.customView.frame.size.width/2 - 59.0, 160.0, self.customView.frame.size.width, 40.0);
        [self.customView.superview addSubview:wrButton];
    }
    
    self.gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.gestureRecognizer setCancelsTouchesInView:NO];
    [self addGestureRecognizer:self.gestureRecognizer];
    [self setNeedsDisplay];
}

- (void)submitNotEventMethod:(id)sender {
    if (self.wrongEventTapHandler) {
        self.wrongEventTapHandler();
    }
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (self.shouldDismissOnTap) {
        [self hide];
    }
    if (self.tapHandler) {
        self.tapHandler();
    }
}

- (void)tapRemoveGestureHandler {
    if (self.shouldDismissOnTapOutside) {
        [self hide];
    }
}

- (void)swipeRemoveGestureHandler {
    if (self.shouldDismissOnSwipeOutside) {
        [self hide];
    }
}

- (void)drawRect:(CGRect)rect {
    if (self.isRounded) {
        BOOL showHorizontally = self.direction == MapPopTipDirectionLeft || self.direction == MapPopTipDirectionRight;
        self.radius = (self.frame.size.height - (showHorizontally ? 0 : self.arrowSize.height)) / 2 ;
    }

    UIBezierPath *path = [self pathWithRect:rect direction:self.direction];

    [self.popoverColor setFill];
    [path fill];

    [self.borderColor setStroke];
    [path setLineWidth:self.borderWidth];
    [path stroke];

    self.paragraphStyle.alignment = self.textAlignment;

    NSDictionary *titleAttributes = @{
                                      NSParagraphStyleAttributeName: self.paragraphStyle,
                                      NSFontAttributeName: self.font,
                                      NSForegroundColorAttributeName: self.textColor
                                      };

    if (self.text != nil) {
        [self.text drawInRect:self.textBounds withAttributes:titleAttributes];
    } else if (self.attributedText != nil) {
        [self.attributedText drawInRect:self.textBounds];
    }
}

- (void)show {
    self.isAnimating = YES;
    [self setup];
    [self setNeedsLayout];
    [self performEntranceAnimation:^{
        [self.containerView addGestureRecognizer:self.tapRemoveGesture];
        [self.containerView addGestureRecognizer:self.swipeRemoveGesture];
        if (self.appearHandler) {
            self.appearHandler();
        }
        if (self.actionAnimation != MapPopTipActionAnimationNone) {
            [self startActionAnimation];
        }
        self.isAnimating = NO;
    }];
}

- (void)showText:(NSString *)text direction:(MapPopTipDirection)direction maxWidth:(CGFloat)maxWidth inView:(UIView *)view fromFrame:(CGRect)frame {
    self.attributedText = nil;
    self.text = text;
    self.accessibilityLabel = text;
    self.direction = direction;
    self.containerView = view;
    self.maxWidth = maxWidth;
    _fromFrame = frame;
    [self.customView removeFromSuperview];
    self.customView = nil;

    [self show];
}

- (void)showAttributedText:(NSAttributedString *)text direction:(MapPopTipDirection)direction maxWidth:(CGFloat)maxWidth inView:(UIView *)view fromFrame:(CGRect)frame {
    self.text = nil;
    self.attributedText = text;
    self.accessibilityLabel = [text string];
    self.direction = direction;
    self.containerView = view;
    self.maxWidth = maxWidth;
    _fromFrame = frame;
    [self.customView removeFromSuperview];
    self.customView = nil;

    [self show];
}

- (void)showCustomView:(UIView *)customView direction:(MapPopTipDirection)direction inView:(UIView *)view fromFrame:(CGRect)frame {
    self.text = nil;
    self.attributedText = nil;
    self.direction = direction;
    self.containerView = view;
    self.maxWidth = customView.frame.size.width;
    _fromFrame = frame;
    [self.customView removeFromSuperview];
    self.customView = customView;
    [self addSubview:self.customView];
    [self.customView layoutIfNeeded];

    [self show];
}

- (void)setFromFrame:(CGRect)fromFrame {
    _fromFrame = fromFrame;
    [self setup];
}

- (void)showText:(NSString *)text direction:(MapPopTipDirection)direction maxWidth:(CGFloat)maxWidth inView:(UIView *)view fromFrame:(CGRect)frame duration:(NSTimeInterval)interval {
    [self showText:text direction:direction maxWidth:maxWidth inView:view fromFrame:frame];
    [self.dismissTimer invalidate];
    if (interval > 0) {
        self.dismissTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                             target:self
                                                           selector:@selector(hide)
                                                           userInfo:nil
                                                            repeats:NO];
    }
}

- (void)showAttributedText:(NSAttributedString *)text direction:(MapPopTipDirection)direction maxWidth:(CGFloat)maxWidth inView:(UIView *)view fromFrame:(CGRect)frame duration:(NSTimeInterval)interval {
    [self showAttributedText:text direction:direction maxWidth:maxWidth inView:view fromFrame:frame];
    [self.dismissTimer invalidate];
    if (interval > 0) {
        self.dismissTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                             target:self
                                                           selector:@selector(hide)
                                                           userInfo:nil
                                                            repeats:NO];
    }
}

- (void)showCustomView:(UIView *)customView direction:(MapPopTipDirection)direction inView:(UIView *)view fromFrame:(CGRect)frame duration:(NSTimeInterval)interval {
    [self showCustomView:customView direction:direction inView:view fromFrame:frame];
    [self.dismissTimer invalidate];
    if (interval > 0) {
        self.dismissTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                             target:self
                                                           selector:@selector(hide)
                                                           userInfo:nil
                                                            repeats:NO];
    }
}
  


- (void)updateBubble {
    [self stopActionAnimation];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self setup];
    } completion:^(BOOL finished) {
        [self startActionAnimation];
    }];
}
  
- (void)hide {
    [self hideForced:NO];
}

- (void)hideForced:(BOOL)forced {
    if (!forced && self.isAnimating) {
        return;
    }
    [self.layer removeAllAnimations];

    self.isAnimating = YES;
    [self.dismissTimer invalidate];
    self.dismissTimer = nil;
    [self.containerView removeGestureRecognizer:self.tapRemoveGesture];
    [self.containerView removeGestureRecognizer:self.swipeRemoveGesture];

    void (^completion)(void) = ^{
        [self.customView removeFromSuperview];
        self.customView = nil;
        [self stopActionAnimation];
        [self.backgroundMask removeFromSuperview];
        [self removeFromSuperview];
        [self.layer removeAllAnimations];
        self.transform = CGAffineTransformIdentity;
        self->_isAnimating = NO;
        if (self.dismissHandler) {
            self.dismissHandler();
        }
    };

    BOOL isActive = YES;
#if NS_EXTENSION_UNAVAILABLE_IOS
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    isActive = (state == UIApplicationStateActive);
#endif
    if (!isActive) {
        completion();
    } else if (self.superview) {
        [self performExitAnimation:completion];
    }
}

- (void)updateText:(NSString *)text {
    self.text = text;
    self.accessibilityLabel = text;
    [self updateBubble];
}
  
- (void)updateAttributedText:(NSAttributedString *)text {
    self.attributedText = text;
    self.accessibilityLabel = [text string];
    [self updateBubble];
}
  
- (void)updateCustomView:(UIView *)view {
    self.customView = view;
    [self updateBubble];
}

- (void)startActionAnimation {
    [self performActionAnimation];
}

- (void)stopActionAnimation {
    [self dismissActionAnimation];
}

- (void)setShouldDismissOnTapOutside:(BOOL)shouldDismissOnTapOutside {
    _shouldDismissOnTapOutside = shouldDismissOnTapOutside;
    _tapRemoveGesture.enabled = shouldDismissOnTapOutside;
}

- (void)setShouldDismissOnSwipeOutside:(BOOL)shouldDismissOnSwipeOutside {
    _shouldDismissOnSwipeOutside = shouldDismissOnSwipeOutside;
    _swipeRemoveGesture.enabled = shouldDismissOnSwipeOutside;
}

- (void)setSwipeRemoveGestureDirection:(UISwipeGestureRecognizerDirection)swipeRemoveGestureDirection {
    _swipeRemoveGestureDirection = swipeRemoveGestureDirection;
    _swipeRemoveGesture.direction = swipeRemoveGestureDirection;
}

- (void)dealloc {
    [_tapRemoveGesture removeTarget:self action:@selector(tapRemoveGestureHandler)];
    _tapRemoveGesture = nil;

    [_swipeRemoveGesture removeTarget:self action:@selector(swipeRemoveGestureHandler)];
    _swipeRemoveGesture = nil;
}

@end
