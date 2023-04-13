# r-rstudio-ide-integration

## Introduction

This repo would like to help with the integration of R with the RStudio IDE and solve/address the following issues

* By default, any R installation only contains `base` and `recommended` package. Any additional package needed for the IDE integration (e.g. `rmarkdown`, `shiny`, ...) needs to be installed by the user upon first using the IDE. Those packages will typically installed into the user's home-directory. On systems with a large user base this can lead to quite a bit of storage consumption. The approach in this repository pre-installs all needed packages for the IDE integration into an additional site library
* For a given R version and as time progresses, newer versions of R packages can become incompatible with an older R version. In order to prevent this from happen, we are using a time-based snapshot of the CRAN repository where the time is 60 days after the corresponding R version was released (if no snapshot exists for the date, a bckwards search is started until a snapshot is found). While this may not allow the installation of the latest version of a package without additional effort, the risk of incompatibilities is greatly reduced. In addition this approach significantly increases the reproducibility of R codes given the fact that package versions are now fixed as per the time-based snapshot. 
* Since `rJava` typically can be challenging to install, in this repo we also provide a consistent way of configuring `rJava` to work with the system provided `JAVA` installation (cf. [solutions.posit.co](https://solutions.posit.co/envs-pkgs/using-rjava/index.html#setup-java-support-in-r))
* The posit provided docker images for `workbench` and `r-session-complete` are typically way behind in terms of the latest available R version. Furthermore it is not always the latest version that is made the default version. In this repo we also show a way on how users can easily add their own desired R versions. This is achieved by programmatically removing any existing R versions and only installing the ones provided by the user
* Every R version will also be configured to directly use the appropriate R binaries suited for the Linux distribution chosen. By default Public Posit Package Manager is used, but users with local Package Managers can change the URL in line 30 of `run.R`.
* Lastly, for users that are still on CentOS/RHEL 7, we also provide a way to make use of the later compiler versions provided by [Red Hat Developer Toolset 11](https://access.redhat.com/documentation/en-us/red_hat_developer_toolset/11/html/11.0_release_notes/index).

## How to use this repo

You will find the Dockerfiles in the `dockerfiles` subdirectory for Ubuntu 18.04 LTS (Bionic), 22.04 LTS (Jammy) and Centos/RHEL 7. They are currently configured against `r-sessions-complete` version 2022.12.0. This can be easily changed by editing the first line in the respective Dockerfile. 

If you wanted to use `r-session-complete:bionic-2022.12.0` and activate R Versions 4.0.5, 4.1.3 and 4.2.3 and add all the aforementioned things, you would run 

```
cd dockerfiles
docker build --build-arg R_VERSIONS="4.0.5 4.1.3 4.2.3" . -f Dockerfile.bionic
```

The last mentioned R version (4.2.3 in this case) will be the default version. 

## A separate note on the preinstallation R packages needed for the RStudio IDE integration

With the setting of time-based snapshots to 60 days after the R version was officially released, for some older versions the IDE may still try to force updates of some packages. This can be avoided by setting

```
RSTUDIO_DISABLE_PACKAGE_INSTALL_PROMPT=yes
```

This setting can be defined in `rsession-profile` or similar files. It will disable the check if package is installed and also disable the attempt to update the packages if the IDE demands it. 

For all tests done so far with extremely old R versions and packages older than the IDE would want update to, no issue/problem with this approach could be found. 

More details in the [Workbench Admin guide](https://docs.posit.co/ide/server-pro/rstudio_pro_sessions/package_installation.html#installations-and-upgrades-automated-by-rstudio-pro-ide).



