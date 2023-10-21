#
#	Local makefile for: GeoFile
#
#	$Id: local.mk,v 1.1 97/04/04 15:54:28 newdeal Exp $
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#				Initial version.
#	RainerB	23.10.21	XCOMPFLAGS -zc flag added

#
# Define the Bullet specific version
#
#GOCFLAGS	+= -DBULLET
XCCOMFLAGS	= -zc
LINKFLAGS       += -r

#include <$(SYSMAKEFILE)>
