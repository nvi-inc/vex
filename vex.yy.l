%{
/*
 * Copyright (c) 2020-2021, 2025 NVI, Inc.
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
#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>

#include "vex.h"
#include "y.tab.h"

#define  ALLOC_SIZE 32

#define NEWSTR(ptr,from)	{ if(strlen(from) > 128) {\
				    yyerror("string too long"); }\
				  if (NULL == (ptr = strdup(from)) ) { \
 				    yyerror("out of memory");} }

#define isodigit(x) ((x) >= '0' && (x) <= '7')
#define hextoint(x) (isdigit((x)) ? (x) - '0'\
                                  : ((x) - 'A') + 10)

static char *find_end(char *buffer, char *text);

static int ref=0;
static int inthreads=0;
static int trailing=0;
int lines=1;
static int version=1;

struct llist *lit();
char *quote();

void yyerror(char const *s);
%}
%option noyywrap

%x VERSION DEF LINE REF

%e 5000
%p 10000
%n 2000
%a 8000

NAME		[^ \t\n\r;:=&*$"]*
WHITE		[ \t\r]
MANTISSA        [+-]?([0-9]+"."[0-9]+|[0-9]+|[0-9]+"."[0-9]*|[0-9]*"."[0-9]+)
EXPONENT	[eE][+-]?[0-9]+
DOUBLE		{MANTISSA}{EXPONENT}?
SEC		[0-9]{1,2}|{DOUBLE}
ANGLE		[+-]?([0-9]{1,2})d([0-9]{1,2})\'{SEC}\"
%%
		{if(version)BEGIN(VERSION);version=0;}

<VERSION>"*"     	{yyerror("Comment not allowed before end of VEX_REV statement\n");}
<VERSION>VEX_rev	{return T_VEX_REV;}
<VERSION>{NAME}		{NEWSTR(yylval.sval,yytext); return T_NAME;}
<VERSION>{WHITE}*		{ /* skip white space */ }
<VERSION>;              {trailing=1;BEGIN(LINE); return yytext[0];}
<VERSION>=		{return(yytext[0]);}
<VERSION>.		{yyerror("lexical error 1 - non-token in version");}

<DEF>\n			{lines++;}
<DEF>{WHITE}*		{ /* skip white space */ }
<DEF>;			{trailing=1;BEGIN(LINE); return yytext[0];}
<DEF>{NAME}*		{NEWSTR(yylval.sval,yytext); return T_NAME;}
<DEF>\"			{ yylval.sval=quote(); return T_NAME;}
<DEF>:			{ return(yytext[0]);}
<DEF>.			{ yyerror("lexical error 2 - non-token in def statement");}

<LINE>"*"[^\n]*		{NEWSTR(yylval.sval,yytext);	 /* comment */
			if(trailing)
				return T_COMMENT_TRAILING;
			else
				return T_COMMENT;}

<LINE>"$"GLOBAL	{BEGIN(INITIAL);return B_GLOBAL;}
<LINE>"$"STATION	{BEGIN(INITIAL);return B_STATION;}
<LINE,REF>"$"EXPER	{BEGIN(INITIAL);return B_EXPER;}
<LINE,REF>"$"SCHEDULING_PARAMS	{BEGIN(INITIAL);return B_SCHEDULING_PARAMS;}
<LINE,REF>"$"PROCEDURES	{BEGIN(INITIAL);return B_PROCEDURES;}
<LINE,REF>"$"EOP		{BEGIN(INITIAL);return B_EOP;}
<LINE>"$"MODE		{BEGIN(INITIAL);return B_MODE;}
<LINE,REF>"$"FREQ		{BEGIN(INITIAL);return B_FREQ;}
<LINE,REF>"$"CLOCK	{BEGIN(INITIAL);return B_CLOCK;}
<LINE,REF>"$"ANTENNA	{BEGIN(INITIAL);return B_ANTENNA;}
<LINE,REF>"$"BBC		{BEGIN(INITIAL);return B_BBC;}
<LINE,REF>"$"BITSTREAMS		{BEGIN(INITIAL);return B_BITSTREAMS;}
<LINE,REF>"$"EXTENSIONS		{BEGIN(INITIAL);return B_EXTENSIONS;}
<LINE,REF>"$"CORR		{BEGIN(INITIAL);return B_CORR;}
<LINE,REF>"$"DAS		{BEGIN(INITIAL);return B_DAS;}
<LINE,REF>"$"DATASTREAMS	{inthreads = 0; BEGIN(INITIAL);return B_DATASTREAMS;}
<LINE,REF>"$"HEAD_POS	{BEGIN(INITIAL);return B_HEAD_POS;}
<LINE,REF>"$"PASS_ORDER	{BEGIN(INITIAL);return B_PASS_ORDER;}
<LINE,REF>"$"PHASE_CAL_DETECT	{BEGIN(INITIAL);return B_PHASE_CAL_DETECT;}
<LINE,REF>"$"ROLL		{BEGIN(INITIAL);return B_ROLL;}
<LINE,REF>"$"IF		{BEGIN(INITIAL);return B_IF;}
<LINE,REF>"$"SEFD		{BEGIN(INITIAL);return B_SEFD;}
<LINE,REF>"$"SITE		{BEGIN(INITIAL);return B_SITE;}
<LINE,REF>"$"SOURCE	{BEGIN(INITIAL);return B_SOURCE;}
<LINE,REF>"$"TAPELOG_OBS	{BEGIN(INITIAL);return B_TAPELOG_OBS;}
<LINE,REF>"$"TRACKS	{BEGIN(INITIAL);return B_TRACKS;}
<LINE,REF>"$"THREADS	{inthreads = 1; BEGIN(INITIAL); return B_THREADS;}
<LINE>"$"SCHED	{BEGIN(INITIAL);return B_SCHED;}

<REF,INITIAL>=		{if(ref == 1) {ref=0;BEGIN(DEF);} return(yytext[0]);}
<LINE>ref		{BEGIN(REF);ref=1;return T_REF;}
<LINE>def		{BEGIN(DEF);return T_DEF;}
<LINE>enddef		{BEGIN(INITIAL);return T_ENDDEF;}
<LINE>scan		{BEGIN(DEF);return T_SCAN;}
<LINE>endscan		{BEGIN(INITIAL);return T_ENDSCAN;}

<LINE>chan_def	{BEGIN(INITIAL);return T_CHAN_DEF;}
<LINE>sample_rate	{BEGIN(INITIAL);return T_SAMPLE_RATE;}
<LINE>bits_per_sample	{BEGIN(INITIAL);return T_BITS_PER_SAMPLE;}
<LINE>switching_cycle	{BEGIN(INITIAL);return T_SWITCHING_CYCLE;}

<LINE>start		{BEGIN(INITIAL);return T_START;}
<LINE>source		{BEGIN(INITIAL);return T_SOURCE;}
<LINE>mode		{BEGIN(INITIAL);return T_MODE;}
<LINE>station		{BEGIN(INITIAL);return T_STATION;}
<LINE>data_transfer	{BEGIN(INITIAL);return T_DATA_TRANSFER;}
<LINE>intent		{BEGIN(INITIAL);return T_INTENT;}
<LINE>pointing_offset		{BEGIN(INITIAL);return T_POINTING_OFFSET;}

<LINE>antenna_diam	{BEGIN(INITIAL);return T_ANTENNA_DIAM;}
<LINE>axis_type	{BEGIN(INITIAL);return T_AXIS_TYPE;}
<LINE>axis_offset	{BEGIN(INITIAL);return T_AXIS_OFFSET;}
<LINE>antenna_motion	{BEGIN(INITIAL);return T_ANTENNA_MOTION;}
<LINE>pointing_sector	{BEGIN(INITIAL);return T_POINTING_SECTOR;}
<LINE>nasmyth            {BEGIN(INITIAL);return T_NASMYTH;}

<LINE>BBC_assign	{BEGIN(INITIAL);return T_BBC_ASSIGN;}

<LINE>stream_def	{BEGIN(INITIAL);return T_STREAM_DEF;}
<LINE>stream_sample_rate	{BEGIN(INITIAL);return T_STREAM_SAMPLE_RATE;}
<LINE>stream_label	{BEGIN(INITIAL);return T_STREAM_LABEL;}

<LINE>clock_early	{BEGIN(INITIAL);return T_CLOCK_EARLY;}

<LINE>record_transport_type {BEGIN(INITIAL);return T_RECORD_TRANSPORT_TYPE;}
<LINE>electronics_rack_type {BEGIN(INITIAL);return T_ELECTRONICS_RACK_TYPE;}
<LINE>number_drives		{BEGIN(INITIAL);return T_NUMBER_DRIVES;}
<LINE>headstack		{BEGIN(INITIAL);return T_HEADSTACK;}
<LINE>record_density		{BEGIN(INITIAL);return T_RECORD_DENSITY;}
<LINE>tape_length		{BEGIN(INITIAL);return T_TAPE_LENGTH;}
<LINE>recording_system_ID	{BEGIN(INITIAL);return T_RECORDING_SYSTEM_ID;}
<LINE>tape_motion		{BEGIN(INITIAL);return T_TAPE_MOTION;}
<LINE>tape_control		{BEGIN(INITIAL);return T_TAPE_CONTROL;}
<LINE>equip		        {BEGIN(INITIAL);return T_EQUIP;}
<LINE>composite_equip	        {BEGIN(INITIAL);return T_COMPOSITE_EQUIP;}
<LINE>equip_set	                {BEGIN(INITIAL);return T_EQUIP_SET;}
<LINE>equip_info                {BEGIN(INITIAL);return T_EQUIP_INFO;}
<LINE>connection                {BEGIN(INITIAL);return T_CONNECTION;}
<LINE>record_method             {BEGIN(INITIAL);return T_RECORD_METHOD;}
<LINE>record_control            {BEGIN(INITIAL);return T_RECORD_CONTROL;}

<LINE>datastream	        {BEGIN(INITIAL);return T_DATASTREAM;}
<LINE>thread	                {BEGIN(INITIAL);return (inthreads ? T_THREAD_DEF : T_THREAD);}
<LINE>channel	                {BEGIN(INITIAL);return (inthreads ? T_CHANNEL_DEF : T_CHANNEL);}
<LINE>merged_datastream	        {BEGIN(INITIAL);return T_MERGED_DATASTREAM;}

<LINE>TAI-UTC			{BEGIN(INITIAL);return T_TAI_UTC;}
<LINE>A1-TAI			{BEGIN(INITIAL);return T_A1_TAI;}
<LINE>eop_ref_epoch		{BEGIN(INITIAL);return T_EOP_REF_EPOCH;}
<LINE>num_eop_points		{BEGIN(INITIAL);return T_NUM_EOP_POINTS;}
<LINE>eop_interval		{BEGIN(INITIAL);return T_EOP_INTERVAL;}
<LINE>ut1-utc			{BEGIN(INITIAL);return T_UT1_UTC;}
<LINE>x_wobble		        {BEGIN(INITIAL);return T_X_WOBBLE;}
<LINE>y_wobble		        {BEGIN(INITIAL);return T_Y_WOBBLE;}
<LINE>nut_ref_epoch		{BEGIN(INITIAL);return T_NUT_REF_EPOCH;}
<LINE>num_nut_points		{BEGIN(INITIAL);return T_NUM_NUT_POINTS;}
<LINE>nut_interval		{BEGIN(INITIAL);return T_NUT_INTERVAL;}
<LINE>delta_psi			{BEGIN(INITIAL);return T_DELTA_PSI;}
<LINE>delta_eps		        {BEGIN(INITIAL);return T_DELTA_EPS;}
<LINE>nut_model			{BEGIN(INITIAL);return T_NUT_MODEL;}
<LINE>eop_origin		{BEGIN(INITIAL);return T_EOP_ORIGIN;}
<LINE>delta_x_nut		{BEGIN(INITIAL);return T_DELTA_X_NUT;}
<LINE>delta_y_nut		{BEGIN(INITIAL);return T_DELTA_Y_NUT;}
<LINE>nut_origin		{BEGIN(INITIAL);return T_NUT_ORIGIN;}

<LINE>exper_num		{BEGIN(INITIAL);return T_EXPER_NUM;}
<LINE>exper_name		{BEGIN(INITIAL);return T_EXPER_NAME;}
<LINE>exper_description		{BEGIN(INITIAL);return T_EXPER_DESCRIPTION;}
<LINE>exper_nominal_start	{BEGIN(INITIAL);return T_EXPER_NOMINAL_START;}
<LINE>exper_nominal_stop	{BEGIN(INITIAL);return T_EXPER_NOMINAL_STOP;}
<LINE>PI_name			{BEGIN(INITIAL);return T_PI_NAME;}
<LINE>PI_email		{BEGIN(INITIAL);return T_PI_EMAIL;}
<LINE>contact_name		{BEGIN(INITIAL);return T_CONTACT_NAME;}
<LINE>contact_email		{BEGIN(INITIAL);return T_CONTACT_EMAIL;}
<LINE>scheduler_name		{BEGIN(INITIAL);return T_SCHEDULER_NAME;}
<LINE>scheduler_email		{BEGIN(INITIAL);return T_SCHEDULER_EMAIL;}
<LINE>target_correlator	{BEGIN(INITIAL);return T_TARGET_CORRELATOR;}
<LINE>scheduling_software	{BEGIN(INITIAL);return T_SCHEDULING_SOFTWARE;}
<LINE>VEX_file_writer	{BEGIN(INITIAL);return T_VEX_FILE_WRITER;}
<LINE>extension  	{BEGIN(INITIAL);return T_EXTENSION;}

<LINE>headstack_pos		{BEGIN(INITIAL);return T_HEADSTACK_POS;}

<LINE>if_def			{BEGIN(INITIAL);return T_IF_DEF;}
<LINE>receiver_name	        {BEGIN(INITIAL);return T_RECEIVER_NAME;}
<LINE>sub_lo_frequencies	        {BEGIN(INITIAL);return T_SUB_LO_FREQUENCIES;}
<LINE>sub_lo_sidebands	        {BEGIN(INITIAL);return T_SUB_LO_SIDEBANDS;}
<LINE>switched_power	        {BEGIN(INITIAL);return T_SWITCHED_POWER;}

<LINE>pass_order		{BEGIN(INITIAL);return T_PASS_ORDER;}
<LINE>S2_group_order		{BEGIN(INITIAL);return T_S2_GROUP_ORDER;}

<LINE>phase_cal_detect		{BEGIN(INITIAL);return T_PHASE_CAL_DETECT;}

<LINE>tape_change		{BEGIN(INITIAL);return T_TAPE_CHANGE;}
<LINE>headstack_motion		{BEGIN(INITIAL);return T_HEADSTACK_MOTION;}
<LINE>new_source_command	{BEGIN(INITIAL);return T_NEW_SOURCE_COMMAND;}
<LINE>new_tape_setup		{BEGIN(INITIAL);return T_NEW_TAPE_SETUP;}
<LINE>setup_always		{BEGIN(INITIAL);return T_SETUP_ALWAYS;}
<LINE>parity_check		{BEGIN(INITIAL);return T_PARITY_CHECK;}
<LINE>tape_prepass		{BEGIN(INITIAL);return T_TAPE_PREPASS;}
<LINE>preob_cal		{BEGIN(INITIAL);return T_PREOB_CAL;}
<LINE>midob_cal		{BEGIN(INITIAL);return T_MIDOB_CAL;}
<LINE>postob_cal		{BEGIN(INITIAL);return T_POSTOB_CAL;}
<LINE>procedure_name_prefix {BEGIN(INITIAL);return T_PROCEDURE_NAME_PREFIX;}

<LINE>roll_reinit_period	{BEGIN(INITIAL);return T_ROLL_REINIT_PERIOD;}
<LINE>roll_inc_period		{BEGIN(INITIAL);return T_ROLL_INC_PERIOD;}
<LINE>roll			{BEGIN(INITIAL);return T_ROLL;}
<LINE>roll_def			{BEGIN(INITIAL);return T_ROLL_DEF;}

<LINE>sefd_model		{BEGIN(INITIAL);return T_SEFD_MODEL;}
<LINE>sefd			{BEGIN(INITIAL);return T_SEFD;}

<LINE>site_type		{BEGIN(INITIAL);return T_SITE_TYPE;}
<LINE>site_name		{BEGIN(INITIAL);return T_SITE_NAME;}
<LINE>site_ID			{BEGIN(INITIAL);return T_SITE_ID;}
<LINE>site_position		{BEGIN(INITIAL);return T_SITE_POSITION;}
<LINE>site_position_epoch	{BEGIN(INITIAL);return T_SITE_POSITION_EPOCH;}
<LINE>site_position_ref		{BEGIN(INITIAL);return T_SITE_POSITION_REF;}
<LINE>site_velocity		{BEGIN(INITIAL);return T_SITE_VELOCITY;}
<LINE>horizon_map_az		{BEGIN(INITIAL);return T_HORIZON_MAP_AZ;}
<LINE>horizon_map_el		{BEGIN(INITIAL);return T_HORIZON_MAP_EL;}
<LINE>zen_atmos		{BEGIN(INITIAL);return T_ZEN_ATMOS;}
<LINE>ocean_load_vert		{BEGIN(INITIAL);return T_OCEAN_LOAD_VERT;}
<LINE>ocean_load_horiz	{BEGIN(INITIAL);return T_OCEAN_LOAD_HORIZ;}
<LINE>occupation_code		{BEGIN(INITIAL);return T_OCCUPATION_CODE;}
<LINE>inclination		{BEGIN(INITIAL);return T_INCLINATION;}
<LINE>eccentricity		{BEGIN(INITIAL);return T_ECCENTRICITY;}
<LINE>arg_perigee		{BEGIN(INITIAL);return T_ARG_PERIGEE;}
<LINE>ascending_node		{BEGIN(INITIAL);return T_ASCENDING_NODE;}
<LINE>mean_anomaly		{BEGIN(INITIAL);return T_MEAN_ANOMALY;}
<LINE>semi-major_axis		{BEGIN(INITIAL);return T_SEMI_MAJOR_AXIS;}
<LINE>mean_motion		{BEGIN(INITIAL);return T_MEAN_MOTION;}
<LINE>orbit_epoch		{BEGIN(INITIAL);return T_ORBIT_EPOCH;}

<LINE>source_type		{BEGIN(INITIAL);return T_SOURCE_TYPE;}
<LINE>source_name		{BEGIN(INITIAL);return T_SOURCE_NAME;}
<LINE>IAU_name		{BEGIN(INITIAL);return T_IAU_NAME;}
<LINE>ra			{BEGIN(INITIAL);return T_RA;}
<LINE>dec			{BEGIN(INITIAL);return T_DEC;}
<LINE>ref_coord_frame		{BEGIN(INITIAL);return T_REF_COORD_FRAME;}
<LINE>source_position_ref	{BEGIN(INITIAL);return T_SOURCE_POSITION_REF;}
<LINE>ra_rate			{BEGIN(INITIAL);return T_RA_RATE;}
<LINE>dec_rate		{BEGIN(INITIAL);return T_DEC_RATE;}
<LINE>source_position_epoch    {BEGIN(INITIAL);return T_SOURCE_POSITION_EPOCH;}
<LINE>velocity_wrt_LSR	{BEGIN(INITIAL);return T_VELOCITY_WRT_LSR;}
<LINE>source_model		{BEGIN(INITIAL);return T_SOURCE_MODEL;}
<LINE>bsp_file_name		{BEGIN(INITIAL);return T_BSP_FILE_NAME;}
<LINE>bsp_object_id		{BEGIN(INITIAL);return T_BSP_OBJECT_ID;}
<LINE>tle0		{BEGIN(INITIAL);return T_TLE0;}
<LINE>tle1		{BEGIN(INITIAL);return T_TLE1;}
<LINE>tle2		{BEGIN(INITIAL);return T_TLE2;}
<LINE>datum     {BEGIN(INITIAL);return T_DATUM;}
<LINE>vector    {BEGIN(INITIAL);return T_VECTOR;}

<LINE>VSN			{BEGIN(INITIAL);return T_VSN;}

<LINE>fanin_def		{BEGIN(INITIAL);return T_FANIN_DEF;}
<LINE>fanout_def		{BEGIN(INITIAL);return T_FANOUT_DEF;}
<LINE>track_frame_format	{BEGIN(INITIAL);return T_TRACK_FRAME_FORMAT;}
<LINE>data_modulation		{BEGIN(INITIAL);return T_DATA_MODULATION;}
<LINE>VLBA_frmtr_sys_trk	{BEGIN(INITIAL);return T_VLBA_FRMTR_SYS_TRK;}
<LINE>VLBA_trnsprt_sys_trk	{BEGIN(INITIAL);return T_VLBA_TRNSPRT_SYS_TRK;}
<LINE>S2_recording_mode		{BEGIN(INITIAL);return T_S2_RECORDING_MODE;}
<LINE>S2_data_source		{BEGIN(INITIAL);return T_S2_DATA_SOURCE;}

<LINE>format		{BEGIN(INITIAL);return T_FORMAT_DEF;}

<LINE>start_literal\(		{BEGIN(INITIAL); yylval.llptr=lit(); return T_LITERAL;}
	
<LINE,REF>\n		{trailing=0;lines++;}
<LINE,REF>{WHITE}*	{/* skip white space */}
<LINE>.			{yyerror("lexical error 3 - non-token at start of statement");}
<REF>{NAME}		{ NEWSTR(yylval.sval,yytext);return T_NAME; }
<REF>:			{return(yytext[0]);}
<REF>.			{yyerror("lexical error 4 - non-token in ref statement");}

{ANGLE}		{ NEWSTR(yylval.sval,yytext); return T_ANGLE; }

\"		{ yylval.sval=quote(); return T_NAME;}
{NAME}		{ NEWSTR(yylval.sval,yytext); return T_NAME; }
\&{NAME}	{ NEWSTR(yylval.sval,yytext+1); return T_LINK; }
\&\"		{ yylval.sval=quote(); return T_LINK;}

\n		{trailing=0;lines++;}
{WHITE}*	{/* skip white space */}

;		{trailing=1;BEGIN(LINE);return(yytext[0]);}
:		{return(yytext[0]);}
.		{yyerror("lexical error 5 - non-token after statement started");}

<<EOF>>         {version=1;ref=0;trailing=0;lines=1;yyterminate();}
%%
struct llist *lit()
{
  int inch, count, max_size;
  char *buffer, *last, *text;
  struct llist *llist;

  buffer = malloc(ALLOC_SIZE);
  if(buffer == NULL)
    yyerror("out of memory in literal 1");

/* find text inside start_literal() */

  max_size = ALLOC_SIZE;
  count=0;
  inch= input();
  while(inch !=EOF && inch != ')' && inch != 0 && inch != '\n') {
    buffer[count++]=inch;
    if(count >= max_size) {
      buffer=realloc(buffer,max_size+ALLOC_SIZE);
      if(buffer == NULL)
	yyerror("out of memory in literal 2");
      max_size += ALLOC_SIZE;
    }
    inch=input();
  }
  if(inch == EOF)
    yyerror("End of file in literal block delimiting text\n");
  else if (inch == 0)
    yyerror("Illegal character (\\0) in literal delimiting text\n");
  else if (inch == '\n')
    yyerror("Illegal character (\\n) in literal delimiting text\n");

  buffer[count++]='\0';
  buffer=realloc(buffer,count);
  if(buffer == NULL)
    yyerror("out of memory in literal 3");

  text=buffer;
  llist=add_list(NULL,buffer);

/* skip to ';' */

  inch=input();
  while(inch !=EOF && inch != ';' && inch != '\0') {
    if(inch == '\n')
      lines++;
    else if(NULL == strchr(" \t\r",inch))
      yyerror("Illegal character after start_literal()");
    inch=input();
  }
  if(inch == EOF)
    yyerror("End of file in literal block");
  else if (inch == 0)
    yyerror("Illegal character (\\0) after start_literal()");

  /* skip to '\n' */

  inch=input();
  while(inch !=EOF && inch != '\n' && inch != '\0') {
    if(NULL == strchr(" \t\r",inch))
      yyerror("Illegal Xcharacter after start_literal();");
    inch=input();
  }
  if(inch == EOF)
    yyerror("End of file in literal block");
  else if (inch == 0)
    yyerror("Illegal character (\\0) after start_literal();");
  else if(inch == '\n')
    lines++;

  /* read lines */

  buffer = malloc(ALLOC_SIZE);
  if(buffer == NULL)
    yyerror("out of memory in literal 4");

  max_size = ALLOC_SIZE;
  count=0;
  inch= input();
  while(inch !=EOF && inch != 0) {
    if(inch != '\n') {
      buffer[count++]=inch;
      if(count >= max_size) {
	buffer=realloc(buffer,max_size+ALLOC_SIZE);
	if(buffer == NULL)
	  yyerror("out of memory in literal 8");
	max_size += ALLOC_SIZE;
      }
    } else {
      buffer[count++]='\0';
      last=find_end(buffer,text);
      if(last != NULL)
	goto done;
      lines++;
      buffer=realloc(buffer,count);
      if(buffer == NULL)
	yyerror("out of memory in literal 6");
      llist=add_list(llist,buffer);
      buffer = malloc(ALLOC_SIZE);
      if(buffer == NULL)
	yyerror("out of memory in literal 7");
      max_size = ALLOC_SIZE;
      count=0;
    }
    inch=input();
  }
  if(inch == EOF)
    yyerror("End of file in literal block\n");
  else if (inch == 0)
    yyerror("Illegal character (\\0) in literal block\n");

 done:
  {
    int i=strlen(last)-1;

    unput('\n');
    while ( i >= 0) {
       unput(last[i]);
    i--;
    }
  }
  free(buffer);

  return llist;
}
static char *find_end(char *buffer, char *text)
{
  char *ptr, *start;
  char end[]="end_literal(";
  int textlen=strlen(text);

  start=buffer;
  while(NULL != (ptr=strchr(buffer++,end[0])))
    if(0==strncmp(ptr,end,sizeof(end)-1))
      if(0==strncmp(ptr+sizeof(end)-1,text,textlen))
	if(0==strncmp(ptr+sizeof(end)-1+textlen,")",1)) {
	  *ptr='\0';
	  for(;*start!=0;start++)
	    if(NULL == strchr(" \t\r",*start))
	      yyerror("Illegal character between '\\n' and end_literal(...)");
	  return ptr+sizeof(end)+textlen;
	}

  return NULL;
}
char *quote()
{
  int inch, count, max_size;
  char *buffer;
  int temp, ch;

  buffer = malloc(ALLOC_SIZE);
  max_size = ALLOC_SIZE;
  inch=input();
  count=0;
  while(inch != EOF && inch != '"' && inch != '\n') {
    if(inch=='\\') {
      inch=input();
      switch (inch) {
      case '\n':
	lines++;
	inch=input();
	break;
      case 'a':
	inch='\a';
	break;
      case 'b':
	inch='\b';
	break;
      case 't':
	inch='\t';
	break;
      case 'n':
	inch='\n';
	break;
      case 'v':
	inch='\v';
	break;
      case 'f':
	inch='\f';
	break;
      case 'r':
	inch='\r';
	break;
      case 'X':
      case 'x':
	/* save which character we actually saw */
	ch=inch;
	inch=input();
	if(isxdigit(inch)){
	  temp=hextoint(toupper(inch));
	  inch=input();
	  if(isxdigit(inch)){
	    temp=(temp <<4) + hextoint(toupper(inch));
	  } else {
	    unput(inch);
	  }
	  inch=temp;
	} else {
	  unput(inch);
	  /* wasn't hex number, put back the character we saw */
	  inch=ch;
	}
	break;
      default:
	if(isodigit(inch)) {
	  temp=inch-'0';
	  inch=input();
	  if(isodigit(inch)){
	    temp = (temp << 3) + (inch - '0');
	    inch=input();
	    if(isodigit(inch)){
	      temp = (temp << 3) + (inch - '0');
	    } else {
	      unput(inch);
	    }
	  } else {
	    unput(inch);
	  }
	  inch=temp;
	}
      }
    }
    if(inch == 0) {
      char tmpbuf[128];
      sprintf(tmpbuf, "Null byte specified at line %d\n", lines);
      yyerror(tmpbuf);
    }
    buffer[count++] = inch;
    if(count >= max_size) {
      buffer = realloc(buffer,max_size + ALLOC_SIZE);
      max_size += ALLOC_SIZE;
    }
    inch = input();
  }
  if(inch == EOF || inch == '\n') {
    char tmpbuf[128];
    sprintf(tmpbuf, "Unterminated string at line %d\n", lines);
    yyerror(tmpbuf);
  }
  buffer[count]='\0';
  if(strlen(buffer) > 128) {
    yyerror("quoted string too long");
  }
  return buffer;
}
