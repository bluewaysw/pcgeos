/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- X11 interface, patient status display
 * FILE:	  status.c
 *
 * AUTHOR:  	  Adam de Boor: Jul 17, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/17/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to maintain the status bar at the top of the command
 *	window.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: status.c,v 1.3 91/04/04 12:13:45 adam Exp $";
#endif lint

#include    "swat.h"
#include    "sym.h"
#include    "event.h"
/*#include    "source.h"*/
#include    "ui.h"

#define Boolean XtBool
#define Opaque XtOpaque
#include    <X11/StringDefs.h>
#include    <X11/IntrinsicP.h>
#include    <X11/CoreP.h>
#undef Boolean
#undef Opaque

#define MAX_STATUS_LENGTH   512
#define INTERNAL_BORDER	    2

typedef struct { int empty; } StatusClassPart;

typedef struct _StatusClassRec {
    CoreClassPart	  core_class;
    StatusClassPart	  status_class;
} StatusClassRec;

typedef struct _StatusPart {
    XFontStruct	  	*font;	    	/* Font with which to draw */
    Pixel		foreground; 	/* Foreground pixel for display */
    Pixel		background; 	/* Background pixel for display */
    char		*moreStatus;	/* Additional status string (assumed to
					 * have been allocated by someone else
					 * so that someone can change it at
					 * will. */
    GC	    	  	gc;
    char    	  	lastStatus[MAX_STATUS_LENGTH];
    char		nextStatus[MAX_STATUS_LENGTH];
    int	    	  	columns;
    int			rows;
    int			charWidth;
    int			charHeight;
} StatusPart;

typedef struct _StatusRec {
    CorePart	  	core;
    StatusPart		status;
} StatusRec, *StatusWidget;

#define XtNstatus   "status"
#define XtCStatus   "Status"

static XtResource resources[] = {
{ XtNfont, XtCFont, XtRFontStruct, sizeof(XFontStruct *),
  XtOffset(StatusWidget, status.font), XtRString, "fixed" },
{ XtNforeground, XtCForeground, XtRPixel, sizeof(Pixel),
  XtOffset(StatusWidget, status.foreground), XtRString,XtExtdefaultforeground},
{ XtNbackground, XtCBackground, XtRPixel, sizeof(Pixel),
  XtOffset(StatusWidget, status.background), XtRString,XtExtdefaultbackground},
{ XtNstatus, XtCStatus, XtRString, sizeof(char *),
  XtOffset(StatusWidget, status.moreStatus), XtRString, NULL },
};

static void StatusInitialize(), StatusDestroy(), StatusResize(), StatusExpose();

static StatusClassRec statusClassRec = {
  { /* core fields */
    /* superclass       */      (WidgetClass) &widgetClassRec,
    /* class_name       */      "Status",
    /* widget_size      */      sizeof(StatusRec),
    /* class_initialize */      NULL,
    /* class_part_init  */	NULL,
    /* class_inited     */      FALSE,
    /* initialize       */      StatusInitialize,
    /* initialize_hook  */	NULL,
    /* realize          */      XtInheritRealize,
    /* actions          */      NULL,
    /* num_actions      */      0,
    /* resources        */      resources,
    /* num_ resource    */      XtNumber(resources),
    /* xrm_class        */      NULLQUARK,
    /* compress_motion  */      TRUE,
    /* compress_exposure*/      FALSE,
    /* compress_enterleave*/	TRUE,
    /* visible_interest */      FALSE,
    /* destroy          */      StatusDestroy,
    /* resize           */      StatusResize,
    /* expose           */      StatusExpose,
    /* set_values       */      NULL,
    /* set_values_hook  */	NULL,
    /* set_values_almost*/	XtInheritSetValuesAlmost,
    /* get_values_hook  */	NULL,
    /* accept_focus     */      XtInheritAcceptFocus,
    /* version          */	XtVersion,
    /* callback_private */      NULL,
    /* tm_table         */      NULL,
    /* query_geometry	*/  	XtInheritQueryGeometry,
    /* display_accelerator*/	XtInheritDisplayAccelerator,
    /* extension	*/	NULL
  },
  { /* status fields    */
    /* empty	      	*/  	0,
  }
};

WidgetClass	statusWidgetClass = (WidgetClass)&statusClassRec;

/*-
 *-----------------------------------------------------------------------
 * StatusChange --
 *	Change the status display for the patient.
 *
 * Results:
 *	=== EVENT_HANDLED.
 *
 * Side Effects:
 *	The status display changes.
 *
 *-----------------------------------------------------------------------
 */
static int
StatusChange(event, callData, w)
    Event		event;
    Opaque		callData;
    StatusWidget  	w;
{
    char    	  	*state;	    /* String form of machine state */
    int			start,	    /* Start of changed area */
			end,	    /* End of changed area */
			oldLength,  /* Length of previous status */
			clearWidth, /* Area to clear out */
			x;  	    /* Current x coordinate */
    char		*funcName;  /* Name of current function */
    Frame   	    	*f; 	    /* Current frame */


    switch(Event_Number(event)) {
	case EVENT_CONTINUE:
	    if (callData == CONTINUE_HALF) {
		/*
		 * If never really stopped DON'T PRINT ANYTHING. We don't
		 * want to slow down handle tracking any more than it
		 * already is...
		 */
		return(EVENT_HANDLED);
	    }
	    state = "RUN"; break;
	case EVENT_FULLSTOP:
	    state = "STOPPED"; break;
	default:
	    switch(sysFlags & (PATIENT_RUNNING|PATIENT_STOPPED|PATIENT_DIED)){
		case PATIENT_RUNNING:
		    state = "RUN"; break;
		case PATIENT_STOPPED:
		    state = "STOPPED"; break;
		case PATIENT_DIED:
		    state = "DEAD"; break;
		default:
		    state = "???"; break;
	    }
	    break;
    }

    /*
     * To handle EVENT_CHANGE properly, where the frame is unlikely to
     * have been set up, we have to call MD_CurrentFrame ourselves should
     * the patient's current frame be NULL. To avoid mucking with the
     * frame cache, we make sure we come after the MD handler.
     */
    if (curPatient->frame && MD_FrameValid(curPatient->frame)) {
	f = curPatient->frame;
    } else {
	f = MD_CurrentFrame();
    }

    if (f && !Sym_IsNull(f->function)) {
	funcName = Sym_Name(f->function);
    } else {
	funcName = "";
    }
    
    if (curPatient->file) {
	sprintf(w->status.nextStatus, "%.20s: %-7s %s \"%s\":%d %s",
		curPatient->name, state, funcName,
#if 0
		Source_Name(curPatient->file),
#else
		"???",
#endif
		curPatient->line,
		w->status.moreStatus ? w->status.moreStatus:"");
    } else {
	if (f && !Sym_IsNull(f->function)) {
	    Boolean  isFar;
	    char    *file;
	    word    ip;
	    word    cs;
	    char    *cp;

	    Sym_GetFuncData(f->function, &isFar, (Address *)NULL,
			    (Type *)NULL);
	    MD_GetFrameRegister(f, REG_MACHINE, REG_IP, &ip);
	    MD_GetFrameRegister(f, REG_MACHINE, REG_CS, &cs);

	    cp = rindex(file, '/');
	    if (cp++ == NULL) {
		cp = file;
	    }
	    
	    sprintf(w->status.nextStatus,
		    "%.20s: %-7s %-4s %s (%04x:%04x) %s%s %s",
		    curPatient->name, state, isFar ? "FAR" : "NEAR",
		    funcName, cs, ip, cp == file ? "" : "...",
		    cp, w->status.moreStatus ? : "");
	} else {
	    sprintf(w->status.nextStatus, "%.20s: %-7s %s *No File* %s",
		    curPatient->name, state, funcName,
		    w->status.moreStatus ? w->status.moreStatus:"");
	}
    }
    for (start = 0;
	 (w->status.nextStatus[start] == w->status.lastStatus[start]) &&
	 (w->status.nextStatus[start] != '\0');
	 start++)
    {
	/* void */ ;
    }
    end = strlen(w->status.nextStatus);
    oldLength = strlen(w->status.lastStatus);
    clearWidth = 0;
    
    if (end == oldLength) {
	while ((w->status.nextStatus[end] == w->status.lastStatus[end]) &&
	       (end > 0))
	{
	    end -= 1;
	}
	end += 1;
    } else if (end < oldLength) {
	clearWidth = w->status.charWidth * (oldLength - end);
    }

    x = start * w->status.charWidth + INTERNAL_BORDER;
    XDrawImageString(XtDisplay(w), XtWindow(w), w->status.gc,
		     x, 2 + w->status.font->ascent,
		     &w->status.nextStatus[start], end - start);

    strcpy(w->status.lastStatus, w->status.nextStatus);

    if (clearWidth) {
	XClearArea(XtDisplay(w), XtWindow(w),
		   end * w->status.charWidth + INTERNAL_BORDER, 0,
		   clearWidth, w->core.height, FALSE);
    }

    XFlush(XtDisplay(w));

    return(EVENT_HANDLED);
}

/*-
 *-----------------------------------------------------------------------
 * StatusInitialize --
 *	Initialize our widget.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	A gc is created and whatnot.
 *
 *-----------------------------------------------------------------------
 */
static void
StatusInitialize(request, new)
    StatusWidget  	request;
    StatusWidget  	new;
{
    XGCValues	  	gcv;

    gcv.font = new->status.font->fid;
    gcv.foreground = new->status.foreground;
    gcv.background = new->status.background;
    new->status.gc = XtGetGC(new, GCFont|GCForeground|GCBackground, &gcv);
    new->status.charWidth = new->status.font->max_bounds.width;
    new->status.charHeight =
	new->status.font->ascent + new->status.font->descent;
    if (new->core.height == 0) {
	new->core.height = new->status.charHeight + 4;
    }
    if (new->core.width == 0) {
	new->core.width = new->status.charWidth * 80 + 4;
    }
    new->status.columns = new->core.width / new->status.charWidth;
    new->status.rows = new->core.height / new->status.charHeight;
    new->status.lastStatus[0] = '\0';

}

/*-
 *-----------------------------------------------------------------------
 * StatusDestroy --
 *	Destroy our dynamic data. Note: we can't free our font b/c
 *	it could be being shared between widgets.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The data are freed.
 *
 *-----------------------------------------------------------------------
 */
static void
StatusDestroy(w)
    StatusWidget  	    w;
{
    XtDestroyGC(w->status.gc);
    /*XFreeFont(XtDisplay(w), w->status.font);*/
}

/*-
 *-----------------------------------------------------------------------
 * StatusResize --
 *	Widget has been resized -- deal with it.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The columns and rows change.
 *
 *-----------------------------------------------------------------------
 */
static void
StatusResize(w)
    StatusWidget  	    w;
{
    w->status.columns = w->core.width / w->status.charWidth;
    w->status.rows = w->core.height / (w->status.font->ascent +
				       w->status.font->descent);
}

/*-
 *-----------------------------------------------------------------------
 * StatusExpose --
 *	Expose a portion of the last status displayed.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The text is redisplayed.
 *
 *-----------------------------------------------------------------------
 */
static void
StatusExpose(w, event)
    StatusWidget  	    w;
    XEvent		    *event;
{
    int	    	  	    start;
    int			    end;

    start = event->xexpose.x / w->status.charWidth;
    end = ((event->xexpose.x+event->xexpose.width) + w->status.charWidth - 1)/
	w->status.charWidth;
    if (end > strlen(w->status.lastStatus)) {
	end = strlen(w->status.lastStatus);
    }
    if (event->xexpose.y < w->status.charHeight) {
	XDrawImageString(XtDisplay(w), XtWindow(w), w->status.gc,
			 start * w->status.charWidth,
			 2 + w->status.font->ascent,
			 &w->status.lastStatus[start], end - start);
    }
}


/***********************************************************************
 *				Status_Init
 ***********************************************************************
 * SYNOPSIS:	    Create the status widget.
 * CALLED BY:	    X11_Init
 * RETURN:	    Nothing
 * SIDE EFFECTS:    A Status widget be created
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
Status_Init(Widget  	vpane)
{
    Widget  	status;

    status = XtCreateManagedWidget("status", statusWidgetClass,
				   vpane, NULL, 0);
    
    (void)Event_Handle(EVENT_FULLSTOP, 	0, StatusChange, (Opaque)status);
    (void)Event_Handle(EVENT_CONTINUE, 	0, StatusChange, (Opaque)status);
    (void)Event_Handle(EVENT_STACK, 	0, StatusChange, (Opaque)status);
    (void)Event_Handle(EVENT_CHANGE, EVENT_MBL, StatusChange, (Opaque)status);
}
