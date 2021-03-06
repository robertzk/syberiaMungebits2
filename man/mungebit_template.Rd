% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mungebit_template.R
\name{mungebit_template}
\alias{mungebit_template}
\title{Create a mungebit template from an expression.}
\usage{
mungebit_template(expression)
}
\arguments{
\item{expression}{expression. An R expression containing potentially
local variables \code{train} or \code{predict} indicating the train
and predict function for the mungebit to be created.}
}
\value{
A zero-argument function that produces the mungebit given by
  the expression.
}
\description{
The format here is similar to the format required for specifying
a mungebit as a resource in a
\href{http://github.com/syberia/modeling.sy}{syberia modeling project}.
}
\details{
The returned mungebit template is a zero-argument function that
produces an untrained mungebit given by the expression.

The expression passed in can specify local variables \code{train} or
\code{predict} indicating the train and predict function for the
mungebit, respectively, as well as set \code{column_transformation} 
to \code{TRUE} to specify they are column transformations.
}
