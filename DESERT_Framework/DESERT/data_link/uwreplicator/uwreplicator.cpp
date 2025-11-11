//
// Copyright (c) 2025 Regents of the SIGNET lab, University of Padova.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. Neither the name of the University of Padova (SIGNET lab) nor the
//    names of its contributors may be used to endorse or promote products
//    derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
/**
 * @file   uwreplicator.cpp
 * @author Your Name
 * @version 1.0.0
 *
 * \brief Simple module that replicates downward packets N times.
 */

#include "uwreplicator.h"

#include <tclcl.h>

#include <iostream>
#include <string>

static class UwReplicatorClass : public TclClass {
public:
	UwReplicatorClass()
		: TclClass("Module/UW/REPL")
	{
	}
	TclObject *create(int, const char *const *)
	{
		return (new UwReplicator());
	}
} class_module_uwreplicator;

UwReplicator::UwReplicator()
	: replicas_(1)
	, spacing_(0.5)
{
	bind("replicas_", &replicas_);
	bind("spacing_", &spacing_);
}

void UwReplicator::recv(Packet *p)
{
	// No source module id provided. Just forward based on direction.
	hdr_cmn *ch = HDR_CMN(p);
	if (ch->direction() == hdr_cmn::UP) {
		sendUp(p);
		return;
	}

	if (replicas_ < 1) {
		printOnLog(Logger::LogLevel::ERROR,
				"UW/REPL",
				std::string("Invalid number of replicas") + std::to_string(replicas_));
		drop(p, 1, INVALID_REPLICAS);
		return;
	}

	if (spacing_ < 0.0) {
		printOnLog(Logger::LogLevel::ERROR,
				"UW/REPL",
				std::string("Invalid spacing ") + std::to_string(spacing_));
		drop(p, 1, INVALID_SPACING);
		return;
	}

	replicateDownAndForward(p);
}

void UwReplicator::recv(Packet *p, int idSrc)
{
	recv(p);
}

int UwReplicator::command(int argc, const char *const *argv)
{
	Tcl &tcl = Tcl::instance();
	if (argc == 2) {
		if (strcasecmp(argv[1], "getreplicas") == 0) {
			tcl.resultf("%d", replicas_);
			return TCL_OK;
		} else if (strcasecmp(argv[1], "getspacing") == 0) {
			tcl.resultf("%f", spacing_);
			return TCL_OK;
		}
	} else if (argc == 3) {
		if (strcasecmp(argv[1], "setreplicas") == 0) {
			int val = atoi(argv[2]);
			if (val < 1)
				val = 1;
			replicas_ = val;
			return TCL_OK;
		} else if (strcasecmp(argv[1], "setspacing") == 0) {
			double val = atof(argv[2]);
			if (val < 0.0)
				val = 0.0;
			spacing_ = val;
			return TCL_OK;
		}
	}
	return Module::command(argc, argv);
}

void UwReplicator::replicateDownAndForward(Packet *p)
{
	hdr_cmn *ch = HDR_CMN(p);
	printOnLog(Logger::LogLevel::DEBUG,
			"UW/REPL",
			std::string("Replicating ") + std::to_string(replicas_) +
					" times packet " + std::to_string(ch->uid()) +
					" with spacing " + std::to_string(spacing_));

	for (int i = 0; i < replicas_; ++i) {
		Packet *repl = Module::copy(p);
		sendDown(repl, spacing_*i);
	}

	Packet::free(p);
}
