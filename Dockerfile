FROM python:3
MAINTAINER Peter Schmitt "pschmitt@gmail.com"

# To build from GitHub, comment out curl http://download.osgeo... and
# cd, replace with something like:
#
#    curl -L https://github.com/OSGeo/gdal/archive/2c866d3c62bb52852d7ab6850b63d3a3d81b51a1.tar.gz | tar zxv -C /tmp && \
#    cd /tmp/gdal-2c866d3c62bb52852d7ab6850b63d3a3d81b51a1/gdal && \
#
# Then build:
#   docker build -t pedros007/python3-gdal:2c866d3 .

RUN \
# Install libraries
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        build-essential \
        make \
        cmake \
        curl \
        ca-certificates\
        libcurl4-gnutls-dev \
        shapelib \
        libproj-dev \
        libproj12 \
        proj-data \
        libgeos-3.5.1 \
        libgeos-c1v5 \
        libgeos-dev \
        postgresql-client-common \
        libpq-dev && \
# Build OpenJPEG
    git clone -b master https://github.com/uclouvain/openjpeg.git /tmp/openjpeg && \
    mkdir /tmp/openjpeg/build && \
    cd /tmp/openjpeg/build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr && \
    make -j $(grep --count ^processor /proc/cpuinfo) && \
    make install && \
# Build GDAL
    pip install numpy && \
    curl http://download.osgeo.org/gdal/2.4.1/gdal-2.4.1.tar.gz | tar zxv -C /tmp && \
    cd /tmp/gdal-2.4.1 && \
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
        --with-curl \
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
        libcurl4-gnutls-dev \
        libgeos-dev \
        libpq-dev && \
    rm -rf /var/lib/apt/lists/* /tmp/* && \
    rm -rf /root/.cache/pip

# Set HOME dir so AWS credentials can be fetched at ~/.aws/credentials
# https://lists.osgeo.org/pipermail/gdal-dev/2017-July/046846.html
ENV HOME=/root

CMD ["gdalinfo", "--version"]
