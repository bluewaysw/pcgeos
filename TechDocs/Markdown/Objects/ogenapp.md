# 3 GenApplication

The GenApplication object is used as the top object in every application 
geode. It acts as the head of the generic object tree, and it provides all the 
functionality necessary for launching and shutting down the application. It 
is a subclass of **GenClass** and therefore inherits all the instance data and 
messages of that class.

**GenApplicationClass** has no inherent visual representation. Instead, the 
main windows of an application are created and managed by one or more 
GenPrimary objects, which should be placed both as children of the 
Application object and on the application's GAGCNLT_WINDOWS notification 
list (if it should appear when the application starts up).

## 3.1 GenApplication Basics

The top-level generic object of your application must be a GenApplication 
object. You should place this application object within its own resource; this 
ensures that your application will take up little memory when minimized. 
Your application tree should branch from this single node. Code Display 3-1 
shows a section of Hello World to illustrate the typical use of a 
**GenApplicationClass** object.

----------
**Code Display 3-1 HelloApp from Hello World**

    /*          Application Object
     * The hello.gp file contains an "appobj" statement which indicates that this
     * "HelloApp" object is the top-level UI object. Note that the name of the
     * resource you place the application object in may be whatever you choose;
     * it does not have to be AppResource. */
    
    @start AppResource;     /* Begin definition of objects in AppResource. */
    
    @object GenApplicationClass HelloApp = {
        GI_comp = @HelloPrimary;
            /* The GI_comp attribute lists the generic children
             * of the object. The HelloApp object has just one
             * child, the primary window of the application. */

        gcnList(MANUFACTURER_ID_GEOWORKS, GAGCNLT_WINDOWS) = HelloPrimary; 
            /* The window's application GCN list determines which
             * windowable children should be launched on
             * startup. The primary window in most cases should be
             * launched on startup.*/
    }

    @end AppResource        /* End definition of objects in AppResource. */

----------
Typically, you will not subclass **GenApplicationClass**. You may 
occasionally send messages to it, but otherwise it exists primarily to interact 
with the User Interface.

Note that the Application object you set up in your .**goc** file must be reflected 
in the Geode Parameters file (the .**gp** file). The name of the Application object 
should appear in the **appobj** field of the .**gp** file.

### 3.1.1 Instance Data

**GenApplicationClass** provides several instance data fields, most of which 
you will not use. All the instance fields of GenApplication are listed in Code 
Display 3-2 for reference, however.

----------
**Code Display 3-2 GenApplication Instance Fields**

    /* These fields will not be used directly. They can be accessed dynamically,
     * however, with the various messages that set and retrieve the instance data. */
    
    @instance AppInstanceReference  GAI_appRef = {"","",NullHandle,{0}};
    @instance word                  GAI_appMode = 0;
    @instance AppLaunchFlags        GAI_launchFlags = 0;
    @instance byte                  GAI_optFlags = 0;
    @instance word                  GAI_appFeatures = 0;
    @instance Handle                GAI_specificUI = 0;
    @instance ApplicationStates     GAI_states = AS_FOCUSABLE | AS_MODELABLE;
    @instance AppAttachFlags        GAI_attachFlags = 0;
    @instance UIInterfaceLevel      GAI_appLevel = UIIL_ADVANCED;
    @instance ChunkHandle           GAI_iacpConnects = 0;
    
    /* ApplicationStates */

    typedef WordFlags ApplicationStates;
    #define AS_HAS_FULL_SCREEN_EXCL         0x2000
    #define AS_SINGLE_INSTANCE              0x1000
    #define AS_QUIT_DETACHING               0x0800
    #define AS_AVOID_TRANSPARENT_DETACH     0x0400
    #define AS_TRANSPARENT_DETACHING        0x0200
    #define AS_REAL_DETACHING               0x0100
    #define AS_QUITTING                     0x0080
    #define AS_DETACHING                    0x0040
    #define AS_FOCUSABLE                    0x0020
    #define AS_MODELABLE                    0x0010
    #define AS_NOT_USER_INTERACTABLE        0x0008
    #define AS_RECEIVED_APP_OBJECT_DETACH   0x0004
    #define AS_ATTACHED_TO_STATE_FILE       0x0002
    #define AS_ATTACHING                    0x0001

    /* Optimization Flags */

    typedef ByteFlags AppOptFlags;
    #define AOF_MULTIPLE_INIT_FILE_CATEGORIES   0x80

    /* GenApplicationClass also modifies two GenClass instance fields. */

    @default GI_states = @default & ~GS_USABLE;
    @default GI_attrs = @default | GA_TARGETABLE;

----------
*GAI_appRef* is internal. It stores information needed to reload this 
application. If the application is detached, this instance field contains 
information necessary to reload this application to its state at detachment.

*GAI_appMode* stores the message that should be sent to the application's 
Process object to bring the application back from a saved state. This is 
initially null and is set by the **GenProcessClass** object as soon as it is 
determined.

*GAI_launchFlags* stores the **AppLaunchFlags** that govern how the 
application should be run. These flags are used internally and are set when 
the application is first launched.

*GAI_appFeatures* stores a word representing the application's features as 
determined by the user's level of expertise. This field is used primarily by 
hints in GenControl objects and is rarely used directly otherwise.

*GAI_specificUI* stores the handle of the specific UI under which this 
application is running. This is determined and set by the system when the 
application is launched.

*GAI_states* stores the **ApplicationStates** of the GenApplication. See 
"ApplicationStates" below for full information on application states.

*GAI_attachFlags* stores the **AppAttachFlags** relating to restoring the 
application from a state file when attached. 

----------
**Code Display 3-3 GenApplication Vardata Fields**

    @vardata void HINT_APP_IS_ENTERTAINING;
    @vardata void HINT_APP_IS_EDUCATIONAL;
    @vardata void HINT_APP_IS_PRODUCTIVITY_ORIENTED;

    @vardata optr ATTR_GEN_APPLICATION_PRINT_CONTROL;
        @reloc ATTR_GEN_APPLICATION_PRINT_CONTROL, 0, optr;
    @vardata optr ATTR_GEN_APPLICATION_KBD_OBJ;
    @vardata optr ATTR_GEN_APPLICATION_SAVE_OPTIONS_TRIGGER;
        @reloc ATTR_GEN_APPLICATION_SAVE_OPTIONS_TRIGGER, 0, optr;

    /* GenApplication adds a TravelOption to communicate with the Print Control. */

    typedef enum {
        TO_PRINT_CONTROL=_FIRST_GenApplicationClass
    } GenApplicationTravelOption;

----------
GenApplication also provides several hints that indicate the type of 
application. HINT_APP_IS_ENTERTAINING, HINT_APP_IS_EDUCATIONAL 
and HINT_APP_IS_PRODUCTIVITY_ORIENTED are provided for this purpose. 

ATTR_GEN_APPLICATION_PRINT_CONTROL stores the optr of the object to 
act as the destination for any messages sent to the 
**GenApplicationTravelOption** TO_PRINT_CONTROL. Specifically, this 
attribute is designed to allow remote printing capabilities.

ATTR_GEN_APPLICATION_KBD_OBJ stores the optr of the object to act as the 
application's floating keyboard. This object must be a subclass of 
**GenInteractionClass** and must be in the generic tree below the application 
object. MSG_GEN_APPLICATION_DISPLAY_FLOATING_KEYBOARD will 
display this keyboard.

ATTR_GEN_APPLICATION_SAVE_OPTIONS_TRIGGER contains the optr of the 
Save Options trigger within the options menu. If you have a custom Save 
Options trigger, you should add the optr of this object in this field.

### 3.1.2 Application GCN Lists

The GCN mechanism is fully discussed in "General Change Notification," 
Chapter 9 of the Concepts Book. 

Your application may use application GCN lists to notify objects of certain 
events. For example, it is essential that any windowed objects that you wish 
to appear upon startup (including your GenPrimary) are added to the 
GAGCNLT_WINDOWS GCN list. 

GenApplication uses its own GCN list types. The four most often used, and 
the four you will likely use in most of your applications, are listed below. The 
others can be found in the file **geoworks.def** and following this short list. 
Note that all of these GCN list types correspond to the manufacturer ID 
MANUFACTURER_ID_GEOWORKS.

+ MGCNLT_ACTIVE_LIST
This GCN list keeps a record of all objects that need to be built upon 
application startup. Objects on this list will receive several system attach 
and detach messages. Several types of GenControl objects need to be on 
this list to function properly. In that case, these controllers must also 
appear on either the GAGCNLT_SELF_LOAD_OPTIONS or 
GAGCNLT_STARTUP_LOAD_OPTIONS lists as well. Objects that do not 
need to receive attach notification (but do need to receive detach 
notification) may be added dynamically to this list.

+ GAGCNLT_WINDOWS
This GCN list keeps a record of windowed objects. All windowed objects 
that should be visible on startup must be added to this list. Any time a 
windowed object is visually initialized, it will be added to this list. It will 
not be removed until the object is visually closed. This is used to save 
window state across shutdown.

+ GAGCNLT_SELF_LOAD_OPTIONS
This GCN list contains a record of all objects that save options upon 
receiving MSG_META_SAVE_OPTIONS. These objects will self-load their 
options; objects on this list will not receive MSG_META_LOAD_OPTIONS 
automatically. If they need to do so, they should be added to the 
GAGCNLT_STARTUP_LOAD_OPTIONS list instead. Objects on this list 
will be sent MSG_META_SAVE_OPTIONS when the GenApplication 
receives MSG_META_SAVE_OPTIONS.

+ GAGCNLT_STARTUP_LOAD_OPTIONS
This GCN list contains a record of all objects that should both load their 
options upon startup and save their options upon receiving 
MSG_META_SAVE_OPTIONS. Objects on this list will receive 
MSG_META_LOAD_OPTIONS when they are first loaded.

----------
**Code Display 3-4 Sample GenApplication with Controllers**

    /* This application includes six controllers. One, the TabControl, must receive 
     * MSG_META_ATTACH to work properly and is placed on the GCN active list. Another
     * controller, the GenViewController, must receive MSG_META_LOAD_OPTIONS at
     * startup and is therefore placed on the STARTUP_LOAD_OPTIONS list. All other
     * controllers are placed on the SELF_LOAD_OPTIONS list. Note that controllers
     * placed on the active list still need to be placed on one options list. */

    @object GenApplicationClass MyApplication = {
        GI_comp = @MyPrimary;
        /* Windows GCN list. */
        gcnList(MANUFACTURER_ID_GEOWORKS, GAGCNLT_WINDOWS) = @MyPrimary;
        /* Active GCN list. All objects that should receive
         * MSG_META_ATTACH should be on this list. These controllers
         * should also be added to the appropriate LOAD_OPTIONS list. */
        gcnList(MANUFACTURER_ID_GEOWORKS, MGCNLT_ACTIVE_LIST) = @MyTabControl, 
                            @MyToolControl;
        /* Startup Load Options GCN list. This list must include
         * all objects that should receive MSG_META_LOAD_OPTIONS
         * at attach time. */
        gcnList(MANUFACTURER_ID_GEOWORKS, GAGCNLT_STARTUP_LOAD_OPTIONS) =
                            @MyGenViewControl;
        /* Self Load Options GCN list. All objects that save
         * options and are not on the Startup Load Options list
         * should appear here. */
        gcnList(MANUFACTURER_ID_GEOWORKS, GAGCNLT_SELF_LOAD_OPTIONS) = @MyTabControl,
                            @MyToolControl, @MyEditControl, @MyCharControl, 
                            @MyParaControl;
    }

----------



The other GenApplication-defined GCN lists are listed below with comments 
about their functions. Other GCN list types are also declared by other classes 
(e.g. **MetaClass**).

GAGCNLT_GEN_CONTROL_NOTIFY_STATUS_CHANGE  
Keeps the GenToolControl up-to-date on the status of all the GenControl 
objects. The data block passed with this list is of type 
**NotifyGenControlStatusChange**.

GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE  
Notifies objects of changes in the selection state. The data block passed 
with this list is of type **NotifySelectStateChange**.

GAGCNLT_EDIT_CONTROL_NOTIFY_UNDO_STATE_CHANGE  
Notifies objects of changes in the state of the undo item. The data block 
passed with this list is of type **NotifyUndoStateChange**.

GAGCNLT_APP_TARGET_NOTIFY_TEXT_CHAR_ATTR_CHANGE  
Notifies objects of changes in the text character attributes.The data block 
passed with this list is of type **VisTextNotifyCharAttrChange**.

GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE  
Notifies objects of changes in the text paragraph attributes. The data 
block passed with this list is of type **VisTextNotifyParaAttrChange**.

GAGCNLT_APP_TARGET_NOTIFY_TEXT_TYPE_CHANGE  
Notifies objects of changes in the text type change.The data block passed 
with this list is of type **VisTextNotifyTypeChange**.

GAGCNLT_APP_TARGET_NOTIFY_TEXT_SELECTION_CHANGE  
Notifies objects of changes in the text selection. The data block passed 
with this list is of type **VisTextNotifySelectionChange**.

GAGCNLT_APP_TARGET_NOTIFY_TEXT_COUNT_CHANGE  
Notifies objects of changes in the text count. The data block passed with 
this list is of type **VisTextNotifyCountChange**.

GAGCNLT_APP_TARGET_NOTIFY_STYLE_TEXT_CHANGE  
Notifies objects of possible changes in the style. The data block passed 
with this list is of type **NotifyStyleChange**.

GAGCNLT_APP_TARGET_NOTIFY_STYLE_SHEET_TEXT_CHANGE  
Notifies objects of possible changes in the style sheet.The data block 
passed with this list is of type **NotifyStyleSheetChange**.

GAGCNLT_APP_TARGET_NOTIFY_TEXT_STYLE_CHANGE  
Notifies objects of changes in the current text style. The data block 
passed with this list is of type **NotifyTextStyleChange**.

GAGCNLT_APP_TARGET_NOTIFY_FONT_CHANGE  
Notifies objects of changes in the font. The data block passed with this list 
is of type **NotifyFontChange**.

GAGCNLT_APP_TARGET_NOTIFY_POINT_SIZE_CHANGE  
Notifies objects of changes in text point size. The data block passed with 
this list is of type **NotifyPointSizeChange**.

GAGCNLT_APP_TARGET_NOTIFY_FONT_ATTR_CHANGE  
Notifies objects of changes in the font attributes. The data block passed 
with this list is of type **NotifyFontAttrChange**.

GAGCNLT_APP_TARGET_NOTIFY_JUSTIFICATION_CHANGE  
Notifies objects of changes in the paragraph justification. The data block 
passed with this list is of type **NotifyJustificationChange**.

GAGCNLT_APP_TARGET_NOTIFY_TEXT_FG_COLOR_CHANGE  
Notifies objects of changes in the text foreground (character) color. The 
data block passed with this list is of type **NotifyColorChange**.

GAGCNLT_APP_TARGET_NOTIFY_TEXT_BG_COLOR_CHANGE  
Notifies objects of changes in the text background color. The data block 
passed with this list is of type **NotifyColorChange**.

GAGCNLT_APP_TARGET_NOTIFY_PARA_COLOR_CHANGE  
Notifies objects of changes in the text paragraph color.The data block 
passed with this list is of type **NotifyColorChange**.

GAGCNLT_APP_TARGET_NOTIFY_BORDER_COLOR_CHANGE  
Notifies objects of changes in text border color. The data block passed 
with this list is of type **NotifyColorChange**.

GAGCNLT_APP_TARGET_NOTIFY_SEARCH_SPELL_CHANGE  
Notifies objects of changes in the search/spell objects.

GAGCNLT_APP_TARGET_NOTIFY_SEARCH_REPLACE_CHANGE  
Notifies objects of changes in the search-and-replace mechanism.

GAGCNLT_APP_TARGET_NOTIFY_CHART_TYPE_CHANGE  
Notifies objects of changes in chart type.

GAGCNLT_APP_TARGET_NOTIFY_CHART_GROUP_FLAGS  
Notifies objects of changes in chart group flags.

GAGCNLT_APP_TARGET_NOTIFY_CHART_AXIS_ATTRIBUTES  
Notifies objects of changes in chart axis attributes.

GAGCNLT_APP_TARGET_NOTIFY_CHART_MARKER_SHAPE  
Notifies objects of changes in the chart marker shape.

GAGCNLT_APP_TARGET_NOTIFY_GROBJ_CURRENT_TOOL_CHANGE  
Notifies objects of changes in the selected GrObj tool.

GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE  
Notifies objects of changes in the GrObj body selection state.

GAGCNLT_APP_TARGET_NOTIFY_GROBJ_AREA_ATTR_CHANGE  
Notifies objects of changes in the GrObj area attributes.

GAGCNLT_APP_TARGET_NOTIFY_GROBJ_LINE_ATTR_CHANGE  
Notifies objects of changes in the GrObj line attributes.

GAGCNLT_APP_TARGET_NOTIFY_GROBJ_TEXT_ATTR_CHANGE  
Notifies objects of changes in the GrObj text attributes.

GAGCNLT_APP_TARGET_NOTIFY_STYLE_GROBJ_CHANGE  
Notifies objects of changes in style changes relating to the GrObj.

GAGCNLT_APP_TARGET_NOTIFY_STYLE_SHEET_GROBJ_CHANGE  
Notifies objects of changes in the style sheet.

GAGCNLT_APP_TARGET_NOTIFY_RULER_TYPE_CHANGE  
Notifies objects of changes in ruler type.

GAGCNLT_APP_TARGET_NOTIFY_RULER_GRID_CHANGE  
Notifies objects of changes in the ruler grid.

GAGCNLT_TEXT_RULER_OBJECTS  
Notifies objects of changes in the active ruler.

GAGCNLT_APP_TARGET_NOTIFY_BITMAP_CURRENT_TOOL_CHANGE  
Notifies objects of changes in the selected bitmap tool.

GAGCNLT_APP_TARGET_NOTIFY_BITMAP_CURRENT_FORMAT_CHANGE  
Notifies objects of changes in the current bitmap format.

GAGCNLT_APP_TARGET_NOTIFY_FLAT_FILE_FIELD_PROPERTIES_STATUS_CHANGE  
Notifies objects of changes in the flatfile database properties status.

GAGCNLT_APP_TARGET_NOTIFY_FLAT_FILE_FIELD_LIST_CHANGE  
Notifies objects of changes in the flatfile field list.

GAGCNLT_APP_TARGET_NOTIFY_FLAT_FILE_RCP_STATUS_CHANGE  
Notifies objects of changes in flatfile status.

GAGCNLT_APP_TARGET_NOTIFY_FLAT_FILE_FIELD_APPEARANCE_CHANGE  
Notifies objects that a field within the flat file has changed its 
appearance.

GAGCNLT_APP_NOTIFY_DOC_SIZE_CHANGE  
Notifies objects of changes in document size. The data block passed with 
this list is of type **NotifyPageSetupChange**.

GAGCNLT_APP_NOTIFY_PAPER_SIZE_CHANGE  
Notifies objects of changes in chosen paper size. The data block passed 
with this list is of type **NotifyPageSetupChange**.

GAGCNLT_APP_TARGET_NOTIFY_VIEW_STATE_CHANGE  
Notifies objects of changes in of view state. The data block passed with 
this list is of type **NotifyViewStateChange**.

GAGCNLT_CONTROLLED_GEN_VIEW_OBJECTS  
A list of GenView objects controlled by the GenViewControl. (These 
GenViews will have ATTR_GEN_VIEW_INTERACT_WITH_CONTROLLER 
set in their instance data.)

GAGCNLT_APP_TARGET_NOTIFY_INK_STATE_CHANGE  
Notifies objects of changes in Ink state.

GAGCNLT_CONTROLLED_INK_OBJECTS  
A list of Ink objects controlled by the InkControl.

GAGCNLT_APP_TARGET_NOTIFY_PAGE_STATE_CHANGE  
Notifies objects of changes in page state. The data block passed with this 
list is of type **NotifyPageStateChange**.

GAGCNLT_APP_TARGET_NOTIFY_DOCUMENT_CHANGE  
Notifies objects of changes in a document. The data block passed with 
this list is of type **NotifyPageStateChange**.

GAGCNLT_APP_TARGET_NOTIFY_DISPLAY_CHANGE  
Notifies objects of changes in a display. The data block passed with this 
list is of type **NotifyDisplayChange**.

GAGCNLT_APP_TARGET_NOTIFY_DISPLAY_LIST_CHANGE  
Notifies objects of changes in the display list. The data block passed with 
this list is of type **NotifyColorChange**.

GAGCNLT_APP_TARGET_NOTIFY_SPLINE_MARKER_SHAPE  
Notifies objects of changes in a spline marker shape.

GAGCNLT_APP_TARGET_NOTIFY_SPLINE_POINT  
Notifies objects of changes in spline points.

GAGCNLT_APP_TARGET_NOTIFY_SPLINE_POLYLINE  
Notifies objects of changes in spline polylines.

GAGCNLT_APP_TARGET_NOTIFY_SPLINE_SMOOTHNESS  
Notifies objects of changes in spline smoothness.

GAGCNLT_APP_TARGET_NOTIFY_SPLINE_OPEN_CLOSE_CHANGE  
Notifies objects of changes in a spline's open/close state.

GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_ACTIVE_CELL_CHANGE  
Notifies objects of changes in the spreadsheet's active cell range. The 
data block passed with this list is of type 
**NotifySSheetActiveCellChanged**.

GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_EDIT_BAR_CHANGE  
Notifies objects of changes in the spreadsheet's edit bar. The data block 
passed with this list is of type **NotifySSheetEditBarChanged**.

GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_SELECTION_CHANGE  
Notifies objects of changes in the spreadsheet's selection. The data block 
passed with this list is of type **NotifySSheetSelectionChanged**.

GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_CELL_WIDTH_HEIGHT_CHANGE  
Notifies objects of changes in the spreadsheet's cell width or height. The 
data block passed with this list is of type 
**NotifySSheetCellWidthHeightChange**.

GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_DOC_ATTR_CHANGE  
Notifies objects of changes in the spreadsheet's document attributes. The 
data block passed with this list is of type 
**NotifySSheetDocAttrChange**.

GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_CELL_ATTR_CHANGE  
Notifies objects of changes in the spreadsheet's cell attributes. The data 
block passed with this list is of type **NotifySSheetCellAttrChange**.

GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_CELL_NOTES_CHANGE  
Notifies objects of changes in the notes of a cell within a spreadsheet.

GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_DATA_RANGE_CHANGE  
Notifies objects of changes in the spreadsheet's data range selection. The 
data block passed with this list is of type 
**NotifySSheetDataRangeChange**.

GAGCNLT_APP_TARGET_NOTIFY_TEXT_NAME_CHANGE  
Notifies objects of changes in a text object's names run. The data block 
passed with this list is of type **VisTextNotifyNameChange**.

GAGCNLT_FLOAT_FORMAT_CHANGE  
Notifies objects of changes in a particular float format within the float 
format controller.

GAGCNLT_DISPLAY_OBJECTS_WITH_RULERS  
A list of GenDisplay objects that have rulers.

GAGCNLT_APP_TARGET_NOTIFY_APP_CHANGE  
Notifies objects of changes in an application.

GAGCNLT_APP_TARGET_NOTIFY_LIBRARY_CHANGE  
Notifies objects of changes in a library.

GAGCNLT_APP_TARGET_NOTIFY_CARD_BACK_CHANGE  
Notifies objects that a card back has changed.

GAGCNLT_NOTIFY_FOCUS_TEXT_OBJECT  
Notifies objects that a an editable text object has a gained the focus. This 
list is used by the floating keyboard to determine when it should be 
enabled or not.

GAGCNLT_NOTIFY_TEXT_CONTEXT  
Notifies objects that a the selection or data in a focused text object has 
changed, if that text object has text contexts turned on. This list is used 
by hand-writing recognition.

GAGCNLT_NOTIFY_HELP_CONTEXT_CHANGE  
Notifies objects that a help context has changed.

GAGCNLT_FLOAT_FORMAT_INIT  
Notifies the float controller that it should re-initialize itself. This 
normally sent to the controller when the target document has changed.

GAGCNLT_ALWAYS_INTERACTABLE_WINDOWS  
This list stores windows that should always remain interactable, even if 
modal windows are on-screen. Objects on this list will get messages even 
if GenInteractions invoked by **UserDoDialog()** are on-screen. These 
objects also receive MSG_META_CHECK_IF_INTERACTABLE_OBJECT to 
allow them to specify objects under them (such as objects in the child 
blocks) that should also receive messages.

GAGCNLT_USER_DO_DIALOGS  
This list stores all dialog boxes initiated via **UserDoDialog()**.

GAGCNLT_MODAL_WIN_CHANGE  
Notifies objects that modal window changes have occurred within the 
application.

GACGNLT_APP_TARGET_NOTIFY_SPREADSHEET_NAME_CHANGE  
Notifies objects that a spreadsheet's name has changed.

GAGCNLT_CONTROLLERS_WITHIN_USER_DO_DIALOGS  
This list stores objects (usually controllers) that will appear within the 
context of **UserDoDialog()** but will not be within the same block as the 
dialog box. Objects on this list will receive 
MSG_META_CHECK_IF_INTERACTABLE_OBJECT.

GAGCNLT_FOCUS_WINDOW_KBD_STATUS  
Notifies floating keyboards when windows gain the focus on pen systems.

### 3.1.3 Application Instance Reference

    GAI_appRef, GAI_appMode, GAI_optFlags, 
    MSG_GEN_APPLICATION_SET_APP_MODE_MESSAGE, 
    MSG_GEN_APPLICATION_GET_APP_MODE_MESSAGE, 
    MSG_GEN_APPLICATION_SET_APP_INSTANCE_REFERENCE, 
    MSG_GEN_APPLICATION_GET_APP_INSTANCE_REFERENCE, 
    MSG_GEN_APPLICATION_SEND_APP_INSTANCE_REFERENCE_TO_FIELD

*GAI_appRef* stores information (within an **AppInstanceReference** 
structure) that allows a GenApplication object to be reloaded from its former 
state. This structure contains a path name, long file name, and disk handle 
of a state file as well as an additional byte of disk data. The system 
automatically manages this state file and this instance field.

*GAI_appMode* stores the application message that should be sent to the 
process to bring this application back from a saved state. This is initially null 
(unless previously saved to a state file); it is set by **GenProcessClass** when 
a mode is determined at MSG_META_ATTACH time. You should not alter this 
instance field.

*GAI_optFlags* stores miscellaneous optimization flags. The only flag at this 
time-AOF_MULTIPLE_INIT_FILE_CATEGORIES-indicates that within this 
application there may be several different init file categories (marked with 
ATTR_GEN_INIT_FILE_CATEGORY). This allows 
MSG_META_GET_INI_CATEGORY to perform a full upward recursive search 
to find the appropriate init file category; by default, if an init file category is 
not found on an object, only the GenApplication object is queried.

----------
#### MSG_GEN_APPLICATION_SET_APP_MODE_MESSAGE

    void    MSG_GEN_APPLICATION_SET_APP_MODE_MESSAGE(
            Message modeMessage);

This message stores a message into the GenApplication's *GAI_appMode* field. 
Generally, this message indicates the current mode of the application. Should 
the application be shut down and restored, this message will be sent to the 
Process object to restore the state to the same mode.

**Source:** Rarely used.

**Destination:** Any GenApplication object.

**Parameters:**  
*modeMessage* - The message number to be stored in *GAI_appMode*.

**Return:** Nothing.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_GET_APP_MODE_MESSAGE

    Message MSG_GEN_APPLICATION_GET_APP_MODE_MESSAGE();

This message returns the message number stored in the GenApplication's 
*GAI_appMode* field.

**Source:** Rarely used.

**Destination:** Any GenApplication object.

**Parameters:** None.

**Return:** The message number stored in *GAI_appMode*.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_SET_APP_INSTANCE_REFERENCE

    void    MSG_GEN_APPLICATION_SET_APP_INSTANCE_REFERENCE(
            Handle  appInstance);

This message sets the *GAI_appRef* field to the passed structure.

**Source:** Rarely used.

**Destination:** Any GenApplication object.

**Parameters:**  
*appInstance* - The handle of the reference data block.

**Return:** Nothing.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_GET_APP_INSTANCE_REFERENCE

    Handle  MSG_GEN_APPLICATION_GET_APP_INSTANCE_REFERENCE();

This message retrieves the values in *GAI_appRef*.

**Source:** Rarely used.

**Destination:** Any GenApplication object.

**Parameters:** None.

**Return:** The handle of the reference stored in *GAI_appRef*.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_SEND_APP_INSTANCE_REFERENCE_TO_FIELD

    void  MSG_GEN_APPLICATION_SEND_APP_INSTANCE_REFERENCE_TO_FIELD();

This message causes the GenApplication to send the contents of its 
*GAI_appRef* field off to its parent GenField object.

**Source:** Rarely used.

**Destination:** Any GenApplication object.

**Interception:** Do not intercept.

### 3.1.4 Attach and Launch Flags

    GAI_launchFlags, GAI_attachFlags, 
    MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS, 
    MSG_GEN_APPLICATION_GET_ATTACH_FLAGS

*GAI_launchFlags* stores flags that are passed when the application is first 
launched. These flags are never set within your object declaration but may 
be passed with other messages. 

ALF_SEND_LAUNCH_REQUEST_TO_UI_TO_HANDLE  
If this bit is set, the application will not immediately be 
launched but will instead wait for the UI to launch it. This flag 
should not be set by the application itself; it is only used by 
**UserLoadApplication()**.

ALF_OPEN_IN_BACK  
If this bit is set, the application will be opened behind other 
applications, in an inactive state. This flag is only used with 
MSG_GEN_PROCESS_OPEN_APPLICATION.  

ALF_DESK_ACCESSORY  
If this bit is set, the application will be treated as a "desk 
accessory," in a layer above normal applications.

ALF_DO_NOT_OPEN_ON_TOP  
If this bit is set, the application will be prevented from both 
gaining the focus and opening on top of other applications.

ALF_OVERRIDE_MULTIPLE_INSTANCE  
If this bit is set, and UILM_MULTIPLE_INSTANCES is also set 
as the application's **UILaunchModel**, the application will not 
query the user if he or she attempts to initiate multiple 
instances of the same application; the application will be 
multiply launched without first checking whether the already 
running application should be used instead.

ALF_OPEN_FOR_IACP_ONLY  
If this bit is set, the application will be opened only to facilitate 
a connection with **IACPConnect()**; the application should 
close once that task is completed. If the application should 
remain open after such an IACP connection, this bit should be 
cleared. This behavior is used only for 
MSG_GEN_PROCESS_OPEN_APPLICATION connections. The 
application cannot be opened in engine mode.

*GAI_attachFlags* stores flags related to an application attaching from a state 
file. These flags are never set within your object declaration but may be 
passed with other messages.

AAF_RESTORING_FROM_STATE  
If this bit is set, the application was launched via 
MSG_GEN_PROCESS_RESTORE_FROM_STATE. 
AAF_STATE_FILE_PASSED will also be set. 

AAF_STATE_FILE_PASSED  
If this bit is set, the application is being restored from a state 
file.

AAF_DATA_FILE_PASSED  
If this bit is set, a data file containing much of the instance data 
of the application (of type **AppLaunchBlock**) is being passed 
to the launching message. This is internal and should not be 
used.

AAF_RESTORING_FROM_QUIT  
If this bit is set, the application was in the process of quitting, 
reached engine mode, and is now being started up into 
application mode again before completely exiting. If set, then 
AAF_RESTORING_FROM_STATE will also be set. This bit 
ensures that certain clean-up operations that are done before 
an application is quit are un-done, and that the application 
returns to its former state.

----------
#### MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS

    AppLaunchFlags MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS();

This message retrieves the contents of the GenApplication's 
*GAI_launchFlags* field.

**Source:** Rarely used.

**Destination:** Any GenApplication object.

**Parameters:** None.

**Return:** The AppLaunchFlags record stored in *GAI_launchFlags*.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_GET_ATTACH_FLAGS

    AppAttachFlags MSG_GEN_APPLICATION_GET_ATTACH_FLAGS();

This message retrieves the contents of the GenApplication's *GAI_attachFlags* 
field.

**Source:** Rarely used.

**Destination:** Any GenApplication object.

**Parameters:** None.

**Return:** The **AppAttachFlags** stored in *GAI_attachFlags*.

**Interception:** Do not intercept.

### 3.1.5 ApplicationStates

    GAI_states, MSG_GEN_APPLICATION_GET_STATE, 
    MSG_GEN_APPLICATION_SET_STATE, 
    MSG_GEN_APPLICATION_SET_NOT_USER_INTERACTABLE, 
    MSG_GEN_APPLICATION_SET_USER_INTERACTABLE, 
    MSG_GEN_APPLICATION_SET_NOT_QUITTING, 
    MSG_GEN_APPLICATION_SET_ATTACHED_TO_STATE_FILE, 
    MSG_GEN_APPLICATION_SET_NOT_ATTACHED_TO_STATE_FILE

*GAI_states* stores the **ApplicationStates** of the application. By default, a 
GenApplication is both AS_FOCUSABLE and AS_MODELABLE, therefore 
enabling those hierarchies for this application. Only under extremely rare 
conditions will you alter this behavior. The flags of **ApplicationStates** are 
listed below:

AS_HAS_FULL_SCREEN_EXCL  
This bit is set if the application is currently the top screen 
object at its level. This bit may only be set if the application is 
between receiving a 
MSG_META_GAINED_FULL_SCREEN_EXCL and a 
MSG_META_LOST_FULL_SCREEN_EXCL.

AS_SINGLE_INSTANCE  
This bit is set if the application is not capable of being launched 
multiple times. You should not need to set this unless 

AS_QUIT_DETACHING  
If this bit is set, the detach sequence has been initiated as the 
result of a QUIT. This bit will only be set if AS_QUITTING is also 
set; the bit is set in the UI thread at the same time 
MSG_META_DETACH is sent to the process. Therefore, this bit 
represents an intermediate step between AS_QUITTING and 
AS_DETACHING.

AS_AVOID_TRANSPARENT_DETACH  
This bit is set if the application should not be transparently 
detached. If the application is running within 
UILM_TRANSPARENT mode, then the application will not 
detach when another application is launched.

AS_TRANSPARENT_DETACHING  
This bit is set if the application is being transparently 
detached. An application can be transparently detached if 
another application is started in this application's field and 
that field is marked UILM_TRANSPARENT.

AS_REAL_DETACHING  
This bit is set if MSG_GEN_PROCESS_REAL_DETACH has been 
sent to the process, signalling the irreversible demise of the 
application. This bit is only set if the UI has finished detaching 
and the GS_USABLE bit on the application has been cleared.

AS_QUITTING  
The application is currently quitting.

AS_DETACHING  
The application object has received MSG_META_DETACH and is 
detaching.

AS_FOCUSABLE  
The application may receive the focus exclusive from its field 
parent. When launched, if this flag is set, the application 
automatically grabs the focus. This flag is set by default. 

AS_MODELABLE  
The application may receive the model exclusive from its field 
parent. When launched, if this flag is set, the application will 
automatically grab the model exclusive. This flag is set by 
default.

AS_NOT_USER_INTERACTABLE  
The application should not be interactable with the user. This 
prevents the user from navigating to non-visible applications 
or otherwise selecting the application.

AS_RECEIVED_APP_OBJECT_DETACH  
The application has received a detach message.

AS_ATTACHED_TO_STATE_FILE  
The application is currently attached to a state file.

AS_ATTACHING  
The application is currently attaching (processing 
MSG_META_ATTACH).

----------
#### MSG_GEN_APPLICATION_GET_STATE

    ApplicationStates MSG_GEN_APPLICATION_GET_STATE();

This message retrieves the current application state, stored in *GAI_states*.

**Source:** Rarely used.

**Destination:** Any GenApplication object.

**Parameters:** None.

**Return:** The **ApplicationStates** record stored in *GAI_states*.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_SET_STATE

    void    MSG_GEN_APPLICATION_SET_STATE(
            ApplicationStates           set,
            ApplicationStates           clear);

This message alters a GenApplication's *GAI_states* flags. This message 
should only be used to set flags that aren't set internally by the UI. Flags that 
can be altered are the AS_FOCUSABLE, AS_MODELABLE, 
AS_NOT_USER_DETACHABLE and AS_AVOID_TRANSPARENT_DETACH state 
bits.

This message does not reject attempts to set internal bits; therefore, be 
careful in using this message and only use it to set the external bits 
mentioned above.

**Source:** Unrestricted. This message is also used internally.

**Destination:** Any GenApplication object.

**Parameters:**  
*set* - **ApplicationStates** to set.

*clear* - **ApplicationStates** to clear.

**Return:** Nothing.

**Warnings:** Do not attempt to set any internal **ApplicationStates** bits with this 
message.

**Interception:** May intercept, but must pass to superclass at some point.

----------
#### MSG_GEN_APPLICATION_SET_NOT_QUITTING

    void    MSG_GEN_APPLICATION_SET_NOT_QUITTING();

This message clears the AS_QUITTING bit in the application's *GAI_states* 
bitfield.

**Source:** Sent by the UI or the kernel.

**Destination:** A GenApplication object.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_SET_NOT_USER_INTERACTABLE

    void    MSG_GEN_APPLICATION_SET_NOT_USER_INTERACTABLE();

This message sets the AS_NOT_USER_INTERACTABLE flag in the 
application's *GAI_states* field.

**Source:** Infrequently used.

**Destination:** The GenApplication to be made not interactable.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_SET_USER_INTERACTABLE

    void    MSG_GEN_APPLICATION_SET_USER_INTERACTABLE();

This message clears the AS_NOT_USER_INTERACTABLE flag in the 
application's *GAI_states* field.

**Source:** Infrequently used.

**Destination:** The GenApplication to be made interactable.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_SET_ATTACHED_TO_STATE_FILE

    void    MSG_GEN_APPLICATION_SET_ATTACHED_TO_STATE_FILE();

This message sets the AS_ATTACHED_TO_STATE_FILE in the 
GenApplication's *GAI_states* field.

**Source:** Sent by the UI or the kernel.

**Destination:** The GenApplication object that has been attached to a state file.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_SET_NOT_ATTACHED_TO_STATE_FILE

    void    MSG_GEN_APPLICATION_SET_NOT_ATTACHED_TO_STATE_FILE();

This message clears the AS_ATTACHED_TO_STATE_FILE in the 
GenApplication's *GAI_states* field.

**Source:** Sent by the UI or the kernel.

**Destination:** The GenApplication object that has been detached to a state file.

**Interception:** Do not intercept.

### 3.1.6 Application Features and Levels

    GAI_appFeatures, GAI_appLevel, 
    MSG_GEN_APPLICATION_GET_APP_FEATURES, 
    MSG_GEN_APPLICATION_SET_APP_FEATURES, 
    MSG_GEN_APPLICATION_SET_APP_LEVEL, 
    MSG_GEN_APPLICATION_UPDATE_APP_FEATURES, 
    MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE, 
    GenAppUsabilityTupleFlags, GenAppUsabilityTuple, 
    GenAppUsabilityCommands

A GenApplication may store a word of features (*GAI_appFeatures*); these 
features correspond to groups of UI objects. Depending on a certain feature 
being set or not set, certain groups of UI objects may or may not appear, 
allowing you to customize your application for different users or criteria. It is 
up to your application to define both the features and the objects that these 
features correspond to.

 *GAI_appFeatures* is a word-length bitfield. Each bit corresponds to a certain 
group of features which you define. You may thus have up to 16 different 
feature groups for any application. (Note that each feature group may 
include several UI objects.) In general, you group these features together so 
that they correspond to a specific **UIInterfaceLevel**. If the application 
appears at a different User Interface level, the makeup of the UI will be 
different.

An application's user interface level is stored in the GenApplication's 
*GAI_appLevel* instance data entry. Each **UIInterfaceLevel** corresponds to a 
certain group of features. Changing the UI level changes the group of 
features that may be displayed.

The features represented in the bitfield may be represented in hints added to 
GenControl objects. Most often, the controllers and the application will 
adjust their menus, tools, and other UI gadgetry to conform to the features 
specified in this record. 

----------
**Code Display 3-5 Setting Up Features**

    /* Features are stored in a word-length bitfield. */

    typedef WordFlags MyFeatures;

    @define MF_EDIT_FEATURES                (0x8000)
    @define MF_PASTE_FEATURES               (0x4000)
    @define MF_FORMAT_FEATURES              (0x2000)

    /* We might want to group certain features together based on the level of 
     * expertise of the user. In this example, if the user level is "intermediate" 
     * (which we will define later), we allow features for editing and pasting to the 
     * UI. If the user level is "advanced" we allow the intermediate features and also 
     * allow formatting features. */

    @define INTRODUCTORY_FEATURES   (0)

    @define INTERMEDIATE_FEATURES   (@MF_EDIT_FEATURES | @MF_PASTE_FEATURES)

    @define ADVANCED_FEATURES       (@INTERMEDIATE_FEATURES | @MF_FORMAT_FEATURES)

----------

MSG_GEN_APPLICATION_GET_APP_FEATURES returns the current 
application features and **UIInterfaceLevel** in use by an application. 

You may set the application's *GAI_appFeatures* by sending it 
MSG_GEN_APPLICATION_SET_APP_FEATURES. You may also change the 
application's user level by sending it 
MSG_GEN_APPLICATION_SET_APP_LEVEL. Each of these messages in turn 
generates a MSG_GEN_APPLICATION_UPDATE_APP_FEATURES. 

This message is meant to be sub-classed so that you can alter the behavior 
for different features. In most cases, however, you will simply handle this 
message, fill in relevant parameters, and send the GenApplication 
MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE - the message 
which performs the actual work done in changing the UI. This message 
expects a number of arguments. 

The most important argument is the table of **GenAppUsabilityTuple** 
entries that correspond to each feature. These entries define what sort of UI 
change is required, and what object is required to change.You must set up 
this table beforehand.

The types of usability commands available (in the bit positions set aside with 
GAUTF_COMMAND in the tuple's **GenAppUsabilityTupleFlags**) are:

+ GAUC_USABILITY  
If set, the object should be made GS_USABLE if the feature is on. This is 
the default behavior.

+ GAUC_RECALC_CONTROLLER  
If set, the controller needs to have its features recalculated. The 
particular feature bits are stored with the controller itself; the 
application knows nothing more about the controller's features other 
than that they need to be changed.

+ GAUC_REPARENT  
If set, the object needs to be relocated to another part of the UI, 
underneath a different parent. This parent is passed in the 
*reparentObject* entry for 
MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE. Only one 
object may be re-parented for each application.

+ GAUC_POPUP  
If set, the object should be made a popup menu. Note that this allows a 
sub-group to become a menu without having to use GAUC_REPARENT.

+ GAUC_TOOLBAR  
If set, the object is a GenBoolean that corresponds to a toolbar state. 
Turning the feature on or off forces the GenBoolean to send an apply in 
addition to other behavior.

+ GAUC_RESTART  
If set, the object needs to be "kick started" by first setting it 
GS_NOT_USABLE and then GS_USABLE.

Because each feature may have multiple objects affected, the 
**GenAppUsabilityTupleFlags** entry GAUTF_END_OF_LIST indicates that 
there are no more commands for that feature. The flag 
GAUTF_OFF_IF_BIT_IS_ON indicates that a given command should be 
reversed for the object. (I.e. if the feature is on, the object should be removed, 
not added.)

----------
**Code Display 3-6 Setting Up the GenAppUsabilityTuple Tables**

    /* Each GenAppUsabilityTuple will refer to a specific set of features. */

    /* 
     * Since GUAC_USABILITY is the default setting (and is zero) setting any other 
     * flags either supersedes or complements this behavior. In this case, setting the 
     * EditToolEntry as a GUAC_TOOLBAR command supersedes the GUAC_USABILITY command. 
     * Setting the GUATF_END_OF_LIST flag for the EditTrigger does not alter the 
     * GUAC_USABILITY command, which is still implicit.
     */

    static const GenAppUsabilityTuple editFeaturesList [] =
    {
            {GUAC_TOOLBAR,          @EditToolEntry      },
            {GUATF_END_OF_LIST      @EditTrigger        }
    };

    static const GenAppUsabilityTuple pasteFeaturesList [] =
    {
            {GUAC_END_OF_LIST,      @PasteTrigger       }
    };

    static const GenAppUsabilityTuple formatFeaturesList [] =
    {
            {
            GAUTF_END_OF_LIST | GUAC_RECALC_CONTROLLER,
            @FeatureController
            }
    };

    /* After each feature's GenAppUsabilityTuple is set up, you should set up a table 
     * of these structures to pass to relevant messages. */

    static const GenAppUsabilityTuple * const usabilityTable [] =
    {
            editFeaturesList,
            pasteFeaturesList,
            formatFeaturesList
    };

    /* 
     * Within your code, decide where you wish to set the application features 
     * (usually within some sort of User level dialog box that passes a selection of 
     * feature bits) and send either MSG_GEN_APPLICATION_SET_APP_FEATURES or
     * MSG_GEN_APPLICATION_SET_APP_LEVEL with the proper feature bits set.
     */

    @method MyLevelApplicationClass, MSG_MY_APPLICATION_SET_USER_LEVEL
    {
        @call oself::MSG_GEN_APPLICATION_SET_APP_FEATURES(selection);
    }

    /* 
     * Then intercept MSG_GEN_APPLICATION_UPDATE_APP_FEATURES and set up the correct 
     * parameters for MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE. 
     */

    @method MyLevelApplicationClass, MSG_GEN_APPLICATION_UPDATE_APP_FEATURES
    {
        @call oself::MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE(
            NullOptr,
            @ObjectToReparent,      /* if any */
            levelTable,             /* if any */
            sizeof(usabilityTable) / sizeof(usabilityTable [0]),
            usabilityTable,
            appOpeningFlag,
            oldLevel,
            level,
            featuresChanged,
            featuresOn);
    }

----------
#### MSG_GEN_APPLICATION_GET_APP_FEATURES

    dword   MSG_GEN_APPLICATION_GET_APP_FEATURES();

This message retrieves the set of features set for the application.

**Source:** Unrestricted-typically a GenControl object finding out the 
application's UI level.

**Destination:** The GenApplication running the controller.

**Parameters:** None.

**Return:** A dword containing the word of features stored in *GAI_appFeatures* 
and the **UIInterfaceLevel** for the application. The features are stored 
in the high word; the interface level is stored in the low word.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_APPLICATION_SET_APP_FEATURES

    void    MSG_GEN_APPLICATION_SET_APP_FEATURES(
            word    features);

This message sets a new set of features into the GenApplication's 
*GAI_appFeatures* record. This message in turn generates a 
MSG_GEN_APPLICATION_UPDATE_APP_FEATURES for your application 
object to intercept. (The message handler for that message must in turn send 
MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE to activate the UI 
changes specified in the features list.)

**Source:** Unrestricted-typically a system function.

**Destination:** The GenApplication having its features set.

**Parameters:**  
*features* - The new word-sized record of application features 
to set.

**Return:** Nothing.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_APPLICATION_UPDATE_APP_FEATURES

    void    MSG_GEN_APPLICATION_UPDATE_APP_FEATURES(@stack
            optr                    unReparentObject,
            optr                    reparentObject,
            GenAppUsabilityTuple    *levelTable,
            word                    tableLength,
            void                    *table,
            word                    appOpeningFlag,
            UIInterfaceLevel        oldLevel,
            UIInterfaceLevel        level,
            word                    featuresChanged,
            word                    featuresOn);

This message is sent by the application to itself when it is told to change 
either its features or its **UIInterfacelevel**. This message is passed a number 
of parameters, most of which should simply be passed to 
MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE. If you have 
reparent objects (or un-reparent objects), you must set them up here.

**Source:** Sent by an application object to itself in response to a 
MSG_GEN_APPLICATION_SET_APP_FEATURES or 
MSG_GEN_APPLICATION_SET_APP_LEVEL.

**Destination:** The GenApplication object.

**Parameters:**  
*unReparentObject* - The optr of the object to be unreparented. If a null 
optr is passed, the object will by default be moved 
up and added as the next sibling of its current 
parent.

*reparentObject* - The optr of the object to be reparented to another 
UI location. You must supply this object if you have 
a **GenAppUsabilityTuple** entry that contains a 
GAUC_REPARENT entry.

*levelTable* - This table contains the GenAppUsabilityTuples 
corresponding to objects that contain their own 
features and that must be notified when the user 
level changes. This is so that those objects can 
generate their own feature updates. Typically, 
controllers are included among these objects.

*tableLength* - The number of table entries in table.

*table* - Table of **GenAppUsabilityTuple** entries that 
must be updated when the user level changes. This 
table is usually set up as global data and maps each 
user level feature to a **GenAppUsabilityTuple**.

*appOpeningFlag* - Set if the application is starting.

*oldLevel* - The previous **UIInterfaceLevel**.

*level* - The new *UIInterfaceLevel*.

*featuresChanged* - The set of features changed (deleted).

*featuresOn* - The set of features to set on.

**Interception:** To set an application's features, you must intercept this message and 
send MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE; there 
is no default message handler. This message is provided as a 
convenient point to intercept and change features before executing the 
changes.

----------
#### MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE

    void    MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE(
            optr                    unReparentObject,
            optr                    reparentObject,
            GenAppUsabilityTuple    *levelTable,
            word                    tableLength,
            void                    *table,
            word                    appOpeningFlag,
            UIInterfaceLevel        oldLevel,
            UIInterfaceLevel        level,
            word                    featuresChanged,
            word                    featuresOn);

This message is called to update the application's features to reflect a new set 
of features to 

**Source:** Typically, your message handler for 
MSG_GEN_APPLICATION_UPDATE_APP_FEATURES.

**Destination:** The GenApplication object.

**Parameters:**  
*unReparentObject* - The optr of the object to be unreparented. If a null 
optr is passed, the object will by default be moved 
up and added as the next sibling of its current 
parent.

*reparentObject* - The optr of the object to be reparented to another 
UI location. You must supply this object if you have 
a **GenAppUsabilityTuple** entry that contains a 
GAUC_REPARENT entry.

*levelTable* - This table contains the GenAppUsabilityTuples 
corresponding to objects that contain their *own* 
features and that must be notified when the user 
level changes. This is so that those objects can 
generate their own feature updates. Typically, 
controllers are included among these objects.

*tableLength* - The number of table entries in table.

*table* - Table of **GenAppUsabilityTuple** entries that 
must be updated when the user level changes. This 
table is usually set up as global data and maps each 
user level feature to a **GenAppUsabilityTuple**.

*appOpeningFlag* - Set if the application is starting.

*oldLevel* - The previous **UIInterfaceLevel**.

*level* - The new **UIInterfaceLevel**.

*featuresChanged* - The set of features changed (deleted).

*featuresOn* - The set of features to set on.

**Interception:** Generally not intercepted. Intercept 
MSG_GEN_APPLICATION_UPDATE_APP_FEATURES instead.

### 3.1.7 IACP

    GAI_iacpConnects, MSG_GEN_APPLICATION_IACP_REGISTER, 
    MSG_GEN_APPLICATION_IACP_UNREGISTER, 
    MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_CONNECTIONS, 
    MSG_GEN_APPLICATION_IACP_
    GET_NUMBER_OF_APP_MODE_CONNECTIONS, 
    MSG_GEN_APPLICATION_IACP_SHUTDOWN_ALL_CONNECTIONS, 
    MSG_GEN_APPLICATION_IACP_COMPLETE_CONNECTIONS, 
    MSG_GEN_APPLICATION_APP_MODE_COMPLETE

IACP (the GEOS *I*nter *A*pplication *C*ommunication *P*rotocol) allows 
applications to communicate with each other. IACP is flexible enough to let 
applications know whether another application is open, closed, or in the 
process of attaching or detaching. IACP allows applications to convey 
information to one another, and could be used to support updating data (e.g. 
documents) across applications. The IACP mechanism is discussed more fully 
in "Applications and Geodes," Chapter 6 of the Concepts Book. The 
information included below only discusses **GenApplicationClass** support of 
IACP mechanisms.

*GAI_iacpConnects* stores the chunk handle to an array of active IACP 
connections. This chunk stores the IACP connection value referring to the 
remote application and the type of IACP connection (i.e. a connection that is 
enabled during a MSG_GEN_PROCESS_OPEN_APPLICATION, for example). 
These values are manipulated internally and there is no need to access them. 
You will instead use a variety of messages provided with 
**GenApplicationClass** to register and unregister for application 
notification.

A good deal of support has been added to **GenApplicationClass** to support 
IACP. The main things you need to know about this support are:

+ A GenApplication object will refuse to quit so long as there are IACP 
connections open to it. It can, however, be forcibly detached, as happens 
when the system shuts down. In such a case, it will call 
**IACPShutdownAll()** to shut down all remaining connections either to 
or from it.

+ When it receives MSG_META_IACP_LOST_CONNECTION sent to it as a 
server, it will eventually call **IACPShutdown()** for the connection when 
it is certain no more messages relating to the connection are in any 
relevant queue. It will forward this message to all GenDocument objects 
below any GenDocumentGroup object in the application, so they can 
close themselves if the lost connection was the last reference to them.

+ It will automatically register itself as a server for the application's token, 
either when it receives MSG_META_APP_STARTUP if the 
**AppLaunchBlock** indicates it's running in engine mode, or when it 
receives MSG_META_ATTACH and has attached all the various pieces of 
UI. It will unregister itself as a server when it loses its last IACP 
connection and is no longer functioning in application mode (either 
because the user quit the application long since, or because it was never 
functioning in application mode).

+ It registers and unregisters itself by sending 
MSG_GEN_APPLICATION_IACP_REGISTER and 
MSG_GEN_APPLICATION_IACP_UNREGISTER to itself, allowing an 
application to subclass these messages and register with other lists as 
appropriate.

+ To determine whether it has any IACP connections remaining, it invokes 
MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_CONNECTIONS on 
itself. Should an application register the GenApplication or any other 
object as a server for another list, it can determine how many connections 
remain from that list and augment the number returned by the default 
handler in **GenApplicationClass**. If this returns non-zero, 
GenApplication will not shut down the application voluntarily.

+ After unregistering, it will force-queue a message to itself that will check 
the number of connections again. If the number has become non-zero 
between the unregister and the check, it re-registers and does not shut 
down. If the number remains zero, however, the application will exit.

+ When forcibly detached, it will send 
MSG_GEN_APPLICATION_IACP_SHUTDOWN_ALL_CONNECTIONS to 
itself. The default handler will call **IACPShutdownAll()**, passing its 
own optr. A subclass can use this to perform a similar operation for any 
other server objects the application might have.

----------
#### MSG_GEN_APPLICATION_IACP_REGISTER

    void    MSG_GEN_APPLICATION_IACP_REGISTER();

This message is sent by a GenApplication object to itself when it registers for 
IACP. It is not a message meant to be sent externally to an application to 
register it for IACP. Instead, you can subclass this message and register the 
object with other lists.

**Source:** Sent by the GenApplication object to itself.

**Destination:** The GenApplication object to register with IACP.

**Interception:** May be intercepted if there are other lists with which you want to 
register the application, or other server objects. You must make sure to 
call the superclass, however.

----------
#### MSG_GEN_APPLICATION_IACP_UNREGISTER

    void    MSG_GEN_APPLICATION_IACP_UNREGISTER();

This message is sent by a GenApplication object to itself when it unregisters 
for IACP. It is not a message meant to be sent externally to an application to 
unregister it for IACP. Instead, you can subclass this message and unregister 
the object with other lists.

**Source:** Sent by the GenApplication object to itself.

**Destination:** The GenApplication object to unregister with IACP.

**Interception:** May be intercepted if there are other lists with which you need to 
unregister the application, or other server objects. You must make sure 
to call the superclass, however.

----------
#### MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_CONNECTIONS

    word    MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_CONNECTIONS();

This message returns the number of active engine or app-mode IACP 
connections for a given application. This message is used to check whether 
an application open only for IACP purposes may be closed.

**Source:** Called by GenProcessClass when the UI has finished processing 
MSG_META_QUIT for the application; this determines if the 
application should exit at this point or if there are client applications 
that need the application to stay open.

**Destination:** GenApplication object of the application.

**Return:** Number of open connections. If non-zero, application will remain open.

**Interception:** Only intercept if you have other server objects beside your 
GenApplication object. If intercepting, call the superclass first and 
then add the number of connections to the other objects onto the result 
returned by **GenApplicationClass**.

----------
#### MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_APP_MODE_CONNECTIONS

    void  MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_APP_MODE_CONNECTIONS();

This message retrieves the number of connections which require that the 
application be open in app-mode (as opposed to engine mode). This message 
is used to check whether an application can be closed down into engine mode 
even if some IACP connections are still open.

**Source:** This message is called by the **GenProcessClass** when the UI has 
finished processing MSG_META_QUIT to determine if the application 
should really close down to engine mode.

**Destination:** GenApplication object of application.

**Interception:** Only intercept if you have other server objects besides your 
GenApplication object. You should call the superclass first and then 
add the number of connections to other objects onto the result returned 
by **GenApplicationClass**.

----------
#### MSG_GEN_APPLICATION_IACP_SHUTDOWN_ALL_CONNECTIONS

    void    MSG_GEN_APPLICATION_IACP_SHUTDOWN_ALL_CONNECTIONS();

This message shuts down all IACP connections for a given application, either 
on the server or the client side of the connection.

**Source:** Sent by the GenApplication object to itself.

**Destination:** GenApplication object of the application.

**Interception:** May be intercepted to allow connections to other server objects to be 
shut down. You must call the superclass at some point to ensure that 
application connections are shut down as well.

----------
#### MSG_GEN_APPLICATION_APP_MODE_COMPLETE

    void    MSG_GEN_APPLICATION_APP_MODE_COMPLETE();

This message is sent to the application when its life as a user-interactable 
app is complete. The default behavior is to continue shutting down the 
process if there are no IACP connections active.

**Source:** Sent by the GenProcess object after it receives a MSG_META_ACK from 
detaching the application.

**Destination:** GenApplication object.

**Interception:** Generally not intercepted; If you have other server connections which 
you want taken into account before shutting the application completely 
down, you should intercept 
MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_CONNECTIONS 
instead.

----------
#### MSG_GEN_APPLICATION_IACP_COMPLETE_CONNECTIONS

    void    MSG_GEN_APPLICATION_IACP_COMPLETE_CONNECTIONS();

This message completes all pending IACP connections, accepting any queued 
messages that have been waiting to be handled. If you subclass it, be sure to 
call the superclass at some point.

**Source:** Sent by the GenApplication object to itself in its default 
MSG_GEN_APPLICATION_OPEN_COMPLETE method, as we assume 
that the object should be able to handle IACP messages at this latter 
stage of opening the IACP mechanism.

**Destination:** GenApplication object of the application.

**Interception:** May be intercepted if there are other lists besides those connected to 
the application's token, if those other connections might be pending. If 
intercepting, you must call the superclass eventually.

## 3.2 Advanced GenApplication Usage

Typically, you will merely set up a GenApplication object in your .goc file and 
then leave it alone. You may occasionally send it messages to invoke 
functions or to query the application. These messages are infrequently used, 
however, and you will likely not have need for them.

### 3.2.1 An Application's Life Cycle

For information on how an application is launched and closed, see 
"Applications and Geodes," Chapter 6 of the Concepts Book.

### 3.2.2 Application Busy States

    MSG_GEN_APPLICATION_MARK_BUSY, 
    MSG_GEN_APPLICATION_MARK_NOT_BUSY, 
    MSG_GEN_APPLICATION_HOLD_UP_INPUT, 
    MSG_GEN_APPLICATION_RESUME_INPUT, 
    MSG_GEN_APPLICATION_IGNORE_INPUT, 
    MSG_GEN_APPLICATION_ACCEPT_INPUT, 
    MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY, 
    MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY

An application's busy state is reflected by its cursor. An application may have 
several busy states, set appropriately for the action going on at the time. The 
messages below can set the application's busy state. You will not usually send 
any of these messages to your GenApplication object. Instead, you will 
usually set appropriate *GI_attrs* to automatically send out these messages 
during times when the application will be busy.

MSG_GEN_APPLICATION_MARK_BUSY marks the application busy (usually 
by changing the cursor to an appropriate shape determined by the specific UI) 
until the current operation in the application thread completes. This 
message is sent by UI gadgets that have GA_INITIATES_BUSY_STATE set in 
their *GI_attrs* fields. It may also be called by any other object that wants to 
mark the application busy. When an application is busy, the user may 
continue to interact with it.

MSG_GEN_APPLICATION_MARK_NOT_BUSY removes the busy state marker. 
This message is automatically sent to the application object when the 
operation that initiated the busy state completes.

MSG_GEN_APPLICATION_HOLD_UP_INPUT instructs the User Interface to 
place all input events into a special "hold-up" queue until the input is 
resumed. This message also marks the application busy. Applications 
marked GA_INITIATES_INPUT_HOLD_UP will receive this message whenever 
they initiate an operation.

MSG_GEN_APPLICATION_RESUME_INPUT removes the input hold-up state, 
allowing normal input flow. This message flushes the "hold-up" event queue 
into the application's input queue, ensuring that all events during the "hold 
up" operation are handled before any new events.

MSG_GEN_APPLICATION_IGNORE_INPUT instructs the GenApplication 
object to ignore all input events it receives. This may be accompanied with an 
audible warning (beep). Applications marked 
GA_INITIATES_INPUT_IGNORE will receive this message whenever they 
initiate an operation.

MSG_GEN_APPLICATION_ACCEPT_INPUT removes the input ignore state 
and directs the GenApplication object to again receive input events and 
handle them.

All of these messages are cumulative. The application will keep track of how 
many times each of these messages is sent. For example, each 
MSG_GEN_APPLICATION_MARK_NOT_BUSY message will remove a 
MSG_GEN_APPLICATION_MARK_BUSY. When the count reaches zero, the 
busy state is removed.

----------
#### MSG_GEN_APPLICATION_MARK_BUSY

    void    MSG_GEN_APPLICATION_MARK_BUSY();

This message marks the application busy and changes the cursor image.

**Source:** Sent automatically by objects with GA_INITIATES_BUSY_STATE set.

**Destination:** The GenApplication object running the sender.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_MARK_NOT_BUSY

    void    MSG_GEN_APPLICATION_MARK_NOT_BUSY();

This message marks the application not busy, removing the effect of a 
previous MSG_GEN_APPLICATION_MARK_BUSY.

**Source:** Sent automatically by objects with GA_INITIATES_BUSY_STATE set.

**Destination:** The GenApplication object running the sender.

**Interception:** Do not intercept.

----------

#### MSG_GEN_APPLICATION_HOLD_UP_INPUT

    void    MSG_GEN_APPLICATION_HOLD_UP_INPUT();

This message causes the GenApplication to mark itself busy and redirect 
input events to a special "hold-up" queue. When the application is ready to 
resume normal activity, it first handles the messages in the hold-up queue 
before handling new input messages.

**Source:** Used infrequently.

**Destination:** The GenApplication object to be held up.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_RESUME_INPUT

    void    MSG_GEN_APPLICATION_RESUME_INPUT();

This message causes a GenApplication to resume normal input handling 
after it has been held up with MSG_GEN_APPLICATION_HOLD_UP_INPUT.

**Source:** Used infrequently.

**Destination:** The GenApplication object running the sender.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_IGNORE_INPUT

    void    MSG_GEN_APPLICATION_IGNORE_INPUT();

This message causes the GenApplication to consume all input events it 
receives rather than handle them. This message may be used during 
debugging as a last resort to help find synchronization problems.

**Source:** Infrequently used.

**Destination:** The GenApplication object to consume input events.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_ACCEPT_INPUT

    void    MSG_GEN_APPLICATION_ACCEPT_INPUT();

This message undoes a previous MSG_GEN_APPLICATION_IGNORE_INPUT, 
allowing the GenApplication to once again handle input events normally.

**Source:** Infrequently used.

**Destination:** The GenApplication object to resume input handling.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY

    void    MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY();

This message is rarely used and forces a busy state over the application 
regardless of other states. It should be used only when a time-intensive task 
is going on in the UI and the program can not handle input during that time.

**Source:** Infrequently used.

**Destination:** The GenApplication object to be marked completely busy.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY

    void    MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY();

This message undoes MSG_GEN_APPLICATION_MARK_COMPLETELY_BUSY, 
allowing the application to once again handle user input.

**Source:** Infrequently used.

**Destination:** The GenApplication object to be marked not busy.

**Interception:** Do not intercept.

### 3.2.3 The GenApplication's Moniker

    MSG_GEN_APPLICATION_FIND_MONIKER, 
    MSG_GEN_APPLICATION_SET_TASK_ENTRY_MONIKER

Every GenApplication object should be given a moniker; this moniker is 
displayed by the UI in its task list. (In OSF/Motif, the task list is manifested 
as the floating "Express" menu.) While you will set the moniker just like for 
any generic object, the GenApplication has two messages that can be used to 
get or set the moniker used in the task list.

----------
#### MSG_GEN_APPLICATION_FIND_MONIKER

    optr    MSG_GEN_APPLICATION_FIND_MONIKER(
            MemHandle       destBlock,
            word            searchFlags,
            DisplayType     displayType);

This message finds the specified moniker in the GenApplication's 
**VisMonikerList** and optionally copies it into a specified destination block.

**Source:** Infrequently used.

**Destination:** The GenApplication to get the moniker from.

**Parameters:**  
*destBlock* - The handle of the destination block into which the 
chunk will be copied. For this to work, you must 
pass VMSF_COPY_CHUNK in *searchFlags*.

*searchFlags* - A record of **VisMonikerSearchFlags** indicating 
what type of moniker to find in the moniker list and 
what to do with it when it is found.

*displayType* - The display type of the moniker to search for.

**Return:** The optr of the GenApplication's **VisMonikerList** chunk.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_SET_TASK_ENTRY_MONIKER

    void    MSG_GEN_APPLICATION_SET_TASK_ENTRY_MONIKER(
            optr    entryMoniker);

This message changes the moniker which is used in the GenField's task list. 
The task list menu will be updated if currently visible.

**Source:** Infrequently used.

**Destination:** The GenApplication to have its moniker changed.

**Parameters:**  
*entryMoniker* - The optr of the chunk containing the moniker that 
will be set into the task list.

**Return:** Nothing.

**Interception:** Do not intercept.

### 3.2.4 Measurement Type

    MSG_GEN_APPLICATION_SET_MEASUREMENT_TYPE, 
    MSG_GEN_APPLICATION_GET_MEASUREMENT_TYPE, 
    GET_APP_MEASUREMENT_TYPE

Each application has a "measurement type" associated with it. The 
measurement type indicates whether measurements should default to metric 
or standard US measurements.

----------
#### MSG_GEN_APPLICATION_SET_MEASUREMENT_TYPE

    void    MSG_GEN_APPLICATION_SET_MEASUREMENT_TYPE(
            byte    measurementType);

This message sets the measurement type used by the application.

**Source:** Infrequently used.

**Destination:** The GenApplication to have the new measurement type.

**Parameters:**  
*measurementType* - A value of **AppMeasurementType** to set for the 
application. Can be AMT_US, AMT_METRIC, or 
AMT_DEFAULT.

**Return:** Nothing.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_GET_MEASUREMENT_TYPE

    word    MSG_GEN_APPLICATION_GET_MEASUREMENT_TYPE();

This message gets the measurement currently used by the application.

**Source:** Infrequently used.

**Destination:** The GenApplication whose measurement is to be retrieved.

**Parameters:** None.

**Return:** A word value, the low byte of which represents the application's 
measurement type. Use the macro GET_MEASUREMENT_TYPE to 
extract the measurement type from the return value.

**Interception:** Do not intercept.

### 3.2.5 Interaction with the UI

The GenApplication is an application's main point of contact with the UI. As 
such, it has several messages that are sent by the UI or by other objects to 
initiate certain UI-related functions. These messages will rarely, if ever, be 
used by application programmers, but they are documented here in case you 
find them useful.

#### 3.2.5.1 Attaching and Detaching

    MSG_GEN_APPLICATION_INITIATE_UI_QUIT, 
    MSG_GEN_APPLICATION_INSTALL_TOKEN, 
    MSG_GEN_APPLICATION_DETACH_PENDING, 
    MSG_GEN_APPLICATION_OPEN_COMPLETE, 
    MSG_GEN_APPLICATION_QUIT_AFTER_UI

----------
#### MSG_GEN_APPLICATION_INITIATE_UI_QUIT

    void    MSG_GEN_APPLICATION_INITIATE_UI_QUIT();

This message causes the GenApplication to begin quitting. The application 
will automatically go through the entire quit sequence.

**Source:** Infrequently used.

**Destination:** The GenApplication of the application to be shut down.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_INSTALL_TOKEN

    void    MSG_GEN_APPLICATION_INSTALL_TOKEN();

This message instructs the GenApplication object to set its token into the 
token database file.

**Source:** Infrequently used.

**Destination:** The GenApplication to have its token installed.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_DETACH_PENDING

    void    MSG_GEN_APPLICATION_DETACH_PENDING();

This message is sent to the specific UI library through the GenApplication to 
notify it that the application is about to be shut down. It is used to abort any 
application-modal dialog boxes so the application's Process object will be able 
to detach.

**Source:** The GenApplication object before it detaches.

**Destination:** The GenApplication of the application about to be detached.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_OPEN_COMPLETE

    void    MSG_GEN_APPLICATION_OPEN_COMPLETE();

This message is sent by the GenApplication object to itself when it has 
finished opening (after it has set itself usable). It is sent via the queue and 
indicates that the application's UI is fully usable.

**Source:** A GenApplication after it has set itself GS_USABLE.

**Destination:** Sent to itself.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_QUIT_AFTER_UI

    void    MSG_GEN_APPLICATION_QUIT_AFTER_UI();

This message is called from the MSG_META_QUIT handler in 
GenProcessClass, after the UI has finished its 
MSG_GEN_APPLICATION_INITIATE_UI_QUIT sequence. This message is the 
application's last chance to abort a quit before the DETACH sequence begins. 
The default behavior is to abort the QUIT if the application is still open for 
the user (i.e. not ALF_OPEN_FOR_IACP_CONNECTION_ONLY) or if an IACP 
connection remains that requires the application to remain open.

**Source:** **GenProcessClass**.

**Destination:** GenApplication object of the application.

**Interception:** May be intercepted and not sent to the superclass to abort the QUIT. 

#### 3.2.5.2 Queries of the UI

    MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME, 
    MSG_GEN_APPLICATION_QUERY_UI, 
    MSG_GEN_APPLICATION_NOTIFY_MODAL_WIN_CHANGE, 
    MSG_GEN_APPLICATION_INK_QUERY_REPLY, 
    MSG_GEN_APPLICATION_GET_GCN_LIST_OF_LISTS, 
    MSG_GEN_APPLICATION_TEST_WIN_INTERACTABILITY, 
    MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION, 
    MSG_GEN_APPLICATION_GET_MODAL_WIN, 
    MSG_GEN_APPLICATION_CHECK_IF_ALWAYS_INTERACTABLE_OBJECT

----------
#### MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME

    void    MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME(
            DisplayScheme   * displayScheme);

This message gets the current display scheme used by the application.

**Source:** Infrequently used.

**Destination:** Any GenApplication.

**Parameters:**  
*displayScheme* - A pointer to a structure of type **DisplayScheme**. 
This structure will be filled by the method and 
contains information about the color scheme, 
display type, font ID, and point size used by the 
application.

**Return:** The **DisplayScheme** structure pointed to by displayScheme will be 
filled upon return.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_QUERY_UI

    Handle  MSG_GEN_APPLICATION_QUERY_UI();

This message is used to determine which UI should be used at a given point 
in the generic tree for a certain type of object.

**Source:** Infrequently used.

**Destination:** Any GenApplication object.

**Parameters:** None.

**Return:** The handle of the specific UI library geode.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_NOTIFY_MODAL_WIN_CHANGE

    void    MSG_GEN_APPLICATION_NOTIFY_MODAL_WIN_CHANGE();

This message is called on a GenApplication object by the UI whenever the 
application should check to see if there is a change in modal status. The 
behavior is to look for the top system-modal window owned by the application 
and then the top application-modal window within the application's layer.

This message sets the AS_ATTACHED_TO_STATE_FILE in the 
GenApplication's *GAI_states* field.

**Source:** Sent by the UI.

**Destination:** Any GenApplication object.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_INK_QUERY_REPLY

    void    MSG_GEN_APPLICATION_INK_QUERY_REPLY(
            InkReturnValue      inkReturnValue,
            word                inkGstate);

This message is sent to an Application object in reply to a 
MSG_META_QUERY_IF_PRESS_IS_INK. It indicates whether the object that 
was queried can or can not handle Ink presses. The GenApplication object 
responds by sending a message to the UI.

**Source:** Sent by an object in response to MSG_META_QUERY_IF_PRESS_IS_INK.

**Destination:** The GenApplication object associated with the sender.

**Parameters:**  
*inkReturnValue* - A value indicating whether the object queried can 
handle Ink input or not. Will be one of IRV_NO_INK, 
IRV_INK_WITH_STANDARD_OVERRIDE, 
IRV_DESIRES_INK, or IRV_WAIT.

*inkGstate* - The GState, if any, to be used when drawing Ink.

**Return:** Nothing.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_GET_GCN_LIST_OF_LISTS

    ChunkHandle MSG_GEN_APPLICATION_GET_GCN_LIST_OF_LISTS();

This message retrieves the GenApplication's GCN list of lists chunk handle. 
This chunk handle may then be used with a number of kernel routines for 
GCN list management or to perform operations on individual GCN lists.

**Source:** Any object in the GenApplication's thread.

**Destination:** Any GenApplication object.

**Parameters:** None.

**Return:** The chunk handle of the GCN list of lists chunk; a null chunk handle 
will be returned if the chunk does not exist.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_TEST_WIN_INTERACTABILITY

    Boolean MSG_GEN_APPLICATION_TEST_WIN_INTERACTABILITY(
            optr    inputOD,
            Handle  window);

This message tests whether the passed window object is interactable.

**Source:** Unrestricted.

**Destination:** Any GenApplication object.

**Parameters:**  
*inputOD* - The optr of the windowed object to be tested.

*window* - The window handle of the window to be tested.

**Return:** The return value will be *false* if there are no modal windows in the 
system or if the window object passed is the topmost active modal 
window. The return value will be *true* if an active modal window exists 
and is not the passed window object (in this case, if the passed object 
has any window grabs, it should release them). *True* is also returned if 
there is no modal window but the GenApplication is ignoring input.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION

    void    MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION(
            optr        obj,
            Boolean     opening);

Notifies the GenApplication object that it has become visible or not visible.

**Source:** The specific UI.

**Destination:** The GenApplication that has become visible or not visible.

**Parameters:**  
*obj* - The optr of the object sending the notification 
message.

*opening* - A Boolean indicating the state of the object: *true* if 
open, *false* if closed.

**Return:** Nothing.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_GET_MODAL_WIN

    optr    MSG_GEN_APPLICATION_GET_MODAL_WIN();

This message returns the current top modal window for the application, if 
any is present.

**Source:** Unrestricted.

**Destination:** GenApplication object.

**Return:** optr of top modal windowed object.

----------
#### MSG_GEN_APPLICATION_CHECK_IF_ALWAYS_INTERACTABLE_OBJECT

    Boolean  MSG_GEN_APPLICATION_CHECK_IF_ALWAYS_INTERACTABLE_OBJECT(
            optr        objToCheck);

This message checks if the passed object should always remain interactable. 

**Source:** Unrestricted.

**Destination:** GenApplication object.

**Parameters:**  
*objToCheck* - optr of object to check the interactable state.

**Return:** *true* if the object is always interactable, *false* if not.

#### 3.2.5.3 Alterations of Functionality

MSG_GEN_APPLICATION_BRING_WINDOW_TO_TOP, 
MSG_GEN_APPLICATION_LOWER_WINDOW_TO_BOTTOM, 
MSG_GEN_APPLICATION_BUILD_STANDARD_DIALOG, 
MSG_GEN_APPLICATION_DO_STANDARD_DIALOG, 
MSG_GEN_APPLICATION_TOGGLE_CURSOR, 
MSG_GEN_APPLICATION_BRING_UP_HELP, 
MSG_GEN_APPLICATION_TOGGLE_CURRENT_MENU_BAR, 
MSG_GEN_APPLICATION_TOGGLE_FLOATING_KEYBOARD, 
MSG_GEN_APPLICATION_TOGGLE_EXPRESS_MENU

----------
#### MSG_GEN_APPLICATION_BRING_WINDOW_TO_TOP

    void    MSG_GEN_APPLICATION_BRING_WINDOW_TO_TOP(
            optr    window);

This message brings the passed window to the front of the screen.

**Source:** Unrestricted

**Destination:** Any GenApplication object.

**Parameters:**  
*window* - The optr of the window object to be brought to the 
front of the screen.

**Return:** Nothing.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_LOWER_WINDOW_TO_BOTTOM

    void    MSG_GEN_APPLICATION_LOWER_WINDOW_TO_BOTTOM(
            optr    window);

This message sends the specified window to the back of the screen, behind 
other window objects.

**Source:** Unrestricted.

**Destination:** Any GenApplication object.

**Parameters:**  
window - The optr of the window object to be sent to the back 
of the screen.

**Return:** Nothing.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_BUILD_STANDARD_DIALOG

    optr    MSG_GEN_APPLICATION_BUILD_STANDARD_DIALOG(
            char                * customTriggers,
            char                * arg2,
            char                * arg1,
            char                * string,
            CustomDialogBoxFlags dialogFlags);

This message builds a standard dialog box for the application.

**Source:** Infrequently used.

**Destination:** The GenApplication to use the dialog box.

**Parameters:**  
*customTriggers* - A pointer to a table of custom GenTrigger 
information. Each trigger given in the table will 
appear in the dialog box in the order declared. The 
table is made up of structures of type 
**StandardDialogResponseTriggerTable**.

*arg1* - A pointer to a character string to be displayed in 
the dialog box.

*arg2* - A pointer to a second string to be displayed in the 
dialog box.

*string* - A pointer to a custom character string to be 
displayed in the dialog box.

*dialogFlags* - A record of **CustomDialogBoxFlags** indicating 
what type of dialog box is to be created.

**Return:** The optr of the dialog box object.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_DO_STANDARD_DIALOG

    void    MSG_GEN_APPLICATION_DO_STANDARD_DIALOG(@stack
            word            dialogMethod,
            optr            dialogOD,
            char            *helpContext,
            char            * customTriggers,
            char            * arg2,
            char            * arg1,
            char            * string,
            CustomDialogBoxFlags dialogFlags);

This message executes a standard dialog box and returns immediately. When 
the dialog box is shut down, the message passed in the *dialogMethod* 
parameter is sent to the object specified in *dialogOD*. Only one dialog box at 
a time may be displayed with this message.

**Source:** Infrequently used.

**Destination:** The GenApplication to use the created dialog box.

**Parameters:**  
*dialogMethod* - The message to be sent out when the user is 
finished with the dialog. This message should be 
defined based on the prototype 
GEN_APP_DO_STANDARD_DIALOG_MSG.

*dialogOD* - The recipient of the message specified in 
*dialogMethod* above.

*helpContext* - The help context for this dialog box.

*customTriggers* - A pointer to a table of custom GenTrigger 
information. Each trigger given in the table will 
appear in the dialog box in the order declared. The 
table is made up of structures of type 
**StandardDialogResponseTriggerTable**.

*arg2* - A pointer to a second string to be displayed in the 
dialog box.

*arg1* - A pointer to a character string to be displayed in 
the dialog box.

*string* - A pointer to a custom character string to be 
displayed in the dialog box.

*dialogFlags* - A record of **CustomDialogBoxFlags** indicating 
what type of dialog box is to be created.

**Return:** Nothing.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_TOGGLE_CURSOR

    void    MSG_GEN_APPLICATION_TOGGLE_CURSOR();

This message toggles the cursor for a text object.

**Source:** Infrequently used.

**Destination:** The GenApplication of the text object.

**Interception:** Do not intercept.

----------
#### MSG_GEN_APPLICATION_BRING_UP_HELP

    void    MSG_GEN_APPLICATION_BRING_UP_HELP();

This message brings up help for an application. Normally, this is 
accomplished by sending a message to the focus object telling it to bring up a 
help window with the focus' help context.

**Source:** Unrestricted, though generally from an application Help icon or <F1>.

**Destination:** GenApplication object.

**Interception:** Generally not intercepted, though it may be useful if for some reason 
you do not wish to bring up help (such as it doesn't exist for this 
application).

----------
#### MSG_GEN_APPLICATION_TOGGLE_CURRENT_MENU_BAR

    void    MSG_GEN_APPLICATION_TOGGLE_CURRENT_MENU_BAR();

This message toggles the GIV_POPOUT state of the current GenPrimary's 
menu bar. This message only takes effect if the menu bar is toggleable (i.e. if 
UIWO_POPOUT_MENU_BAR is set).

**Source:** Unrestricted.

**Destination:** GenApplication object.

----------
#### MSG_GEN_APPLICATION_TOGGLE_FLOATING_KEYBOARD

    void    MSG_GEN_APPLICATION_TOGGLE_FLOATING_KEYBOARD();

This message toggles the state of the floating keyboard within the current 
application. Applications may subclass this to bring up their own 
PenInputControl (or equivalent) object. Otherwise the application object will 
create its own.

**Source:** Unrestricted, though generally only supported on pen-based systems. 

**Destination:** GenApplication object.

**Interception:** May be intercepted if the application has its own PenInputControl 
object.

----------
#### MSG_GEN_APPLICATION_TOGGLE_EXPRESS_MENU

    void    MSG_GEN_APPLICATION_TOGGLE_EXPRESS_MENU();

This message toggles (opens or closes) the parent field's express menu.

**Source:** Unrestricted.

**Destination:** GenApplication object.

[GenClass](ogen.md) <-- [Table of Contents](../objects.md) &nbsp;&nbsp; --> [GenDisplay / GenPrimary](ogendis.md)