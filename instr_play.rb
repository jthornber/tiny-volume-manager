require 'lib/instr'
require 'pp'

include DM::HighLevel

#----------------------------------------------------------------

dev = '/dev/mapper/linear'
prog1 = sequence do
  create(dev)
  load(dev, 'table')
  resume(dev)

  sequence do
    suspend(dev)
    load(dev, 'a large table')
    resume(dev)
    wait(dev, 36)
  end
end

#----------------------------------------------------------------

data_dev = '/dev/mapper/data'
metadata_dev = '/dev/mapper/metadata'
pool_dev = '/dev/mapper/pool'
thin1_dev = '/dev/mapper/thin_1'
thin2_dev = '/dev/mapper/thin_2'

data_table = 'data table'
metadata_table = 'metadata table'
pool_table = 'pool table'
thin1_table = 'thin_1 table'
thin2_table = 'thin 2 table'

prog2 = sequence do
  create(data_dev)
  load(data_dev, data_table)
  resume(data_dev)

  create(metadata_dev)
  load(metadata_dev, metadata_table)
  resume(metadata_dev)

  # FIXME: zeroing of the metadata needs to go in here

  create(pool_dev)
  load(pool_dev, pool_table)
  resume(pool_dev)

  message(pool_dev, 0, "create_thin 0", "del_thin 0")
  message(pool_dev, 0, "create_thin 1", "del_thin 1")

  create(thin1_dev)
  create(thin2_dev)
  load(thin1_dev, thin1_table)
  load(thin2_dev, thin2_table)
end

#----------------------------------------------------------------

print_program optimise(prog1.compile)
