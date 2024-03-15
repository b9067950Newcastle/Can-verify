TARGET = main
REP = CANVerifier
TARGET2 = CAN-Verify
WORKDIR = .

all:
	@dune build
	@dune build @doc
	@mv _build/default/$(REP)/$(TARGET).exe ./$(TARGET2)

docker:
	@docker build -t can-verify .

install:
	dune build
	mv _build/default/$(REP)/$(TARGET).exe /usr/bin/$(TARGET2)
	dune clean

clean:
	@dune clean
	@rm -f $(TARGET2)

clean-docker:
	@docker image rm can-verify

.PHONY: all clean
