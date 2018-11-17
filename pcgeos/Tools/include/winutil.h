/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  GEOS Tools
 * MODULE:	  Win32 utilities library
 * FILE:	  winutil.h
 *
 * AUTHOR:  	  Jacob A. Gabrielson: Oct 28, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jacob	10/28/96   	Initial version
 *
 * DESCRIPTION:
 *
 *	Interface to Win32 utility library.
 *
 * 	$Id: winutil.h,v 1.3 1997/04/10 00:17:21 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _WINUTIL_H_
#define _WINUTIL_H_

//#define Boolean int
#if defined _MSC_VER
#ifndef Boolean
typedef int Boolean ;
#endif
#endif;

extern void	WinUtil_PrintError(char *fmt, ...);
extern void	WinUtil_SprintError (char *buf, char *fmt, ...);
extern char	*WinUtil_LastPathSep(char *path);
extern char	*WinUtil_FirstPathSep(char *path);

extern Boolean	Registry_FindStringValue(const char *regPath,
					 const char *regKey,
					 unsigned char *dataBuffer,
					 long buflen);
extern Boolean	Registry_UpdateStringValue(const char *regPath, 
					   const char *regKey, 
					   unsigned char *dataBuffer);
extern Boolean 	Registry_FindDWORDValue(const char *regPath,
					const char *regKey,
					long *longval);
extern Boolean	Registry_UpdateDWORDValue(const char *regPath, 
					  const char *regKey, 
					  long *longval);
/*
 * the names of registry stuff (default for SDK_NAME can be overridden)
 */
#define REG_GEO_NAME	"Software\\Geoworks"
#define SDK_NAME 	"ntsdk30"

#endif /* _WINUTIL_H_ */
