# Symbolic models and results for BLE-SC pairing Protocol

This project presents symbolic models and results of our paper "Formal Analysis and Patching of BLE-SC Pairing" published at USENIX Security '23.
The symbolic models for the Bluetooth Low Energy Secure Connections (BLE-SC) pairing protocol are developed using the Tamarin Prover and cover all association models, including Numeric Comparison (NC), Passkey Entry (PE), Out of Band (OOB), and Just Works (JW), as well as all phases of the protocol, including Pairing Feature Exchange, Long Term Key (LTK) Generation, and Transport Specific Key Distribution.

## Requirements
To reproduce the results of this project, you will need:
- Tamarin Prover (version 1.6.0) [Installation](https://tamarin-prover.github.io/manual/book/002_installation.html)
- Python (version 3.9)
- Python packages:
  - beautifulsoup4 (version 4.10.0)
  - Jinja2 (version 3.0.2)
  - requests (version 2.26.0)

## Usage
Once you have cloned the repository, you can navigate to the project directory and start exploring the results or reproducing our analysis by yourself.

### Exploring the results
To explore the results, you can open `index.html` in the root directory using a web browser. This file contains an overview of the project and links to the individual results for the unfixed BLE-SC pairing, the fixed BLE-SC pairing, and the SSP-SC pairing protocol.
Click on the link that you are interested in to view the corresponding result.

### Reproducing the analysis
In `index.html`, you will also find detailed instructions on how to reproduce each analysis.
Please note that reproducing the analysis requires a significant amount of computation and may take a long time to complete, depending on the specifications of your computer.

## Examples
Here's an example of how to analyze the unfixed BLE-SC pairing:
1. Ensure that you are in the `BLE` directory.
2. Open the `Makefile.m4` file and change the `File` variable to `BLE_SC_PAIRING.m4`.
3. Change the `Dir` variable to `BLEResults/Unfixed`.
4. Execute the following commands step-by-step:
```shell
m4 Makefile.m4 > Makefile
make ALL
```
Please note that running the `make ALL` command may take a long time, depending on the specifications of your server.

5. After the analysis is complete, you can use the following commands to collect and view the results:
```shell
python rescrawler.py BLEResults/Unfixed
python collect.py BLEResults/Unfixed
```
These commands will collect and aggregate the results from the individual analysis runs and generate a summary report, which can be found in the `BLEResults/Unfixed` directory.
