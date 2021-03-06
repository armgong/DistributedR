\name{deploy.model}
\alias{deploy.model}
\title{Deploy model in Vertica}

\description{ deploy.model is an API to save a model created in R or Distributed R in a Vertica database.
}

\usage{
   deploy.model(model, dsn, modelName, modelComments="", localTmpFilePath = '/tmp')
}

\arguments{
  \item{model}{
    a model created in R or Distributed R which user wants to save in database.
    Currently, regression, kmeans, random forest, and gbm models are supported.
  }
  \item{dsn}{
    Data Source Name(DSN) as provided in ODBC.INI file to connect to Vertica database.
  }
  \item{modelName}{
    name as which {\link{model}} will be saved in the database. modelName can contain letters, numebers and underscore(_)
    and can have a maximum length of 256 characters.
  }
  \item{modelComments}{
    optional argument to add description about the model. It is empty by default. modelComments 
    can have a maximum length of 2048 characters.
  }
  \item{localTmpFilePath}{
    optional argument to specify the location where intermediate, temporary files can be created. It is 'tmp' by default.
  }
}

\details{
  \code{\link{deploy.model}} coverts the model in serialized ASCII format and then saves
  in a Vertica database used in Data Source Name(\code{\link{dsn}}). The models saved in Vertica 
  using this function can be looked up by querying public.R_model table in Vertica. 

  deploy.model supports regression, kmeans, random forest, and gbm models as of now.
  It is suggested to deploy a model which does not have attributes which are 
  distributed objects -\code{\link{darray}}, \code{\link{dframe}}, \code{\link{dlist}}
  as it may cause issues while reading the models in the database.
}

\value{
   No value is returned
}

\author{HP Vertica Development Team}

\note{
%%  ~~further notes~~
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\examples{
\dontrun{
library(distributedR)
distributedR_start()
Y <- as.darray(as.matrix(faithful$eruptions),c(ceiling(length(faithful$eruption)/4),1))
X <- as.darray(as.matrix(faithful$waiting),c(ceiling(length(faithful$waiting)/4),1))
myModel <- hpdglm(responses=Y, predictors=X, family= gaussian(link=identity))
deploy.model(myModel, "vertica_dsn", "Kmeans_model", "Created on faithful dataset")
distributedR_shutdown()
}
}

