all: lib

lib:
	rm -fr lib
	cd src ; moonc -t ../lib *

.PHONY: all lib
