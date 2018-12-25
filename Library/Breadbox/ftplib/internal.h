/*************************************************************************

                Copyright (c) Breadbox Computer Company 1998
                         -- All Rights Reserved --

  PROJECT:      FTP Client
  MODULE:       FTP Library
  FILE:         internal.h

  AUTHOR:       Gerd Boerrigter

  $Header: H:\\CVSROOT\\GEOS\\LIBRARY\\BREADBOX\\FTPLIB\\RCS\\internal.h 1.1 1998/12/11 16:45:36 gerdb Exp $

  DESCRIPTION:
    FtpClass is a class implementing a simple FTP client as described in
    {{REF:RFC959}}.
    This file provides wrappers for a subset of the {{REF:RFC959}}
    commands.

  REVISION HISTORY:
    Date      Name      Description
    --------  --------  -----------
    98-08-31  GerdB     Initial version.

*************************************************************************/

#ifndef __INTERNAL_H
#define __INTERNAL_H

#define SIZE_UPLOAD_BLOCK       4096  /* bytes */
#define SIZE_DOWNLOAD_BLOCK     4096

/*************************************************************************
    Errors and warnings for SWAT
*************************************************************************/

/* Fatal errors */
typedef enum {
    /** The FTP object is not connected to a server, but a method which
        needs a connection is called. */
    FTP_NOT_CONNECTED,
    ILLEGAL_SOCKET,

    /** A function/method was called with an illegal (zero or negativ)
        length (buffer size) parameter. */
    ILLEGAL_LENGTH,

    /** An internal string buffer is too small.  FatalErrors, even if
        NON-EC version. */
    FTP_STRING_BUFFER_SIZE_EXCEEDED = 0x8000

} FatalErrors;

/* SWAT warnings */
typedef enum {
    /**  */
    DUMMY_WARNING
} Warnings;

/* XXX: Check if it is available in Nokia 2.0 SDK! */
#define ECCheckSocket( sock ) if ( sock == 0 ) FatalError( ILLEGAL_SOCKET )


/*************************************************************************
    Functions
*************************************************************************/

#endif /* __INTERNAL_H */

/* internal.h */
