/* sefile.h  handles the ScriptEase file handles
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

#if !defined(__SEFILE_H)
#define  __SEFILE_H
#ifdef __cplusplus
   extern "C" {
#endif

#if defined(JSE_CLIB_FREOPEN)  || \
    defined(JSE_CLIB_FOPEN)    || \
    defined(JSE_CLIB_FPRINTF)  || \
    defined(JSE_CLIB_FSCANF)   || \
    defined(JSE_CLIB_FPUTS)    || \
    defined(JSE_CLIB_FGETS)    || \
    defined(JSE_CLIB_VFPRINTF) || \
    defined(JSE_CLIB_FCLOSE)   || \
    defined(JSE_CLIB_FLOCK)    || \
    defined(JSE_CLIB_FSEEK)    || \
    defined(JSE_CLIB_FTELL)    || \
    defined(JSE_CLIB_FGETC)    || \
    defined(JSE_CLIB_UNGETC)   || \
    defined(JSE_CLIB_FPUTC)    || \
    defined(JSE_CLIB_VFSCANF)  || \
    defined(JSE_CLIB_TMPFILE)  || \
    defined(JSE_CLIB_FFLUSH)   || \
    defined(JSE_CLIB_FREAD)    || \
    defined(JSE_CLIB_FWRITE)   || \
    defined(JSE_CLIB_FGETPOS)  || \
    defined(JSE_CLIB_FSETPOS)  || \
    defined(JSE_CLIB_CLEARERROR)  || \
    defined(JSE_CLIB_REWIND)   || \
    defined(JSE_CLIB_FEOF)     || \
    defined(JSE_CLIB_FERROR)   || \
    defined(JSE_CLIB_PRINTF)   || \
    defined(JSE_CLIB_GETCH)    || \
    defined(JSE_CLIB_GETCHE)   || \
    defined(JSE_CLIB_KBHIT)    || \
    defined(JSE_CLIB_FPRINTF)  || \
    defined(JSE_CLIB_VPRINTF)  || \
    defined(JSE_CLIB_VFPRINTF) || \
    defined(JSE_CLIB_GETS)     || \
    defined(JSE_CLIB_GETCHAR)  || \
    defined(JSE_CLIB_PUTCHAR)  || \
    defined(JSE_CLIB_PERROR)   || \
    defined(JSE_CLIB_PUTS)


#define  DEFAULT_FGETS_BUFSIZE 1000  /* used if none supplied */


struct jseFILE {
   struct jseFILE *Prev;  /* keep linked list */
   FILE  *fp;
};  /* does not include stdin, stdout, and stderr */



struct FileSystem {
   struct FileSystem *Previous;
   struct jseFILE *NewestjseFILE;  /* does not include stdin, stdout, and stderr */

   jseContext pConstructorContext;  /* used for file deletion only */
};

#if defined(JSE_CLIB_FOPEN) || \
    defined(JSE_CLIB_TMPFILE)
jseVariable NEAR_CALL fileSystemFOpen(struct FileSystem * fs,jseContext jsecontext,
                                      const jsecharptr FileName,const jsecharptr Mode);
   /* create the var that is returned. FileName NULL for tmpfile(). */
#endif

#if defined(JSE_CLIB_FREOPEN)
jseVariable NEAR_CALL fileSystemFReOpen(struct FileSystem * fs,jseContext jsecontext,
                                        jseVariable FV,const jsecharptr FileName,
                                        const jsecharptr Mode);
   /* NULL if problem, but no error printed */
#endif

#if defined(JSE_CLIB_FCLOSE)
jsebool NEAR_CALL fileSystemFClose(struct FileSystem * fs,jseContext jsecontext,jseVariable FV,sint *ReturnValue);
   /* LibErrorPrintf and return False if FV is invalid, else True */
#endif

#if defined(JSE_CLIB_TMPFILE)
jseVariable NEAR_CALL fileSystemTmpFile(struct FileSystem * fs,jseContext jsecontext);
#endif

/* All of the function need these functions */
struct FileSystem * NEAR_CALL fileSystemNew(jseContext InitialContext,struct FileSystem *PreviousFileSystem);
void NEAR_CALL fileSystemDelete(jseContext jsecontext,struct FileSystem *fs);
   /* closes all files and remembers their status */
FILE * NEAR_CALL fileSystemFp(struct FileSystem *fs,jseContext jsecontext,jseVariable FV);
   /* LibErrorPrintf and return NULL if FV is invalid, else returns FILE * associated with this FV */
jsebool fileSystemIsConsoleFP(jseContext jsecontext,FILE *fp);


/* fileSystemDelete must call this, so leave it */
void NEAR_CALL fileSystemFCloseStdFile(struct FileSystem * fs,FILE *fp);
   /* Called by fileSystemFCloseStdFile, leave it */
uint NEAR_CALL fileSystemFindStdFileIndex(struct FileSystem * fs,FILE *fp);
  /* find index, fp must be stdin, stdout, or stderr */

#define CONTEXT_FILE_SYSTEM   ((struct FileSystem *)(jseLibraryData(jsecontext)))

#endif
#ifdef __cplusplus
}
#endif
#endif
