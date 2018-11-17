/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Geode Building
 * FILE:	  geo.h
 *
 * AUTHOR:  	  Adam de Boor: Nov  1, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	11/ 1/89  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Definitions shared between the various files that build a geode.
 *
 *
 * 	$Id: geo.h,v 2.17 95/03/02 16:06:31 adam Exp $
 *
 ***********************************************************************/
#ifndef _GEO_H_
#define _GEO_H_

#include    <geode.h>

typedef struct {
    ImportedLibraryEntry entry;
    int	    	    	lnum;	    /* Library number. */
#define NO_LOAD	    -1	    /* lnum if library not auto-loaded */
#define IS_KERNEL   -2	    /* lnum if library is actually the kernel */
#define NO_LOAD_FIXED -3    /* lnum if library not auto-loaded but relocations
			     * are allowed */
} Library;

typedef enum 
{
    LLV_SUCCESS,
    LLV_FAILURE,
    LLV_ALREADY_LINKED
} LibraryLinkValues;

typedef enum
{
    LLT_ON_STARTUP,		/* Library loaded when geode loaded */
    LLT_DYNAMIC,		/* Library loaded by geode, no relocations
				 * fixed up */
    LLT_DYNAMIC_FIXED		/* Library loaded by geode, relocations
				 * handled manually */
} LibraryLoadTypes;

typedef struct {
    ID	    	    name;   	/* Local symbol name */
    ID	    	    alias;  	/* Alias under which it's exported */
    VMBlockHandle   block;  	/* Block containing symbol */
    word    	    offset; 	/* Offset in same */
} EntryPt;    	

typedef union {
    GeodeHeader	    v1x;
    GeodeHeader2    v2x;
} GeodeHeaders;

extern GeodeHeaders geoHeader;

#define GH(field)   ((geosRelease >= 2) ? geoHeader.v2x.field : geoHeader.v1x.field)
#define GHEQ(field,val)   if (geosRelease >= 2) { geoHeader.v2x.field = val; } else { geoHeader.v1x.field = val; }
#define GHA(field) ((geosRelease >= 2) ? &(geoHeader.v2x.field) : &(geoHeader.v1x.field))
#define GH_ASSIGN(field, value) ((geosRelease >= 2) ? ((geoHeader.v2x.field) = (value)) : ((geoHeader.v1x.field) = (value)))
 
extern int  	    stackSize;      /* Size of stack for process thread */
extern Boolean	    stackSpecified; /* True if stack size directive found in 
				     * .gp file */

extern Library	    *libs;  	    /* Array of imported libraries */
extern int  	    numLibs;	    /* Number of imported libraries */
extern int  	    numImport;	    /* Number of libraries actually imported
				     * and loaded by the kernel */
extern EntryPt 	    *entryPoints;   /* Entry points exported by the
				     * geode/kernel */
extern int  	    numEPs; 	    /* Number of entry points exported */

extern int  	    makeLDF;	    /* Non-zero if .ldf file should be created
				     * for library/kernel */

extern Boolean	    noSort; 	    /* Non-zero if Geo module should *not*
				     * sort resources according to when they're
				     * likely to be loaded */

extern Boolean	    localizationWanted; /* true iff should output resource 
					 * names-number pairs and the 
					 * longname of the geode.
					 */

extern char 	    *ldfOutputDir;  /* Directory for .ldf, if any */

int	Parse_GeodeParams(char *file, char *deflongname, int libsOnly);
void  	Parse_FindSym(char *name, int type, char *typeName,
		      word *resid, word *offset);
void	Geo_DecodeRP(char *num, int maxNums, word *wp);

extern void 	Library_AddDir(char *dir);
extern void 	Library_ExportAs(char *name, char *alias,
				 Boolean mustBeDefined);
extern void 	Library_Skip(int n);
extern void 	Library_SkipUntilNumber(int n);
extern void 	Library_SkipUntilConstant(char *name);
extern LibraryLinkValues 
                Library_Link(char   *name,  /* File name */
			     LibraryLoadTypes loadType,
			     word   attrs); /* Expected attributes (library vs.
					     * driver) */
extern void 	Library_WriteLDF(void);
extern int  	Library_Find(ID name, word *entryNum);
extern void 	Library_IncMinor(void);
extern int 	Library_UseEntry(SegDesc *sd, const ObjSym *os, int doInc, int errorIfPlatformViolated);


#endif /* _GEO_H_ */
