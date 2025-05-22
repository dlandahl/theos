#import "Basic";
#load "../sha.jai";
#load "../md5.jai";

teststring :: (testname: string, a: string, b: string) {
    print("%\r\e[15C", testname);
    if a == b { print(" ... success\n"); }
    else {
        print(" ... fail:\n");
        print("\e[22C\"%\"\n\e[19C ≠ \"%\"\n", a, b);
    }
}

main :: () {
    testdata := "the quick brown fox jumped over the lazy dog. all work and no play makes jack a dull boy";

    teststring("SHA224", sha224(testdata), "4e4269f545e0b84b30a3c97486de5d6fa858337bdd59205037dc1556");
    teststring("SHA256", sha256(testdata), "dc8605827fae7755062045b2cabe8043265a51ff844b03c6d62a6b93f8580b96");
    teststring("SHA256", sha256(""), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
    teststring("SHA384", sha384(testdata), "1c9516bf31c60dba86a89123f969366b3d811da0af3228ff70a5b995a84a7e0479a2b93c688bde3d6f78756e20091942");
    teststring("SHA512", sha512(testdata), "1fd26b6e249d9df11b1acc766e6bc8db878bf3b52cc8b3ab5e5a9ba5b8dac0730b487a10410174fda37712472d9f3a56c9609f53803aad57d4d35c3ee15422ba");

    teststring("MD5", md5(""), "d41d8cd98f00b204e9800998ecf8427e");
    teststring("MD5", md5("Mim Hufford"), "111126655c03434e1c4d7d1d9104b790");
    teststring("MD5", md5("The quick brown fox jumps over the lazy dog"), "9e107d9d372bb6826bd81d3542a419d6");
    teststring("MD5", md5("The man in black fled across the desert the gunslinger followed."), "fe48b3e0d34c4a261dcd13fc277888a1");
    teststring("MD5", md5("The man in black fled across the desert the gunslinger followed. The man in black fled across the desert the gunslinger followed."), "eab13003ea3ff3c14370019a685956d3");

    teststring("HMAC_SHA256", hmac_sha256("super-secret-key", "Hello World!"),                                                                  "4b393abced1c497f8048860ba1ede46a23f1ff5209b18e9c428bddfbb690aad8");
    teststring("HMAC_SHA256", hmac_sha256("key", "The quick brown fox jumps over the lazy dog"),                                                "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8");
    teststring("HMAC_SHA256", hmac_sha256("The quick brown fox jumps over the lazy dogThe quick brown fox jumps over the lazy dog", "message"), "5597b93a2843078cbb0c920ae41dfe20f1685e10c67e423c11ab91adfc319d12");
    print("\n\n");
}

#run main();
