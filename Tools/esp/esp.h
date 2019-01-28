/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Definitions file
 * FILE:	  esp.h
 *
 * AUTHOR:  	  Adam de Boor: Aug 26, 1988
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/26/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Header file for Esp -- the PC GEOS assembler.
 *
 *
 * 	$Id: esp.h,v 1.33 95/03/20 10:55:15 adam Exp $
 *
 ***********************************************************************/
#ifndef _ESP_H_
#define _ESP_H_

#include "config.h"
#include <compat/queue.h>
#include <compat/string.h>
#include <compat/stdlib.h>


#define sprintf biff_this_sprintf_we_have_our_own
#include <stdio.h>
#undef sprintf
#include <stdarg.h>

#include <mem.h>
#include <os90.h>
#include <bswap.h>
#include <st.h>			/* String table definitions */
#include <malloc.h>

#define FALSE	  0
#define TRUE	  (!FALSE)

/*
 * Memory tags
 */
#define	TAG_STRING_HEAD	    1
#define TAG_STRING_BLOCK    2
#define TAG_MBLK    	    3
#define TAG_EXPR_ELTS	    4
#define TAG_MACRO_ARG	    5
#define TAG_MACRO_ARG_VALUE 6
#define TAG_PARSER_STACK    7
#define TAG_FIX_EXPR	    8
#define TAG_EQUATE_EXPR	    9
#define TAG_BITFIELD_VALUE  10
#define TAG_POP_OPERAND	    11
#define TAG_FIELD_VALUE	    12

/*
 * Basic machine types
 */
typedef genptr		Opaque;

typedef struct _Symbol	*SymbolPtr;


#include    "assert.h"
#include    "expr.h"
#include    "type.h"	    /* Needed for Symbol definition */
#include    "table.h"	    /* Needed for u.segment */
#include    "symbol.h"	    /* Everyone needs this.. */

extern int  	yydebug;

extern int  	lexdebug;

#define NumElts(array) (sizeof(array)/sizeof((array)[0]))

/*
 * Structure defining an opcode/pseudo-op/keyword
 */
typedef struct _OpCode {
    char    name[12];	    /* name of the opcode. Max of 11 chars + null */
    int	    token;	    /* Token to return */
    int	    value;	    /* Value to return in yylval */
} 	OpCode;

/*
 * Processor types enabled.
 */
#define PROC_8086   	0x0001
#define PROC_80186  	0x0002
#define PROC_80286  	0x0004
#define PROC_80386  	0x0008
#define PROC_80486  	0x0010
#define PROC_IO   	0x0040	/* I/O instructions enabled */
#define PROC_PROT   	0x0080	/* Protected mode instructions enabled */
#define PROC_8087   	0x0200
#define PROC_80287  	0x0400
#define PROC_80387  	0x0800

#define PROC_MASK   	0x009f	/* Bits controlling processor type */
#define PROC_CO_MASK	0x0f00	/* Bits controlling coprocessor type */
extern word 	procType;   	/* Flags for enabled processors */

/*
 * Exported function and data definitions.
 */

/* main.c */
extern char 	*FindFile(char *file);

typedef struct {
    char    *flag;  	/* -W option */
    int	    *var;   	/* Storage for current value of flag */
    int	    defval;	/* Default value of flag, based on arguments */
} WarnOpt;

typedef enum {
    NOTIFY_ERROR, NOTIFY_WARNING, NOTIFY_DEBUG,
} NotifyType;
extern void 	NotifyInt(NotifyType,
			  ID file,
			  int line,
			  char *fmt,
			  va_list args);
extern void 	Notify(NotifyType, ID file, int line, char *fmt, ...);

extern int  	    	geosRelease;   	/* PC/GEOS release number (major, only)
					 * for which we're assembling, as set
					 * by -R flag */
extern int  	    	dbcsRelease;	/* Non-zero for DBCS */

extern VMHandle     	output;	    	/* Stream open to .obj file */
extern VMBlockHandle	symStrings; 	/* Temporary string table */
extern VMBlockHandle	permStrings; 	/* Permanent string table */
extern int  	    	makeDepend; 	/* Set if just producing makefile
					 * dependencies */
extern int  	    	masmCompatible;	/* Non-zero if should exhibit weird
					 * MASM-like behaviour */
extern int  	    	reverseString;	/* Store > byte-sized string constants
					 * in "reverse" order (i.e. first
					 * char last, like MASM does) */
extern WarnOpt	    	warnOpts[]; 	/* Available -W flags */
extern const int    	numWarnOpts;	/* Number of available -W flags */

extern int  	    	warn_unref; 	/* Warn if a symbol is defined but
					 * never referenced */
extern int  	    	warn_local_unref;/* Warn if a local label is defined
					  * but never referenced */
extern int  	    	warn_field; 	/* Warn if a structure field is
					 * used with the . operator when
					 * the address to which it is adding
					 * isn't of the type containing
					 * the field. */
extern int  	    	warn_shadow;	/* Warn if an argument or local
					 * variable shadows a variable
					 * definition in a larger scope */
extern int  	    	warn_private;	/* Warn if a private method or
					 * instance variable is used outside
					 * a method handler or friend function
					 * related to the class that defined
					 * the thing */
extern int  	    	warn_unreach;	/* Warn if "unreachable" code is
					 * assembled */
extern int		warn_unknown;	/* Warn if segment for symbol unknown
					 * when doing far call */
extern int  	    	warn_record;	/* Warn if a record initializer doesn't
					 * contain all the fields of the
					 * record */
extern int  	    	warn_fall_thru;	/* Warn if a function falls into another
					 * one without a .fall_thru directive */
extern int  	    	warn_inline_data;/* Warn if a variable is defined where
					  * code execution can reach it */
extern int  	    	warn_jmp;   	/* Warn about transforming out-of-range
					 * jumps */
extern int  	    	warn_assume;	/* Warn when override is generated
					 * based on segment assumptions */
extern int		warn_localize;	/* Warn when localizable string doesn't
                                         * have the localization instruction */
extern int		warn_anonymous_chunk; /* Warn if the chunk has no
                                                 name. */
extern Expr 	    	*entryPoint;	/* Desired entry point for final
					 * executable */
extern SymbolPtr    	global;	    	/* Nameless, global segment */
extern char 	    	*dependFile;	/* Name to put on lhs of ':' when
					 * generating dependencies */

extern int  	    	localize;   	/* Non-zero if should put out
					 * localization info */

extern int		localizationRequired; /* lastChunk needs localized ? */

extern int  	    	do_bblock;  	/* Non-zero if should put out
					 * basic-block coverage code */
extern ID   	    	*libNames;    	/* Name(s) of library being assembled */
extern int  	    	numLibNames;

/* parse.y */
extern void	yywarning(const char *fmt, ...);
extern void     yyerror(const char *fmt, ...);
extern int  	yyparse(void);
extern int  	dot;
extern int  	fall_thru;  	    	/* Set if .fall_thru directive was
					 * seen. Reset at ENDP */

extern void 	Parse_Init(SymbolPtr global);
extern int  	Parse_Complete(void);
extern void 	Parse_DefineString(char *name, char *value);
extern void	Parse_LastChunkWarning(char *fmt, ...);
extern void 	PushSegment(SymbolPtr seg);
extern void 	PopSegment(void);
extern SymbolPtr curSeg;
extern SymbolPtr curProc;

extern int  	writeCheck;
extern int  	readCheck;


/* scan.c */
extern void	yyflush(void);
extern void	yydefmacro();
extern void	yystartmacro();

/* printf.c */
extern int  	printf(const char *fmt, ...);
extern int  	fprintf(FILE *stream, const char *fmt, ...);
extern int  	sprintf(char *str, const char *fmt, ...);
extern int  	vfprintf(FILE *stream, const char *fmt, va_list args);
extern int  	vprintf(const char *fmt, va_list args);
extern int  	vsprintf(char *str, const char *fmt, va_list args);

/* assert.c */
extern void 	Assert_Enter(Expr *expr, char *msg);
extern int  	Assert_DoAll(void);

/* lmem.c */
extern void 	LMem_EndChunk(SymbolPtr sym);
extern SymbolPtr LMem_DefineChunk(TypePtr type, ID name);
extern void 	LMem_InitSegment(SymbolPtr group, word segType, word flags,
				 word freeSpace);
extern SymbolPtr LMem_CreateSegment(ID name);
extern int  	lmem_Alignment;
extern int	LMem_UsesHandles(SymbolPtr seg);

#endif /* _ESP_H_ */
