% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/likelihood.R
\name{likelihood}
\alias{likelihood}
\title{Compute the loglikelihood of a model and data version of a model}
\usage{
likelihood(model_values, data_in)
}
\arguments{
\item{model_values}{input model_values - a dataframe with (at least) two columns:
1. value: the modeled flux value
2. join_key --> This allows us to connect it to the measured data}

\item{join_key}{The name of the variable we will join to flux_data}
}
\value{
logll of the measured an modeled data
}
\description{
\code{likelihood} Returns the likelihood of a modeled value
}
