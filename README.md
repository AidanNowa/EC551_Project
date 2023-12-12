# EC551_Project
## Team ASMR - Image Processing on FPGA

### Project Goal

Implement a system that could carry out real-time image transformations and encryption on the Nexys-7 FPGA.

Our current system utilizes Vivado's simulation capabilities and system verilog to read in an image in hexcode from the given file path and write the transformed image to a bitmap in the given location. We also have implemented synthesizable code for the camera interface, the VGA driver, and the dual-port BRAM buffer on the FPGA.

## Requirements 

### Hardware
OV7670 camera ([480x640p RGB565 output](https://www.amazon.com/HiLetgo-OV7670-640x480-0-3Mega-Arduino/dp/B07S66Y3ZQ))
          
Nexys A7 Artix-7 FPGA (https://digilent.com/shop/nexys-a7-fpga-trainer-board-recommended-for-ece-curriculum/)

### Software
Vivado 2022.1
Verilog

## How to Run

### Simulation Portion
1. Create a new Vivado 2022.1 project.

2. Upload the image_read.v, image_write.v, parameters.v, and tb_simulation.v files to your project

3. Within the tb_simulation.v file, change the .INFILE() section of the image_read component to the path to the hex file of your image and the .INFILE() section of the image_write component to the destination path (this will create a new file if one with that name does not exist or override the current file).

   a. if you do not have a hex file of your image: First, run the convert_bitmap_image_to_hex.m file with the bitmap image name as the input and change the name of the output file to your desired name ('kodim24.hex' is the default name).

4. Set the simulation time to be 6 seconds (Settings->Simulation->Simulation(within new window)->xsim.simulate.runtime*).

5. Under the 'Simulation' select 'Run Simulation' then 'Run Behavioral Simulation'.

6. From here you can either wait for the simulation to complete or monitor the destination folder until the completed image appears. The simulation can take 5+ minutes but the completed image should appear within a minute.   

## System Architecture
## Overview
![overview]/images/551_overview_arch.png
