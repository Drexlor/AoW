# ////////////////////////////////////////////////////
# ////////// Wolftein is always watching. ////////////
# ////////////////////////////////////////////////////

# Build the file
build: Release

# Compile the file
Release: src/EngineEntry.asm
	nasm -f win32 -o debug/aow.obj src/EngineEntry.asm
	ld --omagic -e _EngineEntry -o debug/aow.exe debug/aow.obj
	strip debug/aow.exe
	
# Finish the makefile process
.PHONY: build clean
