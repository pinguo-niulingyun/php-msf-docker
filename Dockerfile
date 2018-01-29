FROM centos:centos6.9
MAINTAINER niulingyun <leandre@qq.com>

# -----------------------------------------------------------------------------
# Make src dir
# -----------------------------------------------------------------------------
ENV HOME /home/worker
ENV SRC_DIR $HOME/src
RUN mkdir -p ${SRC_DIR}
#ADD src ${SRC_DIR}

# -----------------------------------------------------------------------------
# Install Development tools
# -----------------------------------------------------------------------------
RUN rpm --import /etc/pki/rpm-gpg/RPM* \
    && curl --silent --location https://raw.githubusercontent.com/nodesource/distributions/master/rpm/setup_6.x | bash - \
    && yum -y update \
    && yum groupinstall -y "Development tools" \
    && yum install -y gcc-c++ zlib-devel bzip2-devel openssl boost-devel \
    openssl-devel ncurses-devel sqlite-devel wget \
    tar gzip bzip2 unzip file perl-devel perl-ExtUtils-Embed \
    pcre openssh-server openssh sudo gperf \
    screen vim git telnet expat libuuid-devel \
    lemon net-snmp net-snmp-devel \
    ca-certificates perl-CPAN m4 gmp-devel\
    gd libjpeg libpng zlib libevent net-snmp net-snmp-devel \
    net-snmp-libs freetype libtool-tldl libxml2 unixODBC \
    libxslt libmcrypt freetds \
    gd-devel libjpeg-devel libpng-devel \
    freetype-devel libtool-ltdl libtool-ltdl-devel \
    libxml2-devel gettext-devel \
    curl-devel gettext-devel libevent-devel \
    libxslt-devel expat-devel unixODBC-devel \
    libmcrypt-devel freetds-devel \
    pcre-devel openldap openldap-devel libc-client-devel \
    jemalloc jemalloc-devel inotify-tools nodejs apr-util yum-utils tree \
    && ln -s /usr/lib64/libc-client.so /usr/lib/libc-client.so \
    && rm -rf /var/cache/{yum,ldconfig}/* \
    && rm -rf /etc/ld.so.cache \
    && yum clean all

# -----------------------------------------------------------------------------
# Update Python to 2.7.x
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O Python-2.7.13.tgz http://mirrors.sohu.com/python/2.7.13/Python-2.7.13.tgz \
    && tar zxf Python-2.7.13.tgz \
    && cd Python-2.7.13 \
    && ./configure \
    && make \
    && make install \
    && mv /usr/bin/python /usr/bin/python.old \
    && rm -f /usr/bin/python-config \
    && ln -s /usr/local/bin/python /usr/bin/python \
    && ln -s /usr/local/bin/python-config /usr/bin/python-config \
    && ln -s /usr/local/include/python2.7/ /usr/include/python2.7 \
    && wget https://bootstrap.pypa.io/ez_setup.py -O - | python \
    && easy_install pip \
    && sed -in-place '1s%.*%#!/usr/bin/python2.6%' /usr/bin/yum \
    && cp -r /usr/lib/python2.6/site-packages/yum /usr/local/lib/python2.7/site-packages/ \
    && cp -r /usr/lib/python2.6/site-packages/rpmUtils /usr/local/lib/python2.7/site-packages/ \
    && cp -r /usr/lib/python2.6/site-packages/iniparse /usr/local/lib/python2.7/site-packages/ \
    && cp -r /usr/lib/python2.6/site-packages/urlgrabber /usr/local/lib/python2.7/site-packages/ \
    && cp -r /usr/lib64/python2.6/site-packages/rpm /usr/local/lib/python2.7/site-packages/ \
    && cp -r /usr/lib64/python2.6/site-packages/curl /usr/local/lib/python2.7/site-packages/ \
    && cp -p /usr/lib64/python2.6/site-packages/pycurl.so /usr/local/lib/python2.7/site-packages/ \
    && cp -p /usr/lib64/python2.6/site-packages/_sqlitecache.so /usr/local/lib/python2.7/site-packages/ \
    && cp -p /usr/lib64/python2.6/site-packages/sqlitecachec.py /usr/local/lib/python2.7/site-packages/ \
    && cp -p /usr/lib64/python2.6/site-packages/sqlitecachec.pyc /usr/local/lib/python2.7/site-packages/ \
    && cp -p /usr/lib64/python2.6/site-packages/sqlitecachec.pyo /usr/local/lib/python2.7/site-packages/ \
    && rm -rf ${SRC_DIR}/Python*

# -----------------------------------------------------------------------------
# Install supervisor and distribute ...
# -----------------------------------------------------------------------------
RUN pip install supervisor distribute \
    && rm -rf /tmp/*

# -----------------------------------------------------------------------------
# Configure, timezone/sshd/passwd/networking
# -----------------------------------------------------------------------------
RUN ln -sf /usr/share/zoneinfo/Asia/Chongqing /etc/localtime \
    && sed -i \
        -e 's/^UsePAM yes/#UsePAM yes/g' \
        -e 's/^#UsePAM no/UsePAM no/g' \
        -e 's/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g' \
        -e 's/^#UseDNS yes/UseDNS no/g' \
        /etc/ssh/sshd_config \
    && echo "root" | passwd --stdin root \
    && ssh-keygen -q -b 1024 -N '' -t rsa -f /etc/ssh/ssh_host_rsa_key \
    && ssh-keygen -q -b 1024 -N '' -t dsa -f /etc/ssh/ssh_host_dsa_key \
    && echo "NETWORKING=yes" > /etc/sysconfig/network

# -----------------------------------------------------------------------------
# Install curl
# -----------------------------------------------------------------------------
ENV CURL_INSTALL_DIR ${HOME}/libcurl
RUN cd ${SRC_DIR} \
    && wget -q -O curl-7.58.0.tar.gz http://curl.askapache.com/download/curl-7.58.0.tar.gz \
    && tar xzf curl-7.58.0.tar.gz \
    && cd curl-7.58.0 \
    && ./configure --prefix=${CURL_INSTALL_DIR} \
    && make 1>/dev/null \
    && make install \
    && rm -rf ${SRC_DIR}/curl*

# -----------------------------------------------------------------------------
# Install Nginx
# -----------------------------------------------------------------------------
ENV nginx_version 1.12.2
ENV NGINX_INSTALL_DIR ${HOME}/nginx
RUN cd ${SRC_DIR} \
    && wget -q -O nginx-${nginx_version}.tar.gz http://nginx.org/download/nginx-${nginx_version}.tar.gz \
    && wget -q -O nginx-http-concat.zip https://github.com/alibaba/nginx-http-concat/archive/master.zip \
    && wget -q -O nginx-logid.zip https://github.com/pinguo-liuzhaohui/nginx-logid/archive/master.zip \
    && wget -q -O ngx_devel_kit-0.3.0.tar.gz https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz \
    && wget -q -O lua-nginx-module-0.10.11.tar.gz https://github.com/openresty/lua-nginx-module/archive/v0.10.11.tar.gz \
    && wget -q -O LuaJIT-2.0.5.tar.gz http://luajit.org/download/LuaJIT-2.0.5.tar.gz \
    && tar zxf nginx-${nginx_version}.tar.gz \
    && unzip nginx-http-concat.zip -d nginx-http-concat \
    && unzip nginx-logid.zip -d nginx-logid \
    && tar zxf ngx_devel_kit-0.3.0.tar.gz \
    && tar zxf lua-nginx-module-0.10.11.tar.gz \
    && tar zxf LuaJIT-2.0.5.tar.gz \
    && cd LuaJIT-2.0.5 \
    && make PREFIX=${HOME}/LuaJIT-2.0.5 1>/dev/null \
    && make install PREFIX=${HOME}/LuaJIT-2.0.5 \
    && cd ${HOME} \
    && ln -s LuaJIT-2.0.5 luajit \
    && export LUAJIT_LIB=${HOME}/luajit/lib \
    && export LUAJIT_INC=${HOME}/luajit/include/luajit-2.0 \
    && cd ${SRC_DIR}/nginx-${nginx_version} \
    && ./configure --prefix=$NGINX_INSTALL_DIR --with-http_stub_status_module --with-http_ssl_module \
        --add-module=../nginx-http-concat/nginx-http-concat-master --add-module=../nginx-logid/nginx-logid-master \
        --with-ld-opt="-Wl,-rpath,${HOME}/luajit/lib" --add-module=../ngx_devel_kit-0.3.0 --add-module=../lua-nginx-module-0.10.11 1>/dev/null \
    && make 1>/dev/null \
    && make install \
    && rm -rf ${SRC_DIR}/nginx-* ${SRC_DIR}/ngx_devel_kit* ${SRC_DIR}/lua-nginx-module* ${SRC_DIR}/LuaJIT*

# -----------------------------------------------------------------------------
# Install Redis
# -----------------------------------------------------------------------------
ENV redis_version 3.2.11
ENV REDIS_INSTALL_DIR ${HOME}/redis
RUN cd ${SRC_DIR} \
    && wget -q -O redis-${redis_version}.tar.gz http://download.redis.io/releases/redis-${redis_version}.tar.gz \
    && tar xzf redis-${redis_version}.tar.gz \
    && cd redis-${redis_version} \
    && make 1>/dev/null \
    && make PREFIX=$REDIS_INSTALL_DIR install \
    && rm -rf ${SRC_DIR}/redis-*

# -----------------------------------------------------------------------------
# Install Mongodb
# -----------------------------------------------------------------------------
ENV mongodb_version 3.4.9
ENV MONGODB_INSTALL_DIR ${HOME}/mongodb/${mongodb_version}
RUN cd ${SRC_DIR} \
    && wget -q -O mongodb-linux-x86_64-rhel62-${mongodb_version}.tgz https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel62-3.4.9.tgz \
    && tar xzf mongodb-linux-x86_64-rhel62-${mongodb_version}.tgz \
    && mkdir -p ${MONGODB_INSTALL_DIR} \
    && mv mongodb-linux-x86_64-rhel62-${mongodb_version}/* ${MONGODB_INSTALL_DIR} \
    && rm -rf ${SRC_DIR}/mongodb*

## -----------------------------------------------------------------------------
## Install Mysql
## -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O mysql57-community-release-el6-11.noarch.rpm https://dev.mysql.com/get/mysql57-community-release-el6-11.noarch.rpm \
    && rpm -ivh --nodigest --nosignature mysql57-community-release-el6-11.noarch.rpm \
    && yum -v -y install mysql-community-client mysql-community-server \
    && rm -f mysql57-community-release-el6-11.noarch.rpm \
    && yum clean all

# -----------------------------------------------------------------------------
# Install Rabbitmq
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O rabbitmq-c-0.8.0.tar.gz  https://github.com/alanxz/rabbitmq-c/archive/v0.8.0.tar.gz \
    && tar zxf rabbitmq-c-0.8.0.tar.gz \
    && cd rabbitmq-c-0.8.0 \
    && autoreconf -i \
    && ./configure --prefix=${HOME}/rabbitmq-c 1>/dev/null \
    && make 1>/dev/null \
    && make install \
    && rm -rf ${SRC_DIR}/rabbitmq-c*

RUN cd ${SRC_DIR} \
    && wget -q -O otp_src_20.0.tar.gz http://erlang.org/download/otp_src_20.0.tar.gz \
    && tar zxf otp_src_20.0.tar.gz \
    && cd otp_src_20.0 \
    && ./configure --enable-hipe --with-ssl \
    && make \
    && make install \
    && rm -rf /var/cache/{yum,ldconfig}/* \
    && rm -rf /etc/ld.so.cache \
    && yum clean all \
    && rm -rf ${SRC_DIR}/otp*

ENV RABBIT_INSTALL_DIR $HOME/rabbitmq
RUN cd ${SRC_DIR} \
    && wget -q -O rabbitmq-server-generic-unix-3.6.12.tar.xz http://www.rabbitmq.com/releases/rabbitmq-server/v3.6.12/rabbitmq-server-generic-unix-3.6.12.tar.xz \
    && tar xf rabbitmq-server-generic-unix-3.6.12.tar.xz \
    && mv rabbitmq_server-3.6.12 ${RABBIT_INSTALL_DIR} \
    && rm -rf ${SRC_DIR}/rabbitmq*

# -----------------------------------------------------------------------------
# Install ImageMagick
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O ImageMagick.tar.gz https://www.imagemagick.org/download/ImageMagick.tar.gz \
    && tar zxf ImageMagick.tar.gz \
    && rm -rf ImageMagick.tar.gz \
    && ImageMagickPath=`ls` \
    && cd ${ImageMagickPath} \
    && ./configure \
    && make \
    && make install \
    && rm -rf $SRC_DIR/ImageMagick*

# -----------------------------------------------------------------------------
# Install hiredis
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O hiredis-0.13.3.tar.gz https://github.com/redis/hiredis/archive/v0.13.3.tar.gz \
    && tar zxvf hiredis-0.13.3.tar.gz \
    && cd hiredis-0.13.3 \
    && make \
    && make install \
    && echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf \
    && ldconfig \
    && rm -rf $SRC_DIR/hiredis-*

# -----------------------------------------------------------------------------
# Install libmemcached using by php-memcached
# -----------------------------------------------------------------------------
ENV LIB_MEMCACHED_INSTALL_DIR /usr/local/
RUN cd ${SRC_DIR} \
    && wget -q -O libmemcached-1.0.18.tar.gz https://launchpad.net/libmemcached/1.0/1.0.18/+download/libmemcached-1.0.18.tar.gz \
    && tar xzf libmemcached-1.0.18.tar.gz \
    && cd libmemcached-1.0.18 \
    && ./configure --prefix=$LIB_MEMCACHED_INSTALL_DIR --with-memcached 1>/dev/null \
    && make 1>/dev/null \
    && make install \
    && rm -rf ${SRC_DIR}/libmemcached*

# -----------------------------------------------------------------------------
# Install libmcrypt using by php-mcrypt
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O libmcrypt-2.5.8.tar.gz https://nchc.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz \
    && tar xzf libmcrypt-2.5.8.tar.gz \
    && cd libmcrypt-2.5.8 \
    && ./configure 1>/dev/null \
    && make 1>/dev/null \
    && make install \
    && echo "/usr/local/lib64" >> /etc/ld.so.conf.d/local.conf \
    && echo "/usr/local/src/libmcrypt-2.5.8/lib/.libs" >> /etc/ld.so.conf.d/local.conf \
    && chmod gu+x /etc/ld.so.conf.d/local.conf \
    && ldconfig -v

# -----------------------------------------------------------------------------
# Install re2c for PHP
# -----------------------------------------------------------------------------
run cd $SRC_DIR \
    && wget -q -O re2c-1.0.tar.gz https://excellmedia.dl.sourceforge.net/project/re2c/old/re2c-1.0.tar.gz \
    && tar xzf re2c-1.0.tar.gz \
    && cd re2c-1.0 \
    && ./configure \
    && make \
    && make install \
    && rm -rf ${SRC_DIR}/re2c*

# -----------------------------------------------------------------------------
# Install Gearman
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q https://github.com/gearman/gearmand/releases/download/1.1.18/gearmand-1.1.18.tar.gz \
    && tar zxf gearmand-1.1.18.tar.gz \
    && cd gearmand-1.1.18 \
    && ./configure --prefix=${HOME}/gearmand --disable-hiredis \
    && make -j \
    && make install \
    && rm -rf $SRC_DIR/gearmand*

# -----------------------------------------------------------------------------
# Install PHP
# -----------------------------------------------------------------------------
ENV phpversion 7.1.13
ENV PHP_INSTALL_DIR ${HOME}/php
RUN cd ${SRC_DIR} \
    && ls -l \
    && wget -q -O php-${phpversion}.tar.gz http://cn2.php.net/distributions/php-${phpversion}.tar.gz \
    && tar xzf php-${phpversion}.tar.gz \
    && cd php-${phpversion} \
    && ./configure \
       --prefix=${PHP_INSTALL_DIR} \
       --with-config-file-path=${PHP_INSTALL_DIR}/etc \
       --with-config-file-scan-dir=${PHP_INSTALL_DIR}/etc/php.d \
       --sysconfdir=${PHP_INSTALL_DIR}/etc \
       --with-libdir=lib64 \
       --enable-mysqlnd \
       --enable-zip \
       --enable-exif \
       --enable-ftp \
       --enable-mbstring \
       --enable-mbregex \
       --enable-fpm \
       --enable-bcmath \
       --with-gmp \
       --enable-pcntl \
       --enable-soap \
       --enable-sockets \
       --enable-shmop \
       --enable-sysvmsg \
       --enable-sysvsem \
       --enable-sysvshm \
       --enable-gd-native-ttf \
       --enable-wddx \
       --enable-opcache \
       --with-gettext \
       --with-xsl \
       --with-libexpat-dir \
       --with-xmlrpc \
       --with-snmp \
       --with-ldap \
       --enable-mysqlnd \
       --with-mysqli=mysqlnd \
       --with-pdo-mysql=mysqlnd \
       --with-pdo-odbc=unixODBC,/usr \
       --with-gd \
       --with-jpeg-dir \
       --with-png-dir \
       --with-zlib-dir \
       --with-freetype-dir \
       --with-zlib \
       --with-bz2 \
       --with-openssl \
       --with-curl=${CURL_INSTALL_DIR} \
       --with-mcrypt \
       --with-mhash \
    && make 1>/dev/null \
    && make install \
    && rm -rf ${PHP_INSTALL_DIR}/lib/php.ini \
    && cp -f php.ini-development ${PHP_INSTALL_DIR}/lib/php.ini \
    && rm -rf ${SRC_DIR}/php* ${SRC_DIR}/libmcrypt*

# -----------------------------------------------------------------------------
# Install yaml and PHP yaml extension
# -----------------------------------------------------------------------------
RUN cd $SRC_DIR \
    && wget -q -O yaml-0.1.7.tar.gz http://pyyaml.org/download/libyaml/yaml-0.1.7.tar.gz \
    && tar xzf yaml-0.1.7.tar.gz \
    && cd yaml-0.1.7 \
    && ./configure --prefix=/usr/local \
    && make >/dev/null \
    && make install \
    && cd $SRC_DIR \
    && wget -q -O yaml-2.0.2.tgz https://pecl.php.net/get/yaml-2.0.2.tgz \
    && tar xzf yaml-2.0.2.tgz \
    && cd yaml-2.0.2 \
    && $PHP_INSTALL_DIR/bin/phpize \
    && ./configure --with-yaml=/usr/local --with-php-config=$PHP_INSTALL_DIR/bin/php-config \
    && make >/dev/null \
    && make install \
    && rm -rf $SRC_DIR/yaml-*

# -----------------------------------------------------------------------------
# Install PHP mongodb extensions
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O mongodb-1.3.4.tgz https://pecl.php.net/get/mongodb-1.3.4.tgz \
    && tar zxf mongodb-1.3.4.tgz \
    && cd mongodb-1.3.4\
    && ${PHP_INSTALL_DIR}/bin/phpize \
    && ./configure --with-php-config=$PHP_INSTALL_DIR/bin/php-config 1>/dev/null \
    && make clean \
    && make \
    && make install \
    && rm -rf ${SRC_DIR}/mongodb-*

# -----------------------------------------------------------------------------
# Install PHP amqp extensions
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O amqp-1.9.3.tgz http://pecl.php.net/get/amqp-1.9.3.tgz \
    && tar zxvf amqp-1.9.3.tgz \
    && cd amqp-1.9.3 \
    && ${PHP_INSTALL_DIR}/bin/phpize \
    && ./configure --with-php-config=$PHP_INSTALL_DIR/bin/php-config --with-librabbitmq-dir=${HOME}/rabbitmq-c 1>/dev/null \
    && make clean \
    && make 1>/dev/null \
    && make install \
    && rm -rf ${SRC_DIR}/amqp*

# -----------------------------------------------------------------------------
# Install PHP redis extensions
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O redis-3.1.6.tgz https://pecl.php.net/get/redis-3.1.6.tgz \
    && tar zxf redis-3.1.6.tgz \
    && cd redis-3.1.6 \
    && ${PHP_INSTALL_DIR}/bin/phpize \
    && ./configure --with-php-config=$PHP_INSTALL_DIR/bin/php-config 1>/dev/null \
    && make clean \
    && make 1>/dev/null \
    && make install \
    && rm -rf ${SRC_DIR}/redis-*

# -----------------------------------------------------------------------------
# Install PHP imagick extensions
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O imagick-3.4.3.tgz https://pecl.php.net/get/imagick-3.4.3.tgz \
    && tar zxf imagick-3.4.3.tgz \
    && cd imagick-3.4.3 \
    && ${PHP_INSTALL_DIR}/bin/phpize \
    && ./configure --with-php-config=$PHP_INSTALL_DIR/bin/php-config \
    --with-imagick 1>/dev/null \
    && make clean \
    && make 1>/dev/null \
    && make install \
    && rm -rf ${SRC_DIR}/imagick-*

# -----------------------------------------------------------------------------
# Install PHP xdebug extensions
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O xdebug-2.5.5.tgz https://pecl.php.net/get/xdebug-2.5.5.tgz \
    && tar zxf xdebug-2.5.5.tgz \
    && cd xdebug-2.5.5 \
    && ${PHP_INSTALL_DIR}/bin/phpize \
    && ./configure --with-php-config=$PHP_INSTALL_DIR/bin/php-config 1>/dev/null \
    && make clean \
    && make 1>/dev/null \
    && make install \
    && rm -rf ${SRC_DIR}/xdebug-*

# -----------------------------------------------------------------------------
# Install PHP igbinary extensions
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O igbinary-2.0.1.tgz https://pecl.php.net/get/igbinary-2.0.1.tgz \
    && tar zxf igbinary-2.0.1.tgz \
    && cd igbinary-2.0.1 \
    && ${PHP_INSTALL_DIR}/bin/phpize \
    && ./configure --with-php-config=$PHP_INSTALL_DIR/bin/php-config 1>/dev/null \
    && make clean \
    && make 1>/dev/null \
    && make install \
    && rm -rf ${SRC_DIR}/igbinary-*

# -----------------------------------------------------------------------------
# Install PHP memcached extensions
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O memcached-3.0.3.tgz https://pecl.php.net/get/memcached-3.0.3.tgz \
    && tar xzf memcached-3.0.3.tgz \
    && cd memcached-3.0.3 \
    && ${PHP_INSTALL_DIR}/bin/phpize \
    && ./configure --enable-memcached --with-php-config=$PHP_INSTALL_DIR/bin/php-config \
       --with-libmemcached-dir=$LIB_MEMCACHED_INSTALL_DIR --disable-memcached-sasl 1>/dev/null \
    && make 1>/dev/null \
    && make install \
    && rm -rf ${SRC_DIR}/memcached-*

# -----------------------------------------------------------------------------
# Install PHP yac extensions
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O yac-2.0.2.tgz https://pecl.php.net/get/yac-2.0.2.tgz \
    && tar zxf yac-2.0.2.tgz\
    && cd yac-2.0.2 \
    && ${PHP_INSTALL_DIR}/bin/phpize \
    && ./configure --with-php-config=$PHP_INSTALL_DIR/bin/php-config \
    && make 1>/dev/null \
    && make install \
    && rm -rf $SRC_DIR/yac-*

# -----------------------------------------------------------------------------
# Install PHP swoole extensions
# -----------------------------------------------------------------------------
ENV swooleVersion 1.9.23
RUN cd ${SRC_DIR} \
    && wget -q -O swoole-${swooleVersion}.tar.gz https://github.com/swoole/swoole-src/archive/v${swooleVersion}.tar.gz \
    && tar zxf swoole-${swooleVersion}.tar.gz \
    && cd swoole-src-${swooleVersion}/ \
    && ${PHP_INSTALL_DIR}/bin/phpize \
    && ./configure --with-php-config=$PHP_INSTALL_DIR/bin/php-config --enable-async-redis --enable-openssl \
    && make clean 1>/dev/null \
    && make 1>/dev/null \
    && make install \
    && rm -rf ${SRC_DIR}/swoole*

# -----------------------------------------------------------------------------
# Install PHP inotify extensions
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O inotify-2.0.0.tgz https://pecl.php.net/get/inotify-2.0.0.tgz \
    && tar zxf inotify-2.0.0.tgz \
    && cd inotify-2.0.0 \
    && ${PHP_INSTALL_DIR}/bin/phpize \
    && ./configure --with-php-config=$PHP_INSTALL_DIR/bin/php-config 1>/dev/null \
    && make clean \
    && make 1>/dev/null \
    && make install \
    && rm -rf ${SRC_DIR}/inotify-*

# -----------------------------------------------------------------------------
# Install PHP Gearman extensions
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q https://github.com/wcgallego/pecl-gearman/archive/gearman-2.0.3.tar.gz \
    && tar zxf gearman-2.0.3.tar.gz \
    && cd pecl-gearman-gearman-2.0.3 \
    && ${PHP_INSTALL_DIR}/bin/phpize \
    && ./configure --with-php-config=$PHP_INSTALL_DIR/bin/php-config --with-gearman=${HOME}/gearmand/ 1>/dev/null \
    && make clean \
    && make 1>/dev/null \
    && make install \
    && rm -rf ${SRC_DIR}/*

# -----------------------------------------------------------------------------
# Install phpunit
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O phpunit.phar https://phar.phpunit.de/phpunit.phar \
    && mv phpunit.phar ${PHP_INSTALL_DIR}/bin/phpunit \
    && chmod +x ${PHP_INSTALL_DIR}/bin/phpunit

# -----------------------------------------------------------------------------
# Install php composer
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && curl -sS https://getcomposer.org/installer | $PHP_INSTALL_DIR/bin/php \
    && chmod +x composer.phar \
    && mv composer.phar ${PHP_INSTALL_DIR}/bin/composer

# -----------------------------------------------------------------------------
# Install PhpDocumentor
# -----------------------------------------------------------------------------
RUN $PHP_INSTALL_DIR/bin/pear install -a PhpDocumentor

RUN cd ${PHP_INSTALL_DIR} \
    && bin/php bin/composer self-update \
    && bin/pear install PHP_CodeSniffer-2.3.4 \
    && rm -rf /tmp/*

# -----------------------------------------------------------------------------
# Install jq
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O jq-1.5.tar.gz https://github.com/stedolan/jq/archive/jq-1.5.tar.gz \
    && tar zxf jq-1.5.tar.gz \
    && cd jq-jq-1.5 \
    && ./configure --disable-maintainer-mode \
    && make \
    && make install \
    && rm -rf ${SRC_DIR}/jq-*

# -----------------------------------------------------------------------------
# Install Apache ab
# -----------------------------------------------------------------------------
RUN cd ${HOME} \
    && yum -y remove httpd \
    && mkdir httpd \
    && cd httpd \
    && yumdownloader httpd-tools \
    && rpm2cpio httpd-tools* | cpio -idmv \
    && mkdir -p /home/worker/bin \
    && mv ./usr/bin/ab /home/worker/bin \
    && cd ${HOME} && rm -rf /home/worker/httpd

# -----------------------------------------------------------------------------
# Update Git
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && yum -y remove git subversion \
    && wget -q -O git-2.16.1.tar.gz https://github.com/git/git/archive/v2.16.1.tar.gz \
    && tar zxf git-2.16.1.tar.gz \
    && cd git-2.16.1 \
    && make configure \
    && ./configure --without-iconv --prefix=/usr/local/ --with-curl=${CURL_INSTALL_DIR} \
    && make \
    && make install \
    && rm -rf $SRC_DIR/git-2*

# -----------------------------------------------------------------------------
# Install Node and apidoc and nodemon
# -----------------------------------------------------------------------------
RUN npm install apidoc nodemon -g

# -----------------------------------------------------------------------------
# Copy Config
# -----------------------------------------------------------------------------
ADD run.sh /
ADD config /home/worker/
ADD CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo

# -----------------------------------------------------------------------------
# Add user worker
# -----------------------------------------------------------------------------
RUN useradd -M -u 1000 worker \
    && echo "worker" | passwd --stdin worker \
    && echo 'worker  ALL=(ALL)  NOPASSWD: ALL' > /etc/sudoers.d/worker \
    && sed -i \
        -e 's/^#PermitRootLogin yes/PermitRootLogin no/g' \
        -e 's/^PermitRootLogin yes/PermitRootLogin no/g' \
        -e 's/^#PermitUserEnvironment no/PermitUserEnvironment yes/g' \
        -e 's/^PermitUserEnvironment no/PermitUserEnvironment yes/g' \
        /etc/ssh/sshd_config \
    && chmod a+x /run.sh \
    && chmod a+x ${PHP_INSTALL_DIR}/bin/checkstyle \
    && chmod a+x ${PHP_INSTALL_DIR}/bin/mergeCoverReport

# -----------------------------------------------------------------------------
# clean tmp file
# -----------------------------------------------------------------------------
RUN rm -rf ${SRC_DIR}/*
RUN rm -rf /tmp/*

ENTRYPOINT ["/run.sh"]

EXPOSE 22 80 443
CMD ["/usr/sbin/sshd", "-D"]
