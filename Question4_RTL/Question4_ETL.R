
# Question 4
# ETL using R and PostgreSQL

packages <- c(
  "rvest",
  "dplyr",
  "stringr",
  "readr",
  "tidyr",
  "DBI",
  "RPostgres"
)

missing_packages <- packages[
  !packages %in% rownames(installed.packages())
]

if (length(missing_packages) > 0) {
  install.packages(
    missing_packages,
    repos = "https://cloud.r-project.org"
  )
}

invisible(lapply(
  packages,
  library,
  character.only = TRUE
))

cat("All required libraries loaded successfully.\n")







# 4.1: Web Scraping

website_url <- "https://www.nasa.gov/blogs/"

# Connect to the web
webpage <- rvest::read_html(website_url)

page_title <- webpage |>
  rvest::html_element("title") |>
  rvest::html_text2()

cat("Website:", website_url, "\n")
cat("Page title:", page_title, "\n")

selectors <- c(
  "article",
  "main article",
  ".post",
  ".blog-post",
  "time"
)

for (selector in selectors) {
  count <- length(
    rvest::html_elements(webpage, selector)
  )
  
  cat(selector, ":", count, "elements\n")
}











# 4.1: Inspect NASA blog records

blog_articles <- rvest::html_elements(
  webpage,
  "main article"
)

cat("Articles on first page:",
    length(blog_articles), "\n")

for (i in seq_len(min(3, length(blog_articles)))) {
  
  cat("\nARTICLE", i, "\n")

  article_text <- rvest::html_text2(
    blog_articles[[i]]
  )
  
  cat("Text preview:\n")
  cat(substr(article_text, 1, 350), "\n")

  links <- rvest::html_elements(
    blog_articles[[i]],
    "a"
  )
  
  if (length(links) > 0) {
    cat("First link:",
        rvest::html_attr(links[[1]], "href"),
        "\n")
  }

  dates <- rvest::html_elements(
    blog_articles[[i]],
    "time"
  )
  
  if (length(dates) > 0) {
    cat("Publication date:",
        rvest::html_text2(dates[[1]]),
        "\n")
  }
}









# Check pagination to collect more records

page2_url <- "https://www.nasa.gov/blogs/page/2/"

page2 <- rvest::read_html(page2_url)

page2_articles <- rvest::html_elements(
  page2,
  "main article"
)

cat("Articles on page 1:",
    length(blog_articles), "\n")

cat("Articles on page 2:",
    length(page2_articles), "\n")

cat("Total articles found across both pages:",
    length(blog_articles) + length(page2_articles),
    "\n")








# 4.1: Extract 20 NASA blog records

library(rvest)
library(dplyr)
library(stringr)

# Reuse webpages already loaded
pages <- list(webpage, page2)

records <- list()

record_id <- 1

for (page_num in seq_along(pages)) {

  articles <- html_elements(
    pages[[page_num]],
    "main article"
  )
  
  for (article in articles) {

    card_text <- html_text2(article)

    links <- html_elements(article, "a")
    
    if (length(links) > 0) {
      title <- html_text2(links[[1]])
      article_url <- html_attr(links[[1]], "href")
      
      if (!is.na(article_url)) {
        article_url <- xml2::url_absolute(
          article_url,
          "https://www.nasa.gov"
        )
      }
    } else {
      title <- NA_character_
      article_url <- NA_character_
    }

    dates <- html_elements(article, "time")
    
    published <- if (length(dates) > 0) {
      html_text2(dates[[1]])
    } else {
      NA_character_
    }

    paragraphs <- html_elements(article, "p")
    
    paragraph_text <- html_text2(paragraphs)
    paragraph_text <- str_squish(paragraph_text)
    paragraph_text <- paragraph_text[
      nzchar(paragraph_text)
    ]
    
    excerpt <- if (length(paragraph_text) > 0) {
      paste(paragraph_text, collapse = " ")
    } else {
      NA_character_
    }

    word_count <- if (!is.na(excerpt)) {
      str_count(excerpt, "\\b[[:alpha:]]+\\b")
    } else {
      NA_integer_
    }

    records[[record_id]] <- data.frame(
      record_id = record_id,
      page_number = page_num,
      title_raw = title,
      published_raw = published,
      excerpt_raw = excerpt,
      article_url = article_url,
      word_count_raw = word_count,
      card_text_raw = card_text,
      stringsAsFactors = FALSE
    )
    
    record_id <- record_id + 1
  }
}

raw_news_df <- bind_rows(records)

cat("Total records:", nrow(raw_news_df), "\n")
cat("Total columns:", ncol(raw_news_df), "\n")

print(
  raw_news_df |>
    select(
      record_id,
      title_raw,
      published_raw,
      word_count_raw
    ),
  row.names = FALSE
)

# View the complete dataset
View(raw_news_df)






# Inspect the raw data

cat("Records:", nrow(raw_news_df), "\n")

cat("\nMissing values:\n")
print(colSums(is.na(raw_news_df)))

cat("\nDuplicate article URLs:\n")
print(sum(
  duplicated(raw_news_df$article_url) &
    !is.na(raw_news_df$article_url)
))

cat("\nWord count summary:\n")
print(summary(raw_news_df$word_count_raw))

cat("\nRecords per page:\n")
print(table(raw_news_df$page_number))





dir.create("output", showWarnings = FALSE)

write.csv(
  raw_news_df,
  "output/NASA_Blogs_Raw.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

cat("Raw dataset saved successfully.\n")





# 4.2. Data Cleaning and Transformation

library(dplyr)
library(stringr)

clean_text <- function(x) {
  x <- as.character(x)
  x <- str_replace_all(x, "[\r\n\t]+", " ")
  x <- str_squish(x)
  x[x == ""] <- NA_character_
  return(x)
}

clean_news_df <- raw_news_df |>
  mutate(
    title = clean_text(title_raw),
    excerpt = clean_text(excerpt_raw),
    published = clean_text(published_raw),
    article_url = clean_text(article_url),
 
    date_text = str_extract(
      published,
      "^[A-Za-z]+\\s+\\d{1,2},\\s*\\d{4}"
    ),

    publication_date = as.Date(
      date_text,
      format = "%B %d, %Y"
    ),

    excerpt_imputed = is.na(excerpt),
 
    excerpt = coalesce(excerpt, title),

    word_count = as.integer(
      str_count(
        coalesce(excerpt, ""),
        "\\b[[:alpha:]]+\\b"
      )
    )
  ) |>

  filter(
    !is.na(title),
    !is.na(article_url)
  ) |>

  distinct(article_url, .keep_all = TRUE) |>

  select(
    record_id,
    page_number,
    title,
    publication_date,
    excerpt,
    article_url,
    word_count,
    excerpt_imputed
  )

cat("Cleaned records:", nrow(clean_news_df), "\n")
cat("Cleaned columns:", ncol(clean_news_df), "\n")

View(clean_news_df)







# Validating the cleaned dataset

cat("Missing values after cleaning:\n")
print(colSums(is.na(clean_news_df)))

cat("\nDuplicate URLs:\n")
print(sum(duplicated(clean_news_df$article_url)))

cat("\nImputed excerpts:\n")
print(sum(clean_news_df$excerpt_imputed))

cat("\nPublication date range:\n")
print(range(clean_news_df$publication_date, na.rm = TRUE))

cat("\nWord count summary:\n")
print(summary(clean_news_df$word_count))

# show preview
print(
  clean_news_df |>
    select(
      record_id,
      title,
      publication_date,
      word_count
    ),
  row.names = FALSE
)









# Export data

write.csv(
  clean_news_df,
  "output/NASA_Blogs_Cleaned.csv",
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

cat("Cleaned dataset exported successfully.\n")
