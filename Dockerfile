##
# Yamcs container image built from source.
#
# - Builds the Angular web UI via npm (Maven does not compile it)
# - Builds the Maven `distribution` tarball and installs it into the runtime image
#
# Result: a runnable Yamcs distribution with `/yamcs/bin/yamcsd`
##

# ---- Stage 1: Build the web UI (creates yamcs-web/src/main/webapp/dist/webapp) ----
FROM node:20-bookworm-slim AS webui

WORKDIR /src/yamcs-web/src/main/webapp

COPY yamcs-web/src/main/webapp/package.json yamcs-web/src/main/webapp/package-lock.json ./
RUN npm ci

COPY yamcs-web/src/main/webapp/ ./
RUN npm run build


# ---- Stage 2: Build Yamcs distribution tarball (Maven) ----
FROM maven:3.9.9-eclipse-temurin-17 AS build

WORKDIR /build

COPY . .

# Copy the built web UI into the location expected by the yamcs-web Maven module
COPY --from=webui /src/yamcs-web/src/main/webapp/dist/webapp ./yamcs-web/src/main/webapp/dist/webapp

# Build distribution artifacts (includes Linux tarballs)
RUN mvn -Pbuild-distribution -pl distribution -am -DskipTests package

# Extract the correct Linux tarball based on target architecture
ARG TARGETARCH
RUN set -eux; \
  case "${TARGETARCH:-amd64}" in \
    amd64) DIST_ID="linux-x86_64" ;; \
    arm64) DIST_ID="linux-aarch64" ;; \
    *) echo "Unsupported TARGETARCH: ${TARGETARCH} (expected amd64 or arm64)"; exit 1 ;; \
  esac; \
  TARBALL="$(ls -1 distribution/target/yamcs-*-"${DIST_ID}".tar.gz | head -n 1)"; \
  mkdir -p /out; \
  tar -xzf "${TARBALL}" -C /out; \
  mv /out/yamcs-*/ /out/yamcs


# ---- Stage 3: Runtime image ----
FROM eclipse-temurin:17-jre

WORKDIR /yamcs
COPY --from=build /out/yamcs/ /yamcs/

ENV PATH="/yamcs/bin:${PATH}"

EXPOSE 8090

# Default. Override in your own compose if needed.
CMD ["yamcsd"]


