# 3 Classes: GenValue - ZoomPointer
## GenValueClass

	@class GenValueClass, GenClass

**Instance Data**

	WWFixedAsDWord			GVLI_value = MakeWWFixed(0.0)
	WWFixedAsDWord			GVLI_minimum = MakeWWFixed(0.0)
	WWFixedAsDWord			GVLI_maximum = MakeWWFixed(32766)
	WWFixedAsDWord			GVLI_increment = MakeWWFixed(1.0)
	GenValueStateFlags		GVLI_stateFlags = 0
	GenValueDisplayFormat	GVLI_displayFormat = GVDF_INTEGER
	optr					GVLI_destination
	Message					GVLI_applyMsg = 0

**Variable Data**

	Message ATTR_GEN_VALUE_STATUS_MSG
	word ATTR_GEN_VALUE_DECIMAL_PLACES
	WWFixed ATTR_GEN_VALUE_METRIC_INCREMENT
	optr ATTR_GEN_VALUE_RUNS_ITEM_GROUP
		@reloc ATTR_GEN_VALUE_RUNS_ITEM_GROUP, 0, optr
	void ATTR_GEN_VALUE_SET_MODIFIED_ON_REDUNDANT_SELECTION

**Hints**

	void HINT_VALUE_NAVIGATE_TO_NEXT_FIELD_ON_RETURN_PRESS
	void HINT_VALUE_CUSTOM_RETURN_PRESS
	void HINT_VALUE_INCREMENTABLE
	void HINT_VALUE_NOT_INCREMENTABLE
	void HINT_VALUE_X_SCROLLER
	void HINT_VALUE_Y_SCROLLER
	WWFixedAsDWord HINT_VALUE_DISPLAYS_RANGE
	void HINT_VALUE_ANALOG_DISPLAY
	GenValueIntervals HINT_VALUE_DISPLAY_INTERVALS
	void HINT_VALUE_CONSTRAIN_TO_INTERVALS
	void HINT_VALUE_SHOW_MIN_AND_MAX
	void HINT_VALUE_IMMEDIATE_DRAG_NOTIFICATION
	void HINT_VALUE_DELAYED_DRAG_NOTIFICATION
	void HINT_VALUE_ORIENT_HORIZONTALLY
	void HINT_VALUE_ORIENT_VERTICALLY
	void HINT_VALUE_DIGITAL_DISPLAY
	void HINT_VALUE_NO_DIGITAL_DISPLAY
	void HINT_VALUE_NO_ANALOG_DISPLAY
	void HINT_VALUE_NOT_DIGITALLY_EDITABLE
	void HINT_VALUE_DO_NOT_MAKE_LARGER_ON_PEN_SYSTEMS

**Types and Flags**

	ByteEnum		GenValueDisplayFormat
		GVDF_INTEGER				0
		GVDF_DECIMAL				1
		GVDF_POINTS					2
		GVDF_INCHES					3
		GVDF_CENTIMETERS			4
		GVDF_MILLIMETERS			5
		GVDF_PICAS					6
		GVDF_EUR_POINTS				7
		GVDF_CICEROS				8
		GVDF_POINTS_OR_MILLIMETERS	9
		GVDF_INCHES_OR_CENTIMETERS	10
	typedef enum /* word */ {
		GVT_VALUE,
		GVT_MINIMUM,
		GVT_MAXIMUM,
		GVT_INCREMENT,
		GVT_LONG,
		GVT_RANGE_LENGTH,
		GVT_RANGE_END,
		GVI_VALUE_AS_RATIO_OF_AVAILABLE_RANGE
	} GenValueType
	GEN_VALUE_MAX_TEXT_LEN			30
	ByteFlags		GenValueStateFlags
		GVSF_INDETERMINATE					0x80
		GVSF_MODIFIED						0x40
		GVSF_OUT_OF_DATE					0x20

**Structures**

	typedef struct {
		word		GVI_numMajorIntervals
		word		GVI_numMinorIntervals
	} GenValueIntervals

**Messages**

	void MSG_GEN_VALUE_SET_VALUE(
				WWFixedAsDWord value,
				Boolean indeterminate)
	void MSG_GEN_VALUE_SET_INTEGER_VALUE(
				word value, Boolean indeterminate)
	WWFixedAsDWord MSG_GEN_VALUE_GET_VALUE()
	@alias (MSG_GEN_VALUE_GET_VALUE) word
			MSG_GEN_VALUE_GET_INTEGER_VALUE()
	void MSG_GEN_VALUE_SET_MINIMUM(WWFixedAsDWord value)
	WWFixedAsDWord MSG_GEN_VALUE_GET_MINIMUM()
	void MSG_GEN_VALUE_SET_MAXIMUM(WWFixedAsDWord value)
	WWFixedAsDWord MSG_GEN_VALUE_GET_MAXIMUM()
	void MSG_GEN_VALUE_SET_INCREMENT(WWFixedAsDWord value)
	WWFixedAsDWord MSG_GEN_VALUE_GET_INCREMENT()
	void MSG_GEN_VALUE_SET_INDETERMINATE_STATE(
				Boolean indeterminateState)
	Boolean MSG_GEN_VALUE_IS_INDETERMINATE()
	void MSG_GEN_VALUE_SET_MODIFIED_STATE(
				Boolean modifiedState)
	Boolean MSG_GEN_VALUE_IS_MODIFIED()
	void MSG_GEN_VALUE_SET_DISPLAY_FORMAT(
				GenValueDisplayFormat format)
	GenValueDislayFormat MSG_GEN_VALUE_GET_DISPLAY_FORMAT()
	void MSG_GEN_VALUE_SEND_STATUS_MSG(
				Boolean modifiedState) 
	optr MSG_GEN_VALUE_GET_DESTINATION()
	void MSG_GEN_VALUE_SET_DESTINATION(optr dest)
	Message MSG_GEN_VALUE_GET_APPLY_MSG()
	void MSG_GEN_VALUE_SET_APPLY_MSG(Message message)
	void MSG_GEN_VALUE_SET_RANGE_LENGTH(
				WWFixedAsDWord value)
	WWFixedAsDWord MSG_GEN_VALUE_GET_RANGE_LENGTH()
	void MSG_GEN_VALUE_ADD_RANGE_LENGTH()
	void MSG_GEN_VALUE_SUBTRACT_RANGE_LENGTH()
	void MSG_GEN_VALUE_GET_VALUE_TEXT(
				char *buffer,
				GenValueType valueType)
	void MSG_GEN_VALUE_SET_VALUE_FROM_TEXT(
				char *text, GenValueType valueType)
	WWFixedAsDWord MSG_GEN_VALUE_GET_VALUE_RATIO(
				GenValueType valueType)
	void MSG_GEN_VALUE_SET_VALUE_FROM_RATIO(
				WWFixed ratio,
				GenValueType valueType)
	void MSG_GEN_VALUE_INCREMENT()
	void MSG_GEN_VALUE_DECREMENT()
	void MSG_GEN_VALUE_SET_VALUE_TO_MINIMUM()
	void MSG_GEN_VALUE_SET_VALUE_TO_MAXIMUM()
	VisTextFilters MSG_GEN_VALUE_GET_TEXT_FILTER()
	byte MSG_GEN_VALUE_GET_MAX_TEXT_LEN()
	void MSG_GEN_VALUE_SET_OUT_OF_DATE()
		@prototype void GEN_VALUE_APPLY_MSG(
			WWFixedAsDWord value, word stateFlags)
		@prototype void GEN_VALUE_STATUS_MSG(
			WWFixedAsDWord value, word stateFlags)

## GenViewClass

@class GenViewClass, GenClass

**Instance Data**

	PointDWFixed 	GVI_origin = { {0, 0}, {0, 0} }
	RectDWord		GVI_docBounds = {0, 0, 0, 0}
	PointDWord		GVI_increment = {20, 15}
	PointWWFixed 	GVI_scaleFactor = { {0, 1}, {0, 1} }
	ColorQuad		GVI_color = {C_WHITE, 0, 0, 0}
	GenViewAttrs	GVI_attrs = (GVA_FOCUSABLE)
	GenViewDimensionAttrs GVI_horizAttrs = 0
	GenViewDimensionAttrs GVI_vertAttrs = 0
	GenViewInkType GVI_inkType = GVIT_PRESSES_ARE_NOT_INK
	optr			GVI_content
	optr			GVI_horizLink
	optr			GVI_vertLink
		@default GI_attrs = @default | GA_TARGETABLE

**Variable Data**

	InkDestinationInfoParams
					ATTR_GEN_VIEW_INK_DESTINATION_INFO
	XYSize ATTR_GEN_VIEW_PAGE_SIZE
	void ATTR_GEN_VIEW_SCALE_TO_FIT_BASED_ON_X
	void ATTR_GEN_VIEW_SCALE_TO_FIT_BOTH_DIMENSIONS
	void ATTR_GEN_VIEW_DO_NOT_WIN_SCROLL

**Hints**

	void HINT_VIEW_LEAVE_ROOM_FOR_VERT_SCROLLER
	void HINT_VIEW_LEAVE_ROOM_FOR_HORIZ_SCROLLER
	void HINT_VIEW_IMMEDIATE_DRAG_UPDATES
	void HINT_VIEW_DELAYED_DRAG_UPDATES
	void HINT_VIEW_REMOVE_SCROLLERS_WHEN_NOT_SCROLLABLE
	void HINT_VIEW_SHOW_SCROLLERS_WHEN_NOT_SCROLLABLE
	optr HINT_VIEW_SHARES_SPACE_WITH_VIEW_ABOVE
	optr HINT_VIEW_SHARES_SPACE_WITH_VIEW_BELOW
	optr HINT_VIEW_SHARES_SPACE_WITH_VIEW_TO_LEFT
	optr HINT_VIEW_SHARES_SPACE_WITH_VIEW_TO_RIGHT

**Types and Flags**

	WordFlags		MakeRectVisibleFlags
		MRVF_ALWAYS_SCROLL						0x0080
		MRVF_USE_MARGIN_FROM_TOP_LEFT			0x0040
	MRVM_0_PERCENT				0
	MRVM_25_PERCENT				0xffff/4
	MRVM_50_PERCENT				0xffff/2
	MRVM_75_PERCENT				0xffff*3/4
	MRVM_100_PERCENT			0xffff
	ByteEnum		ScaleViewType
		SVT_AROUND_UPPER_LEFT			0
		SVT_AROUND_CENTER				1
		SVT_AROUND_POINT				2
	ByteEnum		ScrollAction
		SA_NOTHING						0
		SA_TO_BEGINNING					1
		SA_PAGE_BACK					2
		SA_INC_BACK						3
		SA_INC_FWD						4
		SA_DRAGGING						5
		SA_PAGE_FWD						6
		SA_TO_END						7
		SA_SCROLL						8
		SA_SCROLL_INTO					9
		SA_INITIAL_POS					10
		SA_SCALE						11
		SA_PAN							12
		SA_DRAG_SCROLL					13
		SA_SCROLL_FOR_SIZE_CHANGE		14
	ByteFlags		ScrollFlags
		SF_VERTICAL						0x80
		SF_ABSOLUTE						0x40
		SF_DOC_SIZE_CHANGE				0x20
		SF_WINDOW_NOT_SUSPENDED			0x10
		SF_SCALE_TO_FIT					0x08
		SF_SETUP_HAPPENED				0x04
	VS_TYPICAL			0x8000
	VS_SMALL			0x8001
	VS_LARGE			0x8002
	ByteEnum		GenViewInkType
		GVIT_PRESSES_ARE_NOT_INK			0
		GVIT_INK_WITH_STANDARD_OVERRIDE		1
		GVIT_PRESSES_ARE_INK				2
		GVIT_QUERY_OUTPUT					3
	WordFlags		GenViewAttrs
		GVA_CONTROLLED						0x8000
		GVA_GENERIC_CONTENTS				0x4000
		GVA_TRACK_SCROLLING					0x2000
		GVA_DRAG_SCROLLING					0x1000
		GVA_NO_WIN_FRAME					0x0800
		GVA_SAME_COLOR_AS_PARENT_WIN		0x0400
		GVA_VIEW_FOLLOWS_CONTENT_GEOMETRY	0x0200
		GVA_WINDOW_COORDINATE_MOUSE_EVENTS	0x0100
		GVA_DONT_SEND_PTR_EVENTS			0x0080
		GVA_DONT_SEND_KBD_RELEASES			0x0040
		GVA_SEND_ALL_KBD_CHARS				0x0020
		GVA_FOCUSABLE						0x0010
		GVA_SCALE_TO_FIT					0x0008
		GVA_ADJUST_FOR_ASPECT_RATIO			0x0004
	ByteFlags		GenViewDimensionAttrs
		GVDA_SCROLLABLE						0x80
		GVDA_SPLITTABLE						0x40
		GVDA_TAIL_ORIENTED					0x20
		GVDA_DONT_DISPLAY_SCROLLBAR			0x10
		GVDA_NO_LARGER_THAN_CONTENT			0x08
		GVDA_NO_SMALLER_THAN_CONTENT		0x04
		GVDA_SIZE_A_MULTIPLE_OF_INCREMENT	0x02
		GVDA_KEEP_ASPECT_RATIO				0x01

**Structures**

	typedef struct {
		RectDWord 				MRVP_bounds
		word 					MRVP_xMargin
		MakeRectVisibleFlags 	MRVP_xFlags
		word 					MRVP_yMargin
		MakeRectVisibleFlags 	MRVP_yFlags
	} MakeRectVisibleParams
	typedef struct {
		optr 				TR_object
		ClassStruct			*TR_class
	} TargetReference
	typedef struct {
		TargetReference			VTI_target
		TargetReference			VTI_content
	} ViewTargetInfo
	typedef struct {
		ScrollAction		TSP_action
		ScrollFlags			TSP_flags
		optr				TSP_caller
		PointDWord 			TSP_change
		PointDWord			TSP_newOrigin
		PointDWord			TSP_oldOrigin
		sword				TSP_viewWidth
		sword 				TSP_viewHeight
	} TrackScrollingParams
	typedef struct {
		WWFixedAsDWord			GSP_yScaleFactor
		WWFixedAsDWord			GSP_xScaleFactor
	} GetScaleParams
	typedef struct {
		optr			IDIP_dest
		word			IDIP_brushSize
		byte			IDIP_color
		Boolean			IDIP_createGState
	} InkDestinationInfoParams

**Macros**

	GVCD_INDEX(val) ((byte) (val))
	GVCD_RED(val) ((byte) (val))
	GVCD_FLAGS(val) ((byte) ((val) >> 8))
	GVCD_BLUE_AND_GREEN(val) ((word) ((val) >> 16))
	GVCD_BLUE(val) ((byte) ((val) >> 16))
	GVCD_GREEN(val) ((byte) ((val) >> 24))
	MAKE_HORIZ_ATTRS(val) ((byte) (val))
	MAKE_VERT_ATTRS(val) ((byte) ((val) >> 8))
	MAKE_SET_CLEAR_ATTRS(setAttrs, clrAttrs)
					((((word) (clrAttrs)) << 8) | (setAttrs))

**Messages**

	void MSG_GEN_VIEW_GET_ORIGIN(PointDWord *origin)
	void MSG_GEN_VIEW_SET_ORIGIN(@stack
				sdword yOrigin, sdword xOrigin)
	void MSG_GEN_VIEW_SCROLL(@stack
				sdword yOffset, sdword xOffset)
	void MSG_GEN_VIEW_MAKE_RECT_VISIBLE(@stack
				word yFlags, word yMargin,
				word xFlags, word xMargin,
				sdword bottom, sdword right,
				sdword top, sdword left)
	void MSG_GEN_VIEW_SET_SCALE_FACTOR(@stack
				sdword yOrigin, sdword xOrigin,
				ScaleViewType scaleType,
				WWFixedAsDWord yScaleFactor,
				WWFixedAsDWord xScaleFactor)
	void MSG_GEN_VIEW_GET_SCALE_FACTOR(
				GetScaleParams *retValue)
	void MSG_GEN_VIEW_SET_CONTENT(optr content)
	optr MSG_GEN_VIEW_GET_CONTENT()
	WindowHandle MSG_GEN_VIEW_GET_WINDOW()
	void MSG_GEN_VIEW_GET_VISIBLE_RECT(RectDWord *rect)
	void MSG_GEN_VIEW_GET_INCREMENT(PointDWord *increment)
	void MSG_GEN_VIEW_SET_INCREMENT(@stack
				sdword yIncrement,
				sdword xIncrement)
	void MSG_GEN_VIEW_SUSPEND_UPDATE()
	void MSG_GEN_VIEW_UNSUSPEND_UPDATE()
	void MSG_GEN_VIEW_SET_DOC_BOUNDS(@stack
				sdword bottom, sdword right,
				sdword top, sdword left)
	void MSG_GEN_VIEW_GET_DOC_BOUNDS(RectDWord *bounds)
	word MSG_GEN_VIEW_GET_ATTRS()
	void MSG_GEN_VIEW_SET_ATTRS(
				word attrsToSet, word attrsToClear,
				word updateMode)
	void MSG_GEN_VIEW_SET_COLOR(
				byte indexOrRed, byte flags,
				word greenBlue)
	dword MSG_GEN_VIEW_GET_COLOR()
	SizeAsDWord MSG_GEN_VIEW_CALC_WIN_SIZE(
				word width, word height)
	void MSG_GEN_VIEW_SET_PTR_IMAGE(
				optr pointerDef,
				PtrImageLevel level)
	void MSG_GEN_VIEW_UPDATE_CONTENT_TARGET_INFO(
				ViewTargetInfo *targetInfo)
	void MSG_GEN_VIEW_INITIATE_DRAG_SCROLL()
	word MSG_GEN_VIEW_GET_DIMENSION_ATTRS()
	void MSG_GEN_VIEW_SET_DIMENSION_ATTRS(
				word horizAttrsToSetClear,
				word vertAttrsToSetClear,
				word updateMode)
	void MSG_GEN_VIEW_SCROLL_TOP()
	void MSG_GEN_VIEW_SCROLL_PAGE_UP()
	void MSG_GEN_VIEW_SCROLL_UP()
	void MSG_GEN_VIEW_SCROLL_SET_Y_ORIGIN(sdword yOrigin)
	void MSG_GEN_VIEW_SCROLL_DOWN()
	void MSG_GEN_VIEW_SCROLL_PAGE_DOWN()
	void MSG_GEN_VIEW_SCROLL_BOTTOM()
	void MSG_GEN_VIEW_SCROLL_LEFT_EDGE()
	void MSG_GEN_VIEW_SCROLL_PAGE_LEFT()
	void MSG_GEN_VIEW_SCROLL_LEFT()
	void MSG_GEN_VIEW_SCROLL_SET_X_ORIGIN(sdword xOrigin)
	void MSG_GEN_VIEW_SCROLL_RIGHT()
	void MSG_GEN_VIEW_SCROLL_PAGE_RIGHT()
	void MSG_GEN_VIEW_SCROLL_RIGHT_EDGE()
	void MSG_GEN_VIEW_ALLOW_GLOBAL_TRANSFER()
	void MSG_GEN_VIEW_SET_DRAG_BOUNDS(@stack
				sdword bottom, sdword right,
				sdword top, sdword left)
	void MSG_GEN_VIEW_SETUP_TRACKING_ARGS(
				TrackScrollingParams *args)
	void MSG_GEN_VIEW_TRACKING_COMPLETE(
				TrackScrollingParams *args)
	optr MSG_GEN_VIEW_DETERMINE_VIS_PARENT(optr child)
	void MSG_GEN_VIEW_SEND_TO_LINKS(
				EventHandle event, optr originator)
	void MSG_GEN_VIEW_SEND_TO_VLINK(
				EventHandle event, optr originator)
	void MSG_GEN_VIEW_SEND_TO_HLINK(
				EventHandle event, optr originator)
	void MSG_GEN_VIEW_CALL_WITHOUT_LINKS(
				EventHandle event,
				MessageFlags messageFlags)
	void MSG_GEN_VIEW_SET_ORIGIN_LOW(@stack
				sdword yOrigin, sdword xOrigin)
	void MSG_GEN_VIEW_SET_INK_TYPE(GenViewInkType inkType)
	void MSG_GEN_VIEW_SET_EXTENDED_INK_TYPE(
				Boolean createGState,
				Color inkColor,
				word brushSize,
				optr destObj)
	void MSG_GEN_VIEW_RESET_EXTENDED_INK_TYPE()
	void MSG_GEN_VIEW_SEND_NOTIFICATION()
	void MSG_GEN_VIEW_SCALE_LOW(@stack
				sdword yOrigin, sdword xOrigin,
				ScaleViewType scaleType,
				WWFixedAsDWord yScaleFactor,
				WWFixedAsDWord xScaleFactor)
	void MSG_GEN_VIEW_REDRAW_CONTENT()
	void MSG_GEN_VIEW_SET_CONTROLLED_ATTRS(
				GenViewControlAttrs controlAttrs,
				word scaleFactor)

#  GenViewControlClass

	@class GenViewControlClass, GenControlClass

**Instance Data**

	word			GVCI_minZoom = DEFAULT_ZOOM_MINIMUM
	word			GVCI_maxZoom = DEFAULT_ZOOM_MAXIMUM
	word			GVCI_scale = 100
	GenViewControlAttrs GVCI_attrs = (GVCA_SHOW_HORIZONTAL |
					GVCA_SHOW_VERTICAL | GVCA_APPLY_TO_ALL)
		@default GI_attrs = (@default | GA_KBD_SEARCH_PATH)

**Variable Data**

	void ATR_GEN_VIEW_CONTROL_LARGE_ZOOM

**Types and Flags**

	WordFlags		GVCFeatures
		GVCF_MAIN_100				0x4000
		GVCF_MAIN_SCALE_TO_FIT		0x2000
		GVCF_ZOOM_IN				0x1000
		GVCF_ZOOM_OUT				0x0800
		GVCF_REDUCE					0x0400
		GVCF_100					0x0200
		GVCF_ENLARGE				0x0100
		GVCF_BIG_ENLARGE			0x0080
		GVCF_SCALE_TO_FIT			0x0040
		GVCF_ADJUST_ASPECT_RATIO	0x0020
		GVCF_APPLY_TO_ALL			0x0010
		GVCF_SHOW_HORIZONTAL		0x0008
		GVCF_SHOW_VERTICAL			0x0004
		GVCF_CUSTOM_SCALE			0x0002
		GVCF_REDRAW					0x0001
	WordFlags		GVCToolboxFeatures
		GVCTF_100					0x1000
		GVCTF_SCALE_TO_FIT			0x0800
		GVCTF_ZOOM_IN				0x0400
		GVCTF_ZOOM_OUT				0x0200
		GVCTF_REDRAW				0x0100
		GVCTF_PAGE_LEFT				0x0080
		GVCTF_PAGE_RIGHT			0x0040
		GVCTF_PAGE_UP				0x0020
		GVCTF_PAGE_DOWN				0x0010
		GVCTF_ADJUST_ASPECT_RATIO	0x0008
		GVCTF_APPLY_TO_ALL			0x0004
		GVCTF_SHOW_HORIZONTAL		0x0002
		GVCTF_SHOW_VERTICAL			0x0001
	GVC_DEFAULT_FEATURES				(GVCF_MAIN_100 |
			GVCF_MAIN_SCALE_TO_FIT | GVCF_ZOOM_IN |
			GVCF_ZOOM_OUT | GVCF_REDUCE | GVCF_100 |
			GVCF_ENLARGE | GVCF_SCALE_TO_FIT |
			GVCF_ADJUST_ASPECT_RATIO |
			GVCF_APPLY_TO_ALL | GVCF_SHOW_HORIZONTAL |
			GVCF_SHOW_VERTICAL | GVCF_CUSTOM_SCALE)
	GVC_DEFAULT_TOOLBOX_FEATURES (GVCTF_100 | 
			GVCTF_ZOOM_IN | GVCTF_ZOOM_OUT)
	GVC_SUGGESTED_SIMPLE_FEATURES (GVCF_MAIN_100 |
			GVCF_MAIN_SCALE_TO_FIT | GVCF_ZOOM_IN |
			GVCF_ZOOM_OUT)
	GVC_SUGGESTED_INTRODUCTORY_FEATURES (GVCF_MAIN_100 |
			GVCF_ZOOM_IN | GVCF_ZOOM_OUT)
	GVC_SUGGESTED_BEGINNING_FEATURES
			(GVC_SUGGESTED_INTRODUCTORY_FEATURES |
			GVCF_MAIN_SCALE_TO_FIT)
	DEFAULT_ZOOM_MINIMUM				25
	DEFAULT_ZOOM_MAXIMUM				200
	typedef enum /* word */ {
		GVCSSF_TO_FIT,
	} GenViewControlSpecialScaleFactor
	WordFlags GenViewControlAttrs
		GVCA_ADJUST_ASPECT_RATIO			0x8000
		GVCA_APPLY_TO_ALL					0x4000
		GVCA_SHOW_HORIZONTAL				0x2000
		GVCA_SHOW_VERTICAL					0x1000

**Structures**

	typedef struct {
		PointDWFixed 			NVSC_origin
		RectDWord 				NVSC_docBounds
		PointDWord 				NVSC_increment
		PointWWFixed 			NVSC_scaleFactor
		ColorQuad 				NVSC_color
		GenViewAttrs 			NVSC_attrs
		GenViewDimensionAttrs 	NVSC_horizAttrs
		GenViewDimensionAttrs 	NVSC_vertAttrs
		GenViewInkType 			NVSC_inkType
		XYSize 					NVSC_contentSize
		XYSize 					NVSC_contentScreenSize
		PointDWord 				NVSC_originRelative
		PointDWord 				NVSC_documentSize
	} NotifyViewStateChange
	typedef struct {
		optr					NVO_view
	} NotifyViewOpening

**Messages**
	void MSG_GEN_VIEW_CONTROL_SET_ATTRS(
				GenViewControlAttrs attrsToSet,
				GenViewControlAttrs attrsToClear)
	void MSG_GEN_VIEW_CONTROL_SET_MINIMUM_SCALE_FACTOR(
				word minimumScaleFactor)
	void MSG_GEN_VIEW_CONTROL_SET_MAXIMUM_SCALE_FACTOR(
				word maximumScaleFactor)
	void MSG_GVC_SET_SCALE()
	void MSG_GVC_SET_SCALE_VIA_LIST()
	void MSG_GVC_SET_ATTRS()
	void MSG_GVC_REDRAW()
	void MSG_GVC_ZOOM_IN()
	void MSG_GVC_ZOOM_OUT()
	void MSG_GVC_PAGE_LEFT()
	void MSG_GVC_PAGE_RIGHT()
	void MSG_GVC_PAGE_UP()
	void MSG_GVC_PAGE_DOWN()

## GrObjAlignDistributeControlClass

	@class GrObjAlignDistributeControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)
		@default GII_type = GIT_PROPERTIES
		@default GII_visibility = GIV_DIALOG

**Types and Flags**

	WordFlags		GrObjAlignDistributeControlFeatures
		GOADCF_ALIGN_LEFT						0x8000
		GOADCF_ALIGN_CENTER_HORIZONTALLY		0x4000
		GOADCF_ALIGN_RIGHT						0x2000
		GOADCF_ALIGN_WIDTH						0x1000
		GOADCF_ALIGN_TOP						0x800
		GOADCF_ALIGN_CENTER_VERTICALLY			0x400
		GOADCF_ALIGN_BOTTOM						0x200
		GOADCF_ALIGN_HEIGHT						0x100
		GOADCF_DISTRIBUTE_LEFT					0x80
		GOADCF_DISTRIBUTE_CENTER_HORIZONTALLY	0x40
		GOADCF_DISTRIBUTE_RIGHT					0x20
		GOADCF_DISTRIBUTE_WIDTH					0x10
		GOADCF_DISTRIBUTE_TOP					0x8
		GOADCF_DISTRIBUTE_CENTER_VERTICALLY 	0x4
		GOADCF_DISTRIBUTE_BOTTOM 				0x2
		GOADCF_DISTRIBUTE_HEIGHT 				0x1
	GOADC_DEFAULT_FEATURES
						GrObjAlignDistributeControlFeatures

## GrObjAlignToGridControlClass

	@class GrObjAlignToGridControlClass, GenControlClass

**Instance Data**

		@default GII_type = (GIT_COMMAND)
		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GOATGCFeatures
		GOATGCF_ALIGN_TO_GRID				0x01
	GOATGC_DEFAULT_FEATURES					(GOATGCF_ALIGN_TO_GRID)
	GOATGC_DEFAULT_TOOLBOX_FEATURES			0

**Messages**

	MSG_GOATGC_ALIGN_TO_GRID

## GrObjArcControlClass

	@class GrObjArcControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GOArcCFeatures
		GOACF_START_ANGLE			0x8
		GOACF_END_ANGLE				0x4
		GOACF_PIE_TYPE				0x2
		GOACF_CHORD_TYPE			0x1
	GOArcC_DEFAULT_FEATURES		(GOACF_START_ANGLE |
								 GOACF_END_ANGLE |
								 GOACF_PIE_TYPE |
								 GOACF_CHORD_TYPE)
	GOArcC_DEFAULT_TOOLBOX_FEATURES 0

**Messages**

	MSG_GOAC_SET_START_ANGLE
	MSG_GOAC_SET_END_ANGLE
	MSG_GOAC_SET_ARC_CLOSE_TYPE

## GrObjAreaAttrControlClass

	@class GrObjAreaAttrControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)
		@default GI_states = (@default | GS_ENABLED)

**Types and Flags**

	ByteFlags		GOAACFeatures
		GOAACF_MM_CLEAR 			0x0100
		GOAACF_MM_COPY 				0x0080
		GOAACF_MM_NOP 				0x0040
		GOAACF_MM_AND 				0x0020
		GOAACF_MM_INVERT 			0x0010
		GOAACF_MM_XOR 				0x0008
		GOAACF_MM_SET 				0x0004
		GOAACF_MM_OR 				0x0002
		GOAACF_TRANSPARENCY 		0x0001
	GOAAC_DEFAULT_FEATURES	(GOAACF_TRANSPARENCY |
							GOAACF_MM_COPY |
							GOAACF_MM_INVERT |
							GOAACF_MM_XOR |
							GOAACF_MM_AND | GOAACF_MM_OR)
	GOAAC_DEFAULT_TOOLBOX_FEATURES	0

**Messages**

	MSG_GOAAC_SET_MIX_MODE
	MSG_GOAAC_SET_AREA_TRANSPARENCY

## GrObjAreaColorSelectorClass

	@class GrObjAreaColorSelectorClass, ColorSelectorClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)
		@default GI_states = (@default | GS_ENABLED)

**Types and Flags**

	GOACS_DEFAULT_FEATURES	(CSF_INDEX | CSF_RGB |
							CSF_DRAW_MASK | CSF_PATTERN)

## GrObjAttributeManagerClass

	@class GrObjAttributeManagerClass, GrObjClass

**Instance Data**

	word 			GOAMI_areaAttrArrayHandle = 0
	word 			GOAMI_lineAttrArrayHandle = 0
	word 			GOAMI_grObjStyleArrayHandle = 0
	ChunkHandle 	GOAMI_bodyList = 0
	word 			GOAMI_charAttrArrayHandle = 0
	word 			GOAMI_paraAttrArrayHandle = 0
	word 			GOAMI_typeArrayHandle = 0
	word 			GOAMI_graphicArrayHandle = 0
	word 			GOAMI_nameArrayHandle = 0
	word 			GOAMI_textStyleArrayHandle = 0
	optr 			GOAMI_text
		default GOI_optFlags = (GOOF_GROBJ_INVALID |
								GOOF_ATTRIBUTE_MANAGER)

**Types and Flags**

	GROBJ_VM_ELEMENT_ARRAY_CHUNK (sizeof LMemblockHeader)

**Messages**

	MSG_GOAM_ATTACH_AND_CREATE_ARRAYS
	MSG_GOAM_ADD_AREA_ATTR_ELEMENT
	MSG_GOAM_ADD_LINE_ATTR_ELEMENT
	MSG_GOAM_DEREF_AREA_ATTR_ELEMENT_TOKEN
	MSG_GOAM_DEREF_LINE_ATTR_ELEMENT_TOKEN
	MSG_GOAM_ADD_REF_AREA_ATTR_ELEMENT_TOKEN
	MSG_GOAM_ADD_REF_LINE_ATTR_ELEMENT_TOKEN
	MSG_GOAM_GET_FULL_AREA_ATTR_ELEMENT
	MSG_GOAM_GET_FULL_LINE_ATTR_ELEMENT
	MSG_GOAM_GET_STYLE_ARRAY
	MSG_GOAM_GET_AREA_ATTR_ARRAY
	MSG_GOAM_GET_LINE_ATTR_ARRAY
	MSG_GOAM_GET_AREA_AND_LINE_TOKENS_FROM_STYLE
	MSG_GOAM_ATTACH_BODY
	MSG_GOAM_INVALIDATE_BODIES
	MSG_GOAM_SUBST_AREA_TOKEN
	MSG_GOAM_SUBST_LINE_TOKEN
	MSG_GOAM_GET_TEXT_OD
	MSG_GOAM_GET_TEXT_ARRAYS
	MSG_GOAM_LOAD_STYLE_SHEET_PARAMS
	MSG_GOAM_DETACH_BODY
	MSG_GOAM_SUBST_TEXT_ATTR_TOKEN
	MSG_GOAM_RECALC_FOR_TEXT_ATTR_CHANGE
	void MSG_GOAM_LOAD_STYLE_SHEET
	void MSG_GOAM_SET_GROBJ_DRAW_FLAGS(
							GrObjDrawFlags flagsToSet,
							GrObjDrawFlags flagsToReset)

## GrObjBackgroundColorSelectorClass

	@class GrObjBackgroundColorSelectorClass, ColorSelectorClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)
		@default GI_states = (@default | GS_ENABLED)

**Types and Flags**

	GOBGCS_DEFAULT_FEATURES				(CSF_INDEX | CSF_RGB)

## GrObjBitmapClass

	@class GrObjBitmapClass, GrObjVisClass

## GrObjBodyClass

	@class GrObjBodyClass, VisCompClass

**Instance Data**

	RectDWord			GBI_bounds = {0,0,0,0}
	CompPart 			GBI_drawComp = {NullOptr}
	CompPart 			GBI_reverseComp = {NullOptr}
	word 				GBI_childCount
	optr 				GBI_selectionArray
	HierarchicalGrab 	GBI_targetExcl = {NullOptr, 0}
	HierarchicalGrab 	GBI_focusExcl = {NullOptr, 0}
	optr 				GBI_mouseGrab
	word 				GBI_objBlockArray
	GrObjFunctionsActive GBI_defaultOptions
	GrObjFunctionsActive GBI_currentModifiers
	GrObjFunctionsActive GBI_currentOptions
	GrObjBodyFlags 		GBI_flags = (GBF_DEFAULT_TARGET |
						GBF_DEFAULT_FOCUS)
	GrObjDrawFlags 		GBI_drawFlags
	GrObjFileStatus 	GBI_fileStatus
	word 				GBI_graphicsState = 0
	optr 				GBI_head
	optr 				GBI_goam
	optr 				GBI_ruler
	word 				GBI_priorityList = 0
	byte 				GBI_desiredHandleSize =
						DEFAULT_DESIRED_HANDLE_SIZE
	byte 				GBI_curHandleWidth = 0
	byte 				GBI_curHandleHeight = 0
	BBFixed 			GBI_curNudgeX = {0, 0}
	BBFixed 			GBI_curNudgeY = {0, 0}
	PointWWFixed 		GBI_curScaleFactor =
							{MakeWWFixed(1),
							 MakeWWFixed(0)}
	PointDWFixed 		GBI_interestingPoint =
							{ {0, -30000}, {0, -30000} }
	PointDWFixed 		GBI_lastPtr = {0,0}
	word 				GBI_suspendCount = 0
	GrObjBodyUnsuspendOps GBI_unsuspendOps = 0
	VisTextNotificationFlags GBI_textUnsuspendOps = 0
	word 				GBI_reserved1 = 0
	word 				GBI_reserved2 = 0
		@default VI_optFlags = 0
		@default VI_typeFlags = (VTF_IS_COMPOSITE |
								 VTF_IS_INPUT_NODE)
		@default VI_attrs = (VA_DRAWABLE | VA_DETECTABLE |
							 VA_FULLY_ENABLED )

**Variable Data**

	GrObjBodyPasteCallBackStruct ATTR_GB_PASTE_CALL_BACK

**Types and Flags**

	WordFlags		GrObjBodyUnsuspendOps
	ByteFlags		GrObjBodyFlags
		GBF_HAS_ACTION_NOTIFICATION			0x04
		GBF_DEFAULT_TARGET					0x02
		GBF_DEFAULT_FOCUS					0x01
	WordFlags		GrObjDrawFlags
		GODF_DRAW_QUICK_VIEW						0x100
		GODF_DRAW_CLIP_ONLY							0x80
		GODF_DRAW_WRAP_TEXT_INSIDE_ONLY				0x40
		GODF_DRAW_WRAP_TEXT_AROUND_ONLY				0x20
		GODF_DRAW_WITH_INCREASED_RESOLUTION			0x10
		GODF_DRAW_INSTRUCTIONS						0x08
		GODF_DRAW_SELECTED_OBJECTS_ONLY				0x04
		GODF_DRAW_OBJECTS_ONLY						0x02
		GODF_PRINT_INSTRUCTIONS						0x01
	ByteFlags		GrObjsInRectSpecial
		GOIRS_IGNORE_TEMP				0x04
		GOIRS_IGNORE_RECT				0x02
		GOIRS_XOR_CHECK					0x01
	WordFlags		GrObjBodyAddGrObjFlags
		GOBAGOF_DRAW_LIST_POSITION			0x8000
		GOBAGOF_REFERENCE					0x7fff
	GOBAGOR_FIRST			CCO_FIRST
	GOBAGOR_LAST			CCO_LAST

**Structures**

	typedef struct {
		word 					GOIRD_tempMessage
		word 					GOIRD_tempMessageDX
		word 					GOIRD_inRectMessage
		word 					GOIRD_inRectMessageDX
		RectDWord 				GOIRD_rect
		GrObjsInRectSpecial 	GOIRD_special
		word 					align
	} GrObjsInRectData
	typedef struct {
		word 							GBCDP_repetitions
		PointDWFixed 					GBCDP_move
		WWFixed 						GBCDP_rotation
		GrObjHandleSpecification 		GBCDP_rotateAnchor
		GrObjAnchoredSkewData 			GBCDP_skew
		GrObjAnchoredScaleData 			GBCDP_scale
	} GrObjBodyCustomDuplicateParams
	typedef struct {
		word 			GOBPCBS_message
		optr 			GOBPCBS_optr
	} GrObjBodyPasteCallBackStruct

**Messages**

	MSG_GB_CREATE_GSTATE
	MSG_GB_INVALIDATE
	MSG_GB_GIVE_ME_MOUSE_EVENTS
	MSG_GB_DONT_GIVE_ME_MOUSE_EVENTS
	MSG_GB_ATTACH_HEAD
	void MSG_GB_ATTACH_GOAM(optr GrObjAttrManager)
	MSG_GB_ATTACH_RULER
	void MSG_GB_ADD_GROBJ(optr object, word flags)
	MSG_GB_REMOVE_GROBJ
	MSG_GB_FIND_GROBJ */
	MSG_GB_PULL_SELECTED_GROBJS_TO_FRONT
	MSG_GB_PUSH_SELECTED_GROBJS_TO_BACK
	MSG_GB_SHUFFLE_SELECTED_GROBJS_UP
	MSG_GB_SHUFFLE_SELECTED_GROBJS_DOWN
	void MSG_GB_SET_DESIRED_HANDLE_SIZE(byte handleSize)
	MSG_GB_GET_DESIRED_HANDLE_SIZE
	void MSG_GB_ATTACH_UI(optr GrObjHead)
	void MSG_GB_DETACH_UI()
	MSG_GB_ADD_GROBJ_TO_SELECTION_LIST
	MSG_GB_REMOVE_GROBJ_FROM_SELECTION_LIST
	MSG_GB_REMOVE_ALL_GROBJS_FROM_SELECTION_LIST
	MSG_GB_SEND_CLASSED_EVENT_TO_SELECTED_GROBJS
	MSG_GB_GET_NUM_SELECTED_GROBJS
	MSG_GB_GET_BOUNDS_OF_SELECTED_GROBJS
	MSG_GB_GET_DWF_BOUNDS_OF_SELECTED_GROBJS
	MSG_GB_GET_SUMMED_DWF_DIMENSIONS_OF_SELECTED_GROBJS
	MSG_GB_DELETE_SELECTED_GROBJS
	MSG_GB_PROCESS_ALL_GROBJS_IN_RECT
	MSG_GB_INCREASE_POTENTIAL_EXPANSION
	MSG_GB_DECREASE_POTENTIAL_EXPANSION
	MSG_GB_FILL_PRIORITY_LIST
	MSG_GB_MESSAGE_TO_FLOATER_IF_PARENT
	MSG_GB_UPDATE_UI_CONTROLLERS
	MSG_GB_UPDATE_EXTENDED_AREA_ATTR_CONTROLLERS 
	MSG_GB_UPDATE_EXTENDED_AREA_ATTR_CONTROLLERS_WITH_DEFAULTS
	MSG_GB_UPDATE_EXTENDED_LINE_ATTR_CONTROLLERS
	MSG_GB_UPDATE_EXTENDED_LINE_ATTR_CONTROLLERS_WITH_DEFAULTS
	MSG_GB_UPDATE_INSTRUCTION_CONTROLLERS
	MSG_GB_ADD_DUPLICATE_FLOATER
	MSG_GB_PRIORITY_LIST_RESET
	MSG_GB_PRIORITY_LIST_GET_NUM_ELEMENTS
	MSG_GB_PRIORITY_LIST_GET_ELEMENT
	MSG_GB_PRIORITY_LIST_INIT
	MSG_GB_GROUP_SELECTED_GROBJS
	MSG_GB_UNGROUP_SELECTED_GROUPS
	MSG_GB_TRANSFER_GROBJ_FROM_GROUP
	MSG_GB_CLOSE_FINISH_UP
	MSG_GB_CLEAR()
	MSG_GB_ALIGN_SELECTED_GROBJS
	MSG_GB_CREATE_SORTABLE_ARRAY
	MSG_GB_DESTROY_SORTABLE_ARRAY
	MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_DWF_BOUNDS
	MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_CENTERS
	MSG_GB_SORT_SORTABLE_ARRAY
	MSG_GB_GET_CENTER_OF_SELECTED_GROBJS
	MSG_GB_GET_CENTER_OF_FIRST_SELECTED_GROBJ
	MSG_GB_GET_CENTER_OF_LAST_SELECTED_GROBJ
	MSG_GB_GET_DWF_BOUNDS_OF_FIRST_SELECTED_GROBJ
	MSG_GB_GET_DWF_BOUNDS_OF_LAST_SELECTED_GROBJ
	MSG_GB_GET_BLOCK_FOR_ONE_GROBJ
	MSG_GB_GET_WINDOW
	void MSG_GB_ADD_GROBJ_THEN_DRAW(optr object, word flags)
	void MSG_GB_SET_BOUNDS(RectDWord *bounds)
	void MSG_GB_GET_BOUNDS(RectDWord *bounds)
	void MSG_GB_SET_ACTION_NOTIFICATION_OUTPUT(
				optr object, word messageNumber)
	void MSG_GB_SUSPEND_ACTION_NOTIFICATION()
	void MSG_GB_UNSUSPEND_ACTION_NOTIFICATION()
	optr MSG_GB_INSTANTIATE_GROBJ(ClassStruct *class)
	MSG_GB_SUBST_AREA_TOKEN
	MSG_GB_SUBST_LINE_TOKEN
	MSG_GB_CREATE_GROBJ_TRANSFER_FORMAT
	MSG_GB_CREATE_GSTRING_TRANSFER_FORMAT
	MSG_GB_SEND_CLASSED_EVENT_SET_DEFAULT_ATTRS
	MSG_GB_CHANGE_GROBJ_DEPTH
	MSG_GB_DRAW( GStateHandle gstate,
				DrawFlags visDrawFlags,
				GrObjDrawFlags GODrawFlags)
	MSG_GB_EXPORT
	MSG_GB_GRAB_TARGET_FOCUS
	MSG_GB_GENERATE_TEXT_NOTIFY
	MSG_GB_GENERATE_SPLINE_NOTIFY
	MSG_GB_DETACH_GOAM
	MSG_GB_IMPORT
	MSG_GB_CONVERT_SELECTED_GROBJS_TO_BITMAP
	MSG_GB_CONVERT_SELECTED_GROBJS_TO_GRAPHIC
	MSG_GB_IGNORE_UNDO_ACTIONS_AND_SUSPEND
	MSG_GB_UNSUSPEND_AND_ACCEPT_UNDO_ACTIONS
	MSG_GB_MAKE_INSTRUCTIONS_SELECTABLE_AND_EDITABLE
	MSG_GB_MAKE_INSTRUCTIONS_UNSELECTABLE_AND_UNEDITABLE
	void MSG_GB_SET_GROBJ_DRAW_FLAGS(
				GrObjDrawFlags flagsToSet,
				GrObjDrawFlags flagsToReset)
	MSG_GB_DELETE_INSTRUCTIONS
	MSG_GB_PASTE_INSIDE
	MSG_GB_CLONE_SELECTED_GROBJS
	MSG_GB_CREATE_POLYGON
	MSG_GB_CREATE_STAR
	MSG_GB_SUBST_TEXT_ATTR_TOKEN
	MSG_GB_RECALC_FOR_TEXT_ATTR_CHANGE
	void MSG_GB_GET_BOUNDS_OF_GROBJS(RectDWord *retValue)
	void MSG_GB_CUSTOM_DUPLICATE_SELECTED_GROBJS(
			GrObjBodyCustomDuplicateParams *cdParams)
	MSG_GB_EXPORT_SELECTED_GROBJS
	MSG_GB_HIDE_UNSELECTED_GROBJS
	MSG_GB_SHOW_ALL_GROBJS
	MSG_GB_CREATE_GROBJ
	MSG_GB_DUPLICATE_SELECTED_GROBJS
	MSG_GB_FIND_NEXT_GROBJ_THAT_OVERLAPS
	MSG_GB_FIND_PREV_GROBJ_THAT_OVERLAPS
	MSG_GB_ZOOM_IN_ABOUT_POINT
	MSG_GB_ZOOM_OUT_ABOUT_POINT
	MSG_GB_EVALUATE_MOUSE_POSITION
	MSG_GB_EVALUATE_POINT_FOR_HANDLE
	MSG_GB_EVALUATE_POINT_FOR_BOUNDS
	MSG_GB_SET_NORMAL_SIZE_ABOUT_POINT
	MSG_GB_DRAW_GROBJ
	MSG_GB_SEND_TO_SELECTED_GROBJS_SHARE_DATA
	MSG_GB_STANDARD_PASTE_CALL_BACK
	MSG_GB_PASTE
	MSG_GB_REORDER_SELECTION_ARRAY
	MSG_GB_ABORT_SEARCH_SPELL_MESSAGE
	void MSG_GB_QUICK_PASTE(PointDWFixed *pasteAt)
	GrObjDrawFlags MSG_GB_GET_GROBJ_DRAW_FLAGS(
				DrawFlags drawFlags)
	void MSG_GB_SET_BOUNDS_WITHOUT_MARKING_DIRTY(
				RectDWord *bounds)
	void MSG_GB_SET_GROBJ_DRAW_FLAGS_NO_BROADCAST(
				GrObjDrawFlags flagsToSet,
				GrObjDrawFlags flagsToReset)
	MSG_GB_QUICK_PASTE_CALL_BACK

## GrObjClass

	@class GrObjClass, MetaClass, master

**Instance Data**

	LinkPart 				GOI_drawLink
	LinkPart 				GOI_reverseLink
	GrObjAttrFlags 			GOI_attrFlags =
							(GOAF_INSERT_DELETE_MOVE_ALLOWED |
							GOAF_INSERT_DELETE_RESIZE_ALLOWED |
							GOAF_INSERT_DELETE_DELETE_ALLOWED )
	GrObjOptimizationFlags	GOI_optFlags =
							(GOOF_GROBJ_INVALID)
	GrObjMessageOptimizationFlags GOI_msgOptFlags =(0)
	GrObjLocks 				GOI_locks = 0
	GrObjActionModes 		GOI_actionModes = 0
	GrObjTempModes 			GOI_tempState = 0
	ChunkHandle 			GOI_normalTransform = NullChunk
	ChunkHandle 			GOI_spriteTransform = NullChunk
	word 					GOI_areaAttrToken = CA_NULL_ELEMENT
	word 					GOI_lineAttrToken = CA_NULL_ELEMENT

**Variable Data**

	GrObjObjManipData ATTR_GO_OBJ_MANIP_DATA
	GrObjActionNotificationStruct
						ATTR_GO_ACTION_NOTIFICATION
	PointWWFixed ATTR_GO_PARENT_DIMENSIONS_OFFSET

**Types and Flags**

	ByteFlags		GrObjHandleSpecification
		GOHS_HANDLE_LEFT				0x08
		GOHS_HANDLE_TOP					0x04
		GOHS_HANDLE_RIGHT				0x02
		GOHS_HANDLE_BOTTOM				0x01
	HANDLE_MOVE					0
	HANDLE_CENTER				HANDLE_MOVE
	HANDLE_LEFT_TOP				(GOHS_HANDLE_LEFT | GOHS_HANDLE_TOP)
	HANDLE_MIDDLE_TOP			GOHS_HANDLE_TOP
	HANDLE_RIGHT_TOP			(GOHS_HANDLE_RIGHT |
								 GOHS_HANDLE_TOP)
	HANDLE_LEFT_MIDDLE			GOHS_HANDLE_LEFT
	HANDLE_RIGHT_MIDDLE			GOHS_HANDLE_RIGHT
	HANDLE_LEFT_BOTTOM			(GOHS_HANDLE_LEFT |
								 GOHS_HANDLE_BOTTOM)
	HANDLE_MIDDLE_BOTTOM GOHS_HANDLE_BOTTOM
	HANDLE_RIGHT_BOTTOM			(GOHS_HANDLE_BOTTOM |
								GOHS_HANDLE_RIGHT)
	ByteFlags		HandleUpdateMode
		HUM_NOW				0
		HUM_MANUAL			1
	WordFlags		GrObjBaseAreaAttrDiffs
		GOBAAD_MULTIPLE_ELEMENT_TYPES				0x8000
		GOBAAD_MULTIPLE_STYLE_ELEMENTS 				0x4000
		GOBAAD_MULTIPLE_COLORS 						0x2000
		GOBAAD_MULTIPLE_BACKGROUND_COLORS 			0x1000
		GOBAAD_MULTIPLE_MASKS 						0x0800
		GOBAAD_MULTIPLE_PATTERNS 					0x0400
		GOBAAD_MULTIPLE_DRAW_MODES 					0x0200
		GOBAAD_MULTIPLE_INFOS 						0x0100
		GOBAAD_MULTIPLE_GRADIENT_END_COLORS 		0x0080
		GOBAAD_MULTIPLE_GRADIENT_TYPES 				0x0040
		GOBAAD_MULTIPLE_GRADIENT_INTERVALS 			0x0020
		GOBAAD_FIRST_RECIPIENT 						0x0001
	FUTURE_AREA_ATTR_ELEMENT_SIZE		50
	WordFlags		GrObjBaseLineAttrDiffs
		GOBLAD_MULTIPLE_STYLE_ELEMENTS 				0x8000
		GOBLAD_MULTIPLE_ELEMENT_TYPES 				0x4000
		GOBLAD_MULTIPLE_COLORS 						0x2000
		GOBLAD_MULTIPLE_ENDS 						0x1000
		GOBLAD_MULTIPLE_JOINS 						0x0800
		GOBLAD_MULTIPLE_WIDTHS 						0x0400
		GOBLAD_MULTIPLE_MASKS 						0x0200
		GOBLAD_MULTIPLE_STYLES 						0x0100
		GOBLAD_MULTIPLE_DRAW_MODES 					0x0080
		GOBLAD_MULTIPLE_MITER_LIMITS 				0x0040
		GOBLAD_FIRST_RECIPIENT 						0x0001
	FUTURE_LINE_ATTR_ELEMENT_DATA_SIZE 50
	ByteFlags		GrObjSelectionStateFlags
		GSSF_EDITING 								0x20
		GSSF_UNGROUPABLE 							0x10
		GSSF_TEXT_SELECTED 							0x08
		GSSF_BITMAP_SELECTED 						0x04
		GSSF_SPLINE_SELECTED 						0x02
		GSSF_ARC_SELECTED 							0x01
	ByteFlags		GrObjSelectionStateDiffs
		GSSD_MULTIPLE_CLASSES 						0x80
		GSSD_MULTIPLE_ARC_CLOSE_TYPES 				0x40
		GSSD_MULTIPLE_ARC_START_ANGLES 				0x20
		GSSD_MULTIPLE_ARC_END_ANGLES 				0x10
	WordFlags		GrObjUINotificationTypes
		GOUINT_AREA 								0x8000
		GOUINT_LINE 								0x4000
		GOUINT_SELECT 								0x2000
		GOUINT_GROBJ_SELECT 						0x1000
		GOUINT_STYLE_SHEET 							0x0800
		GOUINT_STYLE 								0x0400
		GOUINT_SPLINE 								0x0200

**Structures**

	typedef struct {
		WWFixed 			RWWF_left
		WWFixed 			RWWF_top
		WWFixed 			RWWF_right
		WWFixed 			RWWF_bottom
	} RectWWFixed
	typedef struct {
		WWFixed 			GOSD_xScale
		WWFixed 			GOSD_yScale
	} GrObjScaleData
	typedef struct {
		GrObjScaleData 					GOASD_scale
		GrObjHandleSpecification 		GOASD_scaleAnchor
	} GrObjAnchoredScaleData
	typedef struct {
		GrObjBaseAreaAttrElement 	GOFAAE_base
		byte		GOFAAE_future[FUTURE_AREA_ATTR_ELEMENT_SIZE]
	} GrObjFullAreaAttrElement
	typedef struct {
		GrObjBaseAreaAttrElement				GNAAC_areaAttr
		GrObjBaseAreaAttrDiffs 					GNAAC_areaAttrDiffs
	} GrObjNotifyAreaAttrChange
	typedef struct {
		GrObjBaseLineAttrElement 	GOFLAE_base
		byte		GOFLAE_future[FUTURE_LINE_ATTR_ELEMENT_DATA_SIZE]
	} GrObjFullLineAttrElement
	typedef struct {
		word 						GSS_numSelected
		ClassStruct					*GSS_classSelected
		GrObjSelectionStateFlags 	GSS_flags
		GrObjAttrFlags 				GSS_grObjFlags
		GrObjLocks 					GSS_locks
	} GrObjSelectionState
	typedef struct {
		WWFixed 			GOSD_xDegrees
		WWFixed 			GOSD_yDegrees
	} GrObjSkewData
	typedef struct {
		GrObjSkewData 					GOASD_degrees
		GrObjHandleSpecification 		GOASD_skewAnchor
	} GrObjAnchoredSkewData
	typedef struct {
		WWFixed 			GTM_e11
		WWFixed 			GTM_e12
		WWFixed 			GTM_e21
		WWFixed 			GTM_e22
	} GrObjTransMatrix
	typedef struct {
		WWFixed 			GOGSP_height
		WWFixed 			GOGSP_width
	} GOGetSizeParams
	typedef struct {
		PointDWFixed 		GOID_position
		WWFixed 			GOID_width
		WWFixed 			GOID_height
	} GrObjInitializeData
	typedef struct {
		StyleSheetParams 				GTP_ssp
		VisTextSaveStyleSheetParams 	GTP_textSSP
		PointDWFixed 					GTP_selectionCenterDOCUMENT
		Handle 							GTP_optBlock
		Handle 							GTP_vmFile
		word 							GTP_curSlot
		dword 							GTP_id
		word 							GTP_curSize
		word 							GTP_curPos
	} GrObjTransferParams

**Messages**

	void MSG_GO_GAINED_SELECTION_LIST(HandleUpdateMode hum)
	void MSG_GO_LOST_SELECTION_LIST()
	void MSG_GO_BECOME_SELECTED(HandleUpdateMode hum)
	void MSG_GO_TOGGLE_SELECTION()
	void MSG_GO_BECOME_UNSELECTED()
	MSG_GO_UNDRAW_SPRITE
	MSG_GO_DRAW_SPRITE
	MSG_GO_DRAW_SPRITE_RAW
	MSG_GO_DRAW_HANDLES
	MSG_GO_UNDRAW_HANDLES
	MSG_GO_DRAW_HANDLES_RAW
	MSG_GO_DRAW_HANDLES_FORCE
	MSG_GO_DRAW_HANDLES_MATCH
	MSG_GO_DRAW_HANDLES_OPPOSITE
	MSG_GO_ACTIVATE_MOVE
	MSG_GO_ACTIVATE_RESIZE
	MSG_GO_ACTIVATE_ROTATE
	MSG_GO_ACTIVATE_CREATE
	MSG_GO_REACTIVATE_CREATE
	MSG_GO_START_CHOOSE_ABS
	MSG_GO_START_MOVE_ABS
	MSG_GO_JUMP_START_MOVE
	MSG_GO_JUMP_START_RESIZE
	MSG_GO_JUMP_START_ROTATE
	MSG_GO_PTR_CHOOSE_ABS
	MSG_GO_PTR_MOVE
	MSG_GO_PTR_RESIZE
	MSG_GO_PTR_ROTATE
	MSG_GO_PTR_MOVE_ABS
	MSG_GO_END_CHOOSE_ABS
	MSG_GO_END_MOVE_ABS
	MSG_GO_END_MOVE
	MSG_GO_END_RESIZE
	MSG_GO_END_ROTATE
	MSG_GO_CLEAR
	MSG_GO_INVERT_HANDLES
	MSG_GO_INIT_BASIC_DATA
	void MSG_GO_FLIP_HORIZ()
	void MSG_GO_FLIP_VERT()
	void MSG_GO_ROTATE(WWFixed angle,
				GrObjHandleSpecification center)
	void MSG_GO_UNTRANSFORM()
	void MSG_GO_MOVE(PointDWFixed *distance)
	void MSG_GO_MOVE_CENTER_ABS(PointDWFixed *location)
	MSG_GO_ALIGN
	MSG_GO_ALIGN_TO_GRID
	MSG_GO_SEND_ANOTHER_TOOL_ACTIVATED
	MSG_GO_ANOTHER_TOOL_ACTIVATED
	MSG_GO_SPECIAL_RESIZE_CONSTRAIN(
				GrObjHandleSpecification grObjHandleSpec)
	MSG_GO_DUPLICATE_FLOATER
	MSG_GO_GRAB_MOUSE
	MSG_GO_RELEASE_MOUSE
	MSG_GO_UNGROUPABLE
	MSG_GO_GET_BOUNDING_RECTDWFIXED
	MSG_GO_CALC_PARENT_DIMENSIONS
	MSG_GO_INIT_CREATE
	void MSG_GO_NOTIFY_GROBJ_VALID()
	MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE
	MSG_GO_INVERT_GROBJ_SPRITE
	MSG_GO_INVERT_GROBJ_NORMAL_SPRITE
	void MSG_GO_INVALIDATE()
	void MSG_GO_GET_DW_PARENT_BOUNDS(RectDWord *bounds)
	MSG_GO_GET_DWF_PARENT_BOUNDS
	MSG_GO_GET_DWF_SELECTION_HANDLE_BOUNDS_FOR_TRIVIAL_REJECT
	MSG_GO_GET_WWF_PARENT_BOUNDS
	void MSG_GO_GET_WWF_OBJECT_BOUNDS(RectWWFixed *retValue)
	MSG_GO_BECOME_UNEDITABLE
	MSG_GO_EVALUATE_POSITION
	MSG_GO_EVALUATE_PARENT_POINT_FOR_SELECTION
	void MSG_GO_GET_CENTER(PointDWFixed *center)
	void MSG_GO_INIT_TO_DEFAULT_ATTRS()
	MSG_GO_DRAW
	MSG_GO_LARGE_START_SELECT
	MSG_GO_LARGE_START_MOVE_COPY
	MSG_GO_LARGE_END_SELECT
	MSG_GO_LARGE_END_MOVE_COPY
	MSG_GO_LARGE_DRAG_SELECT
	MSG_GO_LARGE_DRAG_MOVE_COPY
	MSG_GO_LARGE_PTR
	MSG_GO_AFTER_ADDED_TO_GROUP
	MSG_GO_BEFORE_REMOVED_FROM_GROUP
	void MSG_GO_AFTER_ADDED_TO_BODY()
	void MSG_GO_BEFORE_REMOVED_FROM_BODY()
	void MSG_GO_SET_AREA_ATTR(
				GrObjBaseAreaAttrElement *attr)
	void MSG_GO_SET_AREA_COLOR(byte red,
				byte green, byte blue)
	void MSG_GO_SET_AREA_MASK(SysDrawMask mask)
	void MSG_GO_SET_AREA_DRAW_MODE(MixMode mode)
	void MSG_GO_SET_TRANSPARENCY(byte transparent)
	void MSG_GO_SET_LINE_ATTR(
				GrObjBaseLineAttrElement *attr)
	void MSG_GO_SET_LINE_COLOR(byte red,
				byte green, byte blue)
	void MSG_GO_SET_LINE_MASK(SystemDrawMask drawMask)
	void MSG_GO_SET_LINE_END(LineEnd end)
	void MSG_GO_SET_LINE_JOIN(LineJoin join)
	void MSG_GO_SET_LINE_STYLE(LineStyle style)
	void MSG_GO_SET_LINE_WIDTH(WWFixed width)
	void MSG_GO_SET_LINE_MITER_LIMIT(WWFixed miterLimit)
	MSG_GO_GET_GROBJ_AREA_TOKEN
	MSG_GO_GET_GROBJ_LINE_TOKEN
	MSG_GO_SET_GROBJ_AREA_TOKEN
	MSG_GO_SET_GROBJ_LINE_TOKEN
	MSG_GO_SUBST_AREA_TOKEN
	MSG_GO_SUBST_LINE_TOKEN
	MSG_GO_GET_ANCHOR_DOCUMENT
	MSG_GO_BECOME_EDITABLE
	MSG_GO_DRAW_EDIT_INDICATOR
	MSG_GO_UNDRAW_EDIT_INDICATOR
	MSG_GO_DRAW_EDIT_INDICATOR_RAW
	MSG_GO_INVERT_EDIT_INDICATOR
	MSG_GO_GROBJ_SPECIFIC_INITIALIZE
	MSG_GO_GROBJ_SPECIFIC_INITIALIZE_WITH_DATA_BLOCK
	MSG_GO_APPLY_ATTRIBUTES_TO_GSTATE
	word MSG_GO_SET_ACTION_NOTIFICATION_OUTPUT(
				optr object, Message messageNumber)
	word MSG_GO_NOTIFY_ACTION(
				GrObjActionNotificationType action)
	void MSG_GO_NUDGE(sword xDistance, sword yDistance)
	void MSG_GO_SET_SIZE(PointWWFixed *size)
	void MSG_GO_SET_POSITION(PointDWFixed *location)
	dword MSG_GO_CHANGE_LOCKS(GrObjLocks setBits,
				GrObjLocks clearBits)
	void MSG_GO_SCALE(GrObjAnchoredScaleData *params)
	void MSG_GO_COMBINE_AREA_NOTIFICATION_DATA(
				Handle change)
	void MSG_GO_COMBINE_GRADIENT_NOTIFICATION_DATA(
				Handle change)
	void MSG_GO_COMBINE_LINE_NOTIFICATION_DATA(
				Handle change)
	void MSG_GO_COMBINE_SELECT_STATE_NOTIFICATION_DATA(
				Handle change)
	void MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA(
				Handle change)
	void MSG_GO_COMBINE_STYLE_NOTIFICATION_DATA(
				Handle change)
	void MSG_GO_COMBINE_STYLE_SHEET_NOTIFICATION_DATA(
				Handle change)
	void MSG_GO_SEND_UI_NOTIFICATION(
			GrObjUINotificationTypes notifications)
	void MSG_GO_SUSPEND_ACTION_NOTIFICATION()
	void MSG_GO_UNSUSPEND_ACTION_NOTIFICATION()
	void MSG_GO_SKEW(GrObjAnchoredSkewData *params)
	void MSG_GO_TRANSFORM(TransMatrix *transformation)
	MSG_GO_COMPLETE_CREATE
	MSG_GO_COMPLETE_TRANSFORM
	MSG_GO_COMPLETE_TRANSLATE
	void MSG_GO_GET_SIZE(GOGetSizeParams *retValue)
	void MSG_GO_GET_POSITION(PointDWFixed *retValue)
	void MSG_GO_INITIALIZE(GrObjInitializeData *data)
	MSG_GO_SCALE_ABOUT_PARENT_LEFT_TOP
	MSG_GO_INSERT_OR_DELETE_SPACE
	MSG_GO_BEGIN_CREATE
	MSG_GO_END_CREATE
	MSG_GO_EVALUATE_PARENT_POINT_FOR_EDIT
	void MSG_GO_CREATE_TRANSFER(GrObjTransferParams *params)
	void MSG_GO_REPLACE_WITH_TRANSFER(
				GrObjTransferParams *params)
	void MSG_GO_WRITE_INSTANCE_TO_TRANSFER(
				GrObjTransferParams *params)
	void MSG_GO_READ_INSTANCE_FROM_TRANSFER(
				GrObjTransferParams *params)
	MSG_GO_GET_POINTER_IMAGE
	MSG_GO_GET_LOCKS
	void MSG_GO_DRAW_FG_AREA(DrawFlags drawFlags,
				GrObjDrawFlags grobjDrawFlags,
				GStateHandle gstate)
	MSG_GO_DRAW_BG_AREA
	void MSG_GO_DRAW_SPRITE_LINE(GStateHandle gstate)
	MSG_GO_DRAW_NORMAL_SPRITE_LINE
	MSG_GO_DO_NOTHING
	MSG_GO_ADD_POTENTIAL_SIZE_TO_BLOCK
	MSG_GO_SUBTRACT_POTENTIAL_SIZE_FROM_BLOCK
	MSG_GO_GET_GROBJ_CLASS
	MSG_GO_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA
	MSG_GO_GENERATE_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA_ACTION
	MSG_GO_GENERATE_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA_CHAIN
	MSG_GO_CLEAR_SANS_UNDO
	MSG_GO_REMOVE_FROM_BODY
	MSG_GO_REMOVE_FROM_GROUP
	MSG_GO_RELEASE_EXCLS
	MSG_GO_GENERATE_UNDO_CLEAR_CHAIN
	MSG_GO_GENERATE_UNDO_UNDO_CLEAR_CHAIN
	MSG_GO_DEREF_A_GROBJ_AREA_TOKEN
	MSG_GO_DEREF_A_GROBJ_LINE_TOKEN
	MSG_GO_INVALIDATE_AREA
	MSG_GO_INVALIDATE_LINE
	MSG_GO_SUSPEND_COMPLETE_CREATE
	MSG_GO_GET_TEMP_STATE_AND_OPT_FLAGS
	MSG_GO_MAKE_INSTRUCTION
	MSG_GO_MAKE_NOT_INSTRUCTION
	MSG_GO_SET_WRAP_TEXT_TYPE
	MSG_GO_SET_PASTE_INSIDE(
	MSG_GO_SET_INSERT_DELETE_MOVE_ALLOWED
	MSG_GO_SET_INSERT_DELETE_RESIZE_ALLOWED
	MSG_GO_SET_INSERT_DELETE_DELETE_ALLOWED
	MSG_GO_DRAW_PARENT_RECT
	MSG_GO_NUKE_DATA_IN_OTHER_BLOCKS
	void MSG_GO_DRAW_FG_AREA_HI_RES(DrawFlags drawFlags,
				GrObjDrawFlags grobjDrawFlags,
				GStateHandle gstate)
	void MSG_GO_DRAW_FG_LINE(DrawFlags drawFlags,
				GrObjDrawFlags grobjDrawFlags,
				GStateHandle gstate)
	void MSG_GO_DRAW_FG_LINE_HI_RES(DrawFlags drawFlags,
				GrObjDrawFlags grobjDrawFlags,
				GStateHandle gstate)
	MSG_GO_DRAW_CLIP_AREA
	MSG_GO_DRAW_CLIP_AREA_HI_RES
	MSG_GO_DRAW_FG_GRADIENT_AREA
	MSG_GO_DRAW_FG_GRADIENT_AREA_HI_RES
	MSG_GO_DRAW_BG_AREA_HI_RES
	MSG_GO_SET_BG_COLOR
	MSG_GO_SET_AREA_PATTERN
	MSG_GO_SET_AREA_ATTR_ELEMENT_TYPE
	MSG_GO_SET_LINE_ATTR_ELEMENT_TYPE
	MSG_GO_SET_STARTING_GRADIENT_COLOR
	MSG_GO_SET_ENDING_GRADIENT_COLOR
	MSG_GO_SET_NUMBER_OF_GRADIENT_INTERVALS
	MSG_GO_SET_GRADIENT_TYPE
	MSG_GO_SET_ARROWHEAD_ON_START
	MSG_GO_SET_ARROWHEAD_ON_END
	MSG_GO_SET_ARROWHEAD_FILLED
	MSG_GO_SET_ARROWHEAD_ANGLE
	MSG_GO_SET_ARROWHEAD_LENGTH
	MSG_GO_NOTIFY_GROBJ_INVALID
	MSG_GO_SET_GROBJ_ATTR_FLAGS
	MSG_GO_SET_SYS_TARGET
	void MSG_GO_SCALE_OBJECT(GrObjAnchoredScaleData *params)
	MSG_GO_GENERATE_UNDO_CLEAR_CHAIN_WITH_ACTION_NOTIFICATION
	MSG_GO_RECREATE_CACHED_GSTATES
	MSG_GO_DRAW_QUICK_VIEW
	MSG_GO_DRAW_SPRITE_LINE_HI_RES
	MSG_GO_DRAW_NORMAL_SPRITE_LINE_HI_RES
	MSG_GO_GET_GROBJ_ATTR_FLAGS
	MSG_GO_MAKE_ATTRS_DEFAULT
	MSG_GO_GET_SITUATIONAL_POINTER_IMAGE
	MSG_GO_OBJ_FREE
	MSG_GO_ADJUST_CREATE
	MSG_GO_GENERATE_UNDO_UNDO_CLEAR_CHAIN_WITH_ACTION_NOTIFICATION
	MSG_GO_NUDGE_INSIDE
	MSG_GO_MOVE_INSIDE
	MSG_GO_REPLACE_GEOMETRY_INSTANCE_DATA
	MSG_GO_CHECK_ACTION_MODES
	MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_RESIZE
	MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_ROTATE
	MSG_GO_COMBINE_LOCKS
	MSG_GO_DESELECT_IF_GROUP_LOCK_SET
	MSG_GO_GET_POTENTIAL_GROBJECT_SIZE
	MSG_GO_GROUP_GAINED_SELECTION_LIST
	MSG_GO_GROUP_LOST_SELECTION_LIST
	MSG_GO_INVALIDATE_WITH_UNDO
	MSG_GO_AFTER_QUICK_PASTE
	MSG_GO_QUICK_TOTAL_BODY_CLEAR

## GrObjConvertControlClass

	@class GrObjConvertControlClass, GenControlClass

**Instance Data**

	@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GOCCFeatures
		GOCCF_CONVERT_TO_BITMAP					0x0004
		GOCCF_CONVERT_TO_GRAPHIC				0x0002
		GOCCF_CONVERT_FROM_GRAPHIC				0x0001
	GROBJ_CONVERT_CONTROL_DEFAULT_FEATURES
							(GOCCF_CONVERT_TO_BITMAP |
							 GOCCF_CONVERT_TO_GRAPHIC |
							 GOCCF_CONVERT_FROM_GRAPHIC)
	GROBJ_CONVERT_CONTROL_DEFAULT_TOOLBOX_FEATURES
							(GOCCF_CONVERT_TO_BITMAP |
							 GOCCF_CONVERT_TO_GRAPHIC |
							 GOCCF_CONVERT_FROM_GRAPHIC)
**Messages**

	MSG_GOCC_CONVERT_TO_BITMAP
	MSG_GOCC_CONVERT_TO_GRAPHIC
	MSG_GOCC_CONVERT_FROM_GRAPHIC

## GrObjCreateControlClass

	@class GrObjCreateControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)
		@default GI_states = (@default | GS_ENABLED)

**Types and Flags**

	ByteFlags		GrObjCreateControlFeatures
		GOCCF_RECTANGLE						0x0200
		GOCCF_ELLIPSE 						0x0100
		GOCCF_LINE 							0x0080
		GOCCF_ROUNDED_RECTANGLE 			0x0040
		GOCCF_ARC 							0x0020
		GOCCF_TRIANGLE 						0x0010
		GOCCF_HEXAGON 						0x0008
		GOCCF_OCTOGON 						0x0004
		GOCCF_FIVE_POINTED_STAR 			0x0002
		GOCCF_EIGHT_POINTED_STAR 			0x0001
	GROBJ_CREATE_CONTROL_DEFAULT_FEATURES 0x03fb
	GROBJ_CREATE_CONTROL_DEFAULT_TOOLBOX_FEATURES 0x03fb

**Messages**

	MSG_GOCC_CREATE_GROBJ
	MSG_GOCC_CREATE_POLYGON
	MSG_GOCC_CREATE_STAR

## GrObjCustomDuplicateControlClass

	@class GrObjCustomDuplicateControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GOCDCFeatures
		GOCDCF_REPETITIONS			0x10
		GOCDCF_MOVE					0x08
		GOCDCF_SCALE				0x04
		GOCDCF_ROTATE				0x02
		GOCDCF_SKEW					0x01
	GOCDC_DEFAULT_FEATURES (GOCDCF_REPETITIONS |
					 GOCDCF_MOVE | GOCDCF_ROTATE |
					 GOCDCF_SCALE)

**Messages**

	MSG_GOCDC_CUSTOM_DUPLICATE

## GrObjCustomShapeControlClass

	@class GrObjCustomShapeControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)
		@default GI_states = (@default | GS_ENABLED)

**Types and Flags**

	ByteFlags		GOCSCFeatures
		GOCSCF_POLYGONS				0x02
		GOCSCF_STARS				0x01
	GOCSC_DEFAULT_FEATURES (GOCSCF_POLYGONS | GOCSCF_STARS)

**Messages**

	MSG_GOCSC_CREATE_POLYGON
	MSG_GOCSC_CREATE_STAR

## GrObjDefaultAttributesControlClass

	@class GrObjDefaultAttributesControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GODACFeatures
		GODACF_SET_DEFAULT_ATTRIBUTES			0x01
	GODAC_DEFAULT_FEATURES (GODACF_SET_DEFAULT_ATTRIBUTES)
	GODAC_DEFAULT_TOOLBOX_FEATURES
							(GODACF_SET_DEFAULT_ATTRIBUTES)

**Messages**

	MSG_GODAC_SET_DEFAULT_ATTRIBUTES

## GrObjDepthControlClass

	@class GrObjDepthControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GODepthCFeatures
		GODepthCF_BRING_TO_FRONT				0x0008
		GODepthCF_SEND_TO_BACK					0x0004
		GODepthCF_SHUFFLE_UP					0x0002
		GODepthCF_SHUFFLE_DOWN					0x0001
	GODepthC_DEFAULT_FEATURES (GODepthCF_BRING_TO_FRONT |
							GODepthCF_SEND_TO_BACK |
							GODepthCF_SHUFFLE_UP |
							GODepthCF_SHUFFLE_DOWN)
	GODepthC_DEFAULT_TOOLBOX_FEATURES
							(GODepthCF_BRING_TO_FRONT |
							 GODepthCF_SEND_TO_BACK |
							 GODepthCF_SHUFFLE_UP |
							 GODepthCF_SHUFFLE_DOWN)

**Messages**

	MSG_GODC_BRING_TO_FRONT
	MSG_GODC_SEND_TO_BACK
	MSG_GODC_SHUFFLE_UP
	MSG_GODC_SHUFFLE_DOWN

## GrObjDraftModeControlClass

	@class GrObjDraftModeControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GODMCFeatures
		GODMCF_DRAFT_MODE				0x01
	GODMC_DEFAULT_FEATURES (GODMCF_DRAFT_MODE)

**Messages**

	MSG_GODMC_SET_DRAFT_MODE_STATUS

## GrObjDuplicateControlClass

	@class GrObjDuplicateControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GrObjDuplicateControlFeatures
		GODCF_DUPLICATE						0x0002
		GODCF_DUPLICATE_IN_PLACE			0x0001
	ByteFlags		GrObjDuplicateControlToolboxFeatures
		GODCTF_DUPLICATE					0x0002
		GODCTF_DUPLICATE_IN_PLACE			0x0001
	GROBJ_DUPLICATE_CONTROL_DEFAULT_FEATURES
					(GODCF_DUPLICATE |
					 GODCF_DUPLICATE_IN_PLACE)
	GROBJ_DUPLICATE_CONTROL_DEFAULT_TOOLBOX_FEATURES
					(GODCTF_DUPLICATE |
					 GODCTF_DUPLICATE_IN_PLACE)

**Messages**

	MSG_GROBJ_DUPLICATE_CONTROL_DUPLICATE
	MSG_GROBJ_DUPLICATE_CONTROL_DUPLICATE_IN_PLACE

## GrObjEndingGradientColorSelectorClass

	@class GrObjEndingGradientColorSelectorClass, ColorSelectorClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)
		@default GI_states = (@default & ~GS_ENABLED)

**Types and Flags**

	GOSGCS_DEFAULT_FEATURES (CSF_INDEX | CSF_RGB)

## GrObjFlipControlClass

	@class GrObjFlipControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GOFCFeatures
		GOFCF_FLIP_HORIZONTALLY		0x02
		GOFCF_FLIP_VERTICALLY		0x01

Messages

	MSG_GOFC_FLIP_HORIZONTALLY
	MSG_GOFC_FLIP_VERTICALLY

## GrObjGradientFillControlClass

	@class GrObjGradientFillControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GrObjGradientFillControlFeatures
		GOGFCF_HORIZONTAL_GRADIENT					0x0010
		GOGFCF_VERTICAL_GRADIENT					0x0008
		GOGFCF_RADIAL_RECT_GRADIENT					0x0004
		GOGFCF_RADIAL_ELLIPSE_GRADIENT				0x0002
		GOGFCF_NUM_INTERVALS						0x0001
	GOGFC_DEFAULT_FEATURES (GOGFCF_HORIZONTAL_GRADIENT |
						GOGFCF_VERTICAL_GRADIENT |
						GOGFCF_RADIAL_RECT_GRADIENT |
						GOGFCF_RADIAL_ELLIPSE_GRADIENT |
						GOGFCF_NUM_INTERVALS)

**Messages**

	MSG_GOGFC_SET_GRADIENT_TYPE
	MSG_GOGFC_SET_NUMBER_OF_GRADIENT_INTERVALS

## GrObjGroupControlClass

	@class GrObjGroupControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET);

**Types and Flags**

	ByteFlags		GOGCFeatures
		GOGCF_GROUP					0x01
		GOGCF_UNGROUP				0x02
	GOGC_DEFAULT_FEATURES (GOGCF_GROUP | GOGCF_UNGROUP)
	GOGC_DEFAULT_TOOLBOX_FEATURES (GOGCF_GROUP |
								 GOGCF_UNGROUP)

**Messages**

	MSG_GOGC_GROUP
	MSG_GOGC_UNGROUP

## GrObjHandleControlClass

	@class GrObjHandleControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)
		@default GI_states = (@default | GS_ENABLED)

**Types and Flags**

	ByteFlags		GOHCFeatures
		GOHCF_SMALL_HANDLES				0x08
		GOHCF_MEDIUM_HANDLES			0x04
		GOHCF_LARGE_HANDLES				0x02
		GOHCF_INVISIBLE_HANDLES			0x01
	GOHC_DEFAULT_FEATURES (GOHCF_SMALL_HANDLES |
						 GOHCF_MEDIUM_HANDLES |
						 GOHCF_LARGE_HANDLES |
						 GOHCF_INVISIBLE_HANDLES)
	GOHC_DEFAULT_TOOLBOX_FEATURES 0

**Messages**

	MSG_GOHC_SET_HANDLES

## GrObjHeadClass

	@class GrObjHeadClass, MetaClass

**Instance Data**

	ClassStruct		*GH_currentTool = NullClass
	word 			GH_initializeFloaterData = 0
	optr 			GH_currentBody
	optr 			GH_floater

**Structures**

	typedef struct {
		word 				CTV_grObjSpecificData
		word 				CTV_unused
		ClassStruct 		*CTV_toolClass
	} CurrentToolValues

**Messages**

	void MSG_GH_SET_CURRENT_TOOL(ClassStruct *toolClass,
				word initData)
	void MSG_GH_SET_CURRENT_TOOL_WITH_DATA_BLOCK(
				ClassStruct *toolClass,
				word initData)
	MSG_GH_SET_CURRENT_BODY
	MSG_GH_CLEAR_CURRENT_BODY
	MSG_GH_CLASSED_EVENT_TO_FLOATER
	MSG_GH_CLASSED_EVENT_TO_FLOATER_IF_CURRENT_BODY
	MSG_GH_FLOATER_FINISHED_CREATE
	void MSG_GH_GET_CURRENT_TOOL(CurrentToolValues *retVal)
	MSG_GH_SEND_NOTIFY_CURRENT_TOOL
	MSG_GH_CALL_FLOATER
	MSG_GH_SET_TEXT_TOOL_FOR_SEARCH_SPELL

## GrObjHideShowControlClass

	@class GrObjHideShowControlClass, GenControlClass;

**Instance Data**

		@default			GCI_output = (TO_APP_TARGET)
		@default			GI_states = (@default | GS_ENABLED)

**Types and Flags**

	ByteFlags		GOHSCFeatures
		GOHSCF_HIDE				0x02
		GOHSCF_SHOW				0x01
	GOHSC_DEFAULT_FEATURES (GOHSCF_HIDE | GOHSCF_SHOW)

**Messages**

	MSG_GOHSC_HIDE
	MSG_GOHSC_SHOW

## GrObjInstructionControlClass

	@class GrObjInstructionControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GrObjInstructionControlFeatures
		GOICF_DRAW 						0x8000
		GOICF_PRINT 					0x4000
		GOICF_MAKE_EDITABLE 			0x2000
		GOICF_MAKE_UNEDITABLE 			0x1000
		GOICF_DELETE 					0x0800
	GOICF_DEFAULT_FEATURES (GOICF_DRAW | GOICF_PRINT |
							GOICF_MAKE_EDITABLE |
							GOICF_MAKE_UNEDITABLE |
							GOICF_DELETE)

**Messages**

	MSG_GOIC_MAKE_INSTRUCTIONS_EDITABLE
	MSG_GOIC_MAKE_INSTRUCTIONS_UNEDITABLE
	MSG_GOIC_DELETE_INSTRUCTIONS
	MSG_GOIC_SET_INSTRUCTION_ATTRS

## GrObjLineAttrControlClass

	@class GrObjLineAttrControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)
		@default GI_states = (@default | GS_ENABLED)

**Types and Flags**

	WordFlags		GOLACFeatures
		GOLACF_WIDTH_INDEX 					0x0010
		GOLACF_WIDTH_VALUE 					0x0008
		GOLACF_STYLE 						0x0004
		GOLACF_ARROWHEAD_TYPE 				0x0002
		GOLACF_ARROWHEAD_WHICH_END 			0x0001
	GOLAC_DEFAULT_FEATURES (GOLACF_WIDTH_INDEX |
						GOLACF_WIDTH_VALUE |
						GOLACF_STYLE |
						GOLACF_ARROWHEAD_TYPE |
						GOLACF_ARROWHEAD_WHICH_END)
	WordFlags		GOLACToolboxFeatures
		GOLACTF_WIDTH_INDEX 			0x0002
		GOLACTF_STYLE 					0x0001
	GOLAC_DEFAULT_TOOLBOX_FEATURES (GOLACTF_WIDTH_INDEX |
								GOLACF_STYLE)

**Messages**

	MSG_GOLAC_SET_LINE_VALUE_FROM_INDEX
	MSG_GOLAC_SET_LINE_INDEX_FROM_VALUE
	MSG_GOLAC_SET_INTEGER_LINE_WIDTH
	MSG_GOLAC_SET_LINE_WIDTH
	MSG_GOLAC_SET_LINE_STYLE
	MSG_GOLAC_SET_ARROWHEAD_TYPE
	MSG_GOLAC_SET_ARROWHEAD_WHICH_END

## GrObjLineColorSelectorClass

	@class GrObjLineColorSelectorClass, ColorSelectorClass

**Instance Data**

		@default		GCI_output = (TO_APP_TARGET)
		@default		GI_states = (@default | GS_ENABLED)
		@default		CSI_toolboxPrefs = @default |
						(COO_LINE_ORIENTED <<
						CTP_INDEX_ORIENTATION_OFFSET) |
						(COO_LINE_ORIENTED <<
						CTP_DRAW_MASK_ORIENTATION_OFFSET)

**Types and Flags**

	GOLCS_DEFAULT_FEATURES (CSF_INDEX | CSF_RGB |
						CSF_DRAW_MASK | CSF_PATTERN)

## GrObjLocksControlClass

	@class GrObjLocksControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	GOLC_DEFAULT_FEATURES (GOL_MOVE | GOL_RESIZE |
						 GOL_ROTATE)
	GOLC_DEFAULT_TOOLBOX_FEATURES 0

Messages

	MSG_GOLC_CHANGE_LOCKS

## GrObjMoveInsideControlClass

	@class GrObjMoveInsideControlClass, GrObjNudgeControlClass

## GrObjNudgeControlClass

	@class GrObjNudgeControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GONCFeatures
		GONCF_NUDGE_LEFT 					0x10
		GONCF_NUDGE_RIGHT					0x08
		GONCF_NUDGE_UP						0x04
		GONCF_NUDGE_DOWN					0x02
		GONCF_CUSTOM_MOVE					0x01
	GROBJ_NUDGE_CONTROL_DEFAULT_FEATURES (GONCF_NUDGE_LEFT |
									GONCF_NUDGE_RIGHT |
									GONCF_NUDGE_UP |
									GONCF_NUDGE_DOWN |
									GONCF_CUSTOM_MOVE)

**Messages**

	MSG_GONC_NUDGE
	MSG_GONC_CUSTOM_MOVE
	MSG_GONC_SET_DISPLAY_FORMAT

## GrObjObscureAttrControlClass

	@class GrObjObscureAttrControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)
		@default GI_states = (@default | GS_ENABLED)

**Types and Flags**

	ByteFlags		GrObjObscureAttrControlFeatures
		GOOACF_INSTRUCTIONS 					0x80
		GOOACF_INSERT_OR_DELETE_MOVE 			0x40
		GOOACF_INSERT_OR_DELETE_RESIZE 			0x20
		GOOACF_INSERT_OR_DELETE_DELETE 			0x10
		GOOACF_DONT_WRAP 						0x08
		GOOACF_WRAP_INSIDE 						0x04
		GOOACF_WRAP_AROUND_RECT 				0x02
		GOOACF_WRAP_TIGHTLY 					0x01
	GOOAC_INSERT_OR_DELETE_FEATURES
						(GOOACF_INSERT_OR_DELETE_MOVE |
						 GOOACF_INSERT_OR_DELETE_RESIZE |
						 GOOACF_INSERT_OR_DELETE_DELETE)
	GOOAC_WRAP_FEATURES (GOOACF_DONT_WRAP |
						 GOOACF_WRAP_INSIDE |
						 GOOACF_WRAP_AROUND_RECT |
						 GOOACF_WRAP_TIGHTLY)
	GOOAC_DEFAULT_FEATURES (GOOACF_INSTRUCTIONS |
						 GOOAC_WRAP_FEATURES |
						 GOOAC_INSERT_OR_DELETE_FEATURES)

**Messages**

	MSG_GOOAC_SET_WRAP_TEXT_TYPE
	MSG_GOOAC_CHANGE_OBSCURE_ATTRS

## GrObjPasteInsideControlClass

	@class GrObjPasteInsideControlClass, GenControlClass

**Instance Data**

	word		GPICI_lastNumSelected = 0
		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GOPICFeatures
		GOPICF_PASTE_INSIDE 					0x0002
		GOPICF_BREAKOUT_PASTE_INSIDE 			0x0001
	ByteFlags		GOPICToolboxFeatures
		GOPICTF_PASTE_INSIDE 					0x0002
		GOPICTF_BREAKOUT_PASTE_INSIDE 			0x0001
	GOPIC_DEFAULT_FEATURES (GOPICF_PASTE_INSIDE |
						 GOPICF_BREAKOUT_PASTE_INSIDE)
	GOPIC_DEFAULT_TOOLBOX_FEATURES (GOPICTF_PASTE_INSIDE |
						GOPICTF_BREAKOUT_PASTE_INSIDE)

**Messages**

	MSG_GOPIC_PASTE_INSIDE
	MSG_GOPIC_BREAKOUT_PASTE_INSIDE

## GrObjRotateControlClass

	@class GrObjRotateControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GORCFeatures
		GORCF_45_DEGREES_CW 					0x0080
		GORCF_90_DEGREES_CW 					0x0040
		GORCF_135_DEGREES_CW 					0x0020
		GORCF_180_DEGREES 						0x0010
		GORCF_135_DEGREES_CCW 					0x0008
		GORCF_90_DEGREES_CCW 					0x0004
		GORCF_45_DEGREES_CCW 					0x0002
		GORCF_CUSTOM_ROTATION 					0x0001
	GORC_DEFAULT_FEATURES				0x00ff

**Messages**

	MSG_GORC_ROTATE
	MSG_GORC_CUSTOM_ROTATE

## GrObjScaleControlClass

	@class GrObjScaleControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GrObjScaleControlFeatures
		GOSCF_HALF_WIDTH 					0x0010
		GOSCF_HALF_HEIGHT 					0x0008
		GOSCF_DOUBLE_WIDTH 					0x0004
		GOSCF_DOUBLE_HEIGHT 				0x0002
		GOSCF_CUSTOM_SCALE 					0x0001
	GROBJ_SCALE_CONTROL_DEFAULT_FEATURES 0x001f

**Messages**

	MSG_GOSC_SCALE_HORIZONTALLY
	MSG_GOSC_SCALE_VERTICALLY
	MSG_GOSC_CUSTOM_SCALE

## GrObjSkewControlClass

	@class GrObjSkewControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GrObjSkewControlFeatures
		GOSCF_LEFT 					0x0010
		GOSCF_RIGHT 				0x0008
		GOSCF_UP 					0x0004
		GOSCF_DOWN 					0x0002
		GOSCF_CUSTOM_SKEW 			0x0001
	GROBJ_SKEW_CONTROL_DEFAULT_FEATURES 0x001f

**Messages**

	MSG_GOSC_SKEW_HORIZONTALLY
	MSG_GOSC_SKEW_VERTICALLY
	void MSG_GOSC_CUSTOM_SKEW

## GrObjSplineClass

	@class GrObjSplineClass, GrObjVisClass

## GrObjStartingGradientColorSelectorClass

	@class GrObjStartingGradientColorSelectorClass, ColorSelectorClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)
		@default GI_states = (@default & ~GS_ENABLED)

**Types and Flags**

	GOSGCS_DEFAULT_FEATURES (CSF_INDEX | CSF_RGB)

## GrObjStyleSheetControlClass

	@class GrObjStyleSheetControlClass, StyleSheetControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)
		@default GI_states = (@default & ~GS_ENABLED)
		@default SSCI_targetClass = (ClassStruct *)&GrObjBodyClass
		@default SSCI_styledClass = (ClassStruct *)&GrObjClass

## GrObjTextClass

	@class GrObjTextClass, GrObjVisClass;

**Messages**

	MSG_GT_ADJUST_MARGINS_FOR_LINE_WIDTH

## GrObjToolControlClass

	@class GrObjToolControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Variable Data**

	word ATTR_GROBJ_TOOL_CONTROL_POSITION_FOR_ADDED_TOOLS

**Types and Flags**

	WordFlags		GOTCFeatures
		GOTCF_PTR 					0x0800
		GOTCF_ROTATE_PTR 			0x0400
		GOTCF_ZOOM 					0x0200
		GOTCF_TEXT 					0x0100
		GOTCF_LINE 					0x0080
		GOTCF_RECT 					0x0040
		GOTCF_ROUNDED_RECT 			0x0020
		GOTCF_ELLIPSE 				0x0010
		GOTCF_ARC 					0x0008
		GOTCF_POLYLINE 				0x0004
		GOTCF_POLYCURVE 			0x0002
		GOTCF_SPLINE 				0x0001
	GOTC_DEFAULT_FEATURES (GOTCF_PTR |
					 GOTCF_ROTATE_PTR |
					 GOTCF_ZOOM | GOTCF_TEXT |
					 GOTCF_LINE | GOTCF_RECT |
					 GOTCF_ROUNDED_RECT |
					 GOTCF_ELLIPSE | GOTCF_ARC |
					 GOTCF_POLYLINE |
					 GOTCF_POLYCURVE |
					 GOTCF_SPLINE)
	GOTC_DEFAULT_TOOLBOX_FEATURES (GOTC_DEFAULT_FEATURES)

**Messages**

	MSG_GOTC_SET_TOOL

## GrObjToolItemClass

	@class GrObjToolItemClass, GenItemClass

**Instance Data**

	ClassStruct		*GOTII_toolClass = NullClass
	word 			GOTII_specInitData = 0

**Messages**

	MSG_GOTI_GET_TOOL_CLASS
	MSG_GOTI_SELECT_SELF_IF_MATCH

## GrObjTransformControlClass

	@class GrObjTransformControlClass, GenControlClass

**Instance Data**

		@default GCI_output = (TO_APP_TARGET)

**Types and Flags**

	ByteFlags		GOTransformCFeatures
		GOTCF_UNTRANSFORM 					0x8000
	GOTransformC_DEFAULT_FEATURES (GOTCF_UNTRANSFORM)

**Messages**

	MSG_GOTC_UNTRANSFORM

## GrObjVisClass

	@class GrObjVisClass, VisClass, master, variant

**Instance Data**

	optr 		GVI_guardian

**Messages**

	MSG_GV_GET_WWFIXED_CENTER
	MSG_GV_SET_GUARDIAN_LINK
	MSG_GV_SET_VIS_BOUNDS
	MSG_GV_GET_GROBJ_VIS_CLASS
	MSG_GV_SET_REALIZED_AND_UPWARD_LINK
	MSG_GV_CLEAR_REALIZED_AND_UPWARD_LINK
	MSG_GV_GET_GUARDIAN
	MSG_GV_GET_POTENTIAL_WARD_SIZE

## GrObjVisGuardianClass

	@class GrObjVisGuardianClass, GrObjClass

**Instance Data**

	optr						GOVGI_ward
	word						*GOVGI_class
	GrObjVisGuardianFlags		GOVGI_flags

**Types and Flags**

	ByteFlags		GrObjVisGuardianFlags
		GOVGF_VIS_BOUNDS_HAVE_CHANGED 			0x80
		GOVGF_LARGE 							0x40
		GOVGF_GUARDIAN_INITIATED_TRANSFORM 		0x20
		GOVGF_IGNORE_WARD_CHANGE_BOUNDS 		0x10
		GOVGF_APPLY_OBJECT_TO_VIS_TRANSFORM 	0x08
		GOVGF_CAN_EDIT_EXISTING_OBJECTS 		0x04
		GOVGF_CREATE_MODE 						0x03

**Messages**

	MSG_GOVG_UPDATE_VIS_WARD_WITH_STORED_DATA
	MSG_GOVG_CONVERT_LARGE_MOUSE_DATA
	optr MSG_GOVG_CREATE_VIS_WARD(MemHandle wardBlock)
	MSG_GOVG_ADD_VIS_WARD
	MSG_GOVG_APPLY_OBJECT_TO_VIS_TRANSFORM
	MSG_GOVG_CREATE_GSTATE
	MSG_GOVG_VIS_BOUNDS_SETUP
	MSG_GOVG_SET_VIS_WARD_MOUSE_EVENT_TYPE
	MSG_GOVG_UPDATE_EDIT_GRAB_WITH_STORED_DATA
	MSG_GOVG_NORMALIZE
	MSG_GOVG_NOTIFY_VIS_WARD_CHANGE_BOUNDS
	MSG_GOVG_GET_EDIT_CLASS
	optr MSG_GOVG_GET_VIS_WARD_OD()
	MSG_GOVG_GET_TRANSFER_BLOCK_FROM_VIS_WARD
	MSG_GOVG_CREATE_WARD_WITH_TRANSFER
	MSG_GOVG_SET_VIS_WARD_CLASS
	MSG_GOVG_APPLY_SPRITE_OBJECT_TO_VIS_TRANSFORM
	MSG_GOVG_CHECK_FOR_EDIT_WITH_FIRST_START_SELECT
	MSG_GOVG_RULE_LARGE_START_SELECT_FOR_WARD
	MSG_GOVG_RULE_LARGE_PTR_FOR_WARD
	MSG_GOVG_RULE_LARGE_END_SELECT_FOR_WARD

## GroupClass

	@class GroupClass, GrObjClass

**Instance Data**

	CompPart 				GI_drawHead
	word 					GI_suspendCount
	GroupUnsuspendOps 		GI_unsuspendOps

**Types and Flags**

	ByteFlags 		GroupUnsuspendOps
		GUO_EXPAND			0x01

**Messages**

	MSG_GROUP_ADD_GROBJ
	MSG_GROUP_REMOVE_GROBJ
	MSG_GROUP_CREATE_GSTATE
	MSG_GROUP_PROCESS_ALL_GROBJS_SEND_CALL_BACK_MESSAGE
	MSG_GROUP_INITIALIZE
	MSG_GROUP_EXPAND
	optr MSG_GROUP_INSTANTIATE_GROBJ(ClassStruct *class)
	MSG_GROUP_SET_HAS_PASTE_INSIDE_CHILDREN
	MSG_GROUP_PASTE_CALL_BACK_FOR_PASTE_INSIDE
	MSG_GROUP_CREATE_GSTATE_FOR_BOUNDS_CALC
	MSG_GROUP_VIS_TEXT_GENERATE_NOTIFY
	MSG_GROUP_CHECK_FOR_GROBJ_TEXTS

## GStringClass

	@class GStringClass, GrObjClass

**Instance Data**

	word 				GSI_vmemBlockHandle
	PointWWFixed 		GSI_gstringCenterTrans

**Messages**

	void MSG_GSO_SET_GSTRING()

## HelpControlClass

	@class HelpControlClass, GenControlClass

**Instance Data**

	HelpType 			HCI_helpType
	MemHandle 			HCI_curFile
	MemHandle 			HCI_historyBuf
	word 				HCI_nameArrayVM
	GeodeHandle 		HCI_compressLib
		@default GII_attrs = (@default |
							GIA_NOT_USER_INITIATABLE)
		@default GII_visibility = GIV_DIALOG

**Variable Data**

	void ATTR_HELP_SUPPRESS_INITIATE
	char[] ATTR_HELP_INITIAL_HELP
	optr ATTR_HELP_CUSTOM_POINTER_IMAGE

**Hints**

	CompSizeHintArgs HINT_HELP_TEXT_FIXED_SIZE

**Types and Flags**

	ByteEnum		HelpType
		HT_NORMAL_HELP 					0
		HT_FIRST_AID 					1
		HT_STATUS_HELP 					2
		HT_SIMPLE_HELP 					3
		HT_SYSTEM_HELP 					4
	WordFlags		HPCFeatures
		HPCF_HELP 						0x0100
		HPCF_TEXT 						0x0080
		HPCF_CONTENTS 					0x0040
		HPCF_HISTORY 					0x0020
		HPCF_GO_BACK 					0x0010
		HPCF_CLOSE 						0x0008
		HPCF_INSTRUCTIONS 				0x0004
		HPCF_FIRST_AID_GO_BACK 			0x0002
		HPCF_FIRST_AID 					0x0001
	MAX_CONTEXT_NAME_SIZE 				20
	typedef char 			ContextName[MAX_CONTEXT_NAME_SIZE]

**Structures**

	typedef struct {
		HelpType 				NHCC_type
		ContextName 			NHCC_context
		FileLongName 			NHCC_filename
		FileLongName 			NHCC_filenameTOC
	} NotifyHelpContextChange

**Messages**

	MSG_HELP_CONTROL_FOLLOW_LINK
	MSG_HELP_CONTROL_GET_POINTER_IMAGE

**Routines**

	void HelpSendHelpNotification(
					word HelpType,
					const char *contextname,
					const char *filename)

## ImpexMapControlClass

	@class ImpexMapControlClass, GenControlClass

**Instance Data**

	word 				IMCI_dataBlock1
	word 				IMCI_dataBlock2
	word 				IMCI_childBlock
	word 				IMCI_mapListBlock
	ImpexMapFlags 		IMCI_flags

**Types and Flags**

	SOURCE 						0
	DESTINATION 				1
	ByteFlags		IMCFeatures
		IMCF_MAP 				0x01
	IMC_DEFAULT_FEATURES 		(IMCF_MAP)
	IMC_DEFAULT_TOOLBOX_FEATURES 0
	IMC_MAP_MONIKER_SIZE 		1024
	ByteFlags		ImpexMapFlags
		IMF_IMPORT 				0x80
		IMF_EXPORT 				0x40
	ByteEnum		DefaultFieldNameUsage
		DFNU_FIELD 				0
		DFNU_COLUMN 			1
		DFNU_FIXED 				2

**Structures**

	typedef struct {
		LMemBlockHeader 		IMFIH_base
		word 					IMFIH_fieldChunk
		word 					IMFIH_numFields
		DefaultFieldNameUsage 	IMFIH_flag
	} ImpexMapFileInfoHeader
	typedef struct {
		LMemBlockHeader 		MLBH_base
		word 					MLBH_numDestFields
		word 					MLBH_chunk1
	} MapListBlockHeader
	typedef struct {
		word 		CML_source
		word 		CML_dest
	} ChunkMapList

## ImportControlClass

	@class ImportControlClass, ImportExportClass

**Instance Data**

	ImportControlAttrs 		ICI_attrs
	ImpexDataClasses 		ICI_dataClasses
	optr 					ICI_destination
	word 					ICI_message

**Variable Data**

	optr ATTR_IMPORT_CONTROL_APP_UI
		@reloc ATTR_IMPORT_CONTROL_APP_UI, 0, optr
	optr ATTR_IMPORT_CONTROL_CANCEL_DESTINATION
		@reloc ATTR_IMPORT_CONTROL_CANCEL_DESTINATION, 0, optr
	word ATTR_IMPORT_CONTROL_CANCEL_MESSAGE

**Types and Flags**

	WordFlags		ImportControlAttrs
		ICA_IGNORE_INPUT 					0x8000
	ByteFlags		ImportControlFeatures
		IMPORTCF_PREVIEW_TRIGGER 			0x0020
		IMPORTCF_IMPORT_TRIGGER 			0x0010
		IMPORTCF_FORMAT_OPTIONS 			0x0008
		IMPORTCF_FILE_MASK 					0x0004
		IMPORTCF_BASIC 						0x0002
		IMPORTCF_GLYPH 						0x0001
	IMPORTC_DEFAULT_FEATURES (IMPORTCF_GLYPH |
							IMPORTCF_BASIC | IMPORTCF_FILE_MASK
							| IMPORTCF_FORMAT_OPTIONS |
							IMPORTCF_IMPORT_TRIGGER)
	ByteFlags 	ImportControlToolboxFeatures
		IMPORTCTF_DIALOG_BOX 				0x01
	IMPORTC_DEFAULT_TOOLBOX_FEATURES (IMPORTCTF_DIALOG_BOX)

**Structures**

	typedef struct {
		int 		notUsed
		word 		message
		optr 		destOD
	} ObjectState

**Messages**

	void MSG_IMPORT_CONTROL_SET_DATA_CLASSES(
				ImpexDataClasses dataClasses)
	ImpexDataClasses MSG_IMPORT_CONTROL_GET_DATA_CLASSES()
	void MSG_IMPORT_CONTROL_SET_ACTION(
				optr destOD, word ICImsg)
	void MSG_IMPORT_CONTROL_SET_MSG(word ECImsg)
	void MSG_IMPORT_CONTROL_GET_ACTION(
				ObjectState *retValue)
	void MSG_IMPORT_CONTROL_SET_ATTRS(
				ImportControlAttrs attrs)
	ImportControlAttrs MSG_IMPORT_CONTROL_GET_ATTRS()
	word MSG_IMPORT_CONTROL_GET_FILE_SELECTOR_OFFSET(
				ImportControlFeatures features)
	word MSG_IMPORT_CONTROL_GET_FORMAT_LIST_OFFSET(
				ImportControlFeatures features)
	word MSG_IMPORT_CONTROL_GET_FILE_MASK_OFFSET(
				ImportControlFeatures features)
	word MSG_IMPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET(
				ImportControlFeatures features)
	word MSG_IMPORT_CONTROL_GET_APP_UI_PARENT_OFFSET(
				ImportControlFeatures features)
	word MSG_IMPORT_CONTROL_GET_IMPORT_TRIGGER_OFFSET(
				ImportControlFeatures features)
	void MSG_IMPORT_CONTROL_IMPORT_COMPLETE(
				ImpexTranslationParams *itParams)

## ImportExportClass

	@class ImportExportClass, GenControlClass, master, variant

**Instance Data**

		@default ImportExport = GenControlClass
		@default GII_attrs = GIA_MODAL
		@default GII_type = GIT_COMMAND
		@default GII_visibility = GIV_DIALOG
		@default GI_states = (GS_USABLE|GS_ENABLED)

**Variable Data**

	TempImportExportData TEMP_IMPORT_EXPORT_DATA

**Types and Flags**

	WordFlags		ImpexDataClasses
		IDC_TEXT					0x8000
		IDC_GRAPHICS				0x4000
		IDC_SPREADSHEET 			0x2000
		IDC_FONT 					0x1000
	NUMBER_IMPEX_DATA_CLASSES 		4
	XLAT_TOKEN_TEXT_12 				( 'T' | ('L' << 8) )
	XLAT_TOKEN_TEXT_34 				( 'T' | ('X' << 8) )
	XLAT_TOKEN_GRAPHICS_12 			( 'T' | ('L' << 8) )
	XLAT_TOKEN_GRAPHICS_34 			( 'G' | ('R' << 8) )
	XLAT_TOKEN_SPREADSHEET_12 		( 'T' | ('L' << 8) )
	XLAT_TOKEN_SPREADSHEET_34 		( 'S' | ('S' << 8) )
	XLAT_TOKEN_FONT_12 				( 'T' | ('L' << 8) )
	XLAT_TOKEN_FONT_34 				( 'F' | ('N' << 8) )

**Structures**

	typedef struct {
		FileLongName 				IFSD_selection
		PathName 					IFSD_path
		word 						IFSD_disk
		GenFileSelectorEntryFlags 	IFSD_type
	} ImpexFileSelectionData
	typedef struct {
		optr 			TIED_formatUI
		Handle 			TIED_formatLibrary
	} TempImportExportData

## InkClass

	@class InkClass, VisClass

**Instance Data**

	InkFlags		II_flags = IF_HAS_UNDO
	InkTool			II_tool = 0
	Color			II_penColor = 0
	MemHandle		II_segments = NullHandle
	optr			II_dirtyAD = NullOptr
	Message			II_dirtyMsg
	Rectangle		II_selectBounds
	GStateHandle	II_cachedGState
	TimerHandle		II_antTimer
	word			II_antTimerID
	byte			II_antMask

**Variable Data**

	InkStrokeSize ATTR_INK_STROKE_SIZE

**Types and Flags**

	WordFlags		InkFlags
		IF_MOUSE_FLAGS				0x8000
		IF_SELECTING				0x4000
		IF_HAS_TARGET				0x2000
		IF_HAS_SYS_TARGET			0x1000
		IF_DIRTY					0x0800
		IF_ONLY_CHILD_OF_CONTENT	0x0400
		IF_CONTROLLED				0x0200
		IF_INVALIDATE_ERASURES		0x0100
		IF_HAS_UNDO					0x0080
	typedef enum /* word */ {
		IT_PENCIL = 			0,
		IT_ERASER =				2,
		IT_SELECTOR =			4
	} InkTool

**Structures**

	typedef struct {
		Rectangle			IDBF_bounds
		VMFileHandle 		IDBF_VMFile
		DBGroupAndItem 		IDBF_DBGroupAndItem
		word 				IDBF_DBExtra
	} InkDBFrame
	typedef struct {
		word 		DBR_group
		word 		DBR_item
		word 		unused1
		word 		unused2
	} DBReturn
	typedef struct {
		byte		ISS_width
		byte		ISS_height
	} InkStrokeSize

**Messages**

	void MSG_INK_SAVE_TO_DB_ITEM(
				DBReturn *RetValue, InkDBFrame *ptr)
	void MSG_INK_LOAD_FROM_DB_ITEM(InkDBFrame *ptr)
	void MSG_INK_UNDO()
	void MSG_INK_SET_TOOL(InkTool tool)
	InkTool MSG_INK_GET_TOOL()
	void MSG_INK_SET_PEN_COLOR(Color clr)
	void MSG_INK_SET_DIRTY_AD(word method, optr object)
	void MSG_INK_SET_FLAGS(InkFlags setflags,
				InkFlags clearflags)
	InkFlags MSG_INK_GET_FLAGS()
	void MSG_INK_SET_STROKE_SIZE(byte width, byte height)

**Related Routines**

	void _pascal InkDBInit(VMFileHandle fh)
	dword _pascal InkDBGetHeadFolder(VMFileHandle fh)
	void _pascal InkDBGetDisplayInfo(
				InkDBDisplayInfo *RetValue,
				VMFileHandle fh)
	void _pascal InkDBSetDisplayInfo(VMFileHandle fh,
				dword ofh, dword note, word page)
	void _pascal InkSetDocPageInfo(PageSizeReport *psr,
				VMFileHandle fh)
	void _pascal InkGetDocPageInfo(PageSizeReport *psr,
				VMFileHandle fh)
	void _pascal InkSetDocGString(VMFileHandle dbfh,
				word type)
	word _pascal InkGetDocGString(VMFileHandle dbfh)
	void _pascal InkSetDocCustomGString(VMFileHandle dbfh,
				Handle gh)
	Handle _pascal InkGetDocCustomGString(VMFileHandle dbfh)
	void _pascal InkSendTitleToTextObject(dword tag,
				VMFileHandle fh, optr to)
	word _pascal InkGetTitle(dword tag, VMFileHandle fh,
				char *dest)
	dword _pascal InkGetParentFolder(dword tag,
				VMFileHandle fh)
	void _pascal InkFolderSetTitleFromTextObject(dword fldr,
				VMFileHandle fh, optr text)
	void _pascal InkNoteSetTitleFromTextObject(dword note,
				VMFileHandle fh, optr text)
	dword _pascal InkFolderGetContents(dword tag,
				VMFileHandle fh,
				DBGroupAndItem *subFolders)
	dword _pascal InkFolderGetNumChildren(dword fldr,
				VMFileHandle fh)
	void _pascal InkFolderDisplayChildInList(dword fldr,
				VMFileHandle fh, optr list,
				word entry, Boolean displayFolders)
	Boolean _pascal InkFolderGetChildInfo(dword fldr,
				VMFileHandle fh, word child,
				dword *childID)
	word _pascal InkFolderGetChildNumber(dword fldr,
				VMFileHandle fh, dword note)
	dword _pascal InkFolderCreateSubFolder(dword tag,
				VMFileHandle fh)
	void _pascal InkFolderMove(dword fldr, dword pfldr)
	void _pascal InkFolderDelete(dword tag, VMFileHandle fh)
	word _pascal InkFolderDepthFirstTraverse(dword rfldr,
				VMFileHandle fh,
				PCB(Boolean, callback, (dword fldr,
					VMFileHandle fh, word *info)),
				word *info)
	dword _pascal InkNoteCreate(dword tag, VMFileHandle fh)
	void _pascal InkNoteCopyMoniker(dword title, optr list,
				word type, word entry)
	dword _pascal InkNoteGetPages(dword tag,
				VMFileHandle fh)
	word _pascal InkNoteGetNumPages(dword item)
	word _pascal InkNoteCreatePage(dword tag,
				VMFileHandle fh, word page)
	void _pascal InkNoteLoadPage(dword tag, VMFileHandle fh,
				word page, optr obj, word type)
	void _pascal InkNoteSavePage(dword tag, VMFileHandle fh,
				word page, optr obj, word type)
	void _pascal InkNoteSetKeywordsFromTextObject(dword tag,
				VMFileHandle fh, optr text)
	void _pascal InkNoteSetKeywords(dword tag,
				VMFileHandle fh, const char *text)
	word _pascal InkNoteGetKeywords(dword tag,
				VMFileHandle fh, char *text)
	void _pascal InkNoteSendKeywordsToTextObject(dword tag,
				VMFileHandle fh, optr text)
	void _pascal InkNoteDelete(dword tag, VMFileHandle fh)
	void _pascal InkNoteMove(dword tag, dword pfoldr,
				VMFileHandle fh)
	void _pascal InkNoteSetModificationDate(word tdft1,
				word tdft2, dword note,
				VMFileHandle fh)
	dword _pascal InkNoteGetModificationDate(dword note,
				VMFileHandle fh)
	dword _pascal InkNoteGetCreationDate(dword note,
				VMFileHandle fh)
	NoteType _pascal InkNoteGetNoteType(dword note,
				VMFileHandle fh)
	void _pascal InkNoteSetNoteType(dword note,
				VMFileHandle fh, NoteType nt)
	word _pascal InkNoteFindByTitle(char *string, byte opt,
				Boolean body, VMFileHandle fh)
	word _pascal InkNoteFindByKeywords(VMFileHandle fh,
				const char *strings,word opt)

## InkControlClass

	@class InkControlClass, GenControlClass

**Instance Data**

		@default GCI_output = TO_APP_TARGET

**Types and Flags**

	ByteFlags		InkControlFeatures
		ICF_PENCIL_TOOL					0x04
		ICF_ERASER_TOOL					0x02
		ICF_SELECTION_TOOL				0x01
	ByteFlags		InkControlToolboxFeatures
		ICTF_PENCIL_TOOL				0x04
		ICTF_ERASER_TOOL				0x02
		ICTF_SELECTION_TOOL				0x01
	IC_DEFAULT_FEATURES (ICF_PENCIL_TOOL |
					ICF_ERASER_TOOL | ICF_SELECTION_TOOL)
	IC_DEFAULT_TOOLBOX_FEATURES (ICTF_PENCIL_TOOL |
					ICTF_ERASER_TOOL | ICTF_SELECTION_TOOL)

**Structures**

	typedef struct {
		optr		NIHT_optr
	} NotifyInkHasTarget

**Messages**

	void MSG_IC_SET_TOOL_FROM_LIST()

## LineClass

	@class LineClass, GrObjClass

## MetaClass

	@class MetaClass, meta

**Instance Data**

	MetaBase		MI_base

**Variable Data**

	TempMetaGCNData TEMP_META_GCN
	ChunkHandle TEMP_META_QUIT_LIST
	DetachDataEntry DETACH_DATA
	word TEMP_EC_IN_USE_COUNT
	word TEMP_EC_INTERACTIBLE_COUNT

**Types and Flags**

	PTR_LEAVE_LEFT			0x01
	PTR_LEAVE_TOP			0x02
	PTR_LEAVE_RIGHT			0x04
	PTR_LEAVE_BOTTOM		0x08
	typedef enum /* word */ {
		QL_BEFORE_UI,
		QL_UI,
		QL_AFTER_UI,
		QL_DETACH,
		QL_AFTER_DETACH
	} QuitLevel
	typedef enum {
		TO_NULL,
		TO_SELF,
		TO_OBJ_BLOCK_OUTPUT,
		TO_PROCESS
	} TravelOption
	WordFlags		GCNListTypeFlags
		GCNLTF_SAVE_TO_STATE					0x8000
	ByteFlags TempMetaGCNFlags
		TMGCNF_RELOCATED						0x80
	WordFlags		GCNListSendFlags
		GCNLSF_SET_STATUS						0x8000
		GCNLSF_IGNORE_IF_STATUS_TRANSITIONING	0x4000
		GCNLSF_FORCE_QUEUE						0x2000
	INI_CATEGORY_BUFFER_SIZE					64
	typedef enum {
	    OFIQNS_SYSTEM_INPUT_OBJ=0,
	    OFIQNS_INPUT_OBJ_OF_OWNING_GEODE=2,
	    OFIQNS_PROCESS_OF_OWNING_GEODE=4,
	    OFIQNS_DISPATCH=6
	} ObjFlushInputQueueNextStop
	WordFlags		UpdateWindowFlags
		UWF_ATTACHING							0x8000
		UWF_DETACHING							0x4000
		UWF_RESTORING_FROM_STATE					0x2000
		UWF_TOP_LEVEL_WINDOW						0x1000
	WordFlags		CompChildFlags
		CCF_MARK_DIRTY 				0x8000
		CCF_REFERENCE				0x7fff
		CCO_FIRST					0x0000
		CCO_LAST					0x7FFF
	CCF_REFERENCE_OFFSET				0
	ByteEnum		InsertChildOption
		ICO_FIRST					0
		ICO_LAST					1
		ICO_BEFORE_REFERENCE		2
		ICO_AFTER_REFERENCE			3
	WordFlags		InsertChildFlags
		ICF_MARK_DIRTY				0x8000
		ICF_OPTIONS					0x0003
	typedef enum /* word */ {
	    OCCT_SAVE_PARAMS_TEST_ABORT=0,
	    OCCT_SAVE_PARAMS_DONT_TEST_ABORT=2,
	    OCCT_DONT_SAVE_PARAMS_TEST_ABORT=4,
	    OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT=6,
	    OCCT_ABORT_AFTER_FIRST=8,
	    OCCT_COUNT_CHILDREN=10
	} ObjCompCallType

**Structures**

	typedef struct {
		ClassStruct				*MB_class
	} MetaBase
	typedef struct {
		word				ax
		word				cx
		word				dx
		word				bp
	} AsmPassReturn
	typedef struct {
		ClassStruct *		GTP_class
		optr 				GTP_target
	} GetTargetParams
	typedef struct {
		ManufacturerID		NT_manuf
		word				NT_type
	} NotificationType
	typedef struct {
		word				GCNLT_manuf
		word				GCNLT_type
	} GCNListType
	typedef struct {
		optr				GCNLE_item
	} GCNListElement
	typedef struct {
		ChunkArrayHeader 	GCNLH_meta
		word 				GCNLH_statusEvent
		MemHandle 			GCNLH_statusData
		word 				GCNLH_statusCount
	} GCNListHeader
	typedef struct {
		GCNListType				GCNLOLE_ID
		ChunkHandle				GCNLOLE_list
	} GCNListOfListsElement
	typedef struct {
		ChunkArrayHeader		GCNLOL_meta
	} GCNListOfListsHeader
	typedef struct {
		ChunkHandle				TMGCND_listOfLists
		TempMetaGCNFlags		TMGCND_flags
	} TempMetaGCNData
	typedef struct {
		GCNListType 		GCNLP_ID
		optr 				GCNLP_optr
	} GCNListParams
	typedef struct {
		word				DDE_ackCount
		word				DDE_callerID
		optr				DDE_ackOD
		word				DDE_completeMsg
	} DetachDataEntry
	typedef struct {
		optr				LP_next
	} LinkPart
	typedef struct {
		optr				CP_firstChild
	} CompPart

**Messages**

	void MSG_META_NULL()
	void MSG_META_INITIALIZE()
	void MSG_META_DUMMY()
	void MSG_META_APP_STARTUP(MemHandle appLaunchBlock)
	void MSG_META_ATTACH()
	@alias(MSG_META_ATTACH) void MSG_META_ATTACH_PROCESS(
				word value1, word value2)
	@alias(MSG_META_ATTACH) void
		MSG_META_ATTACH_GENPROCESSCLASS(
				MemHandle appLaunchBlock)
	@alias(MSG_META_ATTACH) void MSG_META_ATTACH_OBJECT(
				word flags,
				MemHandle appLaunchBlock,
				MemHandle extraState)
	@alias(MSG_META_ATTACH) void MSG_META_ATTACH_THREAD()
	void MSG_META_DETACH(word callerID, optr caller)
	void MSG_META_DETACH_COMPLETE()
	void MSG_META_DETACH_ABORT()
	void MSG_META_ACK(word callerID, optr caller)
	void MSG_META_APP_SHUTDOWN(word callerID, optr ackOD)
	void MSG_META_SHUTDOWN_COMPLETE()
	void MSG_META_SHUTDOWN_ACK(word callerID, optr ackOD)
	ClassStruct * MSG_META_GET_CLASS()
	Boolean MSG_META_IS_OBJECT_IN_CLASS(ClassStruct *class)
	void MSG_META_BLOCK_FREE()
	void MSG_META_OBJ_FREE()
	ClassStruct * MSG_META_RESOLVE_VARIANT_SUPERCLASS(
				word MasterOffset)
	Boolean MSG_META_RELOCATE(word vmRelocType, word frame)
	Boolean MSG_META_UNRELOCATE(word vmRelocType,
				word frame)
	void MSG_META_SET_FLAGS(ChunkHandle objChunk,
				ObjChunkFlags bitsToSet,
				ObjChunkFlags bitsToClear)
	word MSG_META_GET_FLAGS(ChunkHandle ch)
	void MSG_META_VM_FILE_DIRTY(FileHandle file)
	void MSG_META_QUIT()
	@alias(MSG_META_QUIT) void MSG_META_QUIT_PROCESS(
					word quitLevel,
					ChunkHandle ackODChunk)
	@alias(MSG_META_QUIT) void MSG_META_QUIT_OBJECT(
					optr obj)
	void MSG_META_QUIT_ACK(word quitLevel, word abortFlag)
	Boolean MSG_META_DISPATCH_EVENT(AsmPassReturn *retVals,
					Eventhandle eventHandle,
					MessageFlags msgFlags)
	void MSG_META_SEND_CLASSED_EVENT(
				EventHandle event,
				TravelOption whereTo)
	optr MSG_META_GET_OPTR()
	void MSG_META_GET_TARGET_AT_TARGET_LEVEL(
				GetTargetParams *retValue,
				TargetLevel level)
	void MSG_META_ADD_VAR_DATA(@stack
				word dataType, word dataSize,
				void *data)
	Boolean MSG_META_DELETE_VAR_DATA(word dataType)
	word MSG_META_INITIALIZE_VAR_DATA(word dataType)
	void MSG_META_NOTIFY(ManufacturerID manufID,
				word notificationType, word data)
	void MSG_META_NOTIFY_WITH_DATA_BLOCK(
				ManufacturerID manufID,
				word notificationType,
				MemHandle data)
	Boolean MSG_META_GCN_LIST_ADD(@stack
				optr dest, word listType,
				ManufacturerID listManuf)
	Boolean MSG_META_GCN_LIST_REMOVE(@stack
				optr dest, word listType,
				ManufacturerID listManuf)
	void MSG_META_GCN_LIST_SEND(@stack
				GCNListSendFlags flags,
				EventHandle event, MemHandle block,
				word listType,
				ManufacturerID listManuf)
	void MSG_META_GCN_LIST_DESTROY()
	void MSG_META_SAVE_OPTIONS()
	void MSG_META_GET_INI_CATEGORY(char *buf)
	void MSG_META_SUSPEND()
	void MSG_META_UNSUSPEND()
	void MSG_META_LOAD_OPTIONS()
	void MSG_META_GET_VAR_DATA(@stack
				word dataType, word bufSize,
				void *buf)
	void MSG_META_NOTIFY_OBJ_BLOCK_INTERACTIBLE(
				MemHandle objBlock)
	void MSG_META_NOTIFY_OBJ_BLOCK_NOT_INTERACTIBLE(
				MemHandle objBlock)
	void MSG_META_OBJ_FLUSH_INPUT_QUEUE(
				EventHandle event,
				ObjFlushInputQueueNextStop nextStop,
				MemHandle objBlock)
	void MSG_META_WIN_DEC_REF_COUNT(MemHandle win)
	void MSG_META_UPDATE_WINDOW(
				UpdateWindowFlags updateFlags,
				VisUpdateMode updateMode)
	void MSG_META_FINISH_QUIT(Boolean abortFlag)
	void MSG_META_FINISH_QUIT(Boolean abortFlag)
	void MSG_META_SET_OBJ_BLOCK_OUTPUT(optr output)
	void MSG_META_GET_HELP_FILE(char *buf)
	void MSG_META_GET_HELP_TYPE (byte helpType)
	optr MSG_META_GET_OBJ_BLOCK_OUTPUT()
	void MSG_META_RESET_OPTIONS()
	void MSG_META_BRING_UP_HELP()
	void MSG_META_SET_HELP_FILE(char *buf)
	Boolean MSG_META_GCN_LIST_FIND_ITEM(@stack optr dest,
				word listType,
				ManufacturerID listManuf)
	void MSG_META_TRANSPARENT_DETACH()

**Window Messages**

	@exportMessages MetaWindowMessages,
					DEFAULT_EXPORTED_MESSAGES
	void MSG_META_EXPOSED(WindowHandle win)
	void MSG_META_EXPOSED_FOR_PRINT(
				GStringHandle gstring,
				optr completionOD)
	MSG_META_WIN_UPDATE_COMPLETE
	MSG_META_WIN_CHANGE
	MSG_META_IMPLIED_WIN_CHANGE
	MSG_META_RAW_UNIV_ENTER
	MSG_META_RAW_UNIV_LEAVE
	MSG_META_INVAL_TREE
	MSG_META_INVAL_BOUNDS

**Input Messages**

	@exportMessages MetaInputMessages,
					DEFAULT_EXPORTED_MESSAGES
	void MSG_META_MOUSE_BUTTON(word xPosition,
				word yPosition, word inputState)
	void MSG_META_MOUSE_PTR(word xPosition, word yPosition,
				word inputState)
	@alias (MSG_META_MOUSE_PTR) void MSG_META_PTR(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_KBD_CHAR(word character, word flags,
				word state)
	MSG_META_PRESSURE
	MSG_META_DIRECTION
	MSG_META_MOUSE_TIMER
	void MSG_DRAG(word xPosition, word yPosition,
				word inputState)

**UI Messages**

	@exportMessages MetaUIMessages,
					DEFAULT_EXPORTED_MESSAGES_4
	void MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_FEEDBACK(
			QuickTransferCursor quickTransferCursor)
	void MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_CONCLUDED(
				ClipboardQuickNotifyFlags flags)
	void MSG_META_CLIPBOARD_CUT()
	void MSG_META_CLIPBOARD_COPY()
	void MSG_META_CLIPBOARD_PASTE()
	void MSG_META_UNDO(UndoActionStruct *undoData)
	void MSG_META_UNDO_FREEING_ACTION(
				AddUndoActionStruct *data)
	void MSG_META_SELECT_ALL()
	void MSG_META_DELETE()
	void MSG_META_CLIPBOARD_NOTIFY_TRANSFER_ITEM_FREED(
				VMFileHandle itemFile,
				VMBlockHandle itemBlock)
	void MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED()
	void MSG_META_CONTENT_SET_VIEW(optr view)
	void MSG_META_CONTENT_VIEW_OPENING(optr view)
	void MSG_META_CONTENT_VIEW_CLOSING()
	void MSG_META_CONTENT_VIEW_WIN_OPENED(
				word viewWidth, word viewHeight,
				WindowHandle viewWindow)
	void MSG_META_CONTENT_VIEW_WIN_CLOSED(
				WindowHandle viewWindow)
	void MSG_META_CONTENT_VIEW_ORIGIN_CHANGED(@stack
				WindowHandle viewWindow,
				sdword xOrigin, sdword yOrigin)
	void MSG_META_CONTENT_VIEW_SCALE_FACTOR_CHANGED(@stack
				WindowHandle viewWindow,
				WWFixedAsDWord yScaleFactor,
				WWFixedAsDWord xScaleFactor)
	void MSG_META_CONTENT_VIEW_SIZE_CHANGED(
				word viewWidth, word viewHeight,
				WindowHandle viewWindow)
	void MSG_META_CONTENT_TRACK_SCROLLING(
				TrackScrollingParams *args)
	void MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL(
				WindowHandle viewWindow)
	void MSG_META_CONTENT_NAVIGATION_QUERY(
				optr queryOrigin, word navFlags,
				NavigationQueryParams *retValue)
	void MSG_META_CONTENT_APPLY_DEFAULT_FOCUS()
	void MSG_META_CONTENT_ENTER(optr view)
	void MSG_META_CONTENT_LEAVE(optr view)
	Boolean MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE(
				optr document, FileHandle file)
	void MSG_META_DOC_OUTPUT_CREATE_UI_FOR_DOCUMENT(
				optr document, FileHandle file)
	void MSG_META_DOC_OUTPUT_DESTROY_UI_FOR_DOCUMENT(
				optr document, FileHandle file)
	void MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT(
				optr document, FileHandle file)
	void MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT(
				optr document, FileHandle file)
	void MSG_META_DOC_OUTPUT_READ_CACHED_DATA_FROM_FILE(
				optr document, FileHandle file)
	void MSG_META_DOC_OUTPUT_WRITE_CACHED_DATA_TO_FILE(
				optr document, FileHandle file)
	void MSG_META_DOC_OUTPUT_DOCUMENT_HAS_CHANGED(
				optr document, FileHandle file)
	void MSG_META_DOC_OUTPUT_PHYSICAL_SAVE(
				word *error, optr document,
				FileHandle file)
	Boolean MSG_META_DOC_OUTPUT_PHYSICAL_UPDATE(word *error,
				optr document, FileHandle file)
	void MSG_META_DOC_OUTPUT_PHYSICAL_SAVE_AS_FILE_HANDLE(
				word *error, optr document,
				FileHandle file)
	void MSG_META_DOC_OUTPUT_PHYSICAL_REVERT(
				word *error, optr document,
				FileHandle file)
	Boolean MSG_META_DOC_OUTPUT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT(
				word *error, optr document,
				FileHandle file)
	Boolean MSG_META_DOC_OUTPUT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT(
				word *error, optr document,
				FileHandle file)
	void MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED(
				optr document, FileHandle file)
	void MSG_META_DOC_OUTPUT_ATTACH_FAILED(
				optr document, FileHandle file)
	void MSG_META_UI_FORCE_CONTROLLER_UPDATE(
				ManufacturerID manufID,
				word changeID)
	Boolean MSG_META_GEN_PATH_RESTORE_DISK_PROMPT(
				GenPathDiskRestoreArgs *args,
				DiskRestoreError *error)
	void MSG_META_PAGED_OBJECT_GOTO_PAGE(word page)
	void MSG_META_PAGED_OBJECT_NEXT_PAGE()
	void MSG_META_PAGED_OBJECT_PREVIOUS_PAGE()
	void MSG_META_NOTIFY_TASK_SELECTED()
	void MSG_META_GAINED_MOUSE_EXCL()
	void MSG_META_LOST_MOUSE_EXCL()
	void MSG_META_GAINED_KBD_EXCL()
	void MSG_META_LOST_KBD_EXCL()
	void MSG_META_GAINED_PRESSURE_EXCL()
	void MSG_META_LOST_PRESSURE_EXCL()
	void MSG_META_GAINED_DIRECTION_EXCL()
	void MSG_META_LOST_DIRECTION_EXCL()
	void MSG_META_GRAB_FOCUS_EXCL()
	void MSG_META_RELEASE_FOCUS_EXCL()
	Boolean MSG_META_GET_FOCUS_EXCL(optr *focusObject)
	void MSG_META_GRAB_TARGET_EXCL()
	void MSG_META_RELEASE_TARGET_EXCL()
	Boolean MSG_META_GET_TARGET_EXCL(optr *targetObject)
	void MSG_META_GRAB_MODEL_EXCL()
	void MSG_META_RELEASE_MODEL_EXCL()
	Boolean MSG_META_GET_MODEL_EXCL(optr *targetObj)
	void MSG_META_RELEASE_FT_EXCL()
	void MSG_META_MUP_ALTER_FTVMC_EXCL(
				optr objectWantingControl,
				MetaAlterFTVMCExclFlags flags)
	void MSG_META_GAINED_FOCUS_EXCL()
	void MSG_META_LOST_FOCUS_EXCL()
	void MSG_META_GAINED_SYS_FOCUS_EXCL()
	void MSG_META_LOST_SYS_FOCUS_EXCL()
	void MSG_META_GAINED_TARGET_EXCL()
	void MSG_META_LOST_TARGET_EXCL()
	void MSG_META_GAINED_SYS_TARGET_EXCL()
	void MSG_META_LOST_SYS_TARGET_EXCL()
	void MSG_META_GAINED_MODEL_EXCL()
	void MSG_META_LOST_MODEL_EXCL()
	void MSG_META_GAINED_SYS_MODEL_EXCL()
	void MSG_META_LOST_SYS_MODEL_EXCL()
	void MSG_META_GAINED_DEFAULT_EXCL()
	void MSG_META_LOST_DEFAULT_EXCL()
	void MSG_META_MOUSE_BUMP_NOTIFICATION(
				sword xBump, sword yBump)
	Boolean MSG_META_FUP_KBD_CHAR(word character,
				word flags, word state)
	KbdReturnFlags MSG_META_PRE_PASSIVE_KBD_CHAR(
				word character, word flags,
				word state)
	KbdReturnFlags MSG_META_POST_PASSIVE_KBD_CHAR(
				word character, word flags,
				word state)
	void MSG_META_QUERY_IF_PRESS_IS_INK(
				InkReturnParams *retVal,
				sword xPosition, sword yPosition)
	void MSG_META_LARGE_QUERY_IF_PRESS_IS_INK(
			InkReturnParams *retVal,
			LargeMouseData *largeMouseDataStruct)
	void MSG_META_START_SELECT(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_END_SELECT(
				MouseReturnParams *retVal,
				sword xPosition,sword yPosition,
				word inputState)
	void MSG_META_START_MOVE_COPY(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_END_MOVE_COPY(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_START_FEATURES(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_END_FEATURES(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_START_OTHER(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_END_OTHER(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_DRAG_SELECT(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_DRAG_MOVE_COPY(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_DRAG_FEATURES(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_DRAG_OTHER(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_PRE_PASSIVE_BUTTON(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_POST_PASSIVE_BUTTON(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_PRE_PASSIVE_START_SELECT(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_PRE_PASSIVE_END_SELECT(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_PRE_PASSIVE_START_MOVE_COPY(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_PRE_PASSIVE_END_MOVE_COPY(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_PRE_PASSIVE_START_FEATURES(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_PRE_PASSIVE_END_FEATURES(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_PRE_PASSIVE_START_OTHER(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_PRE_PASSIVE_END_OTHER(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_POST_PASSIVE_START_SELECT(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_POST_PASSIVE_END_SELECT(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_POST_PASSIVE_START_MOVE_COPY(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_POST_PASSIVE_END_MOVE_COPY(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_POST_PASSIVE_START_FEATURES(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_POST_PASSIVE_END_FEATURES(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_POST_PASSIVE_START_OTHER(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_POST_PASSIVE_END_OTHER(
				MouseReturnParams *retVal,
				sword xPosition, sword yPosition,
				word inputState)
	void MSG_META_LARGE_PTR(
			MouseReturnParams *retVal,
			LargeMouseData *largeMouseDataStruct)
	void MSG_META_LARGE_START_SELECT(
			MouseReturnParams *retVal,
			LargeMouseData *largeMouseDataStruct)
	void MSG_META_LARGE_END_SELECT(
			MouseReturnParams *retVal,
			LargeMouseData *largeMouseDataStruct)
	void MSG_META_LARGE_START_MOVE_COPY(
			MouseReturnParams *retVal,
			LargeMouseData *largeMouseDataStruct)
	void MSG_META_LARGE_END_MOVE_COPY(
			MouseReturnParams *retVal,
			LargeMouseData *largeMouseDataStruct)
	void MSG_META_LARGE_START_FEATURES(
			MouseReturnParams *retVal,
			LargeMouseData *largeMouseDataStruct)
	void MSG_META_LARGE_END_FEATURES(
			MouseReturnParams *retVal,
			LargeMouseData *largeMouseDataStruct)
	void MSG_META_LARGE_START_OTHER(
			MouseReturnParams *retVal,
			LargeMouseData *largeMouseDataStruct)
	void MSG_META_LARGE_END_OTHER(
			MouseReturnParams *retVal,
			LargeMouseData *largeMouseDataStruct)
	void MSG_META_LARGE_DRAG_SELECT(
			MouseReturnParams *retVal,
			LargeMouseData *largeMouseDataStruct)
	void MSG_META_LARGE_DRAG_MOVE_COPY(
			MouseReturnParams *retVal,
			LargeMouseData *largeMouseDataStruct)
	void MSG_META_LARGE_DRAG_FEATURES(
			MouseReturnParams *retVal,
			LargeMouseData *largeMouseDataStruct)
	void MSG_META_LARGE_DRAG_OTHER(
			MouseReturnParams *retVal,
			LargeMouseData *largeMouseDataStruct)
	MouseReturnFlags
		MSG_META_ENSURE_MOUSE_NOT_ACTIVELY_TRESPASSING()
	MouseReturnFlags
		MSG_META_ENSURE_NO_MENUS_IN_STAY_UP_MODE()
	void MSG_META_ENSURE_ACTIVE_FT()
	void MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE()
	void MSG_META_DOC_OUTPUT_IMPORT_FILE()
	void MSG_META_DOC_OUTPUT_EXPORT_FILE()
	void MSG_META_GRAB_KBD()
	void MSG_META_FORCE_GRAB_KBD()
	void MSG_META_RELEASE_KBD()
	void MSG_META_VIEW_COMMAND_CHANGE_SCALE()
	void MSG_META_FIELD_NOTIFY_DETACH(optr field,
				word shutdownFlag)
	void MSG_META_FIELD_NOTIFY_NO_FOCUS(optr field,
				word shutdownFlag)
	void MSG_META_FIELD_NOTIFY_START_LAUNCHER_ERROR(
				optr field)
	void MSG_META_DELETE_RANGE_OF_CHARS(@stack
				VisTextRange rangeToDelete)
	Boolean MSG_META_TEST_WIN_INTERACTIBILITY(optr inputOD,
				WindowHandle window)
	Boolean MSG_META_CHECK_IF_INTERACTABLE_OBJECT(optr obj)

**Application Messages**

	@exportMessages MetaApplicationMessages,
					DEFAULT_EXPORTED_MESSAGES_3

**GrObj Messages**

	@exportMessages MetaGrObjMessages,
					DEFAULT_EXPORTED_MESSAGES
	MSG_GROBJ_ACTION_NOTIFICATION

**Printing Messages**

	@exportMessages MetaPrintMessages,
					DEFAULT_EXPORTED_MESSAGES
	void MSG_PRINT_VERIFY_PRINT_REQUEST(optr printCtrlOD)
	void MSG_PRINT_START_PRINTING(optr printCtrlOD,
				GStateHandle gstate)
	void MSG_PRINT_GET_DOC_NAME(optr printCtrlOD)
	void MSG_PRINT_NOTIFY_PRINT_DB(optr printCtrlOD,
				PrintControlStatus pcs)
	void MSG_PRINT_NOTIFY_PRINT_JOB_CREATED(word jobID)
	void MSG_PRINT_REPORT_PAGE_SIZE(PageSizeReport *psr)
	void MSG_PRINTING_GET_DOC_NAME()
	void MSG_PRINTING_COMPLETED()

**Search/Spell Messages**

	@exportMessages MetaSearchSpellMessages,
					DEFAULT_EXPORTED_MESSAGES
	void MSG_SPELL_CHECK(@stack
				optr replyObj,
				dword numCharsToCheck,
				SpellCheckOptions options,
				MemHandle ICbuff)
	void MSG_META_EDIT_USER_DICTIONARY_COMPLETED()
	void MSG_THES_REPLACE_SELECTED_WORDS (@stack
				MemHandle RSWP_string,
				word RSWP_numChars)
	void MSG_THES_SELECT_WORD (@stack
				optr output, Message message,
				word numChars, word type)
	void MSG_SEARCH(MemHandle searchInfo)
	void MSG_REPLACE_CURRENT(MemHandle replaceInfo)
	void MSG_REPLACE_ALL_OCCURRENCES(MemHandle replaceInfo,
				Boolean replaceFromBeginning)
	void MSG_REPLACE_ALL_OCCURRENCES_IN_SELECTION(
				MemHandle replaceInfo)
	void MSG_ABORT_ACTIVE_SPELL()
	void MSG_ABORT_ACTIVE_SEARCH()
	optr MSG_META_GET_OBJECT_FOR_SEARCH_SPELL(
				GetSearchSpellObjectOption option,
				optr curObject)
	void MSG_META_GET_CONTEXT(@stack
				dword position,
				ContextLocation location,
				word numCharsToGet, optr replyObj)
	void MSG_META_GENERATE_CONTEXT_NOTIFICATION(@stack
				dword position,
				ContextLocation location,
				word numCharsToGet, optr replyObj)
	void MSG_META_CONTEXT(MemHandle data)
	void MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL()

**GCN Messages**

	@exportMessages MetaGCNMessages,
					DEFAULT_EXPORTED_MESSAGES
	void MSG_NOTIFY_FILE_CHANGE(
			FileChangeNotificationType notifyType
			MemHandle data)
	void MSG_NOTIFY_DRIVE_CHANGE(
				GCNDriveChangeNotificationType type,
				word driveNum)
	void MSG_NOTIFY_APP_STARTED()
	void MSG_NOTIFY_APP_EXITED(MemHandle appExited)
	void MSG_NOTIFY_DATE_TIME_CHANGE()
	void MSG_NOTIFY_USER_DICT_CHANGE(
				MemHandle sendingSpellBox,
				MemHandle userDictChanged)
	void MSG_DISPLAY_FLOATING_KEYBOARD()
	void MSG_NOTIFY_EXPRESS_MENU_CHANGE(
			GCNExpressMenuNotificationTypes type,
			optr affectedExpressMenuControl)
	void MSG_PRINTER_INSTALLED_REMOVED()
	void MSG_META_CONFIRM_SHUTDOWN(
				word confirmed,
				GCNShutdownControlType type)
	@alias(MSG_META_CONFIRM_SHUTDOWN) void
		MSG_META_CONFIRM_SHUTDOWN_QUERY(
				optr originator,
				GCNShutdownControlType type)

**Text Messages**

	@exportMessages MetaTextMessages,
					DEFAULT_EXPORTED_MESSAGES
	MSG_VIS_TEXT_SET_FONT_ID
	MSG_VIS_TEXT_SET_FONT_WEIGHT
	MSG_VIS_TEXT_SET_FONT_WIDTH
	void MSG_VIS_TEXT_SET_POINT_SIZE(@stack
					WWFixedAsDWord pointSize,
					dword rangeEnd,
					dword rangeStart)
	MSG_VIS_TEXT_SET_SMALLER_POINT_SIZE
	MSG_VIS_TEXT_SET_LARGER_POINT_SIZE
	void MSG_VIS_TEXT_SET_TEXT_STYLE(@stack
				word extBitsToClear,
				word extBitsToSet,
				word styleBitsToClear,
				word styleBitsToSet,
				dword rangeEnd, dword rangeStart)
	MSG_VIS_TEXT_SET_COLOR
	MSG_VIS_TEXT_SET_GRAY_SCREEN
	MSG_VIS_TEXT_SET_PATTERN
	MSG_VIS_TEXT_SET_CHAR_BG_COLOR
	MSG_VIS_TEXT_SET_CHAR_BG_GRAY_SCREEN
	MSG_VIS_TEXT_SET_CHAR_BG_PATTERN
	MSG_VIS_TEXT_SET_TRACK_KERNING
	MSG_VIS_TEXT_SET_BORDER_COLOR
	MSG_VIS_TEXT_SET_BORDER_GRAY_SCREEN
	MSG_VIS_TEXT_SET_BORDER_PATTERN
	void MSG_VIS_TEXT_SET_PARA_ATTRIBUTES(@stack
				word bitsToClear, word bitsToSet,
				dword rangeEnd, dword rangeStart)
	void MSG_META_TEXT_USER_MODIFIED(optr obj)
	void MSG_META_TEXT_CR_FILTERED(word character,
				word flags, word state)
	void MSG_META_TEXT_TAB_FILTERED(word character,
				word flags, word state)
	void MSG_META_TEXT_LOST_FOCUS(optr obj)
	void MSG_META_TEXT_GAINED_FOCUS(optr obj)
	void MSG_META_TEXT_LOST_TARGET(optr obj)
	void MSG_META_TEXT_GAINED_TARGET(optr obj)
	void MSG_META_TEXT_EMPTY_STATUS_CHANGED(
				optr object, Boolean hasTextFlag)
	void MSG_META_TEXT_NOT_USER_MODIFIED(optr obj)
	@exportMessages MetaStylesMessages,
					DEFAULT_EXPORTED_MESSAGES
	void MSG_META_STYLED_OBJECT_REQUEST_ENTRY_MONIKER()
	void MSG_META_STYLED_OBJECT_UPDATE_MODIFY_BOX()
	void MSG_META_STYLED_OBJECT_MODIFY_STYLE()
	void MSG_META_STYLED_OBJECT_DESCRIBE_ATTRS()
	void MSG_META_STYLED_OBJECT_DESCRIBE_STYLE()
	void MSG_META_STYLED_OBJECT_APPLY_STYLE()
	void MSG_META_STYLED_OBJECT_DELETE_STYLE()
	void MSG_META_STYLED_OBJECT_DEFINE_STYLE()
	void MSG_META_STYLED_OBJECT_REDEFINE_STYLE()
	void MSG_META_STYLED_OBJECT_RETURN_TO_BASE_STYLE()
	void MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET()
	void MSG_META_STYLED_OBJECT_SAVE_STYLE()
	void MSG_META_STYLED_OBJECT_RECALL_STYLE()

**Color Messages**

	@exportMessages MetaColorMessages,
					DEFAULT_EXPORTED_MESSAGES
	void MSG_META_COLORED_OBJECT_SET_COLOR()
	void MSG_META_COLORED_OBJECT_SET_DRAW_MASK()
	void MSG_META_COLORED_OBJECT_SET_PATTERN()

**Floating-Point Messages**

	@exportMessages MetaFloatMessages,
					DEFAULT_EXPORTED_MESSAGES
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

## MultTextGuardianClass

	@class MultTextGuardianClass, TextGuardianClass

## PageSizeControlClass

	@class PageSizeControlClass, GenControlClass

**Instance Data**

	PageSizeCtrlAttrs		PZCI_attrs
	dword					PZCI_width
	dword					PZCI_height
	PageLayout				PZCI_layout
	PCMarginParams			PZCI_margins
		@default GII_type = GIT_PROPERTIES
		@default GII_visibility = GIV_DIALOG

**Variable Data**

	PageSizeControlChanges ATTR_PAGE_SIZE_CONTROL_UI_CHANGES

**Types and Flags**

	MINIMUM_PAGE_WIDTH_VALUE			36
	MINIMUM_PAGE_HEIGHT_VALUE			36
	MAXIMUM_PAGE_WIDTH_VALUE			(72 * 45)
	MAXIMUM_PAGE_HEIGHT_VALUE			(72 * 45)
	MAXIMUM_LABELS_ACROSS				63
	MAXIMUM_LABELS_DOWN					63
	WordFlags		PageSizeCtrlAttrs
		PZCA_ACT_LIKE_GADGET			0x8000
		PZCA_PAPER_SIZE					0x4000
		PZCA_INITIALIZE					0x2000
		PZCA_LOAD_SAVE_OPTIONS			0x1000
	ByteFlags		PageSizeControlFeatures
		PSIZECF_MARGINS					0x0010
		PSIZECF_CUSTOM_SIZE				0x0008
		PSIZECF_LAYOUT					0x0004
		PSIZECF_SIZE_LIST				0x0002
		PSIZECF_PAGE_TYPE				0x0001
	PSIZEC_DEFAULT_FEATURES (PSIZECF_PAGE_TYPE |
			PSIZECF_SIZE_LIST | PSIZECF_LAYOUT |
			PSIZECF_CUSTOM_SIZE)
	ByteEnum		PaperOrientation
		PO_PORTRAIT				0x00
		PO_LANDSCAPE			0x01
	WordFlags		PageLayoutPaper
		PLP_ORIENTATION			0x0008
		PLP_TYPE				0x0004
	ByteEnum		EnvelopeOrientation
		EO_PORTAIT				0x00
		EO_LANDSCAPE			0x01
	WordFlags		PageLayoutEnvelope
		PLE_ORIENTATION			0x0010
		PLE_TYPE				0x0004
	WordFlags		PageLayoutLabel
		PLL_ROWS				0x7e00
		PLL_COLUMNS				0x01f8
		PLL_TYPE				0x0004

**Structures**

	typedef struct {
		word 				unused
		word 				PS_width
		word 				PS_height
		PageLayout 			PS_layout
	} PageSize
	typedef struct {
		optr				PSCC_destination
		Message				PSCC_message
	} PageSizeControlChanges
	typedef struct {
		dword 				PSR_width
		dword 				PSR_height
		PageLayout 			PSR_layout
	} PageSizeReport
	typedef union {
		PageLayoutPaper 			PL_paper
		PageLayoutEnvelope			PL_envelope
		PageLayoutLabel				PL_label
	} PageLayout

Messages

	void MSG_PZC_SET_PAGE_SIZE(PageSizeReport *psr)
	void MSG_PZC_GET_PAGE_SIZE(PageSizeReport *psr)

## PointerClass

	@class PointerClass, GrObjClass

**Instance Data**

	PointerModes 			PTR_modes

**Types and Flags**

	MIN_MARQUEE_DIMENSION				7
	MAX_PRIORITY_LIST_ELEMENTS			5
	ByteFlags		PointerModes
		PM_HANDLES_RESIZE 					0x04
		PM_HANDLES_ROTATE 					0x02
		PM_POINTER_IS_ACTION_OBJECT 		0x01

## PrintControlClass

	@class PrintControlClass, GenControlClass, master

**Instance Data**

	PrintControlAttrs PCI_attrs = (PCA_COPY_CONTROLS |
					PCA_PAGE_CONTROLS | PCA_QUALITY_CONTROLS |
					PCA_USES_DIALOG_BOX | PCA_GRAPHICS_MODE |
					PCA_TEXT_MODE)
	word		PCI_startPage = 1
	word		PCI_endPage = 1
	word		PCI_startUserPage = 0
	word		PCI_endUserPage = 0x7fff
	word		PCI_defPrinter = -1
	PageSizeReport PCI_docSizeInfo = {0, 0, 0, {0, 0, 0, 0}}
	optr		PCI_output
	optr		PCI_docNameOutput
		@default GII_visibility = GIV_SUB_GROUP
		@default GII_type = GIT_ORGANIZATIONAL
		@default GI_attrs = @default | GA_KBD_SEARCH_PATH

**Variable Data**

	TempPrintCtrlInstance TEMP_PRINT_CONTROL_INSTANCE
	optr ATTR_PRINT_CONTROL_APP_UI
		@reloc ATTR_PRINT_CONTROL_APP_UI, 0, optr
	TempPrintCompletionEventData
					TEMP_PRINT_COMPLETION_EVENT

**Types and Flags**

	ByteFlags		PrintControlFeatures
		PRINTCF_PRINT_TRIGGER					0x02
		PRINTCF_FAX_TRIGGER						0x01
	ByteFlags PrintControlToolboxFeatures
		PRINTCTF_PRINT_TRIGGER					0x02
		PRINTCTF_FAX_TRIGGER					0x01
	PRINTC_DEFAULT_FEATURES				(PRINTCF_PRINT_TRIGGER |
								 PRINTCF_FAX_TRIGGER)
	ByteFlags		PrinterOutputModes
		POM_GRAPHICS_LOW					0x10
		POM_GRAPHICS_MEDIUM					0x08
		POM_GRAPHICS_HIGH					0x04
		POM_TEXT_DRAFT 						0x02
		POM_TEXT_NLQ						0x01
	PRINT_GRAPHICS			(POM_GRAPHICS_LOW |
							 POM_GRAPHICS_MEDIUM |
							POM_GRAPHICS_HIGH )
	PRINT_TEXT			(POM_TEXT_DRAFT | POM_TEXT_NLQ)
	typedef enum {
		PQT_HIGH,
		PQT_MEDIUM,
		PQT_LOW
	} PrintQualityEnum
	WordFlags		PrintControlAttrs
		PCA_SEE_IF_DOC_WILL_FIT				0x4000
		PCA_MARK_APP_BUSY					0x2000
		PCA_VERIFY_PRINT					0x1000
		PCA_SHOW_PROGRESS					0x0800
		PCA_PROGRESS_PERCENT				0x0400
		PCA_PROGRESS_PAGE					0x0200
		PCA_FORCE_ROTATION					0x0100
		PCA_COPY_CONTROLS					0x0080
		PCA_PAGE_CONTROLS					0x0040
		PCA_QUALITY_CONTROLS				0x0020
		PCA_USES_DIALOG_BOX					0x0010
		PCA_GRAPHICS_MODE					0x0008
		PCA_TEXT_MODE						0x0004
		PCA_DEFAULT_QUALITY					0x0002
	typedef enum {
		PCS_PRINT_BOX_VISIBLE,
		PCS_PRINT_BOX_NOT_VISIBLE
	} PrintControlStatus
	typedef enum {
		SVA_NO_MESSAGE,
		SVA_WARNING,
		SVA_PRINTING
	} SpoolVerifyAction
	typedef enum {
		PCPT_PAGE,
		PCPT_UNUSED1,
		PCPT_PERCENT,
		PCPT_UNUSED2,
		PCPT_TEXT
	} PCProgressType
	typedef enum {
		PT_PAPER,
		PT_UNUSED1,
		PT_ENVELOPE,
		PT_UNUSED2,
		PT_LABEL
	} PageType
	PaperType		PageType
	ByteEnum		PaperOrientation
		PO_PORTRAIT					0x00
		PO_LANDSCAPE				0x01
	WordFlags		PageLayoutPaper
		PLP_ORIENTATION				0x0008
		PLP_TYPE					0x0004
	ByteEnum		EnvelopePath
		EP_LEFT						0x00
		EP_CENTER					0x01
		EP_RIGHT					0x02
	ByteEnum		EnvelopeOrientation
		EO_PORTAIT_LEFT				0x00
		EO_PORTAIT_RIGHT			0x01
		EO_LANDSCAPE_UP				0x02
		EO_LANDSCAPE_DOWN			0x03
	WordFlags		PageLayoutEnvelope
		PLE_PATH					0x0040
		PLE_ORIENTATION				0x0010
		PLE_TYPE					0x0004
	WordFlags		PageLayoutLabel
		PLL_ROWS					0x7e00
		PLL_COLUMNS					0x01f8
		PLL_TYPE					0x0004
	typedef union {
		PageLayoutPaper				PL_paper
		PageLayoutEnvelope			PL_envelope
		PageLayoutLabel				PL_label
	} PageLayout
	ByteFlags		PrintStatusFlags
		PSF_FAX_AVAILABLE			0x80
		PSF_ABORT					0x08
		PSF_RECEIVED_COMPLETED		0x04
		PSF_RECEIVED_NAME			0x02
		PSF_VERIFIED				0x01

**Structures**

	typedef struct {
		dword			PCDSP_width
		dword			PCDSP_height
	} PCDocSizeParams
	typedef struct {
		word			PCMP_left
		word			PCMP_top
		word			PCMP_right
		word			PCMP_bottom
	} PCMarginParams
	typedef struct {
		dword			PSR_width
		dword			PSR_height
		PageLayout 		PSR_layout
		PCMarginParams 	PSR_margins
	} PageSizeReport
	typedef struct {
		int			leftMargin
		int			topMargin
		int			rightMargin
		int			bottomMargin
	} MarginDimensions
	typedef struct {
		int			leftMargin
		int			topMargin
		int			width
		int			height
	} DocumentSize
	typedef struct {
		optr				TPCI_currentSummons
		optr				TPCI_progressBox
		ChunkHandle			TPCI_jobParHandle
		word 				TPCI_fileHandle
		word				TPCI_gstringHandle
		word				TPCI_printBlockHan
		PrintControlAttrs	TPCI_attrs
		PrintStatusFlags	TPCI_status
	} TempPrintCtrlInstance

**Messages**

	void MSG_PRINT_CONTROL_INITIATE_PRINT()
	void MSG_PRINT_CONTROL_PRINT()
	void MSG_PRINT_CONTROL_VERIFY_COMPLETED(
				Boolean continue)
	void MSG_PRINT_CONTROL_SET_DOC_NAME(char *string)
	Boolean MSG_PRINT_CONTROL_REPORT_PROGRESS(
				PCProgressType progress,
				int pageOrPercent)
	@alias(MSG_PRINT_CONTROL_REPORT_PROGRESS)
		Boolean MSG_PRINT_CONTROL_REPORT_STRING(
				PCProgressType progress,
				char *progressString)
	void MSG_PRINT_CONTROL_PRINTING_CANCELLED()
	void MSG_PRINT_CONTROL_PRINTING_COMPLETED()
	void MSG_PRINT_CONTROL_SET_ATTRS(
				PrintControlAttrs attributes)
	PrintControlAttrs MSG_PRINT_CONTROL_GET_ATTRS()
	void MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE(
				int firstPage, int lastPage)
	dword MSG_PRINT_CONTROL_GET_TOTAL_PAGE_RANGE()
	void MSG_PRINT_CONTROL_SET_SELECTED_PAGE_RANGE(
				int firstPage,int lastPage)
	dword MSG_PRINT_CONTROL_GET_SELECTED_PAGE_RANGE()
	void MSG_PRINT_CONTROL_SET_DOC_SIZE(
				int width, int height)
	dword MSG_PRINT_CONTROL_GET_DOC_SIZE()
	void MSG_PRINT_CONTROL_SET_EXTENDED_DOC_SIZE(
				PCDocSizeParams *ptr)
	void MSG_PRINT_CONTROL_GET_EXTENDED_DOC_SIZE(
				PCDocSizeParams *ptr)
	void MSG_PRINT_CONTROL_SET_DOC_MARGINS(
				PCMarginParams *ptr)
	void MSG_PRINT_CONTROL_GET_DOC_MARGINS(
				PCMarginParams *ptr)
	void MSG_PRINT_CONTROL_SET_DOC_SIZE_INFO(
				PageSizeReport *ptr)
	void MSG_PRINT_CONTROL_GET_DOC_SIZE_INFO(
				PageSizeReport *ptr)
	void MSG_PRINT_CONTROL_SET_OUTPUT(optr objectPtr)
	optr MSG_PRINT_CONTROL_GET_OUTPUT()
	void MSG_PRINT_CONTROL_SET_DOC_NAME_OUTPUT(
				optr document)
	optr MSG_PRINT_CONTROL_GET_DOC_NAME_OUTPUT()
	void MSG_PRINT_CONTROL_SET_DEFAULT_PRINTER(
				int printerNum)
	int MSG_PRINT_CONTROL_GET_DEFAULT_PRINTER()
	byte MSG_PRINT_CONTROL_GET_PRINT_MODE()
	void MSG_PRINT_CONTROL_GET_PAPER_SIZE_INFO(
				PageSizeReport *ptr)
	void MSG_PRINT_CONTROL_GET_PAPER_SIZE(
				PCMarginParams *retValue)
	void MSG_PRINT_CONTROL_GET_PRINTER_MARGINS(
				MarginDimensions *retValue,
				Boolean setMargins)
	void MSG_PRINT_CONTROL_CALC_DOC_DIMENSIONS(
				PageSizeReport *ptr)
	Boolean MSG_PRINT_CONTROL_CHECK_IF_DOC_WILL_FIT(
				Boolean warning)

## ProcessClass

	@class ProcessClass, MetaClass

**Types and Flags**

	ByteEnum		CopyChunkMode
		CCM_OPTR			0
		CCM_HPTR			1
		CCM_FPTR 			2
		CCM_STRING 			3
	WordFlags		CopyChunkFlags
		CCF_DIRTY			0x8000
		CCF_MODE			0x6000
		CCF_SIZE			0x1fff
	CCF_MODE_OFFSET			13

**Messages**

	void MSG_PROCESS_NOTIFY_PROCESS_EXIT(
				GeodeHandle exitProcess,
				word exitCode)
	void MSG_PROCESS_NOTIFY_THREAD_EXIT(
				ThreadHandle exitProcess,
				word exitCode)
	void MSG_PROCESS_MEM_FULL(word type)
	void MSG_PROCESS_CREATE_UI_THREAD(
				ClassStruct *class, word stackSize)
	void MSG_PROCESS_CREATE_EVENT_THREAD(
				ClassStruct *class, word stackSize)

## RectClass

	@class RectClass, GrObjClass

## RoundedRectClass

	@class RoundedRectClass, RectClass

**Instance Data**

	word 		RRI_radius

**Messages**

	MSG_RR_SET_RADIUS
	MSG_RR_GET_RADIUS

## SpellControlClass

	@class SpellControlClass, GenControlClass

**Instance Data**

	MemHandle 			SCI_ICBuffHan
	SpellBoxState 		SCI_spellState
	byte 				SCI_haveSelection
	dword 				SCI_charsLeft
	word 				SCI_enableFlags
		@default GII_visibility = GIV_DIALOG
		@default GCI_output = (TO_APP_TARGET)

**Variable Data**

	void ATTR_SPELL_CONTROL_INTERACT_ONLY_WITH_TARGETED_TEXT_OBJECTS

**Types and Flags**

	ByteEnum		SpellCheckStartOption
		SCSO_BEGINNING_OF_DOCUMENT 				0
		SCSO_BEGINNING_OF_SELECTION 			1
		SCSO_WORD_BOUNDARY_BEFORE_SELECTION 	2
		SCSO_END_OF_SELECTION 					3
	WordFlags		SpellCheckOptions
		SCO_CHECK_SELECTION 					0x08
		SCO_CHECK_NUM_CHARS 					0x04
	typedef enum { /* word */
		SCR_ONE_WORD_CHECKED,
		SCR_SELECTION_CHECKED,
		SCR_DOCUMENT_CHECKED
	} SpellCheckResult
	WordFlags		SpellFeatures
		SF_CLOSE 						0x2000
		SF_CONTEXT 						0x1000
		SF_SIMPLE_MODAL_BOX 			0x0800
		SF_SUGGESTIONS 					0x0400
		SF_CHECK_ALL 					0x0200
		SF_CHECK_TO_END 				0x0100
		SF_CHECK_SELECTION 				0x0080
		SF_SKIP 						0x0040
		SF_SKIP_ALL 					0x0020
		SF_REPLACE_CURRENT 				0x0010
		SF_REPLACE_ALL 					0x0008
		SF_ADD_TO_USER_DICTIONARY 		0x0004
		SF_EDIT_USER_DICTIONARY 		0x0002
		SF_STATUS 						0x0001
	WordFlags		SpellToolboxFeatures
		STF_SPELL 					0x01
	SC_DEFAULT_FEATURES (SF_STATUS |
				SF_EDIT_USER_DICTIONARY |
				SF_ADD_TO_USER_DICTIONARY |
				SF_REPLACE_ALL | SF_REPLACE_CURRENT
				| SF_SKIP_ALL | SF_SKIP |
				SF_CHECK_SELECTION |
				SF_CHECK_TO_END | SF_CHECK_ALL |
				SF_SUGGESTIONS | SF_CLOSE |
				SF_CONTEXT)
	SC_SUGGESTED_INTRODUCTORY_FEATURES (SF_SIMPLE_MODAL_BOX
				| SF_CONTEXT | SF_SUGGESTIONS |
				SF_SKIP | SF_REPLACE_CURRENT |
				SF_STATUS)
	SC_DEFAULT_TOOLBOX_FEATURES (STF_SPELL)
	ByteEnum		SpellBoxState
		SBS_NO_SPELL_ACTIVE 					0
		SBS_CHECKING_DOCUMENT 					1
		SBS_CHECKING_SELECTION 					2

**Structures**

	typedef struct {
		dword 		UWI_numChars
		word 		UWI_charOffset
		char 		UWI_unknownWord[SPELL_MAX_WORD_LENGTH]
	} UnknownWordInfo
	typedef struct {
		Boolean 		NSEC_spellEnabled
	} NotifySpellEnableChange

**Messages**

	void MSG_SPELL_CHECK(@stack
				optr replyObj,
				dword numCharsToCheck,
				SpellCheckOptions options,
				MemHandle ICbuff)
	void MSG_SC_UNKNOWN_WORD_FOUND(UnknownWordInfo *infoPtr)
	void MSG_SC_SPELL_CHECK_COMPLETED(
				SpellCheckResult result)

## SplineGuardianClass

	@class SplineGuardianClass, GrObjVisGuardianClass

**Instance Data**

	byte 		SGI_splineCreateMode
	byte 		SGI_splineAfterCreateMode
	byte 		SGI_splineMode

**Messages**

	MSG_SG_SET_SPLINE_MODE
	MSG_SG_GENERATE_SPLINE_NOTIFY
	MSG_SG_SWITCH_TO_SPLINE_CREATE_MODE
	MSG_SG_SWITCH_TO_SPLINE_AFTER_CREATE_MODE
	MSG_SG_SET_SPLINE_CREATE_AND_AFTER_CREATE_MODES

## SplineOpenCloseControlClass

	@class SplineOpenCloseControlClass, GenControlClass

## SplinePointControlClass

	@class SplinePointControlClass, GenControlClass

## SplineSmoothnessControlClass

	@class SplineSmoothnessControlClass, GenControlClass

## SpoolPrintControlClass

	@class SpoolPrintControlClass, GenInteractionClass, master

**Instance Data**

	ChunkHandle			SPCI_local
	word				SPCI_localRevNum = 0
	PrintControlAttrs 	SPCI_attrs = 0
	word				SPCI_startPage = 0
	word				SPCI_endPage = 0
	word				SPCI_startUserPage = 0
	word				SPCI_endUserPage = 0
	word				SPCI_defPrinter = 0
	word				SPCI_docWidth = 0
	word				SPCI_docHeight = 0
	word				SPCI_marginLeft = 0
	word				SPCI_marginTop = 0
	word				SPCI_marginRight = 0
	word				SPCI_marginBottom = 0
	optr				SPCI_printGroup
	optr				SPCI_output
	optr				SPCI_docNameOutput

**Types and Flags**

	PRINT_CONTROL_DEFAULT_PRINTER			(-1)
	PRINT_CONTROL_CURRENT_PRINTER 			(-2)
	ByteFlags		PrinterOutputModes
		POM_TEXT_NLQ					(1 << 0)
		POM_TEXT_DRAFT					(1 << 1)
		POM_GRAPHICS_HIGH				(1 << 2)
		POM_GRAPHICS_MEDIUM				(1 << 3)
		POM_GRAPHICS_LOW				(1 << 4)
	PRINT_GRAPHICS			( POM_GRAPHICS_LOW |
			POM_GRAPHICS_MEDIUM | POM_GRAPHICS_HIGH)
	PRINT_TEXT			( POM_TEXT_DRAFT | POM_TEXT_NLQ)
	ByteEnum		PrintQualityEnum
		PQT_HIGH			0
		PQT_MEDIUM			1
		PQT_LOW				2
	WordFlags		PrintControlAttrs
		PCA_MARK_APP_BUSY				0x2000
		PCA_VERIFY_PRINT				0x1000
		PCA_SHOW_PROGRESS				0x0800
		PCA_PROGRESS_PERCENT			0x0400
		PCA_PROGRESS_PAGE				0x0200
		PCA_FORCE_ROTATION				0x0100
		PCA_COPY_CONTROLS				0x0080
		PCA_PAGE_CONTROLS				0x0040
		PCA_QUALITY_CONTROLS			0x0020
		PCA_USES_DIALOG_BOX				0x0010
		PCA_GRAPHICS_MODE				0x0008
		PCA_TEXT_MODE					0x0004
		PCA_DEFAULT_QUALITY				0x0003
	typedef enum /* word */ {
		PCS_PRINT_BOX_VISIBLE,
		PCS_PRINT_BOX_NOT_VISIBLE
	} PrintControlStatus
	typedef enum /* word */ {
		SVA_NO_MESSAGE,
		SVA_WARNING,
		SVA_PRINTING
	} SpoolVerifyAction
	WordFlags SpoolVerifyDocFail
		SVDF_DUE_TO_DOC_SIZE			0x0002
		SVDF_DUE_TO_MARGINS				0x0001
	typedef enum /* word */ {
		PCPT_PAGE,
		PCPT_PERCENT,
		PCPT_TEXT
	} PCProgressType

**Structures**

	typedef struct {
		dword			PCDSP_width
		dword			PCDSP_height
	} PCDocSizeParams
	typedef struct {
		word			PCMP_left
		word			PCMP_top
		word			PCMP_right
		word			PCMP_bottom
	} PCMarginParams
	typedef struct {
		word			PCMS_left
		word			PCMS_top
		word			PCMS_right
		word			PCMS_bottom
	} PrintControlMarginStruct

**Messages**

	MSG_SPOOL_PRINT_CONTROL_INITIATE_PRINT
	MSG_SPOOL_PRINT_CONTROL_PRINT
	MSG_SPOOL_PRINT_CONTROL_SET_ATTRS
	MSG_SPOOL_PRINT_CONTROL_GET_ATTRS
	MSG_SPOOL_PRINT_CONTROL_GET_PRINT_MODE
	MSG_SPOOL_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE
	MSG_SPOOL_PRINT_CONTROL_GET_TOTAL_PAGE_RANGE
	MSG_SPOOL_PRINT_CONTROL_SET_SELECTED_PAGE_RANGE
	MSG_SPOOL_PRINT_CONTROL_GET_SELECTED_PAGE_RANGE
	MSG_SPOOL_PRINT_CONTROL_SET_DOC_SIZE
	MSG_SPOOL_PRINT_CONTROL_GET_DOC_SIZE
	MSG_SPOOL_PRINT_CONTROL_SET_PRINT_GROUP
	MSG_SPOOL_PRINT_CONTROL_GET_PRINT_GROUP
	MSG_SPOOL_PRINT_CONTROL_SET_OUTPUT
	MSG_SPOOL_PRINT_CONTROL_GET_OUTPUT
	MSG_SPOOL_PRINT_CONTROL_SET_DEFAULT_PRINTER
	MSG_SPOOL_PRINT_CONTROL_SPOOLING_UPDATE
	MSG_SPOOL_PRINT_CONTROL_CANCEL_PRINT_JOB
	MSG_SPOOL_PRINT_CONTROL_GET_PAPER_SIZE
	void MSG_SPOOL_PRINT_CONTROL_SET_DOC_NAME(char *name)
	void MSG_SPOOL_PRINT_CONTROL_SET_DOC_MARGINS(word *ms)
	MSG_SPOOL_PRINT_CONTROL_GET_PRINTER_MARGINS
	MSG_SPOOL_PRINT_CONTROL_GET_DOCUMENT_DIMMENSIONS
	MSG_SPOOL_PRINT_CONTROL_VERIFY_DOC_MARGINS
	MSG_SPOOL_PRINT_CONTROL_VERIFY_DOC_SIZE

## SpreadsheetClass

	@class SpreadsheetClass, VisCompClass, master

**Instance Data**

	CellFunctionParameters 	SSI_cellParams = {0, 0, {0}}
	word 				SSI_chunk = 0
	optr 				SSI_chartBody
	word 				SSI_mapBlock = 0
	word 				SSI_styleArray = 0
	word 				SSI_rowArray = 0
	word 				SSI_formatArray = 0
	word 				SSI_nameArray = 0
	word 				SSI_maxRow = MAX_ROW
	word 				SSI_maxCol = MAX_COLUMN
	PointDWord 			SSI_offset = {0, 0}
	CellRange 			SSI_visible = { {0, 0}, {0, 0} }
	CellReference 		SSI_active = {0, 0}
	CellRange 			SSI_quickSource = { {0, 0}, {0, 0} }
	CellRange 			SSI_selected = { {0, 0}, {0, 0} }
	word 				SSI_curAttrs = 0
	word 				SSI_gstate = NullHandle
	byte 				SSI_gsRefCount = 0
	SpreadsheetFlags 	SSI_flags = 0
	SpreadsheetDrawFlags 	SSI_drawFlags = 0
	byte 				SSI_attributes = 0
	CellRange 			SSI_header = { {-1, -1}, {-1, -1} }
	CellRange 			SSI_footer = { {-1, -1}, {-1, -1} }
	word 				SSI_circCount = 0
	FloatNum 			SSI_converge = 0
	word 				SSI_ancestorList = 0
	word 				SSI_childList = 0
	word 				SSI_finalList = 0
	optr 				SSI_ruler
	RectDWord 			SSI_bounds = {0, 0, 0, 0}

**Types and Flags**

	ByteFlags		NameFlags
		NF_UNDEFINED 					0x80
	MAX_NAME_LENGTH 					128
	MAX_NAME_DEF_LENGTH 					256
	ByteFlags		SpreadsheetDoubleClickFlags
		SDCF_NOTE_EXISTS 					0x02
		SDCF_CELL_EXISTS 					0x01
	WordFlags		SpreadsheetFlags
		SF_MANUAL_RECALC 					0x8000
		SF_ALLOW_ITERATION 					0x4000
		SF_SUPPRESS_REDRAW 					0x2000
		SF_APPLICATION_FUNCTIONS 			0x1000
		SF_QUICK_TRANS_IN_PROGRESS 			0x0800
		SF_DOING_FEEDBACK 					0x0400
		SF_IN_VIEW 							0x0200
		SF_IS_SYS_TARGET 					0x0008
		SF_HAVE_GRAB 						0x0004
		SF_IS_APP_TARGET 					0x0002
		SF_IS_SYS_FOCUS 					0x0001
	SRP_FLAGS		(SF_MANUAL_RECALC | SF_ALLOW_ITERATION)
	ByteFlags		SpreadsheetClearFlags
		SCF_CLEAR_ATTRIBUTES 				0x80
		SCF_CLEAR_DATA 						0x40
		SCF_CLEAR_NOTES 					0x20
	ByteFlags		SpreadsheetInsertFlags
		SIF_COLUMNS 					0x80
		SIF_COMPLETE 					0x40
		SIF_DELETE 						0x20
	WordFlags		SpreadsheetDrawFlags
		SDF_DRAW_GRAPHICS 					0x0008
		SDF_DRAW_NOTE_BUTTON 				0x0004
		SDF_DRAW_HEADER_FOOTER_BUTTON 		0x0002
		SDF_DRAW_GRID 						0x0001
	WordFlags		SpreadsheetPrintFlags
		SPF_PRINT_SIDEWAYS 					0x2000
		SPF_SCALE_TO_FIT 					0x1000
		SPF_PRINT_ROW_COLUMN_TITLES 		0x0800
		SPF_SKIP_DRAW 						0x0400
		SPF_CENTER_VERTICALLY 				0x0200
		SPF_CENTER_HORIZONTALLY 			0x0100
		SPF_CONTINUOUS 						0x0080
		SPF_PRINT_HEADER 					0x0040
		SPF_PRINT_FOOTER 					0x0020
		SPF_PRINT_DOCUMENT 					0x0010
		SPF_PRINT_NOTES 					0x0008
		SPF_PRINT_GRAPHICS 					0x0004
		SPF_DONE 							0x0002
		SPF_PRINT_GRID 						0x0001
	typedef enum /* word */ {
		SET_ENTIRE_SHEET = 0,
		SET_NO_EMPTY_CELLS = 2,
		SET_NO_EMPTY_CELLS_NO_HDR_FTR = 4,
		SET_NEXT_DATA_CELL = 6,
		SET_LAST_DATA_CELL = 8,
		SET_PREV_DATA_CELL = 10,
		SET_FIRST_DATA_CELL = 12
	} SpreadsheetExtentType
	ByteFlags		SpreadsheetSearchFlags
		SSF_MATCH_CASE 						0x80
		SSF_MATCH_PARTIAL_WORDS 			0x40
		SSF_SEARCH_FORMULAS 				0x20
		SSF_SEARCH_VALUES 					0x10
		SSF_SEARCH_NOTES 					0x08
		SSF_SEARCH_TEXT_OBJECTS 			0x04
		SSF_SEARCH_BY_ROWS 					0x02
	SPREADSHEET_MAX_SEARCH_STRING_LENGTH			128
	ByteEnum		SpreadsheetChartReturnType
		SCRT_TOO_MANY_CHARTS 					0
		SCRT_INSUFFICIENT_MEMORY 				2
		SCRT_NO_DATA 							4
	typedef enum /* word */ {
		SPREADSHEET_ADDRESS_ON_SCREEN = 0xf000,
		SPREADSHEET_ADDRESS_IN_SELECTION = 0xf001,
		SPREADSHEET_ADDRESS_DATA_AREA = 0xf100,
		SPREADSHEET_ADDRESS_PAST_END = 0xf101,
		SPREADSHEET_ADDRESS_USE_SELECTION = 0xf200,
		SPREADSHEET_ADDRESS_NIL = 0xffff
	} SpreadsheetAddress
	typedef enum /* word */ {
		SSFT_NUMBER,
		SSFT_DAY,
		SSFT_WEEKDAY,
		SSFT_MONTH,
		SSFT_YEAR
	} SpreadsheetSeriesFillType
	ByteFlags		SpreadsheetSeriesFillFlags
		SSFF_ROWS 						0x02
		SSFF_GEOMETRIC 					0x01
	ByteEnum		SpreadsheetFillError
		SFE_NO_ERROR 					0
		SFE_NOT_DATE_NUMER 				2
		SFE_DATE_STEP_TOO_LARGE 		4
	SPREADSHEET_MAX_DATE_FILL_STEP 				90
	SPREADSHEET_MIN_DATE_FILL_STEP 				-90
	ByteFlags		SpreadsheetAttributes
		SA_TARGETABLE 					0x80
		SA_ENGINE_MODE 					0x40
	MAX_ROW 					(8191+MIN_ROW)
	MAX_COLUMN 					(255+MIN_ROW)
	SSRCAF_TRANSFORM_VALID 				0x80
	SSRCAF_REF_COUNT 					0x7f
	MAX_GSTATE_REF_COUNT 				(SSRCAF_REF_COUNT)
	/* Border Info record */
	ByteFlags 		CellBorderInfo
		CBI_OUTLINE 				0x80
		CBI_LEFT 					0x08
		CBI_TOP 					0x04
		CBI_RIGHT 					0x02
		CBI_BOTTOM 					0x01
	ByteFlags		CellInfo
		CI_LOCKED 					0x04
		CI_JUSTIFICATION 			0x03
	J_GENERAL 						J_FULL
	ROW_HEIGHT_AUTOMATIC 			0x8000
	MIN_ROW 						0
	COLUMN_WIDTH_MIN 				0
	COLUMN_WIDTH_MAX 				512
	ROW_HEIGHT_MIN 					0
	ROW_HEIGHT_MAX 					(792*5/4)
	ByteFlags		NameFlags
		NF_UNDEFINED 				0x80
	MAX_NAMES 					255
	MAX_NAME_BLOCK_SIZE (sizeof(NameHeader) +
				(MAX_NAMES * (sizeof(NameStruct) +
				MAX_NAME_LENGTH)))
	ByteFlags		NameAccessFlags
		NAF_NAME 						0x80
		NAF_DEFINITION 					0x40
		NAF_BY_TOKEN 					0x20
		NAF_TOKEN_DEFINITION 					0x10
	NAME_ROW 					(LARGEST_ROW - 4)
	CHART_ROW 					(LARGEST_ROW - 3)
	FORMATTED_RANGE_BUFFER_SIZE 			14
	PSEE_RESULT_SHOULD_BE_CELL_OR_RANGE 	(PSEE_SSHEET_BASE)
	PSEE_NO_NAME_GIVEN 						(PSEE_SSHEET_BASE + 1)
	PSEE_NO_DEFINITION_GIVEN 				(PSEE_SSHEET_BASE + 2)
	PSEE_NAME_ALREADY_DEFINED 				(PSEE_SSHEET_BASE + 3)
	PSEE_BAD_NAME_DEFINITION 				(PSEE_SSHEET_BASE + 4)
	PSEE_REALLOC_FAILED 					(PSEE_SSHEET_BASE + 5)
	PSEE_LAST_SPREADSHEET_ERROR 			230
	PSEE_SSHEET_ERRORS 						PSEE_PARSER_ERRORS,
			PSEE_RESULT_SHOULD_BE_CELL_OR_RANGE,
			PSEE_NO_NAME_GIVEN,
			PSEE_NO_DEFINITION_GIVEN,
			PSEE_NAME_ALREADY_DEFINED,
			PSEE_BAD_NAME_DEFINITION,
			PSEE_REALLOC_FAILED
	NAME_LIST_INCREMENT 			2048
	CELL_GOTO_MAX_TEXT 				15
	CELL_MAX_TEXT 					255
	CELL_TEXT_BUFFER_SIZE 			(CELL_MAX_TEXT + size CellText)
	CELL_MAX_FORMULA 				256
	CELL_FORMULA_BUFFER_SIZE		(CELL_MAX_FORMULA + size CellFormula)
	SPREADSHEET_LIB_FUNCTIONID_ERRORS
			FUNCTION_ID_SPREADSHEET_CELL,
			FUNCTION_ID_LAST_SPREADSHEET_FUNCTION

**Structures**

	typedef struct {
		optr 			SSD_output
		Message 		SSD_message
		optr 			SSD_chartBody
	} SpreadsheetSetupData
	typedef struct {
		word 			GNI_token
		word 			GNI_entryNum
		word 			GNI_numDefinedNames
		word 			GNI_numUndefinedNames
	} GetNameInfo
	typedef struct {
		byte 		SNP_flags
		word 		SNP_listEntry
		word 		SNP_textLength
		char 		SNP_text[MAX_NAME_LENGTH]
		word 		SNP_defLength
		byte 		SNP_definition[MAX_NAME_DEF_LENGTH * 2]
		word 		SNP_token
		byte 		SNP_unused
	} SpreadsheetNameParams
	typedef struct {
		word 			GNI_unused
		word 			GNI_unused2
		word 			GNI_numDefinedNames
		word 			GNI_numUndefinedNames
	} GetNumNamesInfo
	typedef struct {
		word 			GNI_textSize
		word 			GNI_blockHandle
	} GetNoteInfo
	typedef struct {
		optr 			GTO_textObject
	} GetTextObject
	typedef struct {
		SpreadsheetFlags 	SRP_flags
		word 				SRP_circCount
		FloatNum 			SRP_converge
	} SpreadsheetRecalcParams
	typedef struct {
		word 			GFC_unused
		word 			GFC_unused2
		word 			GFC_numPreDefined
		word 			GFC_numUserDefined
	} GetFormatCount
	typedef struct {
		SpreadsheetPrintFlags 		SDP_flags
		word 						SDP_gstate
		CellReference 				SDP_topLeft
		RectDWord 					SDP_drawArea
		CellRange 					SDP_limit
		Point 						SDP_margins
		PointDWord 					SDP_translation
		PointDWord 					SDP_titleTrans
		WWFixed 					SDP_scale
		CellRange 					SDP_range
		RectDWord 					SDP_rangeArea
	} SpreadsheetDrawParams
	typedef struct {
		word 			GC_unused
		word 			GC_unused2
		word 			GC_cellRow
		word 			GC_cellColumn
	} GetActiveCell
	typedef struct {
		SpreadsheetSearchFlags 		SSP_flags
		char 						SSP_string[128]
		SpreadsheetSearchFlags 		SSP_found
		Point 						SSP_cell
		word 						SSP_startPos
		word 						SSP_endPos
	} SpreadsheetSearchParams
	typedef struct {
		word 			GC_unused
		word 			GC_errorCode
		word 			GC_row
		word 			GC_column
	} GetCell
	typedef struct {
		word 			SEFP_stacksSeg
		word 			SEFP_opStackPtr
		word 			SEFP_argStackPtr
		word 			SEFP_funcID
		word 			SEFP_nArgs
	} SpreadsheetEvalFuncParams
	typedef struct {
		CellRange 				SRP_selection
		CellReference 			SRP_active
	} SpreadsheetRangeParams
	typedef struct {
		SpreadsheetSeriesFillType 			SRP_type
		SpreadsheetSeriesFillFlags 			SRP_flags
		FloatNum 							SRP_stepValue
	} SpreadsheetSeriesFillParams
	typedef struct {
		char 				SSFPRP_text[MAX_RANGE_REF_SIZE]
		CellRange 			SSFPRP_range
	} SpreadsheetFormatParseRangeParams
	typedef struct {
		word 						SIFD_file
		word 						SIFD_numRows
		word 						SIFD_numCols
		SpreadsheetDrawFlags 		SIFD_drawFlags
	} SpreadsheetInitFileData
	typedef struct {
		ColorQuad 				AI_color
		SystemDrawMask 			AI_grayScreen
	} AreaInfo
	typedef struct {
		RefElementHeader 		CA_refCount
		AreaInfo 				CA_textAttrs
		AreaInfo 				CA_bkgrndAttrs
		FontID 					CA_font
		word 					CA_pointsize
		byte 					CA_style
		CellBorderInfo 			CA_border
		AreaInfo 				CA_borderAttrs
		CellInfo 				CA_info
		word 					CA_format
		BBFixed 				CA_trackKern
		byte 					CA_fontWeight
		byte 					CA_fontWidth
		byte 					CA_reserved[9]
	} CellAttrs
	typedef struct {
		word 			NH_blockSize
		word 			NH_definedCount
		word 			NH_undefinedCount
		word 			NH_nextToken
	} NameHeader
	typedef struct {
		byte 			NS_flags
		word 			NS_token
		word 			NS_length
	} NameStruct
	typedef struct {
		byte 		SNP_flags
		word 		SNP_listEntry
		word 		SNP_textLength
		byte 		SNP_text[MAX_NAME_LENGTH]
		word 		SNP_defLength
		byte 		SNP_definition[MAX_NAME_DEF_LENGTH*2]
		word 		SNP_token
		byte 		SNP_nameFlags
		byte 		SNP_unused
	} SpreadsheetNameParameters
	typedef struct {
		FormatParameters 	SFP_formatParams
		dword 				SFP_expression
		dword 				SFP_text
		word 				SFP_length
	} SpreadsheetFormatParams
	typedef struct {
		ParserParameters 	SPP_parserParams
		dword 				SPP_text
		dword 				SPP_expression
		word 				SPP_exprLength
	} SpreadsheetParserParams
	typedef struct {
		EvalParameters 		SEP_evalParams
		dword 				SEP_expression
		dword 				ArgumentStackElement
	} SpreadsheetEvalParams
	typedef struct {
		word 			NLH_endOfData
		word 			NLH_blockSize
	} NameListHeader
	typedef struct {
		word 			NLE_token
		byte 			NLE_flags
		byte 			NLE_unused
		word 			NLE_textLength
		word 			NLE_defLength
	} NameListEntry

**Messages**

	void MSG_SPREADSHEET_READ_CACHED_DATA(
				FileHandle fileHandle,
				word mapBlockHandle)
	void MSG_SPREADSHEET_WRITE_CACHED_DATA(
				FileHandle fileHandle)
	void MSG_SPREADSHEET_ATTACH_UI(
				word handle, FileHandle fileHandle)
	 void MSG_SPREADSHEET_ATTACH_FILE(
				word handle, FileHandle fileHandle)
	void MSG_SPREADSHEET_MOVE_ACTIVE_CELL(
				word row, word column)
	void MSG_SPREADSHEET_GOTO_CELL()
	word MSG_SPREADSHEET_ENTER_DATA(
				word textBlk, word textLen)
	void MSG_SPREADSHEET_SET_ROW_HEIGHT(word rowHeight)
	void MSG_SPREADSHEET_SET_COLUMN_WIDTH(word rowWidth)
	word MSG_SPREADSHEET_GET_ROW_HEIGHT(word rowNum)
	word MSG_SPREADSHEET_GET_COLUMN_WIDTH(word colNum)
	word MSG_SPREADSHEET_MAKE_FOCUS()
	MSG_SPREADSHEET_ADD_NAME_WITH_PARAM_BLK
	void MSG_SPREADSHEET_ADD_NAME(
				GetNameInfo *retValue,
				SpreadsheetNameParams *ssNameParams)
	void MSG_SPREADSHEET_VALIDATE_NAME(
				GetNameInfo *retValue,
				SpreadsheetNameParams *ssNameParams)
	MSG_SPREADSHEET_DELETE_NAME_WITH_LIST_ENTRY
	void MSG_SPREADSHEET_DELETE_NAME(
				GetNameInfo *retValue,
				SpreadsheetNameParams *ssNameParams)
	MSG_SPREADSHEET_CHANGE_NAME_WITH_PARAM_BLK
	void MSG_SPREADSHEET_CHANGE_NAME(
				GetNameInfo *retValue,
				SpreadsheetNameParams *ssNameParams)
	void MSG_SPREADSHEET_GET_NAME_COUNT(
				GetNumNamesInfo *retValue)
	void MSG_SPREADSHEET_GET_NAME_INFO(
				SpreadsheetNameParams *ssNameParams)
	void MSG_SPREADSHEET_FORMAT_EXPRESSION(
			SpreadsheetFormatParams *ssFormatParams)
	byte MSG_SPREADSHEET_PARSE_EXPRESSION(
			SpreadsheetParserParams *ssParserParams)
	MSG_SPREADSHEET_EVAL_EXPRESSION
	void MSG_SPREADSHEET_ERROR()
	void MSG_SPREADSHEET_SET_NOTE(word *textBlockHandle,
				word row, word column)
	void MSG_SPREADSHEET_SET_NOTE_FOR_ACTIVE_CELL(
				word *textBlockHandle)
	void MSG_SPREADSHEET_GET_NOTE(GetNoteInfo *retValue,
				word row, word column)
	void MSG_SPREADSHEET_GET_NOTE_FOR_ACTIVE_CELL(
				GetNoteInfo *retValue)
	void MSG_SPREADSHEET_DISPLAY_NOTE(word data)
	void MSG_SPREADSHEET_CHANGE_RECALC_PARAMS(
			SpreadsheetRecalcParams *ssRecalcParams)
	void MSG_SPREADSHEET_GET_RECALC_PARAMS(
			SpreadsheetRecalcParams *ssRecalcParams)
	void MSG_SPREADSHEET_RECALC()
	void MSG_SPREADSHEET_CLEAR_SELECTED(
			SpreadsheetClearFlags ssClearFlags)
	void MSG_SPREADSHEET_INSERT_SPACE(
			SpreadsheetInsertFlags ssInsertFlags)
	void MSG_SPREADSHEET_SET_NUM_FORMAT(word formatToken)
	void MSG_SPREADSHEET_DRAW_RANGE(
			SpreadsheetDrawParams *ssDrawParams)
	void MSG_SPREADSHEET_GET_EXTENT(
				CellRange *retValue,
				SpreadsheetExtentType ssExtentType)
	MSG_SPREADSHEET_GET_RANGE_BOUNDS
	void MSG_SPREADSHEET_SET_HEADER_RANGE(word flag)
	void MSG_SPREADSHEET_SET_FOOTER_RANGE(word flag)
	void MSG_SPREADSHEET_GET_HEADER_RANGE(
				CellRange *retValue)
	void MSG_SPREADSHEET_GET_FOOTER_RANGE(
				CellRange *retValue)
	void MSG_SPREADSHEET_COMPLETE_REDRAW()
	MSG_SPREADSHEET_NOTES_ENUM
	void MSG_SPREADSHEET_ALTER_DRAW_FLAGS(
				word bitsToSet, word bitsToClear)
	SpreadsheetDrawFlags MSG_SPREADSHEET_GET_DRAW_FLAGS()
	MSG_SPREADSHEET_HANDLE_SPECIAL_FUNCTION
	void MSG_SPREADSHEET_CHANGE_COLUMN_WIDTH(
				word change, word column)
	void MSG_SPREADSHEET_CHANGE_ROW_HEIGHT(
				word change, word row)
	FileHandle MSG_SPREADSHEET_GET_FILE()
	word MSG_SPREADSHEET_SORT_RANGE(
				RangeSortFlags rangeSortFlags)
	MSG_SPREADSHEET_FUNCTION_TO_TOKEN
	MSG_SPREADSHEET_FUNCTION_TO_CELL
	MSG_SPREADSHEET_FORMAT_FUNCTION
	MSG_SPREADSHEET_EVAL_FUNCTION
	void MSG_SPREADSHEET_CHART_RANGE(word chartNum)
	void MSG_SPREADSHEET_CHART_RANGE(word chartNum)
	void MSG_SPREADSHEET_DELETE_CHART(word chartNum)
	void MSG_SPREADSHEET_START_MOVE_COPY()
	void MSG_SPREADSHEET_END_MOVE_COPY()
	void MSG_SSHEET_INIT_FOR_EXPORT()
	void MSG_SPREADSHEET_SET_SELECTION(
			SpreadsheetRangeParams *ssRangeParams)
	void MSG_SPREADSHEET_EXTEND_CONTRACT_SELECTION(
			SpreadsheetRangeParams *ssRangeParams)
	void MSG_SPREADSHEET_GET_SELECTION(
			SpreadsheetRangeParams *ssRangeParams)
	void MSG_SSHEET_PASTE_FROM_DATA_FILE()
	void MSG_SSHEET_EXPORT_FROM_DATA_FILE()
	MSG_SPREADSHEET_INIT_NAME_LIST
	MSG_SPREADSHEET_INIT_CHOOSE_NAME_LIST
	MSG_SPREADSHEET_NAME_REQUEST_ENTRY_MONIKER
	MSG_SPREADSHEET_NAME_UPDATE_DEFINITION
	MSG_SPREADSHEET_NAME_UPDATE_NAME
	MSG_SPREADSHEET_GET_NAME_WITH_LIST_ENTRY
	MSG_SPREADSHEET_REPLACE_TEXT_SELECTION
	void MSG_SPREADSHEET_GET_ROW_AT_POSITION(sdword yPos)
	void MSG_SPREADSHEET_GET_COLUMN_AT_POSITION(sdword xPos)
	void MSG_SPREADSHEET_SET_CELL_BORDERS(
				CellBorderInfo border)
	void MSG_SPREADSHEET_SET_CELL_BORDER_COLOR(
				ColorQuad color)
	void MSG_SPREADSHEET_SET_CELL_BORDER_GRAY_SCREEN(
				SystemDrawMask drawMask)
	void MSG_SPREADSHEET_SET_CELL_BORDER_PATTERN(
				GraphicPattern pattern)
	SpreadsheetFillError MSG_SPREADSHEET_FILL_SERIES(
			SpreadsheetSeriesFillParams *fillParams)
	void MSG_SPREADSHEET_FILL_RANGE(SeriesFillFlags flags)
	void MSG_SPREADSHEET_PARSE_RANGE_REFERENCE(
			SpreadsheetFormatParseRangeParams *params)
	void MSG_SPREADSHEET_FORMAT_RANGE_REFERENCE(
			SpreadsheetFormatParseRangeParams *params)

**Routines**

	VMBlockHandle SpreadsheetInitFile(
				SpreadsheetInitFileData *ifd)
	void SpreadsheetParseNameToToken(
				C_CallbackStruct *cb_s)
	void SpreadsheetParseCreateCell(C_CallbackStruct *cb_s)
	void SpreadsheetParseEmptyCell(C_CallbackStruct *cb_s)
	void SpreadsheetParseDerefCell(C_CallbackStruct *cb_s)
	word SpreadsheetNameTextFromToken(
				SpreadsheetInstance *ssheet,
				word nameToken,
				char *destinationPtr,
				word maxCharsToWrite)
	Boolean SpreadsheetNameTokenFromText(
				SpreadsheetInstance *ssheet,
				char *nameText,
				word nameLen,
				word *tokenDest,
				NameFlags *flagsDest)
	word SpreadsheetNameLockDefinition(
				SpreadsheetInstance *ssheet,
				word nameToken,
				void **defaddr)
	void SpreadsheetCellAddRemoveDeps(
			SpreadsheetInstance *spreadsheetInstance,
			dword cellParams,
			PCB(void, callback,(C_CallbackStruct *)),
			word addOrRemoveDeps,
			word eval_flags,
			word row, word column, word maxRow,
			word maxColumn)
	void SpreadsheetRecalcDependents(
			SpreadsheetInstance *spreadsheetInstance,
			PCB(void, callback,(optr oself,
					word row, word column)),
			word row, word column)

## SpreadsheetRulerClass

	@class SpreadsheetRulerClass,VisRulerClass

**Instance Data**

	SpreadsheetRulerFlags				SRI_flags
	optr				SRI_spreadsheet
	word				SRI_resizeRC
	dword				SRI_startRCPos

**Types and Flags**

	SPREADSHEET_RULER_WIDTH				40
	SPREADSHEET_RULER_HEIGHT			12
	ByteFlags		SpreadsheetRulerFlags
		SRF_SSHEET_IS_FOCUS				0x8
		SRF_NO_INTERACTIVE_RESIZE		0x4
		SRF_SSHEET_IS_TARGET			0x2
		SRF_HAVE_GRAB					0x1

**Messages**

	void MSG_SPREADSHEET_RULER_DRAW_RANGE(
				SpreadsheetDrawParams *ssDrawParams)
	void MSG_SPREADSHEET_RULER_SET_FLAGS(
				SpreadsheetRulerFlags setFlags,
				SpreadsheetRulerFlags clearFlags)

## StyleSheetControlClass

	@class StyleSheetControlClass, GenControlClass

**Instance Data**

	ClassStruct		* SSCI_targetClass = NullClass
	ClassStruct		* SSCI_styledClass = NullClass
		@default GCI_output = (TO_APP_TARGET)

**Variable Data**

	GenFilePath ATTR_STYLE_SHEET_LOAD_STYLE_SHEET_PATH
	GeodeToken ATTR_STYLE_SHEET_LOAD_STYLE_SHEET_TOKEN
	optr TEMP_STYLE_SHEET_MANAGE_UI
	optr TEMP_STYLE_SHEET_DEFINE_UI
	SSCTempAttrInfo TEMP_SYTLE_SHEET_ATTR_TOKENS
	MemHandle TEMP_SYTLE_SHEET_SAVED_STYLE

**Types and Flags**

	WordFlags		SSCFeatures
		SSCF_DEFINE				0x0080
		SSCF_REDEFINE			0x0040
		SSCF_RETURN_TO_BASE		0x0020
		SSCF_APPLY				0x0010
		SSCF_MANAGE				0x0008
		SSCF_LOAD				0x0004
		SSCF_SAVE_STYLE			0x0002
		SSCF_RECALL_STYLE		0x0001
	WordFlags		SSCToolboxFeatures
		SSCTF_REDEFINE					0x0010
		SSCTF_RETURN_TO_BASE			0x0008
		SSCTF_STYLE_LIST				0x0004
		SSCTF_SAVE_STYLE				0x0002
		SSCTF_RECALL_STYLE				0x0001
	SSC_DEFAULT_FEATURES (SSCF_DEFINE | SSCF_REDEFINE
					| SSCF_RETURN_TO_BASE | SSCF_APPLY |
					SSCF_MANAGE | SSCF_LOAD | SSCF_SAVE_STYLE |
					SSCF_RECALL_STYLE)
	SSC_DEFAULT_TOOLBOX_FEATURES (SSCTF_STYLE_LIST |
					SSCTF_SAVE_STYLE | SSCTF_RECALL_STYLE)

**Structures**

	typedef struct {
		NameArrayMaxElement 				NSC_style
		word 		NSC_styleToken
		word 		NSC_usedIndex
		word 		NSC_usedToolIndex
		word 		NSC_styleSize
		word 		NSC_attrTokens[MAX_STYLE_SHEET_ATTRS]
		dword 		NSC_attrChecksums[MAX_STYLE_SHEET_ATTRS]
		byte 		NSC_indeterminate
		byte 		NSC_differsFromBase
		byte 		NSC_canReturnToBase
		word 		NSC_styleCounter
	} NotifyStyleChange
	typedef struct {
		StyleChunkDesc 		NSSHC_styleArray
		word 				NSSHC_counter
		word 				NSSHC_styleCount
		word 				NSSHC_toolStyleCount
	} NotifyStyleSheetChange
	typedef struct {
		word 		SSCTAI_attrTokens[MAX_STYLE_SHEET_ATTRS]
		word 		SSCTAI_baseStyle
		byte 		SSCTAI_differsFromBase
		byte 		SSCTAI_indeterminate
	} SSCTempAttrInfo

**Messages**

	void MSG_STYLE_SHEET_GET_MODIFY_UI()
	void MSG_STYLE_SHEET_GET_DEFINE_UI()
	void MSG_STYLE_SHEET_SET_SAVED_STYLE()
	void MSG_SSC_SELECT_STYLE()
	void MSG_SSC_STATUS_STYLE()
	void MSG_SSC_QUERY_STYLE()
	void MSG_SSC_QUERY_BASE_STYLE()
	void MSG_SSC_APPLY_STYLE()
	void MSG_SSC_APPLY_BOX_STYLE()
	void MSG_SSC_APPLY_TOOLBOX_STYLE()
	void MSG_SSC_INITIATE_MODIFY_STYLE()
	void MSG_SSC_MODIFY_STYLE()
	void MSG_SSC_DELETE_STYLE()
	void MSG_SSC_DELETE_REVERT_STYLE()
	void MSG_SSC_DEFINE_STYLE()
	void MSG_SSC_REDEFINE_STYLE()
	void MSG_SSC_RETURN_TO_BASE_STYLE()
	void MSG_SSC_LOAD_STYLE_SHEET()
	void MSG_SSC_LOAD_STYLE_SHEET_FILE_SELECTED()
	void MSG_SSC_SAVE_STYLE()
	void MSG_SSC_RECALL_STYLE()

## TextGuardianClass

	@class TextGuardianClass, GrObjVisGuardianClass

**Instance Data**

	TextGuardianFlags 	TGI_flags
	word 				TGI_desiredMinHeight
	word 				TGI_desiredMaxHeight

**Types and Flags**

	ByteFlags 		TextGuardianFlags
		TGF_ENFORCE_DESIRED_MIN_HEIGHT 							0x10
		TGF_ENFORCE_DESIRED_MAX_HEIGHT 							0x08
		TGF_DISABLE_ENFORCED_DESIRED_MAX_HEIGHT_WHILE_EDITING	0x04
		TGF_ENFORCE_MIN_DISPLAY_SIZE 							0x02
		TGF_SHRINK_WIDTH_TO_MIN_AFTER_EDIT 						0x01

**Messages**

	MSG_TG_CALC_DESIRED_MIN_HEIGHT
	MSG_TG_SET_DESIRED_MIN_HEIGHT
	MSG_TG_HEIGHT_NOTIFY
	MSG_TG_GENERATE_TEXT_NOTIFY
	MSG_TG_CALC_DESIRED_MAX_HEIGHT
	MSG_TG_SET_DESIRED_MAX_HEIGHT
	void MSG_TG_SET_TEXT_GUARDIAN_FLAGS(
				TextGuardianFlags flagsToSet,
				TextGuardianFlags flagsToReset)

## ThesControlClass

	@class ThesControlClass, GenControlClass

**Instance Data**

	void 		*TCI_meanings
	void 		*TCI_synonyms
	void 		*TCI_grammars
	void 		*TCI_backups
	word 		TCI_status
	char 		TCI_lastWord[MAX_ENTRY_LENGTH]
		@default GCI_output = (TO_APP_TARGET)
		@default GII_visibility = GIV_DIALOG
		@default GI_states = (@default | GS_ENABLED)

**Variable Data**

	void ATTR_THES_CONTROL_INTERACT_ONLY_WITH_TARGETED_TEXT_OBJECTS

**Types and Flags**

	MAX_BACKUP_LIST_SIZE 				30
	MAX_ENTRY_LENGTH 					26
	MAX_GRAMMAR_STRING 					7
	MAX_DEFINITIONS 					30
	MAX_DEFINITION_SIZE 				200
	MAX_MEANINGS_ARRAY_SIZE 			3000
	MAX_SYNONYM_SIZE 					26
	MAX_SYNONYMS 						80
	MAX_SYNONYMS_ARRAY_SIZE 			500
	WordFlags		ThesDictFeatures
		TDF_THESDICT 					0x01
		TC_GCM_FEATURES 				TDF_THESDICT
	WordFlags		ThesDictToolboxFeatures
		TDTF_THESDICT 					0x01
	TD_GCM_TOOLBOX_FEATURES 			(TDTF_THESDICT)

**Structures**

	typedef struct {
		word 			RSWP_numChars
		MemHandle 		RSWP_string
	} ReplaceSelectedWordParameters
	typedef struct {
		word 			SWP_type
		word 			SWP_numChars
		word 			SWP_message
		optr 			SWP_output
	} SelectWordParameters

**Messages**

	void MSG_THES_REPLACE_SELECTED_WORDS (@stack
				MemHandle RSWP_string,
				word RSWP_numChars)
	void MSG_THES_SELECT_WORD (@stack
				optr output, Message message,
				word numChars, word type)

## VisClass

	@class VisClass, MetaClass, master

**Instance Data**

	Rectangle		VI_bounds = {0, 0, 0, 0}
	VisTypeFlags		VI_typeFlags = 0
	VisAttrs		VI_attrs = (VA_MANAGED|VA_DRAWABLE|
					VA_DETECTABLE|VA_FULLY_ENABLED)
	VisOptFlags		VI_optFlags = (VOF_GEOMETRY_INVALID|
				VOF_GEO_UPDATE_PATH| VOF_WINDOW_INVALID|
				VOF_WINDOW_UPDATE_PATH| VOF_IMAGE_INVALID|
				VOF_IMAGE_UPDATE_PATH)
	VisGeoAttrs		VI_geoAttrs = 0
	SpecAttrs		VI_specAttrs = 0
	@link		VI_link

**Variable Data**

	Rectangle TEMP_VIS_OLD_BOUNDS
	VarGeoData ATTR_VIS_GEOMETRY_DATA
	word TEMP_VIS_INVAL_REGION

**Types and Flags**

	ByteFlags		DrawFlags
		DF_EXPOSED						0x80
		DF_OBJECT_SPECIFIC				0x40
		DF_PRINT						0x20
		DF_DONT_DRAW_CHILDREN			0x10
		DF_DISPLAY_TYPE					0x0f
	ByteFlags		ColorScheme
		CS_lightColor					0xf0
		CS_darkColor					0x0f
	CS_lightColor_OFFSET				4
	typedef enum {
		TO_VIS_PARENT = _FIRST_VisClass
	} VisTravelOption
	ByteEnum		VisUpdateMode
		VUM_MANUAL				0
		VUM_NOW				1
		VUM_DELAYED_VIA_UI_QUEUE				2
		VUM_DELAYED_VIA_APP_QUEUE				3
	ByteFlags		VisAttrs
		VA_VISIBLE					0x80
		VA_FULLY_ENABLED			0x40
		VA_MANAGED					0x20
		VA_DRAWABLE					0x10
		VA_DETECTABLE				0x08
		VA_BRANCH_NOT_MINIMIZABLE	0x04
		VA_OLD_BOUNDS_SAVED			0x02
		VA_REALIZED					0x01
	ByteFlags		VisOptFlags
		VOF_GEOMETRY_INVALID				0x80
		VOF_GEO_UPDATE_PATH					0x40
		VOF_IMAGE_INVALID					0x20
		VOF_IMAGE_UPDATE_PATH				0x10
		VOF_WINDOW_INVALID					0x08
		VOF_WINDOW_UPDATE_PATH				0x04
		VOF_UPDATE_PENDING					0x02
		VOF_EC_UPDATING						0x01
	ByteFlags		VisGeoAttrs
		VGA_GEOMETRY_CALCULATED				0x80
		VGA_NO_SIZE_HINTS					0x40
		VGA_NOTIFY_GEOMETRY_VALID			0x20
		VGA_DONT_CENTER						0x10
		VGA_USE_VIS_SET_POSITION			0x08
		VGA_USE_VIS_CENTER					0x04
		VGA_ONLY_RECALC_SIZE_WHEN_INVALID	0x02
		VGA_ALWAYS_RECALC_SIZE				0x01
	ByteFlags		VisTypeFlags
		VTF_IS_COMPOSITE					0x80
		VTF_IS_WINDOW						0x40
		VTF_IS_PORTAL						0x20
		VTF_IS_WIN_GROUP					0x10
		VTF_IS_CONTENT						0x08
		VTF_IS_INPUT_NODE					0x04
		VTF_IS_GEN							0x02
		VTF_CHILDREN_OUTSIDE_PORTAL_WIN		0x01
	ByteFlags		SpecAttrs
		SA_ATTACHED							0x80
		SA_REALIZABLE						0x40
		SA_BRANCH_MINIMIZED					0x20
		SA_USES_DUAL_BUILD					0x10
		SA_CUSTOM_VIS_PARENT				0x08
		SA_SIMPLE_GEN_OBJ					0x04
		SA_CUSTOM_VIS_PARENT_FOR_CHILD		0x02
		SA_TREE_BUILT_BUT_NOT_REALIZED		0x01
	ByteFlags		VisUpdateImageFlags
		VUIF_ALREADY_INVALID					0x80
		VUIF_ALWAYS_INVALIDATE					0x40
	ByteFlags		VisAddRectFlags
		VARF_NOT_IF_ALREADY_INVALID					0x80
		VARF_ONLY_REDRAW_MARGINS					0x40
	ByteFlags		VisInputFlowGrabFlags
		VIFGF_NOT_HERE				0x80
		VIFGF_FORCE					0x20
		VIFGF_GRAB					0x10
		VIFGF_KBD					0x08
		VIFGF_MOUSE					0x04
		VIFGF_LARGE					0x02
		VIFGF_PTR					0x01
	ByteEnum		VisInputFlowGrabType
		VIFGT_ACTIVE					0
		VIFGT_PRE_PASSIVE				1
		VIGFT_POST_PASSIVE				2
	ByteFlags		DrawMonikerFlags
		DMF_UNDERLINE_ACCELERATOR		0x40
		DMF_CLIP_TO_MAX_WIDTH			0x20
		DMF_NONE						0x10
		DMF_Y_JUST_MASK					0x0c
		DMF_X_JUST_MASK					0x03
	DMF_Y_JUST_OFFSET			2
	DMF_X_JUST_OFFSET			0
	WordFlags		VisMonikerSearchFlags
		VMSF_STYLE					0xf000
		VMSF_COPY_CHUNK				0x0400
		VMSF_REPLACE_LIST			0x0200
		VMSF_GSTRING				0x0100
	VMSF_STYLE_OFFSET				12
	WordFlags		SpecSizeSpec
		SSS_TYPE					0x8c00
		SSS_DATA					0x03ff
	WordFlags		SpecWidth
		SW_TYPE					0x8c00
		SW_DATA					0x03ff
	WordFlags		SpecHeight
		SH_TYPE					0x8c00
		SH_DATA					0x03ff
	SSS_TYPE_OFFSET			10
	SSS_DATA_OFFSET			0
	ByteEnum		SpecSizeType
		SST_PIXELS						0x0000
		SST_COUNT						0x0400
		SST_PCT_OF_FIELD_WIDTH			0x0800
		SST_PCT_OF_FIELD_HEIGHT			0x0c00
		SST_AVG_CHAR_WIDTHS				0x1000
		SST_WIDE_CHAR_WIDTHS			0x1400
		SST_LINES_OF_TEXT				0x1800
	PCT_0		0x000
	PCT_5		0x033
	PCT_10		0x066
	PCT_15		0x099
	PCT_20		0x0cc
	PCT_25		0x100
	PCT_30		0x133
	PCT_35		0x166
	PCT_40		0x199
	PCT_45		0x1cc
	PCT_50		0x200
	PCT_55		0x233
	PCT_60		0x266
	PCT_65		0x299
	PCT_70		0x2cc
	PCT_75		0x300
	PCT_80		0x333
	PCT_85		0x366
	PCT_90		0x399
	PCT_95		0x3cc
	PCT_100		0x3ff
	WordFlags		SpecWinSizeSpec
		SWSS_RATIO						0x8000
		SWSS_SIGN						0x4000
		SWSS_MANTISSA					0x3c00
		SWSS_FRACTION					0x03ff
	WordFlags		RecalcSizeArgs
		RSA_CHOOSE_OWN_SIZE				0x8000
		RSA_SUGGESTED_SIZE				0x7fff
	ByteEnum		WinPositionType
		WPT_AT_RATIO				0
		WPT_STAGGER					1
		WPT_CENTER					2
		WPT_TILED					3
		WPT_AT_MOUSE_POSITION		4
		WPT_AS_REQUIRED				5
	ByteEnum		WinSizeType
		WST_AS_RATIO_OF_PARENT					0
		WST_AS_RATIO_OF_FIELD					1
		WST_AS_DESIRED							2
		WST_EXTEND_TO_BOTTOM_RIGHT 				3
		WST_EXTEND_NEAR_BOTTOM_RIGHT			4
	ByteEnum		WinConstrainType
		WCT_NONE 							0
		WCT_KEEP_PARTIALLY_VISIBLE 			1
		WCT_KEEP_VISIBLE 					2
		WCT_KEEP_VISIBLE_WITH_MARGIN 		3
	WordFlags		WinPosSizeFlags
		WPSF_PERSIST						0x8000
		WPSF_HINT_FOR_ICON					0x4000
		WPSF_NEVER_SAVE_STATE				0x2000
		WPSF_SHRINK_DESIRED_SIZE_TO_FIT_IN_PARENT 0x1000
		WPSF_CONSTRAIN_TYPE					0x00c0
		WPSF_POSITION_TYPE					0x0038
		WPSF_SIZE_TYPE						0x0007
	dword SizeAsDWord
	ByteEnum		VMStyle
		VMS_TEXT					0
		VMS_ABBREV_TEXT				1
		VMS_GRAPHIC_TEXT			2
		VMS_ICON					3
		VMS_TOOL					4
	WordFlags		VisMonikerListEntryType
		VMLET_GS_SIZE					0x0300
		VMLET_STYLE						0x0f00
		VMLET_MONIKER_LIST				0x0080
		VMLET_GSTRING					0x0040
		VMLET_GS_ASPECT_RATIO			0x0030
		VMLET_GS_COLOR					0x000f
	VMT_GS_SIZE_OFFSET					12
	VMLET_STYLE_OFFSET					 8
	VMT_GS_ASPECT_RATIO_OFFSET			 4
	VMT_GS_COLOR_OFFSET					 0
	ByteFlags		VisMonikerType
		VMT_MONIKER_LIST				0x80
		VMT_GSTRING						0x40
		VMT_GS_ASPECT_RATIO				0x30
		VMT_GS_COLOR					0x0f
	WordFlags VisMonikerCachedWidth
		VMCW_HINTED					0x8000
		VMCW_BERKELEY_9				0x7f00
		VMCW_BERKELEY_10			0x00ff
	VMCW_BERKELEY_9_OFFSET			8
	VMCW_BERKELEY_10_OFFSET			0
	VMO_CANCEL						0xfd
	VMO_MNEMONIC_NOT_IN_MKR_TEXT	0xfe
	VMO_NO_MNEMONIC					0xff
	ByteFlags		CreateVisMonikerFlags
		CVMF_DIRTY					0x80
	ByteEnum		VisMonikerSourceType
		VMST_FPTR				0
		VMST_OPTR				1
		VMST_HPTR				2
	ByteEnum		VisMonikerDataType
		VMDT_NULL				0
		VMDT_VIS_MONIKER		1
		VMDT_TEXT				2
		VMDT_GSTRING			3
		VMDT_TOKEN				4
	WordFlags		SpecBuildFlags
		SBF_IN_UPDATE_WIN_GROUP				0x8000
		SBF_WIN_GROUP						0x4000
		SBF_TREE_BUILD						0x2000
		SBF_VIS_PARENT_WITHIN_SCOPE_OF_TREE_BUILD 0x1000
		SBF_SKIP_CHILD						0x0800
		SBF_FIND_LAST						0x0400
		SBF_VIS_PARENT_UNBUILDING			0x0200
		SBF_VIS_PARENT_FULLY_ENABLED		0x0100
		SBF_UPDATE_MODE						0x0003
	WordFlags		NavigationFlags
		NF_COMPLETED_CIRCUIT				0x8000
		NF_REACHED_ROOT						0x4000
		NF_NAV_MENU_BAR 					0x0020
		NF_INITIATE_QUERY 					0x0008
		NF_SKIP_NODE 						0x0004
		NF_TRAVEL_CIRCUIT 					0x0002
		NF_BACKTRACK_AFTER_TRAVELING 		0x0001
	ByteFlags		NavigateCommonFlags
		NCF_IS_COMPOSITE					0x80
		NCF_IS_FOCUSABLE					0x40
		NCF_IS_MENU_RELATED					0x20
		NCF_IS_INPUT_NODE					0x10
	ByteFlags		MenuSepFlags
		MSF_SEP							0x80
		MSF_USABLE						0x40
		MSF_FROM_CHILD					0x20
	WordFlags		GenBranchInfo
		GBI_USABLE						0x8000
		GBI_BRANCH_MINIMIZED			0x4000

**Structures**

	typedef struct {
		byte			DS_colorScheme
		byte			DS_displayType
		word			DS_unused
		FontID			DS_fontID
		sword			DS_pointSize
	} DisplayScheme
	typedef struct {
		word			GCP_aboveCenter
		word			GCP_belowCenter
		word			GCP_leftOfCenter
		word			GCP_rightOfCenter
	} GetCenterParams
	typedef struct {
		word			OAGP_grabFlags
		word			OAGP_unused
		optr			OAGP_object
	} ObjectAndGrabParams
	typedef struct {
		word			VMLE_type
		optr			VMLE_moniker
	} VisMonikerListEntry
	typedef struct {
		byte			VM_type
		word			VM_width
	} VisMoniker
	typedef struct {
		VisMoniker 			VMWGS_common
		word 			VMWGS_height
	} VisMonikerWithGString
	VMWGS_gString 			(sizeof(VisMonikerWithGString))
	typedef struct {
		VisMoniker 			VMWT_common
		char 			VMWT_mnemonicOffset
	} VisMonikerWithText
	VMWT_text 			(sizeof(VisMonikerWithText))
	typedef struct {
		word			ESP_extraWidth
		word			ESP_extraHeight
		word			ESP_leftoverChildren
		word			ESP_unused
	} ExtraSizeParams
	typedef struct {
		word			WSIP_windowWidth
		word 			WSIP_windowHeight
		byte 			WSIP_bottomArea
		byte 			WSIP_rightArea
		word 			WSIP_unused
	} WinSizeInfoParams
	typedef struct {
		optr				NCP_object
		NavigationFlags				NCP_navFlags
		NavigateCommonFlags				NCP_navCommonFlags
		ChunkHandle				NCP_genericData
	} NavigateCommonParams
	typedef struct {
		word			VCCIBF_data1
		word 			VCCIBF_data2
		word 			VCCIBF_data3
		word 			VCCIBF_data4
		word 			VCCIBF_data5
		Rectangle 			VCCIBF_bounds
	} VisCallChildrenInBoundsFrame
	typedef struct {
		SpecWinSizeSpec			SWSP_x
		SpecWinSizeSpec			SWSP_y
	} SpecWinSizePair
	typedef struct {
		word			VGD_lineWidth
		word 			VGD_centerOffset
		word 			VGD_secondWidth
	} VarGeoData

**Macros**

	visParent @parent word_offsetof(VisBase, Vis_offset),
				word_offsetof(VisInstance, VI_link)
	visChildren @children
				word_offsetof(VisBase, Vis_offset),
				word_offsetof(VisCompInstance, VCI_comp),
				word_offsetof(VisInstance, VI_link)
	DWORD_WIDTH(val) ((word) (val))
	DWORD_HEIGHT(val) ((word) (val >> 16))
	MAKE_SIZE_DWORD(width,height)
				((((dword) (height)) << 16) | (word) (width))

**Messages**

	@exportMessages VisSpecMessages,
					DEFAULT_EXPORTED_MESSAGES
	@exportMessages VisAppMessages,
					DEFAULT_EXPORTED_MESSAGES
	void MSG_VIS_DRAW(DrawFlags drawFlags, 
					GStateHandle gstate)
	void MSG_VIS_REDRAW_ENTIRE_OBJECT()
	GStateHandle MSG_VIS_VUP_CREATE_GSTATE()
	void MSG_VIS_VUP_QUERY()
	optr MSG_VIS_VUP_FIND_OBJECT_OF_CLASS(
				ClassStruct *class)
	void MSG_VIS_VUP_CALL_OBJECT_OF_CLASS(EventHandle event)
	void MSG_VIS_VUP_SEND_TO_OBJECT_OF_CLASS(
				EventHandle event)
	Boolean MSG_VIS_VUP_TEST_FOR_OBJECT_OF_CLASS(
				ClassStruct *class)
	void MSG_VIS_VUP_CALL_WIN_GROUP(EventHandle event)
	void MSG_VIS_VUP_SEND_TO_WIN_GROUP(EventHandle event)
	void MSG_VIS_SET_ATTRS(VisAttrs attrsToSet,
				VisAttrs attrsToClear,
				VisUpdateMode updateMode)
	void MSG_VIS_SET_GEO_ATTRS(VisGeoAttrs attrsToSet,
				VisGeoAttrs attrsToClear,
				VisUpdateMode updateMode)
	byte MSG_VIS_GET_GEO_ATTRS()
	VisOptFlags MSG_VIS_GET_OPT_FLAGS()
	void MSG_VIS_SET_TYPE_FLAGS(
				byte flagsToSet, byte flagsToClear)
	VisTypeFlags MSG_VIS_GET_TYPE_FLAGS()
	VisAttrs MSG_VIS_GET_ATTRS()
	XYValueAsDWord MSG_VIS_GET_POSITION()
	void MSG_VIS_SET_POSITION(word xOrigin, word yOrigin)
	void MSG_VIS_GET_BOUNDS(Rectangle *retValue)
	SizeAsDWord MSG_VIS_GET_SIZE()
	void MSG_VIS_SET_SIZE(word width, word height)
	void MSG_VIS_GET_CENTER(GetCenterParams *retValue)
	SizeAsDWord MSG_VIS_RECALC_SIZE(word width, word height)
	void MSG_VIS_POSITION_BRANCH(word xOrigin, word yOrigin)
	void MSG_VIS_NOTIFY_GEOMETRY_VALID()
	void MSG_VIS_BOUNDS_CHANGED(@stack
				word bottom, word right,
				word top, word left)
	void MSG_VIS_RESET_TO_INITIAL_SIZE(
				VisUpdateMode updateMode)
	SizeAsDWord MSG_VIS_RECALC_SIZE_AND_INVAL_IF_NEEDED(
				word width, word height)
	Boolean MSG_VIS_POSITION_AND_INVAL_IF_NEEDED(
				word xPosition, word yPosition)
	void MSG_VIS_MARK_INVALID(
				VisOptFlags flagsToSet,
				VisUpdateMode updateMode)
	Boolean MSG_VIS_VUP_UPDATE_WIN_GROUP(
				VisUpdateMode updateMode)
	void MSG_VIS_UPDATE_WIN_GROUP(VisUpdateMode updateMode)
	void MSG_VIS_UPDATE_GEOMETRY()
	void MSG_VIS_UPDATE_WINDOWS_AND_IMAGE(
			VisUpdateImageFlags updateImageFlags)
	void MSG_VIS_INVALIDATE()
	void MSG_VIS_ADD_RECT_TO_UPDATE_REGION(@stack
				byte unused, 
				VisAddRectFlags addRectFlags,
				word bottom, word right,
				word top, word left)
	void MSG_VIS_INVAL_TREE()
	void MSG_VIS_OPEN(WindowHandle window)
	void MSG_VIS_CLOSE()
	void MSG_VIS_DESTROY(VisUpdateMode updateMode)
	void MSG_VIS_REMOVE(VisUpdateMode updateMode)
	WindowHandle MSG_VIS_QUERY_WINDOW()
	void MSG_VIS_OPEN_WIN(WindowHandle parentWindow)
	void MSG_VIS_CLOSE_WIN()
	void MSG_VIS_WIN_ABOUT_TO_BE_CLOSED()
	void MSG_VIS_MOVE_RESIZE_WIN()
	void MSG_VIS_ADD_CHILD(optr child, CompChildFlags flags)
	void MSG_VIS_REMOVE_CHILD(optr child,
					CompChildFlags flags
	void MSG_VIS_MOVE_CHILD(optr child,
					CompChildFlags flags)
	word MSG_VIS_FIND_CHILD(optr object)
	optr MSG_VIS_FIND_CHILD_AT_POSITION(word position)
	word MSG_VIS_COUNT_CHILDREN()
	optr MSG_VIS_FIND_PARENT()
	void MSG_VIS_CALL_PARENT(EventHandle event)
	void MSG_VIS_SEND_TO_PARENT(EventHandle event)
	void MSG_VIS_SEND_TO_CHILDREN(EventHandle event)
	void MSG_VIS_GRAB_MOUSE()
	void MSG_VIS_FORCE_GRAB_MOUSE()
	void MSG_VIS_GRAB_LARGE_MOUSE()
	void MSG_VIS_FORCE_GRAB_LARGE_MOUSE()
	void MSG_VIS_RELEASE_MOUSE()
	void MSG_VIS_ADD_BUTTON_PRE_PASSIVE()
	void MSG_VIS_REMOVE_BUTTON_PRE_PASSIVE()
	void MSG_VIS_ADD_BUTTON_POST_PASSIVE()
	void MSG_VIS_REMOVE_BUTTON_POST_PASSIVE()
	void MSG_VIS_TAKE_GADGET_EXCL(optr child)
	void MSG_VIS_RELEASE_GADGET_EXCL(optr child)
	void MSG_VIS_LOST_GADGET_EXCL()
	void MSG_VIS_VUP_QUERY_FOCUS_EXCL(
				ObjectAndGrabParams *retValue)
	void MSG_VIS_FUP_QUERY_FOCUS_EXCL(
				ObjectAndGrabParams *retValue)
	void MSG_VIS_VUP_ALTER_INPUT_FLOW(@stack
				PointDWord translation,
				WindowHandle window, optr object,
				word grabTypeAndFlags)
	void MSG_VIS_VUP_SET_MOUSE_INTERACTION_BOUNDS(@stack
				word bottom, word right,
				word top, word left)
	word MSG_VIS_VUP_GET_MOUSE_STATUS()
	void MSG_VIS_VUP_TERMINATE_ACTIVE_MOUSE_FUNCTION()
	void MSG_VIS_VUP_BUMP_MOUSE(word xBump, word yBump)
	void MSG_VIS_VUP_ALLOW_GLOBAL_TRANSFER()
	void MSG_VIS_DRAW_MONIKER(@stack
				DrawMonikerFlags monikerFlags,
				ChunkHandle visMoniker,
				word textHeight,
				GStateHandle gstate,
				word yMaximum, word xMaximum,
				word yInset, word xInset)
	XYValueAsDWord MSG_VIS_GET_MONIKER_POS(@stack
				DrawMonikerFlags monikerFlags,
				ChunkHandle visMoniker,
				word textHeight,
				GStateHandle gstate,
				word yMaximum, word xMaximum,
				word yInset, word xInset)
	SizeAsDWord MSG_VIS_GET_MONIKER_SIZE(@stack
				byte monikerFlags,
				ChunkHandle visMoniker,
				word textHeight,
				GStateHandle gstate,
				word yMaximum, word xMaximum,
				word yInset, word xInset)
	optr MSG_VIS_FIND_MONIKER(@stack
				VisMonikerSearchFlags searchFlags,
				Handle destBlock,
				ChunkHandle monikerList,
				DisplayType displayType)
	ChunkHandle MSG_VIS_CREATE_VIS_MONIKER(@stack
				CreateVisMonikerFlags flags,
				word height, word width,
				word length,
				VisMonikerDataType dataType,
				VisMonikerSourceType sourceType,
				dword source)
	void MSG_VIS_VUP_EC_ENSURE_WINDOW_NOT_REFERENCED(
				WindowHandle window)
	void MSG_VIS_VUP_EC_ENSURE_OBJ_BLOCK_NOT_REFERENCED(
				MemHandle objBlock)
	void MSG_VIS_VUP_EC_ENSURE_OD_NOT_REFERENCED(
				optr object)
	void MSG_VIS_LAYER_SET_DOC_BOUNDS(@stack
				sdword bottom, sdword right,
				sdword top, sdword left)
	void MSG_VIS_LAYER_GET_DOC_BOUNDS(RectDWord *bounds)
	void MSG_VIS_QUERY_IF_OBJECT_HANDLES_INK(
			VisCallChildrenInBoundsFrame *data)
	void MSG_VIS_RECREATE_CACHED_GSTATES()
	void MSG_VIS_LAYER_INSERT_OR_DELETE_SPACE()
	void MSG_VIS_CREATE_CACHED_GSTATES()
	void MSG_VIS_DESTROY_CACHED_GSTATES()
	void MSG_VIS_ADD_NON_DISCARDABLE_VM_CHILD(
				optr child, CompChildFlags flags)
	void MSG_VIS_REMOVE_NON_DISCARDABLE_VM_CHILD(optr child)
	void MSG_VIS_REMOVE_NON_DISCARDABLE(
				VisUpdateMode updateMode)
	void MSG_VIS_INVAL_ALL_GEOMETRY(
				VisUpdateMode updateMode)
	void MSG_SPEC_BUILD(SpecBuildFlags flags = bp) /*XXX*/
	void MSG_SPEC_BUILD_BRANCH(SpecBuildFlags flags)
	void MSG_SPEC_UNBUILD_BRANCH(SpecBuildFlags flags)
	void MSG_SPEC_UNBUILD(SpecBuildFlags flags)
	optr MSG_SPEC_GET_VIS_PARENT(SpecBuildFlags flags)
	optr MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD(optr child)
	optr MSG_SPEC_GUP_QUERY_VIS_PARENT(word parentType)
	optr MSG_SPEC_GET_SPECIFIC_VIS_OBJECT(word flags)
	void MSG_SPEC_ADD_CHILD_RELATIVE_TO_GEN(@stack
				word buildFlags, optr parent,
				optr child)
	void MSG_SPEC_RESOLVE_MONIKER_LIST(
				ChunkHandle monikerList)
	void MSG_SPEC_RESOLVE_TOKEN_MONIKER(
				ChunkHandle monikerChunk)
	void MSG_SPEC_SET_ATTRS(SpecAttrs attrsToSet,
				SpecAttrs attrsToClear,
				VisUpdateMode updateMode)
	SpecAttrs MSG_SPEC_GET_ATTRS()
	void MSG_SPEC_SET_USABLE(byte updateMode)
	void MSG_SPEC_SET_NOT_USABLE(byte updateMode)
	Boolean MSG_SPEC_NOTIFY_ENABLED(
				byte updateMode, byte flags)
	Boolean MSG_SPEC_NOTIFY_NOT_ENABLED(
				byte updateMode, byte flags)
	void MSG_SPEC_UPDATE_VIS_MONIKER(byte updateMode,
				word oldMonikerWidth,
				word oldMonikerHeight)
	void MSG_SPEC_UPDATE_VISUAL(byte updateMode)
	void MSG_SPEC_GET_EXTRA_SIZE(word childCount,
				ExtraSizeParams *retValue)
	SizeAsDWord MSG_SPEC_CONVERT_DESIRED_SIZE_HINT(
				word desiredWidth,
				word desiredHeight,
				word childCount)
	word MSG_SPEC_CONVERT_SIZE(
				word specSize, GStateHandle gstate)
	void MSG_SPEC_VUP_GET_WIN_SIZE_INFO(
				WinSizeInfoParams *retValue)
	void MSG_SPEC_NAVIGATE_TO_NEXT_FIELD()
	void MSG_SPEC_NAVIGATE_TO_PREVIOUS_FIELD()
	void MSG_SPEC_NAVIGATE_COMMON(
			NavigateCommonParams *navCommonParams)
	Boolean MSG_SPEC_ACTIVATE_INTERACTION_DEFAULT()
	optr MSG_SPEC_NAVIGATE(word navigateFlags)
	void MSG_SPEC_NAVIGATION_QUERY(optr queryOrigin,
				NavigationFlags navFlags,
				NavigationQueryParams *retValue)
	void MSG_SPEC_NOTIFY_NAVIGATION_COMPLETE(
				NavigationFlags navigateFlags)
	Boolean MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC(
				word character, byte flags,
				word state)
	Boolean MSG_SPEC_CHECK_MNEMONIC(word character,
				byte flags, word state)
	byte MSG_SPEC_MENU_SEP_QUERY(byte flags)
	void MSG_SPEC_UPDATE_MENU_SEPARATORS()
	optr MSG_SPEC_START_BROADCAST_FOR_DEFAULT_FOCUS()
	void MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS(
				ObjectAndGrabParams *retValue)
	void MSG_SPEC_SCAN_GEOMETRY_HINTS()
	void MSG_SPEC_RESCAN_GEO_AND_UPDATE(
				VisUpdateMode updateMode)
	void MSG_SPEC_UPDATE_SPECIFIC_OBJECT()
	void MSG_SPEC_VIS_OPEN_NOTIFY()
	void MSG_SPEC_VIS_CLOSE_NOTIFY()
	dword MSG_SPEC_GET_MENU_CENTER()
	void MSG_SPEC_UPDATE_KBD_ACCELERATOR(
				VisUpdateMode updateMode)
	void MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN(
				VisUpdateMode updateMode)

## VisCompClass

	@class VisCompClass, VisClass

**Instance Data**

	@composite 					VCI_comp = VI_link
	optr						VCI_gadgetExcl
	WindowHandle				VCI_window = 0
	VisCompGeoAttrs 			VCI_geoAttrs = 0
	VisCompGeoDimensionAttrs 	VCI_geoDimensionAttrs = 0
		@default VI_typeFlags = VTF_IS_COMPOSITE

**Types and Flags**

	dword SpacingAsDWord
	WordFlags		VisCompSpacingMarginsInfo
		VCSMI_USE_THIS_INFO						0x8000
		VCSMI_LEFT_MARGIN						0x7000
		VCSMI_TOP_MARGIN						0x0e00
		VCSMI_RIGHT_MARGIN						0x01c0
		VCSMI_BOTTOM_MARGIN						0x0038
		VCSMI_CHILD_SPACING						0x0007
	VCSMI_LEFT_MARGIN_OFFSET					12
	VCSMI_TOP_MARGIN_OFFSET						9
	VCSMI_RIGHT_MARGIN_OFFSET					6
	VCSMI_BOTTOM_MARGIN_OFFSET					3
	VCSMI_CHILD_SPACING_OFFSET					0
	ByteEnum		WidthJustification
		WJ_LEFT_JUSTIFY_CHILDREN						0x00
		WJ_RIGHT_JUSTIFY_CHILDREN						0x40
		WJ_CENTER_CHILDREN_HORIZONTALLY					0x80
		WJ_FULL_JUSTIFY_CHILDREN_HORIZONTALLY			0xc0
	ByteEnum		HeightJustification
		HJ_TOP_JUSTIFY_CHILDREN							0x00
		HJ_BOTTOM_JUSTIFY_CHILDREN						0x04
		HJ_CENTER_CHILDREN_VERTICALLY					0x08
		HJ_FULL_JUSTIFY_CHILDREN_VERTICALLY				0x0c
	ByteFlags		VisCompGeoDimensionAttrs
		VCGDA_WIDTH_JUSTIFICATION						0xc0
		VCGDA_EXPAND_WIDTH_TO_FIT_PARENT				0x20
		VCGDA_DIVIDE_WIDTH_EQUALLY						0x10
		VCGDA_HEIGHT_JUSTIFICATION						0x0c
		VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT				0x02
		VCGDA_DIVIDE_HEIGHT_EQUALLY						0x01
	ByteFlags		VisCompGeoAttrs
		VCGA_ORIENT_CHILDREN_VERTICALLY					0x80
		VCGA_INCLUDE_ENDS_IN_CHILD_SPACING				0x40
		VCGA_ALLOW_CHILDREN_TO_WRAP						0x20
		VCGA_ONE_PASS_OPTIMIZATION						0x10
		VCGA_CUSTOM_MANAGE_CHILDREN						0x08
		VCGA_HAS_MINIMUM_SIZE							0x04
		VCGA_WRAP_AFTER_CHILD_COUNT						0x02
		VCGA_ONLY_DRAWS_IN_MARGINS						0x01

**Structures**

	typedef struct {
		word			CSP_childSpacing
		word			CSP_wrapSpacing
	} ChildSpacingParams

**Macros**

	DWORD_CHILD_SPACING(val) ((word) (val))
	DWORD_WRAP_SPACING(val) ((word) (val >> 16))
	MAKE_SPACING_DWORD(width,height)
			((((dword) (height)) << 16) | (width))

**Messages**

	word MSG_VIS_COMP_GET_GEO_ATTRS()
	void MSG_VIS_COMP_SET_GEO_ATTRS(
				word attrsToSet, word attrsToClear)
	SpacingAsDWord MSG_VIS_COMP_GET_CHILD_SPACING()
	SizeAsDWord MSG_VIS_COMP_GET_MINIMUM_SIZE()
	void MSG_VIS_COMP_GET_MARGINS(Rectangle *retValue)
	word MSG_VIS_COMP_GET_WRAP_COUNT()

## VisContentClass

	@class VisContentClass, VisCompClass

**Instance Data**

	optr 		VCNI_view
	WindowHandle		VCNI_window = 0
	word		VCNI_viewHeight = 0
	word		VCNI_viewWidth = 0
	VisContentAttrs VCNI_attrs = 0
	PointDWord		VCNI_docOrigin = {0, 0}
	PointWWFixed		VCNI_scaleFactor = { {0, 1}, {0, 1} }
	ChunkHandle		VCNI_prePassiveMouseGrabList = 0
	VisMouseGrab		VCNI_impliedMouseGrab =
				{0, 0, {0, 0},
				(VIFGF_MOUSE | VIFGF_PTR), 0}
	VisMouseGrab		VCNI_activeMouseGrab =
				{0, 0, {0, 0}, 0, 0}
	ChunkHandle		VCNI_postPassiveMouseGrabList = 0
	KbdGrab		VCNI_kbdGrab = {0, 0}
	FTVMCGrab		VCNI_focusExcl = {0, MAEF_FOCUS}
	FTVMCGrab		VCNI_targetExcl = {0, MAEF_TARGET}
	Handle		VCNI_holdUpInputQueue = 0
	word		VCNI_holdUpInputCount = 0
	byte		VCNI_holdUpInputFlags = 0
		@default VI_typeFlags = VTF_IS_COMPOSITE |
				VTF_IS_WINDOW | VTF_IS_CONTENT |
				VTF_IS_WIN_GROUP | VTF_IS_INPUT_NODE

**Types and Flags**

	ByteFlags		VisContentAttrs
		VCNA_SAME_WIDTH_AS_VIEW							0x80
		VCNA_SAME_HEIGHT_AS_VIEW						0x40
		VCNA_LARGE_DOCUMENT_MODEL						0x20
		VCNA_WINDOW_COORDINATE_MOUSE_EVENTS				0x10
		VCNA_ACTIVE_MOUSE_GRAB_REQUIRES_LARGE_EVENTS	0x08
		VCNA_VIEW_DOC_BOUNDS_SET_MANUALLY				0x04
		VCNA_VIEW_DOES_NOT_WIN_SCROLL					0x02

**Structures**

	typedef struct {
		optr 					VMG_object
		WindowHandle 			VMG_gWin
		PointDWord 				VMG_translation
		VisInputFlowGrabFlags 	VMG_flags
		byte 					VMG_unused
	} VisMouseGrab

**Messages**

	SizeAsDWord MSG_VIS_CONTENT_GET_WIN_SIZE()
	void MSG_VIS_CONTENT_SET_ATTRS(
				VisContentAttrs attrsToSet, 
				VisContentAttrs attrsToClear)
	VisContentAttrs MSG_VIS_CONTENT_GET_ATTRS()
	SizeAsDWord MSG_VIS_CONTENT_RECALC_SIZE_BASED_ON_VIEW()
	void MSG_VIS_CONTENT_HOLD_UP_INPUT_FLOW()
	void MSG_VIS_CONTENT_RESUME_INPUT_FLOW()
	void MSG_VIS_CONTENT_DISABLE_HOLD_UP()
	void MSG_VIS_CONTENT_ENABLE_HOLD_UP()
	Boolean MSG_VIS_CONTENT_TEST_IF_ACTIVE_OR_IMPLIED_WIN(
				WinHandle window)
	void MSG_VIS_CONTENT_UNWANTED_MOUSE_EVENT(
				VisMouseGrab *mouseGrab,
				word inputState)
	void MSG_VIS_CONTENT_UNWANTED_KBD_EVENT(
				word character, word flags,
				word state)
	void MSG_VIS_CONTENT_REMOTE_OBJ_MESSAGE_VIA_HOLD_UP_QUEUE()
	void MSG_VIS_CONTENT_SET_DOC_BOUNDS(@stack
				sdword bottom, sdword right,
				sdword top, sdword left)
	void MSG_VIS_CONTENT_NOTIFY_ACTIVE_MOUSE_GRAB_WIN_CHANGED()

## VisHorizRulerClass

	@class VisHorizRulerClass, VisRulerClass

## VisLargeTextClass

	@class VisLargeTextClass, VisTextClass

**Instance Data**

	ChunkHandle 				VLTI_regionArray
	VisLargeTextDisplayModes 	VLTI_displayMode
	word 						VLTI_regionSpacing
	XYSize 						VLTI_draftRegionSize
	dword 						VLTI_totalHeight
	word 						VLTI_displayModeWidth
	VisLargeTextFlags 			VLTI_flags
	VisLargeTextAttrs 			VLTI_attrs

**Types and Flags**

	WordFlags		VisLargeTextRegionFlags
		VLTRF_ENDED_BY_COLUMN_BREAK		0x8000
		VLTRF_EMPTY 					0x4000
	typedef enum {
		VLTDM_PAGE,
		VLTDM_CONDENSED,
		VLTDM_GALLEY,
		VLTDM_DRAFT_WITH_STYLES,
		VLTDM_DRAFT_WITHOUT_STYLES
	} VisLargeTextDisplayModes
	WordFlags		VisLargeTextFlags
		VLTF_HEIGHT_NOTIFY_PENDING 			0x8000
	WordFlags		VisLargeTextAttrs
		VLTA_EXACT_HEIGHT 					0x8000

**Structures**

	typedef struct {
		dword 					VLTRAE_charCount
		dword 					VLTRAE_lineCount
		word 					VLTRAE_section
		PointDWord 				VLTRAE_spatialPosition
		XYSize 					VLTRAE_size
		WBFixed 				VLTRAE_calcHeight
		dword 					VLTRAE_region
		VisLargeTextRegionFlags	VLTRAE_flags
		byte 					VLTRAE_reserved[3]
	} VisLargeTextRegionArrayElement

**Messages**

	void MSG_VIS_LARGE_TEXT_CREATE_DATA_STRUCTURES()
	void MSG_VIS_LARGE_TEXT_APPEND_REGION(word region)
	void MSG_VIS_LARGE_TEXT_REGION_IS_LAST(word region)
	void MSG_VIS_LARGE_TEXT_CURRENT_REGION_CHANGED(
				word region)
	void MSG_VIS_LARGE_TEXT_REGION_CHANGED(word region)
	void MSG_VIS_LARGE_TEXT_SET_DISPLAY_MODE(
				VisLargeTextDisplayModes mode)
	void MSG_VIS_LARGE_TEXT_SET_DRAFT_REGION_SIZE(
				word width, word height)
	XYValueAsDWord MSG_VIS_LARGE_TEXT_GET_DRAFT_REGION_SIZE(word 	region)
	word MSG_VIS_LARGE_TEXT_GET_REGION_COUNT()
	void MSG_VIS_LARGE_TEXT_GET_REGION_POS()
	void MSG_VIS_LARGE_TEXT_REGION_FROM_POINT()

## VisRulerClass

	@class VisRulerClass, VisCompClass, master

**Instance Data**

	VisRulerType			VRI_type
	MinIncrementType 		VRI_minIncrement
	WWFixed			VRI_scale
	sdword			VRI_offset
	sdword			VRI_margin

**Types and Flags**

	VIS_RULER_HEIGHT			10
	CUSTOM_RULER_DEFINITION		0xfd
	NO_RULERS					0xfe
	SYSTEM_DEFAULT				0xff
	ByteEnum		VisRulerType
		VRT_INCHES 				0
		VRT_CENTIMETERS 		1
		VRT_POINTS 				2
		VRT_PICAS				3
		VRT_CUSTOM 				CUSTOM_RULER_DEFINITION
		VRT_NONE 				NO_RULERS
		VRT_DEFAULT				SYSTEM_DEFAULT
	ByteEnum		MinUSMeasure
		MUSM_EIGHTH_INCH 			0
		MUSM_QUARTER_INCH 			1
		MUSM_HALF_INCH 				2
		MUSM_ONE_INCH 				3
	ByteEnum		MinMetricMeasure
		MMM_MILLIMETER 				0
		MMM_HALF_CENTIMETER			1
		MMM_CENTIMETER 				2
	ByteEnum		MinPointMeasure
		MPM_25_POINT 				0
		MPM_50_POINT 				1
		MPM_100_POINT 				2
	ByteEnum MinPicaMeasure
		MPM_PICA 			0
		MPM_INCH 			1

**Structures**

	typedef union {
		MinUSMeasure				MIT_US
		MinMetricMeasure			MIT_METRIC
		MinPointMeasure				MIT_POINT
		MinPicaMeasure				MIT_PICA
	} MinIncrementType

**Messages**

	void MSG_VIS_RULER_SET_TYPE(VisRulerType rulerType)
	void MSG_VIS_RULER_SET_MIN_INCREMENT(
				MinIncrementType minIncrementType)
	void MSG_VIS_RULER_SET_SCALE(WWFixed scaleFactor)
	void MSG_VIS_RULER_SET_OFFSET(sdword offset)
	void MSG_VIS_RULER_SET_MARGIN(sdword margin)

## VisTextClass

	@class VisTextClass, VisClass

**Instance Data**

	ChunkHandle 			VTI_text
	word 			VTI_charAttrRuns = VIS_TEXT_INITIAL_CHAR_ATTR
	word 			VTI_paraAttrRuns = VIS_TEXT_INITIAL_PARA_ATTR
	VMFileHandle 			VTI_vmFile = NullHandle
	word 					VTI_lines = 0
	VisTextStorageFlags 	VTI_storageFlags =
							(VTSF_DEFAULT_CHAR_ATTR |
							 VTSF_DEFAULT_PARA_ATTR)
	VisTextFeatures 		VTI_features = 0
	VisTextStates 			VTI_state = 0
	VisTextIntFlags 		VTI_intFlags = 0
	VisTextIntSelFlags 		VTI_intSelFlags = 0
	GSRefCountAndFlags 		VTI_gsRefCount = 0
	GStateHandle 			VTI_gstate = NullHandle
	word 			VTI_gstateRegion = -1
	dword 			VTI_selectStart = 0
	dword 			VTI_selectEnd = 0
	PointDWord 			VTI_startEventPos = {0,0}
	dword 			VTI_selectMinStart = 0
	dword 			VTI_selectMinEnd = 0
	dword 			VTI_lastOffset = 0
	word 			VTI_goalPosition = 0
	Point 			VTI_cursorPos = {0,0}
	word 			VTI_cursorRegion = 0
	word 			VTI_leftOffset = 0
	byte 			VTI_lrMargin = 0
	byte 			VTI_tbMargin = 0
	ColorQuad 		VTI_washColor = {C_WHITE, CF_INDEX, 0, 0}
	word 			VTI_maxLength = 10000
	VisTextFilters 	VTI_filters = 0
	optr 			VTI_output
	WBFixed 		VTI_height = {0,0}
	word 			VTI_lastWidth = -1
	TimerHandle 	VTI_timerHandle = NullHandle
	word 			VTI_timerID = 0

**Variable Data**

	word ATTR_VIS_TEXT_TYPE_RUNS
	word ATTR_VIS_TEXT_GRAPHIC_RUNS
	word ATTR_VIS_TEXT_STYLE_ARRAY
	word ATTR_VIS_TEXT_NAME_ARRAY
	VisTextSuspendData ATTR_VIS_TEXT_SUSPEND_DATA
	void ATTR_VIS_TEXT_NOTIFY_CONTENT
	word ATTR_VIS_TEXT_SELECTED_TAB
	void ATTR_VIS_TEXT_DO_NOT_INTERACT_WITH_SEARCH_CONTROL
	VisTextExtendedFilterType ATTR_VIS_TEXT_EXTENDED_FILTER
	word ATTR_VIS_TEXT_CHAR_ATTR_INSERTION_TOKEN
	word ATTR_VIS_TEXT_TYPE_INSERTION_TOKEN
	word ATTR_VIS_TEXT_TYPE_INSERTION_TOKEN
	VisTextCachedRunInfo TEMP_VIS_TEXT_CACHED_RUN_INFO
	void TEMP_VIS_TEXT_FORCE_SEND_IS_LAST_REGION
	VisTextCachedUndoInfo TEMP_VIS_TEXT_CACHED_UNDO_INFO
	ChunkHandle ATTR_VIS_TEXT_CUSTOM_FILTER
	void ATTR_VIS_TEXT_UPDATE_VIA_PROCESS
	void ATTR_VIS_TEXT_DOES_NOT_ACCEPT_INK
	WBFixed ATTR_VIS_TEXT_MINIMUM_SINGLE_LINE_HEIGHT
	void TEMP_VIS_TEXT_SYS_TARGET

**Types and Flags**

	SEARCH_REPLACE_TEXT_MAXIMUM 					65
	ByteFlags		SearchOptions
		SO_NO_WILDCARDS 						0x20
		SO_IGNORE_SOFT_HYPHENS 					0x10
		SO_BACKWARD_SEARCH 						0x08
		SO_IGNORE_CASE 							0x04
		SO_PARTIAL_WORD 						0x02
		SO_PRESERVE_CASE_OF_DOCUMENT_STRING 	0x01
	ByteEnum		WildCard
		WC_MATCH_SINGLE_CHAR						0x10
		WC_MATCH_MULTIPLE_CHARS						0x11
		WC_MATCH_WHITESPACE_CHAR					0x12
		TEXT_ADDRESS_PAST_END						0x00ffffff
		VIS_TEXT_RANGE_SELECTION					0xffff0000
		VIS_TEXT_RANGE_PARAGRAPH_SELECTION			0xfffe0000
	WordFlags		VisTextRangeContext
		VTRC_PARAGRAPH_CHANGE					0x8000
		VTRC_CHAR_ATTR_CHANGE					0x4000
		VTRC_PARA_ATTR_BORDER_CHANGE			0x2000
	ByteEnum		TextArrayType
		TAT_CHAR_ATTRS 					0
		TAT_PARA_ATTRS 					1
		TAT_GRAPHICS 					2
		TAT_TYPES 						3
	WordFlags 		TextStyleFlags
		TSF_APPLY_TO_SELECTION_ONLY					0x8000
		TSF_POINT_SIZE_RELATIVE						0x4000
		TSF_MARGINS_RELATIVE						0x2000
		TSF_SPACING_RELATIVE						0x1000
	WordFlags 		VisTextCharAttrFlags
		VTCAF_MULTIPLE_FONT_IDS						0x8000
		VTCAF_MULTIPLE_POINT_SIZES					0x4000
		VTCAF_MULTIPLE_COLORS						0x2000
		VTCAF_MULTIPLE_GRAY_SCREENS					0x1000
		VTCAF_MULTIPLE_PATTERNS						0x0800
		VTCAF_MULTIPLE_TRACK_KERNINGS				0x0400
		VTCAF_MULTIPLE_FONT_WEIGHTS					0x0200
		VTCAF_MULTIPLE_FONT_WIDTHS					0x0100
		VTCAF_MULTIPLE_BG_COLORS					0x0080
		VTCAF_MULTIPLE_BG_GRAY_SCREENS				0x0040
		VTCAF_MULTIPLE_BG_PATTERNS					0x0020
		VTCAF_MULTIPLE_STYLES						0x0010
	WordFlags 		VisTextGetAttrFlags
		VTGAF_MERGE_WITH_PASSED						0x8000
	WordFlags		VisTextParaAttrFlags
		VTPAF_MULTIPLE_LEFT_MARGINS					0x8000
		VTPAF_MULTIPLE_RIGHT_MARGINS				0x4000
		VTPAF_MULTIPLE_PARA_MARGINS					0x2000
		VTPAF_MULTIPLE_LINE_SPACINGS				0x1000
		VTPAF_MULTIPLE_DEFAULT_TABS					0x0800
		VTPAF_MULTIPLE_TOP_SPACING					0x0400
		VTPAF_MULTIPLE_BOTTOM_SPACING				0x0200
		VTPAF_MULTIPLE_LEADINGS						0x0100
		VTPAF_MULTIPLE_BG_COLORS					0x0080
		VTPAF_MULTIPLE_BG_GRAY_SCREENS				0x0040
		VTPAF_MULTIPLE_BG_PATTERNS					0x0020
		VTPAF_MULTIPLE_TAB_LISTS					0x0010
		VTPAF_MULTIPLE_STYLES						0x0008
		VTPAF_MULTIPLE_PREPEND_CHARS				0x0004
		VTPAF_MULTIPLE_PARA_NUMBERS					0x0002
	WordFlags 		VisTextParaAttrBorderFlags
		VTPABF_MULTIPLE_BORDER_LEFT					0x8000
		VTPABF_MULTIPLE_BORDER_TOP					0x4000
		VTPABF_MULTIPLE_BORDER_RIGHT				0x2000
		VTPABF_MULTIPLE_BORDER_BOTTOM				0x1000
		VTPABF_MULTIPLE_BORDER_DOUBLES				0x0800
		VTPABF_MULTIPLE_BORDER_DRAW_INNERS			0x0400
		VTPABF_MULTIPLE_BORDER_ANCHORS				0x0200
		VTPABF_MULTIPLE_BORDER_WIDTHS				0x0100
		VTPABF_MULTIPLE_BORDER_SPACINGS				0x0080
		VTPABF_MULTIPLE_BORDER_SHADOWS				0x0040
		VTPABF_MULTIPLE_BORDER_COLORS				0x0020
		VTPABF_MULTIPLE_BORDER_GRAY_SCREENS			0x0010
		VTPABF_MULTIPLE_BORDER_PATTERNS				0x0008
		VTTF_MULTIPLE_HYPERLINKS					0x8000
		VTTF_MULTIPLE_CONTEXTS						0x4000
	ByteEnum 		VisTextNameType
		VTNT_CONTEXT 					0
		VTNT_FILE 						1
	ByteEnum 		VisTextContextType
		VTCT_TEXT 						0
		VTCT_CATEGORY 					1
		VTCT_QUESTION 					2
		VTCT_ANSWER 					3
		VTCT_DEFINITION 				4
		VTCT_FILE 						255
		VIS_TEXT_GRAPHIC_OPAQUE_SIZE 	16
	ByteEnum 		VisTextGraphicType
		VTGT_GSTRING 					0
		VTGT_VARIABLE 					1
		VTGF_DRAW_FROM_BASELINE			0x8000
		VTGF_HANDLES_POINTER			0x4000
	ByteEnum 		VisTextSaveType
		VTST_NONE 						0
		VTST_SINGLE_CHUNK 				1
		VTST_RUNS_ONLY 					2
		VTST_RUNS_AND_ELEMENTS 				3
	WordFlags 		VisTextSaveDBFlags
		VTSDBF_TEXT						0x8000
		VTSDBF_CHAR_ATTR				0x6000
		VTSDBF_PARA_ATTR				0x1800
		VTSDBF_TYPE						0x0600
		VTSDBF_GRAPHIC					0x0180
		VTSDBF_STYLE					0x0040
		VTSDBF_REGION					0x0020
		VTSDBF_NAME						0x0010
	VTSDBF_CHAR_ATTR_OFFSET 			13
	VTSDBF_PARA_ATTR_OFFSET 			11
	VTSDBF_TYPE_OFFSET 					9
	VTSDBF_GRAPHIC_OFFSET 				7
	typedef enum {
		TCO_COPY,
		TCO_RETURN_TRANSFER_FORMAT,
		TCO_RETURN_TRANSFER_ITEM,
		TCO_RETURN_NOTHING
	} TextClipboardOption
	WordFlags 		VisTextNotificationFlags
		VTNF_SELECT_STATE					0x8000
		VTNF_CHAR_ATTR						0x4000
		VTNF_PARA_ATTR						0x2000
		VTNF_TYPE							0x1000
		VTNF_SELECTION						0x0800
		VTNF_COUNT							0x0400
		VTNF_STYLE_SHEET					0x0200
		VTNF_STYLE							0x0100
		VTNF_SEARCH_ENABLE					0x0080
		VTNF_SPELL_ENABLE					0x0040
	WordFlags 		VisTextNotifySendFlags
		VTNSF_UPDATE_APP_TARGET_GCN_LISTS		0x8000
		VTNSF_UPDATE_OUTPUT						0x4000
		VTNSF_NULL_STATUS						0x2000
		VTNSF_STRUCTURE_INITIALIZED				0x1000
		VTNSF_SEND_AFTER_GENERATION				0x0800
		VTNSF_SEND_ONLY							0x0400
		VTNSF_RELAYED_TO_LIKE_TEXT_OBJECTS		0x0200
		SS_DRAGGING								0x8000
		SS_CURSOR_HEIGHT						0x7fff
	ByteEnum 		VisTextExtendedFilterType
		VTEFT_REPLACE_PARAMS 0
		VTEFT_CHARACTER_LEVELER_LEVEL 1
		VTEFT_BEFORE_AFTER 2
	enum {
		GSSOT_FIRST_OBJECT,
		GSSOT_LAST_OBJECT,
		GSSOT_NEXT_OBJECT,
		GSSOT_PREV_OBJECT
	} GetSearchSpellObjectOption
	WordFlags 		GetSearchSpellObjectParam
		GSSOP_RELAYED_FLAG					0x8000
	enum {
		CL_STARTING_AT_POSITION,
		CL_ENDING_AT_POSITION,
		CL_CENTERED_AROUND_POSITION,
		CL_CENTERED_AROUND_SELECTION,
		CL_CENTERED_AROUND_SELECTION_START,
		CL_GET_SELECTED_WORD
	} ContextLocation
	ByteFlags 		SpellCheckFromOffsetFlags
		SCFOF_CHECK_NUM_CHARS					0x01
	ByteFlags 		SpellCheckFromOffsetFlags
		SFOF_STOP_AT_STARTING_POINT				0x01
	WordFlags 		ReplaceAllFromOffsetFlags
		RAFOF_CONTINUING_REPLACE				0x8000
		RAFOF_HAS_UNDO							0x4000
	ByteEnum 		VisTextFilterClass
		VTFC_NO_FILTER 						0
		VTFC_ALPHA 							1
		VTFC_NUMERIC 						2
		VTFC_SIGNED_NUMERIC 				3
		VTFC_SIGNED_DECIMAL 				4
		VTFC_FLOAT_DECIMAL 					5
		VTFC_ALPHA_NUMERIC 					6
		VTFC_FILENAMES 						7
		VTFC_DOS_FILENAMES 					8
		VTFC_DOS_PATH 						9
		VTFC_DATE 							10
		VTFC_TIME 							11
		VTFC_DASHED_ALPHA_NUMERIC 			12
		VTFC_NORMAL_ASCII 					13
		VTFC_DOS_VOLUME_NAMES 				14
		VTFC_DOS_CHARACTER_SET 				15
		VTFC_ALLOW_COLUMN_BREAKS 			16
	ByteFlags 		VisTextFilters
		VTF_NO_SPACES						0x80
		VTF_NO_TABS							0x40
		VTF_UPCASE_CHARS					0x20
		VTF_FILTER_CLASS					0x1f
	typedef enum /* word */ {
		VTKF_FORWARD_LINE=0,
		VTKF_BACKWARD_LINE=6,
		VTKF_SELECT_ADJUST_FORWARD_LINE=12,
		VTKF_SELECT_ADJUST_BACKWARD_LINE=18,
		VTKF_INSERT=24,
		VTKF_FORWARD_CHAR=30,
		VTKF_BACKWARD_CHAR=36,
		VTKF_FORWARD_WORD=42,
		VTKF_BACKWARD_WORD=48,
		VTKF_FORWARD_PARAGRAPH=54,
		VTKF_BACKWARD_PARAGRAPH=60,
		VTKF_START_OF_LINE=66,
		VTKF_END_OF_LINE=72,
		VTKF_START_OF_TEXT=78,
		VTKF_END_OF_TEXT=84,
		VTKF_SELECT_WORD=90,
		VTKF_SELECT_LINE=96,
		VTKF_SELECT_PARAGRAPH=102,
		VTKF_SELECT_OBJECT=108,
		VTKF_SELECT_ADJUST_FORWARD_CHAR=114,
		VTKF_SELECT_ADJUST_BACKWARD_CHAR=120,
		VTKF_SELECT_ADJUST_FORWARD_WORD=126,
		VTKF_SELECT_ADJUST_BACKWARD_WORD=132,
		VTKF_SELECT_ADJUST_FORWARD_PARAGRAPH=138,
		VTKF_SELECT_ADJUST_BACKWARD_PARAGRAPH=144,
		VTKF_SELECT_ADJUST_TO_START=150,
		VTKF_SELECT_ADJUST_TO_END=156,
		VTKF_SELECT_ADJUST_START_OF_LINE=162,
		VTKF_SELECT_ADJUST_END_OF_LINE=168,
		VTKF_DELETE_BACKWARD_CHAR=174,
		VTKF_DELETE_BACKWARD_WORD=180,
		VTKF_DELETE_BACKWARD_LINE=186,
		VTKF_DELETE_BACKWARD_PARAGRAPH=192,
		VTKF_DELETE_TO_START=198,
		VTKF_DELETE_CHAR=204,
		VTKF_DELETE_WORD=210,
		VTKF_DELETE_LINE=216,
		VTKF_DELETE_PARAGRAPH=222,
		VTKF_DELETE_TO_END=228,
		VTKF_DELETE_EVERYTHING=234,
		VTKF_DESELECT=240,
		VTKF_TOGGLE_OVERSTRIKE_MODE=246,
		VTKF_TOGGLE_SMART_QUOTES=252,
	} VisTextKeyFunction
	typedef enum /* word */ {
		TRT_POINTER,
		TRT_SEGMENT_CHUNK,
		TRT_BLOCK_CHUNK,
		TRT_BLOCK,
		TRT_VM_BLOCK,
		TRT_DB_ITEM,
		TRT_HUGE_ARRAY,
	} TextReferenceType
	INSERT_COMPUTE_TEXT_LENGTH				0x01ff
	/* Bitfield VisTextGetTextRangeFlags */
		VTGTRF_ALLOCATE						0x80
		VTGTRF_ALLOCATE_ALWAYS				0x40
		VTGTRF_RESIZE_DEST					0x20
	WordFlags 		VisTextHWRFlags
		VTHWRF_NO_CONTEXT					0x8000
		VTHWRF_USE_PASSED_CONTEXT			0x4000
	OFFSET_FOR_TYPE_RUNS 					0
	OFFSET_FOR_GRAPHIC_RUNS 				1
	WordFlags 		VisTextFeatures
		VTF_NO_WORD_WRAPPING				0x8000
		VTF_AUTO_HYPHENATE					0x4000
		VTF_ALLOW_SMART_QUOTES				0x2000
		VTF_ALLOW_UNDO						0x1000
		VTF_SHOW_HIDDEN_TEXT				0x0800
		VTF_OUTLINE_MODE					0x0400
		VTF_DONT_SHOW_SOFT_PAGE_BREAKS		0x0200
		VTF_DONT_SHOW_GRAPHICS				0x0100
		VTF_TRANSPARENT						0x0080
	ByteFlags 		VisTextStates
		VTS_EDITABLE							0x80
		VTS_SELECTABLE							0x40
		VTS_TARGETABLE							0x20
		VTS_ONE_LINE							0x10
		VTS_SUBCLASS_VIRT_PHYS_TRANSLATION		0x08
		VTS_OVERSTRIKE_MODE						0x04
		VTS_USER_MODIFIED						0x02
	ByteEnum 		SelectionType
		ST_DOING_CHAR_SELECTION 					0
		ST_DOING_WORD_SELECTION 					1
		ST_DOING_LINE_SELECTION 					2
		ST_DOING_PARA_SELECTION 					3
	ByteFlags 		VisTextIntSelFlags
		VTISF_IS_TARGET					0x80
		VTISF_IS_FOCUS					0x40
		VTISF_CURSOR_ON					0x20
		VTISF_CURSOR_ENABLED			0x10
		VTISF_DOING_SELECTION			0x08
		VTISF_DOING_DRAG_SELECTION		0x04
		VTISF_SELECTION_TYPE			0x03
	ByteEnum 		AdjustType
		AT_NORMAL 							0
		AT_NO_ADJUST 						1
		AT_PASTE 							2
		AT_QUICK 							3
		AT_ENTIRE_RANGE 					4
	ByteEnum 		ActiveSearchSpellType
		ASST_NOTHING_ACTIVE 				0
		ASST_SPELL_ACTIVE 					0
		ASST_SEARCH_ACTIVE 					0
	ByteFlags 		VisTextIntFlags
		VTIF_HAS_LINES						0x80
		VTIF_SUSPENDED						0x40
		VTIF_UPDATE_PENDING					0x20
		VTIF_ACTIVE_SEARCH_SPELL			0x18
		VTIF_HILITED						0x04
		VTIF_ADJUST_TYPE					0x03
	ByteFlags 		GSRefCountAndFlags
		GSRCAF_USE_DOC_CLIP_REGION			0x80
		GSRCAF_REF_COUNT					0x7f

**Structures**

	typedef struct {
		dword 				VTR_start
		dword 				VTR_end
	} VisTextRange
	typedef struct {
		ChunkArrayHeader 			TRAH_meta
		word 						TRAH_elementVMBlock
		ChunkHandle 				TRAH_elementArray
	} TextRunArrayHeader
	typedef struct {
		WordAndAHalf 				TRAE_position
		word 						TRAE_token
	} TextRunArrayElement
	typedef struct {
		ElementArrayHeader 			TEAH_meta
		TextArrayType 				TEAH_arrayType
		byte 						TEAH_unused
	} TextElementArrayHeader
	typedef struct {
		TextStyleFlags 				TSPD_flags
		byte 						TSPD_unused[2]
	} TextStylePrivateData
	typedef struct {
		NameArrayElement 			TSEH_meta
		word 						TSEH_baseStyle
		StyleElementFlags 			TSEH_flags
		TextStylePrivateData 		TSEH_privateData
		word 						TSEH_charAttrToken
		word 						TSEH_paraAttrToken
	} TextStyleElementHeader
	typedef struct {
		VisTextCharAttrFlags 				VTCAD_diffs
		VisTextExtendedStyles 				VTCAD_extendedStyles
		TextStyle 							VTCAD_textStyles
		byte 								VTCAD_unused
	} VisTextCharAttrDiffs
	typedef struct {
		VisTextParaAttrFlags 				VTPAD_diffs
		VisTextParaAttrBorderFlags 			VTPAD_borderDiffs
		VisTextParaAttrAttributes 			VTPAD_attributes
		VisTextHyphenationInfo 				VTPAD_hyphenationInfo
		VisTextKeepInfo 					VTPAD_keepInfo
		VisTextDropCapInfo 					VTPAD_dropCapInfo
	} VisTextParaAttrDiffs
	typedef struct {
		RefElementHeader 	VTT_meta
		word 				VTT_attributes
		word 				VTT_hyperlinkName
		word 				VTT_hyperlinkFile
		word 				VTT_context
		byte 				VTT_unused[1]
	} VisTextType
	typedef struct {
		word 				VTTD_diffs
		word 				VTTD_attributes
	} VisTextTypeDiffs
	typedef struct {
		VisTextNameType 			VTND_type
		VisTextContextType 			VTND_contextType
		word 						VTND_file
		DBGroupAndItem 				VTND_helpText
	} VisTextNameData
	typedef struct {
		TransMatrix 				VTGG_tmatrix
	} VisTextGraphicGString
	typedef struct {
		ManufacturerID 				VTGV_manufacturerID
		VisTextVariableType 		VTGV_type
		byte 		VTGV_privateData [VIS_TEXT_GRAPHIC_OPAQUE_SIZE-4]
	} VisTextGraphicVariable
	typedef union {
		VisTextGraphicGString 		VTGD_gstring
		VisTextGraphicVariable 		VTGD_variable
		byte 			VTGD_opaque [VIS_TEXT_GRAPHIC_OPAQUE_SIZE]
	} VisTextGraphicData
	typedef struct {
		RefElementHeader 		VTG_meta
		VMBlockHandle 			VTG_vmChain
		dword 					VTG_dbItem
		XYSize 					VTG_size
		VisTextGraphicType 		VTG_type
		word 					VTG_flags
		byte 					VTG_reserved[4]
		VisTextGraphicData 		VTG_data
	} VisTextGraphic
	typedef struct {
		StyleSheetParams 		VTSSSP_common
		word 					VTSSSP_graphicsElements
		word 					VTSSSP_treeBlock
		word 					VTSSSP_graphicTreeOffset
	} VisTextSaveStyleSheetParams
	typedef struct {
		VMChainTree 			TTBH_meta
		word 					TTBH_reservedOther[20]
		VMChain 				TTBH_text
		VMChain 				TTBH_charAttrRuns
		VMChain 				TTBH_paraAttrRuns
		VMChain 				TTBH_typeRuns
		VMChain 				TTBH_graphicRuns
		VMChain 				TTBH_charAttrElements
		VMChain 				TTBH_paraAttrElements
		VMChain 				TTBH_typeElements
		VMChain 				TTBH_graphicElements
		VMChain 				TTBH_styles
		VMChain 				TTBH_names
		VMChain 				TTBH_pageSetup
		VMChain 				TTBH_reservedVM[10]
	} TextTransferBlockHeader
	typedef struct {
		VMChainLink 		PSI_meta
		XYSize 				PSI_page
		PageLayout 			PSI_layout
		word 				PSI_numColumns
		word 				PSI_columnSpacing
		word 				PSI_ruleWidth
		word 				PSI_leftMargin
		word 				PSI_rightMargin
		word 				PSI_topMargin
		word 				PSI_bottomMargin
	} PageSetupInfo
	typedef struct {
		VisTextCharAttr 			VTNCAC_charAttr
		word 						VTNCAC_charAttrToken
		VisTextCharAttrDiffs 		VTNCAC_charAttrDiffs
	} VisTextNotifyCharAttrChange
	typedef struct {
		VisTextMaxParaAttr 		VTNPAC_paraAttr
		word 					VTNPAC_paraAttrToken
		VisTextParaAttrDiffs 	VTNPAC_paraAttrDiffs
		sdword 					VTNPAC_regionOffset
		sword 					VTNPAC_regionWidth
		word 					VTNPAC_selectedTab
	} VisTextNotifyParaAttrChange
	typedef struct {
		VisTextType 			VTNTC_type
		word 					VTNTC_typeToken
		VisTextTypeDiffs 		VTNTC_typeDiffs
	} VisTextNotifyTypeChange
	typedef struct {
		dword 				VTNSC_selectStart
		dword 				VTNSC_selectEnd
		dword 				VTNSC_lineNumber
		dword 				VTNSC_lineStart
		word 				VTNSC_region
		dword 				VTNSC_regionStartLine
		dword 				VTNSC_regionStartOffset
	} VisTextNotifySelectionChange
	typedef struct {
		dword 				VTNCC_charCount
		dword 				VTNCC_wordCount
		dword 				VTNCC_lineCount
		dword 				VTNCC_paraCount
	} VisTextNotifyCountChange
	typedef struct {
		VisTextNotificationFlags 	VTGNP_notificationTypes
		VisTextNotifySendFlags 		VTGNP_sendFlags
		MemHandle 					VTGNP_notificationBlocks[16]
	} VisTextGenerateNotifyParams
	typedef struct {
		WBFixed 				VTMDP_height
		WBFixed 				VTMDP_width
	} VisTextMinimumDimensionsParameters
	typedef struct { 
		word 				searchSize
		word 				replaceSize
		byte 				params
		optr 				replyObject
		Message 			replyMsg
	} SearchReplaceStruct
	typedef struct {
		optr 				CD_object
		dword 				CD_numChars
		dword 				CD_startPos
		VisTextRange 		CD_selection
	} ContextData
	typedef struct {
		optr 				SFORS_object
		dword 				SFORS_offset
		dword 				SFORS_len
	} SearchFromOffsetReturnStruct
	typedef struct {
		VisTextNameData 	VTNCP_data
		word 				VTNCP_index
		optr 				VTNCP_object
	} VisTextNameCommonParams
	typedef struct {
		dword 				VTGLOAFP_line
		dword 				VTGLOAFP_offset
		word 				VTGLOAFP_flags
	} VisTextGetLineOffsetAndFlagsParameters
	typedef struct {
		word 				VTSD_count
		VisTextRange 		VTSD_recalcRange
		VisTextRange 		VTSD_selectRange
		WordFlags 			VTSD_notifications
		byte 				VTSD_needsRecalc
	} VisTextSuspendData
	typedef struct {
		dword 				VTCRI_lastCharAttrRun
		dword 				VTCRI_lastParaAttrRun
		dword 				VTCRI_lastTypeRun
		dword 				VTCRI_lastGraphicRun
	} VisTextCachedRunInfo
	typedef struct {
		VMChain 				VTCUI_vmChain
		VMFileHandle 			VTCUI_file
	} VisTextCachedUndoInfo
	typedef struct {
		wchar 				VTCFD_startOfRange
		wchar 				VTCFD_endOfRange
	} VisTextCustomFilterData

**Messages**

	void MSG_VIS_TEXT_GET_RANGE(
				VisTextRange *range, word context)
	void MSG_VIS_TEXT_SET_CHAR_ATTR_BY_DEFAULT(@stack
				VisTextDefaultCharAttr defCharAttrs,
				dword rangeEnd, dword rangeStart)
	void MSG_VIS_TEXT_SET_CHAR_ATTR(@stack
				VisTextCharAttr *attrs,
				dword rangeEnd, dword rangeStart)
	MSG_VIS_TEXT_SET_CHAR_ATTR_BY_TOKEN
	MSG_VIS_TEXT_SET_FONT_ID
	MSG_VIS_TEXT_SET_FONT_WEIGHT
	MSG_VIS_TEXT_SET_FONT_WIDTH
	void MSG_VIS_TEXT_SET_POINT_SIZE(@stack
				WWFixedAsDWord pointSize,
				dword rangeEnd, dword rangeStart)
	MSG_VIS_TEXT_SET_SMALLER_POINT_SIZE
	MSG_VIS_TEXT_SET_LARGER_POINT_SIZE
	void MSG_VIS_TEXT_SET_TEXT_STYLE(@stack
				word extBitsToClear,
				word extBitsToSet,
				word styleBitsToClear,
				word styleBitsToSet,
				dword rangeEnd, dword rangeStart)
	MSG_VIS_TEXT_SET_COLOR
	MSG_VIS_TEXT_SET_GRAY_SCREEN
	MSG_VIS_TEXT_SET_PATTERN
	MSG_VIS_TEXT_SET_CHAR_BG_COLOR
	MSG_VIS_TEXT_SET_CHAR_BG_GRAY_SCREEN
	MSG_VIS_TEXT_SET_CHAR_BG_PATTERN(
	MSG_VIS_TEXT_SET_TRACK_KERNING
	word MSG_VIS_TEXT_GET_CHAR_ATTR(@stack
				VisTextGetAttrFlags flags,
				VisTextCharAttrDiffs *diffs,
				VisTextCharAttr *attrs,
				dword rangeEnd, dword rangeStart)
	MSG_VIS_TEXT_ADD_CHAR_ATTR
	MSG_VIS_TEXT_REMOVE_CHAR_ATTR
	void MSG_VIS_TEXT_SET_PARA_ATTR_BY_DEFAULT(@stack
				VisTextDefaultParaAttr defParaAttrs,
				dword rangeEnd, dword rangeStart)
	void MSG_VIS_TEXT_SET_PARA_ATTR(@stack 
				VisTextParaAttr *newParaAttrs,
				dword rangeEnd, dword rangeStart)
	MSG_VIS_TEXT_SET_PARA_ATTR_BY_TOKEN
	MSG_VIS_TEXT_SET_BORDER_BITS
	MSG_VIS_TEXT_SET_BORDER_WIDTH
	MSG_VIS_TEXT_SET_BORDER_SPACING
	MSG_VIS_TEXT_SET_BORDER_SHADOW
	MSG_VIS_TEXT_SET_BORDER_COLOR
	MSG_VIS_TEXT_SET_BORDER_GRAY_SCREEN
	MSG_VIS_TEXT_SET_BORDER_PATTERN
	void MSG_VIS_TEXT_SET_PARA_ATTRIBUTES(@stack
				word bitsToClear, word bitsToSet,
				dword rangeEnd, dword rangeStart)
	MSG_VIS_TEXT_SET_LINE_SPACING
	MSG_VIS_TEXT_SET_DEFAULT_TABS
	MSG_VIS_TEXT_SET_LEFT_MARGIN
	MSG_VIS_TEXT_SET_RIGHT_MARGIN
	MSG_VIS_TEXT_SET_PARA_MARGIN
	MSG_VIS_TEXT_SET_LEFT_AND_PARA_MARGIN
	MSG_VIS_TEXT_SET_SPACE_ON_TOP
	MSG_VIS_TEXT_SET_SPACE_ON_BOTTOM
	MSG_VIS_TEXT_SET_LEADING
	MSG_VIS_TEXT_SET_PARA_BG_COLOR
	MSG_VIS_TEXT_SET_PARA_BG_GRAY_SCREEN
	MSG_VIS_TEXT_SET_PARA_BG_PATTERN
	MSG_VIS_TEXT_SET_TAB
	MSG_VIS_TEXT_CLEAR_TAB
	MSG_VIS_TEXT_MOVE_TAB
	MSG_VIS_TEXT_CLEAR_ALL_TABS
	MSG_VIS_TEXT_SET_PREPEND_CHARS
	MSG_VIS_TEXT_SET_HYPHENATION_PARAMS
	MSG_VIS_TEXT_SET_DROP_CAP_PARAMS
	MSG_VIS_TEXT_SET_KEEP_PARAMS
	MSG_VIS_TEXT_SET_PARAGRAPH_NUMBER
	word MSG_VIS_TEXT_GET_PARA_ATTR(@stack
				VisTextGetAttrFlags flags,
				VisTextParaAttrDiffs *diffs,
				VisTextParaAttr *attrs,
				dword rangeEnd, dword rangeStart)
	word MSG_VIS_TEXT_ADD_PARA_ATTR(
				VisTextMaxParaAttr *paraAttr)
	MSG_VIS_TEXT_REMOVE_PARA_ATTR
	MSG_VIS_TEXT_SUBST_ATTR_TOKEN
	MSG_VIS_TEXT_RECALC_FOR_ATTR_CHANGE
	MSG_VIS_TEXT_SET_HYPERLINK
	MSG_VIS_TEXT_SET_CONTEXT
	word MSG_VIS_TEXT_GET_TYPE(@stack
				VisTextGetAttrFlags flags,
				VisTextTypeDiffs *diffs,
				VisTextType *attrs,
				dword rangeEnd, dword rangeStart)
	MSG_VIS_TEXT_ADD_TYPE
	MSG_VIS_TEXT_REMOVE_TYPE
	MSG_VIS_TEXT_ADD_NAME
	MSG_VIS_TEXT_FIND_NAME
	MSG_VIS_TEXT_FIND_NAME_BY_TOKEN
	MSG_VIS_TEXT_ADD_REF_FOR_NAME
	MSG_VIS_TEXT_REMOVE_NAME*/
	MSG_VIS_TEXT_REPLACE_WITH_GRAPHIC
	void MSG_VIS_TEXT_GET_GRAPHIC_AT_POSITION(@stack
				VisTextGraphic *retPtr,
				dword position)
	MSG_VIS_TEXT_GRAPHIC_VARIABLE_SIZE
	MSG_VIS_TEXT_GRAPHIC_VARIABLE_DRAW
	MSG_VIS_TEXT_GRAPHIC_VARIABLE_START_SELECT
	MSG_VIS_TEXT_GRAPHIC_VARIABLE_OPEN
	MSG_VIS_TEXT_GRAPHIC_VARIABLE_CLOSE
	DBGroupAndItem MSG_VIS_TEXT_SAVE_TO_DB_ITEM(
				DBGroupAndItem item,
				VisTextSaveDBFlags flags)
	@alias (MSG_VIS_TEXT_SAVE_TO_DB_ITEM) DBGroupAndItem
		MSG_VIS_TEXT_SAVE_TO_DB_GROUP_ITEM(
				DBGroup group, DBItem item,
				VisTextSaveDBFlags flags)
	DBGroupAndItem
		MSG_VIS_TEXT_SAVE_TO_DB_ITEM_WITH_STYLES(@stack
				FileHandle xferFile,
				VisTextSaveDBFlags flags,
				DBGroupAndItem item,
				StyleSheetParams *params)
	void MSG_VIS_TEXT_LOAD_FROM_DB_ITEM(DBGroupAndItem item,
				VMFileHandle file)
	@alias (MSG_VIS_TEXT_LOAD_FROM_DB_ITEM) void
		MSG_VIS_TEXT_LOAD_FROM_DB_GROUP_ITEM(
				DBGroup group, DBItem item,
				VMFileHandle file)
	void MSG_VIS_TEXT_LOAD_FROM_DB_ITEM_WITH_STYLES(@stack
				FileHandle file,
				DBGroupAndItem item,
				StyleSheetParams *params)
	void MSG_VIS_TEXT_SET_VM_FILE(VMFileHandle file)
	MSG_VIS_TEXT_CREATE_STORAGE
	MSG_VIS_TEXT_CHANGE_ELEMENT_ARRAY
	MSG_VIS_TEXT_FREE_STORAGE 
	MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT(@stack
				VMBlockHandle block,
				VMFileHandle file, word pasteFrame,
				dword end, dword start)
	MSG_VIS_TEXT_CREATE_TRANSFER_FORMAT
	void MSG_VIS_TEXT_REPLACE_ALL_PTR(
				const char *text, word textLen)
	void MSG_VIS_TEXT_REPLACE_ALL_OPTR(optr o, word textLen)
	void MSG_VIS_TEXT_REPLACE_ALL_BLOCK(
				word block, word textLen)
	void MSG_VIS_TEXT_REPLACE_ALL_VM_BLOCK(
				VMFileHandle file,
				VMBlockHandle block, word textLen)
	void MSG_VIS_TEXT_REPLACE_ALL_DB_ITEM(VMFileHandle file,
				DBGroup group, DBItem item)
	void MSG_VIS_TEXT_REPLACE_ALL_HUGE_ARRAY(
				VMFileHandle file,
				VMBlockHandle hugeArrayBlock,
				word textLen)
	void MSG_VIS_TEXT_REPLACE_SELECTION_PTR(
				const char *text, word textLen)
	void MSG_VIS_TEXT_REPLACE_SELECTION_OPTR(
				optr o, word textLen)
	void MSG_VIS_TEXT_REPLACE_SELECTION_BLOCK(
				word block, word textLen)
	void MSG_VIS_TEXT_REPLACE_SELECTION_VM_BLOCK(
				VMFileHandle file,
				VMBlockHandle block, word textLen)
	void MSG_VIS_TEXT_REPLACE_SELECTION_DB_ITEM(
				VMFileHandle file,
				DBGroup group, DBItem item)
	void MSG_VIS_TEXT_REPLACE_SELECTION_HUGE_ARRAY(
				VMFileHandle file,
				VMBlockHandle hugeArrayBlock,
				word textLen)
	void MSG_VIS_TEXT_APPEND_PTR(
				const char *text, word textLen)
	void MSG_VIS_TEXT_APPEND_OPTR(optr o, word textLen)
	void MSG_VIS_TEXT_APPEND_BLOCK(word block, word textLen)
	void MSG_VIS_TEXT_APPEND_VM_BLOCK(VMFileHandle file,
				VMBlockHandle block, word textLen)
	void MSG_VIS_TEXT_APPEND_DB_ITEM(VMFileHandle file,
				DBGroup group, DBItem item)
	void MSG_VIS_TEXT_APPEND_HUGE_ARRAY(VMFileHandle file,
				VMBlockHandle hugeArrayBlock,
				word textLen)
	word MSG_VIS_TEXT_GET_ALL_PTR(const char *text)
	word MSG_VIS_TEXT_GET_ALL_OPTR(optr o)
	word MSG_VIS_TEXT_GET_ALL_BLOCK(word block)
	word MSG_VIS_TEXT_GET_ALL_VM_BLOCK(VMFileHandle file,
				VMBlockHandle block)
	DBGroupAndItem MSG_VIS_TEXT_GET_ALL_DB_ITEM(
				VMFileHandle file,
				DBGroup group, DBItem item)
	word MSG_VIS_TEXT_GET_ALL_HUGE_ARRAY(VMFileHandle file,
				VMBlockHandle hugeArrayBlock,
				word textLen)
	word MSG_VIS_TEXT_GET_SELECTION_PTR(char *text)
	word MSG_VIS_TEXT_GET_SELECTION_OPTR(optr o)
	word MSG_VIS_TEXT_GET_SELECTION_BLOCK(word block)
	word MSG_VIS_TEXT_GET_SELECTION_VM_BLOCK(
				VMFileHandle file,
				VMBlockHandle block)
	DBGroupAndItem MSG_VIS_TEXT_GET_SELECTION_DB_ITEM(
				VMFileHandle file,
				DBGroup group, DBItem item)
	word MSG_VIS_TEXT_GET_SELECTION_HUGE_ARRAY(
				VMFileHandle file,
				VMBlockHandle hugeArrayBlock,
				word textLen)
	void MSG_VIS_TEXT_DELETE_ALL()
	void MSG_VIS_TEXT_DELETE_SELECTION()
	void MSG_VIS_TEXT_GET_SELECTION_RANGE(VisTextRange *vtr)
	void MSG_VIS_TEXT_SELECT_RANGE_SMALL(
				word start, word end)
	void MSG_VIS_TEXT_SELECT_ALL()
	void MSG_VIS_TEXT_SELECT_START()
	void MSG_VIS_TEXT_SELECT_END()
	void MSG_VIS_TEXT_SELECT_RELATIVE(
				word newStart, word newEnd)
	VisTextStates MSG_VIS_TEXT_GET_STATE()
	VisTextFeatures MSG_VIS_TEXT_GET_FEATURES()
	void MSG_VIS_TEXT_SET_FEATURES(
				VisTextFeatures bitsToSet,
				VisTextFeatures bitsToClear)
	void MSG_VIS_TEXT_SET_MAX_LENGTH(word newMaxLength)
	word MSG_VIS_TEXT_GET_MAX_LENGTH()
	word MSG_VIS_TEXT_GET_USER_MODIFIED_STATE()
	void MSG_VIS_TEXT_SET_NOT_USER_MODIFIED()
	void MSG_VIS_TEXT_SET_USER_MODIFIED()
	MSG_VIS_TEXT_SET_WASH_COLOR
	MSG_VIS_TEXT_GET_WASH_COLOR
	void MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE(
				VisTextStates setBits,
				VisTextStates clearBits)
	MSG_VIS_TEXT_UPDATE_GENERIC
	void MSG_VIS_TEXT_GENERATE_NOTIFY(
				VisTextGenerateNotifyParams *params)
	MSG_VIS_TEXT_CHAR_ATTR_VIRTUAL_TO_PHYSICAL
	MSG_VIS_TEXT_PARA_ATTR_VIRTUAL_TO_PHYSICAL
	void MSG_META_TEXT_USER_MODIFIED(optr obj)
	void MSG_META_TEXT_CR_FILTERED(
				word character, word flags,
				word state)
	void MSG_META_TEXT_TAB_FILTERED(
				word character, word flags,
				word state)
	void MSG_META_TEXT_LOST_FOCUS(optr obj)
	void MSG_META_TEXT_GAINED_FOCUS(optr obj)
	void MSG_META_TEXT_LOST_TARGET(optr obj)
	void MSG_META_TEXT_GAINED_TARGET(optr obj)
	void MSG_META_TEXT_EMPTY_STATUS_CHANGED(
				optr object, Boolean hasTextFlag)
	void MSG_META_TEXT_NOT_USER_MODIFIED(optr obj)
	MSG_VIS_TEXT_EDIT_DRAW
	MSG_VIS_TEXT_SHOW_SELECTION
	void MSG_VIS_TEXT_HEIGHT_NOTIFY(word newHeight)
	MSG_VIS_TEXT_ENTER_OVERSTRIKE_MODE
	void MSG_VIS_TEXT_ENTER_INSERT_MODE(
				Boolean calledFromTextObject)
	void MSG_VIS_TEXT_GET_MINIMUM_DIMENSIONS(
				VisTextMinimumDimensionsParameters *params)
	MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS
	word MSG_VIS_TEXT_FILTER_VIA_CHARACTER(
				word charToFilter)
	MSG_VIS_TEXT_FILTER_VIA_BEFORE_AFTER
	MSG_VIS_TEXT_LOAD_STYLE_SHEET
	MSG_VIS_TEXT_LOAD_STYLE_SHEET_PARAMS
	word MSG_VIS_TEXT_GET_MIN_WIDTH()
	word MSG_VIS_TEXT_GET_AVERAGE_CHAR_WIDTH()
	MSG_VIS_TEXT_CALC_HEIGHT
	word MSG_VIS_TEXT_GET_LINE_HEIGHT()
	void MSG_VIS_TEXT_RECALC_AND_DRAW()
	word MSG_VIS_TEXT_GET_ONE_LINE_WIDTH(word charsToCalc)
	word MSG_VIS_TEXT_GET_SIMPLE_MIN_WIDTH()
	optr MSG_META_GET_OBJECT_FOR_SEARCH_SPELL(G
				etSearchSpellObjectOption option,
				optr curObject)
	void MSG_META_GET_CONTEXT(@stack
				dword position,
				ContextLocation location,
				word numCharsToGet, optr replyObj)
	void MSG_META_GENERATE_CONTEXT_NOTIFICATION (@stack
				dword position,
				ContextLocation location,
				word numCharsToGet, optr replyObj)
	void MSG_META_CONTEXT(MemHandle data)
	void MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL()
	MSG_VIS_TEXT_SCROLL_ONE_LINE
	MSG_VIS_TEXT_GET_SCROLL_AMOUNT
	MSG_VIS_TEXT_SCROLL_PAGE_UP
	MSG_VIS_TEXT_SCROLL_PAGE_DOWN
	MSG_VIS_TEXT_SCREEN_UPDATE
	MSG_VIS_TEXT_FLASH_CURSOR_ON
	MSG_VIS_TEXT_FLASH_CURSOR_OFF
	void MSG_VIS_TEXT_SPELL_CHECK_FROM_OFFSET(@stack
				optr replyObject, dword startOffset,
				dword numCharsToCheck,
				byte spellCheckFlags,
				MemHandle icBuff)
	void MSG_VIS_TEXT_SEARCH_FROM_OFFSET(@stack
				SearchFromOffsetReturnStruct *retStruct,
				byte searchFromOffsetFlags,
				dword currentOffset, dword startOffset,
				dword startObject,
				MemHandle searchReplaceStruct)
	word MSG_VIS_TEXT_REPLACE_ALL_OCCURRENCES_FROM_OFFSET(
				@stack
				ReplaceAllFromOffsetFlags flags,
				dword offset, MemHandle infoHan)
	word MSG_VIS_TEXT_REPLACE_ALL_OCCURRENCES_IN_RANGE(
				@stack
				VisTextRange range,
				MemHandle infoHan)
	void MSG_VIS_TEXT_DO_KEY_FUNCTION()
	MSG_VIS_TEXT_REPLACE_TEXT
	void MSG_VIS_TEXT_GET_TEXT_RANGE()
	void MSG_VIS_TEXT_SELECT_RANGE(@stack
				dword end, dword start)
	void MSG_VIS_TEXT_SHOW_POSITION(dword position)
	void MSG_VIS_TEXT_SET_FILTER(byte filter)
	byte MSG_VIS_TEXT_GET_FILTER()
	void MSG_VIS_TEXT_SET_OUTPUT(optr newOutput)
	optr MSG_VIS_TEXT_GET_OUTPUT()
	void MSG_VIS_TEXT_SET_LR_MARGIN(byte lrMargin)
	byte MSG_VIS_TEXT_GET_LR_MARGIN()
	void MSG_VIS_TEXT_SET_TB_MARGIN(byte tbMargin)
	byte MSG_VIS_TEXT_GET_TB_MARGIN()
	void MSG_VIS_TEXT_REPLACE_WITH_HWR(@stack
				HWRContext context, MemHandle ink,
				VisTextHWRFlags flags,
				VisTextRange range)
	void MSG_VIS_TEXT_SET_HWR_CONTEXT()
	void MSG_VIS_TEXT_SET_HWR_FILTER()
	void MSG_VIS_TEXT_SET_SELECTED_TAB(word position)
	dword MSG_VIS_TEXT_GET_TEXT_SIZE()
	void MSG_VIS_TEXT_INVALIDATE_RANGE(VisTextRange *vtr)
	void MSG_VIS_TEXT_ATTRIBUTE_CHANGE()
	word MSG_VIS_TEXT_GET_LINE_INFO(
				VisTextGetLineInfoParameters *vtglip)
	void MSG_VIS_TEXT_DEFINE_NAME(
				VisTextNameCommonParams *data)
	void MSG_VIS_TEXT_DELETE_NAME(
				VisTextNameCommonParams *data)
	void MSG_VIS_TEXT_RENAME_NAME(
				VisTextNameCommonParams *data)
	void MSG_VIS_TEXT_UPDATE_NAME_LIST(
				VisTextNameCommonParams *data)
	void MSG_VIS_TEXT_GET_NAME_LIST_MONIKER(
				VisTextNameCommonParams *data)
	void MSG_VIS_TEXT_FOLLOW_HYPERLINK(
				VisTextNameCommonParams *data)
	dword MSG_VIS_TEXT_GET_LINE_FROM_OFFSET(dword offset)
	Boolean MSG_VIS_TEXT_GET_LINE_OFFSET_AND_FLAGS(
		VisTextGetLineOffsetAndFlagsParameters *params)
	dword MSG_VIS_TEXT_GET_TEXT_POSITION_FROM_COORD(@stack
				PointDWord coord)
	void MSG_VIS_TEXT_GET_NAME_LIST_NAME_TYPE(
				VisTextNameCommonParams *data)
	void MSG_VIS_TEXT_CROSS_SECTION_REPLACE_ABORTED()
	void MSG_VIS_TEXT_SET_SPELL_IN_PROGRESS()
	void MSG_VIS_TEXT_SET_SEARCH_IN_PROGRESS()
	void MSG_VIS_TEXT_LOAD_FROM_DB_ITEM_FORMAT(void *data)
	void MSG_VIS_TEXT_GET_RUN_BOUNDS(@stack
				VisTextRange *retVal,
				word runOffset, dword position)
	void MSG_SEARCH(MemHandle searchInfo)
	void MSG_REPLACE_CURRENT(MemHandle replaceInfo)
	void MSG_REPLACE_ALL_OCCURRENCES(MemHandle replaceInfo,
				Boolean replaceFromBeginning)
	void MSG_REPLACE_ALL_OCCURRENCES_IN_SELECTION(
				MemHandle replaceInfo)
	void MSG_ABORT_ACTIVE_SPELL()
	void MSG_ABORT_ACTIVE_SEARCH()

**Macros**

	TRAE(pos, base, type)		{ {pos-base, 0}, type}
	TRAE_ABS(pos, type)			{ {pos, 0}, type}
	TRAE_ALL(type)				{ {0, 0}, type}
	TRAE_END		{ {TEXT_ADDRESS_PAST_END&0xffff,
			TEXT_ADDRESS_PAST_END>>16},
			CA_NULL_ELEMENT}
	@define CHAR_ATTR_ELEMENT_ARRAY_HEADER
			@elementArray VisTextCharAttr
			(TextElementArrayHeader (TAT_CHAR_ATTRS))
	@define RUN_ARRAY_HEADER(elements)
			@chunkArray TextRunArrayElement
				(TextRunArrayHeader (0,
				(ChunkHandle)@elements))

**Routines**

	char * TextSearchInString(const char *str1,
				const char *startPtr,
				const char *endPtr, word strSize,
				const char *str2, word str2Size,
				word searchOptions, word *matchLen)
	dword TextSearchInHugeArray(char *str2, word str2Size,
				dword str1Size, dword curOffset,
				dword endOffset,
				FileHandle hugeArrayFile,
				VMBlockHandle hugeArrayBlock,
				word searchOptions, dword *matchLen)
	void TextMapDefaultCharAttr()
	void TextFindDefaultCharAttr()
	void TextMapDefaultParaAttr()
	void TextFindDefaultParaAttr()
	void TextGetSystemCharAttrRun()
	MemHandle TextSetHyphenationCall(
				HyphenationCallback *callback)
	void VisTextFormatNumber(char *buf, dword num,
				VisTextNumberType type)
	optr TextAllocClipboardObject(VMFileHandle file,
				word storageFlags, word regionFlag)
	VMBlockHandle TextFinishWithClipboardObject(optr obj,
				TextClipboardOption opt,
				optr owner, const char *name)

## VisVertRulerClass

	@class VisVertRulerClass, VisRulerClass

## ZoomPointerClass

	@class ZoomPointerClass, PointerClass

[2 Classes: Arc - GenTrigger](qr_clas1.md) <-- [Table of Contents](../quickref.md)
