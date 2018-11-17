/***********************************************************************
 *
 * PROJECT:	  HTMLView
 * FILE:          javascr.h
 *
 * DESCRIPTION:   Main include file for all modules using
 *                JavaScript functions
 *
 * AUTHOR:	  Marcus Groeber
 *
 ***********************************************************************/

#if JAVASCRIPT_SUPPORT
#define JSE_BROWSEROBJECTS 1
#include <js/jseopt.h>

#include "sebrowse.h"

/* Other routines from browser object mod that we want to be public.... */
jseVariable browserWindowObject(jseContext jsecontext,struct BrowserWindow *window);

jseVariable JSWindowObject(jseContext jsecontext, optr frame);
jseVariable JSImageObject(jseContext jsecontext, optr frame, word i);
jseVariable JSFormObject(jseContext jsecontext,optr text,word i);
jseVariable JSElementObject(jseContext jsecontext, optr text, word i);
jseVariable JSLinkObject(jseContext jsecontext, optr frame, word i);

/* Data structure for describing a script source */
typedef struct {
  Boolean BSS_isToken;    /* TRUE if script is stored in a NameToken */
  union {
    struct {              /* data for scripts coming from a HugeArray */
      VMFileHandle vmf;   /* file holding HA */
      VMBlockHandle vmb;  /* initial block of HA */
    } array;
    struct {              /* data for scripts stored as NameToken */
      NameToken code;     /* token holding the code */
    } token;
  } BSS_data;
  dword BSS_offset;       /* current position in script */
} BrowserScriptSource;

/* To keep Borland C quiet... */
struct Call { int dummy; };
struct seCallStack { int dummy; };
struct seAPIVar { int dummy; };


/***************************************************************************
 *              Internal property names
 ***************************************************************************/

/* These definitions override the external constants from the header file.
   This is done because string constants in library files don't work well
   with Borland C. The names must match those used in GLOBAL.GOC of the
   js library. */

#define ARRAY_PROPERTY      UNISTR("_array")
#define CANPUT_PROPERTY     UNISTR("_canPut")
#define DEFAULT_PROPERTY    UNISTR("_defaultValue")
#define DELETE_PROPERTY     UNISTR("_delete")
#define GET_PROPERTY        UNISTR("_get")
#define HASPROPERTY_PROPERTY UNISTR("_hasProperty")
#define LENGTH_PROPERTY     UNISTR("_length")
#define ORIG_PROTOTYPE_PROPERTY   UNISTR("prototype")
#define PARENT_PROPERTY     UNISTR("__parent__")
#define PROTOTYPE_PROPERTY  UNISTR("_prototype")
#define PUT_PROPERTY        UNISTR("_put")
#define VALUE_PROPERTY      UNISTR("_value")
#define FUNCTION_PROPERTY   UNISTR("Function")


/***************************************************************************
 *              JavaScript globals in browser
 ***************************************************************************/
extern jseContext jsecontext;

void InitBrowserJS(void);
void ExitBrowserJS(void);

#define JS_SCHEME _TEXT("javascript:")

/* enable to do more GC to try to reduce memory usage at expense of
   performance */
//#define EXTRA_GC

/* threshold time to define a runaway JS script, in ticks */
#define RUNAWAY_JS_TIME 10*60  /* 10 seconds */
#define RUNAWAY_MAX_TIMES 3  /* give up after third box acknowledged
				and timeout again (total of 40 seconds) */

#endif
