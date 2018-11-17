/* sedyna.h - Dynamic link code
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

#if !defined(_SEDYNA_H) && \
    (defined(JSE_SELIB_DYNAMICLINK) || defined(JSE_OS2_PMDYNAMICLINK))
#define _SEDYNA_H
#ifdef __cplusplus
   extern "C" {
#endif

/* Flags */
#define PMCall      (1L << 0)       /* 0000000000000001  This is OS2 PM call                    */
#define CDecl       (1L << 1)       /* 0000000000000010  C declaration                          */
#define StdDecl     (1L << 2)       /* 0000000000000100  Standard declaration                   */
#define PascalDecl  (1L << 3)       /* 0000000000001000  Pascal declaration                     */
#define BitSize16   (1L << 4)       /* 0000000000010000  For OS2, the stack is 16bit values     */
#define BitSize32   (1L << 5)       /* 0000000000100000  For OS2, the stack is 32bit values     */

#if defined(__JSE_UNIX__) || defined(__JSE_NWNLM__)
#  if defined(__hpux__)
#     define DYNA_MODULE shl_t
#  else
#     define DYNA_MODULE void *
#  endif
#  define DYNA_SYMBOL void *
#elif defined(__JSE_MAC__)
#  define DYNA_MODULE CFragConnectionID
#  define DYNA_SYMBOL Ptr
#elif defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__)
#  define DYNA_MODULE HMODULE
#  define DYNA_SYMBOL PFN
#elif defined(__JSE_WIN32__) || defined(__JSE_CON32__) || defined(__JSE_WIN16__)
#  define DYNA_MODULE HMODULE
#  define DYNA_SYMBOL FARPROC
#else
#  error Dont know dynamic library types for this OS
#endif

#if defined(__JSE_UNIX__)
#  define DYNA_MIN_PARAM  2
#  define DYNA_MAX_PARAM  22
#elif defined(__JSE_NWNLM__)
#  define DYNA_MIN_PARAM  1
#  define DYNA_MAX_PARAM  21
#elif defined(__JSE_MAC__)
#  define DYNA_MIN_PARAM  2
#  define DYNA_MAX_PARAM  14
#elif defined(__JSE_WIN32__) || defined(__JSE_CON32__)
#  define DYNA_MIN_PARAM  2
#  define DYNA_MAX_PARAM  -1
#elif defined(__JSE_WIN16__) || defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__)
#  define DYNA_MIN_PARAM  3
#  define DYNA_MAX_PARAM  -1
#else
#  error Dont know minimum and maximum parameter counts for DynamicLink
#endif

#if defined(JSE_OS2_PMDYNAMICLINK)
struct PMDynamicLibrary {
   jseContext pConstructorContext;
   jsebool CEnvi2PMIsRunning;
   struct PMGate *SharedData;
   HEV ServiceResponse;
   HEV ServiceRequest;
   HWND CEnvi2PMhwnd;
   PID CEnvi2PMProcessID;
   TID CEnvi2PMThreadID;
   ULONG CEnvi2PMSessionID;
   HSWITCH CEnvi2PMSwitchHandle;
   HAB CEnvi2PMhab;
};

jsebool pmdynamiclibraryInitializeCEnvi2PM(struct PMDynamicLibrary *This,jseContext jsecontext);
void pmdynamiclibraryCommunicateWithCEnvi2PM(struct PMDynamicLibrary *This,jseContext jsecontext,
                                             enum pmgateMessageType_ msgType);
void pmdynamiclibraryUnloadCEnvi2PM(struct PMDynamicLibrary *This,jseContext jsecontext);
slong pmdynamiclibraryOS2DLL32PMCall(struct PMDynamicLibrary *This,jseContext jsecontext,PFN function,
                                     jsebool PushLeftFirst/*else push right first*/,
                                     jsebool PopParameters/*else callee pops parameters*/,
                                     uint ParameterCount,sword32 *Parameters);
slong pmdynamiclibraryOS2DLL16PMCall(struct PMDynamicLibrary *This,jseContext jsecontext,
                                     PVOID16 function,uword16 PushLeftFirst/*else push right first*/,
                                     uword16 PopParameters/*else callee pops parameters*/,
                                     uword16 ParameterCount,uword16 *Parameters);
void * pmdynamiclibraryAllocCEnvi2PM(struct PMDynamicLibrary *This,jseContext jsecontext,
                                     const void *data,uint len);
void pmdynamiclibraryFreeCEnvi2PM(struct PMDynamicLibrary *This,jseContext jsecontext,
                                  void *SharedMem,void *data,uint len);
#endif

struct open_module {
   struct open_module * prev;
   jsecharptr name;
   DYNA_MODULE module;
   ulong flags;
};

struct DynamicLibrary
{
#if defined(JSE_OS2_PMDYNAMICLINK)
   struct PMDynamicLibrary *PMdll;
#endif

  struct open_module * OpenModules;
};

struct DynamicLibrary * dynamiclibraryNew(jseContext InitialContext);
void dynamiclibraryDelete(struct DynamicLibrary *This);
/* None of these functions should contain OS-specific calls */
void dynamiclibraryUnloadModules( struct DynamicLibrary *This );
jsebool dynamiclibraryGetSymbol(struct DynamicLibrary *This,jseContext jsecontext,
                                const jsecharptr module_name,
                  const jsecharptr proc_name, ulong ordinal, DYNA_SYMBOL *sym,
                  ulong flags);


/* Data flags */
#define DataType16  (1L << 1)  /*  Data to be put on the stack is 16 bits */
#define DataType32  (1L << 2)  /*  Data to be put on the stack is 32 bits */

#if defined(__JSE_UNIX__) || defined(__JSE_NWNLM__)
#  define DYNA_STACK ulong *
#elif defined(__JSE_MAC__)
#  define DYNA_STACK uint *
#elif defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__) || defined(__JSE_WIN16__)
#  define DYNA_STACK uword16 *
#elif defined(__JSE_WIN32__) || defined(__JSE_CON32__)
#  define DYNA_STACK sword32 *
#else
#  error Dont know Dynamic stack type for this OS
#endif

struct DynamicCall {
   uint         add_offset;
   uint         get_offset;

   DYNA_SYMBOL  symbol;
   ulong        flags;
   DYNA_STACK   stack;

#  ifndef NDEBUG
      uint max_param;
#  endif
};

struct DynamicCall * dynamiccallNew( DYNA_SYMBOL _symbol, uint max_parameters, ulong _flags );
void dynamiccallDelete(struct DynamicCall *This);
void dynamiccallAdd( struct DynamicCall *This, void * data, ulong data_flags );
void * dynamiccallGet( struct DynamicCall *This, ulong data_flags );
slong dynamiccallCall( struct DynamicCall *This, jseContext jsecontext );


#define DYNAMIC_LIBRARY_NAME   UNISTR("DynamicLibrary")
#define CONTEXT_DYNAMIC_LIBRARY ((struct DynamicLibrary *)(jseGetSharedData(jsecontext,DYNAMIC_LIBRARY_NAME)))

/***** These are the only functions the user should call *****/
void DynamicLink(jseContext jsecontext, ulong flags );

jsebool LoadLibrary_DynamicLink(jseContext jsecontext);

#ifdef __cplusplus
}
#endif
#endif /* !defined(_SEDYNA_H) && (defined(JSE_SELIB_DYNAMICLINK) || defined(JSE_OS2_PMDYNAMICLINK)) */
