//
//  SerializationData.h
//  StrongboxTests
//
//  Created by Mark on 17/10/2018.
//  Copyright © 2018 Mark McGuill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DecryptionParameters.h"
#import "DatabaseAttachment.h"

NS_ASSUME_NONNULL_BEGIN

@interface SerializationData : NSObject

@property (nonatomic) uint32_t compressionFlags;
@property (nonatomic) uint32_t innerRandomStreamId;
@property (nonatomic) uint64_t transformRounds;
@property (nonatomic) NSString* xml;
@property (nonatomic) NSData *protectedStreamKey;
@property (nonatomic) NSString *fileVersion;
@property (nonatomic) NSDictionary<NSNumber *,NSObject *>* extraUnknownHeaders;
@property (nonatomic) NSString* headerHash;
@property (nonatomic) NSUUID* cipherId;

@end

NS_ASSUME_NONNULL_END
