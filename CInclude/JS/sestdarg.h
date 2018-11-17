/* sestdarg.h
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

#if !defined(__JSE_STDARG_H)
#  define  __JSE_STDARG_H
#  if defined(JSE_CLIB_VA_ARG)    || \
      defined(JSE_CLIB_VA_START)  || \
      defined(JSE_CLIB_VA_END)    || \
      defined(JSE_CLIB_PRINTF)    || \
      defined(JSE_CLIB_FPRINTF)   || \
      defined(JSE_CLIB_VPRINTF)   || \
      defined(JSE_CLIB_SPRINTF)   || \
      defined(JSE_CLIB_VSPRINTF)  || \
      defined(JSE_CLIB_RVSPRINTF) || \
      defined(JSE_CLIB_SYSTEM)    || \
      defined(JSE_CLIB_FSCANF)    || \
      defined(JSE_CLIB_VFSCANF)   || \
      defined(JSE_CLIB_SCANF)     || \
      defined(JSE_CLIB_VSCANF)    || \
      defined(JSE_CLIB_SSCANF)    || \
      defined(JSE_CLIB_VSSCANF)

#  ifdef __cplusplus
extern "C" {
#  endif

#  if defined(__JSE_DOS16__) || defined(__JSE_WIN16__)
#    define VLIST_CHUNK_SIZE   2 /* args put on valist is a multiple of this size */
#    define VLIST_PAD_AT_END     /* define this or define to VLIST_PAD_AT_START */
#    define VLIST_DIRECTION   +1 /* which direction does next vlist item go */
#  elif defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__) \
     || defined(__JSE_DOS32__) \
     || defined(__JSE_WIN32__) || defined(__JSE_CON32__) \
     || defined(__JSE_NWNLM__)
#    define VLIST_CHUNK_SIZE   4 /* args put on valist is a multiple of this size */
#    define VLIST_PAD_AT_END     /* define this or define to VLIST_PAD_AT_START */
#    define VLIST_DIRECTION   +1 /* which direction does next vlist item go */
#  elif defined(__hpux__)
#    define VLIST_CHUNK_SIZE   4 /* args put on valist is a multiple of this size */
#    define VLIST_PAD_AT_START   /* define this or define to VLIST_PAD_AT_START */
#    define VLIST_DIRECTION   -1 /* which direction does next vlist item go */
#  elif defined(__osf__)
#    define VLIST_CHUNK_SIZE   8 /* args put on valist is a multiple of this size */
#    define VLIST_PAD_AT_START   /* define this or define to VLIST_PAD_AT_START */
#    define VLIST_DIRECTION   +1 /* which direction does next vlist item go */
#  elif defined(__JSE_UNIX__) && (SE_BIG_ENDIAN==False)
#    define VLIST_CHUNK_SIZE   4 /* args put on valist is a multiple of this size */
#    define VLIST_PAD_AT_END     /* define this or define to VLIST_PAD_AT_START */
#    define VLIST_DIRECTION   +1 /* which direction does next vlist item go */
#  elif defined(__JSE_UNIX__) && (SE_BIG_ENDIAN==True)
#    define VLIST_CHUNK_SIZE   4 /* args put on valist is a multiple of this size */
#    define VLIST_PAD_AT_START   /* define this or define to VLIST_PAD_AT_END */
#    ifdef __sun__
#    define VLIST_DIRECTION    1 /* which direction does next vlist item go */
#    else
#    define VLIST_DIRECTION   +1 /* which direction does next vlist item go */
#    endif
#  elif defined(__JSE_MAC__)
#    define VLIST_CHUNK_SIZE   4 /* args put on valist is a multiple of this size */
#    define VLIST_PAD_AT_START   /* define this or define to VLIST_PAD_AT_END */
#    define VLIST_DIRECTION   +1 /* which direction does next vlist item go */
#  elif defined(__JSE_390__)
#    define VLIST_CHUNK_SIZE   4 /* args put on valist is a multiple of this size */
#    define VLIST_PAD_AT_START   /* define this or define to VLIST_PAD_AT_END */
#    define VLIST_DIRECTION   +1 /* which direction does next vlist item go */
#  else
#    error MUST DEFINE valist parameters for this OS-COMPILER
#  endif

#  ifndef VLIST_CHUNK_SIZE
#    error must define VLIST_CHUNK_SIZE
#  endif
#  if !defined(VLIST_PAD_AT_END)  &&  !defined(VLIST_PAD_AT_START)
#    error must define VLIST_PAD_AT_END or VLIST_PAD_AT_START
#  endif
#  if defined(VLIST_PAD_AT_END)  &&  defined(VLIST_PAD_AT_START)
#    error must define VLIST_PAD_AT_END or VLIST_PAD_AT_START, but not both
#  endif

   enum variableargsArgAction { variableargsArgPut, variableargsArgGet };
   /* put arg puts in va_list from var in Arg(), Get takes from va_list in ~VariableArgs */

   enum variableargsArgCType { variableargsCByte, variableargsCInt, variableargsCLong,
#                       if (0!=JSE_FLOATING_POINT)
                         variableargsCDouble,
#                       endif
                         variableargsCString, variableargsCByteArray };
   /* this is the type in va_list.  The jse type must be determined from var. */

   struct jse_List_ {
      struct jse_List_ *next;
      jseVariable  var; /* var that maps to this element of the C_List */
      enum variableargsArgAction Action;
      enum variableargsArgCType  CType;
      uint width;
      union {
         jsechar c;
         int   i;
         long  l;
#        if (0!=JSE_FLOATING_POINT)
         double d;
#        endif
         void *p;
      } data;
   };

   struct VariableArgs {
      struct {
         va_list VaList;  /* the list that has been built */
         uint VaListSize; /* number of bytes used in VaList */
      } C_List;

      uint ArgCount;
      struct jse_List_ *jse_List_Start;
   };

   void NEAR_CALL variableargsInit(struct VariableArgs *This);
   void NEAR_CALL variableargsTerm(struct VariableArgs *This);
   void NEAR_CALL variableargsArg(struct VariableArgs *This,jseContext jsecontext,jseVariable var,
                                  enum variableargsArgAction Action,
                                  enum variableargsArgCType CType,uint width);
   /* add new arg to the end of the va_list.  width is only necessary
    * on CString and CByteArray for ArgGet
    */
   void NEAR_CALL variableargsRetrieve(struct VariableArgs *This,jseContext jsecontext,sint RetrieveCount);
   /* retrieve values, but only from the first ArgCount on valist */


   struct VariableArgList
   {
      jseVariable Arguments;    /* the arguments object for the given va_list
                                 * function call
                                 */
      uint index;               /* arg 0, 1, whatever */
      uint num;                 /* number of arguments */
   };


   jseVariable NEAR_CALL variablearglistVar(struct VariableArgList *This,jseContext jsecontext,
                                            uint InputVarOffset,jseVarNeeded need);
   /* return var from stack, starting at Next(init=0) and going up.
    * If there was an error then return NULL and error has already been
    * printed and context error flag already set
    */
   struct VariableArgList * NEAR_CALL variablearglistGetArgList(jseContext jsecontext,
      jseVariable ArgListVar,
      jsebool PrintErrorIfNotFound);
  /* return pointer to this ArgList, else NULL if not found */

#  ifdef __cplusplus
}
#  endif
#endif /* all those defines */
#endif


