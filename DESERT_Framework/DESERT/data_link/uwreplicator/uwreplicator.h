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
 * @file   uwreplicator.h
 * @brief  Declaration of UwReplicator module which replicates down-going packets.
 */

#ifndef UWREPLICATOR_H
#define UWREPLICATOR_H

#include <module.h>
#include <packet.h>

#define INVALID_REPLICAS "Replicas parameter is invalid"
#define INVALID_SPACING "Spacing parameter is invalid"

/**
 * UwReplicator replicates packets going down by a configurable factor.
 * - replicas_: number of times a packet is transmitted (>=1)
 * - spacing_: optional delay between each transmitted copy
 */
class UwReplicator : public Module {
public:
	UwReplicator();
	virtual ~UwReplicator() = default;

	virtual void recv(Packet *p) override;
	virtual void recv(Packet *p, int idSrc) override;
	virtual int command(int argc, const char *const *argv) override;

protected:
	void replicateDownAndForward(Packet *p);

	int replicas_;
	double spacing_;
};

#endif // UWREPLICATOR_H
