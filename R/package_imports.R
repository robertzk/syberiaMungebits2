# Taken from arules

# arules::discretize
arules_discretize <- function (x, method = "interval", categories = 3, labels = NULL,
  ordered = FALSE, onlycuts = FALSE, ...) {
  methods = c("interval", "frequency", "cluster", "fixed")
  method <- methods[pmatch(tolower(method), methods)]
  if (is.na(method))
      stop("Unknown method!")
  res <- switch(method, interval = {
      categories <- seq(from = min(x, na.rm = TRUE), to = max(x,
          na.rm = TRUE), length.out = categories + 1)
      if (onlycuts) categories else arules_cut2(x, cuts = categories,
          oneval = FALSE, ...)
  }, frequency = arules_cut2(x, g = categories, onlycuts = onlycuts,
      ...), cluster = {
      cl <- stats::kmeans(stats::na.omit(x), categories, ...)
      centers <- sort(cl$centers[, 1])
      categories <- as.numeric(c(min(x, na.rm = TRUE), head(centers,
          length(centers) - 1) + diff(centers)/2, max(x, na.rm = TRUE)))
      if (onlycuts) categories else arules_cut2(x, cuts = categories,
          ...)
  }, fixed = {
      x[x < min(categories) | x > max(categories)] <- NA
      if (onlycuts) categories else arules_cut2(x, cuts = categories,
          ...)
  })
  if (onlycuts)
      return(res)
  if (ordered)
      res <- as.ordered(res)
  if (!is.null(labels))
      levels(res) <- labels
  res
}

# arules:::.cut2
arules_cut2 <- function (x, cuts, m = 150, g, levels.mean = FALSE, digits, minmax = TRUE, 
    oneval = TRUE, onlycuts = FALSE) {
    method <- 1
    x.unique <- sort(unique(c(x[!is.na(x)], if (!missing(cuts)) cuts)))
    min.dif <- min(diff(x.unique))/2
    min.dif.factor <- 1
    if (missing(digits)) 
        digits <- if (levels.mean) 
            5
        else 3
    oldopt <- options(digits = digits)
    on.exit(options(oldopt))
    xlab <- attr(x, "label")
    if (missing(cuts)) {
        nnm <- sum(!is.na(x))
        if (missing(g)) 
            g <- max(1, floor(nnm/m))
        if (g < 1) 
            stop("g must be >=1, m must be positive")
        options(digits = 15)
        n <- table(x)
        xx <- as.double(names(n))
        options(digits = digits)
        cum <- cumsum(n)
        m <- length(xx)
        y <- as.integer(ifelse(is.na(x), NA, 1))
        labs <- character(g)
        cuts <- stats::approx(cum, xx, xout = (1:g) * nnm/g, 
            method = "constant", rule = 2, f = 1)$y
        cuts[length(cuts)] <- max(xx)
        lower <- xx[1]
        upper <- 1e+45
        up <- low <- double(g)
        i <- 0
        for (j in 1:g) {
            cj <- if (method == 1 || j == 1) 
                cuts[j]
            else {
                if (i == 0) 
                  stop("program logic error")
                s <- if (is.na(lower)) 
                  FALSE
                else xx >= lower
                cum.used <- if (all(s)) 
                  0
                else max(cum[!s])
                if (j == m) 
                  max(xx)
                else if (sum(s) < 2) 
                  max(xx)
                else stats::approx(cum[s] - cum.used, xx[s], 
                  xout = (nnm - cum.used)/(g - j + 1), method = "constant", 
                  rule = 2, f = 1)$y
            }
            if (cj == upper) 
                next
            i <- i + 1
            upper <- cj
            y[x >= (lower - min.dif.factor * min.dif)] <- i
            low[i] <- lower
            lower <- if (j == g) 
                upper
            else min(xx[xx > upper])
            if (is.na(lower)) 
                lower <- upper
            up[i] <- lower
        }
        low <- low[1:i]
        up <- up[1:i]
        variation <- logical(i)
        for (ii in 1:i) {
            r <- range(x[y == ii], na.rm = TRUE)
            variation[ii] <- diff(r) > 0
        }
        if (onlycuts) 
            return(unique(c(low, max(xx))))
        flow <- format(low)
        fup <- format(up)
        bb <- c(rep(")", i - 1), "]")
        labs <- ifelse(low == up | (oneval & !variation), flow, 
            paste("[", flow, ",", fup, bb, sep = ""))
        ss <- y == 0 & !is.na(y)
        if (any(ss)) 
            stop(paste("categorization error in cut2.  Values of x not appearing in any interval:\n", 
                paste(format(x[ss], digits = 12), collapse = " "), 
                "\nLower endpoints:", paste(format(low, digits = 12), 
                  collapse = " "), "\nUpper endpoints:", paste(format(up, 
                  digits = 12), collapse = " ")))
        y <- structure(y, class = "factor", levels = labs)
    }
    else {
        if (minmax) {
            r <- range(x, na.rm = TRUE)
            if (r[1] < cuts[1]) 
                cuts <- c(r[1], cuts)
            if (r[2] > max(cuts)) 
                cuts <- c(cuts, r[2])
        }
        l <- length(cuts)
        k2 <- cuts - min.dif
        k2[l] <- cuts[l]
        y <- cut(x, k2)
        if (!levels.mean) {
            brack <- rep(")", l - 1)
            brack[l - 1] <- "]"
            fmt <- format(cuts)
            labs <- paste("[", fmt[1:(l - 1)], ",", fmt[2:l], 
                brack, sep = "")
            if (oneval) {
                nu <- table(cut(x.unique, k2))
                if (length(nu) != length(levels(y))) 
                  stop("program logic error")
                levels(y) <- ifelse(nu == 1, c(fmt[1:(l - 2)], 
                  fmt[l]), labs)
            }
            else levels(y) <- labs
        }
    }
    if (levels.mean) {
        means <- tapply(x, y, function(w) mean(w, na.rm = TRUE))
        levels(y) <- format(means)
    }
    attr(y, "class") <- "factor"
    if (length(xlab)) 
        names(y) <- xlab
    y
}

