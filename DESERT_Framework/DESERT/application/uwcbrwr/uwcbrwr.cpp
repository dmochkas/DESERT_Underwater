#include "uwcbrwr.h"

#include <iostream>
#include <rng.h>
#include <stdint.h>
#include <string>

packet_t PT_UWCBRWR;

int hdr_uwcbr::offset_; /**< Offset used to access in <i>hdr_uwcbr</i> packets
						   header. */

/**
 * Adds the header for <i>hdr_uwcbr</i> packets in ns2.
 */
static class UwCbrWRPktClass : public PacketHeaderClass
{
public:
	UwCbrWRPktClass()
		: PacketHeaderClass("PacketHeader/UWCBRWR", sizeof(hdr_uwcbrwr))
	{
		this->bind();
		bind_offset(&hdr_uwcbrwr::offset_);
	}
} class_uwcbr_pkt;

/**
 * Adds the module for UwCbrModuleClass in ns2.
 */
static class UwCbrWRModuleClass : public TclClass
{
public:
	UwCbrWRModuleClass()
		: TclClass("Module/UW/CBRWR")
	{
	}

	TclObject *
	create(int, const char *const *)
	{
		return (new UwCbrWRModule());
	}
} class_module_uwcbrwr;

// void
// UwSendTimer::expire(Event *e)
// {
// 	module->transmit();
// }

// int UwCbrModule::uidcnt_ = 0;

UwCbrWRModule::UwCbrWRModule()
	: UwCbrModule(),
	request_flag(false)
{ // binding to TCL variables
}

int
UwCbrWRModule::command(int argc, const char *const *argv)
{
	return TCL_OK;
}

void
UwCbrModule::recv(Packet *p, Handler *h)
{
	recv(p);
}

void
UwCbrModule::recv(Packet *p)
{
	hdr_cmn *ch = hdr_cmn::access(p);

	printOnLog(Logger::LogLevel::DEBUG,
			"UWCBR",
			"recv(Packet *)::received packet with id " + to_string(ch->uid()));

	if (ch->ptype() != PT_UWCBR) {
		drop(p, 1, UWCBR_DROP_REASON_UNKNOWN_TYPE);
		incrPktInvalid();
		return;
	}

	hdr_uwcbr *uwcbrh = HDR_UWCBR(p);
	esn = hrsn + 1; // expected sn

	if (!drop_out_of_order_) {
		if (sn_check[uwcbrh->sn() & 0x00ffffff]) {
			// Packet already processed: drop it
			incrPktInvalid();
			drop(p, 1, UWCBR_DROP_REASON_DUPLICATED_PACKET);
			return;
		}
	}

	sn_check[uwcbrh->sn() & 0x00ffffff] = true;

	if (drop_out_of_order_) {
		if (uwcbrh->sn() < esn) {
			// packet is out of sequence and is to be discarded
			incrPktOoseq();

			printOnLog(Logger::LogLevel::ERROR,
					"UWCBR",
					"recv(Packet *)::packet out of sequence sn = " +
							to_string(uwcbrh->sn()) + " hrsn = " +
							to_string(hrsn) + " esn = " + to_string(esn));

			drop(p, 1, UWCBR_DROP_REASON_OUT_OF_SEQUENCE);
			return;
		}
	}

	rftt = NOW - ch->timestamp();

	if (uwcbrh->rftt_valid()) {
		double rtt = rftt + uwcbrh->rftt();
		updateRTT(rtt);
	}

	if (tracefile_enabler_) {
		printReceivedPacket(p);
	}

	updateFTT(rftt);

	incrPktRecv();

	hrsn = uwcbrh->sn();
	if (drop_out_of_order_) {
		if (uwcbrh->sn() > esn) {
			incrPktLost(uwcbrh->sn() - (esn));
		}
	}

	double dt = NOW - lrtime;
	updateThroughput(ch->size(), dt);

	lrtime = NOW;

	Packet::free(p);

	if (drop_out_of_order_) {
		if (pkts_lost + pkts_recv + pkts_last_reset != hrsn) {

			printOnLog(Logger::LogLevel::ERROR,
					"UWCBR",
					"recv(Packet *)::pkts_lost = " + to_string(pkts_lost) +
							" pkts_recv = " + to_string(pkts_recv) +
							" hrsn = " + to_string(hrsn));
		}
	}
}
