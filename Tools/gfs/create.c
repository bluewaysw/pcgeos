/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  GFS (GEOS file system)
 * FILE:	  create.c
 *
 * AUTHOR:  	  Tony Requist
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	CreateGFS   	    Create a GFS file system
 *
 * DESCRIPTION:
 *	Main module for gfs.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: create.c,v 1.15 97/04/28 16:33:18 clee Exp $";

#endif lint

#include    "gfs.h"

#include    <compat/dirent.h>
#include    <time.h>
#include    <errno.h>

typedef struct direct DIRENT;

#define MAX_DIRECTORY_SIZE 200

#if !defined(_MSDOS)
#define COPY_BUF_SIZE 32768
#else
#define COPY_BUF_SIZE 30000
#include    <search.h>
#endif

/*
 * This is the structure used to record the locations of pointers to files
 * (since these all need to be fixed up and written out)
 */

typedef struct _FileFixup {
    char    	    	*filePath;
    dword    	    	dataFixupPos;
    dword    	    	sizeFixupPos;
    dword    	    	sizeFixupPos2;
    int	    	    	isGeosFile:1,	    	/* Set if file has header */
			localize:1; 	    	/* Set if file should be put
						 * in localizable portion of
						 * fs */
    dword    	    	linkReadOffset;	    	/* Non-zero if link (offset
						 * within @dirname file of
						 * link data) */
    struct _FileFixup	*next;
} FileFixup;

FileFixup *firstFixup = NULL;
FileFixup **lastFixup = NULL;

/*
 * This structure records the directories that must be processed
 */

typedef struct _DirToProcess {
    char    	    	*filePath;
    dword   	    	sizeFixupPos;
    dword   	    	dataFixupPos;
    dword   	    	sizeFixupPos2;
    dword   	    	parentPos;
    dword    	    	parentSize;
    Special  	    	*special;   /* Descriptor for this directory for setting
				     * the FA_HIDDEN bit on things it contains
				     * and for telling if files need to be in
				     * the localizable part of the filesystem
				     */
    struct _DirToProcess *next;
} DirToProcess;

DirToProcess *firstDir = NULL;
DirToProcess **lastDir = NULL;

/*
 * This structure records the memory fixups needed
 */

#define MEM_FIXUP_DIR_ENTRY 0
#define MEM_FIXUP_EXT_ATTRS 1
#define MEM_FIXUP_PARENT_POS 2
#define MEM_FIXUP_PARENT_SIZE 3

typedef struct _MemFixup {
    int	    	    	type;	    /* MEM_FIXUP_ */
    int    	    	offset;	    /* Offset from base of array */
    dword   	    	*fixupPos;   /* Memory address to point to fixup */
    struct _MemFixup	*next;
} MemFixup;

MemFixup *fixupPtr = NULL;

/*
 * Statistics
 */

int totalFiles = 0;
int totalGeosFiles = 0;
int totalDirs = 0;
int totalLinks = 0;

/***********************************************************************
 *
 * FUNCTION:	gfsopen
 *
 * DESCRIPTION:	Open a file
 *
 * CALLED BY:	INTERNAL
 *
 * STRATEGY:
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	4/14/93		Initial Revision
 *
 ***********************************************************************/
int
gfsopen(char *name)
{
    int fp;

    if ((fp = open(name, O_RDONLY | O_BINARY)) == -1) {
	gfserror("Cannot open file %s (error %d)\n", name, errno);
    }
    return(fp);
}


void gfsread(int handle, genptr buffer, unsigned int count, char *name)
{
#if 0
    if (debug) {
	printf("*** gfsread, pos = %ld, count = %d\n", tell(handle), count);
    }
#endif
    if (read(handle, buffer, count) != count) {
	gfserror("Error %d reading from file %s\n", errno, name);
    }
}


void gfswrite(int handle, genptr buffer, unsigned int count)
{
#if 0
    if (debug) {
	printf("*** gfswrite, pos = %ld, count = %d\n", tell(handle), count);
    }
#endif
    if (write(handle, buffer, count) != count) {
	gfserror("Error %d writing to output file\n", errno);
    }
}

void gfsclose(int handle, char *name)
{
    if (close(handle)) {
	gfserror("Error %d closing file %s\n", errno, name);
    }
}

void gfsseek(int handle, dword offset, int origin)
{
#if 0
    if (debug) {
	printf("*** gfsseek, pos = %ld, origin = %d\n", offset, origin);
    }
#endif
    if (lseek(handle, offset, origin) == -1) {
	gfserror("Error %d seeking in output file\n", errno);
    }
}

genptr gfsalloc(size_t sz)
{
    genptr foo;

    foo = calloc(1, sz);
    if (foo == NULL) {
	gfserror("Memory full.\n");
    }
    return(foo);
}

char *
gfsstrdup(char *str)
{
    char *cp;

    cp = strdup(str);
    if (cp == NULL) {
	gfserror("Memory full (in strdup)\n");
    }
    return(cp);
}

char *
strcpySbcsToDbcsMaybe(char *s1, char *s2)
{
    if (doDbcs) {
	char *dest = s1;

	do {
	    *s1++ = *s2;
	    *s1++ = '\0';
	} while (*s2++ != '\0');

	return dest;
    } else {
	return strcpy(s1, s2);
    }
}

/***********************************************************************
 *
 * FUNCTION:	DoFileHeader
 *
 * DESCRIPTION:	Process a GEOS file header
 *
 * CALLED BY:	ProcessDir
 *
 * STRATEGY:
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	4/14/93		Initial Revision

 *
 ***********************************************************************/
void
DoFileHeader(int fd,	    	/* file that contains the header */
	     char *name,    	/* file name */
	     GFSDirEntry *gdir,	/* directory entry to fill in */
	     GFSExtAttrs *gext	/* ext attr structure to fill in */
)
{
    GeosFileHeader gfh;

    gfsread(fd, (genptr) &gfh, sizeof(GeosFileHeader), name);
    if ((gfh.signature[0] == ('G' | (char) 0x80)) &&
	(gfh.signature[1] == 'E') &&
	(gfh.signature[2] == ('A' | (char) 0x80)) &&
	(gfh.signature[3] == 'S')) {

	/*
	 * It is really a GEOS file.  Copy attributes.
	 */

	gdir->attrs |= FA_GEOS;
	gext->attrs |= FA_GEOS;
	
	/* Longname */
	
	memcpy(&(gdir->longName), &gfh.longName, FILE_LONGNAME_LENGTH);
	
	/* Ext attrs */
	
	gext->flags = gfh.flags;
	memcpy(&(gext->release), &gfh.release, sizeof(ReleaseNumber));
	memcpy(&(gext->protocol), &gfh.protocol, sizeof(ProtocolNumber));
	memcpy(&(gext->token), &gfh.token, sizeof(GeodeToken));
	memcpy(&(gext->creator), &gfh.creator, sizeof(GeodeToken));
	memcpy(&(gext->userNotes), &gfh.userNotes,
	       	    	    	    	    GFH_USER_NOTES_BUFFER_SIZE);
	memcpy(&(gext->notice), &gfh.notice, GFH_NOTICE_SIZE);
	memcpy(&(gext->created), &gfh.created, sizeof(dword));
	memcpy(&(gext->desktop), &gfh.desktop, FILE_DESKTOP_INFO_SIZE);
	memcpy(&(gext->modified), &gfh.created, sizeof(dword));
	
	/* Geode attributes */
	
	if (SwapWord(gfh.type) == GFT_EXECUTABLE) {
	    gfsread(fd, (genptr) &(gext->geodeAttrs), 2, name);
	}
	
	/* Geos file type */
	
	gdir->type = SwapWord(gfh.type);
	gext->type = gfh.type;
    }
}

/***********************************************************************
 *
 * FUNCTION:	MakeMemFixup
 *
 * DESCRIPTION:	Create a memory fixup
 *
 * CALLED BY:	INTERNAL
 *
 * STRATEGY:
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	4/14/93		Initial Revision
 *
 ***********************************************************************/
void
MakeMemFixup(int type, dword *fixupPos, int index, int offset)
{
    MemFixup *fix;

    fix = (MemFixup *) gfsalloc(sizeof(MemFixup));
    fix->next = fixupPtr;
    fixupPtr = fix;
    fix->type = type;
    fix->fixupPos = fixupPos;
    if (type == MEM_FIXUP_DIR_ENTRY) {
	fix->offset = (index*DIR_ENTRY_REAL_SIZE)+offset;
    } else {
	if (alignSize) {
	    fix->offset = (index*EXT_ATTR_ALIGNED_SIZE)+offset;
	} else {
	    fix->offset = (index*EXT_ATTR_REAL_SIZE)+offset;
	}
    }
}

/***********************************************************************
 *
 * FUNCTION:	MakeFileFixup
 *
 * DESCRIPTION:	...
 *
 * CALLED BY:	INTERNAL
 *
 * STRATEGY:
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	4/15/93		Initial Revision
 *
 ***********************************************************************/
void
MakeFileFixup(char *filePath, int isGeosFile, int localize,
	      dword linkReadOffset, int index)
{
    FileFixup *fixup;

    fixup = (FileFixup *) gfsalloc(sizeof(FileFixup));
    if (firstFixup == NULL) {
	firstFixup = fixup;
    }
    if (lastFixup != NULL) {
	*lastFixup = fixup;
    }
    lastFixup = &(fixup->next);
    
    fixup->filePath = gfsstrdup(filePath);
    fixup->isGeosFile = isGeosFile ? 1 : 0;
    fixup->localize = localize ? 1 : 0;
    fixup->linkReadOffset = linkReadOffset;
    MakeMemFixup(MEM_FIXUP_DIR_ENTRY, &(fixup->dataFixupPos),
				 index, offsetof(GFSDirEntry, data));
    if (linkReadOffset) {
	MakeMemFixup(MEM_FIXUP_DIR_ENTRY, &(fixup->sizeFixupPos),
		     index, offsetof(GFSDirEntry, size));
	MakeMemFixup(MEM_FIXUP_EXT_ATTRS, &(fixup->sizeFixupPos2),
		     index, offsetof(GFSExtAttrs, size));
    }
}

/***********************************************************************
 *
 * FUNCTION:	AlignFile
 *
 * DESCRIPTION:	...
 *
 * CALLED BY:	INTERNAL
 *
 * STRATEGY:
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	4/14/93		Initial Revision
 *
 ***********************************************************************/
void
AlignFile(int fd, int alignment)
{
    dword i;
    char buf[500];
    
    memset(&buf, 0, sizeof(buf));
    i = (tell(fd)+alignment-1);
    i = (alignment-1) - (i % alignment);
    while (i > 0) {
	dword sz;
	sz = (i > 500) ? 500 : i;
	gfswrite(fd, (genptr) &buf, sz);
	i -= sz;
    }
}

/***********************************************************************
 *
 * FUNCTION:	CompareDirEntries
 *
 * DESCRIPTION:	Compare two directory entries.  This is a callback routine
 *	        for qsort
 *
 * CALLED BY:	INTERNAL
 *
 * STRATEGY:
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	4/19/93		Initial Revision
 *
 ***********************************************************************/
int
CompareDirEntries(const void *x, const void *y)
{
    char *sp, *dp;

    /*
     * Don't use strcmp, since it behaves differently on DOS
     */
    sp = ((DIRENT *)x)->d_name;
    dp = ((DIRENT *)y)->d_name;
    while (*sp == *dp) {
	/* Stop when both strings hit NUL terminator. */
	if (*sp == '\0') {
	    return(0);
	}
	sp++;   dp++;
    }
    return(toupper(*sp) - toupper(*dp));
}

/***********************************************************************
 *
 * FUNCTION:	ReadAndSortDir
 *
 * DESCRIPTION:	Read and sort a directory
 *
 * CALLED BY:	INTERNAL
 *
 * STRATEGY:
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	4/19/93		Initial Revision
 *
 ***********************************************************************/
DIRENT *
ReadAndSortDir(char *name, int *entryCount)
{
    DIR *dir;
    DIRENT *dirarray, *dirent, *entry;
    int count;

    /*
     * Open the directory and count the entries
     */

    if ((dir = opendir(name)) == NULL) {

#if defined(_MSDOS)
	/*
	 * Welcome to the wonderful world of DOS.  If the directory has no
	 * files in it then DOS returns us an error
	 */
	if (errno == ENOFILE) {
	    *entryCount = 0;
	    return((DIRENT *) gfsalloc(1));
	}
#endif

	gfserror("Cannot open directory: %s, error %d\n", name, errno);
    }
    count = 0;
    while ((entry = readdir(dir)) != NULL) {
	    /*
	     * bypass . and ..
	     */
	if (strcmp(entry->d_name, ".") && strcmp(entry->d_name, "..")) {
	    count++;
	}
    }
    closedir(dir);
    *entryCount = count;

    if (count == 0) {
	return((DIRENT *) gfsalloc(1));
    }
    /*
     * Allocate the array
     */
    dirent = dirarray = (DIRENT *) gfsalloc(count * sizeof(DIRENT));

    /*
     * Open the directory and and enumerate...
     */

    if ((dir = opendir(name)) == NULL) {
	gfserror("Cannot open directory: %s, error %d\n", name, errno);
    }
    count = 0;
    while ((entry = readdir(dir)) != NULL) {
	    /*
	     * bypass . and ..
	     */
	if (strcmp(entry->d_name, ".") && strcmp(entry->d_name, "..")) {
	    memcpy(dirent, entry, sizeof(DIRENT));
	    dirent++;
	    count++;
	}
    }
    if (count != *entryCount) {
	gfserror("Different directory count during second enumeration\n");
    }
    closedir(dir);

    /*
     * Sort it
     */
    qsort(dirarray, count, sizeof(DIRENT), CompareDirEntries);

    return(dirarray);

}

/***********************************************************************
 *
 * FUNCTION:	ProcessDir
 *
 * DESCRIPTION:	Process a directory
 *
 * CALLED BY:	CreateGFS
 *
 * STRATEGY:
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	4/14/93		Initial Revision
 *
 ***********************************************************************/

GFSDirEntry gdirs[MAX_DIRECTORY_SIZE];
GFSExtAttrs gextattrs[MAX_DIRECTORY_SIZE];

int	/* number of entries in directory */
ProcessDir(int destFile, char *name,
	   dword parentPos, dword parentSize,
	   dword *mypos,	/* position of this directory structure */
	   Special *special)  	/* Descriptor for this directory, for setting
				 * FA_HIDDEN for entries in the directory */
{
    DIRENT *dirarray, *entry;
    int entryCount;
    int index;
    int i;
    dword fpos;

    totalDirs++;

    memset(&gdirs, 0, sizeof(gdirs));
    memset(&gextattrs, 0, sizeof(gextattrs));

    /*
     * Add entries for . and ..
     */
    strcpySbcsToDbcsMaybe(gdirs[0].longName, ".");
    strncpy(gdirs[0].dosName, ".          ", DOS_NO_DOT_FILE_NAME_LENGTH);
    gdirs[0].attrs = FA_SUBDIR;
    gdirs[0].type = GFT_DIRECTORY;

    strcpySbcsToDbcsMaybe(gextattrs[0].longName, ".");
    strncpy(gextattrs[0].dosName, ".          ", DOS_NO_DOT_FILE_NAME_LENGTH);
    gextattrs[0].attrs = FA_SUBDIR;
    gextattrs[0].type = SwapWord(GFT_DIRECTORY);

    strcpySbcsToDbcsMaybe(gdirs[1].longName, "..");
    strncpy(gdirs[1].dosName, "..         ", DOS_NO_DOT_FILE_NAME_LENGTH);
    gdirs[1].attrs = FA_SUBDIR;
    gdirs[1].type = GFT_DIRECTORY;
    gdirs[1].data = SwapDWord(parentPos);
    gdirs[1].size = gextattrs[1].size = SwapDWord(parentSize);

    strcpySbcsToDbcsMaybe(gextattrs[1].longName, "..");
    strncpy(gextattrs[1].dosName, "..         ", DOS_NO_DOT_FILE_NAME_LENGTH);
    gextattrs[1].attrs = FA_SUBDIR;
    gextattrs[1].type = SwapWord(GFT_DIRECTORY);

    index = 2;	/* Start after . and .. */

    /*
     * We want to sort the directory before processing it since DOS and UNIX
     * give us the files in a different order
     */

    entry = dirarray = ReadAndSortDir(name, &entryCount);

    for (; entryCount != 0; entryCount--, entry++) {
	char pathbuf[100];
	int fd;
	struct stat statbuf;
	struct tm *now;
	dword timeStamp;
	Special	*s;

	/*
	 * Construct full name
	 */
	sprintf(pathbuf, "%s%s%s", name, QUOTED_SLASH, entry->d_name);

	if (special) {
	    for (s = special->firstChild; s != 0; s = s->nextSib) {
		if (strcmp(entry->d_name, s->name) == 0) {
		    break;
		}
	    }
	} else {
	    s = 0;
	}
	
	/*
	 * Get the file/directory attributes
	 */
	if (stat(pathbuf, &statbuf)) {
	    gfserror("Cannot stat %s, error %d", pathbuf, errno);
	}

#if defined(_WIN32)
	/*
	 * There is a bug on NT. The bit S_IWRITE is never set for a directory.
	 */
	if (statbuf.st_mode & S_IFDIR) 
	    statbuf.st_mode |= S_IWRITE;
#endif

	now = localtime(&statbuf.st_mtime);

#if defined(_MSDOS)
	/*
	 * DOS is stupid and does not seem to deal with daylight savings
	 * time correctly
	 */
	if (now->tm_isdst) {
	    time_t dorf;

	    dorf = statbuf.st_mtime + 60*60;
	    now = localtime(&dorf);
	}
#endif
	/*
	 * One other stupidity: Since DOS and UNIX don't agree on times
	 * for directories, we will stuff them
	 */
	if ((statbuf.st_mode & S_IFDIR) ||
	    !strcmp(entry->d_name, "@DIRNAME.000") ||
	    !strcmp(entry->d_name, "@dirname.000")) {
	    now->tm_hour = 9;
	    now->tm_min = 30;
	    now->tm_sec = 0;
	}
	timeStamp = (((dword) now->tm_hour << FDAT_HOUR_OFFSET) |
		     ((dword) now->tm_min << FDAT_MINUTE_OFFSET) |
		     (((dword) now->tm_sec >> 1) << FDAT_2SECOND_OFFSET) |
		     (((dword) now->tm_year-80) << FDAT_YEAR_OFFSET) |
		     (((dword) now->tm_mon+1) << FDAT_MONTH_OFFSET) |
		     ((dword) now->tm_mday << FDAT_DAY_OFFSET));
	timeStamp = SwapDWord(timeStamp);
	
	if (debug) {
	    printf("Processing %s, time = %s", entry->d_name, asctime(now));
	}
	
	if (!strcmp(entry->d_name, "@DIRNAME.000") ||
	    !strcmp(entry->d_name, "@dirname.000")) {
	    int sz;
	    /*
	     * This is the special file @DIRNAME.000, which contains the
	     * long name of the directory as well as any symbolic links
	     * in the directory.  We only deal with the symbolic links
	     * here,
	     */
	    fd = gfsopen(pathbuf);
	    gfsseek(fd, sizeof(GeosFileHeader), SEEK_SET);
	    do {
		DOSLinkHeader dlh;
		
		sz = read(fd, (genptr) &dlh, DOS_LINK_REAL_SIZE);
		if (sz == -1) {
		    gfserror("Error reading link from %s\n", pathbuf);
		}
		if (sz > 0) {
		    DOSLinkData dld;
		    /*
		     * Process a link
		     */
		    totalLinks++;
		    if (sz < DOS_LINK_REAL_SIZE) {
			gfserror("Error reading link from %s\n", pathbuf);
		    }
		    gdirs[index].attrs = gextattrs[index].attrs = FA_LINK;
		    memset(&(gdirs[index].dosName), ' ',
			   DOS_NO_DOT_FILE_NAME_LENGTH);
		    memset(&(gextattrs[index].dosName), ' ',
			   DOS_NO_DOT_FILE_NAME_LENGTH);
		    memcpy(&(gdirs[index].longName),
			   &dlh.longName, FILE_LONGNAME_LENGTH);
		    memcpy(&(gextattrs[index].longName),
			   &dlh.longName, FILE_LONGNAME_LENGTH);
		    gextattrs[index].flags = dlh.flags;
		    memcpy(&(gextattrs[index].release),
			   &dlh.release, sizeof(ReleaseNumber));
		    memcpy(&(gextattrs[index].protocol),
			   &dlh.protocol, sizeof(ProtocolNumber));
		    memcpy(&(gextattrs[index].token),
			   &dlh.token, sizeof(GeodeToken));
		    memcpy(&(gextattrs[index].creator),
			   &dlh.creator, sizeof(GeodeToken));
		    gextattrs[index].created = timeStamp;
		    gextattrs[index].modified = timeStamp;
		    memcpy(&(gextattrs[index].desktop),
			   &dlh.desktop, FILE_DESKTOP_INFO_SIZE);
		    gdirs[index].type = SwapWord(dlh.type);
		    gextattrs[index].type = dlh.type;
		    
		    MakeFileFixup(pathbuf, 0, 0, tell(fd), index);
		    
		    gfsread(fd, (genptr) &dld, DOS_LINK_DATA_REAL_SIZE,
			    pathbuf);
		    gfsseek(fd, SwapWord(dld.diskSize) +
			    SwapWord(dld.pathSize) +
			    SwapWord(dld.extraDataSize), SEEK_CUR);
		    
		    if (++index > MAX_DIRECTORY_SIZE) {
			gfserror("Directory too large: %s\n", name);
		    }
		}
	    } while (sz != 0);
	    gfsclose(fd, pathbuf);
	} else {
	    char *sp, *dp;
	    int count;
	    
	    /*
	     * Start filling out the GFSDirEntry
	     */
	    
	    /* DOS name */
	    
	    for (sp = entry->d_name, dp = gdirs[index].dosName, count = 8;
		 (*sp != '.') && (*sp != '\0') && (count > 0);
		 sp++, dp++, count--) {
		*dp = toupper(*sp);
	    }
	    while (count > 0) {
		*dp++ = ' ';
		count--;
	    }
	    while ((*sp != '\0') && (*sp != '.')) {
		sp++;
	    }
	    if (*sp == '.') {
		sp++;
	    }
	    count = 3;
	    while ((*sp != '\0') && (count > 0)) {
		*dp = toupper(*sp);
		sp++;   dp++;
		count--;
	    }
	    while (count > 0) {
		*dp++ = ' ';
		count--;
	    }
	    memcpy(&(gextattrs[index].dosName), &(gdirs[index].dosName),
		   DOS_NO_DOT_FILE_NAME_LENGTH);
	    
	    /* File attributes */
	    
	    gdirs[index].attrs = gextattrs[index].attrs =
		((statbuf.st_mode & S_IFDIR) ? FA_SUBDIR : 0) |
		    ((statbuf.st_mode & S_IWRITE) ? 0 : FA_RDONLY) |
			((s != 0 && (s->flags & SF_HIDDEN)) ? FA_HIDDEN : 0);
	    
	    /* Date and time */
	    
	    gextattrs[index].created = timeStamp;
	    gextattrs[index].modified = timeStamp;
	    
	    if (statbuf.st_mode & S_IFDIR) {
		DirToProcess *dtp;
		char newbuf[300];
		/*
		 * The entry is a directory.  We need to set up the
		 * attributes that we can and enter another directory
		 * to be processed.
		 */
		dtp = (DirToProcess *) gfsalloc(sizeof(DirToProcess));
		if (firstDir == NULL) {
		    firstDir = dtp;
		}
		if (lastDir != NULL) {
		    *lastDir = dtp;
		}
		lastDir = &(dtp->next);
		
		dtp->filePath = gfsstrdup(pathbuf);
		dtp->special = s;
		MakeMemFixup(MEM_FIXUP_DIR_ENTRY,
			     &(dtp->dataFixupPos),
			     index, offsetof(GFSDirEntry, data));
		MakeMemFixup(MEM_FIXUP_DIR_ENTRY,
			     &(dtp->sizeFixupPos),
			     index, offsetof(GFSDirEntry, size));
		MakeMemFixup(MEM_FIXUP_EXT_ATTRS,
			     &(dtp->sizeFixupPos2),
			     index, offsetof(GFSExtAttrs, size));
		
		MakeMemFixup(MEM_FIXUP_PARENT_POS,
			     &(dtp->parentPos), 0, 0);
		MakeMemFixup(MEM_FIXUP_PARENT_SIZE,
			     &(dtp->parentSize), 0, 0);
		/*
		 * Look for an @DIRNAME.000 file that would
		 * contain a longname
		 */
		strcpy(newbuf, pathbuf);
		strcat(newbuf, QUOTED_SLASH "@DIRNAME.000");
		if ((fd = open(newbuf, O_RDONLY | O_BINARY)) == -1) {
		    strcpy(newbuf, pathbuf);
		    strcat(newbuf, QUOTED_SLASH "@dirname.000");
		    fd = open(newbuf, O_RDONLY | O_BINARY);
		}
		if (fd == -1) {
		    char *cp;
		    /*
		     * No @DIRNAME.000, therefore no long name
		     * Upcase the name so that the DOS and UNIX versions
		     * will produce the same output
		     */
		    if (doDbcs) {
			char *cp0 = entry->d_name;
			for (cp = gdirs[index].longName; *cp0 != '\0'; cp += 2,
			     cp0++) {
			    *cp = toupper(*cp0);
			    *(cp+1) = '\0';
			}
			*cp = '\0';
			*(cp+1) = '\0';
		    } else {
			strcpy(gdirs[index].longName, entry->d_name);
			for (cp = gdirs[index].longName; *cp != '\0'; cp++) {
			    *cp = toupper(*cp);
			}
		    }
		    gdirs[index].type = GFT_DIRECTORY;
		    gextattrs[index].type = SwapWord(GFT_DIRECTORY);
		} else {
		    /*
		     * @DIRNAME.000 exists, read the long name and attrs
		     */
		    DoFileHeader(fd, newbuf, &gdirs[index],
				 &gextattrs[index]);
		    gfsclose(fd, pathbuf);
		}
	    } else {
		/*
		 * The entry is a file.
		 */
		
		totalFiles++;
		fd = gfsopen(pathbuf);
		if (statbuf.st_size >= sizeof(GeosFileHeader)) {
		    DoFileHeader(fd, pathbuf, &gdirs[index],
				 &gextattrs[index]);
		    
		    /* File size */
		    
		    gdirs[index].size = gextattrs[index].size =
			SwapDWord(statbuf.st_size-sizeof(GeosFileHeader));
		}
		if (SwapWord(gdirs[index].type) == GFT_NOT_GEOS_FILE) {
		    char *cp;
		    
		    /*
		     * This is not a GEOS file, so set attr accordingly
		     * Upcase the name so that the DOS and UNIX versions
		     * will produce the same output
		     */
		    
		    /* Longname */
		    
		    if (doDbcs) {
			char *cp0 = entry->d_name;
			for (cp = gdirs[index].longName; *cp0 != '\0'; cp += 2,
			     cp0++) {
			    *cp = toupper(*cp0);
			    *(cp+1) = '\0';
			}
			*cp = '\0';
			*(cp+1) = '\0';
		    } else {
			strcpy(gdirs[index].longName, entry->d_name);
			for (cp = gdirs[index].longName; *cp != '\0'; cp++) {
			    *cp = toupper(*cp);
			}
		    }
		    
		    /* Size */
		    
		    gdirs[index].size = gextattrs[index].size =
			SwapDWord(statbuf.st_size);
		} else {
		    totalGeosFiles++;
		}
		
		gfsclose(fd, pathbuf);
		
		/*
		 * Allocate file space for the file and create a fixup
		 * structure. Place the file in localizable space if either
		 * it or its parent directory is so marked.
		 */
		MakeFileFixup(pathbuf, gdirs[index].attrs & FA_GEOS,
			      ((s ? (s->flags & SF_LOCAL) : 0) |
			       (special ? (special->flags & SF_LOCAL) : 0)),
			      0, index);
	    }
	    
	    /*
	     * Copy common fields from dirEntry to ext attr entry
	     */
	    memcpy(&(gextattrs[index].longName), &(gdirs[index].longName),
		   FILE_LONGNAME_LENGTH);
	    
	    if (++index > MAX_DIRECTORY_SIZE) {
		gfserror("Directory too large: %s\n", name);
	    }
	} /* not @DIRNAME.000 */
    } /* for entry */
    free(dirarray);

    /*
     * Since we now know the size of the directory, we can deal with
     * alignment
     */
    if (alignSize) {
	if ((tell(destFile)%alignSize)+(index*DIR_ENTRY_REAL_SIZE)
	    	    	    	    	    	    	> alignSize) {
	    AlignFile(destFile, alignSize);
	}
    }

    /*
     * We now know the real position of the directory structure, so we
     * can do the fixups, but first we must calulate the position of the
     * ext attr array
     */
    fpos = tell(destFile) + (DIR_ENTRY_REAL_SIZE * index);
    if (alignSize) {
	fpos = (fpos + (EXT_ATTR_ALIGNED_SIZE-1)) / EXT_ATTR_ALIGNED_SIZE;
	fpos = fpos * EXT_ATTR_ALIGNED_SIZE;
    }
    while (fixupPtr != NULL) {
	MemFixup *fp;

        fp = fixupPtr;
	fixupPtr = fp->next;
	switch (fp->type) {
	    case MEM_FIXUP_DIR_ENTRY : {
		*(fp->fixupPos) = tell(destFile)+fp->offset;
		break;
	    }
	    case MEM_FIXUP_EXT_ATTRS : {
		*(fp->fixupPos) = fpos + fp->offset;
		break;
	    }
	    case MEM_FIXUP_PARENT_POS : {
		*(fp->fixupPos) = tell(destFile);
		break;
	    }
	    case MEM_FIXUP_PARENT_SIZE : {
		*(fp->fixupPos) = index;
		break;
	    }
	}
    	free(fp);
    }
    fixupPtr = NULL;

    /*
     * Fixup references in the directory entry for .
     */
    fpos = tell(destFile);
    gdirs[0].data = SwapDWord(fpos);
    gdirs[0].size = gextattrs[0].size = SwapDWord(index);
    if (parentSize == -1) {
	/*
	 * this is the root directory, so point .. to the same place
	 */
    	gdirs[1].data = SwapDWord(fpos);
	gdirs[1].size = gextattrs[1].size = SwapDWord(index);
    }
    
    /*
     * Write out the directory entries
     */
    for (i = 0; i < index; i++) {
    	gfswrite(destFile, (genptr) &gdirs[i], DIR_ENTRY_REAL_SIZE);
    }

    /*
     * Align if needed
     */
    if (alignSize > 0) {
	AlignFile(destFile, EXT_ATTR_ALIGNED_SIZE);
    }

    /*
     * Write out the extended attribute structures
     */
    for (i = 0; i < index; i++) {
	gfswrite(destFile, (genptr) &gextattrs[i], EXT_ATTR_REAL_SIZE);
	if (alignSize) {
	    char buf[EXT_ATTR_ALIGNED_SIZE-EXT_ATTR_REAL_SIZE];
	    /*
	     * If there is any alignment the pad to EXT_ATTR_ALIGNED_SIZE
	     */
	    memset(&buf, 0, sizeof(buf));
	    gfswrite(destFile, buf, sizeof(buf));
	}
    }
    *mypos = fpos;  /* set the offset of this directory structure */
    return(index);  /* return number of directory entries */
}

/***********************************************************************
 *
 * FUNCTION:	CreateGFS
 *
 * DESCRIPTION:	Create a GFS file system
 *
 * CALLED BY:	main
 *
 * STRATEGY:
 *	Creating a GFS file system is a pseudo two-pass process.  The first
 *	pass is a recursive traversal of the directory tree where the
 *	directory structures are built and written out.  While this is
 *	happening we create a list of all the files that need to be written
 *	out.  We also create a list of the pointers to files, so that we can
 *	go back and fix these up as well.
 *
 *	The second pass is a traversal of the file list, writing out each
 *	file.
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	4/14/93		Initial Revision
 *
 ***********************************************************************/
void
CreateGFS(int destFile, GFSFileHeader *fileHeader, char *volumeName,
	  dword limit)
{
    dword count;
    FileFixup *ff;
    GFSDirEntry gdir;
    GFSExtAttrs gext;
    dword pos, dirpos;
    dword totalSize;
    char *buf;
    dword checksum;

    char checkbuf[20];
    long locBase, nonLocBase, *locBasePtr, *nonLocBasePtr;
    char *cp;
    dword d;

    /*
     * First write out the header (we will fill in the checksum later)
     */
    gfswrite(destFile, (genptr) fileHeader, sizeof(GFSFileHeader));

    /*
     * Write out the directory entry for the root
     */
    memset(&gdir, 0, sizeof(gdir));
    strcpySbcsToDbcsMaybe(gdir.longName, volumeName);
    gdir.attrs = FA_GEOS | FA_SUBDIR;
    gdir.type = GFT_DIRECTORY;
    gdir.data = sizeof(GFSFileHeader) + DIR_ENTRY_REAL_SIZE
	    	    + EXT_ATTR_REAL_SIZE;
    gfswrite(destFile, (genptr) &gdir, DIR_ENTRY_REAL_SIZE);

    memset(&gext, 0, sizeof(gext));
    strcpySbcsToDbcsMaybe(gext.longName, volumeName);
    gext.attrs = FA_GEOS | FA_SUBDIR;
    gext.type = SwapWord(GFT_DIRECTORY);
    gfswrite(destFile, (genptr) &gext, EXT_ATTR_REAL_SIZE);

    /*
     * Seek to where we're supposed to place directories.
     */
    gfsseek(destFile, dirBase, SEEK_SET);

    /*
     * Prime the sucker by putting an initial directory in the list to
     * process
     */
    firstDir = (DirToProcess *) gfsalloc(sizeof(DirToProcess));
    lastDir = &(firstDir->next);
    firstDir->filePath = gfsstrdup("."); /* dup because we will free later */
    firstDir->dataFixupPos = sizeof(GFSFileHeader)
	    	    	    	    + offsetof(GFSDirEntry, data);
    firstDir->sizeFixupPos = sizeof(GFSFileHeader)
	    	    	    	    + offsetof(GFSDirEntry, size);
    firstDir->sizeFixupPos2 = sizeof(GFSFileHeader) + DIR_ENTRY_REAL_SIZE +
	    	    	    	    + offsetof(GFSExtAttrs, size);
    firstDir->parentPos = tell(destFile);
    firstDir->parentSize = -1;	    /* signal root directory */
    firstDir->special = root;

    /*
     * Process all the directories that we have accumulated
     */
    while (firstDir != NULL) {
	DirToProcess *dtp;

	/*
	 * Pluck the next directory off the head of the queue.
	 */
	dtp = firstDir;
	firstDir = firstDir->next;
	if (firstDir == NULL) {
	    lastDir = NULL;
	}
	
	if (debug) {
	    printf("*** Processing directory %s (%ld, %ld, %ld)\n",
		   dtp->filePath, dtp->dataFixupPos, dtp->sizeFixupPos,
		   dtp->sizeFixupPos2);
	}

	/*
	 * Fixup the relevant pointers
	 */
	count = ProcessDir(destFile, dtp->filePath,
			   dtp->parentPos, dtp->parentSize,
			   &dirpos, dtp->special);
	dirpos = SwapDWord(dirpos);
	gfsseek(destFile, dtp->dataFixupPos, SEEK_SET);
	gfswrite(destFile, (genptr) &dirpos, 4);
	count = SwapDWord(count);
	gfsseek(destFile, dtp->sizeFixupPos, SEEK_SET);
	gfswrite(destFile, (genptr) &count, 4);
	gfsseek(destFile, dtp->sizeFixupPos2, SEEK_SET);
	gfswrite(destFile, (genptr) &count, 4);
	gfsseek(destFile, 0, SEEK_END);
	free(dtp->filePath);
	free(dtp);
    }

    gfsseek(destFile, 0, SEEK_END);
    locBase = tell(destFile);
    locBasePtr = &locBase;
    
    if (fileBase != 0) {
	nonLocBase = fileBase;
	nonLocBasePtr = &nonLocBase;
    } else {
	/*
	 * No localizable portion, so use the same variable.
	 */
	nonLocBasePtr = &locBase;
    }

    /*
     * Initialize the checksum
     */
    checksum = 0x43e809f1;
    
    /*
     * Write out all of the files
     */

    buf = gfsalloc(COPY_BUF_SIZE);
    while (firstFixup != NULL) {
	int fd;
	dword num, copySize;

	ff = firstFixup;
	firstFixup = ff->next;

	/*
	 * Figure out how big the thing is and write that out, as
	 * appropriate.
	 */
	fd = gfsopen(ff->filePath);
	if (ff->linkReadOffset) {
	    DOSLinkData dld;
	    dword xsize;

	    /*
	     * Reading from a link, get size to copy
	     */
	    gfsseek(fd, ff->linkReadOffset, SEEK_SET);
	    gfsread(fd, (genptr) &dld, DOS_LINK_DATA_REAL_SIZE, ff->filePath);
	    gfsseek(fd, ff->linkReadOffset, SEEK_SET);
	    copySize = DOS_LINK_DATA_REAL_SIZE + SwapWord(dld.diskSize) +
		    	SwapWord(dld.pathSize) + SwapWord(dld.extraDataSize);
	    /*
	     * Deal with size fixups
	     */
	    xsize = SwapDWord(copySize);
	    gfsseek(destFile, ff->sizeFixupPos, SEEK_SET);
	    gfswrite(destFile, (genptr) &xsize, 4);
	    gfsseek(destFile, ff->sizeFixupPos2, SEEK_SET);
	    gfswrite(destFile, (genptr) &xsize, 4);
	} else {
	    gfsseek(fd, 0, SEEK_END);
	    copySize = tell(fd);
	    if (ff->isGeosFile) {
		gfsseek(fd, sizeof(GeosFileHeader), SEEK_SET);
		copySize -= sizeof(GeosFileHeader);
	    } else {
		gfsseek(fd, 0, SEEK_SET);
	    }
	}

	/*
	 * Figure to what part of the filesystem we should copy the file.
	 */
	if (ff->localize ||
	    (fileBase && *nonLocBasePtr + copySize > dirBase))
	{
	    /*
	     * File must be localizable, or it won't fit in the non-localizable
	     * portion of the filesystem.
	     */
	    pos = *locBasePtr;
	    *locBasePtr += copySize;
	} else {
	    /*
	     * File needs no localization & will fit in the non-localizable
	     * part of the filesystem.
	     */
	    pos = *nonLocBasePtr;
	    *nonLocBasePtr += copySize;
	}

	/*
	 * Fixup the directory entry to show where the data are going.
	 */
	pos = SwapDWord(pos);
	gfsseek(destFile, ff->dataFixupPos, SEEK_SET);
	gfswrite(destFile, (genptr) &pos, 4);

	gfsseek(destFile, SwapDWord(pos), SEEK_SET);

	
	if (debug) {
	    printf("Writing out %slocalizable file %s at position %ld (%08lx), size %ld\n",
		   ff->localize ? "" : "non-", ff->filePath, SwapDWord(pos), SwapDWord(pos), copySize);
	}

	do {
	    num = read(fd, buf,
		       COPY_BUF_SIZE > copySize ? copySize : COPY_BUF_SIZE);
	    if (num == -1) {
		gfserror("Error reading file %s for copy\n",
			 ff->filePath);
	    }
	    copySize -= num;
	    if (num > 0) {
		/*
		 * If we are using a data-only based checksum then compute it
		 */
		if (dataOnlyChecksum) {
		    for (d = num, cp = buf; d > 0; d--) {
			checksum = ((checksum << 5) + checksum) +
			    (unsigned char) *cp++;
		    }
		}
		gfswrite(destFile, buf, num);
	    }
	} while ((copySize > 0) && (num > 0));
	gfsclose(fd, ff->filePath);

	free(ff->filePath);
	free(ff);
    }

    if ((fileBase != 0) && (nonLocBase > dirBase)) {
	gfserror("Non-localizable data overlapped localizable area by %ld byte%s",
		 nonLocBase - dirBase, nonLocBase - dirBase == 1 ? "" : "s");
    }

    /*
     * Write out the total size
     */
    gfsseek(destFile, 0, SEEK_END);
    totalSize = tell(destFile);
    pos = SwapDWord(totalSize);
    gfsseek(destFile, offsetof(GFSFileHeader, totalSize), SEEK_SET);
    gfswrite(destFile, (genptr) &pos, 4);
    
    /*
     * If we are not using a data-only based checksum then compute it
     */
    if (!dataOnlyChecksum) {
	gfsseek(destFile, 0, SEEK_SET);
	do {
	    d = pos = read(destFile, buf, COPY_BUF_SIZE);
	    if (pos == -1) {
		gfserror("Error reading from destination file");
	    }
	    cp = buf;
	    while (d > 0) {
		checksum = ((checksum << 5) + checksum) + (unsigned char) *cp++;
		d--;
	    }
	} while (pos > 0);
    }
    free(buf);

    if (debug) {
	printf("Checksum is %lx\n", checksum);
    }

    gfsseek(destFile, offsetof(GFSFileHeader, checksum), SEEK_SET);
    sprintf(checkbuf, "%08lx", checksum);
    gfswrite(destFile, (genptr) &checkbuf, 8);

    /*
     * Give a bit of interesting statistical info
     */
    printf("\nGFS file system '%s' created\n", volumeName);
    printf("%d directories, %d files, %d GEOS files, %d links, %ld bytes\n",
	   totalDirs, totalFiles, totalGeosFiles, totalLinks, totalSize);

    if (limit != 0 && totalSize > limit) {
	printf("\n\nFILE SYSTEM IS %d BYTES LARGER THAN ALLOWED %ld BYTES\n",
	       totalSize - limit, limit);
    }
}
