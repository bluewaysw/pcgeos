/* AtExit.c  Track exit functions
 */

/* (c) COPYRIGHT 1993-2000         NOMBAS, INC.
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

struct AtExit * atexitNew(struct AtExit *pParent)
{
   struct AtExit *this = jseMalloc(struct AtExit,sizeof(struct AtExit));

   if( this != NULL )
   {
      this->Parent = pParent;
      this->RecentExitFunction = NULL;
   }

   return this;
}


void atexitDelete(struct AtExit *this)
{
   while ( NULL != this->RecentExitFunction )
   {
      struct ExitFunction *Prev = this->RecentExitFunction->Prev;
      jseMustFree(this->RecentExitFunction);
      this->RecentExitFunction = Prev;
   } /* endwhile */
   jseMustFree(this);
}

void atexitCallFunctions(struct AtExit *this,struct Call *call)
{
   struct ExitFunction *ef;
   for( ef = this->RecentExitFunction; NULL != ef; ef = ef->Prev )
   {
#if defined(__JSE_GEOS__)
      ((pcfm_jseAtExitFunc *)ProcCallFixedOrMovable_pascal)
		    (call, ef->Parameter, ef->AtExitFunction);
#else
      (*(ef->AtExitFunction))(call,ef->Parameter);
#endif
   } /* endfor */
}

   static jsebool NEAR_CALL
atexitAdd(struct AtExit *this,jseAtExitFunc AtExitFunction,void _FAR_ *Parameter)
{
   struct ExitFunction *ef = jseMalloc(struct ExitFunction,
                                           sizeof(struct ExitFunction));

   if( ef != NULL )
   {
      ef->AtExitFunction = AtExitFunction;
      ef->Parameter = Parameter;
      ef->Prev = this->RecentExitFunction;
      this->RecentExitFunction = ef;
   }

   return ef != NULL;
}

   JSECALLSEQ( jsebool )
jseCallAtExit(jseContext jsecontext,jseAtExitFunc ExitFunc,void _FAR_ *Param)
{
   JSE_API_STRING(ThisFuncName,"jseCallAtExit");

   JSE_API_ASSERT_C(jsecontext,1,jseContext_cookie,ThisFuncName,return False);
   JSE_API_ASSERT_(ExitFunc,2,ThisFuncName,return False);

   return atexitAdd((jsecontext)->AtExitFunctions,ExitFunc,Param);
}
