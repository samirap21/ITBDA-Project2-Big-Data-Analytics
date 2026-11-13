
# WebText API and Text Summarisation

packages <- c(
  "rvest",
  "dplyr",
  "stringr",
  "tidytext",
  "ggplot2",
  "stopwords",
  "igraph"
)

# Install packages
missing_packages <- packages[
  !packages %in% rownames(installed.packages())
]

if (length(missing_packages) > 0) {
  install.packages(
    missing_packages,
    repos = "https://cloud.r-project.org"
  )
}

# Load packages
library(rvest)
library(dplyr)
library(stringr)
library(tidytext)
library(ggplot2)
library(stopwords)
library(igraph)

cat("All required libraries loaded successfully.\n")


# Question 3.1: Website access

website_url <- paste0(
  "https://science.nasa.gov/climate-change/",
  "what-is-climate-change/"
)

webpage <- rvest::read_html(website_url)

# Extract heading
article_title <- webpage |>
  html_element("h1") |>
  html_text2()

cat("Website:", website_url, "\n")
cat("Article title:", article_title, "\n")

main_paragraphs <- webpage |>
  html_elements("main p") |>
  html_text2()

article_paragraphs <- webpage |>
  html_elements("article p") |>
  html_text2()

cat("Main paragraph elements:",
    length(main_paragraphs), "\n")

cat("Article paragraph elements:",
    length(article_paragraphs), "\n")








# 3.1. Create a structured data frame

extracted_text <- trimws(article_paragraphs)

extracted_text <- extracted_text[nzchar(extracted_text)]
web_text_df <- data.frame(
  paragraph_id = seq_along(extracted_text),
  content = extracted_text,
  source_url = rep(website_url, length(extracted_text)),
  stringsAsFactors = FALSE
)

# Display the results
cat("Number of paragraphs:", nrow(web_text_df), "\n")
cat("Number of columns:", ncol(web_text_df), "\n")

print(head(web_text_df[, c("paragraph_id", "content")], 5))
View(web_text_df)







# Save the original data
write.csv(
  web_text_df,
  "NASA_Raw_WebText.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

cat("Original web data saved successfully.\n")






# Review the extracted data before cleaning

paragraph_review <- data.frame(
  paragraph_id = web_text_df$paragraph_id,
  character_count = nchar(web_text_df$content),
  text_preview = substr(
    gsub("\\s+", " ", web_text_df$content),
    1,
    180
  )
)

print(
  paragraph_review,
  row.names = FALSE,
  right = FALSE
)







# 3.2: Remove website-related noise

article_df <- web_text_df |>
  dplyr::filter(paragraph_id %in% 1:8) |>
  dplyr::select(paragraph_id, content, source_url)

article_df <- article_df |>
  dplyr::mutate(
    content = stringr::str_squish(content)
  )

cat("Original paragraphs:", nrow(web_text_df), "\n")
cat("Retained article paragraphs:", nrow(article_df), "\n")
cat("Removed paragraphs:",
    nrow(web_text_df) - nrow(article_df), "\n")

# Display the retained text
View(article_df)







# Review excluded paragraph from the main article

for (i in 9:nrow(web_text_df)) {
  cat(
    "\nParagraph", i, ":\n",
    substr(web_text_df$content[i], 1, 220),
    "\n"
  )
}






# Check remaining paragraphs

for (i in 19:22) {
  cat("\nParagraph", i, ":\n")
  cat(web_text_df$content[i], "\n")
}







# 3.2: Text cleaning and preprocessing

article_df <- web_text_df |>
  dplyr::filter(paragraph_id %in% 1:8) |>
  dplyr::mutate(
    content = stringr::str_squish(content)
  )

tokens_df <- article_df |>
  dplyr::select(paragraph_id, content) |>
  tidytext::unnest_tokens(word, content)

tokens_df <- tokens_df |>
  dplyr::filter(
    stringr::str_detect(word, "^[a-z]{3,}$")
  )

tokens_df <- tokens_df |>
  dplyr::filter(
    !word %in% stopwords::stopwords("en")
  )

clean_paragraphs <- tokens_df |>
  dplyr::group_by(paragraph_id) |>
  dplyr::summarise(
    clean_content = paste(word, collapse = " "),
    .groups = "drop"
  )

clean_web_df <- article_df |>
  dplyr::left_join(
    clean_paragraphs,
    by = "paragraph_id"
  ) |>
  dplyr::mutate(
    clean_content = dplyr::coalesce(clean_content, "")
  )

# Display cleaned data
print(clean_web_df[, c("paragraph_id", "clean_content")])

cat("Retained paragraphs:", nrow(clean_web_df), "\n")
cat("Cleaned word tokens:", nrow(tokens_df), "\n")

View(clean_web_df)


write.csv(
  clean_web_df,
  "NASA_Cleaned_WebText.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

cat("Cleaned dataset saved successfully.\n")




# 3.3: Text Summarisation
# 1. Frequency-Based Extractive Summarisation

# original article into sentences
sentences_df <- article_df |>
  dplyr::select(paragraph_id, content) |>
  tidytext::unnest_tokens(
    sentence,
    content,
    token = "sentences",
    to_lower = FALSE
  ) |>
  dplyr::mutate(
    sentence = stringr::str_squish(sentence)
  ) |>
  dplyr::filter(nchar(sentence) >= 30) |>
  dplyr::mutate(
    sentence_id = dplyr::row_number()
  )

cat("Total sentences:", nrow(sentences_df), "\n")

# Display extracted sentences
print(sentences_df)



# Calculate frequencies
word_freq <- tokens_df |>
  dplyr::count(
    word,
    name = "frequency",
    sort = TRUE
  )

# Display most frequent words
cat("Top 15 most frequent words:\n")
print(head(word_freq, 15))








# Tokenise sentences and calculate their importance

sentence_scores <- sentences_df |>
  dplyr::select(sentence_id, sentence) |>
  tidytext::unnest_tokens(word, sentence) |>
  dplyr::filter(word %in% word_freq$word) |>
  dplyr::left_join(word_freq, by = "word") |>
  dplyr::group_by(sentence_id) |>
  dplyr::summarise(
    score = mean(frequency),
    matched_words = dplyr::n(),
    .groups = "drop"
  )

# Scores to the original sentences
ranked_sentences <- sentences_df |>
  dplyr::left_join(
    sentence_scores,
    by = "sentence_id"
  ) |>
  dplyr::mutate(
    score = dplyr::coalesce(score, 0)
  )

# Select highest-scoring sentences
frequency_summary <- ranked_sentences |>
  dplyr::arrange(dplyr::desc(score)) |>
  dplyr::slice_head(n = 4) |>
  dplyr::arrange(sentence_id)

#  show summary
cat("\nFREQUENCY-BASED SUMMARY:\n\n")

cat(
  paste(frequency_summary$sentence, collapse = " "),
  "\n"
)

# Show the selected sentences and scores
print(
  frequency_summary |>
    dplyr::select(sentence_id, sentence, score)
)






# 2. TextRank Extractive Summarisation

sentence_tokens <- sentences_df |>
  dplyr::select(sentence_id, sentence) |>
  tidytext::unnest_tokens(word, sentence) |>
  dplyr::filter(word %in% word_freq$word)

sentence_term_matrix <- as.matrix(
  table(
    factor(
      sentence_tokens$sentence_id,
      levels = sentences_df$sentence_id
    ),
    sentence_tokens$word
  )
)

sentence_norms <- sqrt(
  rowSums(sentence_term_matrix^2)
)

sentence_norms[sentence_norms == 0] <- 1

similarity_matrix <- tcrossprod(
  sentence_term_matrix
) / outer(sentence_norms, sentence_norms)

diag(similarity_matrix) <- 0

cat("Sentence similarity matrix dimensions:",
    dim(similarity_matrix), "\n")

print(round(similarity_matrix[1:5, 1:5], 3))


# Create a weighted graph of sentence similarities
sentence_graph <- igraph::graph_from_adjacency_matrix(
  similarity_matrix,
  mode = "undirected",
  weighted = TRUE,
  diag = FALSE
)

textrank_scores <- igraph::page_rank(
  sentence_graph,
  directed = FALSE,
  damping = 0.85
)$vector

textrank_results <- sentences_df |>
  dplyr::mutate(
    textrank_score = as.numeric(textrank_scores)
  )

textrank_ranked <- textrank_results |>
  dplyr::arrange(dplyr::desc(textrank_score))

textrank_summary <- textrank_ranked |>
  dplyr::slice_head(n = 4) |>
  dplyr::arrange(sentence_id)

# Display the final TextRank summary
cat("\nTEXTRANK SUMMARY:\n\n")

cat(
  paste(textrank_summary$sentence, collapse = " "),
  "\n\n"
)

# Display the selected sentences & scores
print(
  textrank_summary |>
    dplyr::select(
      sentence_id,
      sentence,
      textrank_score
    )
)







# 3.3: Visualization 1
# Most Frequent Keywords

library(ggplot2)
library(dplyr)

dir.create("figures", showWarnings = FALSE)


top_words <- word_freq |>
  dplyr::slice_max(
    order_by = frequency,
    n = 15,
    with_ties = FALSE
  ) |>
  dplyr::mutate(
    word = reorder(word, frequency)
  )

# Create bar chart
keyword_plot <- ggplot(
  top_words,
  aes(x = word, y = frequency)
) +
  geom_col(fill = "#2878B5", width = 0.7) +
  geom_text(
    aes(label = frequency),
    hjust = -0.3,
    size = 3.5
  ) +
  coord_flip() +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.12))
  ) +
  labs(
    title = "Most Frequent Keywords in NASA Climate Change Article",
    subtitle = "Top 15 words after text preprocessing",
    x = "Keywords",
    y = "Word Frequency",
    caption = "Source: NASA Science - What Is Climate Change?"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.major.y = element_blank()
  )

print(keyword_plot)

# Save image
ggsave(
  filename = "figures/NASA_Keyword_Frequency.png",
  plot = keyword_plot,
  width = 10,
  height = 6,
  dpi = 300
)

cat("Keyword frequency chart saved successfully.\n")








# 3.3: Visualisation 2
# TextRank Sentence Importance

library(ggplot2)
library(dplyr)

sentence_plot_df <- textrank_results |>
  dplyr::mutate(
    sentence_label = paste("Sentence", sentence_id),
    selected = ifelse(
      sentence_id %in% textrank_summary$sentence_id,
      "Selected for summary",
      "Not selected"
    )
  )

sentence_plot_df$sentence_label <- factor(
  sentence_plot_df$sentence_label,
  levels = sentence_plot_df$sentence_label[
    order(sentence_plot_df$textrank_score)
  ]
)

# Create chart
textrank_plot <- ggplot(
  sentence_plot_df,
  aes(x = sentence_label, y = textrank_score)
) +
  geom_segment(
    aes(xend = sentence_label, yend = 0),
    colour = "grey70",
    linewidth = 0.7
  ) +
  geom_point(
    aes(colour = selected),
    size = 3.5
  ) +
  geom_text(
    aes(label = sprintf("%.3f", textrank_score)),
    hjust = -0.3,
    size = 3.2
  ) +
  coord_flip() +
  scale_colour_manual(
    values = c(
      "Selected for summary" = "#2878B5",
      "Not selected" = "#9CA3AF"
    )
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.18))
  ) +
  labs(
    title = "TextRank Sentence Importance Scores",
    subtitle = "Ranking of 15 sentences from the NASA article",
    x = "Sentence",
    y = "TextRank Score",
    colour = "Summary selection",
    caption = "Source: NASA Science - What Is Climate Change?"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.major.y = element_blank(),
    legend.position = "bottom"
  )

# Display the chart
print(textrank_plot)

# Save the visualization
ggsave(
  filename = "figures/NASA_TextRank_Sentence_Importance.png",
  plot = textrank_plot,
  width = 11,
  height = 7,
  dpi = 300
)

cat("TextRank sentence importance chart saved successfully.\n")










# Compare summaries

frequency_ids <- frequency_summary$sentence_id
textrank_ids <- textrank_summary$sentence_id

shared_ids <- intersect(frequency_ids, textrank_ids)

cat("FREQUENCY-BASED SUMMARY\n")
cat("Selected sentences:", frequency_ids, "\n\n")

cat("TEXTRANK SUMMARY\n")
cat("Selected sentences:", textrank_ids, "\n\n")

cat("Shared sentences:", shared_ids, "\n")
cat("Number of shared sentences:", length(shared_ids), "\n")

overlap_percentage <- (
  length(shared_ids) / length(frequency_ids)
) * 100

cat("Summary overlap:", overlap_percentage, "%\n")

# Comparison table
comparison_df <- data.frame(
  Method = c("Frequency-Based", "TextRank"),
  Sentences_Selected = c(
    length(frequency_ids),
    length(textrank_ids)
  ),
  Selected_IDs = c(
    paste(frequency_ids, collapse = ", "),
    paste(textrank_ids, collapse = ", ")
  )
)

print(comparison_df)







# Save
writeLines(
  paste(frequency_summary$sentence, collapse = " "),
  "Frequency_Based_Summary.txt",
  useBytes = TRUE
)

writeLines(
  paste(textrank_summary$sentence, collapse = " "),
  "TextRank_Summary.txt",
  useBytes = TRUE
)

write.csv(
  comparison_df,
  "Summary_Comparison.csv",
  row.names = FALSE
)

write.csv(
  ranked_sentences,
  "Frequency_Sentence_Scores.csv",
  row.names = FALSE
)

write.csv(
  textrank_results,
  "TextRank_Sentence_Scores.csv",
  row.names = FALSE
)

cat("Summaries and comparison files saved successfully.\n")







required_files <- c(
  "Question3_WebText.R",
  "NASA_Raw_WebText.csv",
  "NASA_Cleaned_WebText.csv",
  "Frequency_Based_Summary.txt",
  "TextRank_Summary.txt",
  "Summary_Comparison.csv",
  "Frequency_Sentence_Scores.csv",
  "TextRank_Sentence_Scores.csv",
  "figures/NASA_Keyword_Frequency.png",
  "figures/NASA_TextRank_Sentence_Importance.png"
)

file_check <- data.frame(
  File = required_files,
  Exists = file.exists(required_files)
)

print(file_check)

cat(
  "\nFiles found:",
  sum(file_check$Exists),
  "out of",
  length(required_files),
  "\n"
)
