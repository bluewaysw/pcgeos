/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  GFS (GEOS file system)
 * FILE:	  list.c
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
"$Id: list.c,v 1.3 97/04/28 16:34:06 clee Exp $";

#endif lint

#include    "gfs.h"

void listread(int handle, dword pos, genptr buffer, unsigned int count)
{
    if (lseek(handle, pos, SEEK_SET) == -1) {
	gfserror("Error seeking in input file\n");
    }
    if (read(handle, buffer, count) != count) {
	gfserror("Error reading from input file\n");
    }
}

/***********************************************************************
 *
 * FUNCTION:	PrintEntry
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
PrintEntry(GFSDirEntry *dir, GFSExtAttrs *extattr)
{
    char dname[20];

    if (dir->size != extattr->size) {
	gfserror("Sizes differ between dir entry and ext attrs: %s\n",
		 dir->longName);
    }
    if (dir->type != SwapWord(extattr->type)) {
	gfserror("Types differ between dir entry and ext attrs: %s\n",
		 dir->longName);
    }
    if (memcmp(&(dir->longName), &(extattr->longName),
	       FILE_LONGNAME_LENGTH)) {
	gfserror("Long names differ between dir entry and ext attrs: %s\n",
		 dir->longName);
    }
    if (memcmp(&(dir->dosName), &(extattr->dosName),
	       DOS_NO_DOT_FILE_NAME_LENGTH)) {
	gfserror("DOS names differ between dir entry and ext attrs: %s\n",
		 dir->longName);
    }

    strncpy(dname, dir->dosName, 8);
    strcpy(dname+8, ".");
    strncpy(dname+strlen(dname), (dir->dosName)+8, 3);
    strcpy(dname+12, "");

    printf("%.32s (%s), type = %d, %s%s%s%s%s\n", dir->longName, dname, dir->type,
	   dir->attrs & FA_HIDDEN ? "H" : "",
	   dir->attrs & FA_SUBDIR ? "D" : "",
	   dir->attrs & FA_RDONLY ? "R" : "",
	   dir->attrs & FA_LINK ? "L" : "",
	   dir->attrs & FA_GEOS ? "G" : "");
}

/***********************************************************************
 *
 * FUNCTION:	ListDir
 *
 * DESCRIPTION:	List a directory
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
ListDir(int sourceFile, dword dirPos, dword extattrPos, int indent)
{
    GFSDirEntry dir;
    GFSExtAttrs extattr;
    int count;

    /*
     * Read the directory entry for this directory
     */
    listread(sourceFile, dirPos, (genptr) &dir, DIR_ENTRY_REAL_SIZE);
    listread(sourceFile, extattrPos, (genptr) &extattr, EXT_ATTR_REAL_SIZE);
    count = SwapDWord(dir.size);

    printf("%*sDir(%d): ", indent, "", count);
    PrintEntry(&dir, &extattr);

    /*
     * Point at the two directory arrays
     */
    dirPos = SwapDWord(dir.data);
    extattrPos = dirPos + (count * DIR_ENTRY_REAL_SIZE);
    if (alignSize) {
	extattrPos = (extattrPos + (EXT_ATTR_ALIGNED_SIZE-1)) /
	    	    	    	    	    EXT_ATTR_ALIGNED_SIZE;
	extattrPos = extattrPos * EXT_ATTR_ALIGNED_SIZE;
    }

    /*
     * Now list the contents
     */
    indent += 3;
    while (count-- > 0) {
	/*
	 * Read the entry
	 */
    	listread(sourceFile, dirPos, (genptr) &dir, DIR_ENTRY_REAL_SIZE);
	listread(sourceFile, extattrPos, (genptr) &extattr,
		    	    	    	    	EXT_ATTR_REAL_SIZE);

	if (dir.type == GFT_DIRECTORY) {
	    /*
	     * It is a directory, list it
	     */
	    if (strcmp(dir.longName, ".") && strcmp(dir.longName, "..")) {
		ListDir(sourceFile, dirPos, extattrPos, indent);
	    } else {
		if (debug) {
		    printf("%*s", indent, "");
		    PrintEntry(&dir, &extattr);
		}
	    }
	} else if (dir.attrs & FA_LINK) {
	    /*
	     * It is a link
	     */
	    printf("%*sLink: ", indent, "");
	    PrintEntry(&dir, &extattr);
	} else {
	    /*
	     * It is a file
	     */
	    printf("%*s", indent, "");
	    PrintEntry(&dir, &extattr);
	}

	dirPos += DIR_ENTRY_REAL_SIZE;
	if (alignSize) {
	    extattrPos += EXT_ATTR_ALIGNED_SIZE;
	} else {
	    extattrPos += EXT_ATTR_REAL_SIZE;
	}
    }
}

/***********************************************************************
 *
 * FUNCTION:	ListGFS
 *
 * DESCRIPTION:	List a GFS file system
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
ListGFS(int sourceFile)
{
    GFSFileHeader fileHeader;
    char *sp;

    /*
     * Read the file header
     */

    listread(sourceFile, 0, (genptr) &fileHeader, sizeof(GFSFileHeader));

    if (strncmp(fileHeader.signature, "GFS:", 4)) {
	gfserror("Bad signature in GFS file\n");
    }

    printf("Description: ");
    for (sp = &(fileHeader.description[0]); *sp != '\032'; sp++) {
	putchar(*sp);
    }
    printf(", version %d.%d, %ld bytes\n\n", SwapWord(fileHeader.versionMajor),
	   SwapWord(fileHeader.versionMinor), SwapDWord(fileHeader.totalSize));

    /*
     * Start listing directories, starting from the root
     */
    ListDir(sourceFile, sizeof(GFSFileHeader),
	    sizeof(GFSFileHeader) + DIR_ENTRY_REAL_SIZE, 0);

}
