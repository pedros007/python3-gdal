FROM python:3
MAINTAINER Peter Schmitt "pschmitt@gmail.com"
ARG OPENJPEG_VERSION=2.3.1
ARG CURL_VERSION=7.64.1
ARG GDAL_VERSION=2.4.1

# To build from GitHub, comment out curl http://download.osgeo... and
# cd, replace with something like:
#
#    curl -L https://github.com/OSGeo/gdal/archive/2c866d3c62bb52852d7ab6850b63d3a3d81b51a1.tar.gz | tar zxv -C /tmp && \
#    cd /tmp/gdal-2c866d3c62bb52852d7ab6850b63d3a3d81b51a1/gdal && \
#
# Then build:
#   docker build -t pedros007/python3-gdal:2c866d3 .

ENV LD_LIBRARY_PATH=/usr/local/lib
RUN \
# Install libraries
    apt-get update && \
    apt-get upgrade -y && \
    apt-get remove -y curl libcurl3 && \
    apt-get install -y --no-install-recommends \
        build-essential \
        make \
        cmake \
        ca-certificates\
        shapelib \
        libproj-dev \
        libproj12 \
        proj-data \
        libgeos-3.5.1 \
        libgeos-c1v5 \
        libgeos-dev \
        postgresql-client-common \
        libpq-dev \
        nghttp2 \
        libnghttp2-dev \
        libssl-dev && \
# Build libcurl with nghttp2 to enable /vsicurl/ suport for HTTP/2
    wget -qO- https://curl.haxx.se/download/curl-$CURL_VERSION.tar.gz | tar zxv -C /tmp && \
    cd /tmp/curl-$CURL_VERSION  && \
    ./configure --prefix=/usr/local --disable-manual --disable-cookies --with-nghttp2 --with-ssl  && \
    make -j $(grep --count ^processor /proc/cpuinfo) --silent && \
    make install && \
# Build OpenJPEG
    wget -qO- https://github.com/uclouvain/openjpeg/archive/v$OPENJPEG_VERSION.tar.gz | tar zxv -C /tmp && \
    mkdir -p cd /tmp/openjpeg-$OPENJPEG_VERSION/build && \
    cd /tmp/openjpeg-$OPENJPEG_VERSION/build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr && \
    make -j $(grep --count ^processor /proc/cpuinfo) --silent && \
    make install && \
# Build GDAL
    pip install numpy && \
    curl http://download.osgeo.org/gdal/$GDAL_VERSION/gdal-$GDAL_VERSION.tar.gz | tar zxv -C /tmp && \
    cd /tmp/gdal-$GDAL_VERSION && \
    ./configure \
        --prefix=/usr \
        --with-threads \
        --with-hide-internal-symbols=yes \
        --with-rename-internal-libtiff-symbols=yes \
        --with-rename-internal-libgeotiff-symbols=yes \
        --with-libtiff=internal \
        --with-geotiff=internal \
        --with-geos \
        --with-pg \
        --with-curl=/usr/local/bin/curl-config \
        --with-static-proj4=yes \
        --with-openjpeg=yes \
        --with-ecw=no \
        --with-grass=no \
        --with-hdf5=no \
        --with-java=no \
        --with-mrsid=no \
        --with-perl=no \
        --with-python=yes \
        --with-webp=no \
        --with-xerces=no && \
    make -j $(grep --count ^processor /proc/cpuinfo) && \
    make install && \
# Fix certificate path (some applications look in this alternate location)
    mkdir -p /etc/pki/tls/certs && \
    ln -s /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt && \
# Clean up
    apt-get remove -y --purge \
        libgeos-dev \
        libpq-dev \
        libnghttp2-dev \
        libssl-dev && \
    rm -rf /var/lib/apt/lists/* /tmp/* && \
    rm -rf /root/.cache/pip

# Set HOME dir so AWS credentials can be fetched at ~/.aws/credentials
# https://lists.osgeo.org/pipermail/gdal-dev/2017-July/046846.html
ENV HOME=/root

CMD ["gdalinfo", "--version"]
