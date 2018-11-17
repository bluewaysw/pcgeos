##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	
# FILE:		scan.gp
#
# AUTHOR:	Edwin Yu, July  27, 1999
#
#
# 
#
#	$Id: $
#
##############################################################################
#
# Permanent name
#
name parentc.lib
#
# Long name
#
longname "Parental Control Library"
#
# Desktop-related definitions
#
tokenchars "pclb"
tokenid 0
#
# Specify geode type
#
type	library, single
#
# Import library routine definitions
#
library config
#
# Define resources other than standard discardable code
#
nosort
resource PCCode		read-only code shared
resource PCControlPasswordUI	read-only ui-object shared
resource PCControlWebSiteUI	read-only ui-object shared
resource PCControlCheckPasswordUI	read-only lmem data shared
resource PCControlStrings	read-only lmem data shared
resource IconMonikerResource	shared lmem read-only
#
# new classes
#
export	ParentalControlClass
export  WWWDynamicListClass
export  ModifyPrefTextClass
export  WWWSiteTextClass
#
# export routines
#
export  ParentalControlGetAccessInfo
export  ParentalControlSetAccessInfo
export  PCEnsureOpenData
export  PCCloseData
export  PCFindURL
export  PCStoreURLs
export  PCDataDeleteItem
export  PARENTALCONTROLGETACCESSINFO
export  PARENTALCONTROLSETACCESSINFO
export  PARENTALCONTROLENSUREOPENDATA
export  PARENTALCONTROLCLOSEDATA
export  PARENTALCONTROLFINDURL
export  PARENTALCONTROLSTOREURL
export  PARENTALCONTROLDELETEURL
