/* secode.h   Defines to use the secode compiler
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

#ifndef SECODE_H
#define SECODE_H

/* SE430:
 *
 * SECodes have changed somewhat. There are 'seTokCode' and 'seCode'.
 * The first is the list of tokens. The second is the list of opcodes
 * generated from those tokens. They are not interrelated. This was
 * a bad historic decision, making changes difficult and annoying
 * to implement. We undo it now.
 */

/* ---------------------------------------------------------------------- */

#if defined(__cplusplus)
   extern "C" {
#endif

typedef uword8 setokval;

/* NOTE: for all single-character tokens, the type is the same as the
 *       character. We reserve 0-127 for those. I.e. ')' is ')'
 */

#define seTokUnknown          128

#define seTokFilename         129
#define seTokLineNumber       130


#define seTokConstant         131
#define seTokIdentifier       132

#define seTokEqual            133
#define seTokStrictEqual      134
#define seTokNotEqual         135


#define seTokDecrement        136 /* dec even */
#define seTokIncrement        137 /* inc odd  = dec + 1 */

#define seTokShiftLeft        138
#define seTokUnsignedShiftRight 139
#define seTokSignedShiftRight 140

#define seTokLogicalAND       141
#define seTokLogicalOR        142


#define seTokTimesEqual       143
#define seTokDivEqual         144
#define seTokModEqual         145
#define seTokPlusEqual        146
#define seTokMinusEqual       147
#define seTokShiftLeftEqual   148
#define seTokSignedShiftRightEqual 149
#define seTokUnsignedShiftRightEqual 150
#define seTokAndEqual         151
#define seTokXorEqual         152
#define seTokOrEqual          153
#define seTokLessEqual        154
#define seTokGreaterEqual     155
#define seTokStrictNotEqual   156

/* keywords */

#define seTokIf               159
#define seTokElse             160
#define seTokDo               161
#define seTokWhile            162
#define seTokVar              163
#define seTokFor              164
#define seTokIn               165
#define seTokSwitch           166
#define seTokDefault          167
#define seTokCase             168
#define seTokWith             169
#define seTokTry              170
#define seTokCatch            171
#define seTokFinally          172
#define seTokBreak            173
#define seTokContinue         174
#define seTokReturn           175
#define seTokThrow            176
#define seTokFunction         177
#define seTokCFunction        178
#define seTokGoto             179
#define seTokDelete           180
#define seTokTypeof           181
#define seTokInstanceof       182
#define seTokThis             183
#define seTokFalse            184
#define seTokTrue             185
#define seTokNull             186
#define seTokVoid             187
#define seTokNew              188

#define seTokEOL              189
#define seTokEOF              190


/* ---------------------------------------------------------------------- */

/* try/catch/finally handling notes:
 *
 *
 * Let's start with the finally stuff. Although both catch
 * and finally are part of the same statement, they are
 * actually independent in what they do in a program.
 *
 * A finally block simply says that control cannot leave
 * the 'try' portion without executing the finally block.
 * This allows a program to guarantee cleanup, for instance.
 * Even if the program tries to do a 'return', a break,
 * a continue, a goto, or has an error, the finally portion
 * gets executed first. After the finally code is done,
 * whatever was going to happen is done. However, if the
 * finally code itself does such a thing, it takes
 * precedence. We only do the original if the finally
 * statements don't do such. Consider:
 *
 *    try
 *    {
 *       return 10;
 *    }
 *    finally
 *    {
 *       a = 4;
 *    }
 *
 * This returns the value 10. The finally code is executed
 * but since it just 'falls off the end', we go back and
 * actually do the return which was waiting. Note that if
 * the 'try' portion simply falls off the end of its code,
 * the finally is still executed before continuing with
 * the rest of the program. Now consider:
 *
 *    try
 *    {
 *       return 10;
 *    }
 *    finally
 *    {
 *       return 5;
 *    }
 *
 * In this case, the value 5 is returned. The 'return' in
 * the try block was pending, but the finally return takes
 * precedence. Understand that all 'unusual' methods of
 * leaving the block can be overwritten. In this case:
 *
 *    try
 *    {
 *       return 10;
 *    }
 *    finally
 *    {
 *       goto somewhere;
 *    }
 *
 * In this case, the function doesn't return at all. We were
 * ready to return, but the finally code takes precedence, so
 * instead we 'goto somewhere;'.
 *
 * This is implemented by a few opcodes. We use 'startTry'
 * 'endTry', and 'finallyTry' to block of a set of opcodes
 * that is 'protected' by a finally block, and make sure it
 * gets executed. Also, note that 'with' uses the same
 * mechanism. That's because 'with' adds an item to the
 * scope chain which has to be guaranteed to be removed
 * in the same way a finally block is guaranteed to be
 * executed. The simplest way, rather than rewriting the
 * same code, is to reuse it; when we enter a 'with' block,
 * we set up a finally section for that code that removes
 * the item from the scope chain.
 *
 *
 * catch handling. Note that catch handling is considered to
 * be 'inside' the try block. I mean by that if an error occurs,
 * and it is caught, that doesn't trigger any finally blocks
 * yet. When the catch handler is done with it, whatever it
 * does will be the last thing done in that block. Thus, if
 * there is a finally protecting it, that now gets triggered,
 * and the results of the catch block is used assuming the
 * finally does not override it.
 *
 * Like the try block, we use the 'catchTry' statement to
 * say that there is a catch handler in effect for the
 * range of opcodes. Should an error (or throw) occur in
 * that section, rather than aborting with an error, we
 * transfer control catch handler, and give it the error
 * clause. However the catch handler ends is what we do,
 * i.e. it can 'return' or 'goto' or just fall off the end
 * of its code. In any case, the error is considered handled
 * and execution continues. However, the catch handler can
 * 'throw' the error, which makes it reappear. Since that
 * catch handler is done, the error will continue on. It will
 * cause the program to abort, assuming some outer level
 * catch handler doesn't catch it. So for instance, we
 * could code:
 *
 *    var fp = Clib.fopen("foo.out","w");
 *    if( fp==null ) throw new Error("That really sucks!");
 *    try
 *    {
 *       * do some stuff with the file
 *       ...
 *    }
 *    catch( e )
 *    {
 *       * log the error
 *       log_error(e);
 *
 *       * however, there still was an error, and we
 *       * don't want to get rid of it, just note it
 *       throw e;
 *    }
 *    finally
 *    {
 *       * no matter what happens, close the file
 *       Clib.fclose(fp);
 *    }
 *
 * This code will make sure the file is always closed,
 * and log any error, but the error will still abort
 * the program. The above discussion should make it clear
 * what is going on. You may want to define SECODE_LISTINGS
 * and rebuild the core, to see what opcodes get output
 * so you can see how this is implemented under the hood.
 */


typedef sword8 secodeval;

/* ----------------------------------------------------------------------
 * SE430 secodes
 *
 * Secodes are now stored in an array of bytes. Each item needed
 * is extracted from the current pointer as its type (i.e. if
 * it is a 4 byte value, the byte pointer is cast to that type
 * and incremented, meaning the 4 bytes are skipped.) For systems
 * that need data aligned, a helper is called for values >1 byte
 * to grab the data a byte at a time.
 */

/* The first few functions deal with local variables/parameters.
 * The first extension is which local variable we are dealing
 * with. Indexes >=1 are for locals, indexes <=0 are for
 * parameters.
 *
 * The second parameter is a ubyte, the current with depth.
 */

#define SE_START_LOCAL_CODES  1
   /* these map with SE_START_GLOBAL_CODES except they have an extra code at
    * the beginning and at the end
    */
#define sePushLocalWith         SE_START_LOCAL_CODES
   /* Push the local. There is an optimized instruction for when
    * the with depth is 0.
    */
#define sePushLocalAsObject     2
   /* Push a local, but autoconvert it to an object if it is not first */
#define sePushLocalParam        3
   /* Push a local, but put a reference to it. This is for when the
    * local will be a parameter to a function, which may be a
    * pass-by-reference parameter. This can not be known until
    * runtime (unfortunately.)
    */
#define sePreIncLocal           4
#define sePreDecLocal           5
#define sePostIncLocal          6
#define sePostDecLocal          7
   /* standard crement ops for local variables */
#define seIncOnlyLocal          8
#define seDecOnlyLocal          9
   /* when the result is not used, i.e. "a++;" */
#define seAssignLocalWith       10
   /* Assign top of stack to the local, keep tos the same */
#define SE_END_LOCAL_CODES  seAssignLocalWith


#define SE_CONST_TYPE_EXT       11
   /* we define a few boundaries so we can easily figure out which
    * cast to use
    */
#define seContinueFunc          SE_CONST_TYPE_EXT
   /* Call the continue function. Instruction includes linenumber
    * as it almost always is followed by a change in linenumber,
    * so we merge the info rather than having a separate
    * seLineNumber opcode. We currently support only 32K
    * lines per file.
    */
#define seLineNumber            12
   /* Not used when executing, used when finding source location */
#define sePushConstant          13
   /* Push the given indexed constant. Constants are stored
    * per function and referred to by index. A max of 32K constants
    * per function.
    */
#define seDereferParam          14
   /* The extension is the parameter number, i.e. 0th parameter,
    * first, etc. This determines at runtime if this is a
    * value or reference param, and adjusts it as needed.
    */
#define seNewFunction           15
#define seCallFunction          16
   /* The extension is the number of parameters to the function */



#define SE_VAR_INDEX_TYPE_EXT          17

#define sePushLocal             SE_VAR_INDEX_TYPE_EXT
   /* Push a local (see above), with no with depth (it is 0.) */
#define seAssignLocal           18
   /* Assign to a local leaving TOS alone, no with */
#define seAssignLocalPop        19
   /* Assign to local but then pop TOS, this is more common.
    * Basically, if you do "a = (b = 5);", then the top
    * one gets used, if you just do "a = 5;", then this
    * will be the one optimized in.
    */

#define SE_ADDR_TYPE_EXT    20
   /* For all goto codes, the offset into the bytecodes that
    * we are targeting. Note that for certain instructions,
    * (uword32)(-1) is a special marker. Big functions
    * can use more than 32K of bytecodes, unfortunately,
    * so must be 4 bytes
    */
#define seStartTry              SE_ADDR_TYPE_EXT
#define SE_START_GOTO_CODES     seStartTry
#define seCatchTry              21
#define seFinallyTry            22
   /* Try/catch/finally handling opcodes */
#define seGoto                  23
   /* always goto the given instruction */
#define seTransfer              24
   /* goto a given instruction, but possibly could trigger
    * a finally handler, so more checks needed.
    */
#define seGotoForIn             25
   /* 2 items on stack, -2=base object, -1=current object/mem as ref index
    *
    * On exit, it pushes the next member's property name,
    * else goes to the given address (with the two items on the
    * stack.) It cannot remove the two items, as the exit address
    * is the same as the break address, and both must cleanup.
    */
#define seGotoFalse             26
#define seGotoTrue              27
   /* Both convert the TOS to a boolean and goto if the indicated condition
    * is met. The TOS is discarded.
    */
#define SE_END_GOTO_CODES       seGotoTrue



#define SE_VARNAME_EXT          28
   /* These opcodes take a VarName as their extension */
#define seFilename              SE_VARNAME_EXT
   /* When filename changes, for source location reporting */
#define sePushMember            29
   /* The TOS is the object, push the given member in its place */
#define sePushMemberParam       30
   /* The TOS is the object, push a reference to the given member in its place */
#define sePushMemberAsObject    31
   /* Like sePushMember but autoconvert to object first. */
#define seDeleteMember          32
   /* Delete the given member of the TOS, replace TOS with
    * true/false according to ECMA rules
    */
#define seAssignMember          33
   /* The TOS is a value, the TOS-1 is an object. Assign the value
    * to the given member of that object. Get rid of the object from
    * the stack, but the TOS remain TOS
    */
#define sePreIncMember          34
#define sePreDecMember          35
#define sePostIncMember         36
#define sePostDecMember         37

#define SE_START_GLOBAL_CODES  38
   /* crement operators for object members */
#define seCheckGlobal           SE_START_GLOBAL_CODES
   /* ensure global is defined */
#define sePushGlobal            39
   /* push a global */
#define sePushGlobalAsObject    40
   /* push a global, but auto-convert to object first */
#define sePushGlobalParam       41
   /* push reference to global */
#define sePreIncGlobal          42
#define sePreDecGlobal          43
#define sePostIncGlobal         44
#define sePostDecGlobal         45
   /* crement ops on global variables */
#define SE_GLOBAL_NOTDIRECTXLAT 46
#define seAssignGlobal          SE_GLOBAL_NOTDIRECTXLAT
   /* assign TOS to given global, leaving it on stack as well. */
#define seTypeofGlobal          47
   /* Push the type of the global */
#define SE_END_GLOBAL_CODES    seTypeofGlobal

#define seStartCatch            48
   /* first instruction in a catch handler, tell it what name
    * to give the error
    */


/* The rest of the opcodes take no extension data */
#define SE_NO_EXT               49
#define sePopDiscard            SE_NO_EXT

   /* Simply get rid of the top element of the stack */
#define sePushUndefined         50
#define sePushFalse             51
#define sePushTrue              52
#define sePushNull              53
   /* Push the various constants */
#define sePushThis              54
   /* Push the current this variable */
#define sePushGlobalObject      55
   /* Push the current global object */
#define sePushNewObject         56
   /* Create and push a blank object */
#define sePushNewArray          57
   /* Create and push an ECMA array object */
#define sePushArray             58
   /* Push the Array member (obj,index on stack). get rid of both*/
#define sePushArrayParam        59
#define sePushArrayAsObject     60
   /* same as sePushArray, but auto-convert the member to an object
    * first if it is undefined. -> This is for "var a.b = 10;", etc.
    */
#define seDeleteArray           61
   /* delete the member of obj at TOS-2 given be TOS-1, get rid
    * of both, put the true or false on stack.
    */
#define seAssignArray           62
/* wow, three items on stack, the object, the member, and the assign
 * value
 */
#define seTypeof                63
#define sePreIncArray           64
#define sePreDecArray           65
#define sePostIncArray          66
#define sePostDecArray          67
#define sePushDup               68
   /* duplicate top of stack */
#define sePushDup2              69
   /* duplicate the top 2 members of the stack in the same order */
#define sePushDupUnder          70
   /* duplicate the second item on the stack, i.e.:
    *
    *   stack[0], stack[-1]                becomes
    *   stack[0], stack[-1], stack[-1]
    */
#define seSwap                  71
   /* Swap the top two items on the stack */
#define seToNumber              72
   /* turn the top of the stack into a number using stock ecma rules */
#define seToObject              73
   /* turn the top of the stack into an object using stock ecma rules */
#define seToObjectUnder         74
   /* do the same but to the item just under top of stack */
#define seToCallFunc            75
   /* turn the top of the stack to a call function using stock ecma rules */
#define seToNewFunc             76
   /* turn the top of the stack to a new function using stock ecma rules */
#define seScopeAdd              77
#define seScopeRemove           78
   /* add/remove an item to the scope chain */
#define seEndTry                79
#define seEndCatch              80
#define seReturn                81
   /* return top item of stack */
#define seReturnThrow           82
   /* return top item of stack, signal error */
#define seNegate                83
#define seBoolNot               84
#define seBitNot                85
#define seInstanceof            86
#define seIn                    87
#define seEqual                 88
#define seNotEqual              89
#define seStrictEqual           90
#define seStrictNotEqual        91
#define seLess                  92
#define seGreaterEqual          93
#define seGreater               94
#define seLessEqual             95
#define seSubtract              96
#define seAdd                   97
#define seMultiply              98
#define seDivide                99
#define seModulo                100

#define BEGIN_SEOP_32BITS       101
   /* define used when executing secodes */
#define seShiftLeft             BEGIN_SEOP_32BITS
#define seSignedShiftRight      102
#define seUnsignedShiftRight    103
#define seBitOr                 104
#define seBitXor                105
#define seBitAnd                106
#define END_SEOP_32BITS         seBitAnd
#define seThisAndValue          107
#define NUM_SECODES             108


#define SECODE_DELETE_OPCODES(o) jseMustFree(o)



#if defined(JSE_PACK_SECODES) && (JSE_PACK_SECODES==1)
   typedef ubyte secodeelem;
#  define SECODE_DATUM_SIZE(c) (secodeData[c].size0+secodeData[c].size1)

#  define SECODE_GET_ONLY(ops,type) (*((type *)(ops)))
#  define SECODE_GET(ops,type) (*(*((type **)(&(ops))))++)
#  define IPTR_GET(type) SECODE_GET(IPTR,type)
#  define SECODE_PUT_ONLY(addr,type,val) (*(type *)(addr) = val)
#  define SECODE_PUT(sc,type,val) ((*(type *)(sc->opcodes + sc->opcodesUsed) = val),(sc->opcodesUsed)+=sizeof(type))
#  define SECODE_MAX_EXTRAS       8
      /* maximum extra bytes attached */

#  define VAR_INDEX_TYPE sword16
#  define CONST_TYPE     uint
#  define ADDR_TYPE      uword32
#  define WITH_TYPE      ubyte

#else
   typedef uword32 secodeelem;

#  define SECODE_DATUM_SIZE(c) (((c)<SE_CONST_TYPE_EXT)?2:((c)<SE_NO_EXT)?1:0)
#  define SECODE_GET_ONLY(ops,type) ((type)(*(ops)))
#  define SECODE_GET(ops,type) ((type)(*(ops++)))
#  define IPTR_GET(type) SECODE_GET(IPTR,type)
#  define SECODE_PUT_ONLY(addr,type,val) (*(addr) = (secodeelem)(val))
#  define SECODE_PUT(sc,type,val) (sc->opcodes[sc->opcodesUsed++] = (secodeelem)val)
#  define SECODE_MAX_EXTRAS       2

#  define VAR_INDEX_TYPE sint
#  define CONST_TYPE     uint
#  define ADDR_TYPE      uint
#  define WITH_TYPE      uint

#endif

typedef JSE_MEMEXT_R secodeelem *secode;
typedef secodeelem *secode_w;

/* ---------------------------------------------------------------------- */

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
typedef struct secodeInstrInfo
{
#  ifdef SECODE_LISTINGS
   char *name;             /* for outputting listings, not needed to be Unicode */
#  endif

   ubyte size0,size1;
}t_secodeInstrInfo;


#ifdef SECODE_LISTINGS
#  define SECODE_STR(x) (x),
#else
#  define SECODE_STR(x)
#endif
DECLARE_LARGE_STATIC_ARRAY('SC',t_secodeInstrInfo,secodeData,NUM_SECODES);

/* ---------------------------------------------------------------------- */

struct secompile;


/* For Geos, we have to give this type a name to avoid confusing Glue
 * when it tries to create symbol imformation.
 */
enum jseExprType
{
  EXPR_VOID,        /* nothing has yet been done */

  EXPR_CONSTANT,    /* a constant in the function's table */
  EXPR_MEMBER,      /* a member of the object at top of stack */
  EXPR_ARRAY,       /* an array reference-type member, 2 items on stack */
  EXPR_LOCAL,       /* a local variable or parameter */
  EXPR_GLOBAL,      /* a non-local variable (i.e. something on
                     * the scope chain.)
                     */
  EXPR_STACKTOP     /* the value at the top of the stack */
};
 
/* This structure is only used at compile-time, so having a few
 * members that can be merged is no big deal. Clarity is worth
 * a few 'wasted' bytes.
 */
struct seExpression
{
   enum jseExprType type;

   uword16 constant;    /* an index into the table of constants
                         * in the function.
                         */

   sword16 index;       /* a local variable or parameter, parameters
                         * are 0, -1, -2, etc and locals are 1, 2, 3, etc.
                         *
                         * This works out pretty well. To computer a
                         * local's offset, is is FRAMEPTR+1+local offset
                         * (from 0), so the '+1' is already automatically
                         * there, which slightly speeds local variable
                         * access - every little bit helps
                         */

   VarName name;        /* if it is a global variable or a member */
};
typedef struct seExpression *seExpression;

#define SE_NEW_EXPR(this) (this->expr.type = EXPR_VOID)

struct loopTracker
{
   /* it can track loop 'breaks'/'continues' which may require multiple
    * levels of these things. This points back to the last level
    */
   struct loopTracker *next;

   /* We store the address of the goto for the 'breaks' and 'continues'
    * when the loop is done, go back and patch all of these.
    */
   uint breaksUsed,breaksAlloced;
   uint continuesUsed,continuesAlloced;
   uint *breaks,*continues;
};


struct gotoItem
{
   uint sptr;
   VarName label;

   /* In the case we are labelling a loop */
   struct loopTracker *loop;
};


struct gotoTracker
{
   uint gotosUsed,gotosAlloced;
   uint labelsUsed,labelsAlloced;
   struct gotoItem *gotos,*labels;
};


struct secompile
{
   struct Call *call; /* the call initialized in secompileCompile */
   struct LocalFunction *locfunc;
   wSEObject constObj;   /* the current local constant object being created */
   wSEMembers constMembers; /* the current members of the current object */
   secode_w opcodes;
   uint   opcodesUsed,opcodesAlloced;

   /* points to the last token in the local function */
   struct tok *token;

   /* tracks the current expression */
   struct seExpression expr;

   uint prevLineNumber; /* keep track whenever line number changes */
   /* used for initial optimization, such as concatenating lines. If an operator
    * should prevent such optimization this will be set to NULL (for example,
    * this starts as NULL and a label will set it to NULL, otherwise it is
    * set with each operator
    */

   struct gotoItem *looplabel;
   struct loopTracker *loopTrack;
   struct gotoTracker *gotoTrack;
   ubyte with_depth;

   jsebool NowCompiling;
   /* True if compiling; False if playing-back precompiled stuff */
};


#define SECOMPILE_NEW_TOKEN(t) LOCL_NEW_TOKEN((t)->locfunc)
#define SECOMPILE_CURRENT_TOKEN_INDEX(t) LOCL_CURRENT_TOKEN_INDEX((t)->locfunc)
#define SECOMPILE_TOKEN_BY_INDEX(t,i) LOCL_TOKEN((t)->locfunc,(i))
#define SECOMPILE_CURRENT_TOKEN(t) LOCL_CURRENT_TOKEN((t)->locfunc)
#define SECOMPILE_FREE_TOKENS(t,i) LOCL_DELETE_TOKENS((t)->locfunc,i)
#define SECOMPILE_PREV_TOKEN(t) LOCL_PREV_TOKEN((t)->locfunc)


   void NEAR_CALL_CFUNC
secompileAddItem(struct secompile *handle,int/*codeval*/ code,...);
   void NEAR_CALL
secompileFixupGotoItem(struct secompile *This,ADDR_TYPE item,ADDR_TYPE newdest);
#define secompileGotoHere(t,i) secompileFixupGotoItem((t),(i),\
                                  secompileCurrentItem(t))


#  define secompileCurrentItem(this) ((this)->opcodesUsed)

jsebool NEAR_CALL secompileAddBreak(struct secompile *handle,struct loopTracker *it);
jsebool NEAR_CALL secompileAddContinue(struct secompile *handle,struct loopTracker *it);
jsebool NEAR_CALL secompileAddLabel(struct secompile *handle,VarName label);
jsebool NEAR_CALL secompileAddGoto(struct secompile *handle,VarName label);



jsebool NEAR_CALL secompileExpressionEx(struct secompile *handle,jsebool in_allowed);
#  define secompileExpression(h) secompileExpressionEx((h),True)
#  define secompileExpressionNoIn(h) secompileExpressionEx((h),False)

jsebool NEAR_CALL secompileOperatorExpression(struct secompile *handle,
                                              uint Priority,jsebool in_allowed);
jsebool NEAR_CALL secompileStatement(struct secompile *handle);



   void NEAR_CALL
secompileDiscard(struct secompile *this);
   void NEAR_CALL
secompileGetValue(struct secompile *this);
   jsebool NEAR_CALL
secompilePutValue(struct secompile *this);
   jsebool NEAR_CALL
secompileFunction(struct secompile *this,jsebool literal);
   jsebool
secompileFunctionBody(struct LocalFunction *locfunc,struct Call *c,
                      jsebool init_func,struct tok *token);

   struct tok * NEAR_CALL
secompileAdvancePtr(struct secompile *handle);

   jsebool NEAR_CALL
secompileNewLoop(struct secompile *handle,struct gotoItem *label);
void NEAR_CALL secompileEndLoop(struct secompile *handle,
                                ADDR_TYPE break_address,ADDR_TYPE continue_address,
                                struct gotoItem *label);


   jsebool NEAR_CALL
secodeInterpret(struct Call *call);

   void NEAR_CALL
secodeListing(struct secompile *this);

#if defined(__cplusplus)
   }
#endif

#endif
