//
//  KeePass4DatabaseMetadata.m
//  Strongbox
//
//  Created by Mark on 30/10/2018.
//  Copyright © 2018 Mark McGuill. All rights reserved.
//

#import "KeePass4DatabaseMetadata.h"
#import "KeePassConstants.h"
#import "BasicOrderedDictionary.h"
#import "KdbxSerializationCommon.h"
#import "KeePassCiphers.h"
#import "Argon2KdfCipher.h"

static NSString* const kDefaultFileVersion = @"4.0";
static const uint32_t kDefaultInnerRandomStreamId = kInnerStreamChaCha20;

@implementation KeePass4DatabaseMetadata

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.generator = kStrongboxGenerator;
        self.version = kDefaultFileVersion;
        self.compressionFlags = kGzipCompressionFlag;
        self.innerRandomStreamId = kDefaultInnerRandomStreamId;
        self.kdfParameters = [[Argon2KdfCipher alloc] initWithDefaults].kdfParameters;
        self.cipherUuid = chaCha20CipherUuid();
    }
    
    return self;
}

- (BasicOrderedDictionary<NSString*, NSString*>*)kvpForUi {
    BasicOrderedDictionary<NSString*, NSString*>* kvps = [[BasicOrderedDictionary alloc] init];
    
    [kvps addKey:@"Database Format" andValue:@"KeePass 2"];
    [kvps addKey:@"KeePass File Version"  andValue:self.version];
    [kvps addKey:@"Database Generator" andValue:self.generator];
    [kvps addKey:@"Key Derivation" andValue:keyDerivationAlgorithmString(self.kdfParameters.uuid)];
    [kvps addKey:@"Outer Encryption" andValue:outerEncryptionAlgorithmString(self.cipherUuid)];
    [kvps addKey:@"Compressed"  andValue:self.compressionFlags == kGzipCompressionFlag ? @"Yes (GZIP)" : @"No"];
    [kvps addKey:@"Inner Encryption" andValue:innerEncryptionString(self.innerRandomStreamId)];
    
    return kvps;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", [self kvpForUi]];
}

@end
