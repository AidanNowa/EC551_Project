# EC551_Project
## Team ASMR - Image Processing on FPGA

### Project Goal

Implement a system that could carry out real-time image transformations and encryption on the Nexys-7 FPGA.

Our current system utilizes Vivado's simulation capabilities and system verilog to read in an image in hexcode from the given file path and write the transformed image to a bitmap in the given location. We also have implemented synthesizable code for the camera interface, the VGA driver, and the dual-port BRAM buffer on the FPGA.

## Requirements 

### Hardware
![FPGA_Board](images/NexysA7-obl-600__85101.jpg)
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

4. Set the simulation time to be 6 seconds (Settings -> Simulation -> Simulation(within new window) -> xsim.simulate.runtime*).

5. Within the parameters.v file uncomment the transformation you would like to run and ensure that all other transformations are commented out.

6. Under the 'Simulation' select 'Run Simulation' then 'Run Behavioral Simulation'.

7. From here you can either wait for the simulation to complete or monitor the destination folder until the completed image appears. The simulation can take 5+ minutes but the completed image should appear within a minute.   

## System Architecture Overview
![overview](/images/551_overview_arch.png)
The system follows a pipeline structure. The camera captures the image before the pixel-wise downsampling module loads the image into the frame buffer. Parallelization is then utilized as two pixels at a time are transformed before the full image is passed through the VGA and displayed.

## Analysis

Overall, while our system is not fully implemented on the FPGA board, the simulation function can be utilized to generate images that have been transformed by up to 10 different functions as well as an encryption algorithm. Also, utilizing parallelization within the simulated transformations added additional complexity to the transformations, but should increase the speed of the process. The I/O modules have also been shown to synthesize and can be pushed to the FPGA board but the complete pipeline has not yet been pushed to the board.

### Video Details

## Youtube Link: https://www.youtube.com/watch?v=bjGYunQJUVM

## Google Drive Link: https://drive.google.com/file/d/1gATUr9Uhbika6bf0-_6tj3v25HJhlIn5/view

## Title: EC551 Image Transformations and Encryption

## Description:
The goal of this project was to implement a system that could carry out real-time image transformations and encryption on the Nexys-7 FPGA.

Our current system utilizes Vivado's simulation capabilities and system verilog to read in an image in hexcode from the given file path and write the transformed image to a bitmap in the given location. These transformations vary from grayscaling to blurring to encryption. We also have implemented synthesizable code for the camera interface, the VGA driver, and the dual-port BRAM buffer on the FPGA.
