# # Use Python as the base image
# FROM python:3.9-slim

# # Set environment variables
# ENV ODOO_VERSION=16.0 \
#     ODOO_SOURCE_DIR=/opt/odoo \
#     ODOO_ADDONS_DIR=/opt/odoo/addons \
#     ODOO_USER=odoo \
#     ODOO_GROUP=odoo \
#     ODOO_PORT=8069

# # Install dependencies
# RUN apt-get update \
#     && apt-get install -y --no-install-recommends \
#         gcc \
#         python3-dev \
#         libxml2-dev \
#         libxslt1-dev \
#         libldap2-dev \
#         libsasl2-dev \
#         libssl-dev \
#         libpq-dev \
#         libjpeg-dev \
#         zlib1g-dev \
#         node-less \
#         npm \
#         git \
#     && rm -rf /var/lib/apt/lists/*

# COPY ./entrypoint.sh /
# COPY ./odoo.conf /etc/odoo/
# COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py
# ENV ODOO_RC /etc/odoo/odoo.conf
# COPY ./odoo.conf /etc/odoo/

# RUN chmod +x /entrypoint.sh \
#     && chmod +x /usr/local/bin/wait-for-psql.py \
#     && chmod +x /etc/odoo/odoo.conf

# # Install Odoo requirements
# # RUN pip install wheel
# # COPY requirements.txt /tmp/requirements.txt
# # RUN pip install --no-cache-dir -r /tmp/requirements.txt && \
# #     rm /tmp/requirements.txt


# # Expose Odoo port
# EXPOSE 8069 8071 8072

# # Run Odoo
# # ENTRYPOINT ["/entrypoint.sh"]
# CMD ["./odoo-bin"]


FROM debian:bullseye-slim

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Retrieve the target architecture to install the correct wkhtmltopdf package
ARG TARGETARCH

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl-dev \
        node-less \
        npm \
        python3-magic \
        python3-num2words \
        python3-odf \
        python3-pdfminer \
        python3-pip \
        python3-phonenumbers \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-setuptools \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        xz-utils && \
    if [ -z "${TARGETARCH}" ]; then \
        TARGETARCH="$(dpkg --print-architecture)"; \
    fi; \
    WKHTMLTOPDF_ARCH=${TARGETARCH} && \
    case ${TARGETARCH} in \
    "amd64") WKHTMLTOPDF_ARCH=amd64 && WKHTMLTOPDF_SHA=9df8dd7b1e99782f1cfa19aca665969bbd9cc159  ;; \
    "arm64")  WKHTMLTOPDF_SHA=58c84db46b11ba0e14abb77a32324b1c257f1f22  ;; \
    "ppc64le" | "ppc64el") WKHTMLTOPDF_ARCH=ppc64el && WKHTMLTOPDF_SHA=7ed8f6dcedf5345a3dd4eeb58dc89704d862f9cd  ;; \
    esac \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bullseye_${WKHTMLTOPDF_ARCH}.deb \
    && echo ${WKHTMLTOPDF_SHA} wkhtmltox.deb | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# install latest postgresql-client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update  \
    && apt-get install --no-install-recommends -y postgresql-client \
    && rm -f /etc/apt/sources.list.d/pgdg.list \
    && rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian buster)
RUN npm install -g rtlcss

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/

# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py

# Set default user when running the container

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]