#!/usr/bin/env bash
set -e
set -x
cd "$(dirname $0)"
W="${PWD}"
BUILDIR="${BUILDIR:-"${TMPDIR:-"${W}"}/tmppython"}"
PYTHON_VERSION="${PYTHON_VERSION:-"2.4.6"}"
PREFIX="${PREFIX:-${1:-"${W}/python-${PYTHON_VERSION}"}}"
export CFLAGS="-g -I/usr/include -I/usr/include/ncurses -I/usr/include/openssl"
# no-as-needed let shared modules include correctly the shared libs links !
export LDFLAGS="-Wl,-no-as-needed -L/lib/x86_64-linux-gnu -Wl,-rpath,/usr/lib/x86_64-linux-gnu -L/usr/lib/x86_64-linux-gnu -Wl,-rpath,/usr/lib/x86_64-linux-gnu -lexpat -lcrypto -lssl -lcrypt -lz -lbz2"
export OPT="${CFLAGS}"
export LD_RUN_PATH="/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu"
VENV_VER=""
PIP_VER=""
EZ_URL="https://bitbucket.org/pypa/setuptools/raw/ez_setup.py"
if echo ${PYTHON_VERSION}|grep -q "2.4";then
    VENV_VER="==1.7.2"
    PIP_VER="==1.1"
    EZ_URL="https://bitbucket.org/pypa/setuptools/raw/bootstrap-py24/ez_setup.py"
fi
C_OPTS="--prefix="${PREFIX}" --enable-shared --enable-unicode=ucs4"
if echo ${PYTHON_VERSION}|grep -q "2.4";then
    C_OPTS="--prefix="${PREFIX}" --with-fpectl --with-bz2 --with-ncurses --with-readline --with-zlib --enable-shared --enable-unicode=ucs4"
fi
if [ ! -e "${PREFIX}" ];then
    mkdir -p "${PREFIX}"
fi
if [ ! -e "${BUILDIR}" ];then
    mkdir -p "${BUILDIR}"
fi
cd "${BUILDIR}"
if [ ! -e Python-${PYTHON_VERSION}/setup.py ];then
    wget -c "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
fi
if [ ! -e "${PREFIX}/bin/python" ];then
    if [ -e "Python-${PYTHON_VERSION}" ];then
        rm -fr "Python-${PYTHON_VERSION}"
    fi
    tar xzf "Python-${PYTHON_VERSION}.tgz"
    cd "Python-${PYTHON_VERSION}"
    if echo ${PYTHON_VERSION}|grep -q "2.4";then
# backport tarfile from py25
# patch -Np1 < tarfile.diff
# backport zlib from py25
# patch -Np1 < zlib.diff
# patch to include our cflags and link options
patch -Np1 < build.diff
    fi
    ./configure ${C_OPTS}
    make
    make install
fi
if [ ! -e "${PREFIX}/bin/easy_install" ];then
    wget -c "${EZ_URL}" -O "ez_setup.py"
    "${PREFIX}/bin/python" "ez_setup.py"
fi
if [ ! -e "${PREFIX}/bin/virtualenv" ];then
    "${PREFIX}/bin/easy_install" -U "virtualenv${VENV_VER}"
fi
if [ ! -e "${PREFIX}/bin/pip" ];then
    "${PREFIX}/bin/easy_install" -U "pip${PIP_VER}"
fi
rm -rf "${BUILDIR}"
# vim:set et sts=4 ts=4 tw=80:
