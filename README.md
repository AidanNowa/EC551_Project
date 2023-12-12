# EC551_Project
## Team ASMR - Image Processing on FPGA

### Project Goal

Implement a system that could carry out real-time image transformations and encryption on the Nexys-7 FPGA.

Our current system utilizes Vivado's simulation capabilities and system verilog to read in an image in hexcode from the given file path and write the transformed image to a bitmap in the given location. We also have implemented synthesizable code for the camera interface, the VGA driver, and the dual-port BRAM buffer on the FPGA.

## Requirements 

OV7670 camera ([480x640p RGB565 output](https://www.amazon.com/HiLetgo-OV7670-640x480-0-3Mega-Arduino/dp/B07S66Y3ZQ))
          
Nexys A7 Artix-7 FPGA (https://digilent.com/shop/nexys-a7-fpga-trainer-board-recommended-for-ece-curriculum/)

