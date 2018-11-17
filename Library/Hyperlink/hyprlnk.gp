##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Hyperlink Library
# FILE:		hyprlnk.gp
#
# AUTHOR:	Jenny Greenwood, 19 April 1994
#
#	$Id: hyprlnk.gp,v 1.1 97/04/04 18:09:17 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name hyprlnk.lib
#
# Specify geode type
#
type	library, single
#
# Desktop-related things
#
longname	"Hyperlink Library"
tokenchars	"HYPR"
tokenid		0
#
# Hyperlink will run on Upgrade, with a newer version of the Text library
#
#platform upgrade
#exempt text
#
# Libraries used
#
library geos
library ui
library text
#
# Define resources other than standard discardable code
#
nosort
resource HyperlinkClassStructures		fixed read-only shared
resource HyperlinkAndPageNameControlCode	code read-only shared
resource HyperlinkControlUI			ui-object read-only shared
resource HyperlinkControlStrings		lmem read-only shared
resource PageNameControlUI			ui-object read-only shared
#
# Export stuff
#
export HyperlinkControlClass
export PageNameControlClass


