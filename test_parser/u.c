/*
 * Copyright (c) 2021 NVI, Inc.
 *
 * This file is part of VLBI Field System
 * (see http://github.com/nvi-inc/fs).
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
#include <stdio.h>
#include <string.h>
#include "../vex.h"
#include "../y.tab.h"

/*#define YES*/
/* globals */

extern int yydebug;
extern int lines;

int main(int argc, char *argv[])
{
  void *ptr;
  Llist *lowl;
  Llist *lowls,*lowls2;
  struct vex *vex;
  char *cptr;
  char*          scanname = 0;
  char stat_c[128];

  if (argc > 2)
    yydebug=1;
  else
    yydebug=0;

  if(vex_open(argv[1],&vex)) {
    fprintf(stderr,"error opening and parsing vex file %s\n",argv[1]);
    return -1;
  }
  /* Read scan for station 'Jb' */
  strcpy(stat_c, "Jb");
  stat_c[2] = '\0';


printf("Parsed OK - finding scan\n");
  ptr = get_scan_station(&lowl, &scanname, stat_c, vex );
printf("gotit, scanname=%p\n", (void*)scanname);
if( scanname )
	printf("   = '%s'\n", scanname);

  /* For that scan, extract all source(s) */
  while( ptr ) {
	void* ptr2 = get_scan_source(lowl);
	printf(" get scan source = %p\n", (void*)ptr2 );
	while( ptr2 ) {
		printf("  name='%s'\n", (char*)ptr2);
        ptr2 = get_scan_source_next();
	}
    ptr = get_scan_station_next(&lowl, &scanname);
    if( scanname )
	printf("   = '%s'\n", scanname);
  }

  return 0;
}
