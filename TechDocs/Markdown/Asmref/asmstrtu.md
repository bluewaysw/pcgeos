## 3.7 Structures T-U

----------
#### Tab
    Tab     struct
        T_position      word            ; Position of tab (pixels * 8)
        T_attr          TabAttributes   ; Tab attributes.
        T_grayScreen    SysDrawMask     ; Gray screen for tab lines
        T_lineWidth     byte            ; Width of line before (after) tab
                                        ; 0 = none, units are pixels * 8
        T_lineSpacing   byte            ; Space between tab and line
                                        ; 0 = none, units are pixels * 8
        T_anchor        word            ; Anchor character.
    Tab     ends

**Library:** text.def

----------
#### TabAttributes
    TabAttributes           record
                        :3
        TA_LEADER       TabLeader:3
        TA_TYPE         TabType:2
    TabAttributes           end

**Library:** text.def

----------
#### TabLeader
    TabLeader           etype byte
        TL_NONE     enum TabLeader
        TL_DOT      enum TabLeader
        TL_LINE     enum TabLeader
        TL_BULLET   enum TabLeader

**Library:** text.def

----------
#### TabReference
    TabReference        record
        TR_TYPE             TabReferenceType:1  ; Type of reference.
        TR_REF_NUMBER       :7                  ; Reference number
    TabReference        end

**Library:** text.def

----------
#### TabReferenceType
    TabReferenceType        etype byte
        TRT_RULER   enum TabReferenceType   ; Reference is into the ruler.
        TRT_OTHER   enum TabReferenceType

**Library:** text.def

----------
#### TabType
    TabType etype byte
        TT_LEFT             enum TabType
        TT_CENTER           enum TabType
        TT_RIGHT            enum TabType
        TT_ANCHORED         enum TabType

**Library:** text.def

----------
#### TargetLevel
    TargetLevel     etype word
        TL_TARGET                   enum TargetLevel, 0
        TL_CONTENT                  enum TargetLevel
        TL_GENERIC_OBJECTS          enum TargetLevel, 1000
        TL_GEN_SYSTEM               enum TargetLevel
        TL_GEN_FIELD                enum TargetLevel
        TL_GEN_APPLICATION          enum TargetLevel
        TL_GEN_PRIMARY              enum TargetLevel
        TL_GEN_DISPLAY_CTRL         enum TargetLevel
        TL_GEN_DISPLAY              enum TargetLevel
        TL_GEN_VIEW                 enum TargetLevel
        ;
        ; Place PC/GEOS library extensions here 
        TL_LIBRARY_LEVELS   enum TargetLevel, 2000
        
        ; EXPORTED FOR INDIVIDUAL APPLICATIONS
        TL_APPLICATION_OBJECTS  enum TargetLevel, 3000

TL_TARGET  
Final target object. (Currently, just text objects, such as 
VisText, GenTextDisplay or GenText).

TL_CONTENT  
Content within view (generic, visual, or whatever).

TL_GENERIC_OBJECTS

TL_GEN_SYSTEM  
The system object itself.

TL_GEN_FIELD  
Field within system.

TL_GEN_APPLICATION  
Application within field.

TL_GEN_PRIMARY  
Primary within application.

TL_GEN_DISPLAY_CTRL  
Display control within primary.

TL_GEN_DISPLAY  
Display within display control.

TL_GEN_VIEW  
View within display.

**Library:** Objects/genC.def

----------
#### TargetReference
    TargetReference         struct
        TR_object       optr    ; OD of node/leaf in target hierarchy
        TR_class        fptr    ; class of above object
    TargetReference         ends

**Library:** Objects/gViewC.def

----------
#### TCCFeatures
    TCCFeatures     record
        TCCF_CHARACTER      :1
        TCCF_WORD           :1
        TCCF_LINE           :1
        TCCF_PARAGRAPH      :1
        TCCF_RECALC         :1
    TCCFeatures     end

**Library:** Objects/Text/tCtrlC.def

----------
#### TCCToolboxFeatures
    TCCToolboxFeatures      record
    TCCToolboxFeatures      end

**Library:** Objects/Text/tCtrlC.def

----------
#### TCFeatures
    TCFeatures      record
        TCF_LIST            :1
        TCF_POSITION        :1
        TCF_GRAY_SCREEN     :1
        TCF_TYPE            :1
        TCF_LEADER          :1
        TCF_LINE            :1
        TCF_CLEAR           :1
        TCF_CLEAR_ALL       :1
    TCFeatures      end

**Library:** Objects/Text/tCtrlC.def

----------
#### TCToolboxFeatures
    TCToolboxFeatures       record
    TCToolboxFeatures       end

**Library:** Objects/Text/tCtrlC.def

----------
#### TempGenControlInstance
    TempGenControlInstance          struct
        TGCI_interactibleFlags          GenControlInteractibleFlags
        TGCI_childBlock                 hptr
        TGCI_toolBlock                  hptr
        TGCI_toolParent                 optr
        TGCI_features                   word
        TGCI_toolboxFeatures            word
        TGCI_activeNotificationList     GCNListType
        TGCI_upToDate                   GenControlInteractibleFlags
    TempGenControlInstance          ends

*TGCI_interactableFlags* holds the current status of various portions of the 
controller (the entire controller object itself, its associated toolbox, or its 
associated "normal" UI). These flags define which portions of the controller 
are interactable by the user. These bits may be changed by the default 
handlers for MSG_GEN_CONTROL_NOTIFY_INTERACTABLE and 
MSG_GEN_CONTROL_NOTIFY_NOT_INTERACTABLE only. If any bits become 
set, the controller adds itself to the notification list, so that it will be able to 
update the interactable areas. The controller then remains on the lists until 
all bits become clear.

*TGCI_toolParent* stores the object passed to the 
MSG_GEN_CONTROL_GENERATE_TOOLBOX_UI method. This object is the 
object that the tools were added to at that point.

*TGCI_upToDate* holds the status of the **GenControlInteractableFlags** in 
*TGCI_interactibleFlags* at the point that the last notification update came in. 
This defines what portions of the controller's UI were up to date at that last 
notification period. This way, if some part of the UI becomes non-interactable, 
then interactable again before another update, we can detect this scenario 
and avoid a redundant update.

**Library:** Objects/gCtrlC.def

----------
#### TempGenToolControlInstance
    TempGenToolControlInstance              struct
        TGTCI_curController         optr
        TGTCI_features              word
        TGTCI_required              word
        TGTCI_allowed               word
        TGTCI_curToolGroup          optr
        TGTCI_toolGroupVisible      byte
    TempGenToolControlInstance              ends

*TGTCI_curController* stores the optr of the controller whose tool options and 
placement location are currently being displayed for editing by the user.

*TGTCI_features* stores the mask of currently active features.

*TGTCI_required* stores the mask of features which must always be active, i.e. 
can't be "hidden" by the user.

*TGTCI_allowed* stores the mask of features which controller and application 
together will allow the user to access. Bits set here but not in 
"*TGTCI_features*" will appear in the "hidden" list.

*TGTCI_curToolGroup* stores the currently selected tool group.

*TGTCI_toolGroupVisible* stores a non-zero value if a tool group list is visible. 
If visible, all tool groups are highlighted, and the current one "selected" to 
bring it to the attention of the user.

**Library:** Objects/gToolCC.def

----------
#### TempImportExportData
    TempImportExportData            struct
        TIED_formatUI           optr    ; OD of duplicated format UI
        TIED_formatLibrary      hptr    ; handle of library for above
    TempImportExportData            ends

**Library:** impex.def

----------
#### TempMetaGCNData
    TempMetaGCNData     struct
        TMGCND_listOfLists      lptr.GCNListOfListsHeader
        TMGCND_flags            TempMetaGCNFlags
    TempMetaGCNData     ends

*TMGCND_listOfLists* stores the chunk handle holding the GCN list of lists.

**Library:** Objects/metaC.def

----------
#### TempMetaGCNFlags
    TempMetaGCNFlags        record
        TMGCNF_RELOCATED        :1      ; set if relocated
                                :7
    TempMetaGCNFlags        end

**Library:** Objects/metaC.def

----------
#### TempPrintCtrlInstance
    TempPrintCtrlInstance           struct
        TPCI_currentSummons         optr    ; currently active summons
        TPCI_progressBox            optr    ; OD of progress dialog box
        TPCI_jobParHandle           hptr    ; memory handle to JobParamters
        TPCI_fileHandle             word    ; file handle (if printing)
        TPCI_gstringHandle          word    ; gstring handle (if printing)
        TPCI_printBlockHan          word    ; the printer block handle
        TPCI_attrs                  PrintControlAttrs
        TPCI_status                 PrintStatusFlags
        TPCI_holdUpCompletionCount  byte    ; Number of things not wanting the message 
                                            ; stored in TEMP_PRINT_COMPLETION_EVENT to 
                                            ; be sent out just yet.
    TempPrintCtrlInstance           ends

**Library:** spool.def

----------
#### TestRectReturnType
    TestRectReturnType          etype byte
        TRRT_OUT            enum TestRectReturnType
        TRRT_PARTIAL        enum TestRectReturnType
        TRRT_IN             enum TestRectReturnType

**Library:** graphics.def

----------
#### TextArrayType
    TextArrayType       etype byte
        TAT_CHAR_ATTRS          enum TextArrayType
        TAT_PARA_ATTRS          enum TextArrayType
        TAT_GRAPHICS            enum TextArrayType
        TAT_TYPES               enum TextArrayType

**Library:** Objects/vTextC.def

----------
#### TextAttr
    TextAttr        struct
        TA_color        ColorQuad           ; RGB values or index
        TA_mask         SystemDrawMask      ; draw mask
        TA_pattern      GraphicPattern      ; pattern
        TA_styleSet     TextStyle           ; text style bits to set
        TA_styleClear   TextStyle           ; text style bits to clear
        TA_modeSet      TextMode            ; text mode bits to set
        TA_modeClear    TextMode            ; text mode bits to clear
        TA_spacePad     WBFixed             ; space padding
        TA_font         FontID              ; typeface
        TA_size         WBFixed             ; point size
        TA_trackKern    sword               ; track kerning
        TA_fontWeight   FontWeight          ; weight of font
        TA_fontWidth    FontWidth           ; width of font
        align           word
    TextAttr        ends

This structure is used with **GrSetTextAttr** and **GrDrawTextField**.

**Library:** graphics.def

----------
#### TextClipboardOption
    TextClipboardOption         etype word
        TCO_COPY                        enum TextClipboardOption
        TCO_RETURN_TRANSFER_FORMAT      enum TextClipboardOption
        TCO_RETURN_TRANSFER_ITEM        enum TextClipboardOption
        TCO_RETURN_NOTHING              enum TextClipboardOption

**Library:** Objects/vTextC.def

----------
#### TextColors
    TextColors      struc
        TC_unselectedColor      byte
        TC_selectedColor        byte
    TextColors      ends

**Library:** genC.def

----------
#### TextElementArrayHeader
    TextElementArrayHeader      struct
        TEAH_meta           ElementArrayHeader
        TEAH_arrayType      TextArrayType
        TEAH_unused         byte
    TextElementArrayHeader      ends

**Library:** Objects/vTextC.def

----------
#### TextFocusFlags
    TextFocusFlags  record      ;Record passed in BP
        TFF_EDITABLE_TEXT_OBJECT_HAS_FOCUS      :1
                                ; Set if an editable text object has the focus
        TFF_OBJECT_RUN_BY_UI_THREAD             :1
                                ; Set if the object is run by the UI thread
                                                :14
    TextFocusFlags end

**Library:** vTextC.def

----------
#### TextGuardianFlags
    TextGuardianFlags       record
        TGF_ENFORCE_DESIRED_MIN_HEIGHT                          :1
        TGF_ENFORCE_DESIRED_MAX_HEIGHT                          :1
        TGF_DISABLE_ENFORCED_DESIRED_MAX_HEIGHT_WHILE_EDITING   :1
        TGF_ENFORCE_MIN_DISPLAY_SIZE                            :1
        TGF_SHRINK_WIDTH_TO_MIN_AFTER_EDIT                      :1
    TextGuardianFlags       end

TGF_ENFORCE_DESIRED_MIN_HEIGHT  
If true then text object will not shrink below the 
desiredMinHeight while it is being edited or when some 
attribute changes.

TGF_ENFORCE_DESIRED_MAX_HEIGHT  
If true then text object will not expand above the 
desiredMaxHeight while it is being edited or when some 
attribute changes.

TGF_DISABLE_ENFORCED_DESIRED_MAX_HEIGHT_WHILE_EDITING  
If true, text object can grow beyond desiredMaxHeight during 
editing, but when the object stops being edited it will shrink 
back to desiredMaxHeight. This flag is meaningless if 
TGF_ENFORCE_DESIRED_MAX_HEIGHT is not set.

TGF_ENFORCE_MIN_DISPLAY_SIZE  
If true, then during resize don't allow text object to become 
shorter than is necessary to display all the text.

TGF_SHRINK_WIDTH_TO_MIN_AFTER_EDIT  
If true then when the text object loses the edit grab shrink the 
width to minimum needed to hold the text. Used when user 
clicks and releases in the same spot to create.

**Library:** grobj.def

----------
#### TextLargeRunArrayHeader
    TextLargeRunArrayHeader         struct
        TLRAH_meta              HugeArrayDirectory
        TLRAH_elementVMBlock    word        ; Element block (or null)
    TextLargeRunArrayHeader         ends

This structure stores a generic array of runs in the large text format.

**Library:** Objects/vTextC.def

----------
#### TextMetricStyles
    TextMetricStyles        struct
        TMS_styleCallBack       fptr.far        ;style callback routine
        ;
        ;   PASS:       ss:bx   = TOC_vars
        ;               di      = Offset into the field
        ;               ds      = Segment address of old text pointer
        ;   RETURN:     TMS_textAttr set
        ;               ds:si   = Pointer to the text
        ;               cx      = Number of characters in this style
        ;   DESTROYED:          nothing
        ;
        TMS_graphicCallBack     fptr.far        ;graphic callback routine
        ;
        ;   PASS:       ss:bx   = LICL_vars
        ;               di      = Offset into field
        ;               ds      = Segment address of text pointer
        ;   RETURN:     cx      = Height of the graphic of graphic
        ;                           at current position
        ;               dx      = Width of the graphic
        ;   DESTROYED:          nothing
        ;
        TMS_fieldStart          dword
        TMS_sizeSoFar           WBFixed
        TMS_lastCharWidth       WBFixed
        TMS_textAttr            TextAttr
        TMS_fontHandle          hptr.FontBuf
        TMS_trackKernValue      BBFixed
        TMS_flags               TMSFlags
        TMS_gstateHandle        hptr.GState
        TMS_gstateSegment       word
        TMS_styleHeight         WBFixed
        TMS_styleBaseline       WBFixed
    TextMetricStyles        ends

**Library:** text.def

----------
#### TextMode
    TextMode        record
        TM_DRAW_CONTROL_CHARS       :1  ; Does the following mapping when drawing
                                        ; text:
                                        ; C_SPACE        -> C_CNTR_DOT
                                        ; C_NONBRKSPACE  -> C_CNTR_DOT
                                        ; C_CR           -> C_PARAGRAPH
                                        ; C_TAB          -> C_LOGICAL_NOT
                                        ;
        TM_TRACK_KERN               :1  ;internal only - not settable
        TM_PAIR_KERN                :1  ;internal only - not settable
        TM_PAD_SPACES               :1  ;internal only - not settable
        TM_DRAW_BASE                :1
        TM_DRAW_BOTTOM              :1
        TM_DRAW_ACCENT              :1
        TM_DRAW_OPTIONAL_HYPHENS    :1
    TextMode        end

**Library:** graphics.def

----------
#### TextReference
    TextReference       struct
        TR_type     TextReferenceType
        TR_ref      TextReferenceUnion
    TextReference       ends

**Library:** Objects/vTextC.def

----------
#### TextReferenceBlock
    TextReferenceBlock          struct
        TRB_handle          hptr.char
    TextReferenceBlock          ends

This structure corresponds to a **TextReferenceType** of TRT_BLOCK. It is 
used with MSG_VIS_TEXT_REPLACE_TEXT and 
MSG_VIS_TEXT_GET_TEXT_RANGE to reference text used by those messages.

*TRB_handle* stores the handle of the text buffer. No entries need to be filled 
in to allocate a destination buffer. The heap allocation request will be made 
with the HAF_NO_ERR flag. If VTGRF_RESIZE is passed then either the 
passed block or the allocated block will be resized to accommodate the text.

**Library:** Object/vTextC.def

----------
#### TextReferenceBlockChunk
    TextReferenceBlockChunk         struct
        TRBC_ref        optr.char
    TextReferenceBlockChunk         ends

This structure corresponds to a **TextReferenceType** of TRT_OPTR. It is 
used with MSG_VIS_TEXT_REPLACE_TEXT and 
MSG_VIS_TEXT_GET_TEXT_RANGE to reference text used by those messages.

*TRBC_ref* stores the optr to a text buffer (a group of character)s. The handle 
field of *TRBC_ref* must be filled in. 

It is assumed that the LMem heap will be able to accommodate this 
allocation. The caller is responsible for ensuring that this is the case.

If VTGRF_RESIZE is passed then either the passed block or the allocated 
block will be resized to accommodate the text.

**Library:** Objects/vTextC.def

----------
#### TextReferenceDBItem
    TextReferenceDBItem         struct
        TRDBI_file      hptr
        TRDBI_item      word
        TRDBI_group     word
    TextReferenceDBItem         ends

This structure corresponds to a **TextReferenceType** of TRT_DB_ITEM. It is 
used with MSG_VIS_TEXT_REPLACE_TEXT and 
MSG_VIS_TEXT_GET_TEXT_RANGE to reference text used by those messages.

*TRDBI__file* stores the VM file associated with this DB item.

*TRDBI_item* stores the DB item itself.

*TRDBI_group* stores the DB group the item belongs to.

Both *TRDBI_file* and *TRDBI_group* must be filled in if you want a VM block to 
be allocated.

If the *TRDBI_group* field is set to DB_UNGROUPED then the item will be 
allocated ungrouped. *TRDBI_group* will hold the group in which the item 
was allocated on return.

If VTGRF_RESIZE is passed then either the passed block or the allocated 
block will be resized to accommodate the text.

**Library:** Objects/vTextC.def

----------
#### TextReferenceHugeArray
    TextReferenceHugeArray          struct
        TRHA_file           hptr
        TRHA_array          word
    TextReferenceHugeArray          ends

This structure corresponds to a **TextReferenceType** of TRT_HUGE_ARRAY. 
It is used with MSG_VIS_TEXT_REPLACE_TEXT and 
MSG_VIS_TEXT_GET_TEXT_RANGE to reference text used by those messages.

*TRHA_file* stores the VM file associated with this huge array.

*TRHA_array* stores the Huge Array.

The *TRHA_file* field must be set if you want a huge-array to be allocated.

If VTGRF_RESIZE is passed then either the passed block or the allocated 
block will be resized to accommodate the text.

**Library:** Objects/vTextC.def

----------
#### TextReferencePointer
    TextReferencePointer            struct
        TRP_pointer         fptr.char
    TextReferencePointer            ends

This structure corresponds to a **TextReferenceType** of TRT_POINTER. It is 
used with MSG_VIS_TEXT_REPLACE_TEXT and 
MSG_VIS_TEXT_GET_TEXT_RANGE to reference text used by those messages.

*TRP_pointer* stores the pointer to the text. This field must be filled in.

VTGRF_RESIZE has no meaning with this sort of reference. 
VTGRF_ALLOCATE and VTGRF_ALLOCATE_ALWAYS are not valid flags to 
pass with this type of text reference. 

This reference is the safest way to copy text out of a text object. Since the 
caller allocates the block it can also handle errors in the allocation.

**Library:** Objects/vTextC.def

----------
#### TextReferenceSegmentChunk
    TextReferenceSegmentChunk               struct
        TRSC_chunk              word
        TRSC_segment            word
    TextReferenceSegmentChunk               ends

This structure corresponds to a **TextReferenceType** of 
TRT_SEGMENT_CHUNK. It is used with MSG_VIS_TEXT_REPLACE_TEXT and 
MSG_VIS_TEXT_GET_TEXT_RANGE to reference text used by those messages.

*TRSC_segment* stores the segment address of the text chunk. *TRSC_chunk* 
stores the chunk offset to the text.

It is assumed that the LMem heap will be able to accommodate this 
allocation. The caller is responsible for ensuring that this is the case.

If VTGRF_RESIZE is passed then either the passed block or the allocated 
block will be resized to accommodate the text.

**Library:** Objects/vTextC.def

----------
#### TextReferenceType
    TextReferenceType       etype word, 0, 2
        TRT_POINTER             enum    TextReferenceType
        TRT_SEGMENT_CHUNK       enum    TextReferenceType
        TRT_OPTR                enum    TextReferenceType
        TRT_BLOCK               enum    TextReferenceType
        TRT_VM_BLOCK            enum    TextReferenceType
        TRT_DB_ITEM             enum    TextReferenceType
        TRT_HUGE_ARRAY          enum    TextReferenceType

**Library:** Objects/vTextC.def

----------
#### TextReferenceUnion
    TextReferenceUnion          union
        TRU_pointer         TextReferencePointer
        TRU_segChunk        TextReferenceSegmentChunk
        TRU_blockChunk      TextReferenceBlockChunk
        TRU_block           TextReferenceBlock
        TRU_vmBlock         TextReferenceVMBlock
        TRU_dbItem          TextReferenceDBItem
        TRU_hugeArray       TextReferenceHugeArray
    TextReferenceUnion          end

**Library:** Objects/vTextC.def

----------
#### TextReferenceVMBlock
    TextReferenceVMBlock            struct
        TRVMB_file          hptr
        TRVMB_block         word
    TextReferenceVMBlock            ends

This structure corresponds to a **TextReferenceType** of TRT_VM_BLOCK. It 
is used with MSG_VIS_TEXT_REPLACE_TEXT and 
MSG_VIS_TEXT_GET_TEXT_RANGE to reference text used by those messages.

*TRVMB_file* stores the VM file associated with this VM block. This entry must 
be filled in if you want a VM block to be allocated.

*TRVMB_block* stores the VM block itself.

If VTGRF_RESIZE is passed then either the passed block or the allocated 
block will be resized to accommodate the text.

**Library:** Objects/vTextC.def

----------
#### TextRulerAction
    TextRulerAction     etype byte
        TRA_NULL                enum TextRulerAction
        TRA_MOVE_TAB            enum TextRulerAction
        TRA_COPY_TAB            enum TextRulerAction
        TRA_MOVE_MARGIN         enum TextRulerAction

**Library:** Objects/Text/tCtrlC.def

----------
#### TextRulerControlAttributes
    TextRulerControlAttributes      record
        TRCA_ROUND              :1
        TRCA_IGNORE_ORIGIN      :1
                                :14
    TextRulerControlAttributes      end

**Library:** Objects/Text/tCtrlC.def

----------
#### TextRulerFlags
    TextRulerFlags      record
                                        :3
        TRF_ALWAYS_MOVE_BOTH_MARGINS    :1
        TRF_ROUND_COORDINATES           :1
        TRF_OBJECT_SELECTED             :1
        TRF_SELECTING                   :1
        TRF_DRAGGING                    :1
    TextRulerFlags      end

**Library:** Objects/Text/tCtrlC.def

----------
#### TextRunArrayElement
    TextRunArrayElement         struct
        TRAE_position   WordAndAHalf <>     ; Position for start of run
        TRAE_token      word                ; Token for run
    TextRunArrayElement         ends

This structure stores an element in an array of text runs.

**Library:** Objects/vTextC.def

----------
#### TextRunArrayHeader
    TextRunArrayHeader      struct
        TRAH_meta               ChunkArrayHeader
        TRAH_elementVMBlock     word        ; Element block
        TRAH_elmentArray        lptr        ; ChunkHandle of element array
    TextRunArrayHeader      ends

This structure stores the header of an array of runs (for non-LARGE text 
objects).

**Library:** Objects/vTextC.def

----------
#### TextSearchInHugeArrayFrame
    TextSearchInHugeArrayFrame              struct
        TSIHAF_str1Size             dword (?)
        TSIHAF_curOffset            dword (?)
        TSIHAF_endOffset            dword (?)
        TSIHAF_searchFlags          SearchOptions
        TSIHAF_hugeArrayVMFile      hptr
        TSIHAF_hugeArrayVMBlock     hptr
        even
    TextSearchInHugeArrayFrame              ends

*TSIHAF_str1Size* stores the total length of the string to search (str1).

*TSIHAF_curOffset* stores the offset (from the start of str1) to the first 
character to check.

*TSIHAF_endOffset* stores the offset (from the start of str1) to the last 
character to check. The text search will only match words that start at less 
than or equal to the character position in *TSIHAF_endOffset*. To check to the 
start of a string (backward searches only) pass 0:0. To check to the end of a 
string (forward searches only) pass *TSIHAF_str1Size*-1.

*TSIHAF_hugeArrayVMFile* and *TSIHAF_hugeArrayVMBlock* store the file 
and block handles for the huge array we will be extracting text from.

**Library:** Objects/vTextC.def

----------
#### TextStyle
    TextStyle       record
                            :1  ; Do not use this bit.
        TS_OUTLINE          :1
        TS_BOLD             :1
        TS_ITALIC           :1
        TS_SUPERSCRIPT      :1
        TS_SUBSCRIPT        :1
        TS_STRIKE_THRU      :1
        TS_UNDERLINE        :1
    TextStyle       end

**Library:** graphics.def

----------
#### TextStyleElementHeader
    TextStyleElementHeader          struct
        TSEH_meta               NameArrayElement
        TSEH_baseStyle          word
        TSEH_flags              StyleElementFlags
        TSEH_reserved           byte 6 dup (?)
        TSEH_privateData        TextStylePrivateData
        TSEH_charAttrToken      word
        TSEH_paraAttrToken      word
        TSEH_name               label char
    TextStyleElementHeader          ends

**Library:** Objects/vTextC.def

----------
#### TextStyleFlags
    TextStyleFlags      record
        TSF_APPLY_TO_SELECTION_ONLY     :1
        TSF_POINT_SIZE_RELATIVE         :1
        TSF_MARGINS_RELATIVE            :1
        TSF_LEADING_RELATIVE            :1
                                        :12
    TextStyleFlags      end

**Library:** Objects/vTextC.def

----------
#### TextStylePrivateData
    TextStylePrivateData            struct
        TSPD_flags          TextStyleFlags
        TSPD_unused         byte 2 dup (0)
    TextStylePrivateData            ends

**Library:** Objects/vTextC.def

----------
#### TextTransferBlockHeader
    TextTransferBlockHeader             struct
        TTBH_meta                       VMChainTree
        TTBH_reservedOther              word 20 dup (0)

        TTBH_firstVM        label word
        TTBH_text                       dword       ;huge array ID
        TTBH_charAttrRuns               dword       ;huge array ID
        TTBH_paraAttrRuns               dword       ;huge array ID
        TTBH_typeRuns                   dword       ;huge array ID
        TTBH_graphicRuns                dword       ;huge array ID

        TTBH_firstLMem      label word
        TTBH_charAttrElements           dword       ;VM block handle
        TTBH_paraAttrElements           dword       ;VM block handle
        TTBH_typeElements               dword       ;VM block handle
        TTBH_graphicElements            dword       ;VM block handle
        TTBH_styles                     dword       ;VM block handle
        TTBH_names                      dword       ;VM block handle
        TTBH_pageSetup                  dword       ;VM block handle
        TTBH_lastLMem       label word

        TTBH_reservedVM                 dword 10 dup (0)
    TextTransferBlockHeader             ends



**Library:** Objects/vTextC.def

----------
#### TFStyleRun
    TFStyleRun      struct
        TFSR_count          word    ?       ; character count
        TFSR_attr           TextAttr <>     ; text attributes
    TFStyleRun      ends

**Library:** gstring.def

----------
#### THCFeatures
    THCFeatures     record
        THCF_FOLLOW_HYPERLINK           :1
        THCF_SET_HYPERLINK              :1
        THCF_SET_CONTEXT                :1
        THCF_DEFINE_FILE                :1
        THCF_DEFINE_CONTEXT             :1
    THCFeatures     end

**Library:** Objects/Text/tCtrlC.def

----------
#### THCToolboxFeatures
    THCToolboxFeatures      record
    THCToolboxFeatures      end

**Library:** Objects/Text/tCtrlC.def

----------
#### ThreadException
    ThreadException     etype word, 0, 4
        TE_DIVIDE_BY_ZERO       enum ThreadException
        TE_OVERFLOW             enum ThreadException
        TE_BOUND                enum ThreadException
        TE_FPU_EXCEPTION        enum ThreadException
        TE_SINGLE_STEP          enum ThreadException
        TE_BREAKPOINT           enum ThreadException

**Library:** thread.def

----------
#### ThreadGetInfoType
    ThreadGetInfoType       etype word, 0, 2
        TGIT_PRIORITY_AND_USAGE         enum ThreadGetInfoType
        TGIT_THREAD_HANDLE              enum ThreadGetInfoType
        TGIT_QUEUE_HANDLE               enum ThreadGetInfoType

**Library:** thread.def

----------
#### ThreadModifyFlags
    ThreadModifyFlags       record
        TMF_BASE_PRIO           :1
        TMF_ZERO_USAGE          :1
                                :6
    ThreadModifyFlags       end

**Library:** thread.def

----------
#### ThreadPriority
    ThreadPriority      etype byte
        PRIORITY_TIME_CRITICAL      enum ThreadPriority, 0
        PRIORITY_HIGH               enum ThreadPriority, 64     ;IM
        PRIORITY_UI                 enum ThreadPriority, 96     ;UI
        PRIORITY_FOCUS              enum ThreadPriority, 128    ;FOCUS
        PRIORITY_STANDARD           enum ThreadPriority, 160    ;STD
        PRIORITY_LOW                enum ThreadPriority, 192    ;BACKGROUND
        PRIORITY_LOWEST             enum ThreadPriority, 255    ;Used by kernel

**Library:** thread.def

----------
#### ThreePointArcParams
    ThreePointArcParams             struct
        TPAP_close          ArcCloseType    ; how the arc should be closed
        TPAP_point1         PointWWFixed    ; Point #1 (start of arc)
        TPAP_point2         PointWWFixed    ; Point #2 (a non-terminal point on the 
                                            ; arc)
        TPAP_point3         PointWWFixed    ; Point #3 (end of arc)
    ThreePointArcParams             ends

**Library:** graphics.def

----------
#### ThreePointArcToParams
    ThreePointArcToParams           struct
        TPATP_close         ArcCloseType    ; how the arc should be closed
        TPATP_point2        PointWWFixed    ; Point #2 (a non-terminal point on the 
                                            ; arc)
        TPATP_point3         PointWWFixed   ; Point #3 (end of arc)
    ThreePointArcToParams           ends

**Library:** graphics.def

----------
#### ThreePointRelArcToParams
    ThreePointRelArcToParams            struct
        TPRATP_close        ArcCloseType    ; how the arc should be closed
        TPRATP_delta2       PointWWFixed    ; delta to Point #2 
        TPRATP_delta3       PointWWFixed    ; delta to Point #3 
    ThreePointRelArcToParams            ends

**Library:** graphics.def

----------
#### TimerType
    TimerType       etype word, 0, 2
        TIMER_ROUTINE_ONE_SHOT              enum TimerType
        TIMER_ROUTINE_CONTINUAL             enum TimerType
        TIMER_EVENT_ONE_SHOT                enum TimerType
        TIMER_EVENT_CONTINUAL               enum TimerType
        TIMER_MS_ROUTINE_ONE_SHOT           enum TimerType
        TIMER_EVENT_REAL_TIME               enum TimerType

**Library:** timer.def

----------
#### TMSFlags
    TMSFlags        record
        TMSF_IS_BREAK_CHARACTER     :1  ;TRUE: Last char was a break character.
        TMSF_IS_OPTIONAL_HYPHEN     :1  ;TRUE: Break is an optional hyphen.
        TMSF_PAD_SPACES             :1  ;TRUE: AddWidth should pad spaces.
        TMSF_UPDATE_SIZE_ONLY       :1  ;TRUE: AddWidth only updates size.
        TMSF_OPT_HYPHENS            1   ;TRUE: deal with optional hyphens.
        TMSF_NEGATIVE_KERNING       :1  ;TRUE: last char on line was negatively 
                                        ;kerned.
        TMSF_EXTENDS_ABOVE          :1  ;TRUE: last char on line has tall accent.
        TMSF_EXTENDS_BELOW          :1  ;TRUE: last char on line has large 
                                        ;descender.
        TMSF_STYLE_CHANGED          :1  ;TRUE: style changed, update line height.
                                    :7  ;Yes, I want an entire word...
    TMSFlags        end

**Library:** text.def

----------
#### TocCategoryStruct
    TocCategoryStruct           struct
        TCS_tokenChars      TokenChars <>
        TCS_files           dbptr <>        ; file name array
        TCS_devices         dbptr <>
    TocCategoryStruct           ends

This is the element structure for each element in the categories array.

*TCS_devices* stores the device name array (if and only if 
TCF_EXTENDED_DEVICE_DRIVERS is set).

**Library:** config.def

----------
#### TocDeviceStruct
    TocDeviceStruct         struct
        TDS_driver      word        ; element in driver array
        TDS_info        word        ; extra word of info (depends on device type).
        TDS_name        label char
    TocDeviceStruct         ends

**Library:** config.def

----------
#### TocDiskStruct
    TocDiskStruct       struct
        TDSS_volumeName         VolumeName
        TDSS_mediaType          MediaType
        TDSS_name               label char
    TocDiskStruct       ends

**Library:** config.def

----------
#### TOC_ext
    TOC_ext struct
        ;
        ; Entries that are passed
        ;
        TOCE_areaToFill         sword
        TOCE_hyphenCallback     dword
        ;PASS:      ss:bp       = pointer to TOC_vars structure on stack.
        ;           di          = Offset to the position where we would split the 
        ;                       word
        ;           TOCI_lastWordStart =
        ;                       Offset in the text where the word to break starts
        ;           TOCI_lastWordPos =
        ;                       Position (distance from left edge of the field) 
        ;                       where the word to break starts
        ;
        ;RETURN:    TOCI_suggestedHyphen =
        ;                       The offset to the character to break the word at.               
        ;                       Zero to break at the start of the word.
        ;           TOCI_suggestedHyphenPos =
        ;                       The position (distance from left edge of the 
        ;                       field) where the hyphen starts.
        ;           TOCE_hyphenWidth =
        ;                       Width of the hyphen that was placed at the end of
        ;                       the line.
        ;
        ;DESTROYED: nothing
        ;
        TOCE_tabCallback        dword
        ;PASS:      ds:si       = pointer to text
        ;           ss:bp       = TOC_vars
        ;           ss:bx       = LICL_vars
        ;
        ;RETURN:    carry set if there is no tabstop within the margins.
        ;           TOCE_areaToFill set correctly.
        ;
        ;DESTROYED: nothing
        ;
        TOCE_heightCallback     dword
        ;PASSED:    ss:bp       = TOC_vars
        ;           ax.bl       = Line height for new characters (WBFixed)
        ;
        ;RETURN:    nothing
        ;
        ;DESTROYED: nothing
        ;
        TOCE_passBack           word
        TOCE_anchorChar         word
        ;
        ; Entries that are passed and returned
        ;
        TOCE_flags              TOCFlags
        TOCE_lineHeight         WBFixed
        TOCE_lineBLO            WBFixed
        TOCE_lineFlags          LineFlags
        ;
        ; Entries that are returned
        ;
        TOCE_otherFlags         TOCOtherFlags
        TOCE_nSpaces            sword
        TOCE_nExtraSpaces       sword
        TOCE_widthToAnchor      sword
        TOCE_nChars             sword
        TOCE_break              sword
        TOCE_hyphenWidth        WBFixed
        TOCE_fieldWidth         BFixed
        TOCE_justWidth          sword
    TOC_ext ends

This structure contains some fields which are passed to **GrTextObjCalc** by 
the application along with some fields which are returned.

*TOCE_areaToFill* stores the width of the area we are trying to fit the field to.

*TOCE_hyphenCallback* stores the address of the callback routine to perform 
automatic hyphenation. (The callback's parameters are listed in the 
structure display.)

*TOCE_tabCallback* stores the address of the callback routine to call when a 
TAB character is encountered. (The callback's parameters are listed in the 
structure display.)

*TOCE_heightCallback* stores the address of the callback routine to call when 
the line height changes. (The callback's parameters are listed in the 
structure display.)

*TOCE_passBack* stores a custom word of data to allow applications to pass 
data to their callbacks.

*TOCE_anchorChar* stores the anchor character to look for if the current field 
is associated with an anchored tab-stop.

*TOCE_flags* stores the **TOCFlags** that are both passed and returned.

*TOCE_lineHeight* should store the current value of the line height (at the 
time this stack frame is passed in). If a line would grow taller as a result of 
adding the new field, then this value is returned to reflect the new height.

*TOCE_lineBLO* stores the current value of the lines baseline-offset (at the 
time this stack frame is passed in). A line height is determined by its ascent 
and descent. To compute these values we need the baseline.

*TOCE_lineFlags* stores the **LineFlags** for the current line based on the 
previous calculations and the current calculations.

*TOCE_otherFlags* stores some optimization flags which decide whether an 
optimized redraw is possible after a text change. 

*TOCE_nSpaces* stores the number of spaces in the line which can be padded 
for full justification.

*TOCE_nExtraSpaces* stores the number of spaces after the word-break. These 
spaces are on the line but shouldn't be considered for full justification.

*TOCE_widthToAnchor* stores the amount of the field which falls before the 
anchor character.

*TOCE_nChars* stores the number of characters in the field which fit in the 
area.

*TOCE_break* stores the position of the break in the text.

*TOCE_hyphenWidth* stores the width of the generated hyphen at the end of 
the line.

*TOCE_fieldWidth* stores the width of the field up to the word-break.

*TOCE_justWidth* stores the amount of the field which should be considered for 
justification. This value doesn't include the spaces at the end of the line.

**Library:** text.def

----------
#### TocFileStruct
    TocFileStruct       struct
        TFS_sourceDisk      word            ; Disk token
        TFS_release         ReleaseNumber <>
        TFS_name            label char
    TocFileStruct       ends

**Library:** config.def

----------
#### TOCFlags
    TOCFlags        record
        TOCF_NO_WORD_WRAP           :1  ; PASS: Set - word-wrap should be done
        TOCF_AUTO_HYPHENATE         :1  ; PASS: Set - attempt auto hyphenation

        TOCF_FOUND_ANCHOR           :1  ; RET: Set - an anchor character was found
        TOCF_IS_HARD_HYPHEN         :1  ; RET: Set - break is a hard or opt hyphen
        TOCF_FOUND_BREAK            :1  ; RET: Set - an auto-hyphen position was 
                                        ; found
        TOCF_LINE_TERMINATED        :1  ; RET: Set - last field on line
        TOCF_ONE_TAB_TOO_LARGE      :1  ; RET: Set - tab couldn't be handled
        TOCF_OPT_HYPHEN_TOO_WIDE    :1  ; RET: Set - optional hyphen too wide to 
                                        ; fit
    TOCFlags        end

**Library:** text.def

----------
#### TOC_int
    TOC_int struct
        TOCI_style                  TextMetricStyles
        TOCI_currentHgt             WBFixed     ; Height of the field
        TOCI_currentBlo             WBFixed     ; Baseline of the field
        TOCI_lastWordStart          word        ; Position in text of last word start.
        TOCI_lastWordPos            WBFixed     ; Position of last word start.
        TOCI_lastWordEndPos         word        ; Position of last word end.
        TOCI_lastHyphen             word        ; Position of last usable hyphen.
        TOCI_lastHyphenPos          WBFixed     ; Position of last soft/hard hyphen.
        TOCI_tallCharHeightPos      word        ; Position of tall character with an
                                                ; important height value.
        TOCI_tallCharHeight         WBFixed     ; Height of tall char.
        TOCI_tallCharBaselinePos    word        ; Position of tall character with an
                                                ; important baseline value.
        TOCI_tallCharBaseline       WBFixed     ; Baseline of tall char.
        TOCI_suggestedHyphen        word        ; Position of suggested hyphen in text
        TOCI_suggestedHyphenPos     WBFixed     ; Position of suggested hyphen on line
        align                       word
    TOC_int ends

This structure stores fields which are internal to **GrTextObjCalc**. All fields 
are initialized and used inside **GrTextObjCalc**.

**Library:** text.def

----------
#### TocMap
    TocMap  struct
        TM_disks            dbptr
        TM_categories       dbptr
    TocMap  ends

This structure is the map item of the TOC file.

**Library:** config.def

----------
#### TOCOtherFlags
    TOCOtherFlags       record
        TOCOF_IS_FIRST_FIELD    :1  ; PASS: Set - This is the first field on the 
                                    ; line
        TOCOF_PREV_CHAR_KERNED  :1  ; HACK added by jim 4/27/92 so kernel will 
                                    ; make
        TOCOF_LAST_BREAK_KERNED :1  ; HACK added by jim 4/27/92 so kernel will 
                                    ; make
                                :5
    TOCOtherFlags       end

**Library:** text.def

----------
#### TocUpdateCategoryFlags
    TocUpdateCategoryFlags record
        TUCF_EXTENDED_DEVICE_DRIVERS        :1
        ; Files being enumerated are assumed to be extended device drivers.

        TUCF_CUSTOM_FILES                   :1
        ; The TUCP_fileArrayElementSize field will be
        ; used when creating the files array. Otherwise, each element
        ; of the files array will be of size TocFileStruct. NOTE: If
        ; this flag is used, the data structure used for each file
        ; element MUST contain TocFileStruct as its first element.

        TUCF_ADD_CALLBACK                   :1
        ; TUCP_addCallback contains a fptr to a callback
        ; routine that will be called when a file is added to the
        ; files array.

        TUCF_DIRECTORY_NOT_FOUND            :1
        ; Don't actually scan the directory, because it doesn't exist.
        ; Just create the category, and leave it empty.

                                            :12
    TocUpdateCategoryFlags end

**Library:** config.def

----------
#### TocUpdateCategoryParams
    TocUpdateCategoryParams struct
        TUCP_flags                      TocUpdateCategoryFlags
        TUCP_tokenChars                 TokenChars
        TUCP_fileArrayElementSize       byte
        TUCP_addCallback                fptr.far
        ; CALLBACK:
        ;       PASS:       ds:si - filename to add
        ;                   di - VM handle of SortedNameArray
        ;                           (pass to TocSortedNameArrayAdd)
        ;
        ;       RETURN:     carry CLEAR if new element added,
        ;                   ax - element number
        ;                   carry SET if add aborted
        ;
        ;       CAN DESTROY: bx,cx,dx
        ;
        align   word
    TocUpdateCategoryParams ends

**Library:** 

----------
#### TOC_vars
    TOC_vars        struct
        TOCV_int        TOC_int
        TOCV_ext        TOC_ext
        align           word
    TOC_vars        ends

This structure is passed to **GrTextObjCalc** and consists of external 
parameters (*TOC_ext*) and internal variables (*TOC_int*).

**Library:** text.def

----------
#### ToggleState
    ToggleState     record
        TS_CAPSLOCK         :1
        TS_NUMLOCK          :1
        TS_SCROLLLOCK       :1
    ToggleState     end

**Library:** 

----------
#### TokenDBItem
    TokenDBItem     struct
        TDBI_group      word
        TDBI_item       word
    TokenDBItem     ends

This structure defines the identifier for a token database item.

**Library:** token.def

----------
#### TokenEntry
    TokenEntry      struct
        TE_type             TokenIndexType
        TE_token            GeodeToken <>
        TE_monikerList      TokenDBItem <>
        TE_flags            TokenFlags
        TE_release          ReleaseNumber <>
        TE_protocol         ProtocolNumber <>
    TokenEntry      ends

This structure stores a token entry, which is used in the index (map item) of 
the token database.

*TE_type* specifies the type of index entry that this token entry corresponds to.

*TE_token* specifies the **GeodeToken** for this file.

*TE_monikerList* stores the list of monikers for this token. This entry points 
to a chunk containing the item numbers of the chunks of the token.

*TE_flags* stores the **TokenFlags** of the token, which contain the token's 
relocation status.

*TE_release* stores the **ReleaseNumber** of the token database.

*TE_protocol* stores the **ProtocolNumber** of the token database.

**Library:** token.def

----------
#### TokenError
    TokenError              etype   word, 1
        BAD_PROTOCOL_IN_SHARED_TOKEN_DATABASE_FILE      enum    TokenError
        ERROR_OPENING_SHARED_TOKEN_DATABASE_FILE        enum    TokenError
        ERROR_OPENING_LOCAL_TOKEN_DATABASE_FILE         enum    TokenError

**Library:** token.def

----------
#### TokenFlags
    TokenFlags      record
        TF_NEED_RELOCATION      :1
        TF_UNUSED               :15
    TokenFlags      end

**Library:** token.def

----------
#### TokenMonikerInfo
    TokenMonikerInfo        struct
        TMI_moniker     TokenDBItem <>
        TMI_fileFlag    word            ; 0 if token is in shared
                                        ; token DB file
                                        ; non-0 if it's in local file
    TokenMonikerInfo        ends

The **TokenMonikerInfo** structure is used by applications which call 
**TokenLookupMoniker**, store the information returned, and later use it to 
call **TokenLockTokenMoniker**.

**Library:** token.def

----------
#### TokenRangeFlags
    TokenRangeFlags record
        TRF_ONLY_GSTRING            :1
        TRF_ONLY_PASSED_MANUFID     :1
                                    :14
    TokenRangeFlags end

**Library:** token.def

----------
#### ToolboxInfo
    ToolboxInfo     struct
        TI_object       optr
        TI_name         optr
    ToolboxInfo     ends

*TI_object* stores the optr of the GenInteraction under which tools may be 
placed (This optr is *unrelocated*! Use the UN_OPTR macro in assembly).

*TI_name* stores the null-terminated string name for the above tool location 
(This optr is also unrelocated. Use UN_OPTR macro in assembly).

**Library:** Objects/gToolCC.def

----------
#### ToolGroupHighlightType
    ToolGroupHighlightType              etype byte
        TGHT_INACTIVE_HIGHLIGHT     enum ToolGroupHighlightType
        TGHT_ACTIVE_HIGHLIGHT       enum ToolGroupHighlightType
        TGHT_NO_HIGHLIGHT           enum ToolGroupHighlightType

**Library:** Objects/gToolGC.def

----------
#### ToolGroupInfo
    ToolGroupInfo       struct
        TGI_object          optr
    ToolGroupInfo       ends

*TGI_object* stores the GenToolGroup that this tool control will operate on. 
(This optr is *unrelocated*! Use the UN_OPTR macro in assembly).

**Library:** Objects/gToolCC.def

----------
#### TrackScrollingParams
    TrackScrollingParams            struct
        TSP_action              ScrollAction
        TSP_flags               ScrollFlags     ;scroll flags
        TSP_caller              optr            ;object to return args to
        ;
        ; Only one set of these are sent via a MSG_META_CONTENT_TRACK_SCROLLING. The
        ; relative values (xChange, yChange) are sent on the relative scrolls --
        ; SA_SCROLL, SA_INC_FWD, SA_INC_BACK, SA_PAGE_FWD, SA_PAGE_BACK, SA_PAN. The
        ; absolute values (newOriginX, newOriginY) are sent on the absolute scrolls.
        ; To play it safe, your handler should call GenSetupTrackingArgs, which will
        ; fill in all of these.
        ;
        TSP_change              PointDWord      ;proposed change
        TSP_newOrigin           PointDWord      ;proposed new origin
        ;
        ; These arguments are NOT sent via MSG_META_CONTENT_TRACK_SCROLLING. If you 
        ; want to have these (and you probably will), your handler should call 
        ; GenSetupTrackingArgs, which will fill in all of these.
        ;
        TSP_oldOrigin           PointDWord      ;old origin
        TSP_viewWidth           sword           ;view width
        TSP_viewHeight          sword           ;view height
    TrackScrollingParams            ends

*TSP_action* stores the action taking place. Drags don't require the return 
message; in fact, return methods will be ignored for drags.

**Library:** Objects/gViewC.def

----------
#### TransferFileHeader
    TransferFileHeader          struct
        TFH_normalItem      word    ; VM block handle of normal transfer item
    TransferFileHeader          ends

This structure defines the map block of the transfer VM file, this is saved out 
in the UI's transfer VM file when the system is shutdown. The VM block 
handles must be valid handles for this VM transfer file.

**Library:** Objects/clipbrd.def

----------
#### TransFlags
    TransFlags      record
        TF_INV_VALID        :1
        TF_ROTATED          :1
        TF_SCALED           :1
        TF_TRANSLATED       :1
    TransFlags      end

**Library:** tmatrix.def

----------
#### TransMatrix
    TransMatrix         struct
        TM_e11      WWFixed <0,1>
        TM_e12      WWFixed <0,0>
        TM_e21      WWFixed <0,0>
        TM_e22      WWFixed <0,1>
        TM_e31      DWFixed <0,0>
        TM_e32      DWFixed <0,0>
    TransMatrix         ends

This structure stores the transformation matrix used within the GEOS 
graphics system. This matrix has six variable elements. (The last column of 
the 3x3 transformation matrix is the identity column [0 0 1].)

This **TransMatrix** is initially set to the identity matrix. 

*TM_e11* stores the value (32 bit **WWFixed**) at row 1, column 1.

*TM_e12* stores the value (32 bit **WWFixed**) at row 1, column 2.

*TM_e21* stores the value (32 bit **WWFixed**) at row 2, column 1.

*TM_e22* stores the value (32 bit **WWFixed**) at row 2, column 2.

*TM_e31* stores the value (48 bit **DWFixed**) at row 3, column 1.

*TM_e32* stores the value (48 bit **DWFixed**) at row 3, column 2.

**Library:** graphics.def

----------
#### TravelingObjectReference
    TravelingObjectReference            struct
        TIR_travelingObject         optr
        TIR_parent                  lptr
        TIR_compChildFlags          CompChildFlags
    TravelingObjectReference            ends

*TIR_travelingObject* stores the optr of the object which should be kept moving 
to the top GenDisplay. This optr should be stored in unrelocated for. (e.g. in 
assembly):  
UN_OPTR TUIToolbox3

*TIR_parent* stores the optr of the object within the GenDisplay under which 
the traveling object should be added.

*TIR_compChildFlags* stores the **CompChildFlags** to use when adding the 
traveling object below the parent.

**Library:** Objects/gDispC.def

----------
#### TravelOption
    TravelOption        etype word, 0
        TO_NULL                 enum TravelOption
        TO_SELF                 enum TravelOption
        TO_OBJ_BLOCK_OUTPUT     enum TravelOption
        TO_PROCESS              enum TravelOption

TO_NULL  
No object to deliver message to, the event should be destroyed. 

TO_SELF  
No additional UI behavior requested -- allow MetaClass 
handler to dispatch event if possible, else destroy it.

TO_OBJ_BLOCK_OUTPUT  
Sends event to Object Block output, if any, otherwise destroys 
the event. 

TO_PROCESS  
Sends event to the process owning the UI block.

**Library:** Objects/metaC.def

----------
#### TRCCFeatures
    TRCCFeatures        record
        TRCCF_ROUND             :1
        TRCCF_IGNORE_ORIGIN     :1
    TRCCFeatures        end

**Library:** Objects/Text/tCtrlC.def

----------
#### TRCCToolboxFeatures
    TRCCToolboxFeatures         record
    TRCCToolboxFeatures         end

**Library:** Objects/Text/tCtrlC.def

----------
#### TSCFeatures
    TSCFeatures     record
        TSCF_PLAIN              :1
        TSCF_BOLD               :1
        TSCF_ITALIC             :1
        TSCF_UNDERLINE          :1
        TSCF_STRIKE_THRU        :1
        TSCF_SUBSCRIPT          :1
        TSCF_SUPERSCRIPT        :1
        TSCF_BOXED              :1
        TSCF_BUTTON             :1
        TSCF_INDEX              :1
        TSCF_ALL_CAP            :1
        TSCF_SMALL_CAP          :1
    TSCFeatures     end

**Library:** Objects/Text/tCtrlC.def

----------
#### TSCToolboxFeatures
    TSCToolboxFeatures      record
        TSCTF_PLAIN             :1
        TSCTF_BOLD              :1
        TSCTF_ITALIC            :1
        TSCTF_UNDERLINE         :1
        TSCTF_STRIKE_THRU       :1
        TSCTF_SUBSCRIPT         :1
        TSCTF_SUPERSCRIPT       :1
        TSCTF_BOXED             :1
        TSCTF_BUTTON            :1
        TSCTF_INDEX             :1
        TSCTF_ALL_CAP           :1
        TSCTF_SMALL_CAP         :1
    TSCToolboxFeatures      end

**Library:** Objects/Text/tCtrlC.def

----------
#### TVTNCPIData
    TVTNCPIData         struct
        TVTNCPID_handle     word
        TVTNCPID_id         word
    TVTNCPIData         ends

**Library:** vTextC.def

----------
#### UChar
    UChar   etype byte
        UC_NULL             enum UChar, 0x0     ;NULL
        UC_QUICK_COPY       enum UChar, 0x1     ;unnecessary -- should remove!
        UC_BUTTON_EVENT     enum UChar, 0x2     ;send on a button event

**Library:** uiInputC.def

----------
#### UIButtonFlags
    UIButtonFlags       record
        UIBF_NO_KEYBOARD                :1
        UIBF_CLICK_TO_TYPE              :1
        UIBF_SELECT_ALWAYS_RAISES       :1
        UIBF_SELECT_DISPLAYS_MENU       :1
        UIBF_KEYBOARD_ONLY              :1
        UIBF_CLICK_GOES_THRU            :1
        UIBF_SPECIFIC_UI_COMPATIBLE     :1
        UIBF_BLINKING_CURSOR            :1
    UIButtonFlags       end

UIBF_NO_KEYBOARD  
Set if working in no-keyboard mode (i.e. pen system). Can be 
used by UI and applications to provide extensions to easy 
simplify usage. This is exclusive of UIBF_KEYBOARD_ONLY 
below.

UIBF_CLICK_TO_TYPE  
Determines which FOCUS model to use:  
If true: "explicit focus" - must press mouse button over window 
to give window keyboard focus.  
If false: "pointer focus" or "real estate model" - window 
underneath mouse pointer is automatically given keyboard 
focus, after a delay in some UIs.

UIBF_SELECT_ALWAYS_RAISES  
Set if the SELECT function always raises the window 
underneath the pointer to the front, whether in the visible 
region of the window, or inside a view that is inside the window. 
If false, the SELECT function within a view will not bring that 
window to the front.

UIBF_SELECT_DISPLAYS_MENU  
Set if SELECT and FEATURES buttons are swapped so that 
SELECT opens a menu, while FEATURES executes the default 
menu item.

UIBF_KEYBOARD_ONLY  
Set if working in keyboard only mode. Can be used by UI and 
applications to provide extensions to easy simplify keyboard 
usage. This is exclusive of UIBF_NO_KEYBOARD above.

UIBF_CLICK_GOES_THRU  
Applies only in "explicit focus" model - otherwise known as 
"click to type." Set if mouse press event which brings window to 
front should also be sent onto gadget.

UIBF_SPECIFIC_UI_COMPATIBLE  
Set if specific UI should run in compatibility mode.

UIBF_BLINKING_CURSOR  
Set if the text cursor should blink.

**Library:** Objects/uiInputC.def

----------
#### UIExpressOptions
    UIExpressOptions        record
                                    :4
        UIEO_RETURN_TO_DEFAULT_LAUNCHER :1  ; Set to have a "Return to <default
                                            ; launcher>" button in the Express Menu
        UIEO_GEOS_TASKS_LIST        :1      ; Set for list of currently running GEOS 
                                            ; applications
        UIEO_DESK_ACCESSORY_LIST    :1      ; Set for list of desk accessories 
                                            ; (applications in World/Desk Accessories
                                            ; directory)
        UIEO_MAIN_APPS_LIST         :1      ; Set for list of applications in World 
                                            ; directory
        UIEO_OTHER_APPS_LIST        :1      ; Set for hierarchial list of applications 
                                            ; in subdirectories below World directory.
        UIEO_CONTROL_PANEL          :1      ; Set for control panel area.
        UIEO_DOS_TASKS_LIST         :1      ; Set for list of available DOS tasks.
        UIEO_UTILITIES_PANEL        :1      ; Set for utilities panel area.
        UIEO_EXIT_TO_DOS            :1      ; Set for Exit to DOS trigger.
        UIEO_POSITION               UIExpressPositions:3
                                            ; Position of Express menu.
    UIExpressOptions        end

**Library:** ui.def

----------
#### UIExpressPositions
    UIExpressPositions      etype word
        UIEP_NONE               enum UIExpressPositions
        UIEP_TOP_PRIMARY        enum UIExpressPositions
        UIEP_LOWER_LEFT         enum UIExpressPositions

**Library:** ui.def

----------
    #### UIFunctionsActive
        UIFunctionsActive       record
        UIFA_SELECT     :1  ; Basic mouse function
        UIFA_MOVE_COPY  :1  ; Direct action (move/copy, "quick transfer" if 
                            ; between applications)
        UIFA_FEATURES   :1  ; Popup menu, special UI capabilities.
        UIFA_CONSTRAIN  :1  ; Set if modifier(s) designated as "constrain" 
                            ; are pressed. This flag will change with the 
                            ; state of the modifier. Note that it may 
                            ; generally NOT be used when the target object 
                            ; can infer a meaning to "Extend" or "Toggle" 
                            ; selection. (i.e. should only be used w/SELECT 
                            ; function on things like object control points).
        UIFA_PREF_A     :1
        UIFA_PREF_B     :1
        UIFA_PREF_C     :1
        ; User "preferences" Meaning varies with active function. NOTE:
        ; 1) requests followed by (D) are updated every event holding this
        ; info (Dynamic)
        ;
        ;                   A           B       C
        ; SELECT:           Toggle      Extend
        ;
        ; MOVE_COPY:        Move(D)     Copy(D)
        ;
        ; FEATURES:         Popup       Pan
        ;                   menu        View
        ;
        UIFA_IN         :1  ; Set if point (cx, dx) is inside the visual 
                            ; bounds of the object
    UIFunctionsActive       end

**Library:** Objects/uiInput.def

----------
#### UIHelpOptions
    UIHelpOptions       record
                                    :15
        UIHO_HIDE_HELP_BUTTONS      :1
    UIHelpOptions       end

UIHO_HIDE_HELP_BUTTONS  
Set to not add help buttons to various dialog boxes. Usually used on small 
screen devices where screen space is at a premium, or on a device that has a 
dedicated help button already.
Default interpretation: false (i.e., help buttons appear).

**Library:** ui.def

----------
#### UIInterfaceLevel
    UIInterfaceLevel        etype word
        UIIL_INTRODUCTORY       enum UIInterfaceLevel
        UIIL_BEGINNING          enum UIInterfaceLevel
        UIIL_INTERMEDIATE       enum UIInterfaceLevel
        UIIL_ADVANCED           enum UIInterfaceLevel
        UIIL_GURU               enum UIInterfaceLevel

UIIL_INTRODUCTORY  
This level is designed for the first-time user, or those who just 
use computers infrequently. Complex models & all but the most 
basic features are shunned in favor of metaphors & 
functionality that is easy to grasp. Ease of learning and the 
absence of anything that isn't immediately obvious are the 
most important considerations of interfaces presented at this 
level, with a focus towards providing a pleasant experience. 
Ease of quick results is very important, however prefabricated 
& limited in scope (remember PrintShop?).

Default behavior:  
In this mode, the UI protects the user from the concepts of 
"running" applications and "open" documents by letting them 
just switch to whatever application and document they wish to 
use. The UI takes care of managing the running status of 
applications and open status of documents transparently, in 
the background. Applications generally come up maximized, 
and have no window controls whatsoever (the exception here is 
desk accessories, which float on top and may be moved and 
dismissed by the user). Only one document at a time may be 
worked on, and it generally appears in a display which is 
permanently maximized. Applications where the user typically 
uses only one data file (Address book) won't have a "File" menu 
at all. Applications designed for creation of new files will have 
only "New..." & "Switch to..." options, & will automatically fetch 
and place files in a single directory. Keyboard shortcuts and 
mnemonic navigation are turned off (excepting keyboard only 
systems) Application menu structures in general are kept to a 
minimum, and advanced features are kept completely hidden, 
not even accessible through the "Options" menu.

UIIL_BEGINNING  
This level is designed for those who feel comfortable with the 
basic operation of their computer, how it works, what modules 
exist within it, etc. and wish to gain access to more of its 
capability, or need to solve a particular problem or need for 
something other than a canned solution. This level adds in a 
number; of useful features to UI-provided menus, and results in 
applications offering "options" to turn on all but the most 
advanced or short-cut oriented capabilities within them. Ease 
of Learning remains the most important aspect of the interface, 
and probability of successful usage the most important goal. 
We're trying to get the user to be able to actually *accomplish* 
things here, all on their own, with a low risk of failure. Time to 
task completion is not an issue so long as the user is able to 
figure out what the model is, how to use it, and is able to 
actually complete whatever it is they're trying to do. This may 
be accomplished via more verbose, or scripted dialogs, as 
opposed to the "set everything at once" type of dialogs seen at 
higher levels. The computer should detect abnormal or 
dangerous situations & help the user to avoid costly mistakes. 
Dangerous actions should be undoable. Options that trade 
performance against safety or recoverability will be tilted 
towards recoverability.

Default behavior:  
In this mode, the document control adds "New..", "Switch to...", 
"Quick Backup", and variety of other capabilities. Applications 
offer a way to access most of their features. The application 
launch & document models remain "transparent". applications 
continue to run full-screen. Files created by the user remain in 
one directory.

UIIL_INTERMEDIATE  
This level is designed for people familiar with the capabilities 
of the software, & who are now willing to learn a few things 
that might not otherwise be obvious in order to speed up their 
ability to get things done.

Default behavior:  
Here we introduce the user to the concepts of "running 
applications" and "open documents", and add in easy to 
understand "power" features that makes it easier to get things 
done. The user must open and close applications and 
documents to manage accessibility and performance. 
Application windows start out overlapping (except on machines 
with small screens).Adds window min/max/restore capability, 
pinned menus. Systems with both mice and keyboards get 
keyboard accelerators and mnemonic navigation. The system 
allows only one instance of any given application to be running, 
but allows multiple documents to be open within that 
application.

UIIL_ADVANCED  
This level is designed for the people who use their computer 
day in, day out, and know GEOS like the back of their hand. All 
the bells and whistles available are offered here, though still 
organized intelligently with the degree of accessibility set by 
the user -- a technical writer may live in his Word Processor, for 
instance, but venture into other applications only 
infrequently - they shouldn't all look like the cockpits of 727's. 
A reduction in the number of steps necessary to complete 
common tasks, & the speed in which this can be done becomes 
very important. The key phrases here are "powerful", "well 
designed", and "intelligent".

Default behavior:  
The UI offers the possibility of multiple instances of a given 
application, dialog-clarified. The notion of hierarchical storage 
of document files is introduced. 

UIIL_GURU  
Same as "UIIL_ADVANCED" level, but minus protective 
warning dialogs that might be annoying to someone who never 
makes mistakes. Options that trade performance against 
safety or recoverability are tilted towards performance.

**Library:** ui.def

----------
#### UIInterfaceOptions
    UIInterfaceOptions      record
        UIIO_OPTIONS_MENU                       :1
        UIIO_DISABLE_POPOUTS                    :1
        UIIO_ALLOW_INITIALLY_HIDDEN_MENU_BARS   :1
                                                :13
    UIInterfaceOptions      end

UIIO_OPTIONS_MENU  
Set if the options menu should exist.

UIIO_DISABLE_POPOUTS  
True to not allow GIV_POPOUT GenInteractions to pop in and 
out. False to allow pop in and pop out behavior.

**Library:** ui.def

----------
#### UILaunchModel
    UILaunchModel       etype word
        UILM_TRANSPARENT                enum UILaunchModel
        UILM_SINGLE_INSTANCE            enum UILaunchModel
        UILM_MULTIPLE_INSTANCES         enum UILaunchModel
        UILM_GURU                       enum UILaunchModel

UILM_TRANSPARENT  
"Transparent" application launch mode is one in which the user 
doesn't have to understand the concepts of a "running app", as 
the system takes care of launching and shutting down 
applications in the background to manage memory effectively.

-> Express menu is really just a "startup" or "switch to" menu

-> applications are shut down in background, and reloaded 
when switched to

-> Single instance limit on any given application.

-> Application windows are full screen (except for those marked 
as Desk Accessories, which float on top, and would not be 
managed transparently, i.e. would have to stay in memory until 
exited).

-> Minimize/Maximize/Restore/Close features of full-screen 
main Primary windows removed-

-> "Exit" item is eliminated from File menu.

-> Default mode for UIIL_INTRODUCTORY.

The following levels are all user-controlled, meaning that the 
user has to understand the concept of a running application, & 
must manage how many applications are running themselves.

-> Express menu allows switching between currently running 
applications.

-> By default, application windows are not maximized on 
launch, and are movable and resizable. This could be "fine 
tuned" by using window options above, however.

UILM_SINGLE_INSTANCE  
This mode allows only a single instance of any one given 
application to be running at a time.

-> Single instance limit on given application.

-> If application or document is double-clicked on, and an 
instance of the application is already running, that instance 
would be brought to the top (and any document 
opened/switched to within it, depending on the doc model).

-> Default mode for UIIL_INTERMEDIATE.

UILM_MULTIPLE_INSTANCES  
-> If application or document double-clicked on, and an 
instance of the application is already running, a dialog would 
come up asking if one of the already running applications 
should be used, or whether a new instance should be created.

-> Default mode for UIIL_ADVANCED.

UILM_GURU  
-> Like GEOS V1.2 -- the system does nothing to protect the 
user, so double-clicking on an application just launches another 
instance.

-> Default mode for UIIL_GURU.

**Library:** ui.def

----------
#### UILaunchOptions
    UILaunchOptions record
        UILO_DESK_ACCESSORIES   :1  ;TRUE if the desk accessory mode is
                                    ; supported (default = TRUE)
        UILO_CLOSABLE_APPS      :1  ;Set if all apps should be closable.
                                    ; This allows the user to close apps
                                    ; even when in transparent mode.
                                :14
    UILaunchOptions end

**Library:** ui.def

----------
#### UIWindowOptions
    UIWindowOptions     record
        UIWO_MAXIMIZE_ON_STARTUP                            :1
        UIWO_COMBINE_HEADER_AND_MENU_IN_MAXIMIZED_WINDOWS   :1
        UIWO_PRIMARY_MIN_MAX_RESTORE_CONTROLS               :1
        UIWO_WINDOW_MENU                                    :1
        UIWO_PINNABLE_MENUS                                 :1
        UIWO_KBD_NAVIGATION                                 :1
        UIWO_POPOUT_MENU_BAR                                :1
    UIWindowOptions     end

UIWO_MAXIMIZE_ON_STARTUP  
If set, applications by default would come up maximized. 
(applications marked as desk accessories would override this 
behavior).
Default interpretation under Motif: True if running on a small 
screen (less than 512 pixels in x, or 320 pixels in y), or if on 
keyboard-only machine, or if InterfaceLevel < 
UIIL_INTERMEDIATE, or if LaunchMode = 
UILM_TRANSPARENT.

UIWO_COMBINE_HEADER_AND_MENU_IN_MAXIMIZED_WINDOWS  
This is a screen space saving measure-if set, the header and 
menu areas of maximized windows is combined, such that only 
the window gadgetry, window menu and menus are left, i.e. the 
title string is eliminated. Default interpretation under Motif: 
True if running on a small screen (less than 512 pixels in x, or 
320 pixels in y).

UIWO_PRIMARY_MIN_MAX_RESTORE_CONTROLS  
If false, window gadgetry and menu items for minimizing, 
maximizing, and restoring would disappear from primary 
windows. Default interpretation under Motif: Always false if 
LaunchMode = UILM_TRANSPARENT, else true if 
InterfaceLevel >= UIIL_INTERMEDIATE.

UIWO_WINDOW_MENU  
If true, a window menu for keyboard control of 
min/max/restore/move/resize features will be provided. If false, 
only a "close" icon will appear in this space. Default 
interpretation: True if keyboardOnly = true.

UIWO_PINNABLE_MENUS  
True to allow "pinnable" menus. Default interpretation under 
Motif: True if InterfaceLevel >= UIIL_INTERMEDIATE.

UIWO_KBD_NAVIGATION  
True to allow keyboard accelerators, keyboard navigation 
Default interpretation under Motif: True if keyboard-only 
machine or InterfaceLevel >= UIIL_INTERMEDIATE.

UIWO_POPOUT_MENU_BAR  
True to allow menu bar to pop-out into a dialog box. This should 
only be allowed in very specific situations, because the specific 
UI will not always provide gadgetry to restore the menu bar if 
the dialog is closed. Default interpretation under Motif: True if 
running on a small screen (less than 512 pixels in x, or 320 
pixels in y).

**Library:** ui.def

----------
#### UIWindowOptionsInteger
    UIWindowOptionsInteger          record
        UIWOI_MASK              UIWindowOptions:8
        UIWOI_OPTIONS           UIWindowOptions:8
    UIWindowOptionsInteger          end

UIWOI_MASK
Mask of which **UIWindowOptions** in *UIWOI_value* have 
meaning. (If zero, user has made no preference for that specific 
option, and the default behavior should be used).

UIWOI_OPTIONS  
Actual **UIWindowOptions** to use (if mask bit above is set for 
any given bit).

**Library:** ui.def

----------
#### UndoActionDataFlags
    UndoActionDataFlags         struct
        UADF_flags          dword
        UADF_extraFlags     word
    UndoActionDataFlags         ends

**Library:** Objects/gProcC.def

----------
#### UndoActionDataOptr
    UndoActionDataOptr          struct
        UADO_optr           optr
    UndoActionDataOptr          ends

**Library:** Objects/gProcC.def

----------
#### UndoActionDataPtr
    UndoActionDataPtr       struct
        UADP_ptr        fptr
        UADP_size       word
    UndoActionDataPtr       ends

**Library:** Objects/gProcC.def

----------
#### UndoActionDataType
    UndoActionDataType      etype word, 0, 2
        UADT_FLAGS          enum UndoActionDataType
        UADT_PTR            enum UndoActionDataType
        UADT_VM_CHAIN           enum UndoActionDataType
        UADT_OPTR           enum UndoActionDataType

UADT_FLAGS  
The passed data is of type **UndoActionFlags**.

UADT_PTR  
The passed data is of type **UndoActionDataPtr**.

UADT_VM_CHAIN  
The passed data is of type **UndoActionVMChain**.

UADT_OPTR  
This is not a valid type to pass to 
MSG_GEN_PROCESS_ADD_ACTION; it is used by the undo code 
when playing back an action of type UADT_PTR.

If MSG_GEN_PROCESS_UNDO_ADD_ACTION is called with an action of type 
UADT_PTR, if the action is played back, the data will be returned to the object 
with type UADT_OPTR (via MSG_META_UNDO). Calling 
MSG_GEN_PROCESS_ADD_ACTION can cause previously-sent actions to 
move, so the optr should be re-dereferenced after sending this message.

**Library:** Objects/gProcC.def

----------
#### UndoActionDataUnion
    UndoActionDataUnion         union
        UADU_flags          UndoActionDataFlags
        UADU_ptr            UndoActionDataPtr
        UADU_vmChain        UndoActionDataVMChain
        UADU_optr           UndoActionDataOptr
    UndoActionDataUnion         ends

**Library:** Object/gProcC.def

----------
#### UndoActionDataVMChain
    UndoActionDataVMChain           struct
        UADVMC_vmChain          dword
        UADVMC_file             hptr
    UndoActionDataVMChain           ends

This structure is filled in by the undo code for MSG_META_UNDO. VM Chains 
passed to MSG_GEN_PROCESS_UNDO_ADD_ACTION should lie in the undo 
file (which can be obtained by sending 
MSG_GEN_PROCESS_UNDO_GET_FILE).

**Library:** Objects/gProcC.def

----------
#### UndoActionStruct
    UndoActionStruct        struct
        UAS_dataType            UndoActionDataType
        UAS_data                UndoActionDataUnion
        UAS_appType             dword
    UndoActionStruct        ends

*UAS_dataType* stores the type of data passed in **UndoActionDataUnion**.

*UAS_data* stores the data to be stored with the action.

*UAS_appType* stores two extra words of data to be sent with 
MSG_META_CLIPBOARD_UNDO that indicate the type of action we are 
undoing. 

**Library:** Objects/gProcC.def

----------
#### UndoDescription
    UndoDescription     etype byte
        UD_UNDO             enum UndoDescription
        UD_REDO             enum UndoDescription
        UD_NOT_UNDOABLE     enum UndoDescription

UD_UNDO  
Passed in **NotifyUndoStateChange** if there is an active undo 
chain.

UD_REDO  
Passed in **NotifyUndoStateChange** if there is an active 
*redo* chain.

UD_NOT_UNDOABLE  
Passed in **NotifyUndoStateChange** if the last action was not 
undoable. Must pass 0:0 as title.

**Library:** Objects/gEditCC.def

----------
#### UpdateUIDataBlk
    UpdateUIDataBlk     struct
        UUIDB_formatDataVMFileHan   word
        UUIDB_formatDataVMBlkHan    word
        UUIDB_curFormatToken        FormatIdType    ;Current format token
    UpdateUIDataBlk     ends

**Library:** math.def

----------
#### UpdateWindowFlags
    UpdateWindowFlags       record
        UWF_ATTACHING               :1
        UWF_DETACHING               :1
        UWF_RESTORING_FROM_STATE    :1
        UWF_FROM_WINDOWS_LIST       :1
                                    :12
    UpdateWindowFlags       end

UWF_ATTACHING  
Set if MSG_META_UPDATE_WINDOW is being sent because 
application is attaching.

UWF_DETACHING  
Set if MSG_META_UPDATE_WINDOW is being sent because 
application is detaching.

UWF_RESTORING_FROM_STATE  
Set if application is restoring from state (will only be set if 
UWF_ATTACHING is also set, i.e. application is attaching).

UWF_FROM_WINDOWS_LIST  
Set if MSG_META_UPDATE_WINDOW is sent to this object 
because this object was on the GenApplication's 
GAGCNLT_WINDOWS GCN list, and not from a subsequent 
"build-on-demand" request. (This will only be set if 
UWF_ATTACHING is also set, i.e. application is attaching)

**Library:** Objects/metaC.def

----------
#### UserDoDialogStruct
    UserDoDialogStruct          struct
        UDDS_callingThread              hptr
        UDDS_semaphore                  hptr
        UUDS_response                   word
        UUDS_complete                   word
        UUDS_boxRunByCurrentThread      word
        UUDS_dialog                     optr
        UUDS_queue                      hptr
    UserDoDialogStruct          ends

This structure is passed to 
MSG_GEN_INTERACTION_INITIATE_BLOCKING_THREAD_ON_RESPONSE.

*UDDS_callingThread* stores the handle of the thread that is waiting for this 
dialog to come down. If 0, the thread has no event queue, and is instead 
blocking on *UDDS_semaphore*.

*UDDS_semaphore* stores the handle of a the semaphore that a 
non-event-driven thread is blocking on. See note above.

*UDDS_response* stores the response value returned by the dialog to 
**UserDoDialog**. It is most often a value from the enumerated type 
**InteractionCommand**.

*UDDS_complete* is set non-zero upon dialog completion. *UDDS_reponse* should 
be set before *UDDS_complete* is set non-zero.

*UDDS_boxRunByCurrentThread* is set non-zero if the box is run by the 
current thread.

*UDDS_dialog* stores the optr of the dialog that is currently up. This optr is 
needed internally by **UserDoDialog** for loop dispatching mode, to help 
ascertain which events should be dispatched and which saved off.

*UDDS_queue* stores the backed up queue of events arriving for the thread, but 
not dispatched due to the determination that they weren't relevant to the 
dialog's operation. These are reinserted into the queue upon completion of 
the dialog.

**Library:** Objects/gInterC.def

----------
#### UtilAsciiToHexError
    UtilAsciiToHexError         etype word
        UATH_NON_NUMERIC_DIGIT_IN_STRING    enum UtilAsciiToHexError
        UATH_CONVERT_OVERFLOW               enum UtilAsciiToHexError

**Library:** system.def

----------
#### UtilHexToAsciiFlags
    UtilHexToAsciiFlags         record
                                        :11
        UHTAF_SBCS_STRING               :1
        UHTAF_THOUSANDS_SEPARATORS      :1 
        UHTAF_SIGNED_VALUE              :1
        UHTAF_INCLUDE_LEADING_ZEROS     :1
        UHTAF_NULL_TERMINATE            :1
    UtilHexToAsciiFlags         end

**Library:** system.def

[Structures S-S](asmstrss.md) <-- [Table of Contents](../asmref.md) &nbsp;&nbsp; --> [Structures V-Z](asmstrvz.md)

