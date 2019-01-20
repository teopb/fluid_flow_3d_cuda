# Example 22
EXE=smoke_display

# Location of the CUDA Toolkit
CUDA_PATH?=/Developer/NVIDIA/CUDA-10.0

HOST_COMPILER ?= g++
NVCC          := $(CUDA_PATH)/bin/nvcc -ccbin $(HOST_COMPILER)

# Main target
all: $(EXE)

#  MinGW
ifeq "$(OS)" "Windows_NT"
CFLG=-O3 -Wall
LIBS=-lglut32cu -lglu32 -lopengl32
CLEAN=del *.exe *.o *.a
else
#  OSX
ifeq "$(shell uname)" "Darwin"
# TODO Took out Wall?
CFLG=-O3 -Wno-deprecated-declarations
LIBS= -Xlinker -framework -Xlinker GLUT -Xlinker -framework -Xlinker OpenGL
#  Linux/Unix/Solaris
else
CFLG=-O3 -Wall
LIBS=-lglut -lGLU -lGL -lm
endif
#  OSX/Linux/Unix/Solaris
CLEAN=rm -f $(EXE) *.o *.a
endif

# Dependencies
smoke_display.o: smoke_display.cu smoke.cuh CSCIx229.h
smoke.o: smoke.cu CSCIx229.h
fatal.o: fatal.c CSCIx229.h
loadtexbmp.o: loadtexbmp.c CSCIx229.h
print.o: print.c CSCIx229.h
project.o: project.c CSCIx229.h
errcheck.o: errcheck.c CSCIx229.h
object.o: object.c CSCIx229.h

#  Create archive
CSCIx229.a:fatal.o loadtexbmp.o print.o project.o errcheck.o object.o
	ar -rcs $@ $^

# Compile rules
.c.o:
	gcc -c $(CFLG) $<

smoke_display.o:
	$(NVCC) -c --compiler-options $(CFLG) $<

smoke.o:
	$(NVCC) -c --compiler-options $(CFLG) $<

#  Link
smoke_display:smoke_display.o smoke.o CSCIx229.a
	$(NVCC) -O3 -o $@ $^   $(LIBS)

#  Clean
clean:
	$(CLEAN)
