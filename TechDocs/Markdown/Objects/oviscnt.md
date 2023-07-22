# 25 VisContent
**VisContentClass** provides objects that can be used to head visible trees and 
interact with the GenView. The VisContent is a necessary class for any 
application that plans on displaying visible objects in a view.

You should be familiar with visible objects, visible object trees, and the 
GenView class. These topics can be found in "VisClass," Chapter 23 and 
"GenView," Chapter 9.

Because **VisContentClass** is a subclass of **VisCompClass**, it inherits all the 
instance data fields and messages of both that class as well as **VisClass**. You 
will likely want to read about both of those classes before reading this 
chapter. You can just read section 25.2 if you need a basic 
VisContent object - that section describes the most basic ways to use the 
VisContent without understanding its inner workings.

One particular area of interest involving VisContent objects is when using 
the GenDocument and document control objects. A GenDocument at 
run-time gets resolved by the specific UI into some permutation of 
VisContent; thus, when using GenDocuments, you don't use a VisContent as 
well. See "GenDocument," Chapter 13 for more information on documents in 
a view.

## 25.1 VisContent Instance Data
The VisContent has many instance data fields above and beyond those 
defined in **VisClass** and **VisCompClass**. These new instance fields deal with 
such topics as content attributes, the way the content interacts with the view, 
the document described by the content, and how the content handles input.

All the instance fields defined by **VisContentClass** and their definitions are 
shown in Code Display 25-1. Each field is described later in this section.

----------
**Code Display 25-1 VisContent Instance Data Fields**

	/* All the instance fields defined in VisContentClass are described below. You
	 * will likely use very few of them, if any; see the later sections of this
	 * chapter for specific information about each field. */

	/* The following fields deal with the GenView and the view window. */
	@instance optr				VCNI_view = 0;
	@instance WindowHandle		VCNI_window = 0;
	@instance word				VCNI_viewHeight = 0;
	@instance word				VCNI_viewWidth = 0;

	/* VCNI_attrs determines the content's attributes. */
	@instance VisContentAttrs	VCNI_attrs = 0;
	/* The possible flags for VCNI_attrs are
	 *	VCNA_SAME_WIDTH_AS_VIEW							0x80
	 *	VCNA_SAME_HEIGHT_AS_VIEW						0x40
	 *	VCNA_LARGE_DOCUMENT_MODEL						0x20
	 *	VCNA_WINDOW_COORDINATE_MOUSE_EVENTS				0x10
	 *	VCNA_ACTIVE_MOUSE_GRAB_REQUIRES_LARGE_EVENTS	0x08
	 *	VCNA_VIEW_DOC_BOUNDS_SET_MANUALLY				0x04	 */

	/* The following fields determine features of the content's document. */
	@instance PointDWord		VCNI_docOrigin = {0, 0};
	@instance PointWWFixed		VCNI_scaleFactor = { {0, 1}, {0, 1} };

	/* The following fields deal with how the content handles input. */
	@instance ChunkHandle		VCNI_prePassiveMouseGrabList = 0;
	@instance VisMouseGrab		VCNI_impliedMouseGrab =
							{0, 0, {0, 0}, (VIFGF_MOUSE | VIFGF_PTR), 0};
	@instance VisMouseGrab				VCNI_activeMouseGrab =
							{0, 0, {0, 0}, 0, 0};
	@instance ChunkHandle		VCNI_postPassiveMouseGrabList = 0;
	@instance KbdGrab			VCNI_kbdGrab = {0, 0};
	@instance FTVMCGrab			VCNI_focusExcl = {0, MAEF_FOCUS};
	@instance FTVMCGrab			VCNI_targetExcl = {0, MAEF_TARGET};
	@instance Handle			VCNI_holdUpInputQueue = 0;
	@instance word				VCNI_holdUpInputCount = 0;
	@instance byte				VCNI_holdUpInputFlags = 0;

	/* The type flags of the content are special and should not be altered. */
	@default		VI_typeFlags =	VTF_IS_COMPOSITE | VTF_IS_WINDOW |
						VTF_IS_CONTENT | VTF_IS_WIN_GROUP |
						VTF_IS_INPUT_NODE;

----------
### 25.1.1 The VCNI_attrs Field
	VCNI_attrs, MSG_VIS_CONTENT_SET_ATTRS, 
	MSG_VIS_CONTENT_GET_ATTRS
The *VCNI_attrs* field is a record of **VisContentAttrs** that contains several 
attributes which affect how the content object interacts with the view and 
with the visible object tree. You can set these attributes with 
MSG_VIS_CONTENT_SET_ATTRS dynamically, and you can retrieve them 
with MSG_VIS_CONTENT_GET_ATTRS.

The flags in this field are shown below. None of them is set by default.

VCNA_SAME_WIDTH_AS_VIEW  
This flag indicates that the content's width should follow the 
width of the view window, if possible. Most likely, you will want 
to set this if the view is not horizontally scrollable.

VCNA_SAME_HEIGHT_AS_VIEW  
This flag indicates that the content's height should follow the 
height of the view window, if possible. Most likely you will want 
to set this flag if the view is not vertically scrollable.

VCNA_LARGE_DOCUMENT_MODEL  
This flag indicates that the content object manages a large 
document (32-bit coordinates rather than the standard 16-bit 
coordinates). For information on how this affects the content 
and its children, see section 23.6.1 above.

VCNA_WINDOW_COORDINATE_MOUSE_EVENTS  
This flag must be set if VCNA_LARGE_DOCUMENT_MODEL is 
set. It indicates that the associated GenView will pass input 
events with window coordinates rather than document 
coordinates. The default handlers in the content object will 
then automatically translate the events into document 
coordinates.

VCNA_ACTIVE_MOUSE_GRAB_REQUIRES_LARGE_EVENTS  
This flag indicates that the object that currently has the active 
mouse grab requires mouse input events to carry large 
document coordinates rather than the standard document 
coordinates. This flag is set and reset with the message 
MSG_VIS_VUP_ALTER_INPUT_FLOW. Large content objects 
should not set this flag in their Goc declarations.

VCNA_VIEW_DOC_BOUNDS_SET_MANUALLY  
Not often used, this flag indicates that the content should not 
send its document bounds off to the view during a geometry 
update. The GenView's document bounds must be set 
manually, most likely with the GenView message 
MSG_GEN_VIEW_SET_DOC_BOUNDS.

VCNA_VIEW_DOES_NOT_WIN_SCROLL  
This flag indicates that the view does not scroll but instead 
sends MSG_META_CONTENT_VIEW_ORIGIN_CHANGED to the 
content when the user interacts with the scroller. The UI will 
use this flag to invalidate the correct region of the content. This 
should be set when ATTR_GEN_VIEW_DO_NOT_WIN_SCROLL is 
set in the GenView. See "Scrolling" in "GenView," 
Chapter 9, for full information on view scrolling.

----------
#### MSG_VIS_CONTENT_SET_ATTRS
	void	MSG_VIS_CONTENT_SET_ATTRS(
			VisContentAttrs attrsToSet,
			VisContentAttrs attrsToClear);
This message sets the *VCNI_attrs* field of the content object according to the 
passed values.

**Source:** Unrestricted.

**Destination:** Any VisContent object.

**Parameters:**  
*attrsToSet* - This is a record of **VisContentAttrs** to set. A flag 
set in this field will be set in the object's *VCNI_attrs* 
field.

*attrsToClear* - This is a record of **VisContentAttrs** to clear. A flag 
set in this field will be cleared in the object's 
*VCNI_attrs* field. This parameter takes precedence 
over *attrsToSet*; that is, if a flag is set in both 
parameters, it will end up cleared.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_VIS_CONTENT_GET_ATTRS
	VisContentAttrs MSG_VIS_CONTENT_GET_ATTRS();
This message returns the current contents of the object's *VCNI_attrs* field, a 
record of **VisContentAttrs**.

**Source:** Unrestricted.

**Destination:** Any VisContent object.

**Parameters:** None.

**Return:** A record of **VisContentAttrs** reflecting the flags currently set in the 
object's *VCNI_attrs* field.

**Interception:** Unlikely.

### 25.1.2 Fields That Affect the View
	VCNI_view, VCNI_viewHeight, VCNI_viewWidth, VCNI_window, 
	MSG_VIS_CONTENT_GET_WIN_SIZE

Because the content must interact directly with the view, it must maintain 
some information about both the GenView object and its associated window. 
**VisContentClass** defines four fields that deal exclusively with view-related 
information. Each of these fields is described below.

*VCNI_view*  
This field contains the optr of the GenView object. The content 
should not ever actually use this field for the view's optr; if you 
need to contact the view, you should instead use the messages 
MSG_VIS_VUP_SEND_TO_OBJECT_OF_CLASS and 
MSG_VIS_VUP_CALL_OBJECT_OF_CLASS. The field will be set 
automatically by the GenView when the view is opened; the 
view will send a MSG_META_CONTENT_VIEW_OPENING.

*VCNI_viewHeight*  
This field contains the height, in document coordinates, of the 
view window. This will be set by the view object and should not 
be altered by the application; it can be retrieved with the 
message MSG_VIS_CONTENT_GET_WIN_SIZE (below). The 
view automatically notifies the content each time the window 
size changes with MSG_VIS_CONTENT_VIEW_SIZE_CHANGED.

*VCNI_viewWidth*  
This field contains the width, in document coordinates, of the 
view window. This will be set by the view object and should not 
be altered by the application; it can be retrieved with the 
message MSG_VIS_CONTENT_GET_WIN_SIZE (below). The 
view automatically notifies the content on each window resize 
with MSG_META_CONTENT_VIEW_SIZE_CHANGED.

*VCNI_window*  
This field contains the window handle of the view's window. 
This field is set by the view object and should not be accessed 
by the application. If an object under the content needs to get 
the window handle, it should use MSG_VIS_QUERY_WINDOW. 
This field will be set automatically by the GenView when the 
view's window is first opened. The view will send the messages 
MSG_META_CONTENT_VIEW_WIN_OPENED and 
MSG_META_CONTENT_VIEW_OPENING to set the window 
handle. When the view window closes, the view will send 
MSG_META_CONTENT_VIEW_CLOSING and 
MSG_META_CONTENT_VIEW_WIN_CLOSED.

The messages shown above that are sent by the view to the content are 
detailed in "Messages Received from the View" below.

----------
#### MSG_VIS_CONTENT_GET_WIN_SIZE
	SizeAsDWord MSG_VIS_CONTENT_GET_WIN_SIZE();
This message returns the size of the content object's associated window in 
terms of width and height.

**Source:** Unrestricted.

**Destination:** Any VisContent object.

**Parameters:** None.

**Return:** A **SizeAsDWord** value with the window's width in the high word and 
the window's height in the low word. Use the DWORD_HEIGHT and 
DWORD_WIDTH macros to extract the proper values.

**Interception:** Unlikely.

### 25.1.3 Fields That Affect the Document
	VCNI_docOrigin, VCNI_scaleFactor, 
	MSG_VIS_CONTENT_SET_DOC_BOUNDS, 
	MSG_VIS_CONTENT_RECALC_SIZE_BASED_ON_VIEW
The GenView object maintains quite a bit of information about the document 
as managed by the content object. The content must also keep information 
about the document and how the view is displaying it. This information is 
stored in two fields, *VCNI_docOrigin* and *VCNI_scaleFactor*, both detailed 
below.

The document bounds of the content are typically equal to the bounds of the 
VisContent itself. The content's bounds are stored in the *VI_bounds* field 
inherited from **VisClass**. When a content is managing layers or large 
documents, however, its bounds are set to zero. It then manages its document 
bounds within the layer objects and the GenView. When the document 
bounds change, a MSG_VIS_CONTENT_SET_DOC_BOUNDS should be sent to 
the content to get it to notify all its layer children and the GenView of the new 
bounds. This message is shown at the end of this section.

If the content is not a large document and is set up to follow the GenView's 
geometry (it has either or both of VCNA_SAME_WIDTH_AS_VIEW or 
VCNA_SAME_HEIGHT_AS_VIEW set), it will be affected by changes in the 
view's geometry. During geometry updates, the view will send it a 
MSG_VIS_CONTENT_RECALC_SIZE_BASED_ON_VIEW. This message sets the 
content's width and/or height and therefore affects its *VI_bounds* field. This 
message is also shown at the end of this section.

*VCNI_docOrigin*  
This field contains the current origin of the view window. The 
origin is the location of the view's upper left corner in the 
document (where the scrollers are). This field is of type 
**PointDWord**, which has the following structure:

	typedef struct {
		sdword   PD_x;    /* x coordinate of origin */
		sdword   PD_y;    /* y coordinate of origin */
	} PointDWord;

Normally, this field is set when the view is first opened or when 
the view is scrolled, scaled, or otherwise changed in document 
position. The view will send the message 
MSG_META_CONTENT_VIEW_ORIGIN_CHANGED to indicate 
the origin is different from its current setting.

*VCNI_scaleFactor*  
This field contains the current scale factor the view is 
displaying. Scaling is implemented almost entirely in the 
GenView object; some content objects, however, will want to 
react in a special way when the scale factor is changed. The 
scale factor is stored in a **PointWWFixed** structure, as follows:

	typedef struct {
	WWFixed    PF_x;   /* horizontal scale factor */
	WWFixed    PF_y;   /* vertical scale factor */
	} PointWWFixed;

The **WWFixed** structures that determine the scale factor in 
each dimension consist of two elements. This structure is 
shown below:

	typedef struct {
	word    WWF_frac;   /* fractional portion */
	word    WWF_int;    /* integral portion */
	} WWFixed;

The *VCNI_scaleFactor* field in the content is never set directly 
by the application; instead, it is set with 
MSG_META_CONTENT_VIEW_SCALE_FACTOR_CHANGED 
whenever the view's scale factor changes.

Messages that set these fields are discussed in section 25.2.2 below.

----------
#### MSG_VIS_CONTENT_SET_DOC_BOUNDS
	void	MSG_VIS_CONTENT_SET_DOC_BOUNDS(@stack
			sdword	bottom,
			sdword	right,
			sdword	top,
			sdword	left);
This message is used to set the document bounds of a content's large 
document. The content will send MSG_GEN_VIEW_SET_DOC_BOUNDS to its 
view and MSG_VIS_LAYER_SET_DOC_BOUNDS to each of its children with 
the new bounds. The recipient content *must* have the flag 
VCNA_LARGE_DOCUMENT_MODEL set in *VCNI_attrs*.

**Source:** Unrestricted.

**Destination:** Any *large* VisContent object - if the content is not using the large 
document model, an error will result.

**Parameters:**  
*bottom, right, top, left* - The new document bounds in 32-bit document 
coordinates.

**Return:** Nothing.

**Interception:** Unlikely.

**Warnings:** You may only send this message to a content that is using the large 
document model. All other contents will not handle this message but 
will result in a fatal error.

----------
#### MSG_VIS_CONTENT_RECALC_SIZE_BASED_ON_VIEW
	SizeAsDWord MSG_VIS_CONTENT_RECALC_SIZE_BASED_ON_VIEW();
This message causes the content to recalculate its size based on the view's 
geometry. It will try to set its width if it has VCNA_SAME_WIDTH_AS_VIEW 
set, and it will try to set its height if it has VCNA_SAME_HEIGHT_AS_VIEW 
set.

**Source:** Unrestricted - typically sent by the view or by the content to itself 
during geometry updates.

**Destination:** Any VisContent object.

**Parameters:** None.

**Return:** A **SizeAsDWord** value indicating the new size of the content. Use the 
macros DWORD_HEIGHT and DWORD_WIDTH to extract the 
appropriate values.

**Interception:** Unlikely.

### 25.1.4 Fields That Affect Input Events
One of the main features of **VisContentClass** is its ability to handle, 
manage, and pass on input events sent through the GenView. The content 
has a large amount of functionality built into it to provide these features.

#### 25.1.4.1 Mouse and Keyboard Grabs
	VCNI_prePassiveMouseGrabList, VCNI_impliedMouseGrab, 
	VCNI_activeMouseGrab, VCNI_postPassiveMouseGrabList, 
	VCNI_kbdGrab, MSG_VIS_CONTENT_UNWANTED_MOUSE_EVENT, 
	MSG_VIS_CONTENT_UNWANTED_KBD_EVENT, 
	MSG_VIS_CONTENT_TEST_IF_ACTIVE_OR_IMPLIED_WIN
**VisContentClass**, as the head of the visible tree displayed in the view, keeps 
track of which object in its tree has each different type of input grab. With 
this information, the content can simply pass the input event directly to the 
object that has the grab. It can also easily send the event to both the 
prepassive and postpassive grab objects, if any.

To do this, it uses five instance fields that applications can not directly access. 
These fields are altered by the messages that allow an object to gain and 
release the subject grab. (These messages are all detailed in "Handling 
Input" in "VisClass," Chapter 23.) The instance fields are listed 
below:

*VCNI_prePassiveMouseGrabList*  
This field is a pointer to a chunkarray containing the list of 
objects that currently have the prepassive mouse grab.

*VCNI_impliedMouseGrab*  
This field is a **VisMouseGrab** (described below) structure that 
contains details about the object which has the implied mouse 
grab.

*VCNI_activeMouseGrab*  
This field is a **VisMouseGrab** (described below) structure that 
contains details about the object which has the active mouse 
grab.

*VCNI_postPassiveMouseGrabList*  
This field is a pointer to a chunkarray containing the list of 
objects that currently have the postpassive mouse grab.

*VCNI_kbdGrab*  
This field is a **KbdGrab** structure that contains details about 
the object which currently has the keyboard grab.

You will probably not ever have to know the structure of these fields, how to 
set them, or the information they contain. However the two structures 
**VisMouseGrab** and **KbdGrab** are shown in Code Display 25-2 for your 
information.

----------
**Code Display 25-2 Grab Data Structures**

	/* These structures are obscure, and you will likely never have to use them. */

	/* The VisMouseGrab structure contains information about the object that
	 * currently has the mouse grab. */
	typedef struct {
		optr		VMG_object;		/* The optr of the object that has the grab.
								 * If no object has the grab, this is zero. */
		WindowHandle	VMG_gWin;	/* The window handle of the window with the object
								 * having the grab, if it's different from
								 * the content's window. If it's in the content's
								 * window, this field contains zero.	*/
		PointDWord	VMG_translation;/* The 32-bit translation applied to mouse events
								 * if the large document model is in use. This is
								 * set with a previous message call. */
		VisInputFlowGrabFlags VMG_flags; /* A record of VisInputFlowGrabFlags,
								   * described below. */
		byte		VMG_unused;		/* Reserved byte. */
	} VisMouseGrab;

	/* The VisInputFlowGrabFlags determine the type and context of the grab. These
	 * flags are not listed here for simplicity. You do not have to know these flags;
	 * they are set with MSG_VIS_VUP_ALTER_INPUT_FLOW. */

	/* The KbdGrab structure contains information about the object that currently
	 * has the keyboard grab. */
	typedef struct {
		optr		KG_OD;			/* The optr of the object that has the
									 * keyboard grab. */
		word		KG_unused;		/* Reserved word. */
	} KbdGrab;

----------
In addition, the VisContent has the following messages that are affected by 
the input grab fields:

MSG_VIS_CONTENT_TEST_IF_ACTIVE_OR_IMPLIED_WIN  
This message returns *true* if the passed window handle is the 
same as the active or implied window currently translating 
mouse events. It returns false otherwise. This is used by 
specific UI objects.

MSG_VIS_CONTENT_UNWANTED_MOUSE_EVENT  
This message is sent by the content to itself if a mouse event 
has arrived and there is no implied or active grab in the 
content's visible tree. The default reaction is to beep if the event 
is a button press. It's highly unlikely that you'll send or 
intercept this message.

MSG_VIS_CONTENT_UNWANTED_KBD_EVENT  
This message is sent by the content to itself if a keyboard event 
has arrived and there is no keyboard grab set up. It is highly 
unlikely that you will ever send or intercept this message.

----------
#### MSG_VIS_CONTENT_TEST_IF_ACTIVE_OR_IMPLIED_WIN
	Boolean	MSG_VIS_CONTENT_TEST_IF_ACTIVE_OR_IMPLIED_WIN(
			WindowHandle window);
This message checks to see if the passed window handle is the same as the 
window of the object having either the implied or active mouse grab. This is 
typically used by objects in a Specific UI library to determine if the mouse 
event was actually within the window or directly on the window's border.

**Source:** Unrestricted.

**Destination:** Any VisContent object.

**Parameters:**  
*window* - The window handle to be checked.

**Return:** *True* if the window handle is the same as either the active or the 
implied window, *false* otherwise.

**Interception:** Unlikely.

----------
#### MSG_VIS_CONTENT_UNWANTED_MOUSE_EVENT
	void	MSG_VIS_CONTENT_UNWANTED_MOUSE_EVENT(
			VisMouseGrab *mouseGrab,
			word	inputState);
This message is received by the content if a mouse event was received and 
there was no active or implied grab. This is most frequently encountered 
when the user presses a mouse button outside a modal dialog box. The 
default action of this handler is to beep (on presses only, not releases) and get 
rid of the event as if it had been handled.

**Source:** Input flow mechanism.

**Destination:** The affected VisContent object.

**Parameters:**  
*mouseGrab* - A pointer to the appropriate **VisMouseGrab** 
structure.

*inputState* - Same as passed with the actual event.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_VIS_CONTENT_UNWANTED_KBD_EVENT
	void	MSG_VIS_CONTENT_UNWANTED_KBD_EVENT(
			word	character,
			word	flags,
			word	state);

This message will be received by the content if a keyboard event was sent and 
there was no keyboard grab set up. The default action of the content is to beep 
(on presses only, not releases) and return as if the event had been processed.

**Source:** Input flow mechanism.

**Destination:** The affected VisContent object.

**Parameters:**  
*character* - The keyboard character pressed.

*flags* - A word of flags: The low byte is a **CharFlags** 
record, and the high byte is a **ShiftState** record. 
Both *are the same as passed with the original 
MSG_META_KBD_CHAR.

state* - A word containing two values: The low byte is a 
record of **ToggleState**, and the high byte is the 
scan code. Both are the same as passed with the 
original MSG_META_KBD_CHAR.

**Return:** Nothing.

**Interception:** Unlikely.

#### 25.1.4.2 Focus and Target
	VCNI_focusExcl, VCNI_targetExcl, 
	MSG_META_CONTENT_APPLY_DEFAULT_FOCUS
In addition to keeping track of which of its children have the mouse and 
keyboard grabs, the content also keeps track of which objects have the focus 
and target input exclusives. Both *VCNI_focusExcl* and VCNI_targetExcl 
contain a structure of type **FTVMCGrab** that describes the object that has 
the subject exclusive. The messages sent by the GenView that set these fields 
are described in "Messages Received from the View" below.

#### 25.1.4.3 Input Flow Control
	VCNI_holdUpInputQueue, VCNI_holdUpInputCount, 
	VCNI_holdUpInputFlags, 
	MSG_VIS_CONTENT_HOLD_UP_INPUT_FLOW, 
	MSG_VIS_CONTENT_RESUME_INPUT_FLOW, 
	MSG_VIS_CONTENT_DISABLE_HOLD_UP, 
	MSG_VIS_CONTENT_ENABLE_HOLD_UP
GEOS allows a visible tree to hold up input - that is, input will be stored 
elsewhere while the visible tree is doing something else. This can be useful if 
complex tree operations are going on and you don't want input to go to the 
wrong object.

**VisContentClass** provides three instance fields that define the input holdup 
mechanism. These three fields are:

*VCNI_holdUpInputQueue*  
This field contains the queue handle of the queue where 
held-up input will be temporarily stored. Input events will go 
into this event queue until they are allowed to be handled 
again; then they will be sent to their proper recipients.

*VCNI_holdUpInputCount*  
This field contains a count of the number of objects that have 
requested that input be held up. If this count is positive, input 
will be held up and input events will go into the hold-up queue.

*VCNI_holdUpInputFlags*  
This field contains a record of flags which determine the state 
of the hold-up mechanism. The following two flags are allowed:  
HUIF_FLUSHING_QUEUE  
This flag indicates that the hold-up queue is currently being 
flushed.  
HUIF_HOLD_UP_MODE_DISABLED  
This flag forces input events to flow normally. It is used 
primarily by GEOS to ensure that the user can interact with a 
system-modal dialog box.

**VisContentClass** has four messages that it sends to itself to set the state of 
information hold-up. These messages are detailed below.

----------
#### MSG_VIS_CONTENT_HOLD_UP_INPUT_FLOW
	void	MSG_VIS_CONTENT_HOLD_UP_INPUT_FLOW();
This message increments the count in *VCNI_holdUpInputCount*. If this count 
is nonzero and HUIF_HOLD_UP_MODE_DISABLED is clear, subsequent input 
events will be sent into the hold-up queue until either the flag is set or the 
count once more drops to zero.

**Source:** Unrestricted.

**Destination:** Any VisContent object.

**Interception:** Unlikely.

**Warnings:** Do not forget to resume input with a later use of the message 
MSG_VIS_CONTENT_RESUME_INPUT_FLOW.

----------
#### MSG_VIS_CONTENT_RESUME_INPUT_FLOW
	void	MSG_VIS_CONTENT_RESUME_INPUT_FLOW();
This message decrements the count in *VCNI_holdUpInputCount*. If the count 
becomes zero with this call, the hold-up event queue is flushed and all the 
events in it are "played back." If the count goes below zero, GEOS will give an 
error. Therefore, do not use this message unless it is preceded with a 
MSG_VIS_CONTENT_HOLD_UP_INPUT_FLOW.

**Source:** Unrestricted.

**Destination:** Any VisContent object.

**Interception:** Unlikely.

**Warnings:** If this message is used without first holding up input with 
MSG_VIS_CONTENT_HOLD_UP_INPUT_FLOW, an error will be the 
likely result. The error condition is the *VCNI_holdUpInputCount* field 
going below zero.

----------
#### MSG_VIS_CONTENT_DISABLE_HOLD_UP
	void	MSG_VIS_CONTENT_DISABLE_HOLD_UP();
This message sets the HUIF_HOLD_UP_MODE_DISABLED flag, forcing all 
input events to flow normally until the flag is cleared. In essence, it turns off 
the hold-up mechanism.

**Source:** Unrestricted.

**Destination:** Any VisContent object.

**Interception:** Unlikely.

----------
#### MSG_VIS_CONTENT_ENABLE_HOLD_UP
	void	MSG_VIS_CONTENT_ENABLE_HOLD_UP();
This message clears the HUIF_HOLD_UP_MODE_DISABLED flag, allowing 
input events to be held up in the hold-up event queue.

**Source:** Unrestricted.

**Destination:** Any VisContent object.

**Interception:** Unlikely.

## 25.2 Basic VisContent Usage
You will probably not have to subclass **VisContentClass** unless you are 
using a large document or you want the content to draw something in 
response to a MSG_VIS_DRAW. In most other cases, you can declare your 
content object directly on **VisContentClass**.

Most VisContent behavior is inherited directly from **VisCompClass**. Some 
additional behavior is detailed in the following sections.

If you are planning on using the document control objects with GenViews, 
you will not need VisContent objects. The GenDocument resolves at run-time 
into a subclass of VisContent and therefore replaces the need for an 
explicitly-defined VisContent object. See "GenDocument," Chapter 13 for full 
information on GenDocuments.

### 25.2.1 Setting Up Sizing Behavior
Most geometry behavior revolves around whether the GenView is scrollable 
or not. You can set up several different sizing behaviors depending on the 
attributes you set in the GenView. Some are listed below with the attributes 
you should set in both the GenView and the VisContent.

Typically, setting the view's attributes will involve either setting or not 
setting the GVDA_SCROLLABLE flag in the appropriate GenView dimension; 
also, you will want to be aware of the GVDA_NO_LARGER_THAN_CONTENT 
and GVDA_NO_SMALLER_THAN_CONTENT flags.

#### 25.2.1.1 If the Content Is Fixed Size
Typically, if the content object is a fixed size, the view will either conform to 
the content's size or scroll in one or both dimensions. This behavior is 
determined entirely within the GenView's instance data. Three types of this 
behavior are shown in Code Display 25-3.

----------
**Code Display 25-3 Sizing the View with a Fixed Content**

	/* This code display shows three different types of sizing behavior of the GenView
	 * if its VisContent object is of a fixed size. Note that if the content is
	 * managing its geometry, its bounds (and therefore the view's) will be determined
	 * by the content's children. */

	/* The view window is scrollable in both dimensions. This will result in the view
	 * being sizable and scrollable in both dimensions. */
	@object GenViewClass MyView = {
		GVI_content = @MyVisContent;
		GVI_horizAttrs = @default | GVDA_SCROLLABLE;
		GVI_vertAttrs = @default | GVDA_SCROLLABLE;
	};

	/* The view window is scrollable in only the vertical dimension. It follows the
	 * width of the VisContent object and therefore does not scroll vertically. The
	 * VisContent's VI_bounds field should be set by the content. */
	@object GenViewClass MyView = {
		GVI_content = @MyVisContent;
		GVDI_horizAttrs = @default	| GVDA_NO_LARGER_THAN_CONTENT
									| GVDA_NO_SMALLER_THAN_CONTENT;
		GVDI_vertAttrs = @default	| GVDA_SCROLLABLE;
	};

	/* The view window sizes itself exactly to the size of the VisContent's bounds.
	 * The VisContent's VI_bounds field should be set appropriately by the content. 
	 * Note that this is not a valid combination for VisContents that display large
	 * documents or layer objects. */
	@object GenViewClass MyView = {
		GVI_content = @MyVisContent;
		GVDI_horizAttrs = @default	| GVDA_NO_LARGER_THAN_CONTENT
									| GVDA_NO_SMALLER_THAN_CONTENT;
		GVDI_vertAttrs = @default	| GVDA_NO_LARGER_THAN_CONTENT
									| GVDA_NO_SMALLER_THAN_CONTENT;
	}

----------
Another type of behavior with fixed-size contents is called "keeping the 
aspect ratio." The view and content can work together to allow the user to 
resize the view while automatically setting the view's scale factor to keep the 
entire content in the window. This might be used, for example, for a game 
board; the game could be resized, and the entire game board would stay in 
the view.

In this situation, the content calculates its new size based on one of the view's 
dimensions. For example, when the user resizes the view, the content may 
keep the width but calculate the height based on the width. The proper scale 
factor is then set, and the content does not have to do anything special 
beyond that. To gain this behavior, set up your view and content as shown in 
Code Display 25-4.

----------
**Code Display 25-4 Keeping the View Aspect Ratio**

	/* This example shows a view and its content. The content object is of a fixed
	 * size, and the view is resizable. The content/view pair will keep the aspect
	 * ratio to automatically figure the view's height based on its width and then
	 * scale the image to keep the entire bounds of the content within the view
	 * window. */
	@object GenViewClass MyView = {
		GVI_content = @MyVisContent;
		GVDI_horizAttrs = @default	| GVDA_NO_LARGER_THAN_CONTENT
									| GVDA_NO_SMALLER_THAN_CONTENT;
		GVDI_vertAttrs = @default	| GVDA_KEEP_ASPECT_RATIO;
	};

	@object VisContentClass MyVisContent = {
		VI_bounds =	{0,		/* left bound */
					 0,		/* top bound */
					 250,	/* right bound */
					 250};	/* bottom bound */
		VCI_comp =			/* put any children here */;
		VCI_geoAttrs = VCGA_CUSTOM_MANAGE_CHILDREN;
		/* This is set because typically a content's bounds are determined
		 * by its children. If we want to set our own bounds, we should
		 * custom manage our geometry. This is true of contents used with
		 * the views in the previous example. */
	};

----------
#### 25.2.1.2 If the Content Is Variable Size
Many visible trees will have contents that are of variable size. How the 
content determines its size differs from use to use; some contents will adjust 
their geometries to those of their view objects, and some will resize 
themselves based on the geometry of their children.

Typically, if the content resizes itself based on its children's geometry, the 
view either will be scrollable or will adjust its size to that of its content.

If the content rearranges its children to meet the size of the view, the view 
will not be scrollable and will not adjust its size to the content at all. Instead, 
the content will have the VCNA_SAME_WIDTH_AS_VIEW and 
VCNA_SAME_HEIGHT_AS_VIEW flags set in its *VCNI_attrs* field.

### 25.2.2 Messages Received from the View
	MSG_META_CONTENT_SET_VIEW, 
	MSG_META_CONTENT_VIEW_ORIGIN_CHANGED, 
	MSG_META_CONTENT_VIEW_SCALE_FACTOR_CHANGED, 
	MSG_META_CONTENT_VIEW_OPENING, 
	MSG_META_CONTENT_VIEW_WIN_OPENED, 
	MSG_META_CONTENT_VIEW_SIZE_CHANGED, 
	MSG_META_CONTENT_VIEW_CLOSING, 
	MSG_META_CONTENT_VIEW_WIN_CLOSED
As detailed in the discussions on GenView, the view sends a sequence of 
messages to its content when the view is first opening and when it is closing. 
These messages set up the content's visible instance data and prime the 
visible tree to be drawn on the screen. The messages are handled by the 
default handlers in **VisContentClass**, and you do not need to add anything 
to them to make them work.

The messages sent to the content when the view is first created are

1. MSG_META_CONTENT_SET_VIEW  
This message passes the view's optr to the content, setting the *VCNI_view* 
field properly.

2. MSG_META_CONTENT_VIEW_ORIGIN_CHANGED  
This message passes the view's initial origin (which may be set other 
than the default) to the content.

3. MSG_META_CONTENT_VIEW_SCALE_FACTOR_CHANGED  
This message passes the view's initial scale factor (which may be set 
other than the default) to the content.

4. MSG_META_CONTENT_VIEW_OPENING  
This message is sent to the content when the view receives a 
MSG_VIS_OPEN. This notifies the content that the view is about to be put 
on the screen and that it should prepare itself to be drawn.

5. MSG_META_CONTENT_VIEW_WIN_OPENED  
This message passes the window handle of the newly created view 
window so the content can record it in *VCNI_window*.

6. MSG_META_CONTENT_VIEW_SIZE_CHANGED  
This message passes the view window's size (height and width) to the 
content so the content can determine its proper size and geometry.

7. MSG_META_EXPOSED  
This message is sent when the view's window is finally on the screen. It 
signifies that the content should draw itself and then send 
MSG_VIS_DRAWs to all its children.

The view will also send certain messages to the content when different things 
happen to change the content's instance data:

+ MSG_META_CONTENT_VIEW_SIZE_CHANGED  
This message is passed whenever the view window's size changes for any 
reason.

+ MSG_META_CONTENT_VIEW_SCALE_FACTOR_CHANGED  
This message is passed whenever the view's scale factor is changed, 
usually due to the user setting it from a menu.

+ MSG_META_CONTENT_VIEW_ORIGIN_CHANGED  
This message is passed whenever the view's origin is changed, usually 
when the view is scrolled.

+ MSG_META_EXPOSED  
This message is passed to the content whenever a portion of the view 
window becomes exposed and must be drawn. The content automatically 
translates this into a MSG_VIS_DRAW.

When the view is shutting down, it will send the following three messages to 
the content to set the proper data:

1. MSG_META_CONTENT_VIEW_CLOSING  
This message is sent to the content when the view receives a 
MSG_VIS_CLOSE. It indicates that the view is being taken off the screen 
and that all the visible objects in the content's tree should remove 
themselves from the screen.

2. MSG_META_CONTENT_VIEW_WIN_CLOSED  
This message is sent when the view's window is finally destroyed. The 
copy of the window handle in *VCNI_window* will be thrown out now so no 
drawing to the stale window handle will be done.

3. MSG_META_CONTENT_SET_VIEW  
This message is sent to set the content's *VCNI_view* field to a null handle. 
When the view is finally taken off the screen, it no longer should have a 
content associated with it since it is meaningless to work with a visible 
tree that is not on the screen. If the view is opened again later, the 
content will receive another MSG_META_CONTENT_VIEW_OPENING and 
will once again be passed the view's optr.

----------
#### MSG_META_CONTENT_SET_VIEW
	void	MSG_META_CONTENT_SET_VIEW(
			optr	view);
This message passes the optr of the GenView object that will display this 
content object. The default handler will set the content's *VCNI_view* field to 
the passed optr. This message is also used when the view has been shut 
down; the passed optr will be null.

**Source:** Unrestricted - typically sent by a GenView to its content object.

**Destination:** Any VisContent or Process object acting as the content of a GenView.

**Parameters:**  
*view* - The optr of the GenView using this object as its 
content.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_META_CONTENT_VIEW_ORIGIN_CHANGED
	void	MSG_META_CONTENT_VIEW_ORIGIN_CHANGED(@stack
			WindowHandle	viewWindow,
			sdword			xOrigin,
			sdword			yOrigin);
This message notifies the content that the view's origin has changed. The 
content will set its *VCNI_docOrigin* field to the passed values.

**Source:** Unrestricted - typically sent by a GenView to its content object.

**Destination:** Any VisContent or Process object acting as the content of a GenView.

**Parameters:**  
*viewWindow* - The window handle of the GenView's window.

*xOrigin* - The new horizontal origin of the view.

*yOrigin* - The new vertical origin of the view.

**Return:** Nothing.

**Interception:** Any content that is managing large documents will probably need to 
subclass this message and apply the proper translations for the 32-bit 
coordinates.

----------
#### MSG_META_CONTENT_VIEW_SCALE_FACTOR_CHANGED
	void	MSG_META_CONTENT_VIEW_SCALE_FACTOR_CHANGED(@stack
			WindowHandle		viewWindow,
			WWFixedAsDWord		yScaleFactor,
			WWFixedAsDWord		xScaleFactor);

This message notifies the content that the view window's scale factor has 
changed. The content will set its *VCNI_scaleFactor* field to the passed values.

**Source:** Unrestricted - typically sent by a GenView to its content object.

**Destination:** Any VisContent or Process object acting as the content of a GenView.

**Parameters:**  
*viewWindow* - The window handle of the GenView's window.

*yScaleFactor* - The new vertical scale factor.

*xScaleFactor* - The new horizontal scale factor.

**Return:** Nothing.

**Interception:** Any content that is managing large documents will probably need to 
subclass this message and apply the proper translations for the 32-bit 
coordinates.

----------
#### MSG_META_CONTENT_VIEW_WIN_OPENED
	void	MSG_META_CONTENT_VIEW_WIN_OPENED(
			word			viewWidth,
			word			viewHeight,
			WindowHandle	viewWindow);

This message notifies the content that the view's window has been created 
and is being put on the screen. This message will be followed by 
MSG_META_EXPOSED, so the content should not draw anything here.

**Source:** Unrestricted - typically sent by a GenView to its content object.

**Destination:** Any VisContent or Process object acting as the content of a GenView.

**Parameters:**  
*viewWidth* - The new window's initial width.

*viewHeight* - The new window's initial height.

*viewWindow* - The window handle of the GenView's window.

**Return:** Nothing.

**Interception:** A content may wish to subclass this message if it needs to initialize 
data before the view's window is actually on the screen.

----------
#### MSG_META_CONTENT_VIEW_OPENING
	void	MSG_META_CONTENT_VIEW_OPENING(
			optr	view);

This message notifies the content that the view window is being put on the 
screen. Although the window will usually be fully realized by the time the 
content handles this message, the content should not draw anything in this 
handler. Because the view and content are often in different threads, a 
context switch could have occurred and the window might not be fully 
realized. This message will be followed by a MSG_META_EXPOSED indicating 
that the visible tree can be drawn and that the window is fully opened.

**Source:** Unrestricted - typically sent by a GenView to its content object.

**Destination:** Any VisContent or Process object acting as the content of a GenView.

**Parameters:**  
*view* - The optr of the GenView.

**Return:** Nothing.

**Interception:** A content may wish to subclass this message to initialize data before 
the view window is fully opened.

----------
#### MSG_META_CONTENT_VIEW_SIZE_CHANGED
	void	MSG_META_CONTENT_VIEW_SIZE_CHANGED(
			word			viewWidth,
			word			viewHeight,
			WindowHandle	viewWindow);
This message is sent to the content whenever the view's size changes for any 
reason. The passed height and width will be stored in the content's 
*VCNI_viewHeight* and *VCNI_viewWidth* fields.

**Source:** Unrestricted - typically sent by a GenView to its content object.

**Destination:** Any VisContent or Process object acting as the content of a GenView.

**Parameters:**  
*viewWidth* - The new width of the view window.

*viewHeight* - The new height of the view window.

*viewWindow* - The window handle of the GenView's window.

**Return:** Nothing.

**Interception:** Any content that is managing large documents may need to subclass 
this message to apply translations for 32-bit coordinates.

----------
#### MSG_META_CONTENT_VIEW_CLOSING
	void	MSG_META_CONTENT_VIEW_CLOSING();
This message indicates to the content that the view window is being shut 
down. The content should remove the visible tree from the screen and should 
prepare itself for the window to be closed.

**Source:** Unrestricted - typically sent by a GenView to its content object.

**Destination:** Any VisContent or Process object acting as the content of a GenView.

**Interception:** A content may subclass this message if it wants to do additional things 
when the view is taken off the screen.

----------
#### MSG_META_CONTENT_VIEW_WIN_CLOSED
	void	MSG_META_CONTENT_VIEW_WIN_CLOSED(
			WindowHandle viewWindow);
This message indicates that the view's window has been shut down, taken off 
the screen, and destroyed. The content responds to this message by 
discarding the window handle stored in its *VCNI_window* field. The content 
should already have removed itself from the screen when it received an 
earlier MSG_VIS_CLOSE.

**Source:** Unrestricted - typically sent by a GenView to its content object.

**Destination:** Any VisContent or Process object acting as the content of a GenView.

**Parameters:**  
*viewWindow* - The window handle of the GenView's window.

**Return:** Nothing.

**Interception:** A content may subclass this message to clean up after the view window 
is closed (e.g. if the content cached the view's window handle to a global 
variable, it will need to zero that handle now).

[VisComp](oviscmp.md) <-- [Table of Contents](../objects.md) &nbsp;&nbsp; --> [Generic System Classes](osysobj.md)
