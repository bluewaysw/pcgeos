/* DbgShare.h - common header between ScriptEase debuggers and debuggees
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

/*
 * 03/06/98 - started rewrite, Rich Robinson
 *
 *
 * Debugger/Debuggee overview:
 *
 * There are currently two models for debugging which use the same protocol,
 * namely TCP/IP and shared memory. In all cases, a packet of memory is the
 * information being shared. One side is considered to 'own' that packet.
 * In shared memory, the side that owns the packet modifies it to issue
 * or respond to a command, sets the ownership to the other side, then
 * pings the other side (via a windows message) to tell it that it now
 * owns the packet. The other side checks to make sure that it does in
 * fact own the packet (i.e. no bugs and sync errors), then does its
 * thing and the process repeats.
 *
 * For TCP/IP, the whole packet is sent back and forth over the net.
 * The 'ping' is just sending the packet. The packet you send must
 * also have the ownership set to the receiving party.
 *
 * In both cases, the side that does not own the packet ought to be
 * waiting to receive a ping telling it that it owns the packet again.
 *
 *
 * protocol:
 *
 *
 * The initiating party is the one who creates the connection. In the
 * case of shared memory, the initiator is the one who sets up the shared
 * memory then starts the other program. In the case of TCP/IP the initiator
 * is the one establishing the connection (and the receiver is the one
 * waiting for a connection and then accepting it when it appears.) The
 * initiator is responsible for filling in the shared memory with its
 * own window handle when starting so that receiver can find it. In
 * TCP/IP the connection IS the handle so the initiator has no work to
 * do. The shared memory must be in command DBG_INIT at this point.
 * The initiator does NOT send a message (or send a ping.) The ownership
 * is considered to default to the receiver.
 *
 * Once the connection is established, the receiver sends a DBG_INIT message
 * back to the initiator. This establishes that the connection is all set
 * up and everything is ready to go. The receiver must have filled in its
 * own window handle before sending this init message.
 *
 * Finally, when the initiator receives confirmation via the DBG_INIT
 * message. it responds by sending the identical message right back to
 * the initiator. It will have filled in any of its init fields that
 * are important. Although we can fill in initial fields in the shared
 * memory model, we actually need to pass the message in the tcp/ip
 * model, so this extra step is needed. Finally, since the receiver now
 * 'owns' the message, if it is the application, it sends the message back
 * to the initiator without changing it.
 *
 * At this point, the debugger ALWAYS owns the message and normal
 * debugging begins. The debugger fills out the shared structure with
 * the command it would like processed, and sends it to the application
 * being debugged which processes it and responds. This continues
 * until the debugging session is complete.
 *
 *
 * There are a number of new flags described in debugme.h that should
 * be set in your jseopt.h before including the debugger headers. The
 * debugger will need to set these flags as well (well, the appropriate
 * ones.)
 */


#if (defined(JSE_DEBUGGABLE) && (0!=JSE_DEBUGGABLE)) && !defined(DBGSHARE_H)
#define DBGSHARE_H

#define JSEDBG_STR1_PASSWORD "tr%[=@# sq'/"
#define JSEDBG_STR2_PASSWORD  "kil*&6[-="
#define JSEDBG_BASE_ENCRYPTION   "3D-;*yz1@]'\\+|-sqDA"
#define JSEDBG_PASSWORD_MAX_LEN  128
#define JSEDBG_ENCRYPT_KEY_LENGTH 20

#define JSE_DEBUGGABLE_VERSION  64

#if defined(__JSE_WIN16__) || defined(__JSE_WIN32__) || defined(__JSE_CON32__)
#   define WM_JSE_DEBUG_MSG  (WM_USER + 1000)

   /* When the sewse is in 'go' mode, use this msg to tell it to stop */
#   define WM_JSE_DEBUG_STOP (WM_USER + 1001)

   /* If the proxy is shutting down, it will tell the IDE it is doing so.
    * The proxy shuts down when the remote connection is lost (tcp/ip error,
    * sewse terminates, or sewse crashes.)
    */
#   define WM_JSE_DEBUG_PROXY_GONE (WM_USER + 1002)

   /* It is debugging related and I don't want these spread out 'cause we
    * might accidentally duplicate one
    */
#   if defined(JSE_DEBUG_TCPIP)
#     define WM_SOCKET_READY (WM_USER + 1003)
#   endif
#endif

/* Used when doing a "run until" call. */
#define IGNORE_DEPTH 0xffffffff

#define START_DEBUG_STRING "/DEBUG="    /* follow with pointer to DebugInfo struct */

#ifndef _JSELIB_H
/* for the debugger */
typedef struct Var _FAR_ * jseVariable;   /* all jse variable types */

/* enumerate all possible type of jse variables */
typedef int jseDataType;
#   define  jseTypeUndefined  0
#   define  jseTypeNull       1
#   define  jseTypeBoolean    2
#   define  jseTypeObject     3
#   define  jseTypeString     4
#   define  jseTypeNumber     5
#   define  jseTypeBuffer     6
#endif

typedef uword32  jseDbgUInt;
typedef uword32   jseDbgBool;
typedef char     jseDbgChar;

struct DbgVarDesc {
   jseVariable var;         /* debuggee returns; NULL if no more at this index or higher */
   jseDbgChar VarName[300]; /* debuggee sets */
   jseDataType Type;        /* debuggee sets data type for returned variable */
   jseDbgUInt  Dimension;   /* debuggee returns dimension of variable, where 0 is single datum */
   jseDbgUInt  String;      /* set to True if 1-dimensional byte array is probably a string */
};

enum debugOwners {
   DEBUGGER = 62,
   DEBUGGEE = 63
};

enum DbgCommand {

      DBG_TRACE = 34,                   /* execute one statement */
      DBG_GO = 35,
      DBG_GET_SOURCE_LOCATION = 36,     /* return line number */
      DBG_BREAKPOINT_TEST = 37,         /* check if this is valid breakpoint */
      DBG_GET_VARIABLE = 38,            /* get variable name, type, etc... */
      DBG_GET_STRUCT_MEMBER = 39,       /* get next member of structure */
      DBG_INTERPRET = 40,               /* to be defined */
      DBG_EVALUATE_BOOLEAN = 41,        /* to be defined */
      DBG_RETPRINTF = 42,               /* like sprintf, but use this structure as result buffer */
      DBG_INIT = 43,                    /* the process that allocates this memory initializes Initialization */
                                        /* with this value, and the other process POST_MESSAGE */

      DBG_EXIT = 44,                    /* tell cenvi/jsecgi to DIE! don't send this until */
                                        /* you are ready to close the remote connection. */

      /* normally, when the debugger gives the debuggee an instruction, it does
       * it and returns and leaves the instruction the same. (Ex: DBG_GO, debuggee
       * goes and when debugger regains control, the command is still DBG_GO). If
       * an error occurs, the program is terminated and DBG_ERROR is returned. Check
       * the data section for the error message
       */

      DBG_ERROR = 45,
      /* exception is like an error but continues to run */
      DBG_EXCEPTION = 46

#   ifdef JSE_DEBUG_RUN
      ,DBG_CLEAR_BREAKPOINTS = 47,      /* clear all breakpoints stored by the debuggee */
      DBG_ADD_LINE_BREAKPOINT = 48,     /* Add a particular filename/linenumber */
      DBG_ADD_EXPR_BREAKPOINT = 49,     /* Add an expression breakpoint */
      DBG_RUN_UNTIL_SOMETHING_HAPPENS=50,/* Go until breakpoint reached, end of program, */
                                        /* error, or a certain depth reached. */

      /* These are proxy only. */

      DBG_STOP_MESSAGE = 51             /* Got the WM_JSE_DEBUG_STOP */
#   endif

#   ifdef JSE_DEBUG_FILES
      ,DBG_PASS_FILE = 52,              /* Used by the network proxy only */

      /* This message is only for the IDE and proxy, not local debugging */

      DBG_SAVE_FILE_CHUNK = 53,         /* Save the file on the remote system, here is a piece of it */


      /* This next message is used to pass across the file list. The Debugger probably
       * only needs to do this once and save the list.

       * Debugger sends this message with again set to False. Debuggee responds. Debuggee
       * sets again to True if there is more, else to False. Debugger when it sees that
       * there is more can call with again set to True. Do this until there is no more.
       * The list[] field of the data contains the text of the message. Keep strcat()ing
       * these togethor. When the whole list is passed, the string text will be all of the
       * files you can open (ex: "allfield.jse,html.jsh") These files will be comma-separated,
       * but they may not be valid filenames (ex: allfield.jse.2, or something) See next
       * message.
       */

      DBG_SEND_FILE_LIST = 54,

      /* Once the debugger has decided which file it wishes to open, it sends this message
       * to the debuggee. The response is the name of the local file that corresponds to
       * that remote file. This will not change, so you can store these names once you
       * get them. This uses the 'SourceLocation.Filename[]' data entry in both directions.
       */

      DBG_TRANSLATE_FILE = 55
#   endif

#   ifdef JSE_DEBUG_PASSWORD
      ,DBG_GIMME_PASSKEY = 56,          /* proxy is given encryption key to use */
      DBG_TRY_THIS = 57                 /* an encrypted password is sent back for checking. */
#   endif
};

enum WatchReasons
{
   IS_TRUE = 0,
   IS_FALSE = 1,
   HAS_CHANGED = 2
};

enum FileChunk
{
   MIDDLE = 0,
   NEW_FILE = 1,
   LAST_CHUNK = 2
};

struct DebugInfo
{
   jseDbgBool DebuggeeIsUpAndRunning;
   jseDbgUInt Owner; /* either DEBUGGER or DEBUGGEE */

   /* It is entirely possible that the whole file is passed in one chunk, in which
    * case, for example, both NEW_FILE and LAST_CHUNK would be set.
    */

   jseDbgUInt Command;  /* enum DbgCommand */
   union {
     struct {
       uint Version;
       /*
        * When the application does its debug init message, it fills out these
        * booleans so the debugger knows how it is configured.
        */

       /* The application requires a password before it will allow the debugger
        * access. Currently, the proxy knows how to deal with the password.
        * You can add this logic to the debugger if you care to.
        */
       jseDbgBool need_password;
       /* If this is true, then the application is storing the files locally
        * and will transfer them. The proxy makes temp copies on the debugging
        * machine and patches up the filenames for the debugger.
        */
       jseDbgBool files_local;
       /* If so, you can transfer information about breakpoints to the application
        * and then use the 'run_until_something_happens' stuff.
        */
       jseDbgBool run_supported;

       jseDbgBool IsNetwork;

#       if defined(__JSE_WIN16__) || defined(__JSE_WIN32__) || defined(__JSE_CON32__)
         /* this section probably does not belong in this structure, so let's move it... someday */
         HWND DebuggerHwnd;                   /* set by debugger before starting debuggee */
         HWND DebuggeeHwnd;                   /* set by debuggee when initialized */
#         endif
      } Initialization;              /* whoever creates struct fills in; then read by other task */
      struct {
         jseDbgChar  FileName[300];  /* if unknown then zero-length string */
         jseDbgUInt  LineNumber;
         jseDbgUInt  FunctionDepth;  /* increase when calling into functions; decrease when returning */
      } SourceLocation;
      struct {
         jseDbgChar  FileName[300];  /* debugger sets full path to source file */
         jseDbgUInt  LineNumber;     /* debugger sets */
         jseDbgBool  Valid;          /* debuggee sets True or False */
      } BreakpointTest;
      struct {
         jseDbgBool Global;       /* debugger sets, if not global then get local variables */
         jseDbgUInt index;        /* debugger sets, index starting at 0 */
         struct DbgVarDesc ret;   /* filled and returned by debuggee */
      } GetVariable;
      struct {
         jseVariable StructVar;   /* debugger sets, variable returned from DBG_GET_VARIABLE */
         jseDbgUInt  index;       /* debugger sets, index starting at 0 */
         struct DbgVarDesc ret;   /* filled and returned by debuggee; CHEAT WARNING: This is filled in from
                                   * the dimension-0 member of the structure, i.e., if this structure variable is
                                   * dimension 2, then fill in from struct[0][0] element
                                   */
      } GetStructMember;
      struct {
         jseDbgChar Source[400];  /* debugger fills in any code to intepret */
      } Interpret;
      struct {
         jseDbgChar Expression[300];   /* debugger fills with any expression to be true or false */
         jseDbgBool ValidStatement;    /* false (0) if cannot evaluate, else true (non-0) */
         jseDbgUInt Result;            /* return code of expression */
      } EvaluateBoolean;
      struct {
         jseDbgChar Command[100];   /* the command is now any valid javascript */
                                    /* and is usually ToString(foo) */
         jseDbgChar Result[300];    /* debuggee fills in as it would a sprintf(Result,"%d",foo); */
                                    /* if a problem then fill in buffer with "ERROR" message, or somesuch */
      } RetPrintf;

      struct {
        char ErrorMsg[400];
      } Error;

#     ifdef JSE_DEBUG_RUN
      /* For a breakpoint at a particular line, we pass the filename and linenumber of
       * the breakpoint.
       */
      struct
      {
         jseDbgChar FileName[300];
         jseDbgUInt LineNumber;
      }
      BreakpointLine;

      /* If we are passing a watch, we pass the watch expression (ex: a+b>10) and the reason
       * for the watch (i.e. if expression is true, if it is false, or if it has changed)
       */
      struct
      {
         /* changed because Microsoft seems to make enums 2 bytes */
         /*         enum WatchReasons Reason; */
         jseDbgUInt Reason;

         jseDbgChar Expression[396];
      }
      BreakpointExpr;

      /* We have already setup the breakpoints, we just run one of the breakpoints is hit
       * or until the function depth is less than or equal to the given value (for step over)
       * if the value is "IGNORE_DEPTH", just keep going until a breakpoint (go)
       */
      struct
      {
         jseDbgUInt FunctionDepth;
      }
      RunUntilSomethingHappens;
#     endif

#     ifdef JSE_DEBUG_FILES
      /* This message is used by the proxy only for passing files back
       * to the local machine.
       */
      struct
      {
         jseDbgChar filename[100]; /* the file being passed (remote name) */
         jseDbgChar text[296];     /* the text of the file */
         jseDbgUInt chunk_size;    /* how much text in this chunk */
      }
      PassFile;

      /* Each bit of a file to be saved is passed in one of these structures */
      struct
      {
        jseDbgChar filename[100];  /* The file to be saved (local name) */
        jseDbgChar text[292];      /* a piece of the text of the file */
        jseDbgUInt chunk_size;     /* a value between 1 and sizeof(text) (i.e. 292) */
        jseDbgUInt flags;          /* either MIDDLE, NEW_FILE, LAST_CHUNK, or */
                                   /* NEW_FILE|LAST_CHUNK */
      }
      SaveFileChunk;

      /* used for DBG_SEND_FILE_LIST */
      struct
      {
         jseDbgBool again;
         jseDbgChar list[396];
      }
      FileList;
#     endif

#     ifdef JSE_DEBUG_PASSWORD
      /* this is the struct used for both password messages */
      struct
      {
        jseDbgBool BoolResult;     /* True if password needed for first message */
                                   /* True if password was accepted for second. */
        jseDbgChar TextResult[JSEDBG_PASSWORD_MAX_LEN+1];/* either the encryption key or the resulting */
                                                  /* encrypted password. */
      }
      Password;
#     endif
   } data;
};

/* old info but still has some useful info */

/* 1 debugger allocates and initializes DebugInfo structure */

/* 2 debugger starts debuggeee with first parameter being START_DEBUG_STRING followed
 * by pointer to this structure
 */

/* 3 debuggee waits for commands to execute, where command is indicated by the
 * WM_JSE_DEBUG_MSG message
 */

/* 4 debuggee acts on command and goes back to 3 */


/* Debugging messages occurs through an implementation that acts
 * like a pneumatic tube in that there is only one cannister to
 * contain that data, and that cannister may be filled or emptied
 * only when it is at one's own side.  Implementations of this
 * basic class may vary greatly, especially in initialization.
 */

/*class Cannister
{
public:
    Cannister();
};

class PneumaticTube
{
public:
    Cannister *GetCannister( void );
    void SendCannister( Cannister *c );
};*/

/*PneumaticTube *pn = new PneumaticTube;*/

/* how to send a cannister */
/*Cannister *c = new Cannister( 345, 56, 56435, 54 );*/
/*pn->SendCannister( c );*/

/* how to receive */
/*Cannister *c = pn->GetCannister();*/

#endif
