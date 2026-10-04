#**************************************************************
# *  ==CONFIDENTIAL INFORMATION==
# *  COPYRIGHT 1994-2000 BREADBOX COMPUTER COMPANY --
# *  ALL RIGHTS RESERVED  --
# *  THE FOLLOWING CONFIDENTIAL INFORMATION IS BEING DISCLOSED TO YOU UNDER A
# *  NON-DISCLOSURE AGREEMENT AND MAY NOT BE DISCLOSED OR FORWARDED BY THE
# *  RECIPIENT TO ANY OTHER PERSON OR ENTITY NOT COVERED BY THE SAME
# *  NON-DISCLOSURE AGREEMENT COVERING THE RECIPIENT. USE OF THE FOLLOWING
# *  CONFIDENTIAL INFORMATION IS RESTRICTED TO THE TERMS OF THE NON-DISCLOSURE
# *  AGREEMENT.
# **************************************************************/
###############################################################################
#
# PROJECT    : Banker
# MODULE     : n2txt
# FILE       : n2txt.gp
# DESCRIPTION: numerals to text strings
###############################################################################

#Permanent Name
name n2txt.lib

#Long Name                                                                    #
longname "Num to Text Library"

tokenchars   "bb01"
tokenid 16431


type    library, single, c-api


library geos
library ui
library ansic
library text
library math

resource NumberStrings data object


export NUMTOTEXT


