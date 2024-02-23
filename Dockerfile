# Use the official Python image from Docker Hub
FROM python:3.8-slim

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        build-essential \
        libpq-dev \
        libxml2-dev \
        libxslt1-dev \
        libldap2-dev \
        libsasl2-dev \
        libssl-dev \
        libjpeg-dev \
        zlib1g-dev \
        libfreetype6-dev \
        liblcms2-dev \
        libwebp-dev \
        libtiff5-dev \
        libopenjp2-7-dev \
        libjpeg62-turbo-dev \
        wget \
        curl \
        unzip \
    && rm -rf /var/lib/apt/lists/*


# Set working directory
WORKDIR $ODOO_HOME

# Install Odoo dependencies
COPY odoo-bin /
COPY requirements.txt /
RUN pip install -r requirements.txt

# Expose Odoo port
EXPOSE 8069

# Start Odoo
CMD ["python3", "odoo-bin", "-c", "odoo.conf"]
