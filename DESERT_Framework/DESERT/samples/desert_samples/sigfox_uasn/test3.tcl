#
# Copyright (c) 2015 Regents of the SIGNET lab, University of Padova.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the University of Padova (SIGNET lab) nor the
#    names of its contributors may be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# This script is used to test uwhermesphy physical layer
# There are 4 nodes placed in line that can transmit each other packets
# with a CBR (Constant Bit Rate) Application Module and Csma_Aloha datalink
# Here the complete stack used for the simulation
#
# N.B.: UnderwaterChannel and UW/AHOI/PHY are used for PHY layer and channel
#
# Author: Filippo Campagnaro <campagn1@dei.unipd.it>
#
# Version: 1.0.0
#
# NOTE: tcl sample tested on Ubuntu 11.10, 64 bits OS
#
# Stack of the nodes
#   +-------------------------+
#   |  7. UW/CBR              |
#   +-------------------------+
#   |  6. UW/UDP              |
#   +-------------------------+
#   |  5. UW/STATICROUTING    |
#   +-------------------------+
#   |  4. UW/IP               |
#   +-------------------------+
#   |  3. UW/MLL              |
#   +-------------------------+
#   |  2. UW/CSMA_ALOHA       |
#   +-------------------------+        +-------------------------------+
#   |  1. Module/UW/HERMES/PHY| <----- |   UW/INTERFERENCE (MEANPOWER) |
#   +-------------------------+        +-------------------------------+
#           |         |                          ^
#   +-------------------------+                  |
#   |    UnderwaterChannel    |-------------------
#   +-------------------------+

# TODO: Positioning
# TODO: Sleep mode
# TODO: Broadcast messages (filter repetitions)
# TODO: Improve statistics
# TODO: Message replication
# TODO: Energy consumption
# TODO: Downlink ?

######################################
# Flags to enable or disable options #
######################################
set opt(verbose) 			1
set opt(trace_files)		1
set opt(bash_parameters) 	0
set opt(ACK_Active)         0

#####################
# Library Loading   #
#####################
load libMiracle.so
load libMiracleBasicMovement.so
load libmphy.so
load libmmac.so
load libuwip.so
load libuwstaticrouting.so
load libuwmll.so
load libuwudp.so
load libuwcbr.so
load libuwcsmaaloha.so
load libuwinterference.so
load libUwmStd.so
load libuwphy_clmsgs.so
load libuwstats_utilities.so
load libuwphysical.so
load libuwahoi_phy.so

# NS-Miracle initialization #
#############################
# You always need the following two lines to use the NS-Miracle simulator
set ns [new Simulator]
$ns use-Miracle

##################
# Tcl variables  #
##################
set opt(nn)                 4 ;# Number of Nodes
set opt(sink_mode)          1   ;# 1 or 3 values are possible
set opt(pktsize)            32  ;# Pkt sike in byte
set opt(starttime)          1
set opt(stoptime)           10000
set opt(txduration)         [expr $opt(stoptime) - $opt(starttime)] ;# Duration of the simulation

set opt(txpower)            156.0  ;#Power transmitted in dB re uPa
set opt(max_range)          100  ;# Max transmission range

set opt(maxinterval_)       200.0
set opt(freq)               50000.0 ;#Frequency used in Hz
set opt(bw)                 25000.0 ;#Bandwidth used in Hz
set opt(bitrate)            195.3 ;#150000;#bitrate in bps
set opt(cbr_period) 60
set opt(pktsize)	32
set opt(rngstream)	1

if {$opt(bash_parameters)} {
	if {$argc != 3} {
		puts "The script requires three inputs:"
		puts "- the first for the seed"
		puts "- the second one is for the Poisson CBR period"
		puts "- the third one is the cbr packet size (byte);"
		puts "example: ns test_uw_csma_aloha_fully_connected.tcl 1 60 125"
		puts "If you want to leave the default values, please set to 0"
		puts "the value opt(bash_parameters) in the tcl script"
		puts "Please try again."
		return
	} else {
		set opt(rngstream)    [lindex $argv 0]
		set opt(cbr_period) [lindex $argv 1]
		set opt(pktsize)    [lindex $argv 2]
	}
}

if {$opt(ACK_Active)} {
    set opt(ack_mode)           "setAckMode"
} else {
    set opt(ack_mode)           "setNoAckMode"
}

global defaultRNG
for {set k 0} {$k < $opt(rngstream)} {incr k} {
	$defaultRNG next-substream
}

if {$opt(trace_files)} {
	set opt(tracefilename) "./test_uwhermesphy_simple.tr"
	set opt(tracefile) [open $opt(tracefilename) w]
	set opt(cltracefilename) "./test_uwhermesphy_simple.cltr"
	set opt(cltracefile) [open $opt(tracefilename) w]
} else {
	set opt(tracefilename) "/dev/null"
	set opt(tracefile) [open $opt(tracefilename) w]
	set opt(cltracefilename) "/dev/null"
	set opt(cltracefile) [open $opt(cltracefilename) w]
}

set BROADCAST_ADDRESS 255
set BROADCAST_PORT    4000

MPropagation/Underwater set practicalSpreading_ 1.8
MPropagation/Underwater set debug_              0
MPropagation/Underwater set windspeed_          1



set channel [new Module/UnderwaterChannel]
set propagation [new MPropagation/Underwater]
set data_mask [new MSpectralMask/Rect]
$data_mask setFreq       $opt(freq)
$data_mask setBandwidth  $opt(bw)

#########################
# Module Configuration  #
#########################
Module/UW/CBR set packetSize_          $opt(pktsize)
Module/UW/CBR set period_              $opt(cbr_period)
Module/UW/CBR set PoissonTraffic_      1
Module/UW/CBR set debug_               1

Module/UW/MLL set debug_               1
Module/UW/IP  set debug_               1

Module/UW/AHOI/PHY  set BitRate_                    $opt(bitrate)
Module/UW/AHOI/PHY  set AcquisitionThreshold_dB_    5.0
Module/UW/AHOI/PHY  set RxSnrPenalty_dB_            0
Module/UW/AHOI/PHY  set TxSPLMargin_dB_             0
Module/UW/AHOI/PHY  set MaxTxSPL_dB_                $opt(txpower)
Module/UW/AHOI/PHY  set MinTxSPL_dB_                10
Module/UW/AHOI/PHY  set MaxTxRange_                 200
Module/UW/AHOI/PHY  set PER_target_                 0
Module/UW/AHOI/PHY  set CentralFreqOptimization_    0
Module/UW/AHOI/PHY  set BandwidthOptimization_      0
Module/UW/AHOI/PHY  set SPLOptimization_            0
Module/UW/AHOI/PHY  set debug_                      0

################################
# Procedure(s) to create nodes #
################################
proc createNode { id } {

    global channel propagation data_mask ns cbr position node udp portnum ipr ipif channel_estimator
    global phy posdb opt rvposx rvposy rvposz mhrouting mll mac woss_utilities woss_creator db_manager
    global node_coordinates interf_data
    global sink_ids node_ids

    if {$id > 254} {
		puts "Max id value is 254"
		exit
    }

    if {[lsearch -exact $sink_ids $id] != -1} {
        puts "Id is taken by a sink!"
        exit
    }

    set node($id) [$ns create-M_Node $opt(tracefile) $opt(cltracefile)]
    #foreach sink_id $sink_ids {
	#	set cbr($id,$sink_id)  [new Module/UW/CBR]
    #}

    set cbr($id)  [new Module/UW/CBR]
    set udp($id)  [new Module/UW/UDP]
    set ipr($id)  [new Module/UW/StaticRouting]
    set ipif($id) [new Module/UW/IP]
    set mll($id)  [new Module/UW/MLL]
    set mac($id)  [new Module/UW/CSMA_ALOHA]
    set phy($id)  [new Module/UW/AHOI/PHY]

    $ipr($id) setLog 3 "log_ip_$id.out"
    $udp($id) setLog 3 "log_udp_$id.out"
    $cbr($id) setLog 3 "log_cbr_$id.out"

	#foreach sink_id $sink_ids {
	#    $node($id) addModule 7 $cbr($id,$sink_id)   1  "CBR"
	#}

	$node($id) addModule 7 $cbr($id)   1  "CBR"
    $node($id) addModule 6 $udp($id)   1  "UDP"
    $node($id) addModule 5 $ipr($id)   1  "IPR"
    $node($id) addModule 4 $ipif($id)  1  "IPF"
    $node($id) addModule 3 $mll($id)   1  "MLL"
    $node($id) addModule 2 $mac($id)   1  "MAC"
    $node($id) addModule 1 $phy($id)   0  "PHY"

	#foreach sink_id $sink_ids {
	#	$node($id) setConnection $cbr($id,$sink_id)   $udp($id)   1
	#	set portnum($id,$sink_id) [$udp($id) assignPort $cbr($id,$sink_id)]
	#}

	# We do only broadcast
    $node($id) setConnection $cbr($id)   $udp($id)   1
    set portnum($id) [$udp($id) assignPort $cbr($id)]
    $node($id) setConnection $udp($id)      $ipr($id)   1
    $node($id) setConnection $ipr($id)      $ipif($id)  1
    $node($id) setConnection $ipif($id)     $mll($id)   1
    $node($id) setConnection $mll($id)      $mac($id)   1
    $node($id) setConnection $mac($id)      $phy($id)   1
    $node($id) addToChannel  $channel       $phy($id)   1

    #Set the IP address of the node
    set ip_addr_value [expr $id + 1]
    $ipif($id) addr $ip_addr_value

    set position($id) [new "Position/BM"]
    $node($id) addPosition $position($id)
    set posdb($id) [new "PlugIn/PositionDB"]
    $node($id) addPlugin $posdb($id) 20 "PDB"
    $posdb($id) addpos [$ipif($id) addr] $position($id)

    #Interference model
    set interf_data($id)  [new "Module/UW/INTERFERENCE"]
    $interf_data($id) set maxinterval_ $opt(maxinterval_)
    $interf_data($id) set debug_       0

	#Propagation model
    $phy($id) setPropagation $propagation

    $phy($id) setSpectralMask $data_mask
    $phy($id) setInterference $interf_data($id)
    $phy($id) setInterferenceModel "MEANPOWER"; # "CHUNK" is not supported
    $phy($id) setRangePDRFileName "../dbs/ahoi/default_pdr.csv"
    $phy($id) setSIRFileName "../dbs/ahoi/default_sir.csv"
    $phy($id) initLUT
    $mac($id) $opt(ack_mode)
    $mac($id) initialize
}

set cbr_sink       [new Module/UW/CBR]
#set udp_sink       [new Module/UW/UDP]
#set portnum_sink   [$udp_sink assignPort $cbr_sink]
#
#$udp_sink setLog 3 "log_udp.out"

proc createSink { id } {

    global channel propagation smask data_mask ns cbr_sink position_sink node_sink udp_sink portnum_sink interf_data_sink
    global phy_data_sink posdb_sink opt mll_sink mac_sink ipr_sink ipif_sink bpsk interf_sink
    global sink_ids node_ids

    if {$id > 254} {
		puts "Max id value is 254"
		exit
    }

    if {[lsearch -exact $sink_ids $id] != -1} {
        puts "Id is taken by another sink!"
        exit
    }

    set node_sink($id) [$ns create-M_Node $opt(tracefile) $opt(cltracefile)]

    #for {set cnt 0} {$cnt < $opt(nn)} {incr cnt} {
    #    set cbr_sink($id,$cnt)  [new Module/UW/CBR]
    #}
    set udp_sink($id)       [new Module/UW/UDP]
    set ipr_sink($id)       [new Module/UW/StaticRouting]
    set ipif_sink($id)      [new Module/UW/IP]
    set mll_sink($id)       [new Module/UW/MLL]
    set mac_sink($id)       [new Module/UW/CSMA_ALOHA]
    set phy_data_sink($id)  [new Module/UW/AHOI/PHY]

    #foreach node_id $node_ids {
    #    $node_sink($id) addModule 7 $cbr_sink($id,$node_id) 0 "CBR"
    #}
    #for { set cnt 0} {$cnt < $opt(nn)} {incr cnt} {
    #    $node_sink($id) addModule 7 $cbr_sink($id,$cnt) 0 "CBR"
    #}

    $node_sink($id) addModule 7 $cbr_sink 0 "CBR"
    $node_sink($id) addModule 6 $udp_sink($id)       0 "UDP"
    $node_sink($id) addModule 5 $ipr_sink($id)       0 "IPR"
    $node_sink($id) addModule 4 $ipif_sink($id)      0 "IPF"
    $node_sink($id) addModule 3 $mll_sink($id)       0 "MLL"
    $node_sink($id) addModule 2 $mac_sink($id)       0 "MAC"
    $node_sink($id) addModule 1 $phy_data_sink($id)  0 "PHY"

    #foreach node_id $node_ids {
    #    $node_sink($id) setConnection $cbr_sink($id,$node_id)  $udp_sink($id)      0
    #}
    #for { set cnt 0} {$cnt < $opt(nn)} {incr cnt} {
    #    $node_sink($id) setConnection $cbr_sink($id,$cnt)  $udp_sink($id)      0
    #}

    $node_sink($id) setConnection $cbr_sink  $udp_sink($id)      0
    $node_sink($id) setConnection $udp_sink($id)  $ipr_sink($id)            0
    $node_sink($id) setConnection $ipr_sink($id)  $ipif_sink($id)           0
    $node_sink($id) setConnection $ipif_sink($id) $mll_sink($id)            0
    $node_sink($id) setConnection $mll_sink($id)  $mac_sink($id)            0
    $node_sink($id) setConnection $mac_sink($id)  $phy_data_sink($id)       0
    $node_sink($id) addToChannel  $channel   $phy_data_sink($id)       0

    set portnum_sink [$udp_sink($id) assignPort $cbr_sink]
    puts "Port: $portnum_sink"

    #foreach node_id $node_ids {
    #    set portnum_sink($node_id) [$udp_sink($id) assignPort $cbr_sink($node_id)]
    #}
    #for { set cnt 0} {$cnt < $opt(nn)} {incr cnt} {
    #    set portnum_sink($id,$cnt) [$udp_sink($id) assignPort $cbr_sink($id,$cnt)]
    #    if {$cnt >= 252} {
    #        puts "hostnum > 252!!! exiting"
    #        exit
    #    }
    #}

    $ipif_sink($id) addr $id

    set position_sink($id) [new "Position/BM"]
    $node_sink($id) addPosition $position_sink($id)
    set posdb_sink($id) [new "PlugIn/PositionDB"]
    $node_sink($id) addPlugin $posdb_sink($id) 20 "PDB"

    # TODO: Figure what this line does
    $posdb_sink($id) addpos [$ipif_sink($id) addr] $position_sink($id)

    #Interference model
    set interf_data($id)  [new "Module/UW/INTERFERENCE"]
    $interf_data($id) set maxinterval_ $opt(maxinterval_)
    $interf_data($id) set debug_       0

    #Propagation model
    $phy_data_sink($id) setPropagation $propagation

    $phy_data_sink($id) setSpectralMask $data_mask
    $phy_data_sink($id) setInterference $interf_data($id)
    $phy_data_sink($id) setInterferenceModel "MEANPOWER"; # "CHUNK" is not supported
    $phy_data_sink($id) setRangePDRFileName "../dbs/ahoi/default_pdr.csv"
    $phy_data_sink($id) setSIRFileName "../dbs/ahoi/default_sir.csv"
    $phy_data_sink($id) initLUT
    $mac_sink($id) $opt(ack_mode)
    $mac_sink($id) initialize
}

#################
# Node id generation #
#################
set node_ids [list]
for {set id 0} {$id < $opt(nn)} {incr id}  {
    lappend node_ids $id
}

#################
# Sink Creation #
#################
if {$opt(sink_mode) != 1 && $opt(sink_mode) != 3} {
    error "Invalid sink_mode. Possible modes are 1 and 3"
}
set sink_ids [list]
for {set i 0} {$i < $opt(sink_mode)} {incr i}  {
    createSink [expr 254 - $i]
    lappend sink_ids [expr 254 - $i]
}

####################
# Sink Positioning #
####################
$position_sink(254) setX_ [expr 0]
$position_sink(254) setY_ [expr 0]
$position_sink(254) setZ_ -1

if {$opt(sink_mode) == 3} {
    $position_sink(253) setX_ [expr -$opt(max_range)]
    $position_sink(253) setY_ [expr 0]
    $position_sink(253) setZ_ -1

    $position_sink(252) setX_ [expr $opt(max_range)]
    $position_sink(252) setY_ [expr 0]
    $position_sink(252) setZ_ -1
}

#################################
# Node Creation and Positioning #
#################################
foreach node_id $node_ids {
    createNode $node_id

    set rand_x [$defaultRNG uniform -$opt(max_range) $opt(max_range)]
    set rand_y [$defaultRNG uniform 0 [expr {sqrt(3)*$opt(max_range)/2}]]

    $position($node_id) setX_ [expr $rand_x]
    $position($node_id) setY_ [expr $rand_y]
    $position($node_id) setZ_ -1
}

################################
# Inter-node module connection #
################################
proc connectNodeAndSink {node_id sink_id} {
    global ipif ipr portnum cbr cbr_sink ipif_sink portnum_sink ipr_sink opt
    global BROADCAST_ADDRESS

    #$cbr($node_id,$sink_id) set destAddr_ [$ipif_sink($sink_id) addr]
    $cbr($node_id) set destAddr_ 0xff
    #$cbr($node_id) set destAddr_ [$ipif_sink($sink_id) addr]
    #$cbr($node_id,$sink_id) set destPort_ $portnum_sink($sink_id,$node_id)
    $cbr($node_id) set destPort_ $portnum_sink

    puts "Port: $portnum_sink"

    #$cbr_sink($sink_id,$node_id) set destAddr_ [$ipif($node_id) addr]
    #$cbr_sink($sink_id,$node_id) set destPort_ $portnum($node_id,$sink_id)
}

##################
# Setup flows    #
##################
foreach sink_id $sink_ids {
    foreach node_id $node_ids {
        connectNodeAndSink $node_id $sink_id
    }
}
#for {set id1 0} {$id1 < $opt(nn)} {incr id1}  {
#	for {set id2 0} {$id2 < $opt(nn)} {incr id2}  {
#		if {$id1 != $id2} {
#			connectNodes $id1 $id2
#		}
#	}
#}

##################
# ARP tables     #
##################
foreach node_id $node_ids {
    foreach sink_id $sink_ids {
        $mll($node_id) addentry [$ipif_sink($sink_id) addr] [$mac_sink($sink_id) addr]
        $mll($node_id) addentry 255 [$mac_sink($sink_id) addr]
    }
}
#for {set id1 0} {$id1 < $opt(nn)} {incr id1}  {
#    for {set id2 0} {$id2 < $opt(nn)} {incr id2}  {
#      $mll($id1) addentry [$ipif($id2) addr] [$mac($id2) addr]
#	}
#}



##################
# Routing tables #
##################
foreach node_id $node_ids {
    foreach sink_id $sink_ids {
        # set src [expr $node_id]
        $ipr($node_id) addRoute $sink_id $sink_id
    }
    $ipr($node_id) addRoute 255 255
}
#for {set id1 0} {$id1 < $opt(nn)} {incr id1}  {
#	for {set id2 0} {$id2 < $opt(nn)} {incr id2}  {
#			set ip_value [expr $id2 + 1]
#            $ipr($id1) addRoute ${ip_value} ${ip_value}
#	}
#}

#####################
# Start/Stop Timers #
#####################
# Set here the timers to start and/or stop modules (optional)
# e.g.,
foreach sink_id $sink_ids {
    foreach node_id $node_ids {
        $ns at $opt(starttime)    "$cbr($node_id) start"
        $ns at $opt(stoptime)     "$cbr($node_id) stop"
    }
}
#for {set id1 0} {$id1 < $opt(nn)} {incr id1}  {
#	for {set id2 0} {$id2 < $opt(nn)} {incr id2} {
#		if {$id1 != $id2} {
#			$ns at $opt(starttime)    "$cbr($id1,$id2) start"
#			$ns at $opt(stoptime)     "$cbr($id1,$id2) stop"
#		}
#	}
#}

###################
# Final Procedure #
###################
# Define here the procedure to call at the end of the simulation
proc finish {} {
    global ns opt outfile
    global mac propagation cbr_sink mac_sink phy phy_data_sink channel db_manager propagation
    global node_coordinates position
    global ipr_sink ipr ipif udp cbr phy phy_data_sink
    global node_stats tmp_node_stats sink_stats tmp_sink_stats
    global sink_ids node_ids
    if ($opt(verbose)) {
        puts "---------------------------------------------------------------------"
        puts "Simulation summary"
        puts "number of nodes  : $opt(nn)"
        puts "sink mode        : $opt(sink_mode)"
        puts "packet size      : $opt(pktsize) byte"
        puts "cbr period       : $opt(cbr_period) s"
        puts "simulation length: $opt(txduration) s"
        puts "tx power         : $opt(txpower) dB"
        puts "tx frequency     : $opt(freq) Hz"
        puts "tx bandwidth     : $opt(bw) Hz"
        puts "bitrate          : $opt(bitrate) bps"
        if {$opt(ack_mode) == "setNoAckMode"} {
            puts "ACKNOWLEDGEMENT   : disabled"
        } else {
            puts "ACKNOWLEDGEMENT   : active"
        }
        puts "---------------------------------------------------------------------"
    }
    set sum_cbr_throughput     0
    set sum_per                0
    set sum_cbr_sent_pkts      0.0
    set sum_cbr_rcv_pkts       0.0
    set sum_rtx                0.0
    set cbr_throughput         0.0
    set cbr_per                0.0

    set cbr_rcv_pkts                [$cbr_sink getrecvpkts]
    set cbr_sink_throughput         [$cbr_sink getthr]
    set cbr_sink_per                [$cbr_sink getper]

    if ($opt(verbose)) {
        puts "cbr_sink Throughput     : $cbr_sink_throughput"
        puts "cbr_sink PER            : $cbr_sink_per"
        puts "-------------------------------------------"
    }

    foreach node_id $node_ids {
        set position_x              [$position($node_id) getX_]
        set position_y              [$position($node_id) getY_]
        set cbr_throughput              [$cbr($node_id) getthr]
        set cbr_per                     [$cbr($node_id) getper]
        set cbr_sent_pkts               [$cbr($node_id) getsentpkts]

        puts "position($node_id) X     : $position_x"
        puts "position($node_id) Y     : $position_y"
        puts "cbr($node_id) Throughput     : $cbr_throughput"
        puts "cbr($node_id) PER            : $cbr_per       "
        set sum_cbr_sent_pkts [expr $sum_cbr_sent_pkts + $cbr_sent_pkts]
    }

    set ipheadersize        [$ipif(1) getipheadersize]
    set udpheadersize       [$udp(1) getudpheadersize]
    set cbrheadersize       [$cbr(1) getcbrheadersize]
    set sum_cbr_throughput [expr $sum_cbr_throughput + $cbr_sink_throughput]
    set sum_cbr_rcv_pkts  [expr $sum_cbr_rcv_pkts + $cbr_rcv_pkts]


    if ($opt(verbose)) {
        puts "Mean Throughput           : [expr ($sum_cbr_throughput/$opt(sink_mode))]"
        puts "Sent Packets              : $sum_cbr_sent_pkts"
        puts "Received Packets          : $sum_cbr_rcv_pkts"
        puts "Packet Delivery Ratio     : [expr $sum_cbr_rcv_pkts / $sum_cbr_sent_pkts * 100]"
        puts "IP Pkt Header Size        : $ipheadersize"
        puts "UDP Header Size           : $udpheadersize"
        puts "CBR Header Size           : $cbrheadersize"
        if {$opt(ack_mode) == "setAckMode"} {
            puts "MAC-level average retransmissions per node : [expr $sum_rtx/($opt(nn))]"
        }
        puts "---------------------------------------------------------------------"
        puts "- Example of PHY layer statistics for node 1 -"
        puts "Tot. pkts lost            : [$phy(1) getTotPktsLost]"
        puts "done!"
    }

    $ns flush-trace
    close $opt(tracefile)
}

###################
# start simulation
###################
if ($opt(verbose)) {
    puts "\nStarting Simulation\n"
    puts "----------------------------------------------"
}


$ns at [expr $opt(stoptime) + 250.0]  "finish; $ns halt"

$ns run
