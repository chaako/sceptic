c___c___c___c___c___c___c___c___c___c___c___c___c___c___c___c___c___c___
c
c This code is copyright(c) (2003-5) Ian H Hutchinson hutch@psfc.mit.edu
c
c  It may be used freely with the stipulation that any scientific or
c scholarly publication concerning work that uses the code must give an
c acknowledgement referring to the papers I.H.Hutchinson, Plasma Physics
c and Controlled Fusion, vol 44, p 1953 (2002), vol 45, p 1477 (2003).
c  The code may not be redistributed except in its original package.
c
c No warranty, explicit or implied, is given. If you choose to build
c or run the code, you do so at your own risk.
c
c Version 2.6 Aug 2005.
c___c___c___c___c___c___c___c___c___c___c___c___c___c___c___c___c___c___
c
c Common storage for reinjection from a general distribution f(v_x,v_z)
c Dimensions in vx and vz, min, max
      integer nxfvi,nzfvi,nxfva,nzfva
c We only need arrays for the non-negative cosine angles (including 0).
c This was derived from nthsize, but there were overflows.
      parameter (nthfvsize=100)
c Moving to use theta array independent of sceptic mesh
      real fvth(nthfvsize)
c These are the adjustable dimensions for storage optimization.
c Makes no sense for |nxfvi/a| to be different.
c Might make sense for |nzfvi/a| to differ. But for now they don't
      parameter (nxfva=40,nzfva=40,nxfvi=-nxfva,nzfvi=-nzfva)
c Velocity arrays
      real vxfv(nxfvi:nxfva),vzfv(nzfvi:nzfva)
c Cumulative flux distribution integrated (only) in the z-direction
c at specified vx, th.
      real qfv(nzfvi:nzfva,nxfvi:nxfva,nthfvsize)
c z-index such that the transition from positive to negative th in qfv
c occurs between int(ztrfv) and int(ztrfv+1)
      real ztrfv(nxfvi:nxfva,nthfvsize)
c Cumulative flux distribution in vx-direction at fixed th for all vz.
c I.e. the flux density below vx, crossing surface with normal at th.
c This is integral of qfv(vz=infinity), for positive and negative nz.
c Cosine(theta) goes from +-1(1) to zero(nthfvsize) (nthsize even),
c or from +-1(1) to +- a small number(nthfvsize) (odd),
c for positive+ and negative- cases.
      real qxfv(nxfvi:nxfva,nthfvsize)
c Cumulative distribution in th (cos(theta)) for all vx,vz, 
c which is integral of qxfv(infinity).
      real qthfv(nthfvsize)
c Cumulative distribution function (not flux) in vx for specified vz.
c This is actually used in the y-direction to determine the ignorable
c tangential component of velocity.
      real fqvxvz(nxfvi:nxfva,nzfvi:nzfva)
c Diagnostics
      logical ldiaginj
      common /fvcom/fvth,vxfv,vzfv,qfv,ztrfv,qxfv,qthfv,fqvxvz,ldiaginj
