FROM debian:jessie
MAINTAINER Mark Ugarov, m.ugarov86@googlemail.com

#1. Install idba and dependencies
RUN apt-get update -y
RUN apt-get install -y gcc build-essential make sed autoconf fastx-toolkit wget

# See https://groups.google.com/d/msg/hku-idba/RzTkrVTod8o/kNj_ZghK4eQJ
# This is why 1.0.9 is used instead of the latest 1.1.2
ADD https://hku-idba.googlecode.com/files/idba_ud-1.0.9.tar.gz /tmp/idba.tar.gz
RUN mkdir /tmp/idba \
&& tar xzf /tmp/idba.tar.gz --directory /tmp/idba --strip-components=1 \
&& sed --in-place 's/kMaxShortSequence = 128;/kMaxShortSequence = 1024;/' /tmp/idba/src/sequence/short_sequence.h

# See https://groups.google.com/forum/#!topic/hku-idba/T2mcHkDOpBU
RUN sed --in-place 's/contig_graph.MergeSimilarPath();//g' /tmp/idba/src/release/idba_ud.cpp \
&& cd /tmp/idba && \
       ./configure && \
       make && \
       make install \
       
&& mv /tmp/idba/bin/* /usr/local/bin/
     

ENV CONVERT https://github.com/bronze1man/yaml2json/raw/master/builds/linux_386/yaml2json
# download yaml2json and make it executable
RUN cd /usr/local/bin && wget --quiet ${CONVERT} && chmod 700 yaml2json

ENV JQ http://stedolan.github.io/jq/download/linux64/jq
# download jq and make it executable
RUN cd /usr/local/bin && wget --quiet ${JQ} && chmod 700 jq


# 2. Make validation possible
# Locations for biobox file validator
ENV VALIDATOR /bbx/validator/
ENV BASE_URL https://s3-us-west-1.amazonaws.com/bioboxes-tools/validate-biobox-file
ENV VERSION  0.x.y
RUN mkdir -p ${VALIDATOR}

# download the validate-biobox-file binary and extract it to the directory $VALIDATOR
RUN wget \
      --quiet \
      --output-document -\
      ${BASE_URL}/${VERSION}/validate-biobox-file.tar.xz \
    | tar xJf - \
      --directory ${VALIDATOR} \
      --strip-components=1

ENV PATH ${PATH}:${VALIDATOR}

# 3. Add the Taskfile  and the assemble-file
ADD Taskfile /

# Add assemble script to the directory /usr/local/bin inside the container.
# 	/usr/local/bin is appended to the $PATH variable what means that every script in 
#	that directory will be executed in the shell  without providing the path.
ADD assemble /usr/local/bin/
RUN chmod 700 /usr/local/bin/assemble

# download the assembler schema
RUN wget \
    --output-document /schema.yaml \
    https://raw.githubusercontent.com/bioboxes/rfc/master/container/short-read-assembler/input_schema.yaml

ENTRYPOINT ["/usr/local/bin/assemble"]
