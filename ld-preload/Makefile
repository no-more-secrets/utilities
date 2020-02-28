lib := output/libdlclose-noop.so

all: $(lib)

$(lib): $(lastword $(MAKEFILE_LIST))
	mkdir -p output
	gcc --shared dlclose-noop.c -O2 -o $(lib)
	strip $(lib)

clean:
	rm -f $(lib)

.PHONY: all clean