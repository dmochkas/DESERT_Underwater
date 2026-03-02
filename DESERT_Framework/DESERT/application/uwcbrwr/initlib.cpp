#include "uwcbrwr.h"

#include <sap.h>
#include <tclcl.h>

packet_t PT_UWCBRWR;

extern EmbeddedTcl UwCbrWRInitTclCode;

extern "C" int
Uwcbrwr_Init()
{
	PT_UWCBR = p_info::addPacket("UWCBRWR");
	UwCbrWRInitTclCode.load();
	return 0;
}

extern "C" int
Cyguwcbr_Init()
{
	Uwcbrwr_Init();
	return 0;
}
