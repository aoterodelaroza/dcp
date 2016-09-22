### ifort with mkl
FC = ifort
# FCFLAGS = -g -CU -C -traceback -fpe0 -debug -openmp
FCFLAGS = -O3 -openmp
LDFLAGS = -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core -liomp5 -lpthread -openmp

# ### gfortran with static blas and lapack
# FC = gfortran-6
# # FCFLAGS = -O3 -fopenmp
# FCFLAGS = -g -fbounds-check -Wall -Wunused-parameter -ffpe-trap=invalid -fbacktrace -fdump-core -fopenmp
# LIBS=liblapack.a libblas.a 
# LDFLAGS = -fopenmp 

BINS=scan_ls post_eval
OBJS=stuff.o
INCLUDE=

%.o: %.f90
	$(FC) -c $(FCFLAGS) $(INCLUDE) -o $@ $<

%.o: %.f
	$(FC) -c $(FCFLAGS) $(INCLUDE) -o $@ $<

%.mod: %.o
	@if [ ! -f $@ ]; then rm $< ; $(MAKE) $< ; fi

# General targets

all: $(BINS)

clean:
	rm -f core *.mod *.o 

scan_ls: $(OBJS) scan_ls.o
	$(FC) -o scan_ls $(LDFLAGS) $(OBJS) scan_ls.o $(LIBS)

post_eval: $(OBJS) post_eval.o
	$(FC) -o post_eval $(LDFLAGS) $(OBJS) post_eval.o $(LIBS)

# Object dependencies
scan_ls.o : stuff.mod
post_eval.o : stuff.mod

# dummy
dummy: 
	@true
