# ////////////////////////////////////////////////////
# ////////// Wolftein is always watching. ////////////
# ////////////////////////////////////////////////////

# Build the file
build: BuildForHispano BuildForMundosPerdidos

# Compile for server: HispanoAO
BuildForHispano:
	nasm -dFND_HISPANO -dDEFAULT_NAME -f win32 -o build/aow.obj src/EngineEntry.asm
	ld --omagic -e _EngineEntry -o build/AoW_HispanoAO.exe build/aow.obj
	strip build/AoW_HispanoAO.exe

# Compile for server: MundosPerdidosAO
BuildForMundosPerdidos:
	nasm -dFND_MUNDOS_PERDIDOS -dDEFAULT_NAME -f win32 -o build/aow.obj src/EngineEntry.asm
	ld --omagic -e _EngineEntry -o build/AoW_MundosPerdidosAO.exe build/aow.obj
	strip build/AoW_MundosPerdidosAO.exe

# Finish the makefile process
.PHONY: build clean
