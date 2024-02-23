# Use Python as the base image
FROM python:3.9-slim

# Set environment variables
ENV ODOO_VERSION=16.0 \
    ODOO_SOURCE_DIR=/opt/odoo \
    ODOO_ADDONS_DIR=/opt/odoo/addons \
    ODOO_USER=odoo \
    ODOO_GROUP=odoo \
    ODOO_PORT=8069

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        python3-dev \
        libxml2-dev \
        libxslt1-dev \
        libldap2-dev \
        libsasl2-dev \
        libssl-dev \
        libpq-dev \
        libjpeg-dev \
        zlib1g-dev \
        node-less \
        npm \
        git \
    && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py
ENV ODOO_RC /etc/odoo/odoo.conf
COPY ./odoo.conf /etc/odoo/

RUN chmod +x /entrypoint.sh \
    && chmod +x /usr/local/bin/wait-for-psql.py \
    && chmod +x /etc/odoo/odoo.conf

RUN chown odoo /etc/odoo/odoo.conf \
    && mkdir -p /mnt/extra-addons \
    && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]
# Install Odoo requirements
RUN pip install wheel
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt


# Expose Odoo port
EXPOSE 8069 8071 8072

# Run Odoo
ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
