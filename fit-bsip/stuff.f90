module stuff
  implicit none

  public

  interface realloc
     module procedure realloc1r
     module procedure realloc2r
     module procedure realloc1s
  end interface realloc

  type dcpterm
     integer :: iatom, ichan
     character*2 :: satom
     integer :: l
     real*8 :: exp
  end type dcpterm
  type subset
     character(len=10) :: name
     integer, allocatable :: idx(:)
  end type subset

contains

  subroutine makesets(iset)
    type(subset), intent(out) :: iset(14)
    
    integer :: i

    iset(1)%name = "s22"
    allocate(iset(1)%idx(22))
    do i = 1, 22
       iset(1)%idx(i) = 2 + (i-1) * 5
    end do
    
    iset(2)%name = "s66"
    allocate(iset(2)%idx(66))
    do i = 1, 66
       iset(2)%idx(i) = 113 + (i-1) * 8
    end do

    iset(3)%name = "s22x5"
    allocate(iset(3)%idx(110))
    do i = 1, 110
       iset(3)%idx(i) = i
    end do

    iset(4)%name = "s66x8"
    allocate(iset(4)%idx(528))
    do i = 1, 528
       iset(4)%idx(i) = 110 + i
    end do

    iset(5)%name = "f-set"
    allocate(iset(5)%idx(160))
    do i = 1, 160
       iset(5)%idx(i) = 638+i
    end do

    iset(6)%name = "p-set"
    allocate(iset(6)%idx(120))
    do i = 1, 120
       iset(6)%idx(i) = 798+i
    end do

    iset(7)%name = "s-set"
    allocate(iset(7)%idx(144))
    do i = 1, 144
       iset(7)%idx(i) = 918+i
    end do

    iset(8)%name = "cl-set"
    allocate(iset(8)%idx(160))
    do i = 1, 160
       iset(8)%idx(i) = 1062+i
    end do

    iset(9)%name = "bdex"
    allocate(iset(9)%idx(397))
    do i = 1, 397
       iset(9)%idx(i) = 1222 + i
    end do

    iset(10)%name = "bdexrel"
    allocate(iset(10)%idx(340))
    do i = 1, 340
       iset(10)%idx(i) = 1621 + i
    end do

    iset(11)%name = "dipole"
    allocate(iset(11)%idx(128))
    do i = 1, 128
       iset(11)%idx(i) = 1959 + i
    end do

    iset(12)%name = "nci"
    allocate(iset(12)%idx(1222))
    do i = 1, 1222
       iset(12)%idx(i) = i
    end do

    iset(13)%name = "ene"
    allocate(iset(13)%idx(1310))
    do i = 1, 1310
       iset(13)%idx(i) = 2087 + i
    end do

    iset(14)%name = "all"
    allocate(iset(14)%idx(3397))
    do i = 1, 3397
       iset(14)%idx(i) = i
    end do

  end subroutine makesets

  subroutine readfile(file,col,x)
    character(len=*), intent(in) :: file
    integer, intent(in) :: col
    real*8, allocatable, intent(inout) :: x(:)

    integer, parameter :: lu = 10
    integer, parameter :: dsiz = 1378

    integer :: ios, n
    real*8 :: xread(col)

    ! open the file
    open(unit=lu,file=file,status='old',iostat=ios)
    if (ios /= 0) call error("file not found: " // trim(file))

    ! allocate the output vector
    if (allocated(x)) deallocate(x)
    allocate(x(dsiz))

    ! loop over the lines in the file
    n = 0
    do while(.true.)
       read (lu,*,iostat=ios) xread
       if (is_iostat_eor(ios) .or. is_iostat_end(ios)) exit
       n = n + 1
       if (n > size(x)) call realloc(x,2*size(x,1))
       x(n) = xread(col)
    end do

    ! clean up
    if (n < size(x)) call realloc(x,n)
    close(lu)

  end subroutine readfile

  subroutine readfile_string(file,name)
    character(len=*), intent(in) :: file
    character*50, allocatable, intent(inout) :: name(:)

    integer, parameter :: lu = 10
    integer, parameter :: dsiz = 1378

    integer :: ios, n
    character*50 :: aux

    ! open the file
    open(unit=lu,file=file,status='old',iostat=ios)
    if (ios /= 0) call error("file not found: " // trim(file))

    ! allocate the output vector
    if (allocated(name)) deallocate(name)
    allocate(name(dsiz))

    ! loop over the lines in the file
    n = 0
    do while(.true.)
       read (lu,'(A)',iostat=ios) aux
       if (is_iostat_eor(ios) .or. is_iostat_end(ios)) exit
       n = n + 1
       if (n > size(name)) call realloc(name,2*size(name,1))
       name(n) = adjustl(aux)
    end do

    ! clean up
    if (n < size(name)) call realloc(name,n)
    close(lu)

  end subroutine readfile_string

  subroutine error(msg)
    character(len=*), intent(in) :: msg
    write (*,'(A)') msg
    stop 1
  end subroutine error

  !> Adapt the size of an allocatable 1D real*8 array
  subroutine realloc1r(a,nnew)

    real*8, intent(inout), allocatable :: a(:) !< Input array, real*8, 1D
    integer, intent(in) :: nnew !< new dimension
    
    real*8, allocatable :: temp(:)
    integer :: nold
    
    if (.not.allocated(a)) &
       call error('realloc1r: array not allocated')
    nold = size(a)
    allocate(temp(nnew))
    
    temp(1:min(nnew,nold)) = a(1:min(nnew,nold))
    call move_alloc(temp,a)

  end subroutine realloc1r

  !> Adapt the size of an allocatable 2D real*8 array
  subroutine realloc2r(a,n1,n2)

    real*8, intent(inout), allocatable :: a(:,:) !< Input array, real*8, 2D
    integer, intent(in) :: n1, n2 !< new dimension
    
    real*8, allocatable :: temp(:,:)
    integer :: nold(2)
    
    if (.not.allocated(a)) &
       call error('realloc2r: array not allocated')
    nold(1) = size(a,1)
    nold(2) = size(a,2)
    allocate(temp(n1,n2))
    
    temp = 0d0
    temp(1:min(n1,nold(1)),1:min(n2,nold(2))) = a(1:min(n1,nold(1)),1:min(n2,nold(2)))
    call move_alloc(temp,a)

  end subroutine realloc2r

  !> Adapt the size of an allocatable 1D character*50 array
  subroutine realloc1s(a,nnew)

    character*50, intent(inout), allocatable :: a(:) !< Input array, character*50, 1D
    integer, intent(in) :: nnew !< new dimension
    
    character*50, allocatable :: temp(:)
    integer :: nold
    
    if (.not.allocated(a)) &
       call error('realloc1s: array not allocated')
    nold = size(a)
    allocate(temp(nnew))
    
    temp(1:min(nnew,nold)) = a(1:min(nnew,nold))
    call move_alloc(temp,a)

  end subroutine realloc1s

  !> Calculate n choose k
  function choose(n, k)
    integer :: choose
    integer, intent(in) :: n, k
 
    integer :: imax, i, imin, ie
    integer*8 :: itmp
 
    ie = 0
    if ( n < k ) then
       choose = 0
    else if ( n == k ) then
       choose = 1
    else
       imax = max(k, n-k)
       imin = min(k, n-k)
       itmp = 1
       do i = imax+1, n
          itmp = itmp * i
       end do
       do i = 2, imin
          itmp = itmp / i
       end do
       choose = itmp
    end if
  end function choose
 
  subroutine comb(n, k, co)
    integer, intent(in) :: n, k
    integer, dimension(:,:), allocatable, intent(inout) :: co
 
    integer :: i, s, ix, kx, hm, t
 
    hm = choose(n, k)
    if (allocated(co)) deallocate(co)
    allocate(co(hm,k))
    do i = 0, hm-1
       ix = i; kx = k
       do s = 0, n-1
          if ( kx == 0 ) exit
          t = choose(n-(s+1), kx-1)
          if ( ix < t ) then
             co(i+1,kx) = s+1
             kx = kx - 1
          else
             ix = ix - t
          end if
       end do
    end do
 
  end subroutine comb
 
end module stuff
