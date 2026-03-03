
PacketHeaderManager set tab_(PacketHeader/UWCBRWR) 1

Module/UW/CBRWR set packetSize_         500
Module/UW/CBRWR set period_             60
Module/UW/CBRWR set destPort_           0
Module/UW/CBRWR set destAddr_           255
Module/UW/CBRWR set debug_              0
Module/UW/CBRWR set PoissonTraffic_     1
Module/UW/CBRWR set drop_out_of_order_  1
Module/UW/CBRWR set traffic_type_		0
Module/UW/CBRWR set tracefile_enabler_  0
Module/UW/CBRWR set with_response_rate  0.1

Module/UW/CBRWR instproc init {args} {
    $self next $args
    $self settag "UW/CBRWR"
}
