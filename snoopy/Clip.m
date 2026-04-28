//
//  Clip.m
//  snoopy
//
//  Created by dillon on 2025/1/17.
//

#import "Clip.h"

@implementation Clip

+ (NSArray<Clip *> *)loadClips {
    NSString *resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    NSArray<NSString *> *files = [fileManager contentsOfDirectoryAtPath:resourcePath error:&error];
    if (error) {
        NSLog(@"Error reading Resources directory: %@", error.localizedDescription);
        return @[];
    }
    
    NSPredicate *movFilter = [NSPredicate predicateWithFormat:@"self ENDSWITH[c] '.mov'"];
    NSArray<NSString *> *movFiles = [[files filteredArrayUsingPredicate:movFilter] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    
    NSMutableDictionary<NSString *, Clip *> *clipsDict = [NSMutableDictionary dictionary];
    
    for (NSString *file in movFiles) {
        NSString *groupName = (file.length >= 9) ? [file substringToIndex:9] : file;
//        NSString *filePath = [resourcePath stringByAppendingPathComponent:file];
        
        // blank video??? alpha channel!!!
//        if ([file containsString:@"101_WE001"]) {
//            continue;
//        }
        Clip *clip = clipsDict[groupName];
        if (!clip) {
            clip = [[Clip alloc] init];
            clip.name = groupName;
            clipsDict[groupName] = clip;
        }
        
        BOOL checked = NO;
        if ([file containsString:@"Intro"]) {
            checked = YES;
            clip.startURL = file;
            if ([file containsString:@"From"]) {
                NSString *fileNameWithoutExtension = [file stringByDeletingPathExtension];
                clip.from = [fileNameWithoutExtension substringFromIndex:(fileNameWithoutExtension.length - 5)];
            }
        }
        if ([file containsString:@"Loop"]) {
            checked = YES;
            clip.loopURL = file;
            clip.repeat = (arc4random() % 3) + 3;
        }
        if ([file containsString:@"Outro"]) {
            checked = YES;
            clip.endURL = file;
            if ([file containsString:@"To"]) {
                NSString *fileNameWithoutExtension = [file stringByDeletingPathExtension];
                clip.to = [fileNameWithoutExtension substringFromIndex:(fileNameWithoutExtension.length - 5)];
            }
        }
        if (!checked) {
            checked = YES;
            NSMutableArray *others = clip.others ? [clip.others mutableCopy] : [NSMutableArray array];
            [others addObject:file];
            clip.others = [others copy];
        }
    }
    return clipsDict.allValues;
}

+ (NSArray<Clip *> *)randomizedClips:(NSArray<Clip *> *)clips {
    NSMutableArray<Clip *> *mutableClips = [clips mutableCopy];
    NSMutableArray<Clip *> *shuffledArray = [NSMutableArray array];
    // Fisher-Yates 洗牌：先随机打乱数组
    for (NSUInteger i = mutableClips.count - 1; i > 0; i--) {
        NSUInteger j = arc4random_uniform((uint32_t)(i + 1));
        [mutableClips exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
    
    Clip *lastClip = nil;
    while (mutableClips.count > 0) {
        // 有 50% 的概率强制匹配 `from` 和 `to`
        BOOL enforceMatching = arc4random_uniform(2) == 0;
        Clip *nextClip = nil;
        
        if (enforceMatching && lastClip && lastClip.to) {
            NSUInteger matchIndex = [mutableClips indexOfObjectPassingTest:^BOOL(Clip * _Nonnull clip, NSUInteger idx, BOOL * _Nonnull stop) {
                return clip.from && [clip.from isEqualToString:lastClip.to];
            }];
            
            if (matchIndex != NSNotFound) {
                nextClip = mutableClips[matchIndex];
                [mutableClips removeObjectAtIndex:matchIndex];
            }
        }
        if (!nextClip) {
            nextClip = mutableClips.firstObject;
            [mutableClips removeObjectAtIndex:0];
        }
        [shuffledArray addObject:nextClip];
        lastClip = nextClip;
    }
    return [shuffledArray copy];
}

+ (NSArray<NSString *> *)randomClipURLs:(NSArray<Clip *> *)clips {
    NSArray<Clip *> *shuffledArray = [self randomizedClips:clips];
    NSMutableArray *urlArray = [NSMutableArray array];
    for (Clip *clip in shuffledArray) {
        [urlArray addObjectsFromArray:[clip playbackURLs]];
    }
    return [urlArray copy];
}

- (NSArray<NSString *> *)playbackURLs {
    NSMutableArray<NSString *> *urlArray = [NSMutableArray array];
    if (self.startURL) {
        [urlArray addObject:self.startURL];
    }
    if (self.loopURL) {
        for (int i = 0; i < self.repeat; i++) {
            [urlArray addObject:self.loopURL];
        }
    }
    if (self.endURL) {
        [urlArray addObject:self.endURL];
    }
    if (self.others) {
        [urlArray addObjectsFromArray:self.others];
    }
    return [urlArray copy];
}

@end
