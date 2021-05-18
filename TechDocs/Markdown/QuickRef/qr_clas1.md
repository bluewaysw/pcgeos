# 2 Classes: Arc - GenTrigger
## ArcClass

	@class ArcClass, GrObjClass

**Instance Data**

	word				AI_arcCloseType
	WWFixed				AI_startAngle
	WWFixed 			AI_endAngle
	PointWWFixed 		AI_startPoint
	PointWWFixed 		AI_endPoint
	PointWWFixed 		AI_midPoint
	WWFixed 			AI_radius

**Messages**

	MSG_ARC_SET_START_ANGLE
	MSG_ARC_SET_END_ANGLE
	MSG_ARC_SET_ARC_CLOSE_TYPE
	MSG_ARC_UNDO_REPLACE_ARC_GEOMETRY_INSTANCE_DATA
	MSG_ARC_REPLACE_ARC_GEOMETRY_INSTANCE_DATA

## BitmapGuardianClass

	@class BitmapGuardianClass, GrObjVisGuardianClass

**Instance Data**

	BitmapGuardianFlags			BGI_flags
	ClassStruct					*BGI_toolClass

**Types and Flags**

	ByteFlags		BitmapGuardianFlags
		BGF_POINTER_ACTIVE					0x02
		BGF_REAL_ESTATE_RESIZE				0x01

**Messages**

	MSG_BG_SET_TOOL_CLASS
	MSG_BG_SET_BITMAP_POINTER_ACTIVE_STATUS
	MSG_BG_REAL_ESTATE_HANDLE_HIT_DETECTION
	MSG_BG_ACTIVATE_REAL_ESTATE_RESIZE
	MSG_BG_JUMP_START_REAL_ESTATE_RESIZE
	MSG_BG_PTR_REAL_ESTATE_RESIZE
	MSG_BG_END_REAL_ESTATE_RESIZE
	MSG_BG_CREATE_VIS_BITMAP
	MSG_BG_GET_TOOL_CLASS

## ColorSelectorClass

	@class ColorSelectorClass, GenControlClass

**Instance Data**

	ColorQuad				CSI_color = {0, 0, 0, 0}
	byte					CSI_colorIndeterminate
	SystemDrawMask			CSI_drawMask = SDM_0
	byte					CSI_drawMaskIndeterminate
	GraphicPattern			CSI_pattern = {0, 0}
	byte					CSI_patternIndeterminate
	ColorModifiedStates		CSI_states = 0
	ColorToolboxPreferences
							CSI_toolboxPrefs = CTP_IS_POPUP

**Variable Data**

	optr ATTR_COLOR_SELECTOR_DISABLE_OBJECT

**Structures**

	WordFlags		CSFeatures
		CSF_FILLED_LIST		0x10
		CSF_INDEX			0x08
		CSF_RGB				0x04
		CSF_DRAW_MASK		0x02
		CSF_PATTERN			0x01
	WordFlags		CSToolboxFeatures
		CSTF_INDEX			0x04
		CSTF_DRAW_MASK		0x02
		CSTF_PATTERN		0x01
	CS_DEFAULT_FEATURES	(CSF_FILLED_LIST | CSF_INDEX | \
						 CSF_RGB | CSF_DRAW_MASK | \
						 CSF_PATTERN)
	CS_DEFAULT_TOOLBOX_FEATURES	(CSTF_INDEX | \
								 CSTF_DRAW_MASK | CSTF_PATTERN)
	ByteFlags		ColorModifiedStates
		CMS_COLOR_CHANGED				0x04
		CMS_DRAW_MASK_CHANGED			0x02
		CMS_PATTERN_CHANGED				0x01
	ByteEnum		ColoredObjectOrientation
		COO_AREA_ORIENTED				0
		COO_TEXT_ORIENTED				1
		COO_LINE_ORIENTED				2
	typedef ByteFlags ColorToolboxPreferences
		CTP_INDEX_ORIENTATION			0x30
		CTP_DRAW_MASK_ORIENTATION		0x0c
		CTP_PATTERN_ORIENTATION			0x02
		CTP_IS_POPUP					0x01
	CTP_INDEX_ORIENTATION_OFFSET		4
	CTP_DRAW_MASK_ORIENTATION_OFFSET	2
	CTP_PATTERN_ORIENTATION_OFFSET		1

**Messages**

	Boolean MSG_COLOR_SELECTOR_GET_COLOR(
				ColorQuad		*retValue)
	void MSG_COLOR_SELECTOR_SET_COLOR(
				ColorQuad		colorQuad,
				Boolean			indeterminateFlag)
	void MSG_COLOR_SELECTOR_UPDATE_COLOR(
				ColorQuad		colorQuad,
				Boolean			indeterminateFlag)
	void MSG_COLOR_SELECTOR_APPLY_COLOR(
				ColorQuad		colorQuad)
	void MSG_COLOR_SELECTOR_UPDATE_FILLED_STATUS(
				SystemDrawMask 	drawMask,
				Boolean 		indeterminateFlag,
				word 			updateToolboxFlag)
	Boolean MSG_COLOR_SELECTOR_GET_FILLED_MONIKER(
				optr 			*retValue)
	Boolean MSG_COLOR_SELECTOR_GET_UNFILLED_MONIKER(
				optr 			*retValue)
	Boolean MSG_COLOR_SELECTOR_GET_DRAW_MASK(
				SystemDrawMask 	*retValue))
	void MSG_COLOR_SELECTOR_SET_DRAW_MASK(
				SetDrawMask 	drawMask,
				Boolean 		indeterminateFlag)
	void MSG_COLOR_SELECTOR_APPLY_DRAW_MASK(
				SystemDrawMask 	drawMask)
	Boolean MSG_COLOR_SELECTOR_GET_PATTERN(
				GraphicPattern 	*retValue)
	void MSG_COLOR_SELECTOR_SET_PATTERN(
				GraphicPattern 	pattern,
				Boolean 		indeterminateFlag)
	void MSG_COLOR_SELECTOR_UPDATE_PATTERN(
				GraphicPattern	pattern,
				Boolean 		indeterminateFlag)
	void MSG_COLOR_SELECTOR_APPLY_PATTERN(
				GraphicPattern 	pattern)
	void MSG_META_COLORED_OBJECT_SET_COLOR(
				ColorQuad 		colorQuad)
	void MSG_META_COLORED_OBJECT_SET_DRAW_MASK(
				SystemDrawMask 	drawMask)
	void MSG_META_COLORED_OBJECT_SET_PATTERN(
				GraphicPattern 	pattern)

## DictControlClass

	@class DictControlClass, GenControlClass

**Instance Data**

	word		DCI_status
		@default GCI_output = (TO_APP_TARGET)
		@default GII_visibility = GIV_DIALOG
		@default GI_states = (@default | GS_ENABLED)

**Types and Flags**

	WordFlags DictFeatures
		DF_DICT 		0x01
	#define DICT_GCM_FEATURES DF_DICT

	WordFlags DictToolboxFeatures
		DTF_DICT 		0x01
	#define DICT_GCM_TOOLBOX_FEATURES DTF_DICT

## EditTextGuardianClass

	@class EditTextGuardianClass, TextGuardianClass

## EditUserDictionaryControlClass

	@class EditUserDictionaryControlClass, GenControlClass

**Instance Data**

	MemHandle 		EUDCI_userDictList
	MemHandle 		EUDCI_icBuff
		@default GII_attrs = (@default | GIA_MODAL)
		@default GII_type = GIT_COMMAND
		@default GII_visibility = GIV_DIALOG

**Types and Flags**

	WordFlags		EditUserDictionaryFeatures
		EUDF_EDIT_USER_DICTIONARY 					0x01
	WordFlags 		EditUserDictionaryToolboxFeatures
		EUDTF_EDIT_USER_DICTIONARY 					0x01
	EUDC_DEFAULT_FEATURES				(EUDF_EDIT_USER_DICTIONARY)
	EUDC_DEFAULT_TOOLBOX_FEATURES		(EUDTF_EDIT_USER_DICTIONARY)

**Messages**

	void MSG_EUDC_GET_USER_DICTIONARY_LIST_MONIKER()
	void MSG_EUDC_DELETE_SELECTED_WORD_FROM_USER_DICTIONARY()
	void MSG_EUDC_ADD_NEW_WORD_TO_USER_DICTIONARY()
	void MSG_EUDC_UPDATE_SELECTED_WORD()
	void MSG_EUDC_CLOSE_EDIT_BOX()
	void MSG_META_EDIT_USER_DICTIONARY_COMPLETED()

## ExportControlClass

	@class ExportControlClass, ImportExportClass

**Instance Data**

	ExportControlAttrs 			ECI_attrs
	ImpexDataClasses 			ECI_dataClasses
	optr 						ECI_destination
	word 						ECI_message

**Variable Data**

	optr ATTR_EXPORT_CONTROL_APP_UI

**Types and Flags**

	WordFlags		ExportControlAttrs
		ECA_IGNORE_INPUT 					0x8000
	ByteFlags		ExportControlFeatures
		EXPORTCF_EXPORT_TRIGGER 			0x0008
		EXPORTCF_FORMAT_OPTIONS 			0x0004
		EXPORTCF_BASIC 						0x0002
		EXPORTCF_GLYPH 						0x0001
	EXPORTC_DEFAULT_FEATURES (EXPORTCF_GLYPH |
			EXPORTCF_BASIC | EXPORTCF_FORMAT_OPTIONS |
			EXPORTCF_EXPORT_TRIGGER)
	ByteFlags 		ExportControlToolboxFeatures
		EXPORTCTF_DIALOG_BOX 				0x01
	EXPORTC_DEFAULT_TOOLBOX_FEATURES (EXPORTCTF_DIALOG_BOX)

Messages

	void MSG_EXPORT_CONTROL_SET_DATA_CLASSES(
				ImpexDataClasses dataClass)
	ImpexDataClasses MSG_EXPORT_CONTROL_GET_DATA_CLASSES()
	void MSG_EXPORT_CONTROL_SET_ACTION(
				optr destOD, word ECImsg)
	void MSG_EXPORT_CONTROL_SET_MSG(word ECImsg)
	void MSG_EXPORT_CONTROL_GET_ACTION(
				ObjectState *retValue)
	void MSG_EXPORT_CONTROL_SET_ATTRS(
				ExportControlAttrs attrs)
	ExportControlAttrs MSG_EXPORT_CONTROL_GET_ATTRS()
	word MSG_EXPORT_CONTROL_GET_FILE_SELECTOR_OFFSET(
				ExportControlFeatures features)
	word MSG_EXPORT_CONTROL_GET_FORMAT_LIST_OFFSET(
				ExportControlFeatures features)
	word MSG_EXPORT_CONTROL_GET_FILE_NAME_OFFSET(
				ExportControlFeatures features)
	word MSG_EXPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET(
				ExportControlFeatures features)
	word MSG_EXPORT_CONTROL_GET_APP_UI_PARENT_OFFSET(
				ExportControlFeatures features)
	word MSG_EXPORT_CONTROL_GET_EXPORT_TRIGGER_OFFSET(
				ExportControlFeatures features)
	void MSG_EXPORT_CONTROL_EXPORT_COMPLETE(
				ImpexTranslationParams *itParams)

## FloatFormatClass

	@class FloatFormatClass, GenControlClass

**Instance Data**

	word		formatInfoStructHan = 0;
		@default GCI_output = (TO_APP_TARGET)

**Structures**

	typedef struct {
		VMFileHandle 			NFFC_vmFileHan
		VMBlockHandle 			NFFC_vmBlkHan
		FormatIdType 			NFFC_format
		word 			NFFC_count
	} NotifyFloatFormatChange

**Messages**

	void MSG_FLOAT_CTRL_REQUEST_MONIKER(
				MemHandle formatInfoStrucHan)
	void MSG_FLOAT_CTRL_UPDATE_UI(
				MemHandle formatInfoStrucHan)
	void MSG_FLOAT_CTRL_FORMAT_SELECTED(
				MemHandle formatInfoStrucHan)
	void MSG_FLOAT_CTRL_USER_DEF_INVOKE(
				MemHandle formatInfoStrucHan)
	void MSG_FLOAT_CTRL_USER_DEF_OK(
				MemHandle formatInfoStrucHan)
	void MSG_FLOAT_CTRL_FORMAT_DELETE(
				MemHandle formatInfoStrucHan)
	void MSG_FLOAT_CTRL_REPLACE_NUM_FORMAT(
				MemHandle formatInfoStrucHan)
	void MSG_FLOAT_CTRL_FORMAT_APPLY(
				MemHandle formatInfoStrucHan)
	void MSG_FCF_FORMAT_CHANGE(MemHandle formatInfoStrucHan)
	void MSG_FCT_FORMAT_CHANGE(MemHandle formatInfoStrucHan)

**Routines**

	VMBlockHandle FloatFormatInit(word userDefVMFileHan)
	word FloatFormatGetFormatParamsWithListEntry(
				FormatInfoStruc *formatInfoStruc)
	void FloatFormatInitFormatList(
				FormatInfoStruc *formatInfoStruc)
	void FloatFormatProcessFormatSelected(
				FormatInfoStruc *formatInfoStruc)
	void FloatFormatInvokeUserDefDB(
				FormatInfoStruc *formatInfoStruc)
	word FloatFormatUserDefOK(
				FormatInfoStruc *formatInfoStruc)
	word *FloatFormatGetFormatTokenWithName(
				FormatInfoStruc *formatInfoStruc)
	void FloatFormatGetFormatParamsWithToken(
				FormatInfoStruc *formatInfoStruc,
				FormatParams *buffer)
	FormatIdType FloatFormatDelete(
				FormatInfoStruc *formatInfoStruc)
	void FloatFormatIsFormatTheSame(
				FormatInfoStruc *formatInfoStruc,
				FormatParams *formatParams)
	word FloatFormatAddFormat(
				FormatInfoStruc *formatInfoStruc,
				FormatParams *formatParams,
				word formatToken)

## GenApplicationClass

	@class GenApplicationClass, GenClass

**Instance Data**

	AppInstanceReference	GAI_appRef = {"","",NullHandle,{0}}
	word					GAI_appMode = 0
	AppLaunchFlags			GAI_launchFlags = 0
	ApplicationOptFlags		GAI_optFlags = 0
	word					GAI_appFeatures = 0
	Handle					GAI_specificUI = 0
	ApplicationStates		GAI_states = AS_FOCUSABLE |
										 AS_MODELABLE
	AppAttachFlags			GAI_attachFlags = 0
	UIInterfaceLevel		GAI_appLevel = UIIL_ADVANCED
	ChunkHandle				GAI_iacpConnects = 0
		@default GI_states = @default & ~GS_USABLE
		@default GI_attrs = @default | GA_TARGETABLE

**Variable Data**

	optr ATTR_GEN_APPLICATION_PRINT_CONTROL;
		@reloc ATTR_GEN_APPLICATION_PRINT_CONTROL, 0, optr
	ChunkHandle TEMP_GEN_APPLICATION_NO_LONGER_USED;
	optr ATTR_GEN_APPLICATION_KBD_OBJ;
	MemHandle TEMP_GEN_APPLICATION_SAVED_ALB;
	void TEMP_GEN_APPLICATION_ABORT_QUIT;
	optr ATTR_GEN_APPLICATION_SAVE_OPTIONS_TRIGGER;
		@reloc ATTR_GEN_APPLICATION_SAVE_OPTIONS_TRIGGER, 
													0, optr;

**Hints**

	void	HINT_APP_IS_ENTERTAINING
	void	HINT_APP_IS_EDUCATIONAL
	void	HINT_APP_IS_PRODUCTIVITY_ORIENTED

**Types and Flags**

	ByteEnum		AppMeasurementType
		AMT_US				0
		AMT_METRIC			1
		AMT_DEFAULT			0xff
	WordFlags		ApplicationStates
		AS_TRANSPARENT 					0x4000
		AS_HAS_FULL_SCREEN_EXCL 		0x2000
		AS_SINGLE_INSTANCE 				0x1000
		AS_QUIT_DETACHING 				0x0800
		AS_AVOID_TRANSPARENT_DETACH 	0x0400
		AS_TRANSPARENT_DETACHING 		0x0200
		AS_REAL_DETACHING 				0x0100
		AS_QUITTING 					0x0080
		AS_DETACHING 					0x0040
		AS_FOCUSABLE 					0x0020
		AS_MODELABLE 					0x0010
		AS_NOT_USER_INTERACTABLE 		0x0008
		AS_RECEIVED_APP_OBJECT_DETACH 	0x0004
		AS_ATTACHED_TO_STATE_FILE 		0x0002
		AS_ATTACHING 					0x0001
	typedef AppOptFlags ApplicationOptFlags
	typedef ByteFlags AppOptFlags
		AOF_MULTIPLE_INIT_FILE_CATEGORIES	0x80
	typedef ByteEnum GenAppUsabilityCommand
		GAUC_USABILITY				0
		GAUC_RECALC_CONTROLLER		1
		GAUC_REPARENT				2
		GAUC_POPUP					3
		GAUC_TOOLBAR				4
		GAUC_RESTART				5
	typedef ByteFlags GenAppUsabilityTupleFlags
		GAUTF_END_OF_LIST			0x20
		GAUTF_OFF_IF_BIT_ON			0x10
		GAUTF_COMMAND				0x0f
	typedef enum {
		TO_PRINT_CONTROL=_FIRST_GenApplicationClass
	} GenApplicationTravelOption

**Structures**

	typedef struct {
		GenAppUsabilityTupleFlags		GAUT_flags
		optr							GAUT_object
	} GenAppUsabilityTuple
	typedef struct {
		UIInterfaceLevel 		AFI_uiInterfaceLevel;
		word 					AFI_appFeatures;
	} AppFeaturesInfo;
	typedef struct {
		CharFlags 				CFASS_charFlags;
		ShiftState 				CFASS_shiftState;
	} CharFlagsAndShiftState;
	typedef struct {
		ToggleState 			TSASC_toggleState;
		byte 					TSASC_scanCode;
	} ToggleStateAndScanCode;
	typedef struct {
		CustomDialogType 		ND_dialogType;
		byte 					ND_unused1;
		word 					ND_unused2;
		optr 					ND_dialog;
	} NewDialog;

**Macros**

	GET_MEASUREMENT_TYPE(m) ((byte) (m))
	GET_APP_MEASUREMENT_TYPE(m) ((byte) ((m)>>8))
	GET_UI_INTERFACE_LEVEL(val) \
						((val).AFI_uiInterfaceLevel)
	GET_APP_FEATURES(val) ((val).AFI_appFeatures)

**Messages**

	void MSG_GEN_APPLICATION_MARK_BUSY()
	void MSG_GEN_APPLICATION_MARK_NOT_BUSY()
	void MSG_GEN_APPLICATION_HOLD_UP_INPUT()
	void MSG_GEN_APPLICATION_RESUME_INPUT()
	void MSG_GEN_APPLICATION_IGNORE_INPUT()
	void MSG_GEN_APPLICATION_ACCEPT_INPUT()
	Handle MSG_GEN_APPLICATION_QUERY_UI()
	ApplicationStates MSG_GEN_APPLICATION_GET_STATE()
	optr MSG_GEN_APPLICATION_FIND_MONIKER(
				MemHandle destBlock,
				word searchFlags,
				DisplayType displayType)
	void MSG_GEN_APPLICATION_SET_TASK_ENTRY_MONIKER(
				optr entryMoniker)
	void MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME(
				DisplayScheme *displayScheme)
	void MSG_GEN_APPLICATION_SET_APP_MODE_MESSAGE(
				Message modeMessage)
	Message MSG_GEN_APPLICATION_GET_APP_MODE_MESSAGE()
	Handle MSG_GEN_APPLICATION_GET_APP_INSTANCE_REFERENCE()
	void MSG_GEN_APPLICATION_SET_APP_INSTANCE_REFERENCE(
				Handle appInstance)
	void MSG_GEN_APPLICATION_SEND_APP_INSTANCE_REFERENCE\
							_TO_FIELD()
	void MSG_GEN_APPLICATION_INITIATE_UI_QUIT()
	void MSG_GEN_APPLICATION_INSTALL_TOKEN()
	void MSG_GEN_APPLICATION_TOGGLE_CURSOR()
	AppLaunchFlags MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS()
	void MSG_GEN_APPLICATION_SET_APP_LEVEL(
				word level)
	AppFeaturesInfo MSG_GEN_APPLICATION_GET_APP_FEATURES()
	void MSG_GEN_APPLICATION_SET_APP_FEATURES(
				word 	features)
	void MSG_GEN_APPLICATION_DETACH_PENDING()
	optr MSG_GEN_APPLICATION_BUILD_STANDARD_DIALOG(
				char 	*customTriggers,
				char 	*arg2, 	char 	*arg1,
				char 	*string,
				CustomDialogBoxFlags 	dialogFlags)
	void MSG_GEN_APPLICATION_DO_STANDARD_DIALOG(@stack
				word dialogMethod,	optr dialogOD,
				char *helpContext,
				char *customTriggers,
				char *arg2, char *arg1,
				char *string,
				CustomDialogBoxFlags dialogFlags)
	void MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY()
	void MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY()
	void MSG_GEN_APPLICATION_OPEN_COMPLETE()
	void MSG_GEN_APPLICATION_SET_NOT_USER_INTERACTABLE()
	void MSG_GEN_APPLICATION_SET_USER_INTERACTABLE()
	void MSG_GEN_APPLICATION_SET_ATTACHED_TO_STATE_FILE()
	void MSG_GEN_APPLICATION_SET_NOT_ATTACHED_TO_STATE_FILE()
	void MSG_GEN_APPLICATION_SET_NOT_QUITTING()
	void MSG_GEN_APPLICATION_NOTIFY_MODAL_WIN_CHANGE()
	word MSG_GEN_APPLICATION_GET_MEASUREMENT_TYPE()
	void MSG_GEN_APPLICATION_SET_MEASUREMENT_TYPE(
				byte measurementType)
	Boolean MSG_GEN_APPLICATION_TEST_FOR_CANCEL_MNEMONIC(
				word 				character,
				CharFlagsAndShiftState 				flags, 	
				word 				state)
	void MSG_GEN_APPLICATION_INK_QUERY_REPLY(
				InkReturnValue 			inkReturnValue,
				GStateHandle 			inkGState)
	ChunkHandle MSG_GEN_APPLICATION_GET_GCN_LIST_OF_LISTS()
	(GEN_VISIBILITY_OUTPUT) 
	MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION()
	void MSG_GEN_APPLICATION_BRING_WINDOW_TO_TOP(
				optr window)
	void MSG_GEN_APPLICATION_LOWER_WINDOW_TO_BOTTOM(
				optr window)
	AppAttachFlags MSG_GEN_APPLICATION_GET_ATTACH_FLAGS()
	void MSG_GEN_APPLICATION_BUILD_DIALOG_FROM_TEMPLATE(
				NewDialog 			*retValue,
				optr			template)

GenBooleanClass

	@class GenBooleanClass, GenClass

**Instance Data**

	word		GBI_identifier

**Messages**

	word MSG_GEN_BOOLEAN_GET_IDENTIFIER()
	void MSG_GEN_BOOLEAN_SET_IDENTIFIER(word identifier)

## GenBooleanGroupClass

	@class GenBooleanGroupClass, GenClass

Instance Data

	word		GBGI_selectedBooleans = 0
	word		GBGI_indeterminateBooleans = 0
	word		GBGI_modifiedBooleans = 0
	optr		GBGI_destination
	Message		GBGI_applyMsg = 0

**Variable Data**

	Message ATTR_GEN_BOOLEAN_GROUP_STATUS_MSG
	Message ATTR_GEN_BOOLEAN_GROUP_STATUS_MSG;
	optr ATTR_GEN_BOOLEAN_GROUP_LINK
		@reloc ATTR_GEN_BOOLEAN_GROUP_LINK, 0, optr
	void ATTR_GEN_BOOLEAN_GROUP_INIT_FILE_BOOLEAN

**Hints**

	void HINT_BOOLEAN_GROUP_SCROLLABLE
	void HINT_BOOLEAN_GROUP_MINIMIZE_SIZE
	void HINT_BOOLEAN_GROUP_CHECKBOX_STYLE
	void HINT_BOOLEAN_GROUP_TOOLBOX_STYLE

**Messages**

	void MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE(
					word selectedBooleans,
					word indeterminateBooleans)
	void MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE(
					word setBooleans,
					word clearBooleans)
	word MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS()
	word MSG_GEN_BOOLEAN_GROUP_GET_INDETERMINATE_BOOLEANS()
	word MSG_GEN_BOOLEAN_GROUP_GET_MODIFIED_BOOLEANS()
	void MSG_GEN_BOOLEAN_GROUP_SEND_STATUS_MSG(
					word changedBooleans)
	optr MSG_GEN_BOOLEAN_GROUP_GET_BOOLEAN_OPTR(
					word identifier)
	void MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE(
					word identifier,
					Boolean state)
	void MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_INDETERMINATE_STATE(
					word identifier,
					Boolean indeterminateState)
	void MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_MODIFIED_STATE(
					word identifier,
					Boolean modifiedState)
	Boolean MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED(
					word identifier)
	Boolean MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_INDETERMINATE(
					word identifier)
	Boolean MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_MODIFIED(
					word identifier)
	optr MSG_GEN_BOOLEAN_GROUP_GET_DESTINATION()
	void MSG_GEN_BOOLEAN_GROUP_SET_DESTINATION(optr dest)
	Message MSG_GEN_BOOLEAN_GROUP_GET_APPLY_MSG()
	void MSG_GEN_BOOLEAN_GROUP_SET_APPLY_MSG(
					Message message)
	void MSG_GEN_BOOLEAN_GROUP_MAKE_BOOLEAN_VISIBLE(
					word identifier)
	word MSG_GEN_BOOLEAN_GROUP_SCAN_BOOLEANS(
					byte flags,
					word initialBoolean,
					word scanAmount = bp)
	void MSG_GEN_BOOLEAN_GROUP_REDRAW_BOOLEANS(word offset)
	@prototype void GEN_BOOLEAN_GROUP_APPLY_MSG(
					word selectedBooleans,
					word indeterminateBooleans,
					word modifiedBooleans)
	@prototype void GEN_BOOLEAN_GROUP_STATUS_MSG(
					word selectedBooleans,
					word indeterminateBooleans,
					word changedBooleans)

## GenClass

	@class GenClass, VisClass, master, variant

**Instance Data**

	@link				GI_link
	@composite			GI_comp = GI_link
	@visMoniker			GI_visMoniker
	@kbdAccelerator		GI_kbdAccelerator
	GenAttrs			GI_attrs = 0
	GenStates			GI_states = (GS_USABLE|GS_ENABLED)

**Variable Data**

	GenFilePath		ATTR_GEN_PATH_DATA
	void			TEMP_GEN_PATH_SAVED_DISK_HANDLE
	void			ATTR_GEN_PROPERTY
	void			ATTR_GEN_NOT_PROPERTY
	DestinationClassArgs ATTR_GEN_DESTINATION_CLASS
		@reloc ATTR_GEN_DESTINATION_CLASS, 0, optr
	char[]			ATTR_GEN_INIT_FILE_KEY
	char[]			ATTR_GEN_INIT_FILE_CATEGORY
	void			ATTR_GEN_INIT_FILE_PROPAGATE_TO_CHILDREN
	ChunkHandle		ATTR_GEN_FEATURE_LINK
	MemHandle		ATTR_GEN_WINDOW_CUSTOM_LAYER_ID
		@reloc ATTR_GEN_WINDOW_CUSTOM_LAYER_ID, 0, handle
	Point			ATTR_GEN_POSITION
	sword			ATTR_GEN_POSITION_X
	sword			ATTR_GEN_POSITION_Y
	void 	ATTR_GEN_SEND_APPLY_MSG_ON_APPLY_EVEN_IF_NOT_MODIFIED
	void 	ATTR_GEN_SEND_APPLY_MSG_ON_APPLY_EVEN_IF_NOT_ENABLED
	dword			ATTR_GEN_VISIBILITY_DATA
	word			ATTR_GEN_VISIBILITY_MESSAGE
	optr			ATTR_GEN_VISIBILITY_DESTINATION
		@reloc ATTR_GEN_VISIBILITY_DESTINATION, 0, optr
	WinPriority		ATTR_GEN_WINDOW_CUSTOM_WINDOW_PRIORITY
	LayerPriority	ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY
	MemHandle		ATTR_GEN_WINDOW_CUSTOM_PARENT
	void 			ATTR_GEN_WINDOW_CUSTOM_WINDOW
	GenDefaultMonikerType ATTR_GEN_DEFAULT_MONIKER
	char[]			ATTR_GEN_HELP_FILE
	byte			ATTR_GEN_HELP_TYPE
	void			ATTR_GEN_HELP_FILE_FROM_INIT_FILE
	optr			ATTR_GEN_FOCUS_HELP
	optr			ATTR_GEN_FOCUS_HELP_LIB
		@reloc ATTR_GEN_FOCUS_HELP_LIB, 0, optr
	char[]			ATTR_GEN_HELP_CONTEXT
	optr			ATTR_GEN_OUTPUT_TRAVEL_START
		@reloc ATTR_GEN_OUTPUT_TRAVEL_START, 0, optr
	void			ATTR_GEN_USES_HIERARCHICAL_INIT_FILE_CATEGORY
	void			ATTR_GEN_WINDOW_ACCEPT_INK_EVEN_IF_NOT_FOCUSED
	KeyboardOverride ATTR_GEN_WINDOW_KBD_OVERRIDE;
	Point 			ATTR_GEN_WINDOW_KBD_POSITION;

**Hints**

	void HINT_DUMMY
	void HINT_FREQUENTLY_USED
	void HINT_INFREQUENTLY_USED
	void HINT_AN_ADVANCED_FEATURE
	void HINT_DEFAULT_DEFAULT_ACTION
	void HINT_ENSURE_TEMPORARY_DEFAULT
	void HINT_SAME_CATEGORY_AS_PARENT
	void HINT_SYS_MENU
	void HINT_USE_TEXT_MONIKER
	void HINT_USE_ICONIC_MONIKER
	void HINT_DEFAULT_FOCUS
	void HINT_DEFAULT_TARGET
	void HINT_DEFAULT_MODEL
	void HINT_PREVENT_DEFAULT_OVERRIDES
	void HINT_PRESERVE_FOCUS
	void HINT_DO_NOT_PRESERVE_FOCUS
	void HINT_GENERAL_CONSUMER_MODE
	void HINT_NEVER_ADOPT_MENUS
	void HINT_ALWAYS_ADOPT_MENUS
	void HINT_ALLOW_CHILDREN_TO_WRAP
	void HINT_BOTTOM_JUSTIFY_CHILDREN
	void HINT_CENTER_CHILDREN_HORIZONTALLY
	void HINT_CENTER_CHILDREN_ON_MONIKERS
	void HINT_CENTER_CHILDREN_VERTICALLY
	void HINT_CENTER_MONIKER
	SpecSizeSpec HINT_CUSTOM_CHILD_SPACING
	void HINT_DONT_ALLOW_CHILDREN_TO_WRAP
	void HINT_DONT_FULL_JUSTIFY_CHILDREN
	void HINT_DONT_INCLUDE_ENDS_IN_CHILD_SPACING
	void HINT_DO_NOT_USE_MONIKER
	void HINT_DRAW_IN_BOX
	void HINT_EXPAND_HEIGHT_TO_FIT_PARENT
	void HINT_EXPAND_WIDTH_TO_FIT_PARENT
	CompSizeHintArgs HINT_FIXED_SIZE
	void HINT_FULL_JUSTIFY_CHILDREN_HORIZONTALLY
	void HINT_FULL_JUSTIFY_CHILDREN_VERTICALLY
	void HINT_INCLUDE_ENDS_IN_CHILD_SPACING
	CompSizeHintArgs HINT_INITIAL_SIZE
	void HINT_LEFT_JUSTIFY_CHILDREN
	void HINT_LEFT_JUSTIFY_MONIKERS
	void HINT_MAKE_REPLY_BAR
	CompSizeHintArgs HINT_MAXIMUM_SIZE
	CompSizeHintArgs HINT_MINIMUM_SIZE
	void HINT_NO_TALLER_THAN_CHILDREN_REQUIRE
	void HINT_NO_WIDER_THAN_CHILDREN_REQUIRE
	void HINT_ORIENT_CHILDREN_HORIZONTALLY
	void HINT_ORIENT_CHILDREN_VERTICALLY
	void HINT_PLACE_MONIKER_ABOVE
	void HINT_ALIGN_LEFT_MONIKER_EDGE_WITH_CHILD
	void HINT_PLACE_MONIKER_TO_LEFT
	void HINT_PLACE_MONIKER_TO_RIGHT
	void HINT_RIGHT_JUSTIFY_CHILDREN
	void HINT_TOP_JUSTIFY_CHILDREN
	word HINT_WRAP_AFTER_CHILD_COUNT
	void HINT_DIVIDE_WIDTH_EQUALLY
	void HINT_DIVIDE_HEIGHT_EQUALLY
	void HINT_NO_BORDERS_ON_MONIKERS
	word HINT_GADGET_TEXT_COLOR
	void HINT_POPS_UP_TO_RIGHT
	void HINT_POPS_UP_BELOW
	void HINT_SEEK_MENU_BAR
	void HINT_AVOID_MENU_BAR
	void HINT_NAVIGATION_ID
	void HINT_NAVIGATION_NEXT_ID
	void HINT_DISMISS_WHEN_DISABLED
	void HINT_SEEK_X_SCROLLER_AREA
	void HINT_SEEK_Y_SCROLLER_AREA
	void HINT_SEEK_LEFT_OF_VIEW
	void HINT_SEEK_TOP_OF_VIEW
	void HINT_SEEK_RIGHT_OF_VIEW
	void HINT_SEEK_BOTTOM_OF_VIEW
	void HINT_USE_INITIAL_BOUNDS_WHEN_RESTORED
	void HINT_KEEP_INITIALLY_ONSCREEN
	void HINT_DONT_KEEP_INITIALLY_ONSCREEN
	void HINT_KEEP_PARTIALLY_ONSCREEN
	void HINT_KEEP_ENTIRELY_ONSCREEN
	void HINT_KEEP_ENTIRELY_ONSCREEN_WITH_MARGIN
	void HINT_DONT_KEEP_PARTIALLY_ONSCREEN
	SpecWinSizePair HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT
	void HINT_STAGGER_WINDOW
	void HINT_CENTER_WINDOW
	void HINT_TILE_WINDOW
	void HINT_POSITION_WINDOW_AT_MOUSE
	void HINT_EXTEND_WINDOW_TO_BOTTOM_RIGHT
	void HINT_EXTEND_WINDOW_NEAR_BOTTOM_RIGHT
	void HINT_SIZE_WINDOW_AS_DESIRED
	SpecWinSizePair HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT
	SpecWinSizePair HINT_SIZE_WINDOW_AS_RATIO_OF_FIELD
	SpecWinSizePair HINT_POSITION_ICON_AS_RATIO_OF_FIELD
	void HINT_TOOLBOX
	void HINT_SAME_ORIENTATION_AS_PARENT
	void HINT_SEEK_REPLY_BAR
	void HINT_SHOW_SHORTCUT
	void HINT_DRAW_SHORTCUT_BELOW
	void HINT_CAN_CLIP_MONIKER_WIDTH
	void HINT_CAN_CLIP_MONIKER_HEIGHT
	void HINT_SHOW_ENTIRE_MONIKER
	optr HINT_ALIGN_LEFT_EDGE_WITH_OBJECT
		@reloc HINT_ALIGN_LEFT_EDGE_WITH_OBJECT, 0, optr
	optr HINT_ALIGN_TOP_EDGE_WITH_OBJECT
		@reloc HINT_ALIGN_TOP_EDGE_WITH_OBJECT, 0, optr
	optr HINT_ALIGN_RIGHT_EDGE_WITH_OBJECT
		@reloc HINT_ALIGN_RIGHT_EDGE_WITH_OBJECT, 0, optr
	optr HINT_ALIGN_BOTTOM_EDGE_WITH_OBJECT
		@reloc HINT_ALIGN_BOTTOM_EDGE_WITH_OBJECT, 0, optr
	void HINT_DONT_SHOW_SHORTCUT
	void HINT_MINIMIZE_CHILD_SPACING
	BackgroundColors HINT_GADGET_BACKGROUND_COLORS
	void HINT_ORIENT_CHILDREN_ALONG_LONGER_DIMENSION
	void HINT_PLACE_MONKIER_ALONG_LARGER_DIMENSION
	void HINT_WRAP_AFTER_CHILD_COUNT_IF_VERTICAL_SCREEN
	void HINT_NOT_MOVABLE
	void HINT_SEEK_TITLE_BAR_LEFT
	void HINT_SEEK_TITLE_BAR_RIGHT
	void HINT_WINDOW_NO_CONSTRAINTS
	SpecSizeSpec HINT_CUSTOM_CHILD_SPACING_IF_LIMITED_SPACE
	void HINT_WINDOW_NO_TITLE_BAR
	void HINT_WINDOW_NO_SYS_MENU
	SystemAttrs HINT_IF_SYSTEM_ATTRS
	void HINT_ENDIF
	void HINT_ELSE

**Types and Flags**

	typedef enum /* word */ {
		TO_GEN_PARENT=_FIRST_GenClass,
		TO_FOCUS,
		TO_TARGET,
		TO_MODEL,
		TO_APP_FOCUS,
		TO_APP_TARGET,
		TO_APP_MODEL,
		TO_SYS_FOCUS,
		TO_SYS_TARGET,
		TO_SYS_MODEL
	} GenTravelOption
	typedef enum {
		BRPT_OUTPUT_OPTR
	} BranchReplaceParamType
	typedef enum {
		GUQT_UI_FOR_APPLICATION
		GUQT_UI_FOR_SCREEN
		GUQT_UI_FOR_FIELD
		GUQT_UI_FOR_MISC
		GUQT_FIELD
		GUQT_SCREEN
		GUQT_DELAYED_OPERATION
	} GenUpwardQueryType
	ByteFlags		NotifyEnabledFlags
		NEF_STATE_CHANGING				0x80
	ByteEnum		RequestedViewArea
		RVA_NO_AREA_CHOICE				0
		RVA_X_SCROLLER_AREA				1
		RVA_Y_SCROLLER_AREA				2
		RVA_LEFT_AREA					3
		RVA_TOP_AREA					4
		RVA_RIGHT_AREA					5
		RVA_BOTTOM_AREA					6
	WordFlags		GenFindObjectWithMonikerFlags
		GFTMF_EXACT_MATCH				0x8000
		GFTMF_SKIP_THIS_NODE			0x4000
	typedef enum {
		GDMT_LEVEL_0
		GDMT_LEVEL_1
		GDMT_LEVEL_2
		GDMT_LEVEL_3
		GDMT_HELP
		GDMT_HELP_PRIMARY
	} GenDefaultMonikerType
	WordFlags		SystemAttrs
		SA_NOT						0x8000
		SA_TINY						0x4000
		SA_HORIZONTALLY_TINY		0x2000
		SA_VERTICALLY_TINY			0x1000
		SA_COLOR					0x0800
		SA_PEN_BASED				0x0400
		SA_KEYBOARD_ONLY			0x0200
		SA_NO_KEYBOARD				0x0100
	ByteEnum GCMIcon
		GCMI_NONE		0
		GCMI_EXIT		1
		GCMI_HELP		2
	ByteFlags GeneralConsumerModeFlags
		GCMF_LEFT_ICON				0x38
		GCMF_RIGHT_ICON				0x07
	ByteEnum		GenUILevel
		GUIL_DEFAULT				0
		GUIL_GCM					1
		GUIL_NOVICE					2
		GUIL_ADVANCED				3
	ByteFlags GenAttrs
		GA_SIGNAL_INTERACTION_COMPLETE		0x80
		GA_INITIATES_BUSY_STATE				0x40
		GA_INITIATES_INPUT_HOLD_UP			0x20
		GA_INITIATES_INPUT_IGNORE			0x10
		GA_READ_ONLY						0x08
		GA_KBD_SEARCH_PATH					0x04
		GA_TARGETABLE						0x02
		GA_NOTIFY_VISIBILITY				0x01
	ByteFlags GenStates
		GS_USABLE			0x80
		GS_ENABLED			0x40
	typedef ByteEnum DefaultActionMode
		DAM_ACTIVATE_INTERACTION_DEFAULT		0
		DAM_NAVIGATE_TO_NEXT_FIELD				1
		DAM_APPL_VERIFY							2
		DAM_APPL_CUSTOM							3
	DAM_TAKES_DEFAULT				DAM_NAVIGATE_TO_NEXT_FIELD
	DAM_APPL_HANDLES				DAM_APPL_VERIFY
	ByteFlags GadgetAttrs
		GA_DELAYED						0x80
		GA_DISPLAY_ONLY					0x40
		GA_IN_ADD_MODE					0x20
		GA_SEND_USER_CHANGES			0x10
		GA_SEND_REDUNDANT_CHANGES		0x08
		GA_DEFAULT_ACTIONS				0x06
		GA_USER_ACTION_DETERMINES_MESSAGE 0x01
	GA_DEFAULT_ACTIONS_OFFSET			1
	ByteFlags GadgetActionFlags
		GAF_ACTUAL_CHANGE				0x04
		GAF_USER_CHANGE					0x02
		GAF_DEFAULT_ACTION_REQUEST		0x01
	ByteFlags GadgetChangeFlags
		GCF_NO_USER_CHANGE				0x04
		GCF_SUPPRESS_APPLY				0x02
		GCF_SUPPRESS_DRAW				0x01

**Structures**

	typedef struct {
	    word			SSA_width
	    word			SSA_height
	    word			SSA_count
	    VisUpdateMode	SSA_updateMode
	} SetSizeArgs
	typedef struct {
	    word			GSA_width
	    word			GSA_height
	    word			GSA_unused
	    word			GSA_count
	} GetSizeArgs
	typedef struct {
	    word			GRP_ax
	    word			GRP_bp
	    word			GRP_cx
	    word			GRP_dx
	} GenReturnParams
	typedef struct {
	    optr			GGFI_optr
	    word			GGFI_window
	    word			GGFI_unused
	} GenGupFieldInfo
	typedef struct {
	    optr			GGSI_optr
	    word			GGSI_window
	    word			GGSI_unused
	} GenGupScreenInfo
	typedef struct {
	    byte			GFVRP_hViewArea
	    byte			GFVRP_vViewArea
	    ChunkHandle		GFVRP_hRange
	    ChunkHandle		GFVRP_vRange
	} GenFindViewRangesParams
	typedef struct {
	    char		GOP_category[INI_CATEGORY_BUFFER_SIZE]
	    char		GOP_key[INI_CATEGORY_BUFFER_SIZE]
	} GenOptionsParams
	typedef struct {
	    DiskHandle		GFP_disk
	    PathName		GFP_path
	} GenFilePath
	typedef struct {
	    ClassStruct		*DCA_class
	} DestinationClassArgs
	typedef struct {
	    SpecWidth		CSHA_width
	    SpecHeight		CSHA_height
	    sword			CSHA_count
	} CompSizeHintArgs
	typedef struct {
	    SpecWidth		GSHA_width
	    SpecHeight		GSHA_height
	} GadgetSizeHintArgs
	typedef struct {
	    word			HE_type
	    word			HE_size
	} HintEntry
	typedef struct {
	    byte			BC_unselectedColor1
	    byte			BC_unselectedColor2
	    byte			BC_selectedColor1
	    byte			BC_selectedColor2
	} BackgroundColors

**Macros**

	GET_MM_AND_TYPE(M,T)			((M) | ((T) << 8))
	GET_CHAR_AND_SHIFT(C,S)			((C) | (((word) (S)) << 8))
	GET_VIEW_AREAS(H,V)				((H) | (((word) (V)) << 8))
	ObjDerefGen(obj)				ObjDeref2(obj)

**Messages**
	@exportMessages GenSpecMessages,
					DEFAULT_EXPORTED_MESSAGES_3
	@exportMessages GenAppMessages,
					DEFAULT_EXPORTED_MESSAGES_5
	void MSG_GEN_SET_ENABLED(VisUpdateMode updateMode)
	void MSG_GEN_SET_NOT_ENABLED(VisUpdateMode updateMode)
	Boolean MSG_GEN_GET_ENABLED()
	void MSG_GEN_SET_USABLE(VisUpdateMode updateMode)
	void MSG_GEN_SET_NOT_USABLE(VisUpdateMode updateMode)
	Boolean MSG_GEN_GET_USABLE()
	Boolean MSG_GEN_CHECK_IF_FULLY_ENABLED()
	Boolean MSG_GEN_CHECK_IF_FULLY_USABLE()
	void MSG_GEN_SET_ATTRS(
				GenAttrs attrsToSet,
				GenAttrs attrsToClear)
	GenAttrs MSG_GEN_GET_ATTRIBUTES()
	ChunkHandle MSG_GEN_GET_VIS_MONIKER()
	void MSG_GEN_USE_VIS_MONIKER(
				ChunkHandle 			moniker,
				VisUpdateMode 			updateMode)
	ChunkHandle MSG_GEN_REPLACE_VIS_MONIKER(@stack
				VisUpdateMode 			updateMode,
				word height, 			word width,
				word length,
				VisMonikerDataType 		dataType,
				VisMonikerSourceType 	sourceType,
				dword 					source)
	ChunkHandle MSG_GEN_REPLACE_VIS_MONIKER_OPTR(
				optr source,
				VisUpdateMode updateMode)
	ChunkHandle MSG_GEN_REPLACE_VIS_MONIKER_TEXT(
				char 					*source,
				VisUpdateMode 			updateMode) 
	ChunkHandle MSG_GEN_CREATE_VIS_MONIKER(@stack
				CreateVisMonikerFlags 	flags,
				word height, word width,
				word 					length,
				VisMonikerDataType 		dataType,
				VisMonikerSourceType 	sourceType,
				dword 			source)
	void MSG_GEN_DRAW_MONIKER(
				DrawMonikerFlags monikerFlags,
				word textHeight,
				GStateHandle gState,
				word yMaximum, word xMaximum,
				word yInset, word xInset)
	XYValueAsDWord MSG_GEN_GET_MONIKER_POS(
				DrawMonikerFlags monikerFlags,
				word textHeight,
				GStateHandle gState, word yMaximum,
				word xMaximum, word yInset,
				word xInset)
	SizeAsDWord MSG_GEN_GET_MONIKER_SIZE(
				word textHeight,
				GStateHandle gState)
	optr MSG_GEN_FIND_MONIKER( Boolean useAppMonikerList ,
				VisMonikerSearchFlags searchFlags,
				MemHandle destBlock)
	void MSG_GEN_RELOC_MONIKER_LIST(
				optr 		monikerList,
				Boolean 		relocFlag)
	void MSG_GEN_SET_KBD_ACCELERATOR(
				KeyboardShortcut accelerator,
				VisUpdateMode updateMode)
	KeyboardShortcut MSG_GEN_GET_KBD_ACCELERATOR()
	void MSG_GEN_CHANGE_ACCELERATOR(
				KeyboardShortcut bitsToClear,
				KeyboardShortcut bitsToSet)
	void MSG_GEN_ADD_CHILD(
				optr child, CompChildFlags flags)
	void MSG_GEN_REMOVE_CHILD(
				optr child, CompChildFlags flags)
	void MSG_GEN_ADD_CHILD_UPWARD_LINK_ONLY(optr child)
	void MSG_GEN_MOVE_CHILD(
				optr child, CompChildFlags flags)
	word MSG_GEN_FIND_CHILD(optr child)
	optr MSG_GEN_FIND_CHILD_AT_POSITION(word position)
	optr MSG_GEN_FIND_PARENT()
	word MSG_GEN_COUNT_CHILDREN()
	void MSG_GEN_CALL_PARENT(EventHandle event )
	void MSG_GEN_SEND_TO_PARENT(EventHandle event)
	void MSG_GEN_SEND_TO_CHILDREN(EventHandle event)
	void MSG_GEN_GUP_CALL_OBJECT_OF_CLASS(EventHandle event)
	void MSG_GEN_GUP_SEND_TO_OBJECT_OF_CLASS(
				EventHandle event)
	Boolean MSG_GEN_GUP_TEST_FOR_OBJECT_OF_CLASS(
				ClassStruct *class)
	optr MSG_GEN_GUP_FIND_OBJECT_OF_CLASS(
				ClassStruct *class)
	void MSG_GEN_CALL_APPLICATION(EventHandle event)
	void MSG_GEN_SEND_TO_PROCESS(EventHandle event)
	void MSG_GEN_CALL_SYSTEM(EventHandle event)
	void MSG_GEN_OUTPUT_ACTION(EventHandle event, optr dest)
	optr MSG_GEN_COPY_TREE(
				MemHandle destBlock,
				ChunkHandle parentChunk,
				CompChildFlags flags)
	void MSG_GEN_DESTROY(
				VisUpdateMode updateMode,
				CompChildFlags flags)
	void MSG_GEN_BRANCH_REPLACE_PARAMS(
				BranchReplaceParamType type,
				dword replaceParam,
				dword searchParam)
	void MSG_GEN_BRANCH_REPLACE_OUTPUT_OPTR_CONSTANT(
				optr replacementOptr,
				word searchConstant)
	void MSG_GEN_BRING_TO_TOP()
	void MSG_GEN_LOWER_TO_BOTTOM()
	void MSG_GEN_SET_WIN_POSITION(
				WinPositionType modeAndType,
				SpecWinSizeSpec xPosSpec,
				SpecWinSizeSpec yPosSpec)
	void MSG_GEN_SET_WIN_SIZE(
			WinPositionType modeAndType,
			SpecWinSizeSpec xSizeSpec,
			SpecWinSizeSpec ySizeSpec)
	void MSG_GEN_RESET_TO_INITIAL_SIZE(
				VisUpdateMode updateMode)
	void MSG_GEN_SET_WIN_CONSTRAIN(
				VisUpdateMode updateMode,
				WinConstrainType constrainType)
	void MSG_GEN_SET_INITIAL_SIZE(@stack
				VisUpdateMode updateMode, 
				word count, 
				SpecHeight height, SpecWidth width)
	void MSG_GEN_SET_MINIMUM_SIZE(@stack
				VisUpdateMode updateMode, 
				word count, 
				SpecHeight height, SpecWidth width)
	void MSG_GEN_SET_MAXIMUM_SIZE(@stack
				VisUpdateMode updateMode, 
				word count, 
				SpecHeight height, SpecWidth width)
	void MSG_GEN_SET_FIXED_SIZE(@stack
				VisUpdateMode updateMode, 
				word count, 
				SpecHeight height, SpecWidth width)
	void MSG_GEN_GET_INITIAL_SIZE(GetSizeArgs *initSize)
	void MSG_GEN_GET_MINIMUM_SIZE(GetSizeArgs *minSize )
	void MSG_GEN_GET_MAXIMUM_SIZE(GetSizeArgs *maxSize)
	void MSG_GEN_GET_FIXED_SIZE(GetSizeArgs *fixedSize)
	void MSG_GEN_UPDATE_VISUAL(VisUpdateMode updateMode)
	void MSG_GEN_APPLY()
	void MSG_GEN_RESET()
	Boolean MSG_GEN_PRE_APPLY()
	void MSG_GEN_POST_APPLY()
	void MSG_GEN_MAKE_APPLYABLE()
	void MSG_GEN_MAKE_NOT_APPLYABLE()
	void MSG_GEN_ACTIVATE()
	Boolean MSG_GEN_ACTIVATE_INTERACTION_DEFAULT()
	void MSG_GEN_NAVIGATE_TO_NEXT_FIELD()
	void MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD()
	Boolean MSG_GEN_NAVIGATION_QUERY(
				NavigationQueryParams *retValue,
				optr queryOrigin,
				NavigationFlags navFlags)
	Boolean MSG_GEN_GUP_QUERY(
				GenReturnParams *retValue,
				GenUpwardQueryType queryType)
	Boolean MSG_GEN_GUP_QUERY_FOR_FIELD(
				GenGupFieldInfo *retValue,
				GenUpwardQueryType queryType)
	Boolean MSG_GEN_GUP_QUERY_FOR_SCREEN(
				GenGupScreenInfo *retValue,
				GenUpwardQueryType queryType)
	Boolean MSG_GEN_GUP_INTERACTION_COMMAND(
				InteractionCommand command)
	Boolean MSG_GEN_FIND_KBD_ACCELERATOR(
				word charValue,
				word charFlagsAndShiftState,
				word toggleStateAndScanCode)
	void MSG_GEN_SET_KBD_MKR_PATH()
	Boolean MSG_GEN_PATH_SET(char *path, DiskHandle disk)
	Boolean MSG_GEN_PATH_GET(char *buffer, word bufSize )
	@alias (MSG_GEN_PATH_GET) MemHandle
			MSG_GEN_PATH_GET_BLOCK(
				char *buffer, word bufSize)
	DiskHandle MSG_GEN_PATH_GET_DISK_HANDLE()
	optr MSG_GEN_FIND_OBJECT_WITH_TEXT_MONIKER(
				char *text,
				GenFindObjectWithMonikerFlags flags)
	void MSG_GEN_GUP_FINISH_QUIT(
				Boolean abortFlag,
				Boolean notifyParent)
	void MSG_GEN_REMOVE(VisUpdateMode updateMode,
				CompChildFlags flags)
	Boolean MSG_GEN_DESTROY_AND_FREE_BLOCK()
	void MSG_GEN_SET_KBD_OVERRIDE(KeyboardOverride override)
	void MSG_GEN_SET_KBD_POSITION(
				sword xCoord, sword yCoord)
	@prototype void GEN_VISIBILITY_OUTPUT(
				optr obj, Boolean opening)

**Routines**

	word * ObjDerefGen(obj)
	word GenCopyChunk(MemHandle destBlock, MemHandle blk,
				ChunkHandle chnk, 
				CompChildFlags flags)
	void GenInsertChild(MemHandle mh, ChunkHandle chnk,
				optr childToAdd,
				optr referenceChild, 
				CompChildFlags flags)
	void GenSetUpwardLink(MemHandle mh, ChunkHandle chnk,
				optr parent)
	void GenRemoveDownwardLink(MemHandle mh,
				ChunkHandle chnk, 
				CompChildFlags flags)
	void GenSpecShrink(MemHandle mh, ChunkHandle chnk)
	void GenProcessGenAttrsBeforeAction(
				MemHandle mh, ChunkHandle chnk)
	void GenProcessGenAttrsAfterAction(
				MemHandle mh, ChunkHandle chnk)
	optr GenFindObjectInTree(optr startObject,
				dword childTable)

## GenContentClass

	@class GenContentClass, GenClass

**Instance Data**

	byte		GCI_attrs = 0 /* VisContentAttrs */
	optr		GCI_genView

**Hints**

	void HINT_CONTENT_KEEP_FOCUS_VISIBLE

**Messages**

	byte MSG_GEN_CONTENT_GET_ATTRS()
	void MSG_GEN_CONTENT_SET_ATTRS(
				byte attrsToSet, byte attrsToClear)

## GenControlClass

	@class GenControlClass, GenInteractionClass

**Instance Data**

	optr GCI_output
		@default GI_states = (@default & ~GS_ENABLED)

**Variable Data**

	TempGenControlInstance TEMP_GEN_CONTROL_INSTANCE
	WordFlags ATTR_GEN_CONTROL_REQUIRE_UI
	WordFlags ATTR_GEN_CONTROL_REQUIRE_TOOLBOX_UI
	WordFlags ATTR_GEN_CONTROL_PROHIBIT_UI
	WordFlags ATTR_GEN_CONTROL_PROHIBIT_TOOLBOX_UI
	optr ATTR_GEN_CONTROL_APP_UI
		@reloc ATTR_GEN_CONTROL_APP_UI, 0, optr
	optr ATTR_GEN_CONTROL_APP_TOOLBOX_UI
		@reloc ATTR_GEN_CONTROL_APP_TOOLBOX_UI, 0, optr
	void TEMP_GEN_CONTROL_OPTIONS_LOADED
	void ATTR_GEN_CONTROL_DO_NOT_USE_LIBRARY_NAME_FOR_HELP

**Hints**

	GenControlUserData HINT_GEN_CONTROL_MODIFY_INITIAL_UI
	GenControlUserData HINT_GEN_CONTROL_USER_MODIFIED_UI
	void HINT_GEN_CONTROL_TOOLBOX_ONLY
	GenControlScalableUIEntry HINT_GEN_CONTROL_SCALABLE_UI_DATA
	void HINT_GEN_CONTROL_DESTROY_CHILDREN_WHEN_NOT_INTERACTABLE

**Types and Flags**

	ByteFlags GenControlFeatureFlags
	ByteFlags GenControlChildFlags
		GCCF_NOTIFY_WHEN_ADDING					0x04
		GCCF_ALWAYS_ADD							0x02
		GCCF_IS_DIRECTLY_A_FEATURE				0x01
	WordFlags GenControlBuildFlags
		GCBF_SUSPEND_ON_APPLY					0x8000
		GCBF_USE_GEN_DESTROY					0x4000
		GCBF_SPECIFIC_UI						0x2000
		GCBF_CUSTOM_ENABLE_DISABLE				0x1000
		GCBF_ALWAYS_UPDATE						0x0800
		GCBF_EXPAND_TOOL_WIDTH_TO_FIT_PARENT 	0x0400
		GCBF_ALWAYS_INTERACTIBLE 				0x0200
		GCBF_ALWAYS_ON_GCN_LIST					0x0100
		GCBF_MANUALLY_REMOVE_FROM_ACTIVE_LIST	0x0080
		GCBF_IS_ON_ACTIVE_LIST 					0x0040
		GCBF_IS_ON_START_LOAD_OPTIONS_LIST		0x0020
		GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST
												0x0010
	#define GCBF_DO_NOT_DESTROY_CHILDREN_WHEN_CLOSED 
												0x0008
	typedef enum /* word */ {
		GCUIT_NORMAL,
		GCUIT_TOOLBOX
	} GenControlUIType
	WordFlags GenControlInteractableFlags
		GCIF_CONTROLLER					0x8000
		GCIF_TOOLBOX_UI					0x0002
		GCIF_NORMAL_UI					0x0001
	WordFlags GenControlStatusChange
		GCSF_HIGHLIGHTED_TOOLGROUP_SELECTED 0X0004
		GCSF_TOOLBOX_FEATURES_CHANGED					0x0002
		GCSF_NORMAL_FEATURES_CHANGED					0x0001
	WordFlags GenControlUserFlags
		GCUF_USER_TOOLBOX_UI				0x0002
		GCUF_USER_UI						0x0001
	ByteEnum		GenControlScalableUICommand
		GCSUIC_SET_NORMAL_FEATURES_IF_APP_FEATURE_ON		0
		GCSUIC_SET_TOOLBOX_FEATURES_IF_APP_FEATURE_ON		1
		GCSUIC_SET_NORMAL_FEATURES_IF_APP_FEATURE_OFF		2
		GCSUIC_SET_TOOLBOX_FEATURES_IF_APP_FEATURE_OFF		3
		GCSUIC_SET_NORMAL_FEATURES_IF_APP_LEVEL				4
		GCSUIC_SET_TOOLBOX_FEATURES_IF_APP_LEVEL			5
		GCSUIC_ADD_NORMAL_FEATURES_IF_APP_FEATURE_ON		6
		GCSUIC_ADD_TOOLBOX_FEATURES_IF_APP_FEATURE_ON		7

**Structures**

	typedef struct {
		ChunkHandle				GCFI_object
		optr					GCFI_name
		GenControlFeatureFlags	GCFI_flags
	} GenControlFeaturesInfo
	typedef struct {
		ChunkHandle				GCCI_object
		WordFlags				GCCI_featureMask
		GenControlChildFlags	GCCI_flags
	} GenControlChildInfo
	typedef struct {
		GenControlBuildFlags	GCBI_flags
		const char				*GCBI_initFileKey
		const GCNListType		*GCBI_gcnList
		word					GCBI_gcnCount
		const NotificationType	*GCBI_notificationList
		word					GCBI_notificationCount
		optr					GCBI_controllerName
		MemHandle				GCBI_dupBlock
		const GenControlChildInfo *GCBI_childList
		word					GCBI_childCount
		const GenControlFeaturesInfo *GCBI_featuresList
		word					GCBI_featuresCount
		WordFlags				GCBI_features
		MemHandle				GCBI_toolBlock
		const GenControlChildInfo *GCBI_toolList
		word					GCBI_toolCount
		const GenControlFeaturesInfo *GCBI_toolFeaturesList
		word					GCBI_toolFeaturesCount
		WordFlags				GCBI_toolFeatures
		char					*GCBI_helpContext
		byte					GCBI_reserved[8]
	} GenControlBuildInfo
	typedef struct {
		WordFlags			GCSI_userAdded
		WordFlags			GCSI_userRemoved
		WordFlags			GCSI_appRequired
		WordFlags			GCSI_appProhibited
	} GenControlScanInfo
	typedef struct {
		WordFlags			GCSR_features
		WordFlags			GCSR_required
		WordFlags			GCSR_prohibited
		WordFlags			GCSR_supported
	} GenControlGetFeaturesReturn
	typedef struct {
		optr					NGCS_controller
		GenControlStatusChange	NGCS_statusChange
	} NotifyGenControlStatusChange
	typedef struct {
		GenControlInteractableFlags TGCI_interactableFlags
		MemHandle				TGCI_childBlock
		MemHandle				TGCI_toolBlock
		MemHandle				TGCI_toolParent
		WordFlags				TGCI_features
		WordFlags				TGCI_toolboxFeatures
		GCNListType				TGCI_activeNotificationList
		GenControlInteractableFlags TGCI_upToDate
	} TempGenControlInstance
	typedef struct {
		GenControlUserFlags		GCUD_flags
		word					GCUD_userAddedUI
		word					GCUD_userRemovedUI
		word					GCUD_userAddedToolboxUI
		word					GCUD_userRemovedToolboxUI
	} GenControlUserData
	typedef struct {
		GenControlScalableUICommand	GCSUIE_command
		WordFlags					GCSUIE_appFeature
		WordFlags					GCSUIE_newFeatures
	} GenControlScalableUIEntry

**Messages**

	void MSG_GEN_CONTROL_GET_INFO(GenControlBuildInfo *info)
	void MSG_GEN_CONTROL_GENERATE_UI()
	void MSG_GEN_CONTROL_DESTROY_UI()
	void MSG_GEN_CONTROL_GENERATE_TOOLBOX_UI(optr parent)
	void MSG_GEN_CONTROL_DESTROY_TOOLBOX_UI()
	void MSG_GEN_CONTROL_UPDATE_UI(@stack
				MemHandle toolBlock,
				MemHandle childBlock,
				WordFlags toolboxFeatures,
				WordFlags features,
				MemHandle data,
				word changeID,
				ManufacturerID manufID)
	void MSG_GEN_CONTROL_ENABLE_DISABLE(
				Message msg,
				VisUpdateMode updateMode)
	void MSG_GEN_CONTROL_SCAN_FEATURE_HINTS(
				GenControlUIType type,
				GenControlScanInfo *info)
	void MSG_GEN_CONTROL_ADD_FEATURE(WordFlags featureToAdd)
	void MSG_GEN_CONTROL_REMOVE_FEATURE(
				WordFlags featureToRemove)
	void MSG_GEN_CONTROL_ADD_TOOLBOX_FEATURE(
				WordFlags featureToAdd)
	void MSG_GEN_CONTROL_REMOVE_TOOLBOX_FEATURE(
				WordFlags featureToRemove)
	void MSG_GEN_CONTROL_NOTIFY_INTERACTABLE(
				GenControlInteractableFlags flags)
	void MSG_GEN_CONTROL_NOTIFY_NOT_INTERACTABLE(
				GenControlInteractableFlags flags)
	void MSG_GEN_CONTROL_UNBUILD_NORMAL_UI_IF_POSSIBLE()
	void MSG_GEN_CONTROL_ADD_TO_GCN_LISTS()
	void MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS()
	MSG_GEN_CONTROL_GET_NORMAL_FEATURES(
				GenControlGetFeaturesReturn *return)
	MSG_GEN_CONTROL_GET_TOOLBOX_FEATURES(
				GenControlGetFeaturesReturn *return)
	void MSG_GEN_CONTROL_ADD_APP_UI(optr appUI)
	void MSG_GEN_CONTROL_ADD_APP_TOOLBOX_UI(optr appUI)
	void MSG_GEN_CONTROL_REBUILD_NORMAL_UI()
	void MSG_GEN_CONTROL_REBUILD_TOOLBOX_UI()
	void MSG_GEN_CONTROL_ADD_TO_UI()
	void MSG_GEN_CONTROL_REMOVE_FROM_UI()
	void MSG_GEN_CONTROL_OUTPUT_ACTION(EventHandle event)
	void MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI(
				MemHandle childBlock,
				WordFlags features)
	void MSG_GEN_CONTROL_TWEAK_DUPLICATED_TOOLBOX_UI(
				MemHandle toolBlock,
				WordFlags toolboxFeatures)
	void MSG_GEN_CONTROL_NOTIFY_ADDING_FEATURE(optr feature)
	void MSG_GEN_CONTROL_FREE_OBJ_BLOCK(
				MemHandle blockToFree)

## GenDisplayClass

	@class GenDisplayClass, GenClass

**Instance Data**

	GenDisplayAttrs GDI_attributes = GDA_USER_DISMISSABLE
	optr		GDI_document
		@default	GI_attrs = (@default | GA_TARGETABLE |
								GA_KBD_SEARCH_PATH)

**Variable Data**

	ChunkHandle ATTR_GEN_DISPLAY_TRAVELING_OBJECTS
	void ATTR_GEN_DISPLAY_NOT_MINIMIZABLE
	void ATTR_GEN_DISPLAY_NOT_MAXIMIZABLE
	void ATTR_GEN_DISPLAY_NOT_RESTORABLE
	void ATTR_GEN_DISPLAY_MINIMIZED_STATE
	void ATTR_GEN_DISPLAY_MAXIMIZED_STATE
	void ATTR_GEN_DISPLAY_MENU_BAR_POPPED_OUT

**Hints**

	void HINT_DISPLAY_MINIMIZED_ON_STARTUP
	void HINT_DISPLAY_NOT_MINIMIZED_ON_STARTUP
	void HINT_DISPLAY_MAXIMIZED_ON_STARTUP
	void HINT_DISPLAY_NOT_MAXIMIZED_ON_STARTUP
	void HINT_DISPLAY_NOT_RESIZABLE

**Types and Flags**

	ByteFlags		GenDisplayAttrs
		GDA_USER_DISMISSABLE					0x80

**Structures**

	typedef struct {
		optr			TIR_travelingObject
		ChunkHandle			TIR_parent
		word			TIR_compChildFlags
	} TravelingObjectReference

**Messages**

	void MSG_GEN_DISPLAY_SET_MINIMIZED()
	void MSG_GEN_DISPLAY_SET_NOT_MINIMIZED()
	Boolean MSG_GEN_DISPLAY_GET_MINIMIZED()
	void MSG_GEN_DISPLAY_SET_MAXIMIZED()
	void MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED()
	Boolean MSG_GEN_DISPLAY_GET_MAXIMIZED()
	void MSG_GEN_DISPLAY_SET_ATTRS(byte attrs)
	byte MSG_GEN_DISPLAY_GET_ATTRS()
	optr MSG_GEN_DISPLAY_GET_DOCUMENT()
	void MSG_GEN_DISPLAY_CLOSE()

## GenDisplayControlClass

	@class GenDisplayControlClass, GenControlClass

**Instance Data**

	GenDisplayControlAttributes GDCII_attrs =
						(GDCA_MAXIMIZED_NAME_ON_PRIMARY)
		@default GI_states = @default | GS_ENABLED
		@default GCI_output = (TO_APP_TARGET)

**Variable Data**

	void TEMP_GDC_CACHED_NAME
	NotifyDisplayListChange TEMP_GDC_CACHED_LIST_DATA
	NotifyDisplayListChange TEMP_GDC_CACHED_TOOL_LIST_DATA
	word TEMP_GDC_CACHED_SELECTED_DISPLAY

**Hints**

	void HINT_DISPLAY_CONTROL_\
				NO_FEATURES_IF_TRANSPARENT_DOC_CTRL_MODE

**Types and Flags**

	ByteFlags		GenDisplayControlAttributes
		GDCA_MAXIMIZED_NAME_ON_PRIMARY	0x80
	MAX_DISPLAY_NAME_SIZE				64
	WordFlags GDCFeatures
		GDCF_OVERLAPPING_MAXIMIZED		0x0004
		GDCF_TILE						0x0002
		GDCF_DISPLAY_LIST				0x0001
	WordFlags GDCToolboxFeatures
		GDCTF_OVERLAPPING_MAXIMIZED		0x0004
		GDCTF_TILE						0x0002
		GDCTF_DISPLAY_LIST				0x0001
	GDC_DEFAULT_FEATURES		(GDCF_OVERLAPPING_MAXIMIZED |
								 GDCF_TILE |
								 GDCF_DISPLAY_LIST)
	GDC_DEFAULT_TOOLBOX_FEATURES (GDCF_DISPLAY_LIST)
	ByteFlags		GenDisplayControlAttributes
		GDCA_MAXIMIZED_NAME_ON_PRIMARY	0x80

**Structures**

	typedef struct {
		optr			NDC_display
		char			NDC_name[MAX_DISPLAY_NAME_SIZE]
		byte			NDC_overlapping
	} NotifyDisplayChange
	typedef struct {
		word			NDLC_counter
		optr			NDLC_group
	} NotifyDisplayListChange

**Messages**

	void MSG_GDC_SET_OVERLAPPING()
	void MSG_GDC_TILE()
	void MSG_GDC_LIST_APPLY()
	void MSG_GDC_LIST_QUERY()

## GenDisplayGroupClass

	@class GenDisplayGroupClass, GenClass

**Instance Data**

		@default 			GI_attrs = @default | GA_TARGETABLE

**Variable Data**

	void ATTR_GEN_DISPLAY_GROUP_NO_FULL_SIZED
	void ATTR_GEN_DISPLAY_GROUP_NO_OVERLAPPING
	void ATTR_GEN_DISPLAY_GROUP_OVERLAPPING_STATE

**Hints**

	void HINT_DISPLAY_GROUP_SEPARATE_MENUS
	void HINT_DISPLAY_GROUP_ARRANGE_TILED
	void HINT_DISPLAY_GROUP_FULL_SIZED_ON_STARTUP
	void HINT_DISPLAY_GROUP_OVERLAPPING_ON_STARTUP
	void HINT_DISPLAY_GROUP_\
					FULL_SIZED_IF_TRANSPARENT_DOC_CTRL_MODE
	void HINT_DISPLAY_GROUP_TILE_HORIZONTALLY
	void HINT_DISPLAY_GROUP_TILE_VERTICALLY
	void HINT_DISPLAY_GROUP_SIZE_INDEPENDENTLY_OF_DISPLAYS

**Messages**

	void MSG_GEN_DISPLAY_GROUP_SET_FULL_SIZED()
	void MSG_GEN_DISPLAY_GROUP_SET_OVERLAPPING()
	Boolean MSG_GEN_DISPLAY_GROUP_GET_FULL_SIZED()
	void MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS()
	void MSG_GEN_DISPLAY_GROUP_SELECT_DISPLAY(
							word displayNum)

## GenDocumentClass

	@class GenDocumentClass, GenContentClass

**Instance Data**

	GenDocumentAttrs	GDI_attrs = 0
	GenDocumentType 	GDI_type = 0
	word				GDI_operation = 0
	FileHandle			GDI_fileHandle = 0
	FileLongName		GDI_fileName = ""
	MemHandle			GDI_display = 0
		@default GI_attrs = (@default | GA_KBD_SEARCH_PATH)

**Variable Data**

	void ATTR_GEN_DOCUMENT_OPEN_FOR_IACP_ONLY

**Types and Flags**

	WordFlags GenDocumentAttrs
		GDA_READ_ONLY				0x8000
		GDA_READ_WRITE				0x4000
		GDA_FORCE_DENY_WRITE		0x2000
		GDA_SHARED_MULTIPLE			0x1000
		GDA_SHARED_SINGLE			0x0800
		GDA_UNTITLED				0x0400
		GDA_DIRTY					0x0200
		GDA_CLOSING					0x0100
		GDA_ATTACH_TO_DIRTY_FILE	0x0080
		GDA_SAVE_FAILED				0x0040
		GDA_OPENING					0x0020
		GDA_AUTO_SAVE_STOPPED		0x0010
		GDA_MODEL					0x0008
		GDA_ON_WRITABLE_MEDIA 		0x0004
		GDA_BACKUP_EXISTS 			0x0002
		GDA_PREVENT_AUTO_SAVE 		0x0001
	typedef enum {
		GDT_NORMAL,
		GDT_READ_ONLY,
		GDT_TEMPLATE,
		GDT_READ_ONLY_TEMPLATE,
		GDT_PUBLIC,
		GDT_MULTI_USER
	} GenDocumentType
	typedef enum /* word */ {
		GDO_NORMAL,
		GDO_SAVE_AS,
		GDO_REVERT,
		GDO_REVERT_QUICK,
		GDO_ATTACH,
		GDO_DETACH,
		GDO_NEW,
		GDO_OPEN,
		GDO_SAVE,
		GDO_CLOSE,
		GDO_AUTO_SAVE
	} GenDocumentOperation
	typedef WordFlags DocumentOpenFlags
		DOF_CREATE_FILE_IF_FILE_DOES_NOT_EXIST		0x8000
		DOF_FORCE_TEMPLATE_BEHAVIOR					0x4000
		DOF_SAVE_AS_OVERWRITE_EXISTING_FILE			0x2000
		DOF_REOPEN									0x1000
		DOF_RAISE_APP_AND_DOC						0x0800
		DOF_NAME_HOLDS_FILE_ID						0x0400
		DOF_FORCE_REAL_EMPTY_DOCUMENT				0x0200
		DOF_OPEN_FOR_IACP_ONLY						0x0100
	GEN_DOCUMENT_GET_VARIABLE_BUFFER_SIZE			100
	GEN_DOCUMENT_GENERATE_NAME_ERROR				0xffff
	GEN_DOCUMENT_GENERATE_NAME_CANCEL				0xfffe

**Structures**

	typedef struct {
		FileLongName				DCP_name
		DiskHandle					DCP_diskHandle
		PathName					DCP_path
		GenDocumentAttrs			DCP_docAttrs
		DocumentOpenFlags			DCP_flags
		IACPConnection				DCP_connection
	} DocumentCommonParams

**Messages**

	Boolean MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE()
	Boolean MSG_GEN_DOCUMENT_IMPORT(
				ImpexTranslationParams *params)
	void MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT()
	void MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT()
	void MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT()
	void MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT()
	void MSG_GEN_DOCUMENT_EXPORT(
				ImpexTranslationParams *params)
	void MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE()
	void MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE(
				Boolean isSave)
	void MSG_GEN_DOCUMENT_DOCUMENT_HAS_CHANGED()
	Boolean MSG_GEN_DOCUMENT_PHYSICAL_SAVE(word *error)
	Boolean MSG_GEN_DOCUMENT_PHYSICAL_UPDATE(word *error)
	Boolean MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS(
				word *fileOrError,
				DocumentCommonParams *params)
	Boolean MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS_FILE_HANDLE(
				word *error, FileHandle file)
	Boolean MSG_GEN_DOCUMENT_PHYSICAL_REVERT(word *error)
	Boolean MSG_GEN_DOCUMENT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT()
	Boolean MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT()
	Boolean MSG_GEN_DOCUMENT_PHYSICAL_CREATE(
				word *fileOrError,
				DocumentCommonParams *params)
	Boolean MSG_GEN_DOCUMENT_PHYSICAL_OPEN(
				word *fileOrError,
				DocumentCommonParams *params)
	void MSG_GEN_DOCUMENT_PHYSICAL_CLOSE()
	void MSG_GEN_DOCUMENT_PHYSICAL_DELETE()
	Boolean MSG_GEN_DOCUMENT_PHYSICAL_CHECK_FOR_MODIFICATIONS()
	Boolean MSG_GEN_DOCUMENT_PHYSICAL_COPY_TEMPLATE(
				word *fileOrError)
	void MSG_GEN_DOCUMENT_SAVE_AS_COMPLETED()
	void MSG_GEN_DOCUMENT_ATTACH_FAILED()
	void MSG_GEN_DOCUMENT_MARK_DIRTY()
	word MSG_GEN_DOCUMENT_GENERATE_NAME_FOR_NEW(
				char *buffer, word retryCount)
	void MSG_GEN_DOCUMENT_SAVE_AS_CANCELLED()
	byte MSG_GEN_DOCUMENT_COMPUTE_ACCESS_FLAGS(
				DocumentCommonParams *params)
	GenDocumentAttrs MSG_GEN_DOCUMENT_GET_ATTRS()
	void MSG_GEN_DOCUMENT_ENABLE_AUTO_SAVE()
	void MSG_GEN_DOCUMENT_DISABLE_AUTO_SAVE()
	void MSG_GEN_DOCUMENT_GET_FILE_NAME(char *buffer)
	FileHandle MSG_GEN_DOCUMENT_GET_FILE_HANDLE()
	GenDocumentOperation MSG_GEN_DOCUMENT_GET_OPERATION()
	optr MSG_GEN_DOCUMENT_GET_DISPLAY()
	Boolean MSG_GEN_DOCUMENT_NEW(word *fileOrError,
				DocumentCommonParams *params)
	Boolean MSG_GEN_DOCUMENT_OPEN(word *fileOrError,
				DocumentCommonParams *params)
	word MSG_GEN_DOCUMENT_CLOSE(IACPConnection connection)
	void MSG_GEN_DOCUMENT_QUICK_BACKUP()
	void MSG_GEN_DOCUMENT_RECOVER_QUICK_BACKUP()
	Boolean MSG_GEN_DOCUMENT_SAVE()
	Boolean MSG_GEN_DOCUMENT_SAVE_AS(word *fileOrError,
				DocumentCommonParams *params)
	Boolean MSG_GEN_DOCUMENT_SAVE_AS_TEMPLATE(
				word *fileOrError,
				DocumentCommonParams *params)
	Boolean MSG_GEN_DOCUMENT_COPY_TO(
				DocumentCommonParams *params)
	Boolean MSG_GEN_DOCUMENT_REVERT()
	void MSG_GEN_DOCUMENT_EDIT_USER_NOTES()
	void MSG_GEN_DOCUMENT_CHANGE_TYPE(GenDocumentType type)
	void MSG_GEN_DOCUMENT_CHANGE_PASSWORD(char *password)
	void MSG_GEN_DOCUMENT_RENAME()
	void MSG_GEN_DOCUMENT_SET_EMPTY()
	void MSG_GEN_DOCUMENT_CLEAR_EMPTY()
	void MSG_GEN_DOCUMENT_SET_DEFAULT()
	void MSG_GEN_DOCUMENT_CLEAR_DEFAULT()
	void MSG_GEN_DOCUMENT_CLOSE_IF_CLEAN_UNNAMED()
	Boolean MSG_GEN_DOCUMENT_SEARCH_FOR_DOC(
				DocumentCommonParams *params)
	Boolean MSG_GEN_DOCUMENT_TEST_FOR_FILE(
				FileHandle file, optr *docFound)
	void MSG_GEN_DOCUMENT_AUTO_SAVE()
	void MSG_GEN_DOCUMENT_UPDATE(word *error)
	void MSG_GEN_DOCUMENT_CHECK_FOR_MODIFICATIONS()
	void MSG_GEN_DOCUMENT_CLOSE_FILE(
				IACPConnection connection)
	void MSG_GEN_DOCUMENT_REOPEN_FILE()
	void MSG_GEN_DOCUMENT_GET_VARIABLE(@stack
				VisTextGraphic *graphic,
				char *buffer)
	void MSG_GEN_DOCUMENT_REVERT_NO_PROMPT()
	void MSG_GEN_DOCUMENT_FILE_CHANGED_REINITIALIZE_CREATED_UI()
	void MSG_GEN_DOCUMENT_CLOSE_IF_OPEN_FOR_IACP_ONLY()

## GenDocumentControlClass

	@class GenDocumentControlClass, GenControlClass

**Instance Data**

	GeodeToken			GDCI_documentToken = {"",0}
	GenFileSelectorType GDCI_selectorType = GFST_DOCUMENTS
	GenDocumentControlAttrs GDCI_attrs =
			((GDCM_SHARED_SINGLE << GDCA_MODE_OFFSET) |
			GDCA_VM_FILE | GDCA_SUPPORTS_SAVE_AS_REVERT
			| (GDCT_NEW << GDCA_CURRENT_TASK_OFFSET))
	GenDocumentControlFeatures GDCI_features =
			(GDCF_READ_ONLY_SUPPORTS_SAVE_AS_REVERT |
			GDCF_SINGLE_FILE_CLEAN_CAN_NEW_OPEN |
			GDCF_SUPPORTS_TEMPLATES |
			GDCF_SUPPORTS_USER_SETTABLE_EMPTY_DOCUMENT
			 | GDCF_SUPPORTS_USER_MAKING_SHARED_DOCUMENTS
			| GDCF_NAME_ON_PRIMARY)
	GenDocumentAttrs	GDCI_docAttrs = 0
	GenDocumentType 	GDCI_docType = 0
	FileHandle			GDCI_docFileHandle = 0
	byte				GDCI_emptyExists = 0
	byte				GDCI_defaultExists = 0
	ChunkHandle			GDCI_enableDisableList
	optr 				GDCI_openGroup
	optr 				GDCI_importGroup
	optr				GDCI_useTemplateGroup
	optr				GDCI_saveAsGroup
	optr				GDCI_exportGroup
	optr				GDCI_dialogGroup
	optr				GDCI_userLevelGroup
	ChunkHandle			GDCI_noNameText
	ChunkHandle			GDCI_defaultFile
	ChunkHandle			GDCI_templateDir
	optr				GDCI_documentGroup
	FileLongName		GDCI_targetDocName = ""
	ChunkHandle	 		GDCI_dialogNewText
	ChunkHandle	 		GDCI_dialogTemplateText
	ChunkHandle			GDCI_dialogOpenDefaultText
	ChunkHandle	 		GDCI_dialogImportText
	ChunkHandle	 		GDCI_dialogOpenText
	ChunkHandle			GDCI_dialogUserLevelText
	@visMoniker			GDCI_dialogNewMoniker
	@visMoniker			GDCI_dialogTemplateMoniker
	@visMoniker			GDCI_dialogOpenDefaultMoniker
	@visMoniker			GDCI_dialogImportMoniker
	@visMoniker			GDCI_dialogOpenMoniker
	@visMoniker			GDCI_dialogUserLevelMoniker
		@default GI_states = @default | GS_ENABLED
		@default GI_attrs = @default | GA_KBD_SEARCH_PATH

**Hints**

	void INT_GEN_DOCUMENT_CONTROL_NO_PROGRESS_DIALOG_ON_UPDATE_MAJOR
	void HINT_GEN_DOCUMENT_CONTROL_PROGRESS_DIALOG_ON_UPDATE_MINOR

**Variable Data**

	UIInterfaceLevel ATTR_GEN_DOCUMENT_CONTROL_NO_EMPTY_DOC_IF_NOT_ABOVE

**Types and Flags**

	WordFlags		GDCFeatures
		GDCF_NEW 					0x4000
		GDCF_OPEN 					0x2000
		GDCF_CLOSE 					0x1000
		GDCF_QUICK_BACKUP 			0x0800
		GDCF_SAVE 					0x0400
		GDCF_SAVE_AS 				0x0200
		GDCF_COPY 					0x0100
		GDCF_EXPORT 				0x0080
		GDCF_REVERT 				0x0080
		GDCF_RENAME 				0x0040
		GDCF_EDIT_USER_NOTES		0x0020
		GDCF_SET_TYPE 				0x0010
		GDCF_SET_PASSWORD 			0x0008
		GDCF_SAVE_AS_TEMPLATE		0x0004
		GDCF_SET_EMPTY_DOCUMENT 	0x0002
		GDCF_SET_DEFAULT_DOCUMENT 	0x0001
	WordFlags		GDCToolboxFeatures
		GDCTF_NEW_EMPTY				0x0020
		GDCTF_USE_TEMPLATE			0x0010
		GDCTF_OPEN					0x0008
		GDCTF_CLOSE 				0x0004
		GDCTF_SAVE					0x0002
		GDCTF_QUICK_BACKUP			0x0001
	GDC_SUGGESTED_INTRODUCTORY_FEATURES (0)
	GDC_SUGGESTED_BEGINNING_FEATURES
			(GDC_SUGGESTED_INTRODUCTORY_FEATURES |
			GDCF_QUICK_BACKUP | GDCF_COPY | GDCF_RENAME
			| GDCF_EXPORT | GDCF_EDIT_USER_NOTES)
	GDC_SUGGESTED_INTERMEDIATE_FEATURES
			(GDC_SUGGESTED_BEGINNING_FEATURES |
			GDCF_SAVE_AS | GDCF_REVERT |
			GDCF_SET_PASSWORD)
	GDC_SUGGESTED_ADVANCED_FEATURES
			(GDC_SUGGESTED_INTERMEDIATE_FEATURES |
			GDCF_SET_TYPE | GDCF_SAVE_AS_TEMPLATE |
			GDCF_SET_EMPTY_DOCUMENT |
			GDCF_SET_DEFAULT_DOCUMENT)
	ByteEnum		GDCTask
		GDCT_NONE					0
		GDCT_NEW					1
		GDCT_OPEN					2
		GDCT_USE_TEMPLATE			3
		GDCT_SAVE_AS				4
		GDCT_COPY_TO				5
		GDCT_DIALOG					6
		GDCT_TYPE 					7
		GDCT_PASSWORD 				8
	ByteEnum		GenDocumentControlMode
		GDCM_VIEWER					0
		GDCM_SHARED_SINGLE			1
		GDCM_SHARED_MULTIPLE		2
	WordFlags		GenDocumentControlAttrs
		GDCA_MULTIPLE_OPEN_FILES			0x8000
		GDCA_MODE							0x6000
		GDCA_DOS_FILE_DENY_WRITE			0x1000
		GDCA_VM_FILE						0x0800
		GDCA_NATIVE							0x0400
		GDCA_SUPPORTS_SAVE_AS_REVERT		0x0200
		GDCA_DOCUMENT_EXISTS				0x0100
		GDCA_CURRENT_TASK					0x00F0
		GDCA_DO_NOT_SAVE_FILES				0x0008
	GDCA_MODE_OFFSET				13
	GDCA_CURRENT_TASK_OFFSET		5
	WordFlags		GenDocumentControlFeatures
		GDCF_READ_ONLY_SUPPORTS_SAVE_AS_REVERT			0x8000
		GDCF_SINGLE_FILE_CLEAN_CAN_NEW_OPEN				0x4000
		GDCF_SUPPORTS_TEMPLATES							0x2000
		GDCF_SUPPORTS_USER_SETTABLE_EMPTY_DOCUMENT		0x1000
		GDCF_SUPPORTS_USER_SETTABLE_DEFAULT_DOCUMENT	0x0800
		GDCF_SUPPORTS_USER_MAKING_SHARED_DOCUMENTS		0x0400
		GDCF_NAME_ON_PRIMARY							0x0200
	ByteEnum		GenFileSelectorType
		GFST_DOCUMENTS				0
		GFST_EXECUTABLES			1
		GFST_NON_GEOS_FILES			2
		GFST_ALL_FILES				3

**Structures**

	typedef struct {
		FileLongName	DFCP_name
		DiskHandle		DFCP_diskHandle
		PathName		DFCP_path
		optr			DFCP_display
		optr			DFCP_document
	} DocumentFileChangedParams
	typedef struct {
		word			NDC_attrs		/* GenDocumentAttrs */
		word			NDC_type		/* GenDocumentType */
		FileHandle 		NDC_fileHandle
		byte			NDC_emptyExists
		byte			NDC_defaultExists
	} NotifyDocumentChange

**Messages**

	void MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG()
	void MSG_GEN_DOCUMENT_CONTROL_INITIATE_NEW_DOC()
	void MSG_GEN_DOCUMENT_CONTROL_INITATE_USE_TEMPLATE_DOC()
	void MSG_GEN_DOCUMENT_CONTROL_INITIATE_OPEN_DOC()
	void MSG_GEN_DOCUMENT_CONTROL_INITIATE_IMPORT_DOC()
	void MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_DOC()
	void MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC()
	void MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_TEMPLATE_DOC()
	void MSG_GEN_DOCUMENT_CONTROL_INITIATE_COPY_TO_DOC()
	void MSG_GEN_DOCUMENT_CONTROL_INITIATE_EXPORT_DOC()
	void MSG_GEN_DOCUMENT_CONTROL_INITIATE_SET_TYPE_DOC()
	void MSG_GEN_DOCUMENT_CONTROL_INITIATE_SET_PASSWORD_DOC()
	GenDocumentControlAttrs
		MSG_GEN_DOCUMENT_CONTROL_GET_ATTRS()
	GenDocumentControlFeatures
		MSG_GEN_DOCUMENT_CONTROL_GET_FEATURES()
	void MSG_GEN_DOCUMENT_CONTROL_GET_TOKEN(
					GeodeToken *token)
	void MSG_GEN_DOCUMENT_CONTROL_GET_CREATOR(
					GeodeToken *token)
	void MSG_GEN_DOCUMENT_CONTROL_GET_TEMPLATE_DIR(
					char 	*buffer)
	void MSG_GEN_DOCUMENT_CONTROL_SAVE_AS_CANCELLED()
	void MSG_GEN_DOCUMENT_CONTROL_FILE_CHANGED(
				DocumentFileChangedParams dup)
	void MSG_GEN_DOCUMENT_CONTROL_CONFIGURE_FILE_SELECTOR(
				optr fileSelector, word flags)
	void MSG_GEN_DOCUMENT_CONTROL_OPEN_IMPORT_SELECTED(
				ImpexTranslationParams *params)
	void MSG_GEN_DOCUMENT_CONTROL_FILE_EXPORTED()
	void MSG_GEN_DOCUMENT_CONTROL_OPEN_DEFAULT_DOC()
	void MSG_GEN_DOCUMENT_CONTROL_IMPORT_CANCELLED()

## GenDocumentGroupClass

	@class GenDocumentGroupClass, GenClass

**Instance Data**

	GenDocumentGroupAttrs GDGI_attrs = (GDGA_VM_FILE |
				GDGA_SUPPORTS_AUTO_SAVE |
				GDGA_AUTOMATIC_CHANGE_NOTIFICATION |
				GDGA_AUTOMATIC_DIRTY_NOTIFICATION |
				GDGA_APPLICATION_THREAD |
				GDGA_AUTOMATIC_UNDO_INTERACTION |
			    GDGA_CONTENT_DOES_NOT_MANAGE_CHILDREN)
	ChunkHandle			GDGI_untitledName
	ClassStruct			* GDGI_documentClass =
						(ClassStruct *)&GenDocumentClass
	optr			GDGI_genDocument
	optr			GDGI_output
	optr			GDGI_documentControl
	optr			GDGI_genView
	optr			GDGI_genDisplay
	optr			GDGI_genDisplayGroup
	word			GDGI_protocolMajor = 1
	word			GDGI_protocolMinor = 0

**Types and Flags**

	WordFlags		GenDocumentGroupAttrs
		GDGA_VM_FILE							0x8000
		GDGA_NATIVE								0x4000
		GDGA_SUPPORTS_AUTO_SAVE					0x2000
		GDGA_AUTOMATIC_CHANGE_NOTIFICATION		0x1000
		GDGA_AUTOMATIC_DIRTY_NOTIFICATION		0x0800
		GDGA_APPLICATION_THREAD					0x0400
		GDGA_VM_FILE_CONTAINS_OBJECTS			0x0200
		GDGA_CONTENT_DOES_NOT_MANAGE_CHILDREN	0x0100
		GDGA_LARGE_CONTENT						0x0080
		GDGA_AUTOMATIC_UNDO_INTERACTION			0x0040
	typedef enum /* word */ {
		DQS_OK,
		DQS_CANCEL,
		DQS_DELAYED,
		DQS_SAVE_ERROR
	} DocQuitStatus

**Messages**

	optr MSG_GEN_DOCUMENT_GROUP_NEW_DOC(
				DocumentCommonParams *params)
	optr MSG_GEN_DOCUMENT_GROUP_IMPORT_NEW_DOC(
				ImpexTranslationParams *params)
	optr MSG_GEN_DOCUMENT_GROUP_OPEN_DOC(
				DocumentCommonParams *params)
	void MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY(optr document)
	void MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY_BY_FILE(
				FileHandle file)
	void MSG_GEN_DOCUMENT_GROUP_OPEN_DEFAULT_DOC(
				DocumentCommonParams *params)
	GenDocumentGroupAttrs
		MSG_GEN_DOCUMENT_GROUP_GET_ATTRS()
	GenDocumentControlAttrs
		MSG_GEN_DOCUMENT_GROUP_GET_UI_ATTRS()
	void MSG_GEN_DOCUMENT_GROUP_GET_TEMPLATE_DIR(
				char *buffer)
	GenDocumentControlFeatures
		MSG_GEN_DOCUMENT_GROUP_GET_UI_FEATURES()
	word MSG_GEN_DOCUMENT_GROUP_GET_DEFAULT_NAME(
				char *buffer)
	optr MSG_GEN_DOCUMENT_GROUP_GET_OUTPUT()
	void MSG_GEN_DOCUMENT_GROUP_SET_OUTPUT(optr output)
	void MSG_GEN_DOCUMENT_GROUP_GET_TOKEN(GeodeToken *token)
	void MSG_GEN_DOCUMENT_GROUP_GET_CREATOR(
				GeodeToken *token)
	dword MSG_GEN_DOCUMENT_GROUP_GET_PROTOCOL()
	optr MSG_GEN_DOCUMENT_GROUP_GET_VIEW()
	optr MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY()
	optr MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY_GROUP()
	optr MSG_GEN_DOCUMENT_GROUP_GET_DOC_BY_FILE(
				FileHandle file)
	void MSG_GEN_DOCUMENT_GROUP_SAVE_AS_CANCELLED()
	Boolean MSG_GEN_DOCUMENT_GROUP_SEARCH_FOR_DOC(
				DocumentCommonParams *params)

## GenDynamicListClass

	@class GenDynamicListClass, GenItemGroupClass

**Instance Data**

	word		GDLI_numItems = 0
	word		GDLI_queryMsg = 0

**Types and Flags**

	typedef WordFlags ReplaceItemMonikerFlags;
	RIMF_NOT_ENABLED		0x8000
	GDLI_NO_CHANGE			0xffff
	GDLP_FIRST				0x0000
	GDLP_LAST				0xffff

**Messages**

		@prototype void GEN_DYNAMIC_LIST_QUERY_MSG(
					optr list, word item)
	void MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER(@stack
				word item, 
				ReplaceItemMonikerFlags flags,
				word height, word width,
				word length,
				VisMonikerDataType dataType,
				VisMonikerSourceType sourceType,
				dword source)
	void MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR(
				word item, optr moniker)
	void MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT(
				word item, char *text)
	void MSG_GEN_DYNAMIC_LIST_INITIALIZE(word numItems)
	void MSG_GEN_DYNAMIC_LIST_INITIALIZE(word numItems)
	word MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS()
	void MSG_GEN_DYNAMIC_LIST_ADD_ITEMS(
				word item, word numItems)
	void MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS(
				word item, word numItems)
	void MSG_GEN_DYNAMIC_LIST_REMOVE_ITEM_LIST(
				word *deletionList, word numItems)

## GenEditControlClass

	@class GenEditControlClass, GenControlClass

**Instance Data**

		@default		GCI_output = (TO_APP_TARGET)
		@default		GI_states = (@default | GS_ENABLED)
		@default		GI_attrs = (@default | GA_KBD_SEARCH_PATH)

**Variable Data**

	NotifyUndoStateChange TEMP_UNDO_DESCRIPTION
	word TEMP_CLIPBOARD_NOTIFICATION_LIST_COUNT

**Types and Flags**

	WordFlags		GECFeatures
		GECF_UNDO					0x0020
		GECF_CUT					0x0010
		GECF_COPY					0x0008
		GECF_PASTE					0x0004
		GECF_SELECT_ALL				0x0002
		GECF_DELETE 				0x0001
	WordFlags		GECToolboxFeatures
		GECTF_UNDO					0x0020
		GECTF_CUT					0x0010
		GECTF_COPY					0x0008
		GECTF_PASTE					0x0004
		GECTF_SELECT_ALL			0x0002
		GECTF_DELETE				0x0001
	GEC_DEFAULT_FEATURES		(GECF_UNDO | GECF_CUT |
				GECF_COPY | GECF_PASTE |GECF_SELECT_ALL |
				GECF_DELETE)
	GEC_DEFAULT_TOOLBOX_FEATURES (GECTF_UNDO | GECTF_CUT |
				GECTF_COPY | GECTF_PASTE | GECTF_SELECT_ALL
				| GECTF_DELETE)
	typedef enum {
		SDT_TEXT,
		SDT_GRAPHICS,
		SDT_SPREADHSEET,
		SDT_INK,
		SDT_OTHER
	} SelectionDataType
	ByteEnum		UndoDescription
		UD_UNDO				0
		UD_REDO				1
		UD_NOT_UNDOABLE		2

**Structures**

	typedef struct {
		SelectionDataType 		NSSC_selectionType
		byte					NSSC_clipboardableSelection
		byte					NSSC_selectAllAvailable
		byte					NSSC_deleteableSelection
		byte					NSSC_pasteable
	} NotifySelectStateChange
	typedef struct {
		optr					NUSC_undoTitle
		UndoDescription			NUSC_undoType
	} NotifyUndoStateChange

## GenFieldClass

	@class GenFieldClass, GenClass

**Instance Data**

	/* instance data is internal and should not be used */
	GenFieldFlags		GFI_flags = 0
	optr				GFI_visParent = 0
	byte				GFI_numDetachedApps = 0
	byte				GFI_numRestartedApps = 0
	byte				GFI_numAttachingApps = 0
	ChunkHandle			GFI_apps = 0
	ChunkHandle			GFI_processes = 0
	ChunkHandle			GFI_genApplications = 0
	byte				GFI_numAppsToCheck = 0
	optr				GFI_notificationDestination = 0

**Messages**

	void MSG_GEN_FIELD_ADD_GEN_APPLICATION(
				optr genApp,CompChildFlags flags)
	void MSG_GEN_FIELD_ADD_APP_INSTANCE_REFERENCE(
				Handle appInstanceReference,
				Handle appObjectBlock)
	void MSG_GEN_FIELD_ADD_APP_INSTANCE_REFERENCE_HOLDER(
				Handle appObjectBlock)
	void MSG_GEN_FIELD_RESET_BG()
	void MSG_GEN_FIELD_ENABLE_BITMAP()
	void MSG_GEN_FIELD_EXIT_TO_DOS()
	void MSG_GEN_FIELD_OPEN_WINDOW_LIST()
	optr MSG_GEN_FIELD_GET_TOP_GEN_APPLICATION()
	UILaunchModel MSG_GEN_FIELD_GET_LAUNCH_MODEL()

## GenFileSelectorClass

	@class GenFileSelectorClass, GenClass

**Instance Data**

	GenFileSelectorSelection		GFSI_selection = {0}
	FileSelectorFileCriteria		GFSI_fileCriteria =
				(FSFC_DIRS|FSFC_NON_GEOS_FILES |
				 FSFC_GEOS_EXECUTABLES |
				 FSFC_GEOS_NON_EXECUTABLES)
	FileSelectorAttrs				GFSI_attrs =
				(FSA_ALLOW_CHANGE_DIRS |
				 FSA_HAS_CLOSE_DIR_BUTTON |
				 FSA_HAS_OPEN_DIR_BUTTON |
				 FSA_HAS_DOCUMENT_BUTTON |
				 FSA_HAS_CHANGE_DIRECTORY_LIST |
				 FSA_HAS_CHANGE_DRIVE_LIST|
				 FSA_HAS_FILE_LIST)
	optr				GFSI_destination
	Message				GFSI_notificationMsg

**Variable Data**

	void TEMP_GEN_FILE_SELECTOR_DATA
	GeodeToken ATTR_GEN_FILE_SELECTOR_TOKEN_MATCH
	GeodeToken ATTR_GEN_FILE_SELECTOR_CREATOR_MATCH
	GenFileSelectorFileAttrs
			ATTR_GEN_FILE_SELECTOR_FILE_ATTR
	GenFileSelectorGeodeAttrs
			ATTR_GEN_FILE_SELECTOR_GEODE_ATTR
	GenFileSelectorMask ATTR_GEN_FILE_SELECTOR_NAME_MASK
	GenFilePath ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT

**Hints**

	word	HINT_FILE_SELECTOR_NUMBER_OF_FILES_TO_SHOW

Types and Flags

	WordFlags		FileSelectorFileCriteria
		FSFC_DIRS							0x8000
		FSFC_NON_GEOS_FILES					0x4000
		FSFC_GEOS_EXECUTABLES				0x2000
		FSFC_GEOS_NON_EXECUTABLES			0x1000
		FSFC_MASK_CASE_INSENSITIVE 			0x0800
		FSFC_FILE_FILTER					0x0400
		FSFC_FILTER_IS_C					0x0200
		FSFC_TOKEN_NO_ID					0x0100
		FSFC_USE_MASK_FOR_DIRS				0x0080
	WordFlags		FileSelectorAttrs
		FSA_ALLOW_CHANGE_DIRS				0x8000
		FSA_SHOW_FIXED_DISKS_ONLY			0x2000
		FSA_SHOW_FILES_DISABLED				0x1000
		FSA_HAS_CLOSE_DIR_BUTTON			0x0800
		FSA_HAS_OPEN_DIR_BUTTON				0x0400
		FSA_HAS_DOCUMENT_BUTTON				0x0200
		FSA_HAS_CHANGE_DIRECTORY_LIST		0x0100
		FSA_HAS_CHANGE_DRIVE_LIST			0x0080
		FSA_HAS_FILE_LIST					0x0040
		FSA_USE_VIRTUAL_ROOT				0x0020
	ByteEnum		GenFileSelectorEntryType
		GFSET_FILE				0
		GFSET_SUBDIR			1
		GFSET_VOLUME			2
	WordFlags			GenFileSelectorEntryFlags
		GFSEF_TYPE					0xc000
		GFSEF_OPEN					0x2000
		GFSEF_NO_ENTRIES			0x1000
		GFSEF_ERROR					0x0800
		GFSEF_TEMPLATE				0x0400
		GFSEF_SHARED_MULTIPLE		0x0200
		GFSEF_SHARED_SINGLE			0x0100
		GFSEF_READ_ONLY				0x0080
		GFSEF_PARENT_DIR			0x0040
	GFSEF_TYPE_OFFSET				14
	FileLongName			GenFileSelectorMask
	VolumeName				GenFileSelectorVolume
	FileLongName			GenFileSelectorSelection
	ByteEnum		GenFileSelectorScalableUICommand
		GFSSUIC_SET_FEATURES_IF_APP_FEATURE_ON		0
		GFSSUIC_SET_FEATURES_IF_APP_FEATURE_OFF		1
		GFSSUIC_ADD_FEATURES_IF_APP_FEATURE_ON		2
		GFSSUIC_SET_FEATURES_IF_APP_LEVEL			3
		GFSSUIC_ADD_FEATURES_IF_APP_LEVEL			4

**Structures**

	typedef struct {
		GeodeToken			GTP_token
		word				GTP_unused
	} GetTokenCreatorParams
	typedef struct {
		Message				GAP_message
		word				GAP_unused
		optr				GAP_output
	} GetActionParams
	typedef struct {
		GenFileSelectorFilterRoutine	*filterRoutine
		const FileExtAttrDesc			*filterAttrs
	} GenFileSelectorGetFilterRoutineResults
	typedef struct {
		FileAttrs			GFSFA_match
		FileAttrs			GFSFA_mismatch
	} GenFileSelectorFileAttrs
	typedef struct {
		GeodeAttrs			GFSGA_match
		GeodeAttrs			GFSGA_mismatch
	} GenFileSelectorGeodeAttrs
	typedef struct {
		GenFileSelectorScalableUICommand GFSSUIE_command
		WordFlags					GFSSUIE_appFeature
		FileSelectorAttrs			GFSSUIE_fsFeatures
	} GenFileSelectorScalableUIEntry

**Macros**

	GFS_GET_ENTRY_TYPE(A) (((A) & GFSEF_TYPE) >>
						GFSEF_TYPE_OFFSET)
	GFS_GET_ENTRY_NUMBER(A) ((word) (A >> 16))
	GFS_GET_ENTRY_FLAGS(A) ((word) A)
	GFS_GET_FULL_SELECTION_PATH_DISK_HANDLE(A)
						((DiskHandle) (A))
	GET_MATCH_FILE_ATTRS(attr) ((byte) (attr))
	GET_MISMATCH_FILE_ATTRS(attr) ((byte) (attr >> 8))
	SET_TOKEN_CHARS(A, B, C, D) ((A) | ((B) << 8) | 
					((C) << 16) | ((D) << 24))
	GET_MATCH_ATTRS(attr) (((attr) >> 16) & 0xffff)
	GET_MISMATCH_ATTRS(attr) ((attr) & 0xffff)

**Messages**

	dword MSG_GEN_FILE_SELECTOR_GET_SELECTION(
				char *selection)
	Boolean MSG_GEN_FILE_SELECTOR_SET_SELECTION(
				char *selection)
	dword MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH(
				char *selection)
	Boolean MSG_GEN_FILE_SELECTOR_SET_FULL_SELECTION_PATH(
				char *selection,
				DiskHandle diskHandle)
	void MSG_GEN_FILE_SELECTOR_GET_MASK(char *mask)
	void MSG_GEN_FILE_SELECTOR_SET_MASK(char *mask)
	word MSG_GEN_FILE_SELECTOR_GET_FILE_ATTRS()
	void MSG_GEN_FILE_SELECTOR_SET_FILE_ATTRS(
				byte setAttrs,
				byte clearAttrs)
	void MSG_GEN_FILE_SELECTOR_GET_TOKEN(
				GetTokenCreatorParams *retValue)
	void MSG_GEN_FILE_SELECTOR_SET_TOKEN(
				dword tokenChars
				ManufacturerID manufacturerID)
	void MSG_GEN_FILE_SELECTOR_GET_CREATOR(
				GetTokenCreatorParams *retValue)
	void MSG_GEN_FILE_SELECTOR_SET_CREATOR(
				dword tokenChars,
				ManufacturerID manufacturerID)
	dword MSG_GEN_FILE_SELECTOR_GET_GEODE_ATTRS()
	void MSG_GEN_FILE_SELECTOR_SET_GEODE_ATTRS(
				word matchGeodeAttrs,
				word mismatchGeodeAttrs)
	void MSG_GEN_FILE_SELECTOR_GET_ACTION(
				GetActionParams *retValue)
	void MSG_GEN_FILE_SELECTOR_SET_ACTION(
				optr actionOD,
				word actionMessage)
	FileSelectorAttrs MSG_GEN_FILE_SELECTOR_GET_ATTRS()
	void MSG_GEN_FILE_SELECTOR_SET_ATTRS(
				FileSelectorAttrs attributes)
	FileSelectorFileCriteria
		MSG_GEN_FILE_SELECTOR_GET_FILE_CRITERIA()
	void MSG_GEN_FILE_SELECTOR_SET_FILE_CRITERIA(
			FileSelectorFileCriteria fileCriteria)
	void MSG_GEN_FILE_SELECTOR_RESCAN()
	void MSG_GEN_FILE_SELECTOR_UP_DIRECTORY()
	Boolean MSG_GEN_FILE_SELECTOR_OPEN_ENTRY(
				word entryNumber)
	Boolean MSG_GEN_FILE_SELECTOR_SUSPEND()
	Boolean MSG_GEN_FILE_SELECTOR_END_SUSPEND()
	Boolean MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH(
				char *buffer, word bufSize)
	void MSG_GEN_FILE_SELECTOR_GET_FILTER_ROUTINE(
		GenFileSelectorGetFilterRoutineResults *filter)
	@prototype void GEN_FILE_SELECTOR_NOTIFICATION_MSG(
					word entryNum,
					word entryFlags)

**Routines**

	Boolean GenFileSelectorFilterRoutine (
							optr oself,
							FileEnumCallbackData *fecd,
							word frame)

## GenGlyphClass

	@class GenGlyphClass, GenClass

## GenInteractionClass

	@class GenInteractionClass, GenClass

**Instance Data**

	GenInteractionType			GII_type = GIT_ORGANIZATIONAL
	GenInteractionVisibility	GII_visibility = GIV_SUB_GROUP
	GenInteractionAttrs			GII_attrs = 0

**Variable Data**

	GenInteractionGroupType ATTR_GEN_INTERACTION_GROUP_TYPE
	void ATTR_GEN_INTERACTION_OVERRIDE_INPUT_RESTRICTIONS
	void ATTR_GEN_INTERACTION_ABIDE_BY_INPUT_RESTRICTIONS
	void ATTR_GEN_INTERACTION_POPPED_OUT
	void ATTR_GEN_INTERACTION_POPOUT_NOT_CLOSABLE
	optr ATTR_GEN_INTERACTION_PEN_MODE_KEYBOARD_OBJECT

**Hints**

	void HINT_INTERACTION_SINGLE_USAGE
	void HINT_INTERACTION_FREQUENT_USAGE
	void HINT_INTERACTION_COMPLEX_PROPERTIES
	void HINT_INTERACTION_SIMPLE_PROPERTIES
	void HINT_INTERACTION_RELATED_PROPERTIES
	void HINT_INTERACTION_UNRELATED_PROPERTIES
	void HINT_INTERACTION_SLOW_RESPONSE_PROPERTIES
	void HINT_INTERACTION_FAST_RESPONSE_PROPERTIES
	void HINT_INTERACTION_REQUIRES_VALIDATION
	void HINT_INTERACTION_MAKE_RESIZABLE
	void HINT_INTERACTION_CANNOT_BE_DEFAULT
	void HINT_INTERACTION_MODAL
	void HINT_INTERACTION_NO_DISTURB
	void HINT_INTERACTION_DEFAULT_ACTION_OS_NAVIGATE_TO_NEXT_FIELD
	void HINT_INTERACTION_INFREQUENT_USAGE
	void HINT_CUSTOM_SYS_MENU
	void HINT_INTERACTION_MAXIMIZABLE
	void HINT_INTERACTION_POPOUT_HIDDEN_ON_STARTUP

**Types and Flags**

	enum /* word */ {
		IC_NULL,
		IC_DISMISS,
		IC_INTERACTION_COMPLETE,
		IC_APPLY,
		IC_RESET,
		IC_OK,
		IC_YES,
		IC_NO,
		IC_STOP,
		IC_EXIT,
		IC_HELP
	} InteractionCommand
	IC_CUSTOM_START			1000
	ByteEnum		GenInteractionType
		GIT_ORGANIZATIONAL			0
		GIT_PROPERTIES				1
		GIT_PROGRESS				2
		GIT_COMMAND					3
		GIT_NOTIFICATION			4
		GIT_AFFIRMATION				5
		GIT_MULTIPLE_RESPONSE		6
	ByteEnum		GenInteractionVisibility
		GIV_NO_PREFERENCE			0
		GIV_POPUP					1
		GIV_SUB_GROUP				2
		GIV_CONTROL_GROUP			3
		GIV_DIALOG					4
		GIV_POPOUT					5
	ByteFlags		GenInteractionAttrs
		GIA_NOT_USER_INITIATABLE			0x80
		GIA_INITIATED_VIA_USER_DO_DIALOG	0x40
		GIA_MODAL							0x20
		GIA_SYS_MODAL						0x10
	ByteEnum		GenInteractionGroupType
		GIGT_FILE_MENU				0
		GIGT_EDIT_MENU				1
		GIGT_VIEW_MENU				2
		GIGT_OPTIONS_MENU			3
		GIGT_WINDOW_MENU			4
		GIGT_HELP_MENU				5
		GIGT_PRINT_GROUP			6

**Structures**

	typedef struct {
		ThreadHandle				UDDS_callingThread
		SemaphoreHandle				UDDS_semaphore
		word						UDDS_response
		word						UDDS_complete
		Boolean 					UDDS_boxRunByCurrentThread
		optr						UDDS_dialog
		QueueHandle					UDDS_queue
	} UserDoDialogStruct

**Messages**

	byte MSG_GEN_INTERACTION_GET_TYPE()
	void MSG_GEN_INTERACTION_SET_TYPE(byte type)
	byte MSG_GEN_INTERACTION_GET_VISIBILITY()
	void MSG_GEN_INTERACTION_SET_VISIBILITY(byte visibility)
	byte MSG_GEN_INTERACTION_GET_ATTRS()
	void MSG_GEN_INTERACTION_SET_ATTRS(
				byte setAttrs, byte clearAttrs)
	void MSG_GEN_INTERACTION_ACTIVATE_COMMAND(word command)
	void MSG_GEN_INTERACTION_INITIATE()
	void MSG_GEN_INTERACTION_INITIATE_NO_DISTURB()
	void MSG_GEN_INTERACTION_INITIATE_BLOCKING_THREAD_ON_RESPONSE(
				UserDoDialogStruct *dialogInfo)
	void MSG_GEN_INTERACTION_RELEASE_BLOCKED_THREAD_WITH_RESPONSE(
				word *command)
	void MSG_GEN_INTERACTION_TEST_INPUT_RESTRICTABILITY()
					/* XXX */
	void MSG_GEN_INTERACTION_POP_OUT()
	void MSG_GEN_INTERACTION_POP_IN()
	void MSG_GEN_INTERACTION_TOGGLE_POPOUT()

## GenItemClass

	@class GenItemClass, GenClass

**Instance Data**

	word GII_identifier

**Messages**

	word MSG_GEN_ITEM_GET_IDENTIFIER()
	void MSG_GEN_ITEM_SET_IDENTIFIER(word identifier)
	void MSG_GEN_ITEM_SET_INTERACTABLE_STATE(
					Boolean interactable)

## GenItemGroupClass

	@class GenItemGroupClass, GenClass

**Instance Data**

	GenItemGroupBehaviorType	GIGI_behaviorType = GIGBT_EXCLUSIVE
	word						GIGI_selection = GIGS_NONE
	word						GIGI_numSelections = 0
	GenItemGroupStateFlags		GIGI_stateFlags = 0
	optr						GIGI_destination
	Message						GIGI_applyMsg = 0

**Variable Data**

	Message ATTR_GEN_ITEM_GROUP_STATUS_MSG
	void ATTR_GEN_ITEM_GROUP_SET_MODIFIED_ON_REDUNDANT_SELECTION
	Message ATTR_GEN_ITEM_GROUP_CUSTOM_DOUBLE_PRESS
	optr ATTR_GEN_ITEM_GROUP_LINK
		@reloc ATTR_GEN_ITEM_GROUP_LINK, 0, optr
	void ATTR_GEN_ITEM_GROUP_INIT_FILE_BOOLEAN

**Hints**

	void HINT_ITEM_GROUP_SCROLLABLE
	void HINT_ITEM_GROUP_MINIMIZE_SIZE
	void HINT_ITEM_GROUP_RADIO_BUTTON_STYLE
	void HINT_ITEM_GROUP_TOOLBOX_STYLE
	void HINT_ITEM_GROUP_DISPLAY_CURRENT_SELECTION
	void HINT_ITEM_GROUP_MINIMIZE_SIZE_IF_VERTICAL_SCREEN

**Types and Flags**

	ByteEnum		GenItemGroupBehaviorType
		GIGBT_EXCLUSIVE					0
		GIGBT_EXCLUSIVE_NONE			1
		GIGBT_EXTENDED_SELECTION		2
		GIGBT_NON_EXCLUSIVE				3
	GIGS_NONE			(-1)
	ByteFlags		GenItemGroupStateFlags
		GIGSF_INDETERMINATE				0x80
		GIGSF_MODIFIED					0x40

**Messages**

	void MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED(
					Boolean indeterminate)
	void MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION(
					word identifier,
					Boolean indeterminate)
	void MSG_GEN_ITEM_GROUP_SET_MULTIPLE_SELECTIONS(
					word *selectionList,
					word numSelections)
	word MSG_GEN_ITEM_GROUP_GET_SELECTION()
	word MSG_GEN_ITEM_GROUP_GET_NUM_SELECTIONS()
	word MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS(
					word *selectionList,
					word maxSelections)
	void MSG_GEN_ITEM_GROUP_SET_INDETERMINATE_STATE(
					Boolean indeterminateState)
	Boolean MSG_GEN_ITEM_GROUP_IS_INDETERMINATE()
	void MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE(
					Boolean modifiedState)
	Boolean MSG_GEN_ITEM_GROUP_IS_MODIFIED()
	void MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG(
					Boolean modifiedState)
	optr MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR(word identifier)
	void MSG_GEN_ITEM_GROUP_SET_ITEM_STATE(
					word identifier,
					Boolean state)
	Boolean MSG_GEN_ITEM_GROUP_IS_ITEM_SELECTED(
					word identifier)
	void MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE(
					word identifier)
	optr MSG_GEN_ITEM_GROUP_GET_DESTINATION()
	void MSG_GEN_ITEM_GROUP_SET_DESTINATION(optr dest)
	Message MSG_GEN_ITEM_GROUP_GET_APPLY_MSG()
	void MSG_GEN_ITEM_GROUP_SET_APPLY_MSG(Message message)
	GenItemGroupBehaviorType
					MSG_GEN_ITEM_GROUP_GET_BEHAVIOR_TYPE()
	void MSG_GEN_ITEM_GROUP_SET_BEHAVIOR_TYPE(
					GenItemGroupBehaviorType behaviorType)
	word MSG_GEN_ITEM_GROUP_GET_UNIQUE_IDENTIFIER()
	void MSG_GEN_ITEM_GROUP_REDRAW_ITEMS(word offset)
	@prototype void GEN_ITEM_GROUP_APPLY_MSG(
					word selection,
					word numSelections,
					byte stateFlags)
	@prototype void GEN_ITEM_GROUP_STATUS_MSG(
					word selection,
					word numSelections,
					byte stateFlags)

## GenPageControlClass

	@class GenPageControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	WordFlags		GPCFeatures
		GPCF_GOTO_PAGE				0x0004
		GPCF_NEXT_PAGE				0x0002
		GPCF_PREVIOUS_PAGE			0x0001
	WordFlags		GPCToolboxFeatures
		GPCTF_PREVIOUS_PAGE			0x0004
		GPCTF_GOTO_PAGE				0x0002
		GPCTF_NEXT_PAGE				0x0001
	GPC_DEFAULT_FEATURES		(GPCF_GOTO_PAGE |
								 GPCF_NEXT_PAGE |
								 GPCF_PREVIOUS_PAGE)
	GPC_DEFAULT_TOOLBOX_FEATURES (GPCTF_GOTO_PAGE |
								 GPCTF_NEXT_PAGE |
								 GPCTF_PREVIOUS_PAGE)

**Structures**

	typedef struct {
		word		NPSC_firstPage
		word		NPSC_lastPage
		word		NPSC_currentPage
	} NotifyPageStateChange

**Messages**

	void MSG_PC_GOTO_PAGE()
	void MSG_PC_NEXT_PAGE()
	void MSG_PC_PREVIOUS_PAGE()

## GenPenInputControlClass

	@class GenPenInputControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_FOCUS)

**Variable Data**

	CharTableData ATTR_GEN_PEN_INPUT_CONTROL_CUSTOM_CHAR_TABLE_DATA
	optr  ATTR_GEN_PEN_INPUT_CONTROL_CUSTOM_CHAR_TABLE_MONIKER
	PenInputDisplayType ATTR_GEN_PEN_INPUT_CONTROL_STARTUP_DISPLAY_TYPE

**Types and Flags**

	typedef enum { /* word */
		PIDT_KEYBOARD,
		PIDT_CHAR_TABLE,
		PIDT_CHAR_TABLE_SYMBOLS,
		PIDT_CHAR_TABLE_INTERNATIONAL,
		PIDT_CHAR_TABLE_MATH,
		PIDT_CHAR_TABLE_CUSTOM,
		PIDT_HWR_ENTRY_AREA
	} PenInputDisplayType
	WordFlags		GPICFeatures
		GPICF_KEYBOARD						0x0040
		GPICF_CHAR_TABLE					0x0020
		GPICF_CHAR_TABLE_SYMBOLS			0x0010
		GPICF_CHAR_TABLE_INTERNATIONAL		0x0008
		GPICF_CHAR_TABLE_MATH				0x0004
		GPICF_CHAR_TABLE_CUSTOM				0x0002
		GPICF_HWR_ENTRY_AREA				0x0001
	WordFlags		GPICToolboxFeatures
		GPICTF_INITIATE						0x0001
	GPIC_DEFAULT_FEATURES (GPICF_KEYBOARD | GPICF_CHAR_TABLE
		GPICF_HWR_ENTRY_AREA | GPICF_CHAR_TABLE_SYMBOLS |
		GPICF_CHAR_TABLE_MATH | 
		GPICF_CHAR_TABLE_INTERNATIONAL)
	GPIC_DEFAULT_TOOLBOX_FEATURES (GPICTF_INITIATE)

**Structures**

	typedef struct {
		optr		CTD_line1
		optr		CTD_line2
		optr		CTD_line3
		optr		CTD_line4
		optr		CTD_line5
	} CharTableData
	typedef struct {
		VisTextRange		RWHWRD_range
		HWRContext			RWHWRD_context
	} ReplaceWithHWRData

**Messages**

	void MSG_GEN_PEN_INPUT_CONTROL_SET_DISPLAY(
					PenInputDisplayType dispType)
	PenInputDisplayType MSG_GEN_PEN_INPUT_CONTROL_GET_DISPLAY()

## GenPrimaryClass

	@class GenPrimaryClass, GenDisplayClass

**Instance Data**

	ChunkHandle		GPI_longTermMoniker
		@default GI_attrs = @default | GA_TARGETABLE

**Hints**

	void HINT_PRIMARY_FULL_SCREEN
	void HINT_PRIMARY_NO_FILE_MENU
	void HINT_PRIMARY_NO_EXPRESS_MENU
	Rectangle HINT_PRIMARY_OPEN_ICON_BOUNDS
	void HINT_PRIMARY_NO_HELP_BUTTON

**Messages**

	ChunkHandle MSG_GEN_PRIMARY_GET_LONG_TERM_MONIKER()
	void MSG_GEN_PRIMARY_USE_LONG_TERM_MONIKER(
				ChunkHandle moniker)
	ChunkHandle MSG_GEN_PRIMARY_REPLACE_LONG_TERM_MONIKER(
				@stack
				VisUpdateMode updateMode,
				word height,
				word width,
				word length,
				VisMonikerDataType dateType,
				VisMonikerSourceType sourceType,
				dword source)

## GenProcessClass

	@class GenProcessClass, ProcessClass

**Types and Flags**

	WordFlags AppAttachFlags
		AAF_RESTORING_FROM_STATE			0x8000
		AAF_STATE_FILE_PASSED				0x4000
		AAF_DATA_FILE_PASSED				0x2000
	enum /* word */ {
		UADT_FLAGS =			0,
		UADT_PTR =				2,
		UADT_VM_CHAIN =			4
	} UndoActionDataType
	NULL_UNDO_CONTEXT			0
	WordFlags AddUndoActionFlags
		AUAF_NOTIFY_BEFORE_FREEING						0x8000
		AUAF_NOTIFY_IF_FREED_WITHOUT_BEING_PLAYED_BACK	0x4000
	ByteFlags AppLaunchFlags
		ALF_SEND_LAUNCH_REQUEST_TO_UI_TO_HANDLE 0x80
		ALF_OPEN_IN_BACK					0x40
		ALF_DESK_ACCESSORY					0x20
		ALF_DO_NOT_OPEN_ON_TOP				0x10
		ALF_OVERRIDE_MULTIPLE_INSTANCE		0x08
		ALF_LAUNCHED_FOR_PRINTING_ONLY		0x04

**Structures**

	typedef struct {
		dword					UADF_flags
		word					UADF_extraflags
	} UndoActionDataFlags
	typedef struct {
		void					*UADP_ptr
		word					UADP_size
	} UndoActionDataPtr
	typedef struct {
		VMChain					UADVMC_vmChain
		VMFileHandle			UADVMC_file
	} UndoActionDataVMChain
	typedef union {
		UndoActionDataFlags		UADU_flags
		UndoActionDataPtr		UADU_ptr
		UndoActionDataVMChain	UADU_vmChain
	} UndoActionDataUnion
	typedef struct {
		UndoActionDataType		UAS_dataType
		UndoActionDataUnion		UAS_data
		dword					UAS_appType
	} UndoActionStruct
	typedef struct {
		UndoActionStruct		AUAS_data
		optr					AUAS_output
		AddUndoActionFlags		AUAS_flags
	} AddUndoActionStruct
	typedef struct {
		PathName				AIR_fileName
		FileLongName			AIR_stateFile
		DiskHandle				AIR_diskHandle
		byte					AIR_savedDiskData[1]
	} AppInstanceReference
	typedef struct {
		AppInstanceReference	ALB_appRef
		word					ALB_appMode
		AppLaunchFlags			ALB_launchFlags
		MemHandle				ALB_diskHandle
		char					ALB_path[PATH_BUFFER_SIZE]
		char					ALB_dataFile[PATH_BUFFER_SIZE]
		optr					ALB_genParent
		optr					ALB_userLoadAckOutput
		Message					ALB_userLoadAckMessage
		word					ALB_userLoadAckID
		word					ALB_extraData
	} AppLaunchBlock

**Messages**

	void MSG_GEN_PROCESS_RESTORE_FROM_STATE(
				AppAttachFlags attachFlags,
				MemHandle launchBlock,
				MemHandle extraState)
	void MSG_GEN_PROCESS_OPEN_APPLICATION(
				AppAttachFlags attachFlags,
				MemHandle launchBlock,
				MemHandle extraState)
	void MSG_GEN_PROCESS_OPEN_ENGINE(
				AppAttachFlags attachFlags,
				MemHandle launchBlock,
				MemHandle extraState)
	MemHandle MSG_GEN_PROCESS_CLOSE_APPLICATION()
	MemHandle MSG_GEN_PROCESS_CLOSE_ENGINE()
	MemHandle MSG_GEN_PROCESS_CLOSE_CUSTOM()
	MemHandle MSG_GEN_PROCESS_ATTACH_TO_PASSED_STATE_FILE(
				AppAttachFlags attachFlags,
				MemHandle launchBlock)
	word MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE(
				MemHandle appInstanceReference)
	void MSG_GEN_PROCESS_INSTALL_TOKEN()
	optr MSG_GEN_PROCESS_GET_PARENT_FIELD()
	void MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST(@stack
				word sendFlags, EventHandle event,
				MemHandle block, word manufListType,
				word manufID)
	void MSG_GEN_PROCESS_UNDO_START_CHAIN(@stack
				optr title, optr owner)
	void MSG_GEN_PROCESS_UNDO_END_CHAIN(
				Boolean flushChainIfEmpty)
	VMChain MSG_GEN_PROCESS_UNDO_ADD_ACTION(
				AddUndoActionStruct *data)
	VMFileHandle MSG_GEN_PROCESS_UNDO_GET_FILE()
	void MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS()
	dword MSG_GEN_PROCESS_UNDO_SET_CONTEXT(dword context)
	dword MSG_GEN_PROCESS_UNDO_GET_CONTEXT()
	void MSG_GEN_PROCESS_UNDO_PLAYBACK_CHAIN()
	void MSG_GEN_PROCESS_UNDO_IGNORE_ACTIONS(
				Boolean flushActions)
	void MSG_GEN_PROCESS_UNDO_ACCEPT_ACTIONS()
	Boolean MSG_GEN_PROCESS_UNDO_CHECK_IF_IGNORING()
	void MSG_GEN_PROCESS_UNDO_ABORT_CHAIN()

## GenSystemClass

	@class GenSystemClass, GenClass

**Messages**

	optr MSG_GEN_SYSTEM_GET_DEFAULT_SCREEN()
	void MSG_GEN_SYSTEM_SET_DEFAULT_FIELD(optr defaultField)
	optr MSG_GEN_SYSTEM_GET_DEFAULT_FIELD()
	void MSG_GEN_SYSTEM_SET_PTR_IMAGE(
				optr ptrImage, PtrImageLevel level)
	void MSG_GEN_SYSTEM_NOTIFY_SYS_MODAL_WIN_CHANGE()
	void MSG_GEN_SYSTEM_BRING_GEODE_TO_TOP(
				word geode, word layerID,
				Handle parentWindow)
	void MSG_GEN_SYSTEM_LOWER_GEODE_TO_BOTTOM(
				word geode, word layerID,
				Handle parentWindow)

## GenTextClass

@class GenTextClass, GenClass

**Instance Data**

	ChunkHandle			GTXI_text
	word				GTXI_maxLength = 32767
	GenTextAttrs		GTXI_attrs = GTA_USE_TAB_FOR_NAVIGATION
	GenTextStateFlags	GTXI_stateFlags = 0
	optr				GTXI_destination
	word				GTXI_applyMsg = 0

**Variable Data**

	Message ATTR_GEN_TEXT_STATUS_MSG
	void ATTR_GEN_TEXT_SELECTABLE
	ColorQuad HINT_TEXT_WASH_COLOR
	void HINT_TEXT_WHITE_WASH_COLOR
	VisTextDefaultCharAttr ATTR_GEN_TEXT_DEFAULT_CHAR_ATTR
	VisTextDefaultParaAttr ATTR_GEN_TEXT_DEFAULT_PARA_ATTR
	ChunkHandle ATTR_GEN_TEXT_CHAR_ATTR
	ChunkHandle ATTR_GEN_TEXT_MULTIPLE_CHAR_ATTR_RUNS
	ChunkHandle ATTR_GEN_TEXT_PARA_ATTR
	ChunkHandle ATTR_GEN_TEXT_MULTIPLE_PARA_ATTR_RUNS
	void ATTR_GEN_TEXT_ALPHA
	void ATTR_GEN_TEXT_NUMERIC
	void ATTR_GEN_TEXT_SIGNED_NUMERIC
	void ATTR_GEN_TEXT_SIGNED_DECIMAL
	void ATTR_GEN_TEXT_FLOAT_DECIMAL
	void ATTR_GEN_TEXT_ALPHA_NUMERIC
	void ATTR_GEN_TEXT_LEGAL_FILENAMES
	void ATTR_GEN_TEXT_LEGAL_DOS_FILENAMES
	void ATTR_GEN_TEXT_LEGAL_DOS_PATH
	void ATTR_GEN_TEXT_DATE
	void ATTR_GEN_TEXT_TIME
	void ATTR_GEN_TEXT_MAKE_UPPERCASE
	void ATTR_GEN_TEXT_ALLOW_COLUMN_BREAKS
	void ATTR_GEN_TEXT_DASHED_ALPHA_NUMERIC
	void ATTR_GEN_TEXT_NORMAL_ASCII
	void ATTR_GEN_TEXT_LEGAL_DOS_VOLUME_NAMES
	void ATTR_GEN_TEXT_DOS_CHARACTER_SET
	void ATTR_GEN_TEXT_NO_SPACES
	void ATTR_GEN_TEXT_ALLOW_SPACES
	word ATTR_GEN_TEXT_EXTENDED_FILTER
	word ATTR_GEN_TEXT_TYPE_RUNS
	word ATTR_GEN_TEXT_GRAPHIC_RUNS
	word ATTR_GEN_TEXT_STYLE_ARRAY
	word ATTR_GEN_TEXT_NAME_ARRAY
	optr ATTR_GEN_TEXT_RUNS_ITEM_GROUP
		@reloc ATTR_GEN_TEXT_RUNS_ITEM_GROUP, 0, optr

**Hints**

	ColorQuad HINT_TEXT_WASH_COLOR
	void HINT_TEXT_WHITE_WASH_COLOR
	void HINT_TEXT_AUTO_HYPHENATE
	void HINT_TEXT_SELECT_TEXT
	void HINT_TEXT_CURSOR_AT_START
	void HINT_TEXT_CURSOR_AT_END
	void HINT_TEXT_FRAME
	void HINT_TEXT_NO_FRAME
	void HINT_TEXT_ALLOW_UNDO
	void HINT_TEXT_ALLOW_SMART_QUOTES
	void HINT_GEN_TEXT_DO_NOT_MAKE_LARGER_ON_PEN_SYSTEMS

**Types and Flags**

	ByteFlags		GenTextStateFlags
		GTSF_INDETERMINATE					0x80
		GTSF_MODIFIED						0x40
	ByteFlags		GenTextAttrs
		GTA_SINGLE_LINE_TEXT				0x80
		GTA_USE_TAB_FOR_NAVIGATION			0x40
		GTA_INIT_SCROLLING					0x20
		GTA_NO_WORD_WRAPPING				0x10
		GTA_ALLOW_TEXT_OFF_END				0x08
		GTA_TAIL_ORIENTED					0x04
		GTA_DONT_SCROLL_TO_CHANGES			0x02

**Messages**

	void MSG_GEN_TEXT_SET_ATTRS(
				byte attrsToSet, byte attrsToClear)
	byte MSG_GEN_TEXT_GET_ATTRS()
	void MSG_GEN_TEXT_SET_INDETERMINATE_STATE(
				Boolean indeterminateState)
	Boolean MSG_GEN_TEXT_IS_INDETERMINATE()
	void MSG_GEN_TEXT_SET_MODIFIED_STATE(
				Boolean modifiedState)
	Boolean MSG_GEN_TEXT_IS_MODIFIED()
	void MSG_GEN_TEXT_SEND_STATUS_MSG(
				Boolean modifiedState )
	optr MSG_GEN_TEXT_GET_DESTINATION()
	void MSG_GEN_TEXT_SET_DESTINATION(optr dest)
	Message MSG_GEN_TEXT_GET_APPLY_MSG()
	void MSG_GEN_TEXT_SET_APPLY_MSG(Message message)
	void MSG_GEN_TEXT_SET_FROM_ITEM_GROUP(word item)
	@prototype void GEN_TEXT_APPLY_MSG(word stateFlags)
	@prototype void GEN_TEXT_STATUS_MSG(word stateFlags)

## GenToolControlClass

	@class GenToolControlClass, GenControlClass

**Instance Data**

	ChunkHandle			GTCI_toolboxList
	ChunkHandle			GTCI_toolGroupList
		@default		GI_states = @default | GS_ENABLED

**Variable Data**

	TempGenToolControlInstance TEMP_GEN_TOOL_CONTROL_INSTANCE

**Types and Flags**

	WordFlags		GTCFeatures
		GTCF_TOOL_DIALOG			0x0001
	MAX_NUM_TOOLBOXES			25

**Structures**

	typedef struct {
		optr		TI_object
		optr		TI_name
	} ToolboxInfo
	typedef struct {
		optr		TGI_object
	} ToolGroupInfo
	typedef struct {
		optr		TGTCI_curController
		word		TGTCI_features
		word		TGTCI_required
		word		TGTCI_allowed
	} TempGenToolControlInstance

## GenToolGroup

	@class GenToolGroupClass, GenInteractionClass

**Instance Data**

	optr			GTGI_controller
		@default		GI_states = (@default & ~GS_ENABLED)

**Variable Data**

	Color TEMP_TOOL_GROUP_HIGHLIGHT

**Types and Flags**

	ByteEnum		ToolGroupHighlightType
		TGHT_INACTIVE_HIGHLIGHT				0
		TGHT_ACTIVE_HIGHLIGHT				1
		TGHT_NO_HIGHLIGHT					2

**Messages**

	void MSG_GEN_TOOL_GROUP_SET_HIGHLIGHT(
				ToolGroupHighlightType hlType)

## GenTriggerClass
	@class GenTriggerClass, GenClass

**Instance Data**

	optr		GTI_destination
	Message		GTI_actionMsg

**Variable Data**

	void ATTR_GEN_TRIGGER_IMMEDIATE_ACTION
	word ATTR_GEN_TRIGGER_ACTION_DATA
	word ATTR_GEN_TRIGGER_INTERACTION_COMMAND
	Message ATTR_GEN_TRIGGER_CUSTOM_DOUBLE_PRESS
		@vardataAlias (ATTR_GEN_TRIGGER_ACTION_DATA)
			TwoWordArgs
			ATTR_GEN_TRIGGER_ACTION_TWO_WORDS
		@vardataAlias (ATTR_GEN_TRIGGER_ACTION_DATA)
			ThreeWordArgs
			ATTR_GEN_TRIGGER_ACTION_THREE_WORDS
		@vardataAlias (ATTR_GEN_TRIGGER_ACTION_DATA)
			OptrWordArgs
			ATTR_GEN_TRIGGER_ACTION_OPTR_AND_WORD

**Hints**

	void HINT_TRIGGER_BRINGS_UP_WINDOW
	void HINT_TRIGGER_DESTRUCTIVE_ACTION

**Structures**

	typedef struct { word foo, foo2 } TwoWordArgs
	typedef struct { word foo, foo2, foo3 } ThreeWordArgs
	typedef struct { optr output; word foo } OptrWordArgs

**Messages**

	void MSG_GEN_TRIGGER_SEND_ACTION(
				Boolean doublePressFlag)
	Message MSG_GEN_TRIGGER_GET_ACTION_MSG()
	void MSG_GEN_TRIGGER_SET_ACTION_MSG(Message message)
	void MSG_GEN_TRIGGER_SET_DESTINATION(optr dest)
	optr MSG_GEN_TRIGGER_GET_DESTINATION()
	void MSG_GEN_TRIGGER_MAKE_DEFAULT_ACTION()
		@prototype void GEN_TRIGGER_ACTION(optr trigger)

[1 GOC Keywords](qr_kword.md) <-- [Table of Contents](../quickref.md) &nbsp;&nbsp; --> [3 Classes: GenValue - ZoomPointer](qr_clas2.md)
