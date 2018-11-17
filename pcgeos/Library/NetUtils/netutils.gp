##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	Serial/IR Communication project
# FILE:		netutils.gp
#
# AUTHOR:	Steve Jang, Apr 15, 1994
#
#
#   This library contains utilities for net library and netr drivers.
#
#	$Id: netutils.gp,v 1.1 97/04/05 01:25:22 newdeal Exp $
#
##############################################################################

name netutils.lib
type library, single

#
# Token must be SKUT for file manager to find us
#
tokenchars "SKUT"
tokenid 0

longname "Net library/driver utilities"

library geos

#
# resources
#
nosort
resource QueueCode				read-only code shared
resource QueueECCode				read-only code shared
resource HugeLMemCode				read-only code shared
resource HugeLMemECCode				read-only code shared
resource AddressCode				read-only code shared
resource UtilClasses				fixed read-only shared
resource FixedCode				read-only code shared fixed


entry	NetUtilsEntry

#
# classes
#
export	SocketAddressControlClass

#
# Other things for everyone else.
#
export HugeLMemCreate
export HugeLMemForceDestroy
export HugeLMemDestroy
export HugeLMemAllocLock
export HugeLMemFree
export HugeLMemLock
export HugeLMemUnlock

export QueueLMemCreate
export QueueLMemDestroy
export QueueMarkAsDead
export QueueEnqueueLock
export QueueEnqueueUnlock
export QueueAbortEnqueue
export QueueDequeueLock
export QueueDequeueUnlock
export QueueAbortDequeue
export QueueNumEnqueues
export QueueEnum

export NetGenerateRandom32
export NetGenerateRandom8
export NETGENERATERANDOM8
export NetGenerateRandom32 as NETGENERATERANDOM32
incminor
export HugeLMemReAlloc
# Exporting the C stubs
incminor
export HUGELMEMCREATE
export HUGELMEMFORCEDESTROY
export HUGELMEMDESTROY
export HUGELMEMALLOCLOCK
export HUGELMEMFREE
export HUGELMEMLOCK
export HUGELMEMUNLOCK
incminor
export HugeLMemWaitFreeSpace

