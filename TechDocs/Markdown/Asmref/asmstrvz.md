## 3.8 Structures V-Z

----------
#### VarDataCHandler
    VarDataCHandler     struct
        VDCH_dataType           word
        VDCH_handler            fptr.far
    VarDataCHandler     ends

This structure is used as an entry in a class' vardata handler table. Usually, 
several of these structures will make up a table. For each entry within this 
table, specific vardata routines will call the *VDCH_handler* routine with the 
*VDCH_dataType*.

**Library:** object.def

----------
#### VarDataEntry
    VarDataEntry        struct
        VDE_dataType            word
        VDE_entrySize           word
        VDE_extraData           label byte
    VarDataEntry        ends

This structure stores a vardata entry within an object.

*VDE_dataType* stores the vardata data type, a unique identifier.

*VDE_entrySize* stores the size of the vardata if it contains extra data; 
otherwise, this field is left null.

*VDE_extraData* marks the start of the extra data within the vardata entry.

**Library:** object.def

----------
#### VarDataFlags
    VarDataFlags        record
                            :14
        VDF_EXTRA_DATA      :1      ; set if data entry has extra data
        VDF_SAVE_TO_STATE   :1      ; set if this data entry should be
                                    ; saved to state file
    VarDataFlags        end

**Library:** object.def

----------
#### VarDataHandler
    VarDataHandler      struct
        VDH_dataType        word        ; data type for this handler
        VDH_handler         nptr.far    ; handler routine
    VarDataHandler      ends

This structure defines a handler in a **VarDataHandlerTable**.

**Library:** object.def

----------
#### VarGeoData
    VarGeoData      struct
        VGD_lineWidth           word
        VGD_centerOffset        word
        VGD_secondWidth         word
    VarGeoData      ends

**Library:** Objects/visC.def

----------
#### VarObjRelocation
    VarObjRelocation        struct
        VOR_type        VarObjRelocationType
        VOR_offset      word
    VarObjRelocation        ends

**Library:** object.def

----------
#### VarObjRelocationType
    VarObjRelocationType            record
        VORT_DATA_TYPE      :14     ; high 14 bits of VarData type constant.
        VORT_RELOC_TYPE     ObjRelocationType:2
    VarObjRelocationType            end

**Library:** object.def

----------
#### VChar
    VChar   etype byte
        VC_NULL             enum VChar, 0x0     ;NULL
        VC_CTRL_A           enum VChar, 0x1     ;<ctrl>-A
        VC_CTRL_B           enum VChar, 0x2     ;<ctrl>-B
        VC_CTRL_C           enum VChar, 0x3     ;<ctrl>-C
        VC_CTRL_D           enum VChar, 0x4     ;<ctrl>-D
        VC_CTRL_E           enum VChar, 0x5     ;<ctrl>-E
        VC_CTRL_F           enum VChar, 0x6     ;<ctrl>-F
        VC_CTRL_G           enum VChar, 0x7     ;<ctrl>-G
        VC_CTRL_H           enum VChar, 0x8     ;<ctrl>-H
        VC_CTRL_I           enum VChar, 0x9     ;<ctrl>-I
        VC_CTRL_J           enum VChar, 0xa     ;<ctrl>-J
        VC_CTRL_K           enum VChar, 0xb     ;<ctrl>-K
        VC_CTRL_L           enum VChar, 0xc     ;<ctrl>-L
        VC_CTRL_M           enum VChar, 0xd     ;<ctrl>-M
        VC_CTRL_N           enum VChar, 0xe     ;<ctrl>-N
        VC_CTRL_O           enum VChar, 0xf     ;<ctrl>-O
        VC_CTRL_P           enum VChar, 0x10    ;<ctrl>-P
        VC_CTRL_Q           enum VChar, 0x11    ;<ctrl>-Q
        VC_CTRL_R           enum VChar, 0x12    ;<ctrl>-R
        VC_CTRL_S           enum VChar, 0x13    ;<ctrl>-S
        VC_CTRL_T           enum VChar, 0x14    ;<ctrl>-T
        VC_CTRL_U           enum VChar, 0x15    ;<ctrl>-U
        VC_CTRL_V           enum VChar, 0x16    ;<ctrl>-V
        VC_CTRL_W           enum VChar, 0x17    ;<ctrl>-W
        VC_CTRL_X           enum VChar, 0x18    ;<ctrl>-X
        VC_CTRL_Y           enum VChar, 0x19    ;<ctrl>-Y
        VC_CTRL_Z           enum VChar, 0x1a    ;<ctrl>-Z
        VC_ESCAPE           enum VChar, 0x1b    ;ESC

        ; Extended keyboard codes -- those normally in ASCII ctrl set
        ; CTRL <key> sequences pressed by user will also be mapped here.

        VC_BACKSPACE        = VC_CTRL_H
        VC_TAB              = VC_CTRL_I
        VC_LF               = VC_CTRL_J
        VC_ENTER            = VC_CTRL_M
        VC_BLANK            enum VChar, 0x20    ;space

        ; Numeric keypad keys

        VC_NUMPAD_ENTER     enum VChar, 0xd     ;* only on PS/2 keyboards
        VC_NUMPAD_DIV       enum VChar, '/'     ;* only on PS/2 keyboards
        VC_NUMPAD_MULT      enum VChar, '*'
        VC_NUMPAD_PLUS      enum VChar, '+'
        VC_NUMPAD_MINUS     enum VChar, '-'
        VC_NUMPAD_PERIOD    enum VChar, '.'
        VC_NUMPAD_0         enum VChar, '0'
        VC_NUMPAD_1         enum VChar, '1'
        VC_NUMPAD_2         enum VChar, '2'
        VC_NUMPAD_3         enum VChar, '3'
        VC_NUMPAD_4         enum VChar, '4'
        VC_NUMPAD_5         enum VChar, '5'
        VC_NUMPAD_6         enum VChar, '6'
        VC_NUMPAD_7         enum VChar, '7'
        VC_NUMPAD_8         enum VChar, '8'
        VC_NUMPAD_9         enum VChar, '9'

        ; Extended keyboard codes -- non-ASCII

        VC_F1               enum VChar, 0x80    ; Function keys
        VC_F2               enum VChar, 0x81
        VC_F3               enum VChar, 0x82
        VC_F4               enum VChar, 0x83
        VC_F5               enum VChar, 0x84
        VC_F6               enum VChar, 0x85
        VC_F7               enum VChar, 0x86
        VC_F8               enum VChar, 0x87
        VC_F9               enum VChar, 0x88
        VC_F10              enum VChar, 0x89
        VC_F11              enum VChar, 0x8a    ;* only on PS/2 keyboards
        VC_F12              enum VChar, 0x8b    ;* only on PS/2 keyboards
        VC_F13              enum VChar, 0x8c    ;* non-standard key
        VC_F14              enum VChar, 0x8d    ;* non-standard key
        VC_F15              enum VChar, 0x8e    ;* non-standard key
        VC_F16              enum VChar, 0x8f    ;* non-standard key

        VC_UP               enum VChar, 0x90    ;Cursor keys
        VC_DOWN             enum VChar, 0x91
        VC_RIGHT            enum VChar, 0x92
        VC_LEFT             enum VChar, 0x93
        VC_HOME             enum VChar, 0x94    ;Scroll commands
        VC_END              enum VChar, 0x95
        VC_PREVIOUS         enum VChar, 0x96
        VC_NEXT             enum VChar, 0x97
        VC_INS              enum VChar, 0x98    ;INS
        VC_DEL              enum VChar, 0x9a    ;DEL

        VC_PRINTSCREEN      enum VChar, 0x9b    ;* from <shift>-NUMPAD_MULT
                                                ;Appears as key only on PS/2
        VC_PAUSE            enum VChar, 0x9c    ;* from <ctrl>-NUMLOCK
                                                ; Appears as key only on PS/2
        VC_BREAK            enum VChar, 0x9e    ;* from <ctrl>- or <alt>-combo
                                                ; with various keys
        VC_SYSTEMRESET      enum VChar, 0x9f    ; <ctrl>-<alt>-<del> combo

        ; Joystick control keys (0xa0 - 0xa9)

        VC_JOYSTICK_0       enum VChar, 0xa0    ; joystick 0 degrees
        VC_JOYSTICK_45      enum VChar, 0xa1    ; joystick 45 degrees
        VC_JOYSTICK_90      enum VChar, 0xa2    ; joystick 90 degrees
        VC_JOYSTICK_135     enum VChar, 0xa3    ; joystick 135 degrees
        VC_JOYSTICK_180     enum VChar, 0xa4    ; joystick 180 degrees
        VC_JOYSTICK_225     enum VChar, 0xa5    ; joystick 225 degrees
        VC_JOYSTICK_270     enum VChar, 0xa6    ; joystick 270 degrees
        VC_JOYSTICK_315     enum VChar, 0xa7    ; joystick 315 degrees
        VC_FIRE_BUTTON_1    enum VChar, 0xa8    ; fire button #1
        VC_FIRE_BUTTON_2    enum VChar, 0xa9    ; fire button #2

        ; Shift Keys (0xe0 - 0xe7)

        VC_LALT             enum VChar, 0xe0
        VC_RALT             enum VChar, 0xe1
        VC_LCTRL            enum VChar, 0xe2
        VC_RCTRL            enum VChar, 0xe3
        VC_LSHIFT           enum VChar, 0xe4
        VC_RSHIFT           enum VChar, 0xe5
        VC_SYSREQ           enum VChar, 0xe6    ; * Not on base PC keyboard.
                                                ; On PS/2 keyboards, is
                                                ; accessed via ALT PRINTSCREEN
        VC_ALT_GR           enum VChar, 0xe7

        ; Toggle state keys (0xe8 - 0xef)

        VC_CAPSLOCK         enum VChar, 0xe8
        VC_NUMLOCK          enum VChar, 0xe9
        VC_SCROLLLOCK       enum VChar, 0xea

        ; Extended state keys (0xf0 - 0xf7)

        ; Invalid key

        VC_INVALID_KEY      enum VChar, 0xff

The previous represent the low byte of the character value only when the 
high byte is CS_CONTROL.

**Library:** input.def

----------
#### VCR_param
    VCR_param       struct
        VCR_routine         dword
        VCR_BP_param            word
        VCR_DX_param            word
        VCR_CX_param            word
    VCR_param       ends

This structure stores stack parameters used in MSG_VIS_CALL_ROUTINE.

**Library:** Objects/visC.def

----------
#### ViewCommandType
    ViewCommandType     etype   word
        VCT_ZOOM_IN         enum ViewCommandType    ;no other data
        VCT_ZOOM_OUT        enum ViewCommandType    ;no other data
        VCT_SET_SCALE       enum ViewCommandType    ;data is scale %

**Library:** ui.def

----------
#### ViewSize
    ViewSize        etype word, 8000h
    VS_TYPICAL  enum ViewSize       ;choose size typical of the specific UI
    VS_SMALL    enum ViewSize       ;choose a small size
    VS_LARGE    enum ViewSize       ;choose a large size

**Library:** Objects/gViewC.def

----------
#### ViewTargetInfo
    ViewTargetInfo          struct
        VTI_target  TargetReference     ; Final target object within content
        VTI_content TargetReference     ; The content object itself
    ViewTargetInfo          ends

**Library:** Objects/gViewC.def

----------
#### VisAddRectFlags
    VisAddRectFlags     record
        VARF_NOT_IF_ALREADY_INVALID     :1
        VARF_ONLY_REDRAW_MARGINS        :1
        VARF_UPDATE_WILL_HAPPEN         :1
                                        :5
    VisAddRectFlags     end

VARF_NOT_IF_ALREADY_INVALID  
Don't invalidate the rectangle if any node going up to the win 
group has its image or window marked invalid.

VARF_ONLY_REDRAW_MARGINS  
This flag indicates that the object is invalidating old bounds, 
and can optimize invalidation if desired by splitting the 
message into four, one for each margin, in some cases.

VARF_UPDATE_WILL_HAPPEN  
The caller knows of an impending update, so adding the 
rectangle to the update region rather than invalidating is a 
reasonable (and fast) thing to do.

**Library:** Objects/visC.def

----------
#### VisAddRectParams
    VisAddRectParams        struct
        VARP_bounds     Rectangle           ;rect to invalidate
        VARP_flags      VisAddRectFlags
        VARP_unused     byte                ;word align
    VisAddRectParams        ends

**Library:** Objects/visC.def

----------
#### VisAttrs
    VisAttrs    record
        VA_VISIBLE                  :1
        VA_FULLY_ENABLED            :1
        VA_MANAGED                  :1
        VA_DRAWABLE                 :1
        VA_DETECTABLE               :1
        VA_BRANCH_NOT_MINIMIZABLE   :1
        VA_OLD_BOUNDS_SAVED         :1
        VA_REALIZED                 :1
    VisAttrs    end

VA_VISIBLE  
This attribute is for WIN_GROUP's only. (Ignored if 
non-WIN_GROUP object) Set if object may be visually built out, 
meaning that it is allowed to be linked visually into a 
composite, and if that composite is realized, then it would be 
made visible, too.

VA_FULLY_ENABLED  
Flag to tell whether a vis object is enabled or not. If cleared 
visual objects typically don't allow clicks and are drawn in a 
50% pattern, even if they're not generic. Set by 
MSG_SPEC_BUILD, MSG_SPEC_NOTIFY_ENABLED, and 
MSG_SPEC_NOTIFY_NOT_ENABLED in generic objects.

VA_MANAGED  
Set if object is managed, that is, space is reserved for it in the 
composite via the geometry manager. Set if no space should be 
allocated for it. A message will allow this status to change, & if 
the window on which this object is placed is realized, then we 
must have the geometry manager redo the geometry.

VA_DRAWABLE  
Set if object is drawn, set if invisible. A message will allow 
setting of this flag. If the window on which this object resides is 
realized when this happens, the bounding box of the object will 
be invalidated on that window.

VA_DETECTABLE  
Set if object might respond to mouse, ptr, kbd,etc. data. set if 
composite shouldn't bother to send such data onto the child. 
This bit will only be tested when a composite is passing a 
message down to its children. Display only objects should have 
this bit clear. The message allowing changing of this bit will not 
change any grab in progress on the object. Note that a window 
composite may not have this bit clear. Basically, we can't avoid 
an implied grab to a window.

VA_BRANCH_NOT_MINIMIZABLE  
For Generic objects only (Would be a SpecAttrs if room). Used 
to keep modal windows up on screen even if they are generic 
children of a primary which is minimized.       

VA_OLD_BOUNDS_SAVED  
(Would be in optFlags or geoFlags if room). Flag to keep track 
of whether old bounds have been saved for the object by the 
geometry manager for use by the invalidation mechanism. 
Bounds are kept in variable data type VVDT_OLD_BOUNDS.

VA_REALIZED  
Set by default VisOpen and VisClose messages to indicate if 
object is realized (visible within a window) onscreen or not. Is 
also used to ensure that all objects receive a VisOpen, even if 
the visible part of the tree has just been added to a branch that 
is already realized, & then updated - this should all be done in 
one operation, without delaying the update - and the top object 
of the branch to be realized should be marked as 
"WINDOW_INVALID", even if it is a non-windowed object, as the 
MSG_UPDATE_WINDOWS will follow the path bits & figure out 
that the object needs to be sent a MSG_VIS_OPEN. May not be 
set by MSG_VIS_SET_ATTR.

**Library:** Objects/visC.def

----------
#### VisCompGeoAttrs
    VisCompGeoAttrs     record
        VCGA_ORIENT_CHILDREN_VERTICALLY         :1
        VCGA_INCLUDE_ENDS_IN_CHILD_SPACING      :1
        VCGA_ALLOW_CHILDREN_TO_WRAP             :1
        VCGA_ONE_PASS_OPTIMIZATION              :1
        VCGA_CUSTOM_MANAGE_CHILDREN             :1
        VCGA_HAS_MINIMUM_SIZE                   :1
        VCGA_WRAP_AFTER_CHILD_COUNT             :1
        VCGA_ONLY_DRAW_IN_MARGINS               :1
    VisCompGeoAttrs     end

VCGA_ORIENT_CHILDREN_VERTICALLY  
Place the composite's children vertically, rather than 
horizontally. 

VCGA_INCLUDE_ENDS_IN_CHILD_SPACING  
When used with full justification, divides the spacing up so that 
there is as much space allocated before the first child and after 
the last child as there are between the children. An example of 
this is a motif reply bar. When this is clear, there is no space 
allocated at the ends of the composite.

VCGA_ALLOW_CHILDREN_TO_WRAP  
Allows children to wrap if their combined lengths will not allow 
them to fit inside the bounds of this object's parent. The 
composite will keep within the bounds of its parent and wrap 
the children as necessary. When this is clear, the children will 
force the composite to be as big as needed to fit the children on 
one line (unless, of course, the 
CAN_TRUNCATE_WIDTH_TO_FIT_PARENT flags are set.)

VCGA_ONE_PASS_OPTIMIZATION  
This is an optimization which speeds up the geometry 
manager, only making one pass of sizing the children and using 
the sum of the sizes as the size of the composite. In order to use 
this flag, you must be sure that the children don't want to wrap, 
and are always one size, regardless of the size of the parent, 
such as buttons in a horizontal composite.

VCGA_CUSTOM_MANAGE_CHILDREN  
Don't use the geometry manager to manage the children. This 
allows you to set up the sizes and positions of the children 
without the need of the geometry manager. If this flag is set, 
the composite will be default return its current size when asked 
to calculate its size, like a simple non-composite object.

VCGA_HAS_MINIMUM_SIZE  
Geometry manager will send a 
MSG_VIS_COMP_GET_MIN_SIZE to this object if this flag is set, 
and always make the composite at least as big as that.

VCGA_WRAP_AFTER_CHILD_COUNT  
Used in conjunction with VCGA_ALLOW_CHILDREN_TO_WRAP. 
If set, composite will wrap after a certain number of children, 
the number being obtained from a 
MSG_VIS_COMP_GET_CHILD_WRAP_COUNT.

VCGA_ONLY_DRAWS_IN_MARGINS  
This flag can be set by a composite to optimize invalidation. If 
set, a composite whose image is invalid will only have its 
margins invalidated. Any visual child below it will have to have 
its image invalid in order to get invalidated. To get proper 
invalidations, the composite cannot draw anything inside its 
margins (that isn't the color of the background).

**Library:** Objects/vCompC.def

----------
#### VisCompGeoDimensionAttrs
    VisCompGeoDimensionAttrs            record
        VCGDA_WIDTH_JUSTIFICATION           WidthJustification:2
        VCGDA_EXPAND_WIDTH_TO_FIT_PARENT    :1
        VCGDA_DIVIDE_WIDTH_EQUALLY          :1
        VCGDA_HEIGHT_JUSTIFICATION          HeightJustification:2
        VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT   :1
        VCGDA_DIVIDE_HEIGHT_EQUALLY         :1
    VisCompGeoDimensionAttrs            end

VCGDA_WIDTH_JUSTIFICATION  
Horizontal justifications for placing the children. Note that 
horizontal full justification is only meaningful if the composite 
is oriented horizontally.

VCGDA_EXPAND_WIDTH_TO_FIT_PARENT  
Composite will try to expand to fill the available width of the 
parent. By default, a composite will only be as wide as its 
children require.

VCGDA_DIVIDE_WIDTH_EQUALLY  
Will attempt to divide width equally among its manageable 
children if oriented horizontally. Does not guarantee that the 
children can cooperate (the size can only be suggested).

VCGDA_HEIGHT_JUSTIFICATION  
Vertical justifications for placing the children. Note that 
vertical full justification is only meaningful if the composite is 
oriented vertically.

VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT  
Composite will try to expand to fill the available height of the 
parent. By default, a composite will only be as tall as its 
children require.

VCGDA_DIVIDE_HEIGHT_EQUALLY  
Will attempt to divide height equally among its manageable 
children if oriented horizontally. Does not guarantee that the 
children can cooperate (the size can only be suggested).

**Library:** Objects/vCompC.def

----------
#### VisCompSpacingMarginsInfo
    VisCompSpacingMarginsInfo               record
        VCSMI_USE_THIS_INFO             :1
        VCSMI_LEFT_MARGIN               :3
        VCSMI_TOP_MARGIN                :3
        VCSMI_RIGHT_MARGIN              :3
        VCSMI_BOTTOM_MARGIN             :3
        VCSMI_CHILD_SPACING             :3
    VisCompSpacingMarginsInfo               end

VCSMI_USE_THIS_INFO  
VisCompCalcNewSize uses this info for the composite's spacing 
and margins. If zero, will send 
MSG_VIS_COMP_GET_CHILD_SPACING and 
MSG_VIS_COMP_GET_MARGINS to get the information it 
needs.

VCSMI_LEFT_MARGIN

VCSMI_TOP_MARGIN

VCSMI_RIGHT_MARGIN

VCSMI_BOTTOM_MARGIN  
Margins to use when doing geometry, rather than sending a 
MSG_VIS_COMP_GET_MARGINS.

VCSMI_CHILD_SPACING  
Spacing (both between children and between wrapped lines) to 
use in lieu of MSG_VIS_COMP_GET_CHILD_SPACING.

**Library:** Objects/vCompC.def

----------
#### VisContentAttrs
    VisContentAttrs     record
        VCNA_SAMW_WIDTH_AS_VIEW                         :1
        VCNA_SAME_HEIGHT_AS_VIEW                        :1
        VCNA_LARGE_DOCUMENT_MODEL                       :1
        VCNA_WINDOW_COORDINATE_MOUSE_EVENTS             :1
        VCNA_ACTIVE_MOUSE_GRAB_REQUIRES_LARGE_EVENTS    :1
        VCNA_VIEW_DOC_BOUNDS_SET_MANUALLY               :1
        VCNA_VIEW_DOES_NOT_WIN_SCROLL                   :1
                                                        :1
    VisContentAttrs     end

VCNA_SAME_WIDTH_AS_VIEW  
Set if the content's width should just follow the subview's 
window width, if possible. You want to set this if the view is not 
supposed to be horizontally scrollable.

VCNA_SAME_HEIGHT_AS_VIEW  
Set if the content's height should just follow the subview's 
window height, if possible. You want to set this if the view is not 
supposed to be vertically scrollable.

VCNA_LARGE_DOCUMENT_MODEL  
Set if using a large document model, in which this object will be 
a large (32-bit) VisContent. Effects:

Bounds are larger than the graphics space under this model, so 
the 16-bit Visible bounds of this object are meaningless. The 
application must initialize the GenView, or use 
MSG_GEN_VIEW_SET_DOC_SIZE, to set the view's document 
size.

If no active mouse grab: Incoming mouse events are converted 
into 32-bit LARGE mouse events & sent to the VisContent, 
where the default handler will send them on to the first visible 
child, thereby providing correct behavior for the single-child 
case. Applications having multiple visible layers (32-bit 
children of VisContents) must intercept these messages & 
direct them to the correct layer.

MSG_VIS_DRAW is by default sent on to the first visible child, 
thereby providing correct behavior for the single-child case. 
Applications having multiple visible layers (32-bit children of 
VisContents) must intercept this message & direct it to the 
correct layer(s).

VCNA_WINDOW_COORDINATE_MOUSE_EVENTS  
Required if VCNA_LARGE is set. Support for this bit requires a 
VisContentClass object. Set if the GenView associated with this 
content has been set up to send mouse events in window 
coordinates, instead of document coordinates (For either 32-bit 
support capability or fractional mouse position capability). 
Indicates that the VisContent will need to convert the 
coordinates to document coordinates before sending them on. 
This is done via the equation:

Doc Coords = (Win Coords/Scale Factor) + Doc Origin

VCNA_ACTIVE_MOUSE_GRAB_REQUIRES_LARGE_EVENTS  
This bit only used by VisContentClass objects. Set/cleared by 
MSG_VIS_VUP_ALTER_INPUT_FLOW routine to indicate 
whether the current mouse grab wishes to receive LARGE 
mouse events in place of the standard ones. Note that this 
mechanism may be used even when the bit VCNA_LARGE is not 
set.

VCNA_VIEW_DOC_BOUNDS_SET_MANUALLY  
Not often used, this will prevent the content from 
automatically sending off its size to the view on geometry 
updates. The view's document bounds must be set some other 
way. Setting VCNA_LARGE_DOCUMENT_MODEL will also 
cause this behavior.

VCNA_VIEW_DOES_NOT_WIN_SCROLL  
Set to indicate that the view does not actually scroll its window, 
it just sends origin messages to the content when the user 
interacts with the scrollbar.    Visual invalidation will use this 
flag to invalidate the correct region of the content. Should be 
set whenever ATTR_GEN_VIEW_DO_NOT_WIN_SCROLL is set 
in the view.

**Library:** Objects/vCntC.def

----------
#### VisGeoAttrs
    VisGeoAttrs     record
        ;
        ; Geometry state flags
        ;
        VGA_GEOMETRY_CALCULATED             :1
        VGA_NO_SIZE_HINTS                   :1
        ;
        ; Miscellaneous flags
        ;
        VGA_NOTIFY_GEOMETRY_INVALID         :1
        VGA_DONT_CENTER                     :1
        VGA_USE_VIS_SET_POSITION            :1
        VGA_USE_VIS_CENTER                  :1
        VGA_ONLY_RECALC_SIZE_WHEN_INVALID   :1
        VGA_ALWAYS_RECALC_SIZE              :1
    VisGeoAttrs     end

VGA_GEOMETRY_CALCULATED  
Set in an after the first time an object's geometry has been 
calculated. This is used by the specific UI size hint handlers to 
figure out whether an initial size hint should be applied to an 
object or not. This is set at the time an object's size and position 
has been completely determined. It can be cleared if need be.

VGA_NO_SIZE_HINTS  
Specific attribute only: if set, we have checked to see if the 
object has one or more of HINT_INITIAL_SIZE, 
HINT_MINIMUM_SIZE, HINT_MAXIMUM_SIZE, 
HINT_FIXED_SIZE set, and it doesn't. We clear this flag if one of 
the desired size methods are called.

VGA_NOTIFY_GEOMETRY_VALID  
If set, geometry manager will notify object when its geometry 
messages have all been finished and its geometry is valid.

VGA_DONT_CENTER  
Allows an object to individually override the parent composite's 
centering along its width. Will appear on the top (of a 
horizontal composite, left edge if vertical) instead.

VGA_USE_VIS_SET_POSITION  
All objects that don't use the default Vis or VisComp handlers 
for MSG_VIS_SET_POSITION and 
MSG_VIS_POSITION_BRANCH should set  this flag. It's an 
optimization that allows static calls to the geometry manager.

VGA_USE_VIS_CENTER  
If set, geometry manager uses standard vis or visComp center 
message to calculate the object's center.

VGA_ONLY_RECALC_SIZE_WHEN_INVALID  
Set this if your object wants its message called the first time 
after its geometry is invalid, and then always return the 
current size. Example: buttons in a horizontal composite. 

VGA_ALWAYS_RECALC_SIZE  
If set, doesn't do optimizations to calculate the size of this 
object. May be needed for composites that expand to fit and 
center their children to match their parent, or some other 
obscure cases where the size might change from  one call to 
another.

**Library:** Objects/visC.def

----------
#### VisInputFlowGrabFlags
    VisInputFlowGrabFlags           record
        VIFGF_NOT_HERE      :1
                            :1
        VIFGF_FORCE         :1
        VIFGF_GRAB          :1
        VIFGF_KBD           :1
        VIFGF_MOUSE         :1
        VIFGF_LARGE         :1
        VIFGF_PTR           :1
    VisInputFlowGrabFlags           end

VIFGF_NOT_HERE  
This flag overrides all other flags! Set if this request should not 
be honored here, but instead sent on up the hierarchy with this 
bit cleared. This bit exists for two reasons:

1) So that nodes can tell the difference between messages 
coming up from objects below & those requests which it has 
made for itself, which should be handled by the next node up.

2) Thus allowing MSG_VIS_VUP_ALTER_INPUT_FLOW to be 
sent to the object making the request itself, thereby allowing 
nodes the freedom to direct the message in directions other 
than the visual hierarchy, if the next node is not in that 
direction.

VIFGF_FORCE  
If VIFGF_GRAB is set and GrabType = VIFGT_ACTIVE, set to 
force grab away from current owner, clear if we should leave 
any current owner alone.

VIFGF_GRAB  
Set to grab, clear to release. 
Note 1: object must be passed in release case as well as grab. 
Release will not occur unless object matches. 
Note 2: Only one obj may have the active grab at any one time, 
whereas any number of objects may add themselves to a 
passive list.

VIFGF_KBD  
Set to grab/release kbd (keyboard).

VIFGF_MOUSE  
Set to grab/release mouse.

VIFGF_LARGE  
If VIFGF_MOUSE and VIFGF_GRAB: LARGE mouse events 
requested 

VIFGF_PTR  
If VIFGF_MOUSE, set if ptr events need to be sent.

**Library:** Objects/visC.def

----------
#### VisInputFlowGrabType
    VisInputFlowGrabType            etype byte
        VIFGT_ACTIVE            enum VisInputFlowGrabType
        VIFGT_PRE_PASSIVE       enum VisInputFlowGrabType
        VIFGT_POST_PASSIVE      enum VisInputFlowGrabType

**Library:** Objects/visC.def

----------
#### VisLargeTextAttrs
    VisLargeTextAttrs       record
        VLTA_EXACT_HEIGHT       :1
                                :15
    VisLargeTextAttrs       end

**Library:** Objects/vLTextC.def

----------
#### VisLargeTextDisplayModes
    VisLargeTextDisplayModes            etype word
        VLTDM_PAGE                  enum VisLargeTextDisplayModes
        ;
        ; In page mode the values stored in the region array are used.
        ;
        VLTDM_CONDENSED             enum VisLargeTextDisplayModes
        ;
        ; In condensed mode all text regions are put vertically one after the
        ; other. Calculated fields are:
        ; - VLTRAE_spatialPosition
        ;   The x position is taken from vardata. The y position is the
        ;   sum of the region heights (VLTRAE_size.XYS_height) for all
        ;   preceding regions plus the offset stored in vardata plus the
        ;   page spacing stored in vardata.
        ;
        VLTDM_GALLEY                enum VisLargeTextDisplayModes
        ;
        ; In galley mode all text regions are put vertically one after the
        ; other as in condensed mode, except that the computed heights are
        ; used (so that the regions are jammed right next to each other).
        ; Calculated fields are:
        ; - VLTRAE_spatialPosition
        ;   The x position is taken from vardata. The y position is the
        ;   sum of the region calculated heights (VLTRAE_calcHeight) for all
        ;   preceding regions plus the offset stored in vardata plus the
        ;   page spacing stored in vardata.
        ; - VLTRAE_size.XYS_height
        ;   Taken from VLTRAE_calcHeight when being used to clear
        ;
        VLTDM_DRAFT_WITH_STYLES     enum VisLargeTextDisplayModes
        VLTDM_DRAFT_WITHOUT_STYLES  enum VisLargeTextDisplayModes
        ;
        ; In draft mode all text regions are forced to a standard size and are
        ; then put one after the other as in galley mode. Calculated fields
        ; are:
        ; - VLTRAE_spatialPosition
        ;   Same as galley mode
        ; - VLTRAE_size
        ;   Taken from VTDMD_draftRegionSize
        ; - VLTRAE_region
        ;   Always 0 (rectangular region)

**Library:** Objects/vLTextC.def

----------
#### VisLargeTextFlags
    VisLargeTextFlags       record
        VLTF_HEIGHT_NOTIFY_PENDING      :1
                                        :15
    VisLargeTextFlags       end

**Library:** Objects/vLTextC.def

----------
#### VisLargeTextRegionArrayElement
    VisLargeTextRegionArrayElement          struct
        VLTRAE_charCount            dword       ;# characters in region
        VLTRAE_lineCount            dword       ;# lines in region
        VLTRAE_section              word        ;section number
        VLTRAE_spatialPosition      PointDWord  ;position (in 32 bit space)
        VLTRAE_size                 XYSize      ;region size
        VLTRAE_calcHeight           WBFixed     ;computed height of text
        VLTRAE_region               dword       ;db item containing region or
                                                ;0 for rectangular
        VLTRAE_flags                VisLargeTextRegionFlags
        VLTRAE_reserved             byte 3 dup (?)
    VisLargeTextRegionArrayElement          ends

**Library:** Objects/vLTextC.def

----------
#### VisLargeTextRegionFlags
    VisLargeTextRegionFlags         record
        VLTRF_ENDED_BY_COLUMN_BREAK     :1
        VLTRF_EMPTY                     :1
                                        :14
    VisLargeTextRegionFlags         end

**Library:** Objects/vLTextC.def

----------
#### VisMoniker
    VisMoniker      struct
        VM_type         VisMonikerType <>
        VM_width        word
        VM_data         label VisMonikerText
    VisMoniker      ends

This structure defines a visual moniker. Individual monikers can be 
combined into a list using a **VisMonikerList** structure.

*VM_type* stores the type of vis moniker. The low byte of the record determines 
whether this is a moniker or a list of monikers.

*VM_width* stores the cached width of the moniker. This value will be 
calculated if this entry is null and if VMLET_GSTRING bit is not set. (The 
cached height is kept with the gstring.)

*VM_data* stores the start of the visual moniker data. If VMLET_GSTRING bit 
set in *VM_type* is set then a **VisMonikerGString** structure starts here. 
Otherwise a **VisMonikerText** structure starts here.

**Library:** Objects/visC.def

----------
#### VisMonikerCachedWidth
    VisMonikerCachedWidth   record
        VMCW_HINTED             :1 ;If set then low 15 bits are cache info
        VMCW_BERKELEY_9         :7 ;Cached width for Berkeley 9
        VMCW_BERKELEY_10        :8 ;Cached width for Berkeley 10
    VisMonikerCachedWidth   end

**Library:** visC.def

----------
#### VisMonikerDataType
    VisMonikerDataType      etype byte
        VMDT_NULL               enum VisMonikerDataType
        VMDT_VIS_MONIKER        enum VisMonikerDataType
        VMDT_TEXT               enum VisMonikerDataType
        VMDT_GSTRING            enum VisMonikerDataType
        VMDT_TOKEN              enum VisMonikerDataType

VMDT_NULL  
Indicates that there is no source. 
MSG_GEN_REPLACE_VIS_MONIKER will just free current vis 
moniker. Not valid for MSG_VIS_CREATE_VIS_MONIKER and 
MSG_GEN_CREATE_VIS_MONIKER. *CVMF_source*, 
*RVMF_source*, *CVMF_length*, *RVMF_length*, *CVMF_width*, 
*CVMF_height*, *RVMF_width*, and *RVMF_height* are unused.

VMDT_VIS_MONIKER  
Indicates that source is a complete **VisMoniker** structure. 
*CVMF_length* and *RVMF_length* indicate the size of the 
complete VisMoniker structure. *CVMF_width*, *CVMF_height*, 
*RVMF_width*, and *RVMF_height* are unused. 

VMDT_TEXT  
source is a text string. If null-terminated, 
*CVMF_length* and *RVMF_length* should be zero. Otherwise, 
*CVMF_length* and *RVMF_length* indicate the length of the text 
string. A **VisMoniker** structure will be created for the text 
string. *CVMF_width*, *CVMF_height*, *RVMF_width*, and 
*RVMF_height* are unused.

VMDT_GSTRING  
Indicates that source is a graphics string. If *CVMF_length* and 
*RVMF_length* are 0, the gstring length will be determined by 
scanning the graphics string for GR_END_STRING. Otherwise, 
*CVMF_length* and *RVMF_length* indicate the length of the 
graphics string. *CVMF_width*, *CVMF_height*, *RVMF_width* and 
*RVMF_height* indicate the width and height of the graphics 
string. If either is zero, the width and height will be computed 
by examining the string. A **VisMoniker** structure will be 
created for the graphics string.

VMDT_TOKEN  
Indicates that source is a **GeodeToken**. *CVMF_length*, 
*RVMF_length*, *CVMF_width*, *CVMF_height*, *RVMF_width*, and 
*RVMF_height* are unused. The destination object must be 
usable to use this data type because the specific UI must decide 
which moniker to choose from the moniker in the Token 
Database.

**Library:** Objects/visC.def

----------
#### VisMonikerGString
    VisMonikerGString       struct
        VMGS_height             word        ;cached gstring height
        VMGS_gstring            label byte  ;start of gstring
    VisMonikerGString       ends

This structure defines the data at VM_data within a visual moniker if the 
visual moniker is a graphics string.

**Library:** Objects/visC.def

----------
#### VisMonikerListEntry
    VisMonikerListEntry         struct
        VMLE_type           VisMonikerListEntryType <>
        VMLE_moniker        optr
    VisMonikerListEntry         ends

This structure is used for elements in a **VisMonikerList**. The list consists of 
any number of these elements inside a chunk.

*VMLE_type* stores the type of moniker. This type is used during a moniker 
search to find a desired moniker.

*VMLE_moniker* stores the optr of the moniker.

**Library:** Objects/visC.def

----------
#### VisMonikerListEntryType
    VisMonikerListEntryType             record
                                    :2
        VMLET_GS_SIZE               DisplaySize:2
        VMLET_STYLE                 VMStyle:4
        ;
        ; bits below must match VisMonikerType
        ;
        VMLET_MONIKER_LIST          :1
        VMLET_GSTRING               :1
        VMLET_GS_ASPECT_RATIO       DisplayAspectRatio:2
        VMLET_GS_COLOR              DisplayClass:4
    VisMonikerListEntryType             end

VMLET_GS_SIZE  
If is a GString, size of moniker.

VMLET_STYLE  
Style of this moniker

VMLET_MONIKER_LIST  
The UIC compiler always sets this if flag, indicating that this 
record is within a **VisMonikerListElement**, not the actual 
**VisMoniker** itself.

VMLET_GSTRING  
TRUE if this moniker is a graphics string **VisMonikerGString**). 
If false, this moniker is text (**VisMonikerText**).

VMLET_GS_ASPECT_RATIO  
If is a GString, aspect ratio of GString.

VMLET_GS_COLOR  
If is a GString, color requirements of GString.

**Library:** Objects/visC.def

----------
#### VisMonikerSearchFlags
    VisMonikerSearchFlags           record
        VMSF_STYLE              VMStyle:4
                                :1
        VMSF_COPY_CHUNK         :1
        VMSF_REPLACE_LIST       :1
        VMSF_GSTRING            :1
                                :8          ; Internal use only
    VisMonikerSearchFlags           end

VMSF_STYLE 
Preferred style of moniker

VMSF_COPY_CHUNK 
True to copy the **VisMoniker** chunk into the specified object 
block, if the search is successful, and the moniker is not in that 
block already.

VMSF_REPLACE_LIST 
True to replace to **VisMonikerList** chunk with the **VisMoniker**, 
if the search is successful. The idea is that the chunk handle for 
the list now points to the moniker.

VMSF_GSTRING 
True if a gstring moniker is expected (i.e. a 
**VisMonikerGString**), false if a text moniker is expected (i.e. a 
**VisMonikerText**).

**Library:** Objects/visC.def

----------
#### VisMonikerSourceType
    VisMonikerSourceType            etype byte
        VMST_FPTR           enum VisMonikerSourceType
        VMST_OPTR           enum VisMonikerSourceType
        VMST_HPTR           enum VisMonikerSourceType

VMST_FPTR  
Indicates source is referenced by a fptr. *CVMF_source* and 
*RVMF_source* fields are a fptr.

VMST_OPTR  
Indicates source is referenced by a optr. *CVMF_source* and 
*RVMF_source* fields are an optr.

VMST_HPTR  
Indicates source is referenced by a hptr and offset. 
*CVMF_source* and *RVMF_source* fields are a hptr and offset 
within the block.

**Library:** Objects/visC.def

----------
#### VisMonikerText
    VisMonikerText          struct
        VMT_mnemonicOffset      byte            ;offset to mnemonic, -1 if none
        VMT_text                label byte      ;start of null-terminated text
    VisMonikerText          ends

This structure defines the data at *VM_data* within a **VisMoniker** for text 
monikers.

**Library:** Objects/visC.def

----------
#### VisMonikerType
    VisMonikerType      record
        VMT_MONIKER_LIST        :1
        VMT_GSTRING             :1
        VMT_GS_ASPECT_RATIO     DisplayAspectRatio:2
        VMT_GS_COLOR            DisplayClass:4
        VisMonikerType      end

VMT_MONIKER_LIST  
The UIC compiler always clears this flag, indicating that this 
record is within a **VisMoniker**.

VMT_GSTRING  
True if this moniker is a graphics string (**VisMonikerGString**). 
If false, this moniker is text (**VisMonikerText**).

VMT_GS_ASPECT_RATIO  
If is a GString, aspect ratio of moniker.

VMT_GS_COLOR  
Color requirements of GString.

**Library:** Objects/visC.def

----------
#### VisMouseGrab
    VisMouseGrab        struct
        VMG_object          optr
        VMG_gWin            hptr.Window <>
        VMG_translation     PointDWord
        VMG_flags           VisInputFlowGrabFlags
        VMG_unused          byte
    VisMouseGrab        ends

This structure stores data associated with an object requesting a mouse grab. 
This structure is filled in by the handler for 
MSG_VIS_VUP_ALTER_INPUT_FLOW.

*VMG_object* stores the optr of the object having the mouse grab.

*VMG_gWin* stores the handle of the window that the object having grab 
resides in, or 0 if in same window as the **VisContent**.

*VMG_translation* stores the 32 bit translation to use for the grab, set by the 
handler for MSG_VIS_VUP_ALTER_INPUT_FLOW. This 32-bit translation, 
passed in *VAIFD_translation* in the above message, is set by large visible 
objects subclassing the message. Mouse event positions are adjusted by this 
amount before being sent out.

**Library:** Objects/vCntC.def

----------
#### VisOptFlags
    VisOptFlags         record
        VOF_GEOMETRY_INVALID        :1
        VOF_GEO_UPDATE_PATH         :1
        VOF_IMAGE_INVALID           :1
        VOF_IMAGE_UPDATE_PATH       :1
        VOF_WINDOW_INVALID          :1
        VOF_WINDOW_UPDATE_PATH      :1
        VOF_UPDATE_PENDING          :1
        VOF_UPDATING                :1
    VisOptFlags         end

VOF_GEOMETRY_INVALID  
Set by MSG_VIS_MARK_INVALID, which, if followed by a 
MSG_VIS_VUP_UPDATE_WIN_GROUP will insure that changes 
in the object bounds will be reflected in the window.

VOF_GEO_UPDATE_PATH  
Set by MSG_VIS_MARK_INVALID to leave a trail to objects that 
have invalid geometry, for UPDATE_GEOMETRY to follow.

VOF_IMAGE_INVALID  
Set by MSG_VIS_MARK_INVALID, which, if followed by a 
MSG_VIS_VUP_UPDATE_WIN_GROUP will insure that visual 
changes in the object will be reflected in the window.

VOF_IMAGE_UPDATE_PATH  
Set by MSG_VIS_MARK_INVALID to leave a trail to objects that 
have invalid geometry, for UPDATE_WINDOWS_AND_IMAGE to 
follow.

VOF_WINDOW_INVALID  
Set by MSG_VIS_MARK_INVALID, which, if followed by a 
MSG_VIS_VUP_UPDATE_WIN_GROUP will insure that changes 
in the window's view will be reflected in the window. (valid for 
windows only)

VOF_WINDOW_UPDATE_PATH  
Set by MSG_VIS_MARK_INVALID to leave a trail to windows 
that have invalid views, for UPDATE_WINDOWS_AND_IMAGE 
to follow. (valid for composites only).

VOF_UPDATE_PENDING  
Used for Group windows only, indicates that a 
MSG_VIS_UPDATE_WIN_GROUP is still in the UI event queue 
for this window, and hasn't arrived yet.

VOF_UPDATING  
Set while updating visible branch, so we can give an error if we 
get into a nested update situation. Also may be useful for 
knowing how to update an object.

**Library:** Objects/visC.def

----------
#### VisRulerAttributes
    VisRulerAttributes      record
        VRA_IGNORE_ORIGIN       :1
        VRA_SHOW_GUIDES         :1
        VRA_SHOW_GRID           :1
        VRA_SHOW_MOUSE          :1
        VRA_HORIZONTAL          :1
        VRA_MASTER              :1
                                :2
    VisRulerAttributes      end

**Library:** ruler.def

----------
#### VisRulerConstrainStrategy
    VisRulerConstrainStrategy               record
        VRCS_OVERRIDE                                   :1
                                                        :1
        VRCS_SET_REFERENCE                              :1
        VRCS_SNAP_TO_GRID_X_ABSOLUTE                    :1
        VRCS_SNAP_TO_GRID_Y_ABSOLUTE                    :1
        VRCS_SNAP_TO_GRID_X_RELATIVE                    :1
        VRCS_SNAP_TO_GRID_Y_RELATIVE                    :1
        VRCS_SNAP_TO_GUIDES_X                           :1
        VRCS_SNAP_TO_GUIDES_Y                           :1
        VRCS_CONSTRAIN_TO_HORIZONTAL_AXIS               :1
        VRCS_CONSTRAIN_TO_VERTICAL_AXIS                 :1
        VRCS_CONSTRAIN_TO_UNITY_SLOPE_AXIS              :1
        VRCS_CONSTRAIN_TO_NEGATIVE_UNITY_SLOPE_AXIS     :1
        VRCS_CONSTRAIN_TO_VECTOR                        :1
        VRCS_CONSTRAIN_TO_VECTOR_REFLECTION             :1
        VRCS_INTERNAL                                   :1
    VisRulerConstrainStrategy               end

**Library:** ruler.def

----------
#### VisRulerNotifyGuideChangeBlockHeader
    VisRulerNotifyGuideChangeBlockHeader    struct
        VRNGCBH_header                  LMemBlockHeader
        VRNGCBH_vertGuideArray          word
        VRNGCBH_horizGuideArray         word
    VisRulerNotifyGuideChangeBlockHeader    ends

**Library:** ruler.def

----------
#### VisRulerType
    VisRulerType        etype byte, 0
        VRT_INCHES          enum VisRulerType
        VRT_CENTIMETERS     enum VisRulerType
        VRT_POINTS          enum VisRulerType
        VRT_PICAS           enum VisRulerType
        VRT_CUSTOM          enum VisRulerType, 0xfd     ;custom ruler definition
        VRT_NONE            enum VisRulerType, 0xfe     ;no rulers
        VRT_DEFAULT         enum VisRulerType, 0xff     ;use system default

**Library:** ruler.def

----------
#### VisTextAddNameParams
    VisTextAddNameParams            struct
        VTANP_name          fptr.char       ; pointer to name
        VTANP_size          word            ; length of name (0 if null-terminated)
        VTANP_flags         NameArrayAddFlags
        VTANP_data          VisTextNameData
    VisTextAddNameParams            ends

**Library:** Objects/vTextC.def

----------
#### VisTextCachedRunInfo
    VisTextCachedRunInfo            struct
        VTCRI_lastCharAttrRun           dword
        VTCRI_lastParaAttrRun           dword
        VTCRI_lastTypeRun               dword
        VTCRI_lastGraphicRun            dword
    VisTextCachedRunInfo            ends

**Library:** Objects/vTextC.def

----------
#### VisTextCachedUndoInfo
    VisTextCachedUndoInfo           struct
        VTCUI_vmChain           dword
        VTCUI_file              hptr
    VisTextCachedUndoInfo           ends

**Library:** Objects/vTextC.def

----------
#### VisTextCharAttr
    VisTextCharAttr     struct
        VTCA_meta               StyleSheetElementHeader
        VTCA_fontID             FontID
        VTCA_pointSize          WBFixed
        VTCA_textStyles         TextStyle
        VTCA_color              ColorQuad
        VTCA_trackKerning       sword
        VTCA_fontWeight         byte
        VTCA_fontWidth          byte
        VTCA_extendedStyles     VisTextExtendedStyles
        VTCA_grayScreen         SystemDrawMask          ; foreground gray screen
        VTCA_pattern            GraphicPattern          ; Foreground pattern
        VTCA_bgColor            ColorQuad               ; Background color
        VTCA_bgGrayScreen       SystemDrawMask          ; Background gray screen
        VTCA_bgPattern          GraphicPattern          ; Background pattern
        VTCA_reserved           byte 7 dup (0)
    VisTextCharAttr     ends

**Library:** Objects/Text/tCommon.def

----------
#### VisTextCharAttrDiffs
    VisTextCharAttrDiffs            struct
        VTCAD_diffs             VisTextCharAttrFlags
        VTCAD_extendedStyles    VisTextExtendedStyles
        VTCAD_textStyles        TextStyle
        even
    VisTextCharAttrDiffs            ends

**Library:** Objects/vTextC.def

----------
#### VisTextCharAttrFlags
    VisTextCharAttrFlags            record
        VTCAF_MULTIPLE_FONT_IDS         :1  ;Set if more than one font
        VTCAF_MULTIPLE_POINT_SIZES      :1  ;Set if more than one point size
        VTCAF_MULTIPLE_COLORS           :1  ;Set if more than one color
        VTCAF_MULTIPLE_GRAY_SCREENS     :1  ;Set if more than one gray screen
        VTCAF_MULTIPLE_PATTERNS         :1  ;Set if more than one hatch
        VTCAF_MULTIPLE_TRACK_KERNINGS   :1  ;Set if more than 
                                            ; one track kerning
        VTCAF_MULTIPLE_FONT_WEIGHTS     :1  ;Set if more than one font weight
        VTCAF_MULTIPLE_FONT_WIDTHS      :1  ;Set if more than one font width
        VTCAF_MULTIPLE_BG_COLORS        :1  ;Set if more than one bg color
        VTCAF_MULTIPLE_BG_GRAY_SCREENS  :1  ;Set if more than one bg gray screen
        VTCAF_MULTIPLE_BG_PATTERNS      :1  ;Set if more than one bg hatch
        VTCAF_MULTIPLE_STYLES           :1  ;Set if more than one (ssheet) style
                                        :4
    VisTextCharAttrFlags            end

**Library:** Objects/vTextC.def

----------
#### VisTextClearAllTabsParams
    VisTextClearAllTabsParams               struct
        VTCATP_range            VisTextRange
    VisTextClearAllTabsParams               ends

**Library:** Objects/vTextC.def

----------
#### VisTextClearTabParams
    VisTextClearTabParams           struct
        VTCTP_range         VisTextRange
        VTCTP_position      word            ; In units of points * 8
    VisTextClearTabParams           ends

**Library:** Objects/vTextC.def

----------
#### VisTextContextType
    VisTextContextType      etype byte
        VTCT_TEXT               enum VisTextContextType
        VTCT_CATEGORY           enum VisTextContextType
        VTCT_QUESTION           enum VisTextContextType
        VTCT_ANSWER             enum VisTextContextType
        VTCT_DEFINITION         enum VisTextContextType
        VTCT_FILE               enum VisTextContextType, 255

**Library:** Objects/vTextC.def

----------
#### VisTextCursorPositionChange
    VisTextCursorPositionChange     struct
        VTCPC_lineNumber        dword
        VTCPC_rowNumber         dword
    VisTextCursorPositionChange     ends

**Library:** Objects/vTextC.def

----------
#### VisTextCustomFilterData
    VisTextCustomFilterData         struct
        VTCFD_startOfRange              word
        VTCFD_endOfRange                word
    VisTextCustomFilterData         ends

**Library:** Objects/vTextC.def

----------
#### VisTextDefaultCharAttr
    VisTextDefaultCharAttr          record
        VTDCA_UNDERLINE     :1
        VTDCA_BOLD          :1
        VTDCA_ITALIC        :1
                            :1
        VTDCA_COLOR         Color:4
        VTDCA_SIZE          VisTextDefaultSize:3
        VTDCA_FONT          VisTextDefaultFont:5
    VisTextDefaultCharAttr          end

**Library:** Objects/Text/tCommon.def

----------
#### VisTextDefaultDefaultTab
    VisTextDefaultDefaultTab            etype byte
        VTDDT_NONE          enum VisTextDefaultDefaultTab
        VTDDT_HALF_INCH     enum VisTextDefaultDefaultTab
        VTDDT_INCH          enum VisTextDefaultDefaultTab
        VTDDT_CENTIMETER    enum VisTextDefaultDefaultTab

**Library:** Objects/Text/tCommon.def

----------
#### VisTextDefaultFont
    VisTextDefaultFont      etype byte
        VTDF_BERKELEY               enum VisTextDefaultFont ;Bitmap font
        VTDF_CHICAGO                enum VisTextDefaultFont ;Bitmap font
        VTDF_BISON                  enum VisTextDefaultFont ;Bitmap font
        VTDF_WINDOWS                enum VisTextDefaultFont ;Bitmap font
        VTDF_LED                    enum VisTextDefaultFont ;Bitmap font
        VTDF_ROMA                   enum VisTextDefaultFont ;Bitmap font
        VTDF_UNIVERSITY             enum VisTextDefaultFont ;Bitmap font

        VTDF_URW_ROMAN              enum VisTextDefaultFont ;Nimbus-Q font
        VTDF_URW_SANS               enum VisTextDefaultFont ;Nimbus-Q font
        VTDF_URW_MONO               enum VisTextDefaultFont ;Nimbus-Q font
        VTDF_URW_SYMBOLPS           enum VisTextDefaultFont ;Nimbus-Q font
        VTDF_CENTURY_SCHOOLBOOK     enum VisTextDefaultFont ;Nimbus-Q font

**Library:** Objects/Text/tCommon.def

----------
#### VisTextDefaultParaAttr
    VisTextDefaultParaAttr          record
        VTDPA_JUSTIFICATION     Justification:2
        VTDPA_DEFAULT_TABS      VisTextDefaultDefaultTab:2
        VTDPA_LEFT_MARGIN       :4          ;In units of half inches
        VTDPA_PARA_MARGIN       :4          ;In units of half inches
        VTDPA_RIGHT_MARGIN      :4          ;In units of half inches -- 0 means
                                            ;VIS_TEXT_MAX_PARA_ATTR_SIZE
    VisTextDefaultParaAttr          end

**Library:** Objects/Text/tCommon.def

----------
#### VisTextDefaultSize
    VisTextDefaultSize      etype byte
        VTDS_8      enum VisTextDefaultSize
        VTDS_9      enum VisTextDefaultSize
        VTDS_10     enum VisTextDefaultSize
        VTDS_12     enum VisTextDefaultSize
        VTDS_14     enum VisTextDefaultSize
        VTDS_18     enum VisTextDefaultSize
        VTDS_24     enum VisTextDefaultSize
        VTDS_36     enum VisTextDefaultSize

**Library:** Objects/Text/tCommon.def

----------
#### VisTextDropCapInfo
    VisTextDropCapInfo          record
        VTDCI_CHAR_COUNT    :4 = 1-1    ; # characters for drop cap charAttr
        VTDCI_LINE_COUNT    :4 = 3-1    ; # lines for drop cap
        VTDCI_POSITION      :4 = 1-1    ; 0 is full drop cap
                                        ; lineCount-1 is full tall cap
                            :4
    VisTextDropCapInfo          end

**Library:** Objects/Text/tCommon.def

----------
#### VisTextExtendedFilterType
    VisTextExtendedFilterType               etype byte
        VTEFT_REPLACE_PARAMS            enum VisTextExtendedFilterType
        VTEFT_CHARACTER_LEVELER_LEVEL   enum VisTextExtendedFilterType
        VTEFT_BEFORE_AFTER              enum VisTextExtendedFilterType

VTEFT_REPLACE_PARAMS  
This causes MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS 
to be sent.

VTEFT_CHARACTER_LEVELER_LEVEL  
This causes MSG_VIS_TEXT_FILTER_VIA_CHARACTER to be 
sent.

VTEFT_BEFORE_AFTER  
This causes MSG_VIS_TEXT_FILTER_VIA_BEFORE_AFTER to 
be sent.

**Library:** Objects/vTextC.def

----------
#### VisTextExtendedStyles
    VisTextExtendedStyles           record
        VTES_BOXED              :1
        VTES_BUTTON             :1
        VTES_INDEX              :1      ; text should be indexed
        VTES_ALL_CAP            :1
        VTES_SMALL_CAP          :1
        VTES_HIDDEN             :1
        VTES_CHANGE_BAR         :1
        VTES_BACKGROUND_COLOR   :1
                                :8
    VisTextExtendedStyles           end

**Library:** Objects/Text/tCommon.def

----------
#### VisTextFeatures
    VisTextFeatures     record
        VTF_NO_WORD_WRAPPING            :1  ; Set: no word-wrapping is desired.
        VTF_AUTO_HYPHENATE              :1  ; Set: if we want to auto hyphenate.
        VTF_ALLOW_SMART_QUOTES          :1  ; Set: allows smart quotes if they 
                                            ; are enabled.
        VTF_ALLOW_UNDO                  :1  ; Set: allows undo in this object
        VTF_SHOW_HIDDEN_TEXT            :1  ; Set: Show text marked as hidden
                                            ; *** Not implemented ***
        VTF_OUTLINE_MODE                :1  ; Set: show text in outline mode
                                            ; *** Not implemented ***
        VTF_DONT_SHOW_SOFT_PAGE_BREAKS  :1  ; Set: don't display soft (non
                                            ; C_PAGE_BREAK) page breaks
                                            ; *** Not implemented ***
        VTF_DONT_SHOW_GRAPHICS          :1  ; Draw graphics as gray rectangles
                                            ; *** Not implemented ***
        VTF_TRANSPARENT                 :1  ; Set: don't use wash color on DRAW
        VTF_USE_50_PCT_TEXT_MASK        :1  ; Set: force 50% draw mask for  
                                            ; drawing, ignoring char attr runs. 
                                            ; Used by specific GenText objects.
                                        :6
    VisTextFeatures     end

**Library:** Objects/vTextC.def

----------
#### VisTextFilters
    VisTextFilters      record
        VTF_NO_SPACES       :1          ;no spaces allowed
        VTF_NO_TABS         :1          ;no tabs
        VTF_UPCASE_CHARS    :1          ;make uppercase
        VTF_FILTER_CLASS    VisTextFilterClass:5    ;filter classes
                                        ;(keep in low bits!)
    VisTextFilters      end

**Library:** Objects/vTextC.def

----------
#### VisTextFilterClass
    VisTextFilterClass      etype byte
        VTFC_NO_FILTER              enum VisTextFilterClass ;no filter
        VTFC_ALPHA                  enum VisTextFilterClass ;alpha chars only
        VTFC_NUMERIC                enum VisTextFilterClass ;numeric only
        VTFC_SIGNED_NUMERIC         enum VisTextFilterClass ;signed numeric
        VTFC_SIGNED_DECIMAL         enum VisTextFilterClass ;numeric, with decimal
        VTFC_FLOAT_DECIMAL          enum VisTextFilterClass ;numeric,decimal,e,E
        VTFC_ALPHA_NUMERIC          enum VisTextFilterClass ;alphanumeric
        VTFC_FILENAMES              enum VisTextFilterClass ;legal PCGEOS filenames
        VTFC_DOS_FILENAMES          enum VisTextFilterClass ;legal DOS filenames
        VTFC_DOS_PATH               enum VisTextFilterClass ;legal DOS path
        VTFC_DATE                   enum VisTextFilterClass ;legal date
        VTFC_TIME                   enum VisTextFilterClass ;legal time
        VTFC_DASHED_ALPHA_NUMERIC   enum VisTextFilterClass ;alphanumeric plus '-'
        VTFC_NORMAL_ASCII           enum VisTextFilterClass ;normal ascii chars
        VTFC_DOS_VOLUME_NAMES       enum VisTextFilterClass ;legal DOS volume names
        VTFC_DOS_CHARACTER_SET      enum VisTextFilterClass ;DOS character set
        VTFC_ALLOW_COLUMN_BREAKS    enum VisTextFilterClass ;Allow column-breaks

**Library:** Objects/vTextC.def

----------
#### VisTextFindNameParams
    VisTextFindNameParams           struct
        VTFNP_name      fptr.char           ; pointer to name to find
        VTFNP_size      word                ; length of name (0 if null-terminated)
        VTFNP_data      fptr.VisTextNameData ; buffer for data (0 if none)
    VisTextFindNameParams           ends

This structure is passed with MSG_VIS_TEXT_FIND_NAME.

**Library:** Objects/vTextC.def

----------
#### VisTextFollowHyperlinkParams
    VisTextFollowHyperlinkParams                struct
        VTFHLP_range    VisTextRange    ; range of characters in the selection
    VisTextFollowHyperlinkParams                ends

**Library:** Objects/vTextC.def

----------
#### VisTextGenerateNotifyParams
    VisTextGenerateNotifyParams             struct
        VTGNP_notificationTypes     VisTextNotificationFlags
        VTGNP_sendFlags             VisTextNotifySendFlags
        VTGNP_notificationBlocks    hptr 16 dup (?)
    VisTextGenerateNotifyParams             ends

**Library:** Objects/vTextC.def

----------
#### VisTextGetAttrFlags
    VisTextGetAttrFlags         record
        VTGAF_MERGE_WITH_PASSED     :1  ;If set then merge the attributes for
                                        ;this object with the passed attributes
                                    :15
    VisTextGetAttrFlags         end

**Library:** Objects/vTextC.def

----------
#### VisTextGetAttrParams
    VisTextGetAttrParams            struct
        VTGAP_range     VisTextRange
        VTGAP_attr      fptr                ; attribute structure
        VTGAP_return    fptr                ; diff structure
        VTGAP_flags     VisTextGetAttrFlags
    VisTextGetAttrParams            ends

**Library:** Objects/vTextC.def

----------
#### VisTextGetGraphicAtPositionParams
    VisTextGetGraphicAtPositionParams                   struct
        VTGGAPP_position                dword
        VTGGAPP_retPtr                  fptr.VisTextGraphic
    VisTextGetGraphicAtPositionParams                   ends

**Library:** Objects/vTextC.def

----------
#### VisTextGetLineInfoParameters
    VisTextGetLineInfoParameters                struct
        VTGLIP_buffer   fptr.LineInfo   ;pointer to buffer to store results
        VTGLIP_bsize    word            ; size of buffer
        VTGLIP_line     dword           ; specific line that we're interested in
    VisTextGetLineInfoParameters                ends

This structure is passed with MSG_VIS_TEXT_GET_LINE_INFO. That method 
fills in the buffer specified by *VTGLIP_buffer* with a **LineInfo** structure 
followed by a variable number of **FieldInfo** structures.

**Library:** Objects/vTextC.def

----------
#### VisTextGetLineOffsetAndFlagsParameters
    VisTextGetLineOffsetAndFlagsParameters struct
        VTGLOAFP_line       dword           ; line to get information about
        ;
        ; The following entries are filled in by the handler for 
        ; MSG_VIS_TEXT_GET_LINE_OFFSET_AND_FLAGS.
        ;
        VTGLOAFP_offset     dword           ; offset to line start
        VTGLOAFP_flags      LineFlags       ; LineFlags
    VisTextGetLineOffsetAndFlagsParameters ends

**Library:** Objects/vTextC.def

----------
#### VisTextGetRunBoundsParams
    VisTextGetRunBoundsParams       struct
        VTGRBP_position dword               ; Position to check for run around
        VTGRBP_type     word                ; Run offset
        VTGRBP_retVal   fptr.VisTextRange   ; Ptr to VisTextRange to fill 
                                            ; in with the bounds of the run
    VisTextGetRunBoundsParams       ends

**Library:** Objects/vTextC.def

----------
#### VisTextGetTextRangeFlags
    VisTextGetTextRangeFlags            record
        VTGTRF_ALLOCATE         :1
        VTGTRF_ALLOCATE_ALWAYS  :1
        VTGTRF_RESIZE_DEST      :1
                                :5
    VisTextGetTextRangeFlags            end

VTGTRF_ALLOCATE  
If set, requests that the destination be allocated. Otherwise, 
use destination provided

VTGTRF_ALLOCATE_ALWAYS  
If set, asks that destination be allocated even if there is no text 
to copy. 

VTGTRF_RESIZE_DEST  
If set, will resize the destination (if possible) so that it is just 
large enough to hold the text and no larger.

**Library:** Objects/vTextC.def

----------
#### VisTextGetTextRangeParameters
    VisTextGetTextRangeParameters                   struct
        VTGTRP_range            VisTextRange        ; range to get
        VTGTRP_textReference    TextReference       ; Reference to the text
        VTGTRP_flags            VisTextGetTextRangeFlags
        align                   word
    VisTextGetTextRangeParameters                   ends

**Library:** Objects/vTextC.def

----------
#### VisTextGraphic
    VisTextGraphic          struct
        VTG_meta        RefElementHeader        ; basic element header
        VTG_vmChain     dword
        VTG_size        XYSizeis var
        VTG_type        VisTextGraphicType
        VTG_flags       VisTextGraphicFlags
        VTG_reserved    byte 4 dup (?)
        VTG_data        VisTextGraphicData
    VisTextGraphic          ends

This structure defines a text graphic element.

*VTG_vmChain* stores a dword value to pass to VMChain routines. If only the 
low word is zero, then the high word is a VM handle. If both words are 
non-zero, the dword specifies a DB item; the high word specifies the DB group, 
the low word specifies the DB item itself. If the high word is zero, then the 
low word is an **LMemChunk**. If both words are zero, then there is no data.

*VTG_size* stores the size of the graphic. If this value is zero, then the graphic's 
size is determined dynamically.

**Library:** Objects/vTextC.def

----------
#### VisTextGraphicData
    VisTextGraphicData          union
        VTGD_gstring        VisTextGraphicGString
        VTGD_variable       VisTextGraphicVariable
        VTGD_opaque         VisTextGraphicOpaque
    VisTextGraphicData          end

**Library:** Objects/vTextC.def

----------
#### VisTextGraphicFlags
    VisTextGraphicFlags     record
        VTGF_DRAW_FROM_BASELINE :1  ;If set then draw from baseline else
                                    ;draw from top
        VTGF_HANDLES_POINTER    :1  ;Graphic can deal with pointer messages
                                :14
    VisTextGraphicFlags     end

**Library:** Objects/vTextC.def

----------
#### VisTextGraphicGString
    VisTextGraphicGString           struct
        VTGG_tmatrix            TransMatrix
        VTGG_drawOffset         XYOffset
    VisTextGraphicGString           ends

**Library:** Objects/vTextC.def

----------
#### VisTextGraphicType
    VisTextGraphicType      etype byte
        VTGT_GSTRING            enum VisTextGraphicType
        VTGT_VARIABLE           enum VisTextGraphicType

**Library:** Objects/vTextC.def

----------
#### VisTextGraphicVariable
    VisTextGraphicVariable          struct
        VTGV_manufacturerID ManufacturerID
        VTGV_type           VisTextVariableType
        VTGV_privateData    byte (VIS_TEXT_GRAPHIC_OPAQUE_SIZE-4) dup (?)
    VisTextGraphicVariable          ends

**Library:** Objects/vTextC.def

----------
#### VisTextHWRFlags
    VisTextHWRFlags     record
        VTHWRF_NO_CONTEXT               :1
        VTHWRF_USE_PASSED_CONTEXT       :1
                                        :14
    VisTextHWRFlags     end

VTHWRF_NO_CONTEXT  
This is sent when the ink is being quick-copied to the object, or in other cases 
where the user did not draw the ink on top of the object, and so the position 
of the object is not useful information for the recognizer.

**Library:** 

----------
#### VisTextHyphenationInfo
    VisTextHyphenationInfo          record
        VTHI_HYPHEN_MAX_LINES           :4 = 3-1
        VTHI_HYPHEN_SHORTEST_WORD       :4 = 5-1
        VTHI_HYPHEN_SHORTEST_PREFIX     :4 = 3-1
        VTHI_HYPHEN_SHORTEST_SUFFIX     :4 = 3-1
    VisTextHyphenationInfo          end

**Library:** Objects/Text/tCommon.def

----------
#### VisTextIntFlags
    VisTextIntFlags     record
        VTIF_HAS_LINES              :1  ;Object has valid line structures.
        VTIF_SUSPENDED              :1  ;Set if calculation suspended
        VTIF_UPDATE_PENDING         :1  ;Update is about to be delivered.
        VTIF_ACTIVE_SEARCH_SPELL    ActiveSearchSpellType:2
                                        ;Set if a search/spell session is in 
                                        ;progress.
        VTIF_HILITED                :1  ;Set: We have drawn the hilite.
        VTIF_ADJUST_TYPE            AdjustType:2
                                        ; How to adjust the selection.
    VisTextIntFlags     end

**Library:** Objects/vTextC.def

----------
#### VisTextIntSelFlags
    VisTextIntSelFlags      record
        VTISF_IS_TARGET             :1  ; Set if the object is the target.
        VTISF_IS_FOCUS              :1  ; Set if the object is the focus.
        VTISF_CURSOR_ON             :1  ; Set if the cursor is drawn.
        VTISF_CURSOR_ENABLED        :1  ; Set if the cursor is enabled.
        VTISF_DOING_SELECTION       :1  ; Set if we are doing some selection.
                                        ; (Basically if the mouse is down).
        VTISF_DOING_DRAG_SELECTION  :1  ; Set if we have positioned the cursor.
                                        ; (also doubles as flag that indicates
                                        ; we are doing quick-transfer feedback)
        VTISF_SELECTION_TYPE        SelectionType:2
    VisTextIntSelFlags      end

**Library:** Objects/vTextC.def

----------
#### VisTextKeepInfo
    VisTextKeepInfo     record
        VTKI_TOP_LINES      :4      ; # lines at start of PP to keep together
        VTKI_BOTTOM_LINES   :4      ; # lines at end of PP to keep together
    VisTextKeepInfo     end

**Library:** Objects/Text/tCommon.def

----------
#### VisTextKeyFunction
    VisTextKeyFunction      etype word, 0, 6
        VTKF_FORWARD_LINE                       enum    VisTextKeyFunction
        VTKF_BACKWARD_LINE                      enum    VisTextKeyFunction
        VTKF_SELECT_ADJUST_FORWARD_LINE         enum    VisTextKeyFunction
        VTKF_SELECT_ADJUST_BACKWARD_LINE        enum    VisTextKeyFunction
        VTKF_FORWARD_CHAR                       enum    VisTextKeyFunction
        VTKF_BACKWARD_CHAR                      enum    VisTextKeyFunction
        VTKF_FORWARD_WORD                       enum    VisTextKeyFunction
        VTKF_BACKWARD_WORD                      enum    VisTextKeyFunction
        VTKF_FORWARD_PARAGRAPH                  enum    VisTextKeyFunction
        VTKF_BACKWARD_PARAGRAPH                 enum    VisTextKeyFunction
        VTKF_START_OF_LINE                      enum    VisTextKeyFunction
        VTKF_END_OF_LINE                        enum    VisTextKeyFunction
        VTKF_START_OF_TEXT                      enum    VisTextKeyFunction
        VTKF_END_OF_TEXT                        enum    VisTextKeyFunction
        VTKF_SELECT_WORD                        enum    VisTextKeyFunction

            ;==========================================
            ; None of the following entries are supported:
            ;   VTKF_SELECT_LINE
            ;   VTKF_SELECT_PARAGRAPH
            ;   VTKF_SELECT_OBJECT
            ;
        VTKF_SELECT_LINE                        enum    VisTextKeyFunction
        VTKF_SELECT_PARAGRAPH                   enum    VisTextKeyFunction
        VTKF_SELECT_OBJECT                      enum    VisTextKeyFunction
            ;==========================================
        VTKF_SELECT_ADJUST_FORWARD_CHAR         enum    VisTextKeyFunction
        VTKF_SELECT_ADJUST_BACKWARD_CHAR        enum    VisTextKeyFunction
        VTKF_SELECT_ADJUST_FORWARD_WORD         enum    VisTextKeyFunction
        VTKF_SELECT_ADJUST_BACKWARD_WORD        enum    VisTextKeyFunction
        VTKF_SELECT_ADJUST_FORWARD_PARAGRAPH    enum    VisTextKeyFunction
        VTKF_SELECT_ADJUST_BACKWARD_PARAGRAPH   enum    VisTextKeyFunction
        VTKF_SELECT_ADJUST_TO_START             enum    VisTextKeyFunction
        VTKF_SELECT_ADJUST_TO_END               enum    VisTextKeyFunction
        VTKF_SELECT_ADJUST_START_OF_LINE        enum    VisTextKeyFunction
        VTKF_SELECT_ADJUST_END_OF_LINE          enum    VisTextKeyFunction
        VTKF_DELETE_BACKWARD_CHAR               enum    VisTextKeyFunction
        VTKF_DELETE_BACKWARD_WORD               enum    VisTextKeyFunction
        VTKF_DELETE_BACKWARD_LINE               enum    VisTextKeyFunction
        VTKF_DELETE_BACKWARD_PARAGRAPH          enum    VisTextKeyFunction
        VTKF_DELETE_TO_START                    enum    VisTextKeyFunction
        VTKF_DELETE_CHAR                        enum    VisTextKeyFunction
        VTKF_DELETE_WORD                        enum    VisTextKeyFunction
        VTKF_DELETE_LINE                        enum    VisTextKeyFunction
        VTKF_DELETE_PARAGRAPH                   enum    VisTextKeyFunction
        VTKF_DELETE_TO_END                      enum    VisTextKeyFunction
        VTKF_DELETE_EVERYTHING                  enum    VisTextKeyFunction
        VTKF_DESELECT                           enum    VisTextKeyFunction
        VTKF_TOGGLE_OVERSTRIKE_MODE             enum    VisTextKeyFunction
        VTKF_TOGGLE_SMART_QUOTES                enum    VisTextKeyFunction

**Library:** Objects/vTextC.def

----------
#### VisTextLoadFromDBWithStylesParams
    VisTextLoadFromDBWithStylesParams       struct
        VTLFDBWSP_params    fptr.StyleSheetParams
        VTLFDBWSP_dbItem    dword               ; DB item to load from
        VTLFDBWSP_file      hptr                ; file handle (or 0)
    VisTextLoadFromDBWithStylesParams       ends

**Library:** Objects/vTextC.def

----------
#### VisTextMaxParaAttr
    VisTextMaxParaAttr      struct
        VTMPA_paraAttr          VisTextParaAttr
        VTMPA_tabs              Tab VIS_TEXT_MAX_TABS dup (<>)
    VisTextMaxParaAttr      ends

**Library:** Objects/Text/tCommon.def

----------
#### VisTextMinimumDimensionsParameters
    VisTextMinimumDimensionsParameters  struc
        VTMDP_height            WBFixed
        VTMDP_width             WBFixed
    VisTextMinimumDimensionsParameters  ends

**Library:** Objects/vTextC.def

----------
#### VisTextMoveTabParams
    VisTextMoveTabParams            struct
        VTMTP_range             VisTextRange
        VTMTP_destPosition      word            ; in units of points * 8
        VTMTP_sourcePosition    word            ; in units of points * 8
    VisTextMoveTabParams            ends

**Library:** Objects/vTextC.def

----------
#### VisTextNameArrayElement
    VisTextNameArrayElement         struc
        VTNAE_meta          NameArrayElement
        VTNAE_data          VisTextNameData
    VisTextNameArrayElement         ends

**Library:** Objects/vTextC.def

----------
#### VisTextNameCommonParams
    VisTextNameCommonParams         struct
        VTNCP_data      VisTextNameData
        VTNCP_index     word            ; index of name
        VTNCP_object    optr            ; optr of text or list object
    VisTextNameCommonParams         ends

**Library:** Objects/vTextC.def

----------
#### VisTextNameData
    VisTextNameData     struct
        VTND_type           VisTextNameType
        VTND_contextType    VisTextContextType
        VTND_file           word                ; token of file
        VTND_helpText       DBGroupAndItem      ; help text
    VisTextNameData     ends

**Library:** Objects/vTextC.def

----------
#### VisTextNameType
    VisTextNameType     etype byte
        VTNT_CONTEXT        enum VisTextNameType
        VTNT_FILE           enum VisTextNameType

**Library:** Objects/vTextC.def

----------
#### VisTextNotificationFlags
    VisTextNotificationFlags            record
        VTNF_SELECT_STATE           :1
        VTNF_CHAR_ATTR              :1
        VTNF_PARA_ATTR              :1
        VTNF_TYPE                   :1
        VTNF_SELECTION              :1
        VTNF_COUNT                  :1
        VTNF_STYLE_SHEET            :1
        VTNF_STYLE                  :1
        VTNF_SEARCH_ENABLE          :1
        VTNF_SPELL_ENABLE           :1
        VTNF_NAME                   :1
        VTNF_CURSOR_POSITION        :1
                                    :4
    VisTextNotificationFlags            end

**Library:** Objects/vTextC.def

----------
#### VisTextNotifyCharAttrChange
    VisTextNotifyCharAttrChange             struct
        VTNCAC_charAttr             VisTextCharAttr
        VTNCAC_charAttrToken        word
        VTNCAC_charAttrDiffs        VisTextCharAttrDiffs
    VisTextNotifyCharAttrChange             ends

**Library:** Objects/vTextC.def

----------
#### VisTextNotifyCountChange
    VisTextNotifyCountChange            struct
        VTNCC_charCount             dword
        VTNCC_wordCount             dword
        VTNCC_lineCount             dword
        VTNCC_paraCount             dword
    VisTextNotifyCountChange            ends

**Library:** Objects/vTextC.def
----------
#### VisTextNotifyNameChange
    VisTextNotifyNameChange         struct
        VTNNC_count         word
    VisTextNotifyNameChange         ends

**Library:** Objects/vTextC.def

----------
#### VisTextNotifyParaAttrChange
    VisTextNotifyParaAttrChange             struct
        VTNPAC_paraAttr                 VisTextMaxParaAttr
        VTNPAC_paraAttrToken            word
        VTNPAC_paraAttrDiffs            VisTextParaAttrDiffs
        VTNPAC_regionOffset             sdword
        VTNPAC_regionWidth              sword
        VTNPAC_selectedTab              word
    VisTextNotifyParaAttrChange             ends

**Library:** Objects/vTextC.def

----------
#### VisTextNotifySelectionChange
    VisTextNotifySelectionChange                struct
        VTNSC_selectStart           dword
        VTNSC_selectEnd             dword
        VTNSC_lineNumber            dword
        VTNSC_lineStart             dword
        VTNSC_region                word
        VTNSC_regionStartLine       dword
        VTNSC_regionStartOffset     dword
    VisTextNotifySelectionChange                ends

**Library:** Objects/vTextC.def

----------
#### VisTextNotifySendFlags
    VisTextNotifySendFlags          record
        VTNSF_UPDATE_APP_TARGET_GCN_LISTS       :1
        VTNSF_NULL_STATUS                       :1
        VTNSF_STRUCTURE_INITIALIZED             :1
        VTNSF_SEND_AFTER_GENERATION             :1
        VTNSF_SEND_ONLY                         :1
        VTNSF_RELAYED_TO_LIKE_TEXT_OBJECTS      :1
                                                :10
    VisTextNotifySendFlags          end

VTNSF_UPDATE_APP_TARGET_GCN_LISTS  
Set if pertinent Application Target GCN Lists should be 
updated with changes in status.

VTNSF_NULL_STATUS  
Send notification of null status, for all notification types (used 
only to notify GCN Lists of loss of eligibility to update, i.e. lost 
target). The text output will always be sent only meaningful 
info.

VTNSF_STRUCTURE_INITIALIZED  
Set if the rest of the **VisTextGenerateNotifyParams** 
structure is initialized.

VTNSF_SEND_AFTER_GENERATION  
Set to send the notifications after generating them.

VTNSF_SEND_ONLY  
Set to send the notifications *only*.

VTNSF_RELAYED_TO_LIKE_TEXT_OBJECTS  
Set if the message has been registered with the object 
responsible for relaying the message to multiple text objects.

**Library:** Objects/vTextC.def

----------
#### VisTextNotifyTypeChange
    VisTextNotifyTypeChange         struct
        VTNTC_type              VisTextType
        VTNTC_typeToken         word
        VTNTC_typeDiffs         VisTextTypeDiffs
        VTNTC_index             VisTextType
    VisTextNotifyTypeChange         ends

**Library:** Objects/vTextC.def

----------
#### VisTextNumberType
    VisTextNumberType       etype word
        VTNT_NUMBER                 enum VisTextNumberType
        VTNT_LETTER_UPPER_A         enum VisTextNumberType
        VTNT_LETTER_LOWER_A         enum VisTextNumberType
        VTNT_ROMAN_NUMERAL_UPPER    enum VisTextNumberType
        VTNT_ROMAN_NUMERAL_LOWER    enum VisTextNumberType

**Library:** Objects/Text/tCommon.def

----------
    #### VisTextParaAttr
    VisTextParaAttr     struct
        VTPA_meta                   StyleSheetElementHeader
        VTPA_borderFlags            VisTextParaBorderFlags  ; border type
        VTPA_borderColor            ColorQuad               ; color for borders
        VTPA_attributes             VisTextParaAttrAttributes ; other attributes
        VTPA_leftMargin             word
        VTPA_rightMargin            word
        VTPA_paraMargin             word
        VTPA_lineSpacing            BBFixed <>              ; 1.0 is default
        VTPA_leading                word                    ; 13.3 is default
        VTPA_spaceOnTop             word                    ; 0.0 is default
        VTPA_spaceOnBottom          word                    ; 0.0 is default
        VTPA_bgColor                ColorQuad
        VTPA_numberOfTabs           byte
        VTPA_borderWidth            byte                    ; in points * 8
        VTPA_borderSpacing          byte                    ; in points * 8
        VTPA_borderShadow           byte                    ; in points * 8
        VTPA_borderGrayScreen       SystemDrawMask
        VTPA_bgGrayScreen           SystemDrawMask
        VTPA_borderPattern          GraphicPattern
        VTPA_defaultTabs            word                    ; spacing for default tabs
        VTPA_startingParaNumber     word
        VTPA_prependChars           char 4 dup (0)
        VTPA_hyphenationInfo        VisTextHyphenationInfo
        VTPA_keepInfo               VisTextKeepInfo
        VTPA_dropCapInfo            VisTextDropCapInfo
        VTPA_nextStyle              word
        VTPA_language               StandardLanguage
        VTPA_reserved               byte 15 dup (0)
        VTPA_tabList                label byte
    VisTextParaAttr     ends

**Library:** Objects/Text/tCommon.def

----------
#### VisTextParaAttrAttributes
    VisTextParaAttrAttributes               record
        VTPAA_JUSTIFICATION             Justification:2
        VTPAA_KEEP_PARA_WITH_NEXT       :1
        VTPAA_KEEP_PARA_TOGETHER        :1          ;Don't break up paragraph
        VTPAA_ALLOW_AUTO_HYPHENATION    :1          ;Use VisTextHyphenationInfo
        VTPAA_DISABLE_WORD_WRAP         :1
        VTPAA_COLUMN_BREAK_BEFORE       :1
        VTPAA_PARA_NUMBER_TYPE          VisTextNumberType:3
        VTPAA_DROP_CAP                  :1          ;Use VisTextDropCapInfo
        VTPAA_KEEP_LINES                :1          ;Use VisTextKeepInfo
                                        :4
    VisTextParaAttrAttributes               end

**Library:** Objects/Text/tCommon.def

----------
#### VisTextParaAttrBorderFlags
    VisTextParaAttrBorderFlags          record
        VTPABF_MULTIPLE_BORDER_LEFT         :1      ;Match with VTPBF_LEFT
        VTPABF_MULTIPLE_BORDER_TOP          :1      ;Match with VTPBF_TOP
        VTPABF_MULTIPLE_BORDER_RIGHT        :1      ;Match with VTPBF_RIGHT
        VTPABF_MULTIPLE_BORDER_BOTTOM       :1      ;Match with VTPBF_BOTTOM
        VTPABF_MULTIPLE_BORDER_DOUBLES      :1      ;Match with VTPBF_DOUBLE
        VTPABF_MULTIPLE_BORDER_DRAW_INNERS  :1      ;Match with VTPBF_DRAW_INNER
        VTPABF_MULTIPLE_BORDER_ANCHORS      :1
        VTPABF_MULTIPLE_BORDER_WIDTHS       :1
        VTPABF_MULTIPLE_BORDER_SPACINGS     :1
        VTPABF_MULTIPLE_BORDER_SHADOWS      :1
        VTPABF_MULTIPLE_BORDER_COLORS       :1
        VTPABF_MULTIPLE_BORDER_GRAY_SCREENS :1
        VTPABF_MULTIPLE_BORDER_PATTERNS     :1
                                            :3
    VisTextParaAttrBorderFlags          end

**Library:** Objects/vTextC.def

----------
#### VisTextParaAttrDiffs
    VisTextParaAttrDiffs            struct
        VTPAD_diffs             VisTextParaAttrFlags
        VTPAD_diffs2            VisTextParaAttrFlags2
        VTPAD_borderDiffs       VisTextParaAttrBorderFlags
        VTPAD_attributes        VisTextParaAttrAttributes
        VTPAD_hyphenationInfo   VisTextHyphenationInfo
        VTPAD_keepInfo          VisTextKeepInfo
        VTPAD_dropCapInfo       VisTextDropCapInfo
        even
    VisTextParaAttrDiffs            ends

**Library:** Objects/vTextC.def

----------
#### VisTextParaAttrFlags
    VisTextParaAttrFlags            record
        VTPAF_MULTIPLE_LEFT_MARGINS             :1
        VTPAF_MULTIPLE_RIGHT_MARGINS            :1
        VTPAF_MULTIPLE_PARA_MARGINS             :1
        VTPAF_MULTIPLE_LINE_SPACINGS            :1
        VTPAF_MULTIPLE_DEFAULT_TABS             :1
        VTPAF_MULTIPLE_TOP_SPACING              :1
        VTPAF_MULTIPLE_BOTTOM_SPACING           :1
        VTPAF_MULTIPLE_LEADINGS                 :1
        VTPAF_MULTIPLE_BG_COLORS                :1
        VTPAF_MULTIPLE_BG_GRAY_SCREENS          :1
        VTPAF_MULTIPLE_BG_PATTERNS              :1
        VTPAF_MULTIPLE_TAB_LISTS                :1
        VTPAF_MULTIPLE_STYLES                   :1
        VTPAF_MULTIPLE_PREPEND_CHARS            :1
        VTPAF_MULTIPLE_STARTING_PARA_NUMBERS    :1
        VTPAF_MULTIPLE_NEXT_STYLES              :1
    VisTextParaAttrFlags            end

**Library:** Objects/vTextC.def

----------
#### VisTextParaAttrFlags2
    VisTextParaAttrFlags2           record
        VTPAF2_MULTIPLE_LANGUAGES       :1
                                        :15
    VisTextParaAttrFlags2           end

**Library:** Objects/vTextC.def

----------
#### VisTextParaBorderFlags
    VisTextParaBorderFlags          record
        VTPBF_LEFT              :1      ;Set if a border on the left
        VTPBF_TOP               :1      ;Set if a border on the top
        VTPBF_RIGHT             :1      ;Set if a border on the right
        VTPBF_BOTTOM            :1      ;Set if a border on the bottom
        VTPBF_DOUBLE            :1      ;Draw two line border
        VTPBF_DRAW_INNER_LINES  :1      ;Draw lines between bordered paragraphs
        VTPBF_SHADOW            :1      ;Set to use shadow
                                :7
        VTPBF_ANCHOR            ShadowAnchor:2
    VisTextParaBorderFlags          end

**Library:** tCommon.def

----------
#### VisTextRange
    VisTextRange        struct
        VTR_start   dword       ; start of range
        VTR_end     dword       ; end of range
    VisTextRange        ends

**Library:** Objects/Text/tCommon.def

----------
#### VisTextRangeContext
    VisTextRangeContext         record
        VTRC_PARAGRAPH_CHANGE           :1  ;Change done on paragraph level.
        VTRC_CHAR_ATTR_CHANGE           :1  ; Used for a charAttr change (include 
                                            ; last CR, don't include next CR).
        VTRC_PARA_ATTR_BORDER_CHANGE    :1  ;Used for a paraAttr change.
                                            ;including a border.
                                        :13
    VisTextRangeContext         end

**Library:** Objects/vTextC.def

----------
#### VisTextReplaceFlags
    VisTextReplaceFlags         record
        VTRF_FILTER                     :1      ;Set to filter replacement
        VTRF_KEYBOARD_INPUT             :1      ;Set if data is coming from the 
                                                ; keyboard input    
        VTRF_USER_MODIFICATION          :1      ;Set if replace is due to a user 
                                                ;action
        VTRF_UNDO                       :1      ;Set if replace is due to an undo
        VTRF_DO_NOT_SEND_CONTEXT_UPDATE :1      ;Set if this is part of a
                                                ; multi-part replace, and so the
                                                ; text object should not send a 
                                                ; context update (used internally
                                                ; to the text object only)
                                        :11
    VisTextReplaceFlags         end

**Library:** Objects/vTextC.def

----------
#### VisTextReplaceParameters
    VisTextReplaceParameters            struct
        VTRP_range                  VisTextRange
        VTRP_insCount               dword           ; number of characters to 
                                                    ; insert
        VTRP_textReference          TextReference   ; reference to text to insert
        VTRP_flags                  VisTextReplaceFlags
        align                       word
    VisTextReplaceParameters            ends

This structure is passed with MSG_VIS_TEXT_REPLACE.

**Library:** Objects/vTextC.def

----------
#### VisTextReplaceWithHWRParams
    VisTextReplaceWithHWRParams             struct
        VTRWHWRP_range              VisTextRange
        VTRWHWRP_flags              VisTextHWRFlags
        VTRWHWRP_ink                hptr.InkHeader
        VTRWHWRP_context            HWRContext
    VisTextReplaceWithHWRParams             ends

**Library:** Objects/vTextC.def

----------
#### VisTextSaveDBFlags
    VisTextSaveDBFlags          record
        VTSDBF_TEXT         :1                  ;set if text is saved 
                                                ; (0 means null text)
        VTSDBF_CHAR_ATTR    VisTextSaveType:2
        VTSDBF_PARA_ATTR    VisTextSaveType:2
        VTSDBF_TYPE         VisTextSaveType:2
        VTSDBF_GRAPHIC      VisTextSaveType:2
        VTSDBF_STYLE        :1
        VTSDBF_REGION       :1                  ;not currently implemented
        VTSDBF_NAME         :1
                            :4
    VisTextSaveDBFlags          end

**Library:** Objects/vTextC.def

----------
#### VisTextSaveStyleSheetParams
    VisTextSaveStyleSheetParams     struct
        VTSSSP_common               StyleSheetParams
        VTSSSP_graphicsElements     word        ;VM block of graphics elements
        VTSSSP_treeBlock            word
        VTSSSP_graphicTreeOffset    word        ;offset in treeBlock
    VisTextSaveStyleSheetParams     ends

**Library:** Objects/vTextC.def

----------
#### VisTextSaveToDBWithStylesParams
    VisTextSaveToDBWithStylesParams         struct
        VTSTDBWSP_params    fptr.VisTextSaveStyleSheetParams
        VTSTDBWSP_dbItem    dword
        VTSTDBWSP_flags     VisTextSaveDBFlags
        VTSTDBWSP_xferFile  word
    VisTextSaveToDBWithStylesParams         ends

*VTSTDBWSP_dbItem* stores the DB item to save the text to.

**Library:** Objects/vTextC.def

----------
#### VisTextSaveType
    VisTextSaveType     etype byte
        VTST_NONE               enum VisTextSaveType    ;nothing saved
        VTST_SINGLE_CHUNK       enum VisTextSaveType    ;single attr structure
        VTST_RUNS_ONLY          enum VisTextSaveType
        VTST_RUNS_AND_ELEMENTS  enum VisTextSaveType

**Library:** Objects/vTextC.def

----------
#### VisTextSetBorderBitsParams
    VisTextSetBorderBitsParams              struct
        VTSBBP_range                VisTextRange
        VTSBBP_bitsToSet            VisTextParaBorderFlags
        VTSBBP_bitsToClear          VisTextParaBorderFlags
    VisTextSetBorderBitsParams              ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetBorderWidthParams
    VisTextSetBorderWidthParams         struct
        VTSBWP_range            VisTextRange
        VTSBWP_width            byte
        even
    VisTextSetBorderWidthParams         ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetCharAttrByDefaultParams
    VisTextSetCharAttrByDefaultParams           struct
        VTSCABDP_range              VisTextRange
        VTSCABDP_charAttr           VisTExtDefaultCharAttr
    VisTextSetCharAttrByDefaultParams           ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetCharAttrByTokenParams
    VisTextSetCharAttrByTokenParams                 struct
        VTSCABTP_range                  VisTextRange
        VTSCABTP_charAttr               word
    VisTextSetCharAttrByTokenParams                 ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetCharAttrParams
    VisTextSetCharAttrParams            struct
        VTSCAP_range            VisTextRange
    VTSCAP_charAttr             fptr.VisTextCharAttr
    VisTextSetCharAttrParams            ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetColorParams
    VisTextSetColorParams           struct
        VTSCP_range         VisTextRange
        VTSCP_color         ColorQuad
    VisTextSetColorParams           ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetContextFlags
    VisTextSetContextFlags          record
                        :7
        VTCF_TOKEN      :1      ;TRUE: context and hyperlink are tokens
    VisTextSetContextFlags          end

**Library:** Objects/vTextC.def

----------
#### VisTextSetContextParams
    VisTextSetContextParams         struct
        VTSCXP_range            VisTextRange
        VTSCXP_context          word
        VTSCXP_flags            VisTextSetContextFlags
        even
    VisTextSetContextParams         ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetDefaultTabsParams
    VisTextSetDefaultTabsParams             struct
        VTSDTP_range                VisTextRange
        VTSDTP_defaultTabs          word
    VisTextSetDefaultTabsParams             ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetDropCapPParams
    VisTextSetDropCapPParams            struct
        VTSDCP_range                VisTextRange
        VTSDCP_bitsToSet            word
        VTSDCP_bitsToClear          word
    VisTextSetDropCapPParams            ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetFontIDParams
    VisTextSetFontIDParams          struct
        VTSFIDP_range           VisTextRange
        VTSFIDP_fontID          FontID
    VisTextSetFontIDParams          ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetFontWeightParams
    VisTextSetFontWeightParams              struct
        VTSFWP_range                VisTextRange
        VTSFWP_fontWeight           byte
        even
    VisTextSetFontWeightParams              ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetFontWidthParams
    VisTextSetFontWidthParams               struct
        VTSFWIP_range               VisTextRange
        VTSFWIP_fontWidth           byte
        even
    VisTextSetFontWidthParams               ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetGrayScreenParams
    VisTextSetGrayScreenParams              struct
        VTSGSP_range                VisTextRange
        VTSGSP_grayScreen           SystemDrawMask
        even
    VisTextSetGrayScreenParams              ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetHyperlinkParams
    VisTextSetHyperlinkParams               struct
        VTSHLP_range                VisTextRange
        VTSHLP_context              word
        VTSHLP_file                 word
        VTSHLP_flags                VisTextSetContextFlags
        even
    VisTextSetHyperlinkParams               ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetHyphenationPParams
    VisTextSetHyphenationPParams                struct
        VTSHP_range                 VisTextRange
        VTSHP_bitsToSet             VisTextHyphenationInfo
        VTSHP_bitsToClear           VisTextHyphenationInfo
    VisTextSetHyphenationPParams                ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetKeepPParams
    VisTextSetKeepPParams           struct
        VTSKP_range             VisTextRange
        VTSKP_bitsToSet         word
        VTSKP_bitsToClear       word
        VisTextSetKeepPParams           ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetLargerPointSizeParams
    VisTextSetLargerPointSizeParams                 struct
        VTSLPSP_range                   VisTextRange
        VTSLPSP_maximumSize             word
    VisTextSetLargerPointSizeParams                 ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetLeadingParams
    VisTextSetLeadingParams         struct
        VTSLP_range             VisTextRange
        VTSLP_leading           word
    VisTextSetLeadingParams         ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetLineSpacingParams
    VisTextSetLineSpacingParams             struct
        VTSLSP_range                    VisTextRange
        VTSLSP_lineSpacing              BBFixed
    VisTextSetLineSpacingParams             ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetMarginParams
    VisTextSetMarginParams          struct
        VTSMP_range             VisTextRange
        VTSMP_position          word
    VisTextSetMarginParams          ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetParaAttrAttributesParams
    VisTextSetParaAttrAttributesParams      struct
        VTSPAAP_range                   VisTextRange
        VTSPAAP_bitsToSet               VisTextParaAttrAttributes
        VTSPAAP_bitsToClear             VisTextParaAttrAttributes
    VisTextSetParaAttrAttributesParams      ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetParaAttrByDefaultParams
    VisTextSetParaAttrByDefaultParams                   struct
        VTSPABDP_range                  VisTextRange
        VTSPABDP_paraAttr               VisTextDefaultParaAttr
    VisTextSetParaAttrByDefaultParams                   ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetParaAttrByTokenParams
    VisTextSetParaAttrByTokenParams                 struct
        VTSPABTP_range                  VisTextRange
        VTSPABTP_paraAttr               word
    VisTextSetParaAttrByTokenParams                 ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetParaAttrParams
    VisTextSetParaAttrParams            struct
        VTSPAP_range                VisTextRange
        VTSPAP_paraAttr             fptr.VisTextParaAttr
    VisTextSetParaAttrParams            ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetParagraphNumberParams
    VisTextSetParagraphNumberParams                 struct
        VTSPNP_range                        VisTextRange
        VTSPNP_startingParaNumber           word
    VisTextSetParagraphNumberParams                 ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetPatternParams
    VisTextSetPatternParams         struct
        VTSHAP_range            VisTextRange
        VTSHAP_hatch            GraphicPattern
    VisTextSetPatternParams         ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetPointSizeParams
    VisTextSetPointSizeParams               struct
        VTSPSP_range                VisTextRange
        VTSPSP_pointSize            WWFixed
    VisTextSetPointSizeParams               ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetPrependCharsParams
    VisTextSetPrependCharsParams                struct
        VTSPCP_range            VisTextRange
        VTSPCP_chars            char 4 dup (0)
    VisTextSetPrependCharsParams                ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetSmallerPointSizeParams
    VisTextSetSmallerPointSizeParams                    struct
        VTSSPSP_range                   VisTextRange
        VTSSPSP_minimumSize             word
    VisTextSetSmallerPointSizeParams                    ends

**Library:** Objects/vTextC.def

----------
#### VisTextSpaceOnTBParams
    VisTextSpaceOnTBParams          struct
        VTSSOTBP_range          VisTextRange
        VTSSOTBP_spacing        BBFixed
    VisTextSpaceOnTBParams          ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetTabParams
    VisTextSetTabParams         struct
        VTSTP_range         VisTextRange
        VTSTP_tab           Tab
    VisTextSetTabParams         ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetTextStyleParams
    VisTextSetTextStyleParams               struct
        VTSTSP_range                    VisTextRange
        VTSTSP_styleBitsToSet           word
        VTSTSP_styleBitsToClear         word
        VTSTSP_extendedBitsToSet        word
        VTSTSP_extendedBitsToClear      word
    VisTextSetTextStyleParams               ends

**Library:** Objects/vTextC.def

----------
#### VisTextSetTrackKerningParams
    VisTextSetTrackKerningParams                struct
        VTSTKP_range                    VisTextRange
        VTSTKP_trackKerning             BBFixed
        even
    VisTextSetTrackKerningParams                ends

**Library:** Objects/vTextC.def

----------
#### VisTextShowSelectionArgs
    VisTextShowSelectionArgs            struct
        VTSSA_params            MakeRectVisibleParams
        VTSSA_flags             VisTextShowSelectionFlags
    VisTextShowSelectionArgs            ends

**Library:** Objects/vTextC.def

----------
#### VisTextShowSelectionFlags
    VisTextShowSelectionFlags               record
        VTSSF_DRAGGING          :1
                                :15
    VisTextShowSelectionFlags               end

**Library:** Objects/vTextC.def

----------
#### VisTextStates
    VisTextStates       record
        VTS_EDITABLE                        :1  ; Set: text is editable.
        VTS_SELECTABLE                      :1  ; Set: text is selectable.
        VTS_TARGETABLE                      :1  ; Set: object is targetable.
        VTS_ONE_LINE                        :1  ; Set: object is limited to one 
                                                ; line.
        VTS_SUBCLASS_VIRT_PHYS_TRANSLATION  :1  ; Set: send virtual to physical
                                                ; charAttr/paraAttr translation
                                                ; messages to self (for subclass)
        VTS_OVERSTRIKE_MODE                 :1  ; Set: Overstrike mode (not 
                                                ; insert mode)
        VTS_USER_MODIFIED                   :1  ; Set: text has changed.
                                            :1
    VisTextStates       end

**Library:** Objects/vTextC.def

----------
#### VisTextStorageFlags
    VisTextStorageFlags         record
        VTSF_LARGE                      :1
        VTSF_MULTIPLE_CHAR_ATTRS        :1
        VTSF_MULTIPLE_PARA_ATTRS        :1
        VTSF_TYPES                      :1
        VTSF_GRAPHICS                   :1
        VTSF_DEFAULT_CHAR_ATTR          :1
        VTSF_DEFAULT_PARA_ATTR          :1
        VTSF_STYLES                     :1
    VisTextStorageFlags         end

VTSF_LARGE  
If set: this object uses the large storage format and the bits 
below are unused. If clear: this object uses the model storage 
format are the bits below are used.

VTSF_MULTIPLE_CHAR_ATTRS  
If set: *VTI_charAttrRuns* = check handle of charAttr runs. If not 
set:

if (*VTTF_defaultCharAttr*)
*VTI_charAttrRuns* is a **VisTextDefaultCharAttrs**.
else
*VTI_charAttrRuns* = chunk handle of charAttr.

VTSF_MULTIPLE_PARA_ATTRS  
If set: *VTI_paraAttrRuns* = check handle of paraAttr runs. If 
not set:

if (*VTI_paraAttrRuns* != 0)
*VTI_paraAttrRuns* = chunk handle of paraAttr.
else
use default paraAttr.

**Library:** Objects/Text/tCommon.def

----------
#### VisTextSubstAttrTokenParams
    VisTextSubstAttrTokenParams         struct
        VTSATP_oldToken                     word
        VTSATP_newToken                     word
        VTSATP_runOffset                    word
        VTSATP_updateRefFlag                word
        VTSATP_relayedToLikeTextObjects     word
        VTSATP_recalcFlag                   fptr.word
    VisTextSubstAttrTokenParams         ends

**Library:** Objects/vTextC.def

----------
#### VisTextSuspendData
    VisTextSuspendData      struct
        VTSD_count              word
        VTSD_recalcRange        VisTextRange    ; range to recalculate
        VTSD_selectRange        VisTextRange    ; range to select
        VTSD_notifications      word                
        VTSD_needsRecalc        BooleanByte
    VisTextSuspendData      ends

**Library:** Objects/vTextC.def

----------
#### VisTextType
    VisTextType     struct
        VTT_meta                RefElementHeader
        VTT_hyperlinkName       word        ; name array element (-1 if none)
        VTT_hyperlinkFile       word        ; name array element (-1 if none)
        VTT_context             word        ; name array element (-1 if none)
        VTT_unused              byte 1 dup (0)
    VisTextType     ends

**Library:** Objects/vTextC.def

----------
#### VisTextTypeDiffs
    VisTextTypeDiffs        record
        VTTD_MULTIPLE_HYPERLINKS    :1
        VTTD_MULTIPLE_CONTEXTS      :1
                                    :14
    VisTextTypeDiffs        end

**Library:** Objects/vTextC.def

----------
#### VisTextVariableType
    VisTextVariableType         etype word
        VTVT_PAGE_NUMBER                    enum VisTextVariableType
            ; private data: first word is VisTextNumberType
            ; vm chain: unused
        VTVT_PAGE_NUMBER_IN_SECTION         enum VisTextVariableType
            ; private data: first word is VisTextNumberType
            ; vm chain: unused
        VTVT_NUMBER_OF_PAGES                enum VisTextVariableType
            ; private data: first word is VisTextNumberType
            ; vm chain: unused
        VTVT_NUMBER_OF_PAGES_IN_SECTION     enum VisTextVariableType
            ; private data: first word is VisTextNumberType
            ; vm chain: unused
        VTVT_SECTION_NUMBER                 enum VisTextVariableType
            ; private data: first word is VisTextNumberType
            ; vm chain: unused
        VTVT_NUMBER_OF_SECTIONS             enum VisTextVariableType
            ; private data: first word is VisTextNumberType
            ; vm chain: unused
        VTVT_CREATION_DATE_TIME             enum VisTextVariableType
            ; private data: first word is DateTimeFormat
            ; vm chain: unused
            ; available only for large text objects
        VTVT_MODIFICATION_DATE_TIME         enum VisTextVariableType
            ; private data: first word is DateTimeFormat
            ; vm chain: unused
            ; available only for large text objects
        VTVT_CURRENT_DATE_TIME              enum VisTextVariableType
            ; private data: first word is DateTimeFormat
            ; vm chain: unused
            ; available only for large text objects
        VTVT_STORED_DATE_TIME               enum VisTextVariableType
            ; private data: first word is DateTimeFormat, 2nd is FileDate, 3d
            ; is FileTime
            ; vm chain: unused

**Library:** geoworks.def

----------
#### VisTypeFlags
    VisTypeFlags        record
        VTF_IS_COMPOSITE                    :1
        VTF_IS_WINDOW                       :1
        VTF_IS_PORTAL                       :1
        VTF_IS_WIN_GROUP                    :1
        VTF_IS_CONTENT                      :1
        VTF_IS_INPUT_NODE                   :1
        VTF_IS_GEN                          :1
        VTF_CHILDREN_OUTSIDE_PORTAL_WIN     :1
    VisTypeFlags        end

VTF_IS_COMPOSITE  
Set if object is a **VisCompClass** and therefore can have children 
(although, of course, a composite may at times have no 
children).

VTF_IS_WINDOW  
Set if IS_COMPOSITE and creates a window with the window 
system in order to display itself and children in. If set, then the 
assumption is made that the window is the size of VI_bounds 
and therefore messages like MSG_VIS_DRAW and 
MSG_META_BUTTON that traverse all children skip children 
with this bit set. Also, the routine that returns the window 
handle that a visible object sits on will return this object's 
*VCI_window* if this bit is set. Note that this flag differs subtly 
from the VTF_IS_PORTAL flag described below.

VTF_IS_PORTAL  
Set if object has its own window, which is stored elsewhere. Any 
visible children appear in that window. Object still may have 
portions which appear in its parents window. An example is the 
display control object, which manages several child windows 
inside its own window area. Its border is drawn in the parent 
window, and its own window is then inset one pixel from its 
bounds.

The flag has several effects:

* it causes UPDATE_WINDOWS and CLOSE_WIN messages to be 
sent to the object.

* the optimizations made for VTF_IS_WINDOW are not done. 
This object gets a MSG_VIS_DRAW and a MSG_META_BUTTON 
from its parent.

* only one of the flags VTF_IS_WINDOW and VTF_IS_PORTAL 
can be set at a time.

VTF_IS_WIN_GROUP  
Set for top visible object in a visible branch, which makes that 
branch a realizable entity. Visual updates happen on whole 
WIN_GROUP's. VTF_IS_WINDOW and VTF_IS_COMPOSITE 
must be set.

VTF_IS_CONTENT  
Set if the object is basically the output descriptor of another 
window object. VTF_IS_WINDOW and VTF_IS_WIN_GROUP 
must also be set. Has a few subtle differences from a win group, 
one being that a Win is expected to be stuffed in by the "parent" 
object.

VTF_IS_INPUT_NODE
Set if this object controls input flow for either Kbd or Mouse, 
such as **VisContentClass**. 
MSG_VIS_VUP_ALTER_INPUT_FLOW's are sent directly to 
objects having this bit set, unless there is a need for them 
actually to VUP up through each object (as is the case for mouse 
grabs in a 32-bit content model).

VTF_IS_GEN  
Set if object has a Generic master part. This flag must be set for 
the object to handle "SpecClass" messages such as 
MSG_SPEC_BUILD. For optimization reasons, their is no 
SpecClass subclassed off of VisClass, but one can think of it 
that way.

VTF_CHILDREN_OUTSIDE_PORTAL_WIN  
Only if VTF_IS_PORTAL is set, means that visible children lie in 
the portal's parent window areas, rather than in the window 
created by the portal object itself, thus they keep the portal's 
parent window in the their instance data. An example of this is 
the pane, whose visual children lie around the outside of the 
pane's own created window. A display control, by contrast, has 
its visual children reside inside its window and thus would not 
have this flag set. 

**Library:** Objects/visC.def

----------
#### VisUpdateImageFlags
    VisUpdateImageFlags         record
        VUIF_ALREADY_INVALIDATED    :1
        VUIF_SEND_TO_ALL_CHILDREN   :1
        VUIF_JUST_OPENED            :1
                                    :5
    VisUpdateImageFlags         end

VUIF_ALREADY_INVALIDATED  
Set if we no longer need to invalidate things, until we hit a 
window at some point. If a VisComp object's image is 
invalidated, it will sometimes set this flag before broadcasting 
the message to its children so they'll know not to invalidate 
themselves.

VUIF_SEND_TO_ALL_CHILDREN  
Set if we need to send the invalidation message to all children, 
regardless of what the path bit is. This is for cases where a 
composite object is invalid, but only invalidates its margins to 
minimize invalidation, and then only children whose geometry 
is invalid will be invalidated further.

VUIF_JUST_OPENED  
Internal flag.

**Library:** Objects/visC.def

----------
#### VisUpdateMode
    VisUpdateMode       etype byte
        VUM_MANUAL                  enum VisUpdateMode  ;don't update. 
        VUM_NOW                     enum VisUpdateMode  ;update NOW.
        VUM_DELAYED_VIA_UI_QUEUE    enum VisUpdateMode  ;delayed until UI queue 
                                                        ;empty
        VUM_DELAYED_VIA_APP_QUEUE   enum VisUpdateMode  ;delayed until APP queue 
                                                        ;empty

**Library:** Objects/visC.def

----------
#### VisUpwardQueryType
    VisUpwardQueryType      etype word
        SPEC_VIS_QUERY_START    equ 2000    ; offset to first specific UI query type
        APP_VIS_QUERY_START     equ 4000    ; offset to first app UI query type

        VUQ_DISPLAY_SCHEME      enum VisUpwardQueryType
        ; Context:      May be used when drawing part of a visible tree
        ; Source:       Any VisClass object
        ; Destination:  Typically handled by the field object
        ; Interception: It would be unusual to intercept this, as long as there is
        ;               a single video mode per field.
        ;
        ; Pass:         cx      - VUQ_DISPLAY_SCHEME
        ; Return:
        ;               carry   - set if VUP message found routine to process
        ;                           request
        ;
        ;   ax, cx, dx, bp      - display scheme
        ;
        VUQ_VIDEO_DRIVER        enum VisUpwardQueryType
        ;
        ; Used to fetch the handle of the video driver which is in
        ; use for this location in the visible tree.
        ;
        ; Context:      Might be used when drawing part of a visible tree
        ; Source:       Any VisClass object
        ; Destination:  Typically handled by the field object
        ; Interception: It would be unusual to intercept this, as long as there is
        ;               a single video mode per field.
        ;
        ; Pass:         cx      - VUQ_VIDEO_DRIVER
        ; Return:
        ;               carry   - set if VUP message found routine to process 
        ;                           request
        ;               ax      - handle of video driver
        ;       cx, dx, bp      - destroyed

**Library:** Objects/visC.def

----------
#### VisWardMouseEventType
    VisWardMouseEventType           etype byte, 0
        VWMET_SMALL         enum VisWardMouseEventType
        VWMET_LARGE         enum VisWardMouseEventType

**Library:** grobj.def

----------
#### VisWardToolActiveStatus
    VisWardToolActiveStatus         etype byte, 0
        VWTAS_ACTIVE            enum VisWardToolActiveStatus
        VWTAS_INACTIVE          enum VisWardToolActiveStatus

**Library:** grobj.def

----------
#### VMAccessFlags
    VMAccessFlags       record
        VMAF_FORCE_READ_ONLY                    :1
        VMAF_FORCE_READ_WRITE                   :1
        VMAF_ALLOW_SHARED_MEMORY                :1
        VMAF_FORCE_DENY_WRITE                   :1
        VMAF_DISALLOW_SHARED_MULTIPLE           :1
        VMAF_USE_BLOCK_LEVEL_SYNHRONIZATION     :1
        VMAF_FORCE_SHARED_MULTIPLE              :1
        <internal>                              :1
    VMAccessFlags       end

VMAF_FORCE_READ_ONLY  
If set then force the file to be opened read only, even if the 
default would be to open the file read/write.

VMAF_FORCE_READ_WRITE  
If set then force the file to be opened read-write, even if the 
default would be to open the file read-only.

VMAF_ALLOW_SHARED_MEMORY  
If set then use shared memory locally (unless otherwise 
impossible).

VMAF_FORCE_DENY_WRITE  
If set then open file deny write.

VMAF_DISALLOW_SHARED_MULTIPLE  
If set then files with the SHARED_MULTIPLE attribute cannot 
be opened.

VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION  
If set then block the block level synchronization of the VM code 
is assumed to be sufficient and the {Start/End}Exclusive 
mechanism is not used. This is primarily intended for system 
software.

VMAF_FORCE_SHARED_MULTIPLE  
If set, the file is opened as if it had the SHARED_MULTIPLE 
attribute even if it didn't. This is useful for data VM files that 
need to always be opened as if SHARED_MULTIPLE were set, 
even when they're first created. Without this, there's a nasty 
race condition following the creation where the creator has to 
mark the file SHARED_MULTIPLE, close it, and reopen it again.

**Library:** vm.def

----------
#### VMAttributes
    VMAttributes        record
        VMA_SYNC_UPDATE                 :1
        VMA_BACKUP                      :1
        VMA_OBJECT_RELOC                :1
                                        :1
        VMA_NOTIFY_DIRTY                :1
        VMA_NO_DISCARD_IF_IN_USE        :1
        VMA_COMPACT_OBJ_BLOCK           :1
        VMA_SINGLE_THREAD_ACCESS        :1
    VMAttributes        end

VMA_SYNC_UPDATE  
Allow synchronous updates only. Tells the system that it should 
not do asynchronous updates of the VM file. Clean VM blocks 
may always be discarded. Asynchronous updates are active by 
default

VMA_BACKUP  
Maintain a backup copy of all data. The file can be returned to 
its backup state by calling **VMRevert**. The current state is 
made the backup by calling **VMSave**.

VMA_OBJECT_RELOC  
Use the built-in object relocation routines

VMA_NOTIFY_DIRTY  
Notify all processes that have the file open the first time a block 
becomes dirty after a **VMOpen**, **VMUpdate**, **VMSave**, or 
**VMRevert**.

VMA_NO_DISCARD_IF_IN_USE  
Do not discard LMem blocks of type LMEM_TYPE_OBJ_BLOCK 
if *OLMBH_inUseCount* is non-zero

VMA_COMPACT_OBJ_BLOCK  
If set, do a compaction when doing a unreloc before write 
(object blocks only) - allows generic objects in a VM file.

VMA_SINGLE_THREAD_ACCESS  
If set then only a single thread will access the file, allowing 
optimizations in **VMLock**.

**Library:** vm.def

----------
#### VMChainLink
    VMChainLink     struct
        VMCL_next       word
    VMChainLink     ends

**Library:** vm.def

----------
#### VMChainTree
    VMChainTree     struct
        VMCT_meta           VMChainLink
        VMCT_offset         nptr        ;offset to first chain
        VMCT_count          word        ;number of chains
    VMChainTree     ends

**Library:** vm.def

----------
#### VMLinkAndGrObjRelocation
    VMLinkAndGrObjRelocation            struct
        VMLAGOR_link                VMChainLink
        VMLAGOR_relocation          GrObjEntryPointRelocation
    VMLinkAndGrObjRelocation            ends

**Library:** grobj.def

----------
#### VMOpenType
    VMOpenType      etype byte
        VMO_OPEN            enum VMOpenType ; Open existing
        VMO_TEMP_FILE       enum VMOpenType ; Create temp file -- name is 
                                            ; directory
        VMO_CREATE          enum VMOpenType ; Create or open existing
        VMO_CREATE_ONLY     enum VMOpenType ; Create, give error if already 
                                            ; exists
        VMO_CREATE_TRUNCATE enum VMOpenType ; Create, truncate any existing 
                                            ;file

**Library:** vm.def

----------
#### VMOperation
    VMOperation     etype word
        VMO_READ        enum VMOperation    ;default state -- allows
                                            ;readers not to modify the file
        VMO_INTERNAL    enum VMOperation
        VMO_SAVE        enum VMOperation
        VMO_SAVE_AS     enum VMOperation
        VMO_REVERT      enum VMOperation
        VMO_UPDATE      enum VMOperation
        VMO_WRITE       enum VMOperation    ;for apps that don't want
                                            ;their own special codes
        VMO_FIRST_APP_CODE  enum VMOperation, 0x8000

**Library:** vm.def

----------
#### VMRelocType
    VMRelocType     etype word
        VMRT_UNRELOCATE_BEFORE_WRITE        enum VMRelocType
        VMRT_RELOCATE_AFTER_READ            enum VMRelocType
        VMRT_RELOCATE_AFTER_WRITE           enum VMRelocType
        VMRT_RELOCATE_FROM_RESOURCE         enum VMRelocType
        VMRT_UNRELOCATE_FROM_RESOURCE       enum VMRelocType

**Library:** vm.def

----------
#### VMStartExclusiveReturnValue
    VMStartExclusiveReturnValue             etype word
        VMSERV_NO_CHANGES           enum VMStartExclusiveReturnValue
        VMSERV_CHANGES              enum VMStartExclusiveReturnValue
        VMSERV_TIMEOUT              enum VMStartExclusiveReturnValue

**Library:** vm.def

----------
#### VMStatus
    VMStatus        etype word, 256
        VM_OPEN_OK_READ_ONLY                enum VMStatus
        VM_OPEN_OK_TEMPLATE                 enum VMStatus
        VM_OPEN_OK_READ_WRITE_NOT_SHARED    enum VMStatus
        VM_OPEN_OK_READ_WRITE_SINGLE        enum VMStatus
        VM_OPEN_OK_READ_WRITE_MULTIPLE      enum VMStatus
        VM_OPEN_OK_BLOCK_LEVEL              enum VMStatus
        VM_CREATE_OK                        enum VMStatus

        ;   VM error codes

        VM_FILE_EXISTS                      enum VMStatus
        VM_FILE_NOT_FOUND                   enum VMStatus
        VM_SHARING_DENIED                   enum VMStatus
        VM_OPEN_INVALID_VM_FILE             enum VMStatus
        VM_CANNOT_CREATE                    enum VMStatus
        VM_TRUNCATE_FAILED                  enum VMStatus
        VM_WRITE_PROTECTED                  enum VMStatus
        VM_CANNOT_OPEN_SHARED_MULTIPLE      enum VMStatus
        VM_FILE_FORMAT_MISMATCH             enum VMStatus

        ;   VMUpdate status codes

        VM_UPDATE_NOTHING_DIRTY             enum VMStatus
        VM_UPDATE_INSUFFICIENT_DISK_SPACE   enum VMStatus
        VM_UPDATE_BLOCK_WAS_LOCKED          enum VMStatus

**Library:** vm.def

----------
#### VMStyle
    VMStyle etype byte
        VMS_TEXT            enum VMStyle    ; normal text moniker
        VMS_ABBREV_TEXT     enum VMStyle    ; abbreviated text moniker i.e. a 
                                            ; short textual description rather 
                                            ; than the full title. Used for 
                                            ; name under icon of an iconified
                                            ; primary.
        VMS_GRAPHIC_TEXT    enum VMStyle    ; textual gstring
        VMS_ICON            enum VMStyle    ; normal gstring moniker
        VMS_TOOL            enum VMStyle    ; moniker for a tool, normally 
                                            ; smaller than a standard moniker

**Library:** Objects/visC.def

----------
#### VupAlterInputFlowData
    VupAlterInputFlowData           struct
        VAIFD_flags             VisInputFlowGrabFlags
        VAIFD_grabType          VisInputFlowGrabType
        VAIFD_object            optr
        VAIFD_gWin              hptr.Window
        VAIFD_translation       PointDWord
    VupAlterInputFlowData           ends

*VAIFD_gWin* stores the window that the grabbing object is in (for mouse grabs 
only).

*VAIFD_translation* stores any additional 32-bit translation that should be 
applied to all mouse data (for mouse grabs only).

**Library:** Objects/visC.def

----------
#### Warnings
    Warnings        etype word, 0

**Library:** ec.def

----------
#### WBFixed
    WBFixed struct
        WBF_frac        byte        ;8 bits fraction
        WBF_int         word        ;16 bits integer
    WBFixed ends

**Library:** geos.def

----------
#### WidthJustification
    WidthJustification      etype byte
        WJ_LEFT_JUSTIFY_CHILDREN                    enum WidthJustification
        WJ_RIGHT_JUSTIFY_CHILDREN                   enum WidthJustification
        WJ_CENTER_CHILDREN_HORIZONTALLY             enum WidthJustification
        WJ_FULL_JUSTIFY_CHILDREN_HORIZONTALLY       enum WidthJustification

**Library:** Objects/vCompC.def

----------
#### WildCard
    WildCard    etype byte
        WC_MATCH_SINGLE_CHAR            enum WildCard, 0x10
        WC_MATCH_MULTIPLE_CHARS         enum WildCard, 0x11
        WC_MATCH_WHITESPACE_CHAR        enum WildCard, 0x12

**Library:** Objects/vTextC.def

----------
#### WinColorFlags
    WinColorFlags       record
        WCF_RGB             :1
        WCF_TRASNPARENT     :1
        WCF_PLAIN           :1
                            :2
        WCF_MAP_MODE        :3
    WinColorFlags       end

WCF_RGB  
Set if using RGB colors, clear for indexed.

WCF_TRANSPARENT  
Indicates window does not have a background color, & that 
owner must draw entire contents of window.

WCF_PLAIN  
Indicates window is one color only and therefore the window 
system may perform all draw operations for it. (No 
MSG_META_EXPOSED's are sent)

WCF_MAP_MODE  
Graphics color mapping mode.

**Library:** win.def

----------
#### WinConstrainType
    WinConstrainType        etype byte
        WCT_NONE                            enum WinConstrainType
        WCT_KEEP_PARTIALLY_VISIBLE          enum WinConstrainType
        WCT_KEEP_VISIBLE                    enum WinConstrainType
        WCT_KEEP_VISIBLE_WITH_MARGIN        enum WinConstrainType

WCT_NONE  
Do not constrain window to parent. Allow complete clipping of 
window area by parent window.

WCT_KEEP_PARTIALLY_VISIBLE  
Ensure that this window is at least partially visible within its 
parent at all times. In Motif, this means make sure the title bar 
is accessible.

WCT_KEEP_VISIBLE  
Ensure that this window is completely visible within its parent 
at all times.

WCT_KEEP_VISIBLE_WITH_MARGIN

**Library:** Objects/visC.def

----------
#### WinError
    WinError        etype word, 0, 1
        WE_COORD_OVERFLOW       enum WinError   ; 16-bit coordinate overflow
        WE_WINDOW_CLOSING       enum WinError   ; window is closing
        WE_GSTRING_PASSED       enum WinError   ; gstring handle passed

**Library:** win.def

----------
#### WinInfoType
    WinInfoType     etype word, 0, 2
        WIT_PRIVATE_DATA        enum WinInfoType
        WIT_COLOR               enum WinInfoType
        WIT_INPUT_OBJ           enum WinInfoType
        WIT_EXPOSURE_OBJ        enum WinInfoType
        WIT_STRATEGY            enum WinInfoType
        WIT_FLAGS               enum WinInfoType
        WIT_LAYER_ID            enum WinInfoType
        WIT_PARENT_WIN          enum WinInfoType
        WIT_FIRST_CHILD_WIN     enum WinInfoType
        WIT_LAST_CHILD_WIN      enum WinInfoType
        WIT_PREV_SIBLING_WIN    enum WinInfoType
        WIT_NEXT_SIBLING_WIN    enum WinInfoType
        WIT_PRIORITY            enum WinInfoType

**Library:** win.def

----------
#### WinInvalFlag
    WinInvalFlag        etype byte, 0, 1
        WIF_INVALIDATE          enum WinInvalFlag   ; -invalidate the win
        WIF_DONT_INVALIDATE     enum WinInvalFlag   ; -don't

**Library:** win.def

----------
#### WinPassFlags
    WinPassFlags        record
        WPF_CREATE_GSTATE           :1
        WPF_ROOT                    :1
        WPF_SAVE_UNDER              :1
        WPF_INIT_EXCLUDED           :1
        WPF_PLACE_BEHIND            :1
        WPF_PLACE_LAYER_BEHIND      :1
        WPF_LAYER                   :1
        WPF_ABS                     :1
        WPF_PRIORITY                WinPriorityData:8
    WinPassFlags        end

The flags are listed below. Following the description of each flag, the list of 
routines which respect the flag are listed in parentheses.

WPF_CREATE_GSTATE  
Set if a gstate should be created along with window 
(**WinOpen**).

WPF_ROOT  
Set if creating a root window (**WinOpen**).

WPF_SAVE_UNDER  
Set if window should be created w/save under (**WinOpen**).

WPF_INIT_EXCLUDED  
Init as being the head of a branch which is excluded from being 
an implied window, and therefore won't receive 
MSG_META_UNIV_ENTER, MSG_META_VIS_ENTER messages. 
(**WinOpen**).

WPF_PLACE_BEHIND  
Indicates window should be placed behind other windows in its 
priority group. If clear, then window will be placed in front. 
(**WinOpen**, **WinChangePriority**).

WPF_PLACE_LAYER_BEHIND  
Indicates whether layer should be placed behind other layers 
within its priority group. If clear, then layer will be placed in 
front. (**WinOpen**, **WinChangePriority**).

WPF_LAYER  
Set if operation applies to all windows having layerID 
(**WinChangePriority**).

WPF_ABS  
Whether size/offset passed is absolute or relative to current 
(**WinScroll**, **WinMove**, **WinResize**).

**Library:** win.def

----------
#### WinPositionType
    WinPositionType     etype byte
        WPT_AT_RATIO                    enum WinPositionType
        WPT_STAGGER                     enum WinPositionType
        WPT_CENTER                      enum WinPositionType
        WPT_TILED                       enum WinPositionType
        WPT_AT_MOUSE_POSITION           enum WinPositionType
        WPT_AS_REQUIRED                 enum WinPositionType
        WPT_AT_SPECIFIC_POSITION        enum WinPositionType

WPT_AT_RATIO  
Place this window at the specified position relative to the 
parent window. The          position information is initially placed in 
the *R_left* and *R_top* fields of the *VI_bounds* for the object, as 
the object is initialized. During building, this information is 
converted from a ratio to actual coordinates.

WPT_STAGGER  
Stagger this window down and to the right of previously 
staggered windows on this parent object.

WPT_CENTER  
Center this window on the parent window.

WPT_TILED  
Tile this window with its siblings. 

WPT_AT_MOUSE_POSITION  
Place the top-left corner of this window where the mouse 
pointer is. If the system has no mouse, the window is centered 
on the parent window.

WPT_AS_REQUIRED  
Reserved for specific-UI use.

WPT_AT_SPECIFIC_POSITION  
Reserved for specific-UI use. 



**Library:** Objects/visC.def

----------
#### WinPosSizeFlag
    WinPosSizeFlags     record
        WPSF_PERSIST                                :1
        WPSF_HINT_FOR_ICON                          :1
        WPSF_NEVER_SAVE_STATE                       :1
        WPSF_SHRINK_DESIRED_SIZE_TO_FIT_IN_PARENT   :1
                                                    :4
        WPSF_CONSTRAIN_TYPE                         WinConstrainType:2
        WPSF_POSITION_TYPE                          WinPositionType:3
        WPSF_SIZE_TYPE                              WinSizeType:3
    WinPosSizeFlags     end

WPSF_PERSIST  
True for window to maintain its state (position, size, staggered 
slot #) when closed or detached. If false, the window will revert 
back to the specified position and size preferences (see below) 
when the window is re-opened. Note: could nuke this by adding 
HINT_DONT_PERSIST hint.

WPSF_HINT_FOR_ICON  
True if this record is part of a hint for a GenPrimary or 
GenDisplay, and the hint is intended for the icon object. Note: 
could nuke this by creating separate hint.

WPSF_NEVER_SAVE_STATE  
True for objects that never should have state saved when 
closed, such as menus. Overrides persist.

WPSF_SHRINK_DESIRED_SIZE_TO_FIT_IN_PARENT  
Can be set true in objects where WPSF_SIZE_TYPE = 
WST_AS_DESIRED. After geometry has determined DESIRED 
size of window, if right side or bottom portion of window is not 
visible in parent window, this window will be resized to fit.

WPSF_CONSTRAIN_TYPE  
Which constraint algorithm to use (keep inside, etc.).

WPSF_POSITION_TYPE  
If window has not been moved/resized, this field indicates what 
position algorithm should be used.

WPSF_SIZE_TYPE  
If false or window has not been moved/resized, this field 
indicates what sizing algorithm should be used. 

**Library:** Objects/visC.def

----------
#### WinPriority
    WinPriority     etype byte
        WIN_PRIO_POPUP              enum WinPriority, 4
        WIN_PRIO_MODAL              enum WinPriority, 6
        WIN_PRIO_COMMAND            enum WinPriority, 10
        WIN_PRIO_STD                enum WinPriority, 12
        WIN_PRIO_ON_BOTTOM          enum WinPriority, 14

WIN_PRIO_POPUP  
Stay-up mode or drag mode, temporary popup menus.

WIN_PRIO_MODAL  
For modal dialog boxes.

WIN_PRIO_ON_TOP  
For misc which is supposed to appear "on top" of rest of 
application.

WIN_PRIO_COMMAND  
For Command windows, non-modal dialogs, torn-off menus.

WIN_PRIO_STD  
Standard window priority.

WIN_PRIO_ON_BOTTOM  
Window stays on bottom.

**Library:** win.def

----------
#### WinPriorityData
    WinPriorityData     record
        WPD_LAYER   LayerPriority   :4
        WPD_WIN     WinPriority     :4      ; priority value for window.
    WinPriorityData     end

**Library:** win.def

----------
#### WinPtrFlags
    WinPtrFlags     record
        WPF_PTR_IN_UNIV     :1      ; pointer in universe of window. (RAW)
                                    ; this is not synchronous with the UI 
                                    ; thread
        WPF_PTR_IN_VIS      :1      ; pointer is in visible region of window 
                                    ; (RAW) this is NOT synchronous with the 
                                    ; UI thread
                            :6
    WinPtrFlags     end

**Library:** win.def

----------
#### WinRegFlags
    WinRegFlags     record
        WRF_DELAYED_WASH        :1
        WRF_DELAYED_V           :1
        WRF_SIBLING_VALID       :1
        WRF_EXPOSE_PENDING      :1
        WRF_CLOSED              :1
        WRF_INVAL_TREE          :1
                                :2
    WinRegFlags     end

WRF_DELAYED_WASH  
Set if window has WRF_DELAYED_V set and the windowing 
system has delayed doing a was as a result. Will cause the fill 
to be done when the window block is V'd.

WRF_DELAYED_V  
Set if window should not be V'd until validation operation is 
complete. Used to insure that no two V'd windows ever have 
overlapping *W_maskReg*'s at any one instant.

WRF_SIBLING_VALID  
Set if parent window's *W_childReg* contains running sum of 
regions of windows to the left of this one in the tree 
(*W_siblingReg*).

WRF_EXPOSE_PENDING  
Means that a MSG_META_EXPOSED has been sent out, and 
neither **GrBeginUpdate** nor **WinUpdateAck** has been called 
yet.

WRF_CLOSED  
Set if this window has been closed, but not yet freed.

WRF_INVAL_TREE  
Set if this window is being invalidated from **WinInvalTree** 
and may need to redraw in its background color even if the 
entire window is already invalidated.

**Library:** win.def

----------
#### WinSizeType
    WinSizeType     etype byte
        WST_AS_RATIO_OF_PARENT              enum WinSizeType
        WST_AS_RATIO_OF_FIELD               enum WinSizeType
        WST_AS_DESIRED                      enum WinSizeType
        WST_EXTEND_TO_BOTTOM_RIGHT          enum WinSizeType
        WST_EXTEND_NEAR_BOTTOM_RIGHT        enum WinSizeType

WST_AS_RATIO_OF_PARENT  
This can be used to open a window a specific size. The size 
information is initially placed in the *R_right* and *R_bottom* 
fields of the *VI_bounds* of the object, as the object is initialized. 
During building, this info is converted from a ratio to actually 
pixel-distance.

WST_AS_RATIO_OF_FIELD

WST_AS_DESIRED  
Size the window according to its contents.

WST_EXTEND_TO_BOTTOM_RIGHT  
This means size the window so that its bottom right corner is 
at the same position on the screen as the bottom right corner of 
the parent window.

WST_EXTEND_NEAR_BOTTOM_RIGHT  
This means size the window so that its bottom right corner is a 
fixed margin away from the bottom right corner of the parent 
window. The margin is determined by the specific UI. 

**Library:** Objects/visC.def

----------
#### WordAndAHalf
    WordAndAHalf        struct
        WAAH_low            word
        WAAH_high           byte
    WordAndAHalf        ends

**Library:** geos.def

----------
#### WWFixed
    WWFixed struct
        WWF_frac        word        ;16 bits fraction
        WWF_int         word        ;16 bits integer
    WWFixed ends

**Library:** geos.def

----------
#### XYOffset
    XYOffset        struct
        XYO_x   sword
        XYO_y   sword
    XYOffset        ends

**Library:** graphics.def

----------
#### XYSize
    XYSize  struct
        XYS_width       word
        XYS_height      word
    XYSize  ends

**Library:** graphics.def

[Structures T-U](asmstrtu.md) <-- [Table of Contents](../asmref.md) 
