cd libecc
make clean
EXTRA_CFLAGS=-mno-red-zone make build/libarith.a build/libec.a build/libsign.a
cd ..
mv libecc/build/*.a ./

