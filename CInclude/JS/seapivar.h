/* srccore/seapivar.h
 *
 * The API's variable defines (jseVariables)
 */

/* (c) COPYRIGHT 2000              NOMBAS, INC.
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

#ifndef _SRCCORE_SEAPIVAR_H
#define _SRCCORE_SEAPIVAR_H

#if defined(__cplusplus)
   extern "C" {
#endif

/* ----------------------------------------------------------------------
 * If 'value' is not a reference, then that is the real value of the
 * jseVariable. Else, 'last_access' is used for temp storage to
 * derefence the variable each time it is accessed or updated.
 * ---------------------------------------------------------------------- */

struct seAPIVar
{
   /* a doubly linked list for freeing easily. */
   struct seAPIVar *next,*prev;


   struct _SEVar value;

   struct _SEVar last_access;

   jsebool shouldBeFreed;
   jsebool alreadyFreed;

#  if !defined(NDEBUG) && JSE_TRACKVARS==1
   char *function;   /* function received from */
   char *file;       /* file allocated */
   uint line;         /* line allocated */

   JSE_POINTER_UINT checksum;
                     /* adds the values of the past fields to make sure it
                      * is a valid variable
                      */
#  endif

#  if JSE_MEMEXT_STRINGS==1
      void *data;
#  endif

#  if ( 0 < JSE_API_ASSERTLEVEL )
#  define APIVAR_COOKIE 0x73
   ubyte cookie;
#  endif
};
typedef struct seAPIVar *seAPIVar;


wSEVar seapiGetValue(struct Call *call,struct seAPIVar *var);
   void NEAR_CALL
seapiDeleteVariable(struct Call *call,struct seAPIVar *var);
   void
seapiCleanup(struct Call *call);

#if !defined(NDEBUG) && JSE_TRACKVARS==1
#  define SEAPI_RETURN(c,r,l,n) seapiCopyAndReturn(c,r,l,n,FILE,(uint)LINE)
#else
#  define SEAPI_RETURN(c,r,l,n) seapiCopyAndReturn(c,r,l)
#endif

   seAPIVar
seapiCopyAndReturn(struct Call *call,rSEVar realvar,
                   jsebool api_lock
#                  if !defined(NDEBUG) && JSE_TRACKVARS==1
                   ,jsecharptr apiname,char *file,uint line
#                  endif
                   );

#if defined(__cplusplus)
   }
#endif

#endif
