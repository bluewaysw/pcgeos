/*********************************************************************/
/*								     */
/*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     */
/*								     */
/* 	PROJECT:	PC GEOS					     */
/* 	MODULE:							     */	
/* 	FILE:		hsierror.h				     */
/*								     */
/*	AUTHOR:		jimmy lefkowitz				     */
/*								     */
/*	REVISION HISTORY:					     */
/*								     */
/*	Name	Date		Description			     */
/*	----	----		-----------			     */
/*	jimmy	1/27/92		Initial version			     */
/*								     */
/*	DESCRIPTION:						     */
/*								     */
/*	$Id: hsierror.h,v 1.1 97/04/07 11:28:23 newdeal Exp $
/*							   	     */
/*********************************************************************/

 
/**************************************************************************\
  HSIERROR.H - Header file for Error code for HALCYON SOFTWARE CORP.
 
  Description :
     Error code definition file used by Halcyon Software.  In Windows 
     environment, a message.rc file contain all error strings to be
     used in conjunction with message box.  The same resource file is
     used with DOS error handling routine to provide equivalent
     functionality.
 
  Implementation :
     This file is a collection of error codes used in all Halcyon 
     Software product/project.  
 
     Caller should not use any direct value, since new error codes are
     introduced constantly.  The code structure will be remapped at 
     later time to handle different classes of errors (e.g. Fatal, 
     Warning, Alarm, etc.).
 
  Note :
     The most important messages are disk-based errors. These type of
     messages should be handled properly.
 
\**************************************************************************/
 
typedef word  HSI_ERROR_CODE;
 
/* error code definitions*/

#include <Internal/xlatLib.h>
/* now map these TransErrors to the HSI_ERROR */

#define   HSI_EC_SUCCESS       TE_NO_ERROR    /* 0 no Error*/
 
/* File I/O */
 
#define   HSI_EC_FAIL          TE_ERROR       /* operation failed          */
#define   HSI_EC_NOFILES       TE_FILE_ERROR  /* no file name specified    */
#define   HSI_EC_NOINPUTFILE   TE_FILE_ERROR  /* no input file             */
#define   HSI_EC_NOOUTPUTFILE  TE_FILE_ERROR  /* no output file            */
#define   HSI_EC_BADCOMMAND    TE_ERROR       /* 5bad command line option  */
#define   HSI_EC_EOF           TE_FILE_ERROR  /* end of file encountered   */
#define   HSI_EC_SRCCANTSEEK   TE_FILE_ERROR  /* cannot seek input file    */
#define   HSI_EC_SRCCANTREAD   TE_FILE_READ   /* cannot read input file    */
#define   HSI_EC_SRCCANTWRITE  TE_FILE_WRITE  /* cannot write to input file*/
#define   HSI_EC_SRCCANTOPEN   TE_FILE_OPEN   /* cannot open input file    */
#define   HSI_EC_DSTCANTSEEK   TE_FILE_ERROR  /* cannot seek output file   */
#define   HSI_EC_DSTCANTREAD   TE_FILE_READ   /* cannot read output file   */
#define   HSI_EC_DSTCANTWRITE  TE_FILE_WRITE  /* cannot write output file  */
#define   HSI_EC_DSTCANTOPEN   TE_FILE_OPEN   /* cannot open output file   */
#define   HSI_EC_CANTSEEK      TE_FILE_ERROR  /* cannot seek (generic)     */
#define   HSI_EC_CANTREAD      TE_FILE_READ   /* cannot read (generic)     */
#define   HSI_EC_CANTWRITE     TE_FILE_WRITE  /* cannot write (generic)    */
#define   HSI_EC_CANTOPEN      TE_FILE_OPEN   /* cannot open (generic)     */
#define   HSI_EC_READERROR     TE_FILE_READ   /* read error                */
#define   HSI_EC_WRITEERROR    TE_FILE_WRITE  /* write error               */
#define   HSI_EC_OUTOFTMPDISK  TE_DISK_FULL   /* out of temp dirve space   */
#define   HSI_EC_NODISKSPACE   TE_DISK_FULL   /* not enough disk space     */
#define   HSI_EC_TMPCORRUPTED  TE_FILE_ERROR  /* temp file corrupted       */
 
/* command lines */
 
#define   HSI_EC_BADCOMMANDLINE TE_ERROR            /* bad command line option   */
#define   HSI_EC_OPENTMPFILE   TE_FILE_OPEN   /* cannot open tmp file      */
#define   HSI_EC_NOTDIBFILE    TE_FILE_ERROR  /* not DIB file available    */
#define   HSI_EC_INVALIDOPTION TE_ERROR       /* invalid option            */
#define   HSI_EC_INVALIDINPUT  TE_FILE_ERROR  /* invalid input file        */
#define   HSI_EC_INVALIDFILE   TE_FILE_ERROR  /* invalid file              */
#define   HSI_EC_INVALIDEXPR   37             /* invalid expression        */
#define   HSI_EC_INCOMPATIBLE  TE_FILE_ERROR  /* incompatible file         */
                                              /* conversion request        */

/* system resource */
 
#define   HSI_EC_NOMEMORY      TE_OUT_OF_MEMORY/* out of memory            */
#define   HSI_EC_NOMOREBUFS    TE_OUT_OF_MEMORY/* out of temp buffer       */
#define   HSI_EC_NOMORENAMES   TE_ERROR        /* out of internal name     */
#define   HSI_EC_DUMPMESSAGE   TE_ERROR        /* dump error message       */
 
/* clipboard  */
 
#define   HSI_EC_CLPINUSE      TE_ERROR        /* Clipboard in use         */
#define   HSI_EC_CLPCANTOPEN   TE_ERROR        /* clipboard open error     */
#define   HSI_EC_CLPERROR      TE_ERROR        /* clipboard access error   */
#define   HSI_EC_CLPEMPTY      TE_ERROR        /* clipboard is empty       */
#define   HSI_EC_UNSUPTCLP     TE_ERROR        /* unsupp clipboard format  */
 
/* kernel, internal to Halcyon Software */
 
#define   HSI_EC_PCODE          TE_ERROR       /* pcode encountered        */
#define   HSI_EC_CANTLOADLIB    TE_ERROR       /* cannot load library      */
#define   HSI_EC_LIBCODE        TE_ERROR       /* lib module encountered   */
#define   HSI_EC_NOOBJECT       TE_ERROR       /* no object resource       */
#define   HSI_EC_NOMATCH        TE_ERROR       /* no match found           */
#define   HSI_EC_ABANDONSEARCH  TE_ERROR       /* cannot search list       */
#define   HSI_EC_EMPTYLIST      TE_ERROR       /* empty list               */
 
 
/* printer */
 
#define   HSI_EC_PRTNOTREADY            TE_ERROR /* printer not ready        */
#define   HSI_EC_PRTERROR               TE_ERROR /* printer error            */
#define   HSI_EC_PRTSETUPERR            TE_ERROR /* printer error            */
 
/* file conversion */
 
#define   HSI_EC_INVALIDBMPHEADER  TE_INVALID_FORMAT /* Invalid Bitmap hdr */
#define   HSI_EC_WINDOWSBITMAP     TE_ERROR        /* valid Windows 3.0 DIB    */
#define   HSI_EC_OS2BITMAP         TE_ERROR         /* valid OS2 Bitmap file    */
#define   HSI_EC_INVALIDBITMAPFILE TE_INVALID_FORMAT /* Invalid Bitmap file*/
#define   HSI_EC_UNSUPPORTED_DATA  TE_INVALID_FORMAT /* unsupport data type*/
#define   HSI_UNSUPPORTED_COMPRESSION  TE_INVALID_FORMAT 
#define   HSI_EC_NOFILTER       TE_ERROR            /* No conversion filter*/
#define   HSI_EC_NOTGIF         TE_INVALID_FORMAT   /* this is not a GIF   */
#define   HSI_EC_NO24BIT        TE_INVALID_FORMAT   /* cannot convert 24bit*/
#define   HSI_EC_NOCOLOR        TE_INVALID_FORMAT   /* cannot save as color*/
#define   HSI_EC_NOFORMAT       TE_INVALID_FORMAT   /* No format specified */
#define   HSI_EC_CORRUPTED      TE_FILE_ERROR       /* input file corrupted*/
#define   HSI_EC_EPSINCFILEERR  TE_ERROR            /* cant open include   */ 
#define   HSI_EC_INVALIDTAG     TE_INVALID_FORMAT   /* invalid TIFF tag    */
#define   HSI_EC_INVALIDCOMP    TE_INVALID_FORMAT   /* invalid compression */
#define   HSI_EC_UNSUPPORTED    TE_IMPORT_NOT_SUPPORTED 
                                                    /* unsupported format  */
#define   HSI_EC_OUTFILEUNSUPT  TE_EXPORT_NOT_SUPPORTED 
                                                    /* unsupported format  */
#define   HSI_EC_UNSUPTCOMP     TE_IMPORT_NOT_SUPPORTED  
                                                   /* unsupported compres. */
#define   HSI_EC_FILETOOBIG     TE_FILE_TOO_LARGE  /* file size too big    */
#define   HSI_EC_UNSUPTTYPE     TE_IMPORT_NOT_SUPPORTED 
                                                   /* unsupport file type  */
#define   HSI_EC_INVALIDLZW     TE_INVALID_FORMAT  /* Bogus LZW data       */
#define   HSI_EC_NOTHALO        TE_INVALID_FORMAT  /* Not a Dr. Halo image */
#define   HSI_EC_HALO16ONLY     TE_INVALID_FORMAT  /* Only 16 color halo   */
#define   HSI_EC_NOROOM4FONT    TE_ERROR           /* no room for font tbl */
 
/* windows related */
 
#define   HSI_EC_ERRNEWWND                 TE_ERROR /* cannot create new window */
#define   HSI_EC_WINHANDLE                 TE_ERROR /* window handle to process */
#define   HSI_EC_IGOTFOCUS                 TE_ERROR /* window got focus */
 
#define   HSI_EC_CANTLOADDLL               TE_ERROR /* cannot load DLL          */
#define   HSI_EC_INPROGRESS                TE_ERROR /* conversion in progress   */
 
/* non-error message */
 
#define   HSI_REDRAW                       TE_ERROR/* refresh the screen       */
#define   HSI_SKIPNOMEMORY                 TE_ERROR /* not enough memory, skip  */
                                               /* current record.          */
#define   HSI_EC_EXIT                      TE_ERROR/* exit appliction */
    
/* fatal, unknown error */

#define   HSI_EC_ABORT                     TE_ERRRO /* operation abort          */
#define   HSI_EC_OPERATORABORT             TE_ERROR /* abort by operator        */
#define   HSI_EC_UNKNOWNFAILURE            TE_ERROR /* unknown failure          */
 





