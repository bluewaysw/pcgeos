
/*  A Bison parser, made from parse.y  */

#define YYBISON 1  /* Identify Bison output.  */

#define	IDENT	258
#define	KNUMBER	259
#define	NUMBER	260
#define	ALIGNMENT	261
#define	COMBINE	262
#define	STRING	263
#define	NAME	264
#define	LONGNAME	265
#define	TOKENCHARS	266
#define	TOKENID	267
#define	TYPE	268
#define	PROCESS	269
#define	DRIVER	270
#define	LIBRARY	271
#define	SINGLE	272
#define	APPL	273
#define	USES_COPROC	274
#define	NEEDS_COPROC	275
#define	SYSTEM	276
#define	HAS_GCM	277
#define	C_API	278
#define	PLATFORM	279
#define	SHIP	280
#define	EXEMPT	281
#define	DISCARDABLE_DGROUP	282
#define	REV	283
#define	APPOBJ	284
#define	NOLOAD	285
#define	EXPORT	286
#define	AS	287
#define	SKIP	288
#define	UNTIL	289
#define	CLASS	290
#define	STACK	291
#define	HEAPSPACE	292
#define	RESOURCE	293
#define	READONLY	294
#define	DISCARDONLY	295
#define	PRELOAD	296
#define	FIXED	297
#define	CONFORMING	298
#define	SHARED	299
#define	CODE	300
#define	DATA	301
#define	LMEM	302
#define	UIOBJECT	303
#define	OBJECT	304
#define	SWAPONLY	305
#define	DISCARDABLE	306
#define	SWAPABLE	307
#define	NOSWAP	308
#define	NODISCARD	309
#define	ENTRY	310
#define	USERNOTES	311
#define	LOAD	312
#define	NOSORT	313
#define	INCMINOR	314
#define	PUBLISH	315
#define	IFDEF	316
#define	ELSE	317
#define	ENDIF	318
#define	IFNDEF	319

#line 1 "parse.y"

/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Geode Parameter File Parsing
 * FILE:	  parse.y
 *
 * AUTHOR:  	  Adam de Boor: Sep 26, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	yyparse	    	    Parse the file
 *	Parse_Params	    Set up for and parse a parameter file.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	9/26/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Grammar to parse a geode-parameter file to specify the important
 *	attributes of a geode.
 *
 *	The geode-parameter file should be run through this grammar
 *	at the end of pass 1.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: parse.y,v 2.59 96/07/08 17:29:34 tbradley Exp $";
#endif lint

#include    "glue.h"
#include    "library.h"
#include    "sym.h"
#include    "parse.h"

#include    <ctype.h>
#include    <objfmt.h>

#include	  "geo.h"

#if defined(unix)
#define FILE_AND_LINE "file \"%s\", line %d: "
#else
#define FILE_AND_LINE "%s %d: "
#endif

#define GA_SINGLE_LAUNCH 0x10000    /* Fake attribute to handle restriction
				     * to single launch, since applications
				     * by default will allow multiple
				     * launches, but geos only has the
				     * GA_MULTI_LAUNCHABLE flag */
/*
 * Global var for use by the resFlags rule.
 */
static unsigned short	    resFlags;

static char 	*paramFile; 	/* Name of file being read */
static int  	yylineno=1; 	/* Line number in parameter file */
static int  	yylex();    	/* Can't use full prototype b/c YYSTYPE not
				 * defined yet... */
static int  	nameseen=0;
static int  	errorgiven=0;

static int	loadingLibs = 0;

static SegAlias	curAlias;
static Boolean	doingAlias = FALSE;

Boolean		  noSort = FALSE;   /* Set TRUE if user has indicated, via
				     * "nosort" command, that resources are
				     * not to be sorted */

/*
 * Stack of nested if's. iflevel == -1 => no nested ifs in progress. The
 * stack is necessary to handle elseifs properly. The way these things work
 * is to process things normally if a conditional is true, but when it is
 * false, to call ScanToEndif, which reads the file until the end of the
 * conditional is reached. The terminating token, be it an ELSE, ELSEIF or
 * ENDIF, is pushed back into the input stream, preceded by a newline,
 * to be read next.
 */
#define MAX_TOKEN_LENGTH    256
#define MAX_IF_LEVEL	    30
int 		ifStack[MAX_IF_LEVEL];
int		iflevel=-1;

static void HandleIFDEF(int, char *);
void ScanToEndif(int orElse);

/*
 * Provide our own handler for the parser-stack overflow so the default one
 * that uses "alloca" isn't used, since alloca is forbidden to us owing to
 * the annoying hidden non-support of said function by our dearly beloved
 * HighC from MetaWare, A.M.D.G.
 */
#define yyoverflow(m,s,S,v,V,d) ParseStackOverflow(m,s,S,(void **)v,V,d)
static void ParseStackOverflow(char *,
			       short **, size_t,
			       void **, size_t,
			       int *);


#line 112 "parse.y"
typedef union {
    long    number;
    char    *string;
    Boolean bool;
    LibraryLoadTypes loadType;
} YYSTYPE;

#ifndef YYLTYPE
typedef
  struct yyltype
    {
      int timestamp;
      int first_line;
      int first_column;
      int last_line;
      int last_column;
      char *text;
   }
  yyltype;

#define YYLTYPE yyltype
#endif

#ifndef YYDEBUG
#define YYDEBUG 1
#endif

#include <stdio.h>

#ifndef __STDC__
#define const
#endif



#define	YYFINAL		165
#define	YYFLAG		-32768
#define	YYNTBASE	68

#define YYTRANSLATE(x) ((unsigned)(x) <= 319 ? yytranslate[x] : 92)

static const char yytranslate[] = {     0,
     2,     2,     2,     2,     2,     2,     2,     2,     2,    65,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,    67,     2,    66,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     1,     2,     3,     4,     5,
     6,     7,     8,     9,    10,    11,    12,    13,    14,    15,
    16,    17,    18,    19,    20,    21,    22,    23,    24,    25,
    26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
    36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
    46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
    56,    57,    58,    59,    60,    61,    62,    63,    64
};

static const short yyprhs[] = {     0,
     0,     1,     4,     6,    12,    15,    19,    22,    25,    29,
    31,    34,    38,    40,    42,    44,    46,    48,    50,    52,
    54,    56,    58,    60,    64,    68,    72,    76,    80,    83,
    86,    88,    90,    95,    97,   101,   103,   105,   109,   111,
   113,   117,   119,   120,   122,   125,   129,   134,   139,   140,
   145,   147,   151,   154,   156,   160,   164,   168,   172,   176,
   178,   181,   182,   188,   191,   194,   195,   197,   199,   202,
   206,   208,   210,   212,   214,   216,   218,   220,   222,   224,
   226,   228,   230,   232,   234,   236,   238,   241,   247,   249,
   252,   255,   257,   258,   260,   262,   264,   267,   270,   273,
   277,   280,   282,   285,   287,   291
};

static const short yyrhs[] = {    -1,
    68,    69,     0,    65,     0,     9,     3,    66,     3,    65,
     0,    11,     8,     0,    12,     5,    65,     0,    10,     8,
     0,    56,     8,     0,    13,    70,    65,     0,    71,     0,
    70,    71,     0,    70,    67,    71,     0,    14,     0,    15,
     0,    16,     0,    17,     0,    18,     0,    19,     0,    20,
     0,    21,     0,    22,     0,    23,     0,    27,     0,    29,
     3,    65,     0,    15,     3,    65,     0,    24,    72,    65,
     0,    25,    74,    65,     0,    26,    76,    65,     0,    61,
     3,     0,    64,     3,     0,    62,     0,    63,     0,    16,
     3,    78,    65,     0,    73,     0,    72,    67,    73,     0,
     3,     0,    75,     0,    74,    67,    75,     0,     3,     0,
    77,     0,    76,    67,    77,     0,     3,     0,     0,    30,
     0,    30,    42,     0,    33,     5,    65,     0,    33,    34,
     5,    65,     0,    33,    34,     3,    65,     0,     0,    31,
    79,    81,    65,     0,     3,     0,     3,    32,     3,     0,
     3,    61,     0,    80,     0,    81,    67,    80,     0,    35,
     3,    65,     0,    36,     5,    65,     0,    37,     5,    65,
     0,    37,     4,    65,     0,    38,     0,    38,    61,     0,
     0,    82,     3,    83,    84,    65,     0,    58,    65,     0,
     1,    65,     0,     0,    85,     0,    86,     0,    85,    86,
     0,    85,    67,    86,     0,    39,     0,    51,     0,    40,
     0,    50,     0,    52,     0,    53,     0,    54,     0,    41,
     0,    42,     0,    43,     0,    44,     0,    45,     0,    46,
     0,    47,     0,    48,     0,    49,     0,    55,     3,     0,
    57,    87,    32,    88,    65,     0,     3,     0,     3,     8,
     0,     3,    89,     0,    89,     0,     0,     6,     0,     7,
     0,     8,     0,     6,     7,     0,     6,     8,     0,     7,
     8,     0,     6,     7,     8,     0,    60,     3,     0,    59,
     0,    59,    90,     0,    91,     0,    90,    67,    91,     0,
     3,     0
};

#if YYDEBUG != 0
static const short yyrline[] = { 0,
   150,   154,   156,   157,   222,   257,   277,   333,   355,   364,
   365,   366,   368,   369,   370,   371,   372,   373,   374,   375,
   376,   377,   378,   380,   389,   396,   399,   402,   405,   409,
   413,   435,   444,   465,   466,   468,   476,   477,   479,   487,
   488,   490,   498,   499,   500,   502,   508,   514,   520,   527,
   529,   535,   545,   552,   553,   555,   564,   569,   575,   582,
   583,   585,   589,   690,   694,   708,   709,   711,   712,   713,
   715,   725,   731,   736,   741,   745,   749,   753,   754,   760,
   764,   765,   766,   776,   781,   792,   804,   813,   823,   833,
   848,   856,   858,   862,   867,   872,   880,   886,   895,   904,
   916,   930,   936,   941,   942,   945
};

static const char * const yytname[] = {   "$","error","$illegal.","IDENT","KNUMBER",
"NUMBER","ALIGNMENT","COMBINE","STRING","NAME","LONGNAME","TOKENCHARS","TOKENID",
"TYPE","PROCESS","DRIVER","LIBRARY","SINGLE","APPL","USES_COPROC","NEEDS_COPROC",
"SYSTEM","HAS_GCM","C_API","PLATFORM","SHIP","EXEMPT","DISCARDABLE_DGROUP","REV",
"APPOBJ","NOLOAD","EXPORT","AS","SKIP","UNTIL","CLASS","STACK","HEAPSPACE","RESOURCE",
"READONLY","DISCARDONLY","PRELOAD","FIXED","CONFORMING","SHARED","CODE","DATA",
"LMEM","UIOBJECT","OBJECT","SWAPONLY","DISCARDABLE","SWAPABLE","NOSWAP","NODISCARD",
"ENTRY","USERNOTES","LOAD","NOSORT","INCMINOR","PUBLISH","IFDEF","ELSE","ENDIF",
"IFNDEF","'\\n'","'.'","','","file","line","typeArgs","typeArg","platformList",
"platformFile","shipList","shipFile","exemptList","exemptLib","noload","@1",
"exportid","idList","resource","@2","resArgs","resArgList","resArg","nameAndClass",
"loadArgs","segAttrs","protoMinorList","protominorid",""
};
#endif

static const short yyr1[] = {     0,
    68,    68,    69,    69,    69,    69,    69,    69,    69,    70,
    70,    70,    71,    71,    71,    71,    71,    71,    71,    71,
    71,    71,    71,    69,    69,    69,    69,    69,    69,    69,
    69,    69,    69,    72,    72,    73,    74,    74,    75,    76,
    76,    77,    78,    78,    78,    69,    69,    69,    79,    69,
    80,    80,    80,    81,    81,    69,    69,    69,    69,    82,
    82,    83,    69,    69,    69,    84,    84,    85,    85,    85,
    86,    86,    86,    86,    86,    86,    86,    86,    86,    86,
    86,    86,    86,    86,    86,    86,    69,    69,    87,    87,
    88,    88,    89,    89,    89,    89,    89,    89,    89,    89,
    69,    69,    69,    90,    90,    91
};

static const short yyr2[] = {     0,
     0,     2,     1,     5,     2,     3,     2,     2,     3,     1,
     2,     3,     1,     1,     1,     1,     1,     1,     1,     1,
     1,     1,     1,     3,     3,     3,     3,     3,     2,     2,
     1,     1,     4,     1,     3,     1,     1,     3,     1,     1,
     3,     1,     0,     1,     2,     3,     4,     4,     0,     4,
     1,     3,     2,     1,     3,     3,     3,     3,     3,     1,
     2,     0,     5,     2,     2,     0,     1,     1,     2,     3,
     1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
     1,     1,     1,     1,     1,     1,     2,     5,     1,     2,
     2,     1,     0,     1,     1,     1,     2,     2,     2,     3,
     2,     1,     2,     1,     3,     1
};

static const short yydefact[] = {     1,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,    49,     0,     0,     0,     0,    60,     0,
     0,     0,     0,   102,     0,     0,    31,    32,     0,     3,
     2,     0,    65,     0,     7,     5,     0,    13,    14,    15,
    16,    17,    18,    19,    20,    21,    22,    23,     0,    10,
     0,    43,    36,     0,    34,    39,     0,    37,    42,     0,
    40,     0,     0,     0,     0,     0,     0,     0,     0,    61,
    87,     8,    89,     0,    64,   106,   103,   104,   101,    29,
    30,    62,     0,     6,     9,     0,    11,    25,    44,     0,
    26,     0,    27,     0,    28,     0,    24,    51,    54,     0,
    46,     0,     0,    56,    57,    59,    58,    90,    93,     0,
    66,     0,    12,    45,    33,    35,    38,    41,     0,    53,
    50,     0,    48,    47,    93,    94,    95,    96,     0,    92,
   105,    71,    73,    78,    79,    80,    81,    82,    83,    84,
    85,    86,    74,    72,    75,    76,    77,     0,    67,    68,
     4,    52,    55,    91,    97,    98,    99,    88,    63,     0,
    69,   100,    70,     0,     0
};

static const short yydefgoto[] = {     1,
    31,    49,    50,    54,    55,    57,    58,    60,    61,    90,
    63,    99,   100,    32,   111,   148,   149,   150,    74,   129,
   130,    77,    78
};

static const short yypact[] = {-32768,
     0,   -38,    46,    42,    45,    49,    97,    90,   118,   119,
   120,   122,   123,-32768,    -2,   124,   125,     3,    67,   126,
   127,   128,    68,   129,   131,   133,-32768,-32768,   134,-32768,
-32768,   135,-32768,    73,-32768,-32768,    75,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,    25,-32768,
    77,   111,-32768,   -63,-32768,-32768,   -37,-32768,-32768,    20,
-32768,    78,   141,    80,    83,    81,    82,    84,    85,-32768,
-32768,-32768,   140,   121,-32768,-32768,    87,-32768,-32768,-32768,
-32768,-32768,   148,-32768,-32768,    97,-32768,-32768,   110,    91,
-32768,   119,-32768,   120,-32768,   122,-32768,   -27,-32768,    24,
-32768,    92,    93,-32768,-32768,-32768,-32768,-32768,    15,   129,
    56,    94,-32768,-32768,-32768,-32768,-32768,-32768,   152,-32768,
-32768,   141,-32768,-32768,    76,    12,   153,-32768,    95,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,    98,    27,-32768,
-32768,-32768,-32768,-32768,   154,-32768,-32768,-32768,-32768,    56,
-32768,-32768,-32768,   164,-32768
};

static const short yypgoto[] = {-32768,
-32768,-32768,   -35,-32768,    74,-32768,    71,-32768,    72,-32768,
-32768,    47,-32768,-32768,-32768,-32768,-32768,  -143,-32768,-32768,
    48,-32768,    57
};


#define	YYLAST		173


static const short yytable[] = {   164,
     2,    91,    64,    92,   119,   161,    68,    69,     3,     4,
     5,     6,     7,    87,     8,     9,   163,   125,   155,   156,
   126,   127,   128,    10,    11,    12,    33,    93,    13,    94,
    14,    65,    15,   120,    16,    17,    18,    19,    38,    39,
    40,    41,    42,    43,    44,    45,    46,    47,    34,    35,
   113,    48,    36,    37,    20,    21,    22,    23,    24,    25,
    26,    27,    28,    29,    30,   132,   133,   134,   135,   136,
   137,   138,   139,   140,   141,   142,   143,   144,   145,   146,
   147,   126,   127,   128,    95,   102,    96,   103,   121,    85,
   122,    86,    51,   160,   132,   133,   134,   135,   136,   137,
   138,   139,   140,   141,   142,   143,   144,   145,   146,   147,
    38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
    52,    53,    56,    48,    59,    62,    66,    70,    71,    67,
    73,    76,    75,    79,    72,    80,    81,    82,    83,    84,
    89,    88,    97,    98,   101,   104,   105,   108,   106,   107,
   112,   114,   109,   110,   152,   115,   123,   124,   151,   158,
   157,   162,   159,   165,   117,   116,   131,   118,   153,     0,
     0,     0,   154
};

static const short yycheck[] = {     0,
     1,    65,     5,    67,    32,   149,     4,     5,     9,    10,
    11,    12,    13,    49,    15,    16,   160,     3,     7,     8,
     6,     7,     8,    24,    25,    26,    65,    65,    29,    67,
    31,    34,    33,    61,    35,    36,    37,    38,    14,    15,
    16,    17,    18,    19,    20,    21,    22,    23,     3,     8,
    86,    27,     8,     5,    55,    56,    57,    58,    59,    60,
    61,    62,    63,    64,    65,    39,    40,    41,    42,    43,
    44,    45,    46,    47,    48,    49,    50,    51,    52,    53,
    54,     6,     7,     8,    65,     3,    67,     5,    65,    65,
    67,    67,     3,    67,    39,    40,    41,    42,    43,    44,
    45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
    14,    15,    16,    17,    18,    19,    20,    21,    22,    23,
     3,     3,     3,    27,     3,     3,     3,    61,     3,     5,
     3,     3,    65,     3,     8,     3,     3,     3,    66,    65,
    30,    65,    65,     3,    65,    65,    65,     8,    65,    65,
     3,    42,    32,    67,     3,    65,    65,    65,    65,    65,
     8,     8,    65,     0,    94,    92,   110,    96,   122,    -1,
    -1,    -1,   125
};
#define YYPURE 1

/* -*-C-*-  Note some compilers choke on comments on `#line' lines.  */
#line 3 "/usr/public/lib/bison.simple"

/* Skeleton output parser for bison,
   Copyright (C) 1984, 1989, 1990 Bob Corbett and Richard Stallman

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 1, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.  */


#ifndef alloca
#ifdef __GNUC__
#define alloca __builtin_alloca
#else /* not GNU C.  */
#if (!defined (__STDC__) && defined (sparc)) || defined (__sparc__)
#include <alloca.h>
#else /* not sparc */
#if defined (MSDOS) && !defined (__TURBOC__)
#include <malloc.h>
#else /* not MSDOS, or __TURBOC__ */
#if defined(_AIX)
#include <malloc.h>
 #pragma alloca
#endif /* not _AIX */
#endif /* not MSDOS, or __TURBOC__ */
#endif /* not sparc.  */
#endif /* not GNU C.  */
#endif /* alloca not defined.  */

/* This is the parser code that is written into each bison parser
  when the %semantic_parser declaration is not specified in the grammar.
  It was written by Richard Stallman by simplifying the hairy parser
  used when %semantic_parser is specified.  */

/* Note: there must be only one dollar sign in this file.
   It is replaced by the list of actions, each action
   as one case of the switch.  */

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		-2
#define YYEOF		0
#define YYACCEPT	return(0)
#define YYABORT 	return(1)
#define YYERROR		goto yyerrlab1
/* Like YYERROR except do call yyerror.
   This remains here temporarily to ease the
   transition to the new meaning of YYERROR, for GCC.
   Once GCC version 2 has supplanted version 1, this can go.  */
#define YYFAIL		goto yyerrlab
#define YYRECOVERING()  (!!yyerrstatus)
#define YYBACKUP(token, value) \
do								\
  if (yychar == YYEMPTY && yylen == 1)				\
    { yychar = (token), yylval = (value);			\
      yychar1 = YYTRANSLATE (yychar);				\
      YYPOPSTACK;						\
      goto yybackup;						\
    }								\
  else								\
    { yyerror ("syntax error: cannot back up"); YYERROR; }	\
while (0)

#define YYTERROR	1
#define YYERRCODE	256

#ifndef YYPURE
#define YYLEX		yylex()
#endif

#ifdef YYPURE
#ifdef YYLSP_NEEDED
#define YYLEX		yylex(&yylval, &yylloc)
#else
#define YYLEX		yylex(&yylval)
#endif
#endif

/* If nonreentrant, generate the variables here */

#ifndef YYPURE

int	yychar;			/*  the lookahead symbol		*/
YYSTYPE	yylval;			/*  the semantic value of the		*/
				/*  lookahead symbol			*/

#ifdef YYLSP_NEEDED
YYLTYPE yylloc;			/*  location data for the lookahead	*/
				/*  symbol				*/
#endif

int yynerrs;			/*  number of parse errors so far       */
#endif  /* not YYPURE */

#if YYDEBUG != 0
int yydebug;			/*  nonzero means print parse trace	*/
/* Since this is uninitialized, it does not stop multiple parsers
   from coexisting.  */
#endif

/*  YYINITDEPTH indicates the initial size of the parser's stacks	*/

#ifndef	YYINITDEPTH
#define YYINITDEPTH 200
#endif

/*  YYMAXDEPTH is the maximum size the stacks can grow to
    (effective only if the built-in stack extension method is used).  */

#if YYMAXDEPTH == 0
#undef YYMAXDEPTH
#endif

#ifndef YYMAXDEPTH
#define YYMAXDEPTH 10000
#endif

#if __GNUC__ > 1 || defined(yyoverflow)	/* GNU C and GNU C++ define this.  */
#define __yy_bcopy(FROM,TO,COUNT)	__builtin_memcpy(TO,FROM,COUNT)
#else				/* not GNU C or C++ */
#ifndef __cplusplus

/* This is the most reliable way to avoid incompatibilities
   in available built-in functions on various systems.  */
static void
__yy_bcopy (from, to, count)
     char *from;
     char *to;
     int count;
{
  register char *f = from;
  register char *t = to;
  register int i = count;

  while (i-- > 0)
    *t++ = *f++;
}

#else /* __cplusplus */

/* This is the most reliable way to avoid incompatibilities
   in available built-in functions on various systems.  */
static void
__yy_bcopy (char *from, char *to, int count)
{
  register char *f = from;
  register char *t = to;
  register int i = count;

  while (i-- > 0)
    *t++ = *f++;
}

#endif
#endif

#line 169 "/usr/public/lib/bison.simple"
int
yyparse()
{
  register int yystate;
  register int yyn;
  register short *yyssp;
  register YYSTYPE *yyvsp;
  int yyerrstatus;	/*  number of tokens to shift before error messages enabled */
  int yychar1;		/*  lookahead token as an internal (translated) token number */

  short	yyssa[YYINITDEPTH];	/*  the state stack			*/
  YYSTYPE yyvsa[YYINITDEPTH];	/*  the semantic value stack		*/

  short *yyss = yyssa;		/*  refer to the stacks thru separate pointers */
  YYSTYPE *yyvs = yyvsa;	/*  to allow yyoverflow to reallocate them elsewhere */

#ifdef YYLSP_NEEDED
  YYLTYPE yylsa[YYINITDEPTH];	/*  the location stack			*/
  YYLTYPE *yyls = yylsa;
  YYLTYPE *yylsp;

#define YYPOPSTACK   (yyvsp--, yysp--, yylsp--)
#else
#define YYPOPSTACK   (yyvsp--, yysp--)
#endif

  int yystacksize = YYINITDEPTH;

#ifdef YYPURE
  int yychar;
  YYSTYPE yylval;
  int yynerrs;
#ifdef YYLSP_NEEDED
  YYLTYPE yylloc;
#endif
#endif

  YYSTYPE yyval;		/*  the variable used to return		*/
				/*  semantic values from the action	*/
				/*  routines				*/

  int yylen;

#if YYDEBUG != 0
  if (yydebug)
    fprintf(stderr, "Starting parse\n");
#endif

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY;		/* Cause a token to be read.  */

  /* Initialize stack pointers.
     Waste one element of value and location stack
     so that they stay on the same level as the state stack.  */

  yyssp = yyss - 1;
  yyvsp = yyvs;
#ifdef YYLSP_NEEDED
  yylsp = yyls;
#endif

/* Push a new state, which is found in  yystate  .  */
/* In all cases, when you get here, the value and location stacks
   have just been pushed. so pushing a state here evens the stacks.  */
yynewstate:

  *++yyssp = yystate;

  if (yyssp >= yyss + yystacksize - 1)
    {
      /* Give user a chance to reallocate the stack */
      /* Use copies of these so that the &'s don't force the real ones into memory. */
      YYSTYPE *yyvs1 = yyvs;
      short *yyss1 = yyss;
#ifdef YYLSP_NEEDED
      YYLTYPE *yyls1 = yyls;
#endif

      /* Get the current used size of the three stacks, in elements.  */
      int size = yyssp - yyss + 1;

#ifdef yyoverflow
      /* Each stack pointer address is followed by the size of
	 the data in use in that stack, in bytes.  */
#ifdef YYLSP_NEEDED
      yyoverflow("parser stack overflow",
		 &yyss1, size * sizeof (*yyssp),
		 &yyvs1, size * sizeof (*yyvsp),
		 &yyls1, size * sizeof (*yylsp),
		 &yystacksize);
#else
      yyoverflow("parser stack overflow",
		 &yyss1, size * sizeof (*yyssp),
		 &yyvs1, size * sizeof (*yyvsp),
		 &yystacksize);
#endif

      yyss = yyss1; yyvs = yyvs1;
#ifdef YYLSP_NEEDED
      yyls = yyls1;
#endif
#else /* no yyoverflow */
      /* Extend the stack our own way.  */
      if (yystacksize >= YYMAXDEPTH)
	{
	  yyerror("parser stack overflow");
	  return 2;
	}
      yystacksize *= 2;
      if (yystacksize > YYMAXDEPTH)
	yystacksize = YYMAXDEPTH;
      yyss = (short *) alloca (yystacksize * sizeof (*yyssp));
      __yy_bcopy ((char *)yyss1, (char *)yyss, size * sizeof (*yyssp));
      yyvs = (YYSTYPE *) alloca (yystacksize * sizeof (*yyvsp));
      __yy_bcopy ((char *)yyvs1, (char *)yyvs, size * sizeof (*yyvsp));
#ifdef YYLSP_NEEDED
      yyls = (YYLTYPE *) alloca (yystacksize * sizeof (*yylsp));
      __yy_bcopy ((char *)yyls1, (char *)yyls, size * sizeof (*yylsp));
#endif
#endif /* no yyoverflow */

      yyssp = yyss + size - 1;
      yyvsp = yyvs + size - 1;
#ifdef YYLSP_NEEDED
      yylsp = yyls + size - 1;
#endif

#if YYDEBUG != 0
      if (yydebug)
	fprintf(stderr, "Stack size increased to %d\n", yystacksize);
#endif

      if (yyssp >= yyss + yystacksize - 1)
	YYABORT;
    }

#if YYDEBUG != 0
  if (yydebug)
    fprintf(stderr, "Entering state %d\n", yystate);
#endif

 yybackup:

/* Do appropriate processing given the current state.  */
/* Read a lookahead token if we need one and don't already have one.  */
/* yyresume: */

  /* First try to decide what to do without reference to lookahead token.  */

  yyn = yypact[yystate];
  if (yyn == YYFLAG)
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* yychar is either YYEMPTY or YYEOF
     or a valid token in external form.  */

  if (yychar == YYEMPTY)
    {
#if YYDEBUG != 0
      if (yydebug)
	fprintf(stderr, "Reading a token: ");
#endif
      yychar = YYLEX;
    }

  /* Convert token to internal form (in yychar1) for indexing tables with */

  if (yychar <= 0)		/* This means end of input. */
    {
      yychar1 = 0;
      yychar = YYEOF;		/* Don't call YYLEX any more */

#if YYDEBUG != 0
      if (yydebug)
	fprintf(stderr, "Now at end of input.\n");
#endif
    }
  else
    {
      yychar1 = YYTRANSLATE(yychar);

#if YYDEBUG != 0
      if (yydebug)
	{
	  fprintf (stderr, "Next token is %d (%s", yychar, yytname[yychar1]);
	  /* Give the individual parser a way to print the precise meaning
	     of a token, for further debugging info.  */
#ifdef YYPRINT
	  YYPRINT (stderr, yychar, yylval);
#endif
	  fprintf (stderr, ")\n");
	}
#endif
    }

  yyn += yychar1;
  if (yyn < 0 || yyn > YYLAST || yycheck[yyn] != yychar1)
    goto yydefault;

  yyn = yytable[yyn];

  /* yyn is what to do for this token type in this state.
     Negative => reduce, -yyn is rule number.
     Positive => shift, yyn is new state.
       New state is final state => don't bother to shift,
       just return success.
     0, or most negative number => error.  */

  if (yyn < 0)
    {
      if (yyn == YYFLAG)
	goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }
  else if (yyn == 0)
    goto yyerrlab;

  if (yyn == YYFINAL)
    YYACCEPT;

  /* Shift the lookahead token.  */

#if YYDEBUG != 0
  if (yydebug)
    fprintf(stderr, "Shifting token %d (%s), ", yychar, yytname[yychar1]);
#endif

  /* Discard the token being shifted unless it is eof.  */
  if (yychar != YYEOF)
    yychar = YYEMPTY;

  *++yyvsp = yylval;
#ifdef YYLSP_NEEDED
  *++yylsp = yylloc;
#endif

  /* count tokens shifted since error; after three, turn off error status.  */
  if (yyerrstatus) yyerrstatus--;

  yystate = yyn;
  goto yynewstate;

/* Do the default action for the current state.  */
yydefault:

  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;

/* Do a reduction.  yyn is the number of a rule to reduce with.  */
yyreduce:
  yylen = yyr2[yyn];
  yyval = yyvsp[1-yylen]; /* implement default value of the action */

#if YYDEBUG != 0
  if (yydebug)
    {
      int i;

      fprintf (stderr, "Reducing via rule %d (line %d), ",
	       yyn, yyrline[yyn]);

      /* Print the symboles being reduced, and their result.  */
      for (i = yyprhs[yyn]; yyrhs[i] > 0; i++)
	fprintf (stderr, "%s ", yytname[yyrhs[i]]);
      fprintf (stderr, " -> %s\n", yytname[yyr1[yyn]]);
    }
#endif


  switch (yyn) {

case 1:
#line 151 "parse.y"
{
		    yylineno = 1;
		;
    break;}
case 4:
#line 158 "parse.y"
{
		    int	    lName = strlen(yyvsp[-3].string);
		    int	    lExt = strlen(yyvsp[-1].string);
		    char    *cp;
		    char    *cp2;
		    int	    i;

		    nameseen = 1;

		    /*
		     * Adjust name and extension to be within bounds
		     */
		    if (lName > GEODE_NAME_SIZE) {
			lName = GEODE_NAME_SIZE;
		    }
		    if (lExt > GEODE_NAME_EXT_SIZE) {
			lExt = GEODE_NAME_EXT_SIZE;
		    }
		    /*
		     * Copy the name into the geodeName field, space-padding
		     * it on the right as necessary to fill up the field.
		     */
		    cp = yyvsp[-3].string, cp2 = GH(geodeName);
		    for (i = 0; i < lName; i++) {
			*cp2++ = *cp++;
		    }
		    while (i < GEODE_NAME_SIZE) {
			*cp2++ = ' ';
			i++;
		    }
		    /*
		     * The extension is a little trickier, as we have to
		     * place an E at the front of the extension if the
		     * geode is an error-checking version. This reduces the
		     * size of the extension the user may give, but only
		     * if s/he gave the full four characters.
		     */
		    cp = yyvsp[-1].string, cp2 = GH(geodeNameExt);
		    i = 0;
		    if (isEC) {
			*cp2++ = 'E';
			if (lExt < GEODE_NAME_EXT_SIZE) {
			    /*
			     * It'll all fit anyway -- up the length of
			     * the extension to account for the E
			     */
			    lExt++;
			}
			i++;
		    }
		    while (i < lExt) {
			*cp2++ = *cp++;
			i++;
		    }
		    /*
		     * Space-pad the extension too
		     */
		    while (i < GEODE_NAME_EXT_SIZE) {
			*cp2++ = ' ';
			i++;
		    }
		    free(yyvsp[-3].string);
		    free(yyvsp[-1].string);
		;
    break;}
case 5:
#line 223 "parse.y"
{
		    int	    numChars = strlen(yyvsp[0].string);
		    char    *cp;
		    char    *cp2;
		    int	    i;

		    /*
		     * All four token chars must be specified
		     */
		    if (numChars != TOKEN_CHARS_SIZE) {
			Notify(NOTIFY_ERROR,
			       FILE_AND_LINE "token too %s",
			       paramFile, yylineno,
			       (numChars < TOKEN_CHARS_SIZE)? "short" : "long");
			break;
		    }
		    /*
		     * Copy the token chars into the geodeToken fields.
		     */
		    cp = yyvsp[0].string;
		    cp2 = GH(geodeToken.chars);
		    for (i = 0; i < TOKEN_CHARS_SIZE; i++) {
			*cp2++ = *cp++;
		    }
		    cp = yyvsp[0].string;
		    if (geosRelease >= 2) {
			cp2 = geoHeader.v2x.execHeader.geosFileHeader.token.chars;
		    } else {
			cp2 = geoHeader.v1x.execHeader.geosFileHeader.core.token.chars;
		    }
		    for (i = 0; i < TOKEN_CHARS_SIZE; i++) {
			*cp2++ = *cp++;
		    }
		;
    break;}
case 6:
#line 258 "parse.y"
{
		    /*
		     * manufacturer's id must be a word
		     */
		    if ((yyvsp[-1].number < 0) || (yyvsp[-1].number > 65535)) {
			yyerror("manufacturer's id must be in range 0 - 65535");
			break;
		    }
		    /*
		     * Copy the manuf. id of the token into the
		     * geodeToken field.
		     */
		    GH_ASSIGN(geodeToken.manufID, yyvsp[-1].number);
		    if (geosRelease >= 2) {
			geoHeader.v2x.execHeader.geosFileHeader.token.manufID = yyvsp[-1].number;
		    } else {
			geoHeader.v1x.execHeader.geosFileHeader.core.token.manufID = yyvsp[-1].number;
		    }
		;
    break;}
case 7:
#line 278 "parse.y"
{
		    char    *cp;
		    char    *cp2;
		    int	    lName = strlen(yyvsp[0].string);
		    int	    i;

		    /*
		     * Copy the longname into geodeHeader.
		     */
		    cp = yyvsp[0].string;
		    if (geosRelease >= 2) {
			cp2 = geoHeader.v2x.execHeader.geosFileHeader.longName;
		    } else {
			cp2 = geoHeader.v1x.execHeader.geosFileHeader.core.longName;
		    }
		    if (lName > GFH_LONGNAME_SIZE) {
			yyerror("longname TOO long (32 chars max)");
			break;
		    }
		    if (isEC && (lName+3 > GFH_LONGNAME_SIZE)) {
		        Notify(NOTIFY_WARNING,
			       FILE_AND_LINE "EC longname TOO long, losing end character(s)",
			       paramFile, yylineno);
		    }
		    /*
		     * if error-checking version, tack on "EC " at the front
		     */
		    if (!dbcsRelease) {
		    	if (isEC) {
			    *cp2++ = 'E';
			    *cp2++ = 'C';
			    *cp2++ = ' ';
			    i = 3;
		    	} else {
			    i = 0;
		    	}
		    	while (i < GFH_LONGNAME_SIZE) {
			    if (*cp) {
			    	*cp2++ = *cp++;
			    } else {
			    	*cp2++ = 0;
			    }
			    i++;
		    	}
		    	*cp2++ = 0;
		    } else {
			if (isEC) {
			    i = VMCopyToDBCSString(cp2, "EC ", 6);
			} else {
			    i = 0;
			}
			VMCopyToDBCSString(cp2+i, cp, GFH_LONGNAME_SIZE-i);
		    }

		;
    break;}
case 8:
#line 334 "parse.y"
{
		    char    *cp;
		    char    *cp2;
		    int	    lNotes = strlen(yyvsp[0].string);
		    int	    i;

		    /*
		     * Copy the user notes into geodeHeader.
		     */
		    cp = yyvsp[0].string;
		    cp2 = GH(execHeader.geosFileHeader.userNotes);
		    if (lNotes > GFH_USER_NOTES_SIZE) {
			yyerror("user notes too long");
		    	break;
		    }
		    i = 0;
		    while (i < lNotes) {
			*cp2++ = *cp++;
			i++;
		    }
		;
    break;}
case 9:
#line 356 "parse.y"
{
		    if (!(yyvsp[-1].number & GA_SINGLE_LAUNCH)) {
			yyvsp[-1].number |= GA_MULTI_LAUNCHABLE;
		    }
		    GH_ASSIGN(geodeAttr, yyvsp[-1].number);
   		    GH_ASSIGN(execHeader.attributes, yyvsp[-1].number);
		;
    break;}
case 11:
#line 365 "parse.y"
{ yyval.number = yyvsp[-1].number | yyvsp[0].number; ;
    break;}
case 12:
#line 366 "parse.y"
{ yyval.number = yyvsp[-2].number | yyvsp[0].number; ;
    break;}
case 13:
#line 368 "parse.y"
{ yyval.number = GA_PROCESS; ;
    break;}
case 14:
#line 369 "parse.y"
{ yyval.number = GA_DRIVER; ;
    break;}
case 15:
#line 370 "parse.y"
{ yyval.number = GA_LIBRARY; ;
    break;}
case 16:
#line 371 "parse.y"
{ yyval.number = GA_SINGLE_LAUNCH; ;
    break;}
case 17:
#line 372 "parse.y"
{ yyval.number = GA_APPLICATION; ;
    break;}
case 18:
#line 373 "parse.y"
{ yyval.number = GA_USES_COPROC; ;
    break;}
case 19:
#line 374 "parse.y"
{ yyval.number = GA_REQUIRES_COPROC; ;
    break;}
case 20:
#line 375 "parse.y"
{ yyval.number = GA_SYSTEM; ;
    break;}
case 21:
#line 376 "parse.y"
{ yyval.number = GA_HAS_GENERAL_CONSUMER_MODE; ;
    break;}
case 22:
#line 377 "parse.y"
{ yyval.number = GA_ENTRY_POINTS_IN_C; ;
    break;}
case 23:
#line 378 "parse.y"
{ discardableDgroup = 1; yyval.number = 0;;
    break;}
case 24:
#line 381 "parse.y"
{
		    if (!loadingLibs) {
			Parse_FindSym(yyvsp[-1].string, OSYM_CHUNK, "chunk",
				      GHA(execHeader.appObjResource),
				      GHA(execHeader.appObjChunkHandle));
		    }
		    free(yyvsp[-1].string);
		;
    break;}
case 25:
#line 390 "parse.y"
{
		    if (loadingLibs) {
			Library_Link(yyvsp[-1].string, LLT_ON_STARTUP, GA_DRIVER);
		    }
		    free(yyvsp[-1].string);
		;
    break;}
case 26:
#line 397 "parse.y"
{
		;
    break;}
case 27:
#line 400 "parse.y"
{
		;
    break;}
case 28:
#line 403 "parse.y"
{
		;
    break;}
case 29:
#line 406 "parse.y"
{
		    HandleIFDEF(TRUE, yyvsp[0].string);
		;
    break;}
case 30:
#line 410 "parse.y"
{
		    HandleIFDEF(FALSE, yyvsp[0].string);
		;
    break;}
case 31:
#line 414 "parse.y"
{
		    if (iflevel == -1) {
			yyerror("IF-less ELSE");
			yynerrs++;
		    } else if (ifStack[iflevel] == -1) {
			yyerror("Already had an ELSE for this level");
			yynerrs++;
		    } else if (ifStack[iflevel]) {
			/*
			 * Remember ELSE and go to the endif
			 */
			ifStack[iflevel] = -1;
			ScanToEndif(FALSE);
		    } else {
			/*
			 * IF was false, so continue parsing, but remember
			 * we had an ELSE already.
			 */
			ifStack[iflevel] = -1;
		    }
		;
    break;}
case 32:
#line 436 "parse.y"
{
		    if (iflevel == -1) {
			yyerror("IF-less ENDIF");
			yynerrs++;
		    } else {
			iflevel -= 1;
		    }
		;
    break;}
case 33:
#line 445 "parse.y"
{
		    if (loadingLibs)
		    {
		        switch (Library_Link(yyvsp[-2].string, yyvsp[-1].loadType, GA_LIBRARY))
 		        {
		            case LLV_SUCCESS: break;
		            case LLV_FAILURE:
 		                  Notify(NOTIFY_WARNING,
			                 "library %s: missing ldf file.", yyvsp[-2].string);
		                  break;
		            case LLV_ALREADY_LINKED:
 		                  Notify(NOTIFY_WARNING,
			                 "library %s: tried to link twice, perhaps the library's ldf file is out of date.", yyvsp[-2].string);
		                  break;

		        }
		    }
		    free(yyvsp[-2].string);
		;
    break;}
case 36:
#line 469 "parse.y"
{
		    if (loadingLibs) {
			Library_ReadPlatformFile(yyvsp[0].string);
		    }
		    free(yyvsp[0].string);
		;
    break;}
case 39:
#line 480 "parse.y"
{
		    if (loadingLibs) {
			Library_ReadShipFile(yyvsp[0].string);
		    }
		    free(yyvsp[0].string);
		;
    break;}
case 42:
#line 491 "parse.y"
{
		    if (loadingLibs) {
			Library_ExemptLibrary(yyvsp[0].string);
		    }
		    free(yyvsp[0].string);
		;
    break;}
case 43:
#line 498 "parse.y"
{ yyval.loadType = LLT_ON_STARTUP; ;
    break;}
case 44:
#line 499 "parse.y"
{ yyval.loadType = LLT_DYNAMIC; ;
    break;}
case 45:
#line 500 "parse.y"
{ yyval.loadType = LLT_DYNAMIC_FIXED; ;
    break;}
case 46:
#line 503 "parse.y"
{
		    if (!loadingLibs) {
			Library_Skip(yyvsp[-1].number);
		    }
		;
    break;}
case 47:
#line 509 "parse.y"
{
		    if (!loadingLibs) {
			Library_SkipUntilNumber(yyvsp[-1].number);
		    }
		;
    break;}
case 48:
#line 515 "parse.y"
{
		    if (!loadingLibs) {
			Library_SkipUntilConstant(yyvsp[-1].string);
		    }
		;
    break;}
case 49:
#line 521 "parse.y"
{
		    if (!nameseen && !errorgiven) {
			yyerror("NAME must be given before export");
			errorgiven=1;
		    }
		;
    break;}
case 51:
#line 530 "parse.y"
{
		    if (nameseen && !loadingLibs) {
			Library_ExportAs(yyvsp[0].string, yyvsp[0].string, TRUE);
		    }
		;
    break;}
case 52:
#line 536 "parse.y"
{
		    /*
		     * Similar, but the symbol placed in the interface
		     * definition file has the name $3.
		     */
		    if (nameseen && !loadingLibs) {
			Library_ExportAs(yyvsp[-2].string, yyvsp[0].string, TRUE);
		    }
		;
    break;}
case 53:
#line 546 "parse.y"
{
		    if (nameseen && !loadingLibs) {
			Library_ExportAs(yyvsp[-1].string, yyvsp[-1].string, FALSE);
		    }
		;
    break;}
case 56:
#line 556 "parse.y"
{
		    if (!loadingLibs) {
			Parse_FindSym(yyvsp[-1].string, OSYM_CLASS, "class",
				      GHA(execHeader.classResource),
				      GHA(execHeader.classOffset));
		    }
		    free(yyvsp[-1].string);
		;
    break;}
case 57:
#line 565 "parse.y"
{
		    stackSize = yyvsp[-1].number;
		    stackSpecified = TRUE;
		;
    break;}
case 58:
#line 570 "parse.y"
{
		    if (geosRelease >= 2) {
			geoHeader.v2x.execHeader.heapSpace = yyvsp[-1].number;
		    }
		;
    break;}
case 59:
#line 576 "parse.y"
{
                    if (geosRelease >= 2) {
			geoHeader.v2x.execHeader.heapSpace = (yyvsp[-1].number/16);
			}
		;
    break;}
case 60:
#line 582 "parse.y"
{ yyval.bool = TRUE; ;
    break;}
case 61:
#line 583 "parse.y"
{ yyval.bool = FALSE; ;
    break;}
case 62:
#line 586 "parse.y"
{
		    resFlags = RESF_STANDARD & ~RESF_DISCARDABLE;
		;
    break;}
case 63:
#line 590 "parse.y"
{
		    ID	    id;

		    if (!loadingLibs) {
			id = ST_LookupNoLen(symbols, strings, yyvsp[-3].string);
		        if (id == NullID)
		        {
		            char *cp, *cp2;
			    char c='\0';
		            /* since goc puts out _E and _G and _ECONST_DATA
		             * and _GCONST_DATA, I want to accept either of
                             * these (also works for file names with
			     * other underscores in them)
 		             */
                            cp = (char *)strrchr(yyvsp[-3].string, '_');
			    if ((cp != NULL) && !strcmp(cp, "_DATA"))
			    {
				/* get to next to last '_' if we have
				 * _DATA at the end
				 */
				cp[0] = 'A';
				cp2 = (char *)strrchr(yyvsp[-3].string, '_');
				cp[0] = '_';
				cp = cp2;
			    }
			    if ((cp != NULL) && !strncmp(cp, "_G", 2))
			    {
				c = 'E';
			    }
			    if ((cp != NULL) && !strncmp(cp, "_E", 2))
			    {
				c = 'G';
			    }
			    if (c)
			    {
				/* ok we were on fact looking for one of these
				 * ick code segments from C so try the other
				 * one
				 */
				cp[1] = c;
				id = ST_LookupNoLen(symbols, strings, yyvsp[-3].string);
			    }
			}

			if (id == NullID) {
			    if (yyvsp[-4].bool) {
				Notify(NOTIFY_ERROR,
				       FILE_AND_LINE "resource %s not defined",
				       paramFile, yylineno, yyvsp[-3].string);
			    }
			} else {
			    /*
			     * Can't use Seg_Find here b/c C segments have
			     * non-NULL class names...
			     */
			    SegDesc *seg = NULL;
			    int	    i, j;

			    for (i = 0; i < seg_NumSegs; i++)
                            {
				if (seg_Segments[i]->name == id)
		                {
				    seg = seg_Segments[i];

                                    for (j = 2; j < seg_NumSegs; j++)
		                    {
		                        if (seg_Info[j].segID == NullID)
                                        {
                                            break;
                                        }
                                    }
		                    seg_Info[j].segID = id;
				    break;
				}
			    }
			    for (i = 0; seg == NULL && i < seg_NumSubSegs; i++)
			    {
				if (seg_SubSegs[i]->name == id) {
				    seg = seg_SubSegs[i];
				    break;
				}
			    }

			    if (seg == NULL) {
				if (yyvsp[-4].bool) {
				    Notify(NOTIFY_ERROR,
					   FILE_AND_LINE "resource %s not defined",
					   paramFile, yylineno, yyvsp[-3].string);
				}
			    } else {
				if (seg->hasProfileMark) {
				    seg->flags = resFlags & ~RESF_DISCARDABLE;
				} else {
				    seg->flags = resFlags;
				}
			    }
			}
		    }
		    free(yyvsp[-3].string);
		;
    break;}
case 64:
#line 691 "parse.y"
{
		    noSort = TRUE;
		;
    break;}
case 65:
#line 695 "parse.y"
{
		    doingAlias = FALSE;
		;
    break;}
case 71:
#line 716 "parse.y"
{
		    resFlags|= RESF_READ_ONLY;
		    /*
		     * If the resource is fixed, do not make it discardable...
		     */
		    if ( !(resFlags & RESF_FIXED) ) {
			resFlags|= RESF_DISCARDABLE;
		    }
		;
    break;}
case 72:
#line 726 "parse.y"
{
		    if (!(resFlags & RESF_FIXED)) {
			resFlags |= RESF_DISCARDABLE;
		    }
		;
    break;}
case 73:
#line 732 "parse.y"
{
		    resFlags &= ~RESF_SWAPABLE;
		    resFlags |= RESF_DISCARDABLE;
		;
    break;}
case 74:
#line 737 "parse.y"
{
		    resFlags &= ~RESF_DISCARDABLE;
		    resFlags |= RESF_SWAPABLE;
		;
    break;}
case 75:
#line 742 "parse.y"
{
		    resFlags |= RESF_SWAPABLE;
		;
    break;}
case 76:
#line 746 "parse.y"
{
		    resFlags &= ~RESF_SWAPABLE;
		;
    break;}
case 77:
#line 750 "parse.y"
{
		    resFlags &= ~RESF_DISCARDABLE;
		;
    break;}
case 78:
#line 753 "parse.y"
{ resFlags &= ~RESF_DISCARDED; ;
    break;}
case 79:
#line 755 "parse.y"
{
		    resFlags |= RESF_FIXED;
		    resFlags &= ~(RESF_SWAPABLE|RESF_DISCARDABLE|
				  RESF_DISCARDED|RESF_LMEM);
		;
    break;}
case 80:
#line 761 "parse.y"
{
		    resFlags |= RESF_CONFORMING;
		;
    break;}
case 81:
#line 764 "parse.y"
{ resFlags |= RESF_SHARED; ;
    break;}
case 82:
#line 765 "parse.y"
{ resFlags |= RESF_CODE; ;
    break;}
case 83:
#line 767 "parse.y"
{
		    resFlags &= ~(RESF_CODE|RESF_DISCARDABLE);
		    if ((resFlags&(RESF_READ_ONLY|RESF_FIXED))==RESF_READ_ONLY){
			/*
			 * Read-only data can actually still be discarded.
			 */
			resFlags |= RESF_DISCARDABLE;
		    }
		;
    break;}
case 84:
#line 777 "parse.y"
{
		    resFlags |= RESF_LMEM;
		    resFlags &= ~RESF_CODE;
		;
    break;}
case 85:
#line 782 "parse.y"
{
		    resFlags |= RESF_OBJECT|RESF_UI|RESF_LMEM|RESF_SHARED;
		    resFlags &= ~(RESF_CODE|RESF_DISCARDABLE);
		    if ((resFlags&(RESF_READ_ONLY|RESF_FIXED))==RESF_READ_ONLY){
			/*
			 * Read-only data can actually still be discarded.
			 */
			resFlags |= RESF_DISCARDABLE;
		    }
		;
    break;}
case 86:
#line 793 "parse.y"
{
		    resFlags |= RESF_OBJECT|RESF_LMEM;
		    resFlags &= ~(RESF_CODE|RESF_UI|RESF_DISCARDABLE);
		    if ((resFlags&(RESF_READ_ONLY|RESF_FIXED))==RESF_READ_ONLY){
			/*
			 * Read-only data can actually still be discarded.
			 */
			resFlags |= RESF_DISCARDABLE;
		    }
		;
    break;}
case 87:
#line 805 "parse.y"
{
		    if (!loadingLibs) {
			Parse_FindSym(yyvsp[0].string, OSYM_PROC, "procedure",
				      GHA(libEntryResource),
				      GHA(libEntryOff));
		    }
		    free(yyvsp[0].string);
		;
    break;}
case 88:
#line 814 "parse.y"
{
		    if (loadingLibs) {
			Seg_AddAlias(&curAlias);
		    }
		;
    break;}
case 89:
#line 824 "parse.y"
{
		    if (loadingLibs) {
			curAlias.name = ST_EnterNoLen(symbols, strings, yyvsp[0].string);
			curAlias.class = NullID;
			curAlias.aliasMask = 0;
		    }
		    free(yyvsp[0].string);
		    doingAlias = TRUE;
		;
    break;}
case 90:
#line 834 "parse.y"
{
		    if (loadingLibs) {
			curAlias.name = ST_EnterNoLen(symbols, strings, yyvsp[-1].string);
			curAlias.class = ST_EnterNoLen(symbols, strings, yyvsp[0].string);
			curAlias.aliasMask = 0;
		    }
		    free(yyvsp[-1].string);
		    free(yyvsp[0].string);
		    doingAlias = TRUE;
		;
    break;}
case 91:
#line 849 "parse.y"
{
		    if (loadingLibs) {
			curAlias.aliasMask |= SA_NEWNAME;
			curAlias.newName = ST_EnterNoLen(symbols, strings, yyvsp[-1].string);
		    }
		    free(yyvsp[-1].string);
		;
    break;}
case 93:
#line 859 "parse.y"
{
		    /* Do nothing */
		;
    break;}
case 94:
#line 863 "parse.y"
{
		    curAlias.newAlign = yyvsp[0].number;
		    curAlias.aliasMask |= SA_NEWALIGN;
		;
    break;}
case 95:
#line 868 "parse.y"
{
		    curAlias.newCombine = yyvsp[0].number;
		    curAlias.aliasMask |= SA_NEWCOMBINE;
		;
    break;}
case 96:
#line 873 "parse.y"
{
		    if (loadingLibs) {
			curAlias.newClass = ST_EnterNoLen(symbols, strings, yyvsp[0].string);
			curAlias.aliasMask |= SA_NEWCLASS;
		    }
		    free(yyvsp[0].string);
		;
    break;}
case 97:
#line 881 "parse.y"
{
		    curAlias.aliasMask |= SA_NEWALIGN|SA_NEWCOMBINE;
		    curAlias.newAlign = yyvsp[-1].number;
		    curAlias.newCombine = yyvsp[0].number;
		;
    break;}
case 98:
#line 887 "parse.y"
{
		    if (loadingLibs) {
			curAlias.aliasMask |= SA_NEWALIGN|SA_NEWCLASS;
			curAlias.newAlign = yyvsp[-1].number;
			curAlias.newClass = ST_EnterNoLen(symbols, strings, yyvsp[0].string);
		    }
		    free(yyvsp[0].string);
		;
    break;}
case 99:
#line 896 "parse.y"
{
		    if (loadingLibs) {
			curAlias.aliasMask |= SA_NEWCOMBINE|SA_NEWCLASS;
			curAlias.newCombine = yyvsp[-1].number;
			curAlias.newClass = ST_EnterNoLen(symbols, strings, yyvsp[0].string);
		    }
		    free(yyvsp[0].string);
		;
    break;}
case 100:
#line 905 "parse.y"
{
		    if (loadingLibs) {
			curAlias.aliasMask |= SA_NEWALIGN|SA_NEWCOMBINE|SA_NEWCLASS;
			curAlias.newAlign = yyvsp[-2].number;
			curAlias.newCombine = yyvsp[-1].number;
			curAlias.newClass = ST_EnterNoLen(symbols, strings, yyvsp[0].string);
		    }
		    free(yyvsp[0].string);
		;
    break;}
case 101:
#line 917 "parse.y"
{
		    if (!nameseen) {
			if (!errorgiven) {
			    yyerror("NAME must be given before publish");
			    errorgiven=1;
			}
		    } else if (!loadingLibs) {
			Library_ExportAs(yyvsp[0].string, yyvsp[0].string, TRUE);
			Library_MarkPublished(yyvsp[0].string);
		    }
		;
    break;}
case 102:
#line 931 "parse.y"
{
		    if (!loadingLibs) {
			Library_IncMinor();
		    }
		;
    break;}
case 103:
#line 937 "parse.y"
{
		;
    break;}
case 106:
#line 946 "parse.y"
{
		    if (!nameseen) {
			if (!errorgiven) {
			    yyerror("NAME must be given before export");
			    errorgiven=1;
			}
		    } else if (!loadingLibs) {

			/*
			 * I can't figure out how to get the Library_IncMinor
			 * to happen before all the Library_ProtoMinor's, so
			 * I'm simply doing an incminor for each protominor
			 * token found. It'd be "nicer" to have a single
			 * Library_IncMinor above in the line that reads:
			 * "| INCMINOR protominorList". Whatever.
			 */
			Library_IncMinor();
			Library_ProtoMinor(yyvsp[0].string);
		    }
		;
    break;}
}
   /* the action file gets copied in in place of this dollarsign */
#line 440 "/usr/public/lib/bison.simple"

  yyvsp -= yylen;
  yyssp -= yylen;
#ifdef YYLSP_NEEDED
  yylsp -= yylen;
#endif

#if YYDEBUG != 0
  if (yydebug)
    {
      short *ssp1 = yyss - 1;
      fprintf (stderr, "state stack now");
      while (ssp1 != yyssp)
	fprintf (stderr, " %d", *++ssp1);
      fprintf (stderr, "\n");
    }
#endif

  *++yyvsp = yyval;

#ifdef YYLSP_NEEDED
  yylsp++;
  if (yylen == 0)
    {
      yylsp->first_line = yylloc.first_line;
      yylsp->first_column = yylloc.first_column;
      yylsp->last_line = (yylsp-1)->last_line;
      yylsp->last_column = (yylsp-1)->last_column;
      yylsp->text = 0;
    }
  else
    {
      yylsp->last_line = (yylsp+yylen-1)->last_line;
      yylsp->last_column = (yylsp+yylen-1)->last_column;
    }
#endif

  /* Now "shift" the result of the reduction.
     Determine what state that goes to,
     based on the state we popped back to
     and the rule number reduced by.  */

  yyn = yyr1[yyn];

  yystate = yypgoto[yyn - YYNTBASE] + *yyssp;
  if (yystate >= 0 && yystate <= YYLAST && yycheck[yystate] == *yyssp)
    yystate = yytable[yystate];
  else
    yystate = yydefgoto[yyn - YYNTBASE];

  goto yynewstate;

yyerrlab:   /* here on detecting error */

  if (! yyerrstatus)
    /* If not already recovering from an error, report this error.  */
    {
      ++yynerrs;

#ifdef YYERROR_VERBOSE
      yyn = yypact[yystate];

      if (yyn > YYFLAG && yyn < YYLAST)
	{
	  int size = 0;
	  char *msg;
	  int x, count;

	  count = 0;
	  for (x = 0; x < (sizeof(yytname) / sizeof(char *)); x++)
	    if (yycheck[x + yyn] == x && x != YYTERROR)
	      size += strlen(yytname[x]) + 15, count++;
	  msg = (char *) malloc(size + 15);
	  strcpy(msg, "parse error");

	  if (count < 5)
	    {
	      count = 0;
	      for (x = 0; x < (sizeof(yytname) / sizeof(char *)); x++)
		if (yycheck[x + yyn] == x && x != YYTERROR)
		  {
		    strcat(msg, count == 0 ? ", expecting " : " or ");
		    strcat(msg, yytname[x]);
		    count++;
		  }
	    }
	  yyerror(msg);
	  free(msg);
	}
      else
#endif /* YYERROR_VERBOSE */
	yyerror("parse error");
    }

yyerrlab1:   /* here on error raised explicitly by an action */

  if (yyerrstatus == 3)
    {
      /* if just tried and failed to reuse lookahead token after an error, discard it.  */

      /* return failure if at end of input */
      if (yychar == YYEOF)
	YYABORT;

#if YYDEBUG != 0
      if (yydebug)
	fprintf(stderr, "Discarding token %d (%s).\n", yychar, yytname[yychar1]);
#endif

      yychar = YYEMPTY;
    }

  /* Else will try to reuse lookahead token
     after shifting the error token.  */

  yyerrstatus = 3;		/* Each real token shifted decrements this */

  goto yyerrhandle;

yyerrdefault:  /* current state does not do anything special for the error token. */

#if 0
  /* This is wrong; only states that explicitly want error tokens
     should shift them.  */
  yyn = yydefact[yystate];  /* If its default is to accept any token, ok.  Otherwise pop it.*/
  if (yyn) goto yydefault;
#endif

yyerrpop:   /* pop the current state because it cannot handle the error token */

  if (yyssp == yyss) YYABORT;
  yyvsp--;
  yystate = *--yyssp;
#ifdef YYLSP_NEEDED
  yylsp--;
#endif

#if YYDEBUG != 0
  if (yydebug)
    {
      short *ssp1 = yyss - 1;
      fprintf (stderr, "Error: state stack now");
      while (ssp1 != yyssp)
	fprintf (stderr, " %d", *++ssp1);
      fprintf (stderr, "\n");
    }
#endif

yyerrhandle:

  yyn = yypact[yystate];
  if (yyn == YYFLAG)
    goto yyerrdefault;

  yyn += YYTERROR;
  if (yyn < 0 || yyn > YYLAST || yycheck[yyn] != YYTERROR)
    goto yyerrdefault;

  yyn = yytable[yyn];
  if (yyn < 0)
    {
      if (yyn == YYFLAG)
	goto yyerrpop;
      yyn = -yyn;
      goto yyreduce;
    }
  else if (yyn == 0)
    goto yyerrpop;

  if (yyn == YYFINAL)
    YYACCEPT;

#if YYDEBUG != 0
  if (yydebug)
    fprintf(stderr, "Shifting error token, ");
#endif

  *++yyvsp = yylval;
#ifdef YYLSP_NEEDED
  *++yylsp = yylloc;
#endif

  yystate = yyn;
  goto yynewstate;
}
#line 968 "parse.y"



/***********************************************************************
 *				ParseStackOverflow
 ***********************************************************************
 * SYNOPSIS:	  Enlarge the parser's internal stacks.
 * CALLED BY:	  yyparse()
 * RETURN:	  Nothing. *maxDepth left unaltered if we don't want to
 *		  allow the increase. yyerror is called with msg if so.
 * SIDE EFFECTS:
 *
 * STRATEGY:	  This implementation relies on the "errcheck" rule
 *		  freeing stacks up, if necessary. Sadly, there's no
 *		  opportunity to do this, so it be a core leak...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/31/88		Initial Revision
 *
 ***********************************************************************/
static void
ParseStackOverflow(char		*msg,	    /* Message if we decide not to */
		   short	**state,    /* Current state stack */
		   size_t	stateSize,  /* Current state stack size */
		   void	    	**vals,	    /* Current value stack */
		   size_t	valsSize,   /* Current value stack size */
		   int		*maxDepth)  /* Current maximum stack depth of
					     * all stacks */
{
    *maxDepth *= 2;

    if (malloc_size((malloc_t)*state) != 0) {
	/*
	 * we've been called before. Just use realloc()
	 */
	*state = (short *)realloc((char *)*state, stateSize * 2);
	*vals = (YYSTYPE *)realloc((char *)*vals, valsSize * 2);
    } else {
	short	*newstate;
	YYSTYPE	*newvals;

	newstate = (short *)malloc(stateSize * 2);
	newvals = (YYSTYPE *)malloc(valsSize * 2);

	bcopy(*state, newstate, stateSize);
	bcopy(*vals, newvals, valsSize);

	*state = newstate;
	*vals = newvals;
    }
}

void
yyerror(char *s)
{
    Notify(NOTIFY_ERROR, FILE_AND_LINE "%s", paramFile, yylineno, s);
}

/******************************************************************************
 *
 *			   LEXICAL ANALYZER
 *
 *****************************************************************************/
#include    "tokens.h"
typedef struct _Token	Token;

#undef MIN_WORD_LENGTH
#undef MAX_WORD_LENGTH
#undef MIN_HASH_VALUE
#undef MAX_HASH_VALUE

#include    "segattrs.h"
typedef struct _SegAttr	SegAttr;

#define F   1	/* firstid */
#define O   2	/* otherid */
#define B   3	/* both */
#define N   0	/* none */
static const unsigned char  cbits[] = {
    N,	    	    	    	    	/* EOF */
    N,	N,  N,	N,  N,	N,  N,	N,  	/*  0 -  7 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/*  8 - 15 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 16 - 23 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 24 - 31 */
    N,	N,  N, 	N,  B,	N,  N,	N,  	/* sp ! " # $ % & ' */
    N,	N,  N,	N,  N,	O,  N,	N,  	/* (  ) * + , - . / */
    O,	O,  O,	O,  O,	O,  O,	O,  	/* 0  1 2 3 4 5 6 7 */
    O,	O,  N,	N,  N,	N,  N,	B,  	/* 8  9 : ; < = > ? */
    B,	B,  B,	B,  B,	B,  B,	B,  	/* @  A B C D E F G */
    B,	B,  B,	B,  B,	B,  B,	B,  	/* H  I J K L M N O */
    B,	B,  B,	B,  B,	B,  B,	B,  	/* P  Q R S T U V W */
    B,	B,  B,	N,  N, 	N,  N,	B,  	/* X  Y Z [ \ ] ^ _ */
    N,	B,  B,	B,  B,	B,  B,	B,  	/* `  a b c d e f g */
    B,	B,  B,	B,  B,	B,  B,	B,  	/* h  i j k l m n o */
    B,	B,  B,	B,  B,	B,  B,	B,  	/* p  q r s t u v w */
    B,	B,  B,	N,  N, 	N,  N,	N,  	/* x  y z { | } ~ del */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 128 - 135 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 136 - 143 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 144 - 151 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 152 - 159 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 160 - 167 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 168 - 175 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 176 - 183 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 184 - 191 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 192 - 199 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 200 - 207 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 208 - 215 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 216 - 223 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 224 - 231 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 232 - 239 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 240 - 247 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 248 - 255 */
};

#define isfirstid(c)	((cbits+1)[c]&F)
#define isotherid(c)	((cbits+1)[c]&O)

static FILE *yyin;

#ifdef YYDEBUG
#define DBPRINTF(args)	if (yydebug) fprintf args
#else
#define DBPRINTF(args)
#endif



/*
 * some stuff for longname support
 */

#define input() getc(yyin)
#define unput(c) ungetc(c, yyin)


/***********************************************************************
 *				yyreadstring
 ***********************************************************************
 * SYNOPSIS:	    Read a string literal
 * CALLED BY:	    yylex (<, {, ' and " cases)
 * RETURN:	    Token to return
 * SIDE EFFECTS:    yylval->string is set to the string read, dynamically
 *	    	    allocated. findOpcode removed from the list of procedures
 *	    	    tried.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/31/89		Initial Revision
 *
 ***********************************************************************/
static int
yyreadstring(char   open,   	/* If matched, ignore next close */
	     char   close,  	/* Character to close the string */
	     char   duplicate, 	/* If matched and follows, place one
				 * in string and continue */
	     YYSTYPE *yylval,	/* Place to store result */
	     char   *yytext,
	     int    yytextSize)
{
    int  	c;
    char	*base = yytext;
    int 	size = yytextSize;
    char    	*cp;
    int	    	level = 0;

    DBPRINTF((stderr,"reading %c%c string literal...", open ? open : close,
		close));
    cp = base;
    while(1) {
	c = input();
	if (c == 0) {
	    if (close != '\n') {
		yyerror("end-of-file in string constant");
		return(0);
	    } else {
		/*
		 * Snarfing to the end of the line. We don't complain here.
		 * Just return what we've got after pushing a newline
		 * back into the input stream -- the EOF will be handled
		 * gracefully elsewhere.
		 */
		unput('\n');
		break;
	    }
	} else if (c == duplicate) {
	    int	c2 = input();

	    if (c2 != duplicate) {
		unput(c2);
		if (c == close) {
		    break;
		}
	    }
	} else if (c == open) {
	    /*
	     * Open character -- up the nesting level
	     */
	    level++;
	} else if (c == '\n') {
	    /*
	     * Allow a newline to terminate the string, but don't
	     * swallow the thing. Since MASM accepts things like
	     *	MACEXEC <.....\n
	     * we don't give a warning should this happen in a <> string,
	     * but otherwise we do....just to be safe :)
	     */
	    if (close != '>' && close != '\n') {
		Notify(NOTIFY_WARNING,
		       FILE_AND_LINE "%c-terminated string constant terminated by newline",
		       paramFile, yylineno, close);
	    }
	    unput(c);
	    break;
	} else if (c == close && --level < 0) {
	    /*
	     * Close on bottom level -- get out of here.
	     */
	    break;
	} else if (c == '\\') {
	    /*
	     * Handle C-style escape sequences.
	     */
	    switch(c = input()) {
	    case 'n': c = '\n'; break;
	    case 'b': c = '\b'; break;
	    case 'f': c = '\f'; break;
	    case 'r': c = '\r'; break;
	    case 't': c = '\t'; break;
	    case '0': case '1': case '2': case '3': case '4':
	    case '5': case '6': case '7': case '8': case '9':
	    {
		/*
		 * Convert from octal.
		 */
		int	val;

		for (val = c - '0';
		     isdigit(c=input()) && c < '8';
		     val += c - '0')
		{
		    val <<= 3;
		}
		/*
		 * Put back the non-digit char
		 */
		unput(c);
		/*
		 * Convert to a character
		 */
		c = val & 0xff;
		break;
	    }
	    case 'x':
	    {
		/*
		 * Convert following 2 digits from hex
		 */
		int val;

		/*
		 * First character MUST be hex...
		 */
		c = input();
		if (isxdigit(c)) {
		    if (c <= '9') {
			val = c - '0';
		    } else if (c <= 'F') {
			val = c - 'A' + 10;
		    } else {
			val = c - 'a' + 10;
		    }
		} else {
		    yyerror("\\x not followed by hex digit");
		    break;
		}
		/*
		 * Second character is optional
		 */
		c = input();
		if (isxdigit(c)) {
		    val <<= 4;
		    if (c <= '9') {
			val += c - '0';
		    } else if (c <= 'F') {
			val += c - 'A' + 10;
		    } else {
			val += c - 'a' + 10;
		    }
		} else {
		    /*
		     * Ok for there only to be one hex digit. Just put
		     * the character we got, back.
		     */
		    unput(c);
		}
		c = val;
		break;
	    }
			case '\r':
				c = input();
				if(c == '\n') {

					yylineno++;
					continue;
				} else {
					unput(c);
				}
	    case '\n':
		/*
		 * Swallow both the \ and the newline when newline is escaped
		 * like this.
		 */
		yylineno++;
		continue;
	    } /* switch */
	} /* if */

	*cp++ = c;

	if (cp == base+size) {
	    /*
	     * Extend buffer as needed.
	     */
	    if (base == yytext) {
		base = (char *)malloc(size*2);
		bcopy(yytext, base, yytextSize);
	    } else {
		base = (char *)realloc(base, size*2);
	    }
	    cp = base + size;
	    size *= 2;
	}
    }
    DBPRINTF((stderr,"done\n"));

    *cp++ = '\0';

    if (base == yytext) {
	/*
	 * Copy to non-volatile storage now we know how big it is.
	 */
	base = (char *)malloc(cp - yytext);
	bcopy(yytext, base, cp-yytext);
    }

    yylval->string = base;

    DBPRINTF((stderr,"returning string %s\n", yylval->string));
    return(STRING);
}

/***********************************************************************
 *				yylex
 ***********************************************************************
 * SYNOPSIS:	    Lexical analyzer for parsing a geode parameters file
 * CALLED BY:	    yyparse
 * RETURN:	    A token, dude. And either nothing (reserved word),
 *	    	    a dynamically allocated string (IDENT) or a number
 *	    	    (NUMBER)
 * SIDE EFFECTS:    Characters are consumed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/19/89	Initial Revision
 *
 ***********************************************************************/
static int
yylex(yylval)
    YYSTYPE	*yylval;
{
    int	    	c;
    static int	bumpline = 0;	/* Last token returned was a newline, but
				 * we don't up yylineno until we're called
				 * again, at which point we know the newline
				 * has been used and no errors will be reported
				 * for the line, so we can up yylineno */
    static int	needNL = 0; 	/* Returned something since the last newline
				 * so we need to return a newline if we get
				 * an EOF */
    char    	yytext[256];
    char    	*cp;

    /*
     * If last token returned was a newline, up the line counter now we
     * know it's actually been used.
     */
    if (bumpline) {
	DBPRINTF((stderr, "starting line %d\n", yylineno));
	yylineno += 1;
	bumpline = 0;
    }

    while (1) {
	/*
	 * Whitespace is meaningless
	 */
	while ((c = getc(yyin)) == ' ' || c == '\t' || c == '\r' ) {
	    ;
	}

	switch(c) {
	    case '"':
		return yyreadstring (0, '"', '"', yylval,
				     yytext, sizeof(yytext));
	    case '\n':
		bumpline = 1;
		needNL = 0;
		doingAlias = FALSE;
		DBPRINTF((stderr, "returning '\\n'\n"));
		return(c);
	    case '.':
	    case ',':
		/*
		 * Return operator characters as-is
		 */
		DBPRINTF((stderr, "returning '%c'\n", c));
		needNL = 1;
		return(c);
	    case '0': case '1': case '2': case '3': case '4':
	    case '5': case '6': case '7': case '8': case '9':
	    {
		/*
		 * Figure the base of the number and convert it.
		 */
		int 	base;
		int     knumb=0;
		long 	n,
			d;

		/*
		 * Scan all digits into the buffer. We check for it being a
		 * valid hexadecimal as that's the least-restrictive (and
		 * highest) base we support.
		 */
		cp = yytext;
		*cp++ = c;
		while(isxdigit(c = getc(yyin))) {
		    *cp++ = c;
		}

		/*
		 * Determine the radix, using trailing
		 * radix characters
		 */
		if ((c == 'Q') || (c == 'q') || (c == 'O') || (c == 'o')) {
		    base = 8;
		} else if ((c == 'H') || (c == 'h')) {
		    base = 16;
		} else if ((c == 'K') || (c == 'k')) {
		    base = 10;
		    knumb=1;
		} else {
		    ungetc(c, yyin);
		    cp--;
		    if ((*cp == 'B') || (*cp == 'b')) {
			base = 2;
		    } else if ((*cp == 'D') || (*cp == 'd')) {
			base = 10;
		    } else {
			/*
			 * Current radix -- we default to 10 for now.
			 */
			base = 10;
			cp++;
		    }
		}

		*cp++ = '\0';
		/*
		 * Convert the number, now we know what base it's in.
		 */
		cp = yytext;
		n = 0;
		while (*cp != '\0') {
		    n *= base;

		    if (*cp <= '9') {
			d = *cp++ - '0';
		    } else if (*cp <= 'F') {
			d = *cp++ - 'A' + 10;
		    } else {
			d = *cp++ - 'a' + 10;
		    }
		    if (d < base) {
			n += d;
		    } else {
			Notify(NOTIFY_ERROR,
			       FILE_AND_LINE "digit %c out of range for base %d number",
			       paramFile, yylineno, cp[-1], base);
			break;
		    }
		}
		/*
		 * Return the value.
		 */
		needNL = 1;
		if(knumb) {
		    DBPRINTF((stderr, "returning KNUMBER(%ld)\n", n));
		    yylval->number = n * 1024;
		    return(KNUMBER);
		}
		else {
		    DBPRINTF((stderr, "returning NUMBER(%ld)\n", n));
		    yylval->number = n;
		    return(NUMBER);
		}
	    }
	    case EOF:
		if (needNL) {
		    /*
		     * Hit EOF without getting a newline (naughty person),
		     * so return one now to avoid annoying, non-obvious
		     * parse errors.
		     */
		    needNL = 0;
		    DBPRINTF((stderr, "returning \\n after EOF\n"));
		    return('\n');
		} else {
		    DBPRINTF((stderr, "end-of-file\n"));
		    return(0);
		}
	    case '#':
		/*
		 * Skip comments.
		 */
		DBPRINTF((stderr, "skipping comment..."));
		while (((c = getc(yyin)) != '\n') && (c != EOF)) {
		    ;
		}
		if (c == '\n') {
		    if (needNL) {
			/*
			 * Not first thing in the line, so return a newline
			 * to finish the line off, setting bumpline so we
			 * up the line count next time. Need to reset
			 * needNL as well, since we don't :)
			 */
			DBPRINTF((stderr, "returning '\\n'\n"));
			bumpline = 1;
			needNL = 0;
			return('\n');
		    } else {
			/*
			 * No point in returning a newline by itself; we might
			 * as well keep going until we have something real to
			 * say.
			 */
			yylineno++;
			DBPRINTF((stderr, "going back in -- line = %d\n",
				yylineno));
			/*
			 * Break out of switch and loop to fetch next token
			 */
			break;
		    }
		} else {
		    DBPRINTF((stderr, "eof..."));
		    if (needNL) {
			/*
			 * Let reading of EOF next time return the end-of-file
			 * marker.
			 */
			DBPRINTF((stderr, "returning \\n\n"));
			needNL = 0;
			bumpline = 1;
			return('\n');
		    } else {
			return(0);
		    }
		}
	    default:
	    {
		const Token *token;

		if (!isfirstid(c)) {
		    Notify(NOTIFY_WARNING,
			   FILE_AND_LINE "Extraneous character 0x%02.2x discarded",
			   paramFile, yylineno, c);
		    break;
		}
		cp = yytext;

		do {
		    *cp++ = c;
		    c = getc(yyin);
		} while (isotherid(c));

		ungetc(c, yyin);
		*cp = '\0';

		if (doingAlias) {
		    const SegAttr *segattr;

		    segattr = findSegAttr(yytext, cp-yytext);
		    if (segattr != NULL) {
			DBPRINTF((stderr, "returning segattr %s\n", segattr->name));
			needNL = 1;
			yylval->number = segattr->value;
			return(segattr->token);
		    }
		}

		token = in_word_set(yytext, cp-yytext);

		if (token != NULL) {
		    DBPRINTF((stderr, "returning token %s\n", token->name));
		    needNL = 1;
		    return(token->token);
		} else {
		    yylval->string = (char *)malloc((cp-yytext)+1);
		    strcpy(yylval->string, yytext);
		    DBPRINTF((stderr, "returning IDENT %s\n", yylval->string));
		    needNL = 1;
		    return(IDENT);
		}
	    }
	}
    }
}


/***********************************************************************
 *				Parse_GeodeParams
 ***********************************************************************
 * SYNOPSIS:	    Parse a geode parameters file.
 * CALLED BY:	    InterPass
 * RETURN:	    0 on error
 * SIDE EFFECTS:    geodeHeader is filled in.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/10/89	Initial Revision
 *
 ***********************************************************************/
int
Parse_GeodeParams(char	*file,
		  char	*deflongname,
		  int	libsOnly)
{
    int	    ret;

    loadingLibs = libsOnly;

    yyin = fopen(file, "rt");

    if (yyin == NULL) {
	Notify(NOTIFY_ERROR, "Couldn't open parameters (gp) file \"%s\"\n",
	       file);
	return(0);
    }

    /*
     * Set longname fields for the file to match our output file name as a
     * default.
     */
    if (!libsOnly) {
	strncpy((geosRelease >= 2 ?
		 geoHeader.v2x.execHeader.geosFileHeader.longName :
		 geoHeader.v1x.execHeader.geosFileHeader.core.longName),
		deflongname,
		GFH_LONGNAME_BUFFER_SIZE);

    }

    paramFile = file;

    ret = !yyparse();

    fclose(yyin);

    Library_CheckForMissingLibraries();

    if (!libsOnly)
    {
	/* if we are making an application then make sure the App object and
	 * Process class were specified in the gp file
	 */
        if (GH(geodeAttr) & GA_APPLICATION)
        {
            if (GH(execHeader.appObjChunkHandle) == 0)
            {
	        Notify(NOTIFY_ERROR, "Application object not specified in gp file.");
	        ret = 0;
            }
            if (GH(execHeader.classResource) == 0)
            {
	        Notify(NOTIFY_ERROR, "Process class not specified in gp file.");
	        ret = 0;
            }
        }
    }
    /*
     * If any entrypoints exported, write out the LDF file.

     Not yet! We may need to publish some routines, so keep it open!

    if (!libsOnly && (numEPs != 0 || makeLDF)) {
	Library_WriteLDF();
    }

     */

    return(ret);
}


/***********************************************************************
 *				Parse_FindSym
 ***********************************************************************
 * SYNOPSIS:	    Figure out a symbol's address
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/19/89	Initial Revision
 *
 ***********************************************************************/
void
Parse_FindSym(char  	*name,	    /* Name of symbol */
	      int   	type,	    /* Expected type of symbol */
	      char  	*typeName,  /* Name of expected type */
	      word  	*resid,	    /* Place to store resource ID */
	      word  	*offset)    /* Place to store offset */
{
    ID	    	    id;	    	/* ID for which to search */
    ID		    id2;    	/* same, but with (or without, as the case may
				 * be) leading underscore */
    VMBlockHandle   block;  	/* Block in which symbol resides */
    word    	    off;    	/* Offset of symbol in block */
    SegDesc 	    *sd;    	/* Segment being searched */
    int	    	    i;	    	/* Index into seg_Segments */
    int	    	    wrongtype;	/* Set if found a symbol but it's the wrong
				 * type */


    id = ST_LookupNoLen(symbols, strings, name);
    if (name[0] == '_') {
	id2 = ST_LookupNoLen(symbols, strings, name+1);
    } else {
	char	*name2 = (char *)malloc(1+strlen(name)+1);

	sprintf(name2, "_%s", name);
	id2 = ST_LookupNoLen(symbols, strings, name2);
	free((malloc_t)name2);
    }

    wrongtype = 0;

    if ((id != NullID) || (id2 != NullID)) {
	for (i = 0; i < seg_NumSegs; i++) {
	    sd = seg_Segments[i];

	    if ((id != NullID &&
		 Sym_Find(symbols, sd->syms, id, &block, &off, TRUE)) ||
		(id2 != NullID &&
		 Sym_Find(symbols, sd->syms, id2, &block, &off, TRUE)))
	    {
		ObjSym  	*sym;

		sym = (ObjSym *)((genptr)VMLock(symbols,
						block,
						(MemHandle *)NULL)+
				 off);
		/*
		 * XXX: ALLOW VAR SYMS IN PLACE OF CLASS SYMS UNTIL PC/GEOS IS
		 * CONVERTED TO THE ESP OBJECT STYLE.
		 */
		if ((sym->type != type) &&
		    ((sym->type != OSYM_VAR) || (type != OSYM_CLASS)) &&
		    ((sym->type != OSYM_VAR) || (type != OSYM_CHUNK)))
		{
		    wrongtype = 1;
		    VMUnlock(symbols, block);
		} else {
		    /*
		     * If it's global, it's hip.
		     */
		    *resid = sd->pdata.resid;
		    *offset = sym->u.addrSym.address;
		    sym->flags |= OSYM_REF;
		    VMUnlockDirty(symbols, block);
		    return;
		}
	    }
	}
    }
    if (wrongtype) {
	Notify(NOTIFY_ERROR, FILE_AND_LINE "%s isn't a %s",
	       paramFile, yylineno, name, typeName);
    } else {
	Notify(NOTIFY_ERROR, FILE_AND_LINE "%s not defined",
	       paramFile, yylineno, name);
    }
}


/***********************************************************************
 *				HandleIFDEF
 ***********************************************************************
 * SYNOPSIS:	    Deal with the start of a conditional. curExpr contains
 *	    	    an expression to be evaluated if necessary to
 *	    	    decide if the conditional code is to be assembled.
 *	    	    If the result is a non-zero constant, the conditional
 *	    	    is taken.
 * CALLED BY:	    parser for all IF and ELSEIF tokens
 * RETURN:	    Nothing
 * SIDE EFFECTS:    iflevel is altered. ScanToEndif may be called.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/28/89		Initial Revision
 *
 ***********************************************************************/
static void
HandleIFDEF(int     wantDef,  	    /* Non-zero if want symbol to be defined */
	    char    *identifier)    /* String to check for definition */
{

    if (iflevel == MAX_IF_LEVEL) {
	yyerror("Too many nested IF's");
    } else {
	ID  id = ST_LookupNoLen(symbols, strings, identifier);
	if ((wantDef && id != NullID) || (!wantDef && id == NullID)) {
	    ifStack[++iflevel] = 1;
	} else {
	    /*
	     * Record a false IF and go to an ELSE or ENDIF
	     */
	    ifStack[++iflevel] = 0;
	    ScanToEndif(TRUE);
	}
    }
}


/***********************************************************************
 *				ScanToEndif
 ***********************************************************************
 * SYNOPSIS:	    Skip to the ENDIF (or ELSE if orElse is TRUE)
 *		    corresponding to this IF.
 * CALLED BY:	    HandleIF on failed conditional
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Characters are discarded. The terminating token is
 *	    	    pushed back into the input stream.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/29/89		Initial Revision
 *
 ***********************************************************************/
void
ScanToEndif(int orElse)
{
    int	    	    nesting=0;	/* Level of IF nesting */
    int	    	    c;	    	/* Current character */
    int             opp;   	/* Conditional opcode, if any */
    char    	    word[MAX_TOKEN_LENGTH]; /* Buffer for scanning of token */
    char    	    *cp2;   	/* Address in same */

    cp2 = word;			/* Be quiet, GCC (this does actually get
				 * set to something in word whenever opp
				 * is set to 1, and that's when it's used) */

    while (1) {
	/*
	 * Skip to the next identifier by looking for a character that
	 * can begin one.
	 */
	while(!isfirstid(c = input()) && (c != EOF)) {
	    if (c == '#') {
		/*
		 * Skip over a comment.
		 */
		do {
		    c = input();
		} while (c != '\n' && c != EOF);

		/*
		 * Fall through to handle the newline, but break out if
		 * hit the end of the file.
		 */
		if (c == EOF) {
		    yyerror("end-of-file in false conditional");
		    opp = 0;
		    break;
		}
	    }

	    if (c == '\n') {
		yylineno++;
	    }
	}

	/*
	 * Got an ID character or an end-of-file...
	 */
	if (isfirstid(c)) {
	    /*
	     * Hit the start of an identifier. Scan it off into word,
	     * downcasing it as we go, as that's what we need to do for
	     * the keywords for which we search.
	     */

	    cp2 = word;

	    do {
		if (isupper(c)) {
		    *cp2++ = tolower(c);
		} else {
		    *cp2++ = c;
		}
		c = input();
	    } while (isotherid(c));

	    *cp2 = '\0';	/* null terminate */

	    /*
	     * Restore extra character to the input
	     */
	    unput(c);

	    if (!strncmp(word, "endif", cp2-word)) {
		opp = 1;
		if (nesting-- == 0) {
		    /*
		     * If no more nesting, we're done.
		     */
		    break;
		}
	    } else if (!nesting
		       && (!strncmp(word, "else", cp2-word))
		       && orElse) {
		opp = 1;
		/*
		 * Hit an ELSE at the highest level and we're allowed to
		 * stop on an else, so get out.
		 */
		break;
	    } else if (!strncmp(word, "ifdef", cp2-word) ||
		       !strncmp(word, "ifndef", cp2-word))
	    {
		opp = 1;
		/*
		 * Another nested IF (yech). Up the nesting level and
		 * keep going.
		 */
		nesting++;
	    } else {
		/*
		 * If not at the start of the line (barring whitespace),
		 * this line can't contain the end or anything nested -- skip
		 * to the end to avoid running into ghosts (e.g. in comments
		 * or %out's)
		 */
		while ((c = input()) != '\n' && (c != EOF)) {
		    ;
		}
		if (c == EOF) {
		    /*
		     * yrg. EOF -- bitch and get out
		     */
		    yyerror("end-of-file in false conditional");
		    opp = 0;
		    break;
		} else {
		    opp = 1;
		    yylineno++;
		}
	    }
	} else if (c == EOF) {
	    /*
	     * yrg. EOF -- bitch and get out
	     */
	    yyerror("end-of-file in false conditional");
	    opp = 0;
	    break;
	}
    }

    if (opp) {
	/*
	 * Broke out properly -- push the token back into the input stream
	 */
	while (--cp2 >= word) {
	    unput(*cp2);
	}
	unput('\n');
	yylineno -= 1;
    }
}
