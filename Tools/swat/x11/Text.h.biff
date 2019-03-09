/*
* $Header: Text.h,v 1.10 88/02/26 10:09:06 swick Exp $
*/


/***********************************************************
Copyright 1987, 1988 by Digital Equipment Corporation, Maynard, Massachusetts,
and the Massachusetts Institute of Technology, Cambridge, Massachusetts.

                        All Rights Reserved

Permission to use, copy, modify, and distribute this software and its 
documentation for any purpose and without fee is hereby granted, 
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in 
supporting documentation, and that the names of Digital or MIT not be
used in advertising or publicity pertaining to distribution of the
software without specific, written prior permission.  

DIGITAL DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL
DIGITAL BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR
ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
SOFTWARE.

******************************************************************/

#ifndef _XtText_h
#define _XtText_h

/****************************************************************
 *
 * Text widget
 *
 ****************************************************************/

/* Parameters:

 Name		     Class		RepType		Default Value
 ----		     -----		-------		-------------
 background	     Background		pixel		White
 border		     BorderColor	pixel		Black
 borderWidth	     BorderWidth	int		1
 destroyCallback     Callback		Pointer		NULL
 dialogHOffset	     Margin		int		10
 dialogVOffset	     Margin		int		10
 displayPosition     TextPosition	int		0
 editType	     EditType		XtTextEditType	XttextRead
 height		     Height		int		font height
 insertPosition	     TextPosition	int		0
 leftMargin	     Margin		int		2
 mappedWhenManaged   MappedWhenManaged	Boolean		True
 selectTypes	     SelectTypes	Pointer		(internal)
 selection	     Selection		Pointer		empty selection
 sensitive	     Sensitive		Boolean		True
 textOptions	     TextOptions	int		0
 textSink	     TextSink		Pointer		(none)
 textSource	     TextSource		Pointer		(none)
 width		     Width		int		100
 x		     Position		int		0
 y		     Position		int		0

*/


#define XtNtextOptions		"textOptions"
#define XtNdialogHOffset	"dialogHOffset"
#define XtNdialogVOffset	"dialogVOffset"
#define XtNdisplayPosition      "displayPosition"
#define XtNinsertPosition	"insertPosition"
#define XtNleftMargin		"leftMargin"
#define XtNselectTypes		"selectTypes"
#define XtNtextSource		"textSource"
#define XtNtextSink		"textSink"
#define XtNselection		"selection"

#define XtNeditType		"editType"
#define XtNfile			"file"
#define XtNstring		"string"
#define XtNlength		"length"
#define XtNfont			"font"

/* Class record constants */

extern WidgetClass textWidgetClass;
extern Atom FMT8BIT;

typedef struct _TextClassRec *TextWidgetClass;
typedef struct _TextRec      *TextWidget;

/* other stuff */

typedef long XtTextPosition;
typedef struct _XtTextSource XtTextSourceRec, *XtTextSource;
typedef struct _XtTextSink XtTextSinkRec, *XtTextSink;

typedef enum {XttextRead, XttextAppend, XttextEdit} XtTextEditType;
typedef enum {XtselectNull, XtselectPosition, XtselectChar, XtselectWord,
    XtselectLine, XtselectParagraph, XtselectAll} XtTextSelectType;

#define wordBreak		0x01
#define scrollVertical		0x02
#define scrollHorizontal	0x04
#define scrollOnOverflow	0x08
#define resizeWidth		0x10
#define resizeHeight		0x20
#define editable		0x40

extern void XtTextDisplay(); /* w */
    /* Widget w; */

extern void XtTextSetSelectionArray(); /* w, sarray */
    /* Widget        w;		*/
    /* SelectionType *sarray;   */

extern void XtTextSetLastPos(); /* w, lastPos */
    /* Widget        w;		*/
    /* XtTextPosition lastPos;  */

extern void XtTextGetSelectionPos(); /* dpy, w, left, right */
    /* Widget        w;		*/
    /* XtTextPosition *left, *right;    */

extern void XtTextSetSource(); /* dpy, w, source, startPos */
    /* Widget         w;	    */
    /* XtTextSource   source;       */
    /* XtTextPosition startPos;     */

extern int XtTextReplace(); /* w, startPos, endPos, text */
    /* Widget        w;		*/
    /* XtTextPosition   startPos, endPos; */
    /* XtTextBlock      *text; */

extern XtTextPosition XtTextTopPosition(); /* w */
    /* Widget        w;		*/

extern void XtTextSetInsertionPoint(); /*  w, position */
    /* Widget        w;		*/
    /* XtTextPosition position; */

extern XtTextPosition XtTextGetInsertionPoint(); /* w */
    /* Widget        w;		*/

extern void XtTextUnsetSelection(); /* w */
    /* Widget        w;		*/

extern void XtTextChangeOptions(); /* w, options */
    /* Widget        w;		*/
    /* int    options; */

extern int XtTextGetOptions(); /* w */
    /* Widget        w;		*/

extern void XtTextSetSelection(); /* w, left, right */
    /* Widget        w;		*/
    /* XtTextPosition left, right; */

extern void XtTextInvalidate(); /* w, from, to */
    /* Widget        w;		*/
    /* XtTextPosition from, to; */

extern XtTextSource XtTextGetSource() ; /* w */
    /* Widget        w;		*/

/*
 * Stuff from AsciiSink
 */

extern XtTextSink XtAsciiSinkCreate(); /* parent, args, num_args */
    /* Widget parent;		*/
    /* ArgList args;		*/
    /* Cardinal num_args;	*/

extern void XtAsciiSinkDestroy(); /* sink */
    /* XtTextSink  sink */

/*
 * from DiskSrc
 */
extern XtTextSource XtDiskSourceCreate(); /* parent, args, num_args */
    /* Widget	parent;		*/
    /* ArgList	args;		*/
    /* Cardinal	num_args;	*/

extern void XtDiskSourceDestroy(); /* src */
    /* XtTextSource src;	*/

/*
 * from StringSrc
 */

extern XtTextSource XtStringSourceCreate(); /* parent, args, num_args */
    /* Widget parent;		*/
    /* ArgList args;		*/
    /* Cardinal num_args;	*/

extern void XtStringSourceDestroy(); /* src */
    /* XtTextSource src;	*/


#endif _XtText_h
/* DON'T ADD STUFF AFTER THIS #endif */
