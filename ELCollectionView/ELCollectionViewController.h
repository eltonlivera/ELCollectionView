//
//  ELCollectionViewController.h
//
//
//  Created by Elton Livera on 09/01/2015.
//  Copyright (c) 2015. All rights reserved.
//

#import "AAPLSegmentedDataSource.h"

@interface ELCollectionViewController : UIViewController

@property (nonatomic, readonly) UICollectionView *collectionView;

/// Initialize your custom datasource and attach to 'dataSource' using its 'addDataSource:' method.
@property (nonatomic, readonly) AAPLSegmentedDataSource *dataSource;

/// Always use initWithLayout: to initialize this class. Calling init directly will return nil.
- (instancetype)initWithLayout:(UICollectionViewLayout *)collectionViewLayout;

/// Reloads the data source of the collection view by firing the setNeedsLoadContent. The boolean parameter will reset content and the loading state.
- (void)reloadDataSource:(BOOL)shouldReset;

@end
