//
//  FLSCNInstagramViewController.m
//  FLLSCRN
//
//  Created by Salmaan Rizvi on 7/8/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

#import "FLSCNInstagramViewController.h"
#import "IKCell.h"
#import "FLSCNImageViewController.h"
#import "FLLSCRN-Swift.h"

#define kFetchItemsCount 100
#define kNumberOfCellsInARow 2

@interface FLSCNInstagramViewController()

@property (strong, nonatomic)   IBOutlet UINavigationItem *navigationBar;
@property (strong, nonatomic)   IBOutlet UICollectionView *igCollection;
@property (strong, nonatomic)   IBOutlet UIBarButtonItem *loginLogoutButton;
@property (nonatomic, strong)   NSMutableArray *mediaArray;
@property (nonatomic, strong)   InstagramPaginationInfo *currentPaginationInfo;
@property (nonatomic, weak)     InstagramEngine *instagramEngine;

@end

@implementation FLSCNInstagramViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.mediaArray = [[NSMutableArray alloc] init];
    self.instagramEngine = [InstagramEngine sharedEngine];

    [self updateCollectionViewLayout];
    
    [self loadMedia];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userAuthenticationChanged:)
                                                 name:InstagramKitUserAuthenticationChangedNotification
                                               object:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    
//    NSLog(@"Access Token %@", self.instagramEngine.accessToken);
//    
    [self loadMedia];
//    NSLog(@"Third Media Array Size Call: %lu", self.mediaArray.count);
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
    [self.loginLogoutButton setTitle: (isSessionValid) ? @"Logout" : @"Login"];
    [self.mediaArray removeAllObjects];
    [self.igCollection reloadData];
    
    if (isSessionValid) {
        [self requestSelfFeed];
    }
    else
    {
        [self requestPopularMedia];
    }
    [self setTitle: (isSessionValid) ? ((InstagramMedia *)self.mediaArray.firstObject).user.username : @"Social"];

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
         [self.igCollection reloadData];
     }
                                             failure:^(NSError *error, NSInteger statusCode) {
                                                 NSLog(@"Load Popular Media Failed");
                                             }];
}


/**
 Calls InstagramKit's helper method to fetch Media in the authenticated user's feed.
 @discussion The self.currentPaginationInfo object is updated on each successful call
 and it's updated nextMaxId is passed as a parameter to the next paginated request.
 */
- (void)requestSelfFeed
{
    [self.instagramEngine getSelfFeedWithCount:kFetchItemsCount
                                         maxId:self.currentPaginationInfo.nextMaxId
                                       success:^(NSArray *media, InstagramPaginationInfo *paginationInfo) {
                                           
                                           self.currentPaginationInfo = paginationInfo;
                                           
                                           [self.mediaArray addObjectsFromArray:media];
                                           [self.igCollection reloadData];
                                           
                                           [self.igCollection scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
                                           
                                       }
                                       failure:^(NSError *error, NSInteger statusCode) {
                                           NSLog(@"Request Self Feed Failed");
                                       }];
}
- (IBAction)loginLogoutTapped:(UIBarButtonItem *)sender {

    if (![self.instagramEngine isSessionValid]) {
        UINavigationController *loginNavigationViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"InstagramLoginAuthorizationVC"];
        [self presentViewController:loginNavigationViewController animated:YES completion:nil];
    }
    else
    {
        [self.instagramEngine logout];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"InstagramKit" message:@"You are now logged out." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alert show];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"instagramFLSCNSegue"]) {
        FLSCNImageViewController *imageVC = (FLSCNImageViewController *)segue.destinationViewController;
        NSIndexPath *indexPath = self.igCollection.indexPathsForSelectedItems[0];
        InstagramMedia *media = self.mediaArray[indexPath.item];
        imageVC.imageURL = media.standardResolutionImageURL;
    }
}

#pragma mark - User Authenticated Notification -

- (void)userAuthenticationChanged:(NSNotification *)notification
{
    [self loadMedia];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma MARK - UICollectionViewDelegate / Source methods

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.mediaArray.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    IKCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"igImageCell" forIndexPath:indexPath];
    InstagramMedia *media = self.mediaArray[indexPath.row];
    [cell setImageUrl:media.thumbnailURL];
    return cell;
}

-(void)updateCollectionViewLayout {
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.igCollection.collectionViewLayout;
    
    NSLog(@"Updating Collection View Layout.");
    NSLog(@"View Bounds Minus 1: %lf", self.view.bounds.size.width - 1);
    CGFloat size = floor((self.view.bounds.size.width - 1) / kNumberOfCellsInARow);
    NSLog(@"Size: %lf", size);
    layout.itemSize = CGSizeMake(size, size);
}

@end
