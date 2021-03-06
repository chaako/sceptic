
c***********************************************************************

c To use for simple reinjection when there is no flow velocity.
c Maxinjinit should be actualized regularly since it depends the potential
c on the boundary, but for now it is not done.
c The adiabatic reinjection is considerent as a restriction of the 3D one,
c So that we only have 1 maxinjinit for the 3D case.


      subroutine maxreinject(i,dt)

      integer i
      real dt
c Common data:
      include 'piccom.f'

      vscale=sqrt(Ti)
      vdi=vd/vscale
      cerr=0.
      idum=1
 1    continue
      y=ran0(idum)
c Quick fixing to prevent some errors
      if(y.gt.1-1e-6) then
c         write(*,*) y,nrein
         y=1-1e-6
      endif

c Pick angle from cumulative Q.
      call invtfunc(Qcom,nQth,y,x)
      ic1=x
      if(x.lt.1. .or. x.ge.float(nQth))then
         write(*,*)  'REINJECT Q-Error'
         write(*,*)'y,x,nQth=',y,x,nQth
         write(*,*)'Qcom=',Qcom
         goto 1
      endif
c      if(ic1.ge.nQth)ic1=ic1-1
      ic2=ic1+1
      dc=x-ic1
 2    continue
      x=dc+ic1
      yy=ran0(idum)
c Quick fixing to prevent some errors
      if(yy.gt.1-1e-6) then
c         write(*,*) yy,nrein
         yy=1-1e-6
      endif
c Pick normal velocity from cumulative G.
      call invtfunc(Gcom(1,ic1),nvel,yy,v1)
      call invtfunc(Gcom(1,ic2),nvel,yy,v2)
      vr=dc*v2+(1.-dc)*v1

      if(vr.lt.1. .or. vr.ge.nvel) then
         write(*,*) 'REINJECT V-Error'
         write(*,*) yy,v1,v2,ic1,ic2,nvel,vr,nQth
         goto 2
      endif
      iv=vr
      dv=vr-iv
      vr=dv*Vcom(iv+1)+(1.-dv)*Vcom(iv)
c New angle interpolation.
      ct=1.-2.*(x-1.)/(nQth-1)
c Map back to th for phihere.
      call invtfunc(th(1),nth,ct,x)
      ic1h=x
      ic2h=ic1h+1
      dch=x-ic1h
c Old version used th() directly.
c      ct=th(ic1)*(1.-dc)+th(ic2)*dc
c      write(*,*)'ic1,ic2,dc,ct',ic1,ic2,dc,ct
c ct is cosine of the angle of the velocity -- opposite to the radius.      
      st=sqrt(1.- ct**2)
c Now we have cosine theta=c and normal velocity normalized to v_ti.
c Theta and phi velocities are (shifted) Maxwellians but we are working
c in units of vti.
      vt=gasdev(idum)- st*vdi
      vp=gasdev(idum)
c All velocities now.
      p=2.*pi*ran0(idum)
      cp=cos(p)
      sp=sin(p)
c      write(*,*)ct,st,cp,sp
c If velocity is normalized to sqrt(Te/mi), and Ti is Ti/Te really,
c then a distribution with standard deviation sqrt(Ti/mi) is obtained
c from the unit variance random distribution multiplied by sqrt(Ti)=vscale.
      xp(6,i)=(vr*ct - vt*st)*vscale
      xp(5,i)=((vr*st+ vt*ct)*sp + vp*cp)*vscale
      xp(4,i)=((vr*st+ vt*ct)*cp - vp*sp)*vscale

      rs=-r(nr)*0.99999
      xp(3,i)=rs*ct
      xp(2,i)=(rs*st)*sp
      xp(1,i)=(rs*st)*cp

c With a magnetic field, phihere is only calculated on top of the probe
c      if (Bz.eq.0) then
c         phihere=phi(NRUSED,ic1h)*(1.-dch)+phi(NRUSED,ic2h)*dch
c      else
         phihere=averein
c      endif

      vv2=(vt**2 + vr**2 + vp**2)*vscale**2
      vz2=xp(6,i)**2
c Reject particles that have too low an energy
c bcr=1 means isotropic reinjection
c bcr=2 means adiabatic, so the velocity increase is only on the z direction
      if (bcr.ne.2) then
c The angle is chosen by the distribution of injinit, so if fail, keep the same
         if(.not.vv2.gt.-2.*phihere) goto 2
      elseif (bcr.eq.2) then
         if (.not.(vv2.gt.-2*phihere)) goto 2
c If 3D launch is ok, count in the tries for diags.f
         nreintry=nreintry+1
c If Adiabatic launch fails, chose again an angle
         if(.not.vz2.gt.-2.*phihere) goto 1
      endif


c Increment the position by a random amount of the velocity.
c This is equivalent to the particle having started at an appropriately
c random position prior to reentering the domain.
c      xinc=ran0(idum)*dt
c      xinc=0.

c Suppress the initial advance with the new advancing.f
c         do j=1,3
c            vdx=vdx+xp(j,i)*xp(j+3,i)
c         enddo
c         xp(3,i)=xp(3,i)+xp(6,i)*xinc
c         if(Bz.eq.0) then
c            do j=1,2
c               xp(j,i)=xp(j,i)+xp(j+3,i)*xinc
c            enddo
c         else
c            cosomdt=cos(Bz*xinc)
c            sinomdt=sin(Bz*xinc)
c            xp(1,i)=xp(1,i)+(xp(5,i)*(1-cosomdt)+xp(4,i)*sinomdt)/Bz
c            xp(2,i)=xp(2,i)+(xp(4,i)*(cosomdt-1)+xp(5,i)*sinomdt)/Bz
c            temp=xp(4,i)
c            xp(4,i)=temp*cosomdt+xp(5,i)*sinomdt
c            xp(5,i)=xp(5,i)*cosomdt-temp*sinomdt
c         endif

         rcyl=xp(1,i)**2+xp(2,i)**2
         rp=rcyl+xp(3,i)**2

c Do the outer flux accumulation.
         spotrein=spotrein+phihere
         nrein=nrein+1

c     Reject particles that are already outside the mesh.
         if(.not.rp.lt.r(nr)*r(nr))then
c Do the outer flux accumulation because it's like an additional
c particle has been reinjected
            goto 1
         endif


c Direct ic1 usage
      end

c********************************************************************
c Initialize the distributions describing reinjected particles
      subroutine maxinjinit()
c Common data:
      include 'piccom.f'
      real chi
      integer*2 idum
      real gam(nQth)
c      character*1 work(nvel,nth)

c Range of velocities (times (Ti/m_i)^(1/2)) permitted for injection.
      vspread=5.+abs(vd)/sqrt(Ti)
c Random interpolates
      sq2pi=1./sqrt(2.*pi)
      sq2=1./sqrt(2.)
      Qcom(1)=0.
      dqp=0.

      do i=1,nQth
         t=NTHUSED*i/nQth
c Depending on the reinjection, we have a flux depending on chi or not
         chi=diagchi(int(t)+1)*(t-int(t))+diagchi(int(t))*(int(t)+1-t)

c Qth is the cosine angle of the ith angle interpolation position. 
c Qsin is the corresponding sinus
c     We used to used th(i). This is the equivalent definition.
           Qth=1.-2.*(i-1.)/(nQth-1.)
           Qsin=sqrt(1-Qth**2)
c Here the drift velocity is scaled to the ion temperature.
           vdr=vd*Qth/sqrt(Ti)
           dqn=sq2pi*exp(-0.5*vdr**2)+.5*vdr*erfcc(-sq2*vdr)
           if(bcr.eq.2) then
c     Case where we reinject adiabaticly with negative resistance,
c     doesn't work (Except maybe for infinite lambda)
c              dqn=dqn*(
c     $             Qth*(1-erfcc(sqrt(-chi)*Qth/Qsin))
c     $             +exp(-chi)*erfcc(sqrt(-chi)/Qsin)  )
           endif
           if(i.gt.1) then
              Qcom(i)=Qcom(i-1) + dqp +dqn
           endif
   
c     Gamma is the total flux over all velocities at this angle. 
c But it is never used 
         gam(i)=dqn
         dqp=dqn
c At this angle,
         do j=1,nvel
c Contruct the Cumulative distribution of radial velocity
c On the mesh Vcom
            Vcom(j)=vspread*(j-1.)/(nvel-1.)
c The cumulative distribution is Gcom, 
            Gcom(j,i)=(dqn - sq2pi*exp(-0.5*(Vcom(j)-vdr)**2)
     $           - .5*vdr*erfcc(sq2*(Vcom(j)-vdr)) )/dqn
         enddo
         Gcom(1,i)=0.
         Gcom(nvel,i)=1.
      enddo
      do i=2,nQth
         Qcom(i)=Qcom(i)/Qcom(nQth)
      enddo
c Now Gcom(*,i) is the cumulative distribution of radial velocity at cos(Qth)
c normalized to the ion thermal velocity, not sqrt(T_e/m_i).
c And Qcom() is the cumulative distribution in cosine angles Qth
c      work(1,1)=' '
     
 501  format(a,11f8.4)
      idum=4
      call srand(myid+1)
      end

