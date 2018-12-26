/*
 * jerror.c
 *
 * Copyright (C) 1991-1996, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This file contains simple error-reporting and trace-message routines.
 * The Geos version shows error messages in standard dialog boxes.
 *
 * These routines are used by both the compression and decompression code.
 */

#include <geos.h>
#include <uDialog.h>
#include <ec.h>
#include <heap.h>

/* this is not a core library module, so it doesn't define JPEG_INTERNALS */
#include "jinclude.h"
#include "jpeglib.h"
#include "jversion.h"
#include "jerror.h"

#ifndef EXIT_FAILURE		/* define exit() codes if not provided */
#define EXIT_FAILURE  1
#endif


/*
 * Error exit handler: must not return to caller.
 *
 * Applications may override this if they want to get control back after
 * an error.  Typically one would longjmp somewhere instead of exiting.
 * The setjmp buffer can be made a private field within an expanded error
 * handler object.  Note that the info needed to generate an error message
 * is stored in the error object, so you can generate the message now or
 * later, at your convenience.
 * You should make sure that the JPEG object is cleaned up (with jpeg_abort
 * or jpeg_destroy) at some point.
 */

extern void jmp_to_error_handler(word errorHandlerContext);

METHODDEF(void)
error_exit (j_common_ptr cinfo)
{
  struct jpeg_error_mgr * err = cinfo->err;

  /* Always display the message */
  /* with new error handling below, no error message if out-of-memory and
     error context */
#if 0  /* silently pass errors to avoid page loading delays */
  if ((err->msg_code != JERR_OUT_OF_MEMORY) ||
      !(err->error_handler_context)) {
      MCALL1(output_message, cinfo->err, cinfo);
  }
#endif

  /* Let the memory manager delete any temp files before we die */
  jpeg_destroy(cinfo);

// exit(EXIT_FAILURE);
//  FatalError(-1);
//better error handling:
  if (err->error_handler_context) {
      jmp_to_error_handler(err->error_handler_context);
      /* returns if jmp to error handler fails */
  }
  FatalError(-1);
}


/*
 * Actual output of an error or trace message.
 * Applications may override this method to send JPEG messages somewhere
 * other than standard dialog boxes.
 */

METHODDEF(void)
output_message (j_common_ptr cinfo)
{
  char buffer[JMSG_LENGTH_MAX];

  /* Create the message */
  MCALL2(format_message, cinfo->err, cinfo, buffer);

  /* Send it to screen */
  UserStandardDialog
      (NULL,        /* help context */
       NULL,        /* custom triggers */
       NULL,        /* arg2 to string */
       NULL,        /* arg1 to string */
       buffer,      /* string */
       (CDT_ERROR << CDBF_DIALOG_TYPE_OFFSET) |
         (GIT_NOTIFICATION << CDBF_INTERACTION_TYPE_OFFSET));
                    /* dialog type */
}


/*
 * Decide whether to emit a trace or warning message.
 * msg_level is one of:
 *   -1: recoverable corrupt-data warning, may want to abort.
 *    0: important advisory messages (always display to user).
 *    1: first level of tracing detail.
 *    2,3,...: successively more detailed tracing messages.
 * An application might override this method if it wanted to abort on warnings
 * or change the policy about which messages to display.
 */

METHODDEF(void)
emit_message (j_common_ptr cinfo, int msg_level)
{
  struct jpeg_error_mgr * err = cinfo->err;

  if (msg_level < 0) {
    /* It's a warning message.  Since corrupt files may generate many warnings,
     * the policy implemented here is to show only the first warning,
     * unless trace_level >= 3.
     */
    if (err->num_warnings == 0 || err->trace_level >= 3)
      MCALL1(output_message, err, cinfo);
    /* Always count warnings in num_warnings. */
    err->num_warnings++;
  } else {
    /* It's a trace message.  Show it if trace_level >= msg_level. */
    if (err->trace_level >= msg_level)
      MCALL1(output_message, err, cinfo);
  }
}


/*
 * Format a message string for the most recent JPEG error or message.
 * The message is stored into buffer, which should be at least JMSG_LENGTH_MAX
 * characters.  Note that no '\n' character is added to the string.
 * Few applications should need to override this method.
 */

METHODDEF(void)
format_message (j_common_ptr cinfo, char * buffer)
{
  struct jpeg_error_mgr * err = cinfo->err;
  int msg_code = err->msg_code;
  const char * msgtext = NULL;
  const char * msgptr;
  char ch;
  boolean isstring;
  char defErrStr[] = "JPEG error %d";

  /* Look up message string in proper table */
  if (err->jpeg_message_table && msg_code > 0 && msg_code <= err->last_jpeg_message) {
    msgtext = err->jpeg_message_table[msg_code];
  } else if (err->addon_message_table != NULL &&
	     msg_code >= err->first_addon_message &&
	     msg_code <= err->last_addon_message) {
    msgtext = err->addon_message_table[msg_code - err->first_addon_message];
  }

  /* Defend against bogus message number */
  if (msgtext == NULL) {
    err->msg_parm.i[0] = msg_code;
    if (err->jpeg_message_table) {
	msgtext = err->jpeg_message_table[0];
    } else {
      msgtext = defErrStr;
    }
  }

  /* Check for string parameter, as indicated by %s in the message text */
  isstring = FALSE;
  msgptr = msgtext;
  while ((ch = *msgptr++) != '\0') {
    if (ch == '%') {
      if (*msgptr == 's') isstring = TRUE;
      break;
    }
  }

  /* Format the message into the passed buffer */
  if (isstring)
    sprintf(buffer, msgtext, err->msg_parm.s);
  else
    sprintf(buffer, msgtext,
	    err->msg_parm.i[0], err->msg_parm.i[1],
	    err->msg_parm.i[2], err->msg_parm.i[3],
	    err->msg_parm.i[4], err->msg_parm.i[5],
	    err->msg_parm.i[6], err->msg_parm.i[7]);
}


/*
 * Reset error state variables at start of a new image.
 * This is called during compression startup to reset trace/error
 * processing to default state, without losing any application-specific
 * method pointers.  An application might possibly want to override
 * this method if it has additional error processing state.
 */

METHODDEF(void)
reset_error_mgr (j_common_ptr cinfo)
{
  cinfo->err->num_warnings = 0;
  /* trace_level is not reset since it is an application-supplied parameter */
  cinfo->err->msg_code = 0;	/* may be useful as a flag for "no error" */
}


/*
 * Fill in the standard error-handling methods in a jpeg_error_mgr object.
 * Typical call is:
 *	struct jpeg_compress_struct cinfo;
 *	struct jpeg_error_mgr err;
 *
 *	cinfo.err = jpeg_std_error(&err);
 * after which the application may override some of the methods.
 */

GLOBAL(struct jpeg_error_mgr *)
jpeg_std_error (struct jpeg_error_mgr * err)
{
  MASSIGN(err->error_exit, error_exit);
  MASSIGN(err->emit_message, emit_message);
  MASSIGN(err->output_message, output_message);
  MASSIGN(err->format_message, format_message);
  MASSIGN(err->reset_error_mgr, reset_error_mgr);

  err->trace_level = 0;		/* default = no tracing */
  err->num_warnings = 0;	/* no warnings emitted yet */
  err->msg_code = 0;		/* may be useful as a flag for "no error" */

  /* Initialize message table pointers */
  err->jpeg_message_table = /* jpeg_std_message_table; */ NULL;
  err->last_jpeg_message = (int) JMSG_LASTMSGCODE - 1;

  err->addon_message_table = NULL;
  err->first_addon_message = 0;	/* for safety */
  err->last_addon_message = 0;

  err->error_handler_context = 0;

  return err;
}

GLOBAL(void)
jpeg_set_error_handler_context(j_common_ptr cinfo, word errorHandlerContext)
{
    struct jpeg_error_mgr *err = cinfo->err;

    if (err->error_handler_context) {
	MemFree(err->error_handler_context);
    }
    err->error_handler_context = errorHandlerContext;
}
