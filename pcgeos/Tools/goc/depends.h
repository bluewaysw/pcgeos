/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1993 -- All Rights Reserved
 *
 * PROJECT:	  
 * MODULE:	  
 * FILE:	  depends.h
 *
 * AUTHOR:  	  Josh Putnam: Jan 14, 1993
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	1/14/93   	Initial version
 *
 * DESCRIPTION:
 *	header for depends module
 *
 *
 * 	$Id: depends.h,v 1.1 93/01/14 02:19:00 josh Exp $
 *
 ***********************************************************************/
#ifndef _DEPENDS_H_
#define _DEPENDS_H_

#include "goc.h"

/* record that the current file uses the given macro */
extern void Depends_FileUsesMacro (Mac *mac);

/* record that the current file includes the given file */
extern void 
Depends_StoreInclude(char *includeName,char *pathName,Boolean localSearch);

/* tell if goc already included a file and it was optimized. */
extern Boolean Depends_WasOptimized (char *f);

/* 
 * Return the full pathname for an include. needs the name from the 
 * source file, whether or not the search should include '.' and the
 * file pointer's address for setting to the file (if pointer != NULL).
 */
extern char *Depends_GetResolved (char *name,Boolean localSearch, FILE **f);


/* write the depends file for the current file */
extern void Depends_WriteDepends(void);

extern void Depends_Init (void);

/* tells if optimized file is out of date */
extern int 	Depends_ShouldRemake (char *f);

/* records that a file is optimized. */
extern void	Depends_MarkOptimize (void);



extern char *Depends_GetResolved (char *name,Boolean localSearch, FILE **f);


extern Boolean Depends_WasOptimized (char *file);

extern char *Depends_GetFileName (char *root, Boolean dependOrPreGoc);

/*
 * Alternate directory for .[pd]oh to go into.
 */
extern char *directoryOverride;

#endif /* _DEPENDS_H_ */
