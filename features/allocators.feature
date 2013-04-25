Feature: Allocators

  As sys admin I want to be able to be to specify how a volume is
  built up from underlying devices.

  Allocation set:

    A group of volumes the allocator may allocate from.  If you want
    to allocate from a region of a volume define a new volume on top
    of it (see fixed-linear).

  Types of allocator:

    fixed-linear: eg, for specifying regions of disk - I think this
      may be a special case

    linear: takes 1 allocation set and does something sensible (we
      don't expose best-fit, largest-first etc.).

    stripe: takes n allocation sets

    thin-pool: 2 allocation sets; metadata and data

    thin: take a thin-pool

    mirror, raid 2: n allocation sets

    raid5:

    raid

  Things to think about:

  - If we run out of allocation space should we resize the underlying
    allocation volumes (assuming they have allocators defined?).  eg,
    resizing a pool, triggers resizing metadata device, triggers
    resizing underlying mirror dev.

    Really need to think this through.  It's important we get a simple
    conceptual model here.

  - Mixed models.  Say a volume starts out striped, and then the admin
    switches to a linear allocator.  We end up with a volume that's
    partly striped, and partly linear.  Obviously dm can handle this,
    but is it something people want to do?  Is it sensible, or should
    we force one allocator for the entirety of a volume.

    We could go with 1 allocator for the lifetime of a volume, and use
    stacking for mixed targets.  That way things like mirror recovery
    are alway acting on a complete volume (just not necc. a top level
    one).

    Activation optimisation would make sure that these extra levels
    don't get instanced.  There is not a one to one mapping between
    tvm volumes and dm devices.

  - We need to be able to view these volume hierarchies.  Perhaps it
    would be best to start with a tree view module?


  - By default the sys admin should only be able to activate top level
    volumes.  Activation of lower levels may well occur, but we'll not
    parade this fact in front of the admin.

    Sometimes lower levels do need to be operated upon though.  For
    example, repairing a damaged thin_pool, or viewing a metadata
    snapshot.  What is the process for this?  Do we have to disable
    higher levels (unnecc. for read-only access like metadata snaps).

  - Do we wawnt to make allocators first class objects (from the
    admin's point of view)?  Or can we make volumes/allocators the
    same thing?

    Steps the admin goes through when setting up a simple system:

    i) use fixed-linear to specify some PVs

    ii) create a bunch of volumes

    iii) create a couple of allocators that use various bits of the PVs

    iii) link volumes to allocators
 
    iv) resize volumes

  - Can allocators share PVs?  I think we have to allow this, eg,
    mirrors and linear require different allocators?

  Scenario: Every volume has an allocator field


  Scenario: Every volume has an allocatable field (not sure about this)

  Scenario: 