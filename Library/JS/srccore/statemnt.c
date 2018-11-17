/* Statemnt.c   Compile statements to secodes
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
#if (0!=JSE_COMPILER)

/* ---------------------------------------------------------------------- */
/* Statement compilers. They mirror the stuff in the old 'statement.cpp'  */
/* as much as possible.                                                   */
/* ---------------------------------------------------------------------- */

   static jsebool NEAR_CALL
secompileIf(struct secompile *this)
{
   ADDR_TYPE falseptr,elseptr;

   assert( tokType(this->token)==seTokIf );
   secompileAdvancePtr(this);
   if( tokType(this->token)!='(' )
   {
      callQuit(this->call,textcoreBAD_IF);
      return False;
   }
   secompileAdvancePtr(this);

   if( !secompileExpression(this) ) return False;
   secompileGetValue(this);
   assert( this->expr.type==EXPR_STACKTOP );

   if( tokType(this->token)!=')' )
   {
      callQuit(this->call,textcoreBAD_IF);
      return False;
   }
   falseptr = secompileCurrentItem(this);
   secompileAddItem(this,seGotoFalse,(ADDR_TYPE)0);
   secompileAdvancePtr(this);
   if( !secompileStatement(this) ) return False;

   elseptr = secompileCurrentItem(this);
   if( tokType(this->token)==seTokElse )
   {
      secompileAddItem(this,seGoto,(ADDR_TYPE)0);
   }
   secompileGotoHere(this,falseptr);
   if( tokType(this->token)==seTokElse )
   {
      secompileAdvancePtr(this);
      if( !secompileStatement(this) ) return False;
      secompileGotoHere(this,elseptr);
   }
   return True;
}


   static jsebool NEAR_CALL
secompileWhile(struct secompile *this,struct gotoItem *label)
{
   ADDR_TYPE top_of_loop,ptr;

   assert( tokType(this->token)==seTokWhile );
   top_of_loop = secompileCurrentItem(this);
   secompileAdvancePtr(this);

   if( !secompileNewLoop(this,label) ) return False;

   if( tokType(this->token)!='(' )
   {
      callQuit(this->call,textcoreBAD_WHILE);
      return False;
   }

   secompileAdvancePtr(this);
   if( !secompileExpression(this) ) return False;
   secompileGetValue(this);
   assert( this->expr.type==EXPR_STACKTOP );

   if( tokType(this->token)!=')' )
   {
      callQuit(this->call,textcoreBAD_WHILE);
      return False;
   }
   secompileAdvancePtr(this);
   ptr = secompileCurrentItem(this);
   secompileAddItem(this,seGotoFalse,(ADDR_TYPE)0);

   if( !secompileStatement(this) ) return False;
   secompileAddItem(this,seGoto,top_of_loop);
   secompileGotoHere(this,ptr);

   secompileEndLoop(this,secompileCurrentItem(this),top_of_loop,label);
   return True;
}


   static jsebool NEAR_CALL
secompileDo(struct secompile *this,struct gotoItem *label)
{
   ADDR_TYPE top_of_loop;

   assert( tokType(this->token)==seTokDo );

   top_of_loop = secompileCurrentItem(this);

   secompileAdvancePtr(this);

   if( !secompileNewLoop(this,label) ) return False;

   if( !secompileStatement(this) ) return False;
   if( tokType(this->token)!=seTokWhile )
   {
      callQuit(this->call,textcoreBAD_DO);
      return False;
   }
   secompileAdvancePtr(this);
   if( tokType(this->token)!='(' )
   {
      callQuit(this->call,textcoreBAD_DO);
      return False;
   }
   secompileAdvancePtr(this);

   secompileAddItem(this,seContinueFunc,this->prevLineNumber);
   if( !secompileExpression(this) ) return False;
   secompileGetValue(this);
   assert( this->expr.type==EXPR_STACKTOP );

   if( tokType(this->token)!=')' )
   {
      callQuit(this->call,textcoreBAD_DO);
      return False;
   }
   secompileAdvancePtr(this);

   secompileAddItem(this,seGotoTrue,top_of_loop);

   /* eat statement terminator if present */
   if( tokType(this->token)==';' ) secompileAdvancePtr(this);

   secompileEndLoop(this,secompileCurrentItem(this),top_of_loop,label);
   return True;
}


   static jsebool NEAR_CALL
secompileVar(struct secompile *this)
{
   assert( tokType(this->token)==seTokVar );

   do {
      secompileAdvancePtr(this);
      if( tokType(this->token)!=seTokIdentifier )
      {
         callQuit(this->call,textcoreVAR_NEEDS_VARNAME);
         return False;
      }

      /* don't add if already a parameter name */
      if( LOCAL_TEST_IF_INIT_FUNCTION(this->locfunc,this->call) ||
          loclFindParam(this->locfunc,tokGetName(this->token))==-1 )
      {
         loclAddLocal(this->call,this->locfunc,tokGetName(this->token));
      }

      /* initialize to call expression parser */
      SE_NEW_EXPR(this);
      /* assignment statements can't have commas in them */
      if( !secompileOperatorExpression(this,PRI_ASSIGN,False) ) return False;

      /* we don't do anything with the value */
      secompileDiscard(this);
   } while( tokType(this->token)==',' );

   /* eat statement terminator if present */
   if( tokType(this->token)==';' ) secompileAdvancePtr(this);
   return True;
}


   static jsebool NEAR_CALL
secompileFor(struct secompile *this,struct gotoItem *label)
{
   jsebool has_init = False;
   VarName index = NULL;

   assert( tokType(this->token)==seTokFor );

   secompileAdvancePtr(this);

   if( !secompileNewLoop(this,label) ) return False;

   if( tokType(this->token)!='(' )
   {
      callQuit(this->call,textcoreBAD_FOR_STATEMENT);
      return False;
   }
   secompileAdvancePtr(this);
   if( tokType(this->token)==seTokVar )
   {
      struct tok tok;

      tokLookAhead(this,&tok);
      /* if it is not really a variable, this will be bad, but then
       * the var statement will fail anyway, so we are ok.
       */
      index = tokGetName(&tok);
      /* initialization is really For statment. */
      if( !secompileVar(this) ) return False;
   }
   else
   {
      /* possible to have no initialization */
      if( tokType(this->token)!=';' )
      {
         /* initialization is just some expression */
         SE_NEW_EXPR(this);
         if( !secompileExpressionNoIn(this) ) return False;
         has_init = True;
      }
      if( tokType(this->token)!=';' &&
          tokType(this->token)!=seTokIn )
      {
         callQuit(this->call,textcoreBAD_FOR_STATEMENT);
         return False;
      }
      if( tokType(this->token)==';' ) secompileAdvancePtr(this);
   }

   /* Do the for..in part */

   if( tokType(this->token)==seTokIn )
   {
      ADDR_TYPE top;
      struct seExpression save;

      if( index!=NULL )
      {
         if( !LOCAL_TEST_IF_INIT_FUNCTION(this->locfunc,this->call) &&
             (this->expr.index = loclFindLocal(this->locfunc,index))!=-1 )
         {
            this->expr.index++;
            this->expr.type = EXPR_LOCAL;
         }
         else if( !LOCAL_TEST_IF_INIT_FUNCTION(this->locfunc,this->call) &&
                  (this->expr.index = loclFindParam(this->locfunc,index))!=-1 )
         {
            this->expr.index = (sword16)(-this->expr.index);
            this->expr.type = EXPR_LOCAL;
         }
         else
         {
            this->expr.name = index;
            this->expr.type = EXPR_GLOBAL;
         }
      }
      save = this->expr;
      if( this->expr.type==EXPR_MEMBER || this->expr.type==EXPR_ARRAY )
      {
         callQuit(this->call,textcoreBAD_FOR_IN_STATEMENT);
         return False;
      }

      if( !has_init && index==NULL )
      {
         callQuit(this->call,textcoreBAD_FOR_IN_STATEMENT);
         return False;
      }
      secompileAdvancePtr(this);
      SE_NEW_EXPR(this);
      if( !secompileExpression(this) ) return False;

      secompileGetValue(this);

      if( tokType(this->token)!=')' )
      {
         callQuit(this->call,textcoreBAD_FOR_IN_STATEMENT);
         return False;
      }
      secompileAdvancePtr(this);

      secompileAddItem(this,seToObject);
      secompileAddItem(this,sePushNull);

      top = secompileCurrentItem(this);
      secompileAddItem(this,seGotoForIn,(ADDR_TYPE)0);
      this->expr = save;
      secompilePutValue(this);
      secompileDiscard(this);

      if( !secompileStatement(this) ) return False;

      secompileAddItem(this,seGoto,top);

      secompileFixupGotoItem(this,top,secompileCurrentItem(this));
      secompileEndLoop(this,secompileCurrentItem(this),top,label);
      secompileAddItem(this,sePopDiscard);
      secompileAddItem(this,sePopDiscard);
   }
   else
   {
      ADDR_TYPE out_of_loop = 0;
      jsebool patch_out_of_loop = False;
      ADDR_TYPE test;
      ADDR_TYPE go_into_loop,increment;


      /* do the regular for loop part */
      if( has_init ) secompileDiscard(this);

      test = secompileCurrentItem(this);

      /* choice made here to have the test portion be the only place
       * that mayIContinue is called.  It seems the natural place
       * for a compiler to stop.
       */
      secompileAddItem(this,seContinueFunc,this->prevLineNumber);

      if( tokType(this->token)!=';' )
      {
         /* this is the test */
         if( !secompileExpression(this) ) return False;
         secompileGetValue(this);

         patch_out_of_loop = True;
         out_of_loop = secompileCurrentItem(this);
         secompileAddItem(this,seGotoFalse,(ADDR_TYPE)0);
         this->expr.type = EXPR_VOID;
         if( tokType(this->token)!=';' )
         {
            callQuit(this->call,textcoreBAD_FOR_STATEMENT);
            return False;
         }
      }
      else
      {
         /* no test */
      }

      go_into_loop = secompileCurrentItem(this);
      secompileAddItem(this,seGoto,(ADDR_TYPE)0);

      increment = secompileCurrentItem(this);
      secompileAdvancePtr(this);
      if( tokType(this->token)!=')' )
      {
         /* the increment */
         if( !secompileExpression(this) ) return False;
         /* the increment is only used for side effects */
         secompileDiscard(this);
      }
      secompileAddItem(this,seGoto,test);

      if( tokType(this->token)!=')' )
      {
         callQuit(this->call,textcoreBAD_FOR_STATEMENT);
         return False;
      }

      secompileGotoHere(this,go_into_loop);
      secompileAdvancePtr(this);
      if( !secompileStatement(this) ) return False;
      /* we go back up and do the test and increment */
      secompileAddItem(this,seGoto,increment);

      if( patch_out_of_loop ) secompileGotoHere(this,out_of_loop);

      secompileEndLoop(this,secompileCurrentItem(this),increment,label);
   }

   return True;
}


/*
 * Whenever any case matches, we clean up the test from the stack.
 * Bigger code, but its another thing I don't have to keep track
 * of in the interpret() loop. It would be easy if the switch always
 * fully executed, in which case we could just do the pop once,
 * but there can be a return in it.
 */
   static jsebool NEAR_CALL
secompileSwitch(struct secompile *this,struct gotoItem *label)
{
   ADDR_TYPE def_ptr;
   ADDR_TYPE goto_ptr2 = (ADDR_TYPE)-1;
   ADDR_TYPE goto_ptr;

   assert( tokType(this->token)==seTokSwitch );
   secompileAdvancePtr(this);

   if( tokType(this->token)!='(' )
   {
      callQuit(this->call,textcoreBAD_SWITCH);
      return False;
   }
   secompileAdvancePtr(this);

   if( !secompileExpression(this) ) return False;
   secompileGetValue(this);

   if( tokType(this->token)!=')' )
   {
      callQuit(this->call,textcoreBAD_WHILE);
      return False;
   }
   secompileAdvancePtr(this);

   if( tokType(this->token)!='{' )
   {
      callQuit(this->call,textcoreSWITCH_NEEDS_BRACE);
      return False;
   }
   secompileAdvancePtr(this);

   def_ptr = (ADDR_TYPE)-1;
   /* goto ptr is the last test for a case if false, so it must always chain
    * to the next test
    */

   if( !secompileNewLoop(this,label) ) return False;

   /* set up to jump to the first comparison */
   goto_ptr = secompileCurrentItem(this);
   secompileAddItem(this,seGoto,(ADDR_TYPE)0);

   while( tokType(this->token)!='}' )
   {
      if( tokType(this->token)==seTokDefault )
      {
         secompileAdvancePtr(this);
         if( tokType(this->token)!=':' )
         {
            callQuit(this->call,textcoreCONDITIONAL_MISSING_COLON);
            return False;
         }
         secompileAdvancePtr(this);
         if( def_ptr!=(ADDR_TYPE)-1 )
         {
            callQuit(this->call,textcoreDUPLICATE_DEFAULT);
            return False;
         }
         def_ptr = (ADDR_TYPE) secompileCurrentItem(this);
         continue;
      }

      /* each case is an if test. We jump over this test first, so any
       * fallthru will act correctly. If the test succeeds we pop the value
       * from the stack so any executing code doesn't have to try to
       * remember that it is there
       */
      if( tokType(this->token)==seTokCase )
      {
         secompileAdvancePtr(this);
         if( goto_ptr!=(ADDR_TYPE)-1 )
         {
            /* if we are already executing the code for a successful comparison
             * jump over this test into the code for the next case (the
             * fallthru.) Otherwise this is the first test, so make it.
             */
            goto_ptr2 = (ADDR_TYPE) secompileCurrentItem(this);
            secompileAddItem(this,seGoto,(ADDR_TYPE)0);
            secompileGotoHere(this,(uint)goto_ptr);
         }
         else
         {
            goto_ptr2 = (ADDR_TYPE)-1;
         }
         secompileAddItem(this,sePushDup);
         if( !secompileExpression(this) ) return False;
         secompileGetValue(this);
         if( tokType(this->token)!=':' )
         {
            callQuit(this->call,textcoreCONDITIONAL_MISSING_COLON);
            return False;
         }
         secompileAdvancePtr(this);
         secompileAddItem(this,seStrictEqual);
         goto_ptr = (ADDR_TYPE) secompileCurrentItem(this);
         secompileAddItem(this,seGotoFalse,(ADDR_TYPE)0);
         /* this is it, get rid of the item being tested on the stack */
         secompileAddItem(this,sePopDiscard);
         if( goto_ptr2!=(ADDR_TYPE)-1 ) secompileGotoHere(this,(uint)goto_ptr2);
         continue;
      }

      /* else this is a statement in the switch */
      if( goto_ptr==(ADDR_TYPE)-1 )
      {
         callQuit(this->call,textcoreSWITCH_NEEDS_CASE);
         return False;
      }

      if( !secompileStatement(this) ) return False;
   }

   assert( tokType(this->token)=='}' );
   secompileAdvancePtr(this);

   if( goto_ptr!=(ADDR_TYPE)-1 )
   {
      goto_ptr2 = (ADDR_TYPE)secompileCurrentItem(this);
      secompileAddItem(this,seGoto,(ADDR_TYPE)0);
      secompileGotoHere(this,(uint)goto_ptr);
   }

   /* we are at the end of the switch, get rid of the still remaining
    * comparison item, then goto the default if any.
    */
   secompileAddItem(this,sePopDiscard);
   if( def_ptr!=(ADDR_TYPE)-1 ) secompileAddItem(this,seGoto,def_ptr);

   secompileGotoHere(this,(uint)goto_ptr2);

   /* break and continue on switch mean the same thing - just get out */
   secompileEndLoop(this,secompileCurrentItem(this),
                    secompileCurrentItem(this),label);

   return True;
}


/* With now acts very much like try - it has a fake 'finally'
 * part which is where it removes the extra item from the
 * scope chain.
 *
 * This has code cut-and-pasted from Try.
 */
   static jsebool NEAR_CALL
secompileWith(struct secompile *this)
{
   ADDR_TYPE one,two,three,out;


   assert( tokType(this->token)==seTokWith );
   secompileAdvancePtr(this);

   one = (ADDR_TYPE) secompileCurrentItem(this);
   secompileAddItem(this,seStartTry,(ADDR_TYPE)0);
   two = (ADDR_TYPE) secompileCurrentItem(this);
   secompileAddItem(this,seCatchTry,two); /* points to itself, no handler yet */
   three = (ADDR_TYPE) secompileCurrentItem(this);
   secompileAddItem(this,seFinallyTry,(ADDR_TYPE)0);

   if( tokType(this->token)!='(' )
   {
      callQuit(this->call,textcoreBAD_WITH_STATEMENT);
      return False;
   }

   secompileAdvancePtr(this);
   if( !secompileExpression(this) ) return False;
   secompileGetValue(this);

   if( tokType(this->token)!=')' )
   {
      callQuit(this->call,textcoreBAD_WITH_STATEMENT);
      return False;
   }
   secompileAdvancePtr(this);
   secompileAddItem(this,seScopeAdd);
   this->with_depth++;

   if( !secompileStatement(this) ) return False;

   /* After block successfully completes, go to the finally section via
    * a transfer out of the block. If we 'goto' the finally section directly,
    * the section won't be flagged so if it then returns or such, it will
    * call itself again rather than actually returning.
    */
   out = (ADDR_TYPE)secompileCurrentItem(this);
   secompileAddItem(this,seTransfer,(ADDR_TYPE)0);

   /* Always go to the finally section. */
   secompileGotoHere(this,(uint)three);

   /* All done, make sure our finally does its cleanup */
   secompileAddItem(this,seScopeRemove);
   secompileAddItem(this,seEndTry);
   secompileGotoHere(this,(uint)one);
   secompileGotoHere(this,(uint)out);

   this->with_depth--;
   return True;
}


/* ECMA2.0: See secode.c for information on how this works. */
   static jsebool NEAR_CALL
secompileTry(struct secompile *this)
{
   ADDR_TYPE one,two,three,out;
   jsebool catchfound = False;


   assert( tokType(this->token)==seTokTry );
   secompileAdvancePtr(this);

   one = (ADDR_TYPE) secompileCurrentItem(this);
   secompileAddItem(this,seStartTry,(ADDR_TYPE)0);
   two = (ADDR_TYPE) secompileCurrentItem(this);
   secompileAddItem(this,seCatchTry,two); /* points to itself, no handler yet */
   three = (ADDR_TYPE) secompileCurrentItem(this);
   secompileAddItem(this,seFinallyTry,(ADDR_TYPE)0);

   /* Try must in fact be a block */
   if( tokType(this->token)!='{' )
   {
      callQuit(this->call,textcoreTRY_NEEDS_BLOCK);
      return False;
   }
   if( !secompileStatement(this) ) return False;

   /* After block successfully completes, go to the finally section via
    * a transfer out of the block. If we 'goto' the finally section directly,
    * the section won't be flagged so if it then returns or such, it will
    * call itself again rather than actually returning.
    */
   out = (ADDR_TYPE)secompileCurrentItem(this);
   secompileAddItem(this,seTransfer,(ADDR_TYPE)0);


   if( tokType(this->token)==seTokCatch )
   {
      /* Point to first catch handler */

      secompileGotoHere(this,(uint)two);

      /* Catch clause is the format:
       *   code
       *   transferAlways <out of block>
       */

      /* ECMA2.0: can only have a single catch clause */
      if( tokType(this->token)==seTokCatch )
      {
         /* fixup last item if any */
         assert( !catchfound );
         catchfound = True;

         secompileAdvancePtr(this);
         if( tokType(this->token)!='(' )
         {
            callQuit(this->call,textcoreTRY_CATCH_PARAM);
            return False;
         }

         secompileAdvancePtr(this);
         if( tokType(this->token)!=seTokIdentifier )
         {
            callQuit(this->call,textcoreTRY_CATCH_PARAM);
            return False;
         }
         secompileAddItem(this,seStartCatch,tokGetName(this->token));
         this->with_depth++;

         secompileAdvancePtr(this);
         if( tokType(this->token)!=')' )
         {
            callQuit(this->call,textcoreTRY_CATCH_PARAM);
            return False;
         }

         secompileAdvancePtr(this);
         /* Try catch clauses must in fact be blocks */
         if( tokType(this->token)!='{' )
         {
            callQuit(this->call,textcoreTRY_NEEDS_BLOCK);
            return False;
         }
         if( !secompileStatement(this) ) return False;

         this->with_depth--;
         secompileAddItem(this,seEndCatch);
         /* it is a bit inefficient to goto a transfer, but this way we
          * don't need to save a list of all locations and then patch
          * them all.
          */
         secompileAddItem(this,seGoto,out);
      }
      if( tokType(this->token)==seTokCatch )
      {
         callQuit(this->call,textcoreTRY_CATCH_TWICE);
         return False;
      }
   }

   /* Always go to the finally section. */
   secompileGotoHere(this,(uint)three);

   /* First any user code */
   if( tokType(this->token)==seTokFinally )
   {
      secompileAdvancePtr(this);

      /* Try finally clause must in fact be a block */
      if( tokType(this->token)!='{' )
      {
         callQuit(this->call,textcoreTRY_NEEDS_BLOCK);
         return False;
      }
      if( !secompileStatement(this) ) return False;
   }
   else if( !catchfound )
   {
      callQuit(this->call,textcoreTRY_NEEDS_SOMETHING);
      return False;
   }

   /* All done, make sure our finally does its cleanup */
   secompileAddItem(this,seEndTry);
   secompileGotoHere(this,one);
   secompileGotoHere(this,out);

   return True;
}


jsebool NEAR_CALL secompileStatement(struct secompile *this)
{
   jsebool success = True;
   struct gotoItem *label = this->looplabel;

   this->looplabel = NULL;


   if( tokType(this->token)==seTokFilename ||
       tokType(this->token)==seTokLineNumber )
      secompileAdvancePtr(this);

   /* we check to see if we should continue at the beginning of each
    * statement. For those people working on the debugger, if you think
    * the debugger should pause at any particular time, put a mayIContinue
    * at that time. The only place I can think of might be parts of
    * a for() loop, but I don't think it should. We don't add it at the
    * beginning of a block, since the first statement in the block is where
    * it should stop - the begin block is just a grouping thing.
    *
    * I've restored ';', because otherwise an empty loop has no
    * test in it. For instance, 'while( 1 ) {}' will not respond to
    * ctrl-c.
    */
   if( tokType(this->token)!='{' && /* tokType(this->token)!=';' && */
       tokType(this->token)!=seTokFunction && tokType(this->token)!=seTokCFunction )
   {
      /* The one token lookahead causes the linenumber to appear too early.
       * this fixes the problem
       */
      secompileAddItem(this,seContinueFunc,this->prevLineNumber);
   }

   switch( tokType(this->token) )
   {
      /* ECMA2.0 */
      case seTokFunction: case seTokCFunction:
         success = secompileFunction(this,False);
         break;

      /* ECMA2.0 */
      case seTokThrow:
      {
         struct tok tok;

         tokLookAhead(this,&tok);
         /* handle 'no line terminator here' in the production */
         if( tokType(&tok)==seTokEOL )
         {
	    /* newline not allowed -- nombas/brianc 10/17/00 */
	    callQuit(this->call,textcoreTHROW_NO_NEWLINE);
	    success = False;
	    break;
         }
         else
         {
            secompileAdvancePtr(this);
            if( !secompileExpression(this) )
            {
               success = False;
               break;
            }
            secompileGetValue(this);
            /* the error condition will cause an immediate error */
            secompileAddItem(this,seReturnThrow);
            /* eat statement terminator if present */
            if( tokType(this->token)==';' ) secompileAdvancePtr(this);
         }
         break;
      }

      case seTokReturn:
      {
         struct tok tok;

         tokLookAhead(this,&tok);
         /* handle 'no line terminator here' in the production */
	 /* also check for ending '}' -- nombas/brianc 10/17/00 */
         if( tokType(&tok)==seTokEOL || tokType(&tok)=='}')
         {
            /* auto semicolon insertion */
            secompileAdvancePtr(this);
            secompileAddItem(this,sePushUndefined);
            secompileAddItem(this,seReturn);
         }
         else
         {
            secompileAdvancePtr(this);
            if( tokType(this->token)!=';' )
            {
               if( !secompileExpression(this) )
               {
                  success = False;
                  break;
               }
               secompileGetValue(this);
            }
            else
            {
               secompileAddItem(this,sePushUndefined);
            }
            secompileAddItem(this,seReturn);

            /* eat statement terminator if present */
            if( tokType(this->token)==';' ) secompileAdvancePtr(this);
         }
         break;
      }

      case '{':
         /* to parse this, we simply have any number of statements followed
          * by an EndBlock
          */
         secompileAdvancePtr(this);
         if( tokType(this->token)=='}' )
         {
            /* need a break or an empty statement can end up with no
             * continue which really bombs in a loop.
             */
            secompileAddItem(this,seContinueFunc,this->prevLineNumber);
         }
         else
         {
            while( tokType(this->token)!='}' )
            {
               if( !secompileStatement(this) )
               {
                  success = False;
                  break;
               }
            }
         }
         if( success )
         {
            assert( tokType(this->token)=='}' );
            /* eat the '}' */
            secompileAdvancePtr(this);
         }
         break;

      /* several statement types just have us calling further routines to ease
       * readability and modularize
       */
      case seTokIf:
         success = secompileIf(this);
         break;
      case seTokWhile:
         success = secompileWhile(this,label);
         break;
      case seTokDo:
         success = secompileDo(this,label);
         break;
      case seTokWith:
         success = secompileWith(this);
         break;
      case seTokVar:
         success = secompileVar(this);
         break;
      case seTokFor:
         success = secompileFor(this,label);
         break;
      case seTokSwitch:
         success = secompileSwitch(this,label);
         break;
      case seTokTry:
         success = secompileTry(this);
         break;

      case seTokBreak: case seTokContinue:
      {
         /* Either can have a variable parameter. If so, that must be an
          * existing label, and that label must have a loop associated with
          * it.
          */
         struct loopTracker *it = NULL;
         jsebool isbreak = tokType(this->token)==seTokBreak;


         secompileAdvancePtr(this);
         /* handle 'no line terminator here' in the production */
         if( tokType(this->token)==seTokIdentifier &&
             tokType(SECOMPILE_PREV_TOKEN(this))!=seTokEOL )
         {
            uint x;
            VarName name = tokGetName(this->token);

            for( x=0;x<this->gotoTrack->labelsUsed;x++ )
            {
               if( this->gotoTrack->labels[x].label==name )
                  break;
            }

            /* This used to be >, but that is wrong */
            if( x==this->gotoTrack->labelsUsed )
            {
               callQuit(this->call,textcoreGOTO_LABEL_NOT_FOUND,name);
               success = False;
               break;
            }
            else
            {
               it = this->gotoTrack->labels[x].loop;
               if( it==NULL )
               {
                  callQuit(this->call,textcoreNOT_LOOP_LABEL);
                  success = False;
                  break;
               }
            }
            secompileAdvancePtr(this);
         }


         if( isbreak )
            success = secompileAddBreak(this,it);
         else
            success = secompileAddContinue(this,it);
         if( success )
         {
            /* eat statement terminator if present */
            if( tokType(this->token)==';' ) secompileAdvancePtr(this);
         }
         break;
      }

      case seTokGoto:
         secompileAdvancePtr(this);
         if( tokType(this->token)!=seTokIdentifier )
         {
            callQuit(this->call,textcoreGOTO_LABEL_NOT_FOUND);
            success = False;
            break;
         }

         assert( tokGetName(this->token)!=NULL );
         if( !secompileAddGoto(this,tokGetName(this->token)) )
         {
            success = False;
            break;
         }
         secompileAdvancePtr(this);
         /* eat statement terminator if present */
         if( tokType(this->token)==';' ) secompileAdvancePtr(this);
         break;

      case ';':
         secompileAdvancePtr(this);
         break;

      default:
      {
         struct tok tok;

         /* If it is '/' or '/=', then it will end up being a
          * regular expression. The look-ahead interferes with
          * its parsing (both are hacks on top of a basic
          * one-token look ahead.) Rather than rewrite each hack
          * to know about each other, it is much easier just to
          * make sure they don't interfere. Currently, an assert
          * will trigger if they do.
          */
         if( tokType(this->token)!='/' &&
             tokType(this->token)!=seTokDivEqual )
         {
            tokLookAhead(this,&tok);
            /* It is either an expression or a label */
            if( tokType(this->token)==seTokIdentifier &&
                tokType(&tok)==':' )
            {
               assert( tokGetName(this->token)!=NULL );
               success = secompileAddLabel(this,tokGetName(this->token));

               this->looplabel = this->gotoTrack->labels+(this->gotoTrack->labelsUsed-1);

               if( success )
               {
                  secompileAdvancePtr(this);
                  secompileAdvancePtr(this);
               }
               break;
            }
         }

         SE_NEW_EXPR(this);
         success = secompileExpression(this);
         /* eat statement terminator if present */
         if( tokType(this->token)==';' ) secompileAdvancePtr(this);
         secompileDiscard(this);

         break;
      }
   }

   return success;
}

#endif
