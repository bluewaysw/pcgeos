## 3.6 Structures S-S

----------
#### SampleFormat
	SampleFormat		record
		SMID_format			DAC_SampleFormat:15
		SMID_refernce		DAC_ReferenceByte:1
	SampleFormat		end

**Library:** sound.def

----------
#### SampleFormatDescription
	SampleFormatDescription			struct
		SFD_manufact			ManufacturerID
		SFD_format				SampleFormat
		SFD_rate				word
		SFD_playFlags			DACPlayFlags
	SampleFormatDescription			ends

**Library:** sound.def

----------
#### SamplesStruc
	SamplesStruc		struc
		SS_sample1Str		char FLOAT_TO_ASCII_HUGE_BUF_LEN dup (?)
		SS_sample2Str		char FLOAT_TO_ASCII_HUGE_BUF_LEN dup (?)
		SS_formatPosStr		char FLOAT_TO_ASCII_HUGE_BUF_LEN dup (?)
		SS_formatNegStr		char FLOAT_TO_ASCII_HUGE_BUF_LEN dup (?)
	SamplesStruc		ends

**Library:** math.def

----------
#### SansFace
	SansFace		etype byte
		SF_A_OPEN			enum SansFace, 0
		SF_A_CLOSED			enum SansFace, 0x80

There is not much to distinguish between these typefaces. We've decided to 
use the style of the lower case "a" character -- that is, whether it is "closed" 
(looks like a modified "o" character) or "open" (has a smaller closed portion at 
the bottom, and an extra stem on top).

**Library:** fontID.def

----------
#### ScaleChangedParams
	ScaleChangedParams			struct
		SCP_scaleFactor		PointWWFixed	;new scale factor
		SCP_window			lptr Window		;window of view
	ScaleChangedParams			ends

**Library:** Objects/gViewC.def

----------
#### ScaleViewParams
	ScaleViewParams		struct
		SVP_scaleFactor		PointWWFixed		;new, absolute scale factor
		SVP_unused			byte
		SVP_type			ScaleViewType		;type of scaling to perform
		SVP_point			PointDWord			;point to scale around
	ScaleViewParams		ends

**Library:** Objects/gViewC.def

----------
#### ScaleViewType
	ScaleViewType		etype byte
		SVT_AROUND_UPPER_LEFT 			enum ScaleViewType
		SVT_AROUND_CENTER				enum ScaleViewType
		SVT_AROUND_POINT				enum ScaleViewType

SVT_AROUND_UPPER_LEFT  
Upper left corner of subview is kept fixed as we scale.

SVT_AROUND_CENTER  
Center of subview kept fixed as we scale.

SVT_AROUND_POINT  
Point specified in *SVP_point* is kept fixed as we scale.

**Library:** Objects/gViewC.def

----------
#### ScannerToken
	ScannerToken		struct
		ST_type		ScannerTokenType	; The type of token
		ST_data		ScannerTokenData	; The data associated with the token
	ScannerToken		ends

**Library:** parse.def

----------
#### ScannerTokenCellData
	ScannerTokenCellData			struct
		STCD_cellRef			CellReference <>
	ScannerTokenCellData			ends

**Library:** parse.def

----------
#### ScannerTokenData
	ScannerTokenData	union
		STD_number			ScannerTokenNumberData
		STD_string			ScannerTokenStringData
		STD_cell			ScannerTokenCellData
		STD_identifier		ScannerTokenIdentifierData
		STD_operator		ScannerTokenOperatorData
	ScannerTokenData	end

**Library:** parse.def

----------
#### ScannerTokenIdentifierData
	ScannerTokenIdentifierData				struct
		STID_start		word	; The offset to the start of the identifier
	ScannerTokenIdentifierData				ends

**Library:** parse.def

----------
#### ScannerTokenNumberData
	ScannerTokenNumberData			struct
		STND_value			FloatNum		; 8 byte constant
	ScannerTokenNumberData			ends

**Library:** parse.def

----------
#### ScannerTokenOperatorData
	ScannerTokenOperatorData				struct
		STOD_operatorID		OperatorType	; Identifier for this operator
	ScannerTokenOperatorData				ends

**Library:** parse.def

----------
#### ScannerTokenStringData
	ScannerTokenStringData		struct
		STSD_start		word		; Offset to start of string
		STSD_length		word		; Length of the string
	ScannerTokenStringData		ends

**Library:** parse.def

----------
#### ScannerTokenType
	ScannerTokenType		etype byte, 0, 1
		SCANNER_TOKEN_NUMBER			enum ScannerTokenType
		SCANNER_TOKEN_STRING			enum ScannerTokenType
		SCANNER_TOKEN_CELL				enum ScannerTokenType
		SCANNER_TOKEN_END_OF_EXPRESSION	enum ScannerTokenType
		SCANNER_TOKEN_OPEN_PAREN		enum ScannerTokenType
		SCANNER_TOKEN_CLOSE_PAREN		enum ScannerTokenType
		SCANNER_TOKEN_IDENTIFIER		enum ScannerTokenType
		;
		; All the items above are in common with the ParserTokenType list.
		; You can add or delete items below this point without changing
		; the other table.
		;
		SCANNER_TOKEN_OPERATOR			enum ScannerTokenType
		SCANNER_TOKEN_LIST_SEPARATOR	enum ScannerTokenType

**Library:** parse.def

----------
#### ScriptFace
	ScriptFace		etype byte
		SF_CALLIGRAPHIC	enum ScriptFace, 0		; variable thickness stroke
		SF_CURSIVE		enum ScriptFace, 0x80	; single thickness stroke

**Library:** fontID.def
----------
#### ScrollAction
	ScrollAction		etype byte
		SA_NOTHING 					enum ScrollAction
		SA_TO_BEGINNING 			enum ScrollAction
		SA_PAGE_BACK 				enum ScrollAction
		SA_INC_BACK 				enum ScrollAction
		SA_INC_FWD 					enum ScrollAction
		SA_DRAGGING 				enum ScrollAction
		SA_PAGE_FWD 				enum ScrollAction
		SA_TO_END 					enum ScrollAction
		SA_SCROLL					enum ScrollAction
		SA_SCROLL_INTO				enum ScrollAction
		SA_INITIAL_POS				enum ScrollAction
		SA_SCALE					enum ScrollAction
		SA_PAN						enum ScrollAction
		SA_DRAG_SCROLL				enum ScrollAction
		SA_SCROLL_FOR_SIZE_CHANGE 	enum ScrollAction

SA_NOTHING  
No scroll action.

SA_TO_BEGINNING  
Scrolls to beginning of window.

SA_PAGE_BACK  
Scrolls up a page.

SA_INC_BACK  
Scrolls up a small amount.

SA_INC_FWD  
Scrolls down a small amount.

SA_DRAGGING  
Scrolls dragging.

SA_PAGE_FWD  
Scrolls down a page.

SA_TO_END  
Scrolls to end of window.

SA_SCROLL  
Generic scroll method called.

SA_SCROLL_INTO  
Someone called "scroll into" to keep a point onscreen.

SA_INITIAL_POS  
Initial scrolling position. Output object will receive relative 
scroll values equal to the initial origin.

SA_SCALE  
We're scaling. There may or may not be a change in scroll in 
scroll position, but certainly the subview size will have 
changed.

SA_PAN  
Panning. Otherwise exactly like SA_SCROLL.

SA_DRAG_SCROL  L
Select-scrolling. Otherwise exactly like SA_SCROLL.

SA_SCROLL_FOR_SIZE_CHANGE  
Any scrolling that's required as a result of the view size change

**Library:** Objects/gViewC.def

----------
#### ScrollFlags
	ScrollFlags		record
		SF_VERTICAL					:1
		SF_ABSOLUTE					:1
		SF_DOC_SIZE_CHANGE			:1
		SF_WINDOW_NOT_SUSPENDED		:1
		SF_SCALE_TO_FIT				:1
		SF_SETUP_HAPPENED			:1
		SF_EC_SETUP_CALLED			:1
									:1
	ScrollFlags		end

SF_VERTICAL  
Direction of scroll. Invalid for SA_SCROLL_INTO, SA_SCROLL, 
SA_INITIAL_POS.

SF_ABSOLUTE  
Whether the scroll is to an absolute position. Set for 
SA_TO_BEGINNING, SA_TO_END, SA_INITIAL_POS, 
SA_SCROLL_INTO, SA_DRAGGING, and some SA_SCROLL 
events.

SF_DOC_SIZE_CHANGE  
This scroll is happening as an adjustment for a document size 
change. The specific UI uses this to finish changing the 
document size after the tracking is complete.

SF_WINDOW_NOT_SUSPENDED  
An internal flag that the view uses to know whether to 
unsuspend the view window after the track scrolling 
arguments are returned by the view output. Usually the view 
window is suspended beforehand, but not if the window hasn't 
been opened yet.

SF_SCALE_TO_FIT  
Set if the view is in scale to fit mode (which often causes content 
to alter its scrolling behavior).

SF_SETUP_HAPPENED  
Flag for error checking only, to ensure that people are handling 
the normalize and calling the appropriate setup and return 
routines.

**Library:** Objects/gViewC.def

----------
#### SearchFromOffsetFlags

SearchFromOffsetFlags			record

SFOF_STOP_AT_STARTING_POINT					:1

SearchFromOffsetFlags			end

SFOF_STOP_AT_STARTING_POINT
Set (internally) if this search has wrapped around.

**Library:** Objects/vTextC.def

----------
#### SearchFromOffsetReturnStruct
	SearchFromOffsetReturnStruct				struct
		SFORS_object			optr (?)
		SFORS_offset			dword (?)
		SFORS_len				dword (?)
	SearchFromOffsetReturnStruct				ends

*SFORS_object* stores the pointer to the object that the match was found in (or 
0:0 if not found).

*SFORS_offset* stores the offset into the object where the match was found (a 
**VisTextRange**)

*SFORS_len* stores the length of the match.

**Library:** Objects/vTextC.def

----------
#### SearchFromOffsetStruct
	SearchFromOffsetStruct			struct
		SFOS_data			hptr.SearchReplaceStruct
		SFOS_startObject	optr
		SFOS_startOffset	dword
		SFOS_currentOffset	dword
		SFOS_flags			SearchFromOffsetFlags
		SFOS_retStruct		fptr.SearchFromOffsetReturnStruct
		even
	SearchFromOffsetStruct			ends

*SFOS_data* stores the handle of the data block. This data is organized in the 
following format:  
**SearchReplaceStruct**<>  
data - Null-Terminated Search string  
data - Null-Terminated Replace string

*SFOS_startObject* stores the OD of the object where the current search began.

*SFOS_startOffset* stores the offset into the object where the current search 
began. This offset is not an offset to a character, but rather an offset between 
characters. (I.e. the beginning of an object is 0, between the first and second 
characters = 1, etc.) (This value can range from 0 to <text size>).

*SFOS_currentOffset* stores the offset between characters in the text object to 
start search. (This value can range from 0 to <text size>).

*SFOS_retStruct* stores a pointer to a buffer to store the return values.

**Library:** Objects/vTextC.def

----------
#### SearchOptions
	SearchOptions		record
												:2
		SO_NO_WILDCARDS							:1
		SO_IGNORE_SOFT_HYPHENS					:1
		SO_BACKWARD_SEARCH						:1
		SO_IGNORE_CASE							:1
		SO_PARTIAL_WIDTH						:1
		SO_PRESERVE_CASE_OF_DOCUMENT_STRING		:1
	SearchOptions		end

SO_NO_WILDCARDS  
Set if you want to treat wildcard chars as literal chars.

SO_IGNORE_SOFT_HYPHENS  
Set if you want to treat soft hyphens in the "searched-in" text 
as if they do not exist. If the string we are trying to match 
contains soft hyphens, do not set this flag or the strings will 
never match.

SO_BACKWARD_SEARCH  
Set if the user wants to search backward.

SO_IGNORE_CASE  
Set if you want to ignore case when searching for strings.

SO_PARTIAL_WORD  
Set if you want to match partial words when searching for 
strings.

SO_PRESERVE_CASE_OF_DOCUMENT_STRING  
If set, will preserve the case of the occurrence of the search 
string when replacing (will modify the replace string before 
replacing it).

**Library:** Objects/vTextC.def

----------
#### SearchReplaceEnableFlags
	SearchReplaceEnableFlags			record
		SREF_SEARCH		:1	; Set if the object can handle searches
		SREF_REPLACE	:1	; Set if the object can handle replaces
	SearchReplaceEnableFlags			end

**Library:** Objects/Text/tCtrlC.def

----------
#### SearchReplaceFocusInfo
	SearchReplaceFocusInfo			etype byte
		SRFI_SEARCH_TEXT				enum SearchReplaceFocusInfo
	SRFI_REPLACE_TEXT				enum SearchReplaceFocusInfo

**Library:** Objects/Text/tCtrlC.def

----------
#### SearchReplaceStruct
	SearchReplaceStruct		struct
		SRS_searchSize			word
		SRS_replaceSize			word
		SRS_params				SearchOptions
		SRS_replyObject			optr
		SRS_replyMsg			word
		SRS_searchString		label char
	SearchReplaceStruct		ends

*SRS_searchSize* stores the number of characters in the search string 
(including the null terminator).

*SRS_replaceSize* stores the number of characters in the replace string 
(including the null terminator).

*SRS_params* stores the parameters for the search and replace operation.

*SRS_replyObject* stores the OD of the object to send the string-not-found 
message in *SRS_replyMsg* to.

*SRS_replyMsg* stores the message sent to the *SRS_replyObject* if the string 
was not found.

*SRS_searchString* defines the start of the search string.

**Library:** Objects/vTextC.def

----------
#### SelectionDataType
	SelectionDataType		etype word
		SDT_TEXT				enum SelectionDataType
		SDT_GRAPHICS			enum SelectionDataType
		SDT_SPREADSHEET			enum SelectionDataType
		SDT_INK					enum SelectionDataType
		SDT_OTHER				enum SelectionDataType

**Library:** Objects/gEditCC.def

----------
#### SelectionType
	SelectionType		etype byte
		ST_DOING_CHAR_SELECTION				enum SelectionType
		ST_DOING_WORD_SELECTION				enum SelectionType
		ST_DOING_LINE_SELECTION				enum SelectionType
		ST_DOING_PARA_SELECTION				enum SelectionType

**Library:** Objects/vTextC.def

----------
#### SemaphoreError
	SemaphoreError		etype word
		SE_NO_ERROR					enum SemaphoreError
		SE_TIMEOUT					enum SemaphoreError
		SE_PREVIOUS_OWNER_DIED		enum SemaphoreError

**Library:** sem.def

----------
#### SerifFace
	SerifFace		etype byte, 0
		SF_OLD			enum SerifFace, 0
		SF_TRANS		enum SerifFace, 0x40
		SF_MODERN		enum SerifFace, 0x80
		SF_SLAB			enum SerifFace, 0xc0

SF_OLD  
Old Style. Characterized by axes of curves inclined to left, 
smooth transitions to serifs, little contrast between hair-lines 
and main strokes.

SF_TRANS  
Transitional. Characterized by axes of round characters barely 
inclined, serifs are flat, contrast between hair-lines and main 
strokes is more accentuated.

SF_MODERN  
Modern. Characterized by axes of round chars are vertical, 
serifs are horizontal and unbracketed, extremely high contrast 
between hairlines and main strokes.

SF_SLAB  
Slab Serif. All strokes appear to have the same thickness, serifs 
are usually unbracketed

**Library:** fontID.def

----------
#### SetDateTimeParams
	SetDateTimeParams		record
		SDTP_SET_DATE			:1	;TRUE: set date (must be bit 7)
		SDTP_SET_TIME			:1	;TRUE: set time (must be bit 6)
								:6
	SetDateTimeParams		end

**Library:** timedate.def

----------
#### SetPalElement
	SetPalElement		 struct
		SPE_entry		byte			; palette entry number
		SPE_color		RGBValue <>		; color to set that entry
	SetPalElement	 	ends

This structure is passed to GrSetPalette.

**Library:** color.def

----------
#### SetSizeArgs
	SetSizeArgs		struct
		SSA_width		SpecWidth <>	;Width of the composite
		SSA_height		SpecHeight <>	;Height of each child
		SSA_count		sword			;Number of children, or zero if not 
										;applicable
		SSA_updateMode	VisUpdateMode	;Update mode to perform geometry redos
		align			word
	SetSizeArgs		ends

**Library:** Objects/genC.def

----------
#### ShadowAnchor
	ShadowAnchor		etype byte
		SA_TOP_LEFT				enum ShadowAnchor
		SA_TOP_RIGHT			enum ShadowAnchor
		SA_BOTTOM_LEFT			enum ShadowAnchor
		SA_BOTTOM_RIGHT			enum ShadowAnchor

**Library:** Objects/Text/tCommon.def

----------
#### ShiftState
	ShiftState		record
		SS_LALT				:1	;Set if left ALT modifier
		SS_RALT				:1	;Set if right ALT modifier
		SS_LCTRL			:1	;Set if left CTRL modifier
		SS_RCTRL			:1	;Set if right CTRL modifier
		SS_LSHIFT			:1	;Set if left SHIFT modifier
		SS_RSHIFT			:1	;Set if right SHIFT modifier
		SS_FIRE_BUTTON_1	:1	;Set if fire button1 modifier
		SS_FIRE_BUTTON_2	:1	;Set if fire button1 modifier
	ShiftState		end

**Library:** input.def

----------
#### SortableArrayElement
	SortableArrayElement			struct
		SAE_OD		optr
		SAE_key		DWFixed
	SortableArrayElement			ends

**Library:** grobj.def

----------
#### SortableArrayHeader
	SortableArrayHeader			struct
		SAH_CAH						ChunkArrayHeader
		SAH_originalArray			optr
	SortableArrayHeader			ends

**Library:** grobj.def

----------
#### SortedNameArrayFindFlags
	SortedNameArrayFindFlags			record
		SNAFF_IGNORE_CASE			:1
	SortedNameArrayFindFlags			end

**Library:** config.def

----------
#### SoundBasicStatus
	SoundBasicStatus		struct
		SBS_blockHandle		word 0				; handle of block
		SBS_ID				word SOUND_ID		; Says this struct is a sound
		SBS_mutExSem		hptr 0				; mutual exclusive sempahore
		SBS_type			SoundType 0			; the type of block
		SBS_priority		SoundPriority 0		; current priority
		SBS_EOS				EndOfSongFlags 0	; what to do at EOS
	SoundBasicStatus		ends

This structure stores a number of pieces of information that are common to 
all sounds. This structure is an entry within the basic Sound structure.

**Library:** sound.def

----------
#### SoundControl
	SoundControl		struct
		SC_status			SoundBasicStatus
		SC_format			SoundFormatStatus
		SC_position			SoundPositionStatus
		SC_voice			label SoundVoiceStatus
	SoundControl ends

**Library:**		sound.def

----------
#### SoundDACStatus
	SoundDACStatus		struct
		SDACS_rate			word 0				; sample rate of sound
		SDACS_format		DACSampleFormat 0	; sample format of sound
		SDACS_manufactID	ManufacturerID0		; sample ManufacturerID
	SoundDACStatus		ends

**Library:** sound.def

----------
#### SoundErrors
	SoundErrors					etype   word, 0, 2
		SOUND_ERROR_NO_ERROR 						enum	SoundErrors
		SOUND_ERROR_EXCLUSIVE_ACCESS_GRANTED 		enum	SoundErrors
		SOUND_ERROR_OUT_OF_MEMORY 					enum	SoundErrors
		SOUND_ERROR_UNABLE_TO_ALLOCATE_STREAM 		enum	SoundErrors
		SOUND_ERROR_HARDWARE_NOT_AVAILABLE 			enum	SoundErrors
		SOUND_ERROR_FAILED_ATTACH_TO_HARDWARE 		enum	SoundErrors
		SOUND_ERROR_HARDWARE_DOESNT_SUPPORT_FORMAT 	enum	SoundErrors
		SOUND_ERROR_DAC_UNATTACHED 					enum	SoundErrors
		SOUND_ERROR_STREAM_DESTROYED 				enum	SoundErrors

**Library:** sound.def

----------
#### SoundFMStatus
	SoundFMStatus		struct
		SFMS_timerHandle	hptr 0		; current timer handle
		SFMS_timerID		word 0		; current timer ID
		SFMS_timeRemaining	word 0		; Number of 65535 msec left to event
		SFMS_tempo			word 0		; Number of msec per 64th note
		SFMS_voicesUsed		byte 0		; Number of voices used in stream
	SoundFMStatus		ends

**Library:** sound.def

----------
#### SoundFormatStatus
	SoundFormatStatus		union
		SFS_fm		SoundFMStatus
		SFS_dac		SoundDACStatus
	SoundFormatStatus		ends

**Library:** sound.def

----------
#### SoundFunction
	SoundFunction		etype word, DriverFunction, 2
		DR_SOUND_ENTER_LIBRARY_ROUTINE	enum SoundFunction
		DR_SOUND_EXIT_LIBRARY_ROUTINE	enum SoundFunction
		DR_SOUND_ALLOC_MUSIC			enum SoundFunction
		DR_SOUND_ALLOC_MUSIC_STREAM		enum SoundFunction
		DR_SOUND_ALLOC_MUSIC_NOTE		enum SoundFunction
		DR_SOUND_REALLOC_MUSIC			enum SoundFunction
		DR_SOUND_REALLOC_MUSIC_NOTE		enum SoundFunction
		DR_SOUND_PLAY_MUSIC				enum SoundFunction
		DR_SOUND_PLAY_TO_MUSIC_STREAM	enum SoundFunction
		DR_SOUND_STOP_MUSIC				enum SoundFunction
		DR_SOUND_STOP_MUSIC_STREAM		enum SoundFunction
		DR_SOUND_INIT_MUSIC				enum SoundFunction
		DR_SOUND_FREE_SIMPLE			enum SoundFunction
		DR_SOUND_FREE_STREAM			enum SoundFunction
		DR_SOUND_CHANGE_OWNER_SIMPLE	enum SoundFunction
		DR_SOUND_CHANGE_OWNER_STREAM	enum SoundFunction
		DR_SOUND_ALLOC_SAMPLE_STREAM	enum SoundFunction
		DR_SOUND_ENABLE_SAMPLE_STREAM	enum SoundFunction
		DR_SOUND_PLAY_TO_SAMPLE_STREAM	enum SoundFunction
		DR_SOUND_DISABLE_SAMPLE_STREAM	enum SoundFunction
		DR_SOUND_FREE_SAMPLE_STREAM		enum SoundFunction

**Library:** sound.def

----------
#### SoundPositionStatus
	SoundPositionStatus			union
		SSS_simple		SoundSimpleStatus
		SSS_stream		SoundStreamStatus
	SoundPositionStatus			end

**Library:** sound.def

----------
#### SoundPriority
	SoundPriority		etype word, 10, 10
		SP_SYSTEM_LEVEL		enum SoundPriority
		SP_ALARM			enum SoundPriority
		SP_STANDARD			enum SoundPriority
		SP_GAME				enum SoundPriority
		SP_BACKGROUND		enum SoundPriority

		SP_IMMEDIATE		equ -1
		SP_THEME			equ +1

**Library:** sound.def

----------
#### SoundSimpleStatus
	SoundSimpleStatus			struct
		SSS_songBuffer		fptr 0			; fptr to song buffer
		SSS_songPointer		nptr 0			; current place in song
	SoundSimpleStatus			ends

**Library:** sound.def

----------
#### SoundStreamDeltaTimeType
	SoundStreamDeltaTimeType		etype word, SoundStreamEvent, 2
		SSDTT_MSEC			enum SoundStreamDeltaTimeType
		SSDTT_TICKS			enum SoundStreamDeltaTimeType
		SSDTT_TEMPO			enum SoundStreamDeltaTimeType	

Between each event is the delay time from the current event to the next 
event. The value can be either in msec (giving a maximum delay of 65.535 
seconds, in ticks (giving a maximum delay of ~18 minutes, or in 1/64th notes 
(depends on the tempo).

**Library:** sound.def

----------
#### SoundStreamEvent
	SoundStreamEvent		etype word, 0, 2
		SSE_VOICE_ON			enum SoundStreamEvent
		SSE_VOICE_OFF			enum SoundStreamEvent
		SSE_CHANGE				enum SoundStreamEvent
		SSE_GENERAL				enum SoundStreamEvent

A sound stream is just made up of a bunch of events.

**Library:** sound.def

----------
#### SoundStreamSize
	SoundStreamSize		etype	word
		SSS_ONE_SHOT 		enum	SoundStreamSize, 128; bytes
		SSS_SMALL 			enum	SoundStreamSize, 256; bytes
		SSS_MEDIUM 			enum	SoundStreamSize, 512; bytes
		SSS_LARGE 			enum	SoundStreamSize, 1024; bytes

**Library:** sound.def

----------
#### SoundStreamState
	SoundStreamState	record
		SSS_active 			:1 	; does a reader exist?
		SSS_destroying 		:1 	; is it being destroyed?
		SSS_locked 			:1 	; still an outstanding lock?
							:5
	SoundStreamState	end

**Library:** sound.def

----------
#### SoundStreamStatus
	SoundStreamStatus		struct
		SSS_streamToken			word 0				; stream handle
		SSS_streamSegment		word 0				; stream segment
		SSS_dataSem				Semaphore <1,>		; all data on stream?
		SSS_activeReaderSem		Semaphore <1,>		; reader currently on?
		SSS_writerSem			Semaphore <1,>		; writer mutEx sem
		SSS_buffer				fptr 0				; fptr to buffer
		SSS_dataRemaining		word 0				; Number of bytes left
		SSS_dataOnStream		word 0				; Number of events/samples
		SSS_streamState			SoundStreamState	; state of stream
	SoundStreamStatus		ends

**Library:** sound.def

----------
#### SoundType
	SoundType		etype word, 0, 2
		ST_SIMPLE_FM			enum SoundType
		ST_STREAM_FM			enum SoundType
		ST_SIMPLE_DAC			enum SoundType
		ST_STREAM_DAC			enum SoundType

There are a couple of different types of sounds. The first category is where it 
is stored. A simple sound is played from fixed memory. Simple. A stream 
sound is played from a stream. The second category is the type of sound. 
Currently, two formats can't be mixed. A sound can be a Frequency 
Modulation sound. A sound can also be a store digitally and converted to 
analog.

**Library:** sound.def

----------
#### SoundVoiceStatus
	SoundVoiceStatus		struct
		SVS_instrument			fptr.InstrumentEnvelope 0
		SVS_physicalVoice		word 0
								word 0
	SoundVoiceStatus		ends

For every FM sound, whether simple or stream, the VoiceManager must be 
able to tell what the current instrument is and which voice (if any) the stream 
is currently using. It needs to do this for two reasons:  
1) whenever a note gets played the voice has to be initialized to 
match what the stream thinks is on the voice.  
2) when a stream issues a voice off command, the stream 
manager needs to know which voice to actually turn off.

The **SoundVoiceStatus** structure stores these two pieces of information.

**Library:** sound.def

----------
#### SpecAttrs
	SpecAttrs		record
		SA_ATTACHED						:1
		SA_REALIZABLE					:1
		SA_BRANCH_MINIMIZED				:1
		SA_USES_DUAL_BUILD				:1
		SA_CUSTOM_VIS_PARENT			:1
		SA_SIMPLE_GEN_OBJ				:1
		SA_CUSTOM_VIS_PARENT_FOR_CHILD	:1
		SA_TREE_BUILT_BUT_NOT_REALIZED	:1
	SpecAttrs		end

SA_ATTACHED  
For WIN_GROUP's only (Ignored if non-WIN-GROUP object). Set 
for normal operation, clear if application is being shutdown, & 
therefore windows should be closed down, even if the 
VA_VISIBLE bit is set.

SA_REALIZABLE  
For WIN_GROUP's only (Ignored if non-WIN_GROUP object). Set 
to indicate that the specific UI think's it is OK to make this 
object visual. It will not be set visual until the object is also 
USABLE and ATTACHED. This is the "specific UI's vote" for 
whether or not this WIN_GROUP should appear on screen.

SA_BRANCH_MINIMIZED  
Set if this generic object is "minimized" and specific UI wants to 
force all generic children in the branch to become non-visible. 
If this bit is set, the no objects in the generic branch below this 
point which have WIN_GROUP parts 	will be allowed to be 
visible.

SA_USES_DUAL_BUILD  
Set for objects which behave as both a non-WIN_GROUP and a 
WIN_GROUP, and thus require two separate visible builds in 
order to get built. This is done by allowing it to act as both a 
WIN_GROUP object, which gets its own SPEC_BUILD, & as a 
simple object, which will receive a SPEC_BUILD from up above 
itself in the hierarchy.

SA_CUSTOM_VIS_PARENT  
Set for generic objects which will not just be attached visually 
to their generic parent. Causes a MSG_SPEC_GET_VIS_PARENT 
to be sent out to determine what visual object the object should 
be placed on (in the default MSG_SPEC_BUILD handler)

SA_SIMPLE_GEN_OBJ  
Set for generic objects which become a single visible object, via 
the Vis/ Specific/Gen master class scheme. If this bit is set, then 
MSG_GEN_GET_SPECIFIC_VIS_OBJECT need not sent out to 
determine what visible object the gen object has/will become. is 
both a generic & visual object.

SA_CUSTOM_VIS_PARENT_FOR_CHILD  
Set for objects who want to use a different visual parent for 
their generic children than themselves. If this bit is set, 
children will send out a 
MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD to this 
object.

SA_TREE_BUILT_BUT_NOT_REALIZED  
For WIN_GROUP's only, this bit is set whenever the tree has 
been specifically built, but is now unrealized. The object is not 
actually in a visible composite when this bit is set, although it 
appears this way, since the object is given a one-way visible link 
upward. Having a one-way link is far superior to our old 
message of removing the WIN_GROUP from the visible tree, as 
this required an exception handling when setting an object 
immediately under a WIN_GROUP usable, in trying to figure 
out whether we needed to SPEC_BUILD it right away (the old 
message never did work). This way, if *VI_link* is non-zero, then 
the whole tree (all usable objects) is vis-built, and should be 
maintained that way. Also, this makes for quicker setting of 
such a WIN_GROUP to be realized again, as we can just add the 
object to the parent link stored in *VI_link*, without having to 
send a recursive MSG_SPEC_BUILD_BRANCH down the tree.

**Library:** Objects/visC.def

----------
#### SpecBuildFlags
	SpecBuildFlags		record
		SBF_IN_UPDATE_WIN_GROUP							:1
		SBF_WIN_GROUP									:1
		SBF_TREE_BUILD									:1
		SBF_VIS_PARENT_WITHIN_SCOPE_OF_TREE_BUILD		:1
		SBF_SKIP_CHILD									:1
		SBF_FIND_LAST									:1
		SBF_VIS_PARENT_UNBUILDING						:1
		SBF_VIS_PARENT_FULLY_ENABLED					:1
														:6
		SBF_UPDATE_MODE									:2
	SpecBuildFlags		end

SBF_IN_UPDATE_WIN_GROUP 
Used for Building only (Not used in Unbuilding). Set if 
SPEC_BUILD is being sent from within the 
MSG_VIS_VUP_UPDATE_WIN_GROUP. This lets the object 
being called know that the tree is being updated now, & that if 
the SBF_WIN_GROUP flag is not set, then it is the 
WIN_GROUP that it's parent is in is the one which is being 
updated.

SBF_WIN_GROUP  
Valid for non-branch (MSG_SPEC_BUILD & 
MSG_SPEC_UNBUILD) messages only. Used for both 
Building & Unbuilding. Set if object being asked to visually 
build is a WIN_GROUP, & it is the head object being built. The 
flag is used by objects having DUAL_BUILD, so that they can 
tell whether their being asked to be built as the WIN_GROUP 
object, or as the non-WIN_GROUP portion of the object.

SBF_TREE_BUILD  
Used for Building only (Not used in Unbuilding). This 
optimization flag is set automatically when 
MSG_SPEC_BUILD_BRANCH is sent on to generic children of 
an object being built. Indicates the object's generic parent & all 
siblings are being built at once. If so, 
VisAddChildRelativeToGen may assume that there no 
specifically built generic objects to the right of object currently 
being built.

SBF_VIS_PARENT_WITHIN_SCOPE_OF_TREE_BUILD  
Used for Building only (Not used in Unbuilding). This 
optimization bit is set for the current object only if its visible 
parent turns out to be the generic parent, but may also be set 
for a branch by the specific UI in SPEC_BUILD handlers if it is 
sure no objects below that point will end up visually higher 
than the top generic. Used by VisAddChildRelativeToGen to 
avoid the mess of work required to carefully position a new 
object within existing visual objects (When building within 
tree, all objects may just be added at the end, in the order 
encountered)

SBF_SKIP_CHILD  
INTERNAL flag.

SBF_FIND_LAST  
INTERNAL flag.

SBF_VIS_PARENT_UNBUILDING  
Valid for MSG_SPEC_UNBUILD and 
MSG_SPEC_UNBUILD_BRANCH only. Used for unbuilding, is 
set if the object receiving MSG_SPEC_UNBUILD_BRANCH *not* 
because of a generic parent somewhere up the line being set 
NOT_USABLE, but instead because a visual parent somewhere 
up the line is being unbuilt. This can happen when generic 
objects build themselves visually on a window other than the 
one their parent sits on.The difference in the unbuild is 
threefold:

1) MSG_SPEC_UNBUILD_BRANCH is passed on down to visible 
children only, with this same flag set.

2) Only effected portions of object are unbuilt (i.e. only one of 
WIN_GROUP/non-WIN_GROUP piece for dual-build objects).

3) Dual-build objects must be careful to unbuild such that the 
remaining "side" continues to function, and the unbuilt side 
can re-build correctly and continue to work with the already 
built side.

SBF_VIS_PARENT_FULLY_ENABLED  
Passed to tell child object if its parent was fully enabled. Speeds 
up figuring out whether our object should be set fully enabled.

SBF_UPDATE_MODE  
VisUpdateMode to use.

**Library:** Objects/visC.def

----------
#### SpecChildCount
	SpecChildCount		record
		SCC_DATA		:16
	SpecChildCount		end

**Library:** Objects/visC.def

----------
#### SpecHeight
	SpecHeight		record
		SH_TYPE			SpecSizeType:6
		SH_DATA			:10
	SpecHeight		end

**Library:** Objects/visC.def

----------
#### SpecialChar
	SpecialChar		etype word, 0, 2
		SC_WILDCARD				enum	SpecialChar
		SC_WILDCHAR				enum	SpecialChar
		SC_GRAPHIC				enum	SpecialChar
		SC_CR					enum	SpecialChar
		SC_PAGE_BREAK			enum	SpecialChar
		SC_TAB					enum	SpecialChar

**Library:** Objects/Text/tCtrlC.def

----------
#### SpecialFunction
	SpecialFunction		etype word, 0, 2
		SF_FILENAME			enum SpecialFunction
		SF_PAGE				enum SpecialFunction
		SF_PAGES			enum SpecialFunction

**Library:** parse.def

----------
#### SpecQueryVisParentType
	SpecQueryVisParentType				etype word
		SQT_VIS_PARENT_FOR_FIELD		enum SpecQueryVisParentType
		SQT_VIS_PARENT_FOR_APPLICATION	enum SpecQueryVisParentType
		SQT_VIS_PARENT_FOR_PRIMARY		enum SpecQueryVisParentType
		SQT_VIS_PARENT_FOR_DISPLAY		enum SpecQueryVisParentType
		SQT_VIS_PARENT_FOR_POPUP		enum SpecQueryVisParentType
		SQT_VIS_PARENT_FOR_URGENT		enum SpecQueryVisParentType
		SQT_VIS_PARENT_FOR_SYS_MODAL	enum SpecQueryVisParentType

**Library:** Objects/visC.def

----------
#### SpecSizeArgs
	SpecSizeArgs		struct
		SSA_minWidth			sword		; HINT_MINIMUM_SIZE
		SSA_minHeight			sword
		SSA_minNumChildren		sword
		SSA_maxWidth			sword		; HINT_MAXIMUM_SIZE
		SSA_maxHeight			sword
		SSA_maxNumChildren		sword
		SSA_initWidth			sword		; HINT_INITIAL_SIZE
		SSA_initHeight			sword
		SSA_initNumChildren		sword
		SSA_fixedWidth			sword		; HINT_FIXED_SIZE
		SSA_fixedHeight			sword
		SSA_fixedNumChildren	sword
	SpecSizeArgs		ends

This structure is filled in by **VisSetupSizeArgs**, finding all the desired size 
hints and converting them as appropriate. You can then pass the results to 
**VisApplyInitialSizeArgs**, **VisApplySizeArgsToWidth**, or 
**VisApplySizeArgsToHeight**, which each limit MSG_VIS_RECALC_SIZE 
suggested size arguments in various ways.

**Library:** Objects/visC.def

----------
#### SpecSizeSpec
	SpecSizeSpec			record
		SSS_TYPE		SpecSizeType:6
		SSS_DATA		:10
	SpecSizeSpec			end

**Library:** Objects/visC.def

----------
#### SpecSizeType
	SpecSizeType		etype byte
		SST_PIXELS 						enum SpecSizeType
		SST_COUNT 						enum SpecSizeType
		SST_PCT_OF_FIELD_WIDTH 			enum SpecSizeType
		SST_PCT_OF_FIELD_HEIGHT 		enum SpecSizeType
							PCT_0		equ 0000000000b
							PCT_5		equ 0000110011b
							PCT_10		equ 0001100110b
							PCT_15		equ 0010011001b
							PCT_20		equ 0011001100b
							PCT_25		equ 0100000000b
							PCT_30		equ 0100110011b
							PCT_35		equ 0101100110b
							PCT_40		equ 0110011001b
							PCT_45		equ 0111001100b
							PCT_50		equ 1000000000b
							PCT_55		equ 1000110011b
							PCT_60		equ 1001100110b
							PCT_65		equ 1010011001b
							PCT_70		equ 1011001100b
							PCT_75		equ 1100000000b
							PCT_80		equ 1100110011b
							PCT_85		equ 1101100110b
							PCT_90		equ 1110011001b
							PCT_95		equ 1111001100b
							PCT_100		equ 1111111111b
		SST_AVG_CHAR_WIDTHS 			enum SpecSizeType
		SST_WIDE_CHAR_WIDTHS 			enum SpecSizeType
		SST_LINES_OF_TEXT 				enum SpecSizeType

SST_PIXELS  
Size in pixels. This can be 0 through 1023. This also may imply 
that it's an already converted desired size.

SST_COUNT  
This type is not a "size" type proper, and is the only exception 
to the general rule that any **SpecSizeSpec** word may be 
converted by **VisConvertSpecSizeSpec** (Which will 
FATAL_ERROR if passed this). This is offered because some 
generic objects would like to provide a "Count" option in 
addition to having an actual distance. An example is a scrolling 
list, where we want to have both a SpecSizeSpec to indicate the 
height of each moniker, 	 and one more to indicate how tall we 
want the scrolling list to be. A nice option for how tall the 
scrolling list should be is to provide a "count" of how many list 
entries we'd like to display.

SST_PCT_OF_FIELD_WIDTH  
Percentage of screen width, where 10-bit value is a fraction, 
which is multiplied by the width of the screen. For a list of 
predefined fractions, see below. If you wish to calculate your 
own fraction, use a 10-bit value, where each bit has the 
fractional value: Bn = 2 ^ -n, where n = bit position MSB = 1, 
LSB = 10.

SST_PCT_OF_FIELD_HEIGHT  
Percentage of screen height.

SST_AVG_CHAR_WIDTHS  
Data is number to multiply by the width of the average 
character in the font being used. This may be 0 to 1023.

SST_WIDE_CHAR_WIDTHS  
Data is number to multiply by the width of the widest character 
in the set of the font being used. To be used in cases where we 
want to ensure that "any 8 characters" for example, could be 
displayed in the space allocated. This may 	be 0 to 1023.

SST_LINES_OF_TEXT  
Data is the # to multiply times the height of a line of text in the 
font being used. Typically used with a value of 1, as multiple 
lines of text are normally only handled by the text object.

**Library:** Objects/visC.def

----------
#### SpecUINavigationID
	SpecUINavigationID		etype word, NAVIGATION_ID_UI_START

**Library:** Objects/genC.def

----------
#### SpecWidth
	SpecWidth			record
		SW_TYPE		SpecSizeType:6
		SW_DATA		:10
	SpecWidth			end

**Library:** Objects/visC.def

----------
#### SpecWinSizePair
	SpecWinSizePair		struct
		SWSP_x	SpecWinSizeSpec
		SWSP_y	SpecWinSizeSpec
	SpecWinSizePair		ends

This structure stores an (x,y) pair of **SpecWinSIzeSpec** structures. This 
structure allows us to represent the generic position and size of a windowed 
object.

**Library:** Objects/visC.def

----------
#### SpecWinSizeSpec
	SpecWinSizeSpec		record
		SWSS_RATIO		:1		;TRUE if value is ratio. If FALSE,
								;bits 14-0 contain signed pixel value.
								;(need to extend sign to bit 15)
		SWSS_SIGN		:1		;sign of ratio (MUST BE BIT 14)
		SWSS_MANTISSA	:4		;integer portion: 0-15
		SWSS_FRACTION	:10		;fractional portion: 1/1024 to 1023/1024.
	SpecWinSizeSpec		end

**Library:** Objects/visC.def

----------
#### SpellCheckFromOffsetFlags
	SpellCheckFromOffsetFlags				record
		SCFOF_CHECK_NUM_CHARS			:1
	SpellCheckFromOffsetFlags				end

SCFOF_CHECK_NUM_CHARS  
If set, **VisTextSpellCheckFromOffset** will check the passed 
number of characters.

**Library:** Objects/vTextC.def

----------
#### SpellCheckFromOffsetStruct
	SpellCheckFromOffsetStruct				struct
		SCFOS_ICBuff				hptr
		SCFOS_flags					SpellCheckFromOffsetFlags
		SCFOS_numChars				dword
		SCFOS_offset				dword
		SCFOS_replyOptr				optr
		even
	SpellCheckFromOffsetStruct				ends

*SCFOS_ICBuff* stores the **ICBuff** to pass to the spell check library.

*SCFOS_flags* stores flags which specify whether or not to skip the next word 
in the document.

*SCFOS_numChars* stores the number of characters to spell check in total (if 
we want to skip the next word, the size of that word is deducted from this 
total).

*SCFOS_offset* stores the offset into the text to begin spell checking.

*SCFOS_replyOptr* stores the optr that object reply messages (such as 
SPELL_CHECK_COMPLETED) should be sent to.

**Library:** Objects/vTextC.def

----------
#### SpoolFileName
	SpoolFileName		struct
		SFN_base	char "spool"
		SFN_num		char "000"
		SFN_ext		char ".dat",0
	SpoolFileName		ends

This structure stores the default names to attach to spool files.

**Library:** spool.def

----------
#### SpoolInfoType
	SpoolInfoType		etype word, 0, 2
		SIT_JOB_INFO				enum SpoolInfoType
		SIT_QUEUE_INFO				enum SpoolInfoType

**Library:** spool.def

----------
#### SpoolOpStatus
	SpoolOpStatus		etype word, 0, 1
		SPOOL_OPERATION_SUCCESSFUL			enum SpoolOpStatus
		SPOOL_JOB_NOT_FOUND					enum SpoolOpStatus
		SPOOL_QUEUE_EMPTY					enum SpoolOpStatus
		SPOOL_QUEUE_NOT_EMPTY				enum SpoolOpStatus
		SPOOL_QUEUE_NOT_FOUND				enum SpoolOpStatus
		SPOOL_CANT_VERIFY_PORT				enum SpoolOpStatus
		SPOOL_OPERATION_FAILED				enum SpoolOpStatus

**Library:** spool.def

----------
#### SpoolTimeStruct
	SpoolTimeStruct		struct
		STS_second		byte		; second of the minute (0-59)
		STS_minute		byte		; minute of the hour (0-59)
		STS_hour		byte		; hour of the day (0-23)
	SpoolTimeStruct		ends

This structure holds the time stamp for a print spool job.

**Library:** spool.def

----------
#### SRCFeatures
	SRCFeatures		record
		SRCF_CLOSE						:1
		SRCF_FIND_NEXT					:1
		SRCF_FIND_PREV					:1
		SRCF_REPLACE_CURRENT			:1
		SRCF_REPLACE_ALL_IN_SELECTION	:1
		SRCF_REPLACE_ALL				:1
		SRCF_PARTIAL_WORDS				:1
		SRCF_IGNORE_CASE				:1
		SRCF_WILDCARDS					:1
		SRCF_SPECIAL_CHARS				:1
	SRCFeatures		end

**Library:** Objects/Text/tCtrlC.def

----------
#### SRCToolboxFeatures
	SRCToolboxFeatures		record
		SRCTF_SEARCH_REPLACE		:1
	SRCToolboxFeatures		end

**Library:** Objects/Text/tCtrlC.def

----------
#### StandardArrowheadType
	StandardArrowheadType			record
		SAT_LENGTH							:6
		SAT_FILLED							:1
		SAT_FILL_WITH_AREA_ATTRIBUTES		:1
		SAT_ANGLE							:8
	StandardArrowheadType			end

**Library:** grobj.def

----------
#### StandardDialogOptrParams
	StandardDialogOptrParams				struct
		SDOP_customFlags			CustomDialogBoxFlags
		SDOP_customString			optr
		SDOP_stringArg1				optr
		SDOP_stringArg2				optr
		SDOP_customTriggers			fptr.StandardDialogResponseTriggerTable
		SDOP_helpContext			fptr
	StandardDialogOptrParams				ends

This structure stores parameters passed to the **UserStandardDialogOptr** 
routine. These entries must be in the same order as 
**StandardDialogParams**.

**Library:** uDialog.def

----------
#### StandardDialogParams
	StandardDialogParams			struct
		SDP_customFlags			CustomDialogBoxFlags
		SDP_customString		fptr
		SDP_stringArg1			fptr
		SDP_stringArg2			fptr
		SDP_customTriggers		fptr.StandardDialogResponseTriggerTable
		SDP_helpContext			fptr
	StandardDialogParams			ends

This structure stores parameters passed to **UserStandardDialog** and 
MSG_GEN_APPLICATION_DO_STANDARD_DIALOG.

**Library:** uDialog.def

----------
#### StandardDialogResponseTriggerEntry
	StandardDialogResponseTriggerEntry	struct
		SDRTE_moniker				optr
		SDRTE_responseValue			word
	StandardDialogResponseTriggerEntry	ends

This structure defines a custom trigger for a GenInteraction of type 
GIT_MULTIPLE_RESPONSE initiated through **UserStandardDialog**. This 
entry structure is placed within a 
**StandardDialogResponseTriggerTable**.

*SDRTE_moniker* stores an optr to a moniker for the trigger to exhibit.

*SDRTE_responseValue* stores the 
ATTR_GEN_TRIGGER_INTERACTION_COMMAND or custom defined response 
value.

**Library:** uDialog.def

----------
#### StandardDialogResponseTriggerTable
	StandardDialogResponseTriggerTable	struct
		SDRTT_numTriggers		word
		SDRTT_triggers			label StandardDialogResponseTriggerEntry
	StandardDialogResponseTriggerTable	ends

This structure stores a table of custom response triggers for a GenInteraction 
of type GIT_MULTIPLE_RESPONSE initiated through 
*UserStandardDialog*.

**Library:** uDialog.def

----------
#### StandardLanguage
	StandardLanguage		etype byte, 0, 1
		SL_UNIVERSAL			enum StandardLanguage,0	; Universal Language code

		SL_FRENCH			enum StandardLanguage,5		; French
		SL_GERMAN			enum StandardLanguage,6		; German
		SL_SWEDISH			enum StandardLanguage,7		; Swedish
		SL_SPANISH			enum StandardLanguage,8		; Spanish
		SL_ITALIAN			enum StandardLanguage,9		; Italian
		SL_DANISH			enum StandardLanguage,10	; Danish
		SL_DUTCH 			enum StandardLanguage,11	; Dutch
		SL_PORTUGUESE		enum StandardLanguage,12	; Portuguese
		SL_NORWEGIAN		enum StandardLanguage,13	; Norwegian Becalm
		SL_FINNISH			enum StandardLanguage,14	; Finnish
		SL_SWISS			enum StandardLanguage,15	; Swiss
		SL_ENGLISH			enum StandardLanguage,16	; English
		SL_ARABIC			enum StandardLanguage,20	; Arabic
		SL_AUSTRALIAN		enum StandardLanguage,21	; Australian
		SL_CHINESE			enum StandardLanguage,22	; Chines (Pinyon)
		SL_GAELIC			enum StandardLanguage,23	; Gallic
		SL_GREEK			enum StandardLanguage,24	; Greek
		SL_HEBREW			enum StandardLanguage,25	; Hebrew
		SL_HUNGARIAN		enum StandardLanguage,26	; Hungarian (Meager)
		SL_JAPANESE			enum StandardLanguage,27	; Japanese
		SL_POLISH			enum StandardLanguage,28	; Polish
		SL_SERBO_CROATN		enum StandardLanguage,29	; Sorb-Creatine
		SL_SLOVAK			enum StandardLanguage,30	; Slovak/Czech (Czechoslovakia)
		SL_RUSSIAN			enum StandardLanguage,31	; Russian
		SL_TURKISH			enum StandardLanguage,32	; Turkish
		SL_URDU				enum StandardLanguage,33	; Rudy/Hindu
		SL_AFRIKAANS		enum StandardLanguage,34	; Afrikaans
		SL_BASQUE			enum StandardLanguage,35	; Basque
		SL_CATALAN			enum StandardLanguage,36	; Chatelaine
		SL_CANADIAN			enum StandardLanguage,37	; Canadian
		SL_FLEMISH			enum StandardLanguage,38	; Flemish
		SL_HAWAIIAN			enum StandardLanguage,39	; Hawaiian
		SL_KOREAN			enum StandardLanguage,40	; Korean (Angel)
		SL_LATIN			enum StandardLanguage,41	; Latin
		SL_MAORI			enum StandardLanguage,42	; Mario
		SL_NZEALAND			enum StandardLanguage,43	; New Sealant
		SL_BRITISH			enum StandardLanguage,44	; U.K. English

		SL_DEFAULT			equ SL_ENGLISH

**Library:** sllang.def

----------
#### StandardPath
	StandardPath		etype word, 1, 2
		SP_NOT_STANDARD_PATH		enum StandardPath,0
		SP_TOP						enum StandardPath,1
		SP_APPLICATION				enum StandardPath
		SP_DOCUMENT					enum StandardPath
		SP_SYSTEM					enum StandardPath
		SP_PRIVATE_DATA				enum StandardPath
		SP_STATE					enum StandardPath
		SP_FONT						enum StandardPath
		SP_SPOOL					enum StandardPath
		SP_SYS_APPLICATION			enum StandardPath
		SP_USER_DATA				enum StandardPath
		SP_MOUSE_DRIVERS			enum StandardPath
		SP_PRINTER_DRIVERS			enum StandardPath
		SP_FILE_SYSTEM_DRIVERS		enum StandardPath
		SP_VIDEO_DRIVERS			enum StandardPath
		SP_SWAP_DRIVERS				enum StandardPath
		SP_KEYBOARD_DRIVERS			enum StandardPath
		SP_FONT_DRIVERS				enum StandardPath
		SP_IMPORT_EXPORT_DRIVERS	enum StandardPath
		SP_TASK_SWITCH_DRIVERS		enum StandardPath
		SP_HELP_FILES				enum StandardPath
		SP_TEMPLATE					enum StandardPath
		SP_POWER_DRIVERS			enum StandardPath
		SP_DOS_ROOM					enum StandardPath
		SP_HWR						enum StandardPath
		SP_WASTE_BASKET				enum StandardPath
		SP_BACKUP					enum StandardPath
		SP_PAGER_DRIVERS			enum StandardPath

		SP_TEMP_FILES		equ SP_WASTE_BASKET

SP_NOT_STANDARD_PATH  
Not a standard path.

SP_TOP  
Top level directory. (Location of GEOS.EXE and GEOS.INI files.) 
Generally C:/GEOWORKS.

SP_APPLICATION  
Application directory. (Location of all applications.) Default is 
WORLD.

SP_DOCUMENT  
Document directory. (Location of all application datafiles.) 
Default is DOCUMENT.

SP_SYSTEM  
System directory. (Location of drivers, libraries, TOKEN.DB.) 
Default is SYSTEM.

SP_PRIVATE_DATA  
Private data. Default is PRIVDATA.

SP_STATE  
State directory. (Location of state files.) Default is 
PRIVDATA/STATE.

SP_FONT  
Font directory. (Location of all fonts.) Default is 
USERDATA/FONT.

SP_SPOOL  
Spool directory. (Location of application spool files.) Default is 
PRIVDATA/SPOOL.

SP_SYS_APPLICATION  
Secondary application directory. (Location of GCM apps, 
welcome, applications that should not be launched by the user.) 
Default is SYSTEM/SYSAPPL.

SP_USER_DATA  
Public data. Default is USERDATA

SP_MOUSE_DRIVERS  
Mouse drivers. Default is SYSTEM/MOUSE

SP_PRINTER_DRIVERS  
Printer drivers. Default is SYSTEM/PRINTER.

SP_FILE_SYSTEM_DRIVERS  
File system drivers. Default is SYSTEM/FS.

SP_VIDEO_DRIVERS  
Video drivers. Default is SYSTEM/VIDEO.

SP_SWAP_DRIVERS  
Swap drivers. Default is SYSTEM/SWAP.

SP_KEYBOARD_DRIVERS  
Keyboard drivers. Default is SYSTEM/KBD.

SP_FONT_DRIVERS  
Font drivers. Default is SYSTEM/FONT.

SP_IMPORT_EXPORT_DRIVERS  
Import/export libraries. Default is SYSTEM/IMPEX.

SP_TASK_SWITCH_DRIVERS  
Task-switching drivers. Default is SYSTEM/TASK.

SP_HELP_FILES  
Help files. Default is USERDATA/HELP.

SP_TEMPLATE  
Template files. Default is USERDATA/TEMPLATE.

SP_POWER_DRIVERS  
Power-management drivers. Default is SYSTEM/POWER.

SP_DOS_ROOM  
Where DOS Launchers default to and where Welcome looks to 
give user a list of buttons. Default is DOSROOM.

SP_HWR  
HandWritingRecognition drivers. Default is SYSTEM/HWR.

SP_WASTE_BASKET  
This is where discarded files go. Default is PRIVDATA/WASTE.

SP_BACKUP  
his is where backup files go. Default is PRIVDATA/BACKUP.

**Library:** file.def

----------
#### StandardPathByte
	StandardPathByte		record
		SPB_SP		StandardPath:8
	StandardPathByte		end

**Library:** file.def

----------
#### StandardSoundType
	StandardSoundType		etype word
		SST_ERROR				enum StandardSoundType
		SST_WARNING				enum StandardSoundType
		SST_NOTIFY				enum StandardSoundType
		SST_NO_INPUT			enum StandardSoundType
		SST_KEY_CLICK			enum StandardSoundType
		SST_ALARM				enum StandardSoundType
		SST_CUSTOM_SOUND		equ 0xfffd
		SST_CUSTOM_BUFFER		equ 0xfffe	
		SST_CUSTOM_NOTE			equ 0xffff

SST_ERROR  
Sound produced when an Error box comes up. 

SST_WARNING  
General warning beep sound.

SST_NOTIFY  
General notify beep.

SST_NO_INPUT  
Sound produced when the users keystrokes/mouse presses are 
not going anywhere (if the user clicks off a modal dialog box, or 
clicks on the field or something).

SST_KEY_CLICK  
Sound produced when the keyboard is pressed, or when the 
user clicks on a floating keyboard.

SST_CUSTOM_SOUND  
Allows applications to play a custom sound handle and does all 
the checking for sound being off, etc. This is not a part of the 
enumerated type to simplify error checking later.

SST_CUSTOM_BUFFER  
Allows applications to play a custom sound buffer and does all 
the checking for sound being off, etc. This is not a part of the 
enumerated type to simplify error checking later.

SST_CUSTOM_NOTE  
Allows applications to play a custom note and does all the 
checking for sound being off, etc. This is not a part of the 
enumerated type to simplify error checking later.

All sounds are given the following defaults:

TEMPO = 1 msec per 64th note  
PRIORITY = SYSTEM_IMMEDIATE.

**Library:** ui.def

----------
#### StartUndoChainStruct
	StartUndoChainStruct			struct
		SUCS_owner			optr
		SUCS_title			optr
	StartUndoChainStruct			ends

*SUCS_owner* stores the owner of this action.

*SUCS_title* stores the null-terminated title of this action. If null, then the title 
of the undo action will be the title passed with the next 
MSG_GEN_PROCESS_UNDO_START_CHAIN.

**Library:** Objects/gProcC.def

----------
#### SubscriptPosition
	SubscriptPosition		etype byte
		SBP_CHEMICAL				enum SubscriptPosition, 30
		SBP_DENOMINATOR				enum SubscriptPosition, 0
		SBP_DEFAULT					enum SubscriptPosition, 50

**Library:** font.def

----------
#### SubscriptSize
	SubscriptSize		etype byte
		SBS_CHEMICAL				enum SubscriptSize, 65
		SBS_DENOMINATOR				enum SubscriptSize, 60
		SBS_DEFAULT					enum SubscriptSize, 50

**Library:** font.def

----------
#### SuperscriptPosition
	SuperscriptPosition			etype byte
		SPP_DISPLAY			enum SuperscriptPosition, 50
		SPP_FOOTNOTE		enum SuperscriptPosition, 40
		SPP_ALPHA			enum SuperscriptPosition, 45
		SPP_NUMERATOR		enum SuperscriptPosition, 50
		SPP_DEFAULT			enum SuperscriptPosition, 50

**Library:** font.def

----------
#### SuperscriptSize
	SuperscriptSize		etype byte
		SPS_DISPLAY			enum SuperscriptSize, 55
		SPS_FOOTNOTE		enum SuperscriptSize, 65
		SPS_ALPHA			enum SuperscriptSize, 75
		SPS_NUMERATOR		enum SuperscriptSize, 60
		SPS_DEFAULT			enum SuperscriptSize, 50

**Library:** font.def

----------
#### SysConfigFlags
	SysConfigFlags		record
		SCF_UNDER_SWAT	:1,	; Non-zero if kernel started by Swat stub
		SCF_2ND_IC		:1,	; Non-zero if second 8259 present
		SCF_RTC			:1,	; Non-zero if real-time clock around
		SCF_COPROC		:1,	; Non-zero if math coprocessor present
		SCF_RESTARTED	:1	; Non-zero if restarted from our tsr
		SCF_CRASHED		:1	; Non-zero if we crashed the last time we ran
		SCF_MCA			:1	; Non-zero if we're on a Micro Channel machine
		SCF_LOGGING		:1	; Non-zero if we're writing log messages
	SysConfigFlags		end

**Library:** system.def

----------
#### SysDrawMask
	SysDrawMask		record
		SDM_INVERSE		:1					; bit 7: 0 for mask as is
											; 1 for inverse of mask
		SDM_MASK 		SystemDrawMask:7	; bits 6-0: draw mask number
											; 0x7f to set custom mask
	SysDrawMask		end

**Library:** graphics.def

----------
#### SysGetInfoType
	SysGetInfoType		etype word, 0, 2
		SGIT_TOTAL_HANDLES			enum SysGetInfoType
		SGIT_HEAP_SIZE				enum SysGetInfoType
		SGIT_LARGEST_FREE_BLOCK		enum SysGetInfoType
		SGIT_TOTAL_COUNT			enum SysGetInfoType
		SGIT_NUMBER_OF_VOLUMES		enum SysGetInfoType
		SGIT_TOTAL_GEODES			enum SysGetInfoType
		SGIT_NUMBER_OF_PROCESSES	enum SysGetInfoType
		SGIT_NUMBER_OF_LIBRARIES	enum SysGetInfoType
		SGIT_NUMBER_OF_DRIVERS		enum SysGetInfoType
		SGIT_CPU_SPEED				enum SysGetInfoType
		SGIT_SYSTEM_DISK			enum SysGetInfoType
		SGIT_UI_PROCESS				enum SysGetInfoType

**Library:** sysstats.def

----------
#### SysInitialTextMode
	SysInitialTextMode		etype	byte, 0
		SITM_UNKNOWN				enum SysInitialTextMode, 0
		SITM_TEXT_80_25_16_COLOR	enum SysInitialTextMode, 3
		SITM_TEXT_80_25_MONO		enum SysInitialTextMode, 7

**Library:** system.def

----------
#### SysMachineType
	SysMachineType		etype byte, 0
		SMT_UNKNOWN			enum SysMachineType
		SMT_PC				enum SysMachineType
		SMT_PC_CONV			enum SysMachineType
		SMT_PC_JR			enum SysMachineType
		SMT_PC_XT			enum SysMachineType
		SMT_PC_XT_286		enum SysMachineType
		SMT_PC_AT			enum SysMachineType
		SMT_PS2_30			enum SysMachineType
		SMT_PS2_50			enum SysMachineType
		SMT_PS2_60			enum SysMachineType
		SMT_PS2_80			enum SysMachineType
		SMT_PS1				enum SysMachineType

**Library:** system.def

----------
#### SysNotifyFlags
	SysNotifyFlags			record
		SNF_RETRY		:1,	; Retry the operation.
		SNF_EXIT		:1,	; Shutdown the system.
		SNF_ABORT		:1,	; Abort the operation.
		SNF_CONTINUE	:1,	; Continue when done. This is different from
							; SNF_RETRY as it implies the notification is
							; not for a real error, but just to notify
							; the user of something.
		SNF_REBOOT		:1,	; Hard exit -- dirty shutdown followed by
							; reload/restart of GEOS
		SNF_BIZARRE		:1,	; Indicates notice is unexpected and user
							; should be directed to the trouble-shooting
							; guide.
						:10
	SysNotifyFlags			end

**Library:** system.def

----------
#### SysProcessorType
	SysProcessorType		etype byte, 0
		SPT_8088			enum SysProcessorType
		SPT_8086			enum SysProcessorType, SPT_8088
		SPT_80186			enum SysProcessorType
		SPT_80286			enum SysProcessorType
		SPT_80386			enum SysProcessorType
		SPT_80486			enum SysProcessorType

**Library:** system.def

----------
#### SysShutdownType
	SysShutdownType		etype word
		SST_CLEAN			enum SysShutdownType
		SST_CLEAN_FORCED	enum SysShutdownType
		SST_DIRTY			enum SysShutdownType
		SST_PANIC			enum SysShutdownType
		SST_REBOOT			enum SysShutdownType
		SST_RESTART			enum SysShutdownType
		SST_FINAL			enum SysShutdownType
		SST_SUSPEND			enum SysShutdownType
		SST_CONFIRM_START 	enum SysShutdownType
		SST_CONFIRM_END 	enum SysShutdownType

Note: SysNotify depends on these things increasing in severity as the 
number increases. Place any new modes in the proper order.

SST_CLEAN  
Shut down applications cleanly, allowing ones that wish to 
abort the shutdown to do so. 
MSG_META_CONFIRM_SHUTDOWN is sent out via the 
MANUFACTURER_ID_GEOWORKS: 
GCNSLT_SHUTDOWN_CONTROL list.  
**Pass:**  
^lcx:dx	- object to notify when everything's been confirmed; or 
0:0 to simply notify the UI in the standard fashion (via 
MSG_META_DETACH).  
bp - message to send it. When the message is sent, cx 			 		will be 0 
if the shutdown request has been denied; non-zero if the 
shutdown may proceed.  
**Return:** - carry set if another shutdown is already in-progress

SST_CLEAN_FORCED  
Shut down applications cleanly, but do not send out 
MSG_META_CONFIRM_SHUTDOWN.  
**Pass:** - nothing.  
**Return:** - nothing.

SST_DIRTY  
Do not shut down applications. Attempt to exit device drivers 
and close all open files, however.  
**Pass:**  
ds:si - reason for the shutdown (null-terminated string).  
si - -1 if no reason to give the user.  
**Return:** - doesn't.

SST_PANIC  
Do not shut down applications. Do not close files. Only exit 
device drivers marked with GA_SYSTEM. This can be really bad 
for the system and should be used only in dire straits.  
**Pass:** - nothing.  
**Return:** - doesn't.

SST_REBOOT  
Like SST_DIRTY, but warm-boots the machine, rather than just 
exiting to DOS.  
**Pass:** - nothing.  
**Return:** - doesn't.

SST_RESTART  
Like SST_CLEAN_FORCED, but reload the system, rather than 
exiting to 	DOS.  
**Pass:** - nothing.  
**Return:** - only if couldn't set up for restart (e.g. loader.exe wasn't 
found).

SST_FINAL  
Perform the final phase of an SST_CLEAN or 
SST_CLEAN_FORCED shutdown.  
**Pass:**  
ds:si - reason for shutdown (si = -1 if no reason to give).  
**Return:** - doesn't.

SST_SUSPEND  
Suspend system operation in preparation for switching to a 
new DOS task. Broadcasts MSG_META_CONFIRM_SHUTDOWN 
through the system's 	MANUFACTURER_ID_GEOWORKS: 
GCNSLT_SHUTDOWN_CONTROL list.  
**Pass:**  
^lcx:dx	- object to notify when everything's been confirmed  
bp - message to send it. When the message is sent, cx will be 0 
if the shutdown request has been denied; non-zero if the 
shutdown may proceed.  
**Return:** - carry set if another shutdown is already in-progress.

SST_CONFIRM_START  
Called by the recipient of a MSG_META_CONFIRM_SHUTDOWN 
so there's some order to the way confirmation boxes are 
presented to the user. Only one thread may be confirming the 
shutdown at a time. The caller will block until it is given 
permission. **SysShutdown** will return carry set to indicate 
that some other thread has already canceled the shutdown and 
the caller should not put up its confirmation box. It need not 
call **SysShutdown** again.  
**Pass:** - nothing.  
**Return:** - carry set if some other object has already denied the 
shutdown request. Caller should do nothing further.

SST_CONFIRM_END  
Finishes the handling of a MSG_META_CONFIRM_SHUTDOWN.  
**Pass:**  
cx - 0 to deny the shutdown.  
 - non-zero to allow the shutdown.  
**Return:** - nothing.

**Library:** system.def

----------
#### SysSimpleGraphicsMode
	SysSimpleGraphicsMode	etype	byte, 0
		SSGM_NONE 				enum	SysSimpleGraphicsMode, 0
		SSGM_VGA 				enum	SysSimpleGraphicsMode, 1
		SSGM_EGA 				enum	SysSimpleGraphicsMode, 2
		SSGM_MCGA 				enum	SysSimpleGraphicsMode, 3
		SSGM_HGC     			enum	SysSimpleGraphicsMode, 4
		SSGM_CGA 				enum	SysSimpleGraphicsMode, 5
		SSGM_SPECIAL 			enum	SysSimpleGraphicsMode, 6
		SSGM_SVGA_VESA 			enum	SysSimpleGraphicsMode, 7

**Library:** system.def

----------
#### SysStats
	SysStats		struct
		SS_idleCount			dword
		SS_swapOuts				SysSwapInfo
		SS_swapIns				SysSwapInfo
		SS_contextSwitches		word
		SS_interrupts			word
		SS_runQueue				word
	SysStats		ends

This structure is returned by **SysStatistics** and stores the current 
performance statistics of GEOS.

*SS_idleCount* stores the number of idle ticks during the last second.

*SS_swapOuts* stores the outward-bound swapping activity (**SysSwapInfo**).

*SS_swapIns* stores the inward-bound swapping activity (**SysSwapInfo**).

*SS_contextSwitches* stores the number of context switches that occurred 
during the last second.

*SS_interrupts* stores the number of interrupts that occurred during the last 
second.

*SS_runQueue* stores the number of runnable threads at the end of the last 
second.

**Library:** sysstats.def

----------
#### SysSwapInfo
	SysSwapInfo		struct
		SSI_paragraphs		word
		SSI_blocks			word
	SysSwapInfo		ends

This structure stores the current swap activity of the system. This swap 
information is used in the **SysStats** structure.

*SSI_paragraph* stores the number of "paragraphs" swapped.

*SSI_blocks* stores the number of blocks swapped.

**Library:** sysstats.def

----------
#### SystemAttrs
	SystemAttrs     record
		SA_NOT					:1	;Any following set bits must be OFF for hints
									;to be included, rather than on.
		SA_TINY					:1	;If set, screen must be either horizontally or
									;vertically tiny for hints to be included.
		SA_HORIZONTALLY_TINY	:1	;If set, screen must be horizontally tiny for
									;hints to be included.
		SA_VERTICALLY_TINY		:1	;If set, screen must be vertically tiny for
									;hints to be included.
		SA_COLOR				:1	;If set, must be a color screen for hints to
									;be included.
		SA_PEN_BASED			:1	;If set, system must be pen based for hints
									;to be included.
		SA_KEYBOARD_ONLY		:1	;If set, system must be set keyboard-only for
									;hints to be included.
		SA_NO_KEYBOARD			:1	;If set, system must be set no-keyboard for
									;hints to be included.
			:8
	SystemAttrs     end

**Library:** genC.def

----------
#### SystemBitmap
	SystemBitmap		etype byte

**Library:** graphics.def

----------
#### SystemDrawMask
	SystemDrawMask		 etype byte
		SDM_TILE		enum SystemDrawMask		; tile pattern
		SDM_SHADED_BAR	enum SystemDrawMask		; shaded bar
		SDM_HORIZONTAL	enum SystemDrawMask		; horizontal lines
		SDM_VERTICAL	enum SystemDrawMask		; vertical lines
		SDM_DIAG_NE		enum SystemDrawMask		; diagonal lines going up to NorthEast
		SDM_DIAG_NW		enum SystemDrawMask		; diagonal lines going up to NorthWest
		SDM_GRID		enum SystemDrawMask		; checkerboard
		SDM_BIG_GRID	enum SystemDrawMask		; larger checkerboard
		SDM_BRICK		enum SystemDrawMask		; brick wall
		SDM_SLANT_BRICK enum SystemDrawMask		; slanted brick wall

		SDM_0			enum SystemDrawMask, 89		; all zeroes
		SDM_12_5		enum SystemDrawMask, 81
		SDM_25			enum SystemDrawMask, 73
		SDM_37_5		enum SystemDrawMask, 65
		SDM_50			enum SystemDrawMask, 57
		SDM_62_5		enum SystemDrawMask, 49
		SDM_75			enum SystemDrawMask, 41
		SDM_87_5		enum SystemDrawMask, 33
		SDM_100			enum SystemDrawMask, 25		; all ones
		SDM_CUSTOM		enum SystemDrawMask, 0x7f	; setting a custom mask
		SET_CUSTOM_PATTERN = SDM_CUSTOM

**Library:** graphics.def

----------
#### SystemHatch
	SystemHatch		etype byte
	SH_VERTICAL			enum SystemHatch	; vertical lines
	SH_HORIZONTAL		enum SystemHatch	; horizontal lines
	SH_45_DEGREE		enum SystemHatch	; lines at 45 degrees
	SH_135_DEGREE		enum SystemHatch	; lines at 135 degrees
	SH_BRICK			enum SystemHatch	; basic brick
	SH_SLANTED_BRICK	enum SystemHatch	; basic brick, slanted

**Library:** graphics.def

----------
#### SystemVMID
	SystemVMID		etype word, 0xff00
		SVMID_RANGE_DBASE	equ 0xff00			;Reserved for DB code

		DB_MAP_ID			enum SystemVMID 	; ID for DB map block
		DB_GROUP_ID			enum SystemVMID		; ID for new DB group
		DB_ITEM_BLOCK_ID 	enum SystemVMID		; ID for new DB item block
		SVMID_HA_DIR_ID		enum SystemVMID		; ID for HugeArray dir blocks
		SVMID_HA_BLOCK_ID	enum SystemVMID		; ID for HugeArray data blocks

**Library:** vm.def

[Structures N-R](asmstrnr.md) <-- [Table of Contents](../asmref.md) &nbsp;&nbsp; --> [Structures T-U](asmstrtu.md)

