#
YACC=bison
YFLAGS=-d -y
LEX=flex
OBJECTS=vex.o vexf_get.o vexf_put.o vex.yy.o vex_util.o print_vex.o vex_get.o vex_put.o
CC=gcc
#
# F2C needs this others don't
#CPPFLAGS +=-DF2C
ifeq ($(FC),fort77)
CFLAGS= -c -DF2C
endif
#

vex.a: $(OBJECTS)
	touch $@
	rm $@
	ar -qc $@ $(OBJECTS)
#
# GNU ar (Linux) needs this, others don't
	ar s $@
#
	rm -f vex.c vex.yy.c

vex.yy.o:	vex.yy.l y.tab.h

y.tab.h:	vex.y

vex_util.o:	y.tab.h

print_vex.o:	y.tab.h

vex_get.o:	y.tab.h

vex_put.o:	y.tab.h

vexf.o:		y.tab.h
