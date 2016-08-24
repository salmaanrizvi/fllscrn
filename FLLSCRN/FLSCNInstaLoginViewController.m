//
//  FLSCNInstaLoginViewController.m
//  FLLSCRN
//
//  Created by Salmaan Rizvi on 7/8/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

#import "FLSCNInstaLoginViewController.h"
#import "InstagramKit.h"

@interface FLSCNInstaLoginViewController()

@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation FLSCNInstaLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.webView.scrollView.bounces = YES;
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
    NSURL *authURL = [[InstagramEngine sharedEngine] authorizationURL];

    [self.webView loadRequest:[NSURLRequest requestWithURL:authURL]];
}

-(void)viewWillAppear:(BOOL)animated {
    self.webView.delegate = self;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSError *error;
    
    if ([[InstagramEngine sharedEngine] receivedValidAccessTokenFromURL:request.URL error:&error])
    {
        [self authenticationSuccess];
    }
    return YES;
}

- (void)authenticationSuccess
{
    [self cancelButtonTapped:@"authenticated"];
}

- (IBAction)cancelButtonTapped:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

@end
