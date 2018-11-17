/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	input.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines keyboard structures.
 *
 *	$Id: input.h,v 1.1 97/04/04 15:56:56 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__INPUT_H
#define __INPUT_H

#include <char.h>
#include <graphics.h>		/* For "Rectangle" definition */
#include <hwr.h>    	    	/* For "InkPoint"  definition */

/*
 *	PC GEOS Character Value codes
 */

typedef ByteEnum CharacterSet;
#define CS_BSW   	0x00
#define CS_CONTROL   	0xff
#define CS_UI_FUNCS   	0xfe
#define	CS_CALCULATOR	0xfd

#define VC_ISANSI	CS_BSW
#define VC_ISCTRL	CS_CONTROL
#define VC_ISUI		CS_UI_FUNCS
#define	VC_ISCALC	CS_CALCULATOR

/***/

typedef ByteEnum VChar;
#define VC_NULL   	0x0	/* NULL */
#define VC_CTRL_A   	0x1	/* <ctrl>-A */
#define VC_CTRL_B   	0x2	/* <ctrl>-B */
#define VC_CTRL_C   	0x3	/* <ctrl>-C */
#define VC_CTRL_D   	0x4	/* <ctrl>-D */
#define VC_CTRL_E   	0x5	/* <ctrl>-E */
#define VC_CTRL_F   	0x6	/* <ctrl>-F */
#define VC_CTRL_G   	0x7	/* <ctrl>-G */
#define VC_CTRL_H   	0x8	/* <ctrl>-H */
#define VC_CTRL_I   	0x9	/* <ctrl>-I */
#define VC_CTRL_J   	0xa	/* <ctrl>-J */
#define VC_CTRL_K   	0xb	/* <ctrl>-K */
#define VC_CTRL_L   	0xc	/* <ctrl>-L */
#define VC_CTRL_M   	0xd	/* <ctrl>-M */
#define VC_CTRL_N   	0xe	/* <ctrl>-N */
#define VC_CTRL_O   	0xf	/* <ctrl>-O */
#define VC_CTRL_P   	0x10	/* <ctrl>-P */
#define VC_CTRL_Q   	0x11	/* <ctrl>-Q */
#define VC_CTRL_R   	0x12	/* <ctrl>-R */
#define VC_CTRL_S   	0x13	/* <ctrl>-S */
#define VC_CTRL_T   	0x14	/* <ctrl>-T */
#define VC_CTRL_U   	0x15	/* <ctrl>-U */
#define VC_CTRL_V   	0x16	/* <ctrl>-V */
#define VC_CTRL_W   	0x17	/* <ctrl>-W */
#define VC_CTRL_X   	0x18	/* <ctrl>-X */
#define VC_CTRL_Y   	0x19	/* <ctrl>-Y */
#define VC_CTRL_Z   	0x1a	/* <ctrl>-Z */
#define VC_ESCAPE   	0x1b	/* ESC */

#define VC_BLANK   	0x20	/* space */

/* Numeric keypad keys */

#define VC_NUMPAD_ENTER 0xd	/* only on PS/2 keyboards */
#define VC_NUMPAD_DIV  	'/'	/* only on PS/2 keyboards */
#define VC_NUMPAD_MULT  '*'
#define VC_NUMPAD_PLUS  '+'
#define VC_NUMPAD_MINUS '-'
#define VC_NUMPAD_PERIOD '.'
#define VC_NUMPAD_0  	'0'
#define VC_NUMPAD_1  	'1'
#define VC_NUMPAD_2  	'2'
#define VC_NUMPAD_3  	'3'
#define VC_NUMPAD_4  	'4'
#define VC_NUMPAD_5  	'5'
#define VC_NUMPAD_6  	'6'
#define VC_NUMPAD_7  	'7'
#define VC_NUMPAD_8  	'8'
#define VC_NUMPAD_9  	'9'

/* Extended keyboard codes -- non-ASCII */

#define VC_F1   	0x80	/* Function keys */
#define VC_F2   	0x81
#define VC_F3   	0x82
#define VC_F4   	0x83
#define VC_F5   	0x84
#define VC_F6   	0x85
#define VC_F7   	0x86
#define VC_F8   	0x87
#define VC_F9   	0x88
#define VC_F10  	 0x89
#define VC_F11  	 0x8a	/* only on PS/2 keyboards */
#define VC_F12  	 0x8b	/* only on PS/2 keyboards */
#define VC_F13  	 0x8c	/* non-standard key */
#define VC_F14  	 0x8d	/* non-standard key */
#define VC_F15  	 0x8e	/* non-standard key */
#define VC_F16  	 0x8f	/* non-standard key */

#define VC_UP   	0x90	/* Cursor keys */
#define VC_DOWN   	0x91
#define VC_RIGHT   	0x92
#define VC_LEFT   	0x93
#define VC_HOME   	0x94	/* Scroll commands */
#define VC_END   	0x95
#define VC_PREVIOUS   	0x96
#define VC_NEXT   	0x97
#define VC_INS   	0x98	/* INS */
#define VC_DEL   	0x9a	/* DEL */

#define VC_PRINTSCREEN 	0x9b	/* from <shift>-NUMPAD_MULT */
#define VC_PAUSE   	0x9c	/* from <ctrl>-NUMLOCK */
#define VC_BREAK   	0x9e	/* from  <ctrl>- or <alt>-combo */
#define VC_SYSTEMRESET  0x9f	/* <ctrl>-<alt>-<del> combo */

/* Joystick control keys (0xa0 - 0xa9) */

#define	VC_JOYSTICK_0	0xa0	/* joystick 0 degrees */
#define	VC_JOYSTICK_45	0xa1	/* joystick 45 degrees */
#define	VC_JOYSTICK_90	0xa2	/* joystick 90 degrees */
#define	VC_JOYSTICK_135	0xa3	/* joystick 135 degrees */
#define	VC_JOYSTICK_180	0xa4	/* joystick 180 degrees */
#define	VC_JOYSTICK_225	0xa5	/* joystick 225 degrees */
#define	VC_JOYSTICK_270	0xa6	/* joystick 270 degrees */
#define	VC_JOYSTICK_315	0xa7	/* joystick 315 degrees */
#define	VC_FIRE_BUTTON_1 0xa8	/* fire button #1 */
#define	VC_FIRE_BUTTON_2 0xa9	/* fire button #2 */

#define VC_PREV_BUTTON  0xb0    /* Prev-key, if supported */
#define VC_NEXT_BUTTON  0xb1    /* Next-key, if supported */

/* Shift Keys  (0xe0 - 0xe7) */

#define VC_LALT   	0xe0
#define VC_RALT   	0xe1
#define VC_LCTRL   	0xe2
#define VC_RCTRL   	0xe3
#define VC_LSHIFT   	0xe4
#define VC_RSHIFT   	0xe5
#define VC_SYSREQ   	0xe6	/* Not on base PC keyboard */
#define VC_ALT_GR   	0xe7

/* Toggle state keys (0xe8 - 0xeb) */

#define VC_CAPSLOCK   	0xe8
#define VC_NUMLOCK   	0xe9
#define VC_SCROLLLOCK 	0xea

/* More extended keyboard codes -- non-ASCII (0xec - 0xef) */
#define VC_LWIN		0xec
#define VC_RWIN		0xed
#define VC_MENU		0xee

/* Extended state keys (0xf0 - 0xf7) */

/* Invalid key */

#define VC_INVALID_KEY   0xff


#define VC_BACKSPACE	VC_CTRL_H
#define VC_TAB		VC_CTRL_I
#define VC_LF		VC_CTRL_J
#define VC_ENTER	VC_CTRL_M

/*
 *  Calculator functions.
 */

typedef ByteEnum CChar;
#define	CC_SQRT		0x00
#define CC_INVERSE	0x01
#define CC_DIFFER	0x02
#define CC_STACK	0x03
#define CC_LAST		0x04
#define CC_STO		0x05
#define CC_RCL		0x06
#define CC_PLUS_MINUS	0x07

/*
 *	CharFlags
 */

typedef ByteFlags CharFlags;

#define CF_STATE_KEY   	 0x80   /* Set if state key (shift/toggle modifier) */
#define CF_EXTENDED    	 0x10   /* TRUE: extended key	    	      */
#define CF_TEMP_ACCENT 	 0x08   /* Set if temporary accent char	      */
#define CF_FIRST_PRESS 	 0x04   /* Set if initial key press    	      */
#define CF_REPEAT_PRESS	 0x02   /* Set if repeated key press          */
#define CF_RELEASE 	 0x01   /* Set if key release (may be	      */
			    	/* set in conjunction with the	      */
    	    	    	    	/* other two, by monitors or	      */
    	    	    	    	/* UI to lessen # of events)	      */


/* Toggle State	  */

typedef WordFlags ToggleState;
#define TS_SHIFTSTICK   0x80
#define TS_ALTSTICK     0x40
#define TS_CTRLSTICK    0x20
#define TS_FNCTSTICK    0x10
#define TS_CAPSLOCK 	0x04
#define TS_NUMLOCK  	0x02
#define TS_SCROLLLOCK	0x01


/* Format of a keyboard shortcut, as used by the keyboard driver.     	 */
/* KS_ALT, KS_CTRL and KS_SHIFT means the keypress must have the    	 */
/* corresponding modifiers held down. KS_PHYSICAL means match the key,   */
/* not the character value. (this basically means ignore CAPSLOCK and	 */
/* NUMLOCK, as the other modifiers still must match). KS_CHAR_SET is	 */
/* the lower four bits of the CharacterSet, specifying whether the	 */
/* character is a control character or a printable character. KS_CHAR	 */
/* is the character itself, either in Chars or VChar.	    	    	 */

/*typedef ByteFlags KeyboardShortcutFlags;*/

/*
typedef struct {
    unsigned int    	  KS_character : 12;
    unsigned int          KS_flags :4;
} KeyboardShortcut;
*/
typedef WordFlags KeyboardShortcut;

#define KS_PHYSICAL     0x8000	/* TRUE: match key, not character   */
#define KS_ALT  	0x4000	/* TRUE: <ALT> must be pressed	    */
#define KS_CTRL 	0x2000	/* TRUE: <CTRL> must be pressed	    */
#define KS_SHIFT 	0x1000	/* TRUE: <SHIFT> must be pressed    */
#define KS_CHAR_MASK     0x0fff

#ifdef DO_DBCS
#define KS_CHAR_SET_PRINTABLE	0
#define	KS_CHAR_SET_CONTROL 0
#else
#define KS_CHAR_SET_PRINTABLE	(CS_BSW     & 0x0f)
#define KS_CHAR_SET_CONTROL	(CS_CONTROL & 0x0f)
#endif

typedef ByteEnum Button;
#define BUTTON_0 0
#define BUTTON_1 1
#define BUTTON_2 2
#define BUTTON_3 3

typedef ByteFlags ButtonInfo;
#define BI_PRESS		0x80
#define BI_DOUBLE_PRESS		0x40
#define BI_B3_DOWN		0x20
#define BI_B2_DOWN		0x10
#define BI_B1_DOWN		0x08
#define BI_B0_DOWN		0x04
#define BI_BUTTON		0x03

/* State of modifiers */

typedef ByteFlags ShiftState;
#define SS_LALT	    		0x80
#define SS_RALT		    	0x40
#define SS_LCTRL	    	0x20
#define SS_RCTRL    		0x10
#define SS_LSHIFT	    	0x08
#define SS_RSHIFT	    	0x04
#define SS_FIRE_BUTTON_1	0x02
#define SS_FIRE_BUTTON_2	0x01

typedef struct {
    word    	IH_count;
    /* The # ink points collected */

    Rectangle	IH_bounds;
    /* Bounds of the ink on the screen */

    optr    	IH_destination;
    /* The object that the ink was sent to */

    dword   	IH_reserved;
    /* Reserved for future use */

    InkPoint	IH_data;
} InkHeader;

#define	GCF_FIRST_CALL	0x8000
/* If set in the numStrokes field of a GestureCallback function, this means
 * that this is the first time the gesture callback has been called for a
 * given set of user input */

/*
 * Data block format for GWNT_INK_DIGITIZER_COORDS notification.
 */
typedef struct {
    word     IDCH_count;
    /* The number of digitizer coordinates collected */
    
    optr     IDCH_destination;
    /* The destination of the ink. Objects can use this to determine whether
     * the ink was sent to them directly, or just because it overlapped
     * the screen (actually, this is just a hack so the ink object can
     * handle the case where the active tool is the eraser, but the bonehead
     * user enters ink by drawing on the primary and then overlapping the
     * ink object). This field is set by the flow object.
     */

    dword    IDCH_reserved;
    /* Reserved for future use. */

    InkPoint IDCH_data;
} InkDigitizerCoordsHeader;

/*
 * sent out to GCNSLT_SCREEN_SAVER_NOTIFICATIONS
 */
typedef ByteFlags ScrSaverStatus;
#define SSS_ENABLED    0x80
#define SSS_ACTIVE     0x40

#endif ; __INPUT_H
