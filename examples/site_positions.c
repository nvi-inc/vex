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

/* example use of parser to extract site_ID and position */

#include <stdio.h>
#include <stdlib.h>

#include "../vex.h"
#include "../y.tab.h"

int fvex_double();

int main(int argc, char *argv[])
{
  void *def, *lowl;
  struct vex *vex;
  int link, name, ierr, i;
  char *value, *units;
  char *id, *xyz[3], *xyz_units[3];
  char *labels[]= {"x","y","z"};
  double mks;

  if(vex_open(argv[1],&vex)) {
    fprintf(stderr,"error opening and parsing vex file %s\n",argv[1]);
    exit(1);
  }

  def=get_station_def(vex);

  while(NULL!=def) {

/* site ID */

    id="";
    lowl=get_station_lowl(def,T_SITE_ID,B_SITE,vex);
    if(NULL!=lowl) {
      ierr=vex_field(T_SITE_ID,lowl,1,&link,&name,&value,&units);
      if(0==ierr && NULL != value)
        id=value;
    }

    for (i=0;i<3;i++) {
       xyz[i]="";
       xyz_units[i]="";
    }

/* position */

    lowl=get_station_lowl(def,T_SITE_POSITION,B_SITE,vex);
    if(NULL!=lowl) {
      for(i=0;i<3;i++) {
        ierr=vex_field(T_SITE_POSITION,lowl,i+1,&link,&name,&value,&units);
        if(0==ierr) {
          if (NULL != value)
            xyz[i]=value;
          if (NULL != units)
            xyz_units[i]=units;
        }
      }
    }

/* output result */

    printf("def '%s' site_id '%s'\n",def,id);
    for (i=0;i<3;i++) {
      printf(" %s '%s' units '%s'",
        labels[i],xyz[i],xyz_units[i]);
      ierr=fvex_double(&xyz[i],&xyz_units[i],&mks);
      if(0==ierr)
        printf(" MKS %lf",mks);
      printf("\n");
    }

    def=get_station_def_next();
  }

  exit(0);
}
