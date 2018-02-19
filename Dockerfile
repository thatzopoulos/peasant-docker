FROM ubuntu

RUN apt-get update && apt-get install -y \
python \ 
python-dev \  
gcc \
unzip \
make \
git \
wget \
build-essential \
ncbi-blast+ \
python-pip \
libc6-dev \
zlib1g-dev \
vim \
curl

ADD SPAdes-3.10.1-Linux.tar.gz spades
ADD g3-iterated-viral.csh g3-iterated-viral.csh 
ADD BBMap_37.36.tar.gz bbmap
#ADD tRNAscan-SE.tar.gz tRNAscan
ADD requirements.txt requirements.txt


RUN python -m pip install biopython

#Get Peasant
RUN git clone https://github.com/jlbren/peasant
RUN mv peasant/* /

#SICKLE Setup
RUN git clone https://github.com/najoshi/sickle.git \
    && cd sickle \
    && make \
    && cd .. \
    && cp sickle/sickle /usr/bin \
    && rm -r sickle


#Spades Setup
RUN mv spades/SPAdes-3.10.1-Linux/* spades/
RUN rm -r spades/SPAdes-3.10.1-Linux

#Get Glimmer3
ENV GLIMMER_VERSION 302b
ENV GLIMMER_DIR /opt/glimmer
ENV GLIMMER_SUBDIR glimmer3.02
RUN mkdir -p $GLIMMER_DIR
RUN curl -SL https://ccb.jhu.edu/software/glimmer/glimmer$GLIMMER_VERSION.tar.gz | tar -xzC $GLIMMER_DIR
RUN cd $GLIMMER_DIR/$GLIMMER_SUBDIR/src && make
#Add glimmer to PATH
ENV PATH $GLIMMER_DIR/$GLIMMER_SUBDIR/bin:$GLIMMER_DIR/$GLIMMER_SUBDIR/scripts:$PATH
#Update hard-coded paths in g3-iterated.csh 
RUN sed -i "s|/fs/szgenefinding/Glimmer3|${GLIMMER_DIR}/${GLIMMER_SUBDIR}|g" $GLIMMER_DIR/$GLIMMER_SUBDIR/scripts/g3-iterated.csh
RUN sed -i "s|/nfshomes/adelcher/bin/elph|${ELPH_DIR}/bin/elph|g" $GLIMMER_DIR/$GLIMMER_SUBDIR/scripts/g3-iterated.csh
RUN sed -i "s|/bin/awk|/usr/bin/awk|g" $GLIMMER_DIR/$GLIMMER_SUBDIR/scripts/*.awk

RUN cp $GLIMMER_DIR/$GLIMMER_SUBDIR/scripts/g3-iterated.csh .

#Get tRNAScan-SE
RUN cp /usr/include/stdio.h /usr/include/stdio.h~ && \
sed -i -e 678,680d /usr/include/stdio.h && \
cd /tmp && \
wget http://lowelab.ucsc.edu/software/tRNAscan-SE-1.23.tar.gz && \
tar xzvf tRNAscan-SE-1.23.tar.gz && \
cd tRNAscan-SE-1.23 && \
export HOME=/usr/local && \
make && \
make install && \
make testrun && \
make clean && \
mv /usr/include/stdio.h~ /usr/include/stdio.h && \
rm -rf /tmp/*

RUN pip install -r requirements.txt


ENV PATH /bbmap/bbmap:/spades/bin:/blast:$PATH
