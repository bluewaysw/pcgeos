# Parameters for specific screen saver library
# $Id: template.gp,v 1.1 97/04/04 16:47:34 newdeal Exp $
#
# Permanent name
#
name template.lib
#
# All specific screen savers are libraries that may be launched but once
#
type library, single
#
# This is the name that appears in the generic saver's list
#
longname "Template"
#
# All specific screen savers have a token of SSAV, and for now they must have
# our manufacturer's ID (until the file selector can be told to ignore the
# ID)
#
tokenchars "SSAV"
tokenid 0
#
# We use the saver library, of course.
#
library saver
#
# We have user-savable options.
#
library options
#
# We must import the UI so our options block can be properly relocated, the
# relocations happening w.r.t. our imported libraries (we own the block) even
# though it's being duplicated on the generic saver's thread.
#
library ui
#
# The need for this is self-evident...
#
library geos
#
# The kernel needs this, yes precioussss
#
entry TemplateEntry
#
# Any special resource-allocation flags needed.
#
resource TemplateOptions ui-object
resource TemplateHelp ui-object
#
# Pre-defined entry points -- must be first and in this order (q.v.
# SaverFunctions)
#
export TemplateStart
export TemplateStop
export TemplateFetchUI
export TemplateFetchHelp
export TemplateSaveState
export TemplateRestoreState
export TemplateSaveOptions
#
# Other entry  points we use
#
export TemplateDraw
export TemplateSetSpeed
export TemplateSetClearMode
