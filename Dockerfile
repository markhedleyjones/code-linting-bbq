ARG BASE_IMAGE
FROM $BASE_IMAGE AS base
COPY build/tmp/ /build/

# Configure the apt mirror
ARG APT_MIRROR=""
RUN if [ "${APT_MIRROR}" != "" ]; then if [ "${APT_MIRROR}" = "auto" ]; then \
  APT_MIRROR="mirror://mirrors.ubuntu.com/mirrors.txt"; fi && sed --in-place \
  "s|http://archive.ubuntu.com/ubuntu/|${APT_MIRROR}|g" /etc/apt/sources.list; \
  fi

# Install APT packages (if any) from packagelist
COPY build/tmp/packagelist /build/packagelist
RUN if [ -s /build/packagelist ] ; then \
  apt-get update \
  && apt-get install --yes --no-install-recommends $(cat /build/packagelist | xargs) \
  && rm -rf /var/lib/apt/lists/* ; \
  fi

# Install Python packages (if any) from pip-requirements.txt
COPY build/tmp/pip /build/pip
RUN if [ ! -z $(ls /build/pip) ] ; then for path in /build/pip/pip*-req*.txt ; \
  do $(basename ${path} | cut -d '-' -f 1) install --no-cache-dir -r ${path} ; done ; fi

# Create user account (if necessary)
ARG USER_GID
ARG USER_UID
ARG USER_NAME
RUN if [ "${USER_NAME}" != "root" ]; then \
  addgroup --gid ${USER_GID} ${USER_NAME} \
  && adduser --disabled-password --gecos '' --gid ${USER_GID} --uid ${USER_UID} ${USER_NAME} ; \
  fi
USER $USER_NAME

# Setup workspace variables
ARG WORKDIR
ARG WORKSPACE_NAME
ENV WORKSPACE $WORKDIR/$WORKSPACE_NAME
WORKDIR $WORKDIR

# Copy any installation resources from the host
COPY build/resources/* ${WORKDIR}

################################################################################
# DEVELOPMENT TARGET - generate development-friendly image
################################################################################
FROM base AS development-image
# Install development tools

################################################################################
# PRE-PRODUCTION STAGE - transform workspace into production-ready state
################################################################################
FROM base AS pre-production
ARG USER_NAME
ARG WORKSPACE_NAME
COPY --chown=${USER_NAME} $WORKSPACE_NAME $WORKSPACE
# Build workspace and/or remove files not intended for production

################################################################################
# PRODUCTION TARGET - generate final self-contained image
################################################################################
FROM base AS production-image
ARG USER_NAME
# Copy the clean workspace into production image
COPY --from=pre-production --chown=${USER_NAME} $WORKSPACE $WORKSPACE
