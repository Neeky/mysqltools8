#!/bin/bash
# auto install and config mysqltools8
set -eo pipefail
shopt -s nullglob

PYTHON_VERSION=3.7.3
ANSIBLE_VERSION=2.7.10
WORK_DIR=/tmp/mt8/

dependences_dir=$(dirname $0);
if [ ${dependences_dir} == '.' ]
then
    dependences_dir=$(pwd)
else
    dependences_dir="$(pwd)/${dependences_dir}/"
fi

# checking python
if [ -d /usr/local/python-${PYTHON_VERSION} ]
then
    echo "python-${PYTHON_VERSION} has been installed .";
else
    # install dependence of python
    yum -y install openssh openssh-clients gcc gcc-c++ libffi libyaml-devel libffi-devel zlib zlib-devel openssl openssl-devel libyaml sqlite-devel libxml2 libxslt-devel libxml2-devel bzip2 bzip2-devel
    yum clean all
    if [ $? -eq 0 ]
    then
        echo 'yum looks good .';
    else
        echo '[fail] |  execute  | yum -y install gcc gcc-c++ libffi libyaml-devel libffi-devel zlib zlib-devel openssl openssl-devel libyaml sqlite-devel libxml2 libxslt-devel libxml2-devel ';
        exit 1;
    fi

    # create work dir
    mkdir -p ${WORK_DIR};
    # 
    dependences_dir=$(dirname $0);
    if [ ${dependences_dir} == '.' ]
    then
        dependences_dir=$(pwd)
    else
        dependences_dir="$(pwd)/${dependences_dir}/"
    fi
    # 
    cp ${dependences_dir}/python/Python-${PYTHON_VERSION}.tar.xz ${WORK_DIR}
    # 
    cd ${WORK_DIR}
    tar -xvf Python-${PYTHON_VERSION}.tar.xz
    cd Python-${PYTHON_VERSION}
    ./configure --prefix=/usr/local/python-${PYTHON_VERSION} 
    make -j "$(nproc)"
    make install
    ldconfig
    cd /usr/local/
    ln -s python-${PYTHON_VERSION} python
    rm -rf ${WORK_DIR}

fi

# config path env variable
set +e
set +o pipefail
cat /etc/profile | grep 'export PATH=/usr/local/python/bin/:$PATH' >/dev/null
if [ $? -eq 0 ]
then
    echo "PATH has been configured ."
else
    echo 'export PATH=/usr/local/python/bin/:$PATH' >> /etc/profile
fi
source /etc/profile

set -eo pipefail
# install ansible
if [ -f /usr/local/python/bin/ansible ]
then
    echo "ansible-${ANSIBLE_VERSION} has been installed."
else
    echo "${dependences_dir}"
    cd "${dependences_dir}"
    pip3 install ansible/setuptools-41.0.1-py2.py3-none-any.whl
    pip3 install ansible/six-1.12.0-py2.py3-none-any.whl
    pip3 install ansible/MarkupSafe-1.1.1-cp37-cp37m-manylinux1_x86_64.whl
    pip3 install ansible/Jinja2-2.10.1-py2.py3-none-any.whl
    pip3 install ansible/pycparser-2.19.tar.gz
    pip3 install ansible/cffi-1.12.3-cp37-cp37m-manylinux1_x86_64.whl
    pip3 install ansible/bcrypt-3.1.6-cp34-abi3-manylinux1_x86_64.whl
    pip3 install ansible/asn1crypto-0.24.0-py2.py3-none-any.whl
    pip3 install ansible/cryptography-2.6.1-cp34-abi3-manylinux1_x86_64.whl
    pip3 install ansible/PyNaCl-1.3.0-cp34-abi3-manylinux1_x86_64.whl
    pip3 install ansible/PyYAML-5.1.tar.gz
    pip3 install ansible/pyasn1-0.4.5-py2.py3-none-any.whl
    pip3 install ansible/paramiko-2.4.2-py2.py3-none-any.whl
    pip3 install ansible/ansible-${ANSIBLE_VERSION}.tar.gz
fi
