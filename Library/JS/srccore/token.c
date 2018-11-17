/* token.c -  Code for reading or writing (to/from memory) okenized jse.
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

#if ( defined(JSE_TOKENSRC) && (0!=JSE_TOKENSRC) ) \
 || ( defined(JSE_TOKENDST) && (0!=JSE_TOKENDST) )
/* *****************************************************************
 * ******************** TOKEN STRING STUFF *************************
 * ***************************************************************** */

   static void NEAR_CALL
tokenInit(struct Token *This)
{
   This->StringCount = 0;
   This->StringTable = jseMustMalloc(VarName,sizeof(VarName));
}

   static void NEAR_CALL
tokenTerm(struct Token *this)
{
   jseMustFree(this->StringTable);
}

#if (defined(JSE_TOKENSRC) && (0!=JSE_TOKENSRC))  ||  !defined(NDEBUG)
   static uint NEAR_CALL
tokenFindString(struct Token *this,VarName str)
   /* return 0 if not found, else index for string */
{
   uint i;

   assert( NULL != str );
   for ( i = 0; i < this->StringCount; i++ )
   {
      if ( str == this->StringTable[i] )
         return i + 1;
   }
   return 0;   /* 0 indicates it wasn't found */
}
#endif

   static void NEAR_CALL
tokenPutString(struct Token *this,VarName str)
   /* add string (assume not already there)
    * caller must have allocated; this will free
    */
{
   assert( NULL != str );
   assert( 0 == tokenFindString(this,str) );
   this->StringTable = jseMustReMalloc(VarName,this->StringTable,
                 (this->StringCount+1)*sizeof(this->StringTable[0]));
   this->StringTable[this->StringCount++] = str;
}

/*******************************************************************
 ************************* JSE_TOKENSRC ****************************
 ****************************************************************** */
#if defined(JSE_TOKENSRC) && (0!=JSE_TOKENSRC)

   static void NEAR_CALL
tokensrcInit(struct TokenSrc *This)
{
   This->TokenMemSize = 0;
   This->TokenMem = jseMustMalloc(void,1);
   tokenInit(&(This->token));
}

   static void NEAR_CALL
tokensrcTerm(struct TokenSrc *This)
{
   tokenTerm(&(This->token));
   if( This->TokenMem!=NULL )
      jseMustFree(This->TokenMem);
}

   void *
CompileIntoTokens(struct Call *call,
                  const jsecharptr CommandString,jsebool FileSpec
                  /*else CommandString is text*/,
                  uint *BufferLen)
{
   void * TokenBuf = NULL;
   jsecharptr Source = StrCpyMalloc(CommandString);

   if ( CompileFromText(call,&Source,FileSpec) )
   {
      struct TokenSrc tSrc;
      tokensrcInit(&tSrc);
#     if defined(JSE_LINK) && (0!=JSE_LINK)
         assert( NULL != call->ExtensionLib );
         extensionTokenWrite(call->ExtensionLib,call,&tSrc);
#     else
         tokenWriteByte(&tSrc,0); /* store no extension libraries */
#     endif

      /* write out all of the local functions */
      tokenWriteAllLocalFunctions(&tSrc,call);

      /* end with code to show we're all finished */
      tokenWriteCode(&tSrc,(uword8)ALL_DONE_BYE_BYE);

      TokenBuf = tSrc.TokenMem;
      tSrc.TokenMem = NULL;

      assert( NULL != TokenBuf );
      *BufferLen = tSrc.TokenMemSize;
      tokensrcTerm(&tSrc);
   } /* endif */
   jseMustFree(Source);
   return TokenBuf;
}


   static void NEAR_CALL
tokenWriteBuffer(struct TokenSrc *this,const void *buf,uint ByteCount)
{
   if ( 0 != ByteCount ) {
      this->TokenMem =
         jseMustReMalloc(void,this->TokenMem,ByteCount+this->TokenMemSize);
      memcpy((ubyte *)(this->TokenMem)+this->TokenMemSize,buf,ByteCount);
      this->TokenMemSize += ByteCount;
   } /* endif */
}

   void
tokenWriteByte(struct TokenSrc *this,uword8 data)
{
   tokenWriteBuffer(this,&data,1);
}

#if SE_BIG_ENDIAN==True
   void NEAR_CALL
tokenWriteNumericDatum(struct TokenSrc *this,
                       void * datum,uint datumlen)
{
   uword8 buffer[20];
   int i;
   assert( datumlen < sizeof(buffer) );
   for ( i = 0; i < datumlen; i++ ) {
      buffer[i] = ((uword8 *)datum)[datumlen - i - 1];
   } /* endfor */
   tokenWriteBuffer(this,buffer,datumlen);
}
#endif

   void
tokenWriteNumber(struct TokenSrc *this,jsenumber n)
{
   /* try to write in a 32, 16, or 8-bit form if possible */
   sword32 n32 = JSE_FP_CAST_TO_SLONG(n);
   if ( JSE_FP_EQ(JSE_FP_CAST_FROM_SLONG(n32),n) )
   {
      tokenWriteLong(this,n32);
   } else {
      /* cannot write as a shorter form; write the entire number */
      tokenWriteByte(this,0);
      tokenWriteNumericDatum(this,&n,sizeof(n));
   } /* endif */
}

   void
tokenWriteLong(struct TokenSrc *this,sword32 n32)
{
   sword16 n16 = (sword16)n32;
   if ( (sword32)n16 == n32 ) {
      sword8 n8 = (sword8)n16;
      if ( (sword16)n8 == n16 ) {
         /* write as 8-bit number */
         tokenWriteByte(this,8);
         tokenWriteByte(this,(ubyte)n8);
      } else {
         /* write as 16-bit number */
         tokenWriteByte(this,16);
         tokenWriteNumericDatum(this,&n16,sizeof(n16));
      } /* endif */
   } else {
      /* write as 32-bit number */
      tokenWriteByte(this,32);
      tokenWriteNumericDatum(this,&n32,sizeof(n32));
   } /* endif */
}

   void
tokenWriteString(struct Call *call,struct TokenSrc *this,VarName string)
{
   uint StringIndex;

   StringIndex = tokenFindString(&(this->token),string);
   if ( 0 == StringIndex )
   {
      stringLengthType len;
      const jsecharptr str = GetStringTableEntry(call,string,&len);

      /* to handle unicode/ascii translation, both system will print
       * number of pure ascii characters, followed by pure unicode,
       * followed by pure ascii, etc.. until len bytes written.
       * for MBCS this turns into how many pure ascii followed by
       * how many MBCS.  Note that even if we're doing MBCS the
       * characters are written like they are UNICODE.
       */
#     if (defined(JSE_UNICODE) && (0!=JSE_UNICODE)) \
      || (defined(JSE_MBCS) && (0!=JSE_MBCS))
      {
         jsecharptr cptr;
         jsechar c;
         stringLengthType i;

         for ( i = 0, cptr = (jsecharptr)str; i < len; i++, JSECHARPTR_INC(cptr) )
         {
            c = JSECHARPTR_GETC(cptr);
#           if defined(JSE_UNICODE) && (0!=JSE_UNICODE)
               if ( 255 < c )
#           else
               if ( 1 != sizeof_jsechar(c) )
#           endif
                  break;
         }
         if ( i < len )
         {
            /* this string contains some unicode or mbcs */
            tokenWriteCode(this,(uword8)NEW_STRING_UNICODE);
            tokenWriteLong(this,len);
            for ( i = 0, cptr = (jsecharptr)str; i < len; i++, JSECHARPTR_INC(cptr) )
            {
               c = JSECHARPTR_GETC(cptr);
               tokenWriteByte(this,(uword8)(c & 0xff) );
               tokenWriteByte(this,(uword8)((c >> 8) & 0xff) );
            }
         }
         else
         {
            /* this string contains no unicode, save space by writing ascii */
            tokenWriteCode(this,(uword8)NEW_STRING_ASCII);
            tokenWriteLong(this,len);
            for ( i = 0, cptr = (jsecharptr)str; i < len; i++, JSECHARPTR_INC(cptr) )
            {
               c = JSECHARPTR_GETC(cptr);
               tokenWriteByte(this,(uword8)(c));
            }
         }
      }
#     else
         /* unicode not supported.  Pure buffer write. */
         tokenWriteCode(this,(uword8)NEW_STRING_ASCII);
         tokenWriteLong(this,(slong)len);
         tokenWriteBuffer(this,str,(uint)len);
#     endif
      /* add string to our list of already-written strings */
      tokenPutString(&(this->token),string);
   } else {
      /* string is already in the table, so just write its index */
      tokenWriteCode(this,(uword8)OLD_STRING);
      tokenWriteLong(this,(slong)StringIndex);
   }
}

#endif

/* *****************************************************************
 * ************************ JSE_TOKENDST ***************************
 * ***************************************************************** */
#if defined(JSE_TOKENDST) && (0!=JSE_TOKENDST)

static void NEAR_CALL
tokendstInit(struct TokenDst *This,const void *mem)
{
   This->TokenMem = mem;
   tokenInit(&(This->token));
}

   static void NEAR_CALL
tokendstTerm(struct TokenDst *This)
{
   tokenTerm(&(This->token));
}

   void
CompileFromTokens(struct Call *call,const void *CodeBuffer)
{
   struct TokenDst tDst;
   TokenCodes tc;
   wSEObjectMem wDstMem;
   wSEVar wDstVar;
   jsebool found;
   wSEObject wGlobalObject;

   tokendstInit(&tDst,CodeBuffer);
#  if defined(JSE_LINK) && (0!=JSE_LINK)
      assert( NULL != call->ExtensionLib );
      extensionTokenRead(call->ExtensionLib,call,&tDst);
#  else
      tokenReadByte(&tDst); /* ignore number of link libraries */
#  endif
   tc = tokenReadCode(&tDst);
   if( tc!=INITIALIZATION_FUNCTION )
      tokenFatalError();
   SEOBJECT_ASSIGN_LOCK_W(wGlobalObject,call->hGlobalObject);
   wDstMem = seobjNewMember(call,wGlobalObject,
                            STOCK_STRING(Global_Initialization),&found);
   SEOBJECT_UNLOCK_W(wGlobalObject);
   assert( NULL != SEOBJECTMEM_PTR(wDstMem) );
   wDstVar = SEOBJECTMEM_VAR(wDstMem);
   SEVAR_INIT_BLANK_OBJECT(call,wDstVar);
   localTokenRead(call,&tDst,wDstVar);
   SEOBJECTMEM_UNLOCK_W(wDstMem);
   tc = tokenReadCode(&tDst);
   if ( ALL_DONE_BYE_BYE != tc )
      tokenFatalError();
   tokendstTerm(&tDst);
}

   void
tokenFatalError()
{
/*   InstantDeath(TextCore::TOKEN_READ_FAILURE); */
   exit(1);
}


   static void NEAR_CALL
tokenReadBuffer(struct TokenDst *this,void *buf,uint ByteCount)
{
   memcpy(buf,this->TokenMem,ByteCount);
   this->TokenMem = (ubyte *)(this->TokenMem) + ByteCount;
}


   uword8
tokenReadByte(struct TokenDst *this)
{
   uword8 b;
   tokenReadBuffer(this,&b,1);
   return b;
}


#if SE_BIG_ENDIAN==True
   void NEAR_CALL
tokenReadNumericDatum(struct TokenDst *this,
                      void * datum,uint datumlen)
{
   uword8 buffer[20];
   int i;
   assert( datumlen < sizeof(buffer) );
   tokenReadBuffer(this,buffer,datumlen);
   for ( i = 0; i < datumlen; i++ ) {
      ((uword8 *)datum)[i] = buffer[datumlen - i - 1];
   } /* endfor */
}
#endif

   static jsenumber NEAR_CALL
tokenReadNumber_fromNumber(struct TokenDst *this)
{
   jsenumber n;
   tokenReadNumericDatum(this,&n,sizeof(n));
   return n;
}

   static sword32 NEAR_CALL
tokenReadLong_fromLong(struct TokenDst *this,uword8 ByteCount)
{
   sword32 n;
   switch ( ByteCount )
   {
      case 8:
         n = (sword32) (sword8) tokenReadByte(this);
         break;
      case 16:
      {  sword16 n16;
         tokenReadNumericDatum(this,&n16,sizeof(n16));
         n = (sword32)n16;
      }  break;
      case 32:
         tokenReadNumericDatum(this,&n,sizeof(n));
         break;
#     ifndef NDEBUG
      default:
         assert( False );
#     endif
   }
   return n;
}

   jsenumber
tokenReadNumber(struct TokenDst *this)
{
   uword8 ByteCount = tokenReadByte(this);
   return ( 0 == ByteCount )
        ? tokenReadNumber_fromNumber(this)
        : JSE_FP_CAST_FROM_SLONG(tokenReadLong_fromLong(this,ByteCount)) ;
}

   sword32
tokenReadLong(struct TokenDst *this)
{
   uword8 ByteCount = tokenReadByte(this);
   return ( 0 == ByteCount )
        ? JSE_FP_CAST_TO_SLONG(tokenReadNumber_fromNumber(this))
        : tokenReadLong_fromLong(this,ByteCount) ;
}

   VarName
tokenReadString(struct Call *call,struct TokenDst *this)
{
   TokenCodes toke = tokenReadCode(this);
   VarName string;
   if ( OLD_STRING != toke )
   {
      stringLengthType len, i;
      jsecharptr str;
      jsecharptr cptr;

      assert( NEW_STRING_ASCII ==toke  ||  NEW_STRING_UNICODE == toke );
      /* string not already in table, and so add it and get
       * the length and string
       */
      len = (stringLengthType)tokenReadLong(this);
#     ifdef HUGE_MEMORY
      assert( len<HUGE_MEMORY );
#     endif
      str = (jsecharptr) jseMustMalloc(jsechar,(size_t)len*sizeof(jsechar)+1/*so never 0*/);
      for ( i = 0, cptr = str; i < len; i++, JSECHARPTR_INC(cptr) )
      {
         jsechar c;
         if ( NEW_STRING_UNICODE == toke )
         {
            c = (jsechar) (tokenReadByte(this) | (tokenReadByte(this) << 8 ));
         }
         else
         {
            c = (jsechar)tokenReadByte(this);
         }
         JSECHARPTR_PUTC(cptr,c);
      }
      /* enter this string into our string table, program text strings are
       * always locked. */
      string = LockedStringTableEntry(call,str,len);
#     ifdef HUGE_MEMORY
      assert( len<HUGE_MEMORY );
#     endif
         jseMustFree(str);
      /* add this to growing list of known strings */
      tokenPutString(&(this->token),string);
   } else {
      /* string is already in the table.
       * This is just its index into that table
       */
      assert( OLD_STRING == toke );
      string = this->token.StringTable[(size_t)(tokenReadLong(this)-1)];
   }
   return string;
}

#endif  /* defined(JSE_TOKENDST) */

/***************************************************
 ************ READ/WRITE TOKENIZED CODE ************
 ***************************************************/

#if defined(JSE_TOKENSRC) && (0!=JSE_TOKENSRC)
   static uint NEAR_CALL
RelativeGotoFromAbsolute(secode opcodes,uint AbsoluteGoto)
{
   secode end_opcodes = opcodes + AbsoluteGoto;
   uint RelativeGoto;
   for ( RelativeGoto = 0; opcodes < end_opcodes; opcodes++, RelativeGoto++ )
   {
      opcodes += SECODE_DATUM_SIZE(*opcodes);
   }
   assert( opcodes==end_opcodes );
   return RelativeGoto;
}

   void
secodeTokenWriteList(struct Call *call,struct TokenSrc *tSrc,
                     struct LocalFunction *locfunc)
{
   secodeelem c;
   secode cptr, endptr;
#  if JSE_MEMEXT_SECODES==1
      secode base = jsememextLockRead(locfunc->op_handle,jseMemExtSecodeType);
      endptr = (cptr = base) + locfunc->opcodesUsed ;
#  else
      endptr = (cptr = locfunc->opcodes) + locfunc->opcodesUsed ;
#  endif

   /* write out each token as a byte, followed by data for that token */
   assert( cptr < endptr );
   do {
      tokenWriteByte(tSrc,(uword8)(c = *cptr));

      if( c<SE_CONST_TYPE_EXT )
      {
         /* a 2-extension opcode, all are VAR_INDEX_TYPE, WITH_TYPE */
         tokenWriteLong(tSrc,SECODE_GET_ONLY(cptr+1,VAR_INDEX_TYPE));
#        if defined(JSE_PACK_SECODES) && (JSE_PACK_SECODES==1)
            tokenWriteLong(tSrc,(sword32)SECODE_GET_ONLY(cptr+1+(sizeof(VAR_INDEX_TYPE)/sizeof(secodeelem)),
                                                WITH_TYPE));
#        else
            tokenWriteLong(tSrc,(sword32)SECODE_GET_ONLY(cptr+2,WITH_TYPE));
#        endif
      }
      else if( c<SE_VAR_INDEX_TYPE_EXT )
      {
         tokenWriteLong(tSrc,(sword32)SECODE_GET_ONLY(cptr+1,CONST_TYPE));
      }
      else if( c<SE_ADDR_TYPE_EXT )
      {
         tokenWriteLong(tSrc,SECODE_GET_ONLY(cptr+1,VAR_INDEX_TYPE));
      }
      else if( c<SE_VARNAME_EXT )
      {
#        if JSE_MEMEXT_SECODES==1
         tokenWriteLong(tSrc,(sword32)RelativeGotoFromAbsolute(base,
                                                               SECODE_GET_ONLY(cptr+1,ADDR_TYPE)));
#        else
         tokenWriteLong(tSrc,(sword32)RelativeGotoFromAbsolute(locfunc->opcodes,
                                                               SECODE_GET_ONLY(cptr+1,ADDR_TYPE)));
#        endif
      }
      else if( c<SE_NO_EXT )
      {
         VarName vname = SECODE_GET_ONLY(cptr+1,VarName);
         assert( NULL != GetStringTableEntry(call,vname,NULL) );
         tokenWriteString(call,tSrc,vname);
      }
      cptr += SECODE_DATUM_SIZE(*cptr);
   } while ( ++cptr < endptr );

   /* write final code to show this is the end of the token list */
   tokenWriteByte(tSrc,(uword8)END_FUNC_OPCODES);

#  if JSE_MEMEXT_SECODES==1
      jsememextUnlockRead(locfunc->op_handle,base,jseMemExtSecodeType);
#  endif
}
#endif


#if defined(JSE_TOKENDST) && (0!=JSE_TOKENDST)
   static uint NEAR_CALL
AbsoluteGotoFromRelative(secode opcodes,uint RelativeGoto)
{
   secode c;
   for ( c = opcodes; 0 != RelativeGoto--; c++ )
   {
      c += SECODE_DATUM_SIZE(*c);
   }
   return (uint)(c - opcodes);
}

   void
secodeTokenReadList(struct Call *call,struct TokenDst *tDst,
                    struct LocalFunction *locfunc)
{
   struct secompile This;
   secodeelem c;
   secode sptr, EndOpcodes;

   This.call = call;
   This.opcodesAlloced = 50;
   This.opcodesUsed = 0;
   This.locfunc = locfunc;

   /* during compilation will write constants into local structure */
   SEOBJECT_ASSIGN_LOCK_W(This.constObj,locfunc->hConstants);
   SEMEMBERS_PTR(This.constMembers) = NULL;

   This.opcodes = jseMustMalloc(secodeelem,(uint)(This.opcodesAlloced * \
                                                 sizeof(*(This.opcodes))));
#  if (0!=JSE_COMPILER)
      This.NowCompiling = False;
#  endif

   while ( (uword8)END_FUNC_OPCODES != (uword8)(c = tokenReadByte(tDst)) )
   {
      if( c<SE_CONST_TYPE_EXT )
      {
         /* a 2-extension opcode, all are VAR_INDEX_TYPE, WITH_TYPE */
         VAR_INDEX_TYPE a = (VAR_INDEX_TYPE)tokenReadLong(tDst);
         WITH_TYPE b = (WITH_TYPE)tokenReadLong(tDst);
         secompileAddItem(&This,(int)c,a,b);
      }
      else if( c<SE_VAR_INDEX_TYPE_EXT )
      {
         secompileAddItem(&This,(int)c,(CONST_TYPE)tokenReadLong(tDst));
      }
      else if( c<SE_ADDR_TYPE_EXT )
      {
         secompileAddItem(&This,(int)c,(VAR_INDEX_TYPE)tokenReadLong(tDst));
      }
      else if( c<SE_VARNAME_EXT )
      {
         secompileAddItem(&This,(int)c,(ADDR_TYPE)tokenReadLong(tDst));
      }
      else if( c<SE_NO_EXT )
      {
         /* read a string value */
         VarName name = tokenReadString(call,tDst);
         secompileAddItem(&This,(int)c,name);
#        if defined(JSE_GETFILENAMELIST) && (0!=JSE_GETFILENAMELIST)
         if( seFilename == c )
         {
            /* if this file is not already in our filename list then
             * add it now so playback of tokens also maintains a full
             * list of files used.
             */
            jsecharptr *list = call->Global->FileNameList;
            sint count = call->Global->number;
            const jsecharptr file = GetStringTableEntry(call,name,NULL);
            while ( count-- )
            {
               if ( 0 == strcmp_jsechar(file,list[count]) )
                  break;
            }
            if ( count < 0 )
               callAddFileName(call,(jsecharptr)file);
         }
#        endif
      }
      else
      {
         secompileAddItem(&This,(int)c);
      }
   }

   /* goto addresses are still relative; turn them into absolutes */
   EndOpcodes = (sptr=This.opcodes) + This.opcodesUsed;
   for( ; sptr != EndOpcodes; sptr++ )
   {
      assert( sptr < EndOpcodes );
      if( *sptr>=SE_START_GOTO_CODES && *sptr<=SE_END_GOTO_CODES )
      {
         SECODE_PUT_ONLY(sptr+1,ADDR_TYPE,
            AbsoluteGotoFromRelative(This.opcodes,SECODE_GET_ONLY(sptr+1,ADDR_TYPE)));
      }
      sptr += SECODE_DATUM_SIZE(*sptr);
   }
   assert( sptr == EndOpcodes );

#  if defined(SECODE_LISTINGS)
      secodeListing(&This);
#  endif

   /* finished working with the locfunc constants */
#  if 0!=JSE_MEMEXT_MEMBERS
      if ( NULL != SEMEMBERS_PTR(This.constMembers) )
         SEMEMBERS_UNLOCK_W(This.constMembers);
#  endif
   SEOBJECT_UNLOCK_W(This.constObj);

   /* local function will remember the opcodes used */
#  if JSE_MEMEXT_SECODES==1
      locfunc->op_handle =
         jsememextStore(This.opcodes,This.opcodesUsed*sizeof(secodeelem),jseMemExtSecodeType);
      jseMustFree(This.opcodes);
#  else
      locfunc->opcodes = jseMustReMalloc(secodeelem,This.opcodes,
         (locfunc->opcodesUsed=This.opcodesUsed) * sizeof(*(This.opcodes)) );
#  endif
}
#endif

#elif defined(__MWERKS__)
   #if __option(ANSI_strict)
      /* With ANSI_strict ON, empty files are errors, so this dummy variable is added */
      static ubyte DummyVariable;
   #endif /* ANSI_strict */
#endif
