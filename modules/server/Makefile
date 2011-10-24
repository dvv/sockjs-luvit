ROOT=$(shell pwd)
LUA_DIR=$(ROOT)/build/luvit/deps/luajit/src

all: luvit json crypto lib

luvit: build/luvit/build/luvit

build/luvit/build/luvit: build/luvit
	make -C $^

build/luvit:
	mkdir -p build
	git clone http://github.com/creationix/luvit build/luvit

json: build/lua-cjson/cjson.so

build/lua-cjson/cjson.so: build/lua-cjson
	LUA_INCLUDE_DIR=$(LUA_DIR) make -C $^

build/lua-cjson:
	wget http://www.kyne.com.au/~mark/software/lua-cjson-1.0.3.tar.gz -O - | tar -xzpf - -C build
	mv build/lua-cjson-* $@

crypto: build/lua-openssl/openssl.so

build/lua-openssl/openssl.so: build/lua-openssl
	#sed -i 's,$$(CC) -c -o $$@ $$?,$$(CC) -c -I$(ROOT)/build/luvit/deps/luajit/src -o $$@ $$?,' build/lua-openssl/makefile
	make INCS=-I$(ROOT)/build/luvit/deps/luajit/src -C $^

build/lua-openssl:
	wget http://github.com/zhaozg/lua-openssl/tarball/master -O - | tar -xzpf - -C build
	mv build/zhaozg-lua-* $@

lib:
	rm -fr lib
	cd src ; moonc -t ../lib *


.PHONY: all lib crypto json
