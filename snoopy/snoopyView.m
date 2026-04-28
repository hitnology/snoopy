//
//  snoopyView.m
//  snoopy
//
//  Created by dillon on 2025/1/16.
//

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "snoopyView.h"
#import "Clip.h"
#import <SpriteKit/SpriteKit.h>
#define scale 720.0 / 1080.0
#define offside 180.0 / 1080.0

#import <os/log.h>

@interface snoopyView()

@property (nonatomic, strong) AVQueuePlayer *queuePlayer;
@property (nonatomic, strong) SKView *skView;
@property (nonatomic, strong) SKScene *scene;
@property (nonatomic, strong) SKVideoNode *videoNode;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) NSInteger clipIndex;
@property (nonatomic, copy) NSArray<Clip *> *clips;
@property (nonatomic, copy) NSArray<AVPlayerItem *> *currentClipItems;
@property (nonatomic, copy) NSArray<AVPlayerItem *> *queuedClipItems;
@property (nonatomic, copy) NSArray<NSColor *> *colors;
@property (nonatomic, copy) NSArray<NSString *> *backgroundImages;
@property (nonatomic, strong) os_log_t log;

@end

@implementation snoopyView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/30.0];
        self.log = os_log_create("com.dillon.snoopy", "screensaver");
        BOOL preview = NO;
        if (frame.size.width < 600 && frame.size.height < 500) {
            preview = YES;
        }
        if (!preview) {
            self.colors = @[[NSColor colorWithRed:50.0/255.0 green:60.0/255.0 blue:47.0/255.0 alpha:1],
                           [NSColor colorWithRed:5.0/255.0 green:168.0/255.0 blue:157.0/255.0 alpha:1],
                           [NSColor colorWithRed:65.0/255.0 green:176.0/255.0 blue:246.0/255.0 alpha:1],
                           [NSColor colorWithRed:238.0/255.0 green:95.0/255.0 blue:167.0/255.0 alpha:1],
                           [NSColor blackColor]];
            self.wantsLayer = YES;
            [self loadBackgroundImages];
            [self setupPlayer];
            [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(willStop) name:@"com.apple.screensaver.willstop" object:nil];
        }
    }
    return self;
}

- (void)loadBackgroundImages {
    NSString *resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    NSArray<NSString *> *files = [fileManager contentsOfDirectoryAtPath:resourcePath error:&error];
    if (error) {
        NSLog(@"Error reading Resources directory: %@", error.localizedDescription);
        return;
    }
    
    NSPredicate *heicFilter = [NSPredicate predicateWithFormat:@"self ENDSWITH[c] '.heic'"];
    NSArray<NSString *> *heicFiles = [[files filteredArrayUsingPredicate:heicFilter] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    self.backgroundImages = heicFiles;
}

- (void)loadPlaybackClips {
    self.clips = [Clip randomizedClips:[Clip loadClips]];
    self.clipIndex = 0;
}

- (NSArray<AVPlayerItem *> *)playerItemsForClip:(Clip *)clip {
    NSArray<NSString *> *playbackURLs = [clip playbackURLs];
    NSMutableArray<AVPlayerItem *> *playerItems = [NSMutableArray arrayWithCapacity:playbackURLs.count];
    for (NSString *videoStr in playbackURLs) {
        NSURL *videoURL = [[NSBundle bundleForClass:[self class]] URLForResource:videoStr withExtension:nil];
        if (!videoURL) {
            NSLog(@"Error: Video file %@ not found!", videoStr);
            continue;
        }
        [playerItems addObject:[AVPlayerItem playerItemWithURL:videoURL]];
    }
    return [playerItems copy];
}

- (BOOL)shouldResetVideoNodeFromClip:(Clip *)currentClip toClip:(Clip *)nextClip {
    if (currentClip == nil || nextClip == nil) {
        return NO;
    }

    NSUInteger currentClipSegmentCount = [currentClip playbackURLs].count;
    NSUInteger nextClipSegmentCount = [nextClip playbackURLs].count;
    return currentClipSegmentCount <= 1 && nextClipSegmentCount > 1;
}

- (NSInteger)nextClipIndexAfterIndex:(NSInteger)clipIndex {
    if (self.clips.count == 0) {
        return NSNotFound;
    }

    return (clipIndex + 1) % self.clips.count;
}

- (void)appendPlayerItemsToQueue:(NSArray<AVPlayerItem *> *)playerItems {
    for (AVPlayerItem *item in playerItems) {
        [self.queuePlayer insertItem:item afterItem:nil];
    }
}

- (void)installVideoNodeIfNeeded {
    if (self.scene == nil || self.queuePlayer == nil) {
        return;
    }

    [self.videoNode removeFromParent];
    self.videoNode = [SKVideoNode videoNodeWithAVPlayer:self.queuePlayer];
    self.videoNode.position = CGPointMake(self.scene.size.width / 2, self.scene.size.height / 2);
    self.videoNode.size = self.scene.size;
    self.videoNode.zPosition = 3;
    [self.scene addChild:self.videoNode];
}

- (void)updateBackgroundForCurrentClipIfNeeded {
    if (self.clipIndex != 0) {
        return;
    }

    SKSpriteNode *imageNode = (SKSpriteNode *)[self.scene childNodeWithName:@"backgroundImage"];
    NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:self.backgroundImages[arc4random_uniform((uint32_t)self.backgroundImages.count)] withExtension:nil];
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:imageURL];
    double imageAspect = image.size.height / self.scene.size.height;
    imageNode.texture = [SKTexture textureWithImage:image];
    imageNode.position = CGPointMake(self.scene.size.width / 2, self.scene.size.height / 2 - self.scene.size.height * offside);
    imageNode.size = CGSizeMake(image.size.width / imageAspect * scale, self.scene.size.height * scale);
    
    SKSpriteNode *colorNode = (SKSpriteNode *)[self.scene childNodeWithName:@"backgroundColor"];
    colorNode.color = self.colors[arc4random_uniform((uint32_t)self.colors.count)];
}

- (void)queueFollowingClipIfNeeded {
    self.queuedClipItems = nil;
    if (self.queuePlayer == nil || self.clips.count == 0) {
        return;
    }

    NSInteger nextClipIndex = [self nextClipIndexAfterIndex:self.clipIndex];
    if (nextClipIndex == NSNotFound) {
        return;
    }

    Clip *currentClip = self.clips[self.clipIndex];
    Clip *nextClip = self.clips[nextClipIndex];
    if ([self shouldResetVideoNodeFromClip:currentClip toClip:nextClip]) {
        return;
    }

    NSArray<AVPlayerItem *> *nextClipItems = [self playerItemsForClip:nextClip];
    if (nextClipItems.count == 0) {
        NSLog(@"Error: Clip %@ has no playable video files!", nextClip.name);
        return;
    }

    [self appendPlayerItemsToQueue:nextClipItems];
    self.queuedClipItems = nextClipItems;
}

- (void)playCurrentClipResetVideoNode:(BOOL)resetVideoNode {
    if (self.clips.count == 0 || self.scene == nil) {
        return;
    }

    Clip *clip = self.clips[self.clipIndex];
    NSArray<AVPlayerItem *> *playerItems = [self playerItemsForClip:clip];
    if (playerItems.count == 0) {
        NSLog(@"Error: Clip %@ has no playable video files!", clip.name);
        return;
    }

    self.currentClipItems = playerItems;

    if (resetVideoNode || self.queuePlayer == nil || self.videoNode == nil) {
        [self.queuePlayer pause];
        [self.queuePlayer removeAllItems];
        self.queuePlayer = [AVQueuePlayer queuePlayerWithItems:self.currentClipItems];
        [self installVideoNodeIfNeeded];
    } else {
        [self.queuePlayer pause];
        [self.queuePlayer removeAllItems];
        [self appendPlayerItemsToQueue:self.currentClipItems];
    }

    [self queueFollowingClipIfNeeded];

    if (self.isAnimating) {
        [self.queuePlayer play];
    }
}

- (void)setupPlayer {
    SKView *skView = [[SKView alloc] initWithFrame:self.bounds];
    skView.wantsLayer = YES;
    skView.layer.backgroundColor = [[NSColor clearColor] CGColor];
    skView.ignoresSiblingOrder = YES;
    skView.allowsTransparency = YES;
    self.skView = skView;
    [self addSubview:self.skView];
    
    SKScene *scene = [[SKScene alloc] initWithSize:self.bounds.size];
    scene.backgroundColor = [NSColor clearColor];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    scene.userInteractionEnabled = NO;
    self.scene = scene;
    [self.skView presentScene:self.scene];
    
    SKSpriteNode *solidColorBGNode = [SKSpriteNode spriteNodeWithColor:self.colors[arc4random_uniform((uint32_t)self.colors.count)] size:self.scene.size];
    solidColorBGNode.position = CGPointMake(scene.size.width / 2, scene.size.height / 2);
    solidColorBGNode.zPosition = 0;
    solidColorBGNode.name = @"backgroundColor";
    [self.scene addChild:solidColorBGNode];
    
    NSString *bgImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"halftone_pattern" ofType:@"png"];
    NSImage *bgImage = [[NSImage alloc] initWithContentsOfFile:bgImagePath];
    SKTexture *bgtexture = [SKTexture textureWithImage:bgImage];
    SKSpriteNode *backgroundBNode = [SKSpriteNode spriteNodeWithTexture:bgtexture];
    backgroundBNode.position = CGPointMake(scene.size.width / 2, scene.size.height / 2);
    backgroundBNode.size = scene.size;
    backgroundBNode.zPosition = 1;
    backgroundBNode.alpha = 0.1;
    backgroundBNode.name = @"backgroundBImage";
    backgroundBNode.blendMode = SKBlendModeAlpha;
    [self.scene addChild:backgroundBNode];
    
    NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:self.backgroundImages[arc4random_uniform((uint32_t)self.backgroundImages.count)] withExtension:nil];
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:imageURL];
    double imageAspect = image.size.height / self.scene.size.height;
    SKTexture *texture = [SKTexture textureWithImage:image];
    SKSpriteNode *backgroundNode = [SKSpriteNode spriteNodeWithTexture:texture];
    backgroundNode.position = CGPointMake(scene.size.width / 2, scene.size.height / 2 - scene.size.height * offside);
    backgroundNode.size = CGSizeMake(image.size.width / imageAspect * scale, self.scene.size.height * scale);
    backgroundNode.zPosition = 2;
    backgroundNode.name = @"backgroundImage";
    backgroundNode.blendMode = SKBlendModeAlpha;
    [self.scene addChild:backgroundNode];

    [self loadPlaybackClips];
    [self playCurrentClipResetVideoNode:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *finishedItem = notification.object;
    if (![finishedItem isKindOfClass:[AVPlayerItem class]]) {
        return;
    }
    if (self.currentClipItems.count == 0) {
        return;
    }
    if (finishedItem != self.currentClipItems.lastObject) {
        return;
    }

    Clip *currentClip = self.clips[self.clipIndex];
    NSInteger nextClipIndex = [self nextClipIndexAfterIndex:self.clipIndex];
    if (nextClipIndex == NSNotFound) {
        return;
    }

    Clip *nextClip = self.clips[nextClipIndex];
    BOOL shouldResetVideoNode = [self shouldResetVideoNodeFromClip:currentClip toClip:nextClip];

    self.clipIndex = nextClipIndex;
    if (self.clipIndex == 0) {
        [self updateBackgroundForCurrentClipIfNeeded];
    }

    if (shouldResetVideoNode || self.queuedClipItems.count == 0) {
        [self playCurrentClipResetVideoNode:shouldResetVideoNode];
        return;
    }

    self.currentClipItems = self.queuedClipItems;
    self.queuedClipItems = nil;
    [self queueFollowingClipIfNeeded];
}

- (void)startAnimation
{
    [super startAnimation];
    self.isAnimating = YES;
    [self.queuePlayer play];
    os_log(_log, "snoopy startAnimation");
}

- (void)stopAnimation
{
    [super stopAnimation];
    self.isAnimating = NO;
    [self.queuePlayer pause];
    [self.queuePlayer removeAllItems];
    self.queuePlayer = nil;
    self.currentClipItems = nil;
    self.queuedClipItems = nil;
    [self.videoNode removeFromParent];
    self.videoNode = nil;
    [self.scene removeAllChildren];
    [self.scene removeFromParent];
    self.scene = nil;
    [self.skView removeFromSuperview];
    self.skView = nil;
    os_log(_log, "snoopy stopAnimation");
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
}

- (void)willStop {
    os_log(_log, "snoopy willStop call");
    exit(0);
}

- (void)animateOneFrame
{
    return;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [self.queuePlayer pause];
    [self.queuePlayer removeAllItems];
    self.queuePlayer = nil;
    self.currentClipItems = nil;
    self.queuedClipItems = nil;
    [self.videoNode removeFromParent];
    self.videoNode = nil;
    os_log(_log, "snoopy dealloc");
}

@end
