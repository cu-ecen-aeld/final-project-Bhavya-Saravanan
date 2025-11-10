# ECEN 5713 AESD Fall 2025 Final Project



## Project Overview



[Project Overview Link](https://github.com/VrushabhGadaCU/final-project-assignment-OTA-SecureBoot/wiki)



## Project Schedule



[Project Schedule Link](https://github.com/users/VrushabhGadaCU/projects/2/views/1)

## Sprint 1 Update (My Work)

In this sprint, my focus was on setting up the backend required for the OTA update workflow. I worked on creating and verifying our AWS S3 server where the firmware images will be stored for remote updates.

What I completed:

-> Created the S3 bucket and configured access permissions.

-> Uploaded a sample firmware/text file to test the setup.

-> Verified the download from AWS using curl to ensure the Raspberry Pi will be able to access it later.

![](aws_setup_verification.jpg)

I also spent time understanding how the OTA process will run end-to-end. Specifically, I looked into the A/B partitioning method where:

-> The newly downloaded firmware is written to the inactive partition,

-> The boot configuration is updated,

-> And the board reboots into the new firmware, with rollback support if the boot fails.

Right now, I am waiting for my teammate to finish building the Yocto image for the Raspberry Pi. Once that image is ready, I’ll begin writing the OTA update script to:

1. Download the image from AWS,

2. Flash it to the alternate partition,

3. Update boot parameters,

4. And trigger a safe reboot.

As planned, my Sprint-1 goal is successfully achieved.
The server setup and OTA workflow understanding are complete, and I’m ready for the next phase once the image is available.


## Summary:

 -> Server & file hosting + testing completed

 ->  OTA mechanism studied and planned

 -> Awaiting final Yocto image from teammate to continue with OTA implementation in Sprint-2