# docker_disperser

`disperseR` is an R package that runs [HYSPLIT](https://ready.arl.noaa.gov/HYSPLIT.php) many times and calculates the HYSPLIT Average Dispersion (or HyADS) exposure metric.

The [audiracmichelle/disperser](https://hub.docker.com/r/audiracmichelle/disperser) image has Rstudio and all the R and unix dependencies already installed to run `disperseR` quickly and reliably. The image is based on rocker project (<https://www.rocker-project.org/>). 

In a `bash` or `sh` terminal, you can run the image directly from dockerhub using

    docker run -p 8787:8787 -e ROOT=true -e DISABLE_AUTH=true -v $(pwd):/home/rstudio/kitematic/ audiracmichelle/disperser

Or you can build the image using the Dockerfile found in this github repository and then run the container from the local image.

    docker build -t disperser .
    docker run -p 8787:8787 -e ROOT=true -e DISABLE_AUTH=true -v $(pwd):/home/rstudio/kitematic/ disperser

Once the container is running, point your browser to `localhost:8787` and enjoy `disperseR` through your dockerized connection to Rstudio\!

Make sure to run the container from your working directory (the location where your disperseR Rstudio project or the R files you are working with are saved. `$(pwd):/home/rstudio/kitematic/` allows to sync the local volume with the container’s volume.

In a Windows terminal the function `pwd` (print working directory) will not work. Instead fix the local volume using the location of the host machine on the left side of `:` by substituting `LOCATION` with your working directory.

```{}
docker run -p 8787:8787 -e ROOT=true -e DISABLE_AUTH=true -v C:\Users\LOCATION:/home/rstudio/ audiracmichelle/disperser
```

More information on `disperseR` docker image is found in its DockerHub site [https://hub.docker.com/r/audiracmichelle/disperser](https://hub.docker.com/r/audiracmichelle/disperser).
