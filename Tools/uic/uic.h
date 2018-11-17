/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  UIC -- Definitions file
 * FILE:	  uic.h
 *
 * AUTHOR:  	  Tony Requist
 *
 * DESCRIPTION:
 *	Header file for UIC
 *
 * 	$Id: uic.h,v 2.11 97/06/25 19:20:10 cthomas Exp $
 *
 ***********************************************************************/
#ifndef _UIC_H
#define _UIC_H

#define FALSE	  (0)
#define TRUE	  (!FALSE)

#include    <stdio.h>

#include "hash.h"
#include "symbol.h"

/*
 * Stuff for YACC
*/

extern FILE 	*yyin;    	/* Stream for current input file */

extern int	yylineno;
extern int	yyerrors;

extern char	inFile[];

extern int	localizationWarning;	/* Warning flag for localization */
extern int	localizationRequired;	/* lastChunk needs localized ? */
extern int uniqueCount;                 /* for making of the sybolic names */


#ifdef YYDEBUG
extern int  	yydebug;
#endif /* YYDEBUG */

#ifdef LEXDEBUG
extern int  	lexdebug;
#endif /* LEXDEBUG */

extern int	scanStringEndBrace;

extern int	symdebug;
extern int	outdebug;
extern int	uicdebug;
extern int	outcomments;

/*
 *	Misc globals
*/

extern Symbol	*firstResource;
extern Symbol	*processResource;

extern int	specificUI;
extern int	version20;

extern int  	dbcsRelease;

extern Scope	*visMonikerScope;
extern Scope	*kbdAcceleratorScope;

/********************************************************/
/*	For VisualMonikers and VisualMonikerLists	*/
/********************************************************/

/* these are for 2.0 */
#define V20_VMT_STYLE 0x0f00

/* these are for 1.2 */
#define V12_VMT_GS_TEXT 0x8000
#define V12_VMT_ABBREV_TEXT 0x4000

/* these are common */
#define VMT_GS_SIZE 0x3000
#define VMT_MONIKER_LIST 0x0080
#define VMT_GSTRING 0x0040
#define VMT_GS_ASPECT_RATIO 0x0030
#define VMT_GS_COLOR 0x000F

/* these are for 2.0 */
#define V20_VMT_STYLE_FIELD 8

/* these are common */
#define VMT_GS_SIZE_FIELD 12
#define VMT_GS_ASPECT_RATIO_FIELD 4
#define VMT_GS_COLOR_FIELD 0

/* this is for 2.0 */
typedef enum {
    VMS_TEXT,
    VMS_ABBREV_TEXT,
    VMS_GRAPHIC_TEXT,
    VMS_ICON,
    VMS_TOOL
} VMStyle;

/* this is for 2.0 */
#define V20_VMT_DEFAULT 0x1001	/* default: size=standard, style=text,
				 * aspect=normal, color=grey1 */

/* this is for 1.2 */
#define V12_VMT_DEFAULT 0x1001	/* default: size=standard, aspect=normal,
				 * color = grey1 */

/*
 * The creation of .rsc files was removed in favor of passing
 * localization info through to esp.  If the .rsc file is desired
 * once again, uncomment this #define.  CT 6/24/97
 */
/* #define EXTERNAL_LOCALIZATION_FILE */

/******************************************************/

/*
 * Exported function definitions.
 */
extern void Output(char *fmt, ...);
extern void OutputChar(char c);
extern void Abort(char *fmt, ...);
extern void FatalError(char *fmt, ...);
extern void uicerror(Symbol *sym, char *fmt, ...);
extern char *UniqueName(void);

extern void Parse_Init(void);
extern void Parse_LastChunkWarning (char *fmt, ...);

extern void DoSemanticChecks(void);
extern void DoOutput(void);
extern ObjectField *FindDefault(Symbol *class, Symbol *comp);

extern int  yyparse (void);
extern int  yylex   (void);
extern void yyerror (char *fmt, ...);
extern void lexpush (int token, Symbol *sym);

extern void Scan_Init(void);

#endif /* _UIC_H */
