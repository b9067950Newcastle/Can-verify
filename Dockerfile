FROM trivoalen/bigrapher-prism-base

RUN mkdir /CAN-verify

WORKDIR /CAN-verify

COPY . .

RUN eval $(opam env) && make install

RUN mkdir /test_rep

WORKDIR /test_rep

ENTRYPOINT ["CAN-Verify"]