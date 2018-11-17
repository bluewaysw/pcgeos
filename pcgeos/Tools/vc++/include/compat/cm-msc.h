/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  Unix compatibility library
 * FILE:	  cm-msc.h
 *
 * AUTHOR:  	  Tim Bradley, 3/17/97
 *
 * REVISION HISTORY:
 *	Name	 Date		Description
 *	----	 ----		-----------
 *	tbradley 3/17/96	initial revision
 *
 * DESCRIPTION:
 *	Do not include this file directly.  It is meant to be included
 *	via config.h.  See config.h for details.
 *
 *
 * 	$Id: cm-msc.h,v 1.2 1997/03/18 00:27:24 tbradley Exp $
 *
 ***********************************************************************/
#ifndef _CM_MSC_H_
#define _CM_MSC_H_

#ifndef _MSC_VER
#error Why are you including this file?
#endif

/***********************************************************************
 *
 * Remap routine names with macros
 *
 ***********************************************************************/

/* these macros conflict with os90's */
#undef FW_LIGHT
#undef FW_NORMAL
#undef FW_BOLD
#undef FW_BLACK
#undef FF_SCRIPT

/***********************************************************************
 *
 * Define any routines provided by this compiler's runtime
 *
 ***********************************************************************/
/* don't actually have strcasecmp or strncasecmp, but we don't have strcmpi
 * or strncmpi either which is what config.h will use if we don't define
 * the following symbols
 */
#define HAVE_STRNCASECMP 1
#define HAVE_STRCASECMP 1

/* define strncasecmp and strcasecmp to be what we really have */
#define strncasecmp strnicmp
#define strcasecmp stricmp

/***********************************************************************
 *
 * Define compiler's behavior
 *
 ***********************************************************************/

/* MSC likes char foo[0], not char foo[]. */
#define LABEL_IN_STRUCT 0

/* MSC doesn't allow arithmetic on void *. */
typedef char *genptr;

/* microsoft supports _inline */
#define inline _inline

/* microsoft uses _popen() instead of popen() */
#define popen  _popen
#define pclose _pclose

#endif /* _CM_MSC_H_ */
