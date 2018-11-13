//
//  KeePassCiphers.m
//  Strongbox
//
//  Created by Mark on 26/10/2018.
//  Copyright © 2018 Mark McGuill. All rights reserved.
//

#import "KeePassCiphers.h"
#import "AesCipher.h"
#import "ChaCha20Cipher.h"
#import "TwoFishCipher.h"
#import "KeePassConstants.h"

@implementation KeePassCiphers

static NSString* const aesUuid = @"31C1F2E6-BF71-4350-BE58-05216AFC5AFF";
static NSString* const chaCha20Uuid = @"D6038A2B-8B6F-4CB5-A524-339A31DBB59A";
static NSString* const argon2Uuid = @"EF636DDF-8C29-444B-91F7-A9A403E30A0C";
static NSString* const twoFishUuid = @"AD68F29F-576F-4BB9-A36A-D47AF965346C";

NSUUID* const twoFishCipherUuid() {
    static NSUUID* foo = nil;
    
    if (!foo) {
        foo = [[NSUUID alloc] initWithUUIDString:twoFishUuid];
    }
    
    return foo;
}

NSData* twoFishCipherUuidData() {
    static NSData* foo = nil;
    
    if(!foo) {
        uuid_t uuid;
        [twoFishCipherUuid() getUUIDBytes:uuid];
        foo = [NSData dataWithBytes:uuid length:sizeof(uuid_t)];
    }
    
    return foo;
}

NSUUID* const chaCha20CipherUuid() {
    static NSUUID* foo = nil;
    
    if (!foo) {
        foo = [[NSUUID alloc] initWithUUIDString:chaCha20Uuid];
    }
    
    return foo;
}

NSData* chaCha20CipherUuidData() {
    static NSData* foo = nil;
    
    if(!foo) {
        uuid_t uuid;
        [chaCha20CipherUuid() getUUIDBytes:uuid];
        foo = [NSData dataWithBytes:uuid length:sizeof(uuid_t)];
    }
    
    return foo;
}

NSUUID* const argon2CipherUuid() {
    static NSUUID* foo = nil;
    
    if (!foo) {
        foo = [[NSUUID alloc] initWithUUIDString:argon2Uuid];
    }
    
    return foo;
}

NSData* argon2CipherUuidData() {
    static NSData* foo = nil;
    
    if(!foo) {
        uuid_t uuid;
        [argon2CipherUuid() getUUIDBytes:uuid];
        foo = [NSData dataWithBytes:uuid length:sizeof(uuid_t)];
    }
    
    return foo;
}

NSUUID* const aesCipherUuid() {
    static NSUUID* foo = nil;
    
    if (!foo) {
        foo = [[NSUUID alloc] initWithUUIDString:aesUuid];
    }
    
    return foo;
}

NSData* aesCipherUuidData() {
    static NSData* foo = nil;
    
    if(!foo) {
        uuid_t uuid;
        [aesCipherUuid() getUUIDBytes:uuid];
        foo = [NSData dataWithBytes:uuid length:sizeof(uuid_t)];
    }
    
    return foo;
}

NSString* innerEncryptionString(uint32_t innerRandomStreamId) {
    switch (innerRandomStreamId) {
        case kInnerStreamPlainText:
            return @"None (Plaintext)";
            break;
        case kInnerStreamArc4:
            return @"ARC4";
            break;
        case kInnerStreamSalsa20:
            return @"Salsa20";
            break;
        case kInnerStreamChaCha20:
            return @"ChaCha20";
            break;
        default:
            return [NSString stringWithFormat:@"Unknown (%d)", innerRandomStreamId];
            break;
    }
}

NSString* keyDerivationAlgorithmString(NSUUID* uuid){
    if([uuid isEqual:aesCipherUuid()]) {
        return @"AES";
    }
    else if([uuid isEqual:argon2CipherUuid()]) {
        return @"Argon2";
    }
    
    return @"<Unknown>";
}

NSString* outerEncryptionAlgorithmString(NSUUID* uuid) {
    if([uuid isEqual:aesCipherUuid()]) {
        return @"AES";
    }
    else if([uuid isEqual:chaCha20CipherUuid()]) {
        return @"ChaCha20";
    }
    else if([uuid isEqual:twoFishCipherUuid()]) {
        return @"TwoFish";
    }
    
    return @"<Unknown>";
}

id<Cipher> getCipher(NSUUID* cipherUuid) {
    if([cipherUuid isEqual:aesCipherUuid()]) {
        return [[AesCipher alloc] init];
    }
    else if([cipherUuid isEqual:chaCha20CipherUuid()]) {
        return [[ChaCha20Cipher alloc] init];
    }
    else if([cipherUuid isEqual:twoFishCipherUuid()]) {
        return [[TwoFishCipher alloc] init];
    }
    else {
        NSLog(@"Unknown Cipher ID, cannot create. [%@]", cipherUuid.UUIDString);
    }
    
    return nil;
}

@end
