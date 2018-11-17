/* expressn.c
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

#if defined(__JSE_GEOS__)

/* Flag that script engine should callQuit as soon as possible due to 
   an out of memory condition. */
extern jsebool jseOutOfMemory;

#endif

   static void NEAR_CALL
secompileGetValueAsObject(struct secompile *this);
   static void NEAR_CALL
secompileGetValueKeep(struct secompile *this);
   static void NEAR_CALL
secompileGetValueForParam(struct secompile *this,CONST_TYPE arg_num);


#if (defined(JSE_PACK_SECODES) && (JSE_PACK_SECODES==1)) ||\
    defined(SECODE_LISTINGS) || !defined(NDEBUG)
/* Each secode instruction is in this table. It allows the
 * generic 'addItem' routine to figure out what extension
 * data the instruction has.
 *
 * Currently, an instruction can have 0, 1, or 2 pieces
 * of extension data. The table contains the actual size
 * of the data for each instruction. Size 0 indicates
 * that instruction does not use that extension data.
 * Note that if the size of extension 1 is 0, then
 * extension 2 is also 0.
 */
DEFINE_LARGE_STATIC_ARRAY('SC',t_secodeInstrInfo,secodeData,NUM_SECODES)
#if defined(JSE_INIT_STATIC_DATA) && 1==JSE_INIT_STATIC_DATA
   { SECODE_STR(NULL)                      0,                             0 }, /* reserved */

   { SECODE_STR("sePushLocalWith")         sizeof(VAR_INDEX_TYPE),        sizeof(WITH_TYPE) },
   { SECODE_STR("sePushLocalAsObject")     sizeof(VAR_INDEX_TYPE),        sizeof(WITH_TYPE) },
   { SECODE_STR("sePushLocalParam")        sizeof(VAR_INDEX_TYPE),        sizeof(WITH_TYPE) },
   { SECODE_STR("sePreIncLocal")           sizeof(VAR_INDEX_TYPE),        sizeof(WITH_TYPE) },
   { SECODE_STR("sePreDecLocal")           sizeof(VAR_INDEX_TYPE),        sizeof(WITH_TYPE) },
   { SECODE_STR("sePostIncLocal")          sizeof(VAR_INDEX_TYPE),        sizeof(WITH_TYPE) },
   { SECODE_STR("sePostDecLocal")          sizeof(VAR_INDEX_TYPE),        sizeof(WITH_TYPE) },
   { SECODE_STR("seIncOnlyLocal")          sizeof(VAR_INDEX_TYPE),        sizeof(WITH_TYPE) },
   { SECODE_STR("seDecOnlyLocal")          sizeof(VAR_INDEX_TYPE),        sizeof(WITH_TYPE) },
   { SECODE_STR("seAssignLocalWith")       sizeof(VAR_INDEX_TYPE),        sizeof(WITH_TYPE) },

   { SECODE_STR("seContinueFunc")          sizeof(CONST_TYPE),        0 },
   { SECODE_STR("seLineNumber")            sizeof(CONST_TYPE),        0 },
   { SECODE_STR("sePushConstant")          sizeof(CONST_TYPE),        0 },
   { SECODE_STR("seDereferParam")          sizeof(CONST_TYPE),        0 },
   { SECODE_STR("seNewFunction")           sizeof(CONST_TYPE),        0 },
   { SECODE_STR("seCallFunction")          sizeof(CONST_TYPE),        0 },

   { SECODE_STR("sePushLocal")             sizeof(VAR_INDEX_TYPE),        0 },
   { SECODE_STR("seAssignLocal")           sizeof(VAR_INDEX_TYPE),        0 },
   { SECODE_STR("seAssignLocalPop")        sizeof(VAR_INDEX_TYPE),        0 },

   { SECODE_STR("seStartTry")              sizeof(ADDR_TYPE),        0 },
   { SECODE_STR("seCatchTry")              sizeof(ADDR_TYPE),        0 },
   { SECODE_STR("seFinallyTry")            sizeof(ADDR_TYPE),        0 },
   { SECODE_STR("seGoto")                  sizeof(ADDR_TYPE),        0 },
   { SECODE_STR("seTransfer")              sizeof(ADDR_TYPE),        0 },
   { SECODE_STR("seGotoForIn")             sizeof(ADDR_TYPE),        0 },
   { SECODE_STR("seGotoFalse")             sizeof(ADDR_TYPE),        0 },
   { SECODE_STR("seGotoTrue")              sizeof(ADDR_TYPE),        0 },

   { SECODE_STR("seFilename")              sizeof(VarName),        0 },
   { SECODE_STR("sePushMember")            sizeof(VarName),        0 },
   { SECODE_STR("sePushMemberParam")       sizeof(VarName),        0 },
   { SECODE_STR("sePushMemberAsObject")    sizeof(VarName),        0 },
   { SECODE_STR("seDeleteMember")          sizeof(VarName),        0 },
   { SECODE_STR("seAssignMember")          sizeof(VarName),        0 },
   { SECODE_STR("sePreIncMember")          sizeof(VarName),        0 },
   { SECODE_STR("sePreDecMember")          sizeof(VarName),        0 },
   { SECODE_STR("sePostIncMember")         sizeof(VarName),        0 },
   { SECODE_STR("sePostDecMember")         sizeof(VarName),        0 },
   { SECODE_STR("seCheckGlobal")           sizeof(VarName),        0 },
   { SECODE_STR("sePushGlobal")            sizeof(VarName),        0 },
   { SECODE_STR("sePushGlobalAsObject")    sizeof(VarName),        0 },
   { SECODE_STR("sePushGlobalParam")       sizeof(VarName),        0 },
   { SECODE_STR("sePreIncGlobal")          sizeof(VarName),        0 },
   { SECODE_STR("sePreDecGlobal")          sizeof(VarName),        0 },
   { SECODE_STR("sePostIncGlobal")         sizeof(VarName),        0 },
   { SECODE_STR("sePostDecGlobal")         sizeof(VarName),        0 },
   { SECODE_STR("seAssignGlobal")          sizeof(VarName),        0 },
   { SECODE_STR("seTypeofGlobal")          sizeof(VarName),        0 },
   { SECODE_STR("seStartCatch")            sizeof(VarName),        0 },

   { SECODE_STR("sePopDiscard")            0,                      0 },
   { SECODE_STR("sePushUndefined")         0,                      0 },
   { SECODE_STR("sePushFalse")             0,                      0 },
   { SECODE_STR("sePushTrue")              0,                      0 },
   { SECODE_STR("sePushNull")              0,                      0 },
   { SECODE_STR("sePushThis")              0,                      0 },
   { SECODE_STR("sePushGlobalObject")      0,                      0 },
   { SECODE_STR("sePushNewObject")         0,                      0 },
   { SECODE_STR("sePushNewArray")          0,                      0 },
   { SECODE_STR("sePushArray")             0,                      0 },
   { SECODE_STR("sePushArrayParam")        0,                      0 },
   { SECODE_STR("sePushArrayAsObject")     0,                      0 },
   { SECODE_STR("seDeleteArray")           0,                      0 },
   { SECODE_STR("seAssignArray")           0,                      0 },
   { SECODE_STR("seTypeof")                0,                      0 },
   { SECODE_STR("sePreIncArray")           0,                      0 },
   { SECODE_STR("sePreDecArray")           0,                      0 },
   { SECODE_STR("sePostIncArray")          0,                      0 },
   { SECODE_STR("sePostDecArray")          0,                      0 },
   { SECODE_STR("sePushDup")               0,                      0 },
   { SECODE_STR("sePushDup2")              0,                      0 },
   { SECODE_STR("sePushDupUnder")          0,                      0 },
   { SECODE_STR("seSwap")                  0,                      0 },
   { SECODE_STR("seToNumber")              0,                      0 },
   { SECODE_STR("seToObject")              0,                      0 },
   { SECODE_STR("seToObjectUnder")         0,                      0 },
   { SECODE_STR("seToCallFunc")            0,                      0 },
   { SECODE_STR("seToNewFunc")             0,                      0 },
   { SECODE_STR("seScopeAdd")              0,                      0 },
   { SECODE_STR("seScopeRemove")           0,                      0 },
   { SECODE_STR("seEndTry")                0,                      0 },
   { SECODE_STR("seEndCatch")              0,                      0 },
   { SECODE_STR("seReturn")                0,                      0 },
   { SECODE_STR("seReturnThrow")           0,                      0 },
   { SECODE_STR("seNegate")                0,                      0 },
   { SECODE_STR("seBoolNot")               0,                      0 },
   { SECODE_STR("seBitNot")                0,                      0 },
   { SECODE_STR("seInstanceOf")            0,                      0 },
   { SECODE_STR("seIn")                    0,                      0 },
   { SECODE_STR("seEqual")                 0,                      0 },
   { SECODE_STR("seNotEqual")              0,                      0 },
   { SECODE_STR("seStrictEqual")           0,                      0 },
   { SECODE_STR("seStrictNotEqual")        0,                      0 },
   { SECODE_STR("seLess")                  0,                      0 },
   { SECODE_STR("seGreaterEqual")          0,                      0 },
   { SECODE_STR("seGreater")               0,                      0 },
   { SECODE_STR("seLessEqual")             0,                      0 },
   { SECODE_STR("seSubtract")              0,                      0 },
   { SECODE_STR("seAdd")                   0,                      0 },
   { SECODE_STR("seMultiply")              0,                      0 },
   { SECODE_STR("seDivide")                0,                      0 },
   { SECODE_STR("seModulo")                0,                      0 },
   { SECODE_STR("seShiftLeft")             0,                      0 },
   { SECODE_STR("seSignedShiftRight")      0,                      0 },
   { SECODE_STR("seUnsignedShiftRight")    0,                      0 },
   { SECODE_STR("seBitOr")                 0,                      0 },
   { SECODE_STR("seBitXor")                0,                      0 },
   { SECODE_STR("seBitAnd")                0,                      0 },
   { SECODE_STR("seThisAndValue")          0,                      0 },

};
#endif /* defined(JSE_INIT_STATIC_DATA) && 1==JSE_INIT_STATIC_DATA */

#endif


#if (0!=JSE_COMPILER) || ( defined(JSE_TOKENDST) && (0!=JSE_TOKENDST) )
/*
 * Add an secode item. This is really a virtual assembly instruction for this
 * simple 'ScriptEase' machine. Some of the codes have extra parameters which
 * are retrieved and stored.
 */
   void NEAR_CALL_CFUNC
secompileAddItem(struct secompile *This,int/*codeval*/ code,...)
{
   /* NOTE: we cannot blindly do optimizations like concatenating two
    *       adjacent line number ops because a goto may target the second
    *       one. A peephole optimizer does this work later. Please put
    *       nothing like that here, even if it would work. This routine
    *       ought to be simple and straightforward. Peephole is the
    *       place for eliminating small, bad code sequences.
    */

#  if (0!=JSE_COMPILER)
   /* if tokens have switched line numbers then now can signal that the line is complete. Line
    * numbers will later be found by searching for such a token.
    */
   if ( This->NowCompiling &&
        This->prevLineNumber != This->call->Global->CompileStatus.CompilingLineNumber )
      {
         if( seLineNumber!=code )
         {
            /* Prevent the stupid 'seLineNumber 0' at the start of
             * every function.
             */
            if( This->prevLineNumber!=0 )
            {
               secompileAddItem(This,seLineNumber,This->prevLineNumber);
            }
            This->prevLineNumber = This->call->Global->CompileStatus.CompilingLineNumber;
         }
      }
#     endif


   /* Opcodes can have 0, 1, or 2 extensions data. Make sure we have
    * space of the biggest possible one.
    */
   if( This->opcodesAlloced <= (This->opcodesUsed + SECODE_MAX_EXTRAS) )
   {
      This->opcodesAlloced += 100;
      This->opcodes = jseMustReMalloc(secodeelem,This->opcodes,
                                      (uint)(This->opcodesAlloced*sizeof(secodeelem)));
      assert( NULL != This->opcodes );
   }
   assert( This->opcodesUsed < This->opcodesAlloced );


   SECODE_PUT(This,secodeelem,(secodeelem)code);


   /* For all the below, strange casting is needed. This is because
    * some C compilers are broken. va_arg() is supposed to understand
    * promotions. I.e., if I use va_arg(,<type>), where <type> would
    * get automatically promoted on passing, then va_arg is supposed
    * to deal with that. Some don't.
    */
   if( code<SE_CONST_TYPE_EXT )
   {
      /* a 2-extension opcode, all are VAR_INDEX_TYPE, WITH_TYPE */
      va_list arg;
      va_start(arg,code);
      assert( sizeof(VAR_INDEX_TYPE)==secodeData[code].size0 );
      assert( sizeof(WITH_TYPE)==secodeData[code].size1 );

#      if defined(JSE_PACK_SECODES) && (JSE_PACK_SECODES==1)
         assert( sizeof(VAR_INDEX_TYPE)<=sizeof(int) );
         SECODE_PUT(This,VAR_INDEX_TYPE,(VAR_INDEX_TYPE)va_arg(arg,int));
         assert( sizeof(WITH_TYPE)<=sizeof(int) );
         SECODE_PUT(This,WITH_TYPE,(WITH_TYPE)va_arg(arg,int));
#      else
         SECODE_PUT(This,VAR_INDEX_TYPE,va_arg(arg,VAR_INDEX_TYPE));
         SECODE_PUT(This,VAR_INDEX_TYPE,va_arg(arg,WITH_TYPE));
#      endif
      va_end(arg);
   }
   else if( code<SE_VAR_INDEX_TYPE_EXT )
   {
      va_list arg;
      va_start(arg,code);

      assert( code>=SE_CONST_TYPE_EXT );
      assert( sizeof(CONST_TYPE)==secodeData[code].size0 );
#     if defined(JSE_PACK_SECODES) && (JSE_PACK_SECODES==1)
         assert( sizeof(CONST_TYPE)<=sizeof(int) );
         SECODE_PUT(This,CONST_TYPE,(CONST_TYPE)va_arg(arg,int));
#     else
         SECODE_PUT(This,CONST_TYPE,va_arg(arg,CONST_TYPE));
#     endif
      va_end(arg);
   }
   else if( code<SE_ADDR_TYPE_EXT )
   {
      va_list arg;
      va_start(arg,code);

      assert( code>=SE_VAR_INDEX_TYPE_EXT );
      assert( sizeof(VAR_INDEX_TYPE)==secodeData[code].size0 );
#     if defined(JSE_PACK_SECODES) && (JSE_PACK_SECODES==1)
         assert( sizeof(VAR_INDEX_TYPE)<=sizeof(int) );
         SECODE_PUT(This,VAR_INDEX_TYPE,(VAR_INDEX_TYPE)va_arg(arg,int));
#     else
         SECODE_PUT(This,VAR_INDEX_TYPE,va_arg(arg,VAR_INDEX_TYPE));
#     endif
      va_end(arg);
   }
   else if( code<SE_VARNAME_EXT )
   {
      va_list arg;
      va_start(arg,code);

      assert( code>=SE_ADDR_TYPE_EXT );
      assert( sizeof(ADDR_TYPE)==secodeData[code].size0 );
      assert( sizeof(ADDR_TYPE)>=sizeof(int) ); /* uword32 */
      SECODE_PUT(This,ADDR_TYPE,va_arg(arg,ADDR_TYPE));
      va_end(arg);
   }
   else if( code<SE_NO_EXT )
   {
      va_list arg;
      VarName name;

      va_start(arg,code);

      assert( code>=SE_VARNAME_EXT );
      assert( sizeof(VarName)==secodeData[code].size0 );
      name = va_arg(arg,VarName);
      SECODE_PUT(This,VarName,name);
      va_end(arg);
   }

#  if defined(__JSE_GEOS__)
   /* This is a fairly common place to be while compiling, so it makes
      a nice place to insert our test. */
   if (jseOutOfMemory)
   {
      jseOutOfMemory = FALSE;
      callQuit(This->call,textcoreOUT_OF_MEMORY);
   }
#  endif
}
#endif


#if (0!=JSE_COMPILER)

/* ---------------------------------------------------------------------- */
/* secode compiler routines                                               */
/* ---------------------------------------------------------------------- */


/*
 * Handle a card telling us what source file or line number we are on.
 * Updates our call so if an error happens we know what line number we
 * are on, and generates secodes so the same thing will happen at runtime.
 */
   static void NEAR_CALL
secompileFileInfoCard(struct secompile *this)
{
   if( tokType(this->token)==seTokFilename )
   {
      secompileAddItem(this,seFilename,tokGetName(this->token));
      /* compatibility with existing code */
      if ( 0 != this->call->Global->CompileStatus.NowCompiling )
      {
         this->call->Global->CompileStatus.CompilingFileName =
            GetStringTableEntry(this->call,tokGetName(this->token),NULL);
      }
   }
   else
   {
      assert( tokType(this->token)==seTokLineNumber );
      this->call->Global->CompileStatus.CompilingLineNumber = (uint)tokGetLine(this->token);
   }
   this->token = secompileNextToken(this);
}


/*
 * We handle any source file/line num stuff. We generate code to set those
 * at run time (for error reporting.) We also set them now for compile-time
 * errors. This means that error line number reporting is transparent to
 * the rest of the compiler.
 */
   struct tok * NEAR_CALL
secompileAdvancePtr(struct secompile *this)
{
   this->token = secompileNextToken(this);

   while( (this->token)!=NULL &&
          (tokType(this->token)==seTokFilename ||
           tokType(this->token)==seTokLineNumber ||
           tokType(this->token)==seTokEOL) )
   {
      if( tokType(this->token)==seTokEOL )
         this->token = secompileNextToken(this);
      else
         secompileFileInfoCard(this);
   }
   return this->token;
}

/* Backpatch a single goto since we now know what address it should
 * be going to.
 */
   void NEAR_CALL
secompileFixupGotoItem(struct secompile *This,ADDR_TYPE item,ADDR_TYPE newdest)
{
   while( This->opcodes[item]==seLineNumber )
   {
      item += SECODE_DATUM_SIZE(This->opcodes[item]);   /* skip line number parameter */
      item++;   /* skip opcode */
   }
   SECODE_PUT_ONLY(This->opcodes+item+1,ADDR_TYPE,newdest);
}


/* ----------------------------------------------------------------------
 * The gotoTracker class keeps track of all gotos and labels in the
 * function. When the function completes, it points all the gotos at the
 * correct label. If any labels are referred to but not found, this is
 * an error.
 * ---------------------------------------------------------------------- */


   static struct gotoTracker * NEAR_CALL
gototrackerNew(struct Call *call)
{
   struct gotoTracker *this =
      (struct gotoTracker *)jseMallocWithGC(call,sizeof(struct gotoTracker));

   if( this==NULL ) return False;
   this->gotosUsed = this->gotosAlloced = 0;
   this->gotos = NULL;
   this->labelsUsed = this->labelsAlloced = 0;
   this->labels = NULL;

   return this;
}


   static void NEAR_CALL
gototrackerDelete(struct gotoTracker *this,struct secompile *inwhat)
{
   uint x,y;
   for( x = 0;x<this->gotosUsed;x++ )
   {
      for( y = 0;y<this->labelsUsed;y++ )
      {
         if( this->gotos[x].label==this->labels[y].label )
         {
            secompileFixupGotoItem(inwhat,this->gotos[x].sptr,
                                   this->labels[y].sptr);
            break;
         }
      }
      if( y==this->labelsUsed )
      {
         callQuit(inwhat->call,textcoreGOTO_LABEL_NOT_FOUND,
                  GetStringTableEntry(inwhat->call,this->gotos[x].label,NULL));
         break;
      }
   }

   if( this->gotos ) jseMustFree(this->gotos);
   if( this->labels ) jseMustFree(this->labels);

   jseMustFree(this);
}


/* labels and gotos cannot appear within with() statements. Getting
 * this to work would be very difficult. For now at least, ignore it.
 * can't be in for..in either. The reason is both keep information
 * on our runtime stack as well as making changes in the call that
 * have to be in sync. It is a royal PITA to try to make a goto
 * sync these up as it leaves or enters these constructs.
 */

   jsebool NEAR_CALL
secompileAddGoto(struct secompile *this,VarName label)
{
   /* add a goto, and mark it for later fixup when we know what this
    * label refers to
    */
   struct gotoTracker *gTrack = this->gotoTrack;

   if( gTrack->gotosUsed >= gTrack->gotosAlloced )
   {
      gTrack->gotosAlloced += 10;
      gTrack->gotos = jseMustReMalloc(struct gotoItem,gTrack->gotos,
                              gTrack->gotosAlloced * sizeof(struct gotoItem));
   }
   assert( gTrack->gotosUsed < gTrack->gotosAlloced );
   gTrack->gotos[gTrack->gotosUsed].sptr = secompileCurrentItem(this);
   gTrack->gotos[gTrack->gotosUsed].label = label;
   gTrack->gotos[gTrack->gotosUsed].loop = NULL;
   gTrack->gotosUsed++;

   secompileAddItem(this,seTransfer,(ADDR_TYPE)0);
   return True;
}


   jsebool NEAR_CALL
secompileAddLabel(struct secompile *this,VarName label)
{
   struct gotoTracker *gTrack = this->gotoTrack;

   /* overwrite mayIContinue with a linenumber */
   secompileAddItem(this,seLineNumber,this->prevLineNumber);

   if( gTrack->labelsUsed >= gTrack->labelsAlloced )
   {
      gTrack->labelsAlloced += 10;
      gTrack->labels = jseMustReMalloc(struct gotoItem,gTrack->labels,
                              gTrack->labelsAlloced * sizeof(struct gotoItem));
   }
   assert( gTrack->labelsUsed < gTrack->labelsAlloced );
   gTrack->labels[gTrack->labelsUsed].sptr = secompileCurrentItem(this);
   gTrack->labels[gTrack->labelsUsed].label = label;
   gTrack->labels[gTrack->labelsUsed].loop = NULL;
   gTrack->labelsUsed++;

   return True;
}


/*
 * ----------------------------------------------------------------------
 * The loopTracker works very much like the gotoTracker, keeping track
 * of all breaks and continues. When the loop finishes parsing, we
 * patch all of the breaks and continues to point to the correct address.
 *
 * Because loops can be inside loops, we keep a stack of these loops
 * linking them togethor in a list.
 * ----------------------------------------------------------------------
 */

   static void NEAR_CALL
looptrackerAddBreak(struct loopTracker *this,uint addr)
{
   if( this->breaksUsed>=this->breaksAlloced )
   {
      this->breaksAlloced += 10;
      this->breaks = jseMustReMalloc(uint,this->breaks,this->breaksAlloced *
                                     sizeof(uint));
   }
   assert( this->breaks!=NULL );
   assert( this->breaksUsed<this->breaksAlloced );
   this->breaks[this->breaksUsed++] = addr;
}


   static void NEAR_CALL
looptrackerAddContinue(struct loopTracker *this,uint addr)
{
   if( this->continuesUsed>=this->continuesAlloced )
   {
      this->continuesAlloced += 10;
      this->continues = jseMustReMalloc(uint,this->continues,
                                        this->continuesAlloced * sizeof(uint));
   }
   assert( this->continues!=NULL );
   assert( this->continuesUsed<this->continuesAlloced );
   this->continues[this->continuesUsed++] = addr;
}


   static struct loopTracker * NEAR_CALL
looptrackerNew(struct Call *call)
{
   struct loopTracker *this =
      (struct loopTracker *)jseMallocWithGC(call,sizeof(struct loopTracker));
   if( this==NULL ) return NULL;

   this->next = NULL;
   this->breaksUsed = 0;
   this->breaksAlloced = 0;
   this->breaks = NULL;
   this->continuesUsed = 0;
   this->continuesAlloced = 0;
   this->continues = NULL;

   return this;
}


   static void NEAR_CALL
looptrackerDelete(struct loopTracker *this,
                  struct secompile *inwhat,ADDR_TYPE breakPtr,
                  ADDR_TYPE continuePtr)
{
   uint x;

   for( x=0;x<this->breaksUsed;x++ )
      secompileFixupGotoItem(inwhat,this->breaks[x],breakPtr);
   for( x=0;x<this->continuesUsed;x++ )
      secompileFixupGotoItem(inwhat,this->continues[x],continuePtr);

   if( this->breaks ) jseMustFree(this->breaks);
   if( this->continues ) jseMustFree(this->continues);

   jseMustFree(this);
}


/* Mark that we are in a loop, and set up all breaks and continues to be
 * be saves. This must save any old loop behind it
 */
   jsebool NEAR_CALL
secompileNewLoop(struct secompile *this,struct gotoItem *label)
{
   struct loopTracker *t = looptrackerNew(this->call);
   if( t==NULL )
   {
      callQuit(this->call,textcoreOUT_OF_MEMORY);
      return False;
   }

   t->next = this->loopTrack;
   this->loopTrack = t;

   if( label!=NULL ) label->loop = t;

   return True;
}


/* Patch up all the breaks and continues of the loop, restore the old loop
 * (if any.)
 */
   void NEAR_CALL
secompileEndLoop(struct secompile *this,
                 ADDR_TYPE break_address,ADDR_TYPE continue_address,
                 struct gotoItem *label)
{
   struct loopTracker *t = this->loopTrack;

   assert( this->loopTrack!=NULL );
   this->loopTrack = t->next;
   looptrackerDelete(t,this,break_address,continue_address);

   if( label!=NULL ) label->loop = NULL;
}


   jsebool NEAR_CALL
secompileAddBreak(struct secompile *this,struct loopTracker *it)
{
   /* add a break (goto), but mark it so it can be back-filled later
    * when we figure out where break goes to!
    */
   if( !this->loopTrack )
   {
      callQuit(this->call,textcoreBAD_BREAK);
      return False;
   }
   if( it==NULL ) it = this->loopTrack;
   looptrackerAddBreak(it,secompileCurrentItem(this));
   secompileAddItem(this,seTransfer,(ADDR_TYPE)0);
   return True;
}


   jsebool NEAR_CALL
secompileAddContinue(struct secompile *this,struct loopTracker *it)
{
   /* add a continue (goto), but mark it so it can be back-filled later
    * when we figure out where break goes to!
    */
   if( !this->loopTrack )
   {
      callQuit(this->call,textcoreBAD_BREAK);
      return False;
   }
   if( it==NULL ) it = this->loopTrack;
   looptrackerAddContinue(it,secompileCurrentItem(this));
   secompileAddItem(this,seTransfer,(ADDR_TYPE)0);
   return True;
}


#ifndef NDEBUG
/*#define SECODE_LISTINGS*/
#endif

/* List before optimizations */
/*#define SECODE_PRELISTINGS*/

#if defined(SECODE_PRELISTINGS) && !defined(SECODE_LISTINGS)
#define SECODE_LISTINGS
#endif


#ifdef SECODE_LISTINGS
   void NEAR_CALL
secodeListing(struct secompile *this)
{
   struct Call *call = this->call;
   secode EndOpcodes, c;

   DebugPrintf("---------------------------------------------------------------\n");
   DebugPrintf("Function %s(%d args).\n",
          GetStringTableEntry(call,(VarName)this->locfunc->FunctionName,NULL),
          this->locfunc->InputParameterCount);
   DebugPrintf("---------------------------------------------------------------\n");

   EndOpcodes = this->opcodes + this->opcodesUsed;
   for( c = this->opcodes; c != EndOpcodes; c++ )
   {
      DebugPrintf("%03ld: %22s   ",c-this->opcodes,secodeData[*c].name);

      if( secodeData[*c].size1!=0 )
      {
         VAR_INDEX_TYPE index = SECODE_GET_ONLY(c+1,VAR_INDEX_TYPE);
#        if defined(JSE_PACK_SECODES) && (JSE_PACK_SECODES==1)
            WITH_TYPE depth = SECODE_GET_ONLY(c+1+(sizeof(VAR_INDEX_TYPE)/sizeof(secodeelem)),
                                              WITH_TYPE);
#        else
            WITH_TYPE depth = SECODE_GET_ONLY(c+2,WITH_TYPE);
#        endif
         VarName name = (index<=0)?this->locfunc->items[-index].VarName:
            this->locfunc->items[index+this->locfunc->InputParameterCount-1].VarName;
         DebugPrintf("%s[%d] (with depth %d)",GetStringTableEntry(call,name,NULL),
                (int)index,(int)depth);
      }
      else if( secodeData[*c].size0 )
      {
         if( *c>=SE_VARNAME_EXT )
         {
            DebugPrintf("%s",GetStringTableEntry(call,SECODE_GET_ONLY(c+1,VarName),NULL));
         }
         else if( *c>=SE_START_GOTO_CODES )
         {
            DebugPrintf("%03d",SECODE_GET_ONLY(c+1,CONST_TYPE));
         }
         else if( *c==sePushConstant )
         {
            rSEObject robj;
            rSEObjectMem rMem;

            SEOBJECT_ASSIGN_LOCK_R(robj,this->locfunc->hConstants);
            rMem = rseobjIndexMemberStruct(call,robj,SECODE_GET_ONLY(c+1,CONST_TYPE));
            SEOBJECT_UNLOCK_R(robj);
            if( SEVAR_GET_TYPE(SEOBJECTMEM_VAR(rMem))==VNumber )
            {
               jsechar buf[ECMA_NUMTOSTRING_MAX];
               EcmaNumberToString(buf,SEVAR_GET_NUMBER(SEOBJECTMEM_VAR(rMem)));
               DebugPrintf("%s",buf);
            }
            else if( SEVAR_GET_TYPE(SEOBJECTMEM_VAR(rMem))==VString )
            {
               const jsecharptr tmp = sevarGetData(call,SEOBJECTMEM_VAR(rMem));
               DebugPrintf("%s",tmp);
               SEVAR_FREE_DATA(tmp,foo);
            }
            else
               DebugPrintf("constant type %d",SEVAR_GET_TYPE(SEOBJECTMEM_VAR(rMem)));
            SEOBJECTMEM_UNLOCK_R(rMem);
         }
         else if( *c==seNewFunction || *c==seCallFunction )
         {
            DebugPrintf("%d arguments",SECODE_GET_ONLY(c+1,CONST_TYPE));
         }
         else if( *c==sePushLocal || *c==seAssignLocal || *c==seAssignLocalPop )
         {
            VAR_INDEX_TYPE index = SECODE_GET_ONLY(c+1,VAR_INDEX_TYPE);
            VarName name = (index<=0)?this->locfunc->items[-index].VarName:
               this->locfunc->items[index+this->locfunc->InputParameterCount-1].VarName;
            DebugPrintf("%s[%d]",GetStringTableEntry(call,name,NULL),(int)index);
         }
         else
         {
            DebugPrintf("%d",(int)SECODE_GET_ONLY(c+1,CONST_TYPE));
         }
      }

      DebugPrintf("\n");
      c += SECODE_DATUM_SIZE(*c);
   }
   DebugPrintf("---------------------------------------------------------------\n");
}
#endif


/* All instructions that point to another instruction in the range of
 * start..end have their instruction pointer modified by offset. This
 * will allow instructions to be moved around during optimization.
 */
   static void NEAR_CALL
secompileUpdate(struct secompile *This,JSE_POINTER_SINDEX offset,ADDR_TYPE start,ADDR_TYPE end)
{
   secode sptr, StartOpcodes, EndOpcodes;
   ADDR_TYPE ptr;

   EndOpcodes = (StartOpcodes=This->opcodes) + This->opcodesUsed;
   for( sptr = StartOpcodes; sptr != EndOpcodes; sptr++ )
   {
      if( *sptr>=SE_START_GOTO_CODES && *sptr<=SE_END_GOTO_CODES )
      {
         ptr = SECODE_GET_ONLY(sptr+1,ADDR_TYPE);
         if( ptr>=start && ptr<=end )
            SECODE_PUT_ONLY(sptr+1,ADDR_TYPE,ptr+offset);
      }
      sptr += SECODE_DATUM_SIZE(*sptr);
   }
   assert( sptr == EndOpcodes );
}


/* ---------------------------------------------------------------------- *
 * This is the code for the peephole optimizer. Its job is to find common
 * inefficient code sequences that are generated by the compiler and turn
 * them into equivelent, but faster sequences. This generally involves
 * making sure that there is no entry into the middle of the sequence
 * (i.e. no goto jumps into the middle) and then replacing the sequence
 * with a better one. This is done in one place so as to not bloat the code
 * with many repetitive checks.
 * ---------------------------------------------------------------------- */

#if !defined(JSE_PEEPHOLE_OPTIMIZER) || (0!=JSE_PEEPHOLE_OPTIMIZER)

/* Build up an array of which secodes have jumps targetted at them
 */
   static ubyte* NEAR_CALL
secompileTargetted(struct secompile *This)
{
   ubyte *ret;
   secode sptr, StartOpcodes, EndOpcodes;
   uword32 i;

   ret = jseMustMalloc(ubyte,This->opcodesAlloced*sizeof(ubyte));
   assert( ret!=NULL );

   for( i=0;i<This->opcodesUsed;i++ ) ret[i] = 0;

   /* set points for all the gotos so other optimizations do not remove
    * them.  Also optimize gotos so they don't point to line numbers, and
    * so they don't bounce around a gotoAlways
    */
   EndOpcodes = (StartOpcodes=This->opcodes) + This->opcodesUsed;
   for( sptr = StartOpcodes; sptr != EndOpcodes; sptr++ )
   {
      if( *sptr>=SE_START_GOTO_CODES && *sptr<=SE_END_GOTO_CODES )
      {
         ADDR_TYPE dest = SECODE_GET_ONLY(sptr+1,ADDR_TYPE);
         ADDR_TYPE oldDest;
         assert( dest < This->opcodesUsed );

         do {
            oldDest = dest;
            if( seLineNumber == This->opcodes[dest] )
            {
               dest += (1+SECODE_DATUM_SIZE(This->opcodes[dest]));
            }
            if( seGoto == This->opcodes[dest] )
            {
               dest = SECODE_GET_ONLY(This->opcodes+dest+1,ADDR_TYPE);
            }
         } while ( dest != oldDest );
         assert( dest < This->opcodesUsed );

         /* don't update these because the destination is marking a place
          * in memory, to know what range of opcodes is important
          */
         if( *sptr!=seStartTry )
            SECODE_PUT_ONLY(sptr+1,ADDR_TYPE,dest);
         assert( dest<This->opcodesUsed );
         ret[dest] = 1;
      }
      sptr += SECODE_DATUM_SIZE(*sptr);
   }
   assert( sptr == EndOpcodes );

   return ret;
}


/* Remove 'size' instructions starting at 'sptr' and update the 'targetted' array
 * as well.
 * Negative size can be adding elements.
 */
   static void NEAR_CALL
secompileDelete(struct secompile *This,secode_w sptr,
                ubyte **targetted,sint size)
{
   size_t offsetTo = (size_t)(sptr - This->opcodes) ;
   size_t offsetFrom = offsetTo + size ;
   size_t elementMoveCount = This->opcodesUsed - offsetFrom ;

   if( size<0 ) /* an addition */
   {
      /* we are allowed to add an instruction or two, not a huge block */
      assert( size>-50 );
      if( (This->opcodesUsed-size)>This->opcodesAlloced )
      {
         This->opcodesAlloced += 50;
         (*targetted) = jseMustReMalloc(ubyte,*targetted,This->opcodesAlloced);
         This->opcodes = jseMustReMalloc(secodeelem,This->opcodes,
                                         This->opcodesAlloced*sizeof(secodeelem));
      }
   }

   memmove( sptr, sptr+size, elementMoveCount * sizeof(secodeelem) );
   memmove( (*targetted)+offsetTo, (*targetted)+offsetFrom, elementMoveCount );
   This->opcodesUsed -= size;
}


/* NYI: try to make less 'hardcoded' */
/* Scan for and replace common inefficient instruction sequences
 */
   static void NEAR_CALL
secompilePeephole(struct secompile *This)
{
   secode_w sptr, StartOpcodes, nxt;
   jsebool again;
   ubyte *targetted;     /* an array of booleans */
   sint len;

   targetted = secompileTargetted(This);

   do {
      again = False;
      /* The array can move and its size can change, so need
       * to recalculate ending point each iteration.
       */
      StartOpcodes=This->opcodes;
      for( sptr = StartOpcodes; sptr < This->opcodes + This->opcodesUsed; )
      {
         nxt = sptr+1+SECODE_DATUM_SIZE(*sptr);
         len = (1 + SECODE_DATUM_SIZE(*nxt));

         /* It is possible to declare a local after it is first used. We go
          * through these opcodes if any have this happen to them, we change
          * to the appropriate 'local' version.
          */
         if ( !LOCAL_TEST_IF_INIT_FUNCTION(This->locfunc,This->call)
           && ( *sptr<=SE_END_GLOBAL_CODES && SE_START_GLOBAL_CODES<=*sptr ) )
         {
            VarName mem = SECODE_GET_ONLY(sptr+1,VarName);
            VAR_INDEX_TYPE index;
            jsebool found = False;
            WITH_TYPE with_depth = 0;
            secode loop;
            secodeelem c;

            assert( *sptr==sePushGlobal         || *sptr==sePushGlobalParam \
                 || *sptr==sePushGlobalAsObject || *sptr==seAssignGlobal    \
                 || *sptr==sePostIncGlobal      || *sptr==sePostDecGlobal   \
                 || *sptr==sePreIncGlobal       || *sptr==sePreDecGlobal    \
                 || *sptr==seCheckGlobal        ||  *sptr==seTypeofGlobal   );

            if( (index = loclFindLocal(This->locfunc,mem))!=-1 )
            {
               index++; found = True;
            }
            else if( (index = loclFindParam(This->locfunc,mem))!=-1 )
            {
               index = (VAR_INDEX_TYPE)(-index); found = True;
            }

            if( found )
            {
               JSE_POINTER_SINDEX change;

               /* aha, it did happen, change things around */
               if( *sptr==seCheckGlobal )
               {
                  /* the check is not necessary for locals because we
                   * know it is defined.
                   */
                  goto RemoveThisOpcode;
               }

               assert( (nxt) >= This->opcodes );
               /* going to change one class of opcodes into another */
               change = 1+SECODE_DATUM_SIZE(sePushLocalWith) -
                  (1+SECODE_DATUM_SIZE(*sptr));
               /* add one instruction, seTypeof, that takes no extension */
               if( *sptr==seTypeofGlobal ) change += 1;

               c = *sptr;
               secompileUpdate(This,change,(uint)((nxt)-This->opcodes),This->opcodesUsed);
               secompileDelete(This,sptr,&targetted,-change);

               if ( SE_GLOBAL_NOTDIRECTXLAT <= c )
               {
                  if ( seTypeofGlobal == c )
                  {
                     sptr[1+SECODE_DATUM_SIZE(sePushLocalWith)] = seTypeof;
                     *sptr = sePushLocalWith;
                  }
                  else
                  {
                     assert( seAssignGlobal == c );
                     *sptr = seAssignLocalWith;
                  }
               }
               else
               {
                  /* convert global codeto equivalent local code */
                  *sptr = c - ((SE_START_GLOBAL_CODES+1) - SE_START_LOCAL_CODES);
#                 ifndef NDEBUG
                     switch( c )
                     {
                        case sePushGlobal:         assert( *sptr == sePushLocalWith );     break;
                        case sePushGlobalAsObject: assert( *sptr == sePushLocalAsObject ); break;
                        case sePushGlobalParam:    assert( *sptr == sePushLocalParam );    break;
                        case sePreIncGlobal:       assert( *sptr == sePreIncLocal );       break;
                        case sePreDecGlobal:       assert( *sptr == sePreDecLocal );       break;
                        case sePostIncGlobal:      assert( *sptr == sePostIncLocal );      break;
                        case sePostDecGlobal:      assert( *sptr == sePostDecLocal );      break;
                        default:                   assert( False);                         break;
                     }
#                 endif
               }
               SECODE_PUT_ONLY(sptr+1,VAR_INDEX_TYPE,index);

               /* calculate the with-depth. Note that due to the way withs
                * are parsed, a simple lexical calculation of how many unclosed
                * seScopeAdds there are tells us the value.
                */
               for( loop = This->opcodes;loop<sptr;loop++ )
               {
                  if( *loop==seScopeAdd )
                     with_depth++;
                  else if( *loop==seScopeRemove )
                     with_depth--;

                  loop += SECODE_DATUM_SIZE(*loop);
               }

#              if defined(JSE_PACK_SECODES) && (JSE_PACK_SECODES==1)
                  SECODE_PUT_ONLY(sptr+1+(sizeof(VAR_INDEX_TYPE)/sizeof(secodeelem)),
                                          WITH_TYPE,with_depth);
#              else
                  SECODE_PUT_ONLY(sptr+2,WITH_TYPE,with_depth);
#              endif
               again = True;
               continue;
            }
         }
         /* NYI: change sePushLocalWith where with==0 to sePushLocal */

         if( nxt<(This->opcodes+This->opcodesUsed) && *sptr==seGoto &&
             SECODE_GET_ONLY(sptr+1,ADDR_TYPE)==(ADDR_TYPE)(nxt-This->opcodes) )
         {
         RemoveThisOpcode:
            assert( (nxt) >= This->opcodes );
            secompileUpdate(This,-1-SECODE_DATUM_SIZE(*sptr),
                            (ADDR_TYPE)((nxt)-This->opcodes),
                            This->opcodesUsed);
            secompileDelete(This,sptr,&targetted,1+SECODE_DATUM_SIZE(*sptr));
            again = True;
            continue;
         }

         if( nxt<This->opcodes+This->opcodesUsed && !targetted[(size_t)(nxt-This->opcodes)] )
         {
            /* Push line numbers ahead */
            if( *sptr==seLineNumber && *nxt==sePopDiscard )
            {
               memmove(sptr+1,sptr,(1+SECODE_DATUM_SIZE(*sptr))*sizeof(secodeelem));
               *sptr = sePopDiscard;
               again = True;
               continue;
            }

            if( (*sptr==seContinueFunc || *sptr==seLineNumber) &&
                (*nxt==seContinueFunc || *nxt==seLineNumber) )
            {
               if( *nxt==seContinueFunc ) *sptr = seContinueFunc;
               /* we scan ahead to find line numbers, so the second
                * one is effectively covered up and ignored. If it
                * is a continue, though, make the first one a continue
                * too. Two continues in a row doesn't make any sense
                * and there is no problem removing one.
                */
               goto RemoveNextOpcode;
            }

            if( *sptr==seAssignLocal && *nxt==sePopDiscard )
            {
               *sptr = seAssignLocalPop;
               goto RemoveNextOpcode;
            }

            if( (*sptr==sePreIncLocal || *sptr==sePostIncLocal) &&
                *nxt==sePopDiscard )
            {
               *sptr = seIncOnlyLocal;

            RemoveNextOpcode:
               assert( (nxt+len) >= This->opcodes );
               secompileUpdate(This,-1-SECODE_DATUM_SIZE(*nxt),
                               (ADDR_TYPE)((nxt+len)-This->opcodes),
                               This->opcodesUsed);
               secompileDelete(This,nxt,&targetted,len);
               again = True;
               continue;
            }
            if( (*sptr==sePreIncLocal || *sptr==sePostIncLocal) &&
                *nxt==sePopDiscard )
            {
               *sptr = seIncOnlyLocal;
               goto RemoveNextOpcode;
            }

            if( (*sptr==sePushLocal || *sptr==sePushConstant) &&
                *nxt==sePopDiscard )
            {
               /* RemoveBothOpcodes: */
               assert( (nxt+len) >= This->opcodes );
               secompileUpdate(This,-2-SECODE_DATUM_SIZE(*nxt)-SECODE_DATUM_SIZE(*sptr),
                               (ADDR_TYPE)((nxt+len)-This->opcodes),
                               This->opcodesUsed);
               secompileDelete(This,sptr,&targetted,
                               2+SECODE_DATUM_SIZE(*nxt)+SECODE_DATUM_SIZE(*sptr));
               again = True;
               continue;
            }

            if( *sptr==seFilename )
            {
               secode old = This->opcodes,found = NULL;

               while( old<sptr )
               {
                  if( *old==seFilename ) found = old;
                  old += 1 + SECODE_DATUM_SIZE(*old);
               }
               if( found && SECODE_GET_ONLY(found+1,VarName)==SECODE_GET_ONLY(sptr+1,VarName) )
               {
                  /* redundant filename */
                  goto RemoveThisOpcode;
               }
            }
         }
         sptr = nxt;
      }
   } while( again );

   jseMustFree(targetted);
}
#endif /* !defined(JSE_PEEPHOLE_OPTIMIZER) || (0!=JSE_PEEPHOLE_OPTIMIZER) */


/* ---------------------------------------------------------------------- */


/* Compile the header of a function and create a new LocalFunction
 * structure for it. Then call compileFunctionBody() to do the rest.
 *
 * If this is a function literal, do not add it to our parent as
 * a new function define, rather add it as a function constant.
 *
 * For literals, it will always add it as the 'last' constant,
 * i.e. it will be the latest one enterred.
 */
   jsebool NEAR_CALL
secompileFunction(struct secompile *this,jsebool literal)
{
   jsebool success;
   struct LocalFunction *newfunc;
#  if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
   jsebool cfunction = (jsebool)(jseOptDefaultCBehavior &
                                 this->call->Global->ExternalLinkParms.options);
#  endif
   VarName name;
   MemCountUInt i,j;
   struct Call *call = this->call;
   wSEVar wvar = STACK_PUSH;
   struct tok *token;
   uint mark;
   struct tok tmp;

   SEVAR_INIT_UNDEFINED(wvar);

   /* record where this token is in the current local function as
    * we will need to get rid of it later - this token marks the
    * beginning of a new local function.
    */
   mark = SECOMPILE_CURRENT_TOKEN_INDEX(this);

   assert( tokType(this->token)==seTokCFunction ||
           tokType(this->token)==seTokFunction );

#  if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
   if( tokType(this->token)==seTokCFunction ) cfunction = True;
#  endif

   /* Function syntax: function FOO(args) { body } */
   token = secompileAdvancePtr(this);
   if( tokType(token)!=seTokIdentifier )
   {
      if( literal )
      {
         name = LockedStringTableEntry(this->call,UNISTR("anonymous"),9);
      }
      else
      {
         SECOMPILE_FREE_TOKENS(this,mark);
         callQuit(this->call,textcoreFUNCTION_NAME_MISSING);
         return False;
      }
   }
   else
   {
      name = tokGetName(token);
      token = secompileAdvancePtr(this);
   }

   /* Handle the 'function foo.goo()' syntax */
   while( !literal && tokType(token)=='.' )
   {
      VarName name2;
      jsecharptr n1;
      jsecharptr n2;
      jsecharptr tmp;
      stringLengthType l1,l2;


      /* function foo.goo() not applicable to nested functions */
      if( !LOCAL_TEST_IF_INIT_FUNCTION(this->locfunc,this->call) )
      {
         SECOMPILE_FREE_TOKENS(this,mark);
         callQuit(this->call,textcoreFUNCTION_NAME_MISSING);
         return False;
      }

      token = secompileAdvancePtr(this);
      if( tokType(token)!=seTokIdentifier )
      {
         SECOMPILE_FREE_TOKENS(this,mark);
         callQuit(this->call,textcoreFUNCTION_NAME_MISSING);
         return False;
      }
      name2 = tokGetName(token);
      /* some string table entries can be in a built-up buffer,
       * so we get once to find the length, then again to make
       * sure we have the correct value. Otherwise, the calls
       * can overwrite each other.
       */
      n1 = (jsecharptr)GetStringTableEntry(this->call,name,&l1);
      n2 = (jsecharptr)GetStringTableEntry(this->call,name2,&l2);

      tmp = jseMustMalloc(jsecharptrdatum,sizeof(jsechar)*(l1+l2+1));
      n1 = (jsecharptr)GetStringTableEntry(this->call,name,&l1);
      strncpy_jsechar(tmp,n1,l1);
      strncpy_jsechar(JSECHARPTR_OFFSET(tmp,l1),UNISTR("."),1);
      n2 = (jsecharptr)GetStringTableEntry(this->call,name2,&l2);
      strncpy_jsechar(JSECHARPTR_OFFSET(tmp,l1+1),n2,l2);
      name = LockedStringTableEntry(this->call,tmp,(stringLengthType)(l1+l2+1));
      jseMustFree(tmp);
      token = secompileAdvancePtr(this);
   }


   /* Create a constant for it. */
   SEVAR_INIT_BLANK_OBJECT(call,wvar);
#  if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
      newfunc = localNew(this->call,name,cfunction,wvar);
#  else
      newfunc = localNew(this->call,name,wvar);
#  endif
   if( newfunc==NULL )
   {
      callQuit(call,textcoreOUT_OF_MEMORY);
      return False;
   }

   i = secompileCreateConstant(this,wvar);

   if( !literal )
   {
      j = loclAddLocal(this->call,this->locfunc,name);
      this->locfunc->items[j].VarFunc = (sword16)i;
   }

   STACK_POP;

   /* Function syntax: function foo(ARGS) { body } */
   if( tokType(token)=='(' )
   {
      token = secompileAdvancePtr(this);
      while( tokType(token)!=')' )
      {
         jsebool ref = False;

         if( tokType(token)=='&' )
         {
            token = secompileAdvancePtr(this);
            ref = True;
         }

         if( tokType(token)!=seTokIdentifier )
         {
            SECOMPILE_FREE_TOKENS(this,mark);
            callQuit(this->call,textcoreINVALID_PARAMETER_DECLARATION,
                     newfunc->InputParameterCount+1,
                     GetStringTableEntry(this->call,newfunc->FunctionName,NULL));
            return False;
         }

         localAddVarName(newfunc,this->call,tokGetName(token));
         if( ref )
            newfunc->items[newfunc->InputParameterCount-1].VarAttrib = 1;
         token = secompileAdvancePtr(this);

         if( tokType(token)!=',' && tokType(token)!=')' )
         {
            SECOMPILE_FREE_TOKENS(this,mark);
            callQuit(this->call,textcoreINVALID_PARAMETER_DECLARATION,
                     newfunc->InputParameterCount+1,
                     GetStringTableEntry(this->call,newfunc->FunctionName,NULL));
            return False;
         }
         else if( tokType(token)==',' )
         {
            token = secompileAdvancePtr(this);
         }
      }

      assert( tokType(token)==')' );
      secompileAdvancePtr(this);
   }


   FUNCTION_PARAM_COUNT((struct Function *)newfunc) =
      newfunc->InputParameterCount;

   /* reset function to update param count */
#  if JSE_FUNCTION_LENGTHS==1
      seobjSetFunction(this->call,SEVAR_GET_OBJECT(wvar),((struct Function *)newfunc));
#  endif


   /* The current token is the first token of the new function, we
    * need to keep it.
    */
   tmp = *this->token;

   /* junk all the tokens built up to parse the header, we don't need
    * those anymore. The one we do need is already saved.
    */
   SECOMPILE_FREE_TOKENS(this,mark);

   /* Function syntax: function foo(args) _{_ BODY _}_ */
   this->token = SECOMPILE_NEW_TOKEN(this);
   *(this->token) = tmp;
   success = secompileFunctionBody(newfunc,this->call,False,this->token);

   return success;
}


/*
 * Compile the given function, the function's header and such should
 * have already been parsed and analyzed. 'next_token' is the first
 * token beyond the end of the parsed function, and is primed with
 * the first token of the current function (unless this is the init
 * function.)
 */
   jsebool
secompileFunctionBody(struct LocalFunction *locfunc,struct Call *c,
                      jsebool init_func,struct tok *next_token)
{
   struct secompile This;
   jsebool success = False;
   const jsecharptr filename;
   uint i;
   jsebool found;
   jsebool old_c = c->Global->CompileStatus.c_function;


   This.looplabel = NULL;
   if( (This.gotoTrack = gototrackerNew(c))==NULL )
   {
      callQuit(c,textcoreOUT_OF_MEMORY);
      return False;
   }

   This.prevLineNumber = 0;
   This.loopTrack = NULL;
   This.opcodesUsed = 0;
   This.opcodesAlloced = 50;
   This.with_depth = 0;
   This.call = c;
   This.opcodes = jseMustMalloc(secodeelem,(uint)(This.opcodesAlloced * \
                                                 sizeof(*(This.opcodes))));
   assert( This.opcodes!=NULL );
   This.NowCompiling = True;

   This.locfunc = locfunc;

   /* during compilation will write constants into local structure */
   SEOBJECT_ASSIGN_LOCK_W(This.constObj,locfunc->hConstants);
   SEMEMBERS_PTR(This.constMembers) = NULL;

   filename = This.call->Global->CompileStatus.CompilingFileName;
   if( filename==NULL ) filename = UNKNOWN_FILENAME;
   secompileAddItem(&This,seFilename,
      LockedStringTableEntry(This.call,filename,(stringLengthType)strlen_jsechar(filename)));

   c->Global->CompileStatus.c_function = FUNCTION_C_BEHAVIOR((struct Function *)locfunc);

   /* ----------------------------------------------------------------------
    * Actually parse the source text of the function
    *
    * For an initialization function, we will just be all the
    * statements outside of any function. For a regular function
    * we will get the text of the function inside '{' and '}'
    * which we can treat just like a statement.
    */
   if( init_func )
   {
      secompileAdvancePtr(&This);

      while( tokType(SECOMPILE_CURRENT_TOKEN(&This))!=seTokEOF )
      {
         success = secompileStatement(&This);
         if( !success ) break;
      }
   }
   else
   {
      if( tokType(next_token)!='{' )
      {
         callQuit(This.call,textcoreFUNCTION_BRACES);
         success = False;
      }
      else
      {
         This.token = next_token;
         success = secompileStatement(&This);
      }
   }

   if( !success )
   {
      /* unsuccessful, free the memory for any loops we are still in */
      while( This.loopTrack )
         secompileEndLoop(&This,0,0,NULL);

      This.opcodesUsed = 0;
   }
   else
   {
      if( LOCAL_TEST_IF_INIT_FUNCTION(locfunc,This.call) )
      {
         found = False;
         /* Return the last thing evaluated. Can't just check the last
          * entry, because it could be an extension value for a previous
          * opcode.
          */
         for( i=0;i<This.opcodesUsed;i++ )
         {
            if( i==This.opcodesUsed-1 && This.opcodes[i]==sePopDiscard )
            {
               uint j;

               found = True;

               /* if someone goes to the instruction after the sePopDiscard,
                * then the sePopDiscard is not always reached before continuing,
                * and thus cannot be dropped.
                */
               for( j=0;j<This.opcodesUsed;j++ )
               {
                  if( This.opcodes[j]>=SE_START_GOTO_CODES &&
                      This.opcodes[j]<=SE_END_GOTO_CODES &&
                      SECODE_GET_ONLY(This.opcodes+j+1,CONST_TYPE)>i )
                  {
                     found = False;
                     break;
                  }
                  j += SECODE_DATUM_SIZE(This.opcodes[j]);
               }
               if( found ) This.opcodesUsed--;
               break;
            }
            i += SECODE_DATUM_SIZE(This.opcodes[i]);
         }
         if( !found )
            secompileAddItem(&This,sePushUndefined);
      }
      else
      {
         /* For function calls, we always return undefined
          * if no explicit return.
          */
         secompileAddItem(&This,sePushUndefined);
      }

      /* if we fall off the end of the function */
      secompileAddItem(&This,seReturn);
   }

   /* successful or unsuccessful compile, nothing ought to be left around */
   assert( This.loopTrack==NULL );

   /* patch up all gotos and such */
   gototrackerDelete(This.gotoTrack,&This);

   secompileAddItem(&This,seLineNumber,
                    This.call->Global->CompileStatus.CompilingLineNumber);

#  ifdef SECODE_PRELISTINGS
   if( success /*&& !LOCAL_TEST_IF_INIT_FUNCTION(This.locfunc,c)*/ )
      secodeListing(&This);
#  endif

#  if !defined(JSE_PEEPHOLE_OPTIMIZER) || (0!=JSE_PEEPHOLE_OPTIMIZER)
   if( success )
      secompilePeephole(&This);
#  endif

   locfunc->opcodesUsed = This.opcodesUsed;
#  if JSE_MEMEXT_SECODES==1
      locfunc->op_handle = jsememextStore(This.opcodes,
                                          This.opcodesUsed*sizeof(secodeelem),jseMemExtSecodeType);
      assert( locfunc->op_handle != jsememextNullHandle );
#  else
      /* clean up any allocated item holders that aren't used */
      locfunc->opcodes = jseMustReMalloc(secodeelem,This.opcodes,
                                         (This.opcodesUsed) *
                                         sizeof(*(This.opcodes)));
#     if defined(SECODE_LISTINGS) \
      && ( !defined(JSE_PEEPHOLE_OPTIMIZER) || (0!=JSE_PEEPHOLE_OPTIMIZER) )
         This.opcodes = locfunc->opcodes;
#     endif
#  endif

   /* It only makes sense to print it out again if we've actually done some
    * optimizations
    */
#  if defined(SECODE_LISTINGS) \
   && ( !defined(JSE_PEEPHOLE_OPTIMIZER) || (0!=JSE_PEEPHOLE_OPTIMIZER) )
   if( success )
   {
      /*if( !LOCAL_TEST_IF_INIT_FUNCTION(This.locfunc,c) )*/
         secodeListing(&This);
   }
#  endif

#  if JSE_MEMEXT_SECODES==1
      /* In this case, the opcodes have been stored using the 'secodeStore'
       * routine, and we have done everything we need to with them, so
       * they get freed.
       */
      jseMustFree(This.opcodes);
#  endif

   /* The new function's last token is the first token beyond what
    * it used, namely our own function's next token. Move that one
    * token into the current function and then delete it from the
    * new function.
    */
   *next_token = *SECOMPILE_CURRENT_TOKEN(&This);
   SECOMPILE_FREE_TOKENS(&This,SECOMPILE_CURRENT_TOKEN_INDEX(&This));
   if( success && !init_func )
   {
      jsebool done;

      /* get rid of last '}' */
      do
      {
         done = tokType(SECOMPILE_CURRENT_TOKEN(&This))=='}';
         SECOMPILE_FREE_TOKENS(&This,SECOMPILE_CURRENT_TOKEN_INDEX(&This));
      }
      while( !done );
   }

   /* finished working with the locfunc constants */
#  if 0!=JSE_MEMEXT_MEMBERS
      if ( NULL != SEMEMBERS_PTR(This.constMembers) )
         SEMEMBERS_UNLOCK_W(This.constMembers);
#  endif
   SEOBJECT_UNLOCK_W(This.constObj);

   /* minimize use of memory used for tokens */
   localMinimizeTokens(locfunc,!success);

   c->Global->CompileStatus.c_function = old_c;

   return success;
}

/* ---------------------------------------------------------------------- */
/* secode expression compiler routines                                    */
/* ---------------------------------------------------------------------- */

#pragma codeseg EXPRESSN2_TEXT

#define secompileLeftHandSideExpression secompileMemberExpression

static jsebool NEAR_CALL secompileArray(struct secompile *this,jsebool oldstyle);

/*
 * Compile the object declarator syntax a = { a:4, b:6 };
 */
static jsebool NEAR_CALL secompileObject(struct secompile *this)
{
#  ifndef NDEBUG
   uint elem = 0;
#  endif
   struct seExpression save;
   struct tok tok;

   assert( tokType(this->token)=='{' );
   secompileAdvancePtr(this);

   /* ECMA object's are of the form:
    *   { <constant>: value,... }
    */
   tokLookAhead(this,&tok);
   if( tokType(&tok)!=':' )
   {
      /* Old-style ScriptEase syntax */
      return secompileArray(this,True);
   }

   /* create blank object */
   secompileAddItem(this,sePushNewObject);
   /* for each element */
   while( tokType(this->token)!='}' )
   {
      /* so we generate an assignment to the appropriate element number */
      secompileAddItem(this,sePushDup);

      /* To allow for persitence and ToSource(), we must provide a way to have
       * strange variable names in object initializers.  In order to do so, we
       * allow the combination of stringLiteral:value as well.  This allows
       * us to do 'var a = { "a\0b":4 };'.  This is an extension to ECMAScript,
       * so we still support what the spec says.
       */
      if( tokType(this->token) == seTokIdentifier )
      {
         this->expr.type = EXPR_MEMBER;
         this->expr.name = tokGetName(this->token);
         secompileAdvancePtr(this);
         /* ECMA Spec states that both numeric and string literals are allowed */
         if( ':' != tokType(this->token) )
         {
            callQuit(this->call,textcoreBAD_OBJECT_INITIALIZER);
            return False;
         }
      }
      else if( tokType(this->token) == seTokConstant )
      {
         rSEVar rvar = tokGetVar(this,this->token);
         /* ECMA Spec states that both numeric and string literals are allowed */
         if( (SEVAR_GET_TYPE(rvar)!=VString && SEVAR_GET_TYPE(rvar)!=VNumber) )
         {
            callQuit(this->call,textcoreBAD_OBJECT_INITIALIZER);
            return False;
         }
         secompileAddItem(this,sePushConstant,tokGetVarIndex(this->token));
         this->expr.type = EXPR_ARRAY;
         secompileAdvancePtr(this);
         if( ':'!= tokType(this->token) )
         {
            callQuit(this->call,textcoreBAD_OBJECT_INITIALIZER);
            return False;
         }
      }
      else
      {
         callQuit(this->call,textcoreBAD_OBJECT_INITIALIZER);
         return False;
      }

      secompileAdvancePtr(this);

      save = this->expr;
      this->expr.type = EXPR_VOID;
      if( !secompileOperatorExpression(this,PRI_ASSIGN,True) ) return False;
      secompileGetValue(this);
      this->expr = save;
      secompilePutValue(this);
      secompileDiscard(this);
      /* that cleans up the stack leaving the original object still on it */

      if( tokType(this->token)=='}' ) break;
      if( tokType(this->token)!=',' )
      {
         callQuit(this->call,textcoreEXPECT_COMMA_BETWEEN_OBJECT_INITS);
         return False;
      }
      secompileAdvancePtr(this);
#     ifndef NDEBUG
         elem++;
         /* it is very unlikely that a uint is not big enough to handle all the
          * elements of this array.  Let's assert on it anyway to make sure
          * it doesn't rollover.
          */
         assert( elem != 0 );
#     endif
   }

   assert( tokType(this->token)=='}' );
   secompileAdvancePtr(this);
   this->expr.type = EXPR_STACKTOP;
   return True;
}

/*
 * Compile the array declarator syntax a = [ foo, bar ];
 */
static jsebool NEAR_CALL secompileArray(struct secompile *this,jsebool oldstyle)
{
   uint elem = 0;

   if( !oldstyle)
   {
      assert( tokType(this->token)=='[' );
      secompileAdvancePtr(this);
   }

   /* create blank object
    * This object must be an ECMA-Array, so we have to do a little work to
    * make this object appropriately.
    */

   secompileAddItem(this,sePushNewArray);
   /* for each element */
   while( (!oldstyle && tokType(this->token)!=']') ||
          (oldstyle && tokType(this->token)!='}') )
   {
      /* Allow multiple commas to signify empty indexes */
      if( tokType(this->token) != ',' )
      {
         struct seExpression save;

         /* so we generate an assignment to the appropriate element number */
         secompileAddItem(this,sePushDup);
         this->expr.type = EXPR_MEMBER;
         this->expr.name = PositiveStringTableEntry(elem);
         save = this->expr;
         this->expr.type = EXPR_VOID;

         if( !secompileOperatorExpression(this,PRI_ASSIGN,True) )
            return False;
         secompileGetValue(this);
         this->expr = save;
         secompilePutValue(this);
         secompileDiscard(this);
         /* that cleans up the stack leaving the original object still on it */

         if( (!oldstyle && tokType(this->token)==']') ||
             (oldstyle && tokType(this->token)=='}') )
            break;
         if( tokType(this->token)!=',' )
         {
            callQuit(this->call,textcoreEXPECT_COMMA_BETWEEN_ARRAY_INITS);
            return False;
         }
      }
      secompileAdvancePtr(this);
      elem++;
      /* it is very unlikely that a uint is not big enough to handle all the
       * elements of this array.  Let's assert on it anyway to make sure
       * it doesn't rollover.
       */
      assert( elem != 0 );
   }

   assert( (!oldstyle && tokType(this->token)==']') ||
          (oldstyle && tokType(this->token)=='}') );
   secompileAdvancePtr(this);
   this->expr.type = EXPR_STACKTOP;
   return True;
}


/* Returns number of arguments, -1 for error */
static CONST_TYPE NEAR_CALL secompileFunctionArgs(struct secompile *this)
{
   CONST_TYPE count = 0;

   if( tokType(this->token)!=')' )
   {
      do {
         /* eat the comma if there */
         if( count++ ) secompileAdvancePtr(this);

         SE_NEW_EXPR(this);
         /* use this one so commas don't get eaten */
         if( !secompileOperatorExpression(this,PRI_ASSIGN,True) ) return (CONST_TYPE)-1;
         secompileGetValueForParam(this,count-1);
      } while( tokType(this->token)==',' );
   }

   if( tokType(this->token)!=')' )
   {
      callQuit(this->call,textcoreMISSING_CLOSE_PAREN);
      return (CONST_TYPE)-1;
   }
   secompileAdvancePtr(this);

   if( count>this->locfunc->max_params )
      this->locfunc->max_params = (uword16)count;

   return count;
}


static jsebool NEAR_CALL secompilePrimaryExpression(struct secompile *this)
{
   jsebool success = True;


#if defined(JSE_REGEXP_LITERALS) && (0!=JSE_REGEXP_LITERALS)
   if( (tokType(this->token)=='/' || tokType(this->token)==seTokDivEqual ) )
   {
      /* redo as regular expression */
      tokRegExp(this,this->token);
   }
#endif

   switch( tokType(this->token) )
   {
      /* a function literal, second param to secompileFunction specifies that. */
      /* ECMA2.0 */
      case seTokCFunction:
      case seTokFunction:
         if( !secompileFunction(this,True) ) return False;
         secompileAddItem(this,sePushConstant,SEOBJECT_PTR(this->constObj)->used-1);
         this->expr.type = EXPR_STACKTOP;
         return True;

      case seTokNull:
         secompileAddItem(this,sePushNull);
         this->expr.type = EXPR_STACKTOP;
         secompileAdvancePtr(this);
         return True;
      case seTokThis:
         secompileAddItem(this,sePushThis);
         this->expr.type = EXPR_STACKTOP;
         secompileAdvancePtr(this);
         return True;
      case seTokFalse:
         secompileAddItem(this,sePushFalse);
         this->expr.type = EXPR_STACKTOP;
         secompileAdvancePtr(this);
         return True;
      case seTokTrue:
         secompileAddItem(this,sePushTrue);
         this->expr.type = EXPR_STACKTOP;
         secompileAdvancePtr(this);
         return True;
      case '(':
         secompileAdvancePtr(this);
         if( !secompileExpression(this) ) return False;
         if( tokType(this->token)!=')' )
         {
            callQuit(this->call,textcoreMISSING_CLOSE_PAREN);
            success = False;
            break;
         }
         secompileAdvancePtr(this);
         break;
      case seTokConstant:
      {
         uint i = SECOMPILE_CURRENT_TOKEN_INDEX(this);
         struct tok *t;
         rSEVar roldvar, rnewvar;

         secompileAdvancePtr(this);

         /* can't save it above because it can get realloced */
         t = SECOMPILE_TOKEN_BY_INDEX(this,i);
         while( (roldvar=tokGetVar(this,t))->type==VString &&
                tokType(this->token)==seTokConstant &&
                (rnewvar=tokGetVar(this,this->token))->type==VString )
         {
            struct Call *call = this->call;
            wSEVar tmp = STACK_PUSH;

            /* two adjacent strings, concatenate them.
             */
            ConcatenateStrings(this->call,tmp,roldvar,rnewvar);
            SEVAR_CONSTANT_STRING(tmp);

            /* Remove the last two constants which are not needed. They
             * were the strings used to form this new string. We only
             * need the single new string.
             */
            assert( NULL != SEMEMBERS_PTR(this->constMembers) );
            assert( roldvar==&((SEMEMBERS_PTR(this->constMembers)+
                                SEOBJECT_PTR(this->constObj)->used-2)->value) );
            assert( rnewvar==&((SEMEMBERS_PTR(this->constMembers)+
                                SEOBJECT_PTR(this->constObj)->used-1)->value) );

            SEOBJECT_PTR(this->constObj)->used -= 2;


            tokSetVar(t,this,tmp);
            STACK_POP;

            secompileAdvancePtr(this);
            /* Restore t since may have moved */
            t = SECOMPILE_TOKEN_BY_INDEX(this,i);
         }
         secompileAddItem(this,sePushConstant,tokGetVarIndex(t));
         this->expr.type = EXPR_STACKTOP;
         break;
      }
      case seTokVar:
         secompileAdvancePtr(this);
         if( tokType(this->token)!=seTokIdentifier )
         {
            callQuit(this->call,textcoreVAR_NEEDS_VARNAME);
            return False;
         }
         loclAddLocal(this->call,this->locfunc,tokGetName(this->token));
         /* fallthru intentional - 'var x' is the same as 'x' with
          * a little extra which is the item just added
          */
      case seTokIdentifier:
         if( !LOCAL_TEST_IF_INIT_FUNCTION(this->locfunc,this->call) &&
             (this->expr.index = loclFindLocal(this->locfunc,tokGetName(this->token)))!=-1 )
         {
            this->expr.index++;
            this->expr.type = EXPR_LOCAL;
         }
         else if( !LOCAL_TEST_IF_INIT_FUNCTION(this->locfunc,this->call) &&
                  (this->expr.index = loclFindParam(this->locfunc,
                                                    tokGetName(this->token)))!=-1 )
         {
            this->expr.index = (sword16)(-this->expr.index);
            this->expr.type = EXPR_LOCAL;
         }
         else
         {
            this->expr.name = tokGetName(this->token);
            this->expr.type = EXPR_GLOBAL;
         }
         secompileAdvancePtr(this);
         break;
         /* ECMA2.0 */
         /* BeginBlock now signifies the new Object initializers */
      case '{':
         success = secompileObject(this);
         break;
         /* Our old array initializer is the same only with brackets instead */
      case '[':
         success = secompileArray(this,False);
         break;
      default:
         callQuit(this->call,textcoreBAD_PRIMARY);
         success = False;
         break;
   }
   return success;
}


static jsebool NEAR_CALL secompileMemberExpression(struct secompile *this)
{
   setokval t = tokType(this->token);
   jsebool newFunction = False;

   if( t==seTokNew )
   {
      secompileAdvancePtr(this);
      newFunction = True;
   }

   if( !secompilePrimaryExpression(this) ) return False;
   while( (t=tokType(this->token))=='[' || t=='.' || t=='(' )
   {
      if( t=='[' )
      {
         secompileGetValueAsObject(this);
         secompileAdvancePtr(this);
         if( !secompileExpression(this) ) return False;
         if( tokType(this->token)!=']' )
         {
            callQuit(this->call,textcoreMISSING_CLOSE_BRACKET);
            return False;
         }
         secompileGetValue(this);
         this->expr.type = EXPR_ARRAY;
         secompileAdvancePtr(this);
      }
      else if( t=='.' )
      {
         VarName vn;

         secompileAdvancePtr(this);
         secompileGetValueAsObject(this);
         if( tokType(this->token)!=seTokIdentifier ||
             (NULL == (vn = tokGetName(this->token))) )
         {
            callQuit(this->call,textcoreMISSING_PROPERTY_NAME);
            return False;
         }
         this->expr.name = vn;
         this->expr.type = EXPR_MEMBER;
         secompileAdvancePtr(this);
      }
      else
      {
         CONST_TYPE numargs;

         if( this->expr.type==EXPR_MEMBER )
         {
            /* We are about to call a function, so this can't
             * be weird [] stuff, make sure the 'this' object
             * is an object
             */
            secompileAddItem(this,seToObject);
            /* duplicate the object as 'this' */
            secompileAddItem(this,sePushDup);
         }
         else if( this->expr.type==EXPR_ARRAY )
         {
            secompileAddItem(this,seToObjectUnder);
            secompileAddItem(this,sePushDupUnder);
         }
         else if( this->expr.type==EXPR_STACKTOP )
         {
            /* top of stack is expression, we need to
             * get the 'this' (global object) underneath
             * it on the stack.
             */
            secompileAddItem(this,sePushGlobalObject);
            secompileAddItem(this,seSwap);
         }
         else if( this->expr.type==EXPR_GLOBAL )
         {
            secompileAddItem(this,sePushGlobalParam,this->expr.name);
            secompileAddItem(this,seThisAndValue);
            this->expr.type = EXPR_STACKTOP;
         }
         else
         {
            secompileAddItem(this,sePushGlobalObject);
         }
         secompileGetValue(this);
         secompileAdvancePtr(this);
         secompileAddItem(this,newFunction?seToNewFunc:seToCallFunc);
         numargs = secompileFunctionArgs(this);
         if( numargs==(CONST_TYPE)-1 ) return False;
         secompileAddItem(this,newFunction?seNewFunction:seCallFunction,numargs);
         newFunction = False;
         this->expr.type = EXPR_STACKTOP;
      }
   }


   /* This fixes problem when "var a = new foo;", with no function call "()"
    * I'm not sure what the exact behavior is, but this mimics the old behavior
    * (Before the a = foo.bar() bug fix)
    */
   if( newFunction )
   {
      if( this->expr.type==EXPR_MEMBER )
      {
         /* We are about to call a function, so this can't
          * be weird [] stuff, make sure the 'this' object
          * is an object
          */
         secompileAddItem(this,seToObject);
         secompileAddItem(this,sePushDup);
      }
      else if( this->expr.type==EXPR_ARRAY )
      {
         /* ditto */
         secompileAddItem(this,seToObjectUnder);
         secompileAddItem(this,sePushDupUnder);
      }
      else
      {
         secompileAddItem(this,sePushGlobalObject);
      }
      secompileGetValue(this);
      secompileAddItem(this,seToNewFunc);
      secompileAddItem(this,seNewFunction,(CONST_TYPE)0);
   }

   return True;
}


static jsebool NEAR_CALL secompilePostfixExpression(struct secompile *this)
{
   setokval t;

   if( !secompileLeftHandSideExpression(this) ) return False;

   t = tokType(this->token);

   /* do post crement */

   /* handle 'no line terminator here' in the production */
   if( (seTokDecrement==t || seTokIncrement==t)
    && tokType(SECOMPILE_PREV_TOKEN(this))!=seTokEOL )
   {
      int inc = ( seTokIncrement==t ) ? 0 : 1 ;
      switch( this->expr.type )
      {
         case EXPR_LOCAL:
            secompileAddItem(this,sePostIncLocal+inc,this->expr.index,this->with_depth);
            break;
         case EXPR_GLOBAL:
            secompileAddItem(this,sePostIncGlobal+inc,this->expr.name);
            break;
         case EXPR_MEMBER:
            secompileAddItem(this,sePostIncMember+inc,this->expr.name);
            break;
         case EXPR_ARRAY:
            secompileAddItem(this,sePostIncArray+inc);
            break;
         default:
            callQuit(this->call,textcoreNOT_LVALUE);
            return False;
      }
      this->expr.type = EXPR_STACKTOP;
      secompileAdvancePtr(this);
   }

   return True;
}


jsebool NEAR_CALL secompileOperatorExpression(struct secompile *this,
                                              uint orig_priority,jsebool in_allowed)
{
   /* give higher-order operator first chance to compile */
   uint Priority = PRI_UNARY;

   assert( PRI_ASSIGN <= orig_priority  &&  orig_priority <= PRI_UNARY );
   assert( this->expr.type==EXPR_VOID );

 recurse:

   /* Both of these check for unary operators as opposed to binary ones */
   if( Priority==PRI_UNARY && tokType(this->token)=='-' )
   {
      secompileAdvancePtr(this);
      if( !secompileOperatorExpression(this,Priority,in_allowed) ) return False;
      secompileGetValue(this);
      secompileAddItem(this,seNegate);
   }
   else if( Priority==PRI_UNARY && tokType(this->token)=='+' )
   {
      secompileAdvancePtr(this);
      if( !secompileOperatorExpression(this,Priority,in_allowed) ) return False;
      secompileGetValue(this);
      secompileAddItem(this,seToNumber);
   }
   else

   for ( ; ; )
   {
      setokval t;
      struct opDesc *desc;

      /* if the present operator is not of this level then don't compile it */

      t = tokType(this->token);

      if( t==seTokIn && !in_allowed ) break;

      desc = getTokDescription(t);

      if ( Priority != desc->priority )
      {
         if ( PRI_UNARY == Priority && !secompilePostfixExpression(this) )
            return False;
         break;
      }

      switch ( Priority )
      {
         uint ptr,ptr2;


         /* do all the cases that require special-case code */
         case PRI_CONDITIONAL:
            secompileAdvancePtr(this);
            secompileGetValue(this);
            assert( this->expr.type==EXPR_STACKTOP );
            ptr = secompileCurrentItem(this);
            secompileAddItem(this,seGotoFalse,(ADDR_TYPE)0);
            SE_NEW_EXPR(this);
            if( !secompileOperatorExpression(this,PRI_ASSIGN,in_allowed) ) return False;
            secompileGetValue(this);
            if( tokType(this->token)!=':' )
            {
               callQuit(this->call,textcoreCONDITIONAL_MISSING_COLON);
               return False;
            }
            secompileAdvancePtr(this);
            ptr2 = secompileCurrentItem(this);
            secompileAddItem(this,seGoto,(ADDR_TYPE)0);
            secompileGotoHere(this,ptr);
            assert( this->expr.type==EXPR_STACKTOP);
            SE_NEW_EXPR(this);
            if( !secompileOperatorExpression(this,PRI_ASSIGN,in_allowed) )
               return False;
            secompileGetValue(this);
            assert( this->expr.type==EXPR_STACKTOP);
            secompileGotoHere(this,ptr2);
            /* either path leaves us with the value on top of stack */
            break;
         case PRI_LOGICAL_OR:
         case PRI_LOGICAL_AND:
            secompileAdvancePtr(this);
            secompileGetValue(this);
            secompileAddItem(this,sePushDup);
            ptr = secompileCurrentItem(this);
            secompileAddItem(this, seTokLogicalOR == t ? seGotoTrue : seGotoFalse,(ADDR_TYPE)0);
            this->expr.type = EXPR_STACKTOP; /* we had pushed a duplicate */
            secompileDiscard(this);
            if( !secompileOperatorExpression(this,Priority+1,in_allowed) )
               return False;
            secompileGetValue(this);
            secompileGotoHere(this,ptr);
            break;
         case PRI_UNARY:
            secompileAdvancePtr(this);
            if( !secompileOperatorExpression(this,Priority,in_allowed) )
               return False;
            else
            {
               switch( t )
               {
                  case '~':
                     secompileGetValue(this);
                     secompileAddItem(this,seBitNot);
                     this->expr.type = EXPR_STACKTOP;
                     break;
                  case '!':
                     secompileGetValue(this);
                     secompileAddItem(this,seBoolNot);
                     this->expr.type = EXPR_STACKTOP;
                     break;
                  case seTokDelete:
                     if( this->expr.type==EXPR_ARRAY )
                     {
                        secompileAddItem(this,seDeleteArray);
                     }
                     else if( this->expr.type==EXPR_MEMBER )
                     {
                        secompileAddItem(this,seDeleteMember,this->expr.name);
                     }
                     else
                     {
                        /* not a reference, return 'true', 11.4.1 */

                        /* In this case, neither has anything on the stack,
                         * se we don't generate any additional codes. We do
                         * this so that discarding a global doesn't try to
                         * do the 'make sure it exists' check.
                         */
                        if( this->expr.type==EXPR_GLOBAL )
                           this->expr.type = EXPR_VOID;

                        secompileDiscard(this);
                        secompileAddItem(this,sePushTrue);
                     }
                     this->expr.type = EXPR_STACKTOP;
                     break;
                  case seTokVoid:
                     secompileGetValue(this);
                     secompileDiscard(this);
                     secompileAddItem(this,sePushUndefined);
                     this->expr.type = EXPR_STACKTOP;
                     break;
                  case seTokDecrement:
                  case seTokIncrement:
                  {
                     int inc = ( t == seTokIncrement ) ? 0 : 1 ;
                     switch( this->expr.type )
                     {
                        case EXPR_LOCAL:
                           secompileAddItem(this,sePreIncLocal+inc,this->expr.index,
                                            this->with_depth);
                           break;
                        case EXPR_GLOBAL:
                           secompileAddItem(this,sePreIncGlobal+inc,this->expr.name);
                           break;
                        case EXPR_MEMBER:
                           secompileAddItem(this,sePreIncMember+inc,this->expr.name);
                           break;
                        case EXPR_ARRAY:
                           secompileAddItem(this,sePreIncArray+inc);
                           break;
                        default:
                           callQuit(this->call,textcoreNOT_LVALUE);
                           return False;
                     }
                     this->expr.type = EXPR_STACKTOP;
                     break;
                  }
                  case seTokTypeof:
                     if( this->expr.type==EXPR_GLOBAL )
                     {
                        /* must be different to handle the case when
                         * it is undefined, generating a getvalue would
                         * end up spitting out an error.
                         */
                        secompileAddItem(this,seTypeofGlobal,this->expr.name);
                     }
                     else
                     {
                        secompileGetValue(this);
                        secompileAddItem(this,seTypeof);
                     }
                     this->expr.type = EXPR_STACKTOP;
                     break;
                  SEDBG( default: assert( False ); )
               }
            }
            /* unary operators work a bit differently, they parse one thing
             * at their level then jump back up. All the others keep checking
             * the token to see if it is an operator for their level. Later,
             * I'll pull this out and put it at the top of the function.
             */
            goto recurse_out;
         case PRI_ASSIGN:
         {
            struct seExpression save = this->expr;

            if( t!='=' )
            {
               /* Treat 'a X= b' as 'a = a X b' */

               /* we will need the object on the TOS twice */
               secompileGetValueKeep(this);
               secompileAdvancePtr(this);
               SE_NEW_EXPR(this);
               if( !secompileOperatorExpression(this,Priority,in_allowed) )
                  return False;
               secompileGetValue(this);
               secompileAddItem(this,(int)(desc->operator));
            }
            else
            {
               secompileAdvancePtr(this);
               SE_NEW_EXPR(this);
               if( !secompileOperatorExpression(this,Priority,in_allowed) )
                  return False;
               secompileGetValue(this);
            }
            this->expr = save;
            if( !secompilePutValue(this) ) return False;
            break;
         }

         default:
         {
            secompileGetValue(this);
            secompileAdvancePtr(this);
            SE_NEW_EXPR(this);
            if( !secompileOperatorExpression(this,Priority+1,in_allowed) )
               return False;
            secompileGetValue(this);

            /* do some operation */

            assert( desc->operator!=(secodeelem)-1 );
            secompileAddItem(this,(int)(desc->operator));
            assert( this->expr.type==EXPR_STACKTOP );

            break;
         }
      }
   }

 recurse_out:
   if( --Priority<orig_priority ) return True;
   goto recurse;
}


/* The top of the stack is the value to be assigned. In the case
 * of EXPR_MEMBER, the object of which the member being assigned
 * is right underneath it.
 */
   jsebool NEAR_CALL
secompilePutValue(struct secompile *this)
{
   switch( this->expr.type )
   {
      default:
         callQuit(this->call,textcoreNOT_LVALUE);
         return False;
      case EXPR_MEMBER:
         secompileAddItem(this,seAssignMember,this->expr.name);
         break;
      case EXPR_ARRAY:
         secompileAddItem(this,seAssignArray);
         break;
      case EXPR_LOCAL:
         if( this->with_depth )
            secompileAddItem(this,seAssignLocalWith,this->expr.index,this->with_depth);
         else
            secompileAddItem(this,seAssignLocal,this->expr.index);
         break;
      case EXPR_GLOBAL:
         secompileAddItem(this,seAssignGlobal,this->expr.name);
         break;
   }

   /* these operands all leave the assigned value as the result of the
    * expression.
    */
   this->expr.type = EXPR_STACKTOP;
   return True;
}


/* The expression which we have been deferring must now be loaded
 * onto the stack.
 */
   static void NEAR_CALL
secompileGetValueKeep(struct secompile *this)
{
   switch( this->expr.type )
   {
      case EXPR_STACKTOP:
         break;
      default:
         assert( False );
         break;
      case EXPR_CONSTANT:
         secompileAddItem(this,sePushConstant,this->expr.constant);
         break;
      case EXPR_MEMBER:
         secompileAddItem(this,sePushDup);
         secompileAddItem(this,sePushMember,this->expr.name);
         break;
      case EXPR_ARRAY:
         secompileAddItem(this,sePushDup2);
         secompileAddItem(this,sePushArray);
         break;
      case EXPR_LOCAL:
         if( this->with_depth )
            secompileAddItem(this,sePushLocal,this->expr.index);
         else
            secompileAddItem(this,sePushLocalWith,this->expr.index,this->with_depth);
         break;
      case EXPR_GLOBAL:
         secompileAddItem(this,sePushGlobal,this->expr.name);
         break;
   }

   /* it has been pushed to the top of the stack */
   this->expr.type = EXPR_STACKTOP;
}


/* The expression which we have been deferring must now be loaded
 * onto the stack.
 */
   static void NEAR_CALL
secompileGetValueForParam(struct secompile *this,CONST_TYPE arg_num)
{
   jsebool deref = True;

   switch( this->expr.type )
   {
      default:
         assert( False );
         break;

         /* Expression temporaries and constants can never be
          * indirect.
          */
      case EXPR_STACKTOP:
         deref = False;
         break;
      case EXPR_CONSTANT:
         deref = False;
         secompileAddItem(this,sePushConstant,this->expr.constant);
         break;
      case EXPR_MEMBER:
         secompileAddItem(this,sePushMemberParam,this->expr.name);
         break;
      case EXPR_ARRAY:
         secompileAddItem(this,sePushArrayParam);
         break;
      case EXPR_LOCAL:
         secompileAddItem(this,sePushLocalParam,
                          this->expr.index,this->with_depth);
         break;
      case EXPR_GLOBAL:
         secompileAddItem(this,sePushGlobalParam,this->expr.name);
         break;
   }

   if( deref ) secompileAddItem(this,seDereferParam,arg_num);

   /* it has been pushed to the top of the stack */
   this->expr.type = EXPR_STACKTOP;
}


/* The expression which we have been deferring must now be loaded
 * onto the stack.
 */
   void NEAR_CALL
secompileGetValue(struct secompile *this)
{
   switch( this->expr.type )
   {
      case EXPR_STACKTOP:
         break;
      case EXPR_CONSTANT:
         secompileAddItem(this,sePushConstant,this->expr.constant);
         break;
      case EXPR_MEMBER:
         secompileAddItem(this,sePushMember,this->expr.name);
         break;
      case EXPR_ARRAY:
         secompileAddItem(this,sePushArray);
         break;
      case EXPR_LOCAL:
         if( this->with_depth )
            secompileAddItem(this,sePushLocalWith,this->expr.index,this->with_depth);
         else
            secompileAddItem(this,sePushLocal,this->expr.index);
         break;
      case EXPR_GLOBAL:
         secompileAddItem(this,sePushGlobal,this->expr.name);
         break;
      default: assert( False );
   }

   /* it has been pushed to the top of the stack */
   this->expr.type = EXPR_STACKTOP;
}


/* The expression which we have been deferring must now be loaded
 * onto the stack. Autoconvert it to object.
 */
   static void NEAR_CALL
secompileGetValueAsObject(struct secompile *this)
{
   switch( this->expr.type )
   {
      case EXPR_STACKTOP:
         break;
      default:
         assert( False );
         break;
      case EXPR_CONSTANT:
         secompileAddItem(this,sePushConstant,this->expr.constant);
         break;
      case EXPR_MEMBER:
         secompileAddItem(this,sePushMemberAsObject,this->expr.name);
         break;
      case EXPR_ARRAY:
         secompileAddItem(this,sePushArrayAsObject);
         break;
      case EXPR_LOCAL:
         secompileAddItem(this,sePushLocalAsObject,this->expr.index,this->with_depth);
         break;
      case EXPR_GLOBAL:
         secompileAddItem(this,sePushGlobalAsObject,this->expr.name);
         break;
   }

   /* it has been pushed to the top of the stack */
   this->expr.type = EXPR_STACKTOP;
}


   void NEAR_CALL
secompileDiscard(struct secompile *this)
{
   /* NYI: We need this to make eval("a") return 'a's value.
    * Make peephole optimizations instead of trying to be
    * clever here. I've left the old code in for now,
    * #if'd out.
    */
   if( this->expr.type!=EXPR_VOID )
   {
      secompileGetValue(this);
      secompileAddItem(this,sePopDiscard);
   }

#  if 0
   if( this->expr.type==EXPR_MEMBER || this->expr.type==EXPR_STACKTOP )
   {
      secompileAddItem(this,sePopDiscard);
   }
   else if( this->expr.type==EXPR_ARRAY )
   {
      secompileAddItem(this,sePopDiscard);
      secompileAddItem(this,sePopDiscard);
   }
   else if( this->expr.type==EXPR_GLOBAL )
   {
      /* make sure not undefined */
      secompileAddItem(this,seCheckGlobal,this->expr.name);
   }
#  endif

   SE_NEW_EXPR(this);
}


   jsebool NEAR_CALL
secompileExpressionEx(struct secompile *this,jsebool in_allowed)
{
   SE_NEW_EXPR(this);

   if( !secompileOperatorExpression(this,PRI_ASSIGN,in_allowed) ) return False;

   while( tokType(this->token)==',' )
   {
      if( this->expr.type==EXPR_MEMBER ||
          this->expr.type==EXPR_ARRAY )
      {
         /* could be dynamic get so we have to do it, sigh. */
         secompileGetValue(this);
         secompileDiscard(this);
      }
      else if( this->expr.type==EXPR_GLOBAL )
      {
         /* make sure not undefined */
         secompileAddItem(this,seCheckGlobal,this->expr.name);
      }
      else if( this->expr.type==EXPR_STACKTOP )
      {
         secompileAddItem(this,sePopDiscard);
      }
      secompileAdvancePtr(this);
      this->expr.type = EXPR_VOID;
      if( !secompileOperatorExpression(this,PRI_ASSIGN,in_allowed) ) return False;
   }
   return True;
}

#endif /* #if (0!=JSE_COMPILER) */
