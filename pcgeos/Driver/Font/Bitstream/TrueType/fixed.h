/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	TrueType/fixed.h
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: fixed.h,v 1.1 97/04/18 11:45:19 newdeal Exp $
 *
 ***********************************************************************/

/*************************************************************************
 * fixed.h
 *
 * Defines and typedefs for fixed-point functions
 *
 *************************************************************************/
/********************* Revision Control Information **********************************
*                                                                                    *
*     $Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/fixed.h,v 1.1 97/04/18 11:45:19 newdeal Exp $                                                                       *
*                                                                                    *
*     $Log:	fixed.h,v $
 * Revision 1.1  97/04/18  11:45:19  newdeal
 * Initial revision
 * 
 * Revision 1.1.7.1  97/03/29  07:06:01  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:13:47  brianc
 * support TrueType
 * 
 * Revision 6.44  93/03/15  13:06:50  roberte
 * Release
 * 
 * Revision 6.7  93/01/08  10:26:59  roberte
 * Put #ifndef fscdefs_h check around typedefs of Fract and Fixed.
 * 
 * Revision 6.6  93/01/08  09:46:33  roberte
 * Added check of fscdefs_h for #defines of F26Dot6, boolean and others
 * so that speedo.h may be included first.
 * 
 * Revision 6.5  92/12/29  12:44:15  roberte
 * Changed #ifdef INTEL test to #if INTEL so can be compatible
 * with 4-in-1 and speedo.h
 * 
 * Revision 6.4  92/12/29  11:19:20  roberte
 * Only define TRUE and FALSE if not previously defined.
 * 
 * Revision 6.3  92/11/19  15:44:29  roberte
 * Release
 * 
 * Revision 6.1  91/08/14  16:44:38  mark
 * Release
 * 
 * Revision 5.1  91/08/07  12:25:50  mark
 * Release
 * 
 * Revision 4.3  91/08/07  11:49:25  mark
 * remove rcsstatus string
 * 
 * Revision 4.2  91/08/07  11:38:34  mark
 * added RCS control strings
 * 
*************************************************************************************/


#ifndef fscdefs_h
typedef long Fixed;
typedef long Fract;
#endif

typedef unsigned long UFract;
#ifndef fscdefs_h
typedef long int32;
typedef short int16;
#endif
typedef short ShortFrac;                        /* 2.14 */
#ifndef fscdefs_h
typedef unsigned short uint16;
typedef unsigned long uint32;
typedef long F26Dot6;
#endif

#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE 1
#endif

#define FRACONEHALF 0x20000000
#define MINUSONE    0xC0000000
#define POSINFINITY                     0x7FFFFFFF
#define NEGINFINITY                     0x80000000
#define FASTMUL26LIMIT          46340
#define ONEFIX 		( 1L << 16 )
#define FASTDIV26LIMIT  (1L << 25)
#define HIBITSET                0x80000000

#define SHORTMUL(a,b)	(int32)((int32)(a) * (int32)(b))
#ifndef fscdefs_h
#if INTEL
#define USHORTMUL(a, b)	((uint32)((uint32)(a)*(uint32)(b)))
#else
#define USHORTMUL(a, b)	((uint32)((uint16)(a)*(uint16)(b)))
#endif	/* intel */
#endif /* ifndef fscdefs_h */
#define HIWORD(n)                       ((uint16)((uint32)(n) >> 16))
#define LOWORD(n)                       ((uint16)(n))
