FROM python:3.11-slim-bookworm

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

RUN apt-get update \
    # dependencies for building Python packages
    && apt-get install -y build-essential \
    # psycopg dependencies
    && apt-get install -y libpq-dev \
    # Translations dependencies
    && apt-get install -y gettext \
    # Uncomment below lines to enable Sphinx output to latex and pdf
    # && apt-get install -y texlive-latex-recommended \
    # && apt-get install -y texlive-fonts-recommended \
    # && apt-get install -y texlive-latex-extra \
    # && apt-get install -y latexmk \
    # install libs to get python wheels compiled also in armhf environment 
    # && apt-get install -y libxslt1-dev libffi-dev libxml2-dev libssl-dev python3-dev cargo libjpeg-dev \
    # cleaning up unused files
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

COPY ./docker/production/django/pip.conf /etc/pip.conf
RUN if [ "${TARGETPLATFORM}" != "linux/arm/v7" ] ; then rm /etc/pip.conf; fi

# Requirements are installed here to ensure they will be cached.
COPY ./requirements /requirements
# All imports needed for autodoc.
RUN pip install -r /requirements/local.txt -r /requirements/production.txt

WORKDIR /docs

CMD make livehtml
