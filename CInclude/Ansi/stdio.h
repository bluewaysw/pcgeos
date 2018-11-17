/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	stdio.h
 * AUTHOR:	Tony Requist: February 1, 1991
 *
 * DECLARER:	AnsiC
 *
 * DESCRIPTION:
 *	This file defines standard stdio.h functions
 *
 *	$Id: stdio.h,v 1.1 97/04/04 15:50:23 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__STDIO_H
#define __STDIO_H

#include <geos.h>
#include <stdarg.h>

/*----------------------------------------------------------------------
  	Constants & Structures
----------------------------------------------------------------------*/

#define _IOFBF		0
#define	_IOLBF		1
#define	_IONBF		2
#define EOF 		(-1)
#define FILENAME_MAX	32
#define FOPEN_MAX	8

/* the following define the File Position modes used by fseek */
#define  SEEK_SET FILE_POS_START  
#define  SEEK_CUR FILE_POS_RELATIVE
#define  SEEK_END FILE_POS_END

#ifndef NULL
#define NULL 0
#endif

typedef void FILE;

/*----------------------------------------------------------------------
	Declarations
----------------------------------------------------------------------*/

extern sword
    _pascal vsprintf(TCHAR *__buf, const TCHAR *__format, va_list __args);

extern sword
    _cdecl sprintf(TCHAR *__buf, const TCHAR *__format, ...);

#ifdef DO_DBCS
extern sword
    _pascal vsprintfsbcs(char *__buf, const char *__format, va_list __args);

extern sword
    _cdecl sprintfsbcs(char *__buf, const char *__format, ...);
#endif


/*----------------------------------------------------------------------
	General information on streams:
	    Applications wanting to use streams for buffered input
	    are welcome to, but must be careful not to intermix
	    calls to the C stdio library & the PC/GEOS file system.
	    If one would like to convert a PC/GEOS file handle to a
	    buffered stream, used fdopen() & fdclose().

	modeString:
			  Read/Write modes - [r, w, a], +, b - (no default)
			  ----------------
			  r:		open for reading
			  w:		open for writing (create/truncate)
			  a:		append mode (currently not supported)
			  b:		binary mode (currently not supported)
			  +:		allow both r/w

			  Deny modes - [E, N, R, W] - (E is default)
			  ----------
			  E		deny everyone (exclusive access)
			  N		deny none
			  R		deny read
			  W		deny write
			  
			  Other modes - V - (PC/GEOS file is default)
			  -----------
			  V		native file
----------------------------------------------------------------------*/

/*
  FOPEN: opens the file whose name is the string pointed to by filename.
         The file is opened in the mode indicated by the modeString. 
	 Returns a stream fptr if successful, or NULL if not.
*/
extern FILE *
  _pascal fopen(const char *_filename, const char * _modeString);

/*
  FDOPEN: opens the file whose handle is passed in fileHan. The stream
          is opened in the mode indicated by the modeString. Returns
	  a stream fptr if successful, or NULL if not.
*/
extern FILE *
  _pascal fdopen(FileHandle _fileHan, const char * _modeString);

/*
  FCLOSE: closes the file. Returns zero if the file was successfully closed,
          EOF if any errors were detected.
*/
extern int
  _pascal fclose(FILE *_stream);

/*
  FDCLOSE: closes the stream. Returns the PC/GOEOS file handle associated
           with the stream (the opposite of fdopen).
*/
extern FileHandle
  _pascal fdclose(FILE *_stream);

/*
  FSEEK: sets the file position indicator for the file. Returns nonzero for 
         a request that can't be satisfied.
*/
extern int
  _pascal fseek(FILE *_stream,dword _posOrOffset, word _mode);

/*
  FTELL: obtains the current position of the file position indicator for the
          file. Returns the current value of the position indicator if 
          successful, if unsuccessful, returns -1L.
*/
extern dword
  _pascal ftell(FILE *_stream);

/*
  FWRITE: writes from the array pointed to by buf, up to nmemb elements of
          elSize. Returns the number of elements successfuly written, this 
          will be less than nmemb if there was an error.
*/
extern word
  _pascal fwrite(const void * _buf,word _elSize, word _nmemb, FILE *_stream);

/*
  FREAD: reads into the array pointed to by buf, nmemb elements of elSize from
         the file. Returns the number of elements successfully read.
*/
extern word
  _pascal fread(void * _buf, word _elSize, word _nmemb, FILE *_stream);

/*
  FGETC: reads one char from the file associated with the stream.
         Returns char as an integer or EOF if error.
 */
extern int
  _pascal fgetc(FILE *_stream);

/*
  FGETS: reads in a string ending in a newline of EOF and adds a NULL
  	 terminateor to the end.
	 Returns the buffer passed in
*/

extern char *
  _pascal fgets(char *buffer, int buflength, FILE *_stream);

/*
  FEOF:	returns non-zero if the EOF (end-of-file) has been reached
*/
extern int
  _pascal feof(FILE *_stream);

/*
  FFLUSH: flushes stream buffer to file (if required).
 */

extern int
  _pascal fflush(FILE *_stream);

/* 
  RENAME:
        renames the file named by old name to new name. Returns zero if the
        operation succeeds, nonzero if it fails
*/
extern int
  _pascal rename(const char * _oldName, const char * _newName);

/*
  FSCANF: formatted scan of file
 */
extern int
  _cdecl fscanf(FILE *file, const char *fmt, ...);

/*
  SSCANF: formatted scan of string
 */
extern int
  _cdecl sscanf(const char *ibuf, const char *fmt, ...);

#ifdef __HIGHC__
pragma Alias(vsprintf, "VSPRINTF");
pragma Alias(sprintf, "_sprintf");
pragma Alias(fopen, "FOPEN");
pragma Alias(fdopen, "FDOPEN");
pragma Alias(fclose, "FCLOSE");
pragma Alias(fdclose, "FDCLOSE");
pragma Alias(fseek, "FSEEK");
pragma Alias(ftell, "FTELL");
pragma Alias(fwrite, "FWRITE");
pragma Alias(fread, "FREAD");
pragma Alias(fgetc, "FGETC");
pragma Alias(fgets, "FGETS");
pragma Alias(feof, "FEOF");
pragma Alias(fflush, "FFLUSH");
pragma Alias(rename, "RENAME");
#endif

#endif  /* __STDIO_H  */





