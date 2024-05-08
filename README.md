# CAN-Verify

---

## Description

This project is developed based on Mengwei Xu's Can verigy tool. 

https://zenodo.org/records/8282684

The aim of this program is to streamlined the entire underlying process of formal modelling/encoding from BDI agents in CAN language to Bigraphs, model execution in BigraphER tool, and back-end model-checker with PRISM. It was developed by Thibault Rivoalen ([thibault.rivoalen@alumni.enac.fr](mailto:thibault.rivoalen@alumni.enac.fr)) for the University of Glasgow, UK. If you have any question installing it, please also send the email to corresponding author to mengwei.xu@manchester.ac.uk. 

---
## Quick Start


We recommand building program in Ubuntu (which has been succesfully tested).

glibc version requires 2.34 or above

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

1. What is the maximum probability that eventually the belief ```variable``` holds
2. What is the minimum probability that eventually the belief ```variable``` holds

For example, we can have:

What is the maximum probability that eventually the belief report holds
What is the minimum probability that eventually the belief report holds

### Agent attribute specification: ``` [.can] ```
1. // Initial belief bases, there is no upper limit on the number of beliefs,
2. 1 . ```belief name variable``` : <```positive value variable```, ```negative value variable```>, ```belief name variable``` : <```positive value variable```, ```negative value variable```>, ...
3. // External events, there is no upper limit on the number of event
4. ```event_a name variable``` : 1, ```event_b name variable``` : 2, ```event_c name variable``` : 3, ...
5. // Plan library, there is no upper limit on the number of plan.
6. 1: ```plan variable``` <- ```plan body variable```
7. 2：```plan variable``` <- ```plan body variable```
8. ...
9. // Actions description, there is no upper limit on the number of event
10. ```action name variable``` : ```cond variable``` <- < ```belief name variable``` : {```positive value variable```, ```positive EffectWeight variable```}>, < ```belief name variable``` : {```negative value variable```, ```negative EffectWeight variable```}>
11. ```action name variable``` : ```cond variable``` <- < ```belief name variable``` : {```positive value variable```, ```positive EffectWeight variable```}>, < ```belief name variable``` : {```negative value variable```, ```negative EffectWeight variable```}>
12. ...

##### Property specification note
- the generic properties are by default included to check determining if for some/all executions an event finishes with failure or success.

- the parse will complain if the exact wording is not followed.


### run examples
The project provides a new example, drone.can and drone.txt. Examples are included in the folder ./paper_examples. 

please run the command


```./CAN-Verify -dynamic -p paper_examples/drone.txt paper_examples/drone.can```

#### for a quick check

- for the exmaple in drone, you should get the following

> Model checking: Pmin=? [ F ("no_failure"&(X "empty_intention")) ] ... Result: 1.0

> Model checking: Pmax=? [ F ("no_failure"&(X "empty_intention")) ] ... Result: 1.0

there mean that it is always the case the task of sensing is achieved eventually.

> Model checking: Pmin=? [ F ("failure"&(X "empty_intention")) ] ... Result: 0.0

> Model checking: Pmax=? [ F ("failure"&(X "empty_intention")) ] ... Result: 0.0

there means that there never exists the case the task of sensing is failed eventually.

> Model checking: Pmax=? [ F ("predicate_report") ]

This sentence is translated from What is the maximum probability that eventually the belief report holds

> Result 0.7

This means that the maximum probability that eventually the belief report holds is 70%

> Model checking: Pmin=? [ F ("predicate_report") ]

This sentence is translated from What is the minimum probability that eventually the belief report holds

> Result 0.7

This means that the minimum probability that eventually the belief report holds is 70%


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
