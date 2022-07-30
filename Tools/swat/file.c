/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- File Location routines
 * FILE:	  file.c
 *
 * AUTHOR:  	  Adam de Boor: May 18, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	File_FindGeode	    Locate a geode of a given name and serial number
 *	    	    	    and type
 *	File_Locate 	    Locate a file of a given name on a search path
 *	File_Init   	    Initialize module.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/18/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	This file contains functions for locating files of various types.
 *	The places searched come from a config file, for the most part.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: file.c,v 4.47 97/05/27 16:29:13 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "file.h"
#include "geos.h"
#include "ui.h"
#include "cmd.h"
#include "help.h"
#include "ibmInt.h"

#include <stddef.h>
#include <sys/types.h>
#include <stdarg.h>

#if defined(unix)
# include <sys/dir.h>
#else
# if defined(_WIN32)
#  undef FIXED
#  undef LONG
#  define LONG LONG_biff
#  define SID SID_biff
#  define timeval timeval_biff
#  undef timercmp
#  define timercmp timercmp_biff
#  define fd_set fd_set_biff
# endif
# include <compat/dirent.h>
# if defined(_WIN32)
#  undef fd_set
#  undef timercmp
#  undef timeval
#  undef SID
#  undef LONG
#  define FIXED 0x80
# endif
#endif

#include <compat/file.h>
#include <compat/stdlib.h>

#if defined(_MSDOS) /* || defined(_WIN32) */
# include <share.h>
# include <dir.h>
#endif

#if defined(_MSDOS)
# include <stat.h>
#else
# include <sys/stat.h>
#endif

#if defined(_WIN32)
# include <winutil.h>
#endif

#if defined(_MSDOS)
# include <dos.h>
#endif

#if defined(_WIN32)
# define _chdir(a) chdir(a)
# define _getcwd(a,b) getcwd(a,b)
#endif

#if defined(_MSDOS) || defined(_WIN32)
# define CONFIG_SUFFIX "conf"
#else
# define CONFIG_SUFFIX "conf"
#endif

extern	Boolean symCache;
extern	Boolean ignoreSymSerial;
extern  int COLS;
#include <ctype.h>

 	/* used in FileGeodeMatches */
static	    Boolean 	userAsked = FALSE;

long int	    fileNumTypes=0; 	/* Number of geode types for which paths
				 * are defined */
CONST char  **fileDirs;	    	/* Pointers to the paths for the various
				 * types */
CONST char  *fileRoot;	    	/* Root of whole tree */
CONST char  *fileDevel;	    	/* Root of development tree */
CONST char  *fileGym;	    	/* Location of .gym files */
CONST char  *fileDefault;   	/* Subdirectory w/ default geodes */
CONST char  *fileSysLib;    	/* System library directory, from
				 * config file */
CONST char  *fileAbsSysLib;    	/* System library dir, absolute */
char	fileBranch[100];   	/* Branch the user is using */

char	    cwd[1024];	    	/* Initial working directory */
#if defined(_WIN32)
/*
 * set aside space for the above strings
 */
char	    fileRootAlloc[1024];
char	    fileDevelAlloc[1024];
char	    fileGymAlloc[1024];
char	    fileDefaultAlloc[1024];
char	    fileSysLibAlloc[1024];
char	    fileAbsSysLibAlloc[1024];

#endif

int	    gymResources=0;
typedef struct _FileConfigEntry {
    struct _FileConfigEntry *next;
    char    	    	    *key;
    char    	    	    *value;
} FileConfigEntry;

typedef enum { NO, MAYBE, YES } FileMatch;
typedef FileMatch FileMatchProc(char *path,CONST char *name,word serial);

static FileConfigEntry	*fileConfigData = 0;

static char *GeodeSearchTree (
	         CONST char *dir,	/* directory to search		   */
		 CONST char *name,	/* name to find			   */
		 int	bNEC);		/* do we want the Non-EC .geo file */

static int strncmp_path(char *path1, char *path2, int n);

#if defined(unix) || defined(_LINUX)
# define STRNCMP_OS_SPECIFIC strncmp
# define STRCMP_OS_SPECIFIC strcmp
#elif defined(_WIN32)
# define STRNCMP_OS_SPECIFIC strnicmp
# define STRCMP_OS_SPECIFIC strcmpi
#else
# define STRNCMP_OS_SPECIFIC strncmpi
# define STRCMP_OS_SPECIFIC strcmpi
#endif

#define GEODE_PATH_SIZE     256         /* max size of path in symdir file */



/***********************************************************************
 *				File_PathConcat
 ***********************************************************************
 * SYNOPSIS:	    Take a number of separate path components and merge
 *	    	    them into a single path, coping with root directories,
 *	    	    empty components, and other such things.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    dynamically-allocated result
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/95	Initial Revision
 *
 ***********************************************************************/
CONST char *
File_PathConcat (CONST char *first, ...)
{
    va_list 	args;
    char    	*result;
    unsigned	len, cplen;
    CONST char 	*cp;
    char    	*cp2;

    /*
     * First compute the required length. We start len out at 1 to cope
     * with being given a single real component that is the root
     * directory, when we need to leave the final path separator that
     * we'd otherwise biff. So we waste a byte in most cases, but
     * we're happy otherwise.
     */
    va_start(args, first);

    for (len = 1, cp = first; cp != 0; cp = va_arg(args, char *)) {
	/*
	 * Add the length of the next component.
	 */
	cplen = strlen(cp);
	len += cplen;

	/*
	 * If the component was non-empty and didn't end with the path
	 * separator, make room to store the separator (or final null, if
	 * this is the final component)
	 */
	if ((cplen > 0)
	    && (cp[cplen-1] != '/')
#if !defined(unix)
	    && (cp[cplen-1] != '\\')
#endif
	    ) {
	    len += 1;
	}
    }

    va_end(args);

    /*
     * Allocate the room, please.
     */
    cp2 = result = (char *)malloc(len);

    /*
     * Reprocess the arguments to copy the components in.
     */
    va_start(args, first);

    for (cp = first; cp != 0; cp = va_arg(args, char *)) {
	/*
	 * Copy the next component.
	 */
	cplen = strlen(cp);
	memcpy(cp2, cp, cplen);
	cp2 += cplen;

	/*
	 * If the component is non-empty and doesn't end in the separator,
	 * store the separator at the end.
	 */
	if ((cplen > 0)
	    && (cp2[-1] != '/')
#if !defined(unix)
	    && (cp2[-1] != '\\')
#endif
	    ) {
#if defined(unix)
	    *cp2++ = PATHNAME_SLASH;
#else
	    *cp2++ = (strchr(cp, '/') != NULL) ? '/' : '\\';
#endif
	}
    }

    /*
     * Overwrite the final separator with a null char.
     */
    cp2[-1] = '\0';

    /*
     * Cope with ending up with the root directory, under whatever OS.
     */
#if defined(_MSDOS) || defined(_WIN32)
    if ((cp2 == (result + 3)) && (result[1] == ':')) {
	/*
	 * Have just a drive specifier now: put the backslash back and
	 * null-terminate.
	 */
	cp2[-1] = PATHNAME_SLASH;
	*cp2 = '\0';
    }
#endif

    if (cp2 == (result + 1)) {
	/*
	 * Have root directory (no drive spec for DOS), so put it back.
	 */
	cp2[-1] = PATHNAME_SLASH;
	*cp2 = '\0';
    }

    va_end(args);

    return(result);
}


#if defined(_MSDOS) || defined(_WIN32)
/***********************************************************************
 *				FileMapSeparators
 ***********************************************************************
 * SYNOPSIS:	    Map path separators from one convention to another.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    all occurrences of the one separator are changed to
 *	    	    	the other within the passed string.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/95	Initial Revision
 *
 ***********************************************************************/
static void
FileMapSeparators(char *path, char from, char to)
{
    for (path = strchr(path, from);
	 path != 0;
	 path = strchr(path, from))
    {
	*path = to;
    }
}
#endif	/* _MSDOS || _WIN32 */


#if defined(_WIN32)
/***********************************************************************
 *				File_MapUnixToDos
 ***********************************************************************
 * SYNOPSIS:	    Map unix path to dos replacing /staff with equivalent
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    whether it was successful
 * SIDE EFFECTS:    result string is set(space must already be allocated)
 *
 * STRATEGY:	    replace /staff, but if no registry entry for what to
 *		    substitute it with, use defaultSubst, else return
 *		    FALSE
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	02/03/97	Initial Revision
 *
 ***********************************************************************/
Boolean
File_MapUnixToDos(char *dosPath, CONST char *unixPath,
		  CONST char *defaultSubst)
{
    CONST char *fileStaffPath;
    char *cp;
    char *prefix;

    if (strncmp(unixPath, "/staff", 6) != 0) {
	return FALSE;
    }

    fileStaffPath = Tcl_GetVar(interp, "file-staff-path", TRUE);
    if (*fileStaffPath == '\0') {
	if ((defaultSubst == NULL) || (defaultSubst[0] == '\0')) {
	    return FALSE;
	} else {
	    fileStaffPath = defaultSubst;
	}
    }
    prefix = (char *)malloc((sizeof(char)) * (strlen(fileStaffPath) + 1));
    if (prefix == NULL) {
	return FALSE;
    } else {
	strcpy(prefix, fileStaffPath);
    }
    /*
     * now we have a subst string, we need to check for a slash
     * at the end of the string and get rid of it if there
     */
    cp = strrchr(prefix, '/');
    if (strrchr(prefix, '\\') > cp) {
	cp = strrchr(prefix, '\\');
    }
    if (strchr(prefix, '\0') == cp + 1) {
	*cp = '\0';
    }
    sprintf(dosPath, "%s%s", prefix, unixPath + 6);
    free(prefix);
    return TRUE;
}
#endif	/* _WIN32 */

/***********************************************************************
 *				FileAskUser
 ***********************************************************************
 * SYNOPSIS:	    Prompt the user for the location of an executable
 * CALLED BY:	    File_FindGeode
 * RETURN:	    NULL if user refuses to say, else the dynamically
 *	    	    allocated path to the file.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/14/89		Initial Revision
 *
 ***********************************************************************/
static char *
FileAskUser(CONST char 	*name,	    /* Name of patient */
	    Boolean 	maydetach,  /* Non-zero if "detach" command allowed
				     * in response */
	    Boolean 	mayignore)  /* Non-zero if "ignore" command allowed
				     * in response */
{
    char    	cmd[80];
    char    	*res;

    sprintf(cmd, "file-err {%s} %d %d", name, maydetach, mayignore);

    if (Tcl_Eval(interp, cmd, 0, 0) != TCL_OK) {
	/*
	 * Error -- return NULL
	 */
	return((char *)NULL);
    } else if (*interp->result != '\0') {
	/*
	 * Make copy of result.
	 */
	res = (char *)malloc(strlen(interp->result) + 1);
	strcpy(res, interp->result);
	return(res);
    } else {
	/*
	 * Empty return => ignore/detach -- return NULL to signal
	 */
	return((char *)NULL);
    }
}

#if !defined(_MSDOS) && !defined(_WIN32)
# define GYM_CHAR 'g'
# define SYM_CHAR 's'
char CONST sym_ext[5] = ".sym";
char CONST gym_ext[5] = ".gym";
#else
# define GYM_CHAR 'G'
# define SYM_CHAR 'S'
char CONST sym_ext[5] = ".SYM";
char CONST gym_ext[5] = ".GYM";
#endif

/***********************************************************************
 *				FileGeodeMatches
 ***********************************************************************
 * SYNOPSIS:	    See if a file matches the indicated geode
 * CALLED BY:	    FileSearchTree, File_FindGeode
 * RETURN:	    NO if path cannot possibly be used (different name
 *	    	    or missing a .map or .tcl file), MAYBE if everything
 *	    	    but serial number matches, YES if matches in all
 *	    	    particulars.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/14/89		Initial Revision
 *
 ***********************************************************************/
static FileMatch
FileGeodeMatches(char	    *filePath,  /* File to check */
		 CONST char *name,  /* Permanent name of geode */
		 word	serial)	    /* Serial number of geode (same byte-order
				     * as the executable) */
{
    GeodeName  	gn; 	    	/* Name & serial number from the executable */
    FileType 	fd; 	    	/* General-purpose file descriptor, for reading
				 * from the executable & the .sym/.gym file */
    char    	*suffix;    	/* Start of the file's suffix. */
    int	    	haveGeode=0;	/* Non-zero if we've got a .geo file to
				 * consult */
    char    	cp, *cptr;
    char    	permName[32];	/* Buffer into which first part of the user
				 * notes is read when seeing if a .sym or .gym
				 * file is compatible with the geode for
				 * which we're looking */
    char    	osuff[8];   	/* Place to store original suffix, since we
				 * mangle it when looking for symbol files */
    int    	maybe=0;
    int	    	notEC=2;
    int         returnCode;
    long        numRead = 0;
    char	*path;

    /*
     * allocate a larger space in case we need to append a suffix onto
     * the end of the path
     */
    path = (char *)malloc((strlen(filePath) + 5) * sizeof(char));
    strcpy(path, filePath);

    suffix = rindex(path, '.');
    if (suffix == NULL) {
	suffix = path + strlen(path);
	osuff[0] = '\0';
    } else {
	/* save the original suffix plus the ec */
	strncpy(osuff, suffix-2, sizeof(osuff));
    }
    *suffix++ = '.';
    /*
     * Check for sym file.
     */

    /* if we are told to look for a sym file or gym file specifically then
     * remember which one it is, if we are told to look for a geo file then
     * start out looking for the sym file
     */
    if (STRCMP_OS_SPECIFIC(suffix, "geo") == 0) {
	cp = SYM_CHAR;
    } else {
	cp = suffix[0];
#if defined(_WIN32)
	if ((tolower(cp) == tolower(GYM_CHAR))
	    && ((suffix - path) > 2)
	    && !(STRNCMP_OS_SPECIFIC(&suffix[-2], "c", 1))
	    && !(STRNCMP_OS_SPECIFIC(&suffix[-3], "e", 1))) {
#else
# if defined(_MSDOS)
	cp = toupper(cp);
# endif
	if (cp == GYM_CHAR && suffix[-2] == 'c' && suffix[-3] == 'e') {
#endif
	    suffix[-3] = '.';
	    suffix -= 2;
	}
    }

    suffix[0] = 'g';
    suffix[1] = 'e';
    suffix[2] = 'o';
    suffix[3] = '\0';

    returnCode = FileUtil_Open(&fd, path, O_RDONLY|O_BINARY, SH_DENYWR, 0);

    if (returnCode == TRUE) {
	haveGeode = 1;
	(void)FileUtil_Seek(fd, offsetof(GeodeHeader2, geodeFileType),
			    SEEK_SET);
	(void)FileUtil_Read(fd, (char *)&gn, sizeof(gn), &numRead);
	(void)FileUtil_Close(fd);
	/* if the permanent names are different we obviously have the wrong
	 * geode
	 */
	if (STRNCMP_OS_SPECIFIC(gn.name, name, 8)) {
	    free(path);
	    return NO;
	}
    }
    suffix[0] = cp;
    suffix[1] = 'y';
    suffix[2] = 'm';
    suffix[3] = '\0';

    returnCode = FileUtil_Open(&fd, path, O_RDONLY|O_BINARY, SH_DENYWR, 0);

#if defined(_WIN32)
    if ((returnCode == TRUE) && (tolower(cp) == tolower(SYM_CHAR))) {
#else
    if ((returnCode == TRUE) && (cp == SYM_CHAR)) {
#endif
	/* the criterion for accepting a symbol file are:
	 * a) if a geode in the same directory has the right serial # or
	 * b) if the serial number in the user notes of the symbol file
	 *	    itself match the serial # passed in and the permanent
	 *	    name matches the one passed in
	 */
	if (!haveGeode || gn.serial != serial) {
	    /* try reading the serial number from the user notes of
	     * the symbol file
	     */
	    (void)FileUtil_Seek(fd, offsetof(GeosFileHeader2, userNotes),
				SEEK_SET);
	    (void)FileUtil_Read(fd, permName, sizeof(permName), &numRead);
	    /* the first 17 characters are the permanent name followed
	     * by a colon
	     */
	    if (!STRNCMP_OS_SPECIFIC(permName, name, (ignoreSymSerial) ? 12 : 8)) {
	    if (ignoreSymSerial)
	    	gn.serial = serial;
	    else
			gn.serial = swaps(atoi(permName+17));
	    }
	}
	/* ok no acceptable sym file, try for a gym file */
	(void)FileUtil_Close(fd);
	if (gn.serial == serial) {
	    free(path);
	    return YES;
	}
	maybe = 1;
    }

#if defined(_WIN32)
    if (tolower(cp) == tolower(SYM_CHAR)) {
#else
    if (cp == SYM_CHAR) {
#endif
	free(path);
	return (maybe ? MAYBE : NO);
    }

    /* now try the gym file */
    suffix[0] = GYM_CHAR;

    /************************************
     * able to use NON ec gym files for ec versions of the geodes
     ************************************/
    if (suffix[-3] == 'e' && suffix[-2] == 'c') {
	strcpy(suffix-3, gym_ext);
	notEC=0;
    }

    /*
     * if cp == GYM_CHAR we have already opened the gym file
     */
#if defined(_WIN32)
    if (tolower(cp) != tolower(GYM_CHAR)) {
#else
    if (cp != GYM_CHAR) {
#endif
	returnCode = FileUtil_Open(&fd, path, O_RDONLY|O_BINARY,
				  SH_DENYWR, 0);
    }
    if (returnCode == FALSE) {
	/* no gym file so forget it */
	suffix = rindex(path, '.');
	strcpy(suffix-notEC, osuff);
	free(path);
	return (maybe ? MAYBE : NO);
    }
    /* we are dealing with a gym file, read in the pernament name and
     * serial number from the user notes field
     * the permanent name must be right to use a gym file, we don't care
     * about the serial number (so just use first 12 characters)
     */
    (void)FileUtil_Seek(fd, offsetof(GeosFileHeader2, userNotes), SEEK_SET);
    (void)FileUtil_Read(fd, permName, sizeof(permName), &numRead);
    (void)FileUtil_Close(fd);

    /* go to after the second ':'  */
    cptr = index(permName, ':');
    if (cptr != NULL) {
	cptr = index(cptr+1, ':');
    }
    if (cptr != NULL) {
	gymResources = atoi(cptr+1);
    }
    if (!STRNCMP_OS_SPECIFIC(name, permName, 8)) {
	free(path);
	return YES;
    }
    suffix = rindex(path, '.');
    strcpy(suffix-notEC, osuff);
    if (!maybe) {
	/* be sure to reset gymResources if we don't use if */
	gymResources = 0;
	free(path);
	return NO;
    }
    free(path);
    return MAYBE;
}


/***********************************************************************
 *				FileExeMatches
 ***********************************************************************
 * SYNOPSIS:	    See if a path leads to a kernel with the right
 *	    	    checksum.
 * CALLED BY:	    File_FindGeode
 * RETURN:	    TRUE if it does.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/18/89		Initial Revision
 *
 ***********************************************************************/
static FileMatch
FileExeMatches(char 	*path,
	       CONST char *name,
	       word serial)
{
    word       csum;
    FileType   fd;
    char       *suffix;
    int        returnCode;
    long int        numRead = 0;
    char       *cpyofpath;

    cpyofpath = (char *)malloc(strlen(path) + 4);
    strcpy(cpyofpath, path);

    suffix = rindex(cpyofpath, '.');
    if (suffix == NULL) {
	suffix = cpyofpath + strlen(cpyofpath);
    }
    *suffix++ = '.';
    /*
     * Check for sym file.
     */
    suffix[0] = 'e';
    suffix[1] = 'x';
    suffix[2] = 'e';
    suffix[3] = '\0';

    returnCode = FileUtil_Open(&fd, cpyofpath, O_RDONLY|O_BINARY, SH_DENYWR, 0);

    if (returnCode == TRUE) {
	
	/*
	 * Fetch out the checksum while we've got the file open.
	 */
	(void)FileUtil_Seek(fd, EXE_CSUM_OFF, SEEK_SET);
	(void)FileUtil_Read(fd, (unsigned char *)&csum, sizeof(csum), &numRead);
	(void)FileUtil_Close(fd);
    }

    /*
     * Look for a .sym file for the thing. It must exist before we accept
     * the cpyofpath as a valid kernel.
     */
    suffix = rindex(cpyofpath, '.');
    if (suffix == NULL) {
	suffix = cpyofpath + strlen(cpyofpath);
    }
    *suffix++ = '.';
    /*
     * Check for sym file.
     */
    suffix[0] = 's';
    suffix[1] = 'y';
    suffix[2] = 'm';
    suffix[3] = '\0';

    if ((access(cpyofpath, R_OK) < 0) || (serial != csum)) {
	suffix[0] = GYM_CHAR;
	if (access(cpyofpath, R_OK) < 0) {
	    if (csum == serial) {
		free(cpyofpath);
		return(YES);
	    }
	    free(cpyofpath);
	    return(NO);
	} else {
	    char    ln[9];

	    returnCode = FileUtil_Open(&fd, cpyofpath, O_RDONLY|O_BINARY,
				       SH_DENYWR, 0);
	    if (returnCode == TRUE) {
		(void)FileUtil_Seek(fd, offsetof(GeosFileHeader2, longName),
				    SEEK_SET);
		(void)FileUtil_Read(fd, ln, 8, &numRead);
		(void)FileUtil_Close(fd);
		if (!STRNCMP_OS_SPECIFIC(ln, name, strlen(name))) {
		    free(cpyofpath);
		    return(YES);
		} else {
		    if (csum == serial) {
			free(cpyofpath);
			return(YES);
		    }
		    free(cpyofpath);
		    return (NO);
		}
	    }
	    free(cpyofpath);
	    return (NO);
	}
    }
    free(cpyofpath);
    return(YES);
}

/***********************************************************************
 *				FileCheckHack
 ***********************************************************************
 * SYNOPSIS:	    Perform a quick and dirty check of the given tree
 *	    	    based on the knowledge that things tend to be in
 *	    	    a subdirectory of the top-most whose name is the
 *	    	    permanent name with the first letter upcased.
 * CALLED BY:	    File_FindGeode.
 * RETURN:	    Permanent copy of found path, if geode is there.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 2/90		Initial Revision
 *
 ***********************************************************************/
static char *
FileCheckHack(CONST char    *dir,   	    /* Top-level directory */
	      char  	    *name,  	    /* Permanent name to find */
	      word  	    serial, 	    /* Serial number */
	      char  	    *want,  	    /* Suffix desired */
	      FileMatchProc *check, 	    /* Function to call to check */
	      int   	    ecGeode)	    /* are we lookinng for EC? */
{
    char    	    path[1024];
    char    	    *cp, *cp2;
    int	    	    i;
    int	    	    len;

    /*
     * First form the directory name by upcasing the first letter of the
     * permanent name.
     */
    (void)strcpy(path, dir);

    cp = &path[strlen(path)];
    *cp++ = PATHNAME_SLASH;
    cp2 = name;
    if (islower(*cp2)) {
	*cp++ = toupper(*cp2);
    } else {
	*cp++ = *cp2;
    }

    for (cp2++, i = GEODE_NAME_SIZE-1, len = 1;
	 !isspace(*cp2) && i > 0;
	 cp2++, i--, len++)
    {
	*cp++ = *cp2;
    }
    *cp++ = PATHNAME_SLASH;

    /*
     * Now form the file name by downcasing every letter of the permanent
     * name.
     */
    for (cp2 = name, i = GEODE_NAME_SIZE; !isspace(*cp2) && i > 0; cp2++, i--) {
	if (isupper(*cp2)) {
	    *cp++ = tolower(*cp2);
	} else {
	    *cp++ = *cp2;
	}
    }

    if (ecGeode) {
#if !defined(_MSDOS)
	sprintf(cp, "ec%s", want);
#else
	/* check to see if the last letter was changed to 'e' for 8 letter
	 * permanament named geodes as that's what the PC SDK does
	 */
	if (len == 8) {
	    char    oldcp;

	    oldcp = *(cp-1);
	    sprintf(cp-1, "e%s", want);
	    if (access(path, R_OK) != 0) {
		*(cp-1) = oldcp;
		sprintf(cp, "%.*s%s", 8-len, "ec", want);
	    }
	} else {
	    sprintf(cp, "%.*s%s", 8-len, "ec", want);
	}
#endif
    }
    else
    {
	strcpy(cp, want);
    }
    if ((access(path, R_OK) == 0) && ((*check)(path, name, serial) == YES)) {
	cp = (char *)malloc_tagged(strlen(path)+1, TAG_PNAME);
	strcpy(cp, path);

	return(cp);
    }

    if (want[1] == 'e' || want[1] == 'E') {
	return(NULL);
    }

#if 0
    /* for gym files EC and NON EC are the same */
    want[1] = GYM_CHAR;
    if (ecGeode) {
#if !defined(_MSDOS)
	sprintf(cp, "ec%s", want);
#else
	sprintf(cp, "%.*s%s", 8-len, "ec", want);
#endif
    }
    else
    {
	strcpy(cp, want);
    }
    want[1] = SYCHAR;
    if ((access(path, R_OK) == 0) && ((*check)(path, name, serial) == YES)) {
	cp = (char *)malloc_tagged(strlen(path)+1, TAG_PNAME);
	strcpy(cp, path);

	return(cp);
    }
#endif
    return(NULL);
}


/***********************************************************************
 *				FileSearchTree
 ***********************************************************************
 * SYNOPSIS:	    Search a directory tree for the proper .geo file
 * CALLED BY:	    File_FindGeode
 * RETURN:	    the path to the .geo file or NULL if not found
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	We attempt to classify files in a directory by their suffix
 *	    to avoid going to the filesystem to get the actual type.
 *	    Directories are assumed to not have any suffix.
 *	Any .geo file is opened and its header examined to see if it's
 *	    the desired file.
 *	Any file that doesn't have a suffix (and isn't Makefile) is
 *	    checked to see if it's a directory and is processed
 *	    recursively if it is.
 *	We first go through the directory looking for a specific suffix
 *	Then we go through looking for gym files and then we go
 *	through looking for subdirectories to recurse to, this insures that
 *	when we are looking for a sym file, we don't find a gym file for it
 *	first and its still nice and speedy
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/15/88	Initial Revision
 *
 ***********************************************************************/
static char *
FileSearchTree(CONST char    	*dir,       /* Directory to search */
	       CONST char    	*name, 	    /* Name to find */
	       word 	    	serial,     /* Serial number */
	       CONST char    	*want,      /* Suffix desired */
	       FileMatchProc 	*check,	    /* Function to call to check */
	       Boolean	    	recurse)    /* should we recurse */
{
    DIR	    	    *dirp;  	/* Current directory */
    CONST struct direct *dp;   	/* Current entry */
    CONST char 	    *suffix;	/* Suffix of current */
    char    	    *cp;    	/* general-purpose pointer (bad!) */
    char    	    path[1024];	/* Path for .geo or directory */
    char    	    *tail;  	/* Where to put the tail (in path) */
    CONST char 	    *tdir=dir; 	/* save the original dir */
    int	    	    uiInterrupt=0; /* hold value from UI_Interrupt */

#if defined(_WIN32)
	/*
	 * problem: WIN32 opendir returns NULL when passed path+filename,
	 * instead of a directory with only the file.  Soln, strip off file
	 * name and have it search all files.  Slower of course.  Doesn't
	 * get called often tho
	 */

        char *cpDot, *cpSlash1, *cpSlash2, *cpSlash;

	cpDot = strrchr(dir, '.');
	if (cpDot != NULL) {
	    MessageFlush("...");
	    cpSlash1 = strrchr(dir, '\\');
	    cpSlash2 = strrchr(dir, '/');
	    if (cpSlash1 != NULL) {
		if (cpSlash2 != NULL) {
		    cpSlash = (cpSlash1 > cpSlash2) ? cpSlash1 : cpSlash2;
		} else {
		    cpSlash = cpSlash1;
		}
	    } else {
		cpSlash = cpSlash2;
	    }
	    if ((cpSlash != NULL) && (cpSlash < cpDot)) {
		*cpSlash = '\0';
	    }
	}
#endif

    dirp = opendir(dir);
    if (dirp == (DIR *)NULL) {
	return((char *)NULL);
    }

    for (tail = path; *dir != '\0'; *tail++ = *dir++) {
	;
    }
    *tail++ = PATHNAME_SLASH;

    /*
     * Use Ui_Interrupt() here, not Ui_CheckInterrupt(), as we're called
     * from Ibm_NewGeode, which disables interrupts, so as to avoid being
     * nailed while fetching data from the core block. We want the user to
     * be able to interrupt the search, though.
     */

    for (dp = readdir(dirp);
	 dp != 0 && !(uiInterrupt=Ui_Interrupt());
	 dp = readdir(dirp)) {
#if !defined(_WIN32)
	if (dp->d_fileno == 0) {
	    continue;
	}
	for (suffix = dp->d_name+strlen(dp->d_name);
#else
	if ((strcmp(dp->d_name, ".") == 0) ||
	    (strcmp(dp->d_name, "..") == 0)) {
	    continue;
	}
	for (suffix = dp->d_name+strlen(dp->d_name);
#endif
	     suffix > dp->d_name && *suffix != '.';
	     suffix--)
	{
	    ;
	}

	if (suffix > dp->d_name) {
	    if (STRCMP_OS_SPECIFIC(suffix, want) == 0) {
		strcpy(tail, dp->d_name);
		if ((*check)(path, name, serial) == YES) {
		    /*
		     * Found the file. Wheeeeee. Allocate the path
		     * in non-volatile storage, close the directory and
		     * return the proper path.
		     */
		    cp = (char *)malloc_tagged(strlen(path)+1, TAG_PNAME);
		    strcpy(cp, path);

		    closedir(dirp);
		    return(cp);
		}
	    }
	}
    }
    closedir(dirp);

    if (uiInterrupt) {
	return NULL;
    }

    /* we didn't find it, so lets go through and try to find a gym file */
    dir = tdir;

    dirp = opendir(dir);

    if (dirp == (DIR *)NULL) {
	return NULL;
    }

    for (tail = path; *dir != '\0'; *tail++ = *dir++) {
	;
    }
    *tail++ = PATHNAME_SLASH;

    for (dp = readdir(dirp); dp != 0 && !Ui_Interrupt(); dp = readdir(dirp)) {
#if !defined(_WIN32)
	if (dp->d_fileno == 0) {
	    continue;
	}
	for (suffix = dp->d_name+strlen(dp->d_name);
#else
	if ((strcmp(dp->d_name, ".") == 0) ||
	    (strcmp(dp->d_name, "..") == 0)) {
	    continue;
	}
	for (suffix = dp->d_name+strlen(dp->d_name);
#endif
	     suffix > dp->d_name && *suffix != '.';
	     suffix--)
	{
	    ;
	}

	if (suffix > dp->d_name) {
	    if (STRCMP_OS_SPECIFIC(suffix, gym_ext) == 0) {
		strcpy(tail, dp->d_name);
		if ((*check)(path, name, serial) == YES) {
		    /*
		     * Found the file. Wheeeeee. Allocate the path
		     * in non-volatile storage, close the directory and
		     * return the proper path.
		     */
		    cp = (char *)malloc_tagged(strlen(path)+1, TAG_PNAME);
		    strcpy(cp, path);

		    closedir(dirp);
		    return(cp);
		}
	    }
	}
    }
    /*
     * Sorry, dude.
     */
    closedir(dirp);

    if (recurse == FALSE) {
	return NULL;
    }
    dir = tdir;

    dirp = opendir(dir);

    if (dirp == (DIR *)NULL) {
	return NULL;
    }

    for (tail = path; *dir != '\0'; *tail++ = *dir++) {
	;
    }
    *tail++ = PATHNAME_SLASH;

    for (dp = readdir(dirp); dp != 0 && !Ui_Interrupt(); dp = readdir(dirp)) {
#if !defined(_WIN32)
	if (dp->d_fileno == 0) {
	    continue;
	}
	for (suffix = dp->d_name+strlen(dp->d_name);
#else
	if ((strcmp(dp->d_name, ".") == 0) ||
	    (strcmp(dp->d_name, "..") == 0)) {
	    continue;
	}
	for (suffix = dp->d_name+strlen(dp->d_name);
#endif
	     suffix > dp->d_name && *suffix != '.';
	     suffix--)
	{
	    ;
	}

	if ( (suffix <= dp->d_name) &&
	     (STRCMP_OS_SPECIFIC(dp->d_name, "Makefile") != 0) &&
	     (STRCMP_OS_SPECIFIC(dp->d_name, "RCS") != 0) &&
	     (dp->d_name[0] != '.'))
	{
	    /*
	     * Form the path to the file and recurse (it's probably faster
     	     * to open the file, then find it's not a directory, than to
	     * stat every file and then open the directories).
	     */
	    strcpy(tail, dp->d_name);
	    cp = FileSearchTree(path, name, serial, want, check, TRUE);

	    if (cp != (char *)NULL) {
		/*
		 * Success! Close this directory and return the result up
		 * the call chain.
		 */
		closedir(dirp);
		return(cp);
	    }
	}
    }
    /*
     * Sorry, dude.
     */
    closedir(dirp);

    return((char *)NULL);
}

/*********************************************************************
 *			FileCacheSymDir
 *********************************************************************
 * SYNOPSIS: 	cache a sym directory
 * CALLED BY:	File_FindGeode
 * RETURN:
 * SIDE EFFECTS:    _WIN32 - in result string '\\''s are converted to '/'
 * STRATEGY:	    we write out directories where we find sym files for
 *	    	    geodes so we can find them quickly the next time we
 *	    	    need them
 *	    	    they are maintained in files called symdir.<num> where
 *	    	    <num> is a number that corresponds to the geode type
 *	    	    	1 = appplication
 *	    	    	2 = library
 *	    	    	3 = driver
 *	    	    	4 = loader/other
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	4/15/94		Initial version
 *
 *********************************************************************/
void
FileCacheSymDir(CONST char *sdfilename, char *name, char *result)
{
    FileType  sdfile;
    char      *cp2;
    char      symEntry[GEODE_NAME_SIZE + GEODE_PATH_SIZE + 4];
    int       returnCode;
    long int  numWrit;
    char      lastBytes[2];
    long      bytesRead;
#if defined(_WIN32)
    char      *cp3;
    char      spacePaddedName[9];
    int	      i;
#endif

    /* make sure we have something to cache */
    if (result && symCache == TRUE) {
	returnCode = FileUtil_Open(&sdfile, sdfilename, O_RDWR|O_TEXT|O_CREAT,
				   SH_DENYWR, 0666);

	if (returnCode == TRUE)	{
	    int pos = FileUtil_Seek(sdfile, -1L, SEEK_END);
	    returnCode = FileUtil_Read(sdfile, lastBytes, 1, &bytesRead);
	    if (returnCode == TRUE) {
		(void)FileUtil_Seek(sdfile, pos + 1, SEEK_SET);

		if ((lastBytes[0] != '\n') && (bytesRead > 0)) {
		    /*
		     * if there isn't a newline at the end of the last line
		     * add one now
		     */
#if defined(_WIN32)
		    lastBytes[0] = '\r';
		    lastBytes[1] = '\n';
		    (void)FileUtil_Write(sdfile, (unsigned char*) lastBytes, 2, &numWrit);
#else
		    lastBytes[0] = '\n';
		    (void)FileUtil_Write(sdfile, (unsigned char*) lastBytes, 1, &numWrit);
#endif
		}
	    }
	    if (strlen(name) > 8) {
		name[8] = '\0';
	    }
#if defined(_WIN32)
	    if (strlen(name) < 8) {
		strcpy(spacePaddedName, "        ");
		for(i = 0; i < strlen(name); i++) {
		    spacePaddedName[i] = name[i];
		}
		name = spacePaddedName;
	    }
	    do {
		cp3 = (char *)strrchr(result, PATHNAME_SLASH);
		if (cp3 != NULL) {
		    *cp3 = '/';
		}
	    } while (cp3 != NULL);
#endif
	    cp2 = (char *)strrchr(result, PATHNAME_SLASH);
	    if (cp2 != NULL) {
		*cp2 = '\0';
	    }
	    if (strlen(result) < GEODE_PATH_SIZE) {
#if !defined(_WIN32)
		sprintf(symEntry, "%s %s\n", name, result);
#else
		sprintf(symEntry, "%s %s\r\n", name, result);
#endif
		(void)FileUtil_Write(sdfile, symEntry, strlen(symEntry),
				     &numWrit);
		MessageFlush("(cached)...");
	    }

	    (void)FileUtil_Close(sdfile);

	    if (cp2 != NULL) {
		*cp2 = '/';
	    }
	} else {
	    /* if we can't open the file then don't worry about it, it's
	     * just an optimization after all, just let the user know
	     */
	    MessageFlush("Couldn't open %s\n", sdfilename);
	}
    }
}

#if defined(_WIN32)
/*
 * symdir direction constants
 */
# define SDD_HAVENT_LOOKED	0
# define SDD_FOUND_IT		1
# define SDD_NOT_FOUND		2
/*
 * file system constants
 */
# define FS_HAVENT_LOOKED	0
# define FS_FAT			1
# define FS_NTFS		2
#endif

/***********************************************************************
 *			FileGetLocalSymdirCache
 ***********************************************************************
 * SYNOPSIS:	    Figure the name of the local cache for a type of geode
 * CALLED BY:	    (INTERNAL) FileSearchSymdirCache
 * RETURN:	    dynamically-allocated path to the cache file
 * SIDE EFFECTS:    nothing
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 1/95		Initial Revision
 *
 ***********************************************************************/
static CONST char *
FileGetLocalSymdirCache(int 	geodeType)
{
    char    filename[12];
#if defined (_WIN32)
    int	    returnCode;
    static int		symdirDirStatus = SDD_HAVENT_LOOKED;
    static char		symdirDir[256];
#endif

#if !defined(_MSDOS)
    sprintf(filename, ".symdir.%d", geodeType);
#else
    sprintf(filename, "symdir.%d", geodeType);
#endif

#if defined(_WIN32)
    /*
     * check if the symdir location is to be overridden
     */
    if (symdirDirStatus == SDD_HAVENT_LOOKED) {
	returnCode = Registry_FindStringValue(Tcl_GetVar(interp,
							 "file-reg-swat",
							 TRUE),
					      "SYMDIR_DIR",
					      symdirDir,
					      sizeof(symdirDir));
	if ((returnCode == TRUE) && (symdirDir[0] != '\0')) {
	    if (access(symdirDir, R_OK | W_OK) == 0) {
		symdirDirStatus = SDD_FOUND_IT;
	    } else {
		symdirDirStatus = SDD_NOT_FOUND;
		if (MessageFlush != NULL) {
		    MessageFlush("Can't access Symdir Dir = %s, "
				 "using Local Root instead...", symdirDir);
		}
	    }
	} else {
	    symdirDirStatus = SDD_NOT_FOUND;
	}
    }
    if (symdirDirStatus == SDD_FOUND_IT) {
	if (FileUtil_TestFat(symdirDir) == TF_FAT) {
	    /*
	     * 8.3 so modify the filename to conform
	     */
	    sprintf(filename, "symdir.%d", geodeType);
	}
	return(File_PathConcat(symdirDir, filename, 0));
    }
#endif
    if (fileDevel) {
#if defined(_WIN32)
	if (FileUtil_TestFat(fileDevel) == TF_FAT) {
	    /*
	     * 8.3 so modify the filename to conform
	     */
	    sprintf(filename, "symdir.%d", geodeType);
	}
#endif
	return(File_PathConcat(fileDevel, filename, 0));
    } else {
#if defined(unix)
	return(File_PathConcat((CONST char *)getenv("HOME"), filename, 0));
#elif defined(_MSDOS)
	return(File_PathConcat(fileRoot, "BIN", filename, 0));
#else
	Punt("Somehow fileDevel doesn't have a value, shouldn't "
	     "happen under NT\n");
	return(NULL);  /* never gets executed */
#endif
    }
}


/***********************************************************************
 *			FileSearchSymdirCacheInternal
 ***********************************************************************
 * SYNOPSIS:	    Look through a cache file to see if there's a
 *	    	    suggestion for the geode we're trying to find.
 * CALLED BY:	    (INTERNAL) FileSearchSymdirCache
 * RETURN:	    dynamically-allocated path to the file, if found
 *	    	    NULL if not found
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/95	Initial Revision
 *
 ***********************************************************************/
typedef enum {
    FIND_FILE,
    FIND_GEODE
} find_mode;

static char *
FileSearchSymdirCacheInternal(CONST char *sdfilename,	/* Cache file in which
							 * to search */
			      CONST char *name,	    	/* Permanent name
							 * wanted */
			      CONST char *want,
			      FileMatchProc *check, 	/* Function to call to
							 * make sure it
							 * matches */
			      word serial,  	    	/* Serial number to
							 * match */
			      int *ignore,  	    	/* OUT: ignore the
							 * thing */
			      find_mode mode,	    	/* What we're looking
							 * for */
			      CONST char *usersSdf)	/* if not NULL implies
							 * parm 1 =.symdir file
							 * (no # after the r)
							 * and this parm is
							 * the symdir to store
							 * the entry in for
							 * speed-up if win32
							 */
{
    FileType    	sdfile;
    char    		match[GEODE_NAME_SIZE+GEODE_NAME_EXT_SIZE+4];
    char    		*matchp;
    int	    		len = strlen(name);
    int     		returnCode;
    struct stat 	statbuf;
    char 		*symdirContents = NULL;
    long 		symdirFileSize;
    long		fpos;
    char    		wholepath[GEODE_PATH_SIZE + 1];
    char		*wholepathp;
    char    		*result = NULL;
    int	    		indx;
    long int    bytesRead = 0;
    int			lineNum = 1;
#if defined(_WIN32)
    char    		pathbuf[GEODE_PATH_SIZE + 1];
#endif
    /*
     * Cache files contain only the permanent name, not the extension.
     */
    if (len > GEODE_NAME_SIZE) {
	len = GEODE_NAME_SIZE;
    }

    /*
     * get the filesize of the symdir
     */
    if (stat(sdfilename, &statbuf) == -1) {
#if defined(_WIN32)
	if (win32dbg == TRUE) {
	    if (MessageFlush != NULL) {
		MessageFlush("Problem reading symdir file: %s\n", sdfilename);
	    }
	}
#endif
	return FALSE;
    }
    symdirFileSize = statbuf.st_size;

    if ((mode == FIND_FILE) && (ignore)) {
	*ignore = FALSE;
    }
    /*
     * Open the cache file, if we're doing caching.
     */
    if (symCache == TRUE) {
    	returnCode = FileUtil_Open(&sdfile, sdfilename, O_RDONLY|O_TEXT,
				   SH_DENYWR, 0);
	if ((returnCode == TRUE) && (sdfile != 0)) {
	    symdirContents = (char *)malloc(symdirFileSize);
	    if (symdirContents == NULL) {
		(void)FileUtil_Close(sdfile);
		return FALSE;
	    }
	    (void *)FileUtil_Read(sdfile, symdirContents, symdirFileSize,
				  &bytesRead);
	    (void)FileUtil_Close(sdfile);
	    if (bytesRead != symdirFileSize) {
		MessageFlush("Problem reading entire symdir file: %s\n",
			     sdfilename);
		free(symdirContents);
		return FALSE;
	    }
	    fpos = 0;
	}
	/*
	 * read through the file (each loop = one line = one entry)
	 */
 	while(!Ui_Interrupt()) {
	    /*
	     * Read the permanent name
	     */
	    indx = 0;
	    while (1) {
		if ((fpos >= symdirFileSize) || isspace(symdirContents[fpos])) {
		    match[indx] = '\0';
		    fpos++;
		    break;
		}
		match[indx++] = symdirContents[fpos++];
		if (indx >= sizeof(match)) {
		    break;
		}
	    }

	    if (fpos >= symdirFileSize) {
		/*
		 * must not have a sym file path so we are done
		 */
		break;
	    }

	    if (indx >= sizeof(match)) {
		MessageFlush("\r\nEncountered corrupt symdir file: %s  "
			     "line #:%d\r\n", sdfilename, lineNum);
		break;
	    }

	    /*
	     * Space-pad the permanent name from the file to the length of
	     * the name being sought. We only do this if the char in
	     * "name" that corresponds to the null in "match" is a space, as
	     * otherwise the comparison is hopeless.
	     */
	    matchp = strchr(match, '\0');
	    while((matchp - match) < len)
	    {
		*matchp = ' ';
		matchp++;
	    }
	    *matchp = '\0';

	    /*
	     * Read the symfile directory
	     */
	    indx = 0;
	    while (1) {
		if ((fpos >= symdirFileSize) || (symdirContents[fpos] == '\n'))
		{
		    wholepath[indx] = '\0';
		    fpos++;
		    lineNum++;
		    break;
		} else {
		    wholepath[indx] = symdirContents[fpos++];
		}
		if (isspace(wholepath[indx]) == FALSE) {
		    if (++indx >= GEODE_PATH_SIZE) {
			break;
		    }
		}
	    }

	    if (indx >= GEODE_PATH_SIZE) {
		MessageFlush("\r\nDetected a corrupt symdir file: %s  :"
			     " line #:%d\r\n", sdfilename, lineNum);
		break;
	    }

	    if ((fpos >= symdirFileSize) && (indx == 0)) {
		break;
	    }

	    if (strncmp(match, name, len > 8 ? 8 : len) == 0) {
		if (mode == FIND_FILE && !strcmp(wholepath, "Ignore")) {
		    MessageFlush("Ignoring patient (see nuke-symdir-entry "
				 "to unignore)\n");
		    if (ignore) {
			*ignore = TRUE;
		    }
		    break;
		}

#if defined(_MSDOS)
		{
		    char *cp;
		    cp = strchr(wholepath, '/');
		    while (cp)
		    {
			*cp = '\\';
			cp = strchr(cp, '/');
		    }
		}
#endif
#if defined(_WIN32)
		/*
		 * switch from unix to dos file names if necessary
		 */
		if (strncmp(wholepath, "/staff", 6) == 0) {
		    if (File_MapUnixToDos(pathbuf, wholepath, NULL) == FALSE) {
			/*
			 * nothing to substitute /staff with, time to give up
			 */
			continue;
		    } else {
			wholepathp = pathbuf;
		    }
		} else {
		    wholepathp = wholepath;
		}
#else
		wholepathp = wholepath;
#endif
		if (mode == FIND_FILE) {
		    if (strrchr(wholepathp, '.') != NULL) {
			if ((access(wholepathp, R_OK) == 0)
			    && ((*check)(wholepathp, name, serial) == YES)) {
			    result = (char *)malloc_tagged(strlen(wholepathp)+1,
							   TAG_PNAME);
			    strcpy(result, wholepathp);
			}
		    } else {
			result = FileSearchTree(wholepathp, name, serial,
						want, check, FALSE);
		    }
		} else {
#if defined(_MSDOS) || defined(_WIN32)
		    /*
		     * XXX: WHY IS THIS NECESSARY? SHOULDN'T THE FILES HAVE
		     * DIFFERENT SERIAL NUMBERS IN THE DIFFERENT TREES?
		     */
		    char	*cp2;
		    CONST char 	*lpath;
		    int	    	len;

		    result = GeodeSearchTree(wholepathp, name, serial);

		    if (result != NULL) {
			/*
			 * this code always checks for a local version of a geode
			 * if it found a cached installed one, as that's probably
			 * what the user wants
			 */

			len = strlen(fileRoot);
			if ((fileDevel != fileRoot) &&
			    !strncmp_path(result, (char *)fileRoot, len))
			{
			    lpath = File_PathConcat(fileDevel, result+len, 0);
			    FileMapSeparators((char *)lpath, '/', '\\');

			    cp2 = strrchr(lpath, '\\');
			    if (cp2 != NULL) {
				*cp2 = '\0';
			    }
			    cp2 = GeodeSearchTree(lpath, name, serial);
			    free((void *)lpath);

			    if (cp2 != NULL) {
				free(result);
				result = cp2;
			    }
			}
		    } else {
			/* lets try the installed dir if that was local */
			len = strlen(fileDevel);
			if (!strncmp_path(wholepathp, (char *)fileDevel, len)) {
			    lpath = File_PathConcat(fileRoot, wholepathp+len,
						    0);
			    result = GeodeSearchTree(lpath, name, serial);
			    free((void *)lpath);
			}
		    }
#else
		    result = GeodeSearchTree(wholepathp, name, serial);
#endif
		}
	    	if (result) {
#if defined(_MSDOS) || defined(_WIN32)
		    FileMapSeparators(result, '\\', '/');
# if defined(_MSDOS)
		    {
			char *cp;

			cp = strchr(result, '.') + 1;
			while(*cp)
			{
			    *cp = toupper(*cp);
			    cp++;
			}
		    }
# else   /* else _WIN32 case */
		    if (usersSdf != NULL) {
			char namebuf[10];
			/*
			 * found it in the .symdir file, now cache it
			 * in the user's .symdir.# file
			 */
			strncpy(namebuf, name,
				sizeof(namebuf)/sizeof(namebuf[0]));
			FileCacheSymDir(usersSdf, namebuf, result);
		    }
# endif
#endif
		    if (mode == FIND_FILE) {
			MessageFlush("%s\n", result);
		    }
		    free(symdirContents);
		    return(result);
	    	}
	    }
	}
    }
    if (symdirContents != NULL) {
	free(symdirContents);
    }
    return NULL;
}


/*********************************************************************
 *			FileSearchSymdirCache
 *********************************************************************
 * SYNOPSIS: 	check the cache for this geode
 * CALLED BY:
 * RETURN:  	string indictating path or NULL
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	11/ 9/94	Initial version
 *
 *********************************************************************/
static char *
FileSearchSymdirCache(CONST char **sdfilenamePtr,
		      int geodeType,
		      char *name,
		      char *want,
		      FileMatchProc *check,
		      word serial,
		      int  *ignore,
		      find_mode  mode)
{
    char    *cp;
    CONST char *sdfilename;

    sdfilename = FileGetLocalSymdirCache(geodeType);
    cp = FileSearchSymdirCacheInternal(sdfilename, name, want, check,
				       serial, ignore, mode, NULL);

#if defined(unix) || defined(_WIN32) || defined(_LINUX)
    if ((ignore == NULL) || ((cp == NULL) && (! *ignore))) {
	if (geodeType < fileNumTypes && fileDirs[geodeType*2+1]) {
	    CONST char *sdf2 = File_PathConcat(fileDirs[geodeType*2+1],
					       ".symdir",
					       0);
	    cp = FileSearchSymdirCacheInternal(sdf2, name, want, check,
					       serial, ignore, mode,
					       sdfilename);

	    if (cp != NULL) {
		free((void *)sdfilename);
		sdfilename = sdf2;
	    } else {
		free((char *)sdf2);
	    }
	}
    }
#endif /* unix || _WIN32 || _LINUX */

    if (sdfilenamePtr) {
	*sdfilenamePtr = sdfilename;
    }
    return(cp);
}


/***********************************************************************
 *				File_FindGeode
 ***********************************************************************
 * SYNOPSIS:	    Locate a geode by name, serial number and type
 * CALLED BY:	    Ibm_Init, Ibm_NewGeode
 * RETURN:	    Dynamically-allocated, absolute path of the executable
 *	    	    or NULL if couldn't find one.
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/18/89		Initial Revision
 *
 ***********************************************************************/
char *
File_FindGeode(char 	*name,  	/* Permanent name (executable name for
					 * kernel). This should be a null-
					 * terminated version of the permanent
					 * name and extension. I.e. it is
					 * 12 characters long, plus a null */
	       word 	serial, 	/* Serial number (checksum for kernel).
					 * This must be in byte-order to match
					 * the executable file. */
	       int  	geodeType,	/* Type of geode (0 for kernel) */
	       Boolean	maydetach)	/* Non-zero if may detach in answer to
					 * problems in locating the thing */
{
    char	    *cp;		/* Return value */
    char    	    want[5];
    FileMatchProc   *check;
    char	    match[GEODE_NAME_SIZE+GEODE_NAME_EXT_SIZE+4];
    char	    *argv[2];
    char	    *cmd;
    int 	    namelen,
		    extlen;
    int	    	    ecGeode = 0, ignore = 0 ;
    CONST char 	    *sdfilename;
    char    	    *result;
    Boolean	    isKernel;

    MessageFlush("Looking for \"%s\"...", name);

    if ((geodeType == 0) || (geodeType == 4)) {
	check = FileExeMatches;     /* loader */
    } else {
	check = FileGeodeMatches;
	if  (name[8] == 'E') {
	    ecGeode = 1;
	}
	if (!STRNCMP_OS_SPECIFIC(name+8+ecGeode, "spu", 3)) {
	    /* establish the specific ui in a tcl variable, used in
	     * the focus, model, target commands to name a few */
	    Tcl_SetVar(interp, "specific-ui", name, 1);
	}
    }
    strcpy(want, sym_ext);

    /*
     * Try and locate the thing quickly by calling the file-locate-geode
     * TCL function to see if it can do anything when we give it the geode
     * type and the permanent name.
     *
     * First, form our comparison string from the geode type and the name with
     * trailing spaces removed from both the name and its extension.
     */
    namelen = strlen(name);

    if (namelen > GEODE_NAME_SIZE) {
	/*
	 * Name has extension so look for trailing spaces on the extension.
	 */
	namelen = GEODE_NAME_SIZE;
	for (extlen = GEODE_NAME_EXT_SIZE-1;
	     name[GEODE_NAME_SIZE+extlen] == ' ';
	     extlen--)
	{
	    ;
	}
    } else {
	/*
	 * No extension. Leave namelen alone in case its < GEODE_NAME_SIZE.
	 */
	extlen = 0;
    }

    namelen--;
    while (name[namelen] == ' ') {
	namelen--;
    }

    result = FileSearchSymdirCache(&sdfilename, geodeType, name, want,
				    check, serial, &ignore, FIND_FILE);

    if (result != NULL || ignore == TRUE) {
	free((char *)sdfilename);
	return result;
    }

    (void)sprintf(match, "%d %.*s.%.*s", geodeType, namelen+1, name,
		  extlen+1, &name[GEODE_NAME_SIZE]);

    if (ecGeode) {
    	argv[0] = "file-locate-ecgeode";
    } else {
    	argv[0] = "file-locate-geode";
    }
    argv[1] = match;

    cmd = Tcl_Merge(2, argv);

    if ((Tcl_Eval(interp, cmd, 0, 0) == TCL_OK) &&
	(interp->result && *interp->result != '\0'))
    {
	int 	numFiles;
	char	**files;

	(void)free(cmd);

	if (Tcl_SplitList(interp, interp->result, &numFiles, &files)==TCL_OK)
	{
	    int	    i;

	    for (i = 0; i < numFiles; i++) {
		char    *cp2, *result;

		cp = (char *)malloc(strlen(files[i]) + 1);
		strcpy(cp, files[i]);
		cp2 = (char *)strrchr(cp, '/');
		if (cp2 != NULL) {
		    *cp2 = '\0';
		}
		result = FileSearchTree(cp, name, serial, want, check, TRUE);
		free(cp);
#if defined(_MSDOS) || defined(_WIN32)
		 cp2 = result;
		 while ((cp2 != NULL) && (*cp2 != '\0')) {
		     if (*cp2 == '\\') {
			 *cp2 = '/';
# if defined(_MSDOS)
		     } else {
			 *cp2 = toupper(*cp2);
# endif
		     }
		     cp2++;
		 }
#endif
		 if (result) {
		     FileCacheSymDir(sdfilename, name, result);
		     MessageFlush("%s\n", result);
		     (void)free((char *)files);
		     (void)free((char *)sdfilename);
		     return(result);
		 }
	    }
	    (void)free((char *)files);
	}
    } else {
	(void)free(cmd);
    }
    /*
     * If the user interrupted out, let them enter the name.
     */
    if (Ui_Interrupt()) {
	goto handleInt;
    }

    /*
     * Couldn't find it a quick way, so look through the directories we've
     * got stored.
     */

    if (geodeType < fileNumTypes) {
	if (fileDirs[geodeType*2]) {
	    cp = FileCheckHack(fileDirs[geodeType*2], name, serial, want,
			       check, ecGeode);
	} else {
	    cp = NULL;
	}

	if (!cp && fileDirs[geodeType*2+1]) {
	    cp = FileCheckHack(fileDirs[geodeType*2+1], name, serial, want,
			       check, ecGeode);
	}

	Ui_ClearInterrupt();	/* Clear lingering interrupt */

	if (!cp && fileDirs[geodeType*2]) {
	    cp = FileSearchTree(fileDirs[geodeType*2], name, serial,
				    want, check, TRUE);
	}

	if (!cp && fileDirs[geodeType*2+1]) {
	    cp = FileSearchTree(fileDirs[geodeType*2+1], name, serial,
				want, check, TRUE);
	}

    	if (!cp) {
	    cp = FileSearchTree(fileGym, name, serial, (char *)gym_ext,
				    	check, TRUE);
	}

	if (cp) {
#if defined(_MSDOS) || defined(_WIN32)
	    char    *cp2=cp;

	    while(*cp2) {
		if (*cp2 == '\\') {
		    *cp2 = '/';
# if defined(_MSDOS)
		} else {
		    *cp2 = toupper(*cp2);
# endif
		}
		cp2++;
	    }
#endif
	    FileCacheSymDir(sdfilename, name, cp);
	    MessageFlush("%s\n", cp);
	    (void)free((char *)sdfilename);
	    return(cp);
	}
    }

handleInt:
    Ui_ClearInterrupt();	/* Clear lingering interrupt */
    MessageFlush("hmmmm.\n");

    /*
     * Not found in normal manner -- prompt the user for the location.
     * May only ignore if not the kernel.
     */
    Ui_AllowInterrupts(FALSE);
    isKernel = (STRNCMP_OS_SPECIFIC(name, "geos", 4) == 0) ? TRUE : FALSE;
    while((cp = FileAskUser(name, maydetach,
			    ((geodeType != 0) && (geodeType != 4)
			     && !isKernel))) != NULL)
    {
	userAsked = TRUE;
	if (strcmp(cp, "Ignore") == 0) {
	    FileCacheSymDir(sdfilename, name, cp);
	    MessageFlush("Added ignore entry to cache.\n");
	    (void)free((char *)sdfilename);
	    return NULL;
	}
	switch ((*check)(cp, name, serial)) {
	    case YES:
	    	FileCacheSymDir(sdfilename, name, cp);
		if (symCache == TRUE) {
		    MessageFlush("\n");
		}
		(void)free((char *)sdfilename);
		return(cp);
	    case NO:
		MessageFlush("I can't use %s (missing sym file?)\n", cp);
		free(cp);
		break;
	    case MAYBE:
	    {
		char    line[132];
		MessageFlush("%s doesn't have the right serial number. "
			     "Use it anyway?[yn](n) ", cp);
		Ui_ReadLine(line);
		if (line[0] == 'y' || line[0] == 'Y') {
#if 0
		    /* don't cache this, as it's not really the right one */
		    FileCacheSymDir(sdfilename, name, cp);
#endif
		    (void)free((char *)sdfilename);
		    return(cp);
		}
		break;
	    }
	}
    }

    (void)free((char *)sdfilename);

    /*
     * Told to ignore it -- return NULL
     */
    return((char *)NULL);
}



/***********************************************************************
 *				File_Locate
 ***********************************************************************
 * SYNOPSIS:	  Find a file on a search path.
 * CALLED BY:	  Source module
 * RETURN:	  The dynamically-allocated path to the file
 * SIDE EFFECTS:  none
 *
 * STRATEGY:
 *	Concatenate the file being sought with each directory in the path
 *	in turn and see if a file of that name is readable by this
 *	process. If so, return the path to that file. We check for
 *	readability because knowing where it is does us no good unless
 *	we can actually read its contents.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/13/88		Initial Revision
 *
 ***********************************************************************/
char *
File_Locate(char	*file,	    /* File name */
	    char	*path)	    /* Path, formatted as
				     * <dir1>:<dir2>:...<dirn> */
{
    char		name[1024]; /* Name buffer */
    int			nameLength; /* Length of 'file' */
    register char    	*cp;	    /* Mobile pointer into path */
    register char	*cp2;	    /* Current position in 'name' */

    if ((cp = path) == (char *)NULL) {
	return((char *)NULL);
    }

    nameLength = strlen(file) + 1;

    while (1) {
	/*
	 * Skip to end of current directory, copying it in.
	 */
	cp2 = name;
#ifdef _WIN32
	while((*cp != ';') && (*cp != '\0')) {
#else
	while((*cp != ':') && (*cp != '\0')) {
#endif
	    *cp2++ = *cp++;
	}

	/*
	 * Make sure the directory ends in a slash
	 */
#ifdef _WIN32
	if (cp2[-1] != '\\') {
     	    *cp2++ = '\\';
 	}
#else
	if (cp2[-1] != '/') {
	    *cp2++ = '/';
	}
#endif

	/*
	 * Copy in the file being sought
	 */
	bcopy(file, cp2, nameLength);

	/*
	 * See if it's readable.
	 */
	if (access(name, R_OK) == 0) {
	    /*
	     * Yup. Add in the length of the directory in which it was found
	     * (cp2 points after the terminating slash and nameLength is the
	     * length of  file  plus its terminating null) and allocate that
	     * much room, copying the full name into the new area.
	     */
	    nameLength += cp2 - name;
	    cp2 = malloc_tagged(nameLength, TAG_ETC);
	    bcopy(name, cp2, nameLength);
	    return(cp2);
	}
	/*
	 * If we hit the end of the path, return failure, otherwise advance
	 * to the next directory and loop
	 */
	if (*cp++ == '\0') {
	    return((char *)NULL);
	}
    }
}


/***********************************************************************
 *				GeodeSearchTree
 ***********************************************************************
 * SYNOPSIS:	    Search a directory tree for the proper .geo file
 * CALLED BY:	    FindGeode
 * RETURN:	    the path to the .geo file or NULL if not found
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	We attempt to classify files in a directory by their suffix
 *	    to avoid going to the filesystem to get the actual type.
 *	    Directories are assumed to not have any suffix.
 *	Any .geo file is opened and its header examined to see if it's
 *	    the desired file.
 *	Any file that doesn't have a suffix (and isn't Makefile) is
 *	    checked to see if it's a directory and is processed
 *	    recursively if it is.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JS	7/31/93   	Initial Revision copied from FileSearchTree
 *
 ***********************************************************************/
static char *
GeodeSearchTree (CONST char	*dir,	/* directory to search		   */
		 CONST char 	*name,	/* name to find			   */
		 int	bNEC)		/* do we want the Non-EC .geo file */
{
    DIR			*dirp;		/* Current directory		   */
    CONST struct direct	*dp;		/* Current entry		   */
    CONST char		*suffix;	/* Suffix of current		   */
    char		*cp;		/* general-purpose pointer (bad!)  */
    char		path[1024];	/* Path for .geo or directory	   */
    char		*tail;		/* Where to put the tail (in path) */
    GeodeName		gn;		/* GeodeName			   */
    FileType	    	fd;		/* file descriptor		   */
    int                 returnCode;
    long                numRead = 0;

    dirp = opendir(dir);
    if (dirp == (DIR *)NULL) {
	return((char *)NULL);
    }

    MessageFlush("Searching: %.*s%.*s\r", COLS - 13, dir,
		 COLS - (strlen(dir) + 13),
		 "                                                        ");

    for (tail = path; *dir != '\0'; *tail++ = *dir++) {
	;
    }
    *tail++ = '/';

    /*
     * Use Ui_Interrupt() here, not Ui_CheckInterrupt(), as we're called
     * from Ibm_NewGeode, which disables interrupts, so as to avoid being
     * nailed while fetching data from the core block. We want the user to
     * be able to interrupt the search, though.
     */
    for (dp = readdir(dirp); dp != 0 && !Ui_Interrupt(); dp = readdir(dirp)) {
#if !defined(_WIN32)
	if (dp->d_fileno == 0) {
	    continue;
	}
	for (suffix = dp->d_name+strlen(dp->d_name);
#else
	if ((strcmp(dp->d_name, ".") == 0) ||
	    (strcmp(dp->d_name, "..") == 0)) {
	    continue;
	}
	for (suffix = dp->d_name+strlen(dp->d_name);
#endif
	     suffix > dp->d_name && *suffix != '.';
	     suffix--)
	{
	    ;
	}

#if defined(_MSDOS)
	#define GEODE_EXTENSION ".GEO"
#else
	#define GEODE_EXTENSION ".geo"
#endif

	if (suffix > dp->d_name) {
	    if (STRCMP_OS_SPECIFIC(suffix, GEODE_EXTENSION) == 0) {
		strcpy(tail, dp->d_name);

		returnCode = FileUtil_Open(&fd, path, O_RDONLY|O_BINARY,
					  SH_DENYWR, 0);

		if (returnCode == TRUE) {
		    (void)FileUtil_Seek(fd,
					offsetof(GeodeHeader2,
						 geodeFileType),
					SEEK_SET);
		    (void)FileUtil_Read(fd, (char *)&gn, sizeof(gn),
					&numRead);
		    (void)FileUtil_Close(fd);

		    if ((bcmp((char *)name, (char *)gn.name, GEODE_NAME_SIZE) == 0) &&
			(bNEC == (gn.ext[0] != 'E')))
		    {
			/*
			 * Found the file. Wheeeeee. Allocate the path
			 * in non-volatile storage, close the directory and
			 * return the proper path.
			 */
			cp = (char *)malloc_tagged(strlen(path)+1, TAG_PNAME);
			strcpy(cp, path);

			closedir(dirp);
			return(cp);
		    }
		}
	    }
	} else if ((strcmp(dp->d_name, "Makefile") != 0) &&
		   (strcmp(dp->d_name, "RCS") != 0) &&
		   (dp->d_name[0] != '.')) {
	    /*
	     * Form the path to the file and recurse (it's probably faster
	     * to open the file, then find it's not a directory, than to
	     * stat every file and then open the directories).
	     */
	    strcpy(tail, dp->d_name);
	    cp = GeodeSearchTree(path, name, bNEC);

	    if (cp != (char *)NULL) {
		/*
		 * Success! Close this directory and return the result up
		 * the call chain.
		 */
		closedir(dirp);
		return(cp);
	    }
	}
    }
    /*
     * Sorry, dude.
     */
    closedir(dirp);
    return((char *)NULL);
}	/* End of GeodeSearchTree.	*/


/*********************************************************************
 *			strncmp_path
 *********************************************************************
 * SYNOPSIS: 	compare strings allowing for case and slashes
 * CALLED BY:	global
 * RETURN:  	0 for a match, non-zero otherwise
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	11/10/94		Initial version
 *
 *********************************************************************/
static int strncmp_path(char *path1, char *path2, int n)
{
    for (; n > 0 && *path1 && *path2; --n, path1++, path2++)
    {
	if (toupper(*path1) != toupper(*path2) &&
	    ! ((*path1 == '/' || *path2 == '\\') &&
	       (*path2 == '/' || *path2 == '\\')))
	{
	    return 1;
	}
    }

    return 0;
}


/***********************************************************************
 *				FindGeode
 ***********************************************************************
 * SYNOPSIS:	    Find geode file on host machine
 * CALLED BY:	    Tcl
 * RETURN:	    path of geode
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JS	7/31/93   	Initial Revision
 *
 ***********************************************************************/

DEFCMD(find-geode,FindGeode,TCL_EXACT,NULL,obscure,
"Usage:\n\
    find-geode [-n] <geode_name>\n\
\n\
Examples:\n\
    \"find-geode write\"		Find path of EC GeoWrite\n\
    \"find-geode -n write\"		Find path of non-EC GeoWrite\n\
\n\
Synopsis:\n\
    Find path of geode on host machine.\n\
")
{
    int  i, j, inCache=0;
    char *cp = NULL;
    char geodeName[GEODE_NAME_SIZE+GEODE_NAME_EXT_SIZE+4];
    CONST char *sdfilename;
    int ignore;

    if ((argc < 2) || (argc > 3) ||
	((argc == 3) && (strcmp(argv[1], "-n") != 0)))
    {
	Tcl_Error(interp, "Usage: find-geode [-n] <geode_name>");
    }

    /*
     * Space pad geodeName.
     */
    strncpy(geodeName, argv[argc-1], GEODE_NAME_SIZE);
    geodeName[GEODE_NAME_SIZE] = '\0';

    if ((i = strlen(geodeName)) < GEODE_NAME_SIZE) {
	for (; i < GEODE_NAME_SIZE; i++) {
	    geodeName[i] = ' ';
	}
    }

    /* try looking through all the symdir cache files for an entry
     * before doing the long search
     */
    for (i = 1; i <= 4; i++) {
	cp = FileSearchSymdirCache(&sdfilename, i, geodeName, NULL,
				    NULL, (word)(argc == 3), &ignore, FIND_GEODE);

	if (cp != NULL)	{
	    inCache = 1;
	    break;
	}
    }

    if (cp == NULL) {
	/*
	 * Find geode.  If (argc == 3) then we are searching for the NEC .geo
	 * file. Search local directories and then the installed directories.
	 */
	for (i = 0; i < fileNumTypes*2; i++) {
	    j = ((i % fileNumTypes) * 2) + (i / fileNumTypes);
	    if (fileDirs[j] != NULL) {
		cp = GeodeSearchTree(fileDirs[j], geodeName, (argc == 3));
		if (cp != NULL) {
		    break;
		}
	    }
	}
    }

    if (cp != NULL) {
	if (!inCache) {
	    FileCacheSymDir(sdfilename, geodeName, cp);
	}
	Tcl_RetPrintf(interp, "%s", cp);
	free(cp);
    }
    if (Ui_Interrupt()) {
	Message("\n");
    }

    free((char *)sdfilename);
    return TCL_OK;
}	/* End of FindGeode.	*/


#if defined(unix) || defined(_LINUX) || defined(_WIN32)
/***********************************************************************
 *				FileSetVar
 ***********************************************************************
 * SYNOPSIS:	    Set a variable to a copy of the given string, freeing
 *	    	    any previous value.
 * CALLED BY:	    File_Init
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The old value is freed. A TCL variable of the same
 *	    	    value may be entered.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/18/89		Initial Revision
 *
 ***********************************************************************/
static void
FileSetVar(char	    **var,  	    /* Place to store result */
	   char	    *tclVarName,    /* Name of tcl variable under which to
				     * also store the result */
	   char	    *begin, 	    /* Beginning of value */
	   char	    *end)   	    /* End of value, if known (NULL if not) */
{
    /*
     * Find end if not given
     */
    if (end == NULL) {
	end = begin+strlen(begin);
    }

    /*
     * Nuke previous value, if present
     */
    if (*var != NULL) {
	free(*var);
    }
    /*
     * Allocate space for new and copy it in.
     */
    *var = (char *)malloc(end-begin+1);
    bcopy(begin, *var, end-begin+1);

    /*
     * Null-terminate (just in case)
     */
    (*var)[end-begin] = '\0';

    /*
     * If desired, put the value in the interpreter's global variable list
     * under the given name.
     */
    if (tclVarName) {
	Tcl_SetVar(interp, tclVarName, *var, TRUE);
    }
}
#endif /* unix */

/***********************************************************************
 *				FileParseConfigFile
 ***********************************************************************
 * SYNOPSIS:	    Parse the configuration file into a list of keys
 *	    	    and values for use by us and others.
 * CALLED BY:	    File_Init
 * RETURN:	    only if file is valid
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/15/92		Initial Revision
 *
 ***********************************************************************/
static void
FileParseConfigFile(CONST char *path)
{
    char    	    buf[1024];
    FileType  	    cf;	    	/* Stream open to configuration file */
    FileConfigEntry *fce;
    char    	    *cp;
    long int        bytesRead;
    int             indx;
    int             returnCode;

    returnCode = FileUtil_Open(&cf, path, O_RDONLY|O_TEXT, SH_DENYWR, 0);
    if (returnCode == FALSE) {
	Punt("Can't open configuration file \"%s\"", path);
    }

    while(1) {
	char 	*argEnd;
	char	*key;
	int 	keyLen;

	indx = 0;
	while (1) {
	    (void)FileUtil_Read(cf, &(buf[indx]), 1, &bytesRead);
	    if ((bytesRead != 1) || buf[indx] == '\n') {
		buf[indx] = '\0';
		break;
	    }
	    if (++indx >= sizeof(buf)) {
		break;
	    }
	}

	if ((bytesRead != 1) && (indx == 0)) {
	    break;
	}

	if (indx >= sizeof(buf)) {
	    MessageFlush("FileParseConfigFile: problem with config file:"
			 "%s\r\n", path);
	    break;
	}

	if (buf[0] == '#') {
	    continue;
	}
	/*
	 * Skip leading whitespace.
	 */
	for (cp = buf; isspace(*cp); cp++) {
	    ;
	}
	if (*cp == '\0') {
	    /*
	     * Blank line -- ignore it.
	     */
	    continue;
	}

	/*
	 * Find the end of the initial word
	 */
	key = cp;
	while (!isspace(*cp) && *cp) {
	    cp++;
	}
	keyLen = cp - key;
	if (*cp == '\0' || *cp == '\n') {
	    *cp = '\0';
	} else {
	    *cp++ = '\0';		/* Terminate key */
	}

	/*
	 * Skip to argument
	 */
	while(isspace(*cp)) {
	    cp++;
	}

	/*
	 * Locate the end of the argument.
	 */
	for (argEnd = cp; !isspace(*argEnd) && *argEnd != '\0'; argEnd++) {
	    ;
	}

	*argEnd = '\0';		/* Terminate argument */

	/*
	 * Allocate a FileConfigEntry structure for the beast, making room at
	 * the end of it to store the key and the value, all in one block o'
	 * memory.
	 */
	fce = (FileConfigEntry *)malloc(sizeof(FileConfigEntry) +
					(keyLen + 1) +
					(argEnd - cp + 1));
	/*
	 * Point fce->key and fce->value to their respective places
	 * in the block just allocated and copy the strings in.
	 */
	fce->key = (char *)(fce+1);
	fce->value = fce->key + keyLen + 1;
	strcpy(fce->key, key);
	strcpy(fce->value, cp);

	/*
	 * Put this entry at the head of the chain.
	 */
	fce->next = fileConfigData;
	fileConfigData = fce;

	/*
	 * Special-case numeric key as path for a geode type, recording the
	 * largest such seen...
	 */
	if (index("0123456789", key[0]) != NULL) {
	    int	n = atoi(key);

	    if (n >= fileNumTypes) {
		fileNumTypes = n+1;
	    }
	}
    }
    (void)FileUtil_Close(cf);
    return;
}

/***********************************************************************
 *				File_FetchConfigData
 ***********************************************************************
 * SYNOPSIS:	    Look up a key in the configuration file and return
 *	    	    its value, if it's there.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    NULL if the key isn't in the config file, else the
 *	    	    address of the string value.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/15/92		Initial Revision
 *
 ***********************************************************************/
CONST char *
File_FetchConfigData(CONST char *key)
{
    FileConfigEntry *fce;
    char    c = key[0];

    for (fce = fileConfigData; fce != NULL; fce = fce->next) {
	if ((fce->key[0] == c) && (strcmp(fce->key, key) == 0)) {
	    return(fce->value);
	}
    }
    return(NULL);
}


/***********************************************************************
 *				File_CheckAbsolute
 ***********************************************************************
 * SYNOPSIS:	    See if the given path is an absolute one.
 * CALLED BY:	    INTERNAL
 * RETURN:	    TRUE if it is, FALSE if it ain't
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/15/92		Initial Revision
 *
 ***********************************************************************/
Boolean
File_CheckAbsolute(CONST char *path)
{
#if defined(_MSDOS)
    assert(path[0] != '\0');
    if (path[1] == ':') {
	if ((path[2] != '\\') && (path[2] != '/')) {
	    Punt("directory '%s' not fully absolute", path);
	}
	return(TRUE);
    }

#elif defined(_WIN32)
    if (path[0] != '\0') {
	if (path[1] == ':') {
	    if ((path[2] == '\\') || (path[2] == '/')) {
		return(TRUE);
	    }
	}
    }

#else
    if (path[0] == '/') {
	return(TRUE);
    }
#endif
    return(FALSE);
}
#if defined(_MSDOS) || defined(_WIN32)

/***********************************************************************
 *				FileRestoreWorkingDir
 ***********************************************************************
 * SYNOPSIS:	    Restore the DOS working directory to what it was
 *	    	    on start-up, since what we do affects our parent...
 * CALLED BY:	    exit()
 * RETURN:	    nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/23/92		Initial Revision
 *
 ***********************************************************************/
static void
FileRestoreWorkingDir(void)
{
    _chdir(cwd);
}
#endif

/***********************************************************************
 *				File_Init
 ***********************************************************************
 * SYNOPSIS:	    Locate and read the configuration file.
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Various variables are set in the tcl interpreter
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/18/89		Initial Revision
 *
 ***********************************************************************/
void
File_Init(int	    *argcPtr,
	  char	    **argv)
{
    char    	buf[1024]; 	/* Buffer for forming paths etc. */
    CONST char 	*ccp;	    	/* General pointer to read-only memory */
    int	    	i;  	    	/* Index into fileDirs */
    char    	*argv0;	    	/* File portion of argv[0] */
    char    	*argBranch; 	/* Branch specified in argv */
    char	**nav;	    	/* Place to store next unknown arg in argv */
    char    	**av;	    	/* Current arg in argv */
    int		ac; 	    	/* Number of current arg */
    char    	*sargv[3];
    Boolean 	fileerrFound = FALSE;
    int         returnCode;
    char        key[30];
    char    	*cp;	    	/* General pointer */
    int	    	rootLen = 0;    /* Length of root directory */
    CONST char	*value;
#ifdef _WIN32
    char	sdkname[256];		/* name of the sdk in the reg */
#endif

    Message = NULL;
    MessageFlush = NULL;

    argv0 = rindex(argv[0], PATHNAME_SLASH);
    if (argv0++ == NULL) {
	argv0 = argv[0];
    }

    /*
     * Check for flags we support:
     *	-B<branch name>
     *	-c <config file>
     *  -ntsdk <ntsdk name>        WIN32 only - eg ntsdk30b
     */
    argBranch = NULL;
    buf[0] = '\0';
    for (av = nav = &argv[1], ac = *argcPtr-1; ac > 0; ac--, av++) {
	if (strncmp(*av, "-B", 2) == 0) {
	    argBranch = &av[0][2];
	    *argcPtr -= 1;
	} else if (strcmp(*av, "-c") == 0) {

	    if (ac > 1) {
		strcpy(buf, av[1]);
		*argcPtr -= 2;
		av++, ac--;
		if (access(buf, R_OK) != 0) {
		    Punt("Cannot open user-specified configuration "
			 "file '%s'\n", buf);
		}
	    } else {
		Punt("-c argument requires configuration file as an "
		     "argument\n");
	    }
#if defined(_WIN32)
	} else if (strncmp(*av, "-ntsdk", 6) == 0) {
	    if (ac > 1) {
		strcpy(sdkname, av[1]);
		*argcPtr -= 2;
		av++, ac--;
	    } else {
		Punt("-ntsdk argument requires ntsdk name as an "
		     "argument\n");
	    }
#endif
	} else {
	    /*
	     * Copy the argument (down)
	     */
	    *nav++ = *av;
	}
    }

    if (buf[0] != '\0') {
	goto read_config;
    }

    /*
     * Locate a configuration file for us to read:
     *	0) user specified existing config file with -c <file> arg
     *	1) swat.conf in current directory
     *	2) ~/.swat.conf
     *	3) swat.conf along ${PATH}
     * replace "swat" with argv0 if it's different. ~/.swat.conf is
     * special-cased, however...and swat.conf in the local directory is used
     * as a last-ditch attempt.
     */
# if defined(_MSDOS)
    /*
     * In DOS, we try the value of the SWATCONF envariable first.
     */
    cp = (char *)getenv("SWATCONF");
    if ((cp != NULL) && (access(cp, R_OK) == 0)) {
	strcpy(buf, cp);
	goto read_config;
    }

    /*
     * Try argv0.cfg in the current dir next.
     */
    cp = rindex(argv0, '.');
    if (cp != NULL) {
	sprintf(buf, "%.*s." CONFIG_SUFFIX, cp-argv0, argv0);
    } else {
	sprintf(buf, "%s." CONFIG_SUFFIX, argv0);
    }
    if (access(buf, R_OK) == 0) {
	goto read_config;
    }

    /*
     * Try full path in argv[0] with extension replaced by cfg next.
     */
    cp = rindex(argv[0], '.');
    if (cp != NULL) {
	sprintf(buf, "%.*s." CONFIG_SUFFIX, cp-argv[0], argv[0]);
    } else {
	sprintf(buf, "%s." CONFIG_SUFFIX, argv[0]);
    }

# else
    sprintf(buf, "%s." CONFIG_SUFFIX, argv0);
# endif
    if (access(buf, R_OK) == 0) {
	goto read_config;
    }
	    /* No HOME envariable in DOS... */
# if defined(unix)
    cp = (char *)getenv("HOME");
    if (cp != NULL) {
	sprintf(buf, "%s/.%s." CONFIG_SUFFIX, cp, argv0);
	if (access(buf, R_OK) == 0) {
	    /*
	     * Found a config file -- go read it.
	     */
	    goto read_config;
	}
	sprintf(buf, "%s/.swat." CONFIG_SUFFIX, cp);
	if (access(buf, R_OK) == 0) {
	    /*
	     * Found a config file -- go read it.
	     */
	    goto read_config;
	}
    }
# endif

#ifdef _WIN32
    {
	cp = (char *)getenv("PATH");
    
    	if (cp != NULL) {
    	    sprintf(buf, "%s", argv0);
	    if((strlen(buf) > 3) && 
	    		(strncmp(buf + strlen(buf) - 4, ".exe", 4) == 0)) {
		buf[strlen(buf) - 4] = 0;    
	    }
	    strcat(buf, "." CONFIG_SUFFIX);
    	    cp = File_Locate(buf, cp);
    	    if (cp != NULL) {
    		strcpy(buf, cp);
    		free(cp);
    		goto read_config;
    	    }
    	}
    }
#else
    if (argv0 == argv[0]) {
	cp = (char *)getenv("PATH");

	if (cp != NULL) {
	    sprintf(buf, "%s." CONFIG_SUFFIX, argv0);
	    cp = File_Locate(buf, cp);
	    if (cp != NULL) {
		strcpy(buf, cp);
		free(cp);
		goto read_config;
	    }
	}
    }
#endif

    strcpy(buf, "swat." CONFIG_SUFFIX);
    if (access(buf, R_OK) != 0) {
	Punt("Can't locate configuration file");
    }

read_config:

    /*
     * At this point, "buf" contains the path to the configuration file
     */
    FileParseConfigFile(buf);

    
    /*
     * Fetch the root directory of the development tree
     */
    fileRoot = File_FetchConfigData("root");
    if (fileRoot == NULL) {
	fileRoot = (char *)getenv("ROOT_DIR");
	if (fileRoot == NULL) {
	    Punt("Root directory not specified in config file or environment");
	}
    }
    if (!File_CheckAbsolute(fileRoot)) {
	Punt("Root directory must be absolute path");
    }
    rootLen = strlen(fileRoot);
#if defined(_WIN32)
    FileMapSeparators((char *)fileRoot, '\\', '/');
#endif
    Tcl_SetVar(interp, "file-root-dir", fileRoot, TRUE);

    /*
     * Find the current directory so we can set up the search paths
     * for geodes.
     */
# if defined(_MSDOS) || defined(_LINUX)
#ifdef _LINUX
    if (getcwd(cwd, sizeof(cwd)) == NULL) {
#else
    if (_getcwd(cwd, sizeof(cwd)) == NULL) {
#endif
	Punt("could not fetch current directory");
    }
#ifndef _LINUX
    atexit(FileRestoreWorkingDir);
#endif
# else
    if (getcwd(cwd, sizeof(cwd)) == NULL) {
	Punt("could not fetch current directory");
    }
# endif

    /*
     * Store the initial directory away in the init-directory variable
     */
#if defined(_WIN32)
    FileMapSeparators((char *)cwd, '\\', '/');
#endif
    Tcl_SetVar(interp, "file-init-dir", cwd, TRUE);

    fileBranch[0] = '\0';

    /*
     * Figure the root of the development tree so we can find the user's
     * kernel, libraries, etc. The root is simply fileRoot plus the
     * next component after it in the current directory. Note that if
     * we're not in a subdirectory of the root, we have no idea...
     */
# if !defined(_MSDOS)
#if defined(_WIN32)
    	FileMapSeparators((char *)cwd, '\\', '/');
#endif
    if (STRNCMP_OS_SPECIFIC(cwd, fileRoot, rootLen) == 0) {
	cp = cwd + rootLen + 1;
	while(*cp != '/' && *cp != '\0') {
	    cp++;
	}

	/*
	 * Set up the devel-directory variable now too
	 */
	*cp = '\0';

	FileSetVar((char **)&fileDevel, "file-devel-dir", cwd, cp);

	/*
	 * Since we're in a development tree, go look for a BRANCH file at
	 * its root. If one's there, prepend it to the default directory.
	 */
	if (argBranch == NULL) {
	    FileType	cf;
	    CONST char	*bfile;
	    int		indx;
	    long	bytesRead = 0;

	    bfile = File_PathConcat(fileDevel, "BRANCH", 0);
	    returnCode = FileUtil_Open(&cf, bfile, O_RDONLY|O_TEXT,
				      SH_DENYWR, 0);
	    free((char *)bfile);

	    if (returnCode == TRUE) {
		indx = 0;
		while (1) {
		    (void)FileUtil_Read(cf, &(buf[indx]), 1, &bytesRead);
		    if ((bytesRead != 1) || (buf[indx] == '\n')) {
			buf[indx] = '\0';
			break;
		    }

		    if (++indx >= sizeof(buf)) {
			break;
		    }
		}
		if (indx >= sizeof(buf)) {
		    fprintf(stderr, "\r\nFile_Init: buffer overflow"
			    " reading file\r\n");
		    return;
		}

		if (indx > 0) {
		    /*
		     * save the branch's name away.
		     */
		    argBranch = buf;
		}
		(void)FileUtil_Close(cf);
	    }
	}

	if (argBranch != NULL && *argBranch != '\0') {
	    strcpy(fileBranch, argBranch);
	}
    } else {
	fileDevel = getenv("LOCAL_ROOT");
        if (fileDevel == NULL) {
    	    fileDevel = fileRoot;
	    fprintf(stderr, "Current directory (%s) is not under GEOS tree %s\n",
			cwd, fileRoot);
	}
	else {
		fprintf(stderr, "Current directory (%s) is not under GEOS tree %s, using LOCAL_ROOT=%s\n",
        		cwd, fileDevel);
		
	}


    }
# else

    fileDevel = getenv("LOCAL_ROOT");
    if (fileDevel == NULL) {
	fileDevel = fileRoot;
    }

#if defined(_WIN32)
    FileMapSeparators((char *)fileDevel, '\\', '/');
#endif
    Tcl_SetVar(interp, "file-devel-dir", fileDevel, TRUE);
# endif;

    /*
     * Set the file-branch variable to hold the name of the branch being used,
     * or empty if none.
     * XXX: end with a slash to make life easier? Use "." instead of "" for
     * the trunk?
     */
#if defined(_WIN32)
    FileMapSeparators((char *)fileBranch, '\\', '/');
#endif
    Tcl_SetVar(interp, "file-branch", fileBranch, TRUE);

    /*
     * See if there's a default tree in which to locate geodes. If not, we
     * assume the default is just the appropriate subdirs under the root.
     */
    value = File_FetchConfigData("default");
    if (value == NULL) {
	value = fileRoot;
    }
    if (File_CheckAbsolute(value)) {
	fileDefault = value;
    } else {
	/*
	 * Form the absolute path for the default tree and store it away.
	 */
	fileDefault = File_PathConcat(fileRoot, fileBranch, value, 0);
    }

#if defined(_WIN32)
    FileMapSeparators((char *)fileDefault, '\\', '/');
#endif
    Tcl_SetVar(interp, "file-default-dir", fileDefault, TRUE);

    /*
     * Figure where the .gym files are located.
     */
# if defined(_MSDOS)
    fileGym = File_PathConcat(fileRoot, "GYM", 0);
# else
    fileGym = File_PathConcat(fileDefault, "GYM", 0);
# endif

    /*
     * Now locate the directories for the various geode types.
     */
    fileDirs = (CONST char **)calloc(fileNumTypes*2, sizeof(char *));

    for (i = 0; i < fileNumTypes; i++) {
	if (i == 0) {
	    value = File_FetchConfigData("kernel");
	} else {
	    sprintf(key, "%d", i);
	    value = File_FetchConfigData(key);
	}
	if (value != NULL) {
	    fileDirs[i*2+1] = File_PathConcat(fileDefault, value, 0);

	    if (fileDevel) {
		fileDirs[i*2] = File_PathConcat(fileDevel, value, 0);
	    }
	}
    }

# if defined(unix)
    Tcl_SetVar(interp, "file-os", "unix", TRUE);
# elif defined(_LINUX)
    Tcl_SetVar(interp, "file-os", "unix", TRUE);
# elif defined(_MSDOS)
    Tcl_SetVar(interp, "file-os", "dos", TRUE);
# elif defined(_WIN32)
    Tcl_SetVar(interp, "file-os", "win32", TRUE);
# endif

    /*
     * Figure where the Tcl library is.
     */
    fileSysLib = File_FetchConfigData("syslib");
    if (fileSysLib == NULL) {
	Punt("System library directory not specified in config file");
    }
    if (File_CheckAbsolute(fileSysLib)) {
	fileAbsSysLib = fileSysLib;
    } else {
	fileAbsSysLib = File_PathConcat(fileRoot,
					fileBranch,
					fileSysLib,
					0);
    }
#if defined(_WIN32)
    FileMapSeparators((char *)fileAbsSysLib, '\\', '/');
#endif
    Tcl_SetVar(interp, "file-syslib-dir", fileAbsSysLib, TRUE);

after_config:
    /*
     * Initialize the help system so anything in file-err.tcl that has
     * on-line help won't send us off the deep end.
     */
    Help_Init();
    interp->helpFetch = Help_Fetch;
    interp->helpSet = Help_Store;

    Cmd_Create(&FindGeodeCmdRec);

    /*
     * Read in the initial TCL definitions required by this module.
     */

    sargv[0] = "source";
    sargv[2] = 0;
    if (getenv("SWATPATH") != NULL) {
	ccp = File_PathConcat((CONST char *)getenv("SWATPATH"),
			     "file-err.tcl",
			     0);
	if (access((char *)ccp, R_OK) == 0) {
	    sargv[1] = (char *)ccp;
	    fileerrFound = TRUE;
	    if (Tcl_SourceCmd((ClientData)0, interp, 2, sargv) == TCL_OK) {
		free((char *)ccp);
		return;
	    }
	}
	free((char *)ccp);
    }

    if (fileDevel && !File_CheckAbsolute(fileSysLib)) {
	ccp = File_PathConcat(fileDevel, fileSysLib, "file-err.tcl", 0);
	if (access((char *)ccp, R_OK) == 0) {
	    sargv[1] = (char *)ccp;
	    fileerrFound = TRUE;
	    if (Tcl_SourceCmd((ClientData)0, interp, 2, sargv) == TCL_OK) {
		free((char *)ccp);
		return;
	    }
	}
	free((char *)ccp);
    }
    ccp = File_PathConcat(fileAbsSysLib, "file-err.tcl", 0);
    if (access((char *)ccp, R_OK) == 0) {
	sargv[1] = (char *)ccp;
	fileerrFound = TRUE;
	if (Tcl_SourceCmd((ClientData)0, interp, 2, sargv) == TCL_OK) {
	    free((char *)ccp);
	    return;
	}
    }
    if (fileerrFound == FALSE) {
    	Punt("Couldn't read File module error-handling code (%s)", ccp);
    } else {
	Punt("Parse error in %s", ccp);
    }

    free((char *)ccp);

    return;
}
