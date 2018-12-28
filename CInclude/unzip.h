/* unzip.h -- IO for uncompress .zip files using zlib
   Version 0.15 beta, Mar 19th, 1998,

   Copyright (C) 1998 Gilles Vollant

   This unzip package allow extract file from .ZIP file, compatible with PKZip 2.04g
     WinZip, InfoZip tools and compatible.
   Encryption and multi volume ZipFile (span) are not supported.
   Old compressions used by old PKZip 1.x are not supported

   THIS IS AN ALPHA VERSION. AT THIS STAGE OF DEVELOPPEMENT, SOMES API OR STRUCTURE
   CAN CHANGE IN FUTURE VERSION !!
   I WAIT FEEDBACK at mail info@winimage.com
   Visit also http://www.winimage.com/zLibDll/unzip.htm for evolution

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
      ftp://ftp.pkware.com/probdesc.zip */

#ifndef _unz_H
#define _unz_H

#ifdef __cplusplus
extern "C" {
#endif

#ifndef _ZLIB_H
#include "zlib.h"
#endif


#define UNZ_OK                                  (0)
#define UNZ_END_OF_LIST_OF_FILE (-100)
#define UNZ_ERRNO               (Z_ERRNO)
#define UNZ_EOF                 (0)
#define UNZ_PARAMERROR                  (-102)
#define UNZ_BADZIPFILE                  (-103)
#define UNZ_INTERNALERROR               (-104)
#define UNZ_CRCERROR                    (-105)
#define UNZ_UNKNOWNZIPMETHOD		(-106)
#define UNZ_ENCRYPTION_ERROR       	(-107)
/* Encrypted files are currently not supported. You can still get Informations
   about this file, but if you try to access to encrypted data, results may by
   dangerous. Therefore UnzLocateFile(), UnzGoToFileAt() and
   UnzOpenCurrentFile() and UnzCloseCurrentFile() will work, but
   UnzReadCurrentFile(), UnzTell() and UnzEof() will retrun this error. */


/* tm_unz contain date/time info */
typedef struct tm_unz_s
{
	uInt tm_sec;            /* seconds after the minute - [0,59] */
	uInt tm_min;            /* minutes after the hour - [0,59] */
	uInt tm_hour;           /* hours since midnight - [0,23] */
	uInt tm_mday;           /* day of the month - [1,31] */
	uInt tm_mon;            /* months since January - [0,11] */
	uInt tm_year;           /* years - [1980..2044] */
} tm_unz;

/* unz_global_info structure contain global data about the ZIPfile
   These data comes from the end of central dir */
typedef struct unz_global_info_s
{
	uLong number_entry;         /* total number of entries in
				       the central dir on this disk */
	uLong size_comment;         /* size of the global comment of the zipfile */
} unz_global_info;


/* unz_file_info contain information about a file in the zipfile */
typedef struct unz_file_info_s
{
    uLong version;              /* version made by                 2 bytes */
    uLong version_needed;       /* version needed to extract       2 bytes */
    uLong flag;                 /* general purpose bit flag	2 bytes */
    uLong compression_method;   /* compression method              2 bytes */
    uLong dosDate;              /* last mod file date in Dos fmt   4 bytes */
    uLong crc;                  /* crc-32                          4 bytes */
    uLong compressed_size;      /* compressed size                 4 bytes */ 
    uLong uncompressed_size;    /* uncompressed size               4 bytes */ 
    uLong size_filename;        /* filename length                 2 bytes */
    uLong size_file_extra;      /* extra field length              2 bytes */
    uLong size_file_comment;    /* file comment length             2 bytes */

    uLong disk_num_start;       /* disk number start               2 bytes */
    uLong internal_fa;          /* internal file attributes        2 bytes */
    uLong external_fa;          /* external file attributes        4 bytes */

    tm_unz tmu_date;
} unz_file_info;

/* if a file is encrypted, the 0-Bit of general purpose bit flags is set */
#define UNZ_FLAG_FILE_ENCRYPTED	(word)1


/* QuickLocateParams contains informations needed for locate a file without
   using UnzLocateFile() */
typedef struct QuickLocateParamsStruct {
	dword currentPosInCentralDir;
	dword currentFileNumber;
	Boolean currentFileOk;
	} QuickLocateParams;

extern int ZEXPORT unzStringFileNameCompare OF ((const char* fileName1,
												 const char* fileName2,
												 int iCaseSensitivity));
/*
   Compare two filename (fileName1,fileName2).
   If iCaseSenisivity = 1, comparision is case sensitivity (like strcmp)
   If iCaseSenisivity = 2, comparision is not case sensitivity (like strcmpi
								or strcasecmp)
   If iCaseSenisivity = 0, case sensitivity is defaut of your operating system
	(like 1 on Unix, 2 on Windows)
*/

extern int ZEXPORT UnzInitUnzDesc OF((FileHandle fh, MemHandle *mh));
/*
  Verify the file for a valid ZIP-file and returns a Handle to an internal
  structure usable with other functions of this unzip package.
  Returns zero if the file is not a valid ZIP-file.
*/

extern int ZEXPORT UnzDestroyUnzDesc OF((MemHandle mh));
/*
  Destoy an Handle returned from UnzInitUnzDesc() and all associated Memory
  If there is files inside the .Zip opened with UnzOpenCurrentFile (see later),
    these files shoud be closed with unzipCloseCurrentFile before call unzipClose.
  return UNZ_OK if there is no problem. */

extern int ZEXPORT UnzGetGlobalInfo OF((MemHandle mh,
					unz_global_info *pglobal_info));
/*
  Write info about the ZipFile in the *pglobal_info structure.
  No preparation of the structure is needed
  return UNZ_OK if there is no problem. */


extern int ZEXPORT UnzGetGlobalComment OF((MemHandle mh,
		   char *szComment,  uLong uSizeBuf));
/*
  Get the global comment string of the ZipFile, in the szComment buffer.
  uSizeBuf is the size of the szComment buffer.
  return the number of byte copied or an error code <0
*/

/***************************************************************************/
/* Unzip package allow you browse the directory of the zipfile */

extern int ZEXPORT UnzGoToFirstFile OF((MemHandle mh));
/*
  Set the current file of the zipfile to the first file.
  return UNZ_OK if there is no problem
*/

extern int ZEXPORT UnzGoToNextFile OF((MemHandle mh));
/*
  Set the current file of the zipfile to the next file.
  return UNZ_OK if there is no problem
  return UNZ_END_OF_LIST_OF_FILE if the actual file was the latest.
*/

extern int ZEXPORT UnzLocateFile OF((MemHandle mh,
				     const char *szFileName,
				     int iCaseSensitivity));
/*
  Try locate the file szFileName in the zipfile.
  For the iCaseSensitivity signification, see unzStringFileNameCompare

  return value :
  UNZ_OK if the file is found. It becomes the current file.
  UNZ_END_OF_LIST_OF_FILE if the file is not found
*/


extern int ZEXPORT UnzGetGoToAtInfo OF((MemHandle mh, QuickLocateParams * qlp));
/*
	returns infos in qlp about the current file used for quick locate the
	specified File without using UnzLoacteFile, whis is very slow
	because it searchs for the filename.
	return: TRUE, if current file is correct located, FALSE if not
*/

extern int ZEXPORT UnzGoToFileAt OF((MemHandle mh, QuickLocateParams * qlp));
/*
	locates an file without using UnzLoacteFile
	see UnzGetGoToAtInfo()
	return: UNZ_OK if there is no error
*/


extern int ZEXPORT UnzGetCurrentFileInfo OF((MemHandle mh,
		     unz_file_info *pfile_info,
		     char *szFileName, uLong fileNameBufferSize,
		     void *extraField, uLong extraFieldBufferSize,
		     char *szComment,  uLong commentBufferSize));
/*
  Get Info about the current file
  if pfile_info!=NULL, the *pfile_info structure will contain somes info about
	    the current file
  if szFileName!=NULL, the filemane string will be copied in szFileName
			(fileNameBufferSize is the size of the buffer)
  if extraField!=NULL, the extra field information will be copied in extraField
			(extraFieldBufferSize is the size of the buffer).
			This is the Central-header version of the extra field
  if szComment!=NULL, the comment string of the file will be copied in szComment
			(commentBufferSize is the size of the buffer)
*/

/***************************************************************************/
/* for reading the content of the current zipfile, you can open it, read data
   from it, and close it (you can close it before reading all the file)
   */

extern int ZEXPORT UnzOpenCurrentFile OF((MemHandle mh));


/*****************************************************************************
	Assign a new FileHandle to the unzDesc.
	This is used after "save as" command.
	Because of the actual physical file is changed, there schould not be
	any file opened in the archive.
*/
extern int ZEXPORT UnzSetNewFileHandle OF ((MemHandle mh, FileHandle fh));


/*
  Open for reading data the current file in the zipfile.
  If there is no error, the return value is UNZ_OK.
*/

extern int ZEXPORT UnzCloseCurrentFile OF((MemHandle mh));
/*
  Close the file in zip opened with unzOpenCurrentFile
  Return UNZ_CRCERROR if all the file was read but the CRC is not good
*/


extern int ZEXPORT UnzReadCurrentFile OF((MemHandle mh,
					  voidp buf,
					  unsigned len));
/*
  Read bytes from the current file (opened by unzOpenCurrentFile)
  buf contain buffer where data must be copied
  len the size of buf.

  return the number of byte copied if somes bytes are copied
  return 0 if the end of file was reached
  return <0 with error code if there is an error
    (UNZ_ERRNO for IO error, or zLib error for uncompress error)
*/

extern z_off_t ZEXPORT UnzTell OF((MemHandle mh));
/*
  Give the current position in uncompressed data
*/

extern int ZEXPORT UnzEof OF((MemHandle mh));
/*
	return 1 if the end of currently decompressed file was reached,
		0 elsewhere
*/

extern int ZEXPORT UnzGetLocalExtrafield OF((MemHandle mh,
					 voidp buf, unsigned len));
/*
  Read extra field from the current file (opened by unzOpenCurrentFile)
  This is the local-header version of the extra field (sometimes, there is
    more info in the local-header version than in the central-header)

  if buf==NULL, it return the size of the local extra field

  if buf!=NULL, len is the size of the buffer, the extra header is copied in
	buf.
  the return value is the number of bytes copied in buf, or (if <0)
	the error code
*/

#ifdef __cplusplus
}
#endif

#endif /* _unz_H */
