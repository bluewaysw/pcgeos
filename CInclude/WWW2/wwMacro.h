/***********************************************************************
 *
 *	Copyright (c) Geoworks 1998.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  WWW2 Library
 * MODULE:	  macros
 * FILE:	  wwMacro.h
 *
 * AUTHOR:  	  Allen Yuen: Aug  3, 1998
 *
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	allen   	8/ 3/98   	Initial version
 *
 * DESCRIPTION:
 *
 *	C Macros commonly used in the library.
 *
 *	$Id: //depot/pcgeos/CInclude/WWW2/wwMacro.h#1 $
 *
 ***********************************************************************/
#ifndef _WWMACRO_H_
#define _WWMACRO_H_

#include <ec.h>


/* --------------------------------------------------------------------------
 * 		MACROS
 * --------------------------------------------------------------------------*/

/*
 * Macros to use Libary dgroup.
 */
#ifdef __HIGHC__

#ifndef PUSHDS
#define PUSHDS	_inline(0x1e)	/* push	ds */
#endif

#ifndef POPDS
#define POPDS	_inline(0x1f)	/* pop	ds */
#endif

#endif

#ifdef __BORLANDC__

#ifndef PUSHDS
#define PUSHDS  asm{push ds}
#endif

#ifndef POPDS
#define POPDS   asm{pop  ds}
#endif

#endif

#ifdef __WATCOMC__

#ifndef PUSHDS
void _PUSHDS(void);
#pragma aux _PUSHDS = "push ds";
#define PUSHDS  _PUSHDS()
#endif

#ifndef POPDS
void _POPDS(void);
#pragma aux _POPDS = "pop ds";
#define POPDS   _POPDS()
#endif

#endif

#ifndef SET_DS_LIB_DGROUP
#define SET_DS_LIB_DGROUP GeodeLoadDGroup (GeodeGetCodeProcessHandle())
                                /* destroys ds! */
#endif


#if ERROR_CHECK

#define ASSERT(expr) { if (!(expr)) FatalError(-1); }
#define ASSERTS(expr, str) { if (!(expr)) FatalError(-1); }
#define PARAM_ASSERT(expr) ASSERT(expr)
#define PARAM_ASSERTS(expr, str) ASSERT(expr)
#define EC_WARN(str) CWarningNotice(-1)
#define EC_FAIL(str)  FatalError(-1);

#else

#define ASSERT(expr)
#define ASSERTS(expr, str)
#define PARAM_ASSERT(expr)
#define PARAM_ASSERTS(expr, str)
#define EC_WARN(str)
#define EC_FAIL(str)

#endif /* ERROR_CHECK */

#define USE_IT(arg) (void)(arg)

/*
 * Use the macros since they are LOT faster than the system versions. 
 */
#define ISWHITE(c) \
	(((c==' ') || (c>=9 && c<=13)) ? TRUE : FALSE)

#define ISDIGIT(c) \
	((c>='0' && c<='9') ? TRUE : FALSE)

#define ISALPHA(c)  \
	(((c>='a' && c<='z') || (c>='A' && c<='Z')) ? TRUE : FALSE)

#define ISALNUM(c) \
	((ISALPHA(c) || ISDIGIT(c)) ? TRUE : FALSE)

#define TOLOWER(c) \
        (((c>='A') && (c<='Z')) ? c+32 : c)

#define TOUPPER(c) \
        (((c>='a') && (c<='z')) ? c-32 : c)



#endif /* _WWMACRO_H_ */
