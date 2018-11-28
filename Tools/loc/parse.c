
/*  A Bison parser, made from parse.y  */

#define YYBISON 1  /* Identify Bison output.  */

#define	RESOURCE	258
#define	GEODE_LONG_NAME	259
#define	PROTOCOL	260
#define	THING	261

#line 1 "parse.y"

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Tools
MODULE:		Localization (.vm) file generation
FILE:		parse.y

AUTHOR:		Josh Putnam, Nov 19, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JHP	11/19/92   	Initial version.
	jacob   9/9/96		Ported to Win32.

DESCRIPTION:
	Takes .rsc file(s) and turns them into a single .vm file
	for use by ResEdit.

	$Id: parse.y,v 1.17 95/01/03 12:35:30 adam Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <config.h>

#ifdef __BORLANDC__
/* 
 * !@#!@#!@ Borland hoses us by not defining this unless you pass -A,
 * which we don't want to do because it's too restrictive.  But if _STDC_
 * isn't defined, then bison.simple will #define "const" to nothing.
 *
 * XXX: maybe move this to cm-bor.h?
 */
#define __STDC__ 1
#endif

#include <stdio.h>
#include <compat/string.h>
#include <compat/stdlib.h>
#include <compat/file.h>
#include <errno.h>
#include <ctype.h>
#include <stdarg.h>

#include <hash.h>
#include <malloc.h>		/* utils version of malloc */
#include <vm.h>
#include <lmem.h>
#include <bswap.h>

/******************************************************************************
 *
 *			  OUTPUT FILE FORMAT
 *
 *****************************************************************************/
#define LOC_TOKEN_CHARS	"LOCL"

#define LOC_PROTO_MAJOR	1
#define LOC_PROTO_MINOR	0

/* The extra map item block NameArray header info for localization files. */
typedef struct {
    NameArrayHeader 	LMH_meta;
    ProtocolNumber	LMH_protocol;
    char    	    	LMH_geodeName[GFH_LONGNAME_BUFFER_SIZE];
} LocMapHeader;

/* The data that goes in the NameArrayElement for each resource. */
typedef struct {
    word		LMD_item;   /* item # of NameArray of chunks */
    word		LMD_group;  /* resource group */
    word		LMD_number; /* resource number */
    /* char 	    	LMD_name[0];		; resource name */
} LocMapData;

/* The structure of the element.
 * Not actually defined, owing to the alignment restrictions on the Sparc
 * (pad byte added after WordAndAHalf structure to align following word)
;
LocMapElement		struct
    LME_meta		NameArrayElement
    LME_data		LocMapData
LocMapElement		ends
 */

/* The data that goes in the NameArrayElement for each chunk */
typedef struct {
    word    	LAD_number; 	    /* chunk number */
    word	LAD_instItem; 	    /* instruction text item # */
    word	LAD_chunkType; 	    /* chunk type */
    word	LAD_minSize; 	    /* min string length */
    word	LAD_maxSize; 	    /* max string length */
    word	LAD_flags;  	    /* user supplied flags */
    /* char	  LAD_name[0];		; chunk name*/
} LocArrayData;

/* The structure of the element.
 * Not actually defined, owing to the alignment restrictions on th
 * (pad byte added after WordAndAHalf structure to align following word)
;
LocArrayElement		struct
    LAE_meta		NameArrayElement
    LAE_data		LocArrayData
LocArrayElement		ends
 */

/******************************************************************************
 *
 *		    INTERNAL STRUCTURE DEFINITIONS
 *
 *****************************************************************************/

typedef struct _locinfo {
    struct _locinfo	*next;	    	/* Next chunk in the resource */
    char 		*chunkName; 	/* Name of this chunk */
    int 		num;	    	/* Number of this chunk */
    int 		hint;	    	/* Type of data in the chunk */
    char 		*instructions;	/* Localization instructions */
    int 		min;	    	/* Minimum data length */
    int 		max;	    	/* Maximum data length */
    int 		flags;	    	/* Maximum data length */
    word    	    	item;	    	/* Item containing the instructions */
} LocalizeInfo;

typedef struct 	{
    char		*name;	    /* Name of the resource */
    int 		num;	    /* Resource number */
    VMBlockHandle   	group;	    /* Group holding data */
    word    	    	item;	    /* Map item for resource */
    LocalizeInfo 	*locHead;   /* Info for first chunk */
    LocalizeInfo 	*locTail;   /* Info for last chunk */
    unsigned int 	count;	    /* Number of chunks in the resource */
} ResourceSym;

/******************************************************************************
 *
 *			   GLOBAL VARIABLES
 *
 *****************************************************************************/

static int 	    	yylineno;
static int	    	errors = 0;
static FILE 	    	*yyin;
static const char   	*curFile;
static ProtocolNumber	proto;
static Hash_Table   	locHash;		/* all resources    */
static ResourceSym  	*currentResource;
static char 	    	*longName = "UNKNOWN";
int	    	    	geosRelease = 2; /* Create 2.0 VM file */
int			dbcsRelease = 0; /* non-zero: create DBCS file */

#define DUMP_LOC_INFO(loc) do{                                   \
		if (loc->instructions[1] == '"') {          \
		    printf("\tchar 0\n");                        \
		} else {                                         \
		    printf("\tchar %s, 0\n", loc->instructions); \
		}                                                      \
        } while (0)

#define DUMP_LOC_ITEM(res, loc)                 \
    do{                        \
	DBPRINTF((";localization info START\n"));               \
	printf("\tDefDBItem %s %s\n", UNIQUE(res), UNIQUE(loc));  \
        DUMP_LOC_INFO(loc);                                     \
	printf("\tEndDBItem %s %s\n", UNIQUE(res), UNIQUE(loc));  \
	DBPRINTF((";localization info END\n"));		        \
    }                                                           \
    while (0)





/* macro to iterate through the hash table and run 'code' with res=resource */
#define FOR_ALL_RESOURCES_WITH_CHUNKS(__res, code)        \
do{ 	        					 \
    Hash_Entry	*__ent;					 \
    ResourceSym *__res;					 \
    Hash_Search 	hashSearch;                      \
	        					 \
    for (__ent = Hash_EnumFirst(&locHash, &hashSearch);	 \
	 __ent;						 \
	 __ent = Hash_EnumNext(&hashSearch)) {		 \
	__res = (ResourceSym *)Hash_GetValue(__ent);	 \
	if (!(__res)->locHead){                          \
           continue;                                     \
	}                                                \
	code    					 \
    }	        					 \
} while (0)

#define FOR_ALL_LOCINFOS_IN_RESOURCE(__res, __locinfo, __code)     \
    do{	        					         \
	LocalizeInfo	*__locinfo;			         \
	for (__locinfo = (__res)->locHead;		         \
	    __locinfo;					         \
	    __locinfo = (__locinfo)->next){		         \
                __code                                           \
	}                                                        \
    } while (0)


/* Create a resource */
/* This becomes the implicit resource for chunks.	*/
/* If the resource exists already, the resource becomes */
/* the current resource. 				*/

static void  EnterResource(char *name);

static void DumpResource (ResourceSym *res, VMHandle output);

/* create a new chunk in the current resource     		*/
/* the data given is the localization information. 		*/
/* another chunk may be defined with the same name later, 	*/
/* but they'll be distinct.					*/
static void EnterChunk(char *name,
		       int num,
		       int hint,
		       char *instructions,
		       int min,
		       int max,
		       int flags);

static void DumpMapBlock(VMHandle output);


static void yyerror(const char *fmt, ...);


#line 237 "parse.y"
typedef union{
    char 	tok;
    char 	*string;
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

#include <stdio.h>

#ifndef __STDC__
#define const
#endif



#define	YYFINAL		20
#define	YYFLAG		-32768
#define	YYNTBASE	8

#define YYTRANSLATE(x) ((unsigned)(x) <= 261 ? yytranslate[x] : 10)

static const char yytranslate[] = {     0,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     7,
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
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     1,     2,     3,     4,     5,
     6
};

static const short yyprhs[] = {     0,
     0,     1,     5,     8,    12,    15,    23,    27
};

static const short yyrhs[] = {    -1,
     8,     9,     7,     0,     3,     6,     0,     3,     6,     6,
     0,     4,     6,     0,     6,     6,     6,     6,     6,     6,
     6,     0,     5,     6,     6,     0,     0
};

#if YYDEBUG != 0
static const short yyrline[] = { 0,
   247,   248,   251,   255,   261,   265,   275,   282
};

static const char * const yytname[] = {   "$","error","$illegal.","RESOURCE",
"GEODE_LONG_NAME","PROTOCOL","THING","'\\n'","file","line",""
};
#endif

static const short yyr1[] = {     0,
     8,     8,     9,     9,     9,     9,     9,     9
};

static const short yyr2[] = {     0,
     0,     3,     2,     3,     2,     7,     3,     0
};

static const short yydefact[] = {     1,
     8,     0,     0,     0,     0,     0,     3,     5,     0,     0,
     2,     4,     7,     0,     0,     0,     0,     6,     0,     0
};

static const short yydefgoto[] = {     1,
     6
};

static const short yypact[] = {-32768,
     0,    -5,    -4,     1,     2,     3,     5,-32768,     6,     7,
-32768,-32768,-32768,     8,     9,    10,    11,-32768,    18,-32768
};

static const short yypgoto[] = {-32768,
-32768
};


#define	YYLAST		18


static const short yytable[] = {    19,
     7,     8,     2,     3,     4,     5,     9,    10,     0,    11,
    12,    13,    14,    15,    16,    17,    18,    20
};

static const short yycheck[] = {     0,
     6,     6,     3,     4,     5,     6,     6,     6,    -1,     7,
     6,     6,     6,     6,     6,     6,     6,     0
};

#if defined _MSC_VER
#    define alloca _alloca
#endif

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
#if (!defined (__STDC__) && defined (sparc)) || defined (__sparc__) || defined(__WATCOMC__)
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

case 3:
#line 252 "parse.y"
{
		    EnterResource(yyvsp[0].string);
		;
    break;}
case 4:
#line 256 "parse.y"
{
		    EnterResource(yyvsp[-1].string);
		    currentResource->num = atoi(yyvsp[0].string);
		    free(yyvsp[0].string);
		;
    break;}
case 5:
#line 262 "parse.y"
{
		    longName = yyvsp[0].string;
		;
    break;}
case 6:
#line 266 "parse.y"
{
		    EnterChunk(yyvsp[-6].string, atoi(yyvsp[-5].string), atoi(yyvsp[-4].string), yyvsp[-3].string, 
			       atoi(yyvsp[-2].string), atoi(yyvsp[-1].string), atoi(yyvsp[0].string));
		    free(yyvsp[-5].string);
		    free(yyvsp[-4].string);
		    free(yyvsp[-2].string);
		    free(yyvsp[-1].string);
		    free(yyvsp[0].string);
		;
    break;}
case 7:
#line 276 "parse.y"
{
		    proto.major = atoi(yyvsp[-1].string);
		    proto.minor = atoi(yyvsp[0].string);
		    free(yyvsp[-1].string);
		    free(yyvsp[0].string);
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
#line 286 "parse.y"



/***********************************************************************
 *				EnterResource
 ***********************************************************************
 * SYNOPSIS:	Make the passed resource the current one, creating a
 *	    	symbol for the beast if we've never seen it before.
 * CALLED BY:	(INTERNAL) yyparse
 * RETURN:	nothing
 * SIDE EFFECTS:    currentResource is set
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/93		Initial Revision
 *
 ***********************************************************************/
static void
EnterResource(char *name)
{
    Hash_Entry	*ent;	/* entry for this resource in the hash table */
    Boolean   	new; 	/* needed for Hash_CreateEntry */

    ent = Hash_CreateEntry(&locHash, name, &new);

    if (new) {
	/* if the thing is new, init the values (zero for all others) */
	ResourceSym	*res = (ResourceSym *)calloc(1, sizeof(ResourceSym));

	Hash_SetValue(ent, res);
	res->name = name;
    }
    currentResource = (ResourceSym *)Hash_GetValue(ent);
}


/***********************************************************************
 *				EnterChunk
 ***********************************************************************
 * SYNOPSIS:	    Define a chunk for the current resource.
 * CALLED BY:	    (INTERNAL) yyparse
 * RETURN:	    nothing
 * SIDE EFFECTS:    currentResource->count is increased by 1.
 *	    	    currentResource->locIns is definitely set
 *	    	    currentResource->loc
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/93		Initial Revision
 *
 ***********************************************************************/
static void
EnterChunk(char *name,
	   int num,
	   int hint,
	   char *instructions,
	   int min,
	   int max,
	   int flags)
{
    LocalizeInfo *loc = (LocalizeInfo *)calloc(1, sizeof(LocalizeInfo));

    loc->chunkName	= name;
    loc->num 		= num;
    loc->hint 		= hint;
    loc->instructions 	= instructions;
    loc->min 		= min;
    loc->max 		= max;
    loc->flags 		= flags;
    loc->next 	    	= NULL;

    if (currentResource->locTail == NULL) {
	currentResource->locTail = currentResource->locHead = loc;
    } else {
	currentResource->locTail->next = loc;
	currentResource->locTail = loc;
    }
    
    currentResource->count++;
}


/***********************************************************************
 *				DBAllocGroup
 ***********************************************************************
 * SYNOPSIS:	    Create a group in the passed file.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    VMBlockHandle for new group
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/93		Initial Revision
 *
 ***********************************************************************/
static VMBlockHandle
DBAllocGroup(VMHandle	file)
{
    VMBlockHandle   result;
    DBGroupHeader   *hdr;

    result = VMAlloc(file, sizeof(DBGroupHeader), SVMID_DB_GROUP);

    hdr = (DBGroupHeader *)VMLock(file, result, (MemHandle *)NULL);
    hdr->DBGH_vmemHandle = swaps(result);
    hdr->DBGH_handle = 0;
    hdr->DBGH_flags = 0;
    hdr->DBGH_itemBlocks = 0;
    hdr->DBGH_itemFreeList = 0;
    hdr->DBGH_blockFreeList = 0;
    hdr->DBGH_blockSize = swaps(sizeof(DBGroupHeader));

    VMUnlockDirty(file, result);
    return(result);
}


/***********************************************************************
 *				DBEnlargeGroup
 ***********************************************************************
 * SYNOPSIS:	    Enlarge a group block to contain the indicated number
 *	    	    of additional bytes, returning a pointer to those bytes.
 * CALLED BY:	    (INTERNAL) DBAlloc
 * RETURN:	    pointer to the newly-allocated bytes
 * SIDE EFFECTS:    DBGH_blockSize is increased. Group block may move
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/93		Initial Revision
 *
 ***********************************************************************/
static void *
DBEnlargeGroup (MemHandle   	mem,
		unsigned    	newBytes,
		DBGroupHeader	**hdrPtr)
{
    DBGroupHeader   *hdr = *hdrPtr;
    word	    size;

    size = swaps(hdr->DBGH_blockSize) + newBytes;
	
    MemReAlloc(mem, size, 0);
    MemInfo(mem, (genptr *)&hdr, (word *)NULL);
    hdr->DBGH_blockSize = swaps(size);

    *hdrPtr = hdr;
    
    return ((void *)((genptr)hdr + size - newBytes));
}


/***********************************************************************
 *				DBAlloc
 ***********************************************************************
 * SYNOPSIS:	    Allocate an item within a particular group.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    item offset
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/93		Initial Revision
 *
 ***********************************************************************/
static word
DBAlloc(VMHandle    	file,
	VMBlockHandle	group,
	unsigned    	itemSize)	    /* Size of item */
{
    DBGroupHeader   *hdr;   	    	/* Data for the group */
    DBItemBlockInfo *ibi;   	    	/* Data for the item block being used */
    DBItemInfo	    *ii;    	    	/* Data for the item being created */
    MemHandle	    mem;    	    	/* Handle for enlarging *hdr */
    VMBlockHandle   itemBlock = 0;  	/* VM handle of item block being used */
    DBItemBlockHeader   *ibh;	    	/* Header of locked item block */
    MemHandle	    imem;   	    	/* Handle for enlarging *ibh */
    word    	    *chunk; 	    	/* Place to store data offset in
					 * item block */
    word    	    *dataPtr;	    	/* Place to store size word in item
					 * block (pointed to by *chunk) */
    word    	    result; 	    	/* Value to return, of course */
    unsigned	    csize;

    /*
     * Lock down the group and see if the first item block is suitable.
     */
    hdr = (DBGroupHeader *)VMLock(file, group, &mem);

    if (hdr->DBGH_itemBlocks != 0) {
	word	ibSize;
	
	ibi = (DBItemBlockInfo *)((genptr)hdr + swaps(hdr->DBGH_itemBlocks));
	VMInfo(file, swaps(ibi->DBIBI_block), &ibSize, (MemHandle *)NULL,
	       (VMID *)NULL);

	if (ibSize + itemSize > 8192) {
	    /*
	     * Allocate a new one instead of using this one, as this one would
	     * put the existing head block over the edge of respectability.
	     */
	    itemBlock = 0;
	} else {
	    /*
	     * It'll fit here, so use it
	     */
	    itemBlock = swaps(ibi->DBIBI_block);
	}
    }

    if (itemBlock == 0) {
	/*
	 * Allocate a new item block.
	 */
	word	size = (sizeof(DBItemBlockHeader) + 3) & ~3;

	itemBlock = VMAlloc(file, size, SVMID_DB_ITEM);

	/*
	 * Be sure to mark it as lmem, please, lest LMBH_handle not get set
	 * right when it's locked down...
	 */
	VMSetLMemFlag(file, itemBlock);
	
	/*
	 * First make room for and initialize the DBItemBlockInfo structure in
	 * the group.
	 */
	ibi = (DBItemBlockInfo *)DBEnlargeGroup(mem, sizeof(DBItemBlockInfo),
						&hdr);
	ibi->DBIBI_next = hdr->DBGH_itemBlocks;
	ibi->DBIBI_refCount = 0;
	ibi->DBIBI_block = swaps(itemBlock);

	/*
	 * Now initialize the freshly-minted item block.
	 */
	ibh = (DBItemBlockHeader *)VMLock(file, itemBlock, &imem);

	ibh->DBIBH_standard.LMBH_handle = swaps(itemBlock);
	ibh->DBIBH_standard.LMBH_offset = swaps(size);
	ibh->DBIBH_standard.LMBH_flags = swaps(LMF_IS_VM);
	ibh->DBIBH_standard.LMBH_lmemType = swaps(LMEM_TYPE_DB_ITEMS);
	ibh->DBIBH_standard.LMBH_blockSize = ibh->DBIBH_standard.LMBH_offset;
	ibh->DBIBH_standard.LMBH_nHandles = 0;
	ibh->DBIBH_standard.LMBH_freeList = 0;
	ibh->DBIBH_standard.LMBH_totalFree = 0;
	ibh->DBIBH_vmHandle = swaps(itemBlock);

	hdr->DBGH_itemBlocks =
	    ibh->DBIBH_infoStruct =
		swaps((genptr)ibi - (genptr)hdr);
    } else {
	/*
	 * Lock down the item block to use.
	 */
	ibh = (DBItemBlockHeader *)VMLock(file, itemBlock, &imem);
    }

    /*
     * Up the reference count for the chosen item block, while ibi is still
     * valid.
     */
    ibi->DBIBI_refCount = swaps(swaps(ibi->DBIBI_refCount) + 1);

    /*
     * Allocate the DBItemInfo structure. INVALIDATES "ibi"
     */
    ii = (DBItemInfo *)DBEnlargeGroup(mem, sizeof(DBItemInfo), &hdr);
    ii->DBII_block = ibh->DBIBH_infoStruct;

    /*
     * Compute the actual size of the chunk, including the size word and
     * rounding that up to a dword boundary.
     */
    csize = (itemSize + 2 + 3) & ~3;

    /*
     * Chunk handles are always allocated in pairs, and they aren't allocated
     * until one of them is about to be used, so point "chunk" to the last
     * handle in the existing table so we can see if it's free.
     */
    chunk = (word *)((genptr)ibh + swaps(ibh->DBIBH_standard.LMBH_offset) +
		     2 * (swaps(ibh->DBIBH_standard.LMBH_nHandles) - 1));

    if ((ibh->DBIBH_standard.LMBH_nHandles == 0) || (*chunk != 0)) {
	/*
	 * Need to add a chunk to the beast (block either has no handles yet,
	 * or final one is non-zero => in-use).
	 */
	word	*tchunk;

	/*
	 * Make room for the chunk and the additional handle-pair at the
	 * same time.
	 */
	MemReAlloc(imem, swaps(ibh->DBIBH_standard.LMBH_blockSize) + 4 + csize,
		   0);
	MemInfo(imem, (genptr *)&ibh, (word *)NULL);

	/*
	 * Copy all the chunk data up 4 bytes to make room for the two new
	 * chunk handles.
	 */
	chunk = (word *)((genptr)ibh + swaps(ibh->DBIBH_standard.LMBH_offset) +
			 2 * swaps(ibh->DBIBH_standard.LMBH_nHandles));

	bcopy(chunk, chunk+2,
	      (swaps(ibh->DBIBH_standard.LMBH_blockSize) -
	       ((genptr)chunk-(genptr)ibh)));

	/*
	 * Adjust all the existing chunk handles to account for the extra
	 * four bytes between themselves and their data.
	 */
	for (tchunk = (word *)((genptr)ibh +
			       swaps(ibh->DBIBH_standard.LMBH_offset));
	     tchunk < chunk;
	     tchunk++)
	{
	    *tchunk = swaps(swaps(*tchunk) + 4);
	}

	/*
	 * Mark second handle of the allocated pair as free (first handle will
	 * be overwritten in a moment, so no point in changing it now.
	 */
	chunk[1] = 0;

	/*
	 * Adjust header data for the two new handles just allocated. Leave
	 * the additional size for the chunk out of LMBH_blockSize until
	 * we hit the common code, below.
	 */
	ibh->DBIBH_standard.LMBH_blockSize =
	    swaps(swaps(ibh->DBIBH_standard.LMBH_blockSize) + 4);
	ibh->DBIBH_standard.LMBH_nHandles =
	    swaps(swaps(ibh->DBIBH_standard.LMBH_nHandles) + 2);
    } else {
	/*
	 * The handle is available, so just make room for the data. No
	 * adjustment of existing handles required.
	 */
	MemReAlloc(imem, swaps(ibh->DBIBH_standard.LMBH_blockSize) + csize, 0);
	MemInfo(imem, (genptr *)&ibh, (word *)NULL);
	
	/*
	 * The block may move, however, so we have to recompute "chunk"
	 */
	chunk = (word *)((genptr)ibh + swaps(ibh->DBIBH_standard.LMBH_offset) +
			 2 * (swaps(ibh->DBIBH_standard.LMBH_nHandles) - 1));
	
    }
	
    /*
     * Point the chosen chunk handle at the data allocated at the end of the
     * block.
     */
    *chunk = swaps(swaps(ibh->DBIBH_standard.LMBH_blockSize) + 2);

    /*
     * Set the size word of the chunk to be that requested, plus the size of
     * the size word itself.
     */
    dataPtr = (word *)((genptr)ibh + swaps(ibh->DBIBH_standard.LMBH_blockSize));
    *dataPtr = swaps(itemSize + 2);

    /*
     * Increase the block size by the rounded size of the chunk.
     */
    ibh->DBIBH_standard.LMBH_blockSize = 
	swaps(swaps(ibh->DBIBH_standard.LMBH_blockSize) + csize);

    /*
     * Record the chunk handle in the DBItemInfo structure.
     */
    ii->DBII_chunk = swaps((genptr)chunk - (genptr)ibh);

    VMUnlockDirty(file, itemBlock);

    /*
     * Compute the item's offset.
     */
    result = (genptr)ii - (genptr)hdr;

    VMUnlockDirty(file, group);

    return(result);
}
	

/***********************************************************************
 *				DBLock
 ***********************************************************************
 * SYNOPSIS:	    Lock down an item in the file.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    void * to the data in question
 * SIDE EFFECTS:    the item block is left locked.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/93		Initial Revision
 *
 ***********************************************************************/
static void *
DBLock(VMHandle	    	file,
       VMBlockHandle	group,
       word 	    	item)
{
    genptr  	    hdr;
    DBItemBlockInfo *ibi;
    DBItemInfo	    *ii;
    void    	    *result;
    word    	    *chunk;

    /*
     * Lock down the group and point to the DBItemBlockInfo and DBItemInfo
     * structures.
     */
    hdr = (genptr)VMLock(file, group, (MemHandle *)NULL);
    ii = (DBItemInfo *)(hdr + item);
    ibi = (DBItemBlockInfo *)(hdr + swaps(ii->DBII_block));

    /*
     * Lock down the item block and find the chunk handle.
     */
    result = (void *)VMLock(file, swaps(ibi->DBIBI_block), (MemHandle *)NULL);
    chunk = (word *)((genptr)result + swaps(ii->DBII_chunk));

    /*
     * Add the offset stored in the chunk handle to the base of the item block
     * to get the final result.
     */
    result = (genptr)result + swaps(*chunk);

    VMUnlock(file, group);
    return(result);
}



/***********************************************************************
 *				DumpMapBlock
 ***********************************************************************
 * SYNOPSIS:	    Create the map item for the file, pointing to all
 *		    the resources previously dumped.
 * CALLED BY:	    (INTERNAL) DumpLocalizations
 * RETURN:  	    nothing
 * SIDE EFFECTS:    the DB map block is set and the map group allocated.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	11/17/92   	Initial Revision
 *	dubois	3/ 3/94  	DBCS modifications
 *
 ***********************************************************************/
static void
DumpMapBlock (VMHandle	output)
{
    int     	    resourceCount;
    VMBlockHandle   group;
    word    	    item;
    VMBlockHandle   mapBlock;
    DBMapBlock	    *map;
    ResourceSym	    *res;
    Hash_Search	    search;
    Hash_Entry	    *ent;
    unsigned   	    mapItemLen;
    byte    	    *bp;
    word    	    offset;
    unsigned 	    headerLen;
    int		    maxLen;

    /*
     * Count the number of resources that actually have chunks.
     */
    mapItemLen = headerLen = sizeof(NameArrayHeader) + sizeof(ProtocolNumber) +
	((dbcsRelease != 0) ?
	 (strlen(longName) + 1) << 1 :
	 strlen(longName) + 1);

    for (ent = Hash_EnumFirst(&locHash, &search), resourceCount = 0;
	 ent != NULL;
	 ent = Hash_EnumNext(&search))
    {
	res = (ResourceSym *)Hash_GetValue(ent);
	if (res->locHead != NULL) {
	    resourceCount += 1;
	    /* 3 == sizeof(NameArrayElement) w/o padding (it's 4 on a Sparc) */
	    mapItemLen += 3 + sizeof(LocMapData) + (dbcsRelease != 0 ?
						    (strlen(res->name) << 1) :
						    strlen(res->name));
	}
    }

    /*
     * Add in the offsets to the elements
     */
    mapItemLen += 2 * resourceCount;

    /*
     * Allocate the map group and map item.
     */
    group = DBAllocGroup(output);
    item = DBAlloc(output, group, mapItemLen);

    bp = DBLock(output, group, item);
    
    /*
     * Initialize the ChunkArrayHeader
     */
    *bp++ = resourceCount;    	    /* CAH_count.low */
    *bp++ = resourceCount >> 8;	    /* CAH_count.high */
    *bp++ = 0; *bp++ = 0;    	    /* CAH_elementSize (variable) */
    *bp++ = 0; *bp++ = 0;    	    /* CAH_curOffset (used at runtime only) */
    *bp++ = headerLen;	    	    /* CAH_offset.low */
    *bp++ = headerLen >> 8;	    /* CAH_offset.high */

    /*
     * Now the ElementArrayHeader
     */
    *bp++ = 0xff; *bp++ = 0xff;	    /* EAH_freePtr (none) */

    /*
     * Now the NameArrayHeader
     */
    *bp++ = 3*2;    	    	    /* NAH_dataSize.low */
    *bp++ = (3*2) >> 8;	    	    /* NAH_dataSize.high */

    /*
     * Now the LocMapHeader
     */
    *bp++ = proto.major;    	    /* LMH_protocol.PN_major.low */
    *bp++ = proto.major >> 8;       /* LMH_protocol.PN_major.high */
    *bp++ = proto.minor;    	    /* LMH_protocol.PN_minor.low */
    *bp++ = proto.minor >> 8;       /* LMH_protocol.PN_minor.high */

    if (dbcsRelease != 0) {	    /* LMH_geodeName */
	maxLen = (strlen(longName) + 1) << 1;
	maxLen = VMCopyToDBCSString((char *)bp, longName, maxLen);
	bp += maxLen;
    } else {
	strcpy((char *) bp, longName);
	bp += strlen(longName) + 1;
    }
    
    /*
     * Next come the offsets to the elements.
     */
    offset = headerLen + 2 * resourceCount;

    for (ent = Hash_EnumFirst(&locHash, &search);
	 ent != NULL;
	 ent = Hash_EnumNext(&search))
    {
	res = (ResourceSym *)Hash_GetValue(ent);

	if (res->locHead != NULL) {
	    *bp++ = offset;
	    *bp++ = offset >> 8;

	    offset += 3 + sizeof(LocMapData) + (dbcsRelease != 0 ?
						(strlen(res->name) << 1) :
						strlen(res->name));
	}
    }
    
    /*
     * Now the elements themselves.
     */
    for (ent = Hash_EnumFirst(&locHash, &search);
	 ent != NULL;
	 ent = Hash_EnumNext(&search))
    {
	
	res = (ResourceSym *)Hash_GetValue(ent);
	if (res->locHead != NULL) {
	    int nameLen = strlen(res->name);

	    *bp++ = 1; *bp++ = 0; *bp++ = 0;	/* NAE_meta.RAH_refCount (1) */
	    *bp++ = res->item;  	    	/* LMD_item.low */
	    *bp++ = res->item >> 8;	    	/* LMD_item.high */
	    *bp++ = res->group; 	    	/* LMD_group.low */
	    *bp++ = res->group >> 8;    	/* LMD_group.high */
	    *bp++ = res->num;   	    	/* LMD_number.low */
	    *bp++ = res->num >> 8;	    	/* LMD_number.high */

	    if (dbcsRelease != 0) {
		maxLen = nameLen << 1;
		VMCopyToDBCSString((char *)bp, res->name, maxLen);
		bp += maxLen;
	    } else {
		bcopy(res->name, bp, nameLen); 	/* LMD_name (w/o null term) */
		bp += nameLen;
	    }
	}
    }

    /*
     * Allocate the map block for the DB system. (Must round the size up to
     * a paragraph to avoid EC code in the kernel).
     */
    mapBlock = VMAlloc(output, (sizeof(DBMapBlock) + 15) & ~15, SVMID_DB_MAP);
    map = (DBMapBlock *)VMLock(output, mapBlock, (MemHandle *)NULL);
    VMSetDBMap(output, mapBlock);

    /*
     * Initialize it, now we've got all the info.
     */
    map->DBMB_vmemHandle = swaps(mapBlock);
    map->DBMB_handle = 0;
    map->DBMB_mapGroup = swaps(group);
    map->DBMB_mapItem = swaps(item);
    map->DBMB_ungrouped = 0;

    VMUnlockDirty(output, mapBlock);
}	/* End of DumpMapBlock.	*/


/***********************************************************************
 *				DumpResource
 ***********************************************************************
 * SYNOPSIS:	    Create a group to hold the data for a resource and
 *		    define the name array that is its map item.
 * CALLED BY:	    (INTERNAL) DumpLocalizations
 * RETURN:  	    nothing
 * SIDE EFFECTS:    res->group, res->item set
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	11/17/92   	Initial Revision
 *	dubois	3/ 3/94  	DBCS modifications
 *
 ***********************************************************************/
static void
DumpResource (ResourceSym *res,
	      VMHandle	output)
{
    byte    	    *bp;
    unsigned   	    len;
    LocalizeInfo    *loc;
    word    	    offset;
    int		    maxLen;
    
    res->group = DBAllocGroup(output);

    /*
     * Spew the instructions themselves into the group.
     */
    for (loc = res->locHead; loc != NULL; loc = loc->next) {
	char	*inst;
	
	if (strlen(loc->instructions) == 0) {
	    loc->item = 0;
	} else if (dbcsRelease != 0) {
	    maxLen = (strlen(loc->instructions) + 1) << 1;
	    loc->item = DBAlloc(output, res->group, maxLen);
	    inst = DBLock(output, res->group, loc->item);
	    VMCopyToDBCSString(inst, loc->instructions, maxLen);
	} else {
	    loc->item = DBAlloc(output, res->group,
				strlen(loc->instructions) + 1);
	    inst = DBLock(output, res->group, loc->item);
	    strcpy(inst, loc->instructions);
	}
    }

    /*
     * Now figure how big the map item needs to be.
     */
    len = sizeof(NameArrayHeader) + 2 * res->count;

    for (loc = res->locHead; loc != NULL; loc = loc->next) {
	/* 3 == sizeof(NameArrayElement) w/o padding (it's 4 on a Sparc) */
	len += 3 + sizeof(LocArrayData);
	len += ((dbcsRelease != 0) ?
	    	(strlen(loc->chunkName) << 1) :
		strlen(loc->chunkName));
    }
    
    res->item = DBAlloc(output, res->group, len);
    bp = DBLock(output, res->group, res->item);

    /*
     * Initialize the ChunkArrayHeader
     */
    *bp++ = res->count;	    	    /* CAH_count.low */
    *bp++ = res->count >> 8;	    /* CAH_count.high */
    *bp++ = 0; *bp++ = 0;	    /* CAH_elementSize (variable) */
    *bp++ = 0; *bp++ = 0;    	    /* CAH_curOffset (used at runtime only) */
    *bp++ = sizeof(NameArrayHeader);	/* CAH_offset.low */
    *bp++ = sizeof(NameArrayHeader)>>8;	/* CAH_offset.high */

    /*
     * Now the ElementArrayHeader
     */
    *bp++ = 0xff; *bp++ = 0xff;	    /* EAH_freePtr (none) */

    /*
     * Now the NameArrayHeader
     */
    *bp++ = 6*2;    	    	    /* NAH_dataSize.low */
    *bp++ = (6*2) >> 8;	    	    /* NAH_dataSize.high */

    /*
     * Next come the offsets to the elements.
     */
    offset = sizeof(NameArrayHeader) + 2 * res->count;
    for (loc = res->locHead; loc != NULL; loc = loc->next) {
	*bp++ = offset;
	*bp++ = offset >> 8;

	offset += 3 + sizeof(LocArrayData);
	offset += (dbcsRelease != 0 ?
		   (strlen(loc->chunkName) << 1) :
		   strlen(loc->chunkName));
    }
    
    /*
     * Now the elements themselves.
     */
    for (loc = res->locHead; loc != NULL; loc = loc->next) {
	int nameLen = strlen(loc->chunkName);

	*bp++ = 1; *bp++ = 0; *bp++ = 0;/* NAE_meta.RAH_refCount (1) */
	*bp++ = loc->num;   	    	/* LAD_number.low */
	*bp++ = loc->num >> 8;	    	/* LAD_number.high */
	*bp++ = loc->item;  	    	/* LAD_instItem.low */
	*bp++ = loc->item >> 8;	    	/* LAD_instItem.high */
	*bp++ = loc->hint;  	    	/* LAD_chunkType.low */
	*bp++ = loc->hint >> 8;	    	/* LAD_chunkType.high */
	*bp++ = loc->min;   	    	/* LAD_minSize.low */
	*bp++ = loc->min >> 8;	    	/* LAD_minSize.high */
	*bp++ = loc->max;   	    	/* LAD_maxSize.low */
	*bp++ = loc->max >> 8;	    	/* LAD_maxSize.high */
	*bp++ = loc->flags;   	    	/* LAD_flags.low */
	*bp++ = loc->flags >> 8;    	/* LAD_flags.high */

	if (dbcsRelease != 0) {
	    maxLen = nameLen << 1;
	    VMCopyToDBCSString((char *)bp, loc->chunkName, maxLen);
	    bp += maxLen;
	} else {
	    bcopy(loc->chunkName, bp, nameLen); /* LAD_name (w/o null terminator) */
	    bp += nameLen;
	}
    }
}



/***********************************************************************
 *				DumpLocalizations
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	11/16/92   	Initial Revision
 *	dubois	3/ 3/94  	DBCS modifications
 *
 ***********************************************************************/
static void
DumpLocalizations(const char *outputName)
{
    VMHandle	    output;
    short   	    status;
    Hash_Entry	    *ent;
    Hash_Search	    hashSearch;
    GeosFileHeader2 gfh;

    (void)unlink(outputName);

    output = VMOpen(VMO_CREATE_ONLY|FILE_DENY_RW|FILE_ACCESS_RW,
		    70,
		    outputName,
		    &status);

    if (output == NULL) {
	perror(outputName);
	exit(1);
    }
    

    VMGetHeader(output, (char *)&gfh);
    gfh.protocol.major = swaps(LOC_PROTO_MAJOR);
    gfh.protocol.minor = swaps(LOC_PROTO_MINOR);
    bcopy(LOC_TOKEN_CHARS, gfh.token.chars, sizeof(gfh.token.chars));
    bcopy("RSED", gfh.creator.chars, sizeof(gfh.creator.chars));
    if (dbcsRelease != 0) {
	VMCopyToDBCSString(gfh.notice, longName, GFH_RESERVED_SIZE);
    } else {
	strncpy(gfh.notice, longName, GFH_RESERVED_SIZE);
    }
    VMSetHeader(output, (char *)&gfh);

    /* now declare all groups and their chunks */
    for (ent = Hash_EnumFirst(&locHash, &hashSearch);
	 ent != NULL;
	 ent = Hash_EnumNext(&hashSearch))
    {
	ResourceSym	    *res;

	res = (ResourceSym *)Hash_GetValue(ent);

	if (res->locHead != NULL) {
	    DumpResource(res, output);
	}
    }

    DumpMapBlock(output);
    VMClose(output);
}

#if defined(_MSDOS) || defined(_WIN32)

/***********************************************************************
 *				GetNextRSCFile
 ***********************************************************************
 * SYNOPSIS:	    Enum to next .rsc file name in CWD
 * CALLED BY:	    main, GetFirstRSCFile
 * RETURN:	    char *, or NULL if none left or error
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JAG	5/19/96   	Initial Revision
 *
 ***********************************************************************/
#if defined(_MSDOS)
static struct find_t	findStruct;
#elif defined(_WIN32)
#include <compat/windows.h>
static WIN32_FIND_DATA	findStruct;
static HANDLE		findHandle;
/* 
 * Pass in file attributes, get back TRUE if this is
 * not a directory or weird psuedo-file.
 */
#define IS_OKAY_FILE(attrs) (!((attrs) & (FILE_ATTRIBUTE_DIRECTORY \
					  | FILE_ATTRIBUTE_SYSTEM)))
#endif /* _WIN32 */

static char *
GetNextRSCFile(void)
{
#if defined(_MSDOS)
    if (_dos_findnext(&findStruct) == 0) {
	return findStruct.name;
    }
    return NULL;
#elif defined(_WIN32) 
    char *fileName = NULL;

    while (1) {
	if (!FindNextFile(findHandle, &findStruct)) {
	    break;
	}
	if (IS_OKAY_FILE(findStruct.dwFileAttributes)) {
	    fileName = findStruct.cFileName;
	    break;
	}
    }

    return fileName;
#endif
}	/* End of GetNextRSCFile.	*/


/***********************************************************************
 *				GetFirstRSCFile
 ***********************************************************************
 * SYNOPSIS:	    Start the ball rollin' on getting names of
 *		    .rsc files in CWD
 * CALLED BY:	    main
 * RETURN:	    char * of file name, NULL if error or none found
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JAG	5/19/96   	Initial Revision
 *
 ***********************************************************************/
static char *
GetFirstRSCFile(char *path)
{
#if defined(_MSDOS)
    if (_dos_findfirst(path, _A_NORMAL, &findStruct) == 0) {
	return findStruct.name;
    }
#elif defined(_WIN32)
    findHandle = FindFirstFile(path, &findStruct);
    if (findHandle != INVALID_HANDLE_VALUE) {
	if (!IS_OKAY_FILE(findStruct.dwFileAttributes)) {
	    /*
	     * Not a plain file, skip it.
	     */  
	    return GetNextRSCFile();
	}

	return findStruct.cFileName;
    }
#endif

    return NULL;
}	/* End of GetFirstRSCFile.	*/
#endif /* _MSDOS || _WIN32 */


/***********************************************************************
 *				ConstructPath
 ***********************************************************************
 *
 * SYNOPSIS:	    Construct full path to enumerated file name
 * CALLED BY:	    main
 * RETURN:	    char * (must be free()'d)
 * SIDE EFFECTS:    
 *	Allocates space for string.
 *
 * STRATEGY:	    
 *	Lame-o FindFirstFile, when given something like FOO/*.rsc
 *      only returns names like Boot.rsc, not FOO/Boot.rsc.  
 *	So we have to manually add that back in.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jacob	10/23/96   	Initial Revision
 *
 ***********************************************************************/
char *
ConstructPath (const char *wildcard, const char *path)
{
    char *lastSlash = strrchr(wildcard, '/');
    char *lastBackSlash = strrchr(wildcard, '\\');
    char *slash;

    if (lastSlash == NULL && lastBackSlash == NULL) {
	/* 
	 * Wasn't in a subdir, just return a copy of the path.
	 */
	return strdup(path);
    } else {
	char *fullPath = (char *) malloc(strlen(path) + strlen(wildcard) + 1);

	/*
	 * Find the last slash or backslash in the pathname.
	 */
	if (lastSlash == NULL) {
	    slash = lastBackSlash;
	} else if (lastBackSlash == NULL) {
	    slash = lastSlash;
	} else {
	    slash = (lastBackSlash > lastSlash) ? lastBackSlash : lastSlash;
	}

	/*
	 * Now chop off the wildcard at the last slash.
	 */
	strcpy(fullPath, wildcard);
	*(fullPath + (slash - wildcard) + 1) = '\0';
	return strcat(fullPath, path);
    }
}	/* End of ConstructPath.	*/


/***********************************************************************
 *				main
 ***********************************************************************
 * SYNOPSIS:	    You know
 * RETURN:	    int
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JAG	5/19/96   	Initial Revision
 *
 ***********************************************************************/
void
main(int argc, char **argv)
{
    char	*outputName = "loc.vm";
    char	*rscFileNames = "*.rsc";
    int	    	i;

#if defined(unix)
    if (argc == 1) {
	exit(0);
    }
#endif
    
    Hash_InitTable(&locHash, -1, HASH_STRING_KEYS, -1);

    for (i = 1; i < argc; i++) {
	if (argv[i][0] == '-') {
	    switch (argv[i][1]) {
	    case 'o':
		if (strlen(argv[i]) == 2) {
		    if (i+1 == argc) {
		        fprintf(stderr,
				"%s: -o argument requires <output-file> "
				"argument\n",
				argv[0]);
		        exit(1);
		    } else {
		        outputName = argv[i+1];
		        i += 1;
		    }
	        } else {
		    outputName = &argv[i][2];
	        }
		break;
	    case '2':
		dbcsRelease = 1;
		break;
	    default:
		fprintf(stderr, "%s: unknown option %s\n", argv[0], argv[i]);
		exit(1);
	    }
	} else {

#if defined(unix)
	    yyin = fopen(argv[i], "rt");
	    if (yyin == NULL) {
		perror(argv[i]);
	        errors += 1;
	        break;
	    }
	    curFile = argv[i];
	    yylineno = 1;
	    if (yyparse()) {
	        (void)fclose(yyin);
	        break;
	    }
	    (void)fclose(yyin);
#else
	    /*
	     * Under NT/DOS, just grab the pattern.
	     */
	    rscFileNames = argv[i];
#endif
	}
    }

#if defined(_MSDOS) || defined(_WIN32)
    {
	curFile = GetFirstRSCFile(rscFileNames);
	if (curFile == NULL) {
	    fprintf(stderr, "loc: no .rsc files found\n");
	    errors = 1;
	} else {
	    do {
		char *fullPath = ConstructPath(rscFileNames, curFile); /* #1 */

		yyin = fopen(fullPath, "rt"); /* #1 */
		if (yyin == NULL) {
		    perror(fullPath);
		    free(fullPath);
		    errors += 1;
		    break;
		}
		free(fullPath);	/* #1 */
		yylineno = 1;
		if (yyparse()) {
		    (void)fclose(yyin);
		    break;
		}
		(void)fclose(yyin);
		
		curFile = GetNextRSCFile();
	    } while (curFile != NULL);
#if defined(_WIN32)
	    /*
	     * Free this up regardless of how we exited.
	     */
	    if (findHandle != INVALID_HANDLE_VALUE) {
		(void) FindClose(findHandle);
	    }
#endif /* _WIN32 */
	}
    }
#endif /* _MSDOS || _WIN32 */
    
    if (errors == 0) {
	DumpLocalizations(outputName);
    }

    /*
     * Free up Hash table to cut down on leaks that BoundsChecker finds.
     * I guess it would be better to iterate thru the thing and free
     * up more stuff, but that's too complicated for now.
     */
    Hash_DeleteTable(&locHash);

    exit(errors);
}	/* End of main.	*/

char lex_buf[1000];

int
yylex(void)
{
    char 	*temp = lex_buf;
    int 	c;
    static int	bumpLine = 0;

    if (bumpLine) {
	yylineno += 1;
	bumpLine = 0;
    }
    
    /*
     * Skip leading whitespace
     */
    do {
	c = getc(yyin);
    } while (isspace(c) && (c != '\n'));
    
    if (c == '\n') {
	bumpLine = 1;
	return c;
    } else if (c == EOF) {
	return 0;
    }
    
    if (c == '"') {
	/*
	 * Quoted string -- read to the matching double-quote. String is
	 * returned without the double-quotes.
	 */
	c = getc(yyin);
	while ((c != EOF) && (c != '"')) {
	    if (c == '\\'){
		c = getc(yyin);
		if (c == EOF) {
		    break;
		}
	    }
	    *temp++ = c;
	    c = getc(yyin);
	}
	*temp = '\0';
    } else {
	do {
	    *temp++ = c;
	    c = getc(yyin);
	} while (!isspace(c));
	
	*temp = '\0';

	/* Put final char back in case it's newline. */
	ungetc(c, yyin);

	if (strcmp(lex_buf, "resource") == 0) {
	    return RESOURCE;
	} else if (strcmp(lex_buf, "GeodeLongName") == 0) {
	    return GEODE_LONG_NAME;
	} else if (strcmp(lex_buf, "Protocol") == 0) {
	    return PROTOCOL;
	}
    }
    
    yylval.string = (char *)malloc(temp - lex_buf + 2);
    strcpy(yylval.string, lex_buf);
    return THING;
}

static void 
yyerror(const char *fmt, ...)
{
    va_list	args;

    va_start(args, fmt);
    fprintf(stderr, "file \"%s\", line %d ", curFile, yylineno);
    vfprintf(stderr, fmt, args);
    putc('\n', stderr);
    va_end(args);
    errors += 1;
}
