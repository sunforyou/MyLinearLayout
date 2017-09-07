//
//  MyGridLayout.m
//  MyLayout
//
//  Created by apple on 2017/6/19.
//  Copyright © 2017年 YoungSoft. All rights reserved.
//

#import "MyGridLayout.h"
#import "MyLayoutInner.h"
#import "MyGridNode.h"

 NSString * const kMyGridTag = @"tag";
 NSString * const kMyGridAction = @"action";
 NSString * const kMyGridActionData = @"action-data";
 NSString * const kMyGridRows = @"rows";
 NSString * const kMyGridCols = @"cols";
 NSString * const kMyGridSize = @"size";
 NSString * const kMyGridPadding = @"padding";
 NSString * const kMyGridSpace = @"space";
 NSString * const kMyGridGravity = @"gravity";
 NSString * const kMyGridPlaceholder = @"placeholder";
 NSString * const kMyGridAnchor = @"anchor";
 NSString * const kMyGridTopBorderline = @"top-borderline";
 NSString * const kMyGridBottomBorderline = @"bottom-borderline";
 NSString * const kMyGridLeftBorderline = @"left-borderline";
 NSString * const kMyGridRightBorderline = @"right-borderline";

 NSString * const kMyGridBorderlineColor = @"color";
 NSString * const kMyGridBorderlineThick = @"thick";
 NSString * const kMyGridBorderlineHeadIndent = @"head";
 NSString * const kMyGridBorderlineTailIndent = @"tail";
 NSString * const kMyGridBorderlineOffset = @"offset";


 NSString * const vMyGridSizeWrap = @"wrap";
 NSString * const vMyGridSizeFill = @"fill";


 NSString * const vMyGridGravityTop = @"top";
 NSString * const vMyGridGravityBottom = @"bottom";
 NSString * const vMyGridGravityLeft = @"left";
 NSString * const vMyGridGravityRight = @"right";
 NSString * const vMyGridGravityCenterX = @"centerX";
 NSString * const vMyGridGravityCenterY = @"centerY";
 NSString * const vMyGridGravityWidthFill = @"width";
 NSString * const vMyGridGravityHeightFill = @"height";


@interface MyViewGroupAndActionData : NSObject

@property(nonatomic, strong) NSMutableArray *viewGroup;
@property(nonatomic, strong) id actionData;

+(instancetype)viewGroup:(NSArray*)viewGroup actionData:(id)actionData;

@end

@implementation MyViewGroupAndActionData

-(instancetype)initWithViewGroup:(NSArray*)viewGroup actionData:(id)actionData
{
    self = [self init];
    if (self != nil)
    {
        _viewGroup = [NSMutableArray arrayWithArray:viewGroup];
        _actionData = actionData;
    }
    
    return self;
}

+(instancetype)viewGroup:(NSArray*)viewGroup actionData:(id)actionData
{
    return [[[self class] alloc] initWithViewGroup:viewGroup actionData:actionData];
}


@end

@interface MyGridLayout()<MyGridNode>

@property(nonatomic, weak) MyGridLayoutViewSizeClass *lastSizeClass;

@property(nonatomic, strong) NSMutableDictionary *tagsDict;
@property(nonatomic, assign) BOOL tagsDictLock;

@end


@implementation MyGridLayout

-(NSMutableDictionary*)tagsDict
{
    if (_tagsDict == nil)
    {
        _tagsDict = [NSMutableDictionary new];
    }
    
    return _tagsDict;
}

#pragma mark -- Public Method

+(id<MyGrid>)createTemplateGrid:(NSInteger)gridTag
{
    id<MyGrid> grid  =  [[MyGridNode alloc] initWithMeasure:0 superGrid:nil];
    grid.tag = gridTag;
    
    return grid;
}


//删除所有子栅格
-(void)removeGrids
{
    [self removeGridsIn:MySizeClass_hAny | MySizeClass_wAny];
}

-(void)removeGridsIn:(MySizeClass)sizeClass
{
    id<MyGridNode> lsc = (id<MyGridNode>)[self fetchLayoutSizeClass:sizeClass];
    [lsc.subGrids removeAllObjects];
    lsc.subGridsType = MySubGridsType_Unknown;
}

-(id<MyGrid>) gridContainsSubview:(UIView*)subview
{
    return [self gridHitTest:subview.center];
}

-(NSArray<UIView*>*) subviewsContainedInGrid:(id<MyGrid>)grid
{
    
    id<MyGridNode> gridNode = (id<MyGridNode>)grid;
    
#ifdef DEBUG
    NSAssert([gridNode gridLayoutView] == self, @"oops! 非栅格布局中的栅格");
#endif
    
    NSMutableArray *retSbs = [NSMutableArray new];
    NSArray *sbs = [self myGetLayoutSubviews];
    for (UIView *sbv in sbs)
    {
        if (CGRectContainsRect(gridNode.gridRect, sbv.frame))
        {
            [retSbs addObject:sbv];
        }
    }
    
    return retSbs;
}


-(void)addViewGroup:(NSArray<UIView*> *)viewGroup withActionData:(id)actionData to:(NSInteger)gridTag
{
    [self insertViewGroup:viewGroup withActionData:actionData atIndex:(NSUInteger)-1 to:gridTag];
}

-(void)insertViewGroup:(NSArray<UIView*> *)viewGroup withActionData:(id)actionData atIndex:(NSUInteger)index to:(NSInteger)gridTag
{
    if (gridTag == 0)
    {
        for (UIView *sbv in viewGroup)
        {
            [self addSubview:sbv];
        }
        
        return;
    }
    
    //...
    NSNumber *key = @(gridTag);
    NSMutableArray *viewGroupArray = [self.tagsDict objectForKey:key];
    if (viewGroupArray == nil)
    {
        viewGroupArray = [NSMutableArray new];
        [self.tagsDict setObject:viewGroupArray forKey:key];
    }
    
    MyViewGroupAndActionData *va = [MyViewGroupAndActionData viewGroup:viewGroup actionData:actionData];
    if (index == (NSUInteger)-1)
    {
        [viewGroupArray addObject:va];
    }
    else
    {
        [viewGroupArray insertObject:va atIndex:index];
    }
    
    for (UIView *sbv in viewGroup)
    {
        [self addSubview:sbv];
    }

}

-(void)moveViewGroupAtIndex:(NSUInteger)index from:(NSInteger)origGridTag to:(NSInteger)destGridTag
{
    [self moveViewGroupAtIndex:index from:origGridTag toIndex:-1 to:destGridTag];
}

-(void)moveViewGroupAtIndex:(NSUInteger)index1 from:(NSInteger)origGridTag  toIndex:(NSUInteger)index2 to:(NSInteger)destGridTag
{
    if (origGridTag == 0 || destGridTag == 0 || (origGridTag == destGridTag))
        return;
    
    if (_tagsDict == nil)
        return;
    
    NSNumber *origKey = @(origGridTag);
    NSMutableArray<MyViewGroupAndActionData*> *origViewGroupArray = [self.tagsDict objectForKey:origKey];
    
    if (index1 < origViewGroupArray.count)
    {
        
        NSNumber *destKey = @(destGridTag);
        
        NSMutableArray *destViewGroupArray = [self.tagsDict objectForKey:destKey];
        if (destViewGroupArray == nil)
        {
            destViewGroupArray = [NSMutableArray new];
            [self.tagsDict setObject:destViewGroupArray forKey:destKey];
        }
        
        if (index2 > destViewGroupArray.count)
            index2 = destViewGroupArray.count;
        
        
        MyViewGroupAndActionData *va = origViewGroupArray[index1];
        [origViewGroupArray removeObjectAtIndex:index1];
        if (origViewGroupArray.count == 0)
        {
            [self.tagsDict removeObjectForKey:origKey];
        }
        
        [destViewGroupArray insertObject:va atIndex:index2];
        
        
    }
    
    
}



-(void)removeViewGroupAtIndex:(NSUInteger)index from:(NSInteger)gridTag
{
    if (gridTag == 0)
        return;
    
    if (_tagsDict == nil)
        return;
    
    NSNumber *key = @(gridTag);
    NSMutableArray<MyViewGroupAndActionData*> *viewGroupArray = [self.tagsDict objectForKey:key];
    if (index < viewGroupArray.count)
    {
        MyViewGroupAndActionData *va = viewGroupArray[index];
        
        self.tagsDictLock = YES;
        for (UIView *sbv in va.viewGroup)
        {
            [sbv removeFromSuperview];
        }
        self.tagsDictLock = NO;
        
        
        [viewGroupArray removeObjectAtIndex:index];
        
        if (viewGroupArray.count == 0)
        {
            [self.tagsDict removeObjectForKey:key];
        }
        
    }

}



-(void)removeViewGroupFrom:(NSInteger)gridTag
{
    if (gridTag == 0)
        return;
    
    if (_tagsDict == nil)
        return;

    NSNumber *key = @(gridTag);
    NSMutableArray<MyViewGroupAndActionData*> *viewGroupArray = [self.tagsDict objectForKey:key];
    if (viewGroupArray != nil)
    {
        self.tagsDictLock = YES;
        for (MyViewGroupAndActionData * va in viewGroupArray)
        {
            for (UIView *sbv in va.viewGroup)
            {
                [sbv removeFromSuperview];
            }
        }
        
        self.tagsDictLock = NO;
        
        [self.tagsDict removeObjectForKey:key];
    }
    
}



-(void)exchangeViewGroupAtIndex:(NSUInteger)index1 from:(NSInteger)gridTag1  withViewGroupAtIndex:(NSUInteger)index2 from:(NSInteger)gridTag2
{
    if (gridTag1 == 0 || gridTag2 == 0)
        return;
    
    NSNumber *key1 = @(gridTag1);
    NSMutableArray<MyViewGroupAndActionData*> *viewGroupArray1 = [self.tagsDict objectForKey:key1];
    
    NSMutableArray<MyViewGroupAndActionData*> *viewGroupArray2 = nil;
    
    if (gridTag1 == gridTag2)
        viewGroupArray2 = viewGroupArray1;
    else
    {
        NSNumber *key2 = @(gridTag2);
        viewGroupArray2 = [self.tagsDict objectForKey:key2];
    }
    
    if (index1 < viewGroupArray1.count && index2 < viewGroupArray2.count)
    {
        self.tagsDictLock = YES;
        
        if (gridTag1 == gridTag2)
        {
            [viewGroupArray1 exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
        }
        else
        {
            MyViewGroupAndActionData *va1 = viewGroupArray1[index1];
            MyViewGroupAndActionData *va2 = viewGroupArray2[index2];
            
            [viewGroupArray1 removeObjectAtIndex:index1];
            [viewGroupArray2 removeObjectAtIndex:index2];
            
            [viewGroupArray1 insertObject:va2 atIndex:index1];
            [viewGroupArray2 insertObject:va1 atIndex:index2];
        }
        
        
        self.tagsDictLock = NO;
        
        
    }

    
}


-(NSUInteger)viewGroupCountOf:(NSInteger)gridTag
{
    if (gridTag == 0)
        return 0;
    
    if (_tagsDict == nil)
        return 0;
    
    NSNumber *key = @(gridTag);
    NSMutableArray<MyViewGroupAndActionData*> *viewGroupArray = [self.tagsDict objectForKey:key];

    return viewGroupArray.count;
}



-(NSArray<UIView*> *)viewGroupAtIndex:(NSUInteger)index from:(NSInteger)gridTag
{
    if (gridTag == 0)
        return nil;
    
    if (_tagsDict == nil)
        return nil;

    
    NSNumber *key = @(gridTag);
    NSMutableArray<MyViewGroupAndActionData*> *viewGroupArray = [self.tagsDict objectForKey:key];
    if (index < viewGroupArray.count)
    {
        return viewGroupArray[index].viewGroup;
    }
    
    return nil;
}








#pragma mark -- MyGrid

-(id)actionData
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    return lsc.actionData;
}

-(void)setActionData:(id)actionData
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    lsc.actionData = actionData;
}

//添加行。返回新的栅格。
-(id<MyGrid>)addRow:(CGFloat)measure
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    id<MyGridNode> node = (id<MyGridNode>)[lsc addRow:measure];
    node.superGrid = self;
    return node;
}

//添加列。返回新的栅格。
-(id<MyGrid>)addCol:(CGFloat)measure
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    id<MyGridNode> node = (id<MyGridNode>)[lsc addCol:measure];
    node.superGrid = self;
    return node;
}

-(id<MyGrid>)addRowGrid:(id<MyGrid>)grid
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    id<MyGridNode> node = (id<MyGridNode>)[lsc addRowGrid:grid];
    node.superGrid = self;
    return node;
}

-(id<MyGrid>)addColGrid:(id<MyGrid>)grid
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    id<MyGridNode> node = (id<MyGridNode>)[lsc addColGrid:grid];
    node.superGrid = self;
    return node;
}

-(id<MyGrid>)addRowGrid:(id<MyGrid>)grid measure:(CGFloat)measure
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    id<MyGridNode> node = (id<MyGridNode>)[lsc addRowGrid:grid measure:measure];
    node.superGrid = self;
    return node;

}

-(id<MyGrid>)addColGrid:(id<MyGrid>)grid measure:(CGFloat)measure
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    id<MyGridNode> node = (id<MyGridNode>)[lsc addColGrid:grid measure:measure];
    node.superGrid = self;
    return node;

}



-(id<MyGrid>)cloneGrid
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    return [lsc cloneGrid];
}

-(void)removeFromSuperGrid
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    return [lsc removeFromSuperGrid];
    
}

-(id<MyGrid>)superGrid
{
    MyGridLayout *lsc = self.myCurrentSizeClass;

    return lsc.superGrid;
}

-(void)setSuperGrid:(id<MyGridNode>)superGrid
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    lsc.superGrid = superGrid;
}

-(BOOL)placeholder
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    
    return lsc.placeholder;
}

-(void)setPlaceholder:(BOOL)placeholder
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    lsc.placeholder = placeholder;
}

-(BOOL)anchor
{
    
    MyGridLayout *lsc = self.myCurrentSizeClass;
    
    return lsc.anchor;
}

-(void)setAnchor:(BOOL)anchor
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    lsc.anchor = anchor;
}

-(NSDictionary*)gridDictionary
{
    return nil;
}


/*
 栅格的描述。你可以用格子描述语言来建立格子
 
 @code
 
 {rows:[
 
 {size:100, size:"100%", size:"-20%",size:"wrap", size:"fill", padding:"{10,10,10,10}", space:10.0, gravity:@"top|bottom|left|right|centerX|centerY|width|height","top-borderline":{"color":"#AAA",thick:1.0, head:1.0, tail:1.0, offset:1} },
 {},
 ]
 }
 
 @endcode
 
 */
-(void)setGridDictionary:(NSDictionary *)gridDictionary
{
    if (gridDictionary == nil || gridDictionary.count <= 0) return;
    
    if ([gridDictionary objectForKey:kMyGridRows]) {
        
        [self removeGrids];
    
        id temp = [gridDictionary objectForKey:kMyGridRows];
        if ([temp isKindOfClass:[NSArray<NSDictionary *> class]]) {
            
            for (NSDictionary *dic in temp) {
                
                
            }
            
        }
        
    }
    
}

#pragma mark -- MyGridNode


-(NSMutableArray<id<MyGridNode>> *)subGrids
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    return (NSMutableArray<id<MyGridNode>> *)(lsc.subGrids);
}

-(void)setSubGrids:(NSMutableArray<id<MyGridNode>> *)subGrids
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    lsc.subGrids = subGrids;
}

-(MySubGridsType)subGridsType
{
    MyGridLayout *lsc = self.myCurrentSizeClass;

    return lsc.subGridsType;
}

-(void)setSubGridsType:(MySubGridsType)subGridsType
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    lsc.subGridsType = subGridsType;
}


-(CGFloat)gridMeasure
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    return lsc.gridMeasure;
}

-(void)setGridMeasure:(CGFloat)gridMeasure
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    lsc.gridMeasure = gridMeasure;
}

-(CGRect)gridRect
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    return lsc.gridRect;
}

-(void)setGridRect:(CGRect)gridRect
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    lsc.gridRect = gridRect;
}

//更新格子尺寸。
-(CGFloat)updateGridSize:(CGSize)superSize superGrid:(id<MyGridNode>)superGrid withMeasure:(CGFloat)measure
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    return [lsc updateGridSize:superSize superGrid:superGrid withMeasure:measure];
}

-(CGFloat)updateGridOrigin:(CGPoint)superOrigin superGrid:(id<MyGridNode>)superGrid withOffset:(CGFloat)offset
{
    MyGridLayout *lsc = self.myCurrentSizeClass;

    return [lsc updateGridOrigin:superOrigin superGrid:superGrid withOffset:offset];
}



-(UIView*)gridLayoutView
{
    return self;
}


-(void)setBorderlineNeedLayoutIn:(CGRect)rect withLayer:(CALayer *)layer
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    [lsc setBorderlineNeedLayoutIn:rect withLayer:layer];

}

-(void)showBorderline:(BOOL)show
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    [lsc showBorderline:show];

}

-(id<MyGrid>)gridHitTest:(CGPoint)point
{
    MyGridLayout *lsc = self.myCurrentSizeClass;
    return [lsc gridHitTest:point];
}


#pragma mark -- Touches Event

-(id<MyGridNode>)myBestHitGrid:(NSSet *)touches
{
    MySizeClass sizeClass = [self myGetGlobalSizeClass];
    id<MyGridNode> bestSC = (id<MyGridNode>)[self myBestSizeClass:sizeClass];
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    return  [bestSC gridHitTest:point];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    [[self myBestHitGrid:touches] touchesBegan:touches withEvent:event];
    [super touchesBegan:touches withEvent:event];
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self myBestHitGrid:touches] touchesMoved:touches withEvent:event];
    [super touchesMoved:touches withEvent:event];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self myBestHitGrid:touches] touchesEnded:touches withEvent:event];
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self myBestHitGrid:touches] touchesCancelled:touches withEvent:event];
    [super touchesCancelled:touches withEvent:event];
}



#pragma mark -- Override Method

-(void)dealloc
{
    //这里提前释放所有的数据，防止willRemoveSubview中重复删除。。
    _tagsDict = nil;
}

-(void)removeAllSubviews
{
    _tagsDict = nil;  //提前释放所有绑定的数据
    [super removeAllSubviews];
}

-(void)willRemoveSubview:(UIView *)subview
{
    [super willRemoveSubview:subview];
    
    //如果子试图在样式里面则从样式里面删除
    if (_tagsDict != nil && !self.tagsDictLock)
    {
        [_tagsDict enumerateKeysAndObjectsUsingBlock:^(id   key, id   obj, BOOL *  stop) {
            
            NSMutableArray *viewGroupArray = (NSMutableArray*)obj;
            NSInteger sbsCount = viewGroupArray.count;
            for (NSInteger j = 0; j < sbsCount; j++)
            {
                MyViewGroupAndActionData *va = viewGroupArray[j];
                NSInteger sbvCount = va.viewGroup.count;
                for (NSInteger i = 0; i < sbvCount; i++)
                {
                    if (va.viewGroup[i] == subview)
                    {
                        [va.viewGroup removeObjectAtIndex:i];
                        break;
                        *stop = YES;
                    }
                }
                
                if (va.viewGroup.count == 0)
                {
                    [viewGroupArray removeObjectAtIndex:j];
                    break;
                }
                
                if (*stop)
                    break;
            }
            
            
        }];
    }
}


-(CGSize)calcLayoutRect:(CGSize)size isEstimate:(BOOL)isEstimate pHasSubLayout:(BOOL*)pHasSubLayout sizeClass:(MySizeClass)sizeClass sbs:(NSMutableArray*)sbs
{
    CGSize selfSize = [super calcLayoutRect:size isEstimate:isEstimate pHasSubLayout:pHasSubLayout sizeClass:sizeClass sbs:sbs];
    
    if (sbs == nil)
        sbs = [self myGetLayoutSubviews];
    
    
    MyFrame *myFrame = self.myFrame;
    
    MyGridLayout *lsc =  [self myCurrentSizeClassFrom:myFrame];
    
    //只有在非评估，并且当sizeclass的数量大于1个，并且当前的sizeclass和lastSizeClass不一致的时候
    if (!isEstimate && myFrame.multiple)
    {
        //将子栅格中的layer隐藏。
        if (self.lastSizeClass != nil && ((MyGridLayoutViewSizeClass*)lsc) != self.lastSizeClass)
            [((id<MyGridNode>)self.lastSizeClass) showBorderline:NO];
        
        self.lastSizeClass = (MyGridLayoutViewSizeClass*)lsc;
    }
    
    
    //设置根格子的rect为布局视图的大小。
    lsc.gridRect = CGRectMake(0, 0, selfSize.width, selfSize.height);
    
    
    NSMutableDictionary *tagKeyIndexDict = [NSMutableDictionary dictionaryWithCapacity:self.tagsDict.count];
    for (NSNumber *key in self.tagsDict)
    {
        [tagKeyIndexDict setObject:@(0) forKey:key];
    }
    
    //遍历尺寸
    NSInteger index = 0;
    CGFloat selfMeasure = [self myTraversalGridSize:lsc gridSize:selfSize lsc:lsc sbs:sbs pIndex:&index tagViewGroupIndexDict:tagKeyIndexDict tagViewGroup:nil pTagIndex:nil];
    if (lsc.wrapContentHeight)
    {
        selfSize.height =  selfMeasure;
    }
    
    if (lsc.wrapContentWidth)
    {
        selfSize.width = selfMeasure;
    }
    
    //遍历位置。
    for (NSNumber *key in self.tagsDict)
    {
        [tagKeyIndexDict setObject:@(0) forKey:key];
    }
    
    NSEnumerator<UIView*> *enumerator = sbs.objectEnumerator;
    [self myTraversalGridOrigin:lsc gridOrigin:CGPointMake(0, 0) lsc:lsc sbvEnumerator:enumerator tagViewGroupIndexDict:tagKeyIndexDict tagSbvEnumerator:nil  isEstimate:isEstimate sizeClass:sizeClass pHasSubLayout:pHasSubLayout];
    
    
    //遍历那些还剩余的然后设置为0.
    [tagKeyIndexDict enumerateKeysAndObjectsUsingBlock:^(id key, NSNumber *viewGroupIndexNumber, BOOL *  stop) {
        
        NSArray<MyViewGroupAndActionData*> *viewGroupArray = self.tagsDict[key];
        NSInteger viewGroupIndex = viewGroupIndexNumber.integerValue;
        for (NSInteger i = viewGroupIndex; i < viewGroupArray.count; i++)
        {
            MyViewGroupAndActionData *va = viewGroupArray[i];
            for (UIView *sbv in va.viewGroup)
            {
                sbv.myFrame.frame = CGRectZero;
            }
        }
    }];
    
    
    //处理那些剩余没有放入格子的子视图的frame设置为0
  /*  for (UIView *sbv = enumerator.nextObject; sbv; sbv = enumerator.nextObject)
    {
        sbv.myFrame.frame = CGRectZero;
    }
    */
    
    [self myAdjustLayoutSelfSize:&selfSize lsc:lsc];
    
    [self myAdjustSubviewsRTLPos:sbs selfWidth:selfSize.width];
    
    return [self myAdjustSizeWhenNoSubviews:selfSize sbs:sbs lsc:lsc];
}

-(id)createSizeClassInstance
{
    return [MyGridLayoutViewSizeClass new];
}

#pragma mark -- Private Method

//遍历位置
-(void)myTraversalGridOrigin:(id<MyGridNode>)grid  gridOrigin:(CGPoint)gridOrigin lsc:(MyGridLayout*)lsc sbvEnumerator:(NSEnumerator<UIView*>*)sbvEnumerator tagViewGroupIndexDict:(NSMutableDictionary*)tagViewGroupIndexDict tagSbvEnumerator:(NSEnumerator<UIView*>*)tagSbvEnumerator isEstimate:(BOOL)isEstimate sizeClass:(MySizeClass)sizeClass pHasSubLayout:(BOOL*)pHasSubLayout
{
    //这要优化减少不必要的空数组的建立。。
    NSArray<id<MyGridNode>> * subGrids = nil;
    if (grid.subGridsType != MySubGridsType_Unknown)
         subGrids = grid.subGrids;

    //绘制边界线。。
    if (!isEstimate)
    {
        [grid setBorderlineNeedLayoutIn:grid.gridRect withLayer:self.layer];
    }
    
    
    if (grid.tag != 0)
    {
        NSNumber *key = @(grid.tag);

        NSMutableArray<MyViewGroupAndActionData*> *viewGroupArray = [self.tagsDict objectForKey:key];
        NSNumber *viewGroupIndex = [tagViewGroupIndexDict objectForKey:key];
        if (viewGroupArray != nil && viewGroupIndex != nil && viewGroupIndex.integerValue < viewGroupArray.count)
        {
            //这里将动作的数据和栅格进行关联。
            if (viewGroupArray[viewGroupIndex.integerValue].actionData != nil)
                grid.actionData = viewGroupArray[viewGroupIndex.integerValue].actionData;
            
            tagSbvEnumerator =  viewGroupArray[viewGroupIndex.integerValue].viewGroup.objectEnumerator;
            sbvEnumerator = nil;  //因为这里要遍历标签的视图组，所以所有子视图的枚举将被置空
            [tagViewGroupIndexDict setObject:@(viewGroupIndex.integerValue + 1) forKey:key];
        }
        else
        {
            tagSbvEnumerator = nil;
            NSLog(@"0");
        }
    }

    
    
    //处理叶子节点。
    if (grid.anchor || (subGrids.count == 0 && !grid.placeholder))
    {
        //设置子视图的位置和尺寸。。
        UIView *sbv = sbvEnumerator.nextObject;
        
        UIView *tagSbv = tagSbvEnumerator.nextObject;
        if (tagSbv != nil)
            sbv = tagSbv;
        
        if (sbv != nil)
        {
            //调整位置和尺寸。。。
            MyFrame *sbvmyFrame = sbv.myFrame;
            UIView *sbvsc = [self myCurrentSizeClassFrom:sbvmyFrame];
            
            //取垂直和水平对齐
            MyGravity vertGravity = grid.gravity & MyGravity_Horz_Mask;
            if (vertGravity == MyGravity_None)
                vertGravity = MyGravity_Vert_Fill;
            
            MyGravity horzGravity = grid.gravity & MyGravity_Vert_Mask;
            if (horzGravity == MyGravity_None)
                horzGravity = MyGravity_Horz_Fill;
            
            CGFloat paddingTop = grid.padding.top;
            CGFloat paddingLeading = [MyBaseLayout isRTL] ? grid.padding.right : grid.padding.left;
            CGFloat paddingBottom = grid.padding.bottom;
            CGFloat paddingTrailing = [MyBaseLayout isRTL] ? grid.padding.left : grid.padding.right;
            
            [self myAdjustSubviewWrapContentSet:sbv isEstimate:isEstimate sbvmyFrame:sbvmyFrame sbvsc:sbvsc selfSize:grid.gridRect.size sizeClass:sizeClass pHasSubLayout:pHasSubLayout];
            
            
            [self myCalcSubViewRect:sbv sbvsc:sbvsc sbvmyFrame:sbvmyFrame lsc:lsc vertGravity:vertGravity horzGravity:horzGravity inSelfSize:grid.gridRect.size paddingTop:paddingTop paddingLeading:paddingLeading paddingBottom:paddingBottom paddingTrailing:paddingTrailing pMaxWrapSize:NULL];
            
            sbvmyFrame.leading += gridOrigin.x;
            sbvmyFrame.top += gridOrigin.y;
            
        }
    }



    //处理子格子的位置。
    
    CGFloat offset = 0;
    if (grid.subGridsType == MySubGridsType_Col)
    {
        offset = gridOrigin.x + grid.padding.left;
        
        MyGravity horzGravity = grid.gravity & MyGravity_Vert_Mask;
        if (horzGravity == MyGravity_Horz_Center || horzGravity == MyGravity_Horz_Right)
        {
            //得出所有子栅格的宽度综合
            CGFloat subGridsWidth = 0;
            for (id<MyGridNode> sbvGrid in subGrids)
            {
                subGridsWidth += sbvGrid.gridRect.size.width;
            }
            
            if (subGrids.count > 1)
                subGridsWidth += grid.subviewSpace * (subGrids.count - 1);

            
            if (horzGravity == MyGravity_Horz_Center)
            {
                offset += (grid.gridRect.size.width - grid.padding.left - grid.padding.right - subGridsWidth)/2;
            }
            else
            {
                offset += grid.gridRect.size.width - grid.padding.left - grid.padding.right - subGridsWidth;
            }
        }
        
        
    }
    else if (grid.subGridsType == MySubGridsType_Row)
    {
        offset = gridOrigin.y + grid.padding.top;
        
        MyGravity vertGravity = grid.gravity & MyGravity_Horz_Mask;
        if (vertGravity == MyGravity_Vert_Center || vertGravity == MyGravity_Vert_Bottom)
        {
            //得出所有子栅格的宽度综合
            CGFloat subGridsHeight = 0;
            for (id<MyGridNode> sbvGrid in subGrids)
            {
                subGridsHeight += sbvGrid.gridRect.size.height;
            }
            
            if (subGrids.count > 1)
                subGridsHeight += grid.subviewSpace * (subGrids.count - 1);
            
            if (vertGravity == MyGravity_Vert_Center)
            {
                offset += (grid.gridRect.size.height - grid.padding.top - grid.padding.bottom - subGridsHeight)/2;
            }
            else
            {
                offset += grid.gridRect.size.height - grid.padding.top - grid.padding.bottom - subGridsHeight;
            }
        }
        
    }
    else
    {
        
    }
    
    

    for (id<MyGridNode> sbvGrid in subGrids)
    {
        offset += [sbvGrid updateGridOrigin:gridOrigin superGrid:grid withOffset:offset];
        offset += grid.subviewSpace;
        [self myTraversalGridOrigin:sbvGrid gridOrigin:sbvGrid.gridRect.origin lsc:lsc sbvEnumerator:sbvEnumerator tagViewGroupIndexDict:tagViewGroupIndexDict tagSbvEnumerator:((sbvGrid.tag != 0)? nil: tagSbvEnumerator) isEstimate:isEstimate sizeClass:sizeClass pHasSubLayout:pHasSubLayout];
    }
    
  /*  if (grid.tag != 0)
    {
        for (UIView *sbv = tagSbvEnumerator.nextObject; sbv; sbv = tagSbvEnumerator.nextObject)
        {
            sbv.myFrame.frame = CGRectZero;
        }
    }
    */
}

-(void)myBlankTraverse:(id<MyGridNode>)grid sbs:(NSArray<UIView*>*)sbs pIndex:(NSInteger*)pIndex tagSbs:(NSArray<UIView*> *)tagSbs pTagIndex:(NSInteger*)pTagIndex
{
    NSArray<id<MyGridNode>> *subGrids = nil;
    if (grid.subGridsType != MySubGridsType_Unknown)
        subGrids = grid.subGrids;
    
    if (grid.anchor || (subGrids.count == 0 && !grid.placeholder))
    {
        *pIndex = *pIndex + 1;
        
        if (grid.tag == 0 && pTagIndex != NULL)
        {
            *pTagIndex = *pTagIndex + 1;
        }
    }
    
    for (id<MyGridNode> sbvGrid in subGrids)
    {
        [self myBlankTraverse:sbvGrid sbs:sbs pIndex:pIndex tagSbs:tagSbs pTagIndex:(grid.tag != 0)? NULL : pTagIndex];
    }
}

//遍历尺寸。
-(CGFloat)myTraversalGridSize:(id<MyGridNode>)grid gridSize:(CGSize)gridSize lsc:(MyGridLayout*)lsc sbs:(NSArray<UIView*>*)sbs pIndex:(NSInteger*)pIndex tagViewGroupIndexDict:(NSMutableDictionary*)tagViewGroupIndexDict  tagViewGroup:(NSArray<UIView*>*)tagViewGroup  pTagIndex:(NSInteger*)pTagIndex
{
    NSArray<id<MyGridNode>> *subGrids = nil;
    if (grid.subGridsType != MySubGridsType_Unknown)
         subGrids = grid.subGrids;

    UIEdgeInsets padding = grid.padding;
    CGFloat fixedMeasure = 0;  //固定部分的尺寸
    CGFloat validMeasure = 0;  //整体有效的尺寸
    if (subGrids.count > 1)
        fixedMeasure += (subGrids.count - 1) * grid.subviewSpace;
    
    if (grid.subGridsType == MySubGridsType_Col)
    {
        fixedMeasure += padding.left + padding.right;
        validMeasure = grid.gridRect.size.width - fixedMeasure;
    }
    else if(grid.subGridsType == MySubGridsType_Row)
    {
        fixedMeasure += padding.top + padding.bottom;
        validMeasure = grid.gridRect.size.height - fixedMeasure;
    }
    else;
    
    
    //得到匹配的form
    if (grid.tag != 0)
    {
        NSNumber *key = @(grid.tag);
        NSMutableArray<MyViewGroupAndActionData*> *viewGroupArray = [self.tagsDict objectForKey:key];
        NSNumber *viewGroupIndex = [tagViewGroupIndexDict objectForKey:key];
        if (viewGroupArray != nil && viewGroupIndex != nil && viewGroupIndex.integerValue < viewGroupArray.count)
        {
            tagViewGroup = viewGroupArray[viewGroupIndex.integerValue].viewGroup;
            NSInteger tagIndex = 0;
            pTagIndex = &tagIndex;
            
            [tagViewGroupIndexDict setObject:@(viewGroupIndex.integerValue + 1) forKey:key];
        }
        else
        {
            tagViewGroup = nil;
            pTagIndex = NULL;
        }
    }

    
    //叶子节点
    if (grid.anchor || (subGrids.count == 0 && !grid.placeholder))
    {
        NSArray *tempSbs = sbs;
        NSInteger *pTempIndex = pIndex;
        
        if (tagViewGroup != nil && pTagIndex != NULL)
        {
            tempSbs = tagViewGroup;
            pTempIndex = pTagIndex;
        }
        
        //如果尺寸是包裹
        if (grid.gridMeasure == MyLayoutSize.wrap)
        {
            if (*pTempIndex < tempSbs.count)
            {
                //加这个条件是根栅格如果是叶子栅格的话不处理这种情况。
                if (grid.superGrid != nil)
                {
                    UIView *sbv = tempSbs[*pTempIndex];
                    
                    MyFrame *sbvmyFrame = sbv.myFrame;
                    UIView *sbvsc = [self myCurrentSizeClassFrom:sbvmyFrame];
                    sbvmyFrame.frame = sbv.bounds;

                    //如果子视图不设置任何约束但是又是包裹的则这里特殊处理。
                    if (sbvsc.widthSizeInner == nil && sbvsc.heightSizeInner == nil && !sbvsc.wrapContentSize)
                    {
                        CGSize size = CGSizeZero;
                        if (grid.superGrid.subGridsType == MySubGridsType_Row)
                        {
                            size.width = gridSize.width - padding.left - padding.right;
                        }
                        else
                        {
                            size.height = gridSize.height - padding.top - padding.bottom;
                        }
                        
                        size = [sbv sizeThatFits:size];
                        sbvmyFrame.width = size.width;
                        sbvmyFrame.height = size.height;
                    }
                    else
                    {
                        
                        [self myCalcSizeOfWrapContentSubview:sbv sbvsc:sbvsc sbvmyFrame:sbvmyFrame];
                        
                        [self myCalcSubViewRect:sbv sbvsc:sbvsc sbvmyFrame:sbvmyFrame lsc:lsc vertGravity:MyGravity_None horzGravity:MyGravity_None inSelfSize:grid.gridRect.size paddingTop:padding.top paddingLeading:padding.left paddingBottom:padding.bottom paddingTrailing:padding.right pMaxWrapSize:NULL];
                    }

                    if (grid.superGrid.subGridsType == MySubGridsType_Row)
                    {
                        fixedMeasure = padding.top + padding.bottom + sbvmyFrame.height;
                    }
                    else
                    {
                        fixedMeasure = padding.left + padding.right + sbvmyFrame.width;
                    }
                }
            }
        }
        
        //索引加1跳转到下一个节点。
        if (tagViewGroup != nil &&  pTagIndex != NULL)
        {
            *pTempIndex = *pTempIndex + 1;
        }
        
        *pIndex = *pIndex + 1;
    }

    
    if (subGrids.count > 0)
    {
        
        NSMutableArray<id<MyGridNode>> *weightSubGrids = [NSMutableArray new];  //比重尺寸子格子数组
        NSMutableArray<NSNumber*> *weightSubGridsIndexs = [NSMutableArray new]; //比重尺寸格子的开头子视图位置索引
        NSMutableArray<NSNumber*> *weightSubGridsTagIndexs = [NSMutableArray new]; //比重尺寸格子的开头子视图位置索引
        
        
        NSMutableArray<id<MyGridNode>> *fillSubGrids = [NSMutableArray new];    //填充尺寸格子数组
        NSMutableArray<NSNumber*> *fillSubGridsIndexs = [NSMutableArray new];   //填充尺寸格子的开头子视图位置索引
        NSMutableArray<NSNumber*> *fillSubGridsTagIndexs = [NSMutableArray new];   //填充尺寸格子的开头子视图位置索引
        
        
        //包裹尺寸先遍历所有子格子
        CGSize gridSize2 = gridSize;
        if (grid.subGridsType == MySubGridsType_Row)
        {
            gridSize2.width -= (padding.left + padding.right);
        }
        else
        {
            gridSize2.height -= (padding.top + padding.bottom);
        }
        
        for (id<MyGridNode> sbvGrid in subGrids)
        {
            if (sbvGrid.gridMeasure == MyLayoutSize.wrap)
            {
                
                CGFloat gridMeasure = [self myTraversalGridSize:sbvGrid gridSize:gridSize2 lsc:lsc sbs:sbs pIndex:pIndex tagViewGroupIndexDict:tagViewGroupIndexDict tagViewGroup:tagViewGroup pTagIndex:pTagIndex];
                fixedMeasure += [sbvGrid updateGridSize:gridSize2 superGrid:grid  withMeasure:gridMeasure];
                
            }
            else if (sbvGrid.gridMeasure >= 1)
            {
                fixedMeasure += [sbvGrid updateGridSize:gridSize2 superGrid:grid withMeasure:sbvGrid.gridMeasure];
                
                //遍历儿子节点。。
                [self myTraversalGridSize:sbvGrid gridSize:sbvGrid.gridRect.size lsc:lsc sbs:sbs pIndex:pIndex tagViewGroupIndexDict:tagViewGroupIndexDict tagViewGroup:tagViewGroup pTagIndex:pTagIndex];
                
            }
            else if (sbvGrid.gridMeasure > 0 && sbvGrid.gridMeasure < 1)
            {
                fixedMeasure += [sbvGrid updateGridSize:gridSize2 superGrid:grid withMeasure:validMeasure * sbvGrid.gridMeasure];
                
                //遍历儿子节点。。
                [self myTraversalGridSize:sbvGrid gridSize:sbvGrid.gridRect.size lsc:lsc sbs:sbs pIndex:pIndex tagViewGroupIndexDict:tagViewGroupIndexDict tagViewGroup:tagViewGroup pTagIndex:pTagIndex];
                
            }
            else if (sbvGrid.gridMeasure < 0 && sbvGrid.gridMeasure > -1)
            {
                [weightSubGrids addObject:sbvGrid];
                [weightSubGridsIndexs addObject:@(*pIndex)];
                
                if (pTagIndex != NULL)
                {
                    [weightSubGridsTagIndexs addObject:@(*pTagIndex)];
                }
                
                //这里面空转一下。
                [self myBlankTraverse:sbvGrid sbs:sbs pIndex:pIndex tagSbs:tagViewGroup pTagIndex:pTagIndex];
                
                
            }
            else if (sbvGrid.gridMeasure == MyLayoutSize.fill)
            {
                [fillSubGrids addObject:sbvGrid];
                
                [fillSubGridsIndexs addObject:@(*pIndex)];
                
                if (pTagIndex != NULL)
                {
                    [fillSubGridsTagIndexs addObject:@(*pTagIndex)];
                }
                
                //这里面空转一下。
                [self myBlankTraverse:sbvGrid sbs:sbs pIndex:pIndex tagSbs:tagViewGroup pTagIndex:pTagIndex];
            }
            else
            {
                NSAssert(0, @"oops!");
            }
        }
        
        
        //算出剩余的尺寸。
        BOOL hasTagIndex = (pTagIndex != NULL);
        CGFloat remainedMeasure = 0;
        if (grid.subGridsType == MySubGridsType_Col)
        {
            remainedMeasure = grid.gridRect.size.width - fixedMeasure;
        }
        else if (grid.subGridsType == MySubGridsType_Row)
        {
            remainedMeasure = grid.gridRect.size.height - fixedMeasure;
        }
        else;
        
        NSInteger weightSubGridCount = weightSubGrids.count;
        if (weightSubGridCount > 0)
        {
            for (NSInteger i = 0; i < weightSubGridCount; i++)
            {
                id<MyGridNode> sbvGrid = weightSubGrids[i];
                remainedMeasure -= [sbvGrid updateGridSize:gridSize2 superGrid:grid withMeasure:-1 * remainedMeasure * sbvGrid.gridMeasure];
                
                NSInteger index = weightSubGridsIndexs[i].integerValue;
                if (hasTagIndex)
                {
                    NSInteger tagIndex = weightSubGridsTagIndexs[i].integerValue;
                    pTagIndex = &tagIndex;
                }
                else
                {
                    pTagIndex = NULL;
                }
                
                [self myTraversalGridSize:sbvGrid gridSize:sbvGrid.gridRect.size lsc:lsc sbs:sbs pIndex:&index tagViewGroupIndexDict:tagViewGroupIndexDict tagViewGroup:tagViewGroup pTagIndex:pTagIndex];
            }
        }
        
        NSInteger fillSubGridsCount = fillSubGrids.count;
        if (fillSubGridsCount > 0)
        {
            NSInteger totalCount = fillSubGridsCount;
            for (NSInteger i = 0; i < fillSubGridsCount; i++)
            {
                id<MyGridNode> sbvGrid = fillSubGrids[i];
                remainedMeasure -= [sbvGrid updateGridSize:gridSize2 superGrid:grid withMeasure:_myCGFloatRound(remainedMeasure * (1.0/totalCount))];
                totalCount -= 1;
                
                NSInteger index = fillSubGridsIndexs[i].integerValue;
                
                if (hasTagIndex)
                {
                    NSInteger tagIndex = fillSubGridsTagIndexs[i].integerValue;
                    pTagIndex = &tagIndex;
                }
                else
                {
                    pTagIndex = nil;
                }
                
                [self myTraversalGridSize:sbvGrid gridSize:sbvGrid.gridRect.size lsc:lsc sbs:sbs pIndex:&index tagViewGroupIndexDict:tagViewGroupIndexDict tagViewGroup:tagViewGroup pTagIndex:pTagIndex];
            }
        }
    }
    return fixedMeasure;
}


@end
