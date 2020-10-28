/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Source Mapping
 * FILE:	  src.c
 *
 * AUTHOR:  	  Adam de Boor: Feb  3, 1990
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	2/ 3/90	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions for handling source-line mapping using info from VM-format
 *	symbol files.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: src.c,v 4.35 97/04/18 16:38:36 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "buf.h"
#include "cache.h"
#include "cmd.h"
#include "event.h"
#include "file.h"
#include "src.h"
#include "vmsym.h"
#include "expr.h"
#include <errno.h>
#include <sys/types.h>
#include <compat/stdlib.h>
#include <compat/file.h>

#if defined(unix)
# include <sys/stat.h>
#endif

#if defined(_MSDOS) | defined(_WIN32)
# include <share.h>
# if defined(_MSDOS)
#  include <stat.h>
#  include <dos.h>
# else /* _WIN32 specific */
#  include <sys/stat.h>
#  include <ctype.h>
#  define MAX_FILE_NAME 256
#  include <dos.h>    /* XXXdan remove */
# endif
#endif /* _MSDOS || _WIN32 */

#define SRC_MAX_FILES	10  	/* Most files allowed in the file cache */
#define MAX_LINE_LENGTH 512
#define INIT_LINES 500
extern char wrongNumArgsString[];
extern int COLS;

/*
 * Structure to track a source file. It can have as many SrcLine structures
 * on its "lines" list as it needs, but the total number of files tracked
 * is limited.
 */
typedef struct {
    FileType  	file;		/* The stdio stream open to the file */
    time_t  	mtime;	    	/* Time at which file was last modified */
    int	    	num_lines;  /* number of lines in the file */
    unsigned long *posArray;
} SrcFile;

Cache	fileCache;  /* Name -> SrcFile * cache */

/*
 * Structure placed on a file's "lines" list.
 */
typedef struct {
    unsigned long   line;   /* Line number */
    unsigned long   pos;    /* File position */
} SrcLine;

static SrcFile *SrcOpenFileForCurPatient(char *file, 
					 Cache_Entry *entry,
					 Boolean *new);

/***********************************************************************
 *				SrcFileClose
 ***********************************************************************
 * SYNOPSIS:	    Close down a cached source file.
 * CALLED BY:	    Cache routines on cache overflow
 * RETURN:	    None
 * SIDE EFFECTS:    The open file is closed and all SrcLine structures
 *	    	    for it freed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 4/90		Initial Revision
 *
 ***********************************************************************/
static void
SrcFileClose(Cache  	    cache,
	     Cache_Entry    entry)
{
    SrcFile 	*f;

    f = (SrcFile *)Cache_GetValue(entry);

    if (f != NULL) {
	(void)FileUtil_Close(f->file);
	free((malloc_t)f->posArray);
	free((char *)f);
    }
}

/***********************************************************************
 *				Src_FindLine
 ***********************************************************************
 * SYNOPSIS:	    Find the handle and offset for a source file and line
 * CALLED BY:	    SrcCmd, self
 * RETURN:	    TRUE if handle/offset found
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/18/91		Initial Revision
 *
 ***********************************************************************/
Boolean
Src_FindLine(Patient 	    patient,
	    char    	    *file,
	    int	    	    line,
	    Handle  	    *handlePtr,
	    word    	    *offsetPtr)
{
    ObjHeader	    	*hdr;
    ID	    	    	fileName;
    VMHandle	    	symFile;
    VMBlockHandle   	map;
    int	    	    	i;
    char    	    	*fileTail;
#if defined(_MSDOS) || defined(_WIN32)
    char    	    	relname[256];
    char    	    	*cp;
#endif
#if defined(_WIN32)
    char		relnameUp[256];
    char		fileUp[256];
    char		*lastNodeUp;
#endif
#if defined(_MSDOS)
    char    	    	*path;
    char    	    	*pathEnd;
    /* 
     * lets try to figure out what the filename looked like 
     * use the relative path name using the patient's path name
     * as the root dir to be relative from
     */
    
    path = patient->path;
    pathEnd = strrchr(path, '/');

    if (file[0] != '\\' && file[0] != '/' && file[1] != ':')
    {
	/* so we just need to upcase it and translate slashes if any */
	fileTail = file;
    }
    else
    {
	fileTail = file;
	/* look for a match, allowing backslahses for forward slashes 
	 * and vice versa and don't worry about caps
	 * make sure to start after the drive letters to avoid confusion
	 */
#if 0
	if (file[1] == ':')
	{
	    fileTail = &(file[2]);
	}
	if (path[1] == ':')
	{
	    path = &(path[2]);
	}
#endif
	while ((toupper(*path) == toupper(*fileTail) || 
	       (*path == '\\' && *fileTail == '/') ||
	       (*path == '/' && *fileTail == '\\')) &&
	       (path != pathEnd))
	{
	    path++;
	    fileTail++;
    	}
#if 0
	fileTail = strrchr(file, '/') - 1;
	while(*fileTail != '/')
	{
	    fileTail--;
	}
	fileTail++;
#endif
    }

    if (*fileTail == '\\' || *fileTail == '/')
    {
	fileTail++;
    }

    assert(strlen(file) < 256);
    strcpy(relname, file);
    fileTail = relname + (fileTail - file);

    /* 
     * make sure to upcase things and translate back slashes 
     */
    cp = relname;
    while (*cp)
    {
	if ((cp[0] == '/'))
	{
	    cp[0] = '\\';
	} 
	else if (islower(*cp))
	{
	    *cp = toupper(*cp);
        }
	cp++;
    }
#else  /* end _MSDOS case */
# if defined(_WIN32)
    assert(strlen(file) < 256);
    strcpy(relname, file);

    /* 
     * translate slashes to unix style
     */
    cp = relname;
    while (*cp != '\0') {
	if ((*cp == '\\')) {
	    *cp = '/';
	} 
	cp++;
    }

    /*
     * build the relname with the last node upcased
     */
    strcpy(relnameUp, relname);
    cp = strrchr(relnameUp, '/');
    if (strrchr(relnameUp, '\\') > cp) {
	cp = strrchr(relnameUp, '\\');
    }
    if (cp == 0) {
	cp = relnameUp;
    } else {
	cp++;
    }
    while(*cp != '\0') {
	if (islower(*cp)) {
	    *cp = toupper(*cp);
	}
	cp++;
    }
    
    /*
     * build the filename with the last node upcased
     */
    strcpy(fileUp, relname);
    cp = strrchr(fileUp, '/');
    if (strrchr(fileUp, '\\') > cp) {
	cp = strrchr(fileUp, '\\');
    }
    if (cp == 0) {
	lastNodeUp = 0;
	cp = fileUp;
    } else {
	lastNodeUp = ++cp;
    }
    while(*cp != '\0') {
	if (islower(*cp)) {
	    *cp = toupper(*cp);
	}
	cp++;
    }
# endif
    fileTail = file;
#endif
    symFile = patient->symFile;

    map = VMGetMapBlock(symFile);
    hdr = (ObjHeader *)VMLock(symFile, map, (MemHandle *)NULL);

    fileName = ST_LookupNoLen(symFile, hdr->strings, fileTail);
    if (fileName == NullID)
    {
	fileTail = strrchr(file, '/');
	if (fileTail != 0) {
	    fileName = ST_LookupNoLen(symFile, hdr->strings, ++fileTail);
	}
#if defined(_MSDOS) || defined(_WIN32)
	/* 
	 * lookup the string with the slashes changed 
	 */
	if (fileName == NullID) {
	    fileName = ST_LookupNoLen(symFile, hdr->strings, relname);
	}
#endif
#if defined(_WIN32)
	/* 
	 * lookup the string with the slashes changed to unix and upcased
	 */
	if (fileName == NullID) {
	    fileName = ST_LookupNoLen(symFile, hdr->strings, relnameUp);
	}
	/* 
	 * lookup the string with the whole file name upcased
	 */
	if (fileName == NullID) {
	    fileName = ST_LookupNoLen(symFile, hdr->strings, fileUp);
	}
	/* 
	 * lookup the upcased last node 
	 */
	if (fileName == NullID) {
	    if (lastNodeUp != 0) {
		fileName = ST_LookupNoLen(symFile, hdr->strings, lastNodeUp);
	    }
	}
#endif
    }
    if (fileName != NullID) {
	/*
	 * Well, the string's been heard of. That's a step in the right
	 * direction. See if it's in the source map.
	 */
	VMBlockHandle	smBlock;
	word	    	smOffset;

	if (Sym_SearchTable(symFile, hdr->srcMap, fileName,
			    &smBlock, &smOffset, patient->symfileFormat))
	{
	    ObjSrcMapHeader 	*osmh;
	    ObjSrcMap	    	*check;

	    osmh = (ObjSrcMapHeader *)(VMLock(symFile, smBlock,
					      (MemHandle *)NULL)+
				       smOffset);
	    for (i = osmh->numEntries, check = ObjFirstEntry(osmh, ObjSrcMap);
		 i > 0;
		 i--, check++)
	    {
		if (check->line > line) {
		    break;
		}
	    }

	    /*
	     * If we ended up with a block that's after the line in question,
	     * back up one, so long as we're not at the very front, of course.
	     */
	    while (((i == 0) || (check->line > line) || (check->line == 0)) &&
		   (check != ObjFirstEntry(osmh, ObjSrcMap)))
	    {
		check--, i++;
	    }
	    
	    if (check->line <= line && check->line != 0) {
		ObjSegment  	    *s;
		ObjAddrMapHeader    *oamh;
		ObjAddrMapEntry     *oame;
		ObjLineHeader	    *olh;
		ObjLine	    	    *ol;
		Boolean	    	    isFileName;
		int 	    	    n;
		Boolean	    	    look;
		word	    	    lastOffset;
		word	    	    lastLine;
		Sym 	    	    msym;

		s = (ObjSegment *)((genptr)hdr + check->segment);
		assert(s->lines != 0);
		oamh = (ObjAddrMapHeader *)VMLock(symFile, s->lines,
						  (MemHandle *)NULL);
		smOffset = check->offset;
		for (oame = (ObjAddrMapEntry *)(oamh+1),
		     n = oamh->numEntries;
		     n-- > 0;
		     oame++)
		{
		    if (check->offset < oame->last) {
			break;
		    }
		}
		olh = (ObjLineHeader *)VMLock(symFile, oame->block,
					      (MemHandle *)NULL);
		n = olh->num;
		ol = (ObjLine *)(olh+1);

		isFileName = TRUE;
		look = FALSE;

		lastOffset = 0;
		lastLine = 0;
		while (n-- > 0) {
		    if (isFileName) {
			look = (*(ID *)ol++ == fileName);
			isFileName = FALSE;
		    } else {
			if (ol->line == 0) {
			    isFileName = TRUE;
			} else if (look) {
			    /* because borland puts out line numbers info that
			     * is not always in strictly aascending order
			     *  (for loop and while loop conditions cause 
			     *   weirdness) we must go all the way to the end
			     */
			    if (lastLine < ol->line && ol->line <= line)
			    {
				lastLine = ol->line;
				lastOffset = ol->offset;
			    }
			}
			ol++;
		    }
		}

		*offsetPtr = lastOffset;
		VMUnlock(symFile, oame->block);
		VMUnlock(symFile, s->lines);

		msym = Sym_Lookup(ST_Lock(symFile, s->name),
				  SYM_MODULE,
				  patient->global);
		ST_Unlock(symFile, s->name);
		assert(!Sym_IsNull(msym));

		for (n = 0; n < patient->numRes; n++) {
		    if (Sym_Equal(msym, patient->resources[n].sym)) {
			*handlePtr = patient->resources[n].handle;
			break;
		    }
		}
		assert(n != patient->numRes);

		VMUnlock(symFile, smBlock);
		VMUnlock(symFile, map);
		return(TRUE);
	    }

	    VMUnlock(symFile, smBlock);
	    VMUnlock(symFile, map);
	}
    }

    for(i = 0; i < patient->numLibs; i++) {
	if (Src_FindLine(patient->libraries[i], file, line,
			handlePtr, offsetPtr))
	{
	    return(TRUE);
	}
    }

    /* XXX: Look at loader? */
    return(FALSE);
}
	    

/***********************************************************************
 *				Src_MapAddr
 ***********************************************************************
 * SYNOPSIS:	    Map an address to a source file and line number.
 * CALLED BY:	    GLOBAL
 * RETURN:	    TRUE if mapping successful.
 * SIDE EFFECTS:    *patientPtr, *filePtr, and *linePtr set.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/29/92		Initial Revision
 *
 ***********************************************************************/
Boolean
Src_MapAddr(Handle  	    handle,
	    Address 	    offset,
	    Patient 	    *patientPtr,
	    ID	    	    *filePtr,
	    int	    	    *linePtr)
{
    VMBlockHandle   	map;
    ObjSym	    	*os;
    ObjSegment	    	*s;
    ObjHeader	    	*hdr;
    Patient	    	patient;
    ObjLineHeader   	*olh;       /* Header for current line block */
    ObjLine 	    	*ol;        /* Current line to check */
    ID	    	    	file;       /* Actual filename */
    ID	    	    	cfile=0;    /* Current file name */
    int	    	    	line;       /* Most promising/actual line
				     * number */
    ObjAddrMapHeader	*oamh;
    ObjAddrMapEntry     *oame;
    
    /*
     * Make sure handle is a resource handle, as those are the only things
     * for which we can possibly have a line-number mapping.
     */
    if ((handle == NullHandle) ||
	!(Handle_State(handle) & (HANDLE_RESOURCE|HANDLE_KERNEL)))
    {
	return(FALSE);
    }
    
    patient = Handle_Patient(handle);
    
    /*
     * Locate the ObjSegment descriptor for the resource using the offset
     * stored in the module symbol (the symbol is stored in the resources
     * array of the patient that owns the handle; the resource id is stored
     * in the otherInfo field of the handle and that indexes the resources
     * array...).
     */
    os = SymLock(patient->resources[(int)handle->otherInfo].sym);
    map = VMGetMapBlock(patient->symFile);
    hdr = (ObjHeader *)VMLock(patient->symFile, map,
			      (MemHandle *)NULL);
    s = (ObjSegment *)((genptr)hdr + os->u.module.offset);
    
    
    file = NullID;
    line = 0;
    
    if (s->lines != 0) {
	int 	i;
	
	oamh = (ObjAddrMapHeader *)VMLock(patient->symFile,
					  s->lines,
					  (MemHandle *)NULL);
	oame = (ObjAddrMapEntry *)(oamh+1);
	i = oamh->numEntries;
	
	while (i > 0 && oame->last < (word)offset) {
	    i--, oame++;
	}
	while (i > 0) {
	    word	n;
	    Boolean	isFileName;
	    
	    olh = (ObjLineHeader *)VMLock(patient->symFile,
					  oame->block,
					  (MemHandle *)NULL);
	    
	    n = olh->num;
	    
	    ol = (ObjLine *)(olh+1);
	    isFileName = TRUE;	/* First entry in block is
				 * always a file name */
	    while (n-- > 0) {
		if (isFileName) {
		    cfile = *(ID *)ol++;
		    isFileName=FALSE;
		} else if (ol->line == 0) {
		    /*
		     * File change -- record the new file only in 'cfile'. If
		     * the next line number record is still below the offset,
		     * 'cfile' will be transfered to 'file' then.
		     */
		    isFileName=TRUE;
		    ol++;
		} else if (ol->offset > (word)offset) {
		    /*
		     * Passed the offset. file and line already set up
		     * properly, so break out now.
		     */
		    VMUnlock(patient->symFile, oame->block);
		    goto got_it;
		} else {
		    file = cfile;
		    line = ol->line;
		    ol++;
		}
	    }
	    /*
	     * Keep looping until we're certain we're past the thing. If last
	     * is equal to offset, the next block could contain entries that
	     * are equal to offset as well.
	     */
	    VMUnlock(patient->symFile, oame->block);
	    if (oame->last > (word)offset) {
		break;
	    }
	    oame++, i--;
	}
    got_it:
	VMUnlock(patient->symFile, s->lines);
    }
    
    VMUnlock(patient->symFile, map);

    if (file == NullID) {
	/*
	 * Mapping failed.
	 */
	return(FALSE);
    } else {
	/*
	 * Return the three things that define the mapping and tell our caller
	 * of our success.
	 */
	*patientPtr = patient;
	*filePtr = file;
	*linePtr = line;
	return(TRUE);
    }
}	

/***********************************************************************
 *				SrcMapAddr
 ***********************************************************************
 * SYNOPSIS:	    Map an address expression to the source file and
 *	    	    line number at which the address is initialized,
 *		    defined, whatever..
 * CALLED BY:	    SrcCmd
 * RETURN:	    TCL_ERROR/TCL_OK
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/21/91		Initial Revision
 *
 ***********************************************************************/
static int
SrcMapAddr(Tcl_Interp	*interp,
	   char	    	*addrExp,
	   Frame    	*f)
{
    GeosAddr	addr;
#if defined(_WIN32)
    char	filebuf[MAX_FILE_NAME];
    char	*filetmp;
#endif
    
    if (!Expr_Eval(addrExp, f, &addr, (Type *)NULL, TRUE)) {
	Tcl_Error(interp, "cannot map address to line");
    } else if (addr.handle == NullHandle) {
	Tcl_Error(interp, "cannot map absolute address to source line");
    } else if (!(Handle_State(addr.handle) &
		 (HANDLE_RESOURCE|HANDLE_KERNEL)) ||
	       (Handle_State(addr.handle) & HANDLE_THREAD))
    {
	Tcl_Error(interp, "cannot map address to line");
    } else {
	ID  	file;
	int 	line;
	Patient	patient;

	if (Src_MapAddr(addr.handle, addr.offset, &patient, &file, &line)) {
	    char    *fname = ST_Lock(patient->symFile, file);
	    char    lnum[16];
	    char    *retval[2];
	    
	    sprintf(lnum, "%d", line);
	    retval[1] = lnum;

#if !defined(_MSDOS) && !defined(_WIN32)
	    if (*fname != '/') 
#else
	    /* 
	     * it's the PC world so see if we are specifying the drive
	     * use forward slashes since this is a TCL command and
	     * so we accept either
	     */
	    if (*fname != '/' && *fname != '\\' && fname[1] != ':')
#endif
	    {
		/*
		 * Not absolute, so we have to preface the file with
		 * the patient's path.
		 */
		char	*cp, *cp2;
		char    afile[1024];
		
		if (patient->srcRootEnd != 0) {
		    /*
		     * Already determined what part of the patient->path we
		     * want to use...
		     */
		    cp = patient->srcRootEnd;
		} else {
		    /*
		     * Start by assuming we just want to drop the last
		     * component, which is the .geo file itself.
		     */
		    cp = rindex(patient->path, '/');
		    if (rindex(patient->path, '\\') > cp) {
			cp = rindex(patient->path, '\\');
		    }
		}
		
		if (cp == NULL) {
		    /*
		     * Not actually a path => the executable is in the current
		     * directory.
		     */
		    sprintf(afile, "%s/%s", cwd, fname);
		} else {
		    *cp = '\0';
		    sprintf(afile, "%s/%s", patient->path, fname);
		    *cp = '/';
		}
		/* convert any backslashes to forward slashes, so Tcl doesn't
		 * get confused */
		cp2 = index(afile, '\\');
		while (cp2 != NULL) 
		{
		    *cp2 = '/';
		    cp2 = index(cp2, '\\');
		}
		/*
		 * If we've not yet determined whether the patient is
		 * product-specific, check the existence of the file we're
		 * about to return.
		 *
		 * By "product-specific" I mean the executable was placed in
		 * a subdirectory (e.g. "XIP" or "Redwood") of where
		 * the compile actually took place. Source paths are
		 * relative to the compile directory, one level up from
		 * where the executable sits, if it's product-specific.
		 */
		if (patient->srcRootEnd == 0) {
#if defined(_WIN32)
		    if (strncmp(afile, "/staff", 6) == 0) {
			(void)File_MapUnixToDos(filebuf, afile, "s:/");
			filetmp = filebuf;
		    } else {
			filetmp = afile;
		    }
		    if (access(filetmp, R_OK) < 0) {
#else
		    if (access(afile, R_OK) < 0) {
#endif
			/*
			 * Assume this is because the patient is product-
			 * specific and attempt to find the file by trimming
			 * one component from the patient path.
			 */
			if (cp != NULL) {
			    for (cp2 = cp-1; cp2 > patient->path; cp2--) {
				if ((*cp2 == '/') || (*cp2 == '\\')) {
				    break;
				}
			    }
			    /*
			     * Copy the text following (and including) the
			     * slash that's before the relative filename (as
			     * determined by subtracting patient->path from
			     * cp to get the number of characters contributed
			     * by that party) over top of the final component
			     * of the stuff from patient->path (as determined
			     * by subtracting patient->path from cp2, which
			     * is the slash before the final slash in
			     * patient->path).
			     */
			    strcpy(&afile[cp2-patient->path],
				   &afile[cp-patient->path]);
			    /*
			     * Now make sure that thing exists before we go
			     * declaring this thing to be a product-specific
			     * patient...
			     */

#if defined(_WIN32)			    
			    /* 
			     * switch from unix to dos file names
			     */
			    if (strncmp(afile, "/staff", 6) == 0) {
				(void)File_MapUnixToDos(filebuf, afile, "s:/");
				filetmp = filebuf;
			    } else {
				filetmp = afile;
			    }
			    if (access(filetmp, R_OK) == 0) {
#else
			    if (access(afile, R_OK) == 0) {
#endif
				patient->srcRootEnd = cp2;
			    }
			}
		    } else {
			/*
			 * If the source file exists, record the end of
			 * the text we want to use in future calls.
			 */
			patient->srcRootEnd = cp;
		    }
		}
		retval[0] = afile;
		Tcl_Return(interp, Tcl_Merge(2, retval), TCL_DYNAMIC);
	    } else {
		int index=0;

		retval[0] = malloc(strlen(fname)+1);
		while(1) {
		    if (*fname == '\\') {
			retval[0][index] = '/';
		    } else {
			retval[0][index] = *fname;
		    }
		    if (*fname == '\0') break;
		    fname++;
		    index++;
		}
		Tcl_Return(interp, Tcl_Merge(2, retval), TCL_VOLATILE);
		free(retval[0]);
	    }
	    ST_Unlock(patient->symFile, file);
	} else {
	    Tcl_Return(interp, NULL, TCL_STATIC);
	}
    }
    return(TCL_OK);
}

/*********************************************************************
 *			SrcTclReturnFileError
 *********************************************************************
 * SYNOPSIS: 	    return a file error message
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	3/12/93		Initial version			     
 * 
 *********************************************************************/
void
SrcTclReturnFileError(char *file)
{
    switch (errno)
    {
	case ENOENT:
	    if (!strncmp(file, "/staff/pcgeos", 13)) {
		Tcl_RetPrintf(interp,
			      "GEOS system source file not available.");
	    } else {
	    	Tcl_RetPrintf(interp, "File %s doesn't exist.", file);
	    }
	    break;
	case EMFILE:
	    Tcl_RetPrintf(interp, "Too many open files. (Try 'src flush' "
			  "to close some files).");
	    break;
	default:
	    Tcl_RetPrintf(interp, "Couldn't open file %s.", file);
	    break;
    }
}

/***********************************************************************
 *				SrcGetLineInfo
 ***********************************************************************
 * SYNOPSIS:	    basic code for getting number of lines in file
 *	    	    and line numbers/file pos mappings
 * CALLED BY:	    SrcOpenFileForCurPatient
 * RETURN:	    number of lines in a file
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JL	3/30/95   	Initial Revision
 *
 ***********************************************************************/
int
SrcGetLineInfo (SrcFile *f)
{
    FileType        fp;
    int	    	    arraySize;
    unsigned long   pos, *posArray;
    char    	    inputbuf[MAX_LINE_LENGTH];
    unsigned long   lines;
    int	    	    at_start;

    fp = f->file;
    if (f->posArray == NULL) {
	arraySize = INIT_LINES;
	f->posArray = (unsigned long *)malloc(sizeof(long) * INIT_LINES);
    } else {
	/*
	 * Rebuilding the line cache, so set the array size to the number of
	 * lines we found last time, on the assumption the file hasn't changed
	 * much.
	 */
	arraySize = f->num_lines+1;
    }
    posArray = f->posArray;
    pos = 0;
    *posArray++ = pos;
    (void)FileUtil_Seek(fp, pos, SEEK_SET);
    lines = 0;
    at_start = TRUE;
    while (1)
    {
	int 	i;
	char	*cp;
	long 	rd;

	(void)FileUtil_Read(fp, inputbuf, MAX_LINE_LENGTH - 1, &rd);
	if (rd <= 0) {
	    break;
	}
	cp = inputbuf;
	for (i=0; i < rd; i++)
	{
	    if (*cp == '\n') 
	    {
		if (lines+1 == arraySize) 
		{
		    arraySize += INIT_LINES;
		    f->posArray = (unsigned long *)realloc(
				          (malloc_t)f->posArray,
					  sizeof(long) * arraySize);
		    posArray = f->posArray + lines + 1;
		}
		*posArray++ = pos + 1;
		lines++;
		at_start = TRUE;
	    } else {
		at_start = FALSE;
	    }
	    pos++;
	    cp++;
	}
    }

    if (!at_start) {
	/*
	 * Handle file with no newline at the end. This ensures the size of
	 * the file is the last entry in the posArray
	 */
	if (lines+1 == arraySize) 
	{
	    arraySize += INIT_LINES;
	    f->posArray = (unsigned long *)realloc((malloc_t)f->posArray,
						   sizeof(long) * arraySize);
	    posArray = f->posArray + lines + 1;
	}
	*posArray++ = pos;
	lines++;
    }
    
    /*
     * Shrink the array to be the number of lines (in case file changed size
     * dramatically from the last time we built the line cache...) plus one
     * for the size of the file.
     */
    f->posArray = (unsigned long *)realloc((malloc_t)f->posArray,
					   ((char *)posArray -
					    (char *)f->posArray));
    return lines;
}	

#if defined(_WIN32)
/***********************************************************************
 *				SrcSJISRead
 ***********************************************************************
 *
 * SYNOPSIS:	    Reads in SJIS (which incorporates ascii) data
 *		    and makes double byte characters of them all
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    Success(TRUE) or Failure(FALSE)
 * SIDE EFFECTS:    nRead is set to the number of SJIS chars returned
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann2/25/97   	Initial Revision
 *
 ***********************************************************************/
static int
SrcSJISRead (FileType file, unsigned short *doubleByteBuf, long len, 
		      long *nDoubleBytesReturned)
{
    long numBytesRead;
    int sbcPos, dbcPos;
    unsigned char *singleByteBuf;
    unsigned short highByte, lowByte;
    unsigned short sjisChar;

    singleByteBuf = (unsigned char *)malloc(len * 2);
    
    /*
     * Do a normal read, return immediately if EOF or
     * error.
     */
    (void)FileUtil_Read(file, (char *)singleByteBuf, (len * 2), 
			&numBytesRead);

    /*
     * Now scan thru and filter out all the non-printing bytes 
     * (from an ASCII standpoint) that can crop up in SJIS.
     * The non-priting SJIS chars are all > 0x7E.
     */
    if (numBytesRead > 0) {
	sbcPos = 0;
	dbcPos = 0;
	while ((dbcPos < len) && (sbcPos < numBytesRead)) {
	    /* 
	     * form the byte or SJIS bytes to a double byte
	     */

	    if (((singleByteBuf[sbcPos] > SJIS_SB_END_1) && 
		 (singleByteBuf[sbcPos] < SJIS_SB_START_2)) ||
		(singleByteBuf[sbcPos] > SJIS_SB_END_2)) 
	    {
		/* SJIS bytes */
		highByte = singleByteBuf[sbcPos++];
		if (sbcPos >= numBytesRead) {
		    break;
		}
		lowByte = singleByteBuf[sbcPos++];
		if ((lowByte < SJIS_DB2_START_1) ||
		    ((lowByte > SJIS_DB2_END_1) && 
		     (lowByte < SJIS_DB2_START_2)) ||
		    (lowByte > SJIS_DB2_END_2)) 
		{
		    /*
		     * handle bad SJIS character - turn it into a space
		     */
		    if (MessageFlush != NULL) {
			MessageFlush("Encountered an illegal SJIS "
				     "character 0x%x\n", 
				     (highByte << 8) | (lowByte & 0xff));
		    }
		    highByte = 0;
		    lowByte = ' ';
		}
	    } else {
		/* normal byte */
		highByte = 0;
		lowByte = singleByteBuf[sbcPos++];
	    }
	    sjisChar = (highByte << 8) + lowByte;
	    doubleByteBuf[dbcPos++] = sjisChar;
	}
	*nDoubleBytesReturned = dbcPos;
	free((void *)singleByteBuf);
	return TRUE;
    }

    *nDoubleBytesReturned = 0;
    free((void *)singleByteBuf);
    return FALSE;
}	/* End of SrcSJISRead.	*/

#endif  /* end of WIN32 specific code


/***********************************************************************
 *				SrcSJISSafeRead
 ***********************************************************************
 *
 * SYNOPSIS:	    Exactly the same as read(), but filters out
 *		    any non-ASCII SJIS bytes.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    Success(TRUE) or Failure(FALSE)
 * SIDE EFFECTS:    nRead is set to the number of chars returned
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jacob	1/21/97   	Initial Revision
 *
 ***********************************************************************/
static int
SrcSJISSafeRead (FileType file, char *buf, long len, long *nRead)
{
    int i;

    /*
     * Do a normal read, return immediately if EOF or
     * error.
     */
    (void)FileUtil_Read(file, buf, len, nRead);

    /*
     * Now scan thru and filter out all the non-printing bytes 
     * (from an ASCII standpoint) that can crop up in SJIS.
     * The non-priting SJIS chars are all > 0x7E.
     */
    if (nRead > 0) {
	for (i = 0; i < *nRead; i++) {
	    if (((unsigned char) buf[i]) > 0x7E) {
		buf[i] = ' ';
	    }
	}
	return TRUE;
    }

    return FALSE;
}	/* End of SrcSJISSafeRead.	*/


/*
 * macro to make a wide(2 byte) char from a skinny(1 byte) char
 */
# define MAKEWCHAR(ascii) (((unsigned short)(ascii)) & 0x00ff)

/***********************************************************************
 *				Src_ReadLine
 ***********************************************************************
 * SYNOPSIS:	    Read a source line from a file.
 * CALLED BY:	    SrcCmd, dssLowCmd
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:    The line's position is cached.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/21/91		Initial Revision
 *
 ***********************************************************************/
int
Src_ReadLine(Tcl_Interp	    *interp,
	     char    	    *file,
	     char    	    *lineNum,
	     char    	    *numLines, 
	     char    	    *data,
	     unsigned short *doubleByteData)
{
    Cache_Entry	    entry;
    Boolean 	    new;
    SrcFile 	    *f;
    long    	    line, len, lenRead;
    unsigned long   pos;
    int	    	    i;
    long	    cc;
    Buffer  	    buf;
    char    	    *inputbuf, *cp;
    int		    index;

    f = SrcOpenFileForCurPatient(file, &entry, &new);
    if (f == NULL)
    {
	SrcTclReturnFileError(file);
	return (TCL_ERROR);
    }
      
    if (!new) {
	/*
	 * See if the file's been modified since last time it was accessed
	 */
	time_t	mtime;

	mtime = FileUtil_GetTime(f->file);
	if (mtime < 0) {
	    Cache_InvalidateOne(fileCache, entry);
	    Tcl_RetPrintf(interp, "%s file no longer exists", file);
	    return(TCL_ERROR);
	}

	if (f->mtime != mtime) {
	    /*
	     * It has, so biff all the cached line offsets.
	     */
	    f->num_lines = SrcGetLineInfo(f);
	    f->mtime = mtime;
	    /* XXXdan need to do more than this for all cases I believe */
	}
    }

    line = atoi(lineNum);
    if (line == 0) {
	line = 1;
    }

    if ((line < 0) || (line > f->num_lines)) {
	Tcl_RetPrintf(interp, "The source file %s only has %d lines, so can't "
		      "read line %s", file, f->num_lines, lineNum);
	return(TCL_ERROR);
    }

    pos = f->posArray[line - 1];
    (void)FileUtil_Seek(f->file, pos, SEEK_SET);

    /*
     * File now positioned at the start of the requested line. Return
     * it without the newline at the end.
     */
    if (numLines != NULL) {
	index = 0;
	len = atoi(numLines)*COLS;

#if !defined(_WIN32)
	(void)SrcSJISSafeRead(f->file, data, len, &lenRead);
#else   
	if (data != NULL) {
	    (void)FileUtil_Read(f->file, data, len, &lenRead);
	} else {
	    assert(doubleByteData != NULL);
	    (void)SrcSJISRead(f->file, doubleByteData, len, &lenRead);
	    pos = len - 1;
	    while (pos >= lenRead) {
		doubleByteData[pos] = MAKEWCHAR('\0');
		pos--;
	    }
	    while (lenRead-- > 0) {
		if (doubleByteData[index] == MAKEWCHAR('\r')) {
		    doubleByteData[index] = MAKEWCHAR(' ');
		}
		index++;
	    }
	    return TCL_OK;
	}
#endif
	pos = len - 1;
	while (pos >= lenRead) {
	    data[pos] = '\0';
	    pos--;
	}
#if defined(_MSDOS) || defined(_WIN32)
	while (lenRead-- > 0) {
	    if (data[index] == '\r') {
		data[index] = ' ';
	    }
	    index++;
	}
#endif
	return TCL_OK;
    }

    /*
     * Compute the size of the line in the file
     */
    i = f->posArray[line] - f->posArray[line-1];

    /*
     * Assume we'll need that much space (i.e. no tabs)
     */
    buf = Buf_Init(i);

    /*
     * Allocate a buffer to read the whole line in, then read it.
     */
    inputbuf = (char *)malloc(i);
    (void)SrcSJISSafeRead(f->file, inputbuf, i, &cc);

    for (cp = inputbuf, i = 0;
	 cc > 0 && (*cp != '\n') && (*cp != '\r');
	 cp++, cc--)
    {
	if (*cp == '\t') {
	    /*
	     * Expand tabs to spaces (8-space tabs) so caller can
	     * properly figure the line length.
	     */
	    int	n = 8 - (i & 7);
	    
	    Buf_AddBytes(buf, n, (Byte *)"        ");
	    i += n;
	} else {
	    Buf_AddByte(buf, (Byte)(*cp));
	    i++;
	}
    }
    Tcl_Return(interp, (char *)Buf_GetAll(buf, NULL), TCL_DYNAMIC);
    Buf_Destroy(buf, FALSE);
    free ((malloc_t)inputbuf);

    return(TCL_OK);
}


/*********************************************************************
 *			UpcaseString
 *********************************************************************
 * SYNOPSIS:	put a null terminated string into upper case
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	9/14/94		Initial version			     
 * 
 *********************************************************************/
char *
UpcaseString(char *str)
{
    char    *s = str;

    if (s == NULL) return NULL;

    while(*s) 
    {
	*s = toupper(*s);
	s++;
    }
    return str;
}

/*********************************************************************
 *			SrcOpenFileForCurPatient
 *********************************************************************
 * SYNOPSIS: 	    open the file for the current patient
 * CALLED BY:	    various SRC routines
 * RETURN:
 * SIDE EFFECTS:    caches the file handle if new
 * STRATEGY:	    if not a full path prepend the patient's path to it
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	3/16/93		Initial version			     
 * 
 *********************************************************************/
static SrcFile *
SrcOpenFileForCurPatient(char *file, Cache_Entry *entry, Boolean *new)
{
    SrcFile 	*f;
    char    	*buf;
    int	    	must_free = 0;
    int         returnCode;
#if defined(_MSDOS) || defined(_WIN32) || defined(_LINUX)
    char    	    *inst_path;
#endif
#if defined(_WIN32)
	char	filebuf[MAX_FILE_NAME];
	char	*filetmp;
#endif

    buf	 = file;
#if !defined(_MSDOS) && !defined(_WIN32)
    if (file[0] != '/')
#else
    if (file[0] != '/' && file[0] != '\\' && file[1] != ':')
#endif
    {
	char	*bp;

#if defined(_MSDOS)
	char	*fPtr;

	fPtr = file;
	while(*fPtr)
	{
	    if (islower(*fPtr)) {
		*fPtr = toupper(*fPtr);
	    }
	    fPtr++;
	}
#endif
	/* try to append the patients pathname to it */
	bp = strrchr(curPatient->path, '/');
	*bp = '\0';
	buf = malloc(strlen(curPatient->path)+strlen(file)+2);
	sprintf(buf, "%s/%s", curPatient->path, file);
	*bp = '/';
	must_free = 1;
    }

#if defined(_MSDOS) || defined(_WIN32) || defined(_LINUX)
	    /* if there is a local tree, and the path is in the local tree
	     * try looking in the installed tree
	     */
    {
#if defined(_WIN32)
	/* 
	 * switch from unix to dos file names
	 */
	if (strncmp(buf, "/staff", 6) == 0) {
	    (void)File_MapUnixToDos(filebuf, buf, "s:/");
	    filetmp = filebuf;
	} else {
	    filetmp = buf;
	}
	if (access(filetmp, R_OK) != 0) {
#else
	if (access(buf, R_OK) != 0) {
#endif
	    const char	*plr;
	    
	    plr = Tcl_GetVar(interp, "file-devel-dir", TRUE);
	    if (plr != NULL) {
		char    localRoot[256];
		char    *lr;
		int     lr_len;

		strcpy(localRoot, plr);
#if defined(_MSDOS)
		UpcaseString(localRoot);
#endif
		lr = localRoot;
		while(*lr != '\0') {
		    if (*lr == '\\') {
			*lr = '/';
		    }
		    lr++;
		}

		lr_len = strlen(lr);
		if (!strncmp(buf, lr, lr_len)) {
		    const char *prd;
		    
		    prd = Tcl_GetVar(interp, "file-root-dir", TRUE);
		    if (prd != NULL) {
			char rootDir[256];
			char *rd;
			
			strcpy(rootDir, prd);
#if defined(_MSDOS)
			UpcaseString(rootDir);
#endif
			rd = rootDir;
			inst_path = malloc(strlen(rd) + 
					   strlen(buf+lr_len) + 2);
			sprintf(inst_path, "%s%s", rd, buf+lr_len);
			lr = strrchr(inst_path, '\\');
			while(lr != NULL) {
			    *lr = '/';
			    lr = strrchr(lr, '\\');
			}
			if (must_free) {
			    free(buf);
			}
			buf = inst_path;
			must_free = 1;
		    }
		}
	    }
	}
    }		    
#endif
    
    *entry = Cache_Enter(fileCache, (Address)buf, new);
    if (*new) 
    {
	f = (SrcFile *)malloc_tagged(sizeof(SrcFile), TAG_FILE);
#if defined(_WIN32)
	/* 
	 * switch from unix to dos file names if necessary
	 */
	if (strncmp(buf, "/staff", 6) == 0) {
	    (void)File_MapUnixToDos(filebuf, buf, "s:/");
	    filetmp = filebuf;
	} else {
	    filetmp = buf;
	}
	returnCode = FileUtil_Open(&(f->file), filetmp, O_RDONLY|O_TEXT, 
				  SH_DENYNO, 0);
#else
	returnCode = FileUtil_Open(&(f->file), buf, O_RDONLY|O_TEXT, 
				  SH_DENYNO, 0);
#endif
	if (returnCode == FALSE) {
	    Cache_InvalidateOne(fileCache, *entry);
	    free((char *)f);
	    if (must_free) {
		free(buf);
	    }
	    return NULL;
	}
	f->mtime = FileUtil_GetTime(f->file);
	if (f->mtime < 0) {
	    free((char *)f);
	    if (must_free) {
		free(buf);
	    }
	    return NULL;
	}
	f->posArray = NULL;
	f->num_lines = SrcGetLineInfo(f);

        Cache_SetValue(*entry, f);
    }
    else
    {
	f = Cache_GetValue(*entry);
    }
    if (must_free)
    {
       free(buf);
    }
    return f;
}



/*********************************************************************
 *			SrcSize
 *********************************************************************
 * SYNOPSIS: 	gets the number of lines of a source file
 * CALLED BY:	Src_TclCmd
 * RETURN:  	tcl returns the number of lines of the file as a string
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	1/12/93		Initial version			     
 * 
 *********************************************************************/

static int
SrcSize(Tcl_Interp  *interp,
	char 	    *sourcefile)
{
    int    	    lines;
    Cache_Entry	    entry;
    Boolean	    new;
    SrcFile 	    *f;
    char    	    buf[12];

    f = SrcOpenFileForCurPatient(sourcefile, &entry, &new);
    if (f == NULL)
    {
	SrcTclReturnFileError(sourcefile);
	return(TCL_ERROR);
    }
    lines = f->num_lines;
    sprintf(buf, "%ld", (long int)lines);
    Tcl_Return(interp, buf, TCL_VOLATILE);
    return (TCL_OK);
}


/***********************************************************************
 *				SrcCmd
 ***********************************************************************
 * SYNOPSIS:	    "src" command for handling source mapping
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK and others
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 3/90		Initial Revision
 *
 ***********************************************************************/
#define SRC_LINE    (ClientData)0
#define SRC_READ    (ClientData)1
#define SRC_CACHE   (ClientData)2
#define SRC_ADDR    (ClientData)3
#define SRC_FLUSH   (ClientData)4
#define SRC_SIZE   (ClientData)5

static const CmdSubRec srcCmds[] = {
    {"line", 	SRC_LINE,   1, 2, "<addr> [<frame>]"},
    {"read", 	SRC_READ,   2, 3, "<file> <line> [<size>]"},
    {"cache",	SRC_CACHE,  0, 1, "[<max>]"},
    {"addr", 	SRC_ADDR,   2, 3, "<file> <line> [<patient>]"},
    {"flush",	SRC_FLUSH,  0, 0, ""},
    {"size", 	SRC_SIZE,   1, 1, "<file>"},
    {NULL,   	(ClientData)NULL,	    0, 0, NULL}
};

DEFCMD(src,Src,TCL_EXACT,srcCmds,swat_prog,
"Usage:\n\
    src line <addr> [<frame>]\n\
    src read <file> <line>\n\
    src cache [<max>]\n\
    src addr <file> <line> [<patient>]\n\
    src flush\n\
    src size <file>\n\
\n\
Examples:\n\
    \"src line cs:ip\"		Returns a two-list holding the source-line\n\
	    	    	    	number, and the absolute path of the file in\n\
	    	    	    	which it lies (not in this order), that\n\
				encompasses cs:ip.\n\
    \"src read /staff/pcgeos/Library/Kernel/Thread/threadThread.asm 64\"\n\
	    	    	    	Reads the single given source line from the\n\
				given file.\n\
    \"src addr icdecode.c 279\"	Returns an address-list for the start of the\n\
	    	    	    	code produced for the given line.\n\
    \"src cache 10\"		Allow 10 source files to be open at a time.\n\
				This is the default\n\
    \"src flush\"			Close all source files Swat has open.\n\
    \"src size blorg.goc\"  	returns number of lines of source code in\n\
 	    	    	    	the source file blorg.goc\n\
\n\
Synopsis:\n\
    The \"src\" command allows the Tcl programmer to manipulate the source-\n\
    line maps contained in all the geodes' symbol files.\n\
\n\
Notes:\n\
    * The \"src line\" commands returns its list as {<file> <line>}, with\n\
      the <file> being absolute. If no source line can be found, the empty\n\
      list is returned. The optional <frame> argument is the frame from which\n\
      the address comes, providing the necessary XIP context for mapping the\n\
      address to the proper source line.\n\
\n\
    * The <file> given to the \"src read\" command must be absolute, as the\n\
      procedure using this command may well be wrong as to Swat's current\n\
      directory. Typically this name will come from the return value of\n\
      a \"src line\" command, so you needn't worry.\n\
\n\
    * The line returned by \"src read\" contains no tabs and does not include\n\
      the line terminator for the line (the <lf> for UNIX, or the <cr><lf>\n\
      pair for MS-DOS).\n\
\n\
    * \"src addr\" returns an address-list, as returned from \"addr-parse\",\n\
      not an address expression, as you would *pass* to \"addr-parse\". If\n\
      the <file> and <line> cannot be mapped to an address, the result will\n\
      be the empty list.\n\
\n\
    * The <file> given to \"src addr\" must be the name that was given\n\
      to the assembler/compiler. This includes any leading path if the file\n\
      wasn't in the current directory when the assembler/compiler was run.\n\
\n\
    * \"src cache\" returns the current (or new) number of open files that\n\
       are cached.\n\
\n\
    * Swat flushes its cache of open source files when you detach from the\n\
      target machine, but if you need to get to or modify a source file while\n\
      still attached, use the \"src flush\" command to force Swat to close,\n\
      and thereby release, all the source files it has open.\n\
")
{
    switch((int)clientData) {
	case SRC_LINE:
	    if (argc == 4) {
		Frame	*f = (Frame *)atoi(argv[3]);

		if (!VALIDTPTR(f, TAG_FRAME)) {
		    Tcl_RetPrintf(interp, "%.50s: invalid frame", argv[3]);
		    return(TCL_ERROR);
		}

		return SrcMapAddr(interp, argv[2], f);
	    } else {
		return SrcMapAddr(interp, argv[2], NullFrame);
	    }
	case SRC_READ:
	    if (argc == 4) {
		return Src_ReadLine(interp, argv[2], argv[3], NULL, NULL,
				    NULL);
	    }
#if 0
	    else
		return Src_ReadLine(interp, argv[2], argv[3], argv[4],
				    NULL, NULL);
#endif
	case SRC_CACHE:
	    if (argc > 2) 
	    {
		int 	n = atoi(argv[2]);

		if (n < 1) {
		    n = 1;
		}
		Cache_SetMaxSize(fileCache, n);
	    }
	    Tcl_RetPrintf(interp, "%d", Cache_MaxSize(fileCache));
	    break;
	case SRC_ADDR:
	{
	    Handle  	    handle;
	    word    	    offset;
	    Patient 	    patient;

	    if (argc == 5) {
		patient = (Patient)atoi(argv[4]);
	    } else {
		patient = curPatient;
	    }

	    if (!Src_FindLine(patient, argv[2], atoi(argv[3]),
			     &handle, &offset) &&
		(defaultPatient == NULL ||
		 malloc_tag((char *)defaultPatient) != TAG_PATIENT ||
		 !Src_FindLine(defaultPatient, argv[2], atoi(argv[3]),
			      &handle, &offset)))
	    {
		Tcl_Return(interp, "", TCL_STATIC);
	    } else {
		Tcl_RetPrintf(interp, "%d %d nil", handle, offset);
	    }
	    break;
	}
	case SRC_FLUSH:
	    Cache_InvalidateAll(fileCache, TRUE);
	    break;
	case SRC_SIZE:
	    return SrcSize(interp, argv[2]);
    }
    return(TCL_OK);
}


/***********************************************************************
 *				SrcFlushCache
 ***********************************************************************
 * SYNOPSIS:	    Flush the source-line cache to avoid having wrong
 *	    	    positions should the user have remade a patient while
 *	    	    we were detached.
 * CALLED BY:	    EVENT_ATTACH
 * RETURN:	    EVENT_HANDLED
 * SIDE EFFECTS:    All entries are flushed from the cache.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/ 5/91		Initial Revision
 *
 ***********************************************************************/
static int
SrcFlushCache(Event 	event,	    /* Event that called us (UNUSED) */
	      Opaque	callData,   /* Nothing, really (UNUSED) */
	      Opaque	clientData) /* Data we bound to the event (UNUSED) */
{
    /*
     * Nuke all the entries, calling the destroyProc we bound to the cache
     * for each one.
     */
    Cache_InvalidateAll(fileCache, TRUE);

    return(EVENT_HANDLED);
}


/***********************************************************************
 *				Src_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize handling of source files.
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    src command is added.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 4/90		Initial Revision
 *
 ***********************************************************************/
void
Src_Init(void)
{
    Cmd_Create(&SrcCmdRec);
    fileCache = Cache_Create(CACHE_LRU, SRC_MAX_FILES, CACHE_STRING,
			     SrcFileClose);
    /*
     * Set up a handler to flush the whole cache when we attach or detach, since
     * we can't go through the elements of the cache and only biff the ones
     * that pertain to a particular patient when it gets destroyed...
     */
    (void)Event_Handle(EVENT_ATTACH, 0, SrcFlushCache, NullOpaque);
    (void)Event_Handle(EVENT_DETACH, 0, SrcFlushCache, NullOpaque);
}
