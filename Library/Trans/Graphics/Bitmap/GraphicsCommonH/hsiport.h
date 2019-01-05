/*********************************************************************/
/*								     */
/*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     */
/*								     */
/* 	PROJECT:	PC GEOS					     */
/* 	MODULE:							     */	
/* 	FILE:		hsiport.h				     */
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
/*	$Id: hsiport.h,v 1.1 97/04/07 11:28:17 newdeal Exp $         */
/*							   	     */
/*********************************************************************/

/**************************************************************************\
  HSIPORT - Header file for inporting dependence.
\**************************************************************************/
 
/* This file contain porting dependent defines. */
/* Enable one of the following for desired platform */
/* #define DOSVERSION */
/* #define WINVERSION */
 
/* #define applec         MPW C predefined symbol */



#define	GEOSVERSION


#ifdef GEOSVERSION

#define	NOPROFILER  	    /* window stuff we don't need */

#include <geos.h>
#define INTEL       1
#define PASCAL	_pascal
#define MAXREAD        8192
#define STRIPSIZE      4096

       typedef dword	    	    	*FARPROC;

       typedef int                      BOOL;
       typedef int                      SHORT;
       typedef long                     LONG;
       typedef unsigned char            BYTE;
       typedef unsigned int             WORD;
       typedef unsigned long            DWORD;
/* There cannot be near pointers in the memory model we are
   using... BAD BAD things will happen( as putting them in a NULL segment)
       typedef char  _near               *PSTR;
       typedef char  _near               *NPSTR;
*/
      
       typedef char  _far                *LPSTR;
       typedef LPSTR                      PSTR;
       typedef LPSTR                      NPSTR;

       typedef BYTE  _far               *PBYTE;
       typedef BYTE  _far                *LPBYTE;
       typedef int   _far               *PINT;
       typedef int   _far                *LPINT;
       typedef SHORT _far               *PSHORT;
       typedef SHORT _far                *LPSHORT;
       typedef WORD  _far               *PWORD;
       typedef WORD  _far                *LPWORD;
       typedef long  _far               *PLONG;
       typedef long  _far                *LPLONG;
       typedef DWORD _far               *PDWORD;
       typedef DWORD _far                *LPDWORD;
       typedef void  _far                *LPVOID;
       typedef void                     *PVOID; 



#endif

#ifdef WINVERSION
       #define INCMALLOC   1           /* include malloc.h */
       #define OWNRAWIO    1
       #define INTEL       1
       typedef int                      BOOL;
       typedef int                      SHORT;
       typedef long                     LONG;
       typedef unsigned char            BYTE;
       typedef unsigned int             WORD;
       typedef unsigned long DWORD;
       typedef char  near               *PSTR;
       typedef char  near               *NPSTR;
       typedef char  far                *LPSTR;
       typedef BYTE  near               *PBYTE;
       typedef BYTE  far                *LPBYTE;
       typedef int   near               *PINT;
       typedef int   far                *LPINT;
       typedef SHORT near               *PSHORT;
       typedef SHORT far                *LPSHORT;
       typedef WORD  near               *PWORD;
       typedef WORD  far                *LPWORD;
       typedef long  near               *PLONG;
       typedef long  far                *LPLONG;
       typedef DWORD near               *PDWORD;
       typedef DWORD far                *LPDWORD;
       typedef void  far                *LPVOID;
       typedef void                     *PVOID; 
#endif
 
#ifdef SUN
#define UNIXV            1
#define MOTOROLA         1
#define FLATMEMORY       1
#define near
#define far
#define NONEARFAR        1
#define INCMALLOC        1             /* include malloc.h */
#define DOSMEMMGR        1       
#define pascal
#ifdef dummy
#include <osfcn.h>               /* required for C++ compiler */
#include <sysent.h>             /* for raw I/O  */
#endif
/* define the data types used for SUN SPARC station running OS 4.1 */
typedef int                     BOOL;
typedef int                     LONG;
typedef short                   SHORT;
typedef unsigned char           BYTE;
typedef unsigned short          WORD;
typedef unsigned int            DWORD;
typedef char  *PSTR;
typedef char  *NPSTR;
typedef char  *LPSTR;
typedef BYTE  *PBYTE;
typedef BYTE  *LPBYTE;
typedef short   *PINT;
typedef short   *LPINT;
typedef SHORT *PSHORT;
typedef SHORT *LPSHORT;
typedef WORD  *PWORD;
typedef WORD  *LPWORD;
typedef int  *PLONG;
typedef int  *LPLONG;
typedef DWORD *PDWORD;
typedef DWORD *LPDWORD;
typedef void  *LPVOID;
typedef void  *PVOID;

#endif

 
#ifdef DOSVERSION
       #define INCMALLOC   1             /* include malloc.h */
       #define DOSMEMMGR   1
       #define OWNRAWIO    1
       #define INTEL       1
       typedef int                      BOOL;
       typedef int                      SHORT;
       typedef long                     LONG;
       typedef unsigned char            BYTE;
       typedef unsigned int             WORD;
       typedef unsigned long            DWORD;
       typedef char  near               *PSTR;
       typedef char  near               *NPSTR;
       typedef char  far                *LPSTR;
       typedef BYTE  near               *PBYTE;
       typedef BYTE  far                *LPBYTE;
       typedef int   near               *PINT;
       typedef int   far                *LPINT;
       typedef SHORT near               *PSHORT;
       typedef SHORT far                *LPSHORT;
       typedef WORD  near               *PWORD;
       typedef WORD  far                *LPWORD;
       typedef long  near               *PLONG;
       typedef long  far                *LPLONG;
       typedef DWORD near               *PDWORD;
       typedef DWORD far                *LPDWORD;
       typedef void  far                *LPVOID;
       typedef void                     *PVOID; 
#endif

#ifdef MACVERSION
       #define MOTOROLA            1         /* Global Memory Flags */
       #define GMEM_FIXED          0x0000
       #define GMEM_MOVEABLE       0x0002
       #define GMEM_NOCOMPACT      0x0010
       #define GMEM_NODISCARD      0x0020
       #define GMEM_ZEROINIT       0x0040
       #define GMEM_MODIFY         0x0080
       #define GMEM_DISCARDABLE    0x0100
       #define GMEM_NOT_BANKED     0x1000
       #define GMEM_SHARE          0x2000
       #define GMEM_DDESHARE       0x2000
       #define GMEM_NOTIFY         0x4000
       #define GMEM_LOWER          GMEM_NOT_BANKED
 
       #define GHND                (GMEM_MOVEABLE | GMEM_ZEROINIT)
       #define GPTR                (GMEM_FIXED | GMEM_ZEROINIT)
       #define FLATMEMORY          1 
       #define DOSMEMMGR           1
       #include <unix.h>           /* raw IO */
    
       #define near
       #define far
       
       typedef int                      BOOL;
       typedef int                      SHORT;
       typedef long                     LONG;
       typedef unsigned char            BYTE;
       typedef unsigned int             WORD;
typedef unsigned long DWORD;
       typedef char  near               *PSTR;
       typedef char  near               *NPSTR;
       typedef char  far                *LPSTR;
       typedef BYTE  near               *PBYTE;
       typedef BYTE  far                *LPBYTE;
       typedef int   near               *PINT;
       typedef int   far                *LPINT;
       typedef SHORT near               *PSHORT;
       typedef SHORT far                *LPSHORT;
       typedef WORD  near               *PWORD;
       typedef WORD  far                *LPWORD;
       typedef long  near               *PLONG;
       typedef long  far                *LPLONG;
       typedef DWORD near               *PDWORD;
       typedef DWORD far                *LPDWORD;
       typedef void  far                *LPVOID;
       typedef void                     *PVOID; 
#endif

#ifdef OS2
       #define FLAGMEMORY     1
       #define INTEL          1
       #define far
       #define near
       typedef int                      BOOL;
       typedef int                      SHORT;
       typedef long                     LONG;
       typedef unsigned char            BYTE;
       typedef unsigned int             WORD;
       typedef unsigned long            DWORD;
       typedef char  near               *PSTR;
       typedef char  near               *NPSTR;
       typedef char  far                *LPSTR;
       typedef BYTE  near               *PBYTE;
       typedef BYTE  far                *LPBYTE;
       typedef int   near               *PINT;
       typedef int   far                *LPINT;
       typedef SHORT near               *PSHORT;
       typedef SHORT far                *LPSHORT;
       typedef WORD  near               *PWORD;
       typedef WORD  far                *LPWORD;
       typedef long  near               *PLONG;
       typedef long  far                *LPLONG;
       typedef DWORD near               *PDWORD;
       typedef DWORD far                *LPDWORD;
       typedef void  far                *LPVOID;
       typedef void                     *PVOID; 
#endif
 
#if INCMALLOC
#include <malloc.h>
#endif

#ifndef GEOSVERSION

typedef const char _far *         LPCSTR;
#define DECLARE_HANDLE(name)    typedef UINT name
#define DECLARE_HANDLE32(name)  typedef DWORD name

DECLARE_HANDLE(HINSTANCE);
typedef HINSTANCE HMODULE;  /* HMODULEs can be used in place of HINSTANCEs */
#define EXPORT          FAR PASCAL
#define WINAPI             _far pascal
#define CALLBACK            _far pascal
#endif
 







