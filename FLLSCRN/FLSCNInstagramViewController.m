//
//  FLSCNInstagramViewController.m
//  FLLSCRN
//
//  Created by Salmaan Rizvi on 7/8/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

#import "FLSCNInstagramViewController.h"

@interface FLSCNInstagramViewController()

@property (strong, nonatomic) IBOutlet UIImageView *instagramImageView;
@property (nonatomic, strong)   NSMutableArray *mediaArray;
@property (nonatomic, strong)   InstagramPaginationInfo *currentPaginationInfo;
@property (nonatomic, weak)     InstagramEngine *instagramEngine;

@end

@implementation FLSCNInstagramViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.mediaArray = [[NSMutableArray alloc] init];
    self.instagramEngine = [InstagramEngine sharedEngine];
    NSURL *authURL = [self.instagramEngine authorizationURL];
    //[self.webView loadRequest:[NSURLRequest requestWithURL:authURL]];
    [self loadMedia];
    
}
/**
 *  Depending on whether the Instagram session is authenticated,
 *  this method loads either the publicly accessible popular media
 *  or the authenticated user's feed.
 */
- (void)loadMedia
{
    self.currentPaginationInfo = nil;
    
    BOOL isSessionValid = [self.instagramEngine isSessionValid];
    [self setTitle: (isSessionValid) ? @"My Feed" : @"Popular Media"];
//    [self.navigationItem.leftBarButtonItem setTitle: (isSessionValid) ? @"Log out" : @"Log in"];
//    [self.navigationItem.rightBarButtonItem setEnabled: isSessionValid];
    [self.mediaArray removeAllObjects];
    
    [self requestPopularMedia];
    
    InstagramMedia *media = [self.mediaArray firstObject];
    
    NSLog(@"%@", [media lowResolutionImageURL].absoluteString);
     //setImageUrl:media.thumbnailURL];
    
}

#pragma mark - API Requests -

/**
 Calls InstagramKit's helper method to fetch Popular Instagram Media.
 */
- (void)requestPopularMedia
{
    [self.instagramEngine getPopularMediaWithSuccess:^(NSArray *media, InstagramPaginationInfo *paginationInfo)
     {
         [self.mediaArray addObjectsFromArray:media];
     }
                                             failure:^(NSError *error, NSInteger statusCode) {
                                                 NSLog(@"Load Popular Media Failed");
                                             }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
