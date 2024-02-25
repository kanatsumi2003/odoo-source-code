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
        libjpeg-turbo8 \
        libssl1.1 \
        libxext6 \
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
        unzip 

RUN apt-get update && \
    apt-get install -y wget && \
    apt-get install -y openssl && \
    apt-get install -y fontconfig && \
    apt-get install -y libxrender1 && \
    apt-get install -y xfonts-75dpi && \
    apt-get install -y xfonts-base && \
    apt-get clean

RUN wget -O wkhtmltox.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.bionic_amd64.deb && \
    dpkg -i wkhtmltox.deb && \
    apt-get install -f && \
    apt-get clean && \
    rm wkhtmltox.deb

    

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