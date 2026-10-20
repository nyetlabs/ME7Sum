# Build environment
# SYS is the target triplet. Override it to cross-compile (see mingw targets).
NATIVE_SYS := $(shell gcc -dumpmachine 2>/dev/null)
SYS	?= $(NATIVE_SYS)

UNAME_S	:= $(shell uname -s)
UNAME_Darwin = macos
UNAME_Linux = linux
UNAME := $(UNAME_$(UNAME_S))

# Version for --version et al
GIT_VERSION := $(shell sh -c 'git describe --tags --abbrev=4 --dirty --always')

# Tools
RM	:= rm -f
CP	:= cp -f
AR	:= ar rcs
ECHO	:= @echo

# Sanitizers
#CASAN	:= -fsanitize=address -fsanitize=undefined -fno-sanitize=alignment
#LASAN	:= -lasan -lubsan

# Compiler flags
CFLAGS	+= -Wall -O2 -g -Werror -MD $(CASAN) $(CDEFS)
CDEFS	+= -D__GIT_VERSION=\"$(GIT_VERSION)\"

# Source files
SRC := $(foreach dir, . inifile, $(wildcard $(dir)/*.c))

# Build directory structure
BUILD_DIR := build
OBJ_DIR = $(BUILD_DIR)/$(SYS)/obj
BIN_DIR = $(BUILD_DIR)/$(SYS)/bin
STAGE_DIR = $(BUILD_DIR)/stage
OBJ     = $(patsubst %.c, $(OBJ_DIR)/%.o, $(SRC))
DEPS    = $(patsubst %.c, $(OBJ_DIR)/%.d, $(SRC))

# Windows/nmake makefile artifacts
WIN_ARTIFACTS := $(SRC:.c=.obj) me7sum.exe

# Files to include in the package
INIS=sample.ini # testdata/broken/ferrari360.ini testdata/modified/8D0907551M.ini
PACKAGE_FILES_Linux := ME7Check_linux
PACKAGE_FILES := $(PACKAGE_FILES_$(UNAME_S)) README.md $(INIS)

# Native compiler, or $(SYS)-gcc when cross-compiling.
ifeq ($(SYS),$(NATIVE_SYS))
  CC	= gcc
  LD	= gcc
else
  CC	= $(SYS)-gcc
  LD	= $(SYS)-gcc
endif

# Target class. Check mingw before cygwin; a triplet does not contain both.
ifneq (,$(findstring mingw,$(SYS)))
  # Bundled static GMP in mpir/, then switch back so later libs stay dynamic.
  EXE_EXT := .exe
  GMP	?= gmp-$(SYS)
  LIBS	+= ws2_32
  SRC	+= os/pgetopt.c
  ifeq ($(GMP),gmp-$(SYS))
    LDFLAGS += -Lmpir
  endif
  LDFLAGS += $(LASAN) -Wl,-Bstatic -l$(GMP) -Wl,-Bdynamic
else
  # Linux, Cygwin, macOS: system GMP.
  GMP_CFLAGS := $(shell pkg-config --cflags gmp 2>/dev/null)
  GMP_LIBS   := $(shell pkg-config --libs gmp 2>/dev/null)
  ifeq ($(strip $(GMP_LIBS)),)
    GMP_PREFIX := $(shell brew --prefix gmp 2>/dev/null)
    ifneq ($(strip $(GMP_PREFIX)),)
      GMP_CFLAGS := -I$(GMP_PREFIX)/include
      GMP_LIBS   := -L$(GMP_PREFIX)/lib -lgmp
    else
      GMP_LIBS   := -lgmp
    endif
  endif
  CFLAGS  += $(GMP_CFLAGS)
  LDFLAGS += $(LASAN) $(GMP_LIBS)
  ifneq (,$(findstring cygwin,$(SYS)))
    EXE_EXT := .exe
  endif
endif
# vim: set ts=8:
