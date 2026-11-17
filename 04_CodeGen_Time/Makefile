COMPILERNAME = while
SCANNERTEST = scantest
GENERATED   = lex.yy.cc parse.cc Parserbase.h
OBJECTS     = io.o

CC       = gcc
CXX      = g++
CFLAGS   = -m32 -O2 -Wall -Wextra
CXXFLAGS = -std=c++17 -O2 -Wall -Wextra

BISONCPP_VSN = $$(bisonc++ --version 2>/dev/null | sed -n 's/^[^0-9]*\([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1 \2/p' | awk 'NR == 1 { printf "%d%02d", $$1, $$2 }')

.PHONY: all compiler scanner parser test clean

all: $(COMPILERNAME)

compiler: $(COMPILERNAME)

scanner: lex.yy.cc

parser: parse.cc

test: $(COMPILERNAME) $(OBJECTS)
	bash run_tests.sh $(OBJECTS)
	bash run_lexer_tests.sh $(OBJECTS)
	bash run_runtime_tests.sh $(OBJECTS)
	bash run_io_tests.sh

io.o: io.c
	$(CC) $(CFLAGS) -c $< -o $@

lex.yy.cc: $(COMPILERNAME).l
	flex $(COMPILERNAME).l

parse.cc: $(COMPILERNAME).y Parser.ih
	bisonc++ $(COMPILERNAME).y

Parserbase.h: parse.cc
	bisonc++ $(COMPILERNAME).y

$(COMPILERNAME): $(COMPILERNAME).cc lex.yy.cc parse.cc Parserbase.h Parser.h Parser.ih semantics.h
	VSN=$(BISONCPP_VSN); \
	test -n "$$VSN" || { echo "bisonc++ not found or version could not be parsed" >&2; exit 1; }; \
	$(CXX) $(CXXFLAGS) -DBISONCPP_VSN=$$VSN -o $@ $(COMPILERNAME).cc parse.cc lex.yy.cc

$(SCANNERTEST): $(SCANNERTEST).cc lex.yy.cc Parserbase.h
	VSN=$(BISONCPP_VSN); \
	test -n "$$VSN" || { echo "bisonc++ not found or version could not be parsed" >&2; exit 1; }; \
	$(CXX) $(CXXFLAGS) -DBISONCPP_VSN=$$VSN -o $@ $(SCANNERTEST).cc lex.yy.cc

clean:
	rm -f $(COMPILERNAME) $(SCANNERTEST) $(OBJECTS) $(GENERATED) *~
