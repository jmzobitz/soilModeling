% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/run_MCMC.R
\name{run_MCMC}
\alias{run_MCMC}
\title{Do a metropolis chain}
\usage{
run_MCMC(param_file_name, model_in, data_in, join_key, results_file_name,
  out_file_name, mcmc_parameters)
}
\arguments{
\item{param_file_name}{file name (as a string) of where the default parameters are located}

\item{model_in}{the name of the model we are using}

\item{data_in}{input data we use to compare in the likelihood function.}

\item{join_key}{The name of the variable we will join to data_in when doing likelihood}

\item{results_file_name}{The file name (as a string) where the final MCMC results will be stored.}

\item{out_file_name}{The file name (as a string) where we log various info as the mcmc proceeds}

\item{mcmc_parameters}{a data frame of how we want to estimate (can be mcmc_superfast or mcmc_defaults)}
}
\description{
\code{run_MCMC} Does a complete MCMC parameter estimation
}
