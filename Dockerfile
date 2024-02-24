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

COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py
RUN chmod +x /entrypoint.sh \
    && chmod +x /usr/local/bin/wait-for-psql.py
# Set working directory
WORKDIR /app
COPY . /app
# Install Odoo dependencies
COPY odoo-bin /opt/odoo/odoo-bin
COPY requirements.txt /
RUN pip install -r requirements.txt

# Expose Odoo port
EXPOSE 8069 8071 8072

# Start Odoo
ENTRYPOINT ["/entrypoint.sh"]
# CMD ["python", "/app/odoo-bin"]
CMD ["odoo"]
# , "-c", "odoo.conf"