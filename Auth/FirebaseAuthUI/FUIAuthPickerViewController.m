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

#import "FUIAuthPickerViewController.h"

#import <AuthenticationServices/AuthenticationServices.h>

#import <FirebaseAuth/FirebaseAuth.h>
#import "FUIAuthBaseViewController_Internal.h"
#import "FUIAuthSignInButton.h"
#import "FUIAuthStrings.h"
#import "FUIAuthUtils.h"
#import "FUIAuth_Internal.h"
#import "FUIPrivacyAndTermsOfServiceView.h"

/** @var kSignInButtonWidth
    @brief The width of the sign in buttons.
 */
static const CGFloat kSignInButtonWidth = 330.0f;

/** @var kSignInButtonHeight
    @brief The height of the sign in buttons.
 */
static const CGFloat kSignInButtonHeight = 48.0f;

/** @var kSignInButtonVerticalMargin
    @brief The vertical margin between sign in buttons.
 */
static const CGFloat kSignInButtonVerticalMargin = 24.0f;

/** @var kButtonContainerTopBottomMargin
    @brief The margin between sign in buttons and the top of the content view.
 */
static const CGFloat kButtonContainerTopBottomMargin = 20.0f;

/** @var kTOSViewBottomMargin
    @brief The margin between privacy policy and TOS view and the bottom of the content view.
 */
static const CGFloat kTOSViewBottomMargin = 24.0f;

/** @var kTOSViewHorizontalMargin
    @brief The margin between privacy policy and TOS view and the left or right of the content view.
 */
static const CGFloat kTOSViewHorizontalMargin = 16.0f;

static const CGFloat kDescriptionTextViewSideMargin = 34.0f;

@implementation FUIAuthPickerViewController {
  UIView *_buttonContainerView;
  UITextView *_descriptionTextView;
  
  UITextView *_accountActionDescriptionTextView;
  UIButton *_accountActionButton;

  IBOutlet FUIPrivacyAndTermsOfServiceView *_privacyPolicyAndTOSView;

  IBOutlet UIView *_contentView;
}

- (instancetype)initWithAuthUI:(FUIAuth *)authUI {
  // Sign up is the default type since that's usually the page we start with
  return [self initWithAuthUI:authUI authPickerViewType:FUIAuthPickerViewTypeSignUp];
}

- (instancetype)initWithAuthUI:(FUIAuth *)authUI
            authPickerViewType:(FUIAuthPickerViewType)authPickerViewType {
  return [self initWithNibName:@"FUIAuthPickerViewController"
                        bundle:[FUIAuthUtils bundleNamed:FUIAuthBundleName]
                        authUI:authUI
            authPickerViewType:authPickerViewType];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
                         authUI:(FUIAuth *)authUI
             authPickerViewType:(FUIAuthPickerViewType)authPickerViewType
{
  self = [super initWithNibName:nibNameOrNil
                         bundle:nibBundleOrNil
                         authUI:authUI];
  if (self) {
    _authPickerViewType = authPickerViewType;

    // TODO: localize
    switch (authPickerViewType) {
      case FUIAuthPickerViewTypeSignUp:
        self.title = @"Welcome to SwiftMemo";
        break;
      case FUIAuthPickerViewTypeSignIn:
        self.title = @"Welcome back";
        break;
    }
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  // Makes sure that embedded scroll view properly handles translucent navigation bar
  if (!self.navigationController.navigationBar.isTranslucent) {
    self.extendedLayoutIncludesOpaqueBars = true;
  }

  if (!self.authUI.shouldHideCancelButton) {
    UIBarButtonItem *cancelBarButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target:self
                                                      action:@selector(cancelAuthorization)];
    self.navigationItem.leftBarButtonItem = cancelBarButton;
  }
  if (@available(iOS 13, *)) {
    if (!self.authUI.interactiveDismissEnabled) {
      self.modalInPresentation = YES;
    }
  }

  self.navigationItem.backBarButtonItem =
      [[UIBarButtonItem alloc] initWithTitle:nil
                                       style:UIBarButtonItemStylePlain
                                      target:nil
                                      action:nil];
  
  const CGFloat fontSize = 16.0;
  const UIFont *font = [UIFont systemFontOfSize:fontSize];
  const UIColor *descriptionTextColor = [UIColor colorWithRed:90.0/255.0
                                                        green:88.0/255.0
                                                         blue:87.0/255.0
                                                        alpha:1.0];

  if (_authPickerViewType == FUIAuthPickerViewTypeSignUp) {
    _descriptionTextView = [[UITextView alloc] initWithFrame:CGRectZero];
    // TODO: localize
    _descriptionTextView.text = @"Create an account now to start capturing what is on your mind.";
    _descriptionTextView.font = font;
    _descriptionTextView.textColor = descriptionTextColor;
    [_contentView addSubview:_descriptionTextView];
  }
  
  _accountActionDescriptionTextView = [[UITextView alloc] initWithFrame:CGRectZero];
  // TODO: localize
  _accountActionDescriptionTextView.text =
  _authPickerViewType == FUIAuthPickerViewTypeSignUp ?
  @"Already have an account?" :
  @"New here?";
  _accountActionDescriptionTextView.font = font;
  _accountActionDescriptionTextView.textColor = descriptionTextColor;
  _accountActionDescriptionTextView.textContainerInset = UIEdgeInsetsZero;
  [_contentView addSubview:_accountActionDescriptionTextView];
  [_accountActionDescriptionTextView sizeToFit];

  // TODO: make sure the "Log In" button tap target is big enough
  _accountActionButton = [[UIButton alloc] initWithFrame:CGRectZero];
  // When we are on the sign up screen, we show the action to take you to log in screen if you already have account.
  // When on sign in screen, we show action to take you to sign up screen if don't have an account already.
  // Hence why the strings seemed to be opposite of the view type here.
  [_accountActionButton setTitle:_authPickerViewType == FUIAuthPickerViewTypeSignUp ? @"Log in" : @"Create an account"
                        forState:UIControlStateNormal];
  [_accountActionButton setTitleColor:[UIColor colorWithRed:74.0/255.0
                                                      green:194.0/255.0
                                                       blue:255.0/255.0
                                                      alpha:1.0]
                             forState:UIControlStateNormal];
  _accountActionButton.titleLabel.font = [UIFont boldSystemFontOfSize:fontSize];
  // Hack: when 0 inset is used for content edge inset, UIButton uses default so hacking it with a small value here.
  [_accountActionButton setContentEdgeInsets:UIEdgeInsetsMake(0.01, 0.01, 0.01, 0.01)];
  [_contentView addSubview:_accountActionButton];
  [_accountActionButton sizeToFit];
  [_accountActionButton addTarget:self action:@selector(didTapAccountAction:) forControlEvents:UIControlEventTouchUpInside];
  
  NSInteger numberOfButtons = self.authUI.providers.count;

  CGFloat buttonContainerViewHeight =
      kSignInButtonHeight * numberOfButtons + kSignInButtonVerticalMargin * (numberOfButtons - 1);
  CGRect buttonContainerViewFrame = CGRectMake(0, 0, kSignInButtonWidth, buttonContainerViewHeight);
  _buttonContainerView = [[UIView alloc] initWithFrame:buttonContainerViewFrame];
  
  [_contentView addSubview:_buttonContainerView];

  CGRect buttonFrame = CGRectMake(0, 0, kSignInButtonWidth, kSignInButtonHeight);
  for (id<FUIAuthProvider> providerUI in self.authUI.providers) {
    UIButton *providerButton =
        [[FUIAuthSignInButton alloc] initWithFrame:buttonFrame
                                        providerUI:providerUI
                           overwriteWithSignUpText:_authPickerViewType == FUIAuthPickerViewTypeSignUp];
    [providerButton addTarget:self
                       action:@selector(didTapSignInButton:)
             forControlEvents:UIControlEventTouchUpInside];
    [_buttonContainerView addSubview:providerButton];

    // Make the frame for the new button.
    buttonFrame.origin.y += (kSignInButtonHeight + kSignInButtonVerticalMargin);
  }

  _privacyPolicyAndTOSView.authUI = self.authUI;
  [_privacyPolicyAndTOSView useFullMessage];
  [_contentView bringSubviewToFront:_privacyPolicyAndTOSView];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBarHidden = false;
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

  CGFloat buttonContainerHeight = CGRectGetHeight(_buttonContainerView.frame);
  CGFloat buttonContainerWidth = CGRectGetWidth(_buttonContainerView.frame);
  CGFloat width = CGRectGetWidth(self.view.bounds);
  
  CGFloat contentViewHeight;
  
  if (@available(iOS 11.0, *)) {
    contentViewHeight = CGRectGetHeight(self.view.bounds) - self.view.safeAreaInsets.top;
  } else {
    contentViewHeight =
    CGRectGetHeight(self.view.bounds) -
    CGRectGetHeight(self.navigationController.navigationBar.frame) -
    CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
  }
  
  _contentView.frame = CGRectMake(0,
                                  CGRectGetHeight(self.view.bounds) - contentViewHeight,
                                  width,
                                  contentViewHeight);
  
  CGFloat contentY = 0.0;
  
  if (_descriptionTextView != nil) {
    CGSize descriptionSize =
    [_descriptionTextView sizeThatFits:
     CGSizeMake(width - 2 * kDescriptionTextViewSideMargin,
                contentViewHeight)];
    _descriptionTextView.frame = CGRectMake((width - descriptionSize.width) / 2.0,
                                            contentY,
                                            width - 2 * kDescriptionTextViewSideMargin,
                                            descriptionSize.height);
    contentY += CGRectGetHeight(_descriptionTextView.frame) + kButtonContainerTopBottomMargin;
  }
  
  CGFloat buttonContainerSideMargin = (width - buttonContainerWidth) / 2.0f;
  _buttonContainerView.frame = CGRectMake(buttonContainerSideMargin,
                                         contentY,
                                         buttonContainerWidth,
                                         buttonContainerHeight);
  contentY += CGRectGetHeight(_buttonContainerView.frame) + kButtonContainerTopBottomMargin;
  
  _accountActionButton.frame =
  CGRectMake(width - buttonContainerSideMargin - _accountActionButton.frame.size.width,
             contentY,
             _accountActionButton.frame.size.width,
             _accountActionButton.frame.size.height);
  
  _accountActionDescriptionTextView.frame =
  CGRectMake(_accountActionButton.frame.origin.x - _accountActionDescriptionTextView.frame.size.width,
             contentY,
             _accountActionDescriptionTextView.frame.size.width,
             _accountActionDescriptionTextView.frame.size.height);
  
  CGFloat privacyViewHeight = CGRectGetHeight(_privacyPolicyAndTOSView.frame);
  _privacyPolicyAndTOSView.frame = CGRectMake(kTOSViewHorizontalMargin,
                                              contentViewHeight - privacyViewHeight - kTOSViewBottomMargin,
                                              width - kTOSViewHorizontalMargin*2,
                                              privacyViewHeight);
}

#pragma mark - Actions

- (void)didTapSignInButton:(FUIAuthSignInButton *)button {
  [self.authUI signInWithProviderUI:button.providerUI
           presentingViewController:self
                       defaultValue:nil];
}

- (void)didTapAccountAction:(UIButton *)button {
  // If it is the sign in page, then pop the current vc to go back to the sign up page
  // If it is sign up page, then push on the sign in page.
  if (_authPickerViewType == FUIAuthPickerViewTypeSignIn) {
    // Find the sign up view controller to pop to
    __block UIViewController *popToVc = nil;
    [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj,
                                                                            NSUInteger idx,
                                                                            BOOL * _Nonnull stop) {
      if ([obj isKindOfClass:self.class]) {
        FUIAuthPickerViewController *pickerVC = (FUIAuthPickerViewController *)obj;
        if (pickerVC.authPickerViewType == FUIAuthPickerViewTypeSignUp) {
          // Pop to this VC
          popToVc = pickerVC;
          *stop = true;
        }
      }
    }];
    
    if (popToVc != nil) {
      [self.navigationController popToViewController:popToVc animated:true];
    }
  } else {
    FUIAuthPickerViewController *newVC = [[FUIAuthPickerViewController alloc] initWithAuthUI:self.authUI
                                                                          authPickerViewType:FUIAuthPickerViewTypeSignIn];
    [self pushViewController:newVC];
  }
}

@end
