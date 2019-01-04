/***********************************************************************
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  goc -- Definitions file
 * FILE:	  goc.h
 *
 * AUTHOR:  	  Tony Requist
 *
 * DESCRIPTION:
 *      Global definitions for goc
 *
 * 	$Id: goc.h,v 1.27 96/07/09 17:11:10 jimmy Exp $
 *
 ***********************************************************************/
#ifndef _GOC_H
#define _GOC_H

#if !defined(__STDC__) && !defined(__WIN32__)
#define I(a)	  	a
#define CONCAT(a,b)	I(a)b
#else
#define CONCAT(a,b)	a##b
#endif /* __STDC__ */

#define FALSE	  0
#define TRUE	  (!FALSE)

#include <stdio.h>
#include <stdarg.h>

#include "hash.h"
#include "symbol.h"
#include "stringt.h"


#ifdef _MSDOS
/* MetaBlam complains about bcopy, so just use memcpy instead. */
#define bcopy(source,dest,count) memcpy(dest,source,count)
#endif

#if !defined(_LINUX) && !defined(_WIN32)

/* MetaBlam's alloca trashes the stack and leads to death. */
#define alloca(size) alloca_isnt_portable_you_goob_so_dont_use_it()

#endif

/*
 * Object system stuff
 */

#define DEFAULT_MASTER_MESSAGES		8192
#define FIRST_MASTER_MESSAGE		16384
#define DEFAULT_CLASS_MESSAGES		512
#define DEFAULT_EXPORTED_MESSAGES	48

/*
 *   array where we store the include file search path
 *   used in goc.c and scan.c
 */
#define MAX_DIRS  40
extern char		*dirs[];
extern int		numDirs;

#if defined (unix)
#define NEWLINE_SIZE 1
#else
#define NEWLINE_SIZE 2
#endif


/*
 * Stuff for YACC
*/

extern FILE 	*yyin;    	/* Stream for current input file */

extern int	yylineno;
extern int	yyerrors;

extern char	inFile[];
extern char 	*outFile;
extern Boolean	allowOptimize;

extern char *asciiStringType;
extern char *lStringType;
extern char *sjisStringType;
extern char *defStringType;

#ifdef YYDEBUG
extern int  	yydebug;
#endif /* YYDEBUG */

#ifdef LEXDEBUG
extern int  	lexdebug;
#endif /* LEXDEBUG */

extern int	issueArgsUsedPragma;
extern int	symdebug;
extern int	outdebug;
extern int	gocdebug;
extern int	mpddebug;
extern int	linedebug;
extern int	defaultdebug;
extern int	outcomments;
extern int	realLineNumbers;
extern char 	*replaceSuffix;
extern char 	*classSegName;
extern int  	declareMessageParams;
extern Method	*methodForNullParams;

extern int  	specificUI;
extern int	localize;   /* true iff should put out localization info */
extern Boolean	localizationWarning;
extern int 	optimizedebug;
#define HF_APP_BASE 0x01
extern int  	hackFlags;

/*
 *	Misc globals
*/

extern int      dbcsRelease;

extern Symbol *classDeclList;
extern Symbol *resourceList;
extern Symbol *undefinedList;

extern char *compilerFarKeyword;
extern char *compilerOffsetTypeName;
extern char *compilerCastForOffset;

typedef enum { COM_HIGHC, COM_MSC, COM_BORL, COM_WATCOM } Compilers;

extern Compilers compiler;

extern Symbol *processClass;

extern int bumpLine;

extern char libraryName[];

typedef struct _DeflibNode {
    char *name;
    struct _DeflibNode *next;
} DeflibNode;
#define NullDeflibNode (DeflibNode *)0


/*
 * State saved when an INCLUDE directive is seen.
 */
typedef struct _File {
    ID    	    name;    	/* File's name (fully resolved)*/
    ID    	    includeName;/* File's name (as given in the source)*/
    int		    line;    	/* Current line */
    FILE    	    *file;    	/* Stream open to input file */

    /*
     * These are used to make pre-goc'ed output files: one tells where to
     * put the output, the other where to write dependency information for
     * the file.
     */
    Boolean		optimizeThisFile;
    FILE		*foutput;
    struct _File    *next;    	/* Next file in stack */
} File;

extern File *curFile;

extern Boolean	optimizeThisFile;   /* are(not) optimizing this file */
extern FILE	*foutput;                  /* where to dump output */


#define OUTPUT_BUF_SIZE 2048
#define OPEN_AND_ASSIGN_OUTPUT_FILE(stream,path) do{         \
    (stream) = fopen(path,"wb");			     \
    if(stream){						     \
	setvbuf((stream),NULL,_IOFBF,OUTPUT_BUF_SIZE);	     \
    }							     \
}while(0)


extern DeflibNode *deflibPtr;

/*
 * Print this string before decls of data in lmem blocks
 *
 * glue needs to do special things for lmem data.
 * It tells what is an lmem segment by its name
 * with borland, we can only rename the far segment,
 * so we need to put out "far" before all lmem stuff.
 *
 * This string is set to null for borland and all other compilers like it
 * in ParseArgs.
 */

extern char *lms;


/*
 * Borland 3.{0,1} won't put scalars into far segments. We need to make
 * them into arrays. The strings below are printed for lmem variables.
 */

extern char *_ar;
extern char *_op;
extern char *_cl;


/*
 * localizationRequired: Used to give localization warnings.
 */
extern Boolean localizationRequired;


/******************************************************/

/*
 * Exported function definitions.
 */

extern void yyerror(const char *fmt, ...);
extern void yywarning(char *fmt, ...);
extern int Output(char *fmt, ...);
extern void OutputChar(char c);
extern void FatalError(char *fmt, ...);
extern void gocerror(Symbol *sym, char *fmt, ...);
extern char *UniqueName(void);

extern void CompilerStartSegment(char *prefix, char *name);
extern void CompilerEndSegment(char *prefix, char *name);

extern char *GenerateMPDString(Symbol *passMessage, MsgParamPassEnum paramSpec);

extern InstanceValue *FindDefault(Symbol *class, char *field);
extern Boolean LocateSuperForVariant(Symbol *class, Symbol *object,
			      Symbol **superPtr);


extern void OutputLineNumberForSym(Symbol *sym);
extern void OutputLineNumber(int lineNumber, char *fileName);
extern void OutputSubst(char *str, char *find, char *repl);
extern void OutputSubstOptr(char *str);
extern int  OutputLineDirectiveOrNewlinesForFile (int difference,
                                                  char *fileName,
                                                  int lineNumber);
extern void CopySubst(char *dest, char *source, char *find, char *repl);

/* is 1 if used directive, 0 if used newlines */
#define OutputLineDirectiveOrNewlines(count) \
   OutputLineDirectiveOrNewlinesForFile(count,curFile->name,yylineno)

extern void DoSemanticChecks(void);
extern void DoOutput(void);
extern void DoFinalOutput(void);

extern int yyparse(void);

typedef int LexProc(void);
extern LexProc *yylex;
extern LexProc yystdlex;



extern int makeDepend;     /* whether or not to output dependency info */


extern void Scan_MacroInit(void);                      /* init macro code */
extern void Scan_Init(void);                           /* init lexer code */
extern void Scan_DefineMacro(char *name, char *value); /* macro define for cmdline */

/* issue localization warning */
extern void Parse_LocalizationWarning(char *fmt, ...);

#define zmalloc(size) (calloc(size,1))          /* My malloc that zero's */

/* used to make @include <foo> and @include "foo" act the same. */
extern Boolean allowCurrentDirSearch;




/* dynamic buffer definitions and macros. Used for arrays that need to grow  */

typedef struct{
  unsigned int       size;       /* num alloced              */
  unsigned int       size_inc;   /* num to grow buffer by    */
  unsigned int       buf_index;  /* num used                 */
  char               *c_ptr;     /* buffer                   */
}dynamic_buffer;

#define DB_STR(db)           ((db).c_ptr)
#define DB_SIZE(db)          ((db).size)
#define DB_SIZE_INC(db)      ((db).size_inc)
#define DB_INDEX(db)         ((db).buf_index)

#define DEALLOC_DB_BUFFER(db) free(DB_STR(db))
#define DEALLOC_DYNAMIC_BUFFER(db) free(DB_STR(db)), free(db)

#define INIT_DYNAMIC_BUFFER(db,init_size)              \
  (DB_INDEX(db) = 0),                                  \
  (DB_STR(db) = (char *) zmalloc(DB_SIZE_INC(db) = DB_SIZE(db) = init_size))

#define ADD_CHAR_TO_DYNAMIC_BUFFER(ch,x)               \
  ((*(DB_STR(x)+DB_INDEX(x)++) = (ch)),                  \
   (DB_SIZE(x) == DB_INDEX(x))?(DB_STR(x) =            \
        (char *) realloc(DB_STR(x),(DB_SIZE(x)+=DB_SIZE_INC(x)))):0)

#define ADD_STRING_TO_DYNAMIC_BUFFER(__str,__x)                          \
   do {/* need to alloc __ptr because can't increment literal strings */ \
        char *__ptr = __str;                                             \
        while (*__ptr) { ADD_CHAR_TO_DYNAMIC_BUFFER(*__ptr,__x); __ptr++; }    \
      }while(0)


#define CHANGE_LAST_CHAR_OF_DYNAMIC_BUFFER(ch,x)       \
  (*(DB_STR(x)+DB_INDEX(x)-1) = (ch))

#define LAST_CHAR_OF_DYNAMIC_BUFFER(x) (*(DB_STR(x)+DB_INDEX(x)-1) )


#ifdef min
#undef min
#endif
#define min(a,b) (((a) < (b))?(a):(b))

#if !defined(_MSC_VER)
#pragma Off(Behaved)

#endif /* !defined(_MSC_VER) */


#endif /* _GOC_H */
