## 3.4 Structures H-M

----------
#### HandleUpdateMode
    HandleUpdateMode        etype byte, 0
        HUM_NOW         enum HandleUpdateMode
        HUM_MANUAL      enum HandleUpdateMode

**Library:** grobj.def

----------
#### HatchDash
    HatchDash           struct
        HD_on       WWFixed     ; length of dash to be drawn
        HD_off      WWFixed     ; space to skip until next dash
    HatchDash           ends

A **HatchPattern** consists of one or more **HatchLine** structures, which in 
turn may contain zero or more **HatchDash** structures.

**Library:** graphics.def

----------
#### HatchLine
    HatchLine       struct
        HL_origin           PointWWFixed            ; origin of line
        HL_deltaX           WWFixed         ; X offset to next line
        HL_deltaY           WWFixed         ; Y offset to next line
        HL_angle            WWFixed         ; angle at which line is to be drawn
        HL_color            ColorQuad       ; color of line
        HL_numDashes        word            ; number of dash pairs
        HL_dashData         label HatchDash ; array of pairs of on/off lengths
    HatchLine       ends

**Library:** graphics.def

----------
#### HatchPattern
    HatchPattern            struct
        HP_numLines     word            ; number of line records in this pattern
        HP_lineData     label HatchLine ; array of 1 or more hatch lines
    HatchPattern            ends

A **HatchPattern** consists of one or more **HatchLine** structures, which in 
turn may contain zero or more **HatchDash** structures.

**Library:** graphics.def

----------
#### HCFeatures
    HCFeatures      record
        HCF_LIST        :1
    HCFeatures      end

**Library:** Objects/Text/tCtrlC.def

----------
#### HCToolboxFeatures
    HCToolboxFeatures       record
        HCTF_TOGGLE     :1
    HCToolboxFeatures       end

**Library:** Objects/Text/tCtrlC.def

----------
#### HeapAllocFlags
    HeapAllocFlags      record
        HAF_ZERO_INIT           :1  ; Initialize new memory to 0
        HAF_LOCK                :1  ; Return with block locked
        HAF_NO_ERR              :1  ; Caller can't handle errors
        HAF_UI                  :1  ; If HAF_OBJECT_RESOURCE, set HM_otherInfo
                                    ; to the handle of the UI as that's who's
                                    ; to operate objects in the block
        HAF_READ_ONLY           :1  ; Data in block will not/may not be
                                    ; modified
        HAF_OBJECT_RESOURCE     :1  ; Block contains objects
        HAF_CODE                :1  ; Block contains executable code
        HAF_CONFORMING          :1  ; Block contains code that may be executed
                                    ; by a less privileged entity
    HeapAllocFlags      end

**Library:** heap.def

----------
#### HeapCongestion
    HeapCongestion          etype word, 0, 2
        HC_SCRUBBING    enum HeapCongestion ;Heap is being scrubbed. Might be a 
                                            ;good idea to free some things.
                                            ;** Not currently used **
        HC_CONGESTED    enum HeapCongestion ; Couldn't nuke enough memory to
                                            ;satisfy the heap scrubber.
        HC_DESPERATE    enum HeapCongestion ;Heap is perilously close to
                                            ;overflowing. Nuke stuff *now*.

**Library:** heap.def

----------
#### HeapFlags
    HeapFlags       record
        HF_FIXED        :1  ; Block won't ever move
        HF_SHARABLE     :1  ; May be locked by other than owner
        HF_DISCARDABLE  :1  ; May be discarded if space needed
        HF_SWAPABLE     :1  ; May be swapped if space needed
        HF_LMEM         :1  ; Managed by LMem module
        HF_DEBUG        :1  ; Swat cares what happens to it -- DO NOT PASS
                            ; THIS FLAG. IT IS RESERVED FOR INTERNAL USE
                            ; BY THE DEBUGGER
        HF_DISCARDED    :1  ; Discarded and must be brought in fresh from
                            ; executable/resource file
        HF_SWAPPED      :1  ; Swapped to memory or disk.
    HeapFlags       end

**Library:** heap.def

----------
#### HeightJustification
    HeightJustification         etype byte
        HJ_TOP_JUSTIFY_CHILDREN             enum HeightJustification
        HJ_BOTTOM_JUSTIFY_CHILDREN          enum HeightJustification
        HJ_CENTER_CHILDREN_VERTICALLY       enum HeightJustification
        HJ_FULL_JUSTIFY_CHILDREN_VERTICALLY enum HeightJustification

**Library:** Objects/vCompC.def

----------
#### HelpEntry
    HelpEntry       struct
        HE_string       byte
    HelpEntry       ends

This structure defines a help chunk.

**Library:** Objects/genC.def

----------
#### HierarchicalGrab
    HierarchicalGrab        struct
        HG_OD           optr
        HG_flags        HierarchicalGrabFlags <>
    HierarchicalGrab        ends

**Library:** Objects/uiInputC.def

----------
#### HierarchicalGrabFlags
    HierarchicalGrabFlags           record
        HGF_SYS_EXCL            :1
        HGF_APP_EXCL            :1
        HGF_GRAB                :1
        HGF_OTHER_INFO          :12
    HierarchicalGrabFlags           end

HGF_SYS_EXCL  
Not passed anywhere, but stored in hierarchical grab 
structure, it indicates that the object has the exclusive within 
the System.

HGF_APP_EXCL  
Not passed anywhere, but stored in hierarchical grab 
structure, it indicates that the object has the exclusive within 
the Application.

HGF_GRAB  
This bit as passed to **FlowAlterHierarchicalGrab** indicates 
whether the object wishes to grab or release the exclusive it has 
within the node. Stored in a grab, it indicates that an object has 
the exclusive with the node (i.e. is redundant with the fact that 
there is an OD stored in the grab).

HGF_OTHER_INFO  
Use defined by the type of **HierarchicalGrab**. This data is 
stored in the *HG_flags* field, whenever 
**FlowAlterHierarchicalGrab** is called to grab the exclusive 
for an object.

**Library:** uiInputC.def

----------
#### HoldUpInputFlags
    HoldUpInputFlags        record
        HUIF_FLUSHING_QUEUE             :1
        HUIF_HOLD_UP_MODE_DISABLED      :1
                                        :6
    HoldUpInputFlags        end

HUIF_FLUSHING_QUEUE  
Set if the HoldUpInputQueue is in the process of being flushed. 
Used to allow reentrant calls into 
**FlowFlushHoldUpInputQueue**.

HUIF_HOLD_UP_MODE_DISABLED  
Set on call to **FlowDisableHoldUpInput**. Forces input data 
to flow normally until cleared. Used only by the system object 
when a system-modal dialog box is put on screen, to ensure 
that user can interact with it.

**Library:** uiInputC.def

----------
#### HugeArrayDirectory
    HugeArrayDirectory          struct
        HAD_header      LMemBlockHeader <>      ; 
        HAD_data        word                    ; VM block link to first data block
        HAD_dir         lptr.ChunkArrayHeader   ; chunk handle to ChunkArray
        HAD_xdir        word                    ; link to next dir block
        HAD_self        word                    ; vm block handle of self
        HAD_size        word                    ; element size, 0=variable
    HugeArrayDirectory          ends

This structure is allocated at the beginning of the directory block.

**Library:** hugearr.def

----------
#### HWRBoxData
    HWRBoxData      struct
        HWRBD_mode          HWRMode
        HWRBD_top           sword
        HWRBD_bottom        sword
    HWRBoxData      ends

**Library:** hwr.def

----------
#### HWRContext
    HWRContext      union
        HWRC_none       HWRNoneData
        HWRC_lined      HWRLineData
        HWRC_boxed      HWRBoxData
        HWRC_grid       HWRGridData
        HWRContext      end

**Library:** hwr.def

----------
#### HWRGridData
    HWRGridData     struct
        HWRGD_mode          HWRMode
        HWRGD_bounds        Rectangle
        HWRGD_xOffset       sword
        HWRGD_yOffset       sword
    HWRGridData     ends

*HWRGD_bounds* stores the bounds of the grid area (in same coordinates as 
the ink data).

*HWRGD_yOffset* stores the X/Y offsets between grid lines.

**Library:** hwr.def

----------
#### HWRLineData
    HWRLineData     struct
        HWRLD_mode          HWRMode
        HWRLD_line          sword
    HWRLineData     ends

**Library:** hwr.def

----------
#### HWRMode
    HWRMode etype word
        HM_NONE     enum HWRMode
        ; The user is writing in a multi-line object - no guidelines
        HM_LINE     enum HWRMode
        ; The user has a reference line to write on
        HM_BOX      enum HWRMode
        ; The user has a box to write into
        HM_GRID     enum HWRMode
        ; The user has a grid to write chars into (one char per box)

**Library:** hwr.def

----------
#### HWRNoneData
    HWRNoneData     struct
        HWRND_mode      HWRMOde
    HWRNoneData     ends

**Library:** hwr.def

----------
#### HWRRoutine
    HWRRoutine      etype word
        HWRR_BEGIN_INTERACTION                  enum HWRRoutine
        HWRR_END_INTERACTION                    enum HWRRoutine
        ;
        ;   Most HWR drivers can not handle multiple clients at once. Clients
        ;   should call HWRR_BEGIN_INTERACTION before any other HWR calls, and
        ;   HWRR_END_INTERACTION after their HWR calls.
        ;
        ;   NOTE: Assume that after you call HWRR_END_INTERACTION, all of the
        ;    parameters you've set up (points added, filters activated) will
        ;    be destroyed.
        ;
        ;   Pass:       nothing
        ;   Returns:    HWRR_BEGIN_INTERACTION returns AX=0 to show that
        ;               everything is fine, else there is an error.
        ;               If HWRR_BEGIN_INTERACTION returns an error, do 
        ;               not call HWRR_END_INTERACTION.
        ;
        HWRR_RESET                              enum HWRRoutine
        ;
        ;   Resets the library in preparation of sending a new set of ink data
        ;   to it. This nukes all old points, and re-enables the entire 
        ;   character set.
        ;
        ;   Pass:       nothing
        ;   Returns:    nothing
        ;   Destroyed:  nothing
        ;
        HWRR_DISABLE_CHAR_RANGE                 enum HWRRoutine
        ;
        ;   Disables the passed range of characters - this means that strokes
        ;   will not be recognized as these characters.
        ;
        ;   Pass: (on stack)
        ;
        ;       word - first char in range to disable
        ;       word - last char in range to disable
        ;
        ;   Return: nothing
        ;
        HWRR_ENABLE_CHAR_RANGE                  enum HWRRoutine
        ;
        ;   Enables the passed range of characters - this means that strokes
        ;   can be recognized by these characters.
        ;
        ;   Pass: (on stack)
        ;
        ;       word - first char in range to disable
        ;       word - last char in range to disable
        ;
        ;   Return: nothing
        ;
        HWRR_SET_CHAR_FILTER_CALLBACK           enum HWRRoutine
        ;
        ;   Calls the passed callback routine with characters.
        ;
        ;   Pass:       (push in this order)
        ;               fptr to callback routine
        ;               fptr to callback data
        ;
        ;   Return:         nothing
        ;
        ;   Callback is passed (on stack):
        ;
        ;       word        number of choices for character
        ;       word        offset of first point in char
        ;       word        offset of last point in char
        ;       fptr        array of 16-bit characters
        ;       fptr        callback data
        ;
        ;   Callback should return:
        ;
        ;       AX =    character chosen (it does not necessarily have to 
        ;               be one of the characters in the passed array)
        ;
        ;   Callback can destroy: ax, bx, cx, dx
        ;
        HWRR_SET_STRING_FILTER_CALLBACK         enum HWRRoutine
        ;
        ;   This allows the application to specify his own filter   routine on
        ;   an entire word basis (as opposed to a char by char basis)
        ;
        ;   NOTE: If the app specifies a "WHOLE_WORD" filter callback, it should
        ;    not also specify a "CHAR_FILTER" callback, as the "CHAR_FILTER"
        ;    callback will not be called.
        ;
        ;   Pass:       (on stack - push in this order)
        ;               fptr to callback routine
        ;               fptr to callback data
        ;
        ;   Returns:    nothing
        ;
        ;   Callback routine is passed (on stack - pascal model):
        ;
        ;       word        number of characters recognized
        ;       fptr        array of CharChoiceInformation structures
        ;       fptr        callback data
        ;
        ;   Callback routine returns:
        ;
        ;       AX - handle of block containing null-terminated
        ;       ink data
        ;
        ;   Callback routine can destroy:
        ;
        ;       AX, BX, CX, DX
        HWRR_ADD_POINT                          enum HWRRoutine
        ;
        ;       This allows the application to add a point to the list of
        ;       points being collected and recognized
        ;
        ;       Pass: (on stack)
        ;               InkXCoord       ;X coordinate
        ;               word            ;Y coordinate
        ;               dword           ;time stamp
        ;                               (normally passed as 0, but can be passed
        ;                               as an actual value for certain real-time
        ;                               applications, such as signature verification)
        ;       Returns: nothing
        ;
        HWRR_ADD_POINTS                         enum HWRRoutine
        ;
        ;       This adds a bunch of points at once.
        ;
        ;       Pass: (on stack)
        ;               word        num points
        ;               fptr        array of InkPoint structures
        ;       Return: nothing
        ;
        HWRR_DO_GESTURE_RECOGNITION             enum HWRRoutine
        ;
        ;       Checks to see if the points are a single gesture.
        ;
        ;       Pass: nothing
        ;       Return: AX <- return
        ;
        HWRR_DO_SINGLE_CHAR_RECOGNITION         enum HWRRoutine
        ;
        ;       This returns a single char that was recognized from the ink input
        ;
        ;       Pass: nothing
        ;       Return: AX <- character
        ;
        HWRR_DO_MULTIPLE_CHAR_RECOGNITION       enum HWRRoutine
        ;
        ;       This returns a null-terminated string that was recognized from the
        ;       input.
        ;
        ;       Pass: nothing
        ;       Return: AX <- handle of block containing null-terminated ink data
        ;
        HWRR_GET_HWR_MANUF_ID                   enum HWRRoutine
        ;
        ;       Returns the manufacturer of the HWR. This may be useful if you want
        ;       to call certain special features that only exist in certain drivers.
        ;       (For example, if one was writing a signature verification application
        ;       that required a specific HWR driver).
        ;
        ;       Pass: nothing
        ;       Returns: AX - ManufacturerID
        ;
        HWRR_SET_CONTEXT                        enum HWRRoutine
        ;
        ;       Puts the hwr engine in line/grid/boxed mode.
        ;
        ;       Pass (on stack)
        ;               fptr to HWRContext union
        HWRR_SET_LANGUAGE                       enum HWRRoutine
        ;
        ;       Sets the default recognition language of the HWR
        ;       Pass:   (push in this order)
        ;               word - StandardLanguage
        ;       Returns: nothing

**Library:** hwr.def

----------
#### HyphenationPoints
    HyphenationPoints           struct
        HP_wordLen          word
        HP_array            label byte
    HyphenationPoints           ends

*HP_array* marks the start of a null-terminated array of hyphenation points.

**Library:** Objects/vTextC.def

----------
#### HyphenFlags
    HyphenFlags     record
        HF_AUTO_HYPHEN  :1      ; set when auto-hyphen exists at EOL
    HyphenFlags     end

**Library:** text.def

----------
#### IACPConnectError
    IACPConnectError        etype word, GeodeLoadError
        IACPCE_CANNOT_FIND_SERVER   enum IACPConnectError
        IACPCE_NO_SERVER            enum IACPConnectError

IACPCE_CANNOT_FIND_SERVER  
Asked to start server w/o specifying location of app, and IACP was unable to 
find an application with the same token as the list.

IACPCE_NO_SERVER  
Didn't ask IACP to start server, and no server is registered for the list.

**Library:** iacp.def

----------
#### IACPConnectFlags
    IACPConnectFlags        record
                                                :10
        IACPCF_OBEY_LAUNCH_MODEL                :1
        IACPCF_CLIENT_OD_SPECIFIED              :1
        IACPCF_FIRST_ONLY                       :1
        IACPCF_SERVER_MODE IACPServerMode       :3
    IACPConnectFlags        end

IACPCF_OBEY_LAUNCH_MODEL  
Set if IACP should obey any launch model for the field that 
would cause it to ask the user whether an existing server 
should be used, or a new one started. **AppLaunchBlock** must 
be passed with *ALB_appMode* set to 
MSG_GEN_PROCESS_OPEN_APPLICATION and 
IACPCF_SERVER_MODE set to IACPSM_USER_INTERACTIBLE.

IACPCF_CLIENT_OD_SPECIFIED  
Set to indicate **^lcx:dx** contains client OD for the IACP 
connection. If not set, the client OD is set to the application 
object of the process on whose thread the **IACPConnect** call is 
made.

IACPCF_FIRST_ONLY  
Set to connect only to the first server on the list, else connects 
to all of them.

IACPCF_SERVER_MODE  
Mode in which server is expected to be operating 
(IACPSM_IN_FLUX not allowed). Higher-numbered modes are 
expected to support requests for lower-numbered modes.

**Library:** iacp.def

----------
#### IACPDocCloseAckParams
    IACPDocCloseAckParams           struct
        IDCAP_docObj            optr
        IDCAP_connection        IACPConnection
        IDCAP_serverNum         word
        IDCAP_status            word            ; DocQuitStatus
    IACPDocCloseAckParams           ends

**Library:** iacp.def

----------
#### IACPDocOpenAckParams
    IACPDocOpenAckParams        struct
        IDOAP_docObj                optr
        IDOAP_connection            IACPConnection
        IDOAP_serverNum             word
    IACPDocOpenAckParams        ends

*IDOAP_docObj* the optr of the document object managing the document.

*IDOAP_connection* stores the IACP connection over which the request to open 
was received.

*IDOAP_serverNum* stores the server number the document object's 
GenApplication object is for that connection (0 if connection goes through 
some other object).

**Library:** iacp.def

----------
#### IACPServerFlags
    IACPServerFlags     record
        IACPSF_MULTIPLE_INSTANCES:1
        ; Set if application may have multiple instances of itself launched
        :7
    IACPServerFlags     end

**Library:** iacp.def

----------
#### IACPServerMode
    IACPServerMode etype    byte
        IACPSM_NOT_USER_INTERACTIBLE        enum IACPServerMode
        IACPSM_IN_FLUX                      enum IACPServerMode
        IACPSM_USER_INTERACTIBLE            enum IACPServerMode

The mode in which an IACP server is operating. A user-interactable server is 
expected to cope with messages addressed to a non-user-interactable server, 
but the reverse is not true.

**Library:** iacp.def

----------
#### IACPSide
    IACPSide    etype word
        IACPS_CLIENT            enum IACPSide
        IACPS_SERVER            enum IACPSide

Specifies which side of an IACP connection is sending a message via 
**IACPSendMessage**.

**Library:** iacp.def

----------
#### IEEE64
    IEEE64      struct
        IEEE64_wd0      word
        IEEE64_wd1      word
        IEEE64_wd2      word
        IEEE64_wd3      word
    IEEE64      ends

**Library:** math.def

----------
#### ImageBitSize
    ImageBitSize        etype byte
        IBS_1       enum ImageBitSize       ; 1 to 1 mapping
        IBS_2       enum ImageBitSize       ; 2 x 2 pixels
        IBS_4       enum ImageBitSize       ; 4 x 4 pixels
        IBS_8       enum ImageBitSize       ; 8 x 8 pixels
        IBS_16      enum ImageBitSize       ; 16 x 16 pixels

**Library:** graphics.def

----------
#### ImageFlags
    ImageFlags      record
        IF_DRAW_IMAGE   :1,         ; reserved for internal use (set to zero)
        IF_HUGE         :1,         ; reserved for internal use (set to zero)
            :1,
        IF_IGNORE_MASK  :1          ; set to draw all pixels, regardless of mask
        IF_BORDER       :1,         ; set if border desired around each pixel
        IF_BITSIZE      ImageBitSize:3  ; size of each pixel
    ImageFlags      end

**Library:** graphics.def

----------
#### IMCFeatures
    IMCFeatures     record
                        :7
        IMCF_MAP        :1
    IMCFeatures     end

**Library:** impex.def

----------
#### ImpexDataClasses
    ImpexDataClasses            record
        IDC_TEXT            :1
        IDC_GRAPHICS        :1
        IDC_SPREADSHEET     :1
        IDC_FONT            :1
                            :12
    ImpexDataClasses            end

**Library:** impex.def

----------
#### ImpexFileSelectionData
    ImpexFileSelectionData          struct
        IFSD_selection          FileLongName
        IFSD_path               PathName
        IFSD_disk               word
        IFSD_type               GenFileSelectorEntryFlags
    ImpexFileSelectionData          ends

This structure is passed with 
MSG_IMPORT_EXPORT_FILE_SELECTION_INFO.

**Library:** impex.def

----------
#### ImpexMapFileInfoHeader
    ImpexMapFileInfoHeader          struc
        IMFTH_base              LMemBlockHeader
        IMFTH_fieldChunk        word
        IMFTH_numFields         word
        IMFIH_flag              DefaultFieldNameUsage
    ImpexMapFileInfoHeader          ends

**Library:** impex.def

----------
#### ImpexMapFlags
    ImpexMapFlags           record
        IMF_IMPORT      :1
        IMF_EXPORT      :1
                        :6
    ImpexMapFlags           end

**Library:** impex.def

----------
#### ImpexTranslationParams
    ImpexTranslationParams          struct
        ITP_impexOD             optr    ; OD of Import/ExportControl
        ITP_returnMsg           word    ; message to return to above
        ITP_dataClass           word    ; what class type (ImpexDataClasses)
        ITP_transferVMFile      hptr    ; VM file w/ transfer format
        ITP_transferVMChain     dword   ; VM chain w/ transfer format
        ITP_internal            dword   ; two words of internal data
        ITP_manufacturerID      ManufacturerID;
        ITP_clipboardFormat     ClipboardItemFormat
    ImpexTranslationParams          ends

**Library:** ieCommon.def

----------
#### ImportControlAttrs
    ImportControlAttrs      record
        ICA_IGNORE_INPUT            :1      ; ignore input while import occurs.
        ICA_NON_DOCUMENT_IMPORT     :1      ; non-document imports only
                                    :14
    ImportControlAttrs      end

**Library:** impex.def

----------
#### ImportControlFeatures
    ImportControlFeatures       record
        IMPORTCF_PREVIEW_TRIGGER    :1      ; not currently used
        IMPORTCF_IMPORT_TRIGGER     :1      ; import trigger
        IMPORTCF_FORMAT_OPTIONS     :1      ; import format UI parent,
                                            ; under which is placed any
                                            ; UI specific to the
                                            ; currently selected format
        IMPORTCF_FILE_MASK          :1      ; import file mask
        IMPORTCF_BASIC              :1      ; import file selector,
                                            ; import format list, and
                                            ; import app UI parent, under
                                            ; which is placed any UI
                                            ; specific to the app
        IMPORTCF_GLYPH              :1      ; glyph at top of import
                                            ; dialog box
    ImportControlFeatures       end

**Library:** impex.def

----------
#### ImportControlToolboxFeatures
    ImportControlToolboxFeatures                record
        IMPORTCTF_DIALOG_BOX                :1
    ImportControlToolboxFeatures                end

**Library:** impex.def

----------
#### InitFileCharConvert
    InitFileCharConvert         etype byte
        IFCC_INTACT     enum InitFileCharConvert    ; leave intact
        IFCC_UPCASE     enum InitFileCharConvert    ; upcase all chars
        IFCC_DOWNCASE   enum InitFileCharConvert    ; downcase all chars

**Library:** initfile.def

----------
#### InitFileReadFlags
    InitFileReadFlags       record
        IFRF_CHAR_CONVERT       InitFileCharConvert:2   ; character conversion

        IFRF_READ_ALL           :1
        ; Instructs the initfile routine to read from all the init files,
        ; where appropriate. Only used in InitFileEnumStringSection,
        ; which will enumerate over all string sections in all init files

        IFRF_FIRST_ONLY         :1
        ; Read from the first init file only.

        IFRF_SIZE               :12                     ; size of buffer
    InitFileReadFlags       end

**Library:** initfile.def

----------
#### InkBackgroundType
    InkBackgroundType       etype word, 0, 2
        IBT_NO_BACKGROUND               enum InkBackgroundType
        IBT_NARROW_LINED_PAPER          enum InkBackgroundType
        IBT_MEDIUM_LINED_PAPER          enum InkBackgroundType
        IBT_WIDE_LINED_PAPER            enum InkBackgroundType
        IBT_NARROW_STENO_PAPER          enum InkBackgroundType
        IBT_MEDIUM_STENO_PAPER          enum InkBackgroundType
        IBT_WIDE_STENO_PAPER            enum InkBackgroundType
        IBT_SMALL_GRID                  enum InkBackgroundType
        IBT_MEDIUM_GRID                 enum InkBackgroundType
        IBT_LARGE_GRID                  enum InkBackgroundType
        IBT_SMALL_CROSS_SECTION         enum InkBackgroundType
        IBT_MEDIUM_CROSS_SECTION        enum InkBackgroundType
        IBT_LARGE_CROSS_SECTION         enum InkBackgroundType
        IBT_TO_DO_LIST                  enum InkBackgroundType
        IBT_PHONE_MESSAGE               enum InkBackgroundType
        IBT_CUSTOM_BACKGROUND           enum InkBackgroundType

**Library:** pen.def

----------
#### InkControlFeatures
    InkControlFeatures      record
        ICF_PENCIL_TOOL             :1
        ICF_ERASER_TOOL             :1
        ICF_SELECTION_TOOL          :1
    InkControlFeatures      end

**Library:** pen.def

----------
#### InkControlToolboxFeatures
    InkControlToolboxFeatures               record
        ICTF_PENCIL_TOOL                :1
        ICTF_ERASER_TOOL                :1
        ICTF_SELECTION_TOOL             :1
    InkControlToolboxFeatures               end

**Library:** pen.def

----------
#### InkDBFrame
    InkDBFrame      struct
        IDBF_bounds             Rectangle
        IDBF_VMFile             hptr
        IDBF_DBGroupAndItem     DBGroupAndItem
        IDBF_DBExtra            word
    InkDBFrame      ends

*IDBF_bounds* stores the bounds of the ink to write out. If you want all of the 
ink rather than a portion of it, pass <(0,0), (0xffff, 0xffff)> as the bounds.

*IDBF_VMFile* stores the VM File to write to or read from (depending on the 
operation).

*IDBF_DBGroupAndItem* stores the DB Item to save to or load from (or 0 to 
create a new one).

*IDBF_DBExtra* stores the extra space to skip at the start of the block.

**Library:** pen.def

----------
#### InkDestinationInfo
    InkDestinationInfo      struct
        IDI_destObj             optr
        IDI_gstate              hptr.GState
        IDI_brushSize           word
        IDI_gestureCallback     dword
    InkDestinationInfo      ends

*IDI_destObj* stores the optr of the object that the ink should be sent to.

*IDI_gstate* stores the gstate to draw through. (This is optional, and can be set 
to 0 if ink can go all over the screen).

*IDI_brushSize* stores the width/height parameter of the ink lines (see 
**GrBrushPolyline**).Use 0 for default behavior.

*IDI_gestureCallback* stores the virtual far pointer to the callback routine.

**Callback Routine Specifications:**  
**Pass on stack:** (Pascal calling convention):  
fptr - arrayOfInkPoints  
word - numPoints  
word - numStrokes  
*numStrokes* specifies the number of strokes entered by the user. If you only 
support single-stroke gestures, you can check this to quickly exit if the user 
has entered multiple strokes.  
**Return:** ax  Non-zero if the ink is a gesture

**Library:** Objects/uiInputC.def

----------
#### InkDestinationInfoParams
    InkDestinationInfoParams            struct
        IDIP_dest               optr
        IDIP_brushSize          word
        IDIP_color              Color
        IDIP_reserved1          byte
        IDIP_createGState       byte
        IDIP_reserved2          byte
    InkDestinationInfoParams            ends

*IDIP_dest* and *IDIP_brushSize* are the same as the arguments passed to 
**UserCreateInkDestinationInfo**.

**Library:** Objects/gViewC.def

----------
#### InkFlags
    InkFlags    record
        IF_HAS_MOUSE_GRAB           :1
        IF_SELECTING                :1
        IF_HAS_TARGET               :1
        IF_HAS_SYS_TARGET           :1
        IF_DIRTY                    :1
        IF_ONLY_CHILD_OF_CONTENT    :1
        IF_CONTROLLED               :1
        IF_INVALIDATE_ERASURES      :1
        IF_HAS_UNDO                 :1
                                    :7
    InkFlags    end

IF_HAS_MOUSE_GRAB  
Set if the object has grabbed the mouse.

IF_SELECTING  
Set if doing a selection.

IF_HAS_TARGET  
Set if this object has the target.

IF_HAS_SYS_TARGET  
Set if this object has the target.

IF_DIRTY  
Set when we are dirty.

IF_ONLY_CHILD_OF_CONTENT  
Set if this is the only child of a VisContent, in which case it 
should use some optimizations to reply to ink at the view level.

IF_CONTROLLED  
Set if this object is to be used in conjunction with an InkControl 
object.

IF_INVALIDATE_ERASURES  
Set if we should invalidate the bounds of all erasures, in case 
there is a subclass that needs to redraw the background.

IF_HAS_UNDO  
Set if this object should be undoable.

**Library:** pen.def

----------
#### InkGrab
    InkGrab     struct
        IG_OD       optr
        IG_gState   hptr
    InkGrab     ends

This structure is used by the ink code within the Flow object.

**Library:** Objects/uiInputC.def

----------
#### InkHeader
    InkHeader       struct
        IH_count            word
        IH_bounds           Rectangle
        IH_destination      optr
        IH_reserved         dword
        IH_data             label Point
    InkHeader       ends

This structure defines the data block format for the GWNT_INK notification 
type.

*IH_count* stores the number of ink points collected.

*IH_bounds* stores the bounds of the ink on the screen.

*IH_destination* stores the optr of the destination object for the ink. Objects 
can use this to determine whether the ink was sent to them directly, or just 
because it overlapped the screen. This field is set by the flow object.

*IH_reserved* is reserved for future use.

**Library:** Input.def

----------
#### InkPoint
    InkPoint        struct
        IP_x    InkXCoord
        IP_y    word
    InkPoint        ends

**Library:** hwr.def

----------
#### InkReturnValue
    InkReturnValue      etype word
        IRV_NO_REPLY                    enum InkReturnValue, 0
        IRV_NO_INK                      enum InkReturnValue
        IRV_INK_WITH_STANDARD_OVERRIDE  enum InkReturnValue
        IRV_DESIRES_INK                 enum InkReturnValue
        IRV_WAIT                        enum InkReturnValue

IRV_NO_REPLY  
VisComp objects use **VisCallChildUnderPoint** to send 
MSG_META_QUERY_IF_PRESS_IS_INK to its children, and 
VisCallChildUnderPoint returns this value (zero) if there was 
not child under the point. No object should actually return this 
value.

IRV_NO_INK  
Return this if the object wants the MSG_META_START_SELECT 
to be passed on to it.

IRV_INK_WITH_STANDARD_OVERRIDE  
Return this if the object normally wants ink (the text object 
does this), but the user can force mouse events instead by 
pressing the pen and holding for some user-adjustable amount 
of time).

IRV_DESIRES_INK  
Return this if the object does not want the 
MSG_META_START_SELECT (it should be captured as ink).

IRV_WAIT  
This should be the last item in the enumerated type for EC 
reasons.

Return this value if the object under the point is run by a 
different thread, and you want to hold up input (don't do 
anything with the MSG_META_START_SELECT) until an object 
sends a MSG_GEN_APPLICATION_INK_QUERY_REPLY to the 
application object.

**Library:** uiInputC.def

----------
#### InkStrokeSize
    InkStrokeSize           struct
        ISS_width       byte
        ISS_height      byte
    InkStrokeSize           ends

**Library:** pen.def

----------
#### InkTool
    InkTool etype word, 0, 2
        IT_PENCIL       enum InkTool        ;Default tool
        IT_ERASER       enum InkTool
        IT_SELECTOR     enum InkTool

**Library:** pen.def

----------
#### InkXCoord
    InkXCoord       record
        IXC_TERMINATE_STROKE    :1
        IXC_X_COORD             :15
    InkXCoord       end

**Library:** hwr.def

----------
#### InsertChildFlags
    InsertChildFlags        record
        ICF_MARK_DIRTY  :1,                 ;Marks chunk and modified object as 
                                            ; dirty
                        :13,
        ICF_OPTIONS     InsertChildOption:2 ;Options for how to add the child
    InsertChildFlags        end

**Library:** Objects/metaC.def

----------
#### InsertChildOption
    InsertChildOption       etype byte
        ICO_FIRST               enum InsertChildOption
        ICO_LAST                enum InsertChildOption
        ICO_BEFORE_REFERENCE    enum InsertChildOption
        ICO_AFTER_REFERENCE     enum InsertChildOption

**Library:** Objects/metaC.def

----------
#### InsertDeleteSpaceParams
    InsertDeleteSpaceParams         struct
        IDSP_position       PointDWFixed
        IDSP_space          PointDWFixed
        IDSP_type           InsertDeleteSpaceTypes
    InsertDeleteSpaceParams         ends

**Library:** Objects/visC.def

----------
#### InsertDeleteSpaceTypes
    InsertDeleteSpaceTypes          record
                                                                :11 
        IDST_MOVE_OBJECTS_INSIDE_DELETED_SPACE_BY_AMOUNT_DELETED :1
        IDST_MOVE_OBJECTS_INTERSECTING_DELETED_SPACE            :1
        IDST_RESIZE_OBJECTS_INTERSECTING_SPACE                  :1
        IDST_DELETE_OBJECTS_SHRUNK_TO_ZERO_SIZE                 :1
        IDST_MOVE_OBJECTS_BELOW_AND_RIGHT_OF_INSERT_POINT_OR_DELETED_SPACE :1
    InsertDeleteSpaceTypes          end

IDST_MOVE_OBJECTS_INSIDE_DELETED_SPACE_BY_AMOUNT_DELETED  
Move objects that are in the deleted space by the amount of 
space being deleted.

IDST_MOVE_OBJECTS_INTERSECTING_DELETED_SPACE  
Move objects that intersect the deleted space so that their left 
and top are aligned with the left and top of the deleted space

IDST_RESIZE_OBJECTS_INTERSECTING_SPACE  
If inserting space and line extending down and/or to right from 
insert point intersects object then add inserted space to size of 
object. If deleting space and deleted space intersects object 
then remove space from object. Object can be shrunk to zero 
width and height.

IDST_DELETE_OBJECTS_SHRUNK_TO_ZERO_SIZE  
If object is shrunk to zero width OR height during delete space 
then delete it.

IDST_MOVE_OBJECTS_BELOW_AND_RIGHT_OF_INSERT_POINT_OR_DELET
ED_SPACE  
If inserting space and object is below and or to right of insert 
point then move object down and right the amount of inserted 
space. If deleting space and object is below or to right of deleted 
space then move object up and to left the amount of the deleted 
space. In most uses of this message, this bit will be set.

**Library:** Objects/visC.def

----------
#### InstrumentPatch
    InstrumentPatch     etype dword, 0, size InstrumentEnvelope
        ; MIDI patch    1 - 8 = Piano
        IP_ACOUSTIC_GRAND_PIANO                 enum InstrumentPatch
        IP_BRIGHT_ACOUSTIC_PIANO                enum InstrumentPatch
        IP_ELECTRIC_GRAND_PIANO                 enum InstrumentPatch
        IP_HONKY_TONK_PIANO                     enum InstrumentPatch
        IP_ELECTRIC_PIANO_1                     enum InstrumentPatch
        IP_ELECTRIC_PIANO_2                     enum InstrumentPatch
        IP_HARPSICORD                           enum InstrumentPatch
        IP_CLAVICORD                            enum InstrumentPatch
        ; MIDI patch    9 - 16 = Chromatic Percussion
        IP_CELESTA                              enum InstrumentPatch
        IP_GLOCKENSPIEL                         enum InstrumentPatch
        IP_MUSIC_BOX                            enum InstrumentPatch
        IP_VIBRAPHONE                           enum InstrumentPatch
        IP_MARIMBA                              enum InstrumentPatch
        IP_XYLOPHONE                            enum InstrumentPatch
        IP_TUBULAR_BELLS                        enum InstrumentPatch
        IP_DULCIMER                             enum InstrumentPatch
        ; MIDI patch    17 - 24 = Organ
        IP_DRAWBAR_ORGAN                        enum InstrumentPatch
        IP_PERCUSSIVE_ORGAN                     enum InstrumentPatch
        IP_ROCK_ORGAN                           enum InstrumentPatch
        IP_CHURCH_ORGAN                         enum InstrumentPatch
        IP_REED_ORGAN                           enum InstrumentPatch
        IP_ACCORDIAN                            enum InstrumentPatch
        IP_HARMONICA                            enum InstrumentPatch
        IP_TANGO_ACCORDION                      enum InstrumentPatch
        ; MIDI patch    25 - 32 = Guitar
        IP_ACOUSTIC_NYLON_GUITAR                enum InstrumentPatch
        IP_ACOUSTIC_STEEL_GUITAR                enum InstrumentPatch
        IP_ELECTRIC_JAZZ_GUITAR                 enum InstrumentPatch
        IP_ELECTRIC_CLEAN_GUITAR                enum InstrumentPatch
        IP_ELECTRIC_MUTED_GUITAR                enum InstrumentPatch
        IP_OVERDRIVEN_GUITAR                    enum InstrumentPatch
        IP_DISTORTION_GUITAR                    enum InstrumentPatch
        IP_GUITAR_HARMONICS                     enum InstrumentPatch
        ; MIDI patch    33 - 40 = Bass
        IP_ACOUSTIC_BASS                        enum InstrumentPatch
        IP_ELECTRIC_FINGERED_BAS                enum InstrumentPatch
        IP_ELECTRIC_PICKED_BASS                 enum InstrumentPatch
        IP_FRETLESS_BASS                        enum InstrumentPatch
        IP_SLAP_BASS_1                          enum InstrumentPatch
        IP_SLAP_BASS_2                          enum InstrumentPatch
        IP_SYNTH_BASS_1                         enum InstrumentPatch
        IP_SYNTH_BASS_2                         enum InstrumentPatch
        ; MIDI patch    41 - 48 = Strings
        IP_VIOLIN                               enum InstrumentPatch
        IP_VIOLA                                enum InstrumentPatch
        IP_CELLO                                enum InstrumentPatch
        IP_CONTRABASS                           enum InstrumentPatch
        IP_TREMELO_STRINGS                      enum InstrumentPatch
        IP_PIZZICATO_STRINGS                    enum InstrumentPatch
        IP_ORCHESTRAL_HARP                      enum InstrumentPatch
        IP_TIMPANI                              enum InstrumentPatch
        ; MIDI patch    49 - 56 = Ensemble
        IP_STRING_ENSEMBLE_1                    enum InstrumentPatch
        IP_STRING_ENSEMBLE_2                    enum InstrumentPatch
        IP_SYNTH_STRINGS_1                      enum InstrumentPatch
        IP_SYNTH_STRINGS_2                      enum InstrumentPatch
        IP_CHIOR_AAHS                           enum InstrumentPatch
        IP_VOICE_OOHS                           enum InstrumentPatch
        IP_SYNTH_VOICE                          enum InstrumentPatch
        IP_ORCHESTRA_HIT                        enum InstrumentPatch
        ; MIDI patch    57 - 64 = Brass
        IP_TRUMPET                              enum InstrumentPatch
        IP_TROMBONE                             enum InstrumentPatch
        IP_TUBA                                 enum InstrumentPatch
        IP_MUTED_TRUMPET                        enum InstrumentPatch
        IP_FRENCH_HORN                          enum InstrumentPatch
        IP_BRASS_SECTION                        enum InstrumentPatch
        IP_SYNTH_BRASS_1                        enum InstrumentPatch
        IP_SYNTH_BRASS_2                        enum InstrumentPatch
        ; MIDI patch    65 - 72 = Reed
        IP_SOPRANO_SAX                          enum InstrumentPatch
        IP_ALTO_SAX                             enum InstrumentPatch
        IP_TENOR_SAX                            enum InstrumentPatch
        IP_BARITONE_SAX                         enum InstrumentPatch
        IP_OBOE                                 enum InstrumentPatch
        IP_ENGLISH_HORN                         enum InstrumentPatch
        IP_BASSOON                              enum InstrumentPatch
        IP_CLARINET                             enum InstrumentPatch
        ; MIDI patch    73 - 80 = Pipe
        IP_PICCOLO                              enum InstrumentPatch
        IP_FLUTE                                enum InstrumentPatch
        IP_RECORDER                             enum InstrumentPatch
        IP_PAN_FLUTE                            enum InstrumentPatch
        IP_BLOWN_BOTTLE                         enum InstrumentPatch
        IP_SHAKUHACHI                           enum InstrumentPatch
        IP_WHISTLE                              enum InstrumentPatch
        IP_OCARINA                              enum InstrumentPatch
        ; MIDI patch    81 - 88 = Synth Lead
        IP_LEAD_SQUARE                          enum InstrumentPatch
        IP_LEAD_SAWTOOTH                        enum InstrumentPatch
        IP_LEAD_CALLIOPE                        enum InstrumentPatch
        IP_LEAD_CHIFF                           enum InstrumentPatch
        IP_LEAD_CHARANG                         enum InstrumentPatch
        IP_LEAD_VOICE                           enum InstrumentPatch
        IP_LEAD_FIFTHS                          enum InstrumentPatch
        IP_LEAD_BASS_LEAD                       enum InstrumentPatch
        ; MIDI patch    89 - 96 = Synth Pad
        IP_PAD_NEW_AGE                          enum InstrumentPatch
        IP_PAD_WARM                             enum InstrumentPatch
        IP_PAD_POLYSYNTH                        enum InstrumentPatch
        IP_PAD_CHOIR                            enum InstrumentPatch
        IP_PAD_BOWED                            enum InstrumentPatch
        IP_PAD_METALLIC                         enum InstrumentPatch
        IP_PAD_HALO                             enum InstrumentPatch
        IP_PAD_SWEEP                            enum InstrumentPatch
        ; MIDI patch    97 - 104 = Synth Effects
        IP_FX_RAIN                              enum InstrumentPatch
        IP_FX_SOUNDTRACK                        enum InstrumentPatch
        IP_FX_CRYSTAL                           enum InstrumentPatch
        IP_FX_ATMOSPHERE                        enum InstrumentPatch
        IP_FX_BRIGHTNESS                        enum InstrumentPatch
        IP_FX_GOBLINS                           enum InstrumentPatch
        IP_FX_ECHOES                            enum InstrumentPatch
        IP_FX_SCI_FI                            enum InstrumentPatch
        ; MIDI patch    105 - 112 = Ethnic
        IP_SITAR                                enum InstrumentPatch
        IP_BANJO                                enum InstrumentPatch
        IP_SHAMISEN                             enum InstrumentPatch
        IP_KOTO                                 enum InstrumentPatch
        IP_KALIMBA                              enum InstrumentPatch
        IP_BAG_PIPE                             enum InstrumentPatch
        IP_FIDDLE                               enum InstrumentPatch
        IP_SHANAI                               enum InstrumentPatch
        ; MIDI patch    113 - 120 = Percussive
        IP_TINKLE_BELL                          enum InstrumentPatch
        IP_AGOGO                                enum InstrumentPatch
        IP_STEEL_DRUMS                          enum InstrumentPatch
        IP_WOODBLOCK                            enum InstrumentPatch
        IP_TAIKO_DRUM                           enum InstrumentPatch
        IP_MELODIC_TOM                          enum InstrumentPatch
        IP_SYNTH_DRUM                           enum InstrumentPatch
        IP_REVERSE_CYMBAL                       enum InstrumentPatch
        ; MIDI patch    132 - 128 = SoundEffects
        IP_GUITAR_FRET_NOISE                    enum InstrumentPatch
        IP_BREATH_NOISE                         enum InstrumentPatch
        IP_SEASHORE                             enum InstrumentPatch
        IP_BIRD_TWEET                           enum InstrumentPatch
        IP_TELEPHONE_RING                       enum InstrumentPatch
        IP_HELICOPTER                           enum InstrumentPatch
        IP_APPLAUSE                             enum InstrumentPatch
        IP_GUNSHOT                              enum InstrumentPatch
        ; MIDI Percussion Map (Channel 10)
        ; Keys 35 - 42
        IP_ACOUSTIC_BASS_DRUM                   enum InstrumentPatch
        IP_BASS_DRUM_1                          enum InstrumentPatch
        IP_SIDE_STICK                           enum InstrumentPatch
        IP_ACOUSTIC_SNARE                       enum InstrumentPatch
        IP_HAND_CLAP                            enum InstrumentPatch
        IP_ELECTRIC_SNARE                       enum InstrumentPatch
        IP_LOW_FLOOR_TOM                        enum InstrumentPatch
        IP_CLOSED_HI_HAT                        enum InstrumentPatch
        ; Keys 43 - 50
        IP_HIGH_FLOOR_TOM                       enum InstrumentPatch
        IP_PEDAL_HI_HAT                         enum InstrumentPatch
        IP_LOW_TOM                              enum InstrumentPatch
        IP_OPEN_HI_HAT                          enum InstrumentPatch
        IP_LOW_MID_TOM                          enum InstrumentPatch
        IP_HI_MID_TOM                           enum InstrumentPatch
        IP_CRASH_CYMBAL_1                       enum InstrumentPatch
        IP_HIGH_TOM                             enum InstrumentPatch
        ; Keys 51 - 58
        IP_RIDE_CYMBAL_1                        enum InstrumentPatch
        IP_CHINESE_CYMBAL                       enum InstrumentPatch
        IP_RIDE_BELL                            enum InstrumentPatch
        IP_TAMBOURINE                           enum InstrumentPatch
        IP_SPLASH_CYMBAL                        enum InstrumentPatch
        IP_COWBELL                              enum InstrumentPatch
        IP_CRASH_CYMBAL_2                       enum InstrumentPatch
        IP_VIBRASLAP                            enum InstrumentPatch
        ; Keys 59-66
        IP_RIDE_CYMBAL_2                        enum InstrumentPatch
        IP_HI_BONGO                             enum InstrumentPatch
        IP_LOW_BONGO                            enum InstrumentPatch
        IP_MUTE_HI_CONGA                        enum InstrumentPatch
        IP_OPEN_HI_CONGA                        enum InstrumentPatch
        IP_LOW_CONGA                            enum InstrumentPatch
        IP_HI_TIMBALE                           enum InstrumentPatch
        IP_LOW_TIMBALE                          enum InstrumentPatch
        ; Keys 67 - 74
        IP_HIGH_AGOGO                           enum InstrumentPatch
        IP_LOW_AGOGO                            enum InstrumentPatch
        IP_CABASA                               enum InstrumentPatch
        IP_MARACAS                              enum InstrumentPatch
        IP_SHORT_WHISTLE                        enum InstrumentPatch
        IP_LONG_WHISTLE                         enum InstrumentPatch
        IP_SHORT_GUIRO                          enum InstrumentPatch
        IP_LONG_GUIRO                           enum InstrumentPatch
        ; Keys 75 - 81
        IP_CLAVES                               enum InstrumentPatch
        IP_HI_WOOD_BLOCK                        enum InstrumentPatch
        IP_LOW_WOOD_BLOCK                       enum InstrumentPatch
        IP_MUTE_CUICA                           enum InstrumentPatch
        IP_OPEN_CUICA                           enum InstrumentPatch
        IP_MUTE_TRIANGLE                        enum InstrumentPatch
        IP_OPEN_TRIANGLE                        enum InstrumentPatch

**Library:** sound.def

----------
#### InteractionCommand
    InteractionCommand      etype word
        IC_NULL                     enum InteractionCommand
        IC_DISMISS                  enum InteractionCommand
        IC_INTERACTION_COMPLETE     enum InteractionCommand
        IC_APPLY                    enum InteractionCommand
        IC_RESET                    enum InteractionCommand
        IC_OK                       enum InteractionCommand
        IC_YES                      enum InteractionCommand
        IC_NO                       enum InteractionCommand
        IC_STOP                     enum InteractionCommand
        IC_EXIT                     enum InteractionCommand
        IC_HELP                     enum InteractionCommand

IC_NULL  
Special interaction command for use with **UserDoDialog** and 
**UserStandardDialog**, et. al. When returned as the dialog 
response, this indicates that the interaction was terminated by 
the system (for example, the system shut down while the box 
was on-screen). This should not be sent with 
MSG_GEN_INTERACTION_ACTIVATE_COMMAND or 
MSG_GEN_GUP_INTERACTION_COMMAND.

IC_DISMISS  
Dismisses interaction, making it non-visible. Will always cause 
window to come down, even overriding the user's preference, 
such as having pinned the window. 

IC_INTERACTION_COMPLETE  
Notification to the GenInteraction that the user has completed 
one interaction. The specific UI must then decide whether the 
interaction should stay around to allow the user multiple 
interactions, or whether it should come down. 
Motif will dismiss the interaction if it is modal, or if 
HINT_INTERACTION_SINGLE_USAGE is set. 
OPEN LOOK dismisses unpinned interactions.This command is 
automatically sent as a side effect to the interaction, via 
MSG_GEN_GUP_INTERACTION_COMMAND, when a trigger 
with GA_SIGNAL_INTERACTION_COMPLETE set is activated 
and doesn't send another 
MSG_GEN_GUP_INTERACTION_COMMAND as a result of being 
activated. Has no effect if the interaction has already been 
dismissed. This command is special in that a button may not be 
created for the sole purpose of activating this command. 
Because of this, IC_INTERACTION_COMPLETE may not be used 
with ATTR_GEN_TRIGGER_INTERACTION_COMMAND or 
MSG_GEN_INTERACTION_ACTIVATE_COMMAND. It can be 
used with MSG_GEN_GUP_INTERACTION_COMMAND.

IC_APPLY  
Standard response for GIT_PROPERTIES. Applies properties. 
Causes MSG_GEN_APPLY to be sent to the UI gadgets under 
the GenInteraction.

IC_RESET  
Standard response for GIT_PROPERTIES. Resets properties. 
Causes MSG_GEN_RESET to be sent to the UI gadgets under 
the GenInteraction. 

IC_OK  
Standard response for GIT_NOTIFICATION.

IC_YES  
Standard response for GIT_AFFIRMATION.

IC_NO  
Standard response for GIT_AFFIRMATION.

IC_STOP  
Standard response for GIT_PROGRESS.

IC_EXIT  
Special interaction command used to indicate that this 
GenTrigger exits the application. Motif has an "Exit" item in the 
"File" menu. This should only be used with 
ATTR_GEN_TRIGGER_INTERACTION_COMMAND, not with 
MSG_GEN_GUP_INTERACTION_COMMAND or 
MSG_GEN_INTERACTION_ACTIVATE_COMMAND. It is only 
supported for GenTriggers under GIV_POPUP GenInteractions.

IC_HELP  
Special interaction command used to indicate that this 
GenTrigger brings up help. This should only be used with 
ATTR_GEN_TRIGGER_INTERACTION_COMMAND.

**Library:** Objects/gInterC.def

**Library:** netware.def

----------
#### JCFeatures
    JCFeatures      record
        JCF_LEFT        :1
        JCF_RIGHT       :1
        JCF_CENTER      :1
        JCF_FULL        :1
    JCFeatures      end

**Library:** Objects/Text/tCtclC.def

----------
#### JCToolboxFeatures
    JCToolboxFeatures       record
        JCTF_LEFT       :1
        JCTF_RIGHT      :1
        JCTF_CENTER     :1
        JCTF_FULL       :1
    JCToolboxFeatures       end

**Library:** Objects/Text/tCtrlC.def

----------
#### JobStatus
    JobStatus       struct
        ; DO NOT CHANGE THE ORDER OF THESE FIRST FOUR ITEMS
        JS_fname            char 13 dup (?)
        JS_parent           char FILE_LONGNAME_LENGTH+1 dup (?)
        JS_documentName     char FILE_LONGNAME_LENGTH+1 dup (?)
        JS_numPages         word
        JS_time             SpoolTimeStruct <>
        JS_printing         byte
    JobStatus       ends

This structure is returned by the **SpoolJobsInfo** library call. 

*JS_fname* stores the standard DOS (8.3) spool filename.

*JS_parent* stores the parent application's name.

*JS_documentName* stores the document name.

*JS_numPages* stores the number of pages in the document.

*JS_time* stores the time spooled.

*JS_printing* stores the status of printing in progress. (TRUE if we are 
printing.)

**Library:** spool.def

----------
#### Justification
    Justification       etype byte
        J_LEFT              enum Justification
        J_RIGHT             enum Justification
        J_CENTER            enum Justification
        J_FULL              enum Justification

**Library:** graphics.def

----------
#### KbdGrab
    KbdGrab     struct
        KG_OD           optr
        KG_unused       word
    KbdGrab     ends

**Library:** Objects/uiInputC.def

----------
#### KbdReturnFlags
    KbdReturnFlags      record
        KRF_PREVENT_PASS_THROUGH        :1
        KRF_UNUSED                      :15
    KbdReturnFlags      end

**Library:** uiInputC.def

----------
#### KeyboardOverride
    KeyboardOverride        etype       word
        KO_NO_KEYBOARD              enum    KeyboardOverride
        KO_KEYBOARD_REQUIRED        enum    KeyboardOverride
        KO_KEYBOARD_EMBEDDED        enum    KeyboardOverride

KO_NO_KEYBOARD  
This forces the window to act as if none of the child objects 
accept text input - no floating keyboard will be made available.

KO_KEYBOARD_REQUIRED  
This forces the window to act as if a child object required text 
input, so a floating keyboard will be brought on screen.

KO_KEYBOARD_EMBEDDED  
If this is present, it means that the application is providing an 
keyboard directly inside the box - no floating keyboard is 
needed.

**Library:** genC.def

----------
#### KeyboardShortcut
    KeyboardShortcut        record
        KS_PHYSICAL     :1          ;TRUE: match key, not character
        KS_ALT          :1          ;TRUE: <ALT> must be pressed
        KS_CTRL         :1          ;TRUE: <CTRL> must be pressed
        KS_SHIFT        :1          ;TRUE: <SHIFT> must be pressed
        KS_CHAR         Chars:12    ;character itself (Char or VChar)
    KeyboardShortcut        end

**Library:** input.def

----------
#### KeyboardType
    KeyboardType            etype byte, 1, 1
        KT_NOT_EXTD     enum KeyboardType       ;84-key PC/AT
        KT_EXTD         enum KeyboardType       ;102-key PC/AT, PS/2
        KT_BOTH         enum KeyboardType       ;does both (U.S. only)

**Library:** localize.def

----------
#### KeyMapType
    KeyMapType      etype word, 1, 1
        KEYMAP_US_EXTD              enum KeyMapType
        KEYMAP_US                   enum KeyMapType
        KEYMAP_UK_EXTD              enum KeyMapType
        KEYMAP_UK                   enum KeyMapType
        KEYMAP_GERMANY_EXTD         enum KeyMapType
        KEYMAP_GERMANY              enum KeyMapType
        KEYMAP_SPAIN_EXTD           enum KeyMapType
        KEYMAP_SPAIN                enum KeyMapType
        KEYMAP_DENMARK_EXTD         enum KeyMapType
        KEYMAP_DENMARK              enum KeyMapType
        KEYMAP_BELGIUM_EXTD         enum KeyMapType
        KEYMAP_BELGIUM              enum KeyMapType
        KEYMAP_CANADA_EXTD          enum KeyMapType
        KEYMAP_CANADA               enum KeyMapType
        KEYMAP_ITALY_EXTD           enum KeyMapType
        KEYMAP_ITALY                enum KeyMapType
        KEYMAP_LATIN_AMERICA_EXTD   enum KeyMapType
        KEYMAP_LATIN_AMERICA        enum KeyMapType
        KEYMAP_NETHERLANDS          enum KeyMapType
        KEYMAP_NETHERLANDS_EXTD     enum KeyMapType
        KEYMAP_NORWAY_EXTD          enum KeyMapType
        KEYMAP_NORWAY               enum KeyMapType
        KEYMAP_PORTUGAL_EXTD        enum KeyMapType
        KEYMAP_PORTUGAL             enum KeyMapType
        KEYMAP_SWEDEN_EXTD          enum KeyMapType
        KEYMAP_SWEDEN               enum KeyMapType
        KEYMAP_SWISS_FRENCH_EXTD    enum KeyMapType
        KEYMAP_SWISS_FRENCH         enum KeyMapType
        KEYMAP_SWISS_GERMAN_EXTD    enum KeyMapType
        KEYMAP_SWISS_GERMAN         enum KeyMapType
        KEYMAP_FRANCE_EXTD          enum KeyMapType
        KEYMAP_FRANCE               enum KeyMapType

**Library:** localize.def

----------
#### LanguageDialect
    LanguageDialect     record
                            :8
        LD_DEFAULT          :1
        LD_ISE_BRITISH      :1
        LD_IZE_BRITISH      :1
        LD_AUSTRALIAN       :1
        LD_FINANCIAL        :1
        LD_LEGAL            :1
        LD_MEDICAL          :1
        LD_SCIENCE          :1
    LanguageDialect     end

**Library:** sllang.def

----------
#### LargeMouseData
    LargeMouseData      struct
        ; LMD_location must be first entry
        LMD_location                PointDWFixed
        LMD_buttonInfo              byte
        LMD_uiFunctionsActive       UIFunctionsActive
    LargeMouseData      ends

*LMD_location* stores the mouse position in <32 bit integer>.<16 bit fraction> 
format.

*LMD_buttonInfo* stores **ButtonInfo**.

*LMD_uiFunctionsActive* stores additional data normally passed as part of 
mouse event in **bp**. The data normally provided by the bit UIFA_IN is not 
provided by GEOS for LARGE mouse events. The reason for this is that with 
small mouse events, **VisCallChildUnderPoint** can lock down each child, 
look at its bounds, & set UIFA_IN correctly. This is not possible with large 
objects, as the bounds information, if at all existent, is private to that object 
& not known by the Vis library. The bit will be unchanged from the state it 
holds going into the VisContentClass handler for the mouse event.

**Library:** Objects/uiInput.def

----------
#### LASCFeatures
    LASCFeatures        record
        LASCF_SINGLE                :1
        LASCF_ONE_AND_A_HALF        :1
        LASCF_DOUBLE                :1
        LASCF_TRIPLE                :1
        LASCF_CUSTOM                :1
    LASCFeatures        end

**Library:** Objects/Text/tCtrlC.def

----------
#### LASCToolboxFeatures
    LASCToolboxFeatures         record
        LASCTF_SINGLE               :1
        LASCTF_ONE_AND_A_HALF       :1
        LASCTF_DOUBLE               :1
        LASCTF_TRIPLE               :1
    LASCToolboxFeatures         end

**Library:** Objects/Text/tCtrlC.def

----------
#### LayerPriority
    LayerPriority       etype byte
        LAYER_PRIO_MODAL        enum LayerPriority, 6   ; For system-modal dialog 
                                                        ; boxes, when layer is on 
                                                        ; screen
        LAYER_PRIO_ON_TOP       enum LayerPriority, 8   ; For "screen-floating" 
                                                        ; boxes
        LAYER_PRIO_STD          enum LayerPriority, 12  ; Standard layer priority
        LAYER_PRIO_ON_BOTTOM    enum LayerPriority, 14  ; Window stays on bottom

**Library:** win.def

----------
#### LibraryCallType
    LibraryCallType     etype word
        LCT_ATTACH                  enum LibraryCallType
        LCT_DETACH                  enum LibraryCallType
        LCT_NEW_CLIENT              enum LibraryCallType
        LCT_NEW_CLIENT_THREAD       enum LibraryCallType
        LCT_CLIENT_THREAD_EXIT      enum LibraryCallType
        LCT_CLIENT_EXIT             enum LibraryCallType

**Library:** library.def

----------
#### LineAttr
    LineAttr        struct
        LA_colorFlag    ColorFlag CF_INDEX  ; RGB or INDEX
        LA_color        RGBValue <0,0,0>    ; RGB values or index
        LA_mask         SystemDrawMask      ; draw mask
        LA_mapMode      ColorMapMode        ; color map mode
        LA_end          LineEnd             ; end type
        LA_join         LineJoin            ; join type
        LA_style        LineStyle           ; style type
        LA_width        WWFixed             ; line width
    LineAttr        ends

This structure is used with **GrSetLineAttr**.

**Library:** graphics.def

----------
#### LineEnd
    LineEnd etype byte
        LE_BUTTCAP          enum LineEnd        ; but cap
        LE_ROUNDCAP         enum LineEnd        ; round cap
        LE_SQUARECAP        enum LineEnd        ; square cap

**Library:** graphics.def

----------
#### LineFlags
    LineFlags       record
        LF_STARTS_PARAGRAPH             :1
        LF_ENDS_PARAGRAPH               :1
        LF_ENDS_IN_CR                   :1
        LF_ENDS_IN_COLUMN_BREAK         :1
        LF_ENDS_IN_SECTION_BREAK        :1
        LF_ENDS_IN_NULL                 :1
        LF_NEEDS_DRAW                   :1
        LF_NEEDS_CALC                   :1
        LF_ENDS_IN_AUTO_HYPHEN          :1
        LF_ENDS_IN_OPTIONAL_HYPHEN      :1
        LF_INTERACTS_ABOVE              :1
        LF_INTERACTS_BELOW              :1
        LF_LAST_CHAR_EXTENDS_RIGHT      :1
        LF_LAST_CHAR_KERNED             :1
        LF_CONTAINS_EXTENDED_STYLE      :1
                                        :1
    LineFlags       end

LF_STARTS_PARAGRAPH  
Set if line starts a paragraph.

LF_ENDS_PARAGRAPH  
Set if line ends a paragraph. 

LF_ENDS_IN_CR  
Set if field ends in CR.

LF_ENDS_IN_COLUMN_BREAK  
Set if line ends in a column break.

LF_ENDS_IN_SECTION_BREAK  
Set if line ends in a section break.

LF_ENDS_IN_NULL  
Set if line ends in NULL, last one in document.

LF_NEEDS_DRAW  
Set if line needs redrawing.

LF_NEEDS_CALC  
Set if line needs calculating.

LF_ENDS_IN_AUTO_HYPHEN  
Set if line ends in a generated hyphen.

LF_ENDS_IN_OPTIONAL_HYPHEN  
Set if line ends in an optional hyphen.

Sometimes characters in a line will extend outside the top and bottom bounds 
of the line. We mark these lines with these bits. 

LF_INTERACTS_ABOVE  
Set if line interacts with line above it.

LF_INTERACTS_BELOW  
Set if line interacts with line below it.

When doing an optimized redraw of a line we draw the last field in the line if 
the field got longer. If the field got shorter we just clear from beyond the right 
edge of the field. There are a few situations where we can't really do this:

 - Current last character on line extended to the right of its font box. (Italic 
characters are a good example of this).

 - The last character on the line was negatively kerned before we made the 
modification and is that is no longer the case (this character was 
removed).

We flag these two cases separately.

LF_LAST_CHAR_EXTENDS_RIGHT  
Set if the last character on the line extends to the right of its 
font box. 

LF_LAST_CHAR_KERNED  
Set if the last character on the line is kerned. The only time we 
use this is to copy it into the next field.

Set by the application if the line contains styles which are not supported 
directly by the kernel. This allows applications to optimize line redraw by 
skipping over code which may attempt to draw attributes which don't exist 
for the line. 

LF_CONTAINS_EXTENDED_STYLE  
Set if the line contains a non-kernel supported style.

**Library:** text.def

----------
#### LineInfo
    LineInfo        struct
        LI_flags            LineFlags
        LI_hgt              WBFixed
        LI_blo              WBFixed
        LI_adjustment       word
        LI_count            WordAndAHalf
        LI_spacePad         WBFixed
        LI_lineEnd          word
        LI_firstField       FieldInfo
    LineInfo        ends

*LI_flags* stores miscellaneous line flags.

*LI_hgt* stores the height of the line (in points).

*LI_blo* stores the baseline offset (in points).

*LI_adjustment* stores the adjustment for justification.

*LI_count* stores the number of characters in the line. This is the sum of the 
field counts.

*LI_spacePad* stores the amount to pad last field to get full justification.

*LI_lineEnd* stores the rounded end-of-line position which indicates the end of 
the last non-white-space character.

*LI_firstField* stores the first field of the line. (At least one field is always 
present.)

**Library:** text.def

----------
#### LineJoin
    LineJoin        etype byte
        LJ_MITERED              enum LineJoin       ; miter join
        LJ_ROUND                enum LineJoin       ; round join
        LJ_BEVELED              enum LineJoin       ; beveled join

        LAST_LINE_JOIN_TYPE     = LJ_BEVELED

**Library:** graphics.def

----------
#### LineStyle
    LineStyle       etype byte
        LS_SOLID        enum LineStyle      ; ___________   (solid)
        LS_DASHED       enum LineStyle      ; _ _ _ _ _ _   (dashed)
        LS_DOTTED       enum LineStyle      ; . . . . . .   (dotted)
        LS_DASHDOT      enum LineStyle      ; _ . _ . _ .   (dash-dot)
        LS_DASHDDOT     enum LineStyle      ; _ . . _ . .   (dash-double-dot)
    LS_CUSTOM       enum LineStyle

**Library:** graphics.def

----------
#### LinkPart
    LinkPart        struct
        LP_next         optr
    LinkPart        ends

The low bit of the optr is clear to indicate a sibling optr; this bit is set to 
indicate that the optr links a parent. (If 0, then object is not in a composite.)

**Library:** Objects/metaC.def

----------
#### LMemBlockHeader
    LMemBlockHeader     struct
        LMBH_handle         hptr
        LMBH_offset         nptr.word
        LMBH_flags          LocalMemoryFlags <>
        LMBH_lmemType       LMemType LMEM_TYPE_GENERAL
        LMBH_blockSize      word
        LMBH_nHandles       word
        LMBH_freeList       lptr
        LMBH_totalFree      word
    LMemBlockHeader     ends

This structure is found at the beginning of every block which contains an 
LMem heap. You can examine any of the fields (after having locked the block) 
but you should not change any of these fields yourself; they are managed by 
the LMem routines.

*LMBH_handle* stores the handle of this block.

*LMBH_offset* stores the offset from the beginning of the block to the beginning 
of the heap.

*LMBH_flags* stores the **LocalMemoryFlags** which describe the state of the 
local memory block.

*LMBH_lmemType* stores the type of LMem heap in use in this block.

*LMBH_blockSize* stores the total size of the block. This size may change in 
either direction as a result of chunk allocation and heap compaction.

*LMBH_nHandles* stores the number of handles available in the chunk handle 
table. Not all of these chunks are necessarily allocated as owned or free 
chunks. The table grows automatically when necessary.

*LMBH_freeList* stores the chunk handle of the first free chunk in the linked 
list of free chunks.

*LMBH_totalFree* stores the total amount of free space in the LMem heap.

**Library:** lmem.def

----------
#### LMemType
    LMemType        etype word
        LMEM_TYPE_GENERAL               enum LMemType
        LMEM_TYPE_WINDOW                enum LMemType
        LMEM_TYPE_OBJ_BLOCK             enum LMemType
        LMEM_TYPE_GSTATE                enum LMemType
        LMEM_TYPE_FONT_BLK              enum LMemType
        LMEM_TYPE_GSTRING               enum LMemType
        LMEM_TYPE_DB_ITEMS              enum LMemType

**Library:** lmem.def

----------
#### LocalCmpStringsDosToGeosFlags
    LocalCmpStringsDosToGeosFlags               record
                                            :6
        LCSDTG_NO_CONVERT_STRING_2          :1
        LCSDTGF_NO_CONVERT_STRING_1         :1
    LocalCmpStringsDosToGeosFlags               end

**Library:** localize.def

----------
#### LocalDistanceFlags
    LocalDistanceFlags      record
        LDF_FULL_NAMES              :1
        LDF_PRINT_PLURAL_IF_NEEDED  :1
                                    :10
        LDF_PASSING_DECIMAL_PLACES  :1      ; Internal
        LDF_DECIMAL_PLACES          :1      ; Internal
    LocalDistanceFlags      end

**Library:** localize.def

----------
#### LocalMemoryFlags
    LocalMemoryFlags        record
        LMF_HAS_FLAGS       :1      ;True if block has a flags block
        LMF_IN_RESOURCE     :1      ;True if block is just loaded from resource
        LMF_DETACHABLE      :1      ;True if block is detachable
        LMF_DUPLICATED      :1      ;True if block created by 
                                    ;ObjDuplicateResource
        LMF_RELOCATED       :1      ;True if block is being relocated
        LMF_AUTO_FREE       :1      ;Indicates that block may be freed when 
                                    ;in-use count hits 0.
        LMF_IN_LMEM_ALLOC   :1      ;EC ONLY -- In the middle of an LMemAlloc,
                                    ; do not try to do a ECLMemValidateHeap.
                                    ;INTERNAL FLAG -- DO NOT MODIFY
        LMF_IS_VM           :1      ;True if block is stored in VM file and 
                                    ;should be marked dirty whenever a chunk 
                                    ; is marked dirty.
        LMF_NO_HANDLES      :1      ;Block does not have handles (malloc like)
        LMF_NO_ENLARGE      :1      ;Do not enlarge block to try to alloc
        LMF_RETURN_ERRORS   :1      ;Return errors when allocation impossible
                            :1
                            :1
        LMF_DEATH_COUNT     :3      ;Means nothing if 0, else is # of death
                                    ;methods left which must hit
                                    ;BlockDeathCommon before it will destroy
                                    ;the block. Used by MSG_FREE_DUPLICATE &
                                    ;MSG_REMOVE_BLOCK
    LocalMemoryFlags        end

**Library:** lmem.def

----------
#### MakeRectVisibleFlags
    MakeRectVisibleFlags            record
                                            :8
        MRVF_ALWAYS_SCROLL                  :1
        MRVF_USE_MARGIN_FROM_TOP_LEFT       :1
                                            :6
    MakeRectVisibleFlags            end

MRVF_ALWAYS_SCROLL  
Set if we always want to do the scrolling, even if the object is already partly 
onscreen. Mostly only useful if an object is already barely onscreen and we 
want to center it.

MRVF_USE_MARGIN_FROM_TOP_LEFT  
Ignore current placement of the object; margins are always calculated from 
the top or left edge of the view, regardless of the original position of the 
rectangle.

**Library:** Objects/gViewC.def

----------
#### MakeRectVisibleMargin
    MakeRectVisibleMargin           etype word
        MRVM_0_PERCENT      enum MakeRectVisibleMargin, 0
        MRVM_25_PERCENT     enum MakeRectVisibleMargin, 0ffffh/4
        MRVM_50_PERCENT     enum MakeRectVisibleMargin, 0ffffh/2
        MRVM_75_PERCENT     enum MakeRectVisibleMargin, 0ffffh*3/4
        MRVM_100_PERCENT    enum MakeRectVisibleMargin, 0ffffh

How far to bring the rectangle onscreen. See comments for each constant. If 
you need to get more a precise percentage, multiply your percentage by 0ffffh 
and use that rather than one of these constants.

MRVM_0_PERCENT  
Scroll the view just far enough to get the rectangle barely 
onscreen. If the rectangle is larger than the view, brings as 
much as possible onscreen. If 
MRVF_USE_MARGIN_FROM_TOP_LEFT is set, always 
brings the object to the top or left edge of the screen.

MRVM_25_PERCENT

MRVM_50_PERCENT  
Centers the object onscreen.

MRVM_75_PERCENT

MRVM_100_PERCENT  
Scrolls the rectangle all the way to the opposite edge of the 
screen from whence it came. Probably only useful if always 
using margin from top left, in order to bring something to the 
bottom edge of the screen.

**Library:** Objects/gViewC.def

----------
#### MakeRectVisibleParams
    MakeRectVisibleParams           struct
        MRVP_bounds         RectDWord
        MRVP_xMargin        MakeRectVisibleMargin
        MRVP_xFlags         MakeRectVisibleFlags
        MRVP_yMargin        MakeRectVisibleMArgin
        MRVP_yFlags         MakeRectVisibleFlags
    MakeRectVisibleParams           ends

*MRVP_bounds* stores the bounds of the **Rectangle** to make visible. (This 
rectangle must be less than 65535 points high or wide.)

*MRVP_xMargin* stores how far to bring the Rectangle on screen.

**Library:** Objects/gViewC.def

----------
#### ManufacturerID
    ManufacturerID      etype word
        MANUFACTURER_ID_GEOWORKS        enum ManufacturerID

**Library:** geode.def

----------
#### MapListBlockHeader
    MapListBlockHeader      struct
        MLBH_base               LMemBlockHeader
        MLBH_numDestFields      word
        MLBH_chunk1             word
    MapListBlockHeader      ends

**Library:** impex.def

----------
#### MCFeatures
    MCFeatures      record
        MCF_LEFT_MARGIN             :1
        MCF_PARA_MARGIN             :1
        MCF_RIGHT_MARGIN            :1
    MCFeatures      end

**Library:** Objects/Text/tCtrlC.def

----------
#### MCToolboxFeatures
    MCToolboxFeatures       record
    MCToolboxFeatures       end

**Library:** Objects/Text/tCtrlC.def

----------
#### MeasurementType
    MeasurementType     etype byte
        MEASURE_US              enum MeasurementType
        MEASURE_METRIC          enum MeasurementType

**Library:** localize.def

----------
#### MediaType
    MediaType       etype byte, 0
        MEDIA_NONEXISTENT       enum MediaType  ; used as error value
        MEDIA_160K              enum MediaType
        MEDIA_180K              enum MediaType
        MEDIA_320K              enum MediaType
        MEDIA_360K              enum MediaType
        MEDIA_720K              enum MediaType
        MEDIA_1M2               enum MediaType
        MEDIA_1M44              enum MediaType
        MEDIA_2M88              enum MediaType
        MEDIA_FIXED_DISK        enum MediaType
        MEDIA_CUSTOM            enum MediaType
        MEDIA_SRAM              enum MediaType
        MEDIA_ATA               enum MediaType
        MEDIA_FLASH             enum MediaType

**Library:** drive.def

----------
#### MemGetInfoType
    MemGetInfoType      etype word, 0, 2
        MGIT_SIZE                       enum MemGetInfoType
        MGIT_FLAGS_AND_LOCK_COUNT       enum MemGetInfoType
        MGIT_OWNER_OR_VM_FILE_HANDLE    enum MemGetInfoType
        MGIT_ADDRESS                    enum MemGetInfoType
        MGIT_OTHER_INFO                 enum MemGetInfoType
        MGIT_EXEC_THREAD                enum MemGetInfoType

**Library:** heap.def

----------
#### MenuSepFlags
    MenuSepFlags        record
        MSF_SEP             :1
        MSF_USABLE          :1
        MSF_FROM_CHILD      :1
                            :5
    MenuSepFlags        end

MSF_SEP  
When recursing to lower objects in the menu, this is set when 
there is at least one usable object between this object and the 
separator drawn above it. When un-recursing (moving up the 
menu), this is set when there is at least one usable object 
between this object and the separator drawn below it.

MSF_USABLE  
When recursing to lower objects in the menu, this is set when 
an object has at least one previous sibling which is 
GS_USABLE.

MSF_FROM_CHILD  
Set when message is sent from a child to its visible parent, so 
the parent can distinguish from the case where it is called from 
its previous sibling or parent.

**Library:** Objects/visC.def

----------
#### MessageError
    MessageError        etype word
        MESSAGE_NO_ERROR        enum MessageError
        MESSAGE_NO_HANDLES      enum MessageError   ; short on handles and
                                                    ; MF_CAN_DISCARD_IF_DESPERATE
                                                    ; was passed

**Library:** object.def

----------
#### MessageFlags
    MessageFlags        record
        MF_CALL                     :1
        MF_FORCE_QUEUE              :1
        MF_STACK                    :1
                                    :1
        MF_CHECK_DUPLICATE          :1
        MF_CHECK_LAST_ONLY          :1
        MF_REPLACE                  :1
        MF_CUSTOM                   :1
        MF_FIXUP_DS                 :1
        MF_FIXUP_ES                 :1
        MF_DISCARD_IF_NO_MATCH      :1
        MF_MATCH_ALL                :1
        MF_INSERT_AT_FRONT          :1
        MF_CAN_DISCARD_IF_DESPERATE :1
        MF_RECORD                   :1
                                    :1
    MessageFlags        end

**Library:** object.def

----------
#### MetaAlterFTVMCExclFlags
    MetaAlterFTVMCExclFlags     record
        MAEF_NOT_HERE               :1
        MAEF_SYS_EXCL               :1
        MAEF_APP_EXCL               :1
        MAEF_GRAB                   :1
        MAEF_FOCUS                  :1
        MAEF_TARGET                 :1
        MAEF_MODEL                  :1
                                    :6
        MAEF_MODAL                  :1
        MAEF_OD_IS_WINDOW           :1
        MAEF_OD_IS_MENU_RELATED     :1
    MetaAlterFTVMCExclFlags     end

MAEF_NOT_HERE  
Overrides all other flags! Set if this request should not be 
honored here, but instead sent on up the hierarchy with this bit 
cleared. This bit exists for two reasons: 

1) So that nodes can tell the difference between messages 
coming up from objects below & those requests which it has 
made for itself, which should be handled by the next node up.

2) Thus allowing MSG_META_MUP_ALTER_FTVMC_EXCL to be 
sent to the object making the request itself, thereby allowing 
nodes the freedom to direct the message in directions other 
than the visual hierarchy, if the next node is not in that 
direction.

MAEF_SYS_EXCL  
Not passed, but this bit as stored in a HierarchicalGrab 
structure indicates whether the object has a system-wide 
exclusive. 

MAEF_APP_EXCL  
Not passed, but this bit as stored in a HierarchicalGrab 
structure indicates whether the object has an 
applications-wide exclusive.

MAEF_GRAB  
Set to force grab exclusive, clear to release it.

MAEF_FOCUS  
Set to grab/release focus.

MAEF_TARGET  
Set to grab/release target.

MAEF_MODEL  
Set to grab/release model.

MAEF_MODAL  
Meaningful for focus grab only - set if object requesting grab is 
a modal dialog, or a derivative window that happens to have 
the same focus node above it as the modal dialog (such as a 
popup menu). If this bit is clear, but the 
application/field/system etc. is in a modal state, the requesting 
object's optr will be saved away, but not granted the focus, until 
the current modal state within that focus node has been 
completed.

MAEF_OD_IS_WINDOW  
Meaningful for focus grab only-whether object is a windowed 
object or not.

MAEF_OD_IS_MENU_RELATED  
Meaningful for focus grab only-whether object is a specific UI 
menu-related object

**Library:** uiInputC.def

----------
#### MetaBase
    MetaBase        struct
        MB_class        fptr.ClassStruct        ; Instance's class
    MetaBase        ends

This base structure is defined so Esp can build on it for all other classes.

**Library:** Objects/metaC.def

----------
#### MinIncrementType
    MinIncrementType        union
        MIT_US          MinUSMeasure
        MIT_METRIC      MinMetricMeasure
        MIT_POINT       MinPointMeasure
        MIT_PICA        MinPicaMeasure
    MinIncrementType        end

**Library:** ruler.def

----------
#### MinMetricMeasure
    MinMetricMeasure        etype byte, 0
        MMM_MILLIMETER              enum    MinMetricMeasure
        MMM_HALF_CENTIMETER         enum    MinMetricMeasure
        MMM_CENTIMETER              enum    MinMetricMeasure

**Library:** 

----------
#### MinPicaMeasure
    MinPicaMeasure      etype byte, 0
        MPM_PICA            enum MinPicaMeasure
        MPM_INCH            enum MinPicaMeasure

**Library:** ruler.def

----------
#### MinPointMeasure
    MinPointMeasure     etype byte, 0
        MPM_25_POINT            enum MinPointMeasure
        MPM_50_POINT            enum MinPointMeasure
        MPM_100_POINT           enum MinPointMeasure

**Library:** ruler.def

----------
#### MinUSMeasure
    MinUSMeasure        etype byte, 0
        MUSM_EIGHTH_INCH            enum MinUSMeasure
        MUSM_QUARTER_INCH           enum MinUSMeasure
        MUSM_HALF_INCH              enum MinUSMeasure
        MUSM_ONE_INCH               enum MinUSMeasure

**Library:** ruler.def

----------
#### MixMode
    MixMode etype byte
        MM_CLEAR        enum MixMode        ; dest <- 0
        MM_COPY         enum MixMode        ; dest <- src
        MM_NOP          enum MixMode        ; dest <- dest
        MM_AND          enum MixMode        ; dest <- src AND dest
        MM_INVERT       enum MixMode        ; dest <- NOT dest
        MM_XOR          enum MixMode        ; dest <- src XOR dest
        MM_SET          enum MixMode        ; dest <- 1
        MM_OR           enum MixMode        ; dest <- src OR dest

        LAST_MIX_MODE   = MM_OR             ; last legal draw mode

**Library:** graphics.def

----------
#### MonikerGroupEntry
    MonikerGroupEntry       struct
        MGE_type        VisMonikerListEntryType
        MGE_group       word
    MonikerGroupEntry       ends

**Library:** token.def

----------
#### MonikerMessageParams
    MonikerMessageParams            struct
        MMP_xInset          word
        MMP_yInset          word
        MMP_xMaximum        word
        MMP_yMaximum        word
        MMP_gState          hptr.GState
        MMP_textHeight      word
        MMP_visMoniker      lptr.VisMoniker
        MMP_monikerFlags    DrawMonikerFlags
    MonikerMessageParams            ends

*MMP_xInset* stores the horizontal inset to the start of where to draw the 
moniker if top or bottom justifying.

*MMP_yInset* stores the vertical inset to the start of where to draw the 
moniker, if left or right justifying.

*MMP_xMaximum* and *MMP_yMaximum* store the maximum size of the 
moniker. If VMF_CLIP_TO_MAXIMUM_WIDTH is set in the 
*MMP_monikerFlags*, the moniker will be clipped to that width.

*MMP_gState* stores the gstate to use when drawing the moniker. (This gstate 
is typically passed into MSG_VIS_DRAW).

*MMP_textHeight* stores the height of the system text, which speeds up many 
moniker operations. If we happen to know the height of the system text, we 
should pass it here for speed, or else pass 0.

*MMP_visMoniker* stores the visual moniker itself. This moniker must be in 
the same block as the object.

*MMP_monikerFlags* stores justification information and miscellaneous flags 
used when drawing the moniker.

**Library:** Objects/visC.def

----------
#### MouseGrab
    MouseGrab       struct
        MG_OD           optr
        MG_gWin         hptr
    MouseGrab       ends

This structure is similar to an ordinary "grab" except it additionally stores 
the window handle that mouse data should be translated into before sending.

**Library:** Objects/uiInputC.def

----------
#### MouseReturnFlags
    MouseReturnFlags        record
        MRF_PROCESSED                   :1
        MRF_REPLAY                      :1
        MRF_PREVENT_PASS_THROUGH        :1
        MRF_SET_POINTER_IMAGE           :1
        MRF_CLEAR_POINTER_IMAGE         :1
                                        :7
        MRF_INK_RETURN_VALUE            InkReturnValue:4
    MouseReturnFlags        end

MRF_PROCESSED  
To be set by any non-window objects which have had mouse 
events passed on down to them. Used by base window to 
determine if window background was hit, as opposed to any of 
its children. This should be returned set by any object finding 
the mouse within its bounds.

MRF_REPLAY  
Will cause event to be played through implied grab if the active 
grab has gone from a valid grab to no grab, in the 
MSG_META_BUTTON routine which is returning this flag set. 
Normally used when a gadget releases the grab because the ptr 
is out of its range, & it wishes to have the event replayed to the 
implied grab. Note: in a pre passive button handler, this can be 
returned to cause the event to be re-sent to the pre-passive list.

MRF_PREVENT_PASS_THROUGH  
Set by pre-passive button routines only, if event should NOT be 
passed through to active/implied mouse grab. Any grab in the 
pre-passive list may set this bit, & the effect will occur.

MRF_SET_POINTER_IMAGE  
Causes the PIL_GADGET level cursor to be changed to cx:dx.

MRF_CLEAR_POINTER_IMAGE  
Causes the PIL_GADGET level cursor to be reset to the default.

MRF_INK_RETURN_VALUE  
This field is only filled in by handlers for 
MSG_META_QUERY_IF_PRESS_IS_INK.

**Library:** uiInputC.def

[Structures G-G](asmstrgg.md) <-- [Table of Contents](../asmref.md) &nbsp;&nbsp; --> [Structures N-R](asmstrnr.md)

