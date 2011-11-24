require 'lib/instr'
require 'pp'

#----------------------------------------------------------------

include DM::LowLevel
include DM::MediumLevel

dev = 'linear'
table = 'foosldkfjsldkjs'
table2 = 'lorem ipsum ...'


bb1 = BasicBlock.new([create(dev),
                      load(dev, table)])

bb_fail = BasicBlock.new([remove(dev)])

bb2 = BasicBlock.new([suspend(dev),
                      load(dev, table2),
                      resume(dev),
                      wait(dev, 36)])

cond = Cond.new(bb2, bb_fail)
prog = Sequence.new([bb1, cond])

Program.new(compile(prog)).pp

#----------------------------------------------------------------

