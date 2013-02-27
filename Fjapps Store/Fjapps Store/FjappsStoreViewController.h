//
//  FjappsViewController.h
//
//  Created by Francisco Javier Campos García on 17/02/13.
//  Copyright (c) 2013 Fjapps. All rights reserved.
//

// WARNING: Include "MyriadPro-Regular.otf" to the project's fonts

#import <UIKit/UIKit.h>

@interface FjappsStoreViewController : UINavigationController 

// Apps IDs are supposed to be NSNumber objects
@property (nonatomic, readwrite, copy) NSSet *excludedAppIds;

// Search string must have '+' instead of empty spaces
-(id) initFjappsStoreWithTitle:(NSString *)title searchString:(NSString *)searchString artistId:(NSNumber *)artistId;

@end
