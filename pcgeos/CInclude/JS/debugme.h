/* debugme.h  - Header for jse interpreter being debugged
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

/* 03/06/98 - started rewrite, Rich Robinson
 * 03/17/98 - rewrite in C
 *
 *
 * defines:
 *   JSE_DEBUGGABLE  - turns on all the debugging stuff
 *
 * --these next two flags are mutually exclusive--
 *   JSE_DEBUG_MEMORY- uses shared memory
 *   JSE_DEBUG_TCPIP - communicates via tcp/ip
 *
 *   JSE_DEBUG_MASTER- if so, the application starts the debugging session
 *                     this is usually true for sewse and false for sedesk
 *   JSE_DEBUG_PASSWORD- if passwords needed
 *   JSE_DEBUG_RUN   - we allow the RUN_UNTIL_SOMETHING_HAPPENS message and
 *                     friends
 *   JSE_DEBUG_FILES - files are transferred to the debugger (for remote
 *                     debugging.)
 *   JSE_DEBUG_REMOTE- the debugger and debuggee are not sharing memory
 *                     but passing the messages to each other (such as
 *                     across the net.) Causes messages to be transformed
 *                     correctly due to Endianness.
 *
 *   JSE_DEBUG_PROXY - if this is the proxy (which kind of does everything)
 */

#if !defined(DEBUGME_H)
#define DEBUGME_H

#ifdef __cplusplus
extern "C" {
#endif

char *encode(const char *password,const char *key);

#if defined(JSE_DEBUGGABLE) && (0!=JSE_DEBUGGABLE)
/* ----------------------------------------------------------------------
 * A few routines you must fill in. If you use either of the two
 * previded methods, they will get filled in, otherwise you must
 * provide functions to implement your transfer protocol.
 * ---------------------------------------------------------------------- */


void jseDbgDisconnect(jseContext jsecontext,struct debugMe *debugme);


/* Send or receive a message into the 'info' field of the debugme. */
jsebool jseDbgSendMsg(jseContext jsecontext,struct debugMe *debugme,
                               struct DebugInfo *info);
jsebool jseDbgGetMsg(jseContext jsecontext,struct debugMe *debugme);


/* the stop button on the debugger is handled out of the normal
 * message passing, so you need some way in your protocol to find out
 * that it has happened. This routine needs to check it, and update
 * the 'stop_wanted' flag appropriately.
 */
void jseDbgIsStopWanted(jseContext jsecontext,struct debugMe **debugme);

/* We have routines to extract any information we care about from the
 * structure, as well as set any information during initialization. The reason
 * for 2 get init routines is that when the shared memory version is started
 * up, it needs to immediately extract the debugger's window handle from the
 * shared packet. Other protocols may end up needing to do the same thing.
 *
 * The second init is provided in case you want to modify the initialization
 * flags to get the two halves in sync.
 */
void jseDbgSetInit(jseContext jsecontext,struct debugMe *debugme);
void jseDbgGetInit(jseContext jsecontext,struct debugMe *debugme);
void jseDbgGetFirstInit(jseContext jsecontext,struct debugMe *debugme);


#if defined(JSE_DEBUG_TCPIP)
struct tcpipInfo
{
#  if defined(__JSE_WIN32__) || defined(__JSE_WIN16__)
      char DebugAppClassName[50];
      HWND MyHiddenHwnd;
#  elif defined(USE_MAC_WINSOCK)
      NMMessageCallbackUPP nmMessageCallbackUPP;
      NMMessageHandler nmMessageHandler;
#  endif
   SOCKET socket;       /* the connection is on this socket */
   volatile jsebool GotWmSocketReadReady;
   volatile jsebool GotWmSocketWriteReady;
   volatile jsebool GotWmSocketAcceptReady;
   volatile jsebool GotWmSocketConnectReady;
   volatile jsebool GotWmSocketCloseReady;

};
#endif

#if defined(JSE_DEBUG_MEMORY)
struct memoryInfo
{
   char mmf_name[100];             /* the final constructed name */
   HANDLE hMapFile;
   char DebugAppClassName[50];
   HWND MyHiddenHwnd,DebuggerHwnd;
   volatile jsebool GotWmjseDebugMsg;
};
#endif

/* ---------------------------------------------------------------------- */

#if defined(__JSE_WIN32__)
#  define IDE_LOC "sedbgw32.exe"
#else
/* This file is included to allow debugable sewse's to be built,
 * it doesn't make any sense to print this message.
 *
 *#  error 16-bit debugger no longer supported
 */
#endif


#ifdef JSE_DEBUG_FILES
/*
 * Whenever we see the 'get source location' message, we silently translate
 * this to a local filename by passing the contents of the source file
 * across the net. This is only done the first time any particular source
 * file is encountered.
 */
struct source_file {
  struct source_file *next;

  char remote_filename[_MAX_PATH];
  char local_filename[_MAX_PATH];
};
#endif


#define CHANGE_VALUE_SIZE 40

#ifdef JSE_DEBUG_RUN

struct bpoint
{
   struct bpoint *next;

   /* It is easiest, fastest, and most importantly safest to simply copy
    * the message that informed us of the breakpoint
    */
   struct DebugInfo break_point;

   /* Used to keep track of the watch value when the watch is 'until changed' */
   jsechar sOldVal[CHANGE_VALUE_SIZE];
   JSE_POINTER_UINDEX sOldSize;
};
#endif

struct debugMe
{
   void *protocol_info;
#  if defined(__JSE_WIN16__) || defined(__JSE_WIN32__)
     HINSTANCE myAppInstance;
#  endif

#  ifdef JSE_DEBUG_RUN
      /* We have to store the breakpoints that can possibly cause us to drop out
       * of our RUN_UNTIL_SOMETHING_HAPPENS msg
       */
      struct bpoint *break_points;
      jsebool stop_wanted;
#  endif

#  ifdef JSE_DEBUG_PASSWORD
      char encryption_key[JSEDBG_PASSWORD_MAX_LEN+1]; /* the last encryption key we sent out. */
      int password_accepted;                   /* if true, we can just debug. */
#  endif

#  ifdef JSE_DEBUG_FILES
      /*
       * This chain is used to keep track of any temporary files we create on the
       * remote end while using the IDE's remote save capability. In this case the
       * 'remote_filename' is the temporary filename we are storing the file in.
       *
       * Realistically, only one file will be saved across the net at a time, but
       * I've coded the more general purpose case to allow for future expansion
       */
      struct source_file *temp_files;

      struct source_file *files_seen;

      char *filename_list;
      int list_index;

#  endif


   /* both are checks to make sure bad things don't happen */
   jsebool DebuggerRecursion;
   jsebool NowInterpreting;

   struct DebugInfo *info;

   jseDbgUInt depth;
};


struct debugMe * debugmeInit(jseContext jsecontext,char * CommandString
#  if defined(__JSE_WIN32__) || defined(__JSE_WIN16__)
      ,HINSTANCE Instance
#  endif
#  ifdef JSE_DEBUG_TCPIP
      ,const char *remoteTcpipAddress
#  endif
   );

void debugmeTerm(jseContext jsecontext,struct debugMe **);
void debugmeDebug(jseContext jsecontext,struct debugMe **);
void debugmeErrorHappened(struct debugMe *,char *msg);
void debugmeExceptionHappened(struct debugMe *,char *msg);

#if defined(JSE_DEBUG_FILES)
void debugmeFreeCopiedFiles(struct debugMe *);
#endif

void NEAR_CALL debugmeConnect(struct debugMe *,jseContext jsecontext);
void NEAR_CALL debugmeNoMore(jseContext jsecontext,struct debugMe **);

struct debugMe * NEAR_CALL debugmeNew(void);

#ifdef JSE_DEBUG_PROXY
void NEAR_CALL debugmeDelete(struct debugMe *debugme);
#endif

#define debugmeHasTerminated(this) ((this)->info->DebuggeeIsUpAndRunning = False)

#define jseDbgInfo(dm) ((dm)->protocol_info)

#endif /* JSE_DEBUGGABLE */
#ifdef __cplusplus
}
#endif
#endif
