FROM ubuntu:latest

MAINTAINER Paulo Coutinho

# install dependencies
RUN apt-get update && apt-get install -y \
     build-essential \
     git \
	 python \
     wget \
	 nano \
	 curl \
	 unzip \
	 m4
	 
RUN apt-get clean

# versions
ENV GMP_VERSION=gmp-6.1.1
ENV MPFR_VERSION=mpfr-3.1.5
ENV MPC_VERSION=mpc-1.0.3
ENV ISL_VERSION=isl-0.16.1
ENV CLOOG_VERSION=cloog-0.18.1
ENV GCC_VERSION=gcc-6.2.0

# base paths
ENV BASE_DIR=/gcc-from-scratch
ENV GCC_PREFIX=/gcc-from-scratch/gcc
RUN mkdir -p ${BASE_DIR}
RUN mkdir -p ${GCC_PREFIX}

# download things here to prevent download everytime that Dockerfile is changed
RUN wget "ftp://ftp.gmplib.org/pub/$GMP_VERSION/${GMP_VERSION}.tar.bz2" -O ${BASE_DIR}/${GMP_VERSION}.tar.bz2
RUN wget "http://www.mpfr.org/mpfr-current/${MPFR_VERSION}.tar.gz" -O ${BASE_DIR}/${MPFR_VERSION}.tar.gz
RUN wget "ftp://ftp.gnu.org/gnu/mpc/${MPC_VERSION}.tar.gz" -O ${BASE_DIR}/${MPC_VERSION}.tar.gz
RUN wget "ftp://gcc.gnu.org/pub/gcc/infrastructure/${ISL_VERSION}.tar.bz2" -O ${BASE_DIR}/${ISL_VERSION}.tar.bz2
RUN wget "ftp://gcc.gnu.org/pub/gcc/infrastructure/${CLOOG_VERSION}.tar.gz" -O ${BASE_DIR}/${CLOOG_VERSION}.tar.gz
RUN wget "ftp://ftp.uvsq.fr/pub/gcc/releases/${GCC_VERSION}/${GCC_VERSION}.tar.bz2" -O ${BASE_DIR}/${GCC_VERSION}.tar.bz2

# [TODO] send it to top
RUN apt-get install -y m4

# build GMP
WORKDIR ${BASE_DIR}
RUN tar xfjv "${GMP_VERSION}.tar.bz2"
RUN mkdir "${GMP_VERSION}/build"
WORKDIR "${GMP_VERSION}/build"
RUN ../configure --prefix="${GCC_PREFIX}/gmp" --disable-shared --enable-static
RUN make -j"$(nproc)"
RUN make install

# build MPFR
WORKDIR ${BASE_DIR}
RUN tar xfvz "${MPFR_VERSION}.tar.gz"
RUN mkdir "${MPFR_VERSION}/build"
WORKDIR "${MPFR_VERSION}/build"
RUN ../configure --prefix="${GCC_PREFIX}/mpfr" --with-gmp="${GCC_PREFIX}/gmp" --disable-shared --enable-static
RUN make -j"$(nproc)"
RUN make install

# build MPC
WORKDIR ${BASE_DIR}
RUN tar xfvz "${MPC_VERSION}.tar.gz"
RUN mkdir "${MPC_VERSION}/build"
WORKDIR "${MPC_VERSION}/build"
RUN ../configure --prefix="${GCC_PREFIX}/mpc" --with-gmp="${GCC_PREFIX}/gmp" --with-mpfr="${GCC_PREFIX}/mpfr" --disable-shared --enable-static
RUN make -j"$(nproc)"
RUN make install

# build ISL
WORKDIR ${BASE_DIR}
RUN tar xfvj "${ISL_VERSION}.tar.bz2"
RUN mkdir "${ISL_VERSION}/build"
WORKDIR "${ISL_VERSION}/build"
RUN ../configure --prefix="${GCC_PREFIX}/isl" --with-gmp-prefix="${GCC_PREFIX}/gmp" --disable-shared --enable-static
RUN make -j"$(nproc)"
RUN make install

# build CLOOG
WORKDIR ${BASE_DIR}
RUN tar xfvz "${CLOOG_VERSION}.tar.gz"
RUN mkdir "${CLOOG_VERSION}/build"
WORKDIR "${CLOOG_VERSION}/build"
RUN ../configure --prefix="${GCC_PREFIX}/cloog" --with-gmp-prefix="${GCC_PREFIX}/gmp" --with-isl="${GCC_PREFIX}/isl" --disable-shared --enable-static
RUN make -j"$(nproc)"
RUN make install

# paths
ENV LD_LIBRARY_PATH=${GCC_PREFIX}/gmp/lib:${GCC_PREFIX}/mpfr/lib:${GCC_PREFIX}/mpc/lib:${GCC_PREFIX}/isl/lib:${GCC_PREFIX}/cloog/lib
ENV C_INCLUDE_PATH=${GCC_PREFIX}/gmp/include:${GCC_PREFIX}/mpfr/include:${GCC_PREFIX}/mpc/include:${GCC_PREFIX}/isl/include:${GCC_PREFIX}/cloog/include
ENV CPLUS_INCLUDE_PATH=${GCC_PREFIX}/gmp/include:${GCC_PREFIX}/mpfr/include:${GCC_PREFIX}/mpc/include:${GCC_PREFIX}/isl/include:${GCC_PREFIX}/cloog/include

# build GCC
WORKDIR ${BASE_DIR}
RUN tar xfvj "${GCC_VERSION}.tar.bz2"
RUN mkdir "${GCC_VERSION}/build"
WORKDIR "${GCC_VERSION}/build"
RUN ../configure
	--prefix="${GCC_PREFIX}"
	--with-gmp="${GCC_PREFIX}"
	--with-mpfr="${GCC_PREFIX}"
	--with-mpc="${GCC_PREFIX}"
	--with-isl="${GCC_PREFIX}"
	--with-cloog="${GCC_PREFIX}"
	--enable-checking=release
	--enable-languages=c,c++

RUN make -j"$(nproc)"
RUN make install

CMD [bash]