#!/usr/bin/bash

# Simple script to install the required binaries and run some examples,
# additional runs can be made in a similar fashion, but make sure to set the
# path!

# Configure dependencies
pushd bins
chmod u+x bigrapher
tar xzf prism-4.8-linux64-x86.tar.gz
pushd prism-4.8-linux64-x86
./install.sh
popd
popd

export PATH=$PATH:./bins:./bins/prism-4.8-linux64-x86:

# Run examples
echo "Listing 1.3"
CAN-Verify -dynamic paper_examples/Listing_1-3.can

echo "Listing 1.3 Corrected"
CAN-Verify -dynamic paper_examples/Listing_1-3-Corrected.can

echo "Listing 1.4"
CAN-Verify -dynamic -p paper_examples/Listing_1-4.txt paper_examples/Listing_1-4.can
