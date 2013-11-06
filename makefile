# ////////////////////////////////////////////////////
# ////////// Wolftein is always watching. ////////////
# ////////////////////////////////////////////////////

# Build the file
build: AO-Wolftein.exe AO-Wolftein.dump

# Dump the file for bytecode readings
AO-Wolftein.dump: AO-Wolftein.exe
	objdump -D AO-Wolftein.exe > AO-Wolftein.dump

# Compile the file
AO-Wolftein.exe: src/Entry.asm
	as -o AO-Wolftein.obj src/Entry.asm
	ld -e main -o AO-Wolftein.exe AO-Wolftein.obj
	strip AO-Wolftein.exe

# Finish the makefile process
.PHONY: build clean
