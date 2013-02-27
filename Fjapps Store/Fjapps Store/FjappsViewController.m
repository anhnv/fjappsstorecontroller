//
//  FjappsViewController.m
//  Fjapps Store
//
//  Created by Francisco Javier Campos García on 17/02/13.
//  Copyright (c) 2013 Fjapps. All rights reserved.
//

#import "FjappsViewController.h"
#import "FjappsStoreViewController.h"

@interface FjappsViewController ()

@end

@implementation FjappsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)go:(id)sender {
    FjappsStoreViewController *c = [[FjappsStoreViewController alloc] initFjappsStoreWithTitle:@"Fjapps Store" searchString:@"fjapps" artistId:@427786410];
    //[c setExcludedAppIds:[NSSet setWithObject:@466223662]];
    [self presentViewController:c animated:YES completion:nil];
}
@end
