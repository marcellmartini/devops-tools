# Why this repo?
This repo aims to study tools that could be used in SRE/DevOps/Platform Engineer jobs.

You could expect each tool that will be studied in this repo will always have the following:

* IaC that implements the tools.
* Code to test the IaC created for the tool
  * Terratest
  * Molecule (ansible)
* GitHub Actions to test the IaC built
* Always will have one automation, makefile or ansible, to create all necessary infrastructure to run the tool.

Pre-require necessary:
* Go 1.20 or newer
* Docker 23.0.4 or newer
* ansible [core 2.14.4]
* molecule 5.0.0
  * volecule-vagrant
* vagrant 2.3.4
* virtualbox 6.1

# The Future

The idea is to implement not just but at least the mindmap below:

![img](assets/images/DevOpsTools.png)
