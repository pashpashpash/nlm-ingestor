# syntax=docker/dockerfile:experimental

# Base stage for Python and Java
FROM python:3.11-bookworm as base
ENV APP_HOME /app
WORKDIR ${APP_HOME}

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    openjdk-17-jre-headless \
    libxml2-dev libxslt-dev \
    build-essential libmagic-dev \
    libmagic1 \
    unzip \
    git \
    lsb-release \
    && mkdir -p /usr/share/man/man1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Tesseract installation
FROM base as tesseract
RUN echo "deb https://notesalexp.org/tesseract-ocr5/$(lsb_release -cs)/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/notesalexp.list \
    && apt-get update -oAcquire::AllowInsecureRepositories=true \
    && apt-get install notesalexp-keyring -oAcquire::AllowInsecureRepositories=true -y --allow-unauthenticated \
    && apt-get update \
    && apt-get install -y tesseract-ocr libtesseract-dev \
    && wget -P /usr/share/tesseract-ocr/5/tessdata/ https://github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies stage
FROM tesseract as python-deps
COPY requirements.txt .
RUN pip install --upgrade pip setuptools \
    && pip install -r requirements.txt

# Application stage
FROM python:3.11-bookworm as final
ENV APP_HOME /app
WORKDIR ${APP_HOME}
COPY --from=python-deps /root/.cache /root/.cache
COPY --from=python-deps /usr/local /usr/local
COPY . ./
RUN python -m nltk.downloader stopwords \
    && python -m nltk.downloader punkt \
    && chmod +x run.sh \
    # Cleanup pip cache
    && rm -rf /root/.cache

EXPOSE 8080 
# yolo
CMD ["./run.sh"]
