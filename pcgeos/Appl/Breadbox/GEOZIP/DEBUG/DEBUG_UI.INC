/**************************************************************************
 *
 *	File Debug_UI.INC
 *
 *	Definition der Debug-UI-Objekte
 *	Diese Datei ist in die Interface-Resource einzubinden
 *
 *	Das DebugPrimary ist
 *	1. Als Child des Applikationsobjekts einzutragen
 *	2. In die gcnList(MANUFACTURER_ID_GEOWORKS,GAGCNLT_WINDOWS) einzubinden
 *
 **************************************************************************/

# define useDebugPrimary 0

@if useDebugPrimary

@object GenPrimaryClass DebugPrimary = {
	GI_visMoniker = "Debug-Window";
	GI_comp = @DebugText,@DebugInfoGroup;
/*	,DebugSetBreakTrigger,DebugClearBreakTrigger,@DebugContinueTrigger;*/
	HINT_SIZE_WINDOW_AS_DESIRED;
	HINT_ORIENT_CHILDREN_VERTICALLY;
	} /* end of 	Primary */
@elseif

@object GenInteractionClass DebugGroup = {
	GI_comp = @DebugText,@DebugInfoGroup;
	GII_visibility = GIV_POPOUT;
	HINT_MINIMIZE_CHILD_SPACING;
	HINT_SIZE_WINDOW_AS_DESIRED;
	HINT_ORIENT_CHILDREN_VERTICALLY;
	HINT_EXPAND_WIDTH_TO_FIT_PARENT;
	HINT_EXPAND_HEIGHT_TO_FIT_PARENT;

	} /* end of 	DebugGroup */
@endif


@object GenTextClass DebugText = {
	GTXI_text = "Debug Informationen:\15";
	GTXI_attrs = @default | GTA_INIT_SCROLLING;
	HINT_TEXT_WASH_COLOR = {C_LIGHT_CYAN,CF_INDEX,0,0 };
	/*	HINT_TEXT_WHITE_WASH_COLOR;*/
	HINT_EXPAND_WIDTH_TO_FIT_PARENT;
	HINT_EXPAND_HEIGHT_TO_FIT_PARENT;
@if useDebugPrimary
	HINT_INITIAL_SIZE = { SST_AVG_CHAR_WIDTHS | 65,
		SST_LINES_OF_TEXT | 20, 0};
@elseif
	HINT_INITIAL_SIZE = { SST_AVG_CHAR_WIDTHS | 65,
		SST_LINES_OF_TEXT | 8, 0};
@endif
	}

@object GenInteractionClass DebugInfoGroup = {
	GI_comp = @DebugInfoGlyph,@DebugValue1,@DebugValue2,@DebugValue3;
	HINT_ORIENT_CHILDREN_HORIZONTALLY;
	HINT_FULL_JUSTIFY_CHILDREN_HORIZONTALLY;
	HINT_INCLUDE_ENDS_IN_CHILD_SPACING;
	}

@object GenGlyphClass DebugInfoGlyph = {
	GI_visMoniker = "-";
	}

@object GenValueClass DebugValue1 = {
	GI_visMoniker = "Value1:";
	GVLI_minimum = MakeWWFixed( -16*1024 );
	GI_attrs = @default | GA_READ_ONLY;
	}

@object GenValueClass DebugValue2 = {
	GI_visMoniker = "Value2:";
	GI_attrs = @default | GA_READ_ONLY;
	GVLI_minimum = MakeWWFixed( -16*1024 );
	}

@object GenValueClass DebugValue3 = {
	GI_visMoniker = "Value3:";
	GI_attrs = @default | GA_READ_ONLY;
	GVLI_minimum = MakeWWFixed( -16*1024 );
	}

/* noch nicht implementiert, weil dann eine neue Klasse n”tig ist, die
 in Abh„ngigkeit vom DebugFlag in der GP-datei einzubinden ist.
@object GenTriggerClass DebugSetBreakTrigger = {
	GI_visMoniker =
	GTI_actionMsg = MSG_DEBUG_SET_BREAK;
	GTI_destination = @DebugInfoGroup;
	}

@object GenTriggerClass DebugClearBreakTrigger = {
	GI_visMoniker =
	GTI_actionMsg = MSG_DEBUG_CLEAR_BREAK;
	GTI_destination = @DebugInfoGroup;
	}

@object GenTriggerClass DebugContiniueTrigger = {
	GI_visMoniker =
	GTI_actionMsg = MSG_DEBUG_CONTINUE;
	GTI_destination = @DebugInfoGroup;
	}

*/


