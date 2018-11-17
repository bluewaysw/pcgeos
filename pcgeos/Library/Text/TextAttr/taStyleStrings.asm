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

	$Id: taStyleStrings.asm,v 1.1 97/04/07 11:18:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextStyleStrings	segment	lmem	LMEM_TYPE_GENERAL

LocalDefString BadModifyStyleString <"This base style change would result in having a non-character only style based on a character only style, which is illegal.", 0>

;-----


LocalDefString CharacterOnlyString <"Character Only", 0>
LocalDefString PointSizeRelativeString <"Point Size Relative", 0>
LocalDefString MarginsRelativeString <"Indents Relative", 0>
LocalDefString LeadingRelativeString <"Leading Relative", 0>

LocalDefString CharacterString <"Character:", 0>

LocalDefString UnknownFontString <"Font=", 0>

LocalDefString UnderlineString <"Underline", 0>
LocalDefString OutlineString <"Outline", 0>
LocalDefString BoldString <"Bold", 0>
LocalDefString ItalicString <"Italic", 0>
LocalDefString StrikeThruString <"Strike-thru", 0>
LocalDefString SuperscriptString <"Superscript", 0>
LocalDefString SubscriptString <"Subscript", 0>
LocalDefString BoxedString <"Boxed", 0>
LocalDefString ButtonString <"Button", 0>
LocalDefString IndexString <"Index", 0>
LocalDefString AllCapString <"AllCaps", 0>
LocalDefString SmallCapString <"SmallCaps", 0>
LocalDefString HiddenString <"Hidden", 0>
LocalDefString ChangeBarString <"ChangeBar", 0>

LocalDefString FontWeightString <"Font Weight: ", 0>
LocalDefString FontWidthString <"Font Width: ", 0>
LocalDefString TrackKerningString <"Character Spacing:", 0>

LocalDefString FilledString <"filled", 0>
LocalDefString UnfilledString <"unfilled", 0>
LocalDefString HalftoneString <"halftone", 0>

LocalDefString BGColorString <"Background Color:", 0>

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

LocalDefString UnknownPatternString <"Unknown", 0>
LocalDefString SolidPatternString <"Solid", 0>
LocalDefString VerticalPatternString <"Vertical", 0>
LocalDefString HorizontalPatternString <"Horizontal", 0>
LocalDefString Degree45PatternString <"45 Degree", 0>
LocalDefString Degree135PatternString <"135 Degree", 0>
LocalDefString BrickPatternString <"Brick", 0>
LocalDefString SlantedBrickPatternString <"Slanted Brick", 0>
LocalDefString PatternString <"pattern", 0>


LocalDefString ParagraphString <"Paragraph:", 0>

LocalDefString LeftJustString <"Left Justified", 0>
LocalDefString CenterJustString <"Centered", 0>
LocalDefString RightJustString <"Right Justified", 0>
LocalDefString FullJustString <"Full Justified", 0>
if CHAR_JUSTIFICATION
LocalDefString FullCharJustString <"Japanese Justified", 0>
endif

LocalDefString LeftMarginString <"Hanging Left Indent", 0>
LocalDefString ParaMarginString <"Left Indent of First Line", 0>
LocalDefString RightMarginString <"Right Indent", 0>

LocalDefString LineSpacingString <"Line Spacing:", 0>
LocalDefString LeadingString <"Manual Leading:", 0>
LocalDefString TopSpacingString <"Space On Top:", 0>
LocalDefString BottomSpacingString <"Space On Bottom:", 0>

LocalDefString DefaultTabsString <"Default Tabs:", 0>
LocalDefString NoDefaultTabsString <"No Default Tabs", 0>

LocalDefString ParaBGColorString <"BG Color:", 0>

LocalDefString NoTabsString <"No Tabs", 0>
LocalDefString TabsString <"Tabs:", 0>
LocalDefString AnchoredWithString <"with '", 0>
LocalDefString AnchoredEndString <"'", 0>
LocalDefString WithString <"with", 0>
LocalDefString LeaderString <"leader", 0>
LocalDefString TabLineWidthString <"wide lines", 0>
LocalDefString TabLineSpacingString <"spacing", 0>
LocalDefString AnchoredString <"Anchored", 0>
LocalDefString DotLeaderString <"dot", 0>
LocalDefString LineLeaderString <"line", 0>
LocalDefString BulletLeaderString <"bullet", 0>

LocalDefString NoBorderString <"No Border", 0>
LocalDefString DoubleBorderString <"Double Line Border", 0>
LocalDefString ShadowBorderString <"Shadowed Border", 0>
LocalDefString NormalBorderString <"Normal Border", 0>
LocalDefString ShadowTopRightString <"from top-right", 0>
LocalDefString ShadowBottomLeftString <"from bottom-left", 0>
LocalDefString ShadowBottomRightString <"from bottom-right", 0>
;;;LocalDefString WithString <"with", 0>
LocalDefString ShadowWidthString <"wide shadow", 0>
LocalDefString SpaceBetweenString <"between lines", 0>
LocalDefString SideString <"side only", 0>
LocalDefString SidesString <"sides only", 0>
LocalDefString LeftString <"left", 0>
LocalDefString TopString <"top", 0>
LocalDefString RightString <"right", 0>
LocalDefString BottomString <"bottom", 0>
LocalDefString DrawInnerString <"Draw Inner Lines", 0>
LocalDefString BorderWidthString <"Border Width:", 0>
LocalDefString BorderSpacingString <"Border Spacing:", 0>

LocalDefString BorderColorString <"Border Color:", 0>
LocalDefString DisableWordWrapString <"Word Wrap Disabled", 0>
LocalDefString ColumnBreakBeforeString <"Column Break Before", 0>
LocalDefString KeepParaWithNextString <"Keep Paragraph With Next", 0>
LocalDefString KeepParaTogetherString <"Keep Paragraph Together", 0>

LocalDefString AutoHyphenationString <"Auto-hyphenate", 0>
LocalDefString MaxLinesString <"Max consecutive lines to hyphenate", 0>
LocalDefString ShortestWordString <"Shortest word to hyphenate", 0>
LocalDefString ShortestPrefixString <"Shortest prefix to hyphenate", 0>
LocalDefString ShortestSuffixString <"Shortest suffix to hyphenate", 0>

LocalDefString KeepLinesString <"Widow/Orphan control", 0>
LocalDefString KeepTopString <"Max orphan size", 0>
LocalDefString KeepBottomString <"Max widow size", 0>

TextStyleStrings	ends
