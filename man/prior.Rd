% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/prior.R
\name{prior}
\alias{prior}
\title{Return the prior value of a parameter set}
\usage{
prior(param)
}
\arguments{
\item{param}{input parameter vector - is a data frame with the following columns:
1. name
2. changeable
3. value
4. minVal
5.}
}
\value{
Prior probability density
}
\description{
\code{prior} Returns the prior probability of a parameter set
}
