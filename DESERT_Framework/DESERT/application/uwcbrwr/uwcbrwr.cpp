#include "uwcbrwr.h"

#include <iostream>
#include <rng.h>
#include <stdint.h>
#include <string>

extern packet_t PT_UWCBRWR;

int hdr_uwcbrwr::offset_; /**< Offset used to access in <i>hdr_uwcbr</i> packets
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
} class_uwcbrwr_pkt;

/**
 * Adds the module for UwCbrUWModuleClass in ns2.
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

UwCbrWRModule::UwCbrWRModule()
	: UwCbrModule(),
	with_response_rate(0.1)
{ // binding to TCL variables
	bind("with_response_rate", &with_response_rate);
//	bind("period_", &period_);
//	bind("with_response_rate", &with_response_rate);
//	bind("with_response_rate", &with_response_rate);
//	bind("with_response_rate", &with_response_rate);
}

int
UwCbrWRModule::command(int argc, const char *const *argv)
{
	Tcl &tcl = Tcl::instance();
	if (argc == 2) {
 		if (strcasecmp(argv[1], "getWithResponseRate") == 0) {
			tcl.resultf("%f", getWithResponseRate());
			return TCL_OK;
		}
	}
	return UwCbrModule::command(argc, argv);
}

void UwCbrWRModule::initPkt(Packet *p) {
	UwCbrModule::initPkt(p);

	hdr_cmn *ch = hdr_cmn::access(p);
	ch->ptype() = PT_UWCBRWR;

	hdr_uwcbrwr* uwcbrwr = hdr_uwcbrwr::access(p);
	double u = RNG::defaultrng()->uniform_double();
	uwcbrwr->response_flag() = u < with_response_rate;
}

void
UwCbrWRModule::recv(Packet *p, Handler *h)
{
	recv(p);
}

void
UwCbrWRModule::recv(Packet *p)
{
	// TODO: generate a response packet if response flag is set
	hdr_cmn *ch = hdr_cmn::access(p);
	hdr_uwcbr* cbr_hdr = hdr_uwcbr::access(p);
	hdr_uwcbrwr* cbrwr_hdr = hdr_uwcbrwr::access(p);
	hdr_uwudp* udp_hdr = hdr_uwudp::access(p);
	hdr_uwip* ip_hdr = hdr_uwip::access(p);
	auto ip_src = ip_hdr->saddr();
	auto port_src = udp_hdr->sport();
	bool response_flag = false;
	Packet* resp = nullptr;
	packet_t ptype = ch->ptype();
	if (ptype != PT_UWCBRWR && ptype != PT_UWCBR) {
		drop(p, 1, UWCBR_DROP_REASON_UNKNOWN_TYPE);
		incrPktInvalid();
		return;
	}

	if (!drop_out_of_order_ && sn_check[cbr_hdr->sn() & 0x00ffffff]) {
		// Packet already processed: drop it
		incrPktInvalid();
		drop(p, 1, UWCBR_DROP_REASON_DUPLICATED_PACKET);
		return;
	} else if (drop_out_of_order_ && cbr_hdr->sn() < esn) {
		// packet is out of sequence and is to be discarded
		incrPktOoseq();

		printOnLog(Logger::LogLevel::ERROR,
				   "UWCBRWR",
				   "recv(Packet *)::packet out of sequence sn = " +
				   to_string(cbr_hdr->sn()) + " hrsn = " +
				   to_string(hrsn) + " esn = " + to_string(esn));

		drop(p, 1, UWCBR_DROP_REASON_OUT_OF_SEQUENCE);
		return;
	}

	if (ptype == PT_UWCBRWR) {
		ch->ptype() = PT_UWCBR;
		response_flag = cbrwr_hdr->response_flag();
		resp = p->copy();
	}

	// Packet p is freed
	UwCbrModule::recv(p);

	if (!response_flag) {
		if (resp != nullptr) {
			Packet::free(resp);
		}
		return;
	}

	printOnLog(Logger::LogLevel::DEBUG, "UWCBRWR",
			"recv(Packet *)::Sending response to " + to_string(ip_src) + ":" + to_string(port_src));

	ch = hdr_cmn::access(resp);
	ch->direction() = hdr_cmn::DOWN;
	ch->timestamp() = Scheduler::instance().clock();

	cbrwr_hdr = hdr_uwcbrwr::access(resp);
	cbrwr_hdr->response_flag() = false;

	udp_hdr = hdr_uwudp::access(resp);
	udp_hdr->sport() = 0;
	udp_hdr->dport() = port_src;

	ip_hdr = hdr_uwip::access(resp);
	ip_hdr->saddr() = 0;
	ip_hdr->daddr() = ip_src;

	sendDown(resp);
}

double UwCbrWRModule::getWithResponseRate() const {
	return with_response_rate;
}
