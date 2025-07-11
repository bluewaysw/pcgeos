# 18 Graphic Object Library
The grobj (short for "Graphic Object," sometimes capitalized GrObj) library 
allows an application to include a graphic layer. This graphic layer provides 
an interactive graphics environment, allowing the user to create, move, and 
alter shape objects as in GeoDraw. This graphic layer might allow the user to 
add graphic elements to a document. The application could even use a 
modified graphic layer to represent the document, perhaps subclassing one 
of the "shape" object classes to provide application-specific features.

The Graphic Object library works well with the ruler library. If your geode 
includes both a graphics layer and one or more rulers, it is possible to alert 
the graphic layer to the presence of the ruler. The graphic layer will 
automatically work with rulers, relaying mouse events and even respecting 
ruler-imposed mouse constraints.

This chapter was written expecting that the reader would look over the 
DupGrObj sample application. This application shows a sparse graphical 
layer setup and includes the most basic necessary objects.

## 18.1 Setting Up the Objects
Several objects work together to manage a graphics layer. Each shape is 
represented by an object, and there are some objects which act together to 
manage these shapes. These manager objects are probably the only objects 
your geode will interact with directly.

The objects which manage the graphic layer are the GrObjBody, GrObjHead, 
and GrObjAttributeManager objects. Any application which uses one or more 
graphics layers must include a GrObjHead object. This object keeps track of 
data which is shared by all graphics layers in an application. The most 
important piece of information is the current tool. Users might be 
disconcerted if the drawing tool suddenly changed whenever the mouse 
moved between graphical documents, so the GrObjHead makes sure that 
only one tool is in use at a time.

Each "graphic layer" is actually a GrObjBody object. The GrObjBody 
manages the layer's "shape objects," managing their memory and storing 
them in a drawing-order list. The GrObjBody acts as a sort of communication 
nexus. When a controller wants to change a shape's line color, the message is 
actually sent to the GrObjBody, which in turn figures out which object should 
change and forwards the message accordingly. The GrObjBody can relay 
classed events to its associated GrObjHead, rulers, or attribute manager.

![image info](Figures/Fig18-1.png)  
**Figure 18-1** *Relations Between Objects*

If your application is including a graphic layer in each document, then there 
should probably be one GrObjBody for each document. The GrObjBody object 
must be stored in a VM file. **GrObjBodyClass** is a subclass of 
**VisCompClass**, and may be incorporated as the child of a GenDocument's 
visual component as with any other visual object. Of course, if the GrObj is 
part of a GenDocument, it may (and probably should) be stored in the VM file 
associated with the document.

Quite often, several shapes in a graphics layer will have the same properties. 
It would be a waste of space if every shape object were to store its own 
properties - all the shapes with standard thin black borders would be storing 
redundant information. The properties of a layer's objects are stored in a 
GrObjAttributeManager (often written "GOAM"), where they may be 
referenced by tokens. Instead of storing a structure full of property 
information, each shape keeps track of one or more tokens: a rectangle would 
have two tokens, one representing its area properties, and one representing 
its line properties. This mechanism also makes it possible to implement 
graphical "style sheets." Since the drawing properties for all shapes are 
stored in one place, it is possible to change the way that several shapes draw 
by changing data in one place.

Note that if a graphic layer will be saved, its associated attribute manager 
must be saved as well; without the drawing properties stored in the GOAM, 
half the information associated with a graphic layer would be lost. The GOAM 
must be stored in a VM file, the same VM file which contains all managed 
GrObjBodies.

An attribute manager can manage the attributes of more than one 
GrObjBody. If the GOAM will be saved, it will store the information 
associated with all managed graphic layers. 

Your application will probably never directly interact with the "shape 
objects" maintained by the GrObjBody. These are objects of the **GrObjClass**, 
often referred to as "GrObjs." 

GrObjs are also used to represent groups of fused objects, by means of the 
**GroupClass** subclass. Thus, a group may be manipulated as a single object, 
with moving and stretching handles like any shape object.

Spline, bitmap, and text GrObjs are implemented using visual objects in 
conjunction with some special graphic objects. Each object of this sort is 
actually made up of two objects, known as a guardian and a ward. The 
guardian object is a graphic object which has been subclassed to work with 
visual objects. Each guardian object keeps track of a ward visual object. The 
guardian object intercepts GrObj-related messages, translates them into the 
appropriate visual object messages and relays them to its ward.

The grobj library defines several controller classes which your application 
may use to allow the user to carry out certain standard graphic object 
operations including changing the drawing tool, changing area properties, 
and nudging graphic objects.

Applications using the grobj library are also encouraged to use the ruler 
library. The ruler library adds rulers, grids, and guidelines to a graphic layer. 
Note that the GrObjBody correctly directs classed events to an associated 
ruler, so there is no need to use the classed event redirection code normally 
used with VisRulers (as long as the GrObjBody is the target of the classed 
event). 

### 18.1.1 Initializing the Objects
Most of the graphic objects you will be including will be able to set up their 
own instance data. However, your application must send certain messages to 
hook up these objects to their UI. These messages must be sent as soon as the 
appropriate objects are created, whether they are declared or created 
dynamically.

The GrObjAttributeManager needs notification that it should initialize the 
data structures in which it will store the attributes. As soon as the 
GrObjBody is created, something should send a 
MSG_GOAM_CREATE_ALL_ARRAYS to the Attribute Manager, where that 
something is probably the same object responsible for creating the 
GrObjBody. In the DupGrObj sample application, this is done in the handler 
for MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE.

If the GrObjBody and GrObjHead are to communicate properly, when 
attaching the GrObjBody to the UI, you must send it a MSG_GB_ATTACH_UI, 
passing the optr of the GrObjHead. The GrObjBody and GrObjHead will then 
work together to set up the necessary communication links.

### 18.1.2 GrObj in a GenDocument
The GrObj library has several optimizations for those geodes which will be 
using graphic layers as documents, and most applications will probably use 
graphic objects in this context. The DupGrObj sample application is a good 
example of how to set up the main objects for a typical GenDocument setup. 
When setting up a GenDocument, you must consider which objects should 
appear in the document's UI, and which of those objects must have their state 
saved when the document is saved. Note that if you are going to include a 
graphics layer in a GenDocument, you should be familiar with the 
GenDocument class. The rest of this section won't make much sense to you 
otherwise.

The GrObjHead object probably shouldn't be controlled by the GenDocument 
in any way. This object should not be part of any generic or visual tree (not 
surprising, as it is neither a generic nor visual object). Its state does not need 
to be saved with the document; the current tool isn't really part of the 
document.

Similarly, the various GrObj controllers should not be saved with the 
document nor should they be in the document's UI. Normally, these UI 
components are children of the primary, because their influence goes beyond 
individual documents. Their state does not need to be saved with the 
document, since values are updated (and thus any saved state values wiped 
out) whenever a new shape object is selected.

The GrObjBody and the GrObjAttributeManager must be saved with the 
document, because they manage the graphic layer. The GrObjBody should be 
incorporated into the GenDocument's visual tree in the usual way.

If your environment includes VisRulers, you may wish to include these in the 
document's VM file. Remember that the rulers are in charge of storing grid 
and guideline information, and if their state is not saved, this information 
will be lost. However, the RulerView and RulerContent used to contain each 
VisRuler object contain no useful state information, and thus do not need to 
be saved.

DupGrObj also illustrates the proper time to send GrObj initialization 
messages under the GenDocument model. Notice the 
MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE handler sends a 
MSG_GOAM_CREATE_ALL_ARRAYS immediately after attaching the resource 
to a VM block. The MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT 
sends a MSG_GB_ATTACH_UI.

## 18.2 Managing a Graphic Layer
There is no single best way to manage a graphic layer. Different applications 
work with the GrObj library in different ways. Some applications may use 
documents that consist only of a graphic layer. For these applications, the 
main concerns will probably include customizing the behavior of the 
GrObjBody and one or more shape classes. Other applications may wish to 
use an unmodified graphic layer in conjunction with some other object which 
could represent the non-graphical component of the data. Applications 
following this approach will have varying concerns depending on the relation 
between the graphic layer and other objects.

Many applications follow a model by which the GrObjBody acts as a graphic 
layer above some other object, such as a text object or spreadsheet object. The 
grobj library is well suited to this task, but some problems arise to which the 
solutions will vary from application to application. Some of the more common 
issues are discussed below, along with possible solutions.

### 18.2.1 Selection
If you're maintaining a graphic layer above some other object, then you may 
want the user to be able to click in the document area and have the 
application automatically know where to send the event. Different 
applications will probably want to handle this in different ways. What 
happens when the user does a click drag that starts out in empty space? The 
GrObj would select everything inside the drag rectangle (or perhaps create a 
new shape object). But the layer underneath might want to do something 
(e.g. a VisText might want to select a range of text). Different applications 
would handle this message in different ways.

One typical approach is to add a new tool item to the graphic tool palette for 
working with data in the non-graphic layer. If the geode includes a 
GrObjToolControl, then set up a GrObjToolItem for this tool. There probably 
won't be a GrObj class associated with this tool item. However, if the user 
selects this tool, the GrObjHead is still alerted. If an object wants to know if 
it should grab the focus, it may query the GrObjHead to find out which tool 
is selected.

![image info](Figures/Fig18-2.png)  
**Figure 18-2** *Selection with an Extra Tool*

In the case where there is no GrObj class associated with an item in the 
GrObjToolControl, if the user selects this tool, then the GrObjHead will store 
a NULL for the present GrObj class. Each time the tool changes (every time 
the GrObjHead receives a MSG_GH_SET_CURRENT_TOOL), the application 
may check for a NULL tool class and set the target appropriately.

### 18.2.2 Creating GrObjs
The user can create shape objects by interacting with the graphics layer 
using the provided shape classes (e.g., rectangles, splines). The application 
doesn't need to do any runtime work; this functionality is built in to the 
GrObjBody. However, many applications will have cause to create objects 
without the user's help. The chart library does this, creating several objects 
and including them in the graphic layer.

1. Instantiate the graphic object with MSG_GB_INSTANTIATE_GROBJ.  
To create a new graphic object, send the graphic body a 
MSG_GB_INSTANTIATE_GROBJ. This creates the GrObj in a block 
managed by the body.

2. Initialize instance data with MSG_GO_INITIALIZE.  
You must set the object's initial size and position by sending it a 
MSG_GO_INITIALIZE. The object will respond to this message by setting 
its size and position accordingly. Also, the object will set up its attributes 
to the default values. At this time, guardian objects will create their 
visual wards.

3. Initialize other data as desired.  
If you want to change anything about the object before it appears, this 
would be the time to do it. Send messages to the graphic object to change 
its colors, locks, or any other attribute. If you wish to send messages to 
the visual object within a text, spline, or bitmap object, send a 
MSG_GOVG_GET_VIS_WARD to get the OD of the visual object, and then 
send messages to it.

4. Send the GrObj a MSG_GO_NOTIFY_GROBJ_VALID.  
Until the GrObj knows it's valid, it won't be drawn or detectable. When 
you've finished setting up the object's data, let it know it's ready with a 
MSG_GO_NOTIFY_GROBJ_VALID.

5. Add the GrObj to the GrObjBody with MSG_GB_ADD_GROBJ.  
The final step is to attach the GrObj to the body. After this message is 
sent, the object will be drawn and the user will be able to interact with it. 
To force a redraw after adding the object call 
MSG_GB_ADD_GROBJ_THEN_DRAW instead of MSG_GB_ADD_GROBJ.

### 18.2.3 Action Notification
Some applications might want to know when the user is modifying a shape 
object. You may specify an "action notification" for each graphic object, so that 
a specified object will receive a specified message whenever that object is 
modified. The message number and object's optr are stored in the GrObj's 
ATTR_GO_ACTION_NOTIFICATION vardata field. Note that the object must 
be stored in the GrObjBody's VM file or in a resource so that the vardata field 
may be relocated. The action notification may either be declared in a GrObj's 
ATTR_GO_ACTION_NOTIFICATION field, or may be set dynamically with 
MSG_GO_SET_ACTION_NOTIFICATION_OUTPUT.

Thus, if an application were using a graphics layer to model the inner 
workings of a complicated musical instrument, some shape objects might 
send notification messages to other objects which modeled the instrument's 
state, and might in turn interact with the sound library. Thus, the user could 
perhaps produce a sound by manipulating a polygon depicting a spit valve.

If for some reason an application always needed to know the combined 
surface area of all GrObjs in a graphic layer, then all GrObjs might have the 
process as their output descriptor, and the process could handle the action 
notification message by checking for resize actions and adjusting the area 
total accordingly.

Actually, the case in which all GrObjs will want to send action notification to 
a common output descriptor comes up often, and there is an optimization. It 
is possible to set a default action notification output in the GrObjBody. Any 
objects which don't have their own action notification structure will send 
notification based on the body's default notification structure. Of course, if 
neither GrObj nor GrObjBody has a notification structure set up, then no 
notification will go out. The GrObjBody's default action notification 
descriptor, if any, is stored in the ATTR_GB_ACTION_NOTIFICATION vardata 
field. It may be declared in this field, or may be set dynamically by means of 
MSG_GB_SET_ACTION_NOTIFICATION_OUTPUT. If the GrObjBody will have 
such an action notification object descriptor, it should have its *GBI_flags* 
GBF_HAS_ACTION_NOTIFICATION bit set.

It is possible to suspend an object's notification. By sending 
MSG_GO_SUSPEND_ACTION_NOTIFICATION 
(MSG_GB_SUSPEND_NOTIFICATION to suspend notification for all GrObjs 
managed by a graphic body), a geode may ask that the object not send the 
notification message until the corresponding 
MSG_GO_UNSUSPEND_ACTION_NOTIFICATION 
(MSG_GB_UNSUSPEND_ACTION_NOTIFICATION to affect all objects in a 
body) is sent. It is a good idea to suspend action notification when handling 
the notification message; otherwise, any modifications to the GrObj made in 
response to the notification message would generate another notification 
message, leading to an infinite loop. The default handlers for these messages 
account for the case when there is no action notification structure set up.

Notification suspensions may be nested (about 250 times), and the object 
maintains a count keeping track of how many suspends are in effect. This 
suspend count is zeroed when the file containing the GrObj is closed. The 
standard MSG_GO_SET_ACTION_NOTIFICATION_OUTPUT handler also 
zeroes the suspend count.

You need to declare the notification message and write a handler for it. The 
message may receive the modified GrObj's OD and a value specifying what 
sort of action has been performed. The action type is specified by a 
**GrObjActionNotificationType** value.

    @message void MSG_MY_NOTIFY (
        optr grobj,
        GrObjActionNotificationType action);

Though this notification message does not include a return value, because it 
passes the GrObj's OD, the notification message's handler may send 
messages back to the GrObj. If you do this, remember that these messages 
may themselves constitute "actions" which will generate notifications, and 
you may wish to suspend notification before sending them.

### 18.2.4 Locks and Forbidding Actions
To prevent the user from performing certain actions upon a graphic object, 
set the object's locks accordingly.

+ Move  
You may set a lock so that an object may not move. This might come in 
handy if you wish to include some sort of page header which the user 
should not be able to move directly.

+ Resize  
This lock keeps the user from resizing an object. The chart object uses 
this lock to keep users from changing charts without working through 
the chart's data.

+ Rotate  
This flag keeps the object from rotating. Some users are confused by 
rotated text objects, so an application trying to protect users from 
confusion might set this lock on text objects.

+ Skew  
Set this lock to prevent skewing. This is another lock often used with text 
objects.

+ Edit  
Set this flag to prevent the user from editing the innards of a shape object 
which is based on a visual object. This prevents changing a text object's 
text, a spline's points, and a bitmap's picture.

+ Delete  
This lock keeps the user from deleting an object. This lock is useful for 
adding page headers to drawings which the user should not be able to 
remove directly.

+ Select  
This lock prevents the user from selecting the object.

+ Attribute  
Set this lock to keep the user from changing the object's drawing 
attributes, such as color or pattern.

+ Group  
Set this lock to prevent the user from incorporating the object into a 
group. Applications which use their own grouping strategy to keep 
related objects together may wish to set this flag at appropriate times.

+ Ungroup  
Set this lock on a group object to prevent the user from breaking it up. 
Applications which model a complicated object by grouping two or more 
simpler objects might want to set this lock to prevent the user from 
separating the unit.

+ Draw  
Set this lock to make the object invisible. Applications which want to hide 
objects can set this flag at appropriate times.

+ Print  
Setting this lock renders the object invisible while printing. Applications 
which include objects meant as guides probably would set this lock for 
those objects.

### 18.2.5 Wrapping
Each graphic layer provides support for applications that will support the 
idea of "wrapping" data around graphics. However, the exact meaning of 
wrapping may change depending on other components in the application. 
Users have a pretty good idea of what is meant by wrapping text around 
graphic objects (see Figure 18-3). However, other sorts of applications will 
have other models of how their data should wrap around graphics, if any 
notion of wrapping applies at all.

![image info](Figures/Fig18-3.png)  
**Figure 18-3** *Wrapping Text*

For those applications that will support some form of wrapping, GrObj 
provides a way for the application to find out what to wrap around. Each 
GrObj has an attribute in its *GOI_attrFlags* field called GOAF_WRAP. If this 
bit is set, it means that the GrObj is "solid" and that data should wrap around 
it. If this bit is not set, then feel free to draw data over the object.

It is possible to draw a graphic layer in such a way that only those GrObjs 
with the GOAF_WRAP bit set will draw. To draw this way, a geode can send a 
MSG_GB_DRAW, passing the GODF_WRAP_ONLY bit set. Also, a graphic layer 
will restrict drawing to wrapping objects by default if its 
GODF_DRAW_WRAP_TEXT_AROUND_ONLY bit is set.

To determine the bounding path of the region to be wrapped around, draw the 
graphic layer (with a wrap only option) to a path:

    GrBeginPath (MyGState, PCT_REPLACE); 

    @call MyGrObjBody::MSG_GB_DRAW(MyGState,
         0, GODF_DRAW_WRAP_TEXT_AROUND_ONLY);

    /* if the GrObjBody's GBI_drawFlags includes
     * GODF_DRAW_WRAP_TEXT_AROUND_ONLY, we could use
     * either the above or:
     * @call MyGrObjBody::MSG_VIS_DRAW(0, MyGState); */
    GrEndPath (MyGState);

What the application does with this path is up to you.

### 18.2.6 Cut, Paste, and Transfer Items
Depending on the relation between graphics and other data in your 
application, you may end up creating an application-specific clipboard 
format. The GrObjBody can handle MSG_META_CLIPBOARD_CUT, 
MSG_META_CLIPBOARD_COPY, and MSG_META_CLIPBOARD_PASTE 
already. This is fine if the clipboard will never have to store graphical data 
and some other kind of data at the same time. For instance, if your 
spreadsheet application wants to link a chart created in a graphic layer to the 
spreadsheet data which is being charted, then you must create special cut 
and paste handlers to combine the spreadsheet and graphical information 
into a single item that may be copied and pasted.

Before attempting such a thing, you should be familiar with clipboard 
actions, described in "The Clipboard," Chapter 7 of the Concepts Book. By 
interacting with the GrObjBody, it is possible to get a VM block transfer item 
which may be chained together with other VM blocks (representing 
spreadsheet data or what have you) to form a larger transfer item. Your 
MSG_META_CLIPBOARD_CUT and MSG_META_CLIPBOARD_COPY handlers 
can send a MSG_GB_CREATE_TRANSFER to the GrObjBody, creating a 
transfer item incorporating the data of all selected GrObjs. This transfer 
item can then be combined with other data before being passed on to the 
clipboard.

The MSG_META_CLIPBOARD_PASTE handler can extract the GrObj transfer 
item from the combined data, then pass this data on to the target GrObjBody 
as the parameter of a MSG_GB_REPLACE_WITH_TRANSFER.

If you are creating a GrObj subclass, then by default the graphic object will 
include its instance data whenever it is cut or pasted. If objects of this class 
need to include information other than the instance data, then subclass the 
behavior of MSG_GO_CREATE_TRANSFER to construct the VM chain to hold 
all relevant data. Also, subclass MSG_GO_REPLACE_WITH_TRANSFER to 
correctly extract and apply the transfer item information.

## 18.3 GrObj Controllers
The grobj library provides a full suite of controllers which allow the user to 
access some of the graphic library functionality which cannot be accessed by 
merely clicking within the GrObjBody. Most applications which work with a 
graphic layer should include at least the GrObjToolControl, and most of the 
following controllers will be useful to all applications that work with the 
GrObj.

Most of these controllers will send their messages to the target. As long as 
the GrObjBody is at the target, it will then relay these messages on to those 
GrObjs which are selected.

### 18.3.1 GrObjToolControl
The GrObjToolControl allows the user to change tools. If you wish your 
graphic layer to disallow certain tools, then remove the appropriate features. 
To allow an extra tool, you may take advantage of a special piece of vardata 
set up for this control.

The GrObjToolControl is something of an anomaly among GrObj-related 
controllers. Instead of interacting with the targeted GrObjBody, probably it 
should instead send all messages to the GrObjHead.

----------
**Code Display 18-1 GrObjToolControl Features**

    /* GrObjToolControlClass is a subclass of GenControlClass.
     * Add your GrobjToolControl to GAGCNLT_SELF_LOAD_OPTIONS. */

    typedef WordFlags GOTCFeatures;
    /* These flags may be combined with | and &:
        GOTCF_PTR, 
        GOTCF_ROTATE_PTR,
        GOTCF_ZOOM,
        GOTCF_TEXT,
        GOTCF_LINE,
        GOTCF_POLYLINE,
        GOTCF_POLYCURVE,
        GOTCF_SPLINE,
        GOTCF_ARC,
        GOTCF_RECT,
        GOTCF_FOUNDED_RECT,
        GOTCF_ELLIPSE */

    #define GOTC_DEFAULT_FEATURES (GOTCF_PTR | GOTCF_TEXT | GOTCF_LINE | GOTCF_ARC | \
            GOTCF_POLYLINE | GOTCF_ROTATE_PTR | GOTCF_RECT | GOTCF_ZOOM | \
            GOTCF_ROUNDED_RECT | GOTCF_ELLIPSE | GOTCF_POLYCURVE |GOTCF_SPLINE)
    #define GOTC_DEFAULT_TOOLBOX_FEATURES (GOTC_DEFAULT_FEATURES)

    /* GrObjToolControlClass also includes a piece of vardata used to help 
        applications that will include one or more extra tools. */
    @vardata word ATTR_GROBJ_TOOL_CONTROL_POSITION_FOR_ADDED_TOOLS

    /*  The UI for this tool should be provided in an 
    ATTR_GEN_CONTROL_APP_TOOLBOX_UI vardata field.
    */

----------
### 18.3.2 GrObjStyleSheetControl
The GrObjStyleSheetControl allows the user to create graphical "style 
sheets." This is a direct subclass of the StyleSheetControl and has no 
additional features, messages, or instance data, although the classes are of 
course internally different. For full information about the StyleSheetControl, 
see "Generic UI Controllers," Chapter 12.

### 18.3.3 GrObjAreaColorSelector
This controller allows the user to set color and fill pattern information for the 
selected graphic objects.

----------
**Code Display 18-2 GrObjAreaColorSelector Features**

    /* GrObjAreaColorSelector is a subclass of ColorSelectorClass and has the same 
     * feature set: CSF_FILLED_LIST, CSF_INDEX, CSF_RGB, CSF_DRAW_MASK, CSF_PATTERN).
     */

    #define GOACS_DEFAULT_FEATURES (CSF_INDEX | CSF_RGB | CSF_DRAW_MASK )

----------
### 18.3.4 GrObjAreaAttrControl
The GrObjAreaAttrControl allows the user to work with those area 
attributes which are not handled by the ColorSelector. At this time, all of the 
features correspond to **MixMode** values which will be used to draw the area.

----------
**Code Display 18-3 GrObjAreaAttrControl Features**

    /* GrObjAreaAttrControlClass is a subclass of GenControlClass. 
     * Add your GrObjAreaAttrControl to GAGCNLT_SELF_LOAD_OPTIONS. */

    typedef WordFlags GOAACFeatures;
    /* The following flags may be combined using | and &:
        GOAACF_MM_CLEAR,
        GOAACF_MM_COPY,
        GOAACF_MM_NOP,
        GOAACF_MM_AND,
        GOAACF_MM_INVERT,
        GOAACF_MM_XOR,
        GOAACF_MM_SET,
        GOAACF_MM_OR,
        GOAACF_TRANSPARENCY */

    #define GOAAC_DEFAULT_FEATURES      (GOAACF_TRANSPARENCY | GOAACF_MM_COPY | \
            GOAACF_MM_INVERT | GOAACF_MM_XOR | GOAACF_MM_AND | GOAACF_MM_OR)

    #define GOAAC_DEFAULT_TOOLBOX_FEATURES                      0

----------
### 18.3.5 GrObjLineColorSelector
The GrObjLineColorSelector is a color selector which has been set up to work 
with GrObj line attributes. The user may specify a color and mask with which 
to draw lines.

----------
**Code Display 18-4 GrObjLineColorSelector Features**

    /* GrObjLineColorSelector is a subclass of ColorSelectorClass and has the same 
     * feature set: CSF_INDEX, CSF_RGB, CSF_DRAW_MASK. Note that since Lines
     * may not draw with a pattern, the CSF_PATTERN feature is not used. 
     * Add your GrObjLineColorSelector to GAGCNLT_SELF_LOAD_OPTIONS. */

    /* The GOLCS_DEFAULT_FEATURES contains the default feature set */

----------
### 18.3.6 GrObjLineAttrControl
The GrObjLineAttrControl allows the user to specify those attributes of the 
line not controlled by the GrObjLineColorSelector. This includes line width 
and style.

----------
**Code Display 18-5 GrObjLineAttrControl Features**

    /* GrObjLineAttrControlClass is a subclass of GenControlClass. 
     * Add your GrObjLineAttrControl to GAGCNLT_SELF_LOAD_OPTIONS. */

    typedef WordFlags GOLACFeatures;
    #define GOLACF_WIDTH_INDEX 0x0010
    #define GOLACF_WIDTH_VALUE 0x0008
    #define GOLACF_STYLE 0x0004
    #define GOLACF_ARROWHEAD_TYPE 0x0002
    #define GOLACF_ARROWHEAD_WHICH_END 0x0001 

    typedef WordFlags GOLACToolboxFeatures;
    #define GOLACTF_WIDTH_INDEX 0x0002
    #define GOLACTF_STYLE 0x0001 

    #define GOLAC_DEFAULT_FEATURES (GOLACF_WIDTH_INDEX | GOLACF_WIDTH_VALUE | \
                GOLACF_STYLE | GOLACF_ARROWHEAD_TYPE | GOLACF_ARROWHEAD_WHICH_END) 

    #define GOLAC_DEFAULT_TOOLBOX_FEATURES  (GOLACTF_WIDTH_INDEX | GOLACF_STYLE)

----------
### 18.3.7 GrObjNudgeControl
The GrObjNudgeControl allows the user to "nudge" selected objects by small 
amounts.

----------
**Code Display 18-6 GrObjNudgeControl Features**

    /* GrObjNudgeControlClass is a subclass of GenControlClass.
     * Add your GrObjNudgeControl to GAGCNLT_SELF_LOAD_OPTIONS. */

    typedef ByteFlags GrObjNudgeControlFeatures;
    #define GONCF_NUDGE_LEFT                (0x10)
    #define GONCF_NUDGE_RIGHT               (0x08)
    #define GONCF_NUDGE_UP              (0x04)
    #define GONCF_NUDGE_DOWN                (0x02)
    #define GONCF_CUSTOM_MOVE               (0x01)

    #define GONC_DEFAULT_FEATURES                   (GONCF_NUDGE_LEFT | GONCF_NUDGE_RIGHT | \
                        GONCF_NUDGE_UP | GONCF_NUDGE_DOWN | GONCF_CUSTOM_MOVE)

----------
### 18.3.8 GrObjDepthControl
The GrObjDepthControl affects the selected objects' places in the drawing 
order, so that they will appear higher or lower when they overlap with other 
objects. Note that since the GrObjBody stores its GrObjs in drawing order, 
this affects the selected GrObj's place in the drawing order, but other than 
that does not affect the GrObj itself.

----------
**Code Display 18-7 GrObjDepthControl Features**

    /* GrObjDepthControlClass is a subclass of GenControlClass.
     * Add your GrObjDepthControl to GAGCNLT_SELF_LOAD_OPTIONS. */

    typedef ByteFlags GODepthCFeatures;
    /* The following flags may be combined with | and &:
        GODepthCF_BRING_TO_FRONT,
        GODepthCF_SEND_TO_BACK,
        GODepthCF_SHUFFLE_UP,
        GODepthCF_SHUFFLE_DOWN */

    #define GODepthC_DEFAULT_FEATURES \ 
                (GODepthCF_BRING_TO_FRONT | GODepthCF_SEND_TO_BACK |\
                 GODepthCF_SHUFFLE_UP | GODepthCF_SHUFFLE_DOWN )
    #define GODepthC_DEFAULT_TOOLBOX_FEATURES (\
                (GODepthCF_BRING_TO_FRONT | GODepthCF_SEND_TO_BACK |\
                 GODepthCF_SHUFFLE_UP | GODepthCF_SHUFFLE_DOWN )

----------
### 18.3.9 GrObjArcControl
The GrObjArcControl allows the user to specify exact angles and 
characteristics of arc objects.

----------
**Code Display 18-8 GrObjArcControlClass**

    /* GrObjArcControlClass is a subclass of GenControlClass.
     * Add your GrObjDepthControl to GAGCNLT_SELF_LOAD_OPTIONS. */

    typedef ByteFlags GOArcCFeatures;
    /* The following flags may be combined using | and &:
        GOACF_START_ANGLE,
        GOACF_END_ANGLE,
        GOACF_PIE_TYPE,
        GOACF_CHORD_TYPE */

    #define GOArcC_DEFAULT_FEATURES (GOACF_START_ANGLE | GOACF_END_ANGLE | \
                 GOACF_PIE_TYPE | GOACF_CHORD_TYPE)

    #define GOArcC_DEFAULT_TOOLBOX_FEATURES 0

----------
### 18.3.10 GrObjHandleControl
The GrObjHandleControl allows the user to make the shape's movement and 
stretching handles smaller, larger, or invisible.

----------
**Code Display 18-9 GrObjHandleControl Features**

    /* GrObjHandleControlClass is a subclass of GenControlClass.
     * Add your GrObjHandleControl to GAGCNLT_SELF_LOAD_OPTIONS. */

    typedef ByteFlags GOHCFeatures;
    /* The following flags may be combined with | and &:
        GOHCF_SMALL_HANDLES,
        GOHCF_MEDIUM_HANDLES,
        GOHCF_LARGE_HANDLES,
        GOHCF_INVISIBLE_HANDLES */

    #define GOHC_DEFAULT_FEATURES (GOHCF_SMALL_HANDLES | GOHCF_MEDIUM_HANDLES |\
                GOHCF_LARGE_HANDLES | GOHCF_INVISIBLE_HANDLES)
    #define GOHC_DEFAULTD_TOOLBOX_FEATURES                  0

----------
### 18.3.11 GrObjRotateControl
The GrObjRotateControl applies a rotation to the selected GrObj. This 
normally affect's the object's coordinate transformation.

----------
**Code Display 18-10 GrObjRotateControl Features**

    /* GrObjRotateControlClass is a subclass of GenControlClass.
     * Add your GrObjRotateControl to GAGCNLT_SELF_LOAD_OPTIONS. */
    typedef ByteFlags GORCFeatures;
    #define GORCF_45_DEGREES_CW 0x0080
    #define GORCF_90_DEGREES_CW 0x0040
    #define GORCF_135_DEGREES_CW 0x0020
    #define GORCF_180_DEGREES 0x0010
    #define GORCF_135_DEGREES_CCW 0x0008
    #define GORCF_90_DEGREES_CCW 0x0004
    #define GORCF_45_DEGREES_CCW 0x0002
    #define GORCF_CUSTOM_ROTATION 0x0001 

    #define GORC_DEFAULT_FEATURES 0x00ff

----------
### 18.3.12 GrObjFlipControl
The GrObjFlipControl allows the user to flip a graphic object about either 
axis.

----------
**Code Display 18-11 GrObjFlipControl Features**

    /* GrObjFlipControlClass is a subclass of GenControlClass.
     * Add your GrObjFlipControl to GAGCNLT_SELF_LOAD_OPTIONS. */

    typedef ByteFlags GOFCFeatures;
    /* The following flags may be combined with | and &:
        GOFCF_FLIP_HORIZONTALLY,
        GOFCF_FLIP_VERTICALLY */

----------
### 18.3.13 GrObjSkewControl
The GrObjSkewControl provides the user with a standard way to warp 
graphic objects. This normally affect's the object's coordinate transformation.

----------
**Code Display 18-12 GrObjSkewControl Features**

    /* GrObjFlipControlClass is a subclass of GenControlClass.
     * Add your GrObjFlipControl to GAGCNLT_SELF_LOAD_OPTIONS. */

    typedef ByteFlags GOSCFeatures;
    #define GOSCF_LEFT 0x0010
    #define GOSCF_RIGHT 0x0008
    #define GOSCF_UP 0x0004
    #define GOSCF_DOWN 0x0002
    #define GOSCF_CUSTOM_SKEW 0x0001 

    #define GROBJ_SKEW_CONTROL_DEFAULT_FEATURES 0x001f 

----------
### 18.3.14 GrObjAlignToGridControl
The GrObjAlignToGridControl works with a VisRuler's grid mechanism, 
allowing the user to align selected objects with grid lines. Note that standard 
ruler controls will allow the user to constrain all mouse movement to grid 
lines.

----------
**Code Display 18-13 GrObjAlignToGridControl Features**

    /* GrObjAlignToGridControlClass is a subclass of GenControlClass.
     * Add your GrObjAlignToGridControl to GAGCNLT_SELF_LOAD_OPTIONS. */

    typedef ByteFlags GOATGCFeatures;
    /* There is only one GrObjAlignToGridControl feature:
            GOATGCF_ALIGN_TO_GRID */

    #define GOATGC_DEFAULT_FEATURES (GOATGCF_ALIGN_TO_GRID)
    #define GOATGC_DEFAULT_TOOLBOX_FEATURES 0

----------
### 18.3.15 GrObjGroupControl
The GrObjGroupControl allows the user to clump GrObjs together into 
groups. These GrObjs may then be moved, resized, and skewed in common.

----------
**Code Display 18-14 GrObjGroupControl**

    /* GrObjGroupControlClass is a subclass of GenControlClass.
     * Add your GrObjGroupControl to GAGCNLT_SELF_LOAD_OPTIONS. */

    typedef ByteFlags GOGCFeatures;
    /* These flags may be combined using | and &:
        GOGCF_GROUP,
        GOGCF_UNGROUP */

    #define GOGC_DEFAULT_FEATURES   (GOGCF_GROUP | GOGCF_UNGROUP)
    #define GOGC_DEFAULT_TOOLBOX_FEATURES   (GOGCF_GROUP | GOGCF_UNGROUP)

----------
### 18.3.16 GrObjAlignDistributeControl
The GrObjAlignDistributeControl allows the user to align several objects so 
that their edges line up, or to distribute them evenly within a given space.

----------
**Code Display 18-15 GrObjAlignDistrbuteControl Features**

    typedef WordFlags GrObjAlignDistributeControlFeatures;
    #define GOADCF_ALIGN_LEFT 0x8000
    #define GOADCF_ALIGN_CENTER_HORIZONTALLY 0x4000
    #define GOADCF_ALIGN_RIGHT 0x2000
    #define GOADCF_ALIGN_WIDTH 0x1000
 
    #define GOADCF_ALIGN_TOP 0x800
    #define GOADCF_ALIGN_CENTER_VERTICALLY 0x400
    #define GOADCF_ALIGN_BOTTOM 0x200
    #define GOADCF_ALIGN_HEIGHT 0x100
 
    #define GOADCF_DISTRIBUTE_LEFT 0x80
    #define GOADCF_DISTRIBUTE_CENTER_HORIZONTALLY 0x40
    #define GOADCF_DISTRIBUTE_RIGHT 0x20
    #define GOADCF_DISTRIBUTE_WIDTH 0x10
    #define GOADCF_DISTRIBUTE_TOP 0x8
    #define GOADCF_DISTRIBUTE_CENTER_VERTICALLY 0x4
    #define GOADCF_DISTRIBUTE_BOTTOM 0x2
    #define GOADCF_DISTRIBUTE_HEIGHT 0x1 

----------
### 18.3.17 GrObjLocksControl
The GrObjLocksControl allows the user to prohibit certain actions upon a 
graphic object.

----------
**Code Display 18-16 GrObjLocksControl Features**

    /* GrObjLocksControlClass is a subclass of GenControlClass.
     * Add your GrObjLocksControl to GAGCNLT_SELF_LOAD_OPTIONS. */
    /* GrObjLocksControl doesn't have a Features Type; just use the GrObjLocks type. */

----------
### 18.3.18 GrObjConvertControl
The GrObjConvertControl converts an arbitrary collection of graphic objects 
into a bitmap or GString object.

----------

**Code Display 18-17 GrObjConvertControl Features**

    /* GrObjConvertControlClass is a subclass of GenControlClass.
     * Add your GrObjConvertControl to GAGCNLT_SELF_LOAD_OPTIONS. */

    typedef ByteFlags   GOCCFeatures;
    /* The following flags may be combined using | and &:
        GOCCF_CONVERT_TO_BITMAP,
        GOCCF_CONVERT_TO_GRAPHIC,
        GOCCF_CONVERT_FROM_GRAPHIC */

    #define GOCC_TOOLBOX_FEATURES   (GOCCF_CONVERT_TO_BITMAP | GOCCF_CONVERT_TO_GRAPHIC \
                | GOCCF_CONVERT_FROM_GRAPHIC)
    #define GOCC_TOOLBOX_TOOLBOX_FEATURES   (GOCCF_CONVERT_TO_BITMAP | \
                GOCCF_CONVERT_TO_GRAPHIC | GOCCF_CONVERT_FROM_GRAPHIC)

----------
### 18.3.19 GrObjDefaultAttributesControl
This controller allows the setting of default attributes. It has one feature in 
its GODACFeatures structure: GODACF_SET_DEFAULT_ATTRIBUTES.

### 18.3.20 GrObjObscureAttrControl
This controller allows the user to specify a number of attributes for each 
graphic object. The user may change the text wrap flags to determine how 
text (or other information) should wrap around graphical objects in those 
applications which support wrapping around graphics. The user can mark an 
object as an instruction object.

The user may also determine how an object should react depending on the 
background document, if any. For instance, in spreadsheets, this controller 
would determine how an object should react if the column it were in were 
deleted.

----------
**Code Display 18-18 GrObjObscureAttrControl Features**

    typedef ByteFlags GrObjObscureAttrControlFeatures;
    #define GOOACF_INSTRUCTIONS 0x80
    #define GOOACF_INSERT_OR_DELETE_MOVE 0x40
    #define GOOACF_INSERT_OR_DELETE_RESIZE 0x20
    #define GOOACF_INSERT_OR_DELETE_DELETE 0x10
    #define GOOACF_DONT_WRAP 0x08
    #define GOOACF_WRAP_INSIDE 0x04
    #define GOOACF_WRAP_AROUND_RECT 0x02
    #define GOOACF_WRAP_TIGHTLY 0x01

    #define GOOAC_INSERT_OR_DELETE_FEATURES (GOOACF_INSERT_OR_DELETE_MOVE | \
                GOOACF_INSERT_OR_DELETE_RESIZE | GOOACF_INSERT_OR_DELETE_DELETE) 

    #define GOOAC_WRAP_FEATURES (GOOACF_DONT_WRAP | GOOACF_WRAP_INSIDE | \
                GOOACF_WRAP_AROUND_RECT | GOOACF_WRAP_TIGHTLY) 

    #define GOOAC_DEFAULT_FEATURES (GOOACF_INSTRUCTIONS | GOOAC_WRAP_FEATURES | \
                 GOOAC_INSERT_OR_DELETE_FEATURES) 

----------
### 18.3.21 GrObjInstructionControl
This controller allows the user to work with instruction objects. These are 
objects which have been marked as part of the instructions associated with a 
document (perhaps so marked using this very controller). These instruction 
objects might tell the user how to use a template file. This controller allows 
the user to delete or hide instruction objects. Note that the 
GrObjObscureAttrControl allows the user to mark an object as an 
instruction object.

----------
**Code Display 18-19 GrObjInstructionControl Features**

    typedef ByteFlags GrObjInstructionControlFeatures;
    #define GOICF_DRAW 0x8000
    #define GOICF_PRINT 0x4000
    #define GOICF_MAKE_EDITABLE 0x2000
    #define GOICF_MAKE_UNEDITABLE 0x1000
    #define GOICF_DELETE 0x0800

    #define GOICF_DEFAULT_FEATURES (GOICF_DRAW | GOICF_PRINT | GOICF_MAKE_EDITABLE | \
                    GOICF_MAKE_UNEDITABLE | GOICF_DELETE) 

----------
### 18.3.22 GrObjGradientFillControl
This controller allows the user to choose the specifics of a gradient fill, 
including starting and ending colors, direction of fill, and more.

### 18.3.23 GrObjBackgroundColorSelector
This controller allows the user to specify the background color of a graphic 
object, useful when the object is partially see-through.

### 18.3.24 Gradient Color Selectors
The **GrObjStartingGradientColorSelector** and 
**GrObjEndingGradientColorSelector** controllers allow the user to specify 
both ends of a gradient-filled object's color range.

### 18.3.25 Paste Inside Controls
A **GrObjPasteInsideControl** allows the user to paste one object inside of 
another, allowing for complicated clipping effects. The 
**GrObjMoveInsideControl** controller allows the "nudging" of an object 
which has been pasted inside of another object.

----------
**Code Display 18-20 GrObjPasteInsideControl Features**

    typedef ByteFlags GOPICFeatures;
    #define GOPICF_PASTE_INSIDE 0x0002
    #define GOPICF_BREAKOUT_PASTE_INSIDE 0x0001 

    typedef ByteFlags GOPICToolboxFeatures;
    #define GOPICTF_PASTE_INSIDE 0x0002
    #define GOPICTF_BREAKOUT_PASTE_INSIDE 0x0001 

    #define GOPIC_DEFAULT_FEATURES (GOPICF_PASTE_INSIDE | GOPICF_BREAKOUT_PASTE_INSIDE)

    #define GOPIC_DEFAULT_TOOLBOX_FEATURES (GOPICTF_PASTE_INSIDE | \
                        GOPICTF_BREAKOUT_PASTE_INSIDE) 

----------
### 18.3.26 Controls From Other Libraries
Because the grobj incorporates the powers of many other libraries, 
applications working with the grobj may have cause to include controllers 
from some of these other libraries.

The text library includes several controllers, which can work with GrObj text 
objects as they would with VisText objects.

If your geode includes one or more VisRulers, including some ruler controls 
will allow the user to customize some ruler behavior. These ruler controllers 
are discussed in some detail in the "Ruler Object Library," Chapter 19.

The bitmap library provides controls useful for manipulating bitmaps under 
the GrObj. Though the bitmap library is internal to Geoworks, the GrObj 
library provides the VisBitmapToolControl which will allow the user to 
manipulate bitmaps via GrObj.

## 18.4 GrObj Body
The GrObjBody represents a layer of graphics. Most of your application's 
interaction with the world of GrObj will probably be through the body.

### 18.4.1 GrObjBody Instance Data
The GrObjBody largely concerns itself with managing other objects. Much of 
its instance data is taken up with handles of the various objects that it 
interacts with.

----------
**Code Display 18-21 GrObjBody Instance Data**

    @instance RectDWord     GBI_bounds = {0,0,0,0}; 
    @instance CompPart      GBI_drawComp = {NullOptr};      /* Internal */
    @instance CompPart      GBI_reverseComp = {NullOptr};   /* Internal */
    @instance word          GBI_childCount;                 /* Internal */
    @instance optr          GBI_selectionArray;             /* Internal */
    @instance HierarchicalGrab  GBI_targetExcl = {NullOptr, 0}; /* Internal */
    @instance HierarchicalGrab  GBI_focusExcl = {NullOptr, 0};  /* Internal */
    @instance BasicGrab     GBI_curEdit = {NullOptr, 0};    /* Internal */
    @instance optr          GBI_mouseGrab;                  /* Internal */
    @instance word          GBI_objBlockArray;              /* Internal;*/
    @instance GrObjFunctionsActive  GBI_defaultOptions;
    @instance GrObjFunctionsActive  GBI_currentModifiers;
    @instance GrObjFunctionsActive  GBI_currentOptions;
    @instance GrObjBodyFlags        GBI_flags   = (GBF_DEFAULT_TARGET | GBF_DEFUALT_FOCUS);
    @instance GrObjDrawFlags        GBI_drawFlags;
    @instance GrObjFileStatus GBI_fileStatus;               /* Internal */
    @instance GStateHandle  GBI_graphicsState = 0;          /* Internal */
    @instance optr          GBI_head;
    @instance optr          GBI_goam;
    @instance optr          GBI_ruler;
    @instance word          GBI_priorityList =  0;          /* Internal */
    @instance byte          GBI_desiredHandleSize = DEFAULT_DESIRED_HANDLE_SIZE;
    @instance byte          GBI_curHandleWidth = 0;         /* Internal */
    @instance byte          GBI_curHandleHeight = 0;        /* Internal */
    @instance BBFixed       GBI_curNudgeX;                  /* Internal */
    @instance BBFixed       GBI_curNudgeY;                  /* Internal */
    @instance PointWWFixed  GBI_curScaleFactor = {MakeWWFixed(1), MakeWWFixed(0)};
    @instance PointDWFixed  GBI_interestingPoint = {{0, -30000}, {0, -30000}};
    @instance PointDWFixed  GBI_lastPtr = {0,0}; 
    @instance word          GBI_suspendCount = 0;           /* Internal */
    @instance GrObjBodyUnsuspendOps GBI_unsuspendOps;       /* Internal */
    instance VisTextNotificationFlags GBI_textUnsuspendOps = 0; /* Internal */
    @instance word GBI_reserved1 = 0;                       /* Reserved for future use */
    @instance word GBI_reserved2 = 0;                       /* Reserved for future use */ 
    
    @vardata    GrObjActionNotification     ATTR_GB_ACTION_NOTIFICATION;
    
    @vardata GrObjBodyPasteCallBackStruct ATTR_GB_PASTE_CALL_BACK;
    typedef struct {
        word GOBPCBS_message;
        optr GOBPCBS_optr;
    } GrObjBodyPasteCallBackStruct; 

----------
The *GBI_bounds* field acts as the bounds of the drawing area. Geodes using 
graphic bodies as part of documents may wish to make the body's bounds 
match the document bounds. Use MSG_GB_SET_BOUNDS to reset these 
bounds.

When working with a graphic layer, the user will no doubt have certain 
preferences about how input should be interpreted. These preferences 
include the option to "stretch" objects from the center, snapping to the grid, 
and drawing bitmaps as plain rectangles. One set of options may be set as the 
default, stored in *GBI_defaultOptions*. As input events come in, the body may 
turn on other options, which are stored in *GBI_currentModifiers*. The 
*GBI_currentOptions* field contains the computed combination of these 
options.

    typedef WordFlags   GrObjFunctionsActive;
    /* These flags may be combined with | and &:
        GOFA_HAS_SEEN_EVENT,
        GOFA_VIEW_ZOOMED,
        GOFA_SNAP_TO,
        GOFA_FROM_CENTER,
        GOFA_ABOUT_OPPOSITE,
        GOFA_CONSTRAIN,
        GOFA_ADJUST,
        GOFA_EXTEND */

The *GBI_flags* field determines some of the GrObjBody's miscellaneous 
behavior. 

    typedef WordFlags GrObjBodyFlags;
    /* These flags may be combined with | and &:
        GBF_HAS_ACTION_NOTIFICATION,
        GBF_DEFAULT_TARGET,
        GBF_DEFAULT_FOCUS */

The *GBI_goam* field is the handle of the GrObjBody's attribute manager. The 
*GBI_head* field is the handle of the GrObjHead. The *GBI_ruler* field may hold 
a handle to a VisRuler. If used, this ruler will be able to coordinate with the 
GrObjBody to provide mouse tracking.

### 18.4.2 GrObjBody Messages
Since the body is in charge of managing the "shape" objects, several of these 
messages deal with adding and removing shapes from the selection and 
shuffling objects up and down in the drawing order. 

----------
#### MSG_GB_ATTACH_UI
    void    MSG_GB_ATTACH_UI (
            optr    GrObjHead);

This message lets the GrObjBody know where its head is. The head's OD will 
be set in the instance data. This message must be sent to the GrObjBody 
after it has been added to a document.

**Source:** Unrestricted, normally a GenDocument handling 
MSG_GEN_DOCUMENT_ATTACH_UI.

**Destination:** GrObjBody.

***Parameters:**  
head* - The optr of the GrObjHead to use.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GB_DETACH_UI
    void    MSG_GB_DETACH_UI ();

This message must be sent to the GrObjBody before it has been removed from 
a document, and should be in the document's 
MSG_GEN_DOCUMENT_ATTACH_UI.

**Source:** Unrestricted, normally a GenDocument handling 
MSG_GEN_DOCUMENT_DETACH_UI.

**Destination:** GrObjBody.

**Parameters:** None.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GB_ATTACH_GOAM
    void    MSG_GB_ATTACH_GOAM (
            optr    GrObjAttrManager);

This message lets the GrObjBody know where its attribute manager is. The 
manager's optr will be set in the instance data.

**Source:** Unrestricted. Generally the GenDocument on handling 
MSG_GEN_DOCMENT_INITIALIZE_DOCUMENT_FILE.

**Destination:** GrObjBody.

**Parameters:**  
*goam* - The optr of the new GrObjAttributeManager.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GB_ATTACH_RULER
This message sets the *GBI_ruler* field. Note that if the GrObjBody is to 
interact with more than one VisRuler, they should be linked in a 
*VRI_slaveRuler* chain, and the ruler in the *GBI_ruler* field should be at the top 
of this chain.

**Source:** Unrestricted. Generally the GenDocument on handling 
MSG_GEN_DOCMENT_INITIALIZE_DOCUMENT_FILE.

**Destination:** GrObjBody.

**Parameters:**  
*ruler* - The optr of the new VisRuler to use.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GB_ADD_GROBJ
    void    MSG_GB_ADD_GROBJ (
            optr    object,
            word    flags);

This message adds a graphic object to the GrObjBody. The object will be 
notified by a MSG_GO_AFTER_ADDED_TO_BODY that it has been added to 
the body. The object won't necessarily be drawn; to force a redraw, send 
MSG_GB_ADD_GROBJ_THEN_DRAW instead.

**Source:** Unrestricted. Generally the GenDocument on handling 
MSG_GEN_DOCMENT_INITIALIZE_DOCUMENT_FILE.

**Destination:** GrObjBody.

**Parameters:**  
*object* - The optr of the new GrObj.

*flags* - **GrObjBodyAddGrObjFlags** value specifying 
where in the list of objects to add the new GrObj.

**Return:** Nothing.

**Structures:** The flags field is a word with the following structure:

    typedef WordFlags GrObjBodyAddGrObjFlags;
        /* GOBAGOF_DRAW_LIST_POSITION: if this bit
            is set, then other bits describe 
            position in drawing-order list. If
            this bit is clear, then other bits
            describe position in reverse list */
        #define GOBAGOF_DRAW_LIST_POSITION 0x8000
        #define GOBAGOF_REFERENCE 0x7fff
        #define GOBAGOR_FIRST CCO_FIRST
        #define GOBAGOR_LAST CCO_LAST
    /* To add a new object so it draws "on top", use
        (GOBAGOF_DRAW_LIST_POSITION | GOBAGOR_LAST) */

**Interception:** Unlikely.

----------
#### MSG_GB_ADD_GROBJ_THEN_DRAW
    void    MSG_GB_ADD_GROBJ_THEN_DRAW(
            optr    object,
            word    flags);

This message adds a graphic object to the GrObjBody. The object will be 
notified by a MSG_GO_AFTER_ADDED_TO_BODY that it has been added to 
the body. If the object is added at the top of the draw list, it will be sent a draw 
message. Otherwise, it will be invalidated.

**Source:** Unrestricted. Generally the GenDocument on handling 
MSG_GEN_DOCMENT_INITIALIZE_DOCUMENT_FILE.

**Destination:** GrObjBody.

**Parameters:**  
*object* - The optr of the new GrObj.

*flags* - Object, specific flags, if any.

**Return:** Nothing.

**Structures:** The flags field is a word with the following structure:

    typedef WordFlags GrObjBodyAddGrObjFlags;
        /* GOBAGOF_DRAW_LIST_POSITION: if this bit
            is set, then other bits describe 
            position in drawing-order list. If
            this bit is clear, then other bits
            describe position in reverse list */
        #define GOBAGOF_DRAW_LIST_POSITION 0x8000
        #define GOBAGOF_REFERENCE 0x7fff
        #define GOBAGOR_FIRST CCO_FIRST
        #define GOBAGOR_LAST CCO_LAST
    /* To add a new object so it draws "on top", use
        (GOBAGOF_DRAW_LIST_POSITION | GOBAGOR_LAST) */

**Interception:** Unlikely.

----------
#### MSG_GB_SET_BOUNDS
    void    MSG_GB_SET_BOUNDS(
            RectDWord   bounds);

This message sets the bounds of the GrObjBody.

**Source:** Unrestricted.

**Destination:** GrObjBody.

**Parameters:**  
*bounds* - The new bounds.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GB_INSTANTIATE_GROBJ
    optr    MSG_GB_INSTANTIATE_GROBJ(
            ClassStruct     *class);

This message instantiates a GrObj of the passed class in a block managed by 
the body.

**Source:** Unrestricted.

**Destination:** GrObjBody.

**Parameters:**  
*bounds* - The new bounds.

**Return:** Object pointer of the newly created GrObj.

**Interception:** Unlikely.

----------
#### MSG_GB_SET_ACTION_NOTIFICATION_OUTPUT

This message specifies the default message and OD for GrObjs to send 
notification to when an action is performed on them. GrObjs will use this 
default if they don't have their own action notification.

**Source:** Unrestricted.

**Destination:** GrObjBody.

**Interception:** Unlikely.

----------
#### MSG_GB_SUSPEND_ACTION_NOTIFICATION

    void    MSG_GB_SUSPEND_ACTION_NOTIFICATION();

This message suspends action notification for all of a body's GrObjs. This 
prevents all the GrObjs from sending out any action notification.

**Source:** Unrestricted.

**Destination:** GrObjBody.

**Parameters:** None.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GB_UNSUSPEND_ACTION_NOTIFICATION
    void    MSG_GB_UNSUSPEND_ACTION_NOTIFICATION();

This message counteracts MSG_GB_SUSPEND_ACTION_NOTIFICATION. If all 
suspends have been balanced, the body's GrObjs will be free to send out 
action notification. However, action notifications that were aborted during 
the suspend period will not be sent out.

**Source:** Unrestricted.

**Destination:** GrObjBody.

**Parameters:** None.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GB_DRAW
    void    MSG_GB_DRAW(
            GStateHandle        gstate,
            DrawFlags           visDrawFlags,
            GrObjDrawFlags      GODrawFlags);

This message draws the graphic layer, allowing the caller some options. Since 
the GrObjBody is a subclass of VisComp, of course it is normally drawn by 
MSG_VIS_DRAW. MSG_GB_DRAW is normally used directly when drawing the 
layer to something not normally its output.

**Source:** Unrestricted.

**Destination:** GrObjBody.

Parameters:  
*gstate* - The graphics state to draw to.

*visDrawFlags* - Flags as would be set for MSG_VIS_DRAW.

*GODrawFlags* - Special flags which can affect how to draw GrObjs.

**Return:** Nothing.

Structures:  

    typedef ByteFlags   GrObjDrawFlags;
    #define GODF_DRAW_QUICK_VIEW                0x100
    #define GODF_DRAW_CLIP_ONLY                  0x80
    #define GODF_DRAW_WRAP_TEXT_INSIDE_ONLY      0x40
    #define GODF_DRAW_WRAP_TEXT_AROUND_ONLY      0x20
    #define GODF_DRAW_WITH_INCREASED_RESOLUTION  0x10
    #define GODF_DRAW_INSTRUCTIONS               0x08
    #define GODF_DRAW_SELECTED_OBJECTS_ONLY      0x04
    #define GODF_DRAW_OBJECTS_ONLY               0x02
    #define GODF_PRINT_INSTRUCTIONS              0x01

**Interception:** Unlikely.

----------
#### MSG_GB_GIVE_ME_MOUSE_EVENTS
----------
#### MSG_GB_DONT_GIVE_ME_MOUSE_EVENTS
----------
#### MSG_GB_FIND_GROBJ
----------
#### MSG_GB_PULL_SELECTED_GROBJS_TO_FRONT
----------
#### MSG_GB_PUSH_SELECTED_GROBJS_TO_BACK
----------
#### MSG_GB_SHUFFLE_SELECTED_GROBJS_UP
---------
#### MSG_GB_SHUFFLE_SELECTED_GROBJS_DOWN
----------
#### MSG_GB_SET_DESIRED_HANDLE_SIZE
    void    MSG_GB_SET_DESIRED_HANDLE_SIZE(
            byte    handleSize);

----------
#### MSG_GB_REMOVE_GROBJ
----------
#### MSG_GB_ADD_GROBJ_TO_SELECTION_LIST
----------
#### MSG_GB_MESSAGE_TO_FLOATER_IF_PARENT
----------
#### MSG_GB_UPDATE_UI_CONTROLLERS
----------
#### MSG_GB_ADD_DUPLICATE_FLOATER
----------
#### MSG_GB_PRIORITY_LIST_RESET
----------
#### MSG_GB_PRIORITY_LIST_GET_NUM_ELEMENTS
----------
#### MSG_GB_PRIORITY_LIST_GET_ELEMENT
----------
#### MSG_GB_PRIORITY_LIST_INIT
----------
#### MSG_GB_GROUP_SELECTED_GROBJS
----------
#### MSG_GB_UNGROUP_SELECTED_GROUPS
----------
#### MSG_GB_TRANSFER_GROBJ_FROM_GROUP
----------
#### MSG_GB_CLOSE_FINISH_UP
----------
#### MSG_GB_CLEAR
----------
#### MSG_GB_ALIGN_SELECTED_GROBJS
----------
#### MSG_GB_CREATE_SORTABLE_ARRAY
----------
#### MSG_GB_DESTROY_SORTABLE_ARRAY
----------
#### MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_DWF_BOUNDS
----------
#### MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_CENTERS
----------
#### MSG_GB_SORT_SORTABLE_ARRAY
----------
#### MSG_GB_GET_CENTER_OF_SELECTED_GROBJS
----------
#### MSG_GB_GET_CENTER_OF_FIRST_SELECTED_GROBJ
----------
#### MSG_GB_GET_CENTER_OF_LAST_SELECTED_GROBJ
----------
#### MSG_GB_GET_DWF_BOUNDS_OF_FIRST_SELECTED_GROBJ
----------
#### MSG_GB_GET_DWF_BOUNDS_OF_LAST_SELECTED_GROBJ
----------
#### MSG_GB_GET_WINDOW
----------
#### MSG_GB_GET_BOUNDS
    void    MSG_GB_GET_BOUNDS(
            RectDWord *bounds);

----------
#### MSG_GB_SUBST_AREA_TOKEN 
----------
#### MSG_GB_SUBST_LINE_TOKEN 
----------
#### MSG_GB_CREATE_GROBJ_TRANSFER_FORMAT 
----------
#### MSG_GB_CREATE_GSTRING_TRANSFER_FORMAT 
----------
#### MSG_GB_IMPORT
----------
#### MSG_GB_EXPORT
----------
#### MSG_GB_GRAB_TARGET_FOCUS
----------
#### MSG_GB_GENERATE_TEXT_NOTIFY
----------
#### MSG_GB_GENERATE_SPLINE_NOTIFY
----------
#### MSG_GB_DETACH_GOAM
----------
#### MSG_GB_SEND_CLASSED_EVENT_SET_DEFAULT_ATTRS 
----------
#### MSG_GB_REMOVE_GROBJ_FROM_SELECTION_LIST
----------
#### MSG_GB_REMOVE_ALL_GROBJS_FROM_SELECTION_LIST
----------
#### MSG_GB_GET_NUM_SELECTED_GROBJS
----------
#### MSG_GB_GET_BOUNDS_OF_SELECTED_GROBJS
----------
#### MSG_GB_GET_DWF_BOUNDS_OF_SELECTED_GROBJS
----------
#### MSG_GB_GET_SUMMED_DWF_DIMENSIONS_OF_SELECTED_GROBJS
----------
#### MSG_GB_DELETE_SELECTED_GROBJS
----------
#### MSG_GB_PROCESS_ALL_GROBJS_IN_RECT
----------
#### MSG_GB_INCREASE_POTENTIAL_EXPANSION
----------
#### MSG_GB_DECREASE_POTENTIAL_EXPANSION
----------
#### MSG_GB_INVALIDATE
----------
#### MSG_GB_CONVERT_SELECTED_GROBJS_TO_BITMAP
----------
#### MSG_GB_CONVERT_SELECTED_GROBJS_TO_GRAPHIC
----------
#### MSG_GB_CREATE_GSTATE

## 18.5 GrObjHead
The GrObjHead, as previously mentioned, is in charge of maintaining tool 
information for an entire application. Theoretically, you could have more 
than one GrObjHead for an application, but this would lead to confusion for 
the user, and could easily become confusing for you as well. 

When declaring the GrObjHead, you may give a value for the *GH_currentTool* 
field. For instance, by passing **RectClass** in this field, the head will 
automatically start out set up ready for the user to draw rectangles. This is 
an especially useful option which only allows the user to work with one sort 
of object, and will thus not include a tool selector control.

----------
**Code Display 18-22 GrObjHead Instance Data**

    @instance ClassStruct   *GH_currentTool = NullClass;
    @instance word          GH_initializeFloaterData = 0;   /* Internal */
    @instance optr          GH_currentBody;
    @instance optr          GH_floater;         

----------
GrObjHead messages are, concerned with the current tool. 

----------
#### MSG_GH_GET_CURRENT_TOOL
    void    MSG_GH_GET_CURRENT_TOOL (
            CurrentToolValues   *retVal);

This message returns the value of the currently active tool.

**Source:** Unrestricted.

**Destination:** GrObjHead.

**Parameters:**  
*retVal* - Pointer to **CurrentToolValues**, which will hold 
return value.

**Return:** Nothing is returned explicitly.

*retVal* - Pointer to **CurrentToolValues** structure.

**Structures:** The **CurrentToolValues** structure is defined as follows:

    typedef struct{
        word            CTV_grObjSpecificData;
        word            CTV_unused;
        ClassStruct     *CTV_toolClass;
    } CurrentToolValues;

**Interception:** Unlikely.

----------
#### MSG_GH_SET_CURRENT_TOOL
    void    MSG_GH_SET_CURRENT_TOOL (
            ClassStruct     *class,
            word            initData);

This message activates a tool.

**Source:** Unrestricted.

**Destination:** GrObjHead.

**Parameters:**  
*class* - Class of the new tool.

*initData* - Tool class-specific initialization data.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GH_SET_CURRENT_BODY 
----------
#### MSG_GH_CLEAR_CURRENT_BODY 
----------
#### MSG_GH_CLASSED_EVENT_TO_FLOATER 
----------
#### MSG_GH_CLASSED_EVENT_TO_FLOATER_IF_CURRENT_BODY 
----------
#### MSG_GH_FLOATER_FINISHED_CREATE 
----------
#### MSG_GH_SEND_NOTIFY_CURRENT_TOOL 
----------
#### MSG_GH_SET_CURRENT_TOOL_WITH_DATA_BLOCK
    void MSG_GH_SET_CURRENT_TOOL_WITH_DATA_BLOCK(
        ClassStruct     *toolClass,
        word            initData); /* Handle of initialization block */

## 18.6 GrObjAttributeManager
The GrObjAttributeManager keeps track of drawing properties to use, 
maintaining arrays of line, area, and text drawing attributes. 

When the user changes the drawing properties of an object, the GOAM must 
maintain its data structures. It checks to see whether that object was the 
only one to use its old drawing properties. If it was, then the GOAM frees the 
item used to store those properties. Then it checks the new properties. If it 
already has an item corresponding to these properties, it notes that another 
object is using the property item. Otherwise, it creates a new item.

The GrObjAttributeManager's messages are concerned with maintaining 
and updating the attribute data structures.

----------
#### MSG_GOAM_CREATE_ALL_ARRAYS
    void    MSG_GOAM_CREATE_ALL_ARRAYS();

This message initializes the data structures in which the GOAM will store all 
attribute information.

**Source:** Unrestricted, often a 
MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE handler.

**Destination:** GrObjAttributeManager.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GOAM_ATTACH_AND_CREATE_ARRAYS
----------
#### MSG_GOAM_ADD_AREA_ATTR_ELEMENT 
----------
#### MSG_GOAM_ADD_LINE_ATTR_ELEMENT 
----------
#### MSG_GOAM_DEREF_AREA_ATTR_ELEMENT_TOKEN 
----------
#### MSG_GOAM_DEREF_LINE_ATTR_ELEMENT_TOKEN 
----------
#### MSG_GOAM_ADD_REF_AREA_ATTR_ELEMENT_TOKEN 
----------
#### MSG_GOAM_ADD_REF_LINE_ATTR_ELEMENT_TOKEN 
----------
#### MSG_GOAM_GET_FULL_AREA_ATTR_ELEMENT 
----------
#### MSG_GOAM_GET_FULL_LINE_ATTR_ELEMENT 
----------
#### MSG_GOAM_GET_STYLE_ARRAY 
----------
#### MSG_GOAM_GET_AREA_ATTR_ARRAY 
----------
#### MSG_GOAM_GET_LINE_ATTR_ARRAY 
----------
#### MSG_GOAM_ATTACH_BODY 
----------
#### MSG_GOAM_INVALIDATE_BODIES 
----------
#### MSG_GOAM_SUBST_AREA_TOKEN 
----------
#### MSG_GOAM_SUBST_LINE_TOKEN 
----------
#### MSG_GOAM_GET_TEXT_OD 
----------
#### MSG_GOAM_GET_TEXT_ARRAYS 
----------
#### MSG_GOAM_LOAD_STYLE_SHEET_PARAMS 
----------
#### MSG_GOAM_DETACH_BODY 

## 18.7 Graphic Objects
Members of GrObjClass act as the shape objects which appear in a graphics 
layer. Most applications don't concern themselves with graphic objects, and 
just let the GrObjBody manage them. As a general rule, the only applications 
which will work directly with graphic objects are those which create their 
own graphic objects and add them to a layer.

### 18.7.1 GrObj Instance Data
Most applications will never work with GrObj instance data in any way. 
Some applications may work with the *GOI_locks* field. This field acts to 
disallow performing certain operations on the object. Thus, if your 
application provides an object which the user should not be able to resize, 
then set the GOL_RESIZE lock.

    typedef WordFlags GrObjLocks;
    /* These fields may be combined with | and &:
        GOL_COPY,
        GOL_LOCK,
        GOL_SHOW,
        GOL_WRAP,
        GOL_MOVE,
        GOL_RESIZE,
        GOL_ROTATE,
        GOL_SKEW,
        GOL_EDIT,
        GOL_DELETE,
        GOL_SELECT,
        GOL_ATTRIBUTE,
        GOL_GROUP,
        GOL_UNGROUP,
        GOL_DRAW,
        GOL_PRINT,
    Remember, these are locks: if the bit is SET,
    then the action is FORBIDDEN! */

----------
**Code Display 18-23 GrObjClass Instance Data**

    @instance LinkPart          GOI_drawLink;       /* Internal */
    @instance LinkPart          GOI_reverseLink;    /* Internal */
    @instance GrObjAttrFlags    GOI_attrFlags = (GOAF_INSERT_DELETE_MOVE_ALLOWED |
    GOAF_INSERT_DELETE_RESIZE_ALLOWED | GOAF_INSERT_DELETE_DELETE_ALLOWED );
    /*
     *  typedef WordFlags GrObjAttrFlags;
     *  #define GOAF_DONT_COPY_LOCKS 0x0200
     *  #define GOAF_HAS_PASTE_INSIDE_CHILDREN 0x0100
     *  #define GOAF_PASTE_INSIDE 0x0080
     *  #define GOAF_INSERT_DELETE_MOVE_ALLOWED 0x0040
     *  #define GOAF_INSERT_DELETE_RESIZE_ALLOWED 0x0020
     *  #define GOAF_INSERT_DELETE_DELETE_ALLOWED 0x0010
     *  #define GOAF_INSTRUCTION 0x0008
     *  #define GOAF_MULTIPLICATIVE_RESIZE 0x0004
     *  #define GOAF_WRAP 0x0003 
     */

    @instance LinkPart GOI_drawLink;                /* Internal */

    @instance LinkPart GOI_reverseLink;             /* Internal */

    @instance GrObjAttrFlags GOI_attrFlags = (GOAF_INSERT_DELETE_MOVE_ALLOWED | \
    GOAF_INSERT_DELETE_RESIZE_ALLOWED | GOAF_INSERT_DELETE_DELETE_ALLOWED );
                                                    /* Internal */

    @instance GrObjOptimizationFlags        GOI_optFlags =(GOOF_GROBJ_INVALID); /* Internal */
    @instance GrObjMessageOptimizationFlags GOI_msgOptFlags =(0);   /* Internal */
    @instance GrObjLocks                    GOI_locks = 0;
    @instance GrObjActionModes              GOI_actionModes = 0;    /* Internal */
    @instance GrObjTempModes                GOI_tempState = 0;      /* Internal */
    @instance ChunkHandle                   GOI_normalTransform = NullChunk; /* Internal */
    @instance ChunkHandle                   GOI_spriteTransform = NullChunk; /* Internal */
    @instance word GOI_areaAttrToken = CA_NULL_ELEMENT;             /* Internal */
    @instance word GOI_lineAttrToken = CA_NULL_ELEMENT;             /* Internal */

    @vardata    GrObjActionNotificationStruct ATTR_GO_ACTION_NOTIFICATION;
    @vardata PointWWFixed ATTR_GO_PARENT_DIMENSIONS_OFFSET;         /* Internal */

----------
### 18.7.2 GrObj Messages
Most applications will never send any messages to a graphic object. For the 
most part, graphic controllers and the Graphic Body tell GrObjs everything 
that they need to know. It is possible to send a GrObj message to all selected 
GrObjs by sending it as a classed event to the graphic body, which will relay 
the message correctly.

The only applications which normally send any of these messages directly to 
a graphic object are those which instantiate a graphic object and need to 
initialize its data.

#### 18.7.2.1 Creation and Destruction

----------
#### MSG_GO_INITIALIZE
    void    MSG_GO_INITIALIZE(
            GrObjInitializeData *data)

This message initializes the object's size and position. It also causes the 
object to take on the default drawing attributes and to do any other 
initialization necessary before the object is added to the GrObjBody.

**Source:** Unrestricted.

**Destination:** New GrObj.

**Parameters:**  
*data* - The new GrObj's size and position.

**Return:** Nothing.

**Structures:** 

    typedef struct {
        PointDWFixed            GOID_position;
        WWFixed             GOID_width;
        WWFixed             GOID_height;
    } GrObjInitializeData

**Interception:** Possible. Objects with additional instance data should subclass this 
message. 

----------
#### MSG_GO_NOTIFY_GROBJ_VALID
    void    MSG_GO_NOTIFY_GROBJ_VALID();

This message notifies the GrObj that it's ready for action. The GrObj has all 
attributes that it needs to draw, including a transformation. This message is 
sent to the object at the end of an interactive create or after it has been 
created statically.

**Source:** For interactive creates, the object will send this message to itself. If 
statically created, whatever created the object must make sure this 
message is then sent to the object.

**Destination:** GrObj.

**Parameters:** None.

**Return:** Nothing.

**Interception:** Possible, but unlikely.

----------
#### MSG_GO_AFTER_ADDED_TO_BODY
    void    MSG_GO_AFTER_ADDED_TO_BODY ();

This message is sent to an object just after it has been added to a GrObjBody.

**Source:** GrObjBody only.

**Destination:** GrObj.

**Parameters:** None.

**Return:** Nothing.

**Interception:** Possible. Call superclass before doing own processing.

----------
#### MSG_GO_BEFORE_REMOVED_FROM_BODY
    void    MSG_GO_BEFORE_REMOVED_FROM_BODY ();

This message is sent to an object just before it is removed from a GrObjBody.

**Source:** GrObjBody only.

**Destination:** GrObj.

**Parameters:** None.

**Return:** Nothing.

**Interception:** Possible. Call superclass before doing own processing.



#### 18.7.2.2 Locking Actions

----------
#### MSG_GO_CHANGE_LOCKS
    dword   MSG_GO_CHANGE_LOCKS (
            GrObjLocks  setBits,
            GrObjLocks  clearBits);

This message changes the locks on an object. The object's instance data will 
be changed accordingly.

**Source:** Unrestricted.

**Destination:** GrObj.

Parameters:  
*setBits* - Locks to activate, representing forbidden actions.

*clearBits* - Locks to turn off, actions will be allowed. If 
GOL_LOCK is set, then this message will change 
the object's locks even if the GrObj's GOL_LOCK bit 
had been previously set.

**Return:** The returned value is a dword formed by concatenating two words. The 
high word is the **GrObjLocks** value of the object's locks before the 
change. The low word is the **GrObjLocks** value after the change. 
Applications which are making temporary locks may wish to save the 
old values. Mathematically, the return value is (old values << 16) + new 
values.

**Interception:** Unlikely.

#### 18.7.2.3 Drawing Attributes

----------
#### MSG_GO_SET_AREA_ATTR
    void    MSG_GO_SET_AREA_ATTR(
            GrObjBaseAreaAttrElement    *_far *attr);

This message sets the area attributes of the object.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*AreaAttrElement* - The attributes to use.

**Return:** Nothing.

**Structures:** 

    typedef struct { 
        StyleSheetElementHeader GOBAAE_styleElement;
        byte            GOBAAE_r;
        byte            GOBAAE_g;
        byte            GOBAAE_b;
        SysDrawMask     GOBAAE_mask;
        MixMode         GOBAAE_drawMode;
        GraphicPattern  GOBAEE_pattern;
        byte            GOBAEE_backR;
        byte            GOBAEE_backG;
        byte            GOBAEE_backB;
        GrObjAreaAttrElementType GOBAEE_aaeType;
        GrObjAreaAttrInfoRecord GOBAAE_areaInfo;
 
    /* The following fields are unused, but must
     * be initialized to zero. */
        byte            GOBAAE_reservedByte;
        word            GOBAAE_reserved;
    } GrObjBaseAreaAttrElement; 

    typedef enum {
        GOAAET_BASE,
        GOAAET_GRADIENT
    } GrObjAreaAttrElementType; 

    typedef ByteFlags GrObjAreaAttrInfoRecord; 
    #define GOAAIR_TRANSPARENCY 0x80 

**Interception:** Unlikely.

----------
#### MSG_GO_SET_AREA_COLOR
    void    MSG_GO_SET_AREA_COLOR(
            byte    red,
            byte    green,
            byte    blue);

This message sets a GrObj's area color.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*red* - The color's red component.

*green* - The color's green component.

*blue* - The color's blue component.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_SET_AREA_MASK
    void    MSG_GO_SET_AREA_MASK(
            SysDrawMask         mask);

This message sets a GrObj's area mask.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*mask* - The new mask.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_SET_AREA_DRAW_MODE
    void    MSG_GO_SET_AREA_DRAW_MODE(
            MixMode         mode);

This message sets a GrObj's area mix mode.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*mode* - The new mix mode.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_SET_AREA_INFO
    void    MSG_GO_SET_TRANSPARENCY(
            byte    transparent); 

This message sets a GrObj's area information flags, so that the object may 
have a transparent area.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*transparent* - Byte value: non-zero for transparent.

**Return:** Nothing.

**Structures:** The **AreaAttrInfoRecord** has one flag: AAIR_TRANSPARENT.

**Interception:** Unlikely.

----------
#### MSG_GO_SET_LINE_ATTR
    void    MSG_GO_SET_LINE_ATTR(
            GrObjBaseLineAttrElement    *attr);

This message sets a GrObj's line attributes.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
**attr** - The new line attributes.

**Return:** Nothing.

**Structures:** 

    typedef struct {
        StyleSheetElementHeader 
                            GOBGOBLAE_styleElement;
        byte                GOBLAE_r;
        byte                GOBLAE_g;
        byte                GOBLAE_b;
        LineEnd             GOBLAE_end;
        LineJoin            GOBLAE_join;
        WWFixed             GOBLAE_width;
        SystemDrawMask      GOBLAE_mask;
        LineStyle           GOBLAE_style;
        WWFixed             GOBLAE_miterLimit;
        GrObjLineAttrElementType GOBLAE_laeType;
        GrObjLineAttrInfoRecord GOBLAE_lineInfo;
        byte                GOBLAE_arrowheadAngle;
        byte                GOBLAE_arrowheadLength;
        word                GOBLAE_reserved;
    } GrObjBaseLineAttrElement; 

    typedef enum {
        GOLAET_BASE
    } GrObjLineAttrElementType; 

    typedef ByteFlags GrObjLineAttrInfoRecord; 
    #define GOLAIR_ARROWHEAD_ON_START                   0x80
    #define GOLAIR_ARROWHEAD_ON_END                     0x40
    #define GOLAIR_ARROWHEAD_FILLED                     0x20
    #define GOLAIR_ARROWHEAD_FILL_WITH_AREA_ATTRIBUTES  0x10 

**Interception:** Unlikely.

----------
#### MSG_GO_SET_LINE_COLOR
    void    MSG_GO_SET_LINE_COLOR(
            byte    red,
            byte    green,
            byte    blue);

This message sets a GrObj's line color.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*red* - The new color's red component.

*green* - The new color's green component.

*blue* - The new color's blue component.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_SET_LINE_MASK
    void    MSG_GO_SET_LINE_MASK(
            SystemDrawMask  mask);

This message sets a GrObj's line mask.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*mask* - The new line draw mask.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_SET_LINE_END
    void    MSG_GO_SET_LINE_END(
            LineEnd     end);

This message sets a GrObj's line end.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*end* - The new line end.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_SET_LINE_JOIN
    void    MSG_GO_SET_LINE_JOIN(
            LineJoin    join);

This message sets a GrObj's line join.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*join* - The new line join.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_SET_LINE_STYLE
    void    MSG_GO_SET_LINE_DRAW_STYLE(
            MixMode     mode);

This message sets a GrObj's line style, or "dottedness."

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*style* - The new line style.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_SET_LINE_WIDTH
    void    MSG_GO_SET_LINE_WIDTH(
            WWFixed     width);

This message sets a GrObj's line width.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*width* - The new line width.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_SET_LINE_MITER_LIMIIT
    void    MSG_GO_SET_LINE_MITER_LIMIT(
            WWFixed     miterLimit);

This message sets a GrObj's line miter limit, used with mitered line joins.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*miterLimit*  -The new miter limit.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_INIT_TO_DEFAULT_ATTRS
    void    MSG_GO_INIT_TO_DEFAULT_ATTRS ();

This message requests that the object initialize its attributes to the current 
defaults.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:** None.

**Return:** Nothing.

**Interception:** Unlikely.

#### 18.7.2.4 Action Notification
The following messages allow the application to specify what sort, if any, of 
notification should be sent out when the given GrObj is changed.

----------
#### MSG_GO_SET_ACTION_NOTIFICATION_OUTPUT
    void    MSG_GO_SET_ACTION_NOTIFICATION_OUTPUT(
            optr        object,
            Message     messageNumber);

This message specifies the message and OD for the GrObj to send notification 
to when an action is performed on it.

**Source:** Unrestricted.

**Destination:** GrObjBody.

**Parameters:**  
*object* - The object which should be notified. NULL to clear 
the output.

*messageNumber* - The message to send.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_SUSPEND_ACTION_NOTIFICATION
    void    MSG_GO_SUSPEND_ACTION_NOTIFICATION();

This message suspends action notification for a GrObj. This prevents the 
GrObj from sending out any action notification.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:** None.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_UNSUSPEND_ACTION_NOTIFICATION
    void    MSG_GO_UNSUSPEND_ACTION_NOTIFICATION();

This message counteracts MSG_GO_SUSPEND_ACTION_NOTIFICATION. If 
all suspends have been balanced, the GrObj will be free to send out action 
notification. However, action notifications that were aborted during the 
suspend period will not be sent out.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:** None.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_NOTIFY_ACTION
    word    MSG_GO_NOTIFY_ACTION (
            GrObjActionNotificationType     *action);

This message is sent to an object after it has been added to a GrObjBody.

**Source:** Generally the object itself.

**Destination:** GrObj.

**Parameters:**  
*action* - What sort of operation was performed.

**Return:** Word of data whose meaning depends on the notification type.

**Interception:** Possible. Call superclass before doing own processing.

#### 18.7.2.5 Transformations

----------
#### MSG_GO_FLIP_HORIZ
    void    MSG_GO_FLIP_HORIZ ();

This message flips the GrObj about its vertical axis.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:** None.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_FLIP_VERT
    void    MSG_GO_FLIP_VERT ();

This message flips the GrObj about its horizontal axis.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:** None.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_ROTATE
    void    MSG_GO_ROTATE (
            WWFixed                     angle,
            GrObjHandleSpecification    center);

This message rotates the GrObj about one of its handles.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*angle* - Angle of rotation, in degrees counterclockwise.

*center* - Which of the GrObj's handles is the center of 
rotation.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_MOVE
    void    MSG_GO_MOVE (
            PointDWFixed    *distance);

This message moves a GrObj to a relative position.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*distance* - Offsets by which to displace the object.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_MOVE_CENTER_ABS
    void    MSG_GO_MOVE_CENTER_ABS (
            PointDWFixed    *location);

This message moves a GrObj to an absolute position.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*location* - Object's new location.

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_NUDGE
    void    MSG_GO_NUDGE (
            sword   xDistance.
            sword   yDistance);

Move the GrObj by a number of device units.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*xDistance* - Horizontal offset.

*yDistance* - Vertical offset

**Return:** Nothing.

**Interception:** Unlikely.

----------
#### MSG_GO_SET_SIZE
    void    MSG_GO_SET_SIZE (
            PointWWFixed    *size);

Set the object's width and height in points. The dimensions are calculated by 
mapping the object's corners into document coordinates and calculating the 
distances between them. The center of the selection handles of a rectangle 
represent the corners mapped into document coordinates. The line thickness 
is not included in this calculation.

**Source:** GrObjBody only.

**Destination:** GrObj.

**Parameters:**  
*size* - The GrObj's new size.

**Return:** Nothing.

**Interception:** Possible. Call superclass before doing own processing.

----------
#### MSG_GO_SET_POSITION
    void    MSG_GO_SET_POSITION (
            PointDWFixed    *location);

Set the position of the upper left of a GrObj. The position set is in document 
coordinates unless the GrObj is in a group, in which case the position is in 
coordinates relative to the group's upper left corner. If the GrObj has been 
rotated, skewed, or otherwise transformed, this sets the location of the 
selection handle that was originally at the upper left of the GrObj.

**Source:** GrObjBody only.

**Destination:** GrObj.

**Parameters:**  
*location* - The GrObj's new position.

**Return:** Nothing.

**Interception:** Possible. Call superclass before doing own processing.

----------
#### MSG_GO_SCALE
    void    MSG_GO_SCALE(
            GrObjAnchoredScaleData  *params);

This message scales a GrObj.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*params* - A structure containing scale factors and which 
handle will act as the center of scaling.

**Return:** Nothing.

**Structures:** 

    typedef struct {
        WWFixed GOSD_xScale;
        WWFixed GOSD_yScale;
    } GrObjScaleData;

    typedef struct {
        GrObjScaleData GOASD_scale; 
        GrObjHandleSpecification GOASD_scaleAnchor; 
    } GrObjAnchoredScaleData;

**Interception:** Possible. Call superclass before doing own processing.

----------
#### MSG_GO_SKEW
    void    MSG_GO_SKEW(
            GrObjAnchoredSkeweData  *params);

This message skews a GrObj.

**Source:** Unrestricted.

**Destination:** GrObj.

**Parameters:**  
*params* - A structure containing skewage amounts and 
which handle will act as the center of scaling.

**Return:** Nothing.

**Structures:** 

    typedef struct {
        WWFixed GOSD_xDegrees; /* counter-clockwise */
        WWFixed GOSD_yDegrees;
    } GrObjSkewData;

    typedef struct {
        GrObjSkewData GOASD_degrees;
        GrObjHandleSpecification GOASD_skewAnchor;
    } GrObjAnchoredSkewData;

**Interception:** Possible. Call superclass before doing own processing.

----------
#### MSG_GO_GET_SIZE
    void    MSG_GO_GET_SIZE (
            GOGetSizeParams     *retVal);

Get the object's width and height in points. The dimensions are calculated by 
mapping the object's corners into document coordinates and calculating the 
distances between them. The center of the selection handles of a rectangle 
represent the corners mapped into document coordinates. The line thickness 
is not included in this calculation.

**Source:** GrObjBody only.

**Destination:** GrObj.

**Parameters:**  
*retVal* - Structure to hold return value.

**Return:** Nothing explicitly.

*retVal* - Structure filled with size information.

**Interception:** Possible. Call superclass before doing own processing.

Structures: 

    typedef struct {
         WWFixed GOGSP_height;
         WWFixed GOGSP_width;
    } GOGetSizeParams; 

----------
#### MSG_GO_GET_POSITION
    void    MSG_GO_GET_POSITION (
            PointDWFixed    *retValue);

Get the position of the upper left of a GrObj. The position is in document 
coordinates unless the GrObj is in a group, in which case the position is 
relative to the upper left of the group. If the GrObj has been rotated, skewed, 
or otherwise transformed, then this message gets the location of the selection 
handle that was originally at the upper left of the GrObj.

**Source:** GrObjBody only.

**Destination:** GrObj.

**Parameters:**  
*retValue* - Structure to hold return value.

**Return:** Nothing explicitly.

*retValue* - Structure filled with location information.

**Interception:** Possible. Call superclass before doing own processing.

#### 18.7.2.6 Cutting, Pasting, and Transfer Items
The following messages deal with the structures used with GrObj transfer 
items. You will also use the **GrObjTransferParams** structure:

    typedef struct {
        StyleSheetParams    GTP_ssp;
        VisTextSaveStyleSheetParams GTP_textSSP;
        PointDWFixed        GTP_selectionCenterDOCUMENT;
        Handle              GTP_optBlock;
        Handle              GTP_vmFile;
        word                GTP_curSlot;
        dword               GTP_id;
        word                GTP_curSize;
        word                GTP_curPos;
    } GrObjTransferParams;

----------
#### MSG_GO_CREATE_TRANSFER
    void    MSG_GO_CREATE_TRANSFER(
            GrObjTransferParams _far *params);

Any subclass that requires more than just instance data to reconstruct itself 
will subclass this message to construct the **VMChain** necessary to do so.

The *GTP_curSlot* field of *params* is updated to the next slot in the tree, 
specified by *GTP_treeBlock*.

----------
#### MSG_GO_REPLACE_WITH_TRANSFER
    void    MSG_GO_REPLACE_WITH_TRANSFER(
            GrObjTransferParams _far *params);

This message causes an existing GrObj to read the passed transfer item and 
recreate itself from that information. It is sent to an object during paste-type 
operations.

**Source:** Unrestricted.

**Destination:** Any GrObj.

**Interception:** Any subclass that requires more than just instance data to reconstruct 
itself will subclass this message to parse the **VMChain** necessary to do 
so.

----------
#### MSG_GO_WRITE_INSTANCE_TO_TRANSFER
    void    MSG_GO_WRITE_INSTANCE_TO_TRANSFER(
            GrObjTransferParams _far *params);

This message causes the GrObj to write any data needed to create the GrObj 
into a transfer item.

The *GTP_curSlot* field of *params* is updated to point just past the last 
written data so that the superclass can begin writing, etc.

**Interception:** Any subclass with data necessary to recreate the object will subclass 
this message. The subclass will first call its superclass, then write in its 
extra data.

----------
#### MSG_GO_READ_INSTANCE_FROM_TRANSFER
    void    MSG_GO_READ_INSTANCE_FROM_TRANSFER(
            GrObjTransferParams _far *params);

This message causes an existing GrObj to read the passed transfer item and 
recreate itself from that information. It is sent to an object during paste-type 
operations.

**Source:** Unrestricted.

**Destination:** Any GrObj.

**Interception:** Any subclass with data necessary to reconstruct itself will subclass this 
message. The subclass will first call its superclass, then read in its 
extra data.

#### 18.7.2.7 Miscellaneous Messages
----------
#### MSG_GO_ADD_POTENTIAL_SIZE_TO_BLOCK
----------
#### MSG_GO_SUBTRACT_POTENTIAL_SIZEFROM_BLOCK
----------
#### MSG_GO_GET_GROBJ_CLASS
----------
#### MSG_GO_BECOME_SELECTED 
    void    MSG_GO_BECOME_SELECTED(
            HandleUpdateMode hum);

----------
#### MSG_GO_TOGGLE_SELECTION 
    void    MSG_GO_TOGGLE_SELECTION();

----------
#### MSG_GO_BECOME_UNSELECTED 
    void    MSG_GO_BECOME_UNSELECTED();

----------
#### MSG_GO_UNDRAW_SPRITE 
----------
#### MSG_GO_DRAW_SPRITE 
----------
#### MSG_GO_DRAW_SPRITE_RAW 
----------
#### MSG_GO_DRAW_HANDLES 
----------
#### MSG_GO_UNDRAW_HANDLES 
----------
#### MSG_GO_DRAW_HANDLES_RAW 
----------
#### MSG_GO_DRAW_HANDLES_FORCE 
----------
#### MSG_GO_DRAW_HANDLES_MATCH 
----------
#### MSG_GO_DRAW_HANDLES_OPPOSITE 
----------
#### MSG_GO_ACTIVATE_MOVE 
----------
#### MSG_GO_ACTIVATE_RESIZE 
----------
#### MSG_GO_ACTIVATE_ROTATE 
----------
#### MSG_GO_ACTIVATE_CREATE 
----------
#### MSG_GO_REACTIVATE_CREATE 
----------
#### MSG_GO_START_CHOOSE_ABS 
----------
#### MSG_GO_START_MOVE_ABS 
----------
#### MSG_GO_JUMP_START_MOVE 
----------
#### MSG_GO_JUMP_START_RESIZE 
----------
#### MSG_GO_JUMP_START_ROTATE 
----------
#### MSG_GO_PTR_CHOOSE_ABS 
----------
#### MSG_GO_PTR_MOVE 
----------
#### MSG_GO_PTR_RESIZE 
----------
#### MSG_GO_PTR_ROTATE 
----------
#### MSG_GO_PTR_MOVE_ABS 
----------
#### MSG_GO_END_CHOOSE_ABS 
----------
#### MSG_GO_END_MOVE_ABS 
----------
#### MSG_GO_END_MOVE 
----------
#### MSG_GO_END_RESIZE 
----------
#### MSG_GO_END_ROTATE 
----------
#### MSG_GO_CLEAR 
----------
#### MSG_GO_INVERT_HANDLES 
----------
#### MSG_GO_INIT_BASIC_DATA 
----------
#### MSG_GO_ALIGN 
----------
#### MSG_GO_ALIGN_TO_GRID 
----------
#### MSG_GO_SEND_ANOTHER_TOOL_ACTIVATED 
----------
#### MSG_GO_ANOTHER_TOOL_ACTIVATED 
----------
#### MSG_GO_SPECIAL_RESIZE_CONSTRAIN 
    void    MSG_GO_SPECIAL_RESIZE_CONSTRAIN(
            GrObjHandleSpecification grObjHandleSpec);

----------
#### MSG_GO_DUPLICATE_FLOATER 
----------
#### MSG_GO_GRAB_MOUSE 
----------
#### MSG_GO_RELEASE_MOUSE 
----------
#### MSG_GO_UNGROUPABLE 
----------
#### MSG_GO_GET_BOUNDING_RECTDWFIXED 
----------
#### MSG_GO_CALC_DOCUMENT_DIMENSIONS 
----------
#### MSG_GO_INIT_CREATE 
----------
#### MSG_GO_INVERT_GROBJ_SPRITE 
----------
#### MSG_GO_INVERT_GROBJ_NORMAL_SPRITE 
----------
#### MSG_GO_INVALIDATE 
----------
#### MSG_GO_GET_DW_PARENT_BOUNDS 
----------
#### MSG_GO_GET_DWF_PARENT_BOUNDS 
----------
#### MSG_GO_GET_WWF_PARENT_BOUNDS 
----------
#### MSG_GO_GET_WWF_OBJECT_BOUNDS 
    void    MSG_GO_GET_WWF_OBJECT_BOUNDS(
            RectWWFixed         *retValue);

----------
#### MSG_GO_BECOME_UNEDITABLE 
----------
#### MSG_GO_EVALUATE_POSITION 
----------
#### MSG_GO_EVALUATE_PARENT_POINT 
----------
#### MSG_GO_GET_CENTER 
    void    MSG_GO_GET_CENTER(
            PointDWFixed        *center);

----------
#### MSG_GO_DRAW 
----------
#### MSG_GO_LARGE_START_SELECT 
----------
#### MSG_GO_LARGE_START_MOVE_COPY 
----------
#### MSG_GO_LARGE_END_SELECT 
----------
#### MSG_GO_LARGE_END_MOVE_COPY 
----------
#### MSG_GO_LARGE_DRAG_SELECT 
----------
#### MSG_GO_LARGE_DRAG_MOVE_COPY 
----------
#### MSG_GO_LARGE_PTR 
----------
#### MSG_GO_AFTER_ADDED_TO_GROUP 
----------
#### MSG_GO_BEFORE_REMOVED_FROM_GROUP 
----------
#### MSG_GO_SUBST_AREA_TOKEN 
----------
#### MSG_GO_SUBST_LINE_TOKEN 
----------
#### MSG_GO_GET_ANCHOR_DOCUMENT 
----------
#### MSG_GO_BECOME_EDITABLE 
----------
#### MSG_GO_DRAW_EDIT_INDICATOR 
----------
#### MSG_GO_UNDRAW_EDIT_INDICATOR 
----------
#### MSG_GO_DRAW_EDIT_INDICATOR_RAW 
----------
#### MSG_GO_INVERT_EDIT_INDICATOR 
----------
#### MSG_GO_GROBJ_SPECIFIC_INITIALIZE 
----------
#### MSG_GO_GROBJ_SPECIFIC_INITIALIZE_WITH_DATA_BLOCK 
----------
#### MSG_GO_APPLY_ATTRIBUTES_TO_GSTATE 
----------
#### MSG_GO_COMBINE_AREA_NOTIFICATION_DATA 
    @message void MSG_GO_COMBINE_AREA_NOTIFICATION_DATA( 
             Handle /* GrObjNotifyAreaAttrChange */ change);

Combine this GrObj's attributes with the passed structure.

**Structures:** 

    typedef struct {
        GrObjBaseAreaAttrElement GNAAC_areaAttr;
        GrObjBaseAreaAttrDiffs GNAAC_areaAttrDiffs;
    } GrObjNotifyAreaAttrChange;

    typedef WordFlags GrObjBaseAreaAttrDiffs;
    #define GOBAAD_MULTIPLE_ELEMENT_TYPES 0x8000
    #define GOBAAD_MULTIPLE_STYLE_ELEMENTS 0x4000
    #define GOBAAD_MULTIPLE_COLORS 0x2000
    #define GOBAAD_MULTIPLE_BACKGROUND_COLORS 0x1000
    #define GOBAAD_MULTIPLE_MASKS 0x0800
    #define GOBAAD_MULTIPLE_PATTERNS 0x0400
    #define GOBAAD_MULTIPLE_DRAW_MODES 0x0200
    #define GOBAAD_MULTIPLE_INFOS 0x0100
    #define GOBAAD_MULTIPLE_GRADIENT_END_COLORS 0x0080
    #define GOBAAD_MULTIPLE_GRADIENT_TYPES 0x0040
    #define GOBAAD_MULTIPLE_GRADIENT_INTERVALS 0x0020
    #define GOBAAD_FIRST_RECIPIENT 0x0001
        /* A grobj knows that it's the first one to
         * receive this data buffer if this flag is
         * set (and should clear it). */

----------
#### MSG_GO_COMBINE_LINE_NOTIFICATION_DATA 
----------
#### MSG_GO_COMBINE_SELECT_STATE_NOTIFICATION_DATA 
----------
#### MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA 
----------
#### MSG_GO_COMBINE_STYLE_NOTIFICATION_DATA 
    void    MSG_GO_COMBINE_STYLE_NOTIFICATION_DATA(
            Handle  change);    /* handle of block containing NotifyStyleChange */

----------
#### MSG_GO_COMBINE_STYLE_SHEET_NOTIFICATION_DATA 
    void    MSG_GO_COMBINE_STYLE_SHEET_NOTIFICATION_DATA(
            Handle change );        /* handle of NotifyStyleSheetChange */

----------
#### MSG_GO_SEND_UI_NOTIFICATION 
----------
#### MSG_GO_COMPLETE_TRANSFORM 
----------
#### MSG_GO_COMPLETE_TRANSLATE 
----------
#### MSG_GO_INSERT_OR_DELETE_SPACE 
----------
#### MSG_GO_EVALUATE_PARENT_POINT_FOR_EDIT 
----------
#### MSG_GO_GET_POINTER_IMAGE 

### 18.7.3 Shape Classes
The GrObj class on its own, while very powerful, is rather general. GrObjs 
per se aren't actually associated with any shape. Thus, a number of 
subclasses exist to correctly manifest as different kinds of shapes. None of 
these classes has any class-specific messages, although each of course must 
subclass many messages to correctly maintain instance data and draw 
correctly.


**RectClass** is a subclass of **GrObjClass** with no specialized instance data or 
messages.


**RoundedRectClass** is a subclass of **RectClass** with one piece of additional 
instance data: *RRI_radius*.


**LineClass** is a subclass of **GrObjClass** with no specialized instance data or 
messages.


**GStringClass** is a subclass of **GrObjClass** which does not correspond to any 
shape. Instead, it may hold any GString. It has two extra instance fields: 
*GSI_vmemBlockHandle* is the *VMBlockHandle* in which the GString is 
stored. The *GSI_gstringCenterTrans* field holds the GString's center point. It 
has one extra message, MSG_GSO_SET_GSTRING, which sets the contents of 
the GString.

### 18.7.4 GroupClass
The **GroupClass** is a subclass of **GrObjClass** which is used to group 
GrObjs. Grouped objects may be moved, rotated, scaled, and skewed 
collectively.

----------
**Code Display 18-24 GroupClass Instance Data**

    @instance CompPart              GI_drawHead;
    @instance word                  GI_suspendCount;
    @instance GroupUnsuspendOps     GI_unsuspendOps; 

    typedef ByteFlags GroupUnsuspendOps;
    #define GUO_EXPAND 0x01 

----------
----------
#### MSG_GROUP_ADD_GROBJ 
----------
#### MSG_GROUP_REMOVE_GROBJ 
----------
#### MSG_GROUP_CREATE_GSTATE 
----------
#### MSG_GROUP_PROCESS_ALL_GROBJS_SEND_CALL_BACK_MESSAGE 
----------
#### MSG_GROUP_INITIALIZE 
----------
#### MSG_GROUP_EXPAND 
----------
#### MSG_GROUP_INSTANTIATE_GROBJ 
    optr    MSG_GROUP_INSTANTIATE_GROBJ(
            ClassStruct         *class);

### 18.7.5 PointerClass
**PointerClass** is a subclass of **GrObjClass**. GeoDraw's Arrow Pointer is a 
member of this class. Pointers are used for selecting graphic objects and 
interacting with their handles. Pointers control moves and resizes.


**RotatePointerClass** is a subclass of **PointerClass**. Like pointer class, it 
works with an object's handles, but it rotates instead of resizing. The 
**BitmapPointerClass** is useful for working with bitmaps in a GrObj context. 

----------
**Code Display 18-25 PointerClass Instance Data**

    @instance PointerModes                  PTR_modes; /* Internal */

----------

### 18.7.6 GrObjVisGuardian Classes
GrObj provides the ability to incorporate vis objects into a graphic layer. This 
requires that two special classes be set up, known as a guardian and a ward. 
The GrObjVisGuardian is a subclass of GrObj, and accepts all standard 
GrObj messages. The ward class is a subclass of **GrObjVisClass**, set up to 
work with the appropriate visual class. **GrObjVisClass** is a master variant 
class and uses the appropriate visual class as its superclass.


Thus, there is a **SplineGuardianClass** and a **GrObjSplineClass** for 
working with splines and polylines. **TextGuardianClass** and 
**GrObjTextClass** work with text objects. Bitmaps are implemented using 
**BitmapGuardianClass** together with the **GrObjBitmap** class.

Working with these object pairs is simple: you can work with the guardian 
object as you would with any graphic object. This happens automatically and 
transparently. You may also query any guardian object for the OD of its ward, 
and then interact with the ward as with a normal object of the appropriate 
visual type. Thus, you could send a MSG_GOVG_GET_VIS_WARD to a 
TextGuardian, then pass a MSG_VIS_TEXT_REPLACE_ALL to the returned 
OD.

The VisText object is documented in "The Text Objects," Chapter 10. 

Chances are, you will never be concerned with the inner workings of the 
**GrObjVisClass**. It is a subclass of VisClass, with one extra piece of instance 
data: *GVI_guardian*, which holds the optr of the ward's guardian object.

----------
**Code Display 18-26 GrObjVisGuardianClass Instance Data**

    @instance optr                      GOVGI_ward; 
    @instance word                      *GOVGI_class;
    @instance GrObjVisGuardianFlags     GOVGI_flags;

----------

----------
#### MSG_GOVG_UPDATE_VIS_WARD_WITH_STORED_DATA 
----------
#### MSG_GOVG_CONVERT_LARGE_MOUSE_DATA 
----------
#### MSG_GOVG_CREATE_VIS_WARD 
    optr    MSG_GOVG_CREATE_VIS_WARD(
            MemHandle       wardBlock);

----------
#### MSG_GOVG_ADD_VIS_WARD 
----------
#### MSG_GOVG_APPLY_OBJECT_TO_VIS_TRANSFORM 
----------
#### MSG_GOVG_CREATE_GSTATE 
----------
#### MSG_GOVG_VIS_BOUNDS_SETUP 
----------
#### MSG_GOVG_SET_VIS_WARD_MOUSE_EVENT_TYPE 
----------
#### MSG_GOVG_UPDATE_EDIT_GRAB_WITH_STORED_DATA 
----------
#### MSG_GOVG_NORMALIZE 
----------
#### MSG_GOVG_NOTIFY_VIS_WARD_CHANGE_BOUNDS 
----------
#### MSG_GOVG_GET_EDIT_CLASS 
----------
#### MSG_GOVG_GET_VIS_WARD_OD 
    optr    MSG_GOVG_GET_VIS_WARD_OD();

----------
#### MSG_GOVG_GET_TRANSFER_BLOCK_FROM_VIS_WARD 
----------
#### MSG_GOVG_CREATE_WARD_WITH_TRANSFER 
----------
#### MSG_GOVG_SET_VIS_WARD_CLASS 

#### GrObjVisClass Messages

----------
#### MSG_GV_GET_WWFIXED_CENTER 
----------
#### MSG_GV_SET_GUARDIAN_LINK 
----------
#### MSG_GV_SET_VIS_BOUNDS 

[The Spool Library](oprint.md) <-- [Table of Contents](../objects.md) &nbsp;&nbsp; --> [Ruler Object Library](oruler.md)

