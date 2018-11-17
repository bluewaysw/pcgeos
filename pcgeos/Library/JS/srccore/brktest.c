/* brktest.c   Check if code can break at a given line.
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

#if defined(JSE_BREAKPOINT_TEST) && (0!=JSE_BREAKPOINT_TEST)

#define BREAKPOINT_TOO_DEEP   8 /* if deeper than this probably in recursion */

   jsebool
callBreakpointTest(struct Call *call,hSEObject hParentObject,
                   const jsecharptr WantedName,
                   uword32 LineNumber,uint depth)
{
   uint iii;
   jsebool ret = False;
   rSEMembers rsemembers;
   MemCountUInt used;

   {
      /* lock just the members */
      rSEObject rParentObject;
      SEOBJECT_ASSIGN_LOCK_R(rParentObject,hParentObject);
      used = SEOBJECT_PTR(rParentObject)->used;
      if (used == 0)
      {
	 SEOBJECT_UNLOCK_R(rParentObject);
	 return ret;
      }
      SEMEMBERS_ASSIGN_LOCK_R(rsemembers,SEOBJECT_PTR(rParentObject)->hsemembers);
      SEOBJECT_UNLOCK_R(rParentObject);
   }

   for( iii=0; iii < used; iii++ )
   {
      JSE_MEMEXT_R struct _SEObjectMem *f = SEMEMBERS_PTR(rsemembers) + iii;

      if ( VObject == SEVAR_GET_TYPE(&(f->value)) )
      {
         /* if this object is a local function, then test its lines */
         const struct Function *func = sevarGetFunction(call,&(f->value));
         if( NULL != func  &&  FUNCTION_IS_LOCAL(func) )
         {
            secode EndOpcodes, c;
            jsebool right_file = ( 0 == JSECHARPTR_GETC(WantedName) ) ? True : False ;
            secode base;

#           if JSE_MEMEXT_SECODES==1
               base = jsememextLockRead(((struct LocalFunction *)func)->op_handle,jseMemExtSecodeType);
#           else
               base = ((struct LocalFunction *)func)->opcodes;
#           endif

            EndOpcodes = base + ((struct LocalFunction *)func)->opcodesUsed;
            for( c = base; c != EndOpcodes; c++ )
            {
               if( seFilename == *c )
               {
                  right_file =
                     ( 0 == stricmp_jsechar(GetStringTableEntry(call,SECODE_GET_ONLY(c+1,VarName),
                                                                NULL),
                                            WantedName) );
               }
               else if ( (seContinueFunc==(*c) || seLineNumber==(*c) ) && right_file )
               {
                  /* if next mayIContinue or line number is this line then it is a breakpoint */
                  if ( SECODE_GET_ONLY(c+1,CONST_TYPE) == LineNumber )
                  {
                     /* file and line found; this is the TRUE exit point */
                     ret = True;
                     break;
                  }
               }
               c += SECODE_DATUM_SIZE(*c);
            }
#           if JSE_MEMEXT_SECODES==1
               jsememextUnlockRead(((struct LocalFunction *)func)->op_handle,base,jseMemExtSecodeType);
#           endif

            if( ret==True ) break;
         }

         /* this object was not the breakpoint; try subobjects (if not already too deep) */
         if ( depth < BREAKPOINT_TOO_DEEP )
         {
            assert( SEVAR_GET_TYPE(&(f->value))==VObject );
            if ( callBreakpointTest(call,SEVAR_GET_OBJECT(&(f->value)),
                                    WantedName,LineNumber,depth+1) )
            {
               ret = True;
               break;
           }
         }
      }
   }
   SEMEMBERS_UNLOCK_R(rsemembers);

   return ret;
}

#endif
