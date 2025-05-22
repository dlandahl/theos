# Jai Cryptographic Primitives Library

This is very rudimentary native cryptography library for Jai.

Last updated for compiler version 0.1.003.

Currently it supports the SHA-2 family of hash functions, HMAC-SHA256 and MD5, but more will be
added later. See *Features* below.

## Usage

Easiest is to load it into your program like so:

```
#load "jai-crypto/module.jai";
```

But if you want to provide it as a local module, you can put it in Jai's `modules/` directory
(or better yet, symlink it in there). I call it `Crypto` there. Then you can do:

```
#import "Crypto";
```

Beware, if you do this, that at some point Jai will probably have a library called `Crypto`,
that may or may not be based on this one. You may end up confusing yourself or others!

# Features

## Hash functions

 * `sha224 :: (string) -> string`
 * `sha256 :: (string) -> string`
 * `sha384 :: (string) -> string`
 * `sha512 :: (string) -> string`
 * `hmac_sha256 :: (string) -> string`
 * `md5 :: (string) -> string`


# Authors

 * [Smári McCarthy](https://github.com/smari/)
 * [Mim Hufford](https://github.com/mimhufford/)
