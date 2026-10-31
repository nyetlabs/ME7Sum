include vars.mk

EXE := $(BIN_DIR)/me7sum$(EXE_EXT)

.PHONY : all clean distclean test
all: $(EXE)

clean:
	$(ECHO) Deleting $(OBJ) $(DEPS) $(EXE) ...
	$(DEBUG)-$(RM) $(OBJ) $(DEPS) $(EXE)

distclean: clean
	$(RM) -r $(BUILD_DIR) $(WIN_ARTIFACTS)
	find . \( -name '*.[do]' -o -name '*.obj' -o -name '*.zip' -o -name '*.tar.gz' \) -delete
	find . \( -name '*.a' -not -path './mpir/*' \) -delete
	$(RM) -r corpus bins me7sum # old binaries, bins/, and corpus

test: $(EXE)
	ME7SUM=$(EXE) ./scripts/test.py

# corpus: fetch the private ecu-corpus submodule at its pinned commit (needs access)
# corpus-bump: move it to the ecu-corpus head (commit it yourself)
.PHONY: corpus corpus-bump bump
corpus ecu-corpus/corpus.tsv:
	git submodule update --init --checkout --depth 1 ecu-corpus

bump corpus-bump:
	git submodule update --init --checkout --remote --depth 1 ecu-corpus
	@git -C ecu-corpus log -1 --format='corpus now at %h %s'
	@git status --short ecu-corpus

.PHONY: mingw mingw32
# MinGW 64-bit
mingw:
	SYS=x86_64-w64-mingw32 make

# Legacy MinGW 32-bit
mingw32:
	SYS=i686-w64-mingw32 make

# Target/platform-specific build and packaging
ifneq (,$(findstring cygwin, $(NATIVE_SYS)))
# Cygwin only
.PHONY: win
# Native Windows build with nmake
# Always clean first, we don't have dependencies in nmake
# We can't use "./build.cmd clean" because of odd vcvarsall.bat behavior
win:
	$(RM) $(WIN_ARTIFACTS)
	./build.cmd
PACKAGE = me7sum-$(GIT_VERSION)-win.zip
PACKAGE_FILES += ME7Check.exe
else # !Cygwin
PACKAGE = me7sum-$(GIT_VERSION)-$(UNAME).tar.gz
endif # !Cygwin

include rules.mk
# vim: set ts=8:
