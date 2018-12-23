#**************************************************************
# *  ==CONFIDENTIAL INFORMATION==
# *  COPYRIGHT 1994-2014 BREADBOX COMPUTER COMPANY --
# *  ALL RIGHTS RESERVED  --
# *  THE FOLLOWING CONFIDENTIAL INFORMATION IS BEING DISCLOSED TO YOU UNDER A
# *  NON-DISCLOSURE AGREEMENT AND MAY NOT BE DISCLOSED OR FORWARDED BY THE
# *  RECIPIENT TO ANY OTHER PERSON OR ENTITY NOT COVERED BY THE SAME
# *  NON-DISCLOSURE AGREEMENT COVERING THE RECIPIENT. USE OF THE FOLLOWING
# *  CONFIDENTIAL INFORMATION IS RESTRICTED TO THE TERMS OF THE NON-DISCLOSURE
# *  AGREEMENT.
# **************************************************************/

#Permanent Name
name ps2pdf.lib

#Long Name                                                                    #
longname "Breadbox PS to PDF Library"

tokenchars   "bb01"
tokenid 16431


type    library, single, c-api


library geos
library ui
library ansic
library text

resource Strings data object


export CONVERTTOPDF

usernotes "Copyright 1994-2014  Breadbox Computer Company  All Rights Reserved"
