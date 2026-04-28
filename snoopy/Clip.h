//
//  Clip.h
//  snoopy
//
//  Created by dillon on 2025/1/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Clip : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *startURL;
@property (nonatomic, copy) NSString *loopURL;
@property (nonatomic, copy) NSString *endURL;
@property (nonatomic, assign) int repeat;
@property (nonatomic, copy) NSString *from;
@property (nonatomic, copy) NSString *to;
@property (nonatomic, copy) NSArray *others;

+ (NSArray<Clip *> *)loadClips;
+ (NSArray<Clip *> *)randomizedClips:(NSArray<Clip *>*) clips;
+ (NSArray<NSString *> *)randomClipURLs:(NSArray<Clip *>*) clips;
- (NSArray<NSString *> *)playbackURLs;

@end

NS_ASSUME_NONNULL_END
