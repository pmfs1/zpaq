# Cross-platform Makefile for zpaq
# Works on Linux, macOS, and Windows (with MinGW or MSYS2)

# Detect OS
ifeq ($(OS),Windows_NT)
    # Windows (MinGW/MSYS2) - default is Windows, no -Dunix needed
  CXX      = g++
  CPPFLAGS =
  CXXFLAGS = -O3 -march=native -static
  LDFLAGS  = -static
  EXE      = .exe
  RM       = del /Q
  RMDIR    = rmdir /S /Q
  CP       = copy /Y
  MKDIR    = mkdir
  INSTALL  = copy /Y
  POD2MAN  =
  MAN_EXT  =
  PREFIX   = /usr/local
  BINDIR   = $(PREFIX)/bin
    # Windows doesn't use pthread explicitly with MinGW
  PTHREAD =
else
    # Unix/Linux/macOS
  CXX       = g++
  CPPFLAGS += -Dunix
  CXXFLAGS  = -O3 -march=native
  LDFLAGS   =
  EXE       =
  RM        = rm -f
  RMDIR     = rm -rf
  CP        = cp -f
  MKDIR     = mkdir -p
  INSTALL   = install
  POD2MAN   = pod2man
  MAN_EXT   = .1
  PREFIX    = /usr/local
  BINDIR    = $(PREFIX)/bin
  MANDIR    = $(PREFIX)/share/man
  PTHREAD   = -pthread
endif

# Allow NOJIT to be set from command line: make NOJIT=1
ifdef NOJIT
  CPPFLAGS += -DNOJIT
endif

# Default target
all: zpaq$(EXE) zpaq$(MAN_EXT)

# Object files
libzpaq.o: libzpaq.cpp libzpaq.h
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -o $@ -c libzpaq.cpp

zpaq.o: zpaq.cpp libzpaq.h
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -o $@ -c zpaq.cpp $(PTHREAD)

# Main executable
zpaq$(EXE): zpaq.o libzpaq.o
	$(CXX) $(LDFLAGS) -o $@ zpaq.o libzpaq.o $(PTHREAD)

# Man page (Unix only)
zpaq$(MAN_EXT): zpaq.pod
ifneq ($(POD2MAN),)
	$(POD2MAN) $< >$@
else
	@echo "Skipping man page generation on Windows"
endif

# Install (Unix only)
install: zpaq$(EXE) zpaq$(MAN_EXT)
ifneq ($(INSTALL),copy /Y)
	$(MKDIR) $(DESTDIR)$(BINDIR)
	$(INSTALL) -m 0755 zpaq$(EXE) $(DESTDIR)$(BINDIR)
	$(MKDIR) $(DESTDIR)$(MANDIR)/man1
	$(INSTALL) -m 0644 zpaq$(MAN_EXT) $(DESTDIR)$(MANDIR)/man1
else
	@echo "Install target not supported on Windows. Copy zpaq.exe manually."
endif

# Clean
clean:
	$(RM) zpaq.o libzpaq.o zpaq$(EXE) zpaq$(MAN_EXT) archive.zpaq zpaq.new

# Test
check: zpaq$(EXE)
	./zpaq$(EXE) add archive.zpaq zpaq.cpp
	./zpaq$(EXE) extract archive.zpaq zpaq.cpp -to zpaq.new
ifeq ($(OS),Windows_NT)
	fc /B zpaq.cpp zpaq.new
else
	cmp zpaq.cpp zpaq.new
endif
	$(RM) archive.zpaq zpaq.new

.PHONY: all clean check install
