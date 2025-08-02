# 3 Structures
Global data structures and types are listed alphabetically below. Some data structures used by only a few routines or by only one or two classes are documented within those routines or classes.

## 3.1 Structures A-C

----------
#### ActionDescriptor
    ActionDescriptor        struct
        AD_OD               optr
        AD_message          word
    ActionDescriptor        ends

This structure describes an event, storing both the message to send and the 
optr of the destination for that message.

**Library:** ui.def

----------
#### ActivateCreateFlags
    ActivateCreateFlags         record
        ACF_NOTIFY      :   1       ;notify selected objects that
                                    ;tool is activating
    ActivateCreateFlags         end

**Library:** grobj.def

----------
#### ActivationData
    ActivationData      struc
        AD_dialog           optr    ; On-screen "Activating..." dialog.
        AD_appLaunchBlock   hptr    ; Initial AppLaunchBlock - not used once 
                                    ; geode is known (NOT a reference, i.e.
                                    ; MemRefCount is *not* incremented for
                                    ; this usage, so don't decrement later)

        AD_geode            hptr    ; Geode having a dialog put up for it
        AD_savedBlankMoniker lptr   ; Saved blank moniker if not currently in use in
                                    ; the "Activating" dialog
    ActivationData      ends

**Library:** grobj.def

----------
#### ActiveSearchSpellType
    ActiveSearchSpellType               etype   byte, 0, 1
        ASST_NOTHING_ACTIVE         enum    ActiveSearchSpellType
        ASST_SPELL_ACTIVE           enum    ActiveSearchSpellType
        ASST_SEARCH_ACTIVE          enum    ActiveSearchSpellType

**Library:** Objects/vTextC.def

----------
#### AddChildRelativeParams
    AddChildRelativeParams          struct
        ACRP_child          optr            ;the object to add
        ACRP_parent         optr            ;the visual parent to use
        ACRP_buildFlags     SpecBuildFlags  ;the spec build flags to use
    AddChildRelativeParams          ends

**Library:** Objects/visC.def

----------
#### AddUndoActionFlags
    AddUndoActionFlags          record
        AUAF_NOTIFY_BEFORE_FREEING                      :1  
        AUAF_NOTIFY_IF_FREED_WITHOUT_BEING_PLAYED_BACK  :1
                        :14 ; Unused bits
    AddUndoActionFlags          end

AUAF_NOTIFY_BEFORE_FREEING  
Set this flag if you want to be notified when (before) the associated action is 
freed.

AUAF_NOTIFY_IF_FREED_WITHOUT_BEING_PLAYED_BACK  
Set this flag if you want to be notified if the action is freed without being 
played back.

**Library:** Objects/gProcC.def

----------
#### AddUndoActionStruct
    AddUndoActionStruct         struct
        AUAS_data           UndoActionStruct
        AUAS_output         optr
        AUAS_flags          AddUndoActionFlags
        even
    AddUndoActionStruct         ends

This structure provides several pieces of information vital to processes which 
will be working with the "undo" mechanism.

*AUAS_output* stores the optr of the object to be sent 
MSG_META_CLIPBOARD_UNDO.

**Library:** Objects/gProc.def

----------
#### AddVarDataParams
    AddVarDataParams            struct
        AVDP_data           fptr;
        AVDP_dataSize       word;
        AVDP_dataType       word;
    AddVarDataParams            ends

*AVDP_data* stores a pointer to data to initialize the vardata with, or null if no 
extra data is available. *AVDP_data* may also be null if the extra data should 
be initialized to zero.

*AVDP_dataSize* stores the size of the extra data, if any.

*AVDP_dataType* stores the VarData type.

**Library:** Objects/metaC.def

----------
#### AdjustType
    AdjustType      etype   byte, 0, 1
        AT_NORMAL       enum        AdjustType
        AT_PASTE        enum        AdjustType
        AT_QUICK        enum        AdjustType

**Library:** Objects/vTextC.def

----------
#### AfterAddedToGroupData
    AfterAddedToGroupData           struct
        AATGD_group             optr;
        AATGD_centerAdjust      PointDWFixed;
    AfterAddedToGroupData           ends

*AATGD_group* stores the optr of the group object.

*AATGD_centerAdjust* stores the value to subtract from the center of the child 
to position it correctly.

**Library:** grobj.def

----------
#### AfterEditAction
    AfterEditAction         etype   byte, 0
        DONT_SELECT_AFTER_EDIT      enum        AfterEditAction
        SELECT_AFTER_EDIT           enum        AfterEditAction

**Library:** grobj.def

----------
#### AlignParams
    AlignParams             struct
        AP_x            DWFixed
        AP_y            DWFixed
        AP_spacingX     DWFixed
        AP_spacingY     DWFixed
        AP_type         AlignType
    AlignParams             ends

**Library:** grobj.def

----------
#### AlignToGridType
    AlignToGridType         record
        ATGT_LEFT       :1
        ATGT_H_CENTER   :1
        ATGT_RIGHT      :1
        ATGT_TOP        :1
        ATGT_V_CENTER   :1
        ATGT_BOTTOM     :1
    AlignToGridType         end

**Library:** grobj.def

----------
#### AlignType
    AlignType               record
        AT_ALIGN_X      :1
        AT_DISTRIBUTE_X :1
        AT_CLRW         CenterLeftRightWidth:2
        AT_ALIGN_Y      :1
        AT_DISTRIBUTE_Y :1
        AT_CTBH         CenterTopBottomHeight:2
    AlignType               end

**Library:** grobj.def

----------
#### AnotherToolActivatedFlags
    AnotherToolActivatedFlags               record
        ATAF_STANDARD_POINTER       :1
        ATAF_SHAPE                  :1
        ATAF_GUARDIAN               :1
    AnotherToolActivatedFlags               end

This record provides basic information about tool activation. Selected or 
edited GrObj objects will use this information to determine whether to 
remain selected or edited.

ATAF_STANDARD_POINTER  
A pointer tool intended to work on the normal move and resize handles of an 
object.

ATAF_SHAPE  
A shape drawing tool, rectangle, ellipse...     

ATAF_GUARDIAN  
A Vis guardian object

**Library:** grobj.def

----------
#### AppAttachFlags
    AppAttachFlags                  record
        AAF_RESTORING_FROM_STATE        :1
        AAF_STATE_FILE_PASSED           :1
        AAF_DATA_FILE_PASSED            :1
        AAF_RESTORING_FROM_QUIT         :1
                                        :12
    AppAttachFlags                  end

These flags are passed in MSG_GEN_PROCESS_RESTORE_FROM_STATE, 
MSG_GEN_PROCESS_OPEN_APPLICATION, and 
MSG_GEN_PROCESS_OPEN_ENGINE.

AAF_RESTORING_FROM_STATE  
Set if this application was invoked with 
MSG_GEN_PROCESS_RESTORE_FROM_STATE. The mode chosen to restore to 
was extracted from the GenApplication object. The flag 
AAF_STATE_FILE_PASSED will always be set if this flag is.

AAF_STATE_FILE_PASSED  
Set if a state file was passed into this application when invoked. This will be 
set if AAF_RESTORING_FROM_STATE, but may also be set if the application 
has been invoked with a "template" state file.

AAF_DATA_FILE_PASSED  
Set if a data file, whose name is in the **AppLaunchBlock**, has been passed 
into the invocation of this application.

AAF_RESTORING_FROM_QUIT  
Set if the application was in the process of quitting, got to engine mode, and 
is now being restarted to application mode again. If this is set, 
AAF_RESTORING_FROM_STATE will also be set.

**Library:** Objects/gProcC.def

----------
#### AppInstanceReference
    AppInstanceReference            struct
        AIR_fileName            char PATH_BUFFER_SIZE dup (?)
        AIR_stateFile           char FILE_LONGNAME_BUFFER_SIZE dup (?)
        AIR_diskHandle          word
        AIR_savedDiskData       byte 0
        AppInstanceReference            ends

This structure stores information needed to reload an instance of an 
application. This structure is stored in the application object itself and copied 
into the field when the application is forcefully detached. 

*AIR_filename* stores the file name of the application to launch. The path name 
is relative to the SP_APPLICATION directory, though you can override this 
behavior by specifying an absolute path.

*AIR_stateFile* specifies the name of the state file for the application. The state 
file name is assumed to be in the SP_STATE directory. If the first byte of this 
instance data is "0", then there is no state file for this application and it 
cannot be relaunched.

*AIR_diskHandle* specifies the disk handle where the application is located. In 
the field, if **AppInstanceReference** is a placeholder structure 
AIR_diskHandle stores the handle of the application object we are waiting to 
detach.

*AIR_savedDiskData* stores the start of data saved by **DiskSave** when 
instance data is saved to state.

**Library:** Objects/gProcC.def

----------
#### AppLaunchBlock
    AppLaunchBlock      struct
        ALB_appRef          AppInstanceReference
        ALB_appMode         word
        ALB_launchFlags     AppLaunchFlags
        ALB_diskHandle      word
        ALB_path            char    PATH_BUFFER_SIZE dup (?)
        ALB_dataFile        FileLongName
        ALB_genParent       optr
        ALB_userLoadAckAD   ActionDescriptor
        ALB_userLoadAckID   word
        ALB_extraData       word
    AppLaunchBlock      ends

This structure is used when an application is first starting up. It is the 
argument of various messages, including MSG_META_ATTACH, which will be 
intercepted by system classes. The first fields (*ALB_appRef*, *ALB_appMode*, 
and *ALB_launchFlags*) are preserved in the application's state file. The other 
information must be set correctly upon launch.

*ALB_appRef* stores the **AppInstanceReference** which specifies the 
pathname to both the application and its associated state file.

*ALB_appMode* stores the attach mode message used to invoke the 
application. This should be one of the following:

MSG_GEN_PROCESS_RESTORE_FROM_STATE  
State file must be passed; no data file should be passed.

MSG_GEN_PROCESS_OPEN_APPLICATION  
State file normally should not be passed, although one might 
pass a state file to use UI templates. A data file may be passed 
as well.

MSG_GEN_PROCESS_OPEN_ENGINE  
State file normally should not be passed. The data file on which 
the engine will operate must be passed. If this is zero, the 
default data file should be used. (The default data file is 
specified by the application, not **GenProcessClass**.)

*ALB_launchFlags* stores the **AppLaunchFlags** that specify the type of 
launch desired for the application.

*ALB_diskHandle* stores the disk handle for the data path. (This is set as the 
application's current path in MSG_META_ATTACH.)

*ALB_path* stores the directory path for the application to use as its default 
starting path. (This is also set as the application's current path in 
MSG_META_ATTACH.)

*ALB_dataFile* stores the name of the associated data file to be opened (or zero 
if none). The file name is relative to *ALB_path*.

*ALB_genParent* stores the generic parent of the launching application (or zero 
to specify the default field). (This optr should be null when sent to 
MSG_GEN_FIELD_LAUNCH_APPLICATION.)

*ALB_userLoadAckAD* stores the **ActionDescriptor** to activate once the 
application is successfully launched (used in conjunction with 
ALF_SEND_LAUNCH_REQUEST_TO_UI_TO_HANDLE). This 
**ActionDescriptor** should be set to zero if no action should be sent. The 
event sent will pass the following information:  
cx - **GeodeHandle** (if launched successfully).  
dx - Error (0 if no error).  
bp - ID passed in *ALB_userLoadAckID*.  
This **ActionDescriptor** should be set to zero if no action should be sent.

*ALB_userLoadAckID* stores the ID sent out via ALB_userLoadAckAD, if any.

*ALB_extraData* stores extra data to send to the process, if any (possibly a 
handle to a block containing extra arguments).

**Library:** Objects/gProcC.def

----------
#### AppLaunchFlags
    AppLaunchFlags          record
        ALF_SEND_LAUNCH_REQUEST_TO_UI_TO_HANDLE     :1
        ALF_OPEN_IN_BACK                            :1
        ALF_DESK_ACCESSORY                          :1
        ALF_DO_NOT_OPEN_ON_TOP                      :1
        ALF_OVERRIDE_MULTIPLE_INSTANCE              :1
        ALF_OPEN_FOR_IACP_ONLY                      :1
                                                    :2
    AppLaunchFlags          end

ALF_SEND_LAUNCH_REQUEST_TO_UI_TO_HANDLE  
If this bit is set, the application will not immediately be launched, but instead 
the UI will be sent a method which will cause it to do so. Because of this, no 
error is returned. (This flag should *not* be passed to the application itself; it 
is used only by UserLoadApplication.)

ALF_OPEN_IN_BACK  
Set to open application behind other applications. It will also ensure that if 
an application has multiple GenPrimaries, (each with a different Layer ID), 
the GenPrimaries will be restored in the correct order (one behind the other). 
This flag is normally set when restoring from state.

ALF_DESK_ACCESSORY  
Set to open application as a "desk accessory", in a layer above normal 
applications.

ALF_DO_NOT_OPEN_ON_TOP  
Set to prevent application from opening on top with the focus. 

ALF_OVERRIDE_MULTIPLE_INSTANCE  
Set to prevent application, when running in a UILM_MULTIPLE_INSTANCE 
field, from asking the user whether to start another copy. This flag is used 
especially by the express menu.

ALF_OPEN_FOR_IACP_ONLY  
This flag is used only for MSG_GEN_PROCESS_OPEN_APPLICATION mode 
connections. This flag is set if the application is being launched via 
**IACPConnect()** for a specific task only, and should close once the task is 
complete, as indicated by the IACP connection closing (unless there is some 
other reason for the application to stay open, such as other application-mode 
IACP connections). This flag should be clear where ever **IACPConnect()** is 
being used to open an application with the intention that the application is 
to remain open after the IACP connection is closed.

**Library:** Objects/gProcC.def

----------
#### ApplicationStates
    ApplicationStates           record
                                        :1
        AS_TRANSPARENT                  :1
        AS_HAS_FULL_SCREEN_EXCL         :1
        AS_QUIT_DETACHING               :1
        AS_AVOID_TRANSPARENT_DETACH     :1
        AS_TRANSPARENT_DETACHING        :1
        AS_REAL_DETACHING               :1
        AS_QUITTING                     :1
        AS_DETACHING                    :1
        AS_FOCUSABLE                    :1
        AS_MODELABLE                    :1
        AS_NOT_USER_INTERACTIBLE        :1
        AS_RECEIVED_APP_OBJECT_DETACH   :1
        AS_ATTACHED_TO_STATE_FILE       :1
        AS_ATTACHING                    :1
        ApplicationStates       end

AS_TRANSPARENT  
Set if the application is running in UILM_TRANSPARENT mode.

AS_HAS_FULL_SCREEN_EXCL  
Set if the application has the full screen.

AS_SINGLE_INSTANCE  
Set if the application is not capable of being launched multiple times.

AS_QUIT_DETACHING  
Set if the detach sequence has been initiated as the result of a *quit*.

AS_AVOID_TRANSPARENT_DETACH  
Set if this application should ignore transparent detaches.

AS_TRANSPARENT_DETACHING  
Set if this application is being transparently-detached, that is, being 
shutdown to state because another application has been started in this 
application's field and that field is in UILM_TRANSPARENT mode.

AS_REAL_DETACHING  
Set while the application is irreversibly detaching, after the UI has been 
detached and the application's GS_USABLE bit has been cleared.

AS_QUITTING  
Set if the application is currently quitting.

AS_DETACHING  
Set if the app object is detaching.

AS_FOCUSABLE  
Set if the application may receive the "Focus" exclusive. If set, the application 
will be given the focus exclusive within its field, when launched, or clicked in 
by the user. This bit is set TRUE by default. This bit is copied to the 
**GeodeWinFlags** stored as part of the geode upon load, which act to guide 
the window system.

AS_MODELABLE  
Set if the application may receive the "Model" exclusive. If set, the 
application will be given the model exclusive within its field, when launched, 
or clicked in by the user. Unless you're doing something odd, you'll want to 
have this match the state of your GA_TARGETABLE bit. This bit is set TRUE 
by default. This bit is copied to the **GeodeWinFlags** stored as part of the 
geode upon load, which act to guide the window system.

AS_NOT_USER_INTERACTABLE  
Clear if this is a standard application which has at least one primary window 
or other interactable window on-screen. If this bit is set, then the UI need not 
provide options to navigate or select this application for user interaction.

AS_RECEIVED_APP_OBJECT_DETACH  
 Set if we have received a MSG_GEN_APPLICATION_OBJECT_DETACH.

AS_ATTACHED_TO_STATE_FILE  
Set if we are attached to a state file.

AS_ATTACHING  
Set if the application is in the process of attaching.

**Library:** Objects/gAppC.def

----------
#### AppMeasurementType
    AppMeasurementType      etype       byte
        AMT_US      enum        AppMeasurementType, MEASURE_US
        AMT_METRIC  enum        AppMeasurementType, MEASURE_METRIC
        AMT_DEFAULT enum        AppMeasurementType, 0xff ;use system default

**Library:** Objects/gAppC.def

----------
#### AppNavigationID
    AppNavigationID     etype       word, NAVIGATION_ID_APP_START
        NAVIGATION_ID_START_OF_RANGE    equ     0x8000

This mask is OR-ed into a navigation ID number (which is given in 
HINT_NAVIGATION_ID); this bit specifies that the ID number serves as the 
start of a range.

**Library:** Objects/genC.def

----------
#### AppUIData
    AppUIData       struct
        AUID_specificUI             hptr            ;handle of specific UI
        AUID_displayScheme          DisplayScheme <>
        AUID_noTargetNoFocusReg     fptr.Region     ;cursor for no target, no focus
        AUID_targetNoFocusReg       fptr.Region     ;cursor for target, no focus
        AUID_noTargetFocusReg       fptr.Region     ;cursor for no target, focus
        AUID_targetFocusReg         fptr.Region     ;cursor for target, focus
        AUID_textKbdBindings        fptr            ;VisText kbd bindings.
        AUID_textEditCursor         optr.PointerDef ;handle:chunk to PointerDef
                                                    ;(cursor) for text editing
    AppUIData       ends

This structure stores the UI data stored with each process.

**Library:** Objects/gAppC.def

----------
#### ApplicationOptFlags
    ApplicationOptFlags         record
        AOF_MULTIPLE_INIT_FILE_CATEGORIES   :1
                                            :7
    ApplicationOptFlags         ends

AOF_MULTIPLE_INIT_FILE_CATEGORIES  
This is an optimization flag for **UserGetIniCategory**. Keep it clear if an 
application has only one init file category.

**Library:** Objects/gAppC.def

----------
#### ArcCloseType
    ArcCloseType        etype       word
        ACT_OPEN    enum        ArcCloseType    ; illegal for filled arcs
        ACT_CHORD   enum        ArcCloseType    ; draw/fill as a chord
        ACT_PIE     enum        ArcCloseType    ; draw/fill as a pie

**Library:** graphics.def

----------
#### ArcBasicInit
    ArcBasicInit        struct
        ABI_arcCloseType        ArcCloseType
        ABI_startAngle          WWFixed
        ABI_endAngle            WWFixed
        ABI_startPoint          PointWWFixed
        ABI_endPoint            PointWWFixed
        ABI_midPoint            PointWWFixed
        ABI_radius              WWFixed 
    ArcBasicInit    ends

**Library:** grobj.def

----------
#### ArcParams
    ArcParams           struct
        AP_close    ArcCloseTyp     ; how the arc should be closed
        AP_left     sword           ; ellipse bounding box: left
        AP_top      sword           ;                       top
        AP_right    sword           ;                       right
        AP_bottom   sword           ;                       bottom
        AP_angle1   sword           ; start angle for arc
        AP_angle2   sword           ; ending angle for arc
    ArcParams           ends

**ArcParams** is a structure passed to several arc construction routines.

**Library:** graphics.def

----------
#### AreaAttr
    AreaAttr        struct
        AA_colorFlag    ColorFlag CF_INDEX      ; RGB or INDEX
        AA_color        RGBValue <0,0,0>        ; RGB values or index
        AA_mask         SystemDrawMask          ; draw mask
        AA_mapMode      ColorMapMode            ; color map mode
    AreaAttr        ends

This structure is used with **GrSetAreaAttr**.

**Library:** graphics.def

----------
#### ArgumentStackElement
    ArgumentStackElement            struct
        ASE_type        EvalStackArgumentType   ; The type of argument.
        ASE_data        EvalStackArgumentData   ; The associated data.
    ArgumentStackElement            ends

**Library:** parse.def

----------
#### BackgroundColors
    BackgroundColors        struc
        BC_unselectedColor1     byte    ;the two colors to use when unselected
        BC_unselectedColor2     byte
        BC_selectedColor1       byte    ;the two colors to use when selected
        BC_selectedColor2       byte
    BackgroundColors        ends

**Library:** Objects/genC.def

----------
#### BasicGrab
    BasicGrab               struct
        BG_OD       optr
        BG_data     word
    BasicGrab               ends

This structure is used for grab mechanisms where a single optr has the grab 
at any moment in time, and when methods should be sent out to notify optrs 
of their gaining or losing of the grab. The *BG_data* field is solely to keep the 
struct the same size as the **MouseGrab** structures, so that common routines 
may operate on the different structures.

**Library:** Objects/uiInputC.def

----------
#### BasicInit
    BasicInit       struct
        BI_center       PointDWFixed
        BI_width        WWFixed
        BI_height       WWFixed
        BI_transform    GrObjTransMatrix
        align           word
    BasicInit       ends

**Library:** grobj.def

----------
#### BBFixed
    BBFixed     struct
        BBF_frac        byte
        BBF_int         byte
    BBFixed     ends

This structure stores an 8 bit/8 bit fixed point number.

**Library:** geos.def

----------
#### BCCToolboxFeatures
    BCCToolboxFeatures          record
    BCCToolboxFeatures          end

**Library:** Objects/Text/tCtrlC.def

----------
#### BCFeatures
    BCFeatures              record
        BCF_LIST        :1
        BCF_CUSTOM      :1
    BCFeatures              end

**Library:** Objects/Text/tCtrlC.def

----------
#### BCToolboxFeatures
    BCToolboxFeatures       record
    BCToolboxFeatures       end

**Library:** Objects/Text/tCtrlC.def

----------
#### Bitmap
    Bitmap  struct
        B_width     word
        B_height    word
        B_compact   BMCompact BMC_UNCOMPACTED
        B_type      BMType <0,0,0,0,BMF_MONO>
    Bitmap  ends

This structure stores information about a simple graphics bitmap.

*B_width* and *B_height* store the width and height of the bitmap, in points 
(pixels).

*B_compact* stores the method of compaction in use by this bitmap.

*B_type* stores the bitmap type (**BMType**).

**Library:** graphics.def

----------
#### BitmapGuardianBitmapPointerActiveStatus
    BitmapGuardianBitmapPointerActiveStatus etype byte, 0
        BGBPAS_ACTIVE       enum    BitmapGuardianBitmapPointerActiveStatus
        BGBPAS_INACTIVE     enum    BitmapGuardianBitmapPointerActiveStatus

**Library:** grobj.def

----------
#### BitmapGuardianFlags
    BitmapGuardianFlags             record
        BGF_POINTER_ACTIVE              :1
        BGF_REAL_ESTATE_RESIZE          :1
        BitmapGuardianFlags         end

BGF_POINTER_ACTIVE  
This flag specifies that a floater is a **BitmapPointer**, so the bitmap should 
display handles instead of a dotted box for its edit indicator and it should 
respond to clicks on those handles. The **BitmapPointer** is used for changing 
the bitmap width and height.

BGF_REAL_ESTATE_RESIZE  
This flag specifies that the current resize action is actually a real estate 
resize.

**Library:** grobj.def

----------
#### BitmapGuardianSpecificInitializationData
    BitmapGuardianSpecificInitializationData    struct
        BGSID_toolClass                 fptr.ClassStruct
        BGSID_activeStatus              VisWardToolActiveStatus
    BitmapGuardianSpecificInitializationData    ends

**Library:** grobj.def

----------
#### BitmapMode
    BitmapMode      record
                                :14
        BM_EDIT_MASK            :1
        BM_CLUSTERED_DITHER     :1
    BitmapMode      end

BM_EDIT_MASK  
This flag specifies whether the mask is edited.

BM_CLUSTERED_DITHER  
This flag specifies that the bitmap uses a clustered dither instead of a 
dispersed dither.

**Library:** graphics.def

----------
#### BLTMode
    BLTMode etype   word
        BLTM_COPY       enum BLTMode        ; 0 = copy image
        BLTM_MOVE       enum BLTMode        ; 1 = move image
        BLTM_CLEAR      enum BLTMode        ; 2 = clear source rect

**Library:** graphics.def

----------
#### BMCompact
    BMCompact       etype       byte
        BMC_UNCOMPACTED     enum BMCompact          ; 0 = no compaction
        BMC_PACKBITS        enum BMCompact          ; 1 = Mac packbits
        BMC_USER_DEFINED    enum BMCompact, 0x80    ; >0x80 = user defined 
                                                    ; compaction

This data structure is used to specify what sort of compaction is used top 
store a graphics bitmap.

**Library:** graphics.def

----------
#### BMDestroy
    BMDestroy       etype       byte
        BMD_KILL_DATA       enum BMDestroy      ; 0 = free bitmap (HugeArray)
        BMD_LEAVE_DATA      enum BMDestroy      ; 1 = leave bitmap data alone

**Library:** graphics.def

----------
#### BMFormat
    BMFormat        etype       byte, 0
        BMF_MONO        enum BMFormat       ; 0 = monochrome
        BMF_4BIT        enum BMFormat       ; 1 = 4-bit (EGA,VGA)
        BMF_8BIT        enum BMFormat       ; 2 = 8-bit (MCGA,SVGA)
        BMF_24BIT       enum BMFormat       ; 3 = 24-bit (high end cards)
        BMF_4CMYK       enum BMFormat       ; 4 = 4-bit CMYK (printers)
        BMF_3CMY        enum BMFormat       ; 5 = 3-bit CMY (printers)

This type determines a graphic bitmap's depth.

**Library:** graphics.def

----------
#### BMType
    BMType      record
        BMT_PALETTE         :1
        BMT_HUGE            :1
        BMT_MASK            :1
        BMT_COMPLEX         :1
        BMT_FORMAT          BMFormat:3
    BMType      end

This record stores various facts about a graphics bitmap.

BMT_PALETTE  
This flag indicates: 0 = no palette stored with bitmap; 1 = palette 
supplied. (This bit is ignored if BMT_COMPLEX = 0.)

BMT_HUGE  
This flag indicates that the bitmap is stored in a **HugeArray**.

BMT_MASK  
This flag specifies that a bitmap mask is stored along with bitmap data.

BMT_COMPLEX  
This flag specifies that this is not a simple bitmap. This flag must set to use 
a palette.

BMT_FORMAT  
The type of bitmap format (**BMFormat**) is specified here.

**Library:** graphics.def

----------
#### BooleanByte
    BooleanByte             etype       byte
        BB_FALSE    enum        BooleanByte, 0
        BB_TRUE     enum        BooleanByte, 255

**Library:** geos.def

----------
#### BooleanWord
    BooleanWord             etype       word
        BW_FALSE    enum        BooleanWord, 0
        BW_TRUE     enum        BooleanWord, 0ffffh

**Library:** geos.def

----------
#### BoundingRectData
    BoundingRectData            struct
        BRD_rect            RectDWFixed
        CheckHack           < (offset BRD_rect eq 0) >
        BRD_destGState      hptr.GState
        BRD_parentGState    hptr.GState
        BRD_initialized     word
    BoundingRectData            ends

*BRD_initialized* is zero if the rectangle has not been initialized. This entry is 
generally ignored except by groups.

**Library:** grobj.def

----------
#### BranchReplaceParams
    BranchReplaceParams                 struct
        BRP_searchParam         dd  (?)
        BRP_replaceParam        dd  (?)
        BRP_type                BranchReplaceParamType
    BranchReplaceParams                 ends

*BRP_searchParam* stores the search parameter, which is compared with 
instance data. Single word compare values should be stored in the first word; 
single byte values should be stored in the first byte.

*BRP_replaceParam* stores the replace parameter, which replaces any 
instance data which matches the search parameter. Single word compare 
values should be stored in first word, single byte in first byte.

*BRP_type* stores the type of replace operation 
(**BranchReplaceParamType**).

**Library:** Objects/genC.def

----------
#### BranchReplaceParamType
    BranchReplaceParamType          etype       word
        BRPT_OUTPUT_OPTR        enum    BranchReplaceParamType

This type is passed with MSG_GEN_BRANCH_REPLACE_PARAMS to specify 
the type of replacement operation to effect. 

The type BRPT_OUTPUT_OPTR affects all optr's stored in output optr fields 
and action descriptors within the generic branch, replacing and relocating 
them. Generic linkage itself is not affected. 

The following generic objects recognize this replacement operation:  
GenTrigger, GenList, GenValue, GenText: action optr's, 
GenView: output optr's.

**Library:** Objects/genC.def

----------
#### Button
    Button  etype   byte
        BUTTON_0        enum        Button
        BUTTON_1        enum        Button
        BUTTON_2        enum        Button
        BUTTON_3        enum        Button

**Library:** input.def

----------
#### ButtonInfo
    ButtonInfo          record
        BI_PRESS            :1
        BI_DOUBLE_PRESS     :1
        BI_B3_DOWN          :1
        BI_B2_DOWN          :1
        BI_B1_DOWN          :1
        BI_B0_DOWN          :1
        BI_BUTTON           Button:2
    ButtonInfo          end

This record defines the active state of a mouse's buttons.

**Library:** input.def

----------
#### C_CallbackStruct
    C_CallbackStruct        struc
        C_callbackType  CallbackType
        C_params        fptr
        C_returnDS      word
        C_u             C_CallbackUnion
        align           word
    C_CallbackStruct        ends

**Library:** parse.def

----------
#### C_CallbackUnion
    C_CallbackUnion     union
        CT_ftt      CT_FFT_CallbackStruct
        CT_ntt      CT_NTT_CallbackStruct
        CT_cne      CT_CNE_CallbackStruct
        CT_cns      CT_CNS_CallbackStruct
        CT_ef       CT_EF_CallbackStruct
        CT_ln       CT_LN_CallbackStruct
        CT_ul       CT_UL_CallbackStruct
        CT_ff       CT_FF_CallbackStruct
        CT_fn       CT_FN_CallbackStruct
        CT_cc       CT_CC_CallbackStruct
        CT_ec       CT_EX_CallbackStruct
        CT_ntc      CT_NTC_CallbackStruct
        CT_ftc      CT_FTC_CallbackStruct
        CT_dc       CT_DC_CallbackStruct
        CT_sf       CT_SF_CallbackStruct
    C_CallbackUnion     end

**Library:** parse.def

----------
#### CallBackMessageData
    CallBackMessageData         struct
        CBMD_callBackOD             optr
        CBMD_callBackMessage        word
        CBMD_groupOD                optr
        CBMD_childOD                optr
        CBMD_extraData1             word
        CBMD_extraData2             word
        CallBackMessageData     ends

**Library:** grobj.def

----------
#### CallbackType
    CallbackType        etype       byte, 0, 1
        CT_FUNCTION_TO_TOKEN            enum        CallbackType
            ; Description:
            ;   Converts a function name to a function ID token.
            ; Pass:
            ;   ss:bp       = Pointer to ParserParameters structure
            ;   ds:si       = Pointer to the text of the identifier
            ;   cx          = Length of the identifier
            ; Return:
            ;   carry set if the text is a function name
            ;   di          = The Function-ID for the identifier
            ;
        CT_NAME_TO_TOKEN                enum        CallbackType
            ; Description:
            ;   Converts a name to a name ID token.
            ; Pass:
            ;   ss:bp       = Pointer to ParserParameters structure
            ;   ds:si       = Pointer to the text of the name
            ;   cx          = Length of the name
            ; Return:
            ;   cx          = Token for the name
            ;   Carry set on error
            ;   al          = Error code
            ;
        CT_CHECK_NAME_EXISTS            enum        CallbackType
            ; Description:
            ;   Checks whether a name already exists
            ; Pass:
            ;   ss:bp       = Pointer to ParserParameters structure 
            ;   ds:si       = Pointer to the text of the name
            ;   cx          = Length of the name
            ; Return:
            ;   carry set if the name exists
            ;   carry clear otherwise
            ;
        CT_CHECK_NAME_SPACE             enum        CallbackType
            ; Description:
            ;   Signals the need to allocate a certain number of names.
            ;   This avoids the problem of getting part way through
            ;   a set of name glaciations for an expression and running out 
            ;   of space for the names.
            ; Pass:
            ;   ss:bp       = Pointer to ParserParameters structure
            ;   cx          = Number of names we want to allocate
            ; Return:
            ;   Carry set on error
            ;   al          = Error code
            ;
        CT_EVAL_FUNCTION                enum        CallbackType
            ; Description:
            ;   Evaluates a function with parameters.
            ; Pass:
            ;   ss:bp       = Pointer to EvalParameters structure
            ;   cx          = Number of arguments
            ;   si          = Function ID
            ;   es:di       = Operator stack
            ;   es:bx       = Argument stack
            ; Return:
            ;   carry set on error
            ;   al          = Error code
            ;
        CT_LOCK_NAME                    enum        CallbackType
            ; Description:
            ;   Locks a name definition.
            ; Pass:
            ;   ss:bp       = Pointer to ParserParameters structure
            ;   cx          = Name token
            ; Return:
            ;   carry set on error
            ;   al          = Error code
            ;   ds:si       = Pointer to the definition
            ;
        CT_UNLOCK                       enum        CallbackType
            ; Description:
            ;   Unlocks a name/function definition.
            ; Pass:
            ;   ss:bp       = Pointer to ParserParameters structure
            ;   ds          = Segment address of the data to unlock
            ;
        CT_FORMAT_FUNCTION              enum        CallbackType
            ; Description:
            ;   Formats a function name into a buffer.
            ; Pass:
            ;   ss:bp       = Pointer to ParserParameters structure
            ;   es:di       = Buffer to store the text
            ;   cx          = Function token
            ;   dx          = Maximum number of characters that can be written
            ; Return:
            ;   es:di       = Pointer past the inserted text
            ;   dx          = Number of characters that were written
            ;
        CT_FORMAT_NAME                  enum        CallbackType
            ; Description:
            ;   Formats a name into a buffer.
            ; Pass:
            ;   ss:bp       = Pointer to ParserParameters structure
            ;   es:di       = Place to store the text
            ;   cx          = Name token
            ;   dx          = Maximum number of characters that can be written
            ; Return:
            ;   ss:bp       = Pointer to ParserParameters structure
            ;   es:di       = Pointer past the inserted text
            ;   dx      = Number of characters that were written
            ;
        CT_CREATE_CELL                  enum        CallbackType
            ; Description:
            ;   Creates a new empty cell. Used by the dependency code to
            ;   create a cell to add dependencies to.
            ; Pass:
            ;   ss:bp       = Pointer to ParserParameters structure
            ;   dx          = Row of the cell to create
            ;   cx          = Column of the cell to create
            ; Return:
            ;   carry set on error
            ;   al          = Error code
            ;
        CT_EMPTY_CELL                   enum        CallbackType
            ; Description:
            ;   Removes a cell if it's appropriate. This is called when a cell
            ;   has its last dependency removed.
            ; Pass:
            ;   ss:bp       = Pointer to ParserParameters structure
            ;   dx          = Row of the cell that now has no dependencies
            ;   cx          = Column of the cell that now has no dependencies
            ; Return:
            ;   carry set on error
            ;   al          = Error code
            ;
        CT_NAME_TO_CELL                 enum        CallbackType
            ; Description:
            ;   Converts a name into a cell to enable the addition of 
            ;   dependencies to it.
            ; Pass:
            ;   ss:bp       = Pointer to ParserParameters structure
            ;   cx          = Name token
            ; Return:
            ;   dx          = Row of the cell containing the names 
            ;               dependencies
            ;   cx          = Column of the cell containing the names 
            ;               dependencies
            ;
        CT_FUNCTION_TO_CELL             enum        CallbackType
            ; Description:
            ;   Converts a function into a cell to enable the addition of 
            ;   dependencies to it.
            ; Pass:
            ;   ss:bp       = Pointer to ParserParameters structure
            ;   cx          = Function-ID
            ; Return:
            ;   dx          = Row of the cell containing the functions ;    
            ;                   dependencies
            ;               = 0 if no dependency is required
            ;   cx          = Column of the cell containing the functions
            ;               dependencies.
            ;
        CT_DEREF_CELL                   enum        CallbackType
            ; Description:
            ;   Returns the contents of a cell. The callback is responsible for
            ;   popping the cell reference off the stack.
            ; Pass:
            ;   es:bx       = Pointer to the argument stack
            ;   es:di       = Pointer to operator/function stack
            ;   ss:bp       = Pointer to EvalParameters structure
            ;   dx          = Row of the cell to dereference
            ;   cx          = Column of the cell to dereference
            ; Return:
            ;   es:bx       = New pointer to the argument stack
            ;   carry set on error
            ;   al          = Error code
            ;
        CT_SPECIAL_FUNCTION             enum        CallbackType
            ; Description:
            ;   Returns the value of one of the special functions.
            ; Pass:
            ;   es:bx       = Pointer to the argument stack
            ;   es:di       = Pointer to operator/function stack
            ;   ss:bp       = Pointer to EvalParameters structure
            ;   cx          = Special function
            ; Return:
            ;   es:bx       = New pointer to the argument stack
            ;   carry set on error
            ;   al          = Error code

**Library:** parse.def

----------
#### CBitmap
    CBitmap struct
        CB_simple       Bitmap <>           ; simple bitmap structure
        CB_startScan    word 0              ; starting row number
        CB_numScans     word 1              ; Number of scans of data in this slice
        ;
        ; the following three offsets are offsets from the start of the bitmap
        ; structure
        ;
        CB_devInfo      word 0              ; offset to device info
        CB_data         word (size CBitmap) ; offset to start of data
        CB_palette      word 0              ; offset to color table
                                            ; (if bit 6 set in B_type of Bitmap 
                                            ; structure)
        CB_xres         word 72             ; x resolution (DPI)
        CB_yres         word 72             ; y resolution (DPI)
    CBitmap ends

This structure stores information for a "complex" bitmap. (For a simple 
bitmap see the reference entry for **Bitmap**.)

**CBitmap** holds bitmap specifics such as resolution information, a palette, 
and mask data.

**Library:** graphics.def

----------
#### CDependencyStruct
    CDependencyStruct       struc
        DP_parameters               DependencyParameters
        DP_callbackPtr              fptr
        DP_callbackStruct           C_CallbackStruct
    CDependencyStruct       ends

**Library:** parse.def

----------
#### CellFunctionParameterFlags
    CellFunctionParameterFlags              record
        CFPF_DIRTY          :1  ;If set, the parameter block is dirty.
                            :4  ;Unused.
        CFPF_NO_FREE_COUNT  :3  ;Set temporarily in RangeEnum to make sure 
                                ;that a callback doesn't attempt to free 
                                ;anything. These bits count the number of 
                                ;calls to a non-special RangeEnum
    CellFunctionParameterFlags              end

**Library:** cell.def

----------
#### CellFunctionParameters
    CellFunctionParameters          struct
        CFP_flags           CellFunctionParameterFlags
        CFP_file            word
        CFP_rowBlocks       RowBlockList
    CellFunctionParameters          ends

This structure is used to pass specifics about a cell file to the cell library 
routines. Some of the data in the **CellFunctionParameters** structure is 
opaque to the application (namely, the *CFP_flags*) and should not be modified 
by the application.

*CFP_flags* stores flags that are set and modified by the cell library. The only 
flag that is allowed to be checked or changed is the *CFPF_dirty* flag. The cell 
library routines set this bit whenever it changes the 
**CellFunctionParameters** structure, indicating that the structure needs to 
be resaved. After it is saved, you may clear this bit.

*CFP_file* must contain the VM file handle of the cell file. This field must be set 
each time you open the file. The cell library routines will always act on the 
file specified here, not on the VM override file (if any).

*CFP_rowBlocks* contains an array of VM block handles, one for every existing 
or potential row block. The length of this array is N_ROW_BLOCKS (defined 
in **cell.h**). When you create a cell file, initialize all of these handles to zero; 
do not access or change this field thereafter.

**Warning:** The cell library expects the **CellFunctionParameters** structure to remain 
motionless for the duration of the call. Therefore, if you allocate it as a DB 
item in a cell file, you must not have the structure be an ungrouped item.

**Library:** cell.def

----------
#### CellRange
    CellRange       struct
        CR_start        CellReference <>
        CR_end          CellReference <>
    CellRange       ends

This structure specifies a rectangular range of cells

**Library:** parse.def

----------
#### CellReference
    CellReference       struct
        CR_row      CellRowColumn <>
        CR_column   CellRowColumn <>
    CellReference       ends

Cell references can be absolute, relative, or mixed. If the cell reference is 
absolute, this structure specifies a particular cell; if the reference is relative, 
this structure specifies an offset from a previous cell position.

**Library:** parse.def

----------
#### CellRowColumn
    CellRowColumn       record
        CRC_ABSOLUTE            :1  ; Set if the reference is absolute
        CRC_VALUE               :15 ; The value of the row/column
    CellRowColumn       end

**Library:** parse.def

----------
#### CenterLeftRightWidth
    CenterLeftRightWidth            etype       byte
        CLRW_CENTER         enum    CenterLeftRightWidth
        CLRW_LEFT           enum    CenterLeftRightWidth
        CLRW_RIGHT          enum    CenterLeftRightWidth
        CLRW_WIDTH          enum    CenterLeftRightWidth

**Library:** grobj.def

----------
#### CenterTopBottomHeight
    CenterTopBottomHeight           etype       byte
        CTBH_CENTER         enum    CenterTopBottomHeight
        CTBH_TOP            enum    CenterTopBottomHeight
        CTBH_BOTTOM         enum    CenterTopBottomHeight
        CTBH_HEIGHT         enum    CenterTopBottomHeight

**Library:** grobj.def

----------
#### CEvalStruct
    CEvalStruct     struc
        CE_parameters           EvalParameters
        CE_callbackPtr          fptr
        CE_callbackStruct       C_CallbackStruct
    CEvalStruct     ends

**Library:** parse.def

----------
#### CFormatStruct
    CFormatStruct       struc
        CF_parameters           FormatParameters
        CF_callbackPtr          fptr
        CF_callbackStruct       C_CallbackStruct
    CFormatStruct       ends

**Library:** parse.def

----------
#### CharacterSet
    CharacterSet        etype       byte
        CS_BSW      enum CharacterSet, 0x00 ;Extended BSW set (printable) (Chars)
        CS_CONTROL  enum CharacterSet, 0xff ;Control codes (non-printable) (VChar)
        CS_UI_FUNCS enum CharacterSet, 0xfe ;Special UI functions, not actually key
                                            ;presses, defined in ui.def (UChar)
        VC_ISANSI   = CS_BSW
        VC_ISCTRL   = CS_CONTROL
        VC_ISUI     = CS_UI_FUNCS

**Library:** input.def

----------
#### CharChoiceInformation
    CharChoiceInformation               struct
        CCI_numChoices          word
        CCI_firstPoint          word
        CCI_lastPoint           word
        CCI_data                fptr.word
    CharChoiceInformation               ends

*CCI_numChoices* stores the number of choices for this character (can be 0)

*CCI_firstPoint* stores the offset to the first point in the ink data corresponding 
to this char. 

*CCI_lastPoint* stores the offset to the last point in the ink data corresponding 
to this char.

*CCI_data* stores the actual pointer to the characters.

**Library:** hwr.def

----------
#### CharFlags
    CharFlags       record
        CF_STATE_KEY    :1  ;Set if state key (shift/toggle modifier)
            :2
        CF_EXTENDED     :1  ;TRUE: extended key
        CF_TEMP_ACCENT  :1  ;Set if temporary accent char
        CF_FIRST_PRESS  :1  ;Set if initial key press
        CF_REPEAT_PRESS :1  ;Set if repeated key press
        CF_RELEASE      :1  ;Set if key release (may be set in conjunction 
                            ;with the other two, by monitors or UI to lessen
                            ;number of events)
    CharFlags       end



**Library:** input.def

----------
#### Chars
    Chars   etype   byte

        C_NULL          enum Chars, 0x0         ;NULL
        C_CTRL_A        enum Chars, 0x1         ;<ctrl>-A
        C_CTRL_B        enum Chars, 0x2         ;<ctrl>-B
        C_CTRL_C        enum Chars, 0x3         ;<ctrl>-C
        C_CTRL_D        enum Chars, 0x4         ;<ctrl>-D
        C_CTRL_E        enum Chars, 0x5         ;<ctrl>-E
        C_CTRL_F        enum Chars, 0x6         ;<ctrl>-F
        C_CTRL_G        enum Chars, 0x7         ;<ctrl>-G
        C_CTRL_H        enum Chars, 0x8         ;<ctrl>-H
        C_TAB           enum Chars, 0x9         ; TAB
        C_LINEFEED      enum Chars, 0xa         ; LINE FEED
        C_CTRL_K        enum Chars, 0xb         ;<ctrl>-K
        C_CTRL_L        enum Chars, 0xc         ;<ctrl>-L
        C_ENTER         enum Chars, 0xd         ; ENTER or CR
        C_SHIFT_OUT     enum Chars, 0xe         ;<ctrl>-N
        C_SHIFT_IN      enum Chars, 0xf         ;<ctrl>-O
        C_CTRL_P        enum Chars, 0x10        ;<ctrl>-P
        C_CTRL_Q        enum Chars, 0x11        ;<ctrl>-Q
        C_CTRL_R        enum Chars, 0x12        ;<ctrl>-R
        C_CTRL_S        enum Chars, 0x13        ;<ctrl>-S
        C_CTRL_T        enum Chars, 0x14        ;<ctrl>-T
        C_CTRL_U        enum Chars, 0x15        ;<ctrl>-U
        C_CTRL_V        enum Chars, 0x16        ;<ctrl>-V
        C_CTRL_W        enum Chars, 0x17        ;<ctrl>-W
        C_CTRL_X        enum Chars, 0x18        ;<ctrl>-X
        C_CTRL_Y        enum Chars, 0x19        ;<ctrl>-Y
        C_CTRL_Z        enum Chars, 0x1a        ;<ctrl>-Z
        C_ESCAPE        enum Chars, 0x1b        ;ESC

        ; common shortcuts for low 32 codes
        C_NUL       = C_NULL
        C_STX       = C_CTRL_B
        C_ETX       = C_CTRL_C
        C_BEL       = C_CTRL_G
        C_BS        = C_CTRL_H
        C_HT        = C_CTRL_I
        C_VT        = C_CTRL_K
        C_FF        = C_CTRL_L
        C_SO        = C_CTRL_N
        C_SI        = C_CTRL_O
        C_DC1       = C_CTRL_Q
        C_DC2       = C_CTRL_R
        C_DC3       = C_CTRL_S
        C_DC4       = C_CTRL_T
        C_CAN       = C_CTRL_X
        C_EM        = C_CTRL_Y
        C_ESC       = C_ESCAPE
        ;
        ; some alternative names:
        ;
        C_CR        = C_ENTER
        C_CTRL_M    = C_ENTER
        C_CTRL_I    = C_TAB
        C_CTRL_J    = C_LINEFEED
        C_LF        = C_LINEFEED
        C_CTRL_N    = C_SHIFT_OUT
        C_CTRL_O    = C_SHIFT_IN

        C_NULL_WIDTH        enum Chars, 0x19    ; null width character
        C_GRAPHIC           enum Chars, 0x1a    ; Graphic in text.
        C_THINSPACE         enum Chars, 0x1b    ; 1/4 width space
        C_ENSPACE           enum Chars, 0x1c    ; En-space, fixed width
        C_EMSPACE           enum Chars, 0x1d    ; Em-space, fixed width.

        C_SECTION_BREAK     enum Chars, C_CTRL_K
        C_PAGE_BREAK        enum Chars, C_CTRL_L

        C_COLUMN_BREAK      =   C_PAGE_BREAK

        C_NONBRKHYPHEN      enum    Chars, 0x1e ; Non breaking hyphen.
        C_OPTHYPHEN         enum    Chars, 0x1f ; Optional hyphen, only drawn
                                                ; at end of line.
        C_FS                = C_ENSPACE
        C_FIELD_SEP         = C_FS
        ;
        ; the standard ASCII chars:
        ;
        C_SPACE             enum Chars, ' '
        C_EXCLAMATION       enum Chars, '!'
        C_QUOTE             enum Chars, '"'
        C_NUMBER_SIGN       enum Chars, '#'
        C_DOLLAR_SIGN       enum Chars, '$'
        C_PERCENT           enum Chars, '%'
        C_AMPERSAND         enum Chars, '&'
        C_SNG_QUOTE         enum Chars, 0x27
        C_LEFT_PAREN        enum Chars, '('
        C_RIGHT_PAREN       enum Chars, ')'
        C_ASTERISK          enum Chars, '*'
        C_PLUS              enum Chars, '+'
        C_COMMA             enum Chars, ','
        C_MINUS             enum Chars, '-'
        C_PERIOD            enum Chars, '.'
        C_SLASH             enum Chars, '/'
        C_ZERO              enum Chars, '0'
        C_ONE               enum Chars, '1'
        C_TWO               enum Chars, '2'
        C_THREE             enum Chars, '3'
        C_FOUR              enum Chars, '4'
        C_FIVE              enum Chars, '5'
        C_SIX               enum Chars, '6'
        C_SEVEN             enum Chars, '7'
        C_EIGHT             enum Chars, '8'
        C_NINE              enum Chars, '9'
        C_COLON             enum Chars, ':'
        C_SEMICOLON         enum Chars, ';'
        C_LESS_THAN         enum Chars, '<'
        C_EQUAL             enum Chars, '='
        C_GREATER_THAN      enum Chars, '>'
        C_QUESTION_MARK     enum Chars, '?'
        C_AT_SIGN           enum Chars, '@'
        C_CAP_A             enum Chars, 'A'
        C_CAP_B             enum Chars, 'B'
        C_CAP_C             enum Chars, 'C'
        C_CAP_D             enum Chars, 'D'
        C_CAP_E             enum Chars, 'E'
        C_CAP_F             enum Chars, 'F'
        C_CAP_G             enum Chars, 'G'
        C_CAP_H             enum Chars, 'H'
        C_CAP_I             enum Chars, 'I'
        C_CAP_J             enum Chars, 'J'
        C_CAP_K             enum Chars, 'K'
        C_CAP_L             enum Chars, 'L'
        C_CAP_M             enum Chars, 'M'
        C_CAP_N             enum Chars, 'N'
        C_CAP_O             enum Chars, 'O'
        C_CAP_P             enum Chars, 'P'
        C_CAP_Q             enum Chars, 'Q'
        C_CAP_R             enum Chars, 'R'
        C_CAP_S             enum Chars, 'S'
        C_CAP_T             enum Chars, 'T'
        C_CAP_U             enum Chars, 'U'
        C_CAP_V             enum Chars, 'V'
        C_CAP_W             enum Chars, 'W'
        C_CAP_X             enum Chars, 'X'
        C_CAP_Y             enum Chars, 'Y'
        C_CAP_Z             enum Chars, 'Z'
        C_LEFT_BRACKET      enum Chars, '['
        C_BACKSLASH         enum Chars, 0x5c
        C_RIGHT_BRACKET     enum Chars, ']'
        C_ASCII_CIRCUMFLEX  enum Chars, '^'
        C_UNDERSCORE        enum Chars, '_'
        C_BACKQUOTE         enum Chars, '`'
        C_SMALL_A           enum Chars, 'a'
        C_SMALL_B           enum Chars, 'b'
        C_SMALL_C           enum Chars, 'c'
        C_SMALL_D           enum Chars, 'd'
        C_SMALL_E           enum Chars, 'e'
        C_SMALL_F           enum Chars, 'f'
        C_SMALL_G           enum Chars, 'g'
        C_SMALL_H           enum Chars, 'h'
        C_SMALL_I           enum Chars, 'i'
        C_SMALL_J           enum Chars, 'j'
        C_SMALL_K           enum Chars, 'k'
        C_SMALL_L           enum Chars, 'l'
        C_SMALL_M           enum Chars, 'm'
        C_SMALL_N           enum Chars, 'n'
        C_SMALL_O           enum Chars, 'o'
        C_SMALL_P           enum Chars, 'p'
        C_SMALL_Q           enum Chars, 'q'
        C_SMALL_R           enum Chars, 'r'
        C_SMALL_S           enum Chars, 's'
        C_SMALL_T           enum Chars, 't'
        C_SMALL_U           enum Chars, 'u'
        C_SMALL_V           enum Chars, 'v'
        C_SMALL_W           enum Chars, 'w'
        C_SMALL_X           enum Chars, 'x'
        C_SMALL_Y           enum Chars, 'y'
        C_SMALL_Z           enum Chars, 'z'
        C_LEFT_BRACE        enum Chars, '{'
        C_VERTICAL_BAR      enum Chars, '|'
        C_RIGHT_BRACE       enum Chars, '}'
        C_ASCII_TILDE       enum Chars, '~'
        C_DELETE            enum Chars, 0x7f
        ;
        ; some alternative names:
        ;
        C_HYPHEN            = C_MINUS
        C_GRAVE             = C_BACKQUOTE
        C_UA_DIERESIS       enum Chars, 0x80
        C_UA_RING           enum Chars, 0x81
        C_UC_CEDILLA        enum Chars, 0x82
        C_UE_ACUTE          enum Chars, 0x83
        C_UN_TILDE          enum Chars, 0x84
        C_UO_DIERESIS       enum Chars, 0x85
        C_UU_DIERESIS       enum Chars, 0x86
        C_LA_ACUTE          enum Chars, 0x87
        C_LA_GRAVE          enum Chars, 0x88
        C_LA_CIRCUMFLEX     enum Chars, 0x89
        C_LA_DIERESIS       enum Chars, 0x8a
        C_LA_TILDE          enum Chars, 0x8b
        C_LA_RING           enum Chars, 0x8c
        C_LC_CEDILLA        enum Chars, 0x8d
        C_LE_ACUTE          enum Chars, 0x8e
        C_LE_GRAVE          enum Chars, 0x8f
        C_LE_CIRCUMFLEX     enum Chars, 0x90
        C_LE_DIERESIS       enum Chars, 0x91
        C_LI_ACUTE          enum Chars, 0x92
        C_LI_GRAVE          enum Chars, 0x93
        C_LI_CIRCUMFLEX     enum Chars, 0x94
        C_LI_DIERESIS       enum Chars, 0x95
        C_LN_TILDE          enum Chars, 0x96
        C_LO_ACUTE          enum Chars, 0x97
        C_LO_GRAVE          enum Chars, 0x98
        C_LO_CIRCUMFLEX     enum Chars, 0x99
        C_LO_DIERESIS       enum Chars, 0x9a
        C_LO_TILDE          enum Chars, 0x9b
        C_LU_ACUTE          enum Chars, 0x9c
        C_LU_GRAVE          enum Chars, 0x9d
        C_LU_CIRCUMFLEX     enum Chars, 0x9e
        C_LU_DIERESIS       enum Chars, 0x9f
        C_DAGGER            enum Chars, 0xa0
        C_DEGREE            enum Chars, 0xa1
        C_CENT              enum Chars, 0xa2
        C_STERLING          enum Chars, 0xa3
        C_SECTION           enum Chars, 0xa4
        C_BULLET            enum Chars, 0xa5
        C_PARAGRAPH         enum Chars, 0xa6
        C_GERMANDBLS        enum Chars, 0xa7
        C_REGISTERED        enum Chars, 0xa8
        C_COPYRIGHT         enum Chars, 0xa9
        C_TRADEMARK         enum Chars, 0xaa
        C_ACUTE             enum Chars, 0xab
        C_DIERESIS          enum Chars, 0xac
        C_NOTEQUAL          enum Chars, 0xad
        C_U_AE              enum Chars, 0xae
        C_UO_SLASH          enum Chars, 0xaf
        C_INFINITY          enum Chars, 0xb0
        C_PLUSMINUS         enum Chars, 0xb1
        C_LESSEQUAL         enum Chars, 0xb2
        C_GREATEREQUAL      enum Chars, 0xb3
        C_YEN               enum Chars, 0xb4
        C_L_MU              enum Chars, 0xb5
        C_L_DELTA           enum Chars, 0xb6
        C_U_SIGMA           enum Chars, 0xb7
        C_U_PI              enum Chars, 0xb8
        C_L_PI              enum Chars, 0xb9
        C_INTEGRAL          enum Chars, 0xba
        C_ORDFEMININE       enum Chars, 0xbb
        C_ORDMASCULINE      enum Chars, 0xbc
        C_U_OMEGA           enum Chars, 0xbd
        C_L_AE              enum Chars, 0xbe
        C_LO_SLASH          enum Chars, 0xbf
        C_QUESTIONDOWN      enum Chars, 0xc0
        C_EXCLAMDOWN        enum Chars, 0xc1
        C_LOGICAL_NOT       enum Chars, 0xc2
        C_ROOT              enum Chars, 0xc3
        C_FLORIN            enum Chars, 0xc4
        C_APPROX_EQUAL      enum Chars, 0xc5
        C_U_DELTA           enum Chars, 0xc6
        C_GUILLEDBLLEFT     enum Chars, 0xc7
        C_GUILLEDBLRIGHT    enum Chars, 0xc8
        C_ELLIPSIS          enum Chars, 0xc9
        C_NONBRKSPACE       enum Chars, 0xca
        C_UA_GRAVE          enum Chars, 0xcb
        C_UA_TILDE          enum Chars, 0xcc
        C_UO_TILDE          enum Chars, 0xcd
        C_U_OE              enum Chars, 0xce
        C_L_OE              enum Chars, 0xcf
        C_ENDASH            enum Chars, 0xd0
        C_EMDASH            enum Chars, 0xd1
        C_QUOTEDBLLEFT      enum Chars, 0xd2
        C_QUOTEDBLRIGHT     enum Chars, 0xd3
        C_QUOTESNGLEFT      enum Chars, 0xd4
        C_QUOTESNGRIGHT     enum Chars, 0xd5
        C_DIVISION          enum Chars, 0xd6
        C_DIAMONDBULLET     enum Chars, 0xd7
        C_LY_DIERESIS       enum Chars, 0xd8
        C_UY_DIERESIS       enum Chars, 0xd9
        C_FRACTION          enum Chars, 0xda
        C_CURRENCY          enum Chars, 0xdb
        C_GUILSNGLEFT       enum Chars, 0xdc
        C_GUILSNGRIGHT      enum Chars, 0xdd
        C_LY_ACUTE          enum Chars, 0xde
        C_UY_ACUTE          enum Chars, 0xdf
        C_DBLDAGGER         enum Chars, 0xe0
        C_CNTR_DOT          enum Chars, 0xe1
        C_SNGQUOTELOW       enum Chars, 0xe2
        C_DBLQUOTELOW       enum Chars, 0xe3
        C_PERTHOUSAND       enum Chars, 0xe4
        C_UA_CIRCUMFLEX     enum Chars, 0xe5
        C_UE_CIRCUMFLEX     enum Chars, 0xe6
        C_UA_ACUTE          enum Chars, 0xe7
        C_UE_DIERESIS       enum Chars, 0xe8
        C_UE_GRAVE          enum Chars, 0xe9
        C_UI_ACUTE          enum Chars, 0xea
        C_UI_CIRCUMFLEX     enum Chars, 0xeb
        C_UI_DIERESIS       enum Chars, 0xec
        C_UI_GRAVE          enum Chars, 0xed
        C_UO_ACUTE          enum Chars, 0xee
        C_UO_CIRCUMFLEX     enum Chars, 0xef
        C_LOGO              enum Chars, 0xf0
        C_UO_GRAVE          enum Chars, 0xf1
        C_UU_ACUTE          enum Chars, 0xf2
        C_UU_CIRCUMFLEX     enum Chars, 0xf3
        C_UU_GRAVE          enum Chars, 0xf4
        C_LI_DOTLESS        enum Chars, 0xf5
        C_CIRCUMFLEX        enum Chars, 0xf6
        C_TILDE             enum Chars, 0xf7
        C_MACRON            enum Chars, 0xf8
        C_BREVE             enum Chars, 0xf9
        C_DOTACCENT         enum Chars, 0xfa
        C_RING              enum Chars, 0xfb
        C_CEDILLA           enum Chars, 0xfc
        C_HUNGARUMLAT       enum Chars, 0xfd
        C_OGONEK            enum Chars, 0xfe
        C_CARON             enum Chars, 0xff
        ;
        ; some alternative names:
        ;
        C_PARTIAL_DIFF      = C_L_DELTA
        C_SUM               = C_U_SIGMA
        C_PRODUCT           = C_U_PI
        C_RADICAL           = C_ROOT
        C_LOZENGE           = C_DIAMONDBULLET

**Library:** char.def

----------
#### CharTableData
    CharTableData           struct
        CTD_line1       optr
        CTD_line2       optr
        CTD_line3       optr
        CTD_line4       optr
        CTD_line5       optr
    CharTableData           ends

This structure is used during notification of the pen object.

**Library:** Objects/gPenICC.def

----------
#### ChunkArrayHeader
    ChunkArrayHeader            struct
        CAH_count           word
        CAH_elementSize     word
        CAH_curOffset       word
        CAH_offset          word
    ChunkArrayHeader            ends

Every chunk array begins with a **ChunkArrayHeader**. This structure 
contains the basic information about the associated chunk array. 
Applications should never change the contents of the **ChunkArrayHeader**; 
only the chunk array routines should do this. However, applications can 
examine the header if they wish.

*CAH_count* stores the number of elements in the chunk array.

*CAH_elementSize* stores the size of each element in the chunk array if the 
elements are each of the same size. If the elements are variable-sized, this 
entry will be zero.

*CAH_curOffset* stores bookkeeping information pointing to the current 
element in use during an enumeration.

*CAH_offset* stores the offset from the start of the chunk to the first element in 
the array.

**Library:** chunkarr.def

----------
#### ChunkMapList
    ChunkMapList        struc
        CML_source          word
        CML_dest            word
    ChunkMapList        ends

**Library:** impex.def

----------
#### ClassFlags
    ClassFlags      record
        CLASSF_HAS_DEFAULT      :1  ; Set if dword before the class record
                                    ; contains an fptr of a default method
                                    ; handler to deal with any unrecognized
                                    ; method send to an object of the class.
        CLASSF_MASTER_CLASS     :1  ; Set if class is a master class
        CLASSF_VARIANT_CLASS    :1  ; Set if superclass varies
        CLASSF_DISCARD_ON_SAVE  :1  ; Set if class data can be discarded
                                    ; when object is saved
        CLASSF_NEVER_SAVED      :1  ; Set if objects of this class
                                    ; are never saved. This is a signal
                                    ; to Esp that it needn't build up
                                    ; a relocation table for the class
        CLASSF_HAS_RELOC        :1  ; Set if dword after method table is
                                    ; routine to call to relocate or
                                    ; unrelocate an object. Routine is
                                    ; passed MSG_META_RELOCATE or
                                    ; MSG_META_UNRELOCATE in AX.
        CLASSF_C_HANDLERS       :1  ; Handlers are written in C and must
                                    ; be called with the C convention
                                :1
    ClassFlags      end

This record is stored in the **ClassStruct** structure's *Class_flags* field. These 
flags are internal and may not be set or retrieved directly.

**Library:** object.def

----------
#### ClassStruct
    ClassStruct         struct
        Class_superClass            fptr.ClassStruct
        Class_masterOffset          word
        Class_methodCount           word
        Class_instanceSize          word
        Class_vdRelocTable          nptr.VarObjRelocation
        Class_relocTable            nptr.ObjRelocation
        Class_flags                 ClassFlags
        Class_masterMethods         byte
        Class_methodTable           label word
    ClassStruct         ends

This structure contains the arguments which define a class. It is internal and 
used only very rarely by anything other than the kernel and the UI.

*Class_superClass* stores the **ClassStruct** of this class's superclass.

*Class_masterOffset* stores the offset to the master class data.

*Class_methodCount* stores the number of methods defined for this class. This 
is used to determine the size of the method table, which follows this 
**ClassStruct**.

*Class_instanceSize* stores the size of the entire master group's instance data.

*Class_vdRelocTable* stores the offset to the class' relocatable vardata table.

*Class_relocTable* stores the offset to the class' relocatable instance data table.

*Class_flags* stores the **ClassFlags** in use by the class.

*Class_masterMessages* stores internal flags that Esp uses to indicate the 
presence of method handlers for a given master level.

**Class_methodTable** marks the start of the class' method table.

**Library:** object.def

----------
#### ClipboardItemFlags
    ClipboardItemFlags          record
        CIF_UNUSED          :1
        CIF_QUICK           :1
        CIF_UNUSED2         :14
    ClipboardItemFlags          end

**Library:** Objects/clipbrd.def

----------
#### ClipboardItemFormat
    ClipboardItemFormat     etype       word
        CIF_TEXT                enum        ClipboardItemFormat
        CIF_GRAPHICS_STRING     enum        ClipboardItemFormat
        CIF_FILES               enum        ClipboardItemFormat
        CIF_SPREADSHEET         enum        ClipboardItemFormat
        CIF_INK                 enum        ClipboardItemFormat
        CIF_GROBJ               enum        ClipboardItemFormat
        CIF_GEODEX              enum        ClipboardItemFormat
        CIF_BITMAP              enum        ClipboardItemFormat
        CIF_SOUND_SYNTH         enum        ClipboardItemFormat
        CIF_SOUND_SAMPLE        enum        ClipboardItemFormat

CIF_TEXT  
The contents of the clipboard are null terminated text (with possible 
formatting information).

CIF_GRAPHICS_STRING  
The contents of the clipboard is a standard GEOS graphics string.

CIF_FILES  
The contents of the clipboard are in an internal desktop format for 
direct-manipulation file operations.

**Library:** geoworks.def

----------
#### ClipboardItemFormatID
    ClipboardItemFormatID           struct
        CIFID_manufacturer              ManufacturerID
        CIFID_type                      ClipboardItemFormat
    ClipboardItemFormatID           ends

Format IDs are identified by two words. One is a manufacturer ID and the 
other is a manufacturer-specific value that specifies the actual format.

**Library:** Objects/clipbrd.def

----------
#### ClipboardItemFormatInfo
    ClipboardItemFormatInfo         struct
        ;
        ; two words of format identification
        ;
        CIFI_format         ClipboardItemFormatID
        ;
        ; two words of format-specific extra data
        ;   (not used for CIF_TEXT, gstring size for CIF_GRAPHICS_STRING,
        ;    not used for CIF_FILES)
        ;
        CIFI_extra1         word
        CIFI_extra2         word
        ;
        ; VM block handle of first block in linked chain of data blocks
        ;
        CIFI_vmChain        dword
        ;
        ; token of application that knows how to render this format
        ; (not currently used)
        ;
        CIFI_renderer       GeodeToken <>
    ClipboardItemFormatInfo         ends

A clipboard item header contains all of the data for the item in all formats 
supported by the owner. Each format is identified by a structure that stores 
the format type, two words of format-specific extra data, and the VM block 
handle of the first VM block in a chain of VM data blocks for the format.

**Library:** Objects/clipbrd.def

----------
#### ClipboardItemHeader
    ClipboardItemHeader         struct
        CIH_owner           optr
        CIH_flags           ClipboardItemFlags
        CIH_name            ClipboardItemNameBuffer
        CIH_formatCount     word
        CIH_sourceID        optr
        CIH_formats         ClipboardItemFormatInfo CLIPBOARD_MAX_FORMATS dup (<>)
        CIH_reserved        dword
    ClipboardItemHeader         ends

This structure is passed to **ClipboardRegisterItem**, 
**ClipboardRequestItemFormat**, **ClipboardDoneWithItem** and 
returned from **ClipboardQueryItem**.

*CIH_owner* stores the owner of the transfer item - this is cleared when a 
clipboard item is saved to disk when shutting down. Note that only normal 
transfer items persist across shutdown.

*CIH_flags* stores the quick/normal (quick item is only temporary).

*CIH_name* stores the name of this clipboard item.

*CIH_formatCount* stores the number of data formats available.

*CIH_sourceID* stores the optr of additional info about transfer item source 
(used to determine default move/copy behavior during quick transfer). 
"source document ID" -- most things will want to put the optr of the parent 
GenDocument object here.

*CIH_formats* stores the data formats available ordered from most informative 
(includes VM block handles containing data for the format) (all formats for a 
given transfer item must be in the same VM file).

*CIH_reserved* is reserved for future expansion (must be 0 for now).

**Library:** Objects/clipbrd.def

----------
#### ClipboardQuickNotifyFlags
    ClipboardQuickNotifyFlags           record
        CQNF_ERROR              :1
        CQNR_SOURCE_EQUAL_DEST  :1
        CQNR_MOVE               :1
        CQNR_COPY               :1
        CQNR_NO_OPERATION       :1
        CQNR_UNUSED             :11
    ClipboardQuickNotifyFlags           end

These flags return information about the success or failure of a quick transfer 
operation.

**Library:** Objects/clipbrd.def

----------
#### ClipboardQuickTransferFeedback
    ClipboardQuickTransferFeedback              etype word
        CQTF_SET_DEFAULT        enum        ClipboardQuickTransferFeedback
        CQTF_CLEAR_DEFAULT      enum        ClipboardQuickTransferFeedback
        CQTF_MOVE               enum        ClipboardQuickTransferFeedback
        CQTF_COPY               enum        ClipboardQuickTransferFeedback
        CQTF_CLEAR              enum        ClipboardQuickTransferFeedback

CQTF_SET_DEFAULT  
Sets the default modal cursor used during a clipboard quick-transfer 
operation. (This is used internally.)

CQTF_CLEAR_DEFAULT  
Clears the default modal cursor during a clipboard quick-transfer operation. 
(This is used internally.)

CQTF_MOVE  
Sets the move cursor during a clipboard quick-transfer operation.

CQTF_COPY  
Sets the copy cursor during a clipboard quick-transfer operation.

CQTF_CLEAR  
Clears any move/copy cursors present.

**Library:** Objects/clipbrd.def

----------
#### ClipboardQuickTransferFlags
    ClipboardQuickTransferFlags             record
        CQTF_IN_PROGRESS        :1      ; internal
        CQTF_COPY_ONLY          :1      ; if the source only supports copying
        CQTF_USE_REGION         :1      ; use region
        CQTF_NOTIFICATION       :1      ; set if the quick-transfer source wants 
                                        ; to be notified when the transfer item
                                        ; has been processed.
                                :12
    ClipboardQuickTransferFlags             end

**Library:** Objects/clipbrd.def

----------
#### ClipboardQuickTransferRegionInfo
    ClipboardQuickTransferRegionInfo            struct
        CQTRI_paramAX               word
        CQTRI_paramBX               word
        CQTRI_paramCX               word
        CQTRI_paramDX               word
        CQTRI_regionPos             Point
        CQTRI_strategy              dword
        CQTRI_region                dword
    ClipboardQuickTransferRegionInfo            ends

This structure stores the stack parameters used in 
**ClipboardStartQuickTransfer** if the **ClipboardQuickTransferFlags** in 
use include CQTF_USE_REGION.

**Library:** Objects/clipbrd.def

----------
#### Color
    Color       etype   byte
        C_BLACK         enum Color      ; black color index
        C_BLUE          enum Color      ; dark blue color index
        C_GREEN         enum Color      ; dark green color index
        C_CYAN          enum Color      ; dark cyan color index
        C_RED           enum Color      ; dark red color index
        C_VIOLET        enum Color      ; dark violet color index
        C_BROWN         enum Color      ; brown color index
        C_LIGHT_GRAY    enum Color      ; light gray color index
        C_DARK_GRAY     enum Color      ; dark gray color index
        C_LIGHT_BLUE    enum Color      ; light blue color index
        C_LIGHT_GREEN   enum Color      ; light green color index
        C_LIGHT_CYAN    enum Color      ; light cyan color index
        C_LIGHT_RED     enum Color      ; light red color index
        C_LIGHT_VIOLET  enum Color      ; light violet color index
        C_YELLOW        enum Color      ; yellow color index
        C_WHITE         enum Color      ; white color index

        C_LIGHT_GREY =  C_LIGHT_GRAY    ; alternate spelling
        C_DARK_GREY  =  C_DARK_GRAY     ; alternate spelling

        MAX_CF_INDEX    = C_WHITE

        C_BW_GREY       = 0x84          ; "color" to pass to black
                                        ; and white driver to get
                                        ; 50% pattern (in dither mode)

        ;   Additional color enums for use as color indices

        C_GRAY_0        enum Color, 0x10    ; start of grey ramp, 0.0%
        C_GRAY_7        enum Color, 0x11    ; start of grey ramp, 6.3%
        C_GRAY_13       enum Color, 0x12    ; start of grey ramp, 13.3%
        C_GRAY_20       enum Color, 0x13    ; start of grey ramp, 20.0%
        C_GRAY_27       enum Color, 0x14    ; start of grey ramp, 26.7%
        C_GRAY_33       enum Color, 0x15    ; start of grey ramp, 33.3%
        C_GRAY_40       enum Color, 0x16    ; start of grey ramp, 40.0%
        C_GRAY_47       enum Color, 0x17    ; start of grey ramp, 46.7%
        C_GRAY_53       enum Color, 0x18    ; start of grey ramp, 53.3%
        C_GRAY_60       enum Color, 0x19    ; start of grey ramp, 60.0%
        C_GRAY_68       enum Color, 0x1a    ; start of grey ramp, 67.7%
        C_GRAY_73       enum Color, 0x1b    ; start of grey ramp, 73.3%
        C_GRAY_80       enum Color, 0x1c    ; start of grey ramp, 80.0%
        C_GRAY_88       enum Color, 0x1d    ; start of grey ramp, 87.7%
        C_GRAY_93       enum Color, 0x1e    ; start of grey ramp, 93.3%
        C_GRAY_100      enum Color, 0x1f    ; start of grey ramp,100.0%

        C_UNUSED_0      enum Color, 0x20    ; 8 unused spots
        C_UNUSED_1      enum Color, 0x21
        C_UNUSED_2      enum Color, 0x22
        C_UNUSED_3      enum Color, 0x23
        C_UNUSED_4      enum Color, 0x24
        C_UNUSED_5      enum Color, 0x25
        C_UNUSED_6      enum Color, 0x26
        C_UNUSED_7      enum Color, 0x27
        C_R0_G0_B0      enum Color, 0x28    ; start of 6x6x6 RGB cube
        C_R0_G0_B1      enum Color, 0x29
        C_R0_G0_B2      enum Color, 0x2a
        C_R0_G0_B3      enum Color, 0x2b
        C_R0_G0_B4      enum Color, 0x2c
        C_R0_G0_B5      enum Color, 0x2d
        C_R0_G1_B0      enum Color, 0x2e
        C_R0_G1_B1      enum Color, 0x2f
        C_R0_G1_B2      enum Color, 0x30
        C_R0_G1_B3      enum Color, 0x31
        C_R0_G1_B4      enum Color, 0x32
        C_R0_G1_B5      enum Color, 0x33
        C_R0_G2_B0      enum Color, 0x34
        C_R0_G2_B1      enum Color, 0x35
        C_R0_G2_B2      enum Color, 0x36
        C_R0_G2_B3      enum Color, 0x37
        C_R0_G2_B4      enum Color, 0x38
        C_R0_G2_B5      enum Color, 0x39
        C_R0_G3_B0      enum Color, 0x3a
        C_R0_G3_B1      enum Color, 0x3b
        C_R0_G3_B2      enum Color, 0x3c
        C_R0_G3_B3      enum Color, 0x3d
        C_R0_G3_B4      enum Color, 0x3e
        C_R0_G3_B5      enum Color, 0x3f
        C_R0_G4_B0      enum Color, 0x40
        C_R0_G4_B1      enum Color, 0x41
        C_R0_G4_B2      enum Color, 0x42
        C_R0_G4_B3      enum Color, 0x43
        C_R0_G4_B4      enum Color, 0x44
        C_R0_G4_B5      enum Color, 0x45
        C_R0_G5_B0      enum Color, 0x46
        C_R0_G5_B1      enum Color, 0x47
        C_R0_G5_B2      enum Color, 0x48
        C_R0_G5_B3      enum Color, 0x49
        C_R0_G5_B4      enum Color, 0x4a
        C_R0_G5_B5      enum Color, 0x4b
        C_R1_G0_B0      enum Color, 0x4c
        C_R1_G0_B1      enum Color, 0x4d
        C_R1_G0_B2      enum Color, 0x4e
        C_R1_G0_B3      enum Color, 0x4f
        C_R1_G0_B4      enum Color, 0x50
        C_R1_G0_B5      enum Color, 0x51
        C_R1_G1_B0      enum Color, 0x52
        C_R1_G1_B1      enum Color, 0x53
        C_R1_G1_B2      enum Color, 0x54
        C_R1_G1_B3      enum Color, 0x55
        C_R1_G1_B4      enum Color, 0x56
        C_R1_G1_B5      enum Color, 0x57
        C_R1_G2_B0      enum Color, 0x58
        C_R1_G2_B1      enum Color, 0x59
        C_R1_G2_B2      enum Color, 0x5a
        C_R1_G2_B3      enum Color, 0x5b
        C_R1_G2_B4      enum Color, 0x5c
        C_R1_G2_B5      enum Color, 0x5d
        C_R1_G3_B0      enum Color, 0x5e
        C_R1_G3_B1      enum Color, 0x5f
        C_R1_G3_B2      enum Color, 0x60
        C_R1_G3_B3      enum Color, 0x61
        C_R1_G3_B4      enum Color, 0x62
        C_R1_G3_B5      enum Color, 0x63
        C_R1_G4_B0      enum Color, 0x64
        C_R1_G4_B1      enum Color, 0x65
        C_R1_G4_B2      enum Color, 0x66
        C_R1_G4_B3      enum Color, 0x67
        C_R1_G4_B4      enum Color, 0x68
        C_R1_G4_B5      enum Color, 0x69
        C_R1_G5_B0      enum Color, 0x6a
        C_R1_G5_B1      enum Color, 0x6b
        C_R1_G5_B2      enum Color, 0x6c
        C_R1_G5_B3      enum Color, 0x6d
        C_R1_G5_B4      enum Color, 0x6e
        C_R1_G5_B5      enum Color, 0x6f
        C_R2_G0_B0      enum Color, 0x70
        C_R2_G0_B1      enum Color, 0x71
        C_R2_G0_B2      enum Color, 0x72
        C_R2_G0_B3      enum Color, 0x73
        C_R2_G0_B4      enum Color, 0x74
        C_R2_G0_B5      enum Color, 0x75
        C_R2_G1_B0      enum Color, 0x76
        C_R2_G1_B1      enum Color, 0x77
        C_R2_G1_B2      enum Color, 0x78
        C_R2_G1_B3      enum Color, 0x79
        C_R2_G1_B4      enum Color, 0x7a
        C_R2_G1_B5      enum Color, 0x7b
        C_R2_G2_B0      enum Color, 0x7c
        C_R2_G2_B1      enum Color, 0x7d
        C_R2_G2_B2      enum Color, 0x7e
        C_R2_G2_B3      enum Color, 0x7f
        C_R2_G2_B4      enum Color, 0x80
        C_R2_G2_B5      enum Color, 0x81
        C_R2_G3_B0      enum Color, 0x82
        C_R2_G3_B1      enum Color, 0x83
        C_R2_G3_B2      enum Color, 0x84
        C_R2_G3_B3      enum Color, 0x85
        C_R2_G3_B4      enum Color, 0x86
        C_R2_G3_B5      enum Color, 0x87
        C_R2_G4_B0      enum Color, 0x88
        C_R2_G4_B1      enum Color, 0x89
        C_R2_G4_B2      enum Color, 0x8a
        C_R2_G4_B3      enum Color, 0x8b
        C_R2_G4_B4      enum Color, 0x8c
        C_R2_G4_B5      enum Color, 0x8d
        C_R2_G5_B0      enum Color, 0x8e
        C_R2_G5_B1      enum Color, 0x8f
        C_R2_G5_B2      enum Color, 0x90
        C_R2_G5_B3      enum Color, 0x91
        C_R2_G5_B4      enum Color, 0x92
        C_R2_G5_B5      enum Color, 0x93
        C_R3_G0_B0      enum Color, 0x94
        C_R3_G0_B1      enum Color, 0x95
        C_R3_G0_B2      enum Color, 0x96
        C_R3_G0_B3      enum Color, 0x97
        C_R3_G0_B4      enum Color, 0x98
        C_R3_G0_B5      enum Color, 0x99
        C_R3_G1_B0      enum Color, 0x9a
        C_R3_G1_B1      enum Color, 0x9b
        C_R3_G1_B2      enum Color, 0x9c
        C_R3_G1_B3      enum Color, 0x9d
        C_R3_G1_B4      enum Color, 0x9e
        C_R3_G1_B5      enum Color, 0x9f
        C_R3_G2_B0      enum Color, 0xa0
        C_R3_G2_B1      enum Color, 0xa1
        C_R3_G2_B2      enum Color, 0xa2
        C_R3_G2_B3      enum Color, 0xa3
        C_R3_G2_B4      enum Color, 0xa4
        C_R3_G2_B5      enum Color, 0xa5
        C_R3_G3_B0      enum Color, 0xa6
        C_R3_G3_B1      enum Color, 0xa7
        C_R3_G3_B2      enum Color, 0xa8
        C_R3_G3_B3      enum Color, 0xa9
        C_R3_G3_B4      enum Color, 0xaa
        C_R3_G3_B5      enum Color, 0xab
        C_R3_G4_B0      enum Color, 0xac
        C_R3_G4_B1      enum Color, 0xad
        C_R3_G4_B2      enum Color, 0xae
        C_R3_G4_B3      enum Color, 0xaf
        C_R3_G4_B4      enum Color, 0xb0
        C_R3_G4_B5      enum Color, 0xb1
        C_R3_G5_B0      enum Color, 0xb2
        C_R3_G5_B1      enum Color, 0xb3
        C_R3_G5_B2      enum Color, 0xb4
        C_R3_G5_B3      enum Color, 0xb5
        C_R3_G5_B4      enum Color, 0xb6
        C_R3_G5_B5      enum Color, 0xb7
        C_R4_G0_B0      enum Color, 0xb8
        C_R4_G0_B1      enum Color, 0xb9
        C_R4_G0_B2      enum Color, 0xba
        C_R4_G0_B3      enum Color, 0xbb
        C_R4_G0_B4      enum Color, 0xbc
        C_R4_G0_B5      enum Color, 0xbd
        C_R4_G1_B0      enum Color, 0xbe
        C_R4_G1_B1      enum Color, 0xbf
        C_R4_G1_B2      enum Color, 0xc0
        C_R4_G1_B3      enum Color, 0xc1
        C_R4_G1_B4      enum Color, 0xc2
        C_R4_G1_B5      enum Color, 0xc3
        C_R4_G2_B0      enum Color, 0xc4
        C_R4_G2_B1      enum Color, 0xc5
        C_R4_G2_B2      enum Color, 0xc6
        C_R4_G2_B3      enum Color, 0xc7
        C_R4_G2_B4      enum Color, 0xc8
        C_R4_G2_B5      enum Color, 0xc9
        C_R4_G3_B0      enum Color, 0xca
        C_R4_G3_B1      enum Color, 0xcb
        C_R4_G3_B2      enum Color, 0xcc
        C_R4_G3_B3      enum Color, 0xcd
        C_R4_G3_B4      enum Color, 0xce
        C_R4_G3_B5      enum Color, 0xcf
        C_R4_G4_B0      enum Color, 0xd0
        C_R4_G4_B1      enum Color, 0xd1
        C_R4_G4_B2      enum Color, 0xd2
        C_R4_G4_B3      enum Color, 0xd3
        C_R4_G4_B4      enum Color, 0xd4
        C_R4_G4_B5      enum Color, 0xd5
        C_R4_G5_B0      enum Color, 0xd6
        C_R4_G5_B1      enum Color, 0xd7
        C_R4_G5_B2      enum Color, 0xd8
        C_R4_G5_B3      enum Color, 0xd9
        C_R4_G5_B4      enum Color, 0xda
        C_R4_G5_B5      enum Color, 0xdb
        C_R5_G0_B0      enum Color, 0xdc
        C_R5_G0_B1      enum Color, 0xdd
        C_R5_G0_B2      enum Color, 0xde
        C_R5_G0_B3      enum Color, 0xdf
        C_R5_G0_B4      enum Color, 0xe0
        C_R5_G0_B5      enum Color, 0xe1
        C_R5_G1_B0      enum Color, 0xe2
        C_R5_G1_B1      enum Color, 0xe3
        C_R5_G1_B2      enum Color, 0xe4
        C_R5_G1_B3      enum Color, 0xe5
        C_R5_G1_B4      enum Color, 0xe6
        C_R5_G1_B5      enum Color, 0xe7
        C_R5_G2_B0      enum Color, 0xe8
        C_R5_G2_B1      enum Color, 0xe9
        C_R5_G2_B2      enum Color, 0xea
        C_R5_G2_B3      enum Color, 0xeb
        C_R5_G2_B4      enum Color, 0xec
        C_R5_G2_B5      enum Color, 0xed
        C_R5_G3_B0      enum Color, 0xee
        C_R5_G3_B1      enum Color, 0xef
        C_R5_G3_B2      enum Color, 0xf0
        C_R5_G3_B3      enum Color, 0xf1
        C_R5_G3_B4      enum Color, 0xf2
        C_R5_G3_B5      enum Color, 0xf3
        C_R5_G4_B0      enum Color, 0xf4
        C_R5_G4_B1      enum Color, 0xf5
        C_R5_G4_B2      enum Color, 0xf6
        C_R5_G4_B3      enum Color, 0xf7
        C_R5_G4_B4      enum Color, 0xf8
        C_R5_G4_B5      enum Color, 0xf9
        C_R5_G5_B0      enum Color, 0xfa
        C_R5_G5_B1      enum Color, 0xfb
        C_R5_G5_B2      enum Color, 0xfc
        C_R5_G5_B3      enum Color, 0xfd
        C_R5_G5_B4      enum Color, 0xfe

**Library:** color.def

----------
#### ColoredObjectOrientation
    ColoredObjectOrientation        etype       byte
        COO_AREA_ORIENTED               enum        ColoredObjectOrientation
        COO_TEXT_ORIENTED               enum        ColoredObjectOrientation
        COO_LINE_ORIENTED               enum        ColoredObjectOrientation

**Library:** Objects/colorC.def

----------
#### ColorFlag
    ColorFlag           etype       byte
        CF_INDEX    enum    ColorFlag           ; set color with index
        CF_GRAY     enum    ColorFlag           ; set color with gray value
        CF_SAME     enum    ColorFlag           ; don't change the color (hatch)
        CF_CMY      enum    ColorFlag           ; set color with CMY value
        CF_RGB      enum    ColorFlag, 0x80     ; set color with RGB values

Several color-related commands accept colors in a variety of formats. The 
**ColorFlag** type is used to specify how the color is being described. The 
**ColorFlag** is normally used as part of a **ColorQuad**. See **ColorQuad** for 
information about how to interpret color specifications using **ColorFlags**.

**Library:** color.def

----------
#### ColorMapMode
    ColorMapMode            record
        CMM_ON_BLACK    :1                  ; 1 if drawing on black
                        :1
        CMM_MAP_TYPE    ColorMapType:1      ; color mapping mode.
    ColorMapMode            end

**Library:** graphics.def

----------
#### ColorMapType
    ColorMapType            etype       byte
        CMT_CLOSEST     enum    ColorMapType    ; Map to closest solid color
        CMT_DITHER      enum    ColorMapType    ; Map to dither pattern

**Library:** graphics.def

----------
#### ColorModifiedStates
    ColorModifiedStates         record
        CMS_COLOR_CHANGED           :1
        CMS_DRAW_MASK_CHANGED       :1
        CMS_PATTERN_CHANGED         :1
    ColorModifiedStates         end

**Library:** colorC.def

----------
#### ColorQuad
    ColorQuad       struct
        CQ_redOrIndex   byte
        CQ_info         ColorFlag
        CQ_green        byte
        CQ_blue         byte
    ColorQuad       ends

This structure represents a color.

*CQ_info* determines how the color is being described. 

If *CQ_info* includes the CF_INDEX flag, the color is specified by an index value 
which matches a specific color in the palette. This index is stored in the 
*CQ_redOrIndex* field; *CQ_green* and *CQ_blue* are ignored if the color is an 
index value.

If *CQ_info* includes the CF_RGB flag, the color is specified by separate RGB 
components. *CQ_redOrIndex* stores the red value and *CQ_green* and *CQ_blue* 
store the green and blue components, respectively.

If *CQ_info* contains the CF_GRAY flag, the color is being expressed as a grey 
scale. This is basically an optimized way of describing RGB colors where the 
red, green, and blue components are equal. The *CQ_redOrIndex* field contains 
the brightness, a number between 0 and 255. The *CQ_green* and *CQ_blue* 
fields are ignored.

When defining hatch patterns, it is possible to have a CF_SAME info field. 
This means that the hatch lines should used the "same" color when drawing. 
That is, when hatching text, the text color will be used; when filling an area, 
the area color will be used. The *CQ_redOrIndex*, *CQ_green*, and *CQ_blue* fields 
are all ignored.

**Library:** color.def

----------
#### ColorScheme
    ColorScheme     record
        CS_lightColor       Color:4
        CS_darkColor        Color:4
    ColorScheme     end

**Library:** Objects/visC.def

----------
#### ColorToolboxPreferences
    ColorToolboxPreferences             record
                                    :2
        CTP_INDEX_ORIENTATION       :2      ;ColoredObjectOrientation
        CTP_DRAW_MASK_ORIENTATION   :2
        CTP_PATTERN_ORIENTATION     :1
        CTP_IS_POPUP                :1
    ColorToolboxPreferences             end

**Library:** colorC.def

----------
#### ColorTransfer
    ColorTransfer       struct
        CT_data     RGBDelta 5*5*5 dup (?)      ; 375 bytes of data.
    ColorTransfer       ends

A color correction table is a 5x5x5 cube of RGB difference values. The 
correction is done by doing a lookup in the 3D table and applying the 
**RGBDelta** values to the original input values.

**Library:** color.def

----------
#### ColumnArrayElement
    ColumnArrayElement          struct
        CAE_column      byte        ; The column number in which the cell resides.
        CAE_data        DBaseItem   ; The item containing the cell data.
    ColumnArrayElement          ends

**Library:** cell.def

----------
#### ColumnArrayHeader
    ColumnArrayHeader       struct
        CAH_numEntries          word    ; Number of entries in the array.
        CAH_rowFlags            word    ; Flags that exist for each row.
    ColumnArrayHeader       ends

**Library:** cell.def

----------
#### CommonParameters
    CommonParameters            struct
        CP_row              word    ; Current row
        CP_column           word    ; Current column
        CP_maxRow           word    ; Largest legal row value
        CP_maxColumn        word    ; Largest legal column value
        CP_callback         dword   ; One general purpose callback
        CP_cellParams       dword   ; Pointer to the cell parameters
    CommonParameters            ends

This structure stores basic information that is useful to many of the parse 
callback routines. It should always be placed at the base of the parameter 
structures.

**Library:** parse.def

----------
#### CommonTransferParams
    CommonTransferParams            struct
        CTP_range           VisTextRange
        CTP_pasteFrame      word            ;ptr to frame if quick paste.
                                            ;0 otherwise.
        CTP_vmFile          word            ;VM file handle
        CTP_vmBlock         word            ;VM block handle
    CommonTransferParams            ends

This structure stores parameters sent on the stack to all transfer routines.

**Library:** Objects/vTextC.def

----------
#### CompChildFlags
    CompChildFlags      record
        CCF_MARK_DIRTY  :1,     ; Marks chunk and modified objects as
                                ; dirty
        CCF_REFERENCE   :15     ; Object # we should add new object 
                                ; before (if > # objects, then add new
                                ; object last)
        CCO_FIRST       equ     0x0000
        CCO_LAST        equ     0x7FFF  ;NOTE - will not work if the object 
                                        ;already has 32767 children.
    CompChildFlags      end

This record is used when adding, moving, or removing children in an object 
tree. 

CCF_MARK_DIRTY indicates whether the object should be marked dirty at 
the end of the operation.

CCF_REFERENCE stores a child number; when adding or moving a child, this 
is the child number after which the new object should be inserted. It can be 
any number less than 32768 or either of the two constants CCO_FIRST and 
CCO_LAST specifying the absolute first or last position.

**Library:** Objects/metaC.def

----------
#### CompPart
    CompPart        struct
        CP_firstChild       optr        ; 0 = no children.
    CompPart        ends

**Library:** Objects/metaC.def

----------
#### CompSizeHintArgs
    CompSizeHintArgs            struct
        CSHA_width      SpecWidth <>    ; Width of the composite.
        CSHA_height     SpecHeight <>   ; Height of each child.
        CSHA_count      sword           ; Number of children of a composite.
    CompSizeHintArgs            ends

This structure is used for HINT_FIXED_SIZE, HINT_MINIMUM_SIZE, 
HINT_MAXIMUM_SIZE and HINT_INITIAL_SIZE.

**Library:** Objects/genC.def

----------
#### ContextData
    ContextData     struct
        CD_object           optr
        CD_numChars         dword
        CD_range            VisTextRange
        CD_selection        VisTextRange
        CD_contextData      label char
    ContextData     ends

*CD_object* stores the optr of the object the context is coming from.

*CD_numChars* stores the number of chars in the text object.

*CD_range* stores the range of characters that this context represents.

*CD_selection* stores the current text selection.

*CD_contextData* stores the null-terminated data.

**Library:** Objects/vTextC.def

----------
#### ContextLocation
    ContextLocation     etype       word
        CL_STARTING_AT_POSITION             enum        ContextLocation
        CL_ENDING_AT_POSITION               enum        ContextLocation
        CL_CENTERED_AROUND_POSITION         enum        ContextLocation
        CL_CENTERED_AROUND_SELECTION        enum        ContextLocation
        CL_CENTERED_AROUND_SELECTION_START  enum        ContextLocation
        CL_SELECTED_WORD                    enum        ContextLocation

This type is used to identify a context location within a **GetContextParams** 
structure.

CL_STARTING_AT_POSITION  
Retrieves *GCP_numCharsToGet* characters starting at *GCP_position*. 
CL_ENDING_AT_POSITION  
Retrieves text ending at the passed selection.

CL_CENTERED_AROUND_POSITION  
Retrieves *GCP_numCharsToGet* characters centered around *GCP_position*. 

CL_CENTERED_AROUND_SELECTION  
Retrieves *GCP_numCharsToGet* characters centered around the selection

CL_CENTERED_AROUND_SELECTION_START  
Retrieves *GCP_numCharsToGet* characters centered around the start of the 
selection

CL_SELECTED_WORD  
Retrieves the selection or surrounding word.

**Library:** Objects/vTextC.def

----------
#### ContextValues
    ContextValues       etype word, 0

**Library:** ec.def

----------
#### CopyChunkFlags
    CopyChunkFlags          record
        CCF_DIRTY       :1
        CCF_MODE        CopyChunkMode:2
        CCF_SIZE        :13         ; number of bytes to copy (Not used for 
                                    ; CCM_OPTR).
    CopyChunkFlags          end

CCF_DIRTY  
If set, any created chunk is set DIRTY. If clear, any created chunk is set 
IGNORE_DIRTY

**Library:** Objects/processC.def

----------
#### CopyChunkInFrame
    CopyChunkInFrame        struct
        CCIF_copyFlags          CopyChunkFlags
        CCIF_source             dword
        CCIF_destBlock          hptr
    CopyChunkInFrame        ends

This structure is passed on the stack to MSG_PROCESS_COPY_CHUNK_IN.

*CCIF_destBlock* must be in an object block.

**Library:** Objects/process.def

----------
#### CopyChunkMode
    CopyChunkMode           etype       byte
        CCM_OPTR        enum        CopyChunkMode
        CCM_HPTR        enum        CopyChunkMode
        CCM_FPTR        enum        CopyChunkMode
        CCM_STRING      enum        CopyChunkMode

CCM_OPTR  
The chunk being copied is in the form of an object block and chunk offset.

CCM_HPTR  
The chunk being copied is in the form of a memory block and chunk offset.

CCM_FPTR  
The chunk being copied is in the form of a segment and chunk offset.

**Library:** Objects/processC.def

----------
#### CopyChunkOutFrame
    CopyChunkOutFrame           struct
        CCOF_copyFlags      CopyChunkFlags
        CCOF_source         optr
        CCOF_dest           dword
    CopyChunkOutFrame           ends

This structure is passed on the stack to MSG_PROCESS_COPY_CHUNK_OUT.

**Library:** Objects/processC.def

----------
#### CopyChunkOVerFrame
    CopyChunkOVerFrame          struct
        CCOVF_copyFlags     CopyChunkFlags
        CCOVF_source        dword
        CCOVF_dest          optr        ; If 0, then creates a new chunk.
    CopyChunkOVerFrame          ends

This structure is passed on the stack to 
MSG_PROCESS_COPY_CHUNK_OVER.

**Library:** Objects/processC.def

----------
#### CountryType
    CountryType         etype       word, 1, 1
        CT_UNITED_STATE         enum        CountryType
        CT_CANADA               enum        CountryType
        CT_UNITED_KINGDOM       enum        CountryType
        CT_GERMANY              enum        CountryType
        CT_FRANCE               enum        CountryType
        CT_SPAIN                enum        CountryType
        CT_ITALY                enum        CountryType
        CT_DENMARK              enum        CountryType
        CT_NETHERLANDS          enum        CountryType

**Library:** localize.def

----------
#### CParserReturnStruct
    CParserReturnStruct struc
        PRS_errorCode               byte
        PRS_textOffsetStart         word
        PRS_textOffsetEnd           word
        PRS_lastTokenPtr            fptr
    CParserReturnStruct ends

**Library:** parse.def

----------
#### CParserStruct
    CParserStruct       struc
        C_parameters            ParserParameters
        C_callbackPtr           fptr
        C_callbackStruct        C_CallbackStruct
    CParserStruct       ends

**Library:** parse.def

----------
#### CPUFlags
    CPUFlags        record
                            :4
        CPU_OVERFLOW        :1
        CPU_DIRECTION       :1
        CPU_INTERRUPT       :1
        CPU_TRAP            :1
        CPU_SIGN            :1
        CPU_ZERO            :1
                            :1
        CPU_AUX_CARRY       :1
                            :1
        CPU_PARITY          :1
                            :1
        CPU_CARRY           :1
    CPUFlags        end

**Library:** geos.def

----------
#### CRangeEnumCallbackParams
    CRangeEnumCallbackParams            struct
        CRECP_rangeParams       fptr.CRangeEnumParams
        CRECP_row               word            ;current row
        CRECP_column            word            ;current column
        CRECP_cellData          fptr            ;NULL if no data or REF_NO_LOCK 
                                                ;passed
        CRECP_rangeFlags        RangeEnumFlags  ;Range flags.
    CRangeEnumCallbackParams            ends

This structure is a C version of what the **RangeEnum** callback function is 
called with.

**Library:** cell.def

----------
#### CRangeEnumParams
    CRangeEnumParams            struct
        CREP_params         RangeEnumParams
        CREP_locals         fptr
        CREP_callback       fptr.far    ; This field is used internally.
    CRangeEnumParams            ends

This structure is a C version of **RangeEnumParams**.

**Library:** cell.def

----------
#### CreateExpressMenuControlItemFeature
    CreateExpressMenuControlItemFeature etype word
        CEMCIF_GEOS_TASKS_LIST      enum    CreateExpressMenuControlItemFeature
        CEMCIF_DOS_TASKS_LIST       enum    CreateExpressMenuControlItemFeature
        CEMCIF_CONTROL_PANEL        enum    CreateExpressMenuControlItemFeature
        CEMCIF_UTILITIES_PANEL      enum    CreateExpressMenuControlItemFeature

**Library:** Objects/eMenuC.def

----------
#### CreateExpressMenuControlItemParams
    CreateExpressMenuControlItemParams struct
        CEMCIP_feature              CreateExpressMenuControlItemFeature
        CEMCIP_class                fptr.ClassStruct
        CEMCIP_itemPriority         CreateExpressMenuControlItemPriority
        CEMCIP_responseMessage      word
        CEMCIP_responseDestination  optr
        CEMCIP_responseData         word
        CEMCIP_field                optr
    CreateExpressMenuControlItemParams ends

*CEMCIP_feature* stores the feature to which the item is to be created. Only 
EMCF_GEOS_TASKS_LIST, EMCF_DOS_TASKS_LIST, 
ECMF_CONTROL_PANEL, and ECMF_UTILITIES_PANEL are allowed.

*CEMCIP_class* stores the class of the object to create. This class must be a 
subclass of GenItemClass for CEMCIF_GEOS_TASKS_LIST, a subclass of 
GenTriggerClass for CEMCIF_DOS_TASKS_LIST, or a subclass of GenClass for 
CEMCIF_CONTROL_PANEL and CEMCIF_UTILITIES_PANEL.

*CEMCIP_itemPriority* specifies the relative position for the newly created 
item. Lower numbers will be added in front (above) higher numbers. Use 
CEMCIP_STANDARD_PRIORITY for default position

*CEMCIP_responseMessage* stores the message to send with newly created 
object's optr.

*CEMCIP_responseDestination* stores the destination for the response 
message.

*CEMCIP_responseData* stores an opaque word of data copied to 
CEMCIRP_data field to help destination figure out what it should do with the 
new item.

*CEMCIP_field* stores the optr of a GenField. Only Express Menu Control 
objects associated with this GenField object will be affected. Pass 0 if the 
GenField the Express Menu Control is associated with doesn't matter.

**Library:** Objects/eMenuC.def

----------
#### CreateExpressMenuControlItemPriority
    CreateExpressMenuControlItemPriority etype word
        CEMCIP_SPOOL_CONTROL_PANEL  enum CreateExpressMenuControlItemPriority, 100h
        CEMCIP_NETMSG_SEND_MESSAGE  enum CreateExpressMenuControlItemPriority, 200h
        CEMCIP_SAVER_SCREEN_SAVER   enum CreateExpressMenuControlItemPriority, 300h
        CEMCIP_SAVER_SCREEN_LOCK    enum CreateExpressMenuControlItemPriority, 400h
        CEMCIP_STANDARD_PRIORITY    enum CreateExpressMenuControlItemPriority, \
                                                         CCO_LAST

**Library:** Objects/eMenuC.def

----------
#### CreateExpressMenuControlItemResponseParams
    CreateExpressMenuControlItemResponseParams struct
        CEMCIRP_newItem                 optr
        CEMCIRP_data                    word
        CEMCIRP_expressMenuControl      optr
    CreateExpressMenuControlItemResponseParams ends

This structure stores the parameters for the response message sent in 
**CreateExpressMenuControlItemParams**.

*CEMCIRP_newItem* stores the optr of the newly created item.    ;

*CEMCIRP_data* stores an opaque word of data copied from 
*CEMCIP_responseData* field to help the destination figure out what it should 
do with the new item. 

*CEMCIRP_expressMenuControl* stores the optr of the Express Menu Control 
object that created the new item.

**Library:** Objects/eMenuC.def

----------
#### CreateVisMonikerFlags
    CreateVisMonikerFlags           record
        CVMF_DIRTY          :1
                            :7
    CreateVisMonikerFlags           end

**Library:** Objects/visC.def

----------
#### CreateVisMonikerFrame
    CreateVisMonikerFrame           struct
        CVMF_source         dword
        CVMF_sourceType     VisMonikerSourceType
        even
        CVMF_dataType       VisMonikerDataType
        even
        CVMF_length         word
        CVMF_width          word
        CVMF_height         word
        CVMF_flags          CreateVisMonikerFlags
        even
    CreateVisMonikerFrame           ends

This structure contains parameters passed to 
MSG_VIS_CREATE_VIS_MONIKER and MSG_GEN_CREATE_VIS_MONIKER.

*CVMF_source* stores the source for the moniker. This source may be an optr, 
hptr, or fptr, depending on the *CVMF_sourceType*.

*CVMF_sourceType* stores the **VisMonikerSourceType**, which specifies 
whether the moniker in *CVMF_source* is an optr, hptr, or fptr.

*CVMF_dataType* specifies whether the source is a VisMoniker, text string, 
graphics string, or GeodeToken.

*CVMF_length* stores the byte size of the source. This size is not used if 
*CVMF_sourceType* is VMST_OPTR. If the source type is VMDT_TEXT and 
*CVMF_length* is 0, text is assumed to be null-terminated. If the source type is 
VMDT_GSTRING and *CVMF_length* is 0, the length of the gstring is computed 
by scanning the gstring.

*CVMF_width* stores the width of the source if the source type is 
VMDT_GSTRING. If 0, the width of gstring is computed by scanning the 
gstring.

*CVMF_height* stores the height of the source if the source type is 
VMDT_GSTRING. If 0, the height of the gstring is computed by scanning the 
gstring.

*CVMF_flags* stores flags indicating whether to create the new moniker chunk 
dirty.

**Library:** Objects/visC.def

----------
#### CSFeatures
    CSFeatures      record
        CSF_FILLED_LIST     :1
        CSF_INDEX           :1
        CSF_RGB             :1
        CSF_DRAW_MASK       :1
        CSF_PATTERN         :1
    CSFeatures      end

**Library:** Objects/colorC.def

----------
#### CSToolboxFeatures
    CSToolboxFeatures           record
        CSTF_INDEX          :1
        CSTF_DRAW_MASK      :1
        CSTF_PATTERN        :1
    CSToolboxFeatures           end

**Library:** colorC.def

----------
#### CT_CC_CallbackStruct
    CT_CC_CallbackStruct        struc       ; Structure for CT_CREATE_CELL
        CC_row              word
        CC_column           word
        CC_errorOccurred    byte
        CC_error            byte
    CT_CC_CallbackStruct        ends

**Library:** parse.def

----------
#### CT_CNE_CallbackStruct
    CT_CNE_CallbackStruct       struc   ; Structure for CT_CHECK_NAME_EXISTS
        CNE_text            fptr
        CNE_length          word
        CNE_nameExists      byte
    CT_CNE_CallbackStruct       ends

**Library:** parse.def

----------
#### CT_CNS_CallbackStruct
    CT_CNS_CallbackStruct   struc       ; Structure for CT_CHECK_NAME_SPACE
        CNS_numToAllocate       word
        CNS_enoughSpace         byte
        CNS_errorOccurred       byte
        CNS_error               byte
    CT_CNS_CallbackStruct   ends

**Library:** parse.def

----------
#### CT_DC_CallbackStruct
    CT_DC_CallbackStruct            struc   ;Structure for CT_DEREF_CELL
        DC_argStack             fptr
        DC_opFnStack            fptr
        DC_row                  word
        DC_column               byte
        DC_derefFlags           DerefFlags
        DC_newArgStack          fptr
        DC_errorOccurred        byte
        DC_error                byte
    CT_DC_CallbackStruct            ends

**Library:** parse.def

----------
#### CT_EC_CallbackStruct
    CT_EC_CallbackStruct            struc   ; Structure for CT_EMPTY_CELL
        EC_row                  word
        EC_column               word
        EC_errorOccurred        byte
        EC_error                byte
    CT_EC_CallbackStruct            ends

**Library:** parse.def

----------
#### CT_EF_CallbackStruct
    CT_EF_CallbackStruct            struc   ; Structure for CT_EVAL_FUNCTION
        EF_numArgs              word
        EF_funcID               word
        EF_opStack              fptr
        EF_argStack             fptr
        EF_errorOccurred        byte
        EF_error                byte
    CT_EF_CallbackStruct            ends

**Library:** parse.def

----------
#### CT_FF_CallbackStruct
    CT_FF_CallbackStruct        struc   ; Structure for CT_FORMAT_FUNCTION
    FF_funcID               word
    FF_maxChars             word
    FF_resultPtr            fptr
    FF_numWritten           word
    CT_FF_CallbackStruct        ends

**Library:** parse.def

----------
#### CT_FN_CallbackStruct
    CT_FN_CallbackStruct            struc   ; Structure for CT_FORMAT_NAME
        FN_textPtr              fptr
        FN_nameToken            word
        FN_maxChars             word
        FN_resultPtr            fptr
        FN_numWritten           word
    CT_FN_CallbackStruct            ends

**Library:** parse.def

----------
#### CT_FTC_CallbackStruct
    CT_FTC_CallbackStruct       struc   ; Structure for CT_FUNCTION_TO_CELL
        FTC_funcID          word
        FTC_row             word
        FTC_column          word
        FTC_errorOccurred   byte
        FTC_error           byte
    CT_FTC_CallbackStruct       ends

**Library:** parse.def

----------
#### CT_FTT_CallbackStruct
    CT_FTT_CallbackStruct   struc   ; Structure for CT_FUNCTION_TO_TOKEN
        FTT_text                fptr
        FTT_length              word
        FTT_isFunctionName      byte
        FTT_funcID              word
    CT_FTT_CallbackStruct   ends

**Library:** parse.def

----------
#### CT_LN_CallbackStruct
    CT_LN_CallbackStruct            struc   ; Structure for CT_LOCK_NAME
        LN_nameToken            word
        LN_defPtr               dword
        LN_errorOccurred        byte
        LN_error                byte
    CT_LN_CallbackStruct            ends

**Library:** parse.def

----------
#### CT_NTC_CallbackStruct
    CT_NTC_CallbackStruct       struc   ; Structure for CT_NAME_TO_CELL
        NTC_nameToken       word
        NTC_row             word
        NTC_column          word
    CT_NTC_CallbackStruct       ends

**Library:** parse.def

----------
#### CT_NTT_CallbackStruct
    CT_NTT_CallbackStruct           struc   ; Structure for CT_NAME_TO_TOKEN
        NTT_text                fptr
        NTT_length              word
        NTT_nameID              word
        NTT_errorOccurred       byte
        NTT_error               byte
    CT_NTT_CallbackStruct           ends

**Library:** parse.def

----------
#### CT_SF_CallbackStruct
    CT_SF_CallbackStruct        struc   ; Structure for CT_SPECIAL_FUNCTION
        SF_argStack         fptr
        SF_opFnStack        fptr
        SF_specialFunction  SpecialFunction
        SF_newArgStack      fptr
        SF_errorOccurred    byte
        SF_error            byte
    CT_SF_CallbackStruct        ends

**Library:** parse.def

----------
#### CT_UL_CallbackStruct
    CT_UL_CallbackStruct            struc   ; Structure for CT_UNLOCK
        UL_dataPtr              fptr
    CT_UL_CallbackStruct            ends

**Library:** parse.def

----------
#### CurrencyFormatFlags
    CurrencyFormatFlags         record
                                            :2
        CFF_LEADING_ZERO                    :1
        CFF_SPACE_AROUND_SYMBOL             :1

        ; these four are set together in one preference manager gadget.
        CFF_USE_NEGATIVE_SIGN               :1
        CFF_SYMBOL_BEFORE_NUMBER            :1
        CFF_NEGATIVE_SIGN_BEFORE_NUMBER     :1
        CFF_NEGATIVE_SIGN_BEFORE_SYMBOL     :1
    CurrencyFormatFlags         end

**Library:** localize.def

----------
#### CustomDialogBoxFlags
    CustomDialogBoxFlags            record
        CDBF_SYSTEM_MODAL               :1
        CDBF_DIALOG_TYPE                CustomDialogType:2
        CDBF_INTERACTION_TYPE           GenInteractionType:4
        CDBF_DESTRUCTIVE_ACTION         :1=0
            ; This flag signals that the affirmative response to this dialog
            ; denotes a destructive action, and shouldn't be given the
            ; interaction default. A HINT_TRIGGER_DESTRUCTIVE_ACTION will be
            ; placed on the trigger having an IC_YES interaction command.
            ; This flag can only be used on a GIT_MULTIPLE_RESPONSE dialog.
                                        :8
    CustomDialogBoxFlags            end

**Library:** uDialog.def

----------
#### CustomDialogType
    CustomDialogType            etype       byte
        CDT_QUESTION        enum    CustomDialogType
        CDT_WARNING         enum    CustomDialogType
        CDT_NOTIFICATION    enum    CustomDialogType
        CDT_ERROR           enum    CustomDialogType

This type specifies the type of dialog box brought up by 
**UserStandardDialog**. These types are used in determining any special 
graphics strings that the dialog box may display.

CDT_QUESTION  
This type specifies that the dialog asks the user a question (e.g. "Save 
changes to 'ftpoom' before quitting?"). The associated text should normally 
end in a question mark.

CDT_WARNING  
This type specifies that the dialog warns the user of an impending action. 
(e.g. "This action can cause loss of data." ).

CDT_NOTIFICATION  
This type specifies that the dialog performs a generic notification to the user. 
(e.g. "New mail has arrived.").

CDT_ERROR  
This type specifies that the dialog states an error condition (e.g. "cannot open 
file"). Typically, error dialog boxes beep when the dialog is displayed.

**Library:** uDialog.def

[Routines V-Z](asmv_z.md) <-- [Table of Contents](../asmref.md) &nbsp;&nbsp; --> [Structures D-F](asmstrdf.md)