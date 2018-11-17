#ifndef __INSTALLER_H_
#define __INSTALLER_H_
#include <sem.h>

#define SIGNATURE_STR "GlobalPC"
#define H_V_MAJOR 1
#define H_V_MINOR 0
#define S_V_MAJOR 1
#define S_V_MINOR 3

/* Package files for version 1.0 are not zipped. */
#define S_V_MAJOR_1_0 1
#define S_V_MINOR_1_0 0

#define NAME_LEN 256
#define NOTES_LEN 256
#define AUTHOR_LEN 128
#define PATH_LEN 256

#define PT_GEOS_APP 1
#define PT_DOS_APP 2
#define PT_SYSTEM_UPDATE 3

/*
 * Package file contains only other package files that are to be installed
 * once this file has been unpacked.  This file may be removed once the
 * sub-package files have been installed.
 */
#define PT_MULTI_PAK 4

/*
 * Package contains other GEOS data files, such as clip art, templates,
 * crossword puzzles, thesaures, etc.  This is a special category since
 * these files may be installed anywhere in the GEOS tree and, as such,
 * the files must be uninstalled file by file.  Standard uninstall is to
 * remove the whole install directory (this is SWMgr functionality..
 * uninstall is not part of instlr library).
 */
#define PT_GEOS_DATA_FILES 5

/*
 * Fonts require special handling.
 */
#define PT_GEOS_FONT 6

/*
 * Print drivers require special handling.
 */
#define PT_GEOS_PRINT_DRIVER 7

/* Error checking.. if a package type is added, modify this appropriately. */
#define PT_LAST_PACKAGE_TYPE (PT_GEOS_PRINT_DRIVER)


#define BLOCK_SIZE 4096*4
#define MAX_LINE_LEN 1024

typedef enum {
  IE_NO_ERROR = 0,
  IE_NEXT_DISK,
  IE_USER_QUIT,

  IE_NO_MORE_MEMORY,
  IE_OPEN_FILE_ERROR,
  IE_CREATE_FILE_ERROR,
  IE_CREATE_LINK_FILE_ERROR,
  IE_CREATE_DIR_ERROR,
  IE_FILE_READING_ERROR,
  IE_FILE_WRITING_ERROR,
  IE_WRONG_DISK_ERROR,
  IE_WRONG_PACKAGE_TYPE_ERROR,

  IE_CHECKSUM_ERROR,
  IE_WRONG_SIGNATURE,
  IE_SAME_VERSION
} InstallError;

#define IE_DONE IE_NO_ERROR

typedef struct {
  char FS_signature[8];
  word FS_hvmajor;
  word FS_hvminor;
  word FS_svmajor;
  word FS_svminor;
} FileSignature;

typedef struct {
  TCHAR DH_name[NAME_LEN];
  word DH_numDisks;
  word DH_diskNum;
  TCHAR DH_next[PATH_LEN];
  word DH_checksum;
} DiskHeader;

typedef struct {
  TCHAR PH_name[NAME_LEN];
  TCHAR PH_note[NOTES_LEN];
  TCHAR PH_author[AUTHOR_LEN];
  TCHAR PH_mainProg[PATH_LEN];
  TCHAR PH_readme[PATH_LEN];
  TCHAR PH_installPath[PATH_LEN];
  TCHAR PH_linkPath[PATH_LEN];
  TCHAR PH_iniFile[PATH_LEN];
  TCHAR PH_setupGeos[PATH_LEN];
  word PH_verMajor;
  word PH_verMinor;
  word PH_sysMajor;
  word PH_sysMinor;
  word PH_totalFiles;
  word PH_type;
  word PH_day;
  word PH_mon;
  word PH_year;
  word PH_checksum;
} PackageHeader;

typedef struct {
  TCHAR FH_name[PATH_LEN];
  dword FH_size;
  word FH_checksum;
} FileHeader;

typedef struct {
  MemHandle FLE_next;		// Handle to block containing FileListEntry
  word FLE_fileNameOffset;	// Offset into this block for string
} FileListEntry;

#define FLE_fileName(_pfle) ((char *)(_pfle) + (_pfle)->FLE_fileNameOffset)

typedef struct {
  word FL_numFiles;
  DiskHandle FL_SPorDisk;
  word FL_pathTailOffset;	// Offset into this block for string
  MemHandle FL_files;		// Handle to block containing FileListEntry
} FileList;

#define FL_pathTail(_pfl) ((char *)(_pfl) + (_pfl)->FL_pathTailOffset)
  
typedef struct {
  FileHandle IS_outFHandle;
  FileHeader IS_currentFHeader;
  void *IS_buffer;
  word IS_currentFileNum;
  word IS_currentDiskNum;
  MemHandle IS_fileList;	/* Initialize with RecordFileList if you want
				 * to record all of the files installed.
				 * You must free this with FreeFileList.
				 * Type: FileList.
				 */
} InstallState;


#define min(a,b) ((a)>(b)?(b):(a))

InstallError GetFileSignature(FileHandle fh, 
			      FileSignature *fs);

InstallError GetDiskHeader(FileHandle fh, 
			   DiskHeader *dHeader);

InstallError GetPackageHeader(FileHandle fh, 
			      PackageHeader *pHeader);

InstallError InstallPackage(FileHandle fh, 
			    DiskHeader *dHeader, 
			    PackageHeader *pHeader, 
			    InstallState *state,
			    optr progressBar, 
			    Boolean *stopFlag,
			    SemaphoreHandle stopSem);

void CheckFileNameDOS(TCHAR *filename);

extern
void  _pascal InstallPackageINI(FileHandle fh);
#endif

/*
 * Pass in an InstallState (before calling InstallPackage) and this will
 * allocate the FileList and cause the library to record all filenames
 * of all of the files that get installed.  Should be called from the
 * top level of the installation directory so that the FL_stdPath and
 * FL_pathTail are filled in correctly.  (It retrieves this via
 * FileGetCurrentPath, which will include a Standard Path and a tail.)
 */
extern void _pascal RecordFileList(InstallState *state);

/*
 * Pass in an block containing a FileList (which in turn contains a linked
 * list).  This file list was created if RecordFileList was called before
 * InstallPackage and can be found in InstallState->IS_fileList.
 */
extern void _pascal FreeFileList(MemHandle hFileList);

/***********************************************************************
 *		InstlrOpenFile
 ***********************************************************************
 *
 * SYNOPSIS:	Opens the passed install file and checks its signature.
 *		If the install file is zipped, it is unzipped to a
 *		temporary file and its full path copied to tempfile.
 *		The caller must delete the temporary file after it has
 *		finished with it.
 *
 * CALLED BY:	GLOBAL
 *
 * PASS:	filename - name of install file
 * 		tempfile - buffer for path of temporary file
 *
 * RETURN:	If error, returns reason
 * 		If successful, returns IE_NO_ERROR
 *		  *pfh = FileHandle of (unzipped) install file
 *		  If install file was zipped,
 *		    tempfile = full path of temporary file
 *		  else
 *		    tempfile = ""
 *
 * SIDE EFFECTS:temporary file created for unzipped install
 *
 ***********************************************************************/
InstallError
InstlrOpenFile (const TCHAR *filename, PathName tempfile, FileHandle *pfh);
