TARGET_NAME = fftw_extra
TARGET_STATIC = $(TARGET_NAME).a
PYLIB_EXT = $(if $(filter $(OS),Windows_NT),.pyd,.so)
TARGET_PYLIB = ../../Python_2_7/lib/$(TARGET_NAME)$(PYLIB_EXT)

MULTI_ARRAY = ../Multi_array
FFTW_EXTRA = ../FFTW_EXTRA
LIBS = ../libs

IDIR = includes
ODIR = obj
LDIR = lib
SDIR = src

EXTERNAL_INCLUDES = -I$(MULTI_ARRAY)/$(IDIR) -I$(FFTW_EXTRA)/$(IDIR)

SRC  = $(wildcard $(SDIR)/*.cpp)
OBJ  = $(patsubst $(SDIR)/%.cpp,$(ODIR)/%.o,$(SRC))
ASS  = $(patsubst $(SDIR)/%.cpp,$(ODIR)/%.s,$(SRC))
DEPS = $(OBJ:.o=.d)

CXX = $(OS:Windows_NT=x86_64-w64-mingw32-)g++
OPTIMIZATION = -O3 -march=native
CPP_STD = -std=c++14
WARNINGS = -Wall
MINGW_COMPATIBLE = $(OS:Windows_NT=-DMS_WIN64 -D_hypot=hypot)
DEPS_FLAG = -MMD -MP

POSITION_INDEP = -fPIC
SHARED = -shared

FFTW= -lfftw3
 
PY = $(OS:Windows_NT=/c/Anaconda2/)python

PY_INCL := $(shell $(PY) -m pybind11 --includes)
ifneq ($(OS),Windows_NT)
    PY_INCL += -I /usr/include/python2.7/
endif

PY_LINKS = $(OS:Windows_NT=-L /c/Anaconda2/ -lpython27)

LINKS =  $(FFTW) $(PY_LINKS)
LINKING = $(CXX) $(OPTIMIZATION) $(POSITION_INDEP) $(SHARED)  -o $(TARGET_PYLIB) $(OBJ) $(LINKS) $(EXTERNAL_OBJ) $(DEPS_FLAG) $(MINGW_COMPATIBLE)
STATIC_LIB = ar cr $(TARGET_STATIC) $(OBJ) 

INCLUDES = $(PY_INCL) $(EXTERNAL_INCLUDES)
COMPILE  = $(CXX) $(CPP_STD) $(OPTIMIZATION) $(POSITION_INDEP) $(WARNINGS) -c -o $@ $< $(INCLUDES) $(DEPS_FLAG) $(MINGW_COMPATIBLE)
ASSEMBLY = $(CXX) $(CPP_STD) $(OPTIMIZATION) $(POSITION_INDEP) $(WARNINGS) -S -o $@ $< $(INCLUDES) $(DEPS_FLAG) $(MINGW_COMPATIBLE)

LINK_BENCHMARK_CUSTOM =$(FFTW)

LINK_BENCHMARK = \
	$(LINK_BENCHMARK_CUSTOM) \
	-L$(LIBS)/benchmark/build/src -lbenchmark -lpthread -lshlwapi \

LINKING_BENCHMARK = \
	$(CXX) -O3 -march=native \
	-Wl,-rpath=/c/cygwin64/usr/x86_64-w64-mingw32/sys-root/mingw/bin \
	-o $@ $< \
	$(LINK_BENCHMARK)\
	$(DEPS_FLAG) $(MINGW_COMPATIBLE) \
	
INCLUDES_BENCHMARK = \
	-I $(LIBS)/benchmark/include \
	$(INCLUDES)
	
COMPILE_BENCHMARK = \
	$(CXX) $(CPP_STD) $< -O3 -march=native \
	$(INCLUDES_BENCHMARK) \
	$(DEPS_FLAG) $(MINGW_COMPATIBLE) \
	-c -o $@

compile_objects : $(OBJ)

assembly : $(ASS)

all : $(TARGET_PYLIB) $(TARGET_STATIC) $(OBJ) $(ASS)

python_debug_library : $(TARGET_PYLIB)

static_library : $(TARGET_STATIC)

benchmark : benchmark.exe

benchmark.exe : benchmark.o
	@ echo " "
	@ echo "---------Compile $@ ---------"
	$(LINKING_BENCHMARK)

benchmark.o : benchmark.cpp
	@ echo " "
	@ echo "---------Compile $@ from $< ---------"
	$(COMPILE_BENCHMARK)	

$(TARGET_PYLIB): $(OBJ)
	@ echo " "
	@ echo "---------Compile library $(TARGET_PYLIB)---------"
	$(LINKING)

$(TARGET_STATIC) : $(OBJ)
	@ echo " "
	@ echo "---------Compiling static library $(TARGET_STATIC)---------"
	$(STATIC_LIB)
	
$(ODIR)/%.o : $(SDIR)/%.cpp
	@ echo " "
	@ echo "---------Compile object $@ from $<--------"
	$(COMPILE)
	
$(ODIR)/%.s : $(SDIR)/%.cpp
	@ echo " "
	@ echo "---------Assembly $@ from $<--------"
	$(ASSEMBLY)
	
-include $(DEPS)

clean:
	@rm -f $(TARGET_PYLIB) $(TARGET_STATIC) $(OBJ) $(ASS) $(DEPS) benchmark.o benchmark.exe
	 	 
.PHONY: all , clean , python_debug_library , compile_objects , static_library , assembly , benchmark