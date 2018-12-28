/* zip.h -- IO for compress .zip files using zlib 
   Version 0.15 alpha, Mar 19th, 1998,

   Copyright (C) 1998 Gilles Vollant

********************* GEOS ************************************************
Condition of use and distribution require the following note:

	ALL Routines in this library are modified to benfit GEOS requirements
	Some Rountiens and structures are added. Under this circumstands it
	is likely unpracticable to specify for every code line or routine
	"this part is modified / added" or "this part is new / original"

	Only the folowing common rules are true:
	Every use of GEOS specifics like MemHandles, FileHandles or VMFiles is new.
	Every *.GOC and *.GOH file is designed to benefit GEOS requrements
	Every call to ZLIB-library is taken from original code.

	Rainer Bettsteller	7/2000
***************************************************************************

   This unzip package allow creates .ZIP file, compatible with PKZip 2.04g
     WinZip, InfoZip tools and compatible.
   Encryption and multi volume ZipFile (span) are not supported.
   Old compressions used by old PKZip 1.x are not supported

  For uncompress .zip file, look at unzip.h

   THIS IS AN ALPHA VERSION. AT THIS STAGE OF DEVELOPPEMENT, SOMES API OR STRUCTURE
   CAN CHANGE IN FUTURE VERSION !!
   I WAIT FEEDBACK at mail info@winimage.com
   Visit also http://www.winimage.com/zLibDll/zip.htm for evolution

   Condition of use and distribution are the same than zlib :

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.


*/

/* for more info about .ZIP format, see 
      ftp://ftp.cdrom.com/pub/infozip/doc/appnote-970311-iz.zip
   PkWare has also a specification at :
      ftp://ftp.pkware.com/probdesc.zip
*/

#ifndef _zip_H
#define _zip_H

#ifdef __cplusplus
extern "C" {
#endif

#ifndef _ZLIB_H
#include "zlib.h"
#endif


#define ZIP_OK                                  (0)
#define ZIP_ERRNO               (Z_ERRNO)
#define ZIP_PARAMERROR                  (-102)
#define ZIP_INTERNALERROR               (-104)

/*---------------------------------------------------------------------------
 For simplification programming, we define the the strcutures of local header,
 central header and and-of-dir record in "clear text".
 Note that this (and our simple use of FileWrite() etc.) will cause the library
 only valid for "intel compatible platforms", which are using the same lsb-hsb
 order of bytes in a word or double word as intel processors do. Any GEOS platforms
 do so. The same order is used inside of the ZIP-archive, therefor this simple
 definition is possible.

 Any of this structures may be followed by some fields of variable len.
 Therefore, you cannot use sizeof(header) for allocation memory. You have
 allways to calculate the size manually. Simply use
 "sizeof(header)+size_of_my_appendix".
 ---------------------------------------------------------------------------*/

/* The local header is used as start of any file inside of the zip archive */
typedef struct {
	dword	local_magic;    /* 'P','K',01,02 */
	word	version_need,
		gpb_flag,	/* means: general purpose bit flag */
		compression_method;
	dword   last_mod_dosDate,    /* 1st word:last_mod_time,
					2nd word:last_mod_date */
		crc32,
		compressed_size,
		uncompressed_size;
	word	filename_len,
		extrafield_len;
	} LocalHeader;
/* will be followed by filename(var len),   extra filed (var len)*/


/* The central header is used for cntral directory structure.
	This structure consist of an array of global headers, followed by
	a single end of dir record structure */
typedef struct {
	dword	central_magic;    /* 'P','K',03,04 */
	word    version_made_by,
		version_need,
		gpb_flag,	/* means: general purpose bit flag */
		compression_method;
	dword   last_mod_dosDate,    /* 1st word:last_mod_time,
					2nd word:last_mod_date */
		crc32,
		compressed_size,
		uncompressed_size;
	word	filename_len,
		extrafield_len,
		file_comment_len,
		disk_number_start,	/* currently not suported */
		internal_file_attrs;
	dword	external_file_attrs,
		local_header_offset;	/* offset from start of archive file */
	} CentralHeader;
/* will be followed by filename(var len),
   extra field (var len),  file comment (var len)*/


typedef struct {
	dword	end_of_dir_magic;    /* 'P','K',05,06 */
	word	number_this_disk,
		number_disk_starting_central_dir,
		number_entries_this_disk,
		number_entries_central_dir;
	dword	size_central_dir,
		offset_central_dir_respecting_disk_number;
	word	zip_file_comment_len;
	} EndOfDirRecord;
/* will be followed by zipfile comment (var len) */

typedef struct
{
    FileDateAndTime fDaT;	/* date in Geos default format, 4 Bytes */
/*unused:    uLong       flag;		/* general purpose bit flag  2 bytes */
    uLong       internal_fa;    /* internal file attributes        2 bytes */
    uLong       external_fa;    /* external file attributes        4 bytes */
} zip_fileinfo;

extern MemHandle ZEXPORT ZipCreateNewZipDesc OF((FileHandle fh, Boolean append));
/*
  Create a Descriptor for use by all other Zip*-routines
  Returns a Handle to an internal structure usable with other functions of
  this zip package.
  If append is TRUE, all files written into the archive will be appended
  after any data allready stored in the file. This is usefull for SFX'x
  If append is FALSE, first file wirtten to the archive will start at the
  beginning of the archive, so all allready existing data will be lost.

  Note that this routine is NOT ABLE TO START ADDING of files to a existing
  Archive!

*/

extern int ZEXPORT ZipOpenNewFileInZip OF((MemHandle zipDesc, const char* filename,
	   const zip_fileinfo* zipfi,
	   const void* extrafield_local, uInt size_extrafield_local,
	   const void* extrafield_global, uInt size_extrafield_global,
	   const char* comment,
	   int method,  int level));
/*
  Open a file in the ZIP for writing. Writes the local header.
  zipDesc: MemHandle returned by ZipCreateNewZipDesc()
  filename : the filename to store in zip archive (if NULL, '-' without quote
	will be used). No access to this file is done by this routine.
  *zipfi contain supplemental information
  if extrafield_local!=NULL and size_extrafield_local>0, extrafield_local
    contains the extrafield data the the local header
  if extrafield_global!=NULL and size_extrafield_global>0, extrafield_global
    contains the extrafield data the the global header
  if comment != NULL, comment contain the comment string (local header)
  method contains the compression method (0 for store, Z_DEFLATED for deflate)
  level contains the level of compression (can be Z_DEFAULT_COMPRESSION)
*/

extern int ZEXPORT ZipWriteInFileInZip OF((MemHandle zipDesc,
				   const voidp buf, unsigned len));
/*
  Write data into the zipfile.
*/

extern int ZEXPORT ZipCloseFileInZip OF((MemHandle zipDesc));
/*
Close the current file in the zipfile, flush current data and update locak header
*/

extern int ZEXPORT ZipCloseArchive OF((MemHandle zipDesc, int *entriesCount,
			const char* global_comment, Boolean closeArchive));
/*
	Flush data, write central directory, end-of-central-dir-record and
	global comment (if any, pass NULL for none)
	If CloseArchive is TRUE, close the ziparchive. In this case, FileHandle
		passed to ZipCreateNewZipDesc()	will be invalid!
	If closeArchive is FALSE, you have to close the file yourself!
*/


extern FileHandle ZEXPORT ZipOpenFileForZip OF((char * name, zip_fileinfo * zfi,
		char * dosPath, int parentPathLen));
/*
	Open a file for writing to zip-archive.
	- name is the GEOS or DOS filename, relative to the current directory
	- zfi will be filled with informations, usable by ZipOpenNewFileInZip()
	- Use dosPath as file name for ZipOpenNewFileInZip()
	- parentPathLen should contain the len of path, not to store in zip
	  Example:
	  If a dos-filePath is
		c:\geos\document\examples.000\myfile.000
	  and parentPathLen is 17, dosPath will be
		examples.000/myfile.000
	  (this is ready to store in zip file)
	  Note that there is a slash, not a backslash.

	return zero, if the file cannot be opened
		In this case, the dosPath will be set so good as possible
		If file referes a directory, dosPath will be correct
		If file referes a link, dosPath will end with a '/'
		If you have not the read access to the a file, dosPath
			may be correct or not.
*/

extern void ZEXPORT ZipGetFullDosPath OF((char * path , Boolean useSlash));
/*
	Calculate the full DOS-path of the current directory.
	The path will contain the drive letter and an slash (or Backslash)
	at its end.
	useSlash causes C:\DOS\TOOLS\ to switch to C:/DOS/TOOLS/
*/

/****************************************************************************
	Read zip_fileinfo structure for a given file or directory.
	If name referes a link, som informations may be invalid.
*/
extern void ZEXPORT ZipGetZipFileInfo OF(( char * name, zip_fileinfo * zfi));

/****************************************************************************
	Write a complete file to zip.
	The archive is refered by zipDesc, the file is refererd by a FileHandle.
	nameInZip should be a valid DOS-Path to the file, not containig a
		drive letter, wasting parent paths and leading slash.
	zfi contains informations, such like dosDate and attributes
	ZipOpenFileForZip() is designed to tell you the FileHandle, the
		Dos-Path (including drive-Letter!) and all reqiured zip_fileinfo
	if store == FALSE, the file will be deflated, it it is TRUE,
		the file will by stored (withot compression)
	All comments and extra files will be set to zero.
*/
extern int ZEXPORT ZipWriteFileToZip OF((MemHandle zipDesc, FileHandle fh,
		char * nameInZip, zip_fileinfo *zfi, Boolean store));

/****************************************************************************
	Store a directory path in zip.
	The archive is refered by zipDesc, the path is referd by its name.
	name should be a valid DOS-Path, without drive letter and leading
		slash. Backslashes shoud be replaced by slashes, a slash
		should be the last character of the path.
	Use ZipGetZipFileInfo() for proper setting zfi-structure
	All comments and extra files will be set to zero.
*/
extern int ZEXPORT ZipWritePathToZip OF(( MemHandle zipDesc, char * name, zip_fileinfo * zfi));


extern void ZEXPORT ZipFdatToDosDate OF((FileDateAndTime fdat,dword * dosDate));
/*
	Convert a FileDateAndTime structure to a dword dos-Date
*/

extern void ZEXPORT UnzDosDateToFdat OF((dword dosDate,FileDateAndTime *fdat));
/*
	Convert a dword dos-Date to a FileDateAndTime structure
*/



/****************************************************************************
	Close a opened File, but destroy it. Any data of the current file
	written zo Zip-Archive will be lost.
	Use this routine to cancel writing of a file
	Data of all other files in the archive (written previous or later)
	will not be affected.
*/
extern int ZEXPORT    ZipCancelCloseFileInZip OF(( MemHandle zipDesc ));

#ifdef __cplusplus
}
#endif

#endif /* _zip_H */
