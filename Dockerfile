FROM python:3
MAINTAINER Peter Schmitt "pschmitt@gmail.com"
ENV  OPENJPEG_VERSION=2.3.1 \
     GDAL_VERSION=2.4.4

# TODO: add `--without-lib` to configure
# TODO: Build spatiallite support so `ogr2ogr -dialect SQLITE ...` works

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
        ca-certificates\
        shapelib \
        libproj-dev \
        libproj13 \
        proj-data \
        libgeos-3.7.1 \
        libgeos-c1v5 \
        libgeos-dev \
        postgresql-client-common \
        libpq-dev \
        nghttp2 \
        libnghttp2-dev \
        libssl-dev \
	libspatialite7 \
	libspatialite-dev \
	libwebp6 \
	libwebp-dev \
	bash-completion \
	&& \
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
        --with-curl \
        --with-geos=/usr/bin/geos-config \
        --with-geotiff=internal \
        --with-hide-internal-symbols=yes \
        --with-libtiff=internal \
        --with-openjpeg=yes \
        --with-pg=/usr/bin/pg_config \
        --with-python=yes \
	--with-spatialite=yes \
        --with-rename-internal-libgeotiff-symbols=yes \
        --with-rename-internal-libtiff-symbols=yes \
        --with-static-proj4=yes \
        --with-webp=yes \
        --without-ecw \
        --without-grass \
	--without-grib \
        --without-hdf5 \
        --without-java \
        --without-mrsid \
        --without-perl \
        --without-xerces \
	&& \
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
        libssl-dev \
	libspatialite-dev \
	libwebp-dev && \
    rm -rf /var/lib/apt/lists/* /tmp/* && \
    rm -rf /root/.cache/pip

# Set HOME dir so AWS credentials can be fetched at ~/.aws/credentials
# https://lists.osgeo.org/pipermail/gdal-dev/2017-July/046846.html
ENV HOME=/root

CMD ["gdalinfo", "--version"]
