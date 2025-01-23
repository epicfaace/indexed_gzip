# Base image with Python 3.8 (minimum requirement is Python 3.7)
FROM python:3.8-slim AS build-stage

# Install required system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       cython3 \
       zlib1g-dev \
       git \
       libffi-dev \
       pkg-config \
       libpython3-dev \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy pyproject.toml and setup.py to the container for dependency installation
COPY pyproject.toml setup.py .

# Install build dependencies
RUN pip install --no-cache-dir setuptools wheel cython

# Copy the full source code into the image
COPY . .

# Build the project
RUN python setup.py bdist_wheel

# Start a new cleaner image for runtime
FROM python:3.8-slim AS runtime-stage

# Install runtime dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app/main

# Copy the built wheel file from the build-stage
COPY --from=build-stage /app/dist/*.whl ./

# Install the built package
RUN pip install --no-cache-dir ./*.whl

# Ensure only runtime files remain
RUN rm -rf /app/main/*.whl

# The image is now ready for deployment. Leave CMD/ENTRYPOINT for runtime configuration.