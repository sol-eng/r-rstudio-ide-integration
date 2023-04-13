# Needs to be run as an admin that has write permissions to /etc/rstudio
# 
# This script when run against any R version will 
# * figure out which compatible BioConductor Version exist
# * get all the URLs for the repositories of BioConductor
# * Add CRAN  
#       into files in /etc/rstudio/repos/repos-x.y.z.conf
# * add entries into /etc/rstudio/r-versions to define the respective 
#       R version (x.y.z) and point to the repos.conf file  
# * update Rprofile.site with the same repository informations 
# * install all needed R packages for Workbench to work and add them 
#       in a separate .libPath()
# * auto-detect which OS it is running on and add binary package support


binaryflag<-""

if(file.exists("/etc/debian_version")) {
    binaryflag <- paste0("__linux__/",system(". /etc/os-release && echo $VERSION_CODENAME", intern = TRUE),"/")
}

if(file.exists("/etc/redhat-release")) {
    binaryflag <- paste0("__linux__/centos",system(". /etc/os-release && echo $VERSION_ID", intern = TRUE),"/")
}

currver <- paste0(R.Version()$major,".",R.Version()$minor)

libdir <- paste0("/opt/R/rstudio-ide-integration/",currver)

pmurl <- "https://packagemanager.rstudio.com"

if(dir.exists(libdir)) {unlink(libdir,recursive=TRUE)}
dir.create(libdir,recursive=TRUE)
.libPaths(libdir)

if(dir.exists("/tmp/curl")) {unlink("/tmp/curl",recursive=TRUE)}
dir.create("/tmp/curl")
install.packages(c("rjson","RCurl"),"/tmp/curl", repos=paste0(pmurl,"/cran/",binaryflag,"latest"))
library(RCurl,lib.loc="/tmp/curl")
library(rjson,lib.loc="/tmp/curl")

pnames=c("DBI", "R6", "RJDBC", "RODBC", "RSQLite", "Rcpp", "base64enc", "checkmate", "crayon", "commonmark", "curl", "devtools", "digest", "evaluate", "ellipsis", "fastmap", "glue", "haven", "highr", "htmltools", "htmlwidgets", "httpuv", "jsonlite", "keyring", "knitr", "later", "learnr", "lifecycle", "magrittr", "markdown", "mime", "miniUI", "mongolite", "odbc", "openssl", "packrat", "plumber", "png", "profvis", "promises", "r2d3", "ragg", "rappdirs", "rJava", "readr", "readxl", "renv", "reticulate", "rlang", "rmarkdown", "roxygen2", "rprojroot", "rsconnect", "rstan", "rstudioapi", "shiny", "shinytest", "sourcetools", "stringi", "stringr", "testthat", "tinytex", "withr", "xfun", "xml2", "xtable", "yaml")

jsondata<-fromJSON(file="https://raw.githubusercontent.com/rstudio/rstudio/main/src/cpp/session/resources/dependencies/r-packages.json")
pnames<-c()
for (feature in jsondata$features) { pnames<-unique(c(pnames,feature$packages)) }

currver <- paste0(R.Version()$major,".",R.Version()$minor)
paste("version",currver)

#Start with a starting date for the time-based snapshot 60 days past the R release
releasedate <- as.Date(paste0(R.version$year,"-",R.version$month,"-",R.version$day))+60
paste("release", releasedate)
 
#Attempt to install packages from snapshot - if snapshot does not exist, decrease day by 1 and try again
getreleasedate <- function(repodate){
  
  repo=paste0(pmurl,"/cran/",binaryflag,repodate)
  paste(repo)
  URLfound=FALSE
  while(!URLfound) {
   if (!RCurl::url.exists(paste0(repo,"/src/contrib/PACKAGES"),useragent="curl/7.39.0 Rcurl/1.95.4.5")) {
	repodate<-as.Date(repodate)-1
        paste(repodate)
        repo=paste0(pmurl,"/cran/",repodate)
   } else {
   URLfound=TRUE
   }
 }
 return(repodate)
}

releasedate <- getreleasedate(as.Date(releasedate))

#Final CRAN snapshot URL
repo=paste0(pmurl,"/cran/",binaryflag,releasedate)

avpack<-available.packages(paste0(repo,"/src/contrib"))

#Install all packages needed for RSW
install.packages(pnames[pnames %in% avpack],repos=repo,libdir)

#We are setting both CRAN and RSPM to the same repo in order to ensure that no external repo is being used. 
r<-options()$repos
r["CRAN"]<-repo
r["RSPM"]<-repo
options(repos=r)

# Populate r-versions and repos config for RSW
rverstring=paste0(R.version$major,".",R.version$minor)
 
system("mkdir -p /etc/rstudio/repos")
filename=paste0("/etc/rstudio/repos/repos-",rverstring,".conf")
sink(filename)
for (i in names(r)) {cat(noquote(paste0(i,"=",r[i],"\n"))) }
sink()

x<-unlist(strsplit(R.home(),"[/]"))
r_home<-paste0(x[2:length(x)-2],"/",collapse="")

sink("/etc/rstudio/r-versions", append=TRUE)
cat("\n")
cat(paste0("Path: ",r_home,"\n"))
cat(paste0("Label: R","\n"))
cat(paste0("Repo: ",filename,"\n"))
cat(paste0("Script: /opt/R/",rverstring,"/lib/R/etc/ldpaths \n"))
cat("\n")
sink()

sink(paste0("/opt/R/",rverstring,"/lib/R/etc/Rprofile.site"),append=TRUE)
if ( rverstring < "4.1.0" ) {
  cat('.env = new.env()\n')
}
cat('local({\n')
cat('r<-options()$repos\n')
for (line in names(r)) {
   cat(paste0('r["',line,'"]="',r[line],'"\n'))
}
cat('options(repos=r)\n') 

cat(paste0('.libPaths(c(.libPaths(),"',libdir,'"))\n'))
if ( rverstring < "4.1.0" ) {
cat('}, envir = .env)\n')
cat('attach(.env)\n')
} else {
cat('})\n')
}
sink()
