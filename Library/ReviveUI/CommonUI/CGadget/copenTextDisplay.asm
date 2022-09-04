COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/Open
FILE:		openTextDisplay.asm

METHODS:
  Name				Description
  ----				-----------
  OLTextInitialize	Initialize an ol text display instance.

  OLTextDraw		Draw the ol text object.
  OLTextExposed		HandleMem exposure of a text document.
  OLTextHeightNotify	HandleMem a height change due to text changes.
  OLTextRerecalcSize	Calculate a new text height based on a width.
  OLTextPlaceInView	Place a text object in a view.
  OLTextStartSelect	HandleMem a select button press.
  OLTextSpecBuild	Build the visual representation of the object.
  OLTextShowSelection	Force the selection to be visible.
  OLTextNormalizePosition Align document coords to a line boundary.
  OLTextVisClose		Make sure kbd/mouse are released before close.
  OLTextSubviewSizeChanged HandleMem a change in sub-view size.
  OLTextGrabFocusExcl	Force the object to be the focus.
  OLTextReleaseFocusExcl	Force the object to not be the focus.
  OLTextGrabTargetExcl	Force the object to be the target
  OLTextReleaseTargetExcl	Force the object to not be the target.

ROUTINES:
  Name				Description
  ----				-----------
  TranslateGenericFonts		Translate a generic font to a specific font id.
  SetDefaultBGColor		Set the bg color (what goes behind the text).
  CreateView			Create a view for the object to appear in.
  GenInitPrep
  DetermineTextWidth		Figure out the appropriate width for the text.
  DetermineMinHeight		Determine the smallest possible height.
  SpecBuildView			Build the text/view combo.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

DESCRIPTION:
	Implementation of the OpenLook text display class (OLTextClass).

	$Id: copenTextDisplay.asm,v 2.178 92/07/29 22:10:47 joon Exp $

------------------------------------------------------------------------------@

Nuked, see copenText.asm.  7/ 7/92 cbh
