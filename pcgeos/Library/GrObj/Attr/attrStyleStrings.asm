COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text/TextAttr
FILE:		taStyleStrings.asm

AUTHOR:		Tony

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/22/89		Initial revision

DESCRIPTION:
	Strings for style stuff.

	$Id: attrStyleStrings.asm,v 1.1 97/04/04 18:07:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjStyleStrings	segment	lmem	LMEM_TYPE_GENERAL

LocalDefString AreaString <"Area:", 0>
LocalDefString LineString <"Line:", 0>

LocalDefString AreaColorRelativeString <"Area Color Relative", 0>
LocalDefString AreaMaskRelativeString <"Area Shading Relative", 0>
LocalDefString LineColorRelativeString <"Line Color Relative", 0>
LocalDefString LineMaskRelativeString <"Line Shading Relative", 0>
LocalDefString LineWidthRelativeString <"Line Width Relative", 0>

LocalDefString FilledString <"Filled", 0>

if not DBCS_PCGEOS
if _USE_AREA_LINE_COLOR_STRING

LocalDefString AreaColorString <"Area Color:", 0>
LocalDefString LineColorString <"Line Color:", 0>

endif ;_USE_AREA_LINE_COLOR_STRING
endif
LocalDefString BackgroundColorString <"Background Color:", 0>
LocalDefString GradientEndColorString <"Gradient End Color:", 0>

LocalDefString YesGradientFillString <"Gradient Fill", 0>
LocalDefString NoGradientFillString <"No Gradient Fill", 0>

LocalDefString GradientString <"gradient", 0>

LocalDefString NoGradientString <"No", 0>
LocalDefString HorizontalGradientString <"Horizontal", 0>
LocalDefString VerticalGradientString <"Vertical", 0>
LocalDefString RadialRectGradientString <"Rectangular", 0>
LocalDefString RadialEllipseGradientString <"Elliptical", 0>
LocalDefString GradientIntervalString <"gradient intervals", 0>

LocalDefString BlackString <"Black", 0>
LocalDefString DarkBlueString <"Dark Blue", 0>
LocalDefString DarkGreenString <"Dark Green", 0>
LocalDefString CyanString <"Cyan", 0>
LocalDefString DarkRedString <"Dark Red", 0>
LocalDefString DarkVioletString <"Dark Violet", 0>
LocalDefString BrownString <"Brown", 0>
LocalDefString LightGrayString <"Light Gray", 0>
LocalDefString DarkGrayString <"Dark Gray", 0>
LocalDefString LightBlueString <"Light Blue", 0>
LocalDefString LightGreenString <"Light Green", 0>
LocalDefString LightCyanString <"Light Cyan", 0>
LocalDefString LightRedString <"Light Red", 0>
LocalDefString LightVioletString <"Light Violet", 0>
LocalDefString YellowString <"Yellow", 0>
LocalDefString WhiteString <"White", 0>

LocalDefString DoDrawBackgroundString <"Draw Background", 0>
LocalDefString DontDrawBackgroundString <"Don't Draw Background", 0>

LocalDefString SolidString <"Solid", 0>
LocalDefString DashedString <"Dashed", 0>
LocalDefString DottedString <"Dotted", 0>
LocalDefString DashDotString <"Dash-Dot", 0>
LocalDefString DashDDotString <"Dash-Double-Dot", 0>

LocalDefString UnknownString <"Unknown", 0>

LocalDefString PatternString <"pattern", 0>
LocalDefString SolidPatternString <"Solid", 0>
LocalDefString VerticalPatternString <"Vertical", 0>
LocalDefString HorizontalPatternString <"Horizontal", 0>
LocalDefString Degree45PatternString <"45 Degree", 0>
LocalDefString Degree135PatternString <"135 Degree", 0>
LocalDefString BrickPatternString <"Brick", 0>
LocalDefString SlantedBrickPatternString <"Slanted Brick", 0>

LocalDefString DrawModeString <"mode", 0>

LocalDefString MMClearString <"CLEAR", 0>
LocalDefString MMCopyString <"COPY", 0>
LocalDefString MMNopString <"NOP", 0>
LocalDefString MMAndString <"AND", 0>
LocalDefString MMInvertString <"INVERT", 0>
LocalDefString MMXorString <"XOR", 0>
LocalDefString MMSetString <"SET", 0>
LocalDefString MMOrString <"OR", 0>

LocalDefString ArrowheadString <"arrowhead", 0>
LocalDefString NoString <"No ", 0>
LocalDefString ArrowheadOnStartString <"Arrowhead on Start", 0>
LocalDefString ArrowheadOnEndString <"Arrowhead on End", 0>
LocalDefString ArrowheadUnfilledString <"Unfilled arrowhead", 0>
LocalDefString ArrowheadFilledWithLineAttributesString <"Arrowhead filled with line attributes", 0>
LocalDefString ArrowheadFilledWithAreaAttributesString <"Arrowhead filled with area attributes", 0>

LocalDefString NarrowArrowheadString <"Narrow", 0>
LocalDefString WideArrowheadString <"Wide", 0>
LocalDefString FlatheadArrowheadString <"Flathead", 0>

GrObjStyleStrings	ends
