ROOT=$(shell pwd)
LUA_DIR=$(ROOT)/build/luvit/deps/luajit/src

all: luvit json crypto

luvit: build/luvit/build/luvit

build/luvit/build/luvit: build/luvit
	make -C $^

build/luvit:
	mkdir -p build
	git clone http://github.com/dvv/luvit.git build/luvit
	#( cd build/luvit ; patch -Np1 < ../../nodelay.diff )

json: build/lua-cjson/cjson.so

build/lua-cjson/cjson.so: build/lua-cjson
	LUA_INCLUDE_DIR=$(LUA_DIR) make -C $^

build/lua-cjson:
	wget http://www.kyne.com.au/~mark/software/lua-cjson-1.0.3.tar.gz -O - | tar -xzpf - -C build
	mv build/lua-cjson-* $@

crypto: build/lua-openssl/openssl.so

build/lua-openssl/openssl.so: build/lua-openssl
	sed -i 's,$$(CC) -c -o $$@ $$?,$$(CC) -c -I$(ROOT)/build/luvit/deps/luajit/src -o $$@ $$?,' build/lua-openssl/makefile
	make -C $^

build/lua-openssl:
	wget http://github.com/zhaozg/lua-openssl/tarball/master -O - | tar -xzpf - -C build
	mv build/zhaozg-lua-* $@

.PHONY: all crypto
