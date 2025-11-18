FROM node:20-bookworm-slim

ARG SKIP_GRAMMAR=false
ARG SKIP_BUILD_APP=false
ARG SKIP_DATASETS=false
ARG VUE_APP_BACKEND_URL=https://vishalmysore-vidyaastraserver.hf.space

ENV DEBIAN_FRONTEND=noninteractive
ENV VUE_APP_BACKEND_URL=${VUE_APP_BACKEND_URL}

RUN apt-get update && apt-get install -y libatomic1 \
    $([ "$SKIP_GRAMMAR" != "true" ] && echo "openjdk-17-jdk python3" || echo "") \
    $([ "$SKIP_DATASETS" != "true" ] && echo "git" || echo "") \
    && rm -rf /var/lib/apt/lists/*
# Copy app
COPY . /home/node/app
RUN chown -R node:node /home/node/app

# Make data and database directories
RUN mkdir -p /database
RUN mkdir -p /data
RUN chown -R node:node /database
RUN chown -R node:node /data

# Switch to node user
USER node

# Set working directory
WORKDIR /home/node/app

# Install dependencies, generate grammar, and reduce size of kuzu node module
# Increase Node heap size to prevent out of memory errors during build
RUN NODE_OPTIONS="--max-old-space-size=4096" npm install &&\
    if [ "$SKIP_GRAMMAR" != "true" ] ; then NODE_OPTIONS="--max-old-space-size=4096" npm run generate-grammar-prod ; else echo "Skipping grammar generation" ; fi &&\
    rm -rf node_modules/kuzu/prebuilt node_modules/kuzu/kuzu-source

# Fetch datasets
RUN if [ "$SKIP_DATASETS" != "true" ] ; then NODE_OPTIONS="--max-old-space-size=4096" npm run fetch-datasets ; else echo "Skipping dataset fetch" ; fi

# Build app
RUN if [ "$SKIP_BUILD_APP" != "true" ] ; then NODE_OPTIONS="--max-old-space-size=4096" npm run build ; else echo "Skipping build" ; fi

# Expose port
EXPOSE 8000

# Set environment variables
ENV NODE_ENV=production
ENV PORT=8000
ENV KUZU_DIR=/database

# Run app
ENTRYPOINT ["node", "src/server/index.js"]
