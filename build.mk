#####################################################################
#A scalable and high-performance platform for R.
#Copyright (C) [2013] Hewlett-Packard Development Company, L.P.

#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 2 of the License, or (at
#your option) any later version.

#This program is distributed in the hope that it will be useful, but
#WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
#General Public License for more details.  You should have received a
#copy of the GNU General Public License along with this program; if
#not, write to the Free Software Foundation, Inc., 59 Temple Place,
#Suite 330, Boston, MA 02111-1307 USA
#####################################################################

# Makefile rules for building protocol buffer based presto binaries

# --- PROTOCOL BUFFERS ---

# Protocol Buffers C++ src files
${GEN_DIR}/%.pb.cc: platform/messaging/%.proto
	mkdir -p ${GEN_DIR}
	${PROTOC_BIN} --cpp_out=${GEN_DIR} --proto_path=platform/messaging $^

# Protocol Buffers library
${PRESTO_PROTO}: ${ATOMICIO_LIB} ${GEN_PROTO_SRC}
	mkdir -p ${LIB_DIR}
	${CXX} ${GCC_FLAGS} -fPIC -shared -o $@ ${GEN_PROTO_SRC} ${PROTOBUF_STATIC_LIB}

# --- COMMON ---

# Common objects
${PRESTO_COMMON_DIR}/%.o: platform/common/%.cpp ${PRESTO_COMMON_HEADERS}
	${CXX} $< -c ${GCC_FLAGS} -fPIC -o $@

# Common library
${PRESTO_COMMON}: ${PRESTO_PROTO} ${PRESTO_COMMON_OBJS}
	mkdir -p ${LIB_DIR}
	${CXX} ${PRESTO_COMMON_OBJS} ${LINK_FLAGS} -fPIC -shared -o $@ ${PROTOBUF_STATIC_LIB} -lR-proto ${ZMQ_STATIC_LIB}

# --- MASTER ---

# Master objects
${PRESTO_MASTER_DIR}/%.o: ${PRESTO_MASTER_DIR}/%.cpp ${PRESTO_MASTER_HEADERS} ${PRESTO_COMMON_HEADERS}
	${CXX} $< -c ${GCC_FLAGS} -fPIC -o $@

# Master R library
${MASTER_RLIB}: ${PRESTO_PROTO} ${PRESTO_COMMON} ${PRESTO_MASTER_OBJS} ${PRESTO_MASTER_RFILES}
	${R_HOME}/bin/R CMD INSTALL --no-html $(PWD)/platform/master

${MASTER_BIN}: ${PRESTO_PROTO} ${PRESTO_COMMON} ${PRESTO_MASTER_OBJS}
	${CXX} ${PRESTO_MASTER_OBJS} ${LINK_FLAGS} -o $@  -Wl,-rpath,${LIB_DIR} -lR-proto -Wl,-rpath,${LIB_DIR} -lR-common -lRInside -lR ${ZMQ_STATIC_LIB} ${PROTOBUF_STATIC_LIB}

# --- WORKER ---

# Worker R library
${WORKER_RLIB}: ${PRESTO_PROTO} ${PRESTO_COMMON} ${PRESTO_WORKER_OBJS} ${ATOMICIO_LIB} 
	${R_HOME}/bin/R CMD INSTALL $(PWD)/${PRESTO_WORKER_DIR}

# Worker objects
${PRESTO_WORKER_DIR}/%.o: ${PRESTO_WORKER_DIR}/%.cpp ${PRESTO_WORKER_HEADERS} ${PRESTO_COMMON_HEADERS}
	${CXX} $< -c ${GCC_FLAGS} -fPIC -o $@

# Worker binary
${WORKER_BIN}: ${PRESTO_PROTO} ${PRESTO_COMMON} ${PRESTO_WORKER_OBJS}
	mkdir -p ${BIN_DIR}
	${CXX} ${PRESTO_WORKER_OBJS} ${LINK_FLAGS} -o $@  -L${LIB_DIR} -lR-proto -L${LIB_DIR} -lR-common -Wl,-rpath,${LIB_DIR} -lRInside -lR ${ZMQ_STATIC_LIB} ${PROTOBUF_STATIC_LIB}

# --- EXECUTOR ---

# Executor R library
${EXECUTOR_RLIB}: ${PRESTO_COMMON} ${PRESTO_EXECUTOR_OBJS} ${PRESTO_EXECUTOR_RFILES}
	${R_HOME}/bin/R CMD INSTALL --no-docs $(PWD)/${PRESTO_EXECUTOR_DIR}

# Executor objects
${PRESTO_EXECUTOR_DIR}/%.o: ${PRESTO_EXECUTOR_DIR}/%.cpp ${PRESTO_EXECUTOR_HEADERS} ${PRESTO_COMMON_HEADERS}
	${CXX} $< -c ${GCC_FLAGS} -fPIC -o $@

# Executor binary
${EXECUTOR_BIN}: ${PRESTO_COMMON} ${EXECUTOR_RLIB} ${PRESTO_EXECUTOR_OBJS}
	mkdir -p ${BIN_DIR}
	${CXX} ${PRESTO_EXECUTOR_OBJS} platform/common/ArrayData.o platform/common/DistDataFrame.o platform/common/DistList.o platform/common/common.o ${LINK_FLAGS} -o $@ -L${LIB_DIR} -lR-proto -Wl,-rpath,${LIB_DIR} -lRInside -lR ${ZMQ_STATIC_LIB} ${PROTOBUF_STATIC_LIB}

# --- HELPER ---

# Helper R library
${MATRIX_HELPER_RLIB}: ${PRESTO_MATRIX_HELPER_OBJS} ${PRESTO_MATRIX_HELPER_RFILES}
	${R_HOME}/bin/R CMD INSTALL --no-docs $(PWD)/${PRESTO_MATRIX_HELPER_DIR}

# Helper objects
${PRESTO_MATRIX_HELPER_DIR}/%.o: ${PRESTO_EXECUTOR_DIR}/%.cpp
	${CXX} $< -c ${GCC_FLAGS} -fPIC -o $@
