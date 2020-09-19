//
//  Copyright (c) 2016 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "FUIAuthSignInButton.h"

#import "FUIAuthProvider.h"
#import "FUIAuthUtils.h"

NS_ASSUME_NONNULL_BEGIN

//static const CGFloat kButtonHeight = 48.0f;
static const CGFloat kFontSize = 16.0f;

@implementation FUIAuthSignInButton

- (instancetype)initWithFrame:(CGRect)frame
                        image:(UIImage *)image
                         text:(NSString *)text
              backgroundColor:(UIColor *)backgroundColor
                    textColor:(UIColor *)textColor
              buttonAlignment:(FUIButtonAlignment)buttonAlignment
            buttonBorderColor:(UIColor *)buttonBorderColor {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.backgroundColor = backgroundColor;
  
  [self setTitle:text forState:UIControlStateNormal];
  [self setTitleColor:textColor forState:UIControlStateNormal];
  
  if (@available(iOS 8.2, *)) {
    self.titleLabel.font = [UIFont systemFontOfSize:kFontSize weight:UIFontWeightMedium];
  } else {
    // Fallback on earlier versions
    self.titleLabel.font = [UIFont boldSystemFontOfSize:kFontSize];
  }
  
  [self setImage:image forState:UIControlStateNormal];

  CGFloat paddingTitle = 8.0f;
  CGFloat contentWidth = self.imageView.frame.size.width + paddingTitle + self.titleLabel.frame.size.width;
  CGFloat paddingImage = 8.0f;
  if (buttonAlignment == FUIButtonAlignmentCenter) {
    paddingImage = (frame.size.width - contentWidth) / 2 - 4.0f;
  }
  BOOL isLTRLayout = [[UIApplication sharedApplication] userInterfaceLayoutDirection] ==
      UIUserInterfaceLayoutDirectionLeftToRight;
  if (isLTRLayout) {
    [self setTitleEdgeInsets:UIEdgeInsetsMake(0, paddingTitle, 0, paddingImage + paddingTitle)];
    [self setContentEdgeInsets:UIEdgeInsetsMake(0, paddingImage, 0, -paddingImage - paddingTitle)];
    [self setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
  } else {
    [self setTitleEdgeInsets:UIEdgeInsetsMake(0, paddingImage + paddingTitle, 0, paddingTitle)];
    [self setContentEdgeInsets:UIEdgeInsetsMake(0, -paddingImage - paddingTitle, 0, paddingImage)];
    [self setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
  }
  
  self.layer.cornerRadius = frame.size.height / 2.0;
  
  if (buttonBorderColor != nil) {
    self.layer.borderWidth = 1.0;
    self.layer.borderColor = buttonBorderColor.CGColor;
  }
  
  self.adjustsImageWhenHighlighted = NO;

  return self;
}

- (instancetype)initWithFrame:(CGRect)frame
                   providerUI:(id<FUIAuthProvider>)providerUI
      overwriteWithSignUpText:(BOOL)overwriteWithSignUpText {
  _providerUI = providerUI;
  
  UIColor *buttonBorderColor = nil;
  if ([providerUI respondsToSelector:@selector(buttonBorderColor)]) {
    buttonBorderColor = [providerUI buttonBorderColor];
  }
  
  return [self initWithFrame:frame
                       image:providerUI.icon
                        text:overwriteWithSignUpText ? providerUI.signUpLabel : providerUI.signInLabel
             backgroundColor:providerUI.buttonBackgroundColor
                   textColor:providerUI.buttonTextColor
             buttonAlignment:FUIButtonAlignmentCenter
           buttonBorderColor:buttonBorderColor];
}

@end

NS_ASSUME_NONNULL_END

