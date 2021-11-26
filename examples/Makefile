#
LIBS=../vex.a
OBJECTS=site_positions.o
OBJECTS2=scan_modes.o
CC=gcc

all: site_positions scan_modes

site_positions: $(OBJECTS) $(LIBS)
	gcc -o site_positions $(OBJECTS) $(LIBS) -lfl
scan_modes: $(OBJECTS2) $(LIBS)
	gcc -o scan_modes $(OBJECTS2) $(LIBS) -lfl
