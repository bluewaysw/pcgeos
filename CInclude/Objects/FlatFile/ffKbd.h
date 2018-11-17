/***********************************************************************
 *
 *      Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:       PCGEOS
 * MODULE:        ffKbd.h
 * FILE:          ffKbd.h
 *
 * AUTHOR:        Jeremy Dashe: Feb 20, 1993
 *
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      2/20/93   jeremy            Initial version
 *
 * DESCRIPTION:
 *      This file contains definitions for keyboard shortcuts used in the
 *      flat file library.
 *
 *
 *      $Id: ffKbd.h,v 1.1 97/04/04 15:50:39 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _FFKBD_H_
#define _FFKBD_H_

#include <input.h>
#ifdef DO_DBCS
#define LITTLE_N C_LATIN_SMALL_LETTER_N
#define LITTLE_I C_LATIN_SMALL_LETTER_I
#define CHAR_ENTER C_SYS_ENTER
#define CHAR_TAB C_SYS_TAB
#else
#define LITTLE_N C_SMALL_N
#define LITTLE_I C_SMALL_I
#define CHAR_ENTER C_ENTER
#define CHAR_TAB C_TAB
#endif

/*
 * Here's the Shortcut Tables as used by the fields.  Indices follow.
 */
/*#define ST_SHIFT_CTRL_ENTER {CHAR_ENTER & KS_CHAR_MASK \
					 | KS_SHIFT | KS_CTRL | KS_CHAR_SET_CONTROL}*/
#define ST_SHIFT_CTRL_ENTER 0x3f0d
/*#define ST_SHIFT_CTRL_TAB   {CHAR_TAB & KS_CHAR_MASK \
					 | KS_SHIFT | KS_CTRL | KS_CHAR_SET_CONTROL} */
#define ST_SHIFT_CTRL_TAB 0x3f09
/*#define ST_ENTER            {CHAR_ENTER & KS_CHAR_MASK \
					 | KS_CHAR_SET_CONTROL}  */
#define ST_ENTER 0x0f0d
/*#define ST_TAB              {CHAR_TAB & KS_CHAR_MASK \
					 | KS_CHAR_SET_CONTROL} */
#define ST_TAB 0x0f09
/*#define ST_SHIFT_ENTER      {CHAR_ENTER & KS_CHAR_MASK \
					 | KS_SHIFT | KS_CHAR_SET_CONTROL} */
#define ST_SHIFT_ENTER 0x1f0d
/*#define ST_SHIFT_TAB        {CHAR_TAB & KS_CHAR_MASK \
					 | KS_SHIFT | KS_CHAR_SET_CONTROL} */
#define ST_SHIFT_TAB 0x1f09
/*#define ST_CTRL_TAB         {CHAR_TAB & KS_CHAR_MASK \
					 | KS_CTRL | KS_CHAR_SET_CONTROL} */
#define ST_CTRL_TAB 0x2f09
/*#define ST_CTRL_ENTER       {CHAR_ENTER & KS_CHAR_MASK \
					 | KS_CTRL | KS_CHAR_SET_CONTROL} */
#define ST_CTRL_ENTER 0x2f0d
#define ST_CTRL_N           {LITTLE_N & KS_CHAR_MASK \
			       | KS_CTRL | KS_PHYSICAL | KS_CHAR_SET_PRINTABLE}
#define ST_CTRL_COMMA       {C_COMMA & KS_CHAR_MASK \
			       | KS_CTRL | KS_PHYSICAL | KS_CHAR_SET_PRINTABLE}
#define ST_CTRL_PERIOD      {C_PERIOD & KS_CHAR_MASK \
			       | KS_CTRL | KS_PHYSICAL | KS_CHAR_SET_PRINTABLE}
#define ST_SHIFT_CTRL_COMMA {C_COMMA & KS_CHAR_MASK \
			       | KS_CTRL | KS_PHYSICAL | KS_SHIFT | \
				 KS_CHAR_SET_PRINTABLE}
#define ST_SHIFT_CTRL_PERIOD {C_PERIOD & KS_CHAR_MASK \
				| KS_CTRL | KS_PHYSICAL | KS_SHIFT | \
				 KS_CHAR_SET_PRINTABLE}
#define ST_CTRL_SEMICOLON   {C_SEMICOLON & KS_CHAR_MASK \
			       | KS_CTRL | KS_PHYSICAL | KS_CHAR_SET_PRINTABLE}
#define ST_CTRL_I           {LITTLE_I & KS_CHAR_MASK \
			       | KS_CTRL | KS_PHYSICAL | KS_CHAR_SET_PRINTABLE}

/*
 * Here's the definition of the keyboard shortcut table used within
 * the flat file library.
 */
#define  FF_SHORTCUT_TABLE                                      \
	 ST_SHIFT_CTRL_ENTER,      /* INSERT_ENTER_CHAR */      \
	 ST_SHIFT_CTRL_TAB,        /* INSERT_TAB_CHAR */        \
	 ST_ENTER,                 /* Next field */             \
	 ST_TAB,                   /* Next field */             \
	 ST_SHIFT_ENTER,           /* Previous field */         \
	 ST_SHIFT_TAB,             /* Previous field */         \
	 ST_CTRL_TAB,              /* Previous field */         \
	 ST_CTRL_ENTER,            /* New record */             \
	 ST_CTRL_N,                /* New record */             \
	 ST_CTRL_COMMA,            /* Previous record */        \
	 ST_CTRL_PERIOD,           /* Next record */            \
	 ST_SHIFT_CTRL_COMMA,      /* First record */           \
	 ST_SHIFT_CTRL_PERIOD,     /* Last record */            \
	 ST_CTRL_SEMICOLON,        /* Mark current record */    \
	 ST_CTRL_I                 /* Commit current record */

/*
 * The shortcut code table, which matches one-for-one with the above
 * shortcut character definition table.  Match 'em or weep.
 *
 * Note that since each element of the above table is a word, and the returned
 * value from FlowCheckKbdShortcut() is an offset into the above table,
 * each code below is incremented by 2 ( == sizeof(word)).
 */
typedef enum /* word */ {
    SC_INSERT_ENTER_CHAR = 0,
    SC_INSERT_TAB_CHAR   = 2,
    SC_NEXT_FIELD        = 4,
    SC_NEXT_FIELD_2      = 6,
    SC_PREVIOUS_FIELD    = 8,
    SC_PREVIOUS_FIELD_2  = 10,
    SC_PREVIOUS_FIELD_3  = 12,
    SC_NEW_RECORD        = 14,
    SC_NEW_RECORD_2      = 16,
    SC_PREVIOUS_RECORD   = 18,
    SC_NEXT_RECORD       = 20,
    SC_FIRST_RECORD      = 22,
    SC_LAST_RECORD       = 24,
    SC_MARK_RECORD       = 26,
    SC_COMMIT_RECORD     = 28
} ShortcutCode;


#endif /* _FFKBD_H_ */


