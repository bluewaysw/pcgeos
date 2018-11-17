/* jseengin.c   Initialize and terminate jse Engine
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

#if ((defined(JSE_MEM_DEBUG) && (0!=JSE_MEM_DEBUG))&& !defined(__JSE_LIB__)) || \
    (defined(JSE_ONE_STRING_TABLE) && (0!=JSE_ONE_STRING_TABLE))
   static VAR_DATA(sint) EngineThreadCount = 0;
#endif


#if ( 0 < JSE_API_ASSERTLEVEL )
#  if defined(JSE_MBCS) && (JSE_MBCS!=0)
#     define ENGINE_NOT_INITIALIZED "JSE Engine not initialized"
#  else
#     define ENGINE_NOT_INITIALIZED UNISTR("JSE Engine not initialized!")
#endif

static VAR_DATA(jsecharptrdatum) jseApiErrorString[256] = ENGINE_NOT_INITIALIZED;

  static void NEAR_CALL
ClearApiError(void)
{
   memset(jseApiErrorString, 0, sizeof(jseApiErrorString));
}

/* These API calls are for diagnostic purposes.  They need never take
 * a context - that would defeat the purpose that you can get at an
 * error to see that your context is invalid, Null etc.  The calls do
 * not protect the error buffer from being written to by multiple threads.
 */
  JSECALLSEQ( const jsecharptr )
jseGetLastApiError()
{
  return (jsecharptr) jseApiErrorString;
}

   void JSE_CFUNC
SetLastApiError(const jsecharptr formatS,...)
{
   va_list arglist;
   va_start(arglist,formatS);
   ClearApiError();
   jse_vsprintf(jseApiErrorString, formatS, arglist);
   va_end(arglist);
   assert( strlen_jsechar((jsecharptr)jseApiErrorString) < (sizeof(jseApiErrorString)/sizeof(jsecharptrdatum)) );
#  if !defined(NDEBUG) && defined(_DBGPRNTF_H)
      DebugPrintf(UNISTR("SetLastApiError: %s"),jseApiErrorString);
#  endif
}

#if ( 1 == JSE_API_ASSERTNAMES )
   void
ApiParameterError(const jsecharptr funcname,uint ParameterIndex)
{
   SetLastApiError(UNISTR("Parameter %d invalid to function: %s."),ParameterIndex,
                   funcname);
}
#else
   void
ApiParameterError(uint ParameterIndex)
{
   SetLastApiError("Parmeter %d invalid.",ParameterIndex);
}
#endif

  JSECALLSEQ( void )
jseClearApiError(void)
{
  ClearApiError();
}
#endif /*# if ( 0 < JSE_API_ASSERTLEVEL ) */

#  if (0!=JSE_FLOATING_POINT)
   VAR_DATA(jsenumber) jseFPx10000;
   VAR_DATA(jsenumber) jseFPx100000000;
   VAR_DATA(jsenumber) jseFPx7fffffff;
#  endif

void InitializejseEngine(void)
{
#if defined(JSE_FP_EMULATOR) && (0!=JSE_FP_EMULATOR) && defined(__JSE_GEOS__) 
   initialize_FP_constants() ;
#endif
#  if (0!=JSE_FLOATING_POINT) \
   && defined(__JSE_UNIX__) \
   && (!defined(JSE_FP_EMULATOR) || (0==JSE_FP_EMULATOR))
      /* initialize the special_math global for UNIX */
#     if SE_BIG_ENDIAN==True
         static CONST_DATA(uword32) orig_jse_special_math[8] = {
           0x80000000L, 0x00000000L, /* -0 */
           0x7FF00000L, 0x00000000L, /* infinity */
           0xFFF00000L, 0x00000000L, /* -infinity */
           0x7FF80000L, 0x00000000L  /* NaN */
         };
#     else
         static CONST_DATA(uword32) orig_jse_special_math[8] = {
           0x00000000L, 0x80000000L, /* -0 */
           0x00000000L, 0x7FF00000L, /* infinity */
           0x00000000L, 0xFFF00000L, /* -infinity */
           0x00000000L, 0x7FF80000L  /* NaN */
         };
#     endif /* SE_BIG_ENDIAN==True */
      int x;
      for( x=0;x<4;x++ )
      {
         jsenumber *it = jse_special_math+x;
         uword32 *it2 = (uword32 *)it;
         *(it2++) = orig_jse_special_math[x*2];
         *(it2) = orig_jse_special_math[x*2+1];
      }
#  endif

#  if (0!=JSE_FLOATING_POINT)
      /* initialize wrap-around values used for compilation */
      jseFPx10000 = JSE_FP_CAST_FROM_SLONG(0x10000);
      jseFPx100000000 = JSE_FP_MUL(jseFPx10000,jseFPx10000);
      jseFPx7fffffff = JSE_FP_CAST_FROM_SLONG(0x7fffffff);
#  endif

#  if defined(JSE_ONE_STRING_TABLE) && (0!=JSE_ONE_STRING_TABLE)
      if ( 0 == EngineThreadCount )
      {
         if( !allocateGlobalStringTable() )
            jseInsufficientMemory();
      }
#  endif

#  if (defined(JSE_MEM_DEBUG) && (0!=JSE_MEM_DEBUG)) && !defined(__JSE_LIB__)
      if ( 0 == EngineThreadCount )
      {
         jseInitializeMallocDebugging();
         assert( 0 == jseMemReport(False) );
            /* anal check for no allocations yet */
      }
#  endif

#  if ( (defined(JSE_MEM_DEBUG) && (0!=JSE_MEM_DEBUG))&& !defined(__JSE_LIB__)) \
      || (defined(JSE_ONE_STRING_TABLE) && (0!=JSE_ONE_STRING_TABLE) )
      EngineThreadCount++;
#  endif
}

void TerminatejseEngine()
{
#  if (defined(JSE_MEM_DEBUG) && (0!=JSE_MEM_DEBUG)) && !defined(__JSE_LIB__)
      if ( 1 == EngineThreadCount )
         jseTerminateMallocDebugging();
#  endif

#  if defined(JSE_ONE_STRING_TABLE) && (0!=JSE_ONE_STRING_TABLE)
      if ( 1 == EngineThreadCount )
         freeGlobalStringTable();
#  endif

#  if ( (defined(JSE_MEM_DEBUG) && (0!=JSE_MEM_DEBUG))&& !defined(__JSE_LIB__)) \
     || (defined(JSE_ONE_STRING_TABLE) && (0!=JSE_ONE_STRING_TABLE) )
      EngineThreadCount--;
      assert( EngineThreadCount >= 0 );
#  endif
}


JSECALLSEQ(uint) jseInitializeEngine()
{
#  if defined(__JSE_LIB__)
      InitializejseEngine();
#  endif
#  if ( 0 < JSE_API_ASSERTLEVEL )
      ClearApiError();
#  endif
#  if defined(__JSE_GEOS__)
   FloatInit(FP_DEFAULT_STACK_ELEMENTS, FLOAT_STACK_GROW);
#  endif
   return JSE_ENGINE_VERSION_ID;
}

   JSECALLSEQ(void)
jseTerminateEngine()
{
#  if defined(__JSE_GEOS__)
   FloatExit();
#  endif
#  if defined(__JSE_LIB__)
   TerminatejseEngine();
#  endif
}


   JSECALLSEQ(jseContext)
jseInitializeExternalLink(void _FAR_ *LinkData,
   struct jseExternalLinkParameters * LinkParms,
   const jsecharptr globalVarName,
   const char * AccessKey)
{
   struct Call * call;

   JSE_API_STRING(ThisFuncName,"jseInitializeExternalLink");

   JSE_API_ASSERT_(LinkParms,2,ThisFuncName,return NULL);
   JSE_API_ASSERT_(globalVarName,3,ThisFuncName,return NULL);
#  if ( 0 < JSE_API_ASSERTLEVEL )
      if ( NULL == LinkParms->PrintErrorFunc )
      {
         SetLastApiError(textcoreGet(NULL,textcorePRINTERROR_FUNC_REQUIRED));
         return NULL;
      }
#  endif

   call = callInitial(LinkData,LinkParms,globalVarName,(stringLengthType)strlen_jsechar(globalVarName));

   UNUSED_PARAMETER(AccessKey);
   
   return call;
}

   JSECALLSEQ( void _FAR_ * )
jseGetLinkData(jseContext jsecontext)
{
   JSE_API_ASSERT_C(jsecontext,1,jseContext_cookie,UNISTR("jseGetLinkData"),return NULL);
   return jsecontext->Global->GenericData;
}

   JSECALLSEQ(struct jseExternalLinkParameters *)
jseGetExternalLinkParameters(jseContext jsecontext)
{
   JSE_API_ASSERT_C(jsecontext,1,jseContext_cookie,UNISTR("jseGetLinkData"),return NULL);
   return &(jsecontext->Global->ExternalLinkParms);
}



/* ---------------------------------------------------------------------- */

/* Sharing of objects support:
 *
 */

/* There are two kinds of locks, a single object and
 * all shared objects. A context can only ever have
 * *one* at a time (one object, or all objects but no
 * single object.) This prevents any race conditions.
 * appropriate asserts are needed for debugging.
 *
 * Whenever the sweep bit of an object needs to be
 * used, all objects must be locked. Otherwise the
 * only non-obvious lock is that the get/create
 * object member routines all lock the object first,
 * you'll see code like:
 *
 *   seVar a = seobjGetMember(obj,name);
 *   ...
 *   SHARED_UNLOCK(obj);
 *
 * Because only one lock at a time is allowed (and
 * this also keeps the time objects are locked short),
 * you cannot call functions that are not 'quick'.
 * I.e. you can't call a dynamic property for instance.
 * Any place the code currently does this will need
 * to be changed to copy the object's 'value' field,
 * probably to a temp on the stack, free the object
 * lock, then call the function with the copied
 * data not the original object member.
 *
 * VReferenceIndex are not allowed on shared objects
 * because the indexes can be moved around by
 * another context, so the slower VReference has
 * to be substituted (which re-looks up the member
 * when it is being used.) If the member no longer
 * exists, it is recreated as undefined.
 *
 * For analness, the member creation/finding routines
 * will check all children of a shared object and
 * assert they too are shared.
 */

/* Each context keeps a list of objects it knows about
 * and a list of ones it knows about but is not using.
 * Each shared object has a context known count and
 * a context using count. When a context exits, it
 * decrements these counts appropriately. The idea
 * is simple. When a context collects, it first locks
 * all objects, then makes sure it knows about
 * all objects (i.e. any new shared objects are put on
 * its lists), then collects normally. If it
 * knows about an object that it is not using, it
 * moves it to the known but not using and decrements
 * the corresponding count in the object. A shared
 * object can be freed when 'jseContextCount' equals
 * the object's context known about count and the
 * object's context using count is zero. What this
 * means is that every context has agreed it is
 * no longer using the object. If, for instance, one
 * context adds a new shared object as a member
 * of an existing shared object, all contexts using
 * that object implicitly are using the new object
 * too. Until they see that they are and explicitly
 * say, "no, I'm no longer using it," the object
 * isn't free. Shared object garbage collecting
 * effectively garbage collects over the whole
 * system of contexts, just distributed in bits,
 * each context doing its own. The result is that
 * objects get freed more slowly (i.e. every
 * context has to collect before it will go away),
 * but the impact on performance is negligable
 * (no pauses to do system-wide garbage collection).
 */

#ifdef JSE_SHARED
/* Number of contexts we have currently allocated */
static volatile int jseContextCount;

static volatile struct seObject *sharedObjs;
#endif
