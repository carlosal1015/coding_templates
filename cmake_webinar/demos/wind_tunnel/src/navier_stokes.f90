subroutine navier_stokes_cpu()
!updates the vorticity according to the vorticity transport equation:
!
! dw/dt + u dw/dx + v dw/dy = nabla^2 w
!
! The maximum velocity (that the vorticity is advected by) is capped to 1
!
!Also the maximum vorticity is capped at maxvort

    use vars
    use parallel

    implicit none

    integer :: i, j
    real(8) :: uu, vv, v2
    real(8) :: r

    real(8) :: deltax, deltay
    real(8) :: dwdx, dwdy

    !$OMP DO PRIVATE(uu,vv,v2,r,i, deltax, deltay, dwdx, dwdy)
    do j=1,ny
        do i=1,nx
            if (mask(i,j) .eq. 0) then
                !advection

                uu=u(i,j)
                vv=v(i,j)
                v2=uu*uu+vv*vv

                if (v2 .gt. vmax) then
                    v2 = sqrt(vmax/v2)
                    uu=uu*v2
                    vv=vv*v2
                endif

                !Time depenent vorticity evolution: (dw/dt = -u*dw/dx -v*dw/dy + 1/Re * (laplacian(w))

                ! weight the derivative according to the velocity (stronger weight is given to the
                ! derivitive that is being advected into the gridcell)
                deltax = uu*dt/dx
                dwdx = (1-deltax)*(vort(i+1,j)-vort(i,j)) + (1+deltax)*(vort(i,j)-vort(i-1,j))

                deltay = vv*dt/dy
                dwdy = (1-deltay)*(vort(i,j+1)-vort(i,j)) + (1+deltay)*(vort(i,j)-vort(i,j-1))

                dw(i,j) = 0.5*(-uu*dwdx - vv*dwdy)


                r=r0

                dw(i,j)= dw(i,j) + 1./r *( (vort(i+1,j) - 2.*vort(i,j) + vort(i-1,j) )/dx/dx &
                    + (vort(i,j+1) - 2.*vort(i,j) + vort(i,j-1))/dy/dy )
                

            endif
        enddo
    enddo

    !$OMP END DO

    !$OMP DO PRIVATE(j)
     do j=1,ny
          vort(:,j)=vort(:,j) + dw(:,j)*dt
      enddo
    !$OMP END DO

    !limit maximum vorticity
    !$OMP DO PRIVATE(i,j)
    do j=1,ny
         do i=1,nx
             if (vort(i,j) .gt. maxvort) vort(i,j) = maxvort
             if (vort(i,j) .lt. -maxvort) vort(i,j) = -maxvort
         enddo
     enddo
    !$OMP END DO


    !$OMP SINGLE
    call haloswap(vort)
    !$OMP END SINGLE


end subroutine

subroutine navier_stokes()
    use vars

#ifdef USE_CUDA
    if ( device .eqv. .true. ) then 
        call navier_stokes_gpu()
    else 
        call navier_stokes_cpu()
    endif
#else
    call navier_stokes_cpu()
#endif
end subroutine
