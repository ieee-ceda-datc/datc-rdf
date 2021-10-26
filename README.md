DATC Robust Design Flow
===

IEEE CEDA Design Automation Technical Committee (DATC) has developed a public reference design flow, named DATC Robust Design Flow (RDF), over the past six years. IEEE DATC Robust Design Flow (DATC RDF) is intended to (i) preserve and integrate leading research codes, including from past academic contests, and to (ii) provide a foundation and backplane for academic research in the RTL-to-GDS IC implementation arena.

This repository includes the latest release of DATC RDF, _RDF-2021_, which is described in our ICCAD paper:

* J. Chen, I. H.-R. Jiang, J. Jung, A. B. Kahng, S. Kim, V. N. Kravets, Y.-L. Li, R. Varadarajan and M. Woo, "DATC RDF-2021: Design Flow and Beyond," in _Proc. ICCAD_, Nov. 2021.



Installation
---

### Prerequisite

RDF-2021 is provided as a Docker image. So, we need Docker to be installed before installing RDF-2021. For Docker installation, please refer to [this webpage](https://www.docker.com/get-started).


### Creating RDF-2021 Docker Image

Clone this repository.

```bash
git clone https://github.com/ieee-ceda-datc/datc-rdf.git
```

Once it's done, get into the cloned repository and initialize submodules.

```bash
cd datc-rdf
git submodule update --init
```

We first need to build the OpenROAD Docker image. Run the following commands:

```bash
(cd ./submodules/OpenROAD-flow-scripts && ./build_openroad.sh)
```

This will build the OpenROAD Docker image, which is used for building RDF-2021 image.
In case you have issues of building the OpenROAD image, you can find the detailed instruction at the official OpenROAD documentation page shown below:

* [Getting Started with OpenROAD Flow](https://openroad.readthedocs.io/en/latest/user/BuildWithDocker.html).


Once you build the OpenROAD Docker image successfully, you can now build the Docker image of RDF-2021.
First, get back to the top-level directory of the cloned repository.

```bash
cd $(git rev-parse --show-toplevel)
```

And build the Docker image using the following command.

```bash
docker build ./ -t datc-rdf
```


### Checking Installation

You can check whether RDF-2021 image is built properly by the following commands:

```bash
docker image ls
```

You should see the Docker image named `datc-rdf` as follows.


```bash
datc-rdf$ docker image ls
REPOSITORY  TAG     IMAGE ID      CREATED     SIZE
datc-rdf    latest  cba3c1452e87  1 hours ago 6.71GB
```

To check whether you can run RDF-2021, run the following command, which creates a Docker container from the RDF-2021 image.

```bash
docker run --rm -it -v $(pwd):/root/datc-rdf datc-rdf
```


Running Example Chisel Design
---

Here, we describe how to make SP&R for a Chisel design with DATC RDF-2021.
In your Docker container, go to the home directory, i.e., `cd ~/`, and create a workspace under the `datc-rdf` directory.

```bash
cd datc-rdf
mkdir workspace && cd workspace
```

We use `riscv-mini`, is a simple RISC-V 3-stage pipeline written in Chisel ([Link](https://github.com/ucb-bar/riscv-mini)). First, clone the design.

```bash
git clone https://github.com/ucb-bar/riscv-mini.git
```

To generate Verilog from the Chisel source code, run the following.

```bash
cd riscv-mini
make
```

The generated Verilog will be stored at `./ generated-src/Tile.v`.



### Running ASSURE for RTL Obfuscation (Optional)

One key update in RDF 2021 is RTL obfuscation with ASSURE.
ASSURE is already installed in RDF-2021 Docker image, which you can find at `~/datc-rdf/submodules/assure-bin`.
The directory includes the user guide of ASSURE: `~/datc-rdf/submodules/assure-bin/doc`.

To try it with the Chisel design, here's an example command for it.

```bash
./assure-bin/bin/assure \
    --top Core \
    --enable-key-reuse \
    --obfuscate-ops \
    --obfuscate-branch \
    --input-key=./key_512bit.txt \
    ./riscv-mini/generated-src/Tile.v
```


### Adding Scan Chain with Fault (Optional)

Another key update of RDF-2021 is DFT support with Fault tool chain. You can find detailed information about it at the project repository: [Link](https://github.com/Cloud-V/Fault). 

During the Docker build process, Fault is already installed in the RDF-2021 Docker image.  You can try it, for example, on the `riscv-mini` with the following script.

```bash
/root/bin/fault chain \
    --clock clock --reset reset \
    --liberty ~/datc-rdf/submodules/OpenROAD-flow-scripts/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib \
    --dff sky130_fd_sc_hd__dfrtp_1,sky130_fd_sc_hd__dfxtp_1 \
    --output 1_synth.fault.v \
    /workspace/OpenROAD-flow-scripts/flow/results/sky130hd/riscv-mini/base.bak/1_synth.v 
```


### Running SP&R with OpenROAD Flow

To run the OpenROAD flow, we need a design configuration file. Open your preferred text editor, and create a file named `config.mk` with the following contents. It is a configuration file to build `riscv-mini` design targeting SKY130HD library; the core utilization is set as 30%.

```make
export DESIGN_NICKNAME = riscv-mini
export DESIGN_NAME = Core_0_obf
export PLATFORM    = sky130hd

export VERILOG_FILES = $(sort $(wildcard /root/datc-rdf/workspace/riscv-mini/generated-src/*.v))
export SDC_FILE      = ./designs/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc

# These values must be multiples of placement site
#export DIE_AREA    = 0 0 380 380.8
#export CORE_AREA   = 10 12 370 371.2
export CORE_UTILIZATION = 30
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 2
#
export PLACE_DENSITY = 0.72

export ABC_CLOCK_PERIOD_IN_PS = 100000
```

We also need a timing constraint file (SDC). Let us create a simple SDC having only a clock definition.

```tcl
create_clock [get_ports clock] -period 10
```

Once it is done, we can run the OpenROAD flow, for example by the following command.

```bash
cd ~/datc-rdf/submodules/OpenROAD-flow-scripts/flow
make DESIGN_CONFIG=/path/to/your/config.mk
```


### Running SP&R with RDF Point Tool-Based Flow

To run the point-tool based RDF flow, we need a design configuration file. For `riscv-mini`, you can use the following configuration file for example. For more details, please see [here](https://github.com/ieee-ceda-datc/rdf-2020#design-configuration).

```yaml
name:        Core_0_obf
clock_port:  clock
verilog:     
    - ~/datc-rdf/workspace/riscv-mini/generated-src/Tile.v
```

Once you create a design configuration file, you can follow the description shown [here](https://github.com/ieee-ceda-datc/rdf-2020).


References
---

To run more about DATC RDF, please check out our recent papers and webpage.

1. IEEE CEDA Design Automation Technical Committee, https://ieee-ceda.org/node/2591
1. J. Chen, I. H.-R. Jiang, J. Jung, A. B. Kahng, S. Kim, V. N. Kravets, Y.-L. Li, R. Varadarajan and M. Woo, "DATC RDF-2021: Design Flow and Beyond," Proc. ICCAD, Nov. 2021.
1. J. Chen, I. H.-R. Jiang, J. Jung, A. B. Kahng, V. N. Kravets, Y.-L. Li, S.-T. Lin and M. Woo, "DATC RDF-2020: Strengthening the Foundation for Academic Research in IC Physical Design," Proc. ICCAD, Nov. 2020.
1. J. Chen, I. H.-R. Jiang, J. Jung, A. B. Kahng, V. N. Kravets, Y.-L. Li, S.-T. Lin andM. Woo, "DATC RDF-2019: Towards a complete academic reference design flow," Proc. ICCAD, Nov. 2019.
