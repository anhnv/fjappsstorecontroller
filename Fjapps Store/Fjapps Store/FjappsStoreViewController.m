/*
Copyright (c) 2013 Javier Campos

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import "FjappsStoreViewController.h"
#import <StoreKit/StoreKit.h>
#import <QuartzCore/QuartzCore.h>

#define FJAPPS_STORE_RESULTS_KEY          @"results"
#define FJAPPS_STORE_ARTIST_ID_KEY        @"artistId"
#define FJAPPS_STORE_APP_ID_KEY           @"trackId"
#define FJAPPS_STORE_APP_NAME_KEY         @"trackName"
#define FJAPPS_STORE_APP_VERSION_KEY      @"version"
#define FJAPPS_STORE_APP_RATING_KEY       @"averageUserRating"
#define FJAPPS_STORE_APP_PRICE_KEY        @"formattedPrice"
#define FJAPPS_STORE_APP_ICON_KEY         @"fjappsIconImage"
#define FJAPPS_STORE_APP_ICON_URL_60_KEY  @"artworkUrl60"
#define FJAPPS_STORE_APP_ICON_URL_100_KEY @"artworkUrl100"

#define FJAPPS_STORE_CELL_HEIGHT        92.0f
#define FJAPPS_STORE_TIMEOUT            120
#define FJAPPS_STORE_ANIMATION_DURATION 0.3f
#define FJAPPS_STORE_NIB_FILE           @"FjappsStoreTableViewCellNib"
#define FJAPPS_STORE_CELL_ID            @"FjappsStoreCellId"
#define FJAPPS_STORE_SEARCH_URL         @"https://itunes.apple.com/search?term=%@&entity=software&country=%@"

#define FJAPPS_STORE_CELL_ICON_TAG             1
#define FJAPPS_STORE_CELL_PRICE_TAG            2
#define FJAPPS_STORE_CELL_VERSION_TAG          3
#define FJAPPS_STORE_CELL_RATING_TAG           4
#define FJAPPS_STORE_CELL_NAME_TAG             5
#define FJAPPS_STORE_CELL_ACTIVITY_TAG         6
#define FJAPPS_STORE_CELL_PRICE_BACKGROUND_TAG 7
#define FJAPPS_STORE_FONT_REGULAR_NAME         @"MyriadPro-Regular"

#define FJAPPS_STORE_ROUND_CORNERS(macro_view, radius) {[[macro_view layer] setMasksToBounds:YES]; \
                                                        [[macro_view layer] setCornerRadius:(radius)]; \
                                                        [[macro_view layer] setBorderWidth:0.0]; \
                                                        [[macro_view layer] setBorderColor:[[UIColor clearColor] CGColor]];}


/*   GENERIC WORKER PROTOCOL  */
/* ************************** */
@protocol FjappsStoreWorkerProtocol <NSObject>
@required
-(void) startConnection;
-(void) cancelConnection;
@end


/*        STORE WORKER        */
/* ************************** */
#pragma mark - FjappsStoreWorker
@class FjappsStoreWorker;

@protocol FjappsStoreWorkerDelegate <NSObject>

@optional

-(void) fjappsStoreWorkerDidStart: (FjappsStoreWorker *)worker;
-(void) fjappsStoreWorkerDidEnd: (FjappsStoreWorker *)worker withData:(NSDictionary *)workerData;

@end

@interface FjappsStoreWorker: NSObject <FjappsStoreWorkerProtocol, NSURLConnectionDataDelegate>

-(id) initWithSearchString:(NSString *)search;

@property (nonatomic, readonly) NSDictionary *storeData;
@property (nonatomic, readwrite, weak) id <FjappsStoreWorkerDelegate> delegate;
@property (nonatomic, readwrite, strong) NSMutableData *connectionData;
@property (nonatomic, readwrite, strong) NSURLRequest *connectionRequest;
@property (nonatomic, readwrite, strong) NSURLConnection *connection;

@end

@implementation FjappsStoreWorker

@synthesize connectionData = _connectionData;
@synthesize delegate = _delegate;
@synthesize connection = _connection;
@synthesize connectionRequest = _connectionRequest;
@synthesize storeData = _storeData;

-(id)initWithSearchString:(NSString *)search {
    self = [super init];
    
    if (self) {
        // Get APP Search API address
        NSURL *theURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:FJAPPS_STORE_SEARCH_URL, search, [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]]];

        // Request data
        self.connectionRequest = [[NSURLRequest alloc] initWithURL:theURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:FJAPPS_STORE_TIMEOUT];

        _storeData = NO;
    }
    
    return (self);
}

#pragma mark - Methods
-(void)cancelConnection {
    // Cancel the associated connection
    [self.connection cancel];
    self.connection = nil;
}

-(void)startConnection {
    // Create connection data
    self.connectionData = [[NSMutableData alloc] init];
    
    if(_storeData) {
        _storeData = nil;
    }
    
    // Notify the delagate
    if ([self.delegate respondsToSelector:@selector(fjappsStoreWorkerDidStart:)]) {
        [self.delegate fjappsStoreWorkerDidStart:self];
    }
    
    
    // Configure connection
    self.connection = [[NSURLConnection alloc] initWithRequest:self.connectionRequest delegate:self];
    [self.connection start];
}

#pragma mark - NSConnectionDataDelegate protocol
-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append new data
    [self.connectionData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSData *theData = [NSData dataWithData:self.connectionData];
    self.connectionData = nil;
    self.connection = nil;
    
    // JSON Serialization
    NSDictionary *serial = [NSJSONSerialization JSONObjectWithData:theData options:NSJSONReadingAllowFragments error:nil];
    
    _storeData = [NSDictionary dictionaryWithDictionary:serial];
    
    // Notify the delegate in the main queue
    __weak FjappsStoreWorker *weakSelf = self;
    if ([self.delegate respondsToSelector:@selector(fjappsStoreWorkerDidEnd:withData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate fjappsStoreWorkerDidEnd:weakSelf withData:weakSelf.storeData];
        });
    }
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // Release data
    self.connectionData = nil;
    self.connection = nil;
    
    // Notify delegate in the main queue
    __weak FjappsStoreWorker *weakSelf = self;
    if ([self.delegate respondsToSelector:@selector(fjappsStoreWorkerDidEnd:withData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate fjappsStoreWorkerDidEnd:weakSelf withData:nil];
        });
    }
}

@end

/*        IMAGE WORKER        */
/* ************************** */
@class FjappsStoreImageWorker;

@protocol FjappsStoreImageWorkerDelegate <NSObject>

@optional

-(void)fjappsStoreImageWorker:(FjappsStoreImageWorker *)worker didLoadImage:(UIImage *)image;
-(void)fjappsStoreImageWorkerDidStart:(FjappsStoreImageWorker *)worker;

@end

@interface FjappsStoreImageWorker : NSObject <FjappsStoreWorkerProtocol, NSURLConnectionDataDelegate>

@property (nonatomic, readwrite, copy) NSURL *productImageURL;
@property (nonatomic, readwrite, copy) NSIndexPath *productIndexPath;
@property (nonatomic, readwrite, strong) NSMutableData *connectionData;
@property (nonatomic, readwrite, strong) NSURLConnection *connection;
@property (nonatomic, readwrite, weak) id<FjappsStoreImageWorkerDelegate>delegate;

@end

@implementation FjappsStoreImageWorker

@synthesize productImageURL = _productImageURL;
@synthesize productIndexPath = _productIndexPath;
@synthesize connection = _connection;
@synthesize connectionData = _connectionData;
@synthesize delegate = _delegate;

#pragma mark - Methods
-(void) startConnection {
    // If a connection is already created... Cancel it
    if (self.connection) {
        [self.connection cancel];
    }
    
    // Initialize data array
    self.connectionData = [[NSMutableData alloc] init];

    // Create request
    NSURLRequest *theRequest = [[NSURLRequest alloc] initWithURL:self.productImageURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:FJAPPS_STORE_TIMEOUT];
    
    // Create connection
    self.connection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    
    // Notify the delegate
    if ([self.delegate respondsToSelector:@selector(fjappsStoreImageWorkerDidStart:)]) {
        [self.delegate fjappsStoreImageWorkerDidStart:self];
    }
    
    // Start connection
    [self.connection start];
}

-(void) cancelConnection {
    [self.connection cancel];
    self.connection = nil;
}

#pragma mark - NSURLConnectionDataDelegate protocol
-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append data
    [self.connectionData appendData:data];
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // Stop loading
    self.connection = nil;
    self.connectionData = nil;
    
    // Notify the delegate
    if ([self.delegate respondsToSelector:@selector(fjappsStoreImageWorker:didLoadImage:)]) {
        [self.delegate fjappsStoreImageWorker:self didLoadImage:nil];
    }
}

-(void) connectionDidFinishLoading:(NSURLConnection *)connection {
    // Create image
    UIImage *theImage = [UIImage imageWithData:self.connectionData scale:[[UIScreen mainScreen] scale]];

    // Cancel everything
    self.connection = nil;
    self.connectionData = nil;
    
    // Notify delegate
    if ([self.delegate respondsToSelector:@selector(fjappsStoreImageWorker:didLoadImage:)]) {
        [self.delegate fjappsStoreImageWorker:self didLoadImage:theImage];
    }
}

@end


/*     TABLE CONTROLLER       */
/* ************************** */

#pragma mark - FjappsStoreTableViewController
@interface FjappsStoreTableViewController: UITableViewController <UITableViewDataSource, UITableViewDelegate, SKStoreProductViewControllerDelegate, NSURLConnectionDataDelegate, FjappsStoreWorkerDelegate, FjappsStoreImageWorkerDelegate>

@property (nonatomic, readwrite, copy) NSString *storeTitle;
@property (nonatomic, readwrite, strong) NSMutableSet *storeWorkers;
@property (nonatomic, readwrite, strong) NSMutableArray *storeProducts;
@property (nonatomic, readwrite, weak) UIView *pickerView;
@property (nonatomic, readwrite, weak) UIActivityIndicatorView *pickerActivityView;
@property (nonatomic, readwrite, copy) NSString *searchString;
@property (nonatomic, readwrite, copy) NSNumber *artistId;
@property (nonatomic, readwrite, weak) NSSet *excludedAppIds;
@property (nonatomic, readwrite, getter = isLoadingStoreController) BOOL loadingStoreController;
@property (nonatomic, readwrite, getter = isDismissing) BOOL dismissing;

-(void)fjappsCancelStore:(id) sender;
-(void)fjappsShowLoading:(BOOL)animated;
-(void)fjappsDismissLoading:(BOOL)animated;

@end

@implementation FjappsStoreTableViewController

@synthesize storeTitle = _storeTitle;
@synthesize storeWorkers = _storeWorkers;
@synthesize storeProducts = _storeProducts;
@synthesize pickerView = _pickerView;
@synthesize pickerActivityView = _pickerActivityView;
@synthesize searchString = _searchString;
@synthesize artistId = _artistId;
@synthesize excludedAppIds = _excludedAppIds;
@synthesize loadingStoreController = _loadingStoreController;
@synthesize dismissing = _dismissing;

#pragma mark - View Controller Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    // Register class for table's reuse identifier
    [self.tableView registerNib:[UINib nibWithNibName:FJAPPS_STORE_NIB_FILE bundle:[NSBundle mainBundle]] forCellReuseIdentifier:FJAPPS_STORE_CELL_ID];
	
    // This class is also the table's delegate and data source
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    // Configure navigation bar
    self.title = self.storeTitle;
    
    // Register for notifications
    __weak FjappsStoreTableViewController *weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note){
        // Set network activity indicator if view is vissible
        if (weakSelf.view.window) {
            // If there are still workers pending finishing...
            if ([weakSelf.storeWorkers count] > 0) {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

                [weakSelf.storeWorkers enumerateObjectsUsingBlock:^(id obj, BOOL *stop){
                    id<FjappsStoreWorkerProtocol> thisWorker = (id<FjappsStoreWorkerProtocol>)obj;
                    *stop = NO;
                    // Restart connection in this worker
                    [thisWorker startConnection];
                }];
            }
            if ([weakSelf isLoadingStoreController]) {
                // Show loading screen if store controller is loading
                [weakSelf fjappsShowLoading:NO];
            }
        }
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note){
        // If view is vissible
        if (weakSelf.view.window) {
            // If there are still workers pending finishing...
            if ([weakSelf.storeWorkers count] > 0) {
                // Cancel network activity indicator
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
                // Dismiss loading screen
                [weakSelf fjappsDismissLoading:NO];
        
                // Cancel worker's connections
                [weakSelf.storeWorkers enumerateObjectsUsingBlock:^(id obj, BOOL *stop){
                    id<FjappsStoreWorkerProtocol> thisWorker = (id<FjappsStoreWorkerProtocol>)obj;
                    *stop = NO;
                    [thisWorker cancelConnection];
                }];
            }
        }
    }];
    
    // Set Network Activity Indicator
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    // Initialize NSSet for all workers
    self.storeWorkers = [[NSMutableSet alloc] init];
    
    // Initialize NSArray for all products
    self.storeProducts = [[NSMutableArray alloc] init];
    
    // Initialize loading store controller
    self.loadingStoreController = NO;

    // Create worker
    FjappsStoreWorker *thisWorker = [[FjappsStoreWorker alloc] initWithSearchString:self.searchString];
    [thisWorker setDelegate:self];
        
    // Store worker in the NSSet
    [self.storeWorkers addObject:thisWorker];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // If at least there is one worker, show the loading screen and start connections
    if ([self.storeWorkers count] > 0) {
        [self.storeWorkers enumerateObjectsUsingBlock:^(id obj, BOOL *stop){
            *stop = NO;
            id<FjappsStoreWorkerProtocol> thisWorker = (id<FjappsStoreWorkerProtocol>)obj;
            
            // Start connection
            [thisWorker startConnection];
        }];
    }
    [self.tableView flashScrollIndicators];
}

-(void)viewWillAppear:(BOOL)animated {
    self.dismissing = NO;
    [super viewWillAppear:animated];
    
    // Configure Navigation Bar
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(fjappsCancelStore:)];
    [self.navigationItem setLeftBarButtonItem:leftItem];
}

-(void)viewWillDisappear:(BOOL)animated {
    self.dismissing = YES;
    
    [super viewWillDisappear:animated];
    
    // If this view is disappearing... Cancel all workers
    if ([self.storeWorkers count] > 0) {
        [self.storeWorkers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            id<FjappsStoreWorkerProtocol> thisWorker = (id<FjappsStoreWorkerProtocol>)obj;
            [thisWorker cancelConnection];
        }];
    }
    [self fjappsDismissLoading:animated];
}

-(UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    // Portrait orientation only
    return (UIInterfaceOrientationPortrait);
}

-(NSUInteger) supportedInterfaceOrientations {
    // Portrait orientation only
    return (UIInterfaceOrientationMaskPortrait);
}

#pragma mark - UITableViewDataSource protocol
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // The number of rows is the number of products
    return [self.storeProducts count];
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    // Only one section
    return 1;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *thisCell = [tableView dequeueReusableCellWithIdentifier:FJAPPS_STORE_CELL_ID forIndexPath:indexPath];
    
    // Get product info
    NSMutableDictionary *thisProduct = [self.storeProducts objectAtIndex:indexPath.row];
    NSString *name = [thisProduct valueForKey:FJAPPS_STORE_APP_NAME_KEY];
    NSString *version = [thisProduct valueForKey:FJAPPS_STORE_APP_VERSION_KEY];
    NSNumber *rating = [NSNumber numberWithFloat:[[thisProduct valueForKey:FJAPPS_STORE_APP_RATING_KEY] floatValue]];
    NSString *price = [thisProduct valueForKey:FJAPPS_STORE_APP_PRICE_KEY];
    UIImage *image = [thisProduct valueForKey:FJAPPS_STORE_APP_ICON_KEY];
    
    // Get views
    UIImageView *thisImageView = (UIImageView *)[thisCell viewWithTag:FJAPPS_STORE_CELL_ICON_TAG];
    UILabel *thisPrice = (UILabel *)[thisCell viewWithTag:FJAPPS_STORE_CELL_PRICE_TAG];
    UILabel *thisVersion = (UILabel *)[thisCell viewWithTag:FJAPPS_STORE_CELL_VERSION_TAG];
    UILabel *thisRating = (UILabel *)[thisCell viewWithTag:FJAPPS_STORE_CELL_RATING_TAG];
    UILabel *thisName = (UILabel *)[thisCell viewWithTag:FJAPPS_STORE_CELL_NAME_TAG];
    UIActivityIndicatorView *thisActivityView = (UIActivityIndicatorView *)[thisCell viewWithTag:FJAPPS_STORE_CELL_ACTIVITY_TAG];
    UIView *priceView = [thisCell viewWithTag:FJAPPS_STORE_CELL_PRICE_BACKGROUND_TAG];
    
    // Set fonts
    UIFont *newFontRegular = [UIFont fontWithName:FJAPPS_STORE_FONT_REGULAR_NAME size:10.0f];
    if (newFontRegular) {
        UIFont *priceFont = [thisPrice font];
        UIFont *versionFont = [thisVersion font];
        UIFont *nameFont = [thisName font];
        
        thisPrice.font = [newFontRegular fontWithSize:priceFont.pointSize];
        thisVersion.font = [newFontRegular fontWithSize:versionFont.pointSize];
        thisName.font = [newFontRegular fontWithSize:nameFont.pointSize];
    }
    
    // Configure cell
    [thisName setText:name];
    [thisPrice setText:price];
    [thisVersion setText:version];
    NSMutableString *ratingString = [[NSMutableString alloc] init];
    const char starFill[4] = {0xE2, 0x98, 0x85, 0x00};
    const char starEmpty[4] = {0xE2, 0x98, 0x86, 0x00};
    for (int i = 0; i < 5; i++) {
        if ([rating floatValue] > (float)i) {
            [ratingString appendString:[NSString stringWithUTF8String:starFill]];
        } else {
            [ratingString appendString:[NSString stringWithUTF8String:starEmpty]];
        }
    }
    [thisRating setText:[NSString stringWithString:ratingString]];
    [thisImageView setImage:image];
    // Show activity indicator while image is loaded
    if (image != nil) {
        [thisActivityView stopAnimating];
    } else {
        [thisActivityView startAnimating];
    }
    FJAPPS_STORE_ROUND_CORNERS(thisImageView, 10.0f)
    FJAPPS_STORE_ROUND_CORNERS(priceView, 4.0f)

    return (thisCell);
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return FJAPPS_STORE_CELL_HEIGHT;
}

#pragma mark - UITableViewDelegate protocol
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Create the SKStoreProductViewController class
    SKStoreProductViewController *theController = [[SKStoreProductViewController alloc] init];
    
    // Get the product id
    NSMutableDictionary *thisProduct = [self.storeProducts objectAtIndex:indexPath.row];
    NSNumber *thisAppId = [thisProduct valueForKey:FJAPPS_STORE_APP_ID_KEY];
    
    // Set the delegate
    theController.delegate = self;
    __weak FjappsStoreTableViewController *weakSelf = self;
    
    // Present the activity view
    [self fjappsShowLoading:YES];
    
    // Load the product
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    self.loadingStoreController = YES;
    [theController loadProductWithParameters:[NSDictionary dictionaryWithObject:thisAppId forKey:SKStoreProductParameterITunesItemIdentifier] completionBlock:^(BOOL result, NSError *error) {
        if (result && ![weakSelf isDismissing] && weakSelf.view.window) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // Present the controller
                [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
                [weakSelf presentViewController:theController animated:YES completion:^{
                    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                    [weakSelf fjappsDismissLoading:NO];
                }];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf fjappsDismissLoading:YES];
                [weakSelf.tableView deselectRowAtIndexPath:indexPath animated:YES];
            });
        }
        weakSelf.loadingStoreController = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        });
    }];
}

#pragma mark - SKStoreProductViewControllerDelegate protocol
-(void) productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    // Dismiss the controller
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [self dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }];
}

#pragma mark - FjappsStoreImageWorkerDelegate protocol
-(void) fjappsStoreImageWorkerDidStart:(FjappsStoreImageWorker *)worker {
    // Show network activity
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

-(void) fjappsStoreImageWorker:(FjappsStoreImageWorker *)worker didLoadImage:(UIImage *)image {
    if (image) {
        NSMutableDictionary *thisElement = [self.storeProducts objectAtIndex:worker.productIndexPath.row];
    
        // Add image to product information
        [thisElement setObject:image forKey:FJAPPS_STORE_APP_ICON_KEY];
    }

    // Remove the worker from the set
    [self.storeWorkers removeObject:worker];
    
    // If this is the last, remove the network activity indicator
    if ([self.storeWorkers count] == 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
    
    [self.tableView reloadData];
}

#pragma mark - FjappsStoreWorkerDelegate protocol
-(void) fjappsStoreWorkerDidStart:(FjappsStoreWorker *)worker {
    // Show network activity
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    // Show loading screen
    [self fjappsShowLoading:YES];
}

-(void) fjappsStoreWorkerDidEnd:(FjappsStoreWorker *)worker withData:(NSDictionary *)workerData {
    
    // Iterate in the result
    NSArray *results = [workerData valueForKey:FJAPPS_STORE_RESULTS_KEY];
    
    // Get the scale
    CGFloat scale = [[UIScreen mainScreen] scale];

    __weak FjappsStoreTableViewController *weakSelf = self;
    [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
        *stop = NO;
        NSDictionary *thisElement = (NSDictionary *)obj;
        // Check artistId and excluded list
        NSNumber *thisAppId = [thisElement valueForKey:FJAPPS_STORE_APP_ID_KEY];
        __block BOOL include = YES;
        [weakSelf.excludedAppIds enumerateObjectsUsingBlock:^(id obj, BOOL *stop){
            NSNumber *thisExcludedAppId = (NSNumber *)obj;
            *stop = NO;
            if ([thisExcludedAppId isEqualToNumber:thisAppId]) {
                *stop = YES;
                include = NO;
            }
        }];
        NSNumber *thisArtistId = [thisElement valueForKey:FJAPPS_STORE_ARTIST_ID_KEY];
        if (([thisArtistId isEqualToNumber:weakSelf.artistId]) && include) {
            // Convert to Mutable
            NSMutableDictionary *thisMutableElement = [thisElement mutableCopy];
            // Add data to products
            [weakSelf.storeProducts addObject:thisMutableElement];
         
            // Create the image worker
            NSString *productIcon;
            if (scale == 1.0f) {
                productIcon = [thisMutableElement valueForKey:FJAPPS_STORE_APP_ICON_URL_60_KEY];
            } else {
                productIcon = [thisMutableElement valueForKey:FJAPPS_STORE_APP_ICON_URL_100_KEY];
            }
            NSURL *theURL = [[NSURL alloc] initWithString:productIcon];
            FjappsStoreImageWorker *imageWorker = [[FjappsStoreImageWorker alloc] init];
            [imageWorker setProductImageURL:theURL];
            [imageWorker setDelegate:weakSelf];
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[weakSelf.storeProducts indexOfObject:thisMutableElement] inSection:0];
            [imageWorker setProductIndexPath:indexPath];
            
            // Start the worker
            [imageWorker startConnection];
            
            // Add the imager worker to the NSSet
            [weakSelf.storeWorkers addObject:imageWorker];
        }
    }];

    // Remove worker from NSSet
    [weakSelf.storeWorkers removeObject:worker];
    
    // Reload table data
    [self.tableView reloadData];
    
    // Remove the loading screen and let icons load in background
    [self fjappsDismissLoading:YES];
    
    // If this is the last, remove the network activity indicator
    if ([self.storeWorkers count] == 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}

#pragma mark - Loading activity indicator
-(void) fjappsShowLoading:(BOOL)animated {

    if (self.pickerView.window) {
        // Already in window
        return;
    }
    
    // Present the activity view
    UIView *thisPickerView = [[UIView alloc] initWithFrame:self.view.frame];
    [thisPickerView setUserInteractionEnabled:YES];
    UIActivityIndicatorView *thisIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    thisIndicatorView.center = thisPickerView.center;
    [thisPickerView addSubview:thisIndicatorView];
    thisPickerView.backgroundColor = [UIColor blackColor];
    thisPickerView.alpha = 0.0f;
    
    self.pickerView = thisPickerView;
    self.pickerActivityView = thisIndicatorView;
    
    [self.view addSubview:self.pickerView];
    
    __weak FjappsStoreTableViewController *weakSelf = self;
    NSTimeInterval animationInterval = (animated)? FJAPPS_STORE_ANIMATION_DURATION : 0.0f;
    [UIView animateWithDuration:animationInterval animations:^{
        [weakSelf.pickerView setAlpha:0.7f];
    } completion:^(BOOL finished) {
        [weakSelf.pickerActivityView startAnimating];
    }];

}

-(void) fjappsDismissLoading:(BOOL)animated {
    
    if (self.pickerView.window == nil) {
        // Not in window
        return;
    }
    
    NSTimeInterval animationInterval = (animated)? FJAPPS_STORE_ANIMATION_DURATION : 0.0f;

    [self.pickerActivityView stopAnimating];
    [self.pickerActivityView removeFromSuperview];
    
    __weak FjappsStoreTableViewController *weakSelf = self;
    [UIView animateWithDuration:animationInterval animations:^{
        [weakSelf.pickerView setAlpha:0.0f];
    } completion:^(BOOL finished){
        [weakSelf.pickerView removeFromSuperview];
        [weakSelf.tableView flashScrollIndicators];
    }];
}

#pragma mark - Actions
-(void) fjappsCancelStore:(id)sender {
    // Dismiss the controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

/*      VIEW CONTROLLER       */
/* ************************** */

#pragma mark - FjappsStoreViewController

@interface FjappsStoreViewController ()

@property (nonatomic, readwrite) UIStatusBarStyle fjappsStatusBarStyle;
@property (nonatomic, readwrite, weak) FjappsStoreTableViewController *storeTableController;

@end

@implementation FjappsStoreViewController

@synthesize fjappsStatusBarStyle = _fjappsStatusBarStyle;
@synthesize excludedAppIds = _excludedAppIds;
@synthesize storeTableController = _storeTableController;

#pragma mark - Initialization
-(id) initFjappsStoreWithTitle:(NSString *)title searchString:(NSString *)searchString artistId:(NSNumber *)artistId {
    // Create a Navigation Controller
    FjappsStoreTableViewController *tableController = [[FjappsStoreTableViewController alloc] initWithStyle:UITableViewStylePlain];
    tableController.storeTitle = title;
    tableController.searchString = searchString;
    tableController.artistId = artistId;
    self = [super initWithRootViewController:tableController];
    if (self) {
        self.storeTableController = tableController;
    }
    
    // Customization
    [[UINavigationBar appearanceWhenContainedIn:[self class], nil] setTintColor:[UIColor blackColor]];
    return (self);
}

#pragma mark - Accessors
-(void) setExcludedAppIds:(NSSet *)excludedAppIds {
    _excludedAppIds = [excludedAppIds copy];
    
    [self.storeTableController setExcludedAppIds:excludedAppIds];
}

#pragma mark - View Controller cycle
-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Store previous status bar style and set style to black
    self.fjappsStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:animated];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Restore previous status bar style
    [[UIApplication sharedApplication] setStatusBarStyle:self.fjappsStatusBarStyle animated:animated];
    
    // Disable the network activity indicator
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];    
}

@end

