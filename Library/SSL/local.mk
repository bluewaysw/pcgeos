##############################################################################
#
#	(c) Copyright GlobalPC 1998 -- All Rights Reserved
#
# PROJECT:	SSL
# MODULE:	
# FILE:		local.mk
#
# AUTHOR:	Brian Chin, Nov 4 1998
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#	brianc	11/4/98		Initial version.
#
# DESCRIPTION:
#
#	$Id:$
#
##############################################################################

#
# compiler options
# -K		chars are unsigned
# -d		merge duplicate strings
# -X		no autodependcy output
# -Fs-		DS!=SS
# -dc		put strings in code segment
# -p		Pascal convention
# -rd           Only optimize register variables if using keyword 'register'
#                  (avoids crashes from outside calls mangling SI)
# -WDE          Does dgroup fixup on _export'd routines
#
#CCOMFLAGS	+= -K -d -X -Fs- -dc -p -WDE -rd
CCOMFLAGS	+= -ecp -zu -zc 

#
# main options
#
CCOMFLAGS	+= -DL_ENDIAN -DNO_ERR -DNO_STDIO

#
# extra options
# -DRSAref	build to use RSAref
# -DNO_IDEA	build with no IDEA algorithm
# -DNO_RC4	build with no RC4 algorithm
# -DNO_RC2	build with no RC2 algorithm
# -DNO_BF	build with no Blowfish algorithm
# -DNO_DES	build with no DES/3DES algorithm
# -DNO_MD2	build with no MD2 algorithm
#
# DES_PTR	use pointer lookup vs arrays in the DES in crypto/des/des_locl.h
# DES_RISC1	use different DES_ENCRYPT macro that helps reduce register
#		dependancies but needs to more registers, good for RISC CPU's
# DES_RISC2	A different RISC variant.
# DES_UNROLL	unroll the inner DES loop, sometimes helps, somtimes hinders.
# DES_INT	use 'int' instead of 'long' for DES_LONG in crypto/des/des.h
#		This is used on the DEC Alpha where long is 8 bytes
#		and int is 4
# BN_LLONG	use the type 'long long' in crypto/bn/bn.h
# MD2_CHAR	use 'char' instead of 'int' for MD2_INT in crypto/md2/md2.h
# MD2_LONG	use 'long' instead of 'int' for MD2_INT in crypto/md2/md2.h
# IDEA_SHORT	use 'short' instead of 'int' for IDEA_INT in crypto/idea/idea.h
# IDEA_LONG	use 'long' instead of 'int' for IDEA_INT in crypto/idea/idea.h
# RC2_SHORT	use 'short' instead of 'int' for RC2_INT in crypto/rc2/rc2.h
# RC2_LONG	use 'long' instead of 'int' for RC2_INT in crypto/rc2/rc2.h
# RC4_CHAR	use 'char' instead of 'int' for RC4_INT in crypto/rc4/rc4.h
# RC4_LONG	use 'long' instead of 'int' for RC4_INT in crypto/rc4/rc4.h
# RC4_INDEX	define RC4_INDEX in crypto/rc4/rc4_locl.h.  This turns on
#		array lookups instead of pointer use.
# BF_PTR	use 'pointer arithmatic' for Blowfish (unsafe on Alpha).
# BF_PTR2	use a pentium/intel specific version.
# MD5_ASM	use some extra md5 assember,
# SHA1_ASM	use some extra sha1 assember, must define L_ENDIAN for x86
# RMD160_ASM	use some extra ripemd160 assember,
# BN_ASM	use some extra bn assember,
#

CCOMFLAGS += -DNO_BLOWFISH -DNO_BF -DNO_IDEA -DNO_RC2 -DNO_MD2 -DNO_CAST -DNO_RC5 -DNO_MDC2 -DNO_DH -DNO_SHA -DNO_DES -DNO_DSA -DNO_RIPEMD
#if $(PRODUCT) == "NDO2000"
#else
#CCOMFLAGS += -DCOMPILE_OPTION_MAP_HEAP
#LINKFLAGS += -DCOMPILE_OPTION_MAP_HEAP
#endif

#
# GEOS_CLIENT -- only need client side code, other GEOS stuff (multi-thread
#		 support)
# GEOS_MEM -- use GEOS heap instead of C malloc (s2 packet r/w buffers)
# GEOS_ERROR -- integrate GEOS error handling (ThreadGetError/ThreadSetError)
#
CCOMFLAGS	+= -DGEOS_CLIENT -DGEOS_MEM -DGEOS_ERROR

#
# for bn/bnManager.asm
#
ASMFLAGS	+= -D__GEOS__

#
# hack
#
# LINK		= glueold

#include        <$(SYSMAKEFILE)>

