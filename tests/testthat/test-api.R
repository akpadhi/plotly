context("api")

test_that("api() returns endpoints", {
  skip_on_cran()
  
  res <- api()
  expect_true(length(res) > 1)
  expect_true(all(c("plots", "grids", "folders") %in% names(res)))
})

test_that("Can search with white-space", {
  skip_on_cran()
  
  res <- api("search?q=overdose drugs")
  expect_true(length(res) > 1)
})

test_that("Changing a filename works", {
  skip_on_cran()
  
  id <- plotly:::new_id()
  f <- api("files/cpsievert:14680", "PATCH", list(filename = id)) 
  expect_equivalent(f$filename, id)
})


test_that("Downloading plots works", {
  skip_on_cran()
  
  # https://plot.ly/~cpsievert/200
  p <- api_download_plot(200, "cpsievert")
  expect_is(p, "htmlwidget")
  expect_is(p, "plotly")
  
  l <- plotly_build(p)$x
  expect_length(l$data, 1)
  
  # This file is a grid, not a plot https://plot.ly/~cpsievert/14681
  expect_error(
    api_download_plot(14681, "cpsievert"), "grid"
  )
})


test_that("Downloading grids works", {
  skip_on_cran()
  
  g <- api_download_grid(14681, "cpsievert")
  expect_is(g, "api_file")
  expect_is(
    tibble::as_tibble(g$preview), "data.frame"
  )
  
  # This file is a plot, not a grid https://plot.ly/~cpsievert/14681
  expect_error(
    api_download_grid(200, "cpsievert"), "plot"
  )
})


test_that("Creating produces a new file by default", {
  skip_on_cran()
  
  expect_new <- function(obj) {
    old <- api("folders/home?user=cpsievert")
    new_obj <- api_create(obj)
    Sys.sleep(3)
    new <- api("folders/home?user=cpsievert")
    n <- if (plotly:::is.plot(new_obj)) 2 else 1
    expect_equivalent(old$children$count + n, new$children$count)
  }
  
  expect_new(mtcars)
  # even if plot has multiple traces, only one grid should be created
  p1 <- plot_ly(mtcars, x = ~mpg, y = ~wt)
  p2 <- add_markers(p1, color = ~factor(cyl))
  p3 <- add_markers(p1, color = ~factor(cyl), frame = ~factor(vs))
  expect_new(p1)
  expect_new(p2)
  expect_new(p3)
})


test_that("Can overwrite a grid", {
  skip_on_cran()
  
  id <- new_id()
  m <- api_create(mtcars, id)
  m2 <- api_create(iris, id)
  expect_true(identical(m$embed_url, m2$embed_url))
  expect_false(identical(m$cols, m2$cols))
})

test_that("Can overwrite a plot", {
  skip_on_cran()
  
  id <- new_id()
  p <- plot_ly()
  m <- api_create(p, id)
  m2 <- api_create(layout(p, title = "test"), id)
  expect_true(identical(m$embed_url, m2$embed_url))
  expect_false(identical(m$figure$layout$title, m2$figure$layout$title))
})

test_that("Can create plots with non-trivial src attributes", {
  skip_on_cran()
  
  # can src-ify data[i].marker.color
  p <- plot_ly(x = 1:10, y = 1:10, color = 1:10)
  res <- api_create(p)
  m <- res$figure$data[[1]]$marker
  expect_length(strsplit(m$colorsrc, ":")[[1]], 3)
  
  # can src-ify frames[i].data[i].marker.color
  res <- p %>% 
    add_markers(frame = rep(1:2, 5)) %>%
    api_create()
  m <- res$figure$frames[[1]]$data[[1]]$marker
  expect_length(strsplit(m$colorsrc, ":")[[1]], 3)
  
  # can src-ify layout.xaxis.tickvals
  res <- api_create(qplot(1:10))
  ticks <- res$figure$layout$xaxis$tickvalssrc
  expect_length(strsplit(ticks, ":")[[1]], 3)
  
})



