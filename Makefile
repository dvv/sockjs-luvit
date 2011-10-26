all: modules/server/build/luvit/build/luvit lib

modules/server/build/luvit/build/luvit:
	make -C modules/server

lib:
	-which moonc && rm -fr lib && ( cd src ; moonc -t ../lib * )

.PHONY: all lib
