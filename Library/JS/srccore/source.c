/* source.c     Keep track of the position of source code
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

#define  MAX_SOURCE_FILE_LINE_LEN   1500
#if defined(__DJGPP__)
#  define _MAX_PATH   255
#elif defined(__JSE_390__)
#  define _MAX_PATH   80
#elif defined(__JSE_EPOC32__)
#  define _MAX_PATH FILENAME_MAX
#elif defined(__JSE_NWNLM__)
#  include <nwfattr.h>
#endif

#if defined(JSE_GETFILENAMELIST) && (0!=JSE_GETFILENAMELIST)
void callAddFileName(struct Call *This,jsecharptr name)
{
  if( This->Global->FileNameList )
    This->Global->FileNameList =
       jseMustReMalloc(jsecharptr ,This->Global->FileNameList,
                       (This->Global->number+1)*sizeof(jsecharptr ));
  else
    This->Global->FileNameList = jseMustMalloc(jsecharptr ,sizeof(jsecharptr ));

  This->Global->FileNameList[This->Global->number] = (jsecharptr)
     jseMustMalloc(jsechar,bytestrsize_jsechar(name));
  strcpy_jsechar(This->Global->FileNameList[This->Global->number++],name);
}
#endif

#if defined(JSE_TOOLKIT_APPSOURCE) && (0!=JSE_TOOLKIT_APPSOURCE)
/* define a function to set the filename.  This happens in this tricky way
 * because for the toolkit user the name field has been defined as a const,
 * so that they don't change it.  But we want to be able to change it
 * ourselves.
 */
   static void NEAR_CALL
sourceSetFilename(struct Source *This,const jsecharptr const value)
{
   memcpy((void *)&(This->sourceDesc.name),(void *)&value,
          sizeof(This->sourceDesc.name));
}
#endif

/* ----------------------------------------------------------------------
 * Maintain a list of included files so we don't include them again
 * ---------------------------------------------------------------------- */

#if defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)
   static void NEAR_CALL
sourceFreeAllIncludedFileMemory(struct Source *This)
{
   while ( NULL != This->RecentIncludedFile ) {
      struct IncludedFile *Prev = This->RecentIncludedFile->Previous;
      jseMustFree(This->RecentIncludedFile);
      This->RecentIncludedFile = Prev;
   }
}
#endif /* defined(JSE_INCLUDE) && (0!=JSE_INCLUDE) */

#if defined(JSE_CONDITIONAL_COMPILE) && (0!=JSE_CONDITIONAL_COMPILE)
   static void NEAR_CALL
sourceRemoveConditionalCompilation(struct Source *This)
{
   struct ConditionalCompilation_ * OldCC = This->ConditionalCompilation;
   assert( NULL != This->ConditionalCompilation );
   This->ConditionalCompilation = This->ConditionalCompilation->prev;
   jseMustFree(OldCC);
}
#endif

void sourceDelete(struct Source *This,struct Call *call)
{
#  if defined(JSE_TOOLKIT_APPSOURCE) && (0!=JSE_TOOLKIT_APPSOURCE)
   if ( NULL != This->AllocMemory )
   {
#  endif
      /* this source was directly from memory */
      jseMustFree(This->AllocMemory);
#  if defined(JSE_TOOLKIT_APPSOURCE) && (0!=JSE_TOOLKIT_APPSOURCE)
   }
   else
   {
      /* this source was from a file */
      if ( This->FileIsOpen )
      {
         /* call 'fclose' callback */
#        if (defined(__JSE_WIN16__) || defined(__JSE_DOS16__) || defined(__JSE_GEOS__)) && \
            (defined(__JSE_DLLLOAD__) || defined(__JSE_DLLRUN__))
            DispatchToClient(call->Global->ExternalDataSegment,
                             (ClientFunction)(call->Global->ExternalLinkParms.
                                              GetSourceFunc),
                             (void *)call,
                             (void *)&(This->sourceDesc),jseClose);
#        else
            (*(call->Global->ExternalLinkParms.GetSourceFunc))
               (call,&(This->sourceDesc),jseClose);
#        endif
#        if !defined(NDEBUG) && (0<JSE_API_ASSERTLEVEL) && defined(_DBGPRNTF_H)
            if ( !jseApiOK )
            {
               DebugPrintf(UNISTR("Error calling source close function"));
               DebugPrintf(UNISTR("Error message: %s"),jseGetLastApiError());
            }
#        endif
         assert( jseApiOK );
      }
   }
#  endif
#  if defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)
      if ( NULL == This->prev ) {
         sourceFreeAllIncludedFileMemory(This);
      } else {
         This->prev->RecentIncludedFile = This->RecentIncludedFile;
      }
#  elif defined(JSE_TOOLKIT_APPSOURCE) && (0!=JSE_TOOLKIT_APPSOURCE)
      if ( NULL != This->sourceDesc.name )
         jseMustFree((jsecharptr )(This->sourceDesc.name));
#  endif
#  if defined(JSE_CONDITIONAL_COMPILE) && (0!=JSE_CONDITIONAL_COMPILE)
      while ( NULL != This->ConditionalCompilation ) {
         sourceRemoveConditionalCompilation(This);
      }
#  endif
   jseMustFree(This);
}

#if defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)
static jsecharptr NEAR_CALL sourceFindFileName(struct Source *This,jsecharptr FileSpec)
{
   struct IncludedFile *incf;

   assert( NULL != FileSpec  &&  0 != JSECHARPTR_GETC(FileSpec) );
   for ( incf = This->RecentIncludedFile; NULL != incf; incf = incf->Previous )
   {
#     if defined(__JSE_UNIX__)
      /* Unix filenames are case-sensitive */
      if ( !strcmp_jsechar(FileSpec,(jsecharptr)incf->RootFileName) )
#     else
      if ( !stricmp_jsechar(FileSpec,(jsecharptr)incf->RootFileName) )
#     endif
      {
         return((jsecharptr)incf->RootFileName);
      } /* endif */
   } /* endfor */
   return( NULL );
}

   static jsecharptr NEAR_CALL
sourceAddFileName(struct Source *This,jsecharptr RootFileSpec)
{
   struct IncludedFile *incf =
      jseMustMalloc(struct IncludedFile,sizeof(*incf)+bytestrlen_jsechar(RootFileSpec));

   assert( NULL == sourceFindFileName(This,RootFileSpec) );
   strcpy_jsechar((jsecharptr)incf->RootFileName,RootFileSpec);
   incf->Previous = This->RecentIncludedFile;
   This->RecentIncludedFile = incf;
   return((jsecharptr)incf->RootFileName);
}
#endif /* defined(JSE_INCLUDE) && (0!=JSE_INCLUDE) */

static struct Source * NEAR_CALL
sourceNew(struct Source *iprev)
{
   struct Source *This = jseMustMalloc(struct Source,sizeof(struct Source));
   memset(This,0,sizeof(*This));
#  if defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)
      assert( !This->RecentIncludedFile );
#  endif
#  if defined(JSE_TOOLKIT_APPSOURCE) && (0!=JSE_TOOLKIT_APPSOURCE)
      assert( !This->sourceDesc.lineNumber );
      assert( !This->sourceDesc.name );
#  endif
   assert( !This->AllocMemory );
#  if defined(JSE_CONDITIONAL_COMPILE) && (0!=JSE_CONDITIONAL_COMPILE)
      assert( NULL == This->ConditionalCompilation );
#  endif
   This->prev = iprev;
#  if defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)
      if ( NULL != iprev )
      {
         This->RecentIncludedFile = iprev->RecentIncludedFile;
      }
#  endif
   return This;
}

/* ----------------------------------------------------------------------
 * SOURCE DIRECTLY FROM A STRING
 * ---------------------------------------------------------------------- */

   struct Source *
sourceNewFromText(struct Source *PrevSB,const jsecharptr const SourceText)
{
   struct Source *This = sourceNew(PrevSB);
   jsecharptr s;

   assert( NULL != SourceText );
   This->AllocMemory = (jsecharptr) jseMustMalloc(jsechar,sizeof(jsechar)*(1+strlen_jsechar(SourceText)+1));
   JSECHARPTR_PUTC(This->AllocMemory,'\0');
   This->MemoryPtr = JSECHARPTR_NEXT(This->AllocMemory);
   strcpy_jsechar(This->MemoryPtr,SourceText);
   This->MemoryEnd = JSECHARPTR_OFFSET(This->MemoryPtr,strlen_jsechar(This->MemoryPtr));
   /* turn all newlines into NULL so work one line at a time */
   for ( s = This->MemoryPtr; NULL != (s=strchr_jsechar(s,'\n')); JSECHARPTR_INC(s) )
   {
      assert( sizeofnext_jsechar(s) == sizeof_jsechar('\0') );
      assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
      JSECHARPTR_PUTC(s,'\0');
   }
#  if defined(JSE_TOOLKIT_APPSOURCE) && (0!=JSE_TOOLKIT_APPSOURCE)
      if ( NULL != PrevSB )
      {
         This->sourceDesc.lineNumber = PrevSB->sourceDesc.lineNumber
                                     - 1 /* will soon increment */;
         sourceSetFilename(This,PrevSB->sourceDesc.name);
      }
#  endif
   /* reading in plain always force initial NULL to force call to NextLine() */
#  if !defined(JSE_MBCS) || (0==JSE_MBCS) /* Not worth translating for MBCS */
      assert( This->AllocMemory == (This->MemoryPtr - 1) );
#  endif
   JSECHARPTR_PUTC(This->AllocMemory,'\0');
   This->MemoryPtr = This->AllocMemory;

   return This;
}

/* ----------------------------------------------------------------------
 * INITIAL SOURCE FROM SOURCE 'FILE'
 * ---------------------------------------------------------------------- */

#if defined(JSE_TOOLKIT_APPSOURCE) && (0!=JSE_TOOLKIT_APPSOURCE)
   struct Source *
sourceNewFromFile(struct Call *call,struct Source *PrevSB,
                  jsecharptr FileSpec,jsebool *Success)
{
   struct Source * This;
   jsecharptr FileName;

   /* We used to get the source from a file that we managed.  To remove
    * dependencies on an I/O library we now use a callback to manage any
    * files or file like script sources.  This also opens to the possibility
    * of reading script source line-by-line fron non-file sources i.e
    * network, database, serialport, etc...
    */
   This = sourceNew(PrevSB);
   assert( NULL == This->AllocMemory );
      /* AllocMemory is NULL for interp from memory  */
   This->MemoryPtr = UNISTR("");
      /* initialize in case someone tries to read from this */
   assert( !This->FileIsOpen );
      /* in case of error, show that no file was opened */

   FileName = (jsecharptr) jseMustMalloc(jsechar, _MAX_PATH*sizeof(jsechar));

   assert( NULL != FileSpec );

   /* call 'fullpath' callback */
   if ( NULL == call->Global->ExternalLinkParms.FileFindFunc )
   {
      /* no callback provided, so just copy the file name directly */
      strncpy_jsechar(FileName,FileSpec,_MAX_PATH-1);
      *Success = True;
   }
   else
   {
#     if (defined(__JSE_WIN16__) || defined(__JSE_DOS16__) || defined(__JSE_GEOS__)) && \
      (defined(__JSE_DLLLOAD__) || defined(__JSE_DLLRUN__))
         *Success = (jsebool)DispatchToClient(call->Global->
                                              ExternalDataSegment,
                              (ClientFunction)(call->Global->
                                               ExternalLinkParms.FileFindFunc),
                              (void *)call,
                              (void *)FileSpec,
                              (void *)FileName,
                              (void *)(_MAX_PATH-1),
                              (void *)False);
#     else
         *Success = ( (*(call->Global->ExternalLinkParms.FileFindFunc))
                      (call,FileSpec,FileName,_MAX_PATH-1,False) );
#     endif
#     if !defined(NDEBUG) && (0<JSE_API_ASSERTLEVEL) && defined(_DBGPRNTF_H)
         if ( !jseApiOK )
         {
            DebugPrintf(UNISTR("Error calling FileFind function on filespec \"%s\""),
                        FileSpec);
            DebugPrintf(UNISTR("Error message: %s"),jseGetLastApiError());
         }
#     endif
      assert( jseApiOK );
   }

   if ( *Success != False )
   {
#     if defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)
         /* if this file was already used, then don't use it again */
         jsecharptr SavedFileName;
         if ( NULL != (SavedFileName=sourceFindFileName(This,FileName)) )
         {
            sourceSetFilename(This,SavedFileName);
         }
         else
#     endif
         {
            sourceSetFilename(This,FileName); /* no longer makes sense */
            /* call 'fopen' callback */
            if ( NULL == call->Global->ExternalLinkParms.GetSourceFunc )
            {
               *Success = False;
            }
            else
            {
#              if (defined(__JSE_WIN16__) || defined(__JSE_DOS16__) || defined(__JSE_GEOS__)) && \
                  (defined(__JSE_DLLLOAD__) || defined(__JSE_DLLRUN__))
                  *Success = DispatchToClient(call->Global->
                                              ExternalDataSegment,
                     (ClientFunction)(call->Global->
                                      ExternalLinkParms.GetSourceFunc),
                     (void *)call,(void *)&This->sourceDesc,jseNewOpen);
#              else
                  *Success = ( (*(call->Global->ExternalLinkParms.
                                  GetSourceFunc))
                                 (call,&This->sourceDesc,jseNewOpen) );
#              endif
#              if !defined(NDEBUG) && (0<JSE_API_ASSERTLEVEL) && \
                  defined(_DBGPRNTF_H)
                  if ( !jseApiOK )
                  {
                     DebugPrintf(
                        UNISTR("Error calling source open function on file \"%s\""),
                                 This->sourceDesc.name);
                     DebugPrintf(UNISTR("Error message: %s"),jseGetLastApiError());
                  }
#              endif
               assert( jseApiOK );

               if ( *Success ) {
                  /* yea! File is open. */
                  This->FileIsOpen = True;
#                 if defined(JSE_GETFILENAMELIST) && (0!=JSE_GETFILENAMELIST)
                     callAddFileName(call,FileName);
#                 endif
#                 if defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)
                     sourceSetFilename(This,sourceAddFileName(This,FileName));
#                 else
                     sourceSetFilename(This,StrCpyMalloc(FileName));
#                 endif
               }
            }
         }
   }

   jseMustFree(FileName);

   if ( !(*Success) )
   {
     callError(call,textcoreUNABLE_TO_OPEN_SOURCE_FILE,FileSpec);
   }
   else
   {
      /* for top level, read in first line now */
      if ( NULL == PrevSB  &&  This->FileIsOpen  &&
           !sourceNextLine(This,call,False,Success) )
      {
         This->MemoryPtr = UNISTR("");
      }
   }

   return This;
}
#endif

/* ----------------------------------------------------------------------
 * INCLUDING A FILE
 * ---------------------------------------------------------------------- */

#if defined(JSE_CONDITIONAL_COMPILE) && (0!=JSE_CONDITIONAL_COMPILE)

enum ConditionalCompilationDirective {
   ccd_if_flag  = 0x01,  /* this flag set on if, ifdef, and endif */
   ccd_if       = 0x03,
   ccd_ifdef    = 0x05,
   ccd_ifndef   = 0x09,
   ccd_endif    = 0x10,
   ccd_else     = 0x20,
   ccd_elif     = 0x40
};
struct ConditionalComps_ {
   const jsecharptr Name;
   uint len;
   enum ConditionalCompilationDirective ccd;
};

   static jsebool NEAR_CALL
sourceEvaluateConditionalCompilation(
                           struct Source *This,struct Call *call,
                           const jsecharptr SourceStatement,
                           jsebool WantTruth,jsebool AutomaticDefineFunc)
{
   jsecharptr command_buf =
      (jsecharptr) jseMustMalloc(jsechar,(strlen_jsechar(SourceStatement) + 50)*sizeof(jsechar));
   jseVariable ReturnVar;
   jsebool InterpSuccess;
   jsebool RestoreOptReqVarKeyword;
   struct CompileStatus_ cs;


   assert( !This->ConditionalCompilation->ConditionHasBeenMet );
   /* create wrapper around statement to interpret */
   if ( AutomaticDefineFunc )
   {
      strcpy_jsechar(command_buf,UNISTR("\"undefined\" != typeof"));
   }
   else
   {
      assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
      *(jsecharptrdatum *)command_buf = '\0';
   }
   strcat_jsechar(command_buf,UNISTR(" "));
   strcat_jsechar(command_buf,SourceStatement);

   /* call to interpret the statement */

   /* this is quite likely an #ifdef type of statement, which can
    * causes errors if VAR keyword is required.  So turn off that
    * options during the life of this call.
    */
   RestoreOptReqVarKeyword = ( 0 != ( call->Global->ExternalLinkParms.options
                                    & jseOptReqVarKeyword ) );
   if ( RestoreOptReqVarKeyword )
      call->Global->ExternalLinkParms.options &= ~jseOptReqVarKeyword;

   /* Compile status structure holds the filename and line number -
    * the inner interpret will do its own compile, changing these.
    * We restore them.
    */
   cs = call->Global->CompileStatus;
   InterpSuccess = jseInterpret(call,NULL,command_buf,NULL,
                                jseNewNone,JSE_INTERPRET_TRAP_ERRORS,
                                NULL,&ReturnVar);
   call->Global->CompileStatus = cs;

   if ( RestoreOptReqVarKeyword )
      call->Global->ExternalLinkParms.options |= jseOptReqVarKeyword;

   jseMustFree(command_buf);
   if ( InterpSuccess )
   {
      jsebool ReturnCode = jseEvaluateBoolean(call,ReturnVar);
      assert( NULL != ReturnVar );
      jseDestroyVariable(call,ReturnVar);
      This->ConditionalCompilation->ConditionHasBeenMet =
      This->ConditionalCompilation->ConditionTrue =
         WantTruth ? ReturnCode : !ReturnCode ;
   }
   else
   {
      /* set flag for higher levels to be sure an error occured */
      jseReturnVar(call,ReturnVar,jseRetTempVar);
      jseLibSetErrorFlag(call);
   }
   return InterpSuccess;
}

   static jsebool NEAR_CALL
sourceConditionalCompilationFilter(
     struct Source *This,struct Call *call,jsebool *IgnoreThisLine)
     /* If error then return False (error printed through call->errorxx),
      * else True. If filter then set *IgnoreThisLine = True (else ignore it)
      */
{
   static CONST_DATA(struct ConditionalComps_) ConditionalComps[] = {
      { UNISTR("if"),      2,     ccd_if     },
      { UNISTR("ifdef"),   5,     ccd_ifdef  },
      { UNISTR("ifndef"),  6,     ccd_ifndef },
      { UNISTR("endif"),   5,     ccd_endif  },
      { UNISTR("else"),    4,     ccd_else  },
      { UNISTR("elif"),    4,     ccd_elif  },
      { NULL }
   };
   jsecharptr PotentialConditionalComp = This->MemoryPtr;
   uint PotentialLen;
   const struct ConditionalComps_ *cc;
   enum ConditionalCompilationDirective ccd;
   const jsecharptr SourceToEvaluate;

   JSECHARPTR_INC(PotentialConditionalComp);

   /* allowed to have whitespace between '#' and directive */
   while( IS_WHITESPACE(JSECHARPTR_GETC(PotentialConditionalComp)) )
      JSECHARPTR_INC(PotentialConditionalComp);

   PotentialLen = strcspn_jsechar(PotentialConditionalComp,(jsecharptr)WhiteSpace);

   assert( UNICHR('#') == JSECHARPTR_GETC(This->MemoryPtr) );
   for ( cc = ConditionalComps; ; cc++ ) {
      if ( NULL == cc->Name ) {
         return True;
      } /* endif */
      assert( cc->len == strlen_jsechar(cc->Name) );
      if ( PotentialLen == cc->len &&
           !strnicmp_jsechar((void*)cc->Name,PotentialConditionalComp,(size_t)PotentialLen) )
         break;
   }

   /* this is a conditional compilation directive.  Handle now */
   ccd = cc->ccd;
   SourceToEvaluate = JSECHARPTR_OFFSET(PotentialConditionalComp,PotentialLen + 1);
   if ( ccd & ccd_if_flag )
   {
      /* add new conditional structure to nested/linked list */
      struct ConditionalCompilation_ *NewCC =
         jseMustMalloc(struct ConditionalCompilation_,
                       sizeof(struct ConditionalCompilation_));
      NewCC->prev = This->ConditionalCompilation;
      This->ConditionalCompilation = NewCC;
      NewCC->ConditionTrue = False;
      if ( NULL != NewCC->prev  &&  !NewCC->prev->ConditionTrue )
      {
         /* we're within a conditional compilation statement that is not true,
          * so this one will not be true either. Just set ConditionHasBeenMet
          * to avoid future inquiries.
          */
         NewCC->ConditionHasBeenMet = True;
      } else {
         NewCC->ConditionHasBeenMet = False;
         /* determine if */
         if ( ccd_if == ccd ) {
            if ( !sourceEvaluateConditionalCompilation(This, call,
                     SourceToEvaluate, True, False ) )
               return False;
         } else {
            assert( ccd_ifdef == ccd  ||  ccd_ifndef == ccd );
            if ( !sourceEvaluateConditionalCompilation(This,call,
                      SourceToEvaluate, ccd_ifdef == ccd, True ) )
               return False;
         } /* endif */
      }
   } else {
      /* not an #ifxxxx, this must be within a conditional compilation */
      if ( NULL == This->ConditionalCompilation ) {
         callError(call,textcoreMUST_APPEAR_WITHIN_CONDITIONAL_COMPILATION,
                   cc->Name);
         return False;
      } /* endif */
      if ( ccd_endif == ccd ) {
         sourceRemoveConditionalCompilation(This);
      } else if ( !This->ConditionalCompilation->ConditionHasBeenMet ) {
         if ( ccd_else == ccd ) {
            /* no condition previously met, so take this one */
            This->ConditionalCompilation->ConditionTrue = True;
            This->ConditionalCompilation->ConditionHasBeenMet = True;
         } else {
            assert( ccd_elif == ccd );
            if ( !sourceEvaluateConditionalCompilation(This,call,
                     SourceToEvaluate, True, False ) )
               return False;
         } /* endif */
      } else {
         /* new directive when have already taken correct one.
            turn off in case it is on */
         This->ConditionalCompilation->ConditionTrue = False;
      }
   }
   *IgnoreThisLine = True; /* will force next line to be read */
   return True;
}

#endif



jsebool sourceNextLine(struct Source *This,struct Call *call,
                       jsebool withinComment,jsebool *success)
     /* read in each line to make one huge file, always at least one
      * newline-whitespace between lines, and at beginning and end of the
      * whole thing.
      */
{
#  if defined(JSE_CONDITIONAL_COMPILE) && (0!=JSE_CONDITIONAL_COMPILE)
      jsebool IgnoreThisLine;
#  endif

   do {
#     if defined(JSE_CONDITIONAL_COMPILE) && (0!=JSE_CONDITIONAL_COMPILE)
         IgnoreThisLine = False;
#     endif
      call->Global->CompileStatus.CompilingLineNumber =
         ++(SOURCE_LINE_NUMBER(This));
         /* set for display in case of error */

#     if defined(JSE_TOOLKIT_APPSOURCE) && (0!=JSE_TOOLKIT_APPSOURCE)
      if ( NULL != This->AllocMemory ) /* interp from buffer */
#     endif
      {
         /* Does this comment simply mean that we're 'interpreting from a
          * buffer'? not a file pointer Source object.  Next line is
          * characters beyond next null returned from previous NextLine call
          */
         This->MemoryPtr = JSECHARPTR_OFFSET(This->MemoryPtr,1 + strlen_jsechar(This->MemoryPtr));
         if ( This->MemoryEnd <= This->MemoryPtr) {
            goto EndOfFile;
         }
         SKIP_WHITESPACE(This->MemoryPtr);
      }
#     if defined(JSE_TOOLKIT_APPSOURCE) && (0!=JSE_TOOLKIT_APPSOURCE)
      else /* interp from customer supplied 'file' */
      {
         /* call 'fgets' callback */
         if ( !This->FileIsOpen /* if file never had to happen */
           || !
#        if (defined(__JSE_WIN16__) || defined(__JSE_DOS16__) || defined(__JSE_GEOS__)) && \
            (defined(__JSE_DLLLOAD__) || defined(__JSE_DLLRUN__))
            DispatchToClient(call->Global->ExternalDataSegment,
                             (ClientFunction)(call->Global->ExternalLinkParms.
                                              GetSourceFunc),
                             (void *)call,
                             (void *)&This->sourceDesc,jseGetNext)
#        else
            ( (*(call->Global->ExternalLinkParms.GetSourceFunc))
                           (call,&This->sourceDesc,jseGetNext) )
#        endif
            )
            goto EndOfFile;
#        if !defined(NDEBUG) && (0<JSE_API_ASSERTLEVEL) && defined(_DBGPRNTF_H)
            if ( !jseApiOK )
            {
               DebugPrintf(
                  UNISTR("Error calling source-line callback with jseGetNext"));
               DebugPrintf(UNISTR("Error message: %s"),jseGetLastApiError());
            }
#        endif
         assert( jseApiOK );
         This->MemoryPtr = This->sourceDesc.code;
         assert(NULL != This->MemoryPtr);
         SKIP_WHITESPACE(This->MemoryPtr);
      }
#     endif

      assert( 0 == JSECHARPTR_GETC(This->MemoryPtr) || !IS_WHITESPACE(JSECHARPTR_GETC(This->MemoryPtr)) );
#     if defined(JSE_CONDITIONAL_COMPILE) && (0!=JSE_CONDITIONAL_COMPILE)
      if ( !withinComment )
      {

         if ( UNICHR('#') == JSECHARPTR_GETC(This->MemoryPtr) )
         {
#          ifdef __JSE_UNIX__
           if ( '!' == JSECHARPTR_GETC(JSECHARPTR_NEXT(This->MemoryPtr)) )
           {
              /* for unix skip any lines starting with #! */
              IgnoreThisLine = True;
           } else
#          endif
            if( !sourceConditionalCompilationFilter(This,call,&IgnoreThisLine))
            {
               assert( CALL_QUIT(call) );
               *success = False;
               return False;
            }
         }
      }
#     endif

   } while( 0 == JSECHARPTR_GETC(This->MemoryPtr)
#            if defined(JSE_CONDITIONAL_COMPILE) && \
                (0!=JSE_CONDITIONAL_COMPILE)
                || IgnoreThisLine
                || ( This->ConditionalCompilation &&
                     !This->ConditionalCompilation->ConditionTrue )
#            endif
          );
   return True;

EndOfFile:
   call->Global->CompileStatus.CompilingLineNumber--;
   assert( jseApiOK );
#  if defined(JSE_CONDITIONAL_COMPILE) && (0!=JSE_CONDITIONAL_COMPILE)
      if ( This->ConditionalCompilation ) {
         callError(call,textcoreENDIF_NOT_FOUND);
         *success = False;
      } /* endif */
#  endif
   return False;
}


#if defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)
/* if this file was already used, then don't use it again */
jsebool sourceInclude(struct Source **source,struct Call *call)
{
   jsechar QuoteChar;
   jsecharptr src = sourceGetPtr(*source);
   jsebool success = False;

   /* next character had better be a quote character */
   if ( (QuoteChar = UNICHR('\"')) != JSECHARPTR_GETC(src)
     && (QuoteChar = UNICHR('\'')) != JSECHARPTR_GETC(src)
     && (QuoteChar = UNICHR('<')) != JSECHARPTR_GETC(src) ) {
      callError(call,textcoreMISSING_INCLINK_NAME_QUOTE,'<',
                textcoreIncludeDirective);
   }
   else
   {
      jsechar EndQuoteChar = (jsechar) ((UNICHR('<') == QuoteChar) ? UNICHR('>') : QuoteChar);
      jsecharptr End;

      JSECHARPTR_INC(src);
      if ( NULL == (End = strchr_jsechar(src,EndQuoteChar)) )
      {
         callError(call,textcoreMISSING_INCLINK_NAME_QUOTE,EndQuoteChar,
                   textcoreIncludeDirective);
      }
      else
      {
         assert( sizeof_jsechar(EndQuoteChar) == sizeof_jsechar('\0') );
         assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
         JSECHARPTR_PUTC(End,'\0');
         sourceSetPtr(*source,JSECHARPTR_NEXT(End));
         *source = sourceNewFromFile(call,*source,src,&success);
         if( success )
         {
            if ( !sourceNextLine(*source,call,False,&success) )
            {
               /* nothing was read at all */
               (*source)->MemoryPtr = UNISTR("");
            }
         }
      }
   }
   return success;
}
#endif



#endif
