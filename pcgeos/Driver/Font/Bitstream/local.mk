##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Bitstream Driver -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Brian Chin
#
# DESCRIPTION:
#	Special definitions required for the Bitstream font driver
#
#	$Id: local.mk,v 1.1 97/04/18 11:45:12 newdeal Exp $
#
###############################################################################
ASMFLAGS	+= -i -DPROC_TRUETYPE=0 -DPROC_TYPE1=0
#use this to include TrueType and Type1
# (update CCOMFLAGS, TRUETYP{E}OBJS, TYPE1{E}OBJS and .gp file also)
#ASMFLAGS	+= -i -DPROC_TRUETYPE=1 -DPROC_TYPE1=1

.PATH.asm .PATH.def: ../FontCom $(INSTALL_DIR:H)/FontCom \

GEODE		= bitstrm

LINKFLAGS	+= -m

CCOMFLAGS	+= -D__HIGH_C__ -DINCL_OUTLINE=1 -DINCL_2D=1 -DINCL_KEYS=0 -DINCL_SCREEN=0 -DINCL_WHITE=0 -DINCL_BLACK=0 -USHORT_LISTS -DMSDOS=1 -DPROC_PCL=0 -DPROC_TYPE1=0 -DPROC_TRUETYPE=0 -DNOT_ON_THE_MAC=1
#use this to include TrueType and Type1
#CCOMFLAGS	+= -D__HIGH_C__ -DINCL_OUTLINE=1 -DINCL_2D=1 -DINCL_KEYS=0 -DINCL_SCREEN=0 -DINCL_WHITE=0 -DINCL_BLACK=0 -USHORT_LISTS -DMSDOS=1 -DPROC_PCL=0 -DPROC_TYPE1=1 -DPROC_TRUETYPE=1 -DNOT_ON_THE_MAC=1

FRONTENDOBJS	= cmt.obj cmtglob.obj frontend.obj
FRONTENDEOBJS	= cmt.eobj cmtglob.eobj frontend.eobj

OUTPUTOBJS	= out_util.obj
OUTPUTEOBJS	= out_util.eobj
#if	INCL_OUTLINE
OUTPUTOBJS	+= out_outl.obj
OUTPUTEOBJS	+= out_outl.eobj
#endif
#if	INCL_2D
OUTPUTOBJS	+= out_bl2d.obj
OUTPUTEOBJS	+= out_bl2d.eobj
#endif
#if	INCL_SCREEN
OUTPUTOBJS	+= out_scrn.obj
OUTPUTEOBJS	+= out_scrn.eobj
#endif
#if	INCL_WHITE
OUTPUTOBJS	+= out_wht.obj
OUTPUTEOBJS	+= out_wht.eobj
#endif
#if	INCL_BLACK
OUTPUTOBJS	+= out_blk.obj
OUTPUTEOBJS	+= out_blk.eobj
#endif

#damn above thing doesn't work
OUTPUTOBJS	= out_util.obj out_outl.obj out_bl2d.obj
OUTPUTEOBJS	= out_util.eobj out_outl.eobj out_bl2d.eobj

SPEEDOOBJS	= do_char.obj do_trns.obj\
		  reset.obj set_spcs.obj set_trns.obj
SPEEDOEOBJS	= do_char.eobj do_trns.eobj\
		  reset.eobj set_spcs.eobj set_trns.eobj
#ifdef	INCL_KEYS
SPEEDOOBJS	+= set_keys.obj
SPEEDOEOBJS	+= set_keys.eobj
#endif

#if	PROC_TRUETYPE
TRUETYPEOBJS	= fixed_pt.obj fnt.obj fontscal.obj fsglue.obj mapstrng.obj\
		  newscan.obj sfntd.obj tt_iface.obj tt_specs.obj
TRUETYPEEOBJS	= fixed_pt.eobj fnt.eobj fontscal.eobj fsglue.eobj mapstrng.eobj\
		  newscan.eobj sfntd.eobj tt_iface.eobj tt_specs.eobj
#else
TRUETYPEOBJS	=
TRUETYPEEOBJS	=
#endif
#damn above thing doesn't work
TRUETYPEOBJS	=
TRUETYPEEOBJS	=
#use this to include TrueType
#TRUETYPEOBJS	= fixed_pt.obj fnt.obj fontscal.obj fsglue.obj mapstrng.obj\
#		  newscan.obj sfntd.obj tt_iface.obj tt_specs.obj
#TRUETYPEEOBJS	= fixed_pt.eobj fnt.eobj fontscal.eobj fsglue.eobj mapstrng.eobj\
#		  newscan.eobj sfntd.eobj tt_iface.eobj tt_specs.eobj

#if	PROC_TYPE1
TYPE1OBJS	= tr_ldfnt.obj tr_mkchr.obj tr_names.obj tr_trans.obj
TYPE1EOBJS	= tr_ldfnt.eobj tr_mkchr.eobj tr_names.eobj tr_trans.eobj
#else
TYPE1OBJS	=
TYPE1EOBJS	=
#endif
#damn above thing doesn't work
TYPE1OBJS	=
TYPE1EOBJS	=
#use this to include Type1
#TYPE1OBJS	= tr_ldfnt.obj tr_mkchr.obj tr_names.obj tr_trans.obj
#TYPE1EOBJS	= tr_ldfnt.eobj tr_mkchr.eobj tr_names.eobj tr_trans.eobj

OBJS		= Main.obj\
		  $(FRONTENDOBJS) $(OUTPUTOBJS) $(SPEEDOOBJS)\
		  $(TRUETYPEOBJS) $(TYPE1OBJS)
EOBJS		= Main.eobj\
		  $(FRONTENDEOBJS) $(OUTPUTEOBJS) $(SPEEDOEOBJS)\
		  $(TRUETYPEEOBJS) $(TYPE1EOBJS)

_PROTO		= 3.0

#include	<$(SYSMAKEFILE)>
