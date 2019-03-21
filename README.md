GDAL built from python:3 image.  Used as a base image for various geospatial use cases.

This Docker Image is available on Dockerhub at [python3-gdal](https://hub.docker.com/r/pedros007/python3-gdal)

# Usage

Run gdalinfo on a file at `$(pwd)/file.tif` with this image:

	docker run --rm -it -v $(pwd):/data pedros007/python3-gdal:2.4.0 gdalinfo /data/file.tif

# Build

	docker build -t pedros007/python3-gdal:2.4.0 .
