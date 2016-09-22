program scan_least_squares
  use stuff
  implicit none

  ! File names
  character*(20), parameter :: emptyfile = "dat/empty.dat"
  character*(20), parameter :: wfile = "dat/w.dat"
  character*(20), parameter :: namefile = "dat/names.dat"
  character*(20), parameter :: filelist(32) = (/character(len=20)::&
     "dat/f_l.dat",&
     "dat/f_s.dat",&
     "dat/f_p.dat",&
     "dat/f_p.dat",&
     "dat/o_l.dat",&
     "dat/o_s.dat",&
     "dat/o_p.dat",&
     "dat/o_p.dat",&
     "dat/cl_l.dat",&
     "dat/cl_s.dat",&
     "dat/cl_p.dat",&
     "dat/cl_d.dat",&
     "dat/n_l.dat",&
     "dat/n_s.dat",&
     "dat/n_p.dat",&
     "dat/n_p.dat",&
     "dat/s_l.dat",&
     "dat/s_s.dat",&
     "dat/s_p.dat",&
     "dat/s_d.dat",&
     "dat/c_l.dat",&
     "dat/c_s.dat",&
     "dat/c_p.dat",&
     "dat/c_p.dat",&
     "dat/p_l.dat",&
     "dat/p_s.dat",&
     "dat/p_p.dat",&
     "dat/p_d.dat",&
     "dat/h_l.dat",&
     "dat/h_s.dat",&
     "dat/h_s.dat",&
     "dat/h_s.dat"/)

  ! Terms to use and atom/channel distribution
  integer, parameter :: useterms(8,4) = reshape((/&
     1, 1, 1, 1, 1, 1, 1, 1,&
     1, 1, 1, 1, 1, 1, 1, 1,&
     1, 1, 1, 1, 1, 1, 1, 0,&
     0, 0, 1, 0, 1, 0, 1, 0/),shape(useterms))

  ! Sets 
  type(subset) :: iset(14)

  ! Labels
  character*(2), parameter :: atomlist(8) = (/character(len=2)::&
     "F","O","Cl","N","S","C","P","H"/)
  integer, parameter :: chanlist(4) = (/0,1,2,3/)
  character*5, parameter :: channame(4) = (/"local","s    ","p    ","d    "/)
  real*8, parameter :: explist(20) = (/&
     0.08d0,0.10d0,0.12d0,0.14d0,0.16d0,0.18d0,0.20d0,&
     0.22d0,0.24d0,0.26d0,0.28d0,0.40d0,0.60d0,0.80d0,1.00d0,&
     1.20d0,1.40d0,1.60d0,1.80d0,2.00d0/)
  integer, parameter :: mcols = size(explist) * size(atomlist) * size(chanlist)
  type(dcpterm) :: lab(mcols)

  ! Atom sets
  integer, allocatable :: idx0(:,:)

  ! Weights, names
  character*50, allocatable :: name(:)
  real*8, allocatable :: w(:)

  ! 
  integer :: i, j, k, n1, n2, ncols, iat, ichan, ifile
  integer :: n, nnew, nterms, natom, nchan
  real*8, allocatable :: yref(:), yempty(:), xread(:), y0(:)
  real*8, allocatable :: x0(:,:), xw(:,:), yw(:)
  logical, allocatable :: lexp(:)
  ! for lapack
  integer :: rank, lwork, info

  ! Header
  write (*,'("* Evaluation  ")')

  ! read the empty file
  call readfile(emptyfile,1,yref)
  call readfile(emptyfile,2,yempty)
  n = size(yempty)
  write (*,'("  Number of data points in empty file: ",I4)') n

  ! build the table of DCP terms
  natom = size(useterms,1)
  nchan = size(useterms,2)
  if (natom /= size(atomlist)) call error("inconsistent number of atoms")
  if (nchan /= size(chanlist)) call error("inconsistent number of channels")
  write (*,'("  Number of atoms: ",I2)') natom
  write (*,'("  Number of angular momentum channels: ",I2)') nchan
  write (*,'("  Table of atoms and DCP terms in use (in sequence order):")')
  do i = 1, natom
     write (*,'(2X,A2,2X,99(I2,X))') trim(atomlist(i)), useterms(i,:)
  end do
  
  ! read the rest of the files
  nterms = -1
  allocate(x0(n,mcols))
  x0 = 0d0
  ncols = 0
  ifile = 0
  do iat = 1, natom
     do ichan = 1, nchan
        ifile = ifile + 1
        call readfile(filelist(ifile),2,xread)
        nnew = size(xread) / n
        if (n * nnew /= size(xread)) call error("non-integer number of blocks")
        if (nterms < 0) then
           nterms = nnew
        elseif (nterms /= nnew) then
           call error("inconsistent number of blocks")        
        end if
        if (nterms /= size(explist)) call error("nterms /= size(explist)")
        do j = 1, nnew
           ! write the column to the table
           ncols = ncols + 1
           if (ncols > mcols) call error("too many columns, increase mcols?")
           x0(:,ncols) = xread((j-1)*n+1:j*n)

           ! assign the label
           lab(ncols)%iatom = iat
           lab(ncols)%ichan = ichan
           lab(ncols)%satom = atomlist(iat)
           lab(ncols)%l = chanlist(ichan)
           lab(ncols)%exp = explist(j)
        end do
     end do
  end do
  write (*,'("  Number of DCP terms per atom and channel: ",I2)') nterms
  write (*,'("  Number of columns: ",I4," out of max ",I4)') ncols, mcols
  deallocate(xread)

  ! read the names
  call readfile_string(namefile,name)
  if (size(name) /= n) call error("names inconsistent with ndata")

  ! read the weights
  call readfile(wfile,1,w)
  if (size(w) /= n) call error("weights inconsistent with ndata")

  ! build the indices for the sets
  write (*,'("  Table of sets in output: ")')
  call makesets(iset)
  do i = 1, size(iset)
     write (*,'(I4,X,A)') i, trim(iset(i)%name)
  end do
  write (*,*)

  ! substract the empty from the input table and the target table
  allocate(y0(size(yref)))
  y0 = yref - yempty
  do i = 1, ncols
     x0(:,i) = x0(:,i) - yempty
  end do

  ! apply the weights, prune where the weight is zero
  n1 = count(abs(w) > 1d-10)
  allocate(yw(n1))
  allocate(xw(n1,size(x0,2)))
  j = 0
  do i = 1, n
     if (abs(w(i)) > 1d-10) then
        j = j + 1
        yw(j) = y0(i) * sqrt(w(i))
        xw(j,:) = x0(i,:) * sqrt(w(i))
     endif
  end do
  n = n1 
  write (*,'("Input pruned to ",I5," data points")') n

  ! determine which exponents to use
  allocate(lexp(nterms))
  lexp = .true.
  
  write (*,'("  Using exponents: ")')
  do i = 1, nterms
     if (lexp(i)) then
        write (*,'("   Exponent ",F10.2," is used.")') explist(i)
     else
        write (*,'("xx Exponent ",F10.2," is NOT used.")') explist(i)
     end if
  end do
  write (*,*) 

  ! Punch the no-DCP result to the output
  allocate(idx0(natom,5))
  idx0(1,:) = (/     56, 46,  40,  27,  20/)
  idx0(2,:) = (/    140,117, 114,  95,  90/)
  idx0(3,:) = (/    240,239, 202, 195, 163/)
  idx0(4,:) = (/    292,273, 271, 258, 256/)
  idx0(5,:) = (/    396,393, 380, 376, 375/)
  idx0(6,:) = (/    444,435, 433, 413, 403/)
  idx0(7,:) = (/    557,514, 513, 498, 494/)
  idx0(8,:) = (/    599,594, 587, 573, 571/)

  write (*,'("+ Final DCP")')
  call punch(idx0,.true.,.true.)

  write (*,'("* Done")')

contains

  !> Scan all exponent+channel combinations in the same atom, using
  !> nuse terms per atom. Only use some of the 15 terms available for
  !> the combinations.
  subroutine scanall_nuse(nuse,lexp,minerr,fixnorm)
    integer, intent(in) :: nuse
    logical, intent(in) :: lexp(nterms)
    logical, intent(in) :: minerr
    real*8, intent(in), optional :: fixnorm

    integer :: idx(natom,nuse), icur(natom*nuse)
    real*8 :: xsub(count(abs(w) > 1d-10),natom*nuse)
    real*8 :: coef(count(abs(w) > 1d-10))
    real*8 :: dy(count(abs(w) > 1d-10))
    real*8 :: work(natom*nuse + 3 * count(abs(w) > 1d-10) + 1)
    integer :: jpvt(natom*nuse)
    integer :: nsame, ncyc, nterm0
    real*8 :: minval, wrms, norm2, minwrms, minnorm2, fnorm2
    integer, allocatable :: idxsave(:,:)
    integer, allocatable :: iatidx(:,:), natidx(:)
    real*8, allocatable :: dyw(:)
    integer, allocatable :: co(:,:)

    write (*,'("+ Scan a subset of exponents, using ",I2," terms")') nuse
    if (present(fixnorm)) then
       write (*,'("  Minimum-error/maximum-norm strategy")')
       fnorm2 = fixnorm*fixnorm
    elseif (minerr) then
       write (*,'("  Minimum-error strategy")')
    else
       write (*,'("  Minimum-norm strategy")')
    end if

    nterm0 = count(lexp)

    ! prepare the atom sets
    allocate(iatidx(natom,nchan*nterm0),natidx(natom))
    natidx = 0
    n1 = 0
    do i = 1, natom
       n2 = 0
       do j = 1, nchan
          if (useterms(i,j) == 1) then
             do k = 1, nterms
                n1 = n1 + 1
                if (.not.lexp(k)) cycle
                n2 = n2 + 1
                iatidx(i,n2) = n1
                natidx(i) = natidx(i) + 1
             end do
          else
             n1 = n1 + nterms
          end if
       end do
    end do

    !
    allocate(idx0(natom,nuse),idxsave(natom,nuse))

    ! prepare for lapack
    jpvt = 0
    lwork = natom*nuse + 3 * n + 1

    idx0 = 0
    nsame = 0
    ncyc = 0
    main: do while (.true.)
       ncyc = ncyc + 1
       write (*,'("  Cycle ",I2)') ncyc
       do i = 1, natom
          write (*,'("  Atom ",I2," (",A,")")') i, atomlist(i)
          call comb(natidx(i),nuse,co)
          minval = 1d30
          minwrms = 0d0
          minnorm2 = 0d0

          ! parallelize using openmp
          !$omp parallel do private(idx,n1,icur,xsub,coef,dy,jpvt,rank,work,info,&
          !$omp norm2,wrms) firstprivate(lwork) schedule(static)
          do j = 1, size(co,1)
             ! if (mod(j,size(co,1)/10) == 1) write (*,'(4X,I12,"/",I12)') j, size(co,1)
             idx = idx0
             idx(i,:) = iatidx(i,co(j,:))
             n1 = count(idx /= 0)
             icur(1:n1) = pack(idx,idx/=0)

             xsub(:,1:n1) = xw(:,icur(1:n1))
             dy = yw
             coef = yw
             call dgelsy(n,n1,1,xsub,n,coef,n,jpvt,1d-10,rank,work,lwork,info)
             norm2 = sum(coef(1:n1)**2) * 1d-6
             xsub(:,1:n1) = xw(:,icur(1:n1))
             call dgemv('n',n,n1,-1d0,xsub,n,coef,1,1d0,dy,1)
             wrms = sqrt(sum(dy**2) / sum(w))
             if (present(fixnorm)) then
                !$omp critical (save)
                if (norm2 < fnorm2 .and. wrms < minval) then
                   minwrms = wrms
                   minnorm2 = norm2
                   minval = wrms
                   idxsave = idx
                end if
                !$omp end critical (save)
             elseif (minerr) then
                !$omp critical (save)
                if (wrms < minval) then
                   minwrms = wrms
                   minnorm2 = norm2
                   minval = wrms
                   idxsave = idx
                end if
                !$omp end critical (save)
             else
                !$omp critical (save)
                if (norm2 < minval) then
                   minwrms = wrms
                   minnorm2 = norm2
                   minval = norm2
                   idxsave = idx
                end if
                !$omp end critical (save)
             end if
          end do
          !$omp end parallel do
          if (all(idxsave == idx0)) then
             nsame = nsame + 1
          else
             idx0 = idxsave
             nsame = 1
          endif
          write (*,'("  List of indices at the end of last iteration:")')
          do j = 1, natom
             write (*,'(4x,999(I3,X))') idx0(j,:)
          end do
          write (*,'("  wrms = ",F14.8)') minwrms
          write (*,'("  norm = ",F12.6)') sqrt(minnorm2)
          write (*,'("  nsame = ",I2)') nsame
          if (nsame == natom) exit main
          write (*,*) 
       end do
       write (*,*) 
    end do main
    
  end subroutine scanall_nuse

  subroutine punch(idx,doeval,dodcp)
    integer, intent(in) :: idx(:,:)
    logical, intent(in) :: doeval, dodcp

    integer :: i, j, k, l, n1, rank, lwork, info, ihere, nall
    integer, allocatable :: icur(:)
    real*8, allocatable :: xsub(:,:), xsubw(:,:), dy(:), dyw(:), coef(:), work(:)
    integer, allocatable :: jpvt(:)
    real*8 :: norm, wrms, rms, mae
    
    ! count terms in the least squares
    allocate(icur(size(idx)))
    n1 = count(idx /= 0)
    icur(1:n1) = pack(idx,idx/=0)

    ! work space for lapack
    allocate(jpvt(n1))
    jpvt = 0
    lwork = n1 + 3 * n + 1
    allocate(work(lwork))

    ! allocate and populate the arrays
    nall = size(x0,1)
    allocate(xsubw(size(xw,1),n1),xsub(nall,n1),dy(nall),dyw(size(yw)),coef(size(yw)))

    ! least squares
    if (n1 > 0) then
       xsubw = xw(:,icur(1:n1))
       coef = yw
       call dgelsy(n,n1,1,xsubw,n,coef,n,jpvt,1d-10,rank,work,lwork,info)
       norm = sqrt(sum(coef(1:n1)**2) * 1d-6)
    else
       coef = 0d0
       norm = 0d0
    endif
    
    ! calculate the wrms
    xsubw(:,1:n1) = xw(:,icur(1:n1))
    dyw = yw
    call dgemv('n',n,n1,-1d0,xsubw,n,coef(1:n1),1,1d0,dyw,1)
    if (abs(sum(w)) > 1d-10) then
       wrms = sqrt(sum(dyw**2) / sum(w))
    else
       wrms = 0d0
    endif

    ! calculate the residues for the whole set
    xsub(:,1:n1) = x0(:,icur(1:n1))
    dy = y0
    call dgemv('n',nall,n1,-1d0,xsub,nall,coef(1:n1),1,1d0,dy,1)

    write (*,'("  Statistics of the results: ")')
    write (*,'("    norm = ",F12.6)') norm
    write (*,'("    wrms(all) = ",F14.8)') wrms
    do i = 1, size(iset)
       rms = sqrt(sum(dy(iset(i)%idx)**2) / size(iset(i)%idx))
       mae = sum(abs(dy(iset(i)%idx))) / size(iset(i)%idx)
       write (*,'(4X,A8," rms = ",F14.8," mae = ",F14.8)') &
          iset(i)%name, rms, mae
    end do
    write (*,*)

    if (doeval) then
       write (*,'("  Evaluation: ")')
       write (*,'("  | id | Name | w | yref | yempty | ycalc |")')
       do i = 1, size(dy)
          write (*,'("    | ",I4," | ",A," | ",F5.1," | ",3(F14.8," | "))') &
             i, trim(name(i)), w(i), yref(i), yempty(i), yempty(i)+y0(i)-dy(i)
       end do
       write (*,*)
    end if

    if (dodcp) then
       write (*,'("  DCP in Gaussian form: ")')
       l = 0
       do i = 1, natom
          write (*,'(A,X,"0")') trim(atomlist(i))
          write (*,'(A,X,"3 0")') trim(atomlist(i))
          do j = 1, nchan
             write (*,'(A)') trim(channame(j))
             write (*,'(I2)') count((icur >= l+1) .and. (icur <= l+nterms))
             do k = 1, nterms
                l = l + 1
                if (any(icur == l)) then
                   ihere = maxloc(icur,1,icur == l)
                   write (*,'("2 ",F14.10,X,F14.10)') explist(k), coef(ihere) * 0.001d0
                end if
             end do
          end do
       end do
       write (*,*)
    end if

    deallocate(xsub,xsubw,dy,dyw,coef,work,jpvt,icur)

  end subroutine punch

end program scan_least_squares
