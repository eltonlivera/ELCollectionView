//
//  ELCollectionViewController.m
//  
//
//  Created by Elton Livera on 09/01/2015.
//  Copyright (c) 2015. All rights reserved.
//

#import "ELCollectionViewController.h"
#import "AAPLDataSource_Private.h"
#import "AAPLCollectionViewGridLayout_Private.h"

static void * const AAPLDataSourceContext = @"DataSourceContext";

@interface ELCollectionViewController () <AAPLDataSourceDelegate, UICollectionViewDelegate>

@property (nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic) AAPLSegmentedDataSource *dataSource;

@end

@implementation ELCollectionViewController

- (void)dealloc {
    [self.collectionView removeObserver:self forKeyPath:@"dataSource" context:AAPLDataSourceContext];
    
    // For some reason the key value observer is still attached to collection view even after calling removeObserver.
    // Setting it to nil calling (custom setter) solves the problem.
    self.collectionView = nil;
}

- (instancetype)init {
    return nil;
}

- (instancetype)initWithLayout:(UICollectionViewLayout *)collectionViewLayout {
    if (self = [super init]) {
        NSParameterAssert(collectionViewLayout);
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    if (_collectionView && !self.collectionView.superview) {
        self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        self.collectionView.delegate = self;
        [self.view addSubview:_collectionView];
        
        NSMutableArray *constraints = [NSMutableArray array];
        NSDictionary *views = NSDictionaryOfVariableBindings(_collectionView);
        
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_collectionView]-0-|" options:0 metrics:0 views:views]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_collectionView]-0-|" options:0 metrics:0 views:views]];
        [self.view addConstraints:constraints];
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    //  We need to know when the data source changes on the collection view so we can become the delegate for any APPLDataSource subclasses.
    [self.collectionView addObserver:self forKeyPath:@"dataSource" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:AAPLDataSourceContext];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _prepareDataSource];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UICollectionView *collectionView = self.collectionView;
    
    AAPLDataSource *dataSource = (AAPLDataSource *)collectionView.dataSource;
    if ([dataSource isKindOfClass:[AAPLDataSource class]]) {
        [dataSource registerReusableViewsWithCollectionView:collectionView];
        [dataSource setNeedsLoadContent];
    }
}

- (void)setCollectionView:(UICollectionView *)collectionView {
    
    if (_collectionView != collectionView) {
        UICollectionView *oldCollectionView = _collectionView;
        _collectionView = collectionView;
        _collectionView.delegate = self;
        
        [oldCollectionView removeObserver:self forKeyPath:@"dataSource" context:AAPLDataSourceContext];
        
        //  We need to know when the data source changes on the collection view so we can become the delegate for any APPLDataSource subclasses.
        [collectionView addObserver:self forKeyPath:@"dataSource" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:AAPLDataSourceContext];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    //  For change contexts that aren't the data source, pass them to super.
    if (AAPLDataSourceContext != context) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    UICollectionView *collectionView = object;
    id<UICollectionViewDataSource> dataSource = collectionView.dataSource;
    
    if ([dataSource isKindOfClass:[AAPLDataSource class]]) {
        AAPLDataSource *aaplDataSource = (AAPLDataSource *)dataSource;
        if (!aaplDataSource.delegate)
            aaplDataSource.delegate = self;
    }
}

- (void)_prepareDataSource {
    _dataSource = [[AAPLSegmentedDataSource alloc] init];
    
    // default styling, can override
    _dataSource.shouldDisplayDefaultHeader = NO;
    AAPLLayoutSectionMetrics *metrics = self.dataSource.defaultMetrics;
    metrics.separatorColor = [UIColor colorWithWhite:224/255.0 alpha:1];
    metrics.separatorInsets = UIEdgeInsetsZero;
    self.collectionView.dataSource = self.dataSource;
}

- (void)reloadDataSource:(BOOL)shouldReset {
    AAPLDataSource *dataSource = (AAPLDataSource *)self.collectionView.dataSource;
    if (shouldReset) {
        [dataSource resetContent];
    }
    [dataSource setNeedsLoadContent];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.collectionView.collectionViewLayout invalidateLayout];
    } completion:nil];
}

#pragma mark - AAPL Datasource delegate methods

- (void)dataSource:(AAPLDataSource *)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths {
    [self.collectionView insertItemsAtIndexPaths:indexPaths];
}

- (void)dataSource:(AAPLDataSource *)dataSource didRemoveItemsAtIndexPaths:(NSArray *)indexPaths {
    [self.collectionView deleteItemsAtIndexPaths:indexPaths];
}

- (void)dataSource:(AAPLDataSource *)dataSource didRefreshItemsAtIndexPaths:(NSArray *)indexPaths {
    [self.collectionView reloadItemsAtIndexPaths:indexPaths];
}

- (void)dataSource:(AAPLDataSource *)dataSource didInsertSections:(NSIndexSet *)sections direction:(AAPLDataSourceSectionOperationDirection)direction {
    if (!sections)  // bail if nil just to keep collection view safe and pure
        return;

    AAPLCollectionViewGridLayout *layout = (AAPLCollectionViewGridLayout *)self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:[AAPLCollectionViewGridLayout class]])
        [layout dataSource:dataSource didInsertSections:sections direction:direction];
    [self.collectionView insertSections:sections];
}

- (void)dataSource:(AAPLDataSource *)dataSource didRemoveSections:(NSIndexSet *)sections direction:(AAPLDataSourceSectionOperationDirection)direction {
    if (!sections)  // bail if nil just to keep collection view safe and pure
        return;
    
    AAPLCollectionViewGridLayout *layout = (AAPLCollectionViewGridLayout *)self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:[AAPLCollectionViewGridLayout class]])
        [layout dataSource:dataSource didRemoveSections:sections direction:direction];
    [self.collectionView deleteSections:sections];
}

- (void)dataSource:(AAPLDataSource *)dataSource didMoveSection:(NSInteger)section toSection:(NSInteger)newSection direction:(AAPLDataSourceSectionOperationDirection)direction {
    AAPLCollectionViewGridLayout *layout = (AAPLCollectionViewGridLayout *)self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:[AAPLCollectionViewGridLayout class]])
        [layout dataSource:dataSource didMoveSection:section toSection:newSection direction:direction];
    [self.collectionView moveSection:section toSection:newSection];
}

- (void)dataSource:(AAPLDataSource *)dataSource didMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {
    [self.collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
}

- (void)dataSource:(AAPLDataSource *)dataSource didRefreshSections:(NSIndexSet *)sections {
    if (!sections)  // bail if nil just to keep collection view safe and pure
        return;
    
    [self.collectionView reloadSections:sections];
}

- (void)dataSourceDidReloadData:(AAPLDataSource *)dataSource {
    [self.collectionView reloadData];
}

- (void)dataSource:(AAPLDataSource *)dataSource performBatchUpdate:(dispatch_block_t)update complete:(dispatch_block_t)complete {
    [self.collectionView performBatchUpdates:^{
        update();
    } completion:^(BOOL finished){
        if (complete) {
            complete();
        }
        [self.collectionView reloadData];
    }];
}

@end
