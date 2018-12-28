/* unzip.c -- IO on .zip files using zlib
   Version 0.15 beta, Mar 19th, 1998,

   Read unzip.h for more info
*/


#include <stdio.h>
#include <Ansi/stdlib.h>
#include <Ansi/string.h>
#include "zlib.h"
#include "unzip.h"

#include "file.h"
#include "heap.h"

#ifdef STDC
#  include <stddef.h>
#  include <string.h>
#  include <stdlib.h>
#endif
#ifdef NO_ERRNO_H
    extern int errno;
#else
#   include <errno.h>
#endif


#ifndef local
#  define local static
#endif
/* compile with -Dlocal if your debugger can't find static symbols */



#if !defined(unix) && !defined(CASESENSITIVITYDEFAULT_YES) && \
		      !defined(CASESENSITIVITYDEFAULT_NO)
#define CASESENSITIVITYDEFAULT_NO
#endif

#ifdef  CASESENSITIVITYDEFAULT_NO
#define CASESENSITIVITYDEFAULTVALUE 2
#else
#define CASESENSITIVITYDEFAULTVALUE 1
#endif

#ifndef STRCMPCASENOSENTIVEFUNCTION
#define STRCMPCASENOSENTIVEFUNCTION strcmpcasenosensitive_internal
#endif



#ifndef UNZ_BUFSIZE
#define UNZ_BUFSIZE (16384)
#endif

#define BUFREADCOMMENT (0x16)
// reduced to sizeof(End-of-dir-record)


#ifndef UNZ_MAXFILENAMEINZIP
#define UNZ_MAXFILENAMEINZIP (256)
#endif

#define SIZECENTRALDIRITEM (0x2e)
#define SIZEZIPLOCALHEADER (0x1e)



const char unz_copyright[] =
   " unzip 0.15 Copyright 1998 Gilles Vollant ";

/* unz_file_info_interntal contain internal info about a file in zipfile*/
typedef struct unz_file_info_internal_s
{
    uLong offset_curfile;/* relative offset of local header 4 bytes */
} unz_file_info_internal;


/* file_in_zip_read_info_s contain internal information about a file in zipfile,
    when reading and decompress it */
typedef struct
{
/*	char  read_buf[UNZ_BUFSIZE];  /* internal buffer for compressed data */
	char * read_bufp;
	z_stream stream;            /* zLib stream structure for inflate */

	uLong pos_in_zipfile;       /* position in byte on the zipfile, for FilePos*/
	uLong stream_initialised;   /* flag set if stream structure is initialised*/

	uLong offset_local_extrafield;/* offset of the local extra field */
	uInt  size_local_extrafield;/* size of the local extra field */
	uLong pos_local_extrafield;   /* position in the local extra field in read*/

	uLong crc32;                /* crc32 of all data uncompressed */
	uLong crc32_wait;           /* crc32 we must obtain after decompress all */
	uLong rest_read_compressed; /* number of byte to be decompressed */
	uLong rest_read_uncompressed;/*number of byte to be obtained after decomp*/
	FileHandle fileHandle;       /* geos-io structore of the zipfile */
	uLong compression_method;   /* compression method (0==store) */
	uLong byte_before_the_zipfile;/* byte before the zipfile, (>0 for sfx)*/
} file_in_zip_read_info_s;


/* unz_s contain internal information about the zipfile
*/
typedef struct
{
	FileHandle fileHandle;      /* geos-io structure of the zipfile */
	unz_global_info gi;       /* public global information */
	uLong byte_before_the_zipfile;/* byte before the zipfile, (>0 for sfx)*/
	uLong num_file;             /* number of the current file in the zipfile*/
	uLong pos_in_central_dir;   /* pos of the current file in the central dir*/
	uLong current_file_ok;      /* flag about the usability of the current file*/
	uLong central_pos;          /* position of the beginning of the central dir*/

	uLong size_central_dir;     /* size of the central directory  */
	uLong offset_central_dir;   /* offset of start of central directory with
								   respect to the starting disk number */

	unz_file_info cur_file_info; /* public info about the current file in zip*/
	unz_file_info_internal cur_file_info_internal; /* private info about it*/
        MemHandle file_in_zip_read_info_handle; /* structure about the current
					    file if we are decompressing it */
} unz_s;


/*********************************** GEOS *************************************/

local int strcmpcasenosensitive_internal(const char *, const char *);
local void unzlocal_DosDateToTmuDate(uLong ulDosDate, tm_unz *ptm);

local int unzlocal_readByte(FileHandle fh, int *pi);
local int unzlocal_readWord(FileHandle fh, uLong *pX);
local int unzlocal_readDword(FileHandle fh, uLong *pX);

local uLong unzlocal_SearchCentralDir(FileHandle fh);
local int unzlocal_CheckCurrentFileCoherencyHeader(
  unz_s *s, uInt *piSizeVar, uLong *poffset_local_extrafield,
  uInt *psize_local_extrafield);

/*
  Get Info about the current file in the zipfile, with internal only info
*/
local int unzlocal_GetCurrentFileInfoInternal (MemHandle mh,
		  unz_file_info   *pfile_info,
		  unz_file_info_internal   *pfile_info_internal,
		  char *szFileName,  uLong fileNameBufferSize,
		  void *extraField,  uLong extraFieldBufferSize,
		  char *szComment,  uLong commentBufferSize);


/******************************************************************************/


/* My own strcmpi / strcasecmp */
local int strcmpcasenosensitive_internal (fileName1,fileName2)
	const char* fileName1;
	const char* fileName2;
{
	for (;;)
	{
		char c1=*(fileName1++);
		char c2=*(fileName2++);
		if ((c1>='a') && (c1<='z'))
			c1 -= 0x20;
		if ((c2>='a') && (c2<='z'))
			c2 -= 0x20;
		if (c1=='\0')
			return ((c2=='\0') ? 0 : -1);
		if (c2=='\0')
			return 1;
		if (c1<c2)
			return -1;
		if (c1>c2)
			return 1;
	}
}

/*
   Compare two filename (fileName1,fileName2).
   If iCaseSenisivity = 1, comparision is case sensitivity (like strcmp)
   If iCaseSenisivity = 2, comparision is not case sensitivity (like strcmpi
								or strcasecmp)
   If iCaseSenisivity = 0, case sensitivity is defaut of your operating system
	(like 1 on Unix, 2 on Windows)

*/
extern int ZEXPORT unzStringFileNameCompare (fileName1,fileName2,iCaseSensitivity)
	const char* fileName1;
	const char* fileName2;
	int iCaseSensitivity;
{
	if (iCaseSensitivity==0)
		iCaseSensitivity=CASESENSITIVITYDEFAULTVALUE;

	if (iCaseSensitivity==1)
		return strcmp(fileName1,fileName2);

	return STRCMPCASENOSENTIVEFUNCTION(fileName1,fileName2);
} 

/*********************************** GEOS *************************************/

local int unzlocal_readByte(FileHandle fh, int *pi)
{
	*pi = 0;
	if ( FileRead(fh,pi,1,FALSE) == 1 ) return UNZ_OK;
	return UNZ_EOF;
}

local int unzlocal_readWord(FileHandle fh, uLong *pX)
{
	*pX =0;
	if ( FileRead(fh,pX,2,FALSE) == 2 ) return UNZ_OK;
	return UNZ_EOF;
}

local int unzlocal_readDword(FileHandle fh, uLong *pX)
{
	*pX =0;
	if ( FileRead(fh,pX,4,FALSE) == 4 ) return UNZ_OK;
	return UNZ_EOF;
}




/*
  Locate the Central directory of a zipfile (at the end, just before
    the global comment)
*/
local uLong unzlocal_SearchCentralDir(FileHandle fh)
{
	unsigned char* buf;
	uLong uSizeFile;
	uLong uBackRead;
	uLong uMaxBack=0xffff; /* maximum size of global comment */
	uLong uPosFound=0;



	uSizeFile = FileSize(fh);

	if (uMaxBack>uSizeFile)
		uMaxBack = uSizeFile;

	buf = (unsigned char*)malloc(BUFREADCOMMENT+4);
	if (buf==NULL)
		return 0;

	uBackRead = 4;
	while (uBackRead<uMaxBack)
	{
		uLong uReadSize,uReadPos ;
		int i;
		if (uBackRead+BUFREADCOMMENT>uMaxBack)
			uBackRead = uMaxBack;
		else
			uBackRead+=BUFREADCOMMENT;
		uReadPos = uSizeFile-uBackRead ;

		uReadSize = ((BUFREADCOMMENT+4) < (uSizeFile-uReadPos)) ?
		     (BUFREADCOMMENT+4) : (uSizeFile-uReadPos);

		FilePos(fh,uReadPos,FILE_POS_START);
		FileRead(fh,buf,uReadSize,FALSE);

		for (i=0;i<(int)uReadSize-3;i++)
			if (((*(buf+i))==0x50) && ((*(buf+i+1))==0x4b) &&
				((*(buf+i+2))==0x05) && ((*(buf+i+3))==0x06))
			{
				uPosFound = uReadPos+i;
				break;
			}

		if (uPosFound!=0)
			break;
	}
	free(buf);
	return uPosFound;
}

/***************************************************************************
  Verify the file for a valid ZIP-file and returns a Handle to an internal
  structure usable with other functions of this unzip package.
  Returns zero if the file is not a valid ZIP-file.
*/
extern int ZEXPORT UnzInitUnzDesc (FileHandle fh, MemHandle *mh)
{
	unz_s us;
	unz_s *s;
	uLong central_pos,uL;

	uLong number_disk;          /* number of the current dist, used for
								   spaning ZIP, unsupported, always 0*/
	uLong number_disk_with_CD;  /* number the the disk with central dir, used
								   for spaning ZIP, unsupported, always 0*/
	uLong number_entry_CD;      /* total number of entries in
				       the central dir
				       (same than number_entry on nospan) */

	int err=UNZ_OK;

	central_pos = unzlocal_SearchCentralDir(fh);
	if (central_pos==0)
		err=UNZ_ERRNO;

	FilePos(fh,central_pos,FILE_POS_START);

	/* the signature, already checked */
	if (unzlocal_readDword(fh,&uL)!=UNZ_OK)
		err=UNZ_ERRNO;

	/* number of this disk */
	if (unzlocal_readWord(fh,&number_disk)!=UNZ_OK)
		err=UNZ_ERRNO;

	/* number of the disk with the start of the central directory */
	if (unzlocal_readWord(fh,&number_disk_with_CD)!=UNZ_OK)
		err=UNZ_ERRNO;

	/* total number of entries in the central dir on this disk */
	if (unzlocal_readWord(fh,&us.gi.number_entry)!=UNZ_OK)
		err=UNZ_ERRNO;

	/* total number of entries in the central dir */
	if (unzlocal_readWord(fh,&number_entry_CD)!=UNZ_OK)
		err=UNZ_ERRNO;

	if ((number_entry_CD!=us.gi.number_entry) ||
		(number_disk_with_CD!=0) ||
		(number_disk!=0))
		err=UNZ_BADZIPFILE;
/*/
	err = 0;
	if (number_entry_CD != us.gi.number_entry) err |= 2;
	if (number_disk_with_CD != 0) err |= 4;
	if (number_disk != 0) err |=8;
return err;
/*/

	/* size of the central directory */
	if (unzlocal_readDword(fh,&us.size_central_dir)!=UNZ_OK)
		err=UNZ_ERRNO;

	/* offset of start of central directory with respect to the
	      starting disk number */
	if (unzlocal_readDword(fh,&us.offset_central_dir)!=UNZ_OK)
		err=UNZ_ERRNO;

	/* zipfile comment length */
	if (unzlocal_readWord(fh,&us.gi.size_comment)!=UNZ_OK)
		err=UNZ_ERRNO;

	if ((central_pos<us.offset_central_dir+us.size_central_dir) &&
		(err==UNZ_OK))
		err=UNZ_BADZIPFILE;
	if (err!=UNZ_OK)
	{
		return err;
	}

	us.fileHandle = fh;

	us.byte_before_the_zipfile = central_pos -
				    (us.offset_central_dir+us.size_central_dir);
	us.central_pos = central_pos;
	us.file_in_zip_read_info_handle = NULL;


	*mh = MemAlloc(sizeof(unz_s),HF_SHARABLE | HF_SWAPABLE, HAF_LOCK | HAF_ZERO_INIT);
	if (!*mh) return 0;

	s=(unz_s*)MemDeref(*mh);
	*s=us;
	UnzGoToFirstFile(*mh);
	MemUnlock(*mh);

	return UNZ_OK;
}


/*****************************************************************************
  Destoy an Handle returned from UnzInitUnzDesc() and all associated Memory
  If there is files inside the .Zip opened with UnzOpenCurrentFile (see later),
    these files shoud be closed with unzipCloseCurrentFile before call unzipClose.
  return UNZ_OK if there is no problem. */
extern int ZEXPORT UnzDestroyUnzDesc (MemHandle mh)
{
unz_s* s;

if (mh == NULL)	return UNZ_PARAMERROR;
s=(unz_s*)MemLock(mh);

if (s->file_in_zip_read_info_handle!=NULL) UnzCloseCurrentFile(mh);

MemFree(mh);
return UNZ_OK;
}

/*
  Write info about the ZipFile in the *pglobal_info structure.
  No preparation of the structure is needed
  return UNZ_OK if there is no problem. */
extern int ZEXPORT UnzGetGlobalInfo (MemHandle mh,
					unz_global_info *pglobal_info)
{
	unz_s* s;
	if (mh==NULL)	return UNZ_PARAMERROR;

	s=(unz_s*)MemLock(mh);
	*pglobal_info=s->gi;
        MemUnlock(mh);
	return UNZ_OK;
}

/*
   Translate date/time from Dos format to tm_unz (readable more easilty)
*/
local void unzlocal_DosDateToTmuDate (ulDosDate, ptm)
    uLong ulDosDate;
    tm_unz* ptm;
{
    uLong uDate;
    uDate = (uLong)(ulDosDate>>16);
    ptm->tm_mday = (uInt)(uDate&0x1f) ;
    ptm->tm_mon =  (uInt)((((uDate)&0x1E0)/0x20)-1) ;
    ptm->tm_year = (uInt)(((uDate&0x0FE00)/0x0200)+1980) ;

    ptm->tm_hour = (uInt) ((ulDosDate &0xF800)/0x800);
    ptm->tm_min =  (uInt) ((ulDosDate&0x7E0)/0x20) ;
    ptm->tm_sec =  (uInt) (2*(ulDosDate&0x1f)) ;
}


/**************************************************************************
  Get Info about the current file in the zipfile, with internal only info
*/
local int unzlocal_GetCurrentFileInfoInternal (MemHandle mh,
		  unz_file_info   *pfile_info,
		  unz_file_info_internal   *pfile_info_internal,
		  char *szFileName,  uLong fileNameBufferSize,
		  void *extraField,  uLong extraFieldBufferSize,
		  char *szComment,  uLong commentBufferSize)
{
	unz_s* s;
	unz_file_info file_info;
	unz_file_info_internal file_info_internal;
	int err=UNZ_OK;
	uLong uMagic;
	long lSeek=0;

	if (mh==NULL) 	return UNZ_PARAMERROR;

	s=(unz_s*)MemLock(mh);
	FilePos(s->fileHandle,s->pos_in_central_dir+s->byte_before_the_zipfile,
					FILE_POS_START);

	/* we check the magic */
	if (unzlocal_readDword(s->fileHandle,&uMagic) != UNZ_OK)
			err=UNZ_ERRNO;
		else if (uMagic!=0x02014b50)
			err=UNZ_BADZIPFILE;

	if (unzlocal_readWord(s->fileHandle,&file_info.version) != UNZ_OK)
		err=UNZ_ERRNO;

	if (unzlocal_readWord(s->fileHandle,&file_info.version_needed) != UNZ_OK)
		err=UNZ_ERRNO;

	if (unzlocal_readWord(s->fileHandle,&file_info.flag) != UNZ_OK)
		err=UNZ_ERRNO;

	if (unzlocal_readWord(s->fileHandle,&file_info.compression_method) != UNZ_OK)
		err=UNZ_ERRNO;

	if (unzlocal_readDword(s->fileHandle,&file_info.dosDate) != UNZ_OK)
		err=UNZ_ERRNO;

    unzlocal_DosDateToTmuDate(file_info.dosDate,&file_info.tmu_date);

	if (unzlocal_readDword(s->fileHandle,&file_info.crc) != UNZ_OK)
		err=UNZ_ERRNO;

	if (unzlocal_readDword(s->fileHandle,&file_info.compressed_size) != UNZ_OK)
		err=UNZ_ERRNO;

	if (unzlocal_readDword(s->fileHandle,&file_info.uncompressed_size) != UNZ_OK)
		err=UNZ_ERRNO;

	if (unzlocal_readWord(s->fileHandle,&file_info.size_filename) != UNZ_OK)
		err=UNZ_ERRNO;

	if (unzlocal_readWord(s->fileHandle,&file_info.size_file_extra) != UNZ_OK)
		err=UNZ_ERRNO;

	if (unzlocal_readWord(s->fileHandle,&file_info.size_file_comment) != UNZ_OK)
		err=UNZ_ERRNO;

	if (unzlocal_readWord(s->fileHandle,&file_info.disk_num_start) != UNZ_OK)
		err=UNZ_ERRNO;

	if (unzlocal_readWord(s->fileHandle,&file_info.internal_fa) != UNZ_OK)
		err=UNZ_ERRNO;

	if (unzlocal_readDword(s->fileHandle,&file_info.external_fa) != UNZ_OK)
		err=UNZ_ERRNO;

	if (unzlocal_readDword(s->fileHandle,&file_info_internal.offset_curfile) != UNZ_OK)
		err=UNZ_ERRNO;

	lSeek+=file_info.size_filename;
	if ((err==UNZ_OK) && (szFileName!=NULL))
	{
		uLong uSizeRead ;
		if (file_info.size_filename<fileNameBufferSize)
		{
			*(szFileName+file_info.size_filename)='\0';
			uSizeRead = file_info.size_filename;
		}
		else
			uSizeRead = fileNameBufferSize;

		if ((file_info.size_filename>0) && (fileNameBufferSize>0))
			if (FileRead(s->fileHandle,szFileName,uSizeRead,
					FALSE) != uSizeRead) err=UNZ_ERRNO;
		lSeek -= uSizeRead;
	}


	if ((err==UNZ_OK) && (extraField!=NULL))
	{
		uLong uSizeRead ;
		if (file_info.size_file_extra<extraFieldBufferSize)
			uSizeRead = file_info.size_file_extra;
		else
			uSizeRead = extraFieldBufferSize;

		if (lSeek!=0) FilePos(s->fileHandle,lSeek,FILE_POS_RELATIVE);

		if ((file_info.size_file_extra>0) && (extraFieldBufferSize>0))
			if (FileRead(s->fileHandle,extraField,uSizeRead,
					FALSE) != uSizeRead) err=UNZ_ERRNO;

		lSeek += file_info.size_file_extra - uSizeRead;
	}
	else
		lSeek+=file_info.size_file_extra;


	if ((err==UNZ_OK) && (szComment!=NULL))
	{
		uLong uSizeRead ;
		if (file_info.size_file_comment<commentBufferSize)
		{
			*(szComment+file_info.size_file_comment)='\0';
			uSizeRead = file_info.size_file_comment;
		}
		else
			uSizeRead = commentBufferSize;

		if (lSeek!=0) FilePos(s->fileHandle,lSeek,FILE_POS_RELATIVE);

		if ((file_info.size_file_comment>0) && (commentBufferSize>0))
			if (FileRead(s->fileHandle,szComment,uSizeRead,
					FALSE) != uSizeRead)  err=UNZ_ERRNO;

		lSeek+=file_info.size_file_comment - uSizeRead;
	}
	else
		lSeek+=file_info.size_file_comment;

	if ((err==UNZ_OK) && (pfile_info!=NULL))
		*pfile_info=file_info;

	if ((err==UNZ_OK) && (pfile_info_internal!=NULL))
		*pfile_info_internal=file_info_internal;

	MemUnlock(mh);
	return err;
}


/****************************************************************************
  Write info about the ZipFile in the *pglobal_info structure.
  No preparation of the structure is needed
  return UNZ_OK if there is no problem.
*/
extern int ZEXPORT UnzGetCurrentFileInfo (MemHandle mh,
		     unz_file_info *pfile_info,
		     char *szFileName, uLong fileNameBufferSize,
		     void *extraField, uLong extraFieldBufferSize,
		     char *szComment,  uLong commentBufferSize)
{
	return unzlocal_GetCurrentFileInfoInternal(mh,pfile_info,NULL,
			szFileName,fileNameBufferSize,
			extraField,extraFieldBufferSize,
			szComment,commentBufferSize);
}

/****************************************************************************
  Set the current file of the zipfile to the first file.
  return UNZ_OK if there is no problem
*/
extern int ZEXPORT UnzGoToFirstFile (MemHandle mh)
{
	int err=UNZ_OK;
	unz_s* s;

	if (mh == NULL) return UNZ_PARAMERROR;

	s=(unz_s*)MemLock(mh);
	s->pos_in_central_dir=s->offset_central_dir;
	s->num_file=0;

	err=unzlocal_GetCurrentFileInfoInternal(mh,&s->cur_file_info,
			 &s->cur_file_info_internal, NULL,0,NULL,0,NULL,0);

	s->current_file_ok = (err == UNZ_OK);
	MemUnlock(mh);
	return err;
}


/*
  Set the current file of the zipfile to the next file.
  return UNZ_OK if there is no problem
  return UNZ_END_OF_LIST_OF_FILE if the actual file was the latest.
*/
extern int ZEXPORT UnzGoToNextFile (MemHandle mh)
{
	unz_s* s;
	int err;

	if (mh==NULL)
		return UNZ_PARAMERROR;

	s=(unz_s*)MemLock(mh);

	if (!s->current_file_ok) {
		MemUnlock(mh);
		return UNZ_END_OF_LIST_OF_FILE;
		}
	if (s->num_file+1==s->gi.number_entry) {
		MemUnlock(mh);
		return UNZ_END_OF_LIST_OF_FILE;
		}

	s->pos_in_central_dir += SIZECENTRALDIRITEM + s->cur_file_info.size_filename +
			s->cur_file_info.size_file_extra + s->cur_file_info.size_file_comment ;
	s->num_file++;
	err = unzlocal_GetCurrentFileInfoInternal(mh,&s->cur_file_info,
			   &s->cur_file_info_internal,NULL,0,NULL,0,NULL,0);
	s->current_file_ok = (err == UNZ_OK);
	MemUnlock(mh);
	return err;
}

/*
  Try locate the file szFileName in the zipfile.
  For the iCaseSensitivity signification, see unzipStringFileNameCompare

  return value :
  UNZ_OK if the file is found. It becomes the current file.
  UNZ_END_OF_LIST_OF_FILE if the file is not found
*/
extern int ZEXPORT UnzLocateFile (MemHandle mh,
	     const char *szFileName, int iCaseSensitivity)
{
	unz_s* s;
	int err;


	uLong num_fileSaved;
	uLong pos_in_central_dirSaved;


	if (mh==NULL)
		return UNZ_PARAMERROR;

    if (strlen(szFileName)>=UNZ_MAXFILENAMEINZIP)
	return UNZ_PARAMERROR;

	s=(unz_s*)MemLock(mh);
	if (!s->current_file_ok) {
		MemUnlock(mh);
		return UNZ_END_OF_LIST_OF_FILE;
		}

	num_fileSaved = s->num_file;
	pos_in_central_dirSaved = s->pos_in_central_dir;

	err = UnzGoToFirstFile(mh);

	while (err == UNZ_OK)
	{
		char szCurrentFileName[UNZ_MAXFILENAMEINZIP+1];
		UnzGetCurrentFileInfo(mh,NULL,
				szCurrentFileName,sizeof(szCurrentFileName)-1,
				NULL,0,NULL,0);
		if (unzStringFileNameCompare(szCurrentFileName,
				szFileName,iCaseSensitivity)==0)
				{
				MemUnlock(mh);
				return UNZ_OK;
				}
		err = UnzGoToNextFile(mh);
	}

	s->num_file = num_fileSaved ;
	s->pos_in_central_dir = pos_in_central_dirSaved ;
	MemUnlock(mh);
	return err;
}

/****************************************************************************
  Read the local header of the current zipfile
  Check the coherency of the local header and info in the end of central
	directory about this file
  store in *piSizeVar the size of extra info in local header
	(filename and size of extra field data)
*/
local int unzlocal_CheckCurrentFileCoherencyHeader (s,piSizeVar,
													poffset_local_extrafield,
													psize_local_extrafield)
	unz_s* s;
	uInt* piSizeVar;
	uLong *poffset_local_extrafield;
	uInt  *psize_local_extrafield;
{
	uLong uMagic,uData,uFlags;
	uLong size_filename;
	uLong size_extra_field;
	int err=UNZ_OK;

	*piSizeVar = 0;
	*poffset_local_extrafield = 0;
	*psize_local_extrafield = 0;

	FilePos(s->fileHandle,s->cur_file_info_internal.offset_curfile +
			s->byte_before_the_zipfile,FILE_POS_START);

	if (unzlocal_readDword(s->fileHandle,&uMagic) != UNZ_OK)
			err=UNZ_ERRNO;
		else if (uMagic!=0x04034b50)
			err=UNZ_BADZIPFILE;

	if (unzlocal_readWord(s->fileHandle,&uData) != UNZ_OK)
		err=UNZ_ERRNO;
/*
	else if ((err==UNZ_OK) && (uData!=s->cur_file_info.wVersion))
		err=UNZ_BADZIPFILE;
*/
	if (unzlocal_readWord(s->fileHandle,&uFlags) != UNZ_OK)
		err=UNZ_ERRNO;

	if (unzlocal_readWord(s->fileHandle,&uData) != UNZ_OK)
		err=UNZ_ERRNO;
	else if ((err==UNZ_OK) && (uData!=s->cur_file_info.compression_method))
		err=UNZ_BADZIPFILE;

    if ((err==UNZ_OK) && (s->cur_file_info.compression_method!=0) &&
			 (s->cur_file_info.compression_method!=Z_DEFLATED))
	err=UNZ_UNKNOWNZIPMETHOD;

	if (unzlocal_readDword(s->fileHandle,&uData) != UNZ_OK) /* date/time */
		err=UNZ_ERRNO;

	if (unzlocal_readDword(s->fileHandle,&uData) != UNZ_OK) /* crc */
		err=UNZ_ERRNO;
	else if ((err==UNZ_OK) && (uData!=s->cur_file_info.crc) &&
				      ((uFlags & 8)==0))
		err=UNZ_BADZIPFILE;

	if (unzlocal_readDword(s->fileHandle,&uData) != UNZ_OK) /* size compr */
		err=UNZ_ERRNO;
	else if ((err==UNZ_OK) && (uData!=s->cur_file_info.compressed_size) &&
							  ((uFlags & 8)==0))
		err=UNZ_BADZIPFILE;

	if (unzlocal_readDword(s->fileHandle,&uData) != UNZ_OK) /* size uncompr */
		err=UNZ_ERRNO;
	else if ((err==UNZ_OK) && (uData!=s->cur_file_info.uncompressed_size) &&
							  ((uFlags & 8)==0))
		err=UNZ_BADZIPFILE;


	if (unzlocal_readWord(s->fileHandle,&size_filename) != UNZ_OK)
		err=UNZ_ERRNO;
	else if ((err==UNZ_OK) && (size_filename!=s->cur_file_info.size_filename))
		err=UNZ_BADZIPFILE;

	*piSizeVar += (uInt)size_filename;

	if (unzlocal_readWord(s->fileHandle,&size_extra_field) != UNZ_OK)
		err=UNZ_ERRNO;
	*poffset_local_extrafield= s->cur_file_info_internal.offset_curfile +
									SIZEZIPLOCALHEADER + size_filename;
	*psize_local_extrafield = (uInt)size_extra_field;

	*piSizeVar += (uInt)size_extra_field;

	return err;
}

/****************************************************************************
  Open for reading data the current file in the zipfile.
  If there is no error and the file is opened, the return value is UNZ_OK.
*/
extern int ZEXPORT UnzOpenCurrentFile (MemHandle mh)
{
int ret=UNZ_OK;
int err=UNZ_OK;
int Store;
uInt iSizeVar;
unz_s* s;
MemHandle read_info_mh;
file_in_zip_read_info_s* pfile_in_zip_read_info;
uLong offset_local_extrafield;  /* offset of the local extra field */
uInt  size_local_extrafield;    /* size of the local extra field */

if (mh == NULL) return UNZ_PARAMERROR;
s=(unz_s*)MemLock(mh);

do {	/* ensure MemUnlock(mh); */
   if (!s->current_file_ok) ret = UNZ_PARAMERROR;
   if ( ret != UNZ_OK) break;

   if (s->file_in_zip_read_info_handle != NULL)	UnzCloseCurrentFile(mh);

   ret = unzlocal_CheckCurrentFileCoherencyHeader(s,&iSizeVar,
		&offset_local_extrafield,&size_local_extrafield);
   if ( ret != UNZ_OK) break;

   read_info_mh = MemAlloc(sizeof(file_in_zip_read_info_s),
		HF_SHARABLE | HF_SWAPABLE, HAF_LOCK | HAF_ZERO_INIT);
   if (read_info_mh == 0) ret = UNZ_INTERNALERROR;
   if ( ret != UNZ_OK) break;

   do {		/* ensure MemUnlock(read_info_mh) */
      pfile_in_zip_read_info = MemDeref(read_info_mh);

pfile_in_zip_read_info->read_bufp = malloc(UNZ_BUFSIZE);
if ( !(pfile_in_zip_read_info->read_bufp) ) {
		ret = UNZ_INTERNALERROR;
		break;
		}

      pfile_in_zip_read_info->offset_local_extrafield = offset_local_extrafield;
      pfile_in_zip_read_info->size_local_extrafield = size_local_extrafield;
      pfile_in_zip_read_info->pos_local_extrafield=0;

      pfile_in_zip_read_info->stream_initialised=0;

      if ((s->cur_file_info.compression_method!=0) &&
		(s->cur_file_info.compression_method!=Z_DEFLATED))
						ret = UNZ_UNKNOWNZIPMETHOD;
      if ( ret != UNZ_OK) break;

      Store = s->cur_file_info.compression_method==0;

      pfile_in_zip_read_info->crc32_wait=s->cur_file_info.crc;
      pfile_in_zip_read_info->crc32=0;
      pfile_in_zip_read_info->compression_method =
					s->cur_file_info.compression_method;
      pfile_in_zip_read_info->fileHandle = s->fileHandle;
      pfile_in_zip_read_info->byte_before_the_zipfile=s->byte_before_the_zipfile;

      pfile_in_zip_read_info->stream.total_out = 0;

      if (!Store)
	{
	  pfile_in_zip_read_info->stream.zalloc = (alloc_func)0;
	  pfile_in_zip_read_info->stream.zfree = (free_func)0;
	  pfile_in_zip_read_info->stream.opaque = (voidpf)0;

	  err=inflateInit2(&pfile_in_zip_read_info->stream, -MAX_WBITS);
	  if (err == Z_OK)
	    pfile_in_zip_read_info->stream_initialised=1;
	/* windowBits is passed < 0 to tell that there is no zlib header.
	 * Note that in this case inflate *requires* an extra "dummy" byte
	 * after the compressed stream in order to complete decompression and
	 * return Z_STREAM_END.
	 * In unzip, i don't wait absolutely Z_STREAM_END because I known the
	 * size of both compressed and uncompressed data
	 */
	}
      pfile_in_zip_read_info->rest_read_compressed =
					    s->cur_file_info.compressed_size;
      pfile_in_zip_read_info->rest_read_uncompressed =
					    s->cur_file_info.uncompressed_size ;
      pfile_in_zip_read_info->pos_in_zipfile =
				    s->cur_file_info_internal.offset_curfile
				    + SIZEZIPLOCALHEADER + iSizeVar;
      pfile_in_zip_read_info->stream.avail_in = (uInt)0;

      } while (0);	/* ensure MemUnlock(read_info_mh) */

   MemUnlock(read_info_mh);
   if ( ret != UNZ_OK ) MemFree(read_info_mh);
	else s->file_in_zip_read_info_handle = read_info_mh;

   } while(0);	/* ensure MemUnlock(mh); */

MemUnlock(mh);
return ret;
}

/****************************************************************************
  Read bytes from the current file.
  buf contain buffer where data must be copied
  len the size of buf.

  return the number of byte copied if somes bytes are copied
  return 0 if the end of file was reached
  return <0 with error code if there is an error
    (UNZ_ERRNO for IO error, or zLib error for uncompress error)
*/
extern int ZEXPORT UnzReadCurrentFile (MemHandle mh,
				  voidp buf, unsigned len)
  {
  int err=UNZ_OK;
  uInt iRead = 0;
  unz_s* s;
  file_in_zip_read_info_s* pfile_in_zip_read_info;
  MemHandle ri_handle;

  if (mh == NULL)	return UNZ_PARAMERROR;
  if (len==0) return 0;

  s=(unz_s*)MemLock(mh);
  ri_handle = s->file_in_zip_read_info_handle;
  if ( ri_handle == 0 )
	{
	MemUnlock(mh);
	return UNZ_PARAMERROR;
	}
/* if the current file is encrypted, you cannot access data of this file */
  if ( s->cur_file_info.flag & UNZ_FLAG_FILE_ENCRYPTED )
	{
	MemUnlock(mh);
	return UNZ_ENCRYPTION_ERROR;
	}

  pfile_in_zip_read_info=MemLock(ri_handle);

	/* this is from old structure, but it seem not able to occur
	if ((pfile_in_zip_read_info->read_buffer == NULL))
		return UNZ_END_OF_LIST_OF_FILE;
	*/

  pfile_in_zip_read_info->stream.next_out = (Bytef*)buf;
  pfile_in_zip_read_info->stream.avail_out = (uInt)len;

  if (len>pfile_in_zip_read_info->rest_read_uncompressed)
		pfile_in_zip_read_info->stream.avail_out =
			  (uInt)pfile_in_zip_read_info->rest_read_uncompressed;

  while (pfile_in_zip_read_info->stream.avail_out>0)
	{
	if ((pfile_in_zip_read_info->stream.avail_in==0) &&
		    (pfile_in_zip_read_info->rest_read_compressed>0))
		{
		uInt uReadThis = UNZ_BUFSIZE;
		if (pfile_in_zip_read_info->rest_read_compressed<uReadThis)
				uReadThis = (uInt)pfile_in_zip_read_info->rest_read_compressed;
		if (uReadThis == 0)
			{
			MemUnlock(mh);
			MemUnlock(ri_handle);
			return UNZ_EOF;
			}

		FilePos(pfile_in_zip_read_info->fileHandle,
		      pfile_in_zip_read_info->pos_in_zipfile +
		      pfile_in_zip_read_info->byte_before_the_zipfile,FILE_POS_START);

		if (FileRead(pfile_in_zip_read_info->fileHandle,
				pfile_in_zip_read_info->read_bufp,uReadThis,
				FALSE ) != uReadThis)
				{
				MemUnlock(mh);
				MemUnlock(ri_handle);
				return UNZ_ERRNO;
				}

		pfile_in_zip_read_info->pos_in_zipfile += uReadThis;
		pfile_in_zip_read_info->rest_read_compressed-=uReadThis;

		pfile_in_zip_read_info->stream.next_in =
			(Bytef*)pfile_in_zip_read_info->read_bufp;
		pfile_in_zip_read_info->stream.avail_in = (uInt)uReadThis;
		}	/* if ( .. && .. ) */

	if (pfile_in_zip_read_info->compression_method==0)	/* == store */
		{
		uInt uDoCopy,i ;
		if (pfile_in_zip_read_info->stream.avail_out <
			    pfile_in_zip_read_info->stream.avail_in)
			    uDoCopy = pfile_in_zip_read_info->stream.avail_out;
		else
			uDoCopy = pfile_in_zip_read_info->stream.avail_in ;

		for (i=0;i<uDoCopy;i++)
				*(pfile_in_zip_read_info->stream.next_out+i) =
				*(pfile_in_zip_read_info->stream.next_in+i);

		pfile_in_zip_read_info->crc32 = crc32(pfile_in_zip_read_info->crc32,
						pfile_in_zip_read_info->stream.next_out,
						uDoCopy);
		pfile_in_zip_read_info->rest_read_uncompressed-=uDoCopy;
		pfile_in_zip_read_info->stream.avail_in -= uDoCopy;
		pfile_in_zip_read_info->stream.avail_out -= uDoCopy;
		pfile_in_zip_read_info->stream.next_out += uDoCopy;
		pfile_in_zip_read_info->stream.next_in += uDoCopy;
		pfile_in_zip_read_info->stream.total_out += uDoCopy;
		iRead += uDoCopy;
		}	/* compression Methopd == 0 */
	else
		{
		uLong uTotalOutBefore,uTotalOutAfter;
		const Bytef *bufBefore;
		uLong uOutThis;
		int flush=Z_SYNC_FLUSH;

		uTotalOutBefore = pfile_in_zip_read_info->stream.total_out;
		bufBefore = pfile_in_zip_read_info->stream.next_out;
			/*
			if ((pfile_in_zip_read_info->rest_read_uncompressed ==
				 pfile_in_zip_read_info->stream.avail_out) &&
				(pfile_in_zip_read_info->rest_read_compressed==0))
				flush = Z_FINISH;
			*/
		err=inflate(&pfile_in_zip_read_info->stream,flush);

		uTotalOutAfter = pfile_in_zip_read_info->stream.total_out;
		uOutThis = uTotalOutAfter-uTotalOutBefore;

		pfile_in_zip_read_info->crc32 =
			crc32(pfile_in_zip_read_info->crc32,bufBefore,
			(uInt)(uOutThis));

		pfile_in_zip_read_info->rest_read_uncompressed -= uOutThis;

		iRead += (uInt)(uTotalOutAfter - uTotalOutBefore);

		if (err==Z_STREAM_END)
			{
			MemUnlock(mh);
			MemUnlock(ri_handle);
			return (iRead==0) ? UNZ_EOF : iRead;
			}

		if (err!=Z_OK)	break;
		}	/* CompressionMethod != 0 */
	}  /* while (pfile_in_zip_read_info->stream.avail_out>0)  */

  MemUnlock(mh);
  MemUnlock(ri_handle);
  if (err==Z_OK)	return iRead;
  return err;
  }

/****************************************************************************
  Give the current position in uncompressed data
*/
extern z_off_t ZEXPORT UnzTell (MemHandle mh)
{
	unz_s* s;
	MemHandle ri_handle;
	file_in_zip_read_info_s* pfile_in_zip_read_info;
	z_off_t offset;

	if (mh ==NULL)	return UNZ_PARAMERROR;

	s=(unz_s*)MemLock(mh);
	ri_handle = s->file_in_zip_read_info_handle;
	if ( ri_handle == 0 )
		{
		MemUnlock(mh);
		return UNZ_PARAMERROR;
		}
/* if the current file is encrypted, you cannot access data of this file */
	if ( s->cur_file_info.flag & UNZ_FLAG_FILE_ENCRYPTED )
		{
		MemUnlock(mh);
		return UNZ_ENCRYPTION_ERROR;
		}

	pfile_in_zip_read_info=MemLock(ri_handle);

	offset = (z_off_t)pfile_in_zip_read_info->stream.total_out;
	MemUnlock(mh);
	MemUnlock(ri_handle);
	return offset;
}

/****************************************************************************
	return 1 if the end of currently decompressed file was reached,
		0 elsewhere
*/
extern int ZEXPORT UnzEof (MemHandle mh)
{
	unz_s* s;
	file_in_zip_read_info_s* pfile_in_zip_read_info;
	MemHandle	ri_handle;
	int ret;


	if (mh ==NULL)	return UNZ_PARAMERROR;

	s=(unz_s*)MemLock(mh);
	ri_handle = s->file_in_zip_read_info_handle;
	if ( ri_handle == 0 )
		{
		MemUnlock(mh);
		return UNZ_PARAMERROR;
		}
/* if the current file is encrypted, you cannot access data of this file */
	if ( s->cur_file_info.flag & UNZ_FLAG_FILE_ENCRYPTED )
		{
		MemUnlock(mh);
		return UNZ_ENCRYPTION_ERROR;
		}

	pfile_in_zip_read_info=MemLock(ri_handle);
	if (pfile_in_zip_read_info->rest_read_uncompressed == 0)
			ret = 1;
		else	ret = 0;

	MemUnlock(mh);
	MemUnlock(ri_handle);
	return ret;
}



/****************************************************************************
  Read extra field from the current file (opened by unzOpenCurrentFile)
  This is the local-header version of the extra field (sometimes, there is
    more info in the local-header version than in the central-header)

  if buf==NULL, it return the size of the local extra field that can be read

  if buf!=NULL, len is the size of the buffer, the extra header is copied in
	buf.
  the return value is the number of bytes copied in buf, or (if <0)
	the error code
*/
extern int ZEXPORT UnzGetLocalExtrafield (MemHandle mh,
					 voidp buf, unsigned len)
{
	unz_s* s;
	file_in_zip_read_info_s* pfile_in_zip_read_info;
	uInt read_now;
	uLong size_to_read;
	MemHandle ri_handle;

	if (mh ==NULL)	return UNZ_PARAMERROR;

	s=(unz_s*)MemLock(mh);
	ri_handle = s->file_in_zip_read_info_handle;
	if ( ri_handle == 0 )
		{
		MemUnlock(mh);
		return UNZ_PARAMERROR;
		}


	size_to_read = (pfile_in_zip_read_info->size_local_extrafield -
				pfile_in_zip_read_info->pos_local_extrafield);

	if (buf==NULL) {
		MemUnlock(mh);
		MemUnlock(ri_handle);
		return (int)size_to_read;
		}

	if (len>size_to_read)
		read_now = (uInt)size_to_read;
	else
		read_now = (uInt)len ;

	if (read_now==0) {
		MemUnlock(mh);
		MemUnlock(ri_handle);
		return 0;
		}

	FilePos(pfile_in_zip_read_info->fileHandle,
	      pfile_in_zip_read_info->offset_local_extrafield +
	      pfile_in_zip_read_info->pos_local_extrafield,FILE_POS_START);

	if (FileRead(pfile_in_zip_read_info->fileHandle,buf,size_to_read,
				FALSE) != size_to_read) {
				MemUnlock(mh);
				MemUnlock(ri_handle);
				return UNZ_ERRNO;
				}
	MemUnlock(mh);
	MemUnlock(ri_handle);
	return (int)read_now;
}

/*
  Close the file in zip opened with unzipOpenCurrentFile
  Return UNZ_CRCERROR if all the file was read but the CRC is not good
*/
extern int ZEXPORT UnzCloseCurrentFile (MemHandle mh)
{
int err=UNZ_OK;
unz_s* s;
file_in_zip_read_info_s* pfile_in_zip_read_info;

if (mh == NULL)	return UNZ_PARAMERROR;

s=(unz_s*)MemLock(mh);

do {	/* ensure MemUnlock(mh) */

   if ( s->file_in_zip_read_info_handle == 0 )  err = UNZ_PARAMERROR;
   if ( err != UNZ_OK ) break;

   pfile_in_zip_read_info=MemLock(s->file_in_zip_read_info_handle);

   if (pfile_in_zip_read_info->rest_read_uncompressed == 0)
	{
	if (pfile_in_zip_read_info->crc32 != pfile_in_zip_read_info->crc32_wait)
				err=UNZ_CRCERROR;
	}

   if (pfile_in_zip_read_info->stream_initialised)
				inflateEnd(&pfile_in_zip_read_info->stream);

   pfile_in_zip_read_info->stream_initialised = 0;
free(pfile_in_zip_read_info->read_bufp);

   MemFree(s->file_in_zip_read_info_handle);

   s->file_in_zip_read_info_handle = NULL;

   } while (0);

MemUnlock(mh);
return err;
}

/*
  Get the global comment string of the ZipFile, in the szComment buffer.
  uSizeBuf is the size of the szComment buffer.
  return the number of byte copied or an error code <0
*/
extern int ZEXPORT UnzGetGlobalComment (MemHandle mh,
		   char *szComment,  uLong uSizeBuf)
{
	unz_s* s;
	uLong uReadThis ;

	if ( mh ==NULL)	return UNZ_PARAMERROR;

	s=(unz_s*)MemLock(mh);

	uReadThis = uSizeBuf;
	if (uReadThis>s->gi.size_comment)
		uReadThis = s->gi.size_comment;

	FilePos(s->fileHandle,s->central_pos+22,FILE_POS_START);

	if (uReadThis>0)
	  {
	  *szComment='\0';
	  if (FileRead(s->fileHandle,szComment,uReadThis,FALSE) != uReadThis) {
		MemUnlock(mh);
		return UNZ_ERRNO;
		}
	  }

	if ((szComment != NULL) && (uSizeBuf > s->gi.size_comment))
		*(szComment+s->gi.size_comment)='\0';
	MemUnlock(mh);
	return (int)uReadThis;
}


/*****************************************************************************
	returns infos in qlp about the current file used for quick locate the
	specified File without using UnzLoacteFile, whis is very slow
	because it searchs for the filename.
	return: TRUE, if current file is correct located, FALSE if not
*/
extern int ZEXPORT UnzGetGoToAtInfo (MemHandle mh, QuickLocateParams * qlp)
{
	unz_s* s;

	if (mh == NULL) return UNZ_PARAMERROR;
	s=(unz_s*)MemLock(mh);

	qlp->currentPosInCentralDir = s->pos_in_central_dir;
	qlp->currentFileNumber = s->num_file;
	qlp->currentFileOk = s->current_file_ok;

	MemUnlock(mh);
	return qlp->currentFileOk;
}

/*****************************************************************************
	locates an file without using UnzLoacteFile
	see UnzGetGoToAtInfo()
	return: UNZ_OK if there is no error
*/
extern int ZEXPORT UnzGoToFileAt (MemHandle mh, QuickLocateParams * qlp)
{
	int err=UNZ_OK;
	unz_s* s;

	if (mh == NULL) return UNZ_PARAMERROR;
	s=(unz_s*)MemLock(mh);

	s->pos_in_central_dir = qlp->currentPosInCentralDir;
	s->num_file = qlp->currentFileNumber;

	err=unzlocal_GetCurrentFileInfoInternal(mh,&s->cur_file_info,
			 &s->cur_file_info_internal, NULL,0,NULL,0,NULL,0);

	s->current_file_ok = (err == UNZ_OK);
	MemUnlock(mh);
	return err;
}


/*****************************************************************************
	Assign a new FileHandle to the unzDesc.
	This is used after "save as" command.
	Because of the actual physical file is changed, there schould not be
	any file opened in the archive.
*/
extern int ZEXPORT UnzSetNewFileHandle (MemHandle mh, FileHandle fh)
{
unz_s* s;

	if (mh == NULL) return UNZ_PARAMERROR;

	s=(unz_s*)MemLock(mh);
	if (s->file_in_zip_read_info_handle!=NULL) UnzCloseCurrentFile(mh);
	s->fileHandle = fh;
	MemUnlock(mh);
	return UNZ_OK;
	}


