# CAN-Verify

---

## Description

The aim of this program is to streamlined the entire underlying process of formal modelling/encoding from BDI agents in CAN language to Bigraphs, model execution in BigraphER tool, and back-end model-checker with PRISM. It was developed by Thibault Rivoalen ([thibault.rivoalen@alumni.enac.fr](mailto:thibault.rivoalen@alumni.enac.fr)) for the University of Glasgow, UK. If you have any question installing it, please also send the email to corresponding author to mengwei.xu@manchester.ac.uk. 


--- 

## Script

We recommand building program in Ubuntu (which has been succesfully tested).

We have provide a script ```ifm-artifact-install-and-run.sh``` that anyone can run to 1. install the dependencies automatically and 2. run the IFM2023 accepted paper examples automatically. 

You may need to do ```chmod +x ifm-artifact-install-and-run.sh``` first.




---
## Quick Start


We recommand building program in Ubuntu (which has been succesfully tested).


We have pre-combined the main binary and dependency binary in folder ```./bins``` required whereever we can to run the tool.

1. ./CAN-Verify is the main binary (as its name indicates)
2. ./bigrapher is the binary for dependency tool BigraphER




To get the binary for PRISM, we have provided the source code (for Linux x86) downloaded directly from the PRISM website.

- extract the prism source code
- navigate to the folder as current path
- simply run ```./install.sh``` 


To allow the binary dependencies to be discovered, please set these in your PATH, 

e.g. ```export PATH=$PATH:./bins:./bins/prism-4.8-linux64-x86: ```

You may also need to run ```chmod u+x bigrapher``` to use dependency binary bigrapher. 




---

## How to build the program from the source codes



### Built locally

To build the project and have an executable binary ```./CAN-Verify```, please first obtain the following dependency

#### Dependencies
1. Java 17 (or above), 
2. PRISM model checker: http://www.prismmodelchecker.org/download.php
3. BigraphER: https://uog-bigraph.bitbucket.io/
4. Opam/OCaml: ```sudo apt install ocaml opam```
5. packages for OCaml: dune, dune-configurator, jsonm, menhir, cmdliner, ppx_optcomp, mtime, zarith, odoc -- ```opam install dune dune-configurator jsonm menhir cmdliner ppx_optcomp mtime zarith odoc```


##### Dependencies note for 2 and 3


To allow the binary dependencies to be discovered, please set these in your PATH, 

e.g. ```export PATH=$PATH:./bins:./bins/prism-4.8-linux64-x86: ```

You may also need to run ```chmod u+x bigrapher``` to use dependency binary bigrapher. 

#### Build the program

run : ``` make ```  



---


## Usage


Run ```./CAN-Verify  [options] [-p prop.txt] <file.can>```

### Options: ``` [options] ```

```-static```: to perform a static check of ```file.can``` 

```-dynamic```: to perform a dynamic check with BigraphER and PRISM   

```-p```: to tell the program which file contains the properties to verify  

```-Ms```: to tell the maximum number of states possible (default: 4000)  

```-mp```: to tell the minimum number of plan required (default: 2)  

```-Mp```: to tell the maximum number of plan allowed (default: 100)  

```-mc```: to tell the minimum number of character required in a name (default: 2)  

```-Mc```: to tell the maximum number of character allowed in a name (default: 20)

```-big```:  to export the CAN model to .big file

```--help```:  to display this list of options

### Belief-based property specifications: ``` [-p prop.txt] ```

the current implementation support the input in ```prop.txt``` of the following 

1. In all possible executions, eventually the belief ```variable``` holds: *A [ F ("```variable```") ]*.
2. In some executions, eventually the belief ```variable``` holds: *E [ F ("```variable```") ]*.

For example, we can have:

1. In all possible executions, eventually the belief F1_clean holds.
2. In some executions, eventually the belief F1_clean holds.



##### Property specification note
- the generic properties are by default included to check determining if for some/all executions an event finishes with failure or success.

- the parse will complain if the exact wording is not followed.


## Paper Examples
As per our accepted IFM paper attached in the artifact submission, the examples used in the paper are included in the folder ./paper_examples. The following is the commentary:

- **Listing_1-3.can** corresponds to the examples in Listing 1.3. CAN agent for concurrent sensing in UAVs.
- **Listing_1-3-Corrected.can** corresponds to the improved design for Listing 1.3 where we replace the concurrenty program  **dust || photo** with **dust; photo**. 
- **Listing_1-4.can** corresponds to the examples in Listing 1.4. CAN agent for two-storey building patrol robot.
- **Listing_1-4.txt** corresponds to the belief-based property spefication for Listing 1.4. 


### run examples
- for the exmaple in listing 1.3, please run the command

```./CAN-Verify -dynamic paper_examples/Listing_1-3.can```

```./CAN-Verify -dynamic paper_examples/Listing_1-3-Corrected.can```

- for the exmaple in listing 1.4, please run the command


```./CAN-Verify -dynamic -p paper_examples/Listing_1-4.txt paper_examples/Listing_1-4.can```


#### for a quick check

- for the exmaple in listing 1.3, you should get the following

> Model checking: A [ F ("no_failure"&(X "empty_intention")) ] ... Result: false

there means that it is not always the case the task of sensing is achieved eventually.

> Model checking: E [ F ("failure"&(X "empty_intention")) ] ... Result: true

there means that there indeed exists a case that the task of sensing is failed eventually.


- if you run the exmaple in **Listing_1-3-Corrected.can**, you should get the following

> Model checking: A [ F ("no_failure"&(X "empty_intention")) ] ... Result: True

there means that it is always the case the task of sensing is achieved eventually.


> Model checking: E [ F ("failure"&(X "empty_intention")) ] ... Result: false

there means that there never exists the case the task of sensing is failed eventually.

- for the exmaple in **Listing_1-4.can**, you should get the following

> Modelc checking: A [ F ("predicate_F1_clean") ] ... Result: true

there means that it is always the case that the predicate of F1_clean holds eventually. 




### Built with Docker

Make sure the current path is in the extracted zip fold.

Run ```sudo make docker``` to have a ```can-verify``` Docker image built for you. 


#### Usage 

Instead of running ```./CAN-Verify  [options] [-p prop.txt] <file.can>```, in docker setting, please run 


```sudo docker run --rm --volume "${PWD}":/test_rep --interactive can-verify [options] [-p prop.txt] <file.can>```.

For example to run the example in listing 1.4, you can run

```sudo docker run --rm --volume "${PWD}":/test_rep --interactive can-verify -dynamic -p paper_examples/Listing_1-4.txt paper_examples/Listing_1-4.can```



## Copyright and license
Copyright 2012-2022 Glasgow Bigraph Team  
All rights reserved. Tools distributed under the terms of the Simplified BSD License that can be found in the [LICENSE file](LICENSE.md).Copyright 2012-2022 Glasgow Bigraph Team  
All rights reserved. Tools distributed under the terms of the Simplified BSD License that can be found in the [LICENSE file](LICENSE.md).