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

/* example use of parser to extract scan mode keywords */

#include <stdio.h>
#include <stdlib.h>

#include "../vex.h"
#include "../y.tab.h"

int main(int argc, char *argv[])
{
  void *lowls;
  struct vex *vex;
  char *scan_id, *keyword;

  if(vex_open(argv[1],&vex)) {
    fprintf(stderr,"error opening and parsing vex file %s\n",argv[1]);
    exit(1);
  }

  lowls=get_scan(&scan_id,vex);
  while(NULL!=lowls) {

/* mode keyword */

    keyword=get_scan_mode(lowls);

/* use get_all_lowl()/_next_lowl() to assure access to all
 * primitives defined for a station/mode, including those
 * set globally and by station, as well as set by the mode.
 */

/* output result */

    printf("scan_id '%s' mode keyword '%s'\n",scan_id,keyword);

    lowls=get_scan_next(&scan_id);
  }

  exit(0);
}
