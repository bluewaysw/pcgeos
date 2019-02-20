/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- X11 interface, Tty class implementation
 * FILE:	  Tty.c
 *
 * AUTHOR:  	  Adam de Boor: Apr 23, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to implement the TTY widget -- a subclass of the
 *	text widget that acts much like a standard tty, except
 *	there's no process running under it.
 *
 *	The data for the source are kept in two pieces: a read-only (or
 *	nearly so) log file and a fully editable memory buffer.
 *
 *	The current input line is kept in the memory buffer where it
 *	may be edited in a standard emacs-like manner. The current
 *	input line is defined by the end of the edit buffer and a
 *	position known as the "fence" that is set by the creator of the
 *	widget, after issuing each prompt, using the function
 *	XtTtySourceSetFence.
 *
 *	The fence is used at several points:
 *	    - the backward-delete-to-prompt action deletes all text
 *	      between the fence and the end of the edit buffer.
 *	    - the enter action passes all text between the fence and the
 *	      end of the edit buffer as the input line.
 *	    - the source text replacement function will refuse to allow
 *	      edits to text behind the fence.
 *
 *	Good thing to do: provide all translations as our accelerators.
 *	This will allow someone to install these accelerators on our
 *	parent so as to have all uncaptured keystrokes go to us.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: Tty.c,v 1.3 89/07/29 15:57:00 adam Exp $";
#endif lint

#include    <X11/IntrinsicP.h>
#include    <X11/Xos.h>
#include    <X11/StringDefs.h>
#include    <X11/Xatom.h>
#include    <stdio.h>
#include    "TtyP.h"

/*#include    <sys/file.h>*/
#include    <stdarg.h>
#include    <ctype.h>

#define TTY_BUF_SIZE 1024

#define DEFAULT_HEIGHT	24
#define DEFAULT_WIDTH	80

XtTextSource	XtTtySourceCreate();
void		XtTtySourceDestroy();
void		XtTtySourceSetFence();
XtTextPosition	XtTtySourceGetFence();
void	    	XtTtySourceGetChar();
void	    	XtTtySourceCharGotten();

static int  	  	defOptions = scrollVertical|scrollOnOverflow;

static XtResource 	resources[] = {
{ XtNenterCallback, XtCCallback, XtRCallback, sizeof(caddr_t),
  XtOffset(TtyWidget, tty.enter), XtRCallback, (caddr_t)NULL },
{ XtNtextOptions, XtCTextOptions, XtRInt, sizeof(int),
  XtOffset(TtyWidget, text.options), XtRInt, (caddr_t)&defOptions },
{ XtNinterruptCallback, XtCCallback, XtRCallback, sizeof(caddr_t),
  XtOffset(TtyWidget, tty.interrupt), XtRCallback, (caddr_t)NULL },
{ XtNgeometry, XtCGeometry, XtRString, sizeof(char *),
  XtOffset(TtyWidget, tty.geometry), XtRString, (caddr_t)NULL },
};

/*
 * Forwards for action procedures
 */
static void	  	Enter(), KillLine(), SetMark(),
			SaveRegion(), Interrupt();

static XtActionsRec 	actions[] = {
{"enter", Enter},
{"backward-delete-to-prompt", KillLine },
{"set-mark", SetMark },
{"save-region", SaveRegion },
{"interrupt", Interrupt },
{NULL, NULL}
};

/*
 * New translations -- adds enter to the various newline() translations.
 */
static char defaultTranslations[] =
"\
Ctrl<Key>@: 	set-mark()\n\
Ctrl<Key>0x20:	set-mark()\n\
Ctrl<Key>F:	forward-character() \n\
Ctrl<Key>B:	backward-character() \n\
Ctrl<Key>C: 	interrupt() \n\
Ctrl<Key>D:	delete-next-character() \n\
Ctrl<Key>A:	beginning-of-line() \n\
Ctrl<Key>E:	end-of-line() \n\
Ctrl<Key>H:	delete-previous-character() \n\
Ctrl<Key>J:	newline-and-indent() \n\
Ctrl<Key>K:	kill-to-end-of-line() \n\
Ctrl<Key>L:	redraw-display() \n\
Ctrl<Key>M:	newline() enter()\n\
Ctrl<Key>N:	next-line() \n\
Ctrl<Key>O:	newline-and-backup() \n\
Ctrl<Key>P:	previous-line() \n\
Ctrl<Key>V:	next-page() \n\
:Ctrl<Key>w:	delete-previous-word() \n\
:Ctrl<Key>W:	kill-selection()\n\
Ctrl<Key>X: 	backward-delete-to-prompt() \n\
Ctrl<Key>Y:	unkill() \n\
Ctrl<Key>Z:	scroll-one-line-up() \n\
Meta<Key>F:	forward-word() \n\
Meta<Key>B:	backward-word() \n\
Meta<Key>I:	insert-file() \n\
Meta<Key>K:	kill-to-end-of-paragraph() \n\
Meta<Key>W: 	save-region() \n\
Meta<Key>V:	previous-page() \n\
Meta<Key>Y:	stuff() \n\
Meta<Key>Z:	scroll-one-line-down() \n\
:Meta<Key>d:	delete-next-word() \n\
:Meta<Key>D:	kill-word() \n\
:Meta<Key>h:	delete-previous-word() \n\
:Meta<Key>H:	backward-kill-word() \n\
:Meta<Key>\\<:	beginning-of-file() \n\
:Meta<Key>\\>:	end-of-file() \n\
:Meta<Key>]:	forward-paragraph() \n\
:Meta<Key>[:	backward-paragraph() \n\
~Shift Meta<Key>Delete:		delete-previous-word() \n\
 Shift Meta<Key>Delete:		backward-kill-word() \n\
~Shift Meta<Key>Backspace:	delete-previous-word() \n\
 Shift Meta<Key>Backspace:	backward-kill-word() \n\
<Key>Right:	forward-character() \n\
<Key>Left:	backward-character() \n\
<Key>Down:	next-line() \n\
<Key>Up:	previous-line() \n\
<Key>Delete:	delete-previous-character() \n\
<Key>BackSpace:	delete-previous-character() \n\
<Key>Linefeed:	newline-and-indent() \n\
<Key>Return:	newline() enter()\n\
<Key>:		insert-char() \n\
<FocusIn>:	focus-in() \n\
<FocusOut>:	focus-out() \n\
<Btn1Down>:	select-start() \n\
<Btn1Motion>:	extend-adjust() \n\
<Btn1Up>:	extend-end(PRIMARY, CUT_BUFFER0) \n\
<Btn2Down>:	insert-selection(PRIMARY, CUT_BUFFER0) \n\
<Btn3Down>:	extend-start() \n\
<Btn3Motion>:	extend-adjust() \n\
<Btn3Up>:	extend-end(PRIMARY, CUT_BUFFER0) \
";

static void TtyInitialize(), TtyDestroy(), TtyInitializeHook();
static XtGeometryResult TtyQueryGeometry();

TtyClassRec ttyClassRec = {
  { /* core fields */
    /* superclass       */      (WidgetClass) &textClassRec,
    /* class_name       */      "Tty",
    /* widget_size      */      sizeof(TtyRec),
    /* class_initialize */      NULL,
    /* class_part_init  */	NULL,
    /* class_inited     */      FALSE,
    /* initialize       */      TtyInitialize,
    /* initialize_hook  */	TtyInitializeHook,
    /* realize          */      XtInheritRealize,
    /* actions          */      actions,
    /* num_actions      */      XtNumber(actions),
    /* resources        */      resources,
    /* num_ resource    */      XtNumber(resources),
    /* xrm_class        */      NULLQUARK,
    /* compress_motion  */      TRUE,
    /* compress_exposure*/      FALSE,
    /* compress_enterleave*/	TRUE,
    /* visible_interest */      FALSE,
    /* destroy          */      TtyDestroy,
    /* resize           */      XtInheritResize,
    /* expose           */      XtInheritExpose,
    /* set_values       */      NULL,
    /* set_values_hook  */	NULL,
    /* set_values_almost*/	XtInheritSetValuesAlmost,
    /* get_values_hook  */	NULL,
    /* accept_focus     */      XtInheritAcceptFocus,
    /* version          */	XtVersion,
    /* callback_private */      NULL,
    /* tm_table         */      defaultTranslations,
    /* query_geometry	*/  	TtyQueryGeometry,
    /* display_accelerator*/	XtInheritDisplayAccelerator,
    /* extension	*/	NULL
  },
  { /* text fields */
    /* empty            */      0
  },
  { /* tty fields */
    /* empty	  	*/  	0
  }
};

WidgetClass ttyWidgetClass  = (WidgetClass)&ttyClassRec;

/*-
 *-----------------------------------------------------------------------
 * TtyInitialize --
 *	Initialize a Tty widget -- duplicate prompt string, if any and
 *	initialize startPos and prompted.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	See above.
 *
 *-----------------------------------------------------------------------
 */
static void
TtyInitialize(request, new)
    Widget  	  request;
    Widget	  new;
{
    TtyWidget	  tty = (TtyWidget)new;

    tty->tty.markPos = 0;

    /* superclass Initialize can't set the following,
     * as it didn't know the source or sink when it was called */
    if (request->core.height == DEFAULT_TEXT_HEIGHT) {
	new->core.height = DEFAULT_TEXT_HEIGHT;
    }
}

/*-
 *-----------------------------------------------------------------------
 * TtyInitializeHook --
 *	Create the necessary source and sink for this beastie.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The source and sink are created for the widget.
 *
 *-----------------------------------------------------------------------
 */
static void
TtyInitializeHook(w, args, num_args)
    Widget  	  w;
    ArgList	  args;
    Cardinal	  *num_args;
{
    TtyWidget	    tty = (TtyWidget)w;
    static XFontStruct  *f;
    static XtResource garbage[] = {
    { XtNfont, XtCFont, XtRFontStruct, sizeof(f), (caddr_t)&f,
      XtRString, (caddr_t)"Fixed" },
    };
    long	wid;
    
    /*
     * Create the source and the sink
     */
    tty->text.source = XtTtySourceCreate(w, args, *num_args);
    tty->text.sink = XtAsciiSinkCreate(w, args, *num_args);

    /*
     * Damn AsciiSink neither places the font being used in the
     * XtTextSink as it should, nor is there any way to get at the
     * spacing being used for the f'ing thing, so we go through all
     * this GARBAGE to figure the thing out.
     */
    XtGetSubresources(tty, (caddr_t)0, XtNtextSink, XtCTextSink,
		      garbage, XtNumber(garbage),
		      (ArgList)NULL, 0);
    
    if (!XGetFontProperty(f, XA_QUAD_WIDTH, &wid) || wid <= 0) {
	/*
	 * Font doesn't have a QUAD_WIDTH property -- see if we've
	 * got the per-character stats for '0' (the paradigm of
	 * average characterhood, you know).
	 */
	if (f->per_char && (f->min_char_or_byte2 <= '0' &&
			    f->max_char_or_byte2 >= '0'))
	{
	    /*
	     * Yes -- use them
	     */
	    wid = f->per_char['0' - f->min_char_or_byte2].width;
	} else {
	    /*
	     * Use the width of the bounding box (do *not* use
	     * lbearing and rbearing).
	     */
	    wid = f->max_bounds.width;
	}
    }
    

    tty->tty.charWidth = (int)wid;
    tty->tty.charHeight = (*tty->text.sink->MaxHeight)(tty, 1);

    /*
     * Seek to the end of the file.
     */
    tty->text.lastPos = /* GETLASTPOS */
      (*tty->text.source->Scan) (tty->text.source, 0, XtstAll,
				 XtsdRight, 1, TRUE );

    /*
     * Deal with any geometry spec, using DEFAULT_HEIGHT and DEFAULT_WIDTH
     * for missing aspects and DEFAULT_HEIGHT if height not yet
     * specified and no geometry given.
     */
    if (tty->tty.geometry) {
	int 	x;		/* JUNK */
	int 	y;		/* JUNK */
	int 	width;		/* Width from geometry */
	int 	height;		/* Height from geometry */
	int 	flags;		/* Flags from geometry */

	flags = XParseGeometry(tty->tty.geometry, &x, &y, &width, &height);
	
	if (flags & WidthValue) {
	    width *= tty->tty.charWidth;
	} else {
	    width = DEFAULT_WIDTH * tty->tty.charWidth;
	}
	/* Account for scrollbar */
	width += tty->text.leftmargin;

	if (flags & HeightValue) {
	    height *= tty->tty.charHeight;
	} else {
	    height = DEFAULT_HEIGHT * tty->tty.charHeight;
	}

	tty->core.width = width;
	tty->core.height = height;
    } else if (tty->core.height == DEFAULT_TEXT_HEIGHT) {
        tty->core.height =
	    (2*yMargin) + 2 + (*tty->text.sink->MaxHeight)(tty,DEFAULT_HEIGHT);
    }

    /*
     * Adjust the scrollbar to match
     */
    XtResizeWidget(tty->text.sbar,
		   tty->text.sbar->core.width,
		   tty->core.height,
		   tty->text.sbar->core.border_width);

    /*
     * Set the tab-stops for the thing at every 8 spaces.
     */
    if (tty->text.sink->SetTabs != NULL) {
#define TAB_COUNT   32
	int 	i;
	Position tabs[TAB_COUNT], tab;

	for (i=0, tab=0; i<TAB_COUNT;i++) {
	    tabs[i] = (tab += 8);
	}
	(*tty->text.sink->SetTabs) (w, tty->text.leftmargin, TAB_COUNT, tabs);
#undef TAB_COUNT
    }
	
    /*
     * Redisplay the entire thing
     */
    ForceBuildLineTable( (TextWidget)tty );
}

/*-
 *-----------------------------------------------------------------------
 * TtyDestroy --
 *	Destroy the source and sink for the widget.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The source and sink c'est freed.
 *
 *-----------------------------------------------------------------------
 */
static void
TtyDestroy(w)
    Widget  	  w;
{
    TtyWidget	  tty = (TtyWidget)w;

    XtTtySourceDestroy(tty->text.source);
    XtAsciiSinkDestroy(tty->text.sink);
}


/***********************************************************************
 *				TtyQueryGeometry
 ***********************************************************************
 * SYNOPSIS:	    Tell the parent how big we'd like to be.
 * CALLED BY:	    Parent's geometry manager.
 * RETURN:	    XtGeometryAlmost or XtGeometryYes
 * SIDE EFFECTS:    The fields of the preferred are filled in.
 *
 * STRATEGY:
 *	We want to make sure we're only resized in increments of the
 *	font box we're using. If either the width or the height isn't
 *	a multiple, round it down to the nearest multiple.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/18/89		Initial Revision
 *
 ***********************************************************************/
static XtGeometryResult
TtyQueryGeometry(w, intended, preferred)
    Widget  	    	w;  	    /* Widget being queried */
    XtWidgetGeometry	*intended;  /* Intended geometry */
    XtWidgetGeometry	*preferred; /* What we'd really like */
{
    TtyWidget	    	tty = (TtyWidget)w;
    XtGeometryResult	res = XtGeometryYes;
    
    /*
     * Copy all fields since we look at so few...
     */
    *preferred = *intended;

    if (preferred->request_mode & CWWidth) {
	/*
	 * Wants to change our width -- round the thing down to the nearest
	 * character (perhaps should round up instead?). Note that we
	 * don't let the leftMargin enter into it...it can be whatever
	 * size it wants to be.
	 */
	preferred->width =
	    ((intended->width - tty->text.leftmargin) / tty->tty.charWidth) *
		tty->tty.charWidth + tty->text.leftmargin;
	if (preferred->width != intended->width) {
	    res = XtGeometryAlmost;
	}
    } else {
	preferred->request_mode |= CWWidth;
	preferred->width = tty->core.width;
    }
    
    if (preferred->request_mode & CWHeight) {
	/*
	 * Wants to change our height -- round down to the nearest character
	 * (again, should we round up?).
	 */
	preferred->height =
	    ((intended->height / tty->tty.charHeight) * tty->tty.charHeight) +
		(2*yMargin);
	if (preferred->height != intended->height) {
	    res = XtGeometryAlmost;
	}
    } else {
	/*
	 * VPaned likes to use this result, even if it's not asking about it,
	 * so I figure we ought to set it.
	 */
	preferred->request_mode |= CWHeight;
	preferred->height = tty->core.height;
    }

    /*
     * As for everything else, the parent can do what it wants...
     */
    return(res);
}
/*-
 *-----------------------------------------------------------------------
 * XtTtyNumColumns --
 *	Return the number of columns in the given tty widget.
 *
 * Results:
 *	The number of columns in the widget.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
int
XtTtyNumColumns(w)
    Widget  	  	w;
{
    TtyWidget	  	tty = (TtyWidget)w;

    return ((tty->core.width - tty->text.leftmargin) / tty->tty.charWidth);
}
    
/*-
 *-----------------------------------------------------------------------
 * XtTtyPrintf --
 *	Perform a printf to the given widget at its end. The buffer used
 *	is as big as that used in the Tty source. This is a kludge,
 *	however. What should happen is either the proper-sized buffer
 *	should be determined, allocated, printed-to and broken into
 *	decent-sized chunks for TtyReplaceText, or the thing printed
 *	piecemeal, thus replicating printf into here...
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The characters are added to the window.
 *
 *-----------------------------------------------------------------------
 */
/*VARARGS*/
void
XtTtyPrintf(Widget  w, char *fmt, ...)
{
    va_list		args;

    va_start(args, fmt);

    XtTtyVPrintf(w, fmt, args);

    va_end(args);
}

/************************************************************************
 * The following code is taken from the Sprite vfprintf.c:
 *
 * Copyright 1988 Regents of the University of California
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright
 * notice appear in all copies.  The University of California
 * makes no representations about the suitability of this
 * software for any purpose.  It is provided "as is" without
 * express or implied warranty.
 *
 ***********************************************************************/
/*
 * The following defines the size of buffer needed to hold the ASCII
 * digits for the largest floating-point number and the largest integer.
 */

#define CVT_DBL_BUF_SIZE 320
#define CVT_INT_BUF_SIZE 33

/*
 *----------------------------------------------------------------------
 *
 * CvtUtoA --
 *
 *	Convert a number from internal form to a sequence of
 *	ASCII digits.
 *
 * Results:
 *	The return value is a pointer to the ASCII digits representing
 *	i, and *lengthPtr will be filled in with the number of digits
 *	stored at the location pointed to by the return value.  The
 *	return value points somewhere inside buf, but not necessarily
 *	to the beginning.  Note:  the digits are left null-terminated.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static char *
CvtUtoA(i, base, buf, lengthPtr)
    register unsigned i;	/* Value to convert. */
    register int base;		/* Base for conversion.  Shouldn't be
				 * larger than 36.  2, 8, and 16
				 * execute fastest.
				 */
    register char *buf;		/* Buffer to use to hold converted string.
				 * Must hold at least CVT_INT_BUF_SIZE bytes.*/
    int *lengthPtr;		/* Number of digits is stored here. */
{
    register char *p;

    /*
     * Handle a zero value specially.
     */

    if (i == 0) {
	buf[0] = '0';
	buf[1] = 0;
	*lengthPtr = 1;
	return buf;
    }

    /*
     * Build the string backwards from the end of the result array.
     */

    p = &buf[CVT_INT_BUF_SIZE-1];
    *p = 0;

    switch (base) {

	case 2:
	    while (i != 0) {
		p -= 1;
		*p = '0' + (i & 01);
		i >>= 1;
	    }
	    break;
    
	case 8:
	    while (i != 0) {
		p -= 1;
		*p = '0' + (i & 07);
		i >>= 3;
	    }
	    break;
	
	case 16:
	    while (i !=0) {
		p -= 1;
		*p = '0' + (i & 0xf);
		if (*p > '9') {
		    *p += 'a' - '9' - 1;
		}
		i >>= 4;
	    }
	    break;
	
	default:
	    while (i != 0) {
		p -= 1;
		*p = '0' + (i % base);
		if (*p > '9') {
		    *p += 'a' - '9' - 1;
		}
		i /= base;
	    }
	    break;
    }

    *lengthPtr = (&buf[CVT_INT_BUF_SIZE-1] - p);
    return p;
}

/*
 *----------------------------------------------------------------------
 *
 * CvtFtoA --
 *
 *	This procedure converts a double-precision floating-point
 *	number to a string of ASCII digits.
 *
 * Results:
 *	The characters at buf are modified to hold up to numDigits ASCII
 *	characters, followed by a null character.  The digits represent
 *	the most significant numDigits digits of value, with the lowest
 *	digit rounded.  The value at *pointPtr is modified to hold
 *	the number of characters in buf that precede the decimal point.
 *	A negative value of *pointPtr means zeroes must be inserted
 *	between the point and buf[0].  If value is negative, *signPtr
 *	is set to TRUE;	otherwise it is set to FALSE.  The return value
 *	is the number of digits stored in buf, which is either:
 *	(a) numDigits (if the number is so huge that all numDigits places are
 *	    used before getting to the right precision level, or if
 *	    afterPoint is -1)
 *	(b) afterPoint + *pointPtr (the normal case if afterPoint isn't -1)
 *	If there were no significant digits within the specified precision,
 *	then *pointPtr gets set to -afterPoint and 0 is returned.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static int
CvtFtoA(value, numDigits, afterPoint, pointPtr, signPtr, buf, fpError)
    double value;		/* Value to be converted. */
    int numDigits;		/* Maximum number of significant digits
				 * to generate in result. */
    int afterPoint;		/* Maximum number of digits to generate
				 * after the decimal point.  If -1, then
				 * there there is no limit. */
    int *pointPtr;		/* Will be filled in with position of
				 * decimal point (number of digits before
				 * decimal point). */
    int *signPtr;		/* Modified to indicate whether or not
				 * value was negative. */
    char *buf;			/* Place to store ASCII digits.  Must hold
				 * at least numDigits+1 bytes. */
    int *fpError;               /* pointer to flag that is set if the number
                                   is not a valid number. */

{
    extern double modf();
    register char *p;
    double fraction, intPart;
    int i, numDigits2;
    char tmpBuf[CVT_DBL_BUF_SIZE];
				/* Large enough to hold largest possible
				 * floating-point number.
				 */

    /*
     * Make sure the value is a valid number
     */
    {
	union {
	    double d;
	    long l[2];
	} u;

	/*
	 * Put the value into a union so we can check out the bits.
	 */
	u.d = value;

	/*
	 * An IEEE Std 754 double precision floating point number
         * has the following format:
	 *
	 *      1  bit       -- sign of Mantissa
	 *      11 bits      -- exponent
	 *      52 bits      -- Mantissa
	 *
	 * If the exponent has all bits set, the value is not a 
	 * real number.
	 *
	 * If the Mantissa is zero then the value is infinity, which
	 * is the result of division by zero, or overflow.
	 *
	 * If the Mantissa is non-zero the value is not a number (NaN).
	 * NaN can be generated by dividing zero by itself, taking the
	 * logarithm of a negative number, etc.
	 */

	/*
	 * check the exponent
	 */
	if ((u.l[0] & 0x7ff00000) == 0x7ff00000) {
	    /*
	     * Set the error flag so the invoking function will know
	     * that something is wrong.
	     */
	    *fpError = TRUE;

	    /*
	     * See if the Mantissa is zero.
	     */
	    if ((u.l[0] & ~0xfff00000) == 0 && u.l[1] == 0) {
		strcpy(buf, "(INFINITY)");
		return sizeof("(INFINITY)") - 1;
	    } else {
		strcpy(buf, "(NaN)");
		return sizeof("(NaN)") - 1;
	    }
	} else {
	    *fpError = FALSE;
	}
    }

    /*
     * Take care of the sign.
     */

    if (value < 0.0) {
	*signPtr = TRUE;
	value = -value;
    } else {
	*signPtr = FALSE;
    }

    /*
     * Divide value into an integer and a fractional component.  Convert
     * the integer to ASCII in a temporary buffer, then move the characters
     * to the real buffer (since we're converting from the bottom up,
     * we won't know the highest-order digit until last).
     */

    fraction = modf(value, &intPart);
    *pointPtr = 0;
    for (p = &tmpBuf[CVT_DBL_BUF_SIZE-1]; intPart != 0; p -= 1) {
	double tmp;
	char digit;

	tmp = modf(intPart/10.0, &intPart);

	digit = (tmp * 10.0) + .2;
	*p = digit + '0';
	*pointPtr += 1;
    }
    p++;
    for (i = 0; (i <= numDigits) && (p <= &tmpBuf[CVT_DBL_BUF_SIZE-1]);
	    i++, p++) {
	buf[i] = *p;
    }

    /*
     * If the value was zero, put an initial zero in the buffer
     * before the decimal point.
     */
    
    if (value == 0.0) {
	buf[0] = '0';
	i = 1;
	*pointPtr = 1;
    }

    /*
     * Now handle the fractional part that's left.  Repeatedly multiply
     * by 10 to get the next digit.  At the beginning, the value may be
     * very small, so do repeated multiplications until we get to a
     * significant digit.
     */
    
    if ((i == 0) && (fraction > 0)) {
	while (fraction < .1) {
	    fraction *= 10.0;
	    *pointPtr -= 1;
	};
    }

    /*
     * Compute how many total digits we should generate, taking into
     * account both numDigits and afterPoint.  Then generate the digits.
     */
    
    numDigits2 = afterPoint + *pointPtr;
    if ((afterPoint < 0) || (numDigits2 > numDigits)) {
	numDigits2 = numDigits;
    }
    
    for ( ; i <= numDigits2; i++) {
	double tmp;
	char digit;

	fraction = modf(fraction*10.0, &tmp);

	digit = tmp;
	buf[i] = digit + '0';
    }

    /*
     * The code above actually computed one more digit than is really
     * needed.  Use it to round the low-order significant digit, if
     * necessary.  This could cause rounding to propagate all the way
     * back through the number.
     */
    
    if ((numDigits2 >= 0) && (buf[numDigits2] >= '5')) {
	for (i = numDigits2-1; ; i--) {
	    if (i < 0) {
		int j;

		/*
		 * Must slide the entire buffer down one slot to make
		 * room for a leading 1 in the buffer.  Careful: if we've
		 * already got numDigits digits, must drop the last one to
		 * add the 1.
		 */

		for (j = numDigits2; j > 0; j--) {
		    buf[j] = buf[j-1];
		}
		if (numDigits2 < numDigits) {
		    numDigits2++;
		}
		(*pointPtr)++;
		buf[0] = '1';
		break;
	    }

	    buf[i] += 1;
	    if (buf[i] <= '9') {
		break;
	    }
	    buf[i] = '0';
	}
    }

    if (numDigits2 <= 0) {
	numDigits2 = 0;
	*pointPtr = -afterPoint;
    }
    buf[numDigits2] = 0;
    return numDigits2;
}

/*
 * The table below is used to convert from ASCII digits to a
 * numerical equivalent.  It maps from '0' through 'z' to integers
 * (100 for non-digit characters).
 */

static const char cvtIn[] = {
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9,		/* '0' - '9' */
    100, 100, 100, 100, 100, 100, 100,		/* punctuation */
    10, 11, 12, 13, 14, 15, 16, 17, 18, 19,	/* 'A' - 'Z' */
    20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
    30, 31, 32, 33, 34, 35,
    100, 100, 100, 100, 100, 100,		/* punctuation */
    10, 11, 12, 13, 14, 15, 16, 17, 18, 19,	/* 'a' - 'z' */
    20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
    30, 31, 32, 33, 34, 35};

/*
 *----------------------------------------------------------------------
 *
 * strtoul --
 *
 *	Convert an ASCII string into an integer.
 *
 * Results:
 *	The return value is the integer equivalent of string.  If endPtr
 *	is non-NULL, then *endPtr is filled in with the character
 *	after the last one that was part of the integer.  If string
 *	doesn't contain a valid integer value, then zero is returned
 *	and *endPtr is set to string.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

unsigned long int
strtoul(string, endPtr, base)
    char *string;		/* String of ASCII digits, possibly
				 * preceded by white space.  For bases
				 * greater than 10, either lower- or
				 * upper-case digits may be used.
				 */
    char **endPtr;		/* Where to store address of terminating
				 * character, or NULL. */
    int base;			/* Base for conversion.  Must be less
				 * than 37.  If 0, then the base is chosen
				 * from the leading characters of string:
				 * "0x" means hex, "0" means octal, anything
				 * else means decimal.
				 */
{
    register char *p;
    register unsigned long int result = 0;
    register unsigned digit;
    int anyDigits = FALSE;

    /*
     * Skip any leading blanks.
     */

    p = string;
    while (isspace(*p)) {
	p += 1;
    }

    /*
     * If no base was provided, pick one from the leading characters
     * of the string.
     */
    
    if (base == 0)
    {
	if (*p == '0') {
	    p += 1;
	    if (*p == 'x') {
		p += 1;
		base = 16;
	    } else {

		/*
		 * Must set anyDigits here, otherwise "0" produces a
		 * "no digits" error.
		 */

		anyDigits = TRUE;
		base = 8;
	    }
	}
	else base = 10;
    } else if (base == 16) {

	/*
	 * Skip a leading "0x" from hex numbers.
	 */

	if ((p[0] == '0') && (p[1] == 'x')) {
	    p += 2;
	}
    }

    /*
     * Sorry this code is so messy, but speed seems important.  Do
     * different things for base 8, 10, 16, and other.
     */

    if (base == 8) {
	for ( ; ; p += 1) {
	    digit = *p - '0';
	    if (digit > 7) {
		break;
	    }
	    result = (result << 3) + digit;
	    anyDigits = TRUE;
	}
    } else if (base == 10) {
	for ( ; ; p += 1) {
	    digit = *p - '0';
	    if (digit > 9) {
		break;
	    }
	    result = (10*result) + digit;
	    anyDigits = TRUE;
	}
    } else if (base == 16) {
	for ( ; ; p += 1) {
	    digit = *p - '0';
	    if (digit > ('z' - '0')) {
		break;
	    }
	    digit = cvtIn[digit];
	    if (digit > 15) {
		break;
	    }
	    result = (result << 4) + digit;
	    anyDigits = TRUE;
	}
    } else {
	for ( ; ; p += 1) {
	    digit = *p - '0';
	    if (digit > ('z' - '0')) {
		break;
	    }
	    digit = cvtIn[digit];
	    if (digit >= base) {
		break;
	    }
	    result = result*base + digit;
	    anyDigits = TRUE;
	}
    }

    /*
     * See if there were any digits at all.
     */

    if (!anyDigits) {
	p = string;
    }

    if (endPtr != NULL) {
	*endPtr = p;
    }

    return result;
}
/*-
 *-----------------------------------------------------------------------
 * XtTtyVPrintf --
 *	Perform a printf to the given widget at its current insert
 *	position. Care is taken to avoid overflowing the source's
 *	internal buffer, though I'm not certain this is still necessary.
 *
 *	This code is modified from the Sprite vfprintf code, as mentioned
 *	above.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The characters are added to the window.
 *
 *-----------------------------------------------------------------------
 */
/*VARARGS*/
void
XtTtyVPrintf(Widget w, char *fmt, va_list args)
{
    TtyWidget	  	tty = (TtyWidget)w;
    XtTextBlock	  	text;	    /* Block for replacement */
    XtTextPosition	ipoint;	    /* Current insertion point */
    register char	*cp;	    /* Current character */
    char		*cpStart;   /* Start of non-format string */
    int			leftAdjust; /* TRUE means field should be left-
				     * adjusted. */
    int	    	    	minWidth;   /* Minimum width of field. */
    int			precision;  /* Precision for field (e.g. digits after
				     * decimal, or string length). */
    int	    	    	altForm;    /* TRUE means value should be converted to
				     * an alternate form (depends on type of
				     * conversion). */
    register char   	c;	    /* Current character from format string.
				     * Eventually it ends up holding the format
				     * type (e.g. 'd' for decimal). */
    char    	    	pad;	    /* Pad character. */
    char    	    	buf[CVT_DBL_BUF_SIZE+10];
				    /* Buffer used to hold converted numbers
				     * before outputting to stream.  Must be
				     * large enough for floating-point number
				     * plus sign plus "E+XXX + null" */
    char    	    	expBuf[CVT_INT_BUF_SIZE];
    	    	    	    	    /*Buffer to use for converting exponents.*/
    char    	    	*prefix;    /* Holds non-numeric stuff that precedes
				     * number, such as "-" or "0x".  This is
				     * kept separate to be sure we add padding
				     * zeroes AFTER the prefix. */
    register char   	*field;	    /* Pointer to converted field. */
    int			actualLength;/* Actual length of converted field. */
    int			point;	    /* Location of decimal point, for "f" and
				     * "e" conversions. */
    int     	    	sign;	    /* Also used for "f" and "e" conversions.*/
    int     	    	i, tmp;
    char    	    	*end;
    int     	    	fpError = FALSE;

    cpStart = cp = fmt;

    ipoint = tty->text.insertPos;

    /*
     * If insertion point someplace we can't insert, go someplace
     * we can...
     */
    if (ipoint < XtTtySourceGetFence(tty->text.source)) {
	ipoint = tty->text.lastPos;
    }
    
    while ((c = *cp) != '\0') {
	if (c != '%') {
	    cp++;
	} else {
	    if (cp != cpStart) {
		/*
		 * Print the chars we skipped over in chunks no larger
		 * than the buffer size.
		 */
		text.firstPos = 0;
		text.ptr = cpStart;
		while (cpStart + text.firstPos < cp) {
		    text.length = (cp - (text.ptr + text.firstPos));
#if 0
		    if (text.length > TTY_BUF_SIZE) {
			text.length = TTY_BUF_SIZE;
		    }
#endif
		    XtTextReplace((Widget)tty, ipoint, ipoint, &text);
		    ipoint += text.length;
		    text.firstPos += text.length;
		}
	    }
	    cpStart = cp;
	    cp++;
	    /*
	     * Parse off the format control fields.
	     */
	    
	    leftAdjust	= FALSE;
	    pad		= ' ';
	    minWidth	= 0;
	    precision	= -1;
	    altForm	= FALSE;
	    prefix	= "";
	    actualLength = 0;
	    
	    c = *cp++;
	    while (TRUE) {
		if (c == '-') {
		    leftAdjust = TRUE;
		} else if (c == '0') {
		    pad = '0';
		} else if (c == '#') {
		    altForm = TRUE;
		} else if (c == '+') {
		    prefix = "+";
		    actualLength = 1;
		} else {
		    break;
		}
		c = *cp++;
	    }
	    if (isdigit(c)) {
		minWidth = strtoul(cp, &end, 10);
		cp = end;
		c = *cp++;
	    } else if (c == '*') {
		minWidth = va_arg(args, int);
		cp++; 
		c = *cp++;
	    }
	    if (c == '.') {
		c = *cp++;
	    }
	    if (isdigit(c)) {
		precision = strtoul(cp, &end, 10);
		cp = end;
		c = *cp++;
	    } else if (c == '*') {
		precision = va_arg(args, int);
		c = *cp++;
	    }
	    if (c == 'l') {		/* Ignored for compatibility. */
		c = *cp++;
	    }
	    
	    /*
	     * Take action based on the format type (which is now in c).
	     */
	    
	    field = buf;
	    switch (c) {
		
		case 'D':
		case 'd':
		    i = va_arg(args, int);
		    if (i < 0) {
			prefix = "-";
			i = -i;
			actualLength = 1;
		    }
		    field = CvtUtoA((unsigned) i, 10, buf, &tmp);
		    actualLength += tmp;
		    break;
		    
		case 'O':
		case 'o':
		    i = va_arg(args, int);
		    if (altForm && (i != 0)) {
			prefix = "0";
			actualLength = 1;
		    }
		    field = CvtUtoA((unsigned) i, 8, buf, &tmp);
		    actualLength += tmp;
		    break;
		    
		case 'X':
		case 'x':
		    i = va_arg(args, int);
		    field = CvtUtoA((unsigned) i, 16, buf, &actualLength);
		    if (altForm) {
			char *p;
			if (c == 'X') {
			    if (i != 0) {
				prefix = "0X";
				actualLength += 2;
			    }
			    for (p = field; *p != 0; p++) {
				if (*p >= 'a') {
				    *p += 'A' - 'a';
				}
			    }
			} else if (i != 0) {
			    prefix = "0x";
			    actualLength += 2;
			}
		    }
		    break;
		    
		case 'U':
		case 'u':
		    field = CvtUtoA(va_arg(args, unsigned), 10, buf,
				    &actualLength);
		    break;
		    
		case 's':
		    field = va_arg(args, char *);
		    if (field == (char *) NULL) {
			field = "(NULL)";
		    } 
		    actualLength = strlen(field);
		    if ((precision >= 0) && (precision < actualLength)) {
			actualLength = precision;
		    }
		    pad = ' ';
		    break;
		    
		case 'c':
		    buf[0] = va_arg(args, int);
		    actualLength = 1;
		    pad = ' ';
		    break;
		    
		case 'F':
		case 'f':
		    if (precision < 0) {
			precision = 6;
		    } else if (precision > CVT_DBL_BUF_SIZE) {
			precision = CVT_DBL_BUF_SIZE;
		    }
		    
		    /*
		     * Just generate the digits and compute the total length
		     * here.  The rest of the work will be done when the
		     * characters are actually output, below.
		     */
#ifdef sun4
		    /*
		     * Varargs is not correctly implemented in gcc version 1.34
		     * for the sun4.  This problem should be fixed in the next
		     * version of the compiler, and this code can then be
		     * deleted.
		     */
		{
		    union {
			long i[2];
			double d;
		    } u;
		    
		    u.i[0] = va_arg(args, long);
		    u.i[1] = va_arg(args, long);
		    
		    actualLength = CvtFtoA(u.d, CVT_DBL_BUF_SIZE,
					   precision, &point, &sign, field,
					   &fpError);
		}
#else
		    actualLength = CvtFtoA(va_arg(args, double),
					   CVT_DBL_BUF_SIZE,
					   precision, &point, &sign, field,
					   &fpError);
#endif
		    if (fpError) {
			break;
		    }
		    if (point <= 0) {
			actualLength += 1 - point;
		    }
		    if ((precision != 0) || (altForm)) {
			actualLength += 1;
		    }
		    if (sign) {
			prefix = "-";
			actualLength += 1;
		    }
		    c = 'f';
		    break;
		    
		case 'E':
		case 'e':
		    if (precision < 0) {
			precision = 6;
		    } else if (precision > CVT_DBL_BUF_SIZE-1) {
			precision = CVT_DBL_BUF_SIZE-1;
		    }
#ifdef sun4
		    /*
		     * Varargs is not correctly implemented in gcc version 1.34
		     * for the sun4.  This problem should be fixed in the next
		     * version of the compiler, and this code can then be
		     * deleted.
		     */
		{
		    union {
			long i[2];
			double d;
		    } u;
		    
		    u.i[0] = va_arg(args, long);
		    u.i[1] = va_arg(args, long);
		    
		    actualLength = CvtFtoA(u.d, precision+1, -1,
					   &point, &sign, &buf[1],
					   &fpError);
		}
#else
		    actualLength = CvtFtoA(va_arg(args, double), precision+1,
					   -1, &point, &sign, &buf[1],
					   &fpError);
#endif
		    if (fpError) {
			break;
		    }
		    eFromG:
		    
		    /*
		     * Insert a decimal point after the first digit of the
		     * number. If no digits after decimal point, then don't
		     * print decimal unless in altForm.
		     */
		    
		    buf[0] = buf[1];
		    buf[1] = '.';
		    if ((precision != 0) || (altForm)) {
			field = buf + precision + 2;
		    } else {
			field = &buf[1];
		    }
		    
		    /*
		     * Convert the exponent.
		     */
		    
		    *field = c;
		    field++;
		    point--;	/* One digit before decimal point. */
		    if (point < 0) {
			*field = '-';
			point = -point;
		    } else {
			*field = '+';
		    }
		    field++;
		    if (point < 10) {
			*field = '0';
			field++;
		    }
		    strcpy(field, CvtUtoA((unsigned) point, 10, expBuf, &i));
		    actualLength = (field - buf) + i;
		    field = buf;
		    if (sign) {
			prefix = "-";
			actualLength += 1;
		    }
		    break;
		    
		case 'G':
		case 'g': {
		    int eLength, fLength;
		    
		    if (precision < 0) {
			precision = 6;
		    } else if (precision > CVT_DBL_BUF_SIZE-1) {
			precision = CVT_DBL_BUF_SIZE-1;
		    } else if (precision == 0) {
			precision = 1;
		    }
		    
#ifdef sun4
		    /*
		     * Varargs is not correctly implemented in gcc version 1.34
		     * for the sun4.  This problem should be fixed in the next
		     * version of the compiler, and this code can then be
		     * deleted.
		     */
		{
		    union {
			long i[2];
			double d;
		    } u;
		    
		    u.i[0] = va_arg(args, long);
		    u.i[1] = va_arg(args, long);
		    
		    actualLength = CvtFtoA(u.d, precision,
					   -1, &point, &sign, &buf[1],
					   &fpError);
		}
#else
		    actualLength = CvtFtoA(va_arg(args, double), precision,
					   -1, &point, &sign, &buf[1],
					   &fpError);
		    
#endif
		    if (fpError) {
			break;
		    }
		    if (!altForm) {
			for ( ; actualLength > 1; actualLength--) {
			    if (buf[actualLength] != '0') {
				break;
			    }
			}
		    }
		    if ((actualLength > 1) || altForm) {
			eLength = actualLength + 5;
		    } else {
			eLength = actualLength + 4;
		    }
		    if (point <= 0) {
			fLength = actualLength + 2 - point;
		    } else {
			fLength = actualLength;
			if (point < actualLength) {
			    fLength += 1;
			} else if (altForm) {
			    fLength = point + 1;
			} else {
			    fLength = point;
			}
		    }
		    
		    /*
		     * Use "e" format if it results in fewer digits than "f"
		     * format, or if it would result in non-significant zeroes
		     * being printed.  Remember that precision means something
		     * different in "e" and "f" (digits after decimal) than it
		     * does in "g" (significant digits).
		     */
		    
		    if ((eLength < fLength) || (point > precision)) {
			c += 'E' - 'G';
			precision = actualLength-1;
			goto eFromG;
		    }
		    c = 'f';
		    field = &buf[1];
		    actualLength = fLength;
		    if (sign) {
			prefix = "-";
			actualLength += 1;
		    }
		    break;
		}
		    
		case '%':
		    XtTtyPutString(w, "%");
		    goto endOfField;
		    
		case 0:
		    return;
		    
		default:
		    buf[0] = c;
		    buf[1] = '\0';
		    XtTtyPutString(w, buf);
		    goto endOfField;
	    }
	    
	    /* Handle pad characters on the left.  If the pad is '0', then
	     * padding goes after the prefix.  Otherwise, padding goes before
	     * the prefix.
	     */
	    
	    if (!leftAdjust) {
		if (pad == '0') {
		    char    *pstart = prefix;
		    
		    for ( ; *prefix != 0; prefix++) {
			actualLength--;
			minWidth--;
		    }
		    text.ptr = pstart;
		    text.firstPos = 0;
		    text.length = prefix - pstart;
		    XtTextReplace(w, ipoint, ipoint, &text);
		    ipoint += prefix - pstart;
		}
		text.ptr = &pad;
		text.firstPos = 0;
		text.length = 1;
		
		while (minWidth > actualLength) {
		    XtTextReplace(w, ipoint, ipoint, &text);
		    ipoint += 1;
		    minWidth --;
		}
	    }
	    
	    /*
	     * Output anything left in the prefix.
	     */
	    
	    minWidth -= actualLength;

	    text.ptr = prefix;
	    text.firstPos = 0;
	    text.length = strlen(prefix);
	    if (text.length) {
		XtTextReplace(w, ipoint, ipoint, &text);
		ipoint += text.length;
		actualLength -= text.length;
	    }
	    
	    /*
	     * "F" and "f" formats are handled specially here:  output
	     * everything up to and including the decimal point.
	     */
	    
	    if (c == 'f' && !fpError) {
		static char zero = '0';

		if (point <= 0) {

		    text.ptr = &zero;
		    text.length = 1;
		    text.firstPos = 0;
		    
		    if (actualLength > 0) {
			XtTextReplace(w, ipoint, ipoint, &text);
			ipoint += 1;
			point++;
			actualLength--;
		    }
		    if (actualLength > 0) {
			zero = '.';
			XtTextReplace(w, ipoint, ipoint, &text);
			ipoint += 1;
			zero = '0';
			actualLength--;
		    }
		    while ((point <= 0) && (actualLength > 0)) {
			XtTextReplace(w, ipoint, ipoint, &text);
			ipoint += 1;
			point++;
			actualLength--;
		    }
		} else {
		    text.ptr = field;
		    text.firstPos = 0;
		    text.length = 0;
		    
		    while ((point > 0) && (actualLength > 0)) {
			text.length += 1;
			field++;
			point--;
			actualLength--;
		    }
		    if (text.length) {
			XtTextReplace(w, ipoint, ipoint, &text);
			ipoint += text.length;
		    }

		    if (actualLength > 0) {
			text.ptr = zero;
			text.length = 1;
			zero = '.';
			XtTextReplace(w, ipoint, ipoint, &text);
			ipoint += 1;
			zero = '0';
			actualLength--;
		    }
		}
	    }
	    
	    /*
	     * Output the contents of the field (for "f" format, this is
	     * just the stuff after the decimal point).
	     */
	    
	    text.ptr = field;
	    text.firstPos = 0;
	    text.length = 0;
	    for ( ; actualLength > 0; actualLength--) {
		field++;
	    }
	    while(text.ptr+text.firstPos < field) {
		text.length = field - (text.ptr+text.firstPos);
#if 0
		if (text.length > TTY_BUF_SIZE) {
		    text.length = TTY_BUF_SIZE;
		}
#endif
		XtTextReplace(w, ipoint, ipoint, &text);
		ipoint += text.length;
		text.firstPos += text.length;
	    }
	    
	    /*
	     * Pad the right of the field, if necessary.
	     */
	    
	    pad = ' ';
	    text.ptr = &pad;
	    text.firstPos = 0;
	    text.length = 1;
	    
	    while (minWidth > 0) {
		XtTextReplace(w, ipoint, ipoint, &text);
		ipoint += 1;
		minWidth --;
	    }
	    
	    endOfField:
	    cpStart = cp;
	}
    }
    if (cp != cpStart) {
	/*
	 * Print the chars we skipped over in chunks no larger
	 * than the buffer size.
	 */
	text.firstPos = 0;
	text.ptr = cpStart;
	while (cpStart + text.firstPos < cp) {
	    text.length = (cp - (text.ptr + text.firstPos));
#if 0
	    if (text.length > TTY_BUF_SIZE) {
		text.length = TTY_BUF_SIZE;
	    }
#endif
	    XtTextReplace((Widget)tty, ipoint, ipoint, &text);
	    ipoint += text.length;
	    text.firstPos += text.length;
	}
    }

    XtTextSetInsertionPoint((Widget)tty, ipoint);
}

/*-
 *-----------------------------------------------------------------------
 * XtTtyPutString --
 *	Outputs the string, without formatting, to the given widget.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Insertion point advanced beyond the inserted text.
 *
 *-----------------------------------------------------------------------
 */
void
XtTtyPutString(w, string)
    Widget  	  	w;
    char		*string;
{
    TtyWidget	  	tty = (TtyWidget)w;
    XtTextBlock		text;
    XtTextPosition	last;

    text.ptr = string;
    text.firstPos = 0;
    text.length = strlen(string);

    last = tty->text.insertPos;
    if (text.length < TTY_BUF_SIZE) {
	XtTextReplace((Widget)tty, last, last, &text);
	XtTextSetInsertionPoint((Widget)tty, last + text.length);
    } else {
	int 	  length;

#ifndef min
#define min(a,b) ((a)<(b)?(a):(b))
#endif
	length = text.length;
	while (length != 0) {
#if 0
	    text.length = min(TTY_BUF_SIZE-1, length);
#else
	    text.length = length;
#endif /* 0 */
	    XtTextReplace((Widget)tty, last, last, &text);
	    length -= text.length;
	    text.firstPos += text.length;
	    last += text.length;
	}
	XtTextSetInsertionPoint((Widget)tty, last);
    }
}

/*-
 *-----------------------------------------------------------------------
 * XtTtySetFence --
 *	Set the boundary beyond which characters may not be deleted.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	None
 *
 *-----------------------------------------------------------------------
 */
void
XtTtySetFence(w, fence)
    Widget  	    w;
    XtTextPosition  fence;  	/* New fence (-1 => end) */
{
    XtTtySourceSetFence(((TtyWidget)w)->text.source, fence);
}


/***********************************************************************
 *				XtTtyGetFence
 ***********************************************************************
 * SYNOPSIS:	    Return the current input fence position
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The current fence position
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/17/89		Initial Revision
 *
 ***********************************************************************/
XtTextPosition
XtTtyGetFence(w)
    Widget  	w;
{
    XtTtySourceGetFence(((TtyWidget)w)->text.source);
}


/***********************************************************************
 *				XtTtyGetChar
 ***********************************************************************
 * SYNOPSIS:	    Kludge to allow us to fetch a single character
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Nothing
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/17/89		Initial Revision
 *
 ***********************************************************************/
void
XtTtyGetChar(w, cp, echo)
    Widget  	w;  	/* Widget through which to get the char */
    char    	*cp;	/* Points to place to store fetched character */
    Boolean 	echo;	/* True if fetched character is to be echoed */
{
    XtTtySourceGetChar(((TtyWidget)w)->text.source, cp, echo);
}

/***********************************************************************
 *				XtTtyCharGotten
 ***********************************************************************
 * SYNOPSIS:	    Turn off single-character mode -- character gotten
 *	    	    from somewhere else.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Nothing
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/18/89		Initial Revision
 *
 ***********************************************************************/
void
XtTtyCharGotten(w)
    Widget  	w;  	/* Widget through which to get the char */
{
    XtTtySourceCharGotten(((TtyWidget)w)->text.source);
}


/***********************************************************************
 *				XtTtyHaveInput
 ***********************************************************************
 * SYNOPSIS:	    See if there's any input yet.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    True if there's anything beyond the fence.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	Just need to compare the fence with the last position.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/17/89		Initial Revision
 *
 ***********************************************************************/
Boolean
XtTtyHaveInput(w)
    Widget  	w;
{
    TtyWidget       tty = (TtyWidget)w;
    XtTextPosition  fence;
    XtTextPosition  last;

    fence = XtTtySourceGetFence(tty->text.source);
    last = (*tty->text.source->Scan) (tty->text.source, 0, XtstAll,
				      XtsdRight, 1, TRUE );

    return(last == fence ? FALSE : TRUE);
}


/*XXX: No function officially exported to snag the text, so use one
 * that's unofficially exported (though the comments say it's sort of ok) */
extern char *_XtTextGetText( /* ctx, left, right */ );

/*************************************************************
 *
 * Action procedures
 *
 ************************************************************/

/*-
 *-----------------------------------------------------------------------
 * Enter --
 *	Extract the text typed since the last prompt and pass it off
 *	to the enterCallback function(s).
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The enterCallback function(s) are called.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
Enter(w, event, params, num_params)
    Widget  	  w;
    XEvent	  *event;
    String	  *params;
    Cardinal	  *num_params;
{
    TtyWidget	    tty = (TtyWidget)w;
    XtTextPosition  startPos, endPos;
    char    	    *string;
    char    	    *cp;
    XtTextBlock	    text;

    /*
     * Find bounds of input line
     */
    endPos = tty->text.lastPos;
    startPos = XtTtySourceGetFence(tty->text.source);

    /*
     * Deal with optional terminator character
     */
    if (*num_params == 1) {
	char terminator;
	
	string = (char *)XtMalloc(endPos - startPos + 2);

	if (params[0][0] != '\\') {
	    /*
	     * Plain -- use the first char of the arg
	     */
	    terminator = params[0][0];
	} else {
	    /*
	     * Ugh. Has a backslash. Convert to something reasonable.
	     */
	    switch(params[0][1]) {
		case 'b': terminator = '\b'; break;
		case 'n': terminator = '\n'; break;
		case 'r': terminator = '\r'; break;
		case 'e': terminator = '\033'; break;
		case 'f': terminator = '\f'; break;
		case 't': terminator = '\t'; break;
		case '\\': terminator = '\\'; break;
		case 'x': terminator = (char)strtoul(&params[0][2], NULL, 16);
		    break;
		case '0': case '1': case '2': case '3':
		case '4': case '5': case '6': case '7':
		    terminator = (char)strtoul(&params[0][2], NULL, 8);
		    break;
		default:
		    terminator = params[0][1];
		    break;
	    }
	}
		    
	/*
	 * Store terminator and null-terminate
	 */
	string[endPos - startPos] = terminator;
	string[endPos - startPos + 1] = '\0';
    } else {
	/*
	 * Assume terminator already present -- just null-terminate
	 */
	string = (char *)XtMalloc(endPos - startPos + 1);
	string[endPos - startPos] = '\0';
    }

    /*
     * Get the input line in pieces and copy them into the buffer.
     */
    cp = string;
    while (startPos != endPos) {
	int 	len = endPos - startPos;

	if (len > TTY_BUF_SIZE) {
	    len = TTY_BUF_SIZE;
	}
	startPos = (* tty->text.source->Read) (tty->text.source,
					       startPos,
					       &text,
					       len);
	bcopy(text.ptr, cp, text.length);
	cp += text.length;
    }
    /*
     * Call the interested parties.
     */
    XtCallCallbacks(w, XtNenterCallback, (caddr_t)string);

    /*
     * Free up the string we passed -- no one needs it any longer.
     */
    XtFree(string);
}

/*-
 *-----------------------------------------------------------------------
 * KillLine --
 *	Kill all the text back to the prompt.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The text from the last prompt to the end of the file is
 *	nuked.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
KillLine(w, event, params, num_params)
    Widget  	  w;
    XEvent  	  *event;
    String	  *params;
    Cardinal	  *num_params;
{
    TtyWidget	  tty = (TtyWidget)w;
    XtTextPosition cur;
    XtTextBlock	   text;

    cur = tty->text.lastPos;
    text.length = text.firstPos = 0;
    text.ptr = "";
    XtTextReplace(w, XtTtySourceGetFence(tty->text.source), cur, &text);
}

/*-
 *-----------------------------------------------------------------------
 * SetMark --
 *	Record the current point for later reference.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	tty->tty.markPos is changed.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
SetMark(w, event, params, num_params)
    Widget  	  w;
    XEvent	  *event;
    String	  *params;
    Cardinal	  *num_params;
{
    TtyWidget	  tty = (TtyWidget)w;

    tty->tty.markPos = XtTextGetInsertionPoint(w);
}

/*-
 *-----------------------------------------------------------------------
 * SaveRegion --
 *	Save the text between the current point and the last mark in
 *	cut buffer 1.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Cut buffer 1 is changed.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
SaveRegion(w, event, params, num_params)
    Widget  	  w;
    XEvent	  *event;
    String	  *params;
    Cardinal	  *num_params;
{
    TtyWidget	  tty = (TtyWidget)w;
    char    	  *ptr;
    XtTextPosition cur;

    cur = XtTextGetInsertionPoint(w);
    if (cur < tty->tty.markPos) {
	ptr = _XtTextGetText((TextWidget)w, cur, tty->tty.markPos);
    } else {
	ptr = _XtTextGetText((TextWidget)w, tty->tty.markPos, cur);
    }

    XStoreBuffer(XtDisplay(w), ptr, strlen(ptr), 1);
    XtFree(ptr);
}

/*-
 *-----------------------------------------------------------------------
 * Interrupt --
 *	Handle an interrupt. Calls the functions in the interruptCallback
 *	list for the widget.
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
Interrupt(w, event, params, num_params)
    Widget  	  w;
    XEvent	  *event;
    String	  *params;
    Cardinal	  *num_params;
{
    XtCallCallbacks(w, XtNinterruptCallback, (caddr_t)NULL);
}
    

/*************************************************************
 *
 * Tty Source Functions
 *
 *************************************************************/

/*
 * The following code is modified from DiskSrc.c. Aside from renaming,
 * it also allows text to be removed from the end of the file, thus
 * allowing for line-editing.
 */
#define TMPSIZ 32		/* bytes to allocate for tmpnam */

extern char *tmpnam();
void bcopy();

/** private TtySource definitions **/

typedef struct _TtySourceData {
    /* resources */
    char       	    *fileName;
    /* private data */
    Boolean	    is_tempfile;    /* Non-zero if should be nuked on delete */
    int		    fd;		    /* Stream open to file */
    XtTextPosition  fence;  	    /* Start of current input line */
    XtTextPosition  selLeft,	    /* Left end of selection */
		    selRight;	    /* Right end of selection */
    char    	    *getChar;	    /* Place to store fetched character, if
				     * in that mode... */
    Boolean 	    echo; 	    /* True if should echo gotten char */

    /* file buffer data */
    XtTextPosition  position, 	    /* file position of first char in buffer */
 		    length; 	    /* length of file */
    char	    buffer[TTY_BUF_SIZE]; /* piece of file in memory */
    int		    charsInBuffer;   /* number of bytes used in memory */
    int		    dirtyStart;	    /* Start of dirty section (buffer index) */
    int		    dirtyEnd;	    /* End of dirty section (buffer index) */
    /* string edit buffer data */
    char    	    editBuf[TTY_BUF_SIZE];  /* Buffer containing input line */
    int	    	    editChars;	    /* Number of chars in editBuf */
} TtySourceData, *TtySourcePtr;

#define LastPos(data)	    ((data)->length + (data)->editChars)

#define EditPos(pos,data)   ((pos)-(data)->length)
#define Increment(data, position, direction)\
{\
     if (direction == XtsdLeft) {\
     	if (position > 0) \
	    position -= 1;\
     }\
     else {\
	if (position < LastPos(data))\
	    position += 1;\
     }\
}

static XtResource srcResources[] = {
{XtNfile, XtCFile, XtRString, sizeof (char *),
 XtOffset(TtySourcePtr, fileName), XtRString, NULL},
};

/*-
 *-----------------------------------------------------------------------
 * TtyFillBuffer --
 *	Read text starting at the given position into memory. Attempts
 *	to place the position at a sane place in the buffer for
 *	maximum flexibility, given the number of bytes the caller will
 *	be needing to access.
 *
 * Results:
 *	?
 *
 * Side Effects:
 *	The buffer is filled with characters.
 *
 *-----------------------------------------------------------------------
 */
static void
TtyFillBuffer (data, pos, length, modify)
    TtySourcePtr  	data;	    /* Private data */
    XtTextPosition	pos;	    /* Starting position caller needs */
    long		length;	    /* Bytes beyond that caller needs */
    Boolean		modify;	    /* TRUE if intend to modify the buffer.
				     * i.e. there must be length bytes
				     * available in the buffer when we return*/
{
    long    	  	readPos;    /* File position for read */
    
#ifdef DEBUG
    printf("FillBuffer: pos = %d, length = %d, cur=%d, curLength = %d\n",
	   pos, length, data->position, data->charsInBuffer);
#endif

    if (!modify && ((pos + length) > data->length)) {
	/*
	 * If not going to write the buffer, don't worry if we haven't
	 * got exactly the right amount of data if the dude is trying to
	 * read beyond the end of the file...Otherwise we need to leave
	 * extra room at the end of the buffer to store the data that
	 * will be arriving.
	 */
	length = data->length - pos;
#ifdef DEBUG
	printf("FillBuffer: length = %d\n", length);
#endif
    }
    
    if ((pos < data->position) ||
	((pos + length) >= (data->position + data->charsInBuffer)))
    {
	/*
	 * Range not within buffer -- need to reposition.
	 */
	if (length > TTY_BUF_SIZE / 2) {
	    /*
	     * If the caller wants more characters than half a buffer's worth,
	     * don't bother trying to center the position in the buffer --
	     * just place it at the beginning.
	     */
	    readPos = pos;
	} else if (pos < (TTY_BUF_SIZE / 2)) {
	    /*
	     * Position is before halfway point of buffer -- read from start
	     * of file.
	     */
	    readPos = 0;
	} else if (pos >= data->length - (TTY_BUF_SIZE - length)) {
	    /*
	     * Position is in last buffer of file -- read last buffer,
	     * but leave room enough at the end for length bytes.
	     */
	    readPos = data->length - (TTY_BUF_SIZE - length);
	} else {
	    /*
	     * Read so pos is in center, allowing caller to go backwards
	     * or forwards...
	     */
	    readPos = pos - (TTY_BUF_SIZE / 2);
	}
	if (readPos < 0) {
	    readPos = 0;
	}
	if (readPos != data->position) {
	    /*
	     * Actually did adjust the start of the buffer -- go fetch
	     * the required data.
	     * XXX: What about block moves if close enough?
	     */
	    if (data->dirtyStart >= 0) {
		/*
		 * If any data are dirty, flush them to disk before changing
		 * positions.
		 */
#ifdef DEBUG
		printf("FillBuffer: dirty = [%d, %d]\n", data->dirtyStart,
		       data->dirtyEnd);
#endif	    
		lseek(data->fd, data->position + data->dirtyStart, L_SET);
		write(data->fd, data->buffer + data->dirtyStart,
		      data->dirtyEnd - data->dirtyStart + 1);
		data->dirtyStart = data->dirtyEnd = -1;
	    }
	    
	    lseek(data->fd, readPos, L_SET);
	    data->charsInBuffer = read(data->fd, data->buffer, TTY_BUF_SIZE);
	    data->position = readPos;
#ifdef DEBUG
	    printf("FillBuffer: cur = %d, curLength = %d\n", data->position,
		   data->charsInBuffer);
#endif
	}
    }
}

/*-
 *-----------------------------------------------------------------------
 * TtyLook --
 *	Look to the right or left (based on 'direction') of the given
 *	position and return the character found there.
 *
 * Results:
 *	The appropriate character.
 *
 * Side Effects:
 *	The buffer is filled as necessary.
 *
 *-----------------------------------------------------------------------
 */
static char
TtyLook(data, position, direction)
    TtySourcePtr  	data;	    /* Private data */
    XtTextPosition	position;   /* Current position (between two
				     * characters, you know) */
    XtTextScanDirection direction;  /* Direction to look */
{
    if (direction == XtsdLeft) {
	if (position <= 0) {
	    /*
	     * Always return EOL at/beyond beginning of file
	     */
	    return('\n');
	} else {
	    if (position > data->length) {
		return (data->editBuf[EditPos(position-1,data)]);
	    } else if ((position <= data->position) ||
		       (position > data->position + data->charsInBuffer))
	    {
		TtyFillBuffer(data, position - 1, 1, FALSE);
	    }
	    return(data->buffer[position - data->position - 1]);
	}
    } else {
	if (position >= LastPos(data)) {
	    /*
	     * Always return EOL at/beyond end of buffer
	     */
	    return('\n');
	} else {
	    if (position >= data->length) {
		return (data->editBuf[EditPos(position,data)]);
	    } else if ((position < data->position) ||
		       (position >= data->position + data->charsInBuffer))
	    {
		TtyFillBuffer(data, position, 1, FALSE);
	    }
	    return(data->buffer[position - data->position]);
	}
    }
}

/*-
 *-----------------------------------------------------------------------
 * TtyReadText --
 *	Read text from the file. The returned text is not dynamically
 *	allocated and will be no longer than TTY_BUF_SIZE bytes.
 *
 * Results:
 *	The position after the characters read.
 *
 * Side Effects:
 *	The buffer is filled and *text changed.
 *
 *-----------------------------------------------------------------------
 */
static int
TtyReadText (src, pos, text, length)
    XtTextSource  	src;
    XtTextPosition	pos;	/** starting position */
    XtTextBlock		*text;	/** RETURNED: text read in */
    int			length;	/** max number of bytes to read **/
{
    XtTextPosition 	count;
    TtySourcePtr	data;
    
    data = (TtySourcePtr) src->data;
    if (length > TTY_BUF_SIZE) {
	XtError("TtyReadText: length > buffer size");
    }
    if (pos >= data->length) {
	/*
	 * Wants text from the edit buffer.
	 */
	text->firstPos = pos;
	text->ptr = &data->editBuf[EditPos(pos,data)];
	count = data->editChars - (pos - data->length);
    } else {
	if ((pos < data->position) ||
	    (data->position + data->charsInBuffer < pos + length))
	{
	    TtyFillBuffer(data, pos, length, FALSE);
	}
	text->firstPos = pos;
	text->ptr = data->buffer + (pos - data->position);
	count = data->charsInBuffer - (pos - data->position);
    }
    
    text->length = (length > count) ? count : length;
    if ((text->length == 0) && (pos != LastPos(data)) && (length != 0)) {
	XtError("Premature EOF");
    }
    return pos + text->length;
}


/***********************************************************************
 *				TtyDataToEnd
 ***********************************************************************
 * SYNOPSIS:	    Copy a buffer of data to the end of the file,
 *	    	    adjusting the dirty markers.
 * CALLED BY:	    TtyMigrate, TtyReplaceText
 * RETURN:	    Nothing
 * SIDE EFFECTS:    dirty markers are altered.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/18/89		Initial Revision
 *
 ***********************************************************************/
static void
TtyDataToEnd(data, src, nbytes)
    TtySourcePtr    data;   	/* Data for source */
    char    	    *src;   	/* Buffer of data to copy */
    int	    	    nbytes; 	/* Size of same */
{
    int dest;
    
    /*
     * Fill the buffer with enough room to add the characters
     */
    TtyFillBuffer(data, data->length, nbytes, TRUE);
    
    /*
     * Copy the characters from the edit buffer to the disk buffer
     */
    dest = data->length - data->position;
    bcopy(src, &data->buffer[dest], nbytes);
    
    /*
     * Modify the dirty markers to contain the new data
     */
    if (data->dirtyStart < 0 || data->dirtyStart > dest) {
	data->dirtyStart = dest;
    }
    if (data->dirtyEnd < dest+nbytes-1) {
	data->dirtyEnd = dest+nbytes-1;
    }
    /*
     * Adjust file boundary
     */
    data->length += nbytes;
    data->charsInBuffer += nbytes;
}


/***********************************************************************
 *				TtyMigrate
 ***********************************************************************
 * SYNOPSIS:	    Migrate data from the edit buffer to the end of the
 *	    	    file.
 * CALLED BY:	    TtyReplaceText, XtTtySourceSetFence
 * RETURN:	    Nothing
 * SIDE EFFECTS:    charsInBuffer, length, editChars, dirtyStart and
 *	    	    dirtyEnd are modified to reflect reality.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/18/89		Initial Revision
 *
 ***********************************************************************/
static void
TtyMigrate(data, ncopy)
    TtySourcePtr    data;
    int	    	    ncopy;  	/* Number of chars to migrate */
{
    TtyDataToEnd(data, data->editBuf, ncopy);

    /*
     * Copy the rest of the edit data down
     */
    bcopy(&data->editBuf[ncopy], data->editBuf, data->editChars-ncopy);
    data->editChars -= ncopy;
}
/*-
 *-----------------------------------------------------------------------
 * TtyReplaceText --
 *	Replace text in the edit buffer only. Further, the text to be
 *	replaced must be after the fence, as set by the creator of this
 *	widget. If it isn't, an error is generated.
 *
 * Results:
 *	PositionError or EditDone if successful.
 *
 * Side Effects:
 *	Characters may be removed from the edit buffer and/or added
 *	to it.
 *
 *-----------------------------------------------------------------------
 */
static int
TtyReplaceText (src, startPos, endPos, text)
    XtTextSource  	src;	    /* Us */
    XtTextPosition	startPos;   /* Start of text to nuke */
    XtTextPosition	endPos;	    /* End of text to nuke */
    XtTextBlock		*text;	    /* Text with which to replace nuked stuff*/
{
    TtySourcePtr	data;	    /* Private data */
    int	    	    	diff;	    /* Difference between old and new text
				     * length */
    int	    	    	ntail;	    /* Number of bytes in edit buffer after
				     * endPos */
    int	    	    	savedFirst; /* Saved text->firstPos */
    int	    	    	savedLength;/* Saved text->length */

    data = (TtySourcePtr) src->data;
    if (startPos < data->fence || endPos < startPos)
    {
	return (PositionError);
    }

    /*
     * Handle gross "get-me-a-character" function: if appending a single
     * character to the buffer, store the first character to be appended
     * at *data->getChar and turn off this gross mode. If the character
     * is not to be echoed, we don't even add the thing.
     */
    if (data->getChar && startPos == endPos && startPos == LastPos(data) &&
	text->length == 1)
    {
	*data->getChar = text->ptr[text->firstPos];
	data->getChar = NULL;

	if (!data->echo) {
	    return(EditDone);
	}
    }
    
    if (startPos != endPos) {
	/*
	 * Deal with fence having migrated into the file.
	 */
	if (startPos < data->length) {
	    if (endPos < data->length) {
		/*
		 * Can only do this if the ending position is in the
		 * edit buffer.
		 */
		return(PositionError);
	    }
	    /*
	     * Adjust endPos for deletion of characters at end of
	     * file.
	     */
	    endPos -= (data->length - startPos);
	    /*
	     * Record file truncation, assigning new positions to all the
	     * chars in the edit buffer thereby
	     */
	    data->length = startPos;
	    /*
	     * Truncate the file and update state variables.
	     */
	    ftruncate(data->fd, data->length);
	    if (data->position + data->charsInBuffer > data->length) {
		/*
		 * Reduce the number of characters in the buffer if it contains
		 * the last block of the file
		 */
		data->charsInBuffer = data->length - data->position;
	    }
	    if (data->dirtyEnd > data->charsInBuffer) {
		/*
		 * Trim dirty area to fit buffer
		 */
		data->dirtyEnd = data->charsInBuffer - 1;
	    }
	    if (data->dirtyStart > data->charsInBuffer) {
		/*
		 * If dirty area is now beyond buffer, nothing's
		 * dirty anymore
		 */
		data->dirtyStart = data->dirtyEnd = -1;
	    }
	}
    }

    diff = text->length - (endPos - startPos);
    ntail = data->editChars - EditPos(endPos,data);

    /*
     * Deal with adding lots of data to the buffer. We still only allow the
     * user to edit 1K, but we allow the user to add more than a K a
     * a time by migrating the text to be added straight to the end
     * of the disk file.
     */
    if (EditPos(startPos,data)+diff+ntail > TTY_BUF_SIZE) {
	/*
	 * FIRST ATTEMPT: Migrate half to the disk file
	 */
	int ncopy;
	
	ncopy = data->editChars/2;
	/*
	 * Don't migrate any of the data to be replaced
	 */
	if (ncopy > EditPos(startPos,data)) {
	    ncopy = EditPos(startPos, data);
	}
	TtyMigrate(data, ncopy);
    }

    if ((EditPos(startPos,data)+diff+ntail > TTY_BUF_SIZE) &&
	(startPos != data->length))
    {
	/*
	 * SECOND ATTEMPT: migrate any data remaining before the
	 * starting position, positioning startPos at the beginning of
	 * the edit buffer.
	 */
	TtyMigrate(data, EditPos(startPos, data));
    }

    /*
     * THIRD ATTEMPT: copy data from the front of the string that's to be
     * added straight to the file, reducing diff each time. We also
     * modify the firstPos and length accordingly, but set it back before
     * returning, since the caller expects it to be unmodified.
     * Note that we don't need the EditPos(startPos,data) term in the
     * test since we've shifted startPos to the start of the edit buffer.
     */
    savedFirst = text->firstPos;
    savedLength = text->length;
    while(diff+ntail > TTY_BUF_SIZE) {
	int 	ncopy;

	ncopy = diff;
	if (ncopy > TTY_BUF_SIZE) {
	    ncopy = TTY_BUF_SIZE;
	}
	TtyDataToEnd(data, text->ptr+text->firstPos, ncopy);
	text->firstPos += ncopy;
	diff -= ncopy;
	text->length -= ncopy;
	startPos += ncopy;
    }

    /*
     * Shuffle remaining characters so new ones will fit.
     */
    bcopy(&data->editBuf[EditPos(endPos,data)],
	  &data->editBuf[EditPos(endPos,data)+diff],
	  ntail);
	
    if (text->length > 0) {
	bcopy(text->ptr + text->firstPos,
	      &data->editBuf[EditPos(startPos,data)],
	      text->length);
    }
	
    /*
     * Restore preserved first position and length.
     */
    text->firstPos = savedFirst;
    text->length = savedLength;

    /*
     * Record increased number of editable characters.
     */
    data->editChars += diff;

    return (EditDone);
}


/***********************************************************************
 *			TtyFilterAndReplaceText
 ***********************************************************************
 * SYNOPSIS:	    Front-end to TtyReplaceText to take care of
 *	    	    backspaces, of all things.
 * CALLED BY:	    source->ReplaceText
 * RETURN:	    error, if TtyReplaceText returns one, else EditDone
 * SIDE EFFECTS:    Same as TtyReplaceText
 *
 * STRATEGY:
 *	The problem here is if someone prints a \b and expects the
 *	cursor to back up (or someone prints \b \b and expects to erase
 *	something), that someone will be sorely disappointed unless we
 *	deal with it somewhere, and this seems like the best place.
 *
 *	We need to run through the text being installed looking for \b.
 *	If there's one at the beginning of a chunk, we need to do a
 *	replace operation that will delete the preceeding character.
 *	If there's one in the middle of a string, we can just do
 *	a replace up to the character before the \b.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/19/89		Initial Revision
 *
 ***********************************************************************/
static int
TtyFilterAndReplaceText(src, startPos, endPos, text)
    XtTextSource    	src;
    XtTextPosition  	startPos;
    XtTextPosition  	endPos;
    XtTextBlock	    	*text;
{
    int	    	    	result;

    if (text->length == 0) {
	/*
	 * Nothing being added -- just pass on through.
	 */
	result = TtyReplaceText(src, startPos, endPos, text);
    } else {
	XtTextBlock 	ntext;
	char	    	*cp;
	int 	    	i;

	i = text->length, cp = text->ptr + text->firstPos;
	while (i > 0) {
	    if (*cp == '\b') {
		/*
		 * Backspace at the start -- see if there's a chain...
		 */
		int numToNuke;

		for (numToNuke = 1, cp++, i--;
		     i > 0 && *cp == '\b';
		     numToNuke++, cp++, i--)
		{
		    ;
		}
		/*
		 * Blow away the characters before the current start.
		 */
		ntext.firstPos = ntext.length = 0;
		result = TtyReplaceText(src, startPos-numToNuke, startPos,
					&ntext);
		if (result != EditDone) {
		    break;
		}
	    }

	    /*
	     * Set up new text block
	     */
	    ntext.ptr = cp;
	    ntext.firstPos = 0;
	    ntext.length = 1;

	    /*
	     * Skip to next backspace, keeping track of the length of the
	     * string being inserted.
	     */
	    for (cp++, i--; *cp != '\b' && i > 0; cp++, i--) {
		ntext.length += 1;
	    }

	    if (i > 0) {
		/*
		 * Hit a backspace. Adjust the length of the string to
		 * insert by the number of backspaces we've got.
		 */
		while (ntext.length != 0 && *cp == '\b' && i > 0) {
		    ntext.length -= 1;
		    cp += 1;
		    i -= 1;
		}
	    }
	    /*
	     * Perform the replacement, breaking out on error
	     */
	    result = TtyReplaceText(src, startPos, endPos, &ntext);
	    if (result != EditDone) {
		break;
	    }

	    /*
	     * Advance startPos so we don't nuke those new characters...
	     */
	    startPos += ntext.length;
	    /*
	     * If startPos now beyond endPos, just set endPos to startPos
	     * so we just end up inserting the rest of the characters.
	     */
	    if (startPos > endPos) {
		endPos = startPos;
	    }
	}
    }

    return(result);
}
	
/*-
 *-----------------------------------------------------------------------
 * TtySetLastPos --
 *	Set the bounding point for the file.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The length recorded in the private data for this source
 *	is altered.
 *
 *-----------------------------------------------------------------------
 */
static int
TtySetLastPos (src, lastPos)
    XtTextSource  	src;
    XtTextPosition	lastPos;
{
    ((TtySourceData *)(src->data))->length = lastPos;
    return(EditDone);
}

/*-
 *-----------------------------------------------------------------------
 * TtyGetLastPos --
 *	Return the last position in the source.
 *
 * Results:
 *	The last position in the file is returned.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static XtTextPosition
TtyGetLastPos(src)
    XtTextSource  src;
{
    TtySourceData   *data = (TtySourceData *)src->data;
    
    return(LastPos(data));
}

/*-
 *-----------------------------------------------------------------------
 * TtyScan --
 *	Scan through the file in the proper direction for the desired
 *	thing.
 *
 * Results:
 *	The new position.
 *
 * Side Effects:
 *	May refill the internal buffer.
 *
 *-----------------------------------------------------------------------
 */
static XtTextPosition
TtyScan (src, pos, sType, dir, count, include)
    XtTextSource 	 src;	    /* Source to use */
    XtTextPosition	 pos;	    /* Starting position */
    XtTextScanType	 sType;	    /* Type of scan desired */
    XtTextScanDirection  dir;	    /* Direction in which to go */
    int			 count;	    /* Number of sTypes to skip */
    Boolean		 include;   /* Scan inclusively? */
{
    TtySourcePtr  	data;	    /* Private data */
    XtTextPosition	position;   /* Current position */
    int			i;  	    /* General counter */
    char		c;  	    /* Current character */
    
    data = (TtySourcePtr) src->data;
    position = pos;
    switch (sType) {
	case XtstPositions: 
	    /*
	     * Scan count positions in the desired direction.
	     */
	    if (!include && count > 0) {
		count -= 1;
	    }
	    if (dir == XtsdLeft) {
		position -= count;
		if (position < 0) {
		    position = 0;
		}
	    } else {
		position += count;
		if (position > LastPos(data)) {
		    position = LastPos(data);
		}
	    }
	    break;
	case XtstWhiteSpace:
	{
	    /*
	     * Skip to and over count bits of whitespace. Note that
	     * we can't use the Increment macro as that bounds the
	     * traversal with 0 and LastPos(data). Should we allow this,
	     * we would never break out, since TtyLook returns \n at
	     * the start and end of the buffer. So we use 'incr' instead.
	     */
	    XtTextPosition	inSpace;
	    int	incr = (dir == XtsdRight) ? 1 : -1;
	    
	    for (i = 0; i < count; i++) {
		inSpace = -1;
		while (position >= 0 && position <= LastPos(data)) {
		    c = TtyLook(data, position, dir);
		    if ((c == ' ') || (c == '\t') || (c == '\n')) {
			inSpace = position;
		    } else if (inSpace >= 0) {
			/*
			 * Another whitespace area skipped...
			 */
			break;
		    }
		    position += incr;
		}
	    }
	    if (!include) {
		if (inSpace < 0 && dir == XtsdRight) {
		    position = LastPos(data);
		} else {
		    position = inSpace;
		}
	    }
	    if (position < 0) {
		position = 0;
	    } else if (position > LastPos(data)) {
		position = LastPos(data);
	    }
	    break;
	}
	case XtstEOL: 
	    for (i = 0; i < count; i++) {
		while (position >= 0 && position <= LastPos(data)) {
		    if (TtyLook(data, position, dir) == '\n')
			break;
		    Increment(data, position, dir);
		}
		if (i + 1 != count)
		    Increment(data, position, dir);
	    }
	    if (include) {
		/* later!!!check for last char in file # eol */
		Increment(data, position, dir);
	    }
	    break;
	case XtstAll: 
	    if (dir == XtsdLeft)
		position = 0;
	    else
		position = LastPos(data);
    }
    return(position);
}

/*-
 *-----------------------------------------------------------------------
 * TtyAddWidget --
 *	Warn that this function was called.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	A warning is printed.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
TtyAddWidget(src, w)
    XtTextSource  	src;
    Widget		w;
{
    XtWarning("TtyAddWidget called");
}

/*-
 *-----------------------------------------------------------------------
 * TtyRemoveWidget --
 *	Warn that this function was called.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	A warning is printed.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
TtyRemoveWidget(src, w)
    XtTextSource  	src;
    Widget		w;
{
    XtWarning("TtyRemoveWidget called");
}

/*-
 *-----------------------------------------------------------------------
 * TtyGetSelection --
 *	Warn that this function was called.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	A warning is printed.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static Boolean
TtyGetSelection(src, left, right)
    XtTextSource  	src;
    XtTextPosition	left;
    XtTextPosition	right;
{
    XtWarning("TtyGetSelection called");
}

/******* Public routines **********/

/*-
 *-----------------------------------------------------------------------
 * XtTtySourceCreate --
 *	Create a tty source. Only allows edit_mode XttextAppend, though
 *	the caller may specify a file to use either in args or as a
 *	fileName resource.
 *
 * Results:
 *	The new source.
 *
 * Side Effects:
 *	The file is opened and, if no fileName resource was found, a
 *	temporary file is created. The widget must be properly destroyed
 *	for the temporary file to be unlinked.
 *
 *-----------------------------------------------------------------------
 */
XtTextSource
XtTtySourceCreate(parent, args, num_args)
    Widget	parent;
    ArgList	args;
    Cardinal	num_args;
{
    XtTextSource src;
    TtySourcePtr data;
    long topPosition = 0;
    
    src = XtNew(XtTextSourceRec);
    data = XtNew(TtySourceData);
    
    src->Read 	    	    = TtyReadText;
    src->Replace    	    = TtyFilterAndReplaceText;
    src->GetLastPos 	    = TtyGetLastPos;
    src->SetLastPos 	    = TtySetLastPos;
    src->Scan 	    	    = TtyScan;
    src->AddWidget  	    = TtyAddWidget;
    src->RemoveWidget 	    = TtyRemoveWidget;
    src->SetSelection 	    = NULL; /* Nothing special */
    src->GetSelection 	    = NULL; /* Nothing special */
    src->ConvertSelection   = NULL; /* Nothing special */
    src->edit_mode  	    = XttextEdit;
    src->data		    = (caddr_t)data;
    
    XtGetSubresources (parent, (caddr_t)data, XtNtextSource, XtCTextSource,
		       srcResources, XtNumber(srcResources),
		       args, num_args);
    
    if (data->fileName == NULL) {
	data->fileName = tmpnam (XtMalloc((unsigned)TMPSIZ));
	data->is_tempfile = TRUE;
    } else {
        data->is_tempfile = FALSE;
    }
    
    if ((data->fd = open(data->fileName, O_RDWR|O_CREAT|O_TRUNC, 0600)) == 0) {
	XtError("Cannot open source file in XtTtySourceCreate");
    }
    data->fence = data->length = 0;
    data->position = data->length;
    data->dirtyStart = data->dirtyEnd = -1;
    data->editChars = data->charsInBuffer = 0;
    data->getChar = (char *)NULL;
    return src;
}

/*-
 *-----------------------------------------------------------------------
 * XtTtySourceGetFence --
 *	Get the boundary beyond which characters may not be deleted.
 *
 * Results:
 *	The fence for the source.
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
XtTextPosition
XtTtySourceGetFence(src)
    XtTextSource    src;
{
    return ((TtySourcePtr)src->data)->fence;
}
/*-
 *-----------------------------------------------------------------------
 * XtTtySourceSetFence --
 *	Set the boundary beyond which characters may not be deleted.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	data->fence is set to the given position.
 *
 *-----------------------------------------------------------------------
 */
void
XtTtySourceSetFence(src, fence)
    XtTextSource  	src;
    XtTextPosition	fence;	    /* Fence. -1 => end of file. */
{
    TtySourcePtr  	data;
    int	    	    	pre;	    /* Characters in editBuf before fence */
    int	    	    	post;	    /* Characters in editBuf after fence */
    int	    	    	n;	    /* Characters in buffer before new
				     * data */

    data = (TtySourcePtr)src->data;

    /*
     * Record the fence
     */
    if (fence >= data->length) {
	data->fence = fence;
    } else if (fence == -1) {
	data->fence = LastPos(data);
    } else {
	XtError("invalid fence specified for XtTtySourceSetFence");
    }

    /*
     * Flush the non-editable characters to the file.
     */
    TtyMigrate(data, data->fence - data->length);
}

/*-
 *-----------------------------------------------------------------------
 * XtTtySourceDestroy --
 *	Free up data associated with this source, including the
 *	XtTextSource structure itself.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Memory is freed and any temporary file opened is unlinked.
 *
 *-----------------------------------------------------------------------
 */
void
XtTtySourceDestroy (src)
    XtTextSource src;
{
    TtySourcePtr data;
    
    data = (TtySourcePtr) src->data;

    if (data->is_tempfile) {
        unlink(data->fileName);
	XtFree((char *) data->fileName);
    }
    close(data->fd);
    
    XtFree((char *) data);
    XtFree((char *) src);
}


/***********************************************************************
 *				XtTtySourceGetChar
 ***********************************************************************
 * SYNOPSIS:	    Turn on "get-me-a-character" mode for the source.
 * CALLED BY:	    XtTtyGetChar
 * RETURN:	    Nothing
 * SIDE EFFECTS:    getChar and noecho are set for the data.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/17/89		Initial Revision
 *
 ***********************************************************************/
void
XtTtySourceGetChar(src, cp, echo)
    XtTextSource    	src;
    char    	    	*cp;
    Boolean 	    	echo;
{
    TtySourcePtr    	data = (TtySourcePtr)src->data;

    data->echo = echo;
    data->getChar = cp;
}

/***********************************************************************
 *				XtTtySourceCharGotten
 ***********************************************************************
 * SYNOPSIS:	    Turn off "get-me-a-character" mode for the source.
 * CALLED BY:	    XtTtyCharGotten
 * RETURN:	    Nothing
 * SIDE EFFECTS:    getChar set null
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/17/89		Initial Revision
 *
 ***********************************************************************/
void
XtTtySourceCharGotten(src)
    XtTextSource    	src;
{
    TtySourcePtr    	data = (TtySourcePtr)src->data;

    data->getChar = (char *)NULL;
}
