/*
 * Copyright 2010, 2011 nxtbgthng for SoundCloud Ltd.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 *
 * For more information and documentation refer to
 * http://soundcloud.com/api
 * 
 */

#if TARGET_OS_IPHONE
#import "NXOAuth2.h"
#else
#import <OAuth2Client/NXOAuth2.h>
#endif
#import <QuartzCore/QuartzCore.h>

#import "SCSoundCloud.h"
#import "SCSoundCloud+Private.h"
#import "UIColor+SoundCloudUI.h"
#import "UIDevice+SoundCloudUI.h"
#import "UIView+SoundCloudUI.h"
#import "SCConstants.h"
#import "SCBundle.h"
#import "SCLoginView.h"
#import "SCGradientButton.h"
#import "SCAlertView.h"
#import "SCDrawing.h"
#import "OHAttributedLabel.h"
#import "NSAttributedString+Attributes.h"

@interface SCLoginView () <UIWebViewDelegate>
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIWebView *webView;
- (void)commonAwake;
@end

@implementation SCLoginView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonAwake];
    }
    return self;
}

- (void)commonAwake;
{
    self.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.backgroundColor = [UIColor soundCloudBackgroundGrey];
    
    self.webView = [[[UIWebView alloc] initWithFrame:self.bounds] autorelease];
    self.webView.delegate = self;
    self.webView.backgroundColor = [UIColor whiteColor];
    self.webView.alpha = 0.0;
    self.webView.opaque = NO;
    [self addSubview:self.webView];
    self.webView.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
    self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    self.activityIndicator.hidesWhenStopped = YES;
    [self addSubview:self.activityIndicator];
}

- (void)dealloc;
{
    self.webView = nil;
    self.activityIndicator = nil;
    [super dealloc];
}

#pragma mark View

- (void)layoutSubviews;{
    [super layoutSubviews];
    self.webView.frame = self.bounds;
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

#pragma mark Accessors

@synthesize loginDelegate;
@synthesize activityIndicator;

- (void)removeAllCookies;
{
    // WORKAROUND: Remove all Cookies to enable the use of facebook user accounts
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

- (NSURL *)loginURL{
    NSDictionary *accountConfig = [[NXOAuth2AccountStore sharedStore] configurationForAccountType:kSCAccountType];
    NSURL *URLToOpen = [NSURL URLWithString:[NSString stringWithFormat:@"%@?client_id=%@&redirect_uri=%@&display=popup&response_type=code",
                                             accountConfig[kNXOAuth2AccountStoreConfigurationAuthorizeURL],
                                             accountConfig[kNXOAuth2AccountStoreConfigurationClientID],
                                             accountConfig[kNXOAuth2AccountStoreConfigurationRedirectURL]]];
    return URLToOpen;
}

- (void)login{
    NSURL *urlToOpen = [self loginURL];
    [self.webView loadRequest:[NSURLRequest requestWithURL:urlToOpen]];
    // Dismiss Keyboard if it is still shown
    [[self firstResponderFromSubviews] resignFirstResponder];
}


#pragma mark WebView Delegate

- (void)webViewDidStartLoad:(UIWebView *)webView;{
    [self.activityIndicator startAnimating];
    if(self.webViewDidStartLoadingBlock){
        self.webViewDidStartLoadingBlock(webView);
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView;{
    [self.activityIndicator stopAnimating];
    if(self.webViewDidFinishLoadingBlock){
        self.webViewDidFinishLoadingBlock(webView);
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;{
    [SCSoundCloud handleRedirectURL:request.URL];
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;{
    if ([[error domain] isEqualToString:NSURLErrorDomain]) {

        if ([error code] == NSURLErrorCancelled)
            return;

    } else if ([[error domain] isEqualToString:@"WebKitErrorDomain"]) {

        if ([error code] == 101)
            return;

        if ([error code] == 102)
            return;
    }

    if ([self.loginDelegate respondsToSelector:@selector(loginView:didFailWithError:)]) {
        [self.loginDelegate loginView:self
                     didFailWithError:error];
    }
    
    if(self.webViewDidFailWithErrorBlock){
        self.webViewDidFailWithErrorBlock(webView,error);
    }
}

@end
