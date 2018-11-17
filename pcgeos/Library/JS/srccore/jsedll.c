/* jseDLL.c     Main routines for any jse.DLL
 */

/* (c) COPYRIGHT 1993-98           NOMBAS, INC.
 *                                 64 SALEM ST.
 *                                 MEDFORD, MA 02155  USA
 *
 * ALL RIGHTS RESERVED
 *
 * This software is the property of Nombas, Inc. and is furnished under
 * license by Nombas, Inc.; this software may be used only in accordance
 * with the terms of said license.  This copyright notice may not be removed,
 * modified or obliterated without the prior written permission of Nombas, Inc.
 *
 * This software is a Trade Secret of Nombas, Inc.
 *
 * This software may not be copied, transmitted, provided to or otherwise made
 * available to any other person, company, corporation or other entity except
 * as specified in the terms of said license.
 *
 * No right, title, ownership or other interest in the software is hereby
 * granted or transferred.
 *
 * The information contained herein is subject to change without notice and
 * should not be construed as a commitment by Nombas, Inc.
 */

#include "srccore.h"

#if defined(__JSE_DLLLOAD__) || defined(__JSE_DLLRUN__)

#if defined(__JSE_WIN16__)
#if defined(__cplusplus)
extern "C" {
#endif /* __cplusplus */
   int FAR PASCAL LibMain(HINSTANCE hInstance,WORD ,WORD ,LPSTR );
   int __export FAR PASCAL WEP(int );
#if defined(__cplusplus)
}
#endif /* __cplusplus */

   int FAR PASCAL
LibMain(HINSTANCE unused1,WORD unused2,WORD unused3,LPSTR unused4)
{
   InitializejseEngine();
   return 1;
}

   int __export FAR PASCAL
WEP(int unused)
{
   TerminatejseEngine();
   return 1;         /* success */
}

#endif /* __JSE_WIN16__ */


#if defined(__JSE_DOS16__)
#include <windows.h>
extern "C" {
   int FAR PASCAL LibMain(HINSTANCE , WORD , WORD wHeapSize, LPSTR );
   int __export FAR PASCAL WEP(int );
}

   int FAR PASCAL
LibMain(HINSTANCE , WORD , WORD wHeapSize, LPSTR )
{
   /* 16-bit apps unlock data segment if it has been declared as MOVEABLE */
   if (wHeapSize != 0)
      UnlockData(0) ;
   /* nonzero return inidicates success... */
   InitializejseEngine();
   return 1;
}

/***************************** DLL exit code ******************************/

/* called once when this DLL is about to be unloaded */
   int __export FAR PASCAL
WEP(int )
{
   TerminatejseEngine();
   return(1) ;
}

#endif /* __JSE_DOS16__ */



#if defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__)

#if defined(__cplusplus)
extern "C" {
#endif /* __cplusplus */
  int __dll_initialize(void);
  int __dll_terminate(void);
#if defined(__cplusplus)
}
#endif /* __cplusplus */

#if defined(__BORLANDC__)
   ULONG cdecl
_dllmain(ULONG termflag,HMODULE)*/
unsigned long _System _DLL_InitTerm(unsigned long , unsigned long termflag)
{
   if ( !termflag ) {
      /* initializing */
      InitializejseEngine();
   }

   /* terminating */
   TerminatejseEngine();
   return 1;   /* success */
}
#elif defined(__IBMCPP__)
#error IBMCPP Not done yet
#else
int __dll_initialize(void)
{
   /* initializing */
   InitializejseEngine();
   return 1;
}

int __dll_terminate(void)
{
   /* terminating */
   TerminatejseEngine();
   return 1;   /* success */
}
#endif /* __BORLANDC__ */
#endif /* __JSE_OS2TEXT__ || __JSE_OS2PM__ */

#if defined(__JSE_WIN32__)
/* NEVER EVER Change the name of this function! - JMC */
BOOL WINAPI DllMain(HANDLE hinstDLL, ULONG fdwReason, LPVOID lpvReserved)
{
   switch (fdwReason) {
      case DLL_PROCESS_ATTACH:
         /* The DLL is being mapped into the process's address space. */
         /* case DLL_THREAD_ATTACH: */
         /* A thread is being created. */
         InitializejseEngine();
         break;

         /* case DLL_THREAD_DETACH: */
         /* A thread is exiting cleanly. */
      case DLL_PROCESS_DETACH:
         /* The DLL is being unmapped from the process's address
            space. */
         TerminatejseEngine();
         break;
   }
   return(TRUE);
}
#endif /* __JSE_WIN32__ */

#if defined(__JSE_GEOS__)
#include <library.h>

#ifdef GEOS_MAPPED_MALLOC
extern JSECALLSEQ_CFUNC(void) mappedInit(void);
extern JSECALLSEQ_CFUNC(void) mappedExit(void);
#endif

extern void initializeMemExt(void);
extern void terminateMemExt(void);

#pragma argsused
Boolean _pascal _export JSEntry(LibraryCallType ty, GeodeHandle client)
{
    if (ty == LCT_ATTACH)
    {
#ifdef GEOS_MAPPED_MALLOC
	mappedInit();
#endif
#if (JSE_MEMEXT_SECODES!=0) \
 || (JSE_MEMEXT_STRINGS!=0) \
 || (JSE_MEMEXT_OBJECTS!=0) \
 || (JSE_MEMEXT_MEMBERS!=0)
	initializeMemExt();
#endif
        FloatInit(FP_DEFAULT_STACK_ELEMENTS, FLOAT_STACK_GROW);
        InitializejseEngine();
        FloatExit();
    }
    else if (ty == LCT_DETACH) {
        TerminatejseEngine();
#if (JSE_MEMEXT_SECODES!=0) \
 || (JSE_MEMEXT_STRINGS!=0) \
 || (JSE_MEMEXT_OBJECTS!=0) \
 || (JSE_MEMEXT_MEMBERS!=0)
	terminateMemExt();
#endif
#ifdef GEOS_MAPPED_MALLOC
	mappedExit();
#endif
    }

    return FALSE;
}
#endif

#endif /* __JSE_DLLLOAD__ || __JSE_DLLRUN__ */
