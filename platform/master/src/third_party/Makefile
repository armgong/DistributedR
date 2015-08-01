.PHONY: atomicio

ZMQ_VERSION=4.1.2
PROTOBUF_VERSION=2.6.1
BOOST_VERSION=1_58_0

INSTALLDIR=$(abspath install/)
NCORES=$(shell getconf _NPROCESSORS_ONLN)

all: boost protobuf zmq uuid atomicio cgroup


boost: $(INSTALLDIR)/lib/libboost_chrono.a $(INSTALLDIR)/lib/libboost_date_time.a $(INSTALLDIR)/lib/libboost_filesystem.a $(INSTALLDIR)/lib/libboost_log.a $(INSTALLDIR)/lib/libboost_log_setup.a $(INSTALLDIR)/lib/libboost_system.a $(INSTALLDIR)/lib/libboost_thread.a

boost/b2:
	tar xf boost_${BOOST_VERSION}.tar.gz
	cd boost_${BOOST_VERSION}; ./bootstrap.sh --with-libraries=thread,system,log,chrono

$(INSTALLDIR)/lib/libboost_chrono.a $(INSTALLDIR)/lib/libboost_date_time.a $(INSTALLDIR)/lib/libboost_filesystem.a $(INSTALLDIR)/lib/libboost_log.a $(INSTALLDIR)/lib/libboost_log_setup.a $(INSTALLDIR)/lib/libboost_system.a $(INSTALLDIR)/lib/libboost_thread.a: boost/b2
	cd boost_${BOOST_VERSION}; ./b2 -j$(NCORES) --with-thread --with-log --with-chrono --with-system cxxflags=-fPIC link=static runtime-link=shared --stagedir=$(INSTALLDIR)/ stage

protobuf: $(INSTALLDIR)/lib/libprotobuf.a  $(INSTALLDIR)/lib/libprotobuf-lite.a  $(INSTALLDIR)/lib/libprotoc.a $(INSTALLDIR)/bin/protoc

$(INSTALLDIR)/lib/libprotobuf.a  $(INSTALLDIR)/lib/libprotobuf-lite.a  $(INSTALLDIR)/lib/libprotoc.a $(INSTALLDIR)/bin/protoc:
	tar xf protobuf-$(PROTOBUF_VERSION).tar.gz
	cd protobuf-$(PROTOBUF_VERSION); CFLAGS=-fPIC CXXFLAGS=-fPIC LDFLAGS=-fPIC ./configure --enable-static --enable-shared=no --prefix=$(INSTALLDIR) && make -j$(NCORES) && make install

zmq: $(INSTALLDIR)/lib/libzmq.a

$(INSTALLDIR)/lib/libzmq.a: $(INSTALLDIR)/lib/libuuid.a
	tar xf zeromq-${ZMQ_VERSION}.tar.gz
	cd zeromq-$(ZMQ_VERSION); CFLAGS="-fPIC -I$(INSTALLDIR)/include" CXXFLAGS="-fPIC -I$(INSTALLDIR)/include" LDFLAGS="-fPIC -L$(INSTALLDIR)/lib" ./configure --enable-static --enable-shared=no --prefix=$(INSTALLDIR) && make -j$(NCORES) && make install


uuid: $(INSTALLDIR)/lib/libuuid.a
$(INSTALLDIR)/lib/libuuid.a:
	tar xf libuuid-1.0.3.tar.gz
	cd libuuid-1.0.3; CFLAGS=-fPIC CXXFLAGS=-fPIC LDFLAGS=-fPIC ./configure  --enable-static --enable-shared=no --prefix=$(INSTALLDIR)  && make -j$(NCORES) && make install

cgroup: $(INSTALLDIR)/lib/libcgroup.a
$(INSTALLDIR)/lib/libcgroup.a:
	tar xf libcgroup-0.41.tar.gz
	cd libcgroup-0.41; CFLAGS=-fPIC CXXFLAGS=-fPIC LDFLAGS=-fPIC ./configure --enable-pam=no --enable-static --enable-shared=no --prefix=$(INSTALLDIR) && make -j$(NCORES) && make install

atomicio:
	cd atomicio && make

blkin: $(INSTALLDIR)/lib/libzipkin-cpp.so

$(INSTALLDIR)/lib/libzipkin-cpp.a: $(INSTALLDIR)/lib/libboost_chrono.a
	tar -zxf blkin.tar.gz
	cd blkin/; autoreconf -fi; CFLAGS="-fPIC -I$(INSTALLDIR)/../boost_${BOOST_VERSION}" CXXFLAGS="-fPIC -I$(INSTALLDIR)/../boost_${BOOST_VERSION}" LDFLAGS=-fPIC ./configure --prefix=$(INSTALLDIR) --enable-static --enable-shared=no --without-babeltrace; make -j$(NCORES) && make install; 
	
clean: 
	rm -rf $(INSTALLDIR)/bin/protoc
	rm -rf $(INSTALLDIR)/bin/R-executor-bin
	rm -rf $(INSTALLDIR)/bin/R-worker-bin
	rm -rf $(INSTALLDIR)/include/
	rm -rf $(INSTALLDIR)/lib/
	rm -rf $(INSTALLDIR)/share/
	cd zeromq-$(ZMQ_VERSION) && make clean
	cd libuuid-1.0.3 && make clean
	cd protobuf-$(PROTOBUF_VERSION) && make clean
	cd libcgroup-0.41 && make clean
	cd atomicio && make clean
	cd boost_${BOOST_VERSION}/ && ./b2 --clean
	rm -rf boost_${BOOST_VERSION}/stage/
	rm -rf boost_${BOOST_VERSION}/b2
 
