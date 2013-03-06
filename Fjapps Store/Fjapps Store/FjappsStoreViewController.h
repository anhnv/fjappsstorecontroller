/*
Copyright (c) 2013 Fjapps

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// WARNING: Include "MyriadPro-Regular.otf" to the project's fonts

#import <UIKit/UIKit.h>

@interface FjappsStoreViewController : UINavigationController 

// Apps IDs are supposed to be NSNumber objects
@property (nonatomic, readwrite, copy) NSSet *excludedAppIds;

// Search string must have '+' instead of empty spaces
-(id) initFjappsStoreWithTitle:(NSString *)title searchString:(NSString *)searchString artistId:(NSNumber *)artistId;

@end
