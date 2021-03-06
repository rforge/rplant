RAxML <- function(file.name, file.path="", type="DNA", out.name=NULL, 
                  model=NULL, bootstrap=NULL, algorithm="d", rseed=NULL,
                  multipleModelFileName=NULL, args=NULL, numcat=25, nprocs=12,
                  job.name=NULL, print.curl=FALSE, shared.username=NULL, 
                  substitution_matrix=NULL, empirical.frequencies=FALSE,
                  suppress.Warnings=FALSE, email=TRUE) {

  type <- match.arg(type, c("DNA", "PROTEIN"))
      
  if (type == "DNA"){

    if (is.null(model)){
      model="GTRCAT"
    }

    model <- match.arg(model, c("GTRCAT", "GTRGAMMA", "GTRCATI", "GTRGAMMAI"))

  } else {

    if (!is.null(substitution_matrix)){
      substitution_matrix  <- match.arg(substitution_matrix, c("DAYHOFF", "DCMUT", "JTT", "MTREV", "WAG", "RTREV", "CPREV", "VT", "BLOSUM62", "MTMAM", "LG", "MTART", "MTZOA", "PMB", "HIVB", "HIVW", "JTTDCMUT", "FLU", "GTR"))
    }

    if (is.null(model)){
      if (empirical.frequencies==FALSE){
        if (is.null(substitution_matrix)){
          model="PROTCATBLOSUM62"
          other.models <- c("PROTCATBLOSUM62", "PROTGAMMABLOSUM62", "PROTCATIBLOSUM62", "PROTGAMMAIBLOSUM62")
        } else {
          model=paste("PROTCAT", substitution_matrix, sep="")
          other.models <- c(paste("PROTCAT", substitution_matrix, sep=""), paste("PROTGAMMA", substitution_matrix, sep=""), paste("PROTCATI", substitution_matrix, sep=""), paste("PROTGAMMAI", substitution_matrix, sep=""))
        }
      } else {
        if (is.null(substitution_matrix)){
          model="PROTCATBLOSUM62F"
          other.models <- c("PROTCATBLOSUM62F", "PROTGAMMABLOSUM62F", "PROTCATIBLOSUM62F", "PROTGAMMAIBLOSUM62F")
        } else {
          model=paste("PROTCAT", substitution_matrix, "F", sep="")
          other.models <- c(paste("PROTCAT", substitution_matrix, "F", sep=""), paste("PROTGAMMA", substitution_matrix, "F", sep=""), paste("PROTCATI", substitution_matrix, "F", sep=""), paste("PROTGAMMAI", substitution_matrix, "F", sep=""))
        }
      }
    } else {
      if (empirical.frequencies==FALSE){
        if (is.null(substitution_matrix)){
          model=paste(model, "BLOSUM62", sep="")
          other.models <- c("PROTCATBLOSUM62", "PROTGAMMABLOSUM62", "PROTCATIBLOSUM62", "PROTGAMMAIBLOSUM62")
        } else {
          model=paste(model, substitution_matrix, sep="")
          other.models <- c(paste("PROTCAT", substitution_matrix, sep=""), paste("PROTGAMMA", substitution_matrix, sep=""), paste("PROTCATI", substitution_matrix, sep=""), paste("PROTGAMMAI", substitution_matrix, sep=""))
        }
      } else {
        if (is.null(substitution_matrix)){
          model=paste(model, "BLOSUM62F", sep="")
          other.models <- c("PROTCATBLOSUM62F", "PROTGAMMABLOSUM62F", "PROTCATIBLOSUM62F", "PROTGAMMAIBLOSUM62F")
        } else {
          model=paste(model, substitution_matrix, "F", sep="")
          other.models <- c(paste("PROTCAT", substitution_matrix, "F", sep=""), paste("PROTGAMMA", substitution_matrix, "F", sep=""), paste("PROTCATI", substitution_matrix, "F", sep=""), paste("PROTGAMMAI", substitution_matrix, "F", sep=""))
        }
      }
    }

    model <- match.arg(model, other.models)

  }

  if (rplant.env$api == "a") {
 #   version="RAxML-8.1.17"
    priv.APP=TRUE
    version="raxml-gamma-8.1.17"
    App <- GetAppInfo(version)[[3]]
    input.list <- vector("list",1)
    input.list[[1]] <- App[,2][1]
#    input.list[[1]] <- "inname"
   
    #initialize arguments
    options <- c(args)
    args <- NULL
    args <- append(args, list(c("model", model)))
    args <- append(args, list(c("N", 10)))
    args <- append(args, list(c("threads", nprocs)))
  
    if (is.null(rseed)){
      args <- append(args, list(c("p", floor(runif(1, 1, 10^6)))))
    } else {
      args <- append(args, list(c("p", rseed)))
    }

    if (!is.null(out.name)){
      args <- append(args, list(c("outname", out.name)))
    } else {
      args <- append(args, list(c("outname", "nwk")))
    }

    if (!is.null(bootstrap)) {
      options <- append(options, c("-b", bootstrap))
    }
    options <- append(options, c("-f", algorithm))
    #options <- append(options, c("-#", numberOfRuns))
    options <- append(options, c("-c", numcat))
  
    if(!is.null(multipleModelFileName)) {
      options <- append(options, c("-q", multipleModelFileName))
    }
    options <- paste(options, collapse=" ")  # make a single statement
   
    args <- append(args, list(c("options", options)))
  
  } else {
    version="raxml-lonestar-7.2.8u1"

    App <- GetAppInfo(version)[[3]]
    input.list <- vector("list",1)
    input.list[[1]] <- App[,2][1]
  
    #initialize arguments
    args <- c(args)
    args <- append(args, c("-m", model))
    args <- append(args, c("-N", 10))
    args <- append(args, c("-T", nprocs))
    if (!is.null(bootstrap)) {
      args <- append(args, c("-b", bootstrap))
    }
    args <- append(args, c("-f", algorithm))
    if (is.null(rseed)){
      args <- append(args, c("-p", floor(runif(1, 1, 10^6))))
    } else {
      args <- append(args, c("-p", rseed))
    }
    #args <- append(args, c("-#", numberOfRuns))
    args <- append(args, c("-c", numcat))

    if (!is.null(out.name)){
      args <- append(args, c("-n", out.name))
    } else {
      args <- append(args, c("-n", "nwk"))
    }
    
    if(!is.null(multipleModelFileName)) {
      args <- append(args, c("-q", multipleModelFileName))
    }
    args <- paste(args, collapse=" ")  # make a single statement
   
    args <- list(c("arguments", args))
  }

  if (is.null(job.name)){
#   job.name <- paste(rplant.env$user, "_RAxMLprotein_", model, "_viaR", sep="")
    job.name <- version
  }

  # Submit
  myJob<-SubmitJob(application=version, job.name=job.name, nprocs=nprocs,
                   file.list=list(file.name), file.path=file.path, 
                   input.list=input.list, suppress.Warnings=suppress.Warnings,
                   print.curl=print.curl, shared.username=shared.username,
                   args.list=args, email=email, private.APP=TRUE)
  return(myJob)
}
