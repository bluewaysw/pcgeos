/***********************************************************************
 *
 *	Copyright (c) 2000 Turon Technologies, Inc. -- All Rights Reserved
 *
 * PROJECT:	PC/GEOS
 * FILE:	mp3.h
 * AUTHOR:	Martin Turon, April 2000
 *
 * DESCRIPTION:
 *	Global routines of the MP3 library.
 *
 *	$Id: mp3.h,v 1.1 2000/4/14 15:57:03 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__MP3_H
#define __MP3_H

#include <stdarg.h>

/*
 * Arguments: <input filename>, <output filename>, ...
 */
int Mp3Decode(int argc, char **argv);

/*
 * Debugging function used to set a callback to replace printf() calls
 * in the MP3 library.  Calls occur via ProcCallFixedOrMovable_cdecl.
 * This routine works only in an EC build and does
 * nothing in an NC build.
 */
typedef void (*Mp3PrintfCallback)(const char _FAR *__format, va_list ap);
void Mp3SetDebug(Mp3PrintfCallback debug_cb);

#endif
