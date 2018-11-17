##############################################################################
#
#       Copyright (c) Geoworks 1992 -- All Rights Reserved
#
# PROJECT:     PC GEOS
# MODULE:      Flat File Database Library
# FILE:        ffile.gp
#
# AUTHOR:      Jeremy Dashe
#
#
# Geode parameters for FFile -- the flat file database library
#
#       $Id: ffile.gp,v 1.1 97/04/04 18:03:28 newdeal Exp $
#
##############################################################################
#
# Specify the geode's permanent name
#
name ffile.lib

#
# Specify the type of geode (this is both a library, so other geodes can
# use the functions, and a driver, so it is allowed to access I/O ports).
# It may only be loaded once.
#
type library, single

#
# Import definitions from the kernel
#
library cell
library geos
library ui
library ssheet
library parse
library ansic
library math
library text
library grobj
library spool
library ssmeta

#
# Desktop-related things
#
longname        "Flat File Database Library"
tokenchars      "FFDL"
tokenid         0

#
# Specify alternate resource flags for anything non-standard
#
nosort
ifdef DO_DBCS
#resource InitCode                       code read-only shared
#resource FFDMETA_TEXT           code read-only shared           
#resource FFDPARSE_TEXT          code read-only shared           
#resource FFPGLAY_TEXT           code read-only shared           
#resource FFDIMPEX_TEXT          code read-only shared           
#resource FFDSUB_TEXT            code read-only shared           
#resource FFDPASTE_TEXT          code read-only shared           
#resource FFDCREAT_TEXT          code read-only shared          
#resource FFDFIELD_TEXT          code read-only shared           
#resource FFDLAY_TEXT            code read-only shared          
#resource FFDRCP_TEXT            code read-only shared           
#resource FFDFCON_TEXT           code read-only shared           
#resource FFDBASE_TEXT           code read-only shared          
#resource FFDSORT_TEXT           code read-only shared           
#resource FFDFORD_TEXT           code read-only shared           
#resource FFDTEXT_TEXT           code read-only shared           
#resource FFDLABEL_TEXT          code read-only shared           
#resource FFEXBLD_TEXT           code read-only shared           
#resource FFFPTEXT_TEXT          code read-only shared            
#resource FFFEDGES_TEXT          code read-only shared            
#resource FFFPROPS_TEXT          code read-only shared           
#resource FFTCHEST_TEXT          code read-only shared           
#resource FFSTRIN0_TEXT          code read-only shared             
#resource FFRECCON_TEXT          code read-only shared           
#resource FFRCUI_TEXT            code read-only shared             
#resource FFRCPVA0_TEXT          code read-only shared            
#resource FFGROBJ0_TEXT          code read-only shared           
#resource _TEXT                  code read-only shared            
resource FFEXPRESSIONBUILDERUI          shared, ui-object, read-only
resource FFEDGECONTROLLERUI             object
resource FFFIELDPROPERTIESUI            shared, ui-object, read-only
resource WARNINGSTRINGS         lmem
resource FIELDDISPLAYSTRINGS            shared, lmem, read-only
resource PASTEERRORSTRINGS              lmem
resource IMPEXERRORSTRINGS              lmem
resource PARSEERRORSTRINGS              lmem
resource ERRORSTRINGS                   shared, lmem, read-only
resource CONTROLSTRINGS                 shared, lmem, read-only
resource FFRECORDCONTROLTOOLBOXUI       shared, ui-object, read-only
resource APPRCPICONMONIKERRESOURCE      lmem read-only shared
resource FFRECORDCONTROLUI              shared, ui-object, read-only
resource FFTREASURECHESTUI              shared, ui-object 
resource APPICONMONIKERRESOURCE         lmem read-only shared

else
#resource InitCode                     code read-only shared
#resource Math                         code read-only shared
#resource FFDATABASE_G                 code read-only shared
#resource DATABASEINITIALIZATION               code read-only shared
#resource DATABASEFIELDPROPERTIES              code read-only shared
#resource DATABASEDATAENTRYSUPPORT             code read-only shared
#resource DATABASENEWRECORDSUPPORT             code read-only shared
#resource DATABASEFILE         code read-only shared
#resource DATABASEFIELDCREATION                code read-only shared
#resource DATABASEPAGENUMBERING                code read-only shared
#resource DATABASETYPECONVERSION               code read-only shared
#resource DATABASEFIELDORDER           code read-only shared
#resource FFDATABASEFIELDS_G           code read-only shared
#resource FFDATABASEFLOATCONTR         code read-only shared
#resource DATABASEIMPEX                code read-only shared
#resource FFDATABASELABELS_G           code read-only shared
#resource DATABASELAYOUTMANAGEMENT             code read-only shared
#resource DATABASEPRINT                code read-only shared
#resource DATABASEMETAHANDLERS         code read-only shared
#resource DATABASEPARSER               code read-only shared
#resource FFDATABASEPASTE_G            code read-only shared
#resource FFDATABASERCP_G              code read-only shared
#resource DATABASESORT         code read-only shared
#resource DATABASESUBSET               code read-only shared
#resource FFDATABASETEXT_G             code read-only shared
#resource FFPAGELAYOUTRECT_G           code read-only shared
#resource FFEXPRBUILDER_G              code read-only shared
#resource FFEXPRBUILDER_GCONST_DATA            code read-only shared
#resource FFFIELDEDGES_G               code read-only shared
#resource FFFIELDEDGES_GCONST_DATA             code read-only shared
#resource FFFIELDPROPERTIES_G  code read-only shared
#resource FFFIELDPROPERTIES_GCONST_DATA                code read-only shared
#resource FIELDPROPERTIESADVANCED              code read-only shared
#resource FFFPTEXT_G           code read-only shared
#resource FFGROBJBODY_G                code read-only shared
#resource FFRCPVALUE_G         code read-only shared
#resource FFRECORDCONTROL_G            code read-only shared
#resource FFRECORDCONTROL_GCONST_DATA          code read-only shared
#resource FFTREASURECHEST_G            code read-only shared
#resource FFTREASURECHEST_GCONST_DATA          code read-only shared
resource FFEXPRESSIONBUILDERUI        shared, ui-object, read-only
resource FFEDGECONTROLLERUI           object
resource FFFIELDPROPERTIESUI          shared, ui-object, read-only
resource WARNINGSTRINGS               lmem
resource FIELDDISPLAYSTRINGS          shared, lmem, read-only
resource PASTEERRORSTRINGS            lmem
resource IMPEXERRORSTRINGS            lmem
resource PARSEERRORSTRINGS            lmem
resource ERRORSTRINGS                 shared, lmem, read-only
resource CONTROLSTRINGS               shared, lmem, read-only
resource FFRECORDCONTROLTOOLBOXUI     shared, ui-object, read-only
resource APPRCPICONMONIKERRESOURCE    lmem read-only shared
resource FFRECORDCONTROLUI            shared, ui-object, read-only
resource FFTREASURECHESTUI            shared, ui-object 
resource APPICONMONIKERRESOURCE               lmem read-only shared
endif

#
# Define the library entry point
#
entry FlatFileEntry

#
# Exported Classes
#
export  FlatFileDatabaseClass
export  FFTextFieldGuardianClass
export  FFLabelGuardianClass
export  FFTextClass
export  FFExpressionBuilderClass
export  FFFieldPropertiesClass
export  FFTreasureChestClass
export	FFRecordControlClass
export  FFPageLayoutRectClass
export  FFGrObjBodyClass
export  FFEdgeControllerClass
export  FFRCPValueClass
export  FFFPFieldTextClass

#
# Exported Routines
#
export FLATFILEINITFILE
