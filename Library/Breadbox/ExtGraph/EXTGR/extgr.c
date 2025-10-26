#include "extgraph.h"
#include <geos.h>
#include <vm.h>
#include <timer.h>
#include <ec.h>
#include <graphics.h>
#include <gstring.h>

/***************************************************************************/

SizeAsDWord _pascal _export
ExtGrGetGStringSize(VMFileHandle file, VMBlockHandle block,
	EGError *error)
{
	GStateHandle gstring, bmstate;
	Rectangle rect;
	word width = 0, height = 0;
	EGError stat = EGE_NO_ERROR;

	gstring = GrLoadGString(file, GST_VMEM, block);

	if(gstring)
	{
		bmstate = GrCreateState(0);

		if(bmstate)
		{
			GrGetGStringBounds(gstring, bmstate, 0, &rect);

			width = rect.R_right - rect.R_left;
			height = rect.R_bottom - rect.R_top;

			GrDestroyState(bmstate);
		}
		else
			stat = EGE_BLOCK_LOCKING_FAILURE;

		GrDestroyGString(gstring, 0, GSKT_LEAVE_DATA);
	}
	else
		stat = EGE_BLOCK_LOCKING_FAILURE;

	if(error)
		*error = stat;

	return(MAKE_SIZE_DWORD(width, height));
}

/***************************************************************************/

EGError _pascal _export
ExtGrDrawGString(GStateHandle gstate, sword x, sword y, VMFileHandle file, VMBlockHandle block)
{
	EGError stat = EGE_NO_ERROR;
	GStateHandle gstring;
	Rectangle rect;
	word element;

	// load
	gstring = GrLoadGString(file, GST_VMEM, block);

	if(gstring)
	{
		// get offset
		GrGetGStringBounds(gstring, gstate, 0, &rect);

		// draw
		GrDrawGString(gstate, gstring,
			(-rect.R_left) + x, (-rect.R_top) + y, 0, &element);

		// unload
		GrDestroyGString(gstring, 0, GSKT_LEAVE_DATA);
	}
	else
		stat = EGE_BLOCK_LOCKING_FAILURE;

	return(stat);
}

/***************************************************************************/
