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
cat > build.diff << EOF
ZGlmZiAtdXIgUHl0aG9uLTIuNC42Lm9yaWcvTW9kdWxlcy9yZWFkbGluZS5jIFB5dGhvbi0yLjQu
Ni9Nb2R1bGVzL3JlYWRsaW5lLmMKLS0tIFB5dGhvbi0yLjQuNi5vcmlnL01vZHVsZXMvcmVhZGxp
bmUuYwkyMDA2LTEwLTAzIDIwOjI5OjM1LjAwMDAwMDAwMCArMDIwMAorKysgUHl0aG9uLTIuNC42
L01vZHVsZXMvcmVhZGxpbmUuYwkyMDE0LTEyLTA5IDEwOjI5OjQwLjk4NDYxMzQ0NyArMDEwMApA
QCAtNzA4LDEyICs3MDgsMjcgQEAKIAlybF9iaW5kX2tleV9pbl9tYXAgKCdcdCcsIHJsX2NvbXBs
ZXRlLCBlbWFjc19tZXRhX2tleW1hcCk7CiAJcmxfYmluZF9rZXlfaW5fbWFwICgnXDAzMycsIHJs
X2NvbXBsZXRlLCBlbWFjc19tZXRhX2tleW1hcCk7CiAJLyogU2V0IG91ciBob29rIGZ1bmN0aW9u
cyAqLwotCXJsX3N0YXJ0dXBfaG9vayA9IChGdW5jdGlvbiAqKW9uX3N0YXJ0dXBfaG9vazsKKyAg
ICBybF9zdGFydHVwX2hvb2sgPQorI2lmIGRlZmluZWQoX1JMX0ZVTkNUSU9OX1RZUEVERUYpCisg
ICAgICAgIChybF9ob29rX2Z1bmNfdCAqKW9uX3N0YXJ0dXBfaG9vazsKKyNlbHNlCisgICAgICAg
IChGdW5jdGlvbiAqKW9uX3N0YXJ0dXBfaG9vazsKKyNlbmRpZgogI2lmZGVmIEhBVkVfUkxfUFJF
X0lOUFVUX0hPT0sKLQlybF9wcmVfaW5wdXRfaG9vayA9IChGdW5jdGlvbiAqKW9uX3ByZV9pbnB1
dF9ob29rOworICAgIHJsX3ByZV9pbnB1dF9ob29rID0KKyNpZiBkZWZpbmVkKF9STF9GVU5DVElP
Tl9UWVBFREVGKQorICAgICAgICAocmxfaG9va19mdW5jX3QgKilvbl9wcmVfaW5wdXRfaG9vazsK
KyNlbHNlCisgICAgICAgIChGdW5jdGlvbiAqKW9uX3ByZV9pbnB1dF9ob29rOworI2VuZGlmCiAj
ZW5kaWYKIAkvKiBTZXQgb3VyIGNvbXBsZXRpb24gZnVuY3Rpb24gKi8KLQlybF9hdHRlbXB0ZWRf
Y29tcGxldGlvbl9mdW5jdGlvbiA9IChDUFBGdW5jdGlvbiAqKWZsZXhfY29tcGxldGU7CisgICAg
cmxfYXR0ZW1wdGVkX2NvbXBsZXRpb25fZnVuY3Rpb24gPQorI2lmIGRlZmluZWQoX1JMX0ZVTkNU
SU9OX1RZUEVERUYpCisgICAgICAgIChybF9jb21wbGV0aW9uX2Z1bmNfdCAqKWZsZXhfY29tcGxl
dGU7CisjZWxzZQorICAgICAgICAoQ1BQRnVuY3Rpb24gKilmbGV4X2NvbXBsZXRlOworI2VuZGlm
CiAJLyogU2V0IFB5dGhvbiB3b3JkIGJyZWFrIGNoYXJhY3RlcnMgKi8KIAlybF9jb21wbGV0ZXJf
d29yZF9icmVha19jaGFyYWN0ZXJzID0KIAkJc3RyZHVwKCIgXHRcbmB+IUAjJCVeJiooKS09K1t7
XX1cXHw7OidcIiw8Pi8/Iik7CmRpZmYgLXVyIFB5dGhvbi0yLjQuNi5vcmlnL3NldHVwLnB5IFB5
dGhvbi0yLjQuNi9zZXR1cC5weQotLS0gUHl0aG9uLTIuNC42Lm9yaWcvc2V0dXAucHkJMjAwNi0x
MC0wOCAxOTo0MToyNS4wMDAwMDAwMDAgKzAyMDAKKysrIFB5dGhvbi0yLjQuNi9zZXR1cC5weQky
MDE0LTEyLTA5IDEwOjM0OjQzLjYxMjI4NzUwMCArMDEwMApAQCAtMjY4LDkgKzI2OCwxMyBAQAog
ICAgICAgICAjIGJlIGFzc3VtZWQgdGhhdCBubyBhZGRpdGlvbmFsIC1JLC1MIGRpcmVjdGl2ZXMg
YXJlIG5lZWRlZC4KICAgICAgICAgbGliX2RpcnMgPSBzZWxmLmNvbXBpbGVyLmxpYnJhcnlfZGly
cyArIFsKICAgICAgICAgICAgICcvbGliNjQnLCAnL3Vzci9saWI2NCcsCisgICAgICAgICAgICAn
L3Vzci9saWIveDg2XzY0LWxpbnV4LWdudScsCisgICAgICAgICAgICAnL2xpYi94ODZfNjQtbGlu
dXgtZ251JywKICAgICAgICAgICAgICcvbGliJywgJy91c3IvbGliJywKICAgICAgICAgICAgIF0K
LSAgICAgICAgaW5jX2RpcnMgPSBzZWxmLmNvbXBpbGVyLmluY2x1ZGVfZGlycyArIFsnL3Vzci9p
bmNsdWRlJ10KKyAgICAgICAgaW5jX2RpcnMgPSBzZWxmLmNvbXBpbGVyLmluY2x1ZGVfZGlycyAr
IFsnL3Vzci9pbmNsdWRlJywgJy91c3IvaW5jbHVkZS9zc2wnLAorICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICcvdXNyL2luY2x1ZGUvbmN1cnNlcycsICcv
dXNyL2luY2x1ZGUvb3BlbnNzbCcsCisgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgJy91c3IvaW5jbHVkZS9yZWFkbGluZSddCiAgICAgICAgIGV4dHMgPSBb
XQoKICAgICAgICAgcGxhdGZvcm0gPSBzZWxmLmdldF9wbGF0Zm9ybSgpCkBAIC00ODQsNyArNDg4
LDcgQEAKICAgICAgICAgZXh0cy5hcHBlbmQoIEV4dGVuc2lvbignX3NvY2tldCcsIFsnc29ja2V0
bW9kdWxlLmMnXSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZXBlbmRzID0gWydz
b2NrZXRtb2R1bGUuaCddKSApCiAgICAgICAgICMgRGV0ZWN0IFNTTCBzdXBwb3J0IGZvciB0aGUg
c29ja2V0IG1vZHVsZSAodmlhIF9zc2wpCi0gICAgICAgIHNzbF9pbmNzID0gZmluZF9maWxlKCdv
cGVuc3NsL3NzbC5oJywgaW5jX2RpcnMsCisgICAgICAgIHNzbF9pbmNzID0gZmluZF9maWxlKCdv
cGVuc3NsL3NzbC5oJywgaW5jX2RpcnMsIGluY19kaXJzKwogICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICBbJy91c3IvbG9jYWwvc3NsL2luY2x1ZGUnLAogICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgJy91c3IvY29udHJpYi9zc2wvaW5jbHVkZS8nCiAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgIF0KCg==
EOF
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
