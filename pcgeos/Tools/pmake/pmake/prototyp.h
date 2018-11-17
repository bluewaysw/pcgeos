/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  PMake -- Prototype Definitions
 * FILE:	  prototyp.h
 *
 * AUTHOR:  	  Jimmy Lefkowitz: Jul 27, 1992
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	jimmy	7/21/92	    Initial version
 *
 * DESCRIPTION:
 *	
 *
 *
 * 	$Id: prototyp.h,v 1.5 96/06/24 15:06:42 tbradley Exp $
 *
 ***********************************************************************/
#ifndef _PROTOTYP_H_
#define _PROTOTYP_H_

#include <stdio.h>
#include <compat/string.h>
#include <stdarg.h>

#include "lst.h"
#include "hash.h"

#define MallocCheck(fptr, size) (char *)(fptr) = (char *)malloc(size);if((fptr)==NULL)printf("MALLOC FAILED"),exit(1)

typedef struct Path {
    char         *name;	    	/* Name of directory */
    int	    	  refCount; 	/* Number of paths with this directory */
    int		  hits;	    	/* the number of times a file in this
				 * directory has been found */
    Hash_Table    files;    	/* Hash table of files in directory */
} Path;

typedef struct _Suff {
    char         *name;	    	/* The suffix itself */
    int		 nameLen;	/* Length of the suffix */
    short	 flags;      	/* Type of suffix */
#define SUFF_INCLUDE	  0x01	    /* One which is #include'd */
#define SUFF_LIBRARY	  0x02	    /* One which contains a library */
#define SUFF_NULL 	  0x04	    /* The empty suffix */
    Lst    	 searchPath;	/* The path along which files of this suffix
				 * may be found */
    int          sNum;	      	/* The suffix number */
    Lst          parents;	/* Suffixes we have a transformation to */
    Lst          children;	/* Suffixes we have a transformation from */
} Suff;

#if !defined(unix)

extern  char *          getenv(const char *__name);

#endif /*!defined(unix)*/

/*********************************************************************
  	    	    	COMPAT MODULE
**********************************************************************/
extern void	Compat_Run (Lst targs);
extern int	CompatMake (GNode *gn, GNode *pgn);

/*********************************************************************
  	    	    	COND MODULE
**********************************************************************/
extern int	Cond_Eval (char *line);
extern void	Cond_End  (void);

/*********************************************************************
  	    	    	DIR MODULE
**********************************************************************/


extern void	    Dir_Init             (void);
extern Boolean     Dir_HasWildcards     (char *name);
extern void	    Dir_Expand           (char *myword, Lst path, Lst expansions);
extern char   	   *Dir_FindFile         (char *name, Lst path);
extern time_t	    Dir_MTime            (GNode *gn);
extern void	    Dir_AddDir           (Lst path, char *name);
extern ClientData  Dir_CopyDir          (Path *p);
extern char	   *Dir_MakeFlags        (char *flag, Lst path);
extern void	    Dir_Destroy          (Path *p);
extern void	    Dir_ClearPath        (Lst path);
extern void	    Dir_Concat           (Lst path1, Lst path2);
extern void	    Dir_PrintDirectories (void);
extern void	    Dir_PrintPath        (Lst path);


/*********************************************************************
			MAKE MODULE
**********************************************************************/
extern int	    Make_TimeStamp (register GNode *pgn, register GNode *cgn);
extern Boolean	    Make_OODate    (register GNode *gn);
extern void	    Make_Update    (register GNode *cgn);
extern void	    Make_DoAllVar  (GNode *gn);
extern Boolean	    Make_Run       (Lst targs);
extern int	    Make_HandleUse (register GNode *cgn, register GNode *pgn);

/*********************************************************************
			PARSE MODULE
**********************************************************************/
extern Boolean	    Parse_AnyExport     (void);
extern Boolean	    Parse_IsVar         (register char *line);
extern void	    Parse_DoVar         (char *line0, GNode *ctxt);
extern void	    Parse_File          (char *name, FILE *stream);
extern void	    Parse_Init          (void);
extern Lst	    Parse_MainName      (void);
extern void         Parse_Error         (int type, char *fmt, ...);
#if defined(_WIN32)
extern void	    Parse_UpCaseString (char *str);
extern Boolean      Parse_DoBackTick   (char **cmd);
#endif /* defined(_WIN32) */

extern void	    Parse_AddIncludeDir (char *dir);

/*********************************************************************
			SPRITE LIBRARY
**********************************************************************/
//#undef setenv
//extern void setenv(char *, char *);

/*********************************************************************
  	    	    	STR MODULE
**********************************************************************/
extern char	    *Str_Concat        (char *s1, char *s2, int flags);
extern char	    *Str_New           (char *str);
extern char	   **Str_BreakString   (register char *str, register char *breaks,
			        register char *end, Boolean parseBS,
			        int *argcPtr);
extern void	     Str_FreeVec       (register int count, register char **vecPtr);

#if !defined(Sprite) && !defined(_WIN32)
extern char	    *Str_FindSubstring (register char *string, char *substring);
#endif /* !defined(Sprite) && !defined(_WIN32) */

extern int	     Str_Match         (register char *string, register char *pattern,
		         	char **index1, char **index2);
extern char *Str_FindSubstringI(char *string, char *substring);

/*********************************************************************
  	    	    	SUFF MODULE
**********************************************************************/


extern void	    Suff_Init          (void);
extern int	    SuffSuffIsSuffixP  (Suff *s, char *str);
extern void	    Suff_ClearSuffixes (void);
extern Boolean	    Suff_IsTransform   (char *str);
extern GNode	   *Suff_AddTransform  (char *line);
extern int	    Suff_EndTransform  (GNode *gn);
extern void	    Suff_AddSuffix     (char *str);
extern Lst	    Suff_GetPath       (char *sname);
extern void	    Suff_DoPaths       (void);
extern void	    Suff_AddInclude    (char *sname);
extern void	    Suff_AddLib        (char *sname);
extern void	    Suff_FindDeps      (GNode *gn);
extern void	    Suff_SetNull       (char *name);
extern void	    Suff_PrintAll      (void);
/*********************************************************************
			TARG MODULE
**********************************************************************/
extern void	    Targ_Init       (void);
extern GNode	   *Targ_NewGN      (char *name);
extern GNode	   *Targ_FindNode   (char *name, int flags);
extern Lst	    Targ_FindList   (Lst names, int flags);
extern Boolean	    Targ_Ignore     (GNode *gn);
extern Boolean	    Targ_Silent     (GNode *gn);
extern Boolean	    Targ_Precious   (GNode *gn);
extern void	    Targ_SetMain    (GNode *gn);
extern int	    Targ_PrintCmd   (char *cmd);
extern char 	   *Targ_FmtTime    (long time);
extern void	    Targ_PrintType  (long type);
extern void	    Targ_PrintGraph (int pass);
/*********************************************************************
			VAR MODULE
**********************************************************************/
extern void	    Var_Delete      (char *name, GNode *ctxt);
extern void	    Var_Set         (char *name, char *val, GNode *ctxt);
extern void	    Var_Append      (char *name, char *val, GNode *ctxt);
extern Boolean	    Var_Exists      (char *name, GNode *ctxt);
extern char       *Var_Value       (char *mame, GNode *ctxt);
extern char       *Var_Parse       (char *str, GNode *ctxt, Boolean err, 
				    int *lenthPtr, Boolean *freePtr);
extern char       *Var_Subst       (char *str, GNode *ctxt, Boolean undefErr);
extern char       *Var_GetTail     (char *file);
extern char       *Var_GetHead     (char *file);
extern void        Var_Dump        (GNode *ctxt);
extern void	    Var_Init        (void);
extern void        Var_SetFromFile (char *name, char *filename, GNode *ctxt);
extern char       *Var_LastPathSep (char *path);
extern char       *Var_FirstPathSep (char *path);
/*********************************************************************
			MAIN MODULE
**********************************************************************/
extern void	    Main_ParseArgLine (char *line);
extern void        Error             (char *fmt, ...);
extern void        VError            (char *fmt, va_list ap);
#if defined(_WIN32)
extern void        ErrorMessage      (char *fmt, ...);
#endif defined(_WIN32)

extern void        Fatal             (char *fmt, ...);

extern void        Finish            (int errors);

extern void	    DieHorribly       (void);

extern void        Punt              (char *fmt, ...);

#endif /* _PROTOTYP_H_ */
