# Summary

Sometimes in a CTF I land on an ubuntu box and need to compile an exploit. I've had trouble before doing so from a kali host so in the past I spun up an ubuntu docker to compile the code. This automates that procedure. The `Dockerfile` pulls the `ubuntu:latest` image and installs nano and gcc. `start.sh` builds the Dockerfile tagging it as `dockercompile:latest` then runs it in detached mode and mounts the current directory into `/volume` inside the container. So you can write the code in the current directory on the host and compile using the container's gcc from the command line on the host or you can hop inside the container.

# Example
On my host I ran `./start.sh` to create the `dockercompile:latest` container

<img src="images/dockerps.png">

I'll grab the `CONTAINER ID`

<img src="images/dockerid.png">

On the host I have a hello world C program

<img src="images/testcat.png">

The current directory is mapped to `/volume` in the container so it's there as well

<img src="images/volume.png">

From the command line I'll compile the code

<img src="images/compile.png">

Check it works

<img src="images/helloworld.png">
