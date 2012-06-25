require 'lib/device-mapper/instr'
require 'pp'

#----------------------------------------------------------------

include DM::LowLevel
include DM::MediumLevel

dev = 'linear'
table =<<EOF
0 4194304 thin-pool /dev/mapper/test-dev-664792 /dev/mapper/test-dev-236096 128 0
4194304 8388608 thin-pool /dev/mapper/test-dev-784461 /dev/mapper/test-dev-720393 128 0
EOF

table2 =<<EOF
0 4194304 thin-pool /dev/mapper/test-dev-753075 /dev/mapper/test-dev-518628 128 0
4194304 8388608 linear /dev/vdc 8388608
EOF

bb1 = BasicBlock.new([create(dev),
                      load(dev, table)])

bb_fail = BasicBlock.new([remove(dev)])

bb2 = BasicBlock.new([suspend(dev),
                      load(dev, table2),
                      resume(dev),
                      wait(dev, 36)])

cond = Cond.new(bb2, bb_fail)
prog = Sequence.new([bb1, cond])

compile(prog).pp

#----------------------------------------------------------------
