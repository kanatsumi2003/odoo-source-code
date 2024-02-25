# Use the official Python image from Docker Hub
FROM python:3.8-slim

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
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

COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
COPY setup/odoo /usr/bin/odoo
COPY odoo-bin /opt/odoo/odoo-bin
COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py
COPY requirements.txt /
RUN chmod +x /entrypoint.sh \
    && chmod +x /usr/local/bin/wait-for-psql.py \
    && chmod +x /usr/bin/odoo
# Set working directory
WORKDIR /app
COPY . /app
# Install Odoo dependencies
RUN pip install -r requirements.txt --target=/usr/lib/python3/dist-packages
RUN mkdir -p /usr/lib/python3/dist-packages/odoo
RUN chmod +x /usr/lib/python3/dist-packages/odoo
RUN cp -r /app/odoo /usr/lib/python3/dist-packages/
ENV PYTHONPATH="${PYTHONPATH}:/usr/lib/python3/dist-packages/"

# Expose Odoo port
EXPOSE 8069 8071 8072

# Start Odoo
ENTRYPOINT ["/entrypoint.sh"]
# CMD ["python", "/app/odoo-bin"]
CMD ["odoo", "--config=/etc/odoo/odoo.conf" ]
# , "-c", "odoo.conf"