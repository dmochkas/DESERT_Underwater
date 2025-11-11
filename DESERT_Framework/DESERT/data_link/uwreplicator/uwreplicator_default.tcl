#
# Defaults for the UwReplicator module
#
# This module replicates downward packets N times.
#

Module/UW/REPL set replicas_ 1
Module/UW/REPL set spacing_  0.5

Module/UW/REPL instproc init {args} {
    $self next $args
    $self settag "UW/REPL"
}
