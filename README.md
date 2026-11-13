# ITBDA Project 2 | Big Data Analytics

**Module:** ITBDA4-14, Honours BSc IT (Data Science)  
**Institution:** Eduvos  
**Technologies:** Hadoop MapReduce (Java), Python/Jupyter, R, PostgreSQL and SQL

## Project overview

This repository brings together four practical Big Data Analytics tasks: searching a news corpus with Hadoop MapReduce, discovering topics with Latent Dirichlet Allocation (LDA), extracting and summarising web text in R, and implementing an extract-transform-load (ETL) workflow with PostgreSQL.

The results below describe the sample datasets and runs used for this assignment. They are not claims about larger populations or production deployments.

## Repository contents

```text
ITBDA_Project2/
├── Question1_MapReduce/       # Java, HDFS input, keyword search outputs and evidence
├── Question2_LDA/             # Jupyter topic-modelling work, data and figures
├── Question3_WebText/         # R web scraping, summaries and visualizations
├── Question4_RTL/             # R ETL, NASA blog CSVs and PostgreSQL SQL queries
├── ITBDA4-14_Documentation_*.pdf  # Full assignment documentation (filename may vary)
├── README.md
└── .gitignore
```

The `Question4_RTL` directory name reflects the current local folder; the task itself is **ETL (Extract, Transform, Load)**. Individual files and subfolders should be checked against the final upload.

## Question 1: Hadoop MapReduce keyword search

**Objective:** Find a user-supplied keyword in seven news documents and report its document name, row and starting column position.

- **Environment:** Hadoop 2.7.6, Java 8 and Windows.
- **Implementation:** Java Mapper, Reducer, driver and custom whole-file input format.
- **Storage:** News documents and generated results in HDFS.
- **Validated runs:** `africa` produced 16 matching locations across four documents. Running `AFRICA` produced the same results. A separate search for `the` demonstrated dynamic keyword input.
- **Execution note:** The successfully demonstrated MapReduce run used **local MapReduce mode with HDFS**, not a successfully completed YARN cluster job.

Example HDFS checks (run in a configured Hadoop Command Prompt):

```cmd
hdfs dfs -ls /user/samir/itbda/input
hdfs dfs -cat /user/samir/itbda/output_africa_local/part-r-00000
```

To rerun the Java application, compile the source files if necessary, package the JAR, and use the driver with a keyword plus input and a **new** output directory. Hadoop requires that the output directory not already exist.

## Question 2: LDA topic modelling

**Objective:** Turn a collection of news files into clean documents, identify latent topics and visualise their important words.

- **Environment:** Python in Jupyter Notebook.
- **Input:** Ten news text documents (`news.zip`).
- **Processing:** Text normalisation, tokenisation, stopword filtering and document-term matrix construction.
- **Model:** LDA with **3 topics** and the **top 10 terms per topic**.
- **Results:** Dominant-topic counts were **3, 4 and 3 documents**, respectively.
- **Visualizations:** Topic keyword bar charts and a topic-word probability heatmap.

Open the Question 2 `.ipynb` file in Jupyter and run its cells in order with its dataset accessible at the paths used by the notebook. Topic assignments may vary if model settings or random seeds change.

## Question 3: NASA WebText and extractive summarisation

**Objective:** Extract meaningful text from a public NASA Science webpage and compare two summary methods.

**Source:** [NASA Science, What Is Climate Change?](https://science.nasa.gov/climate-change/what-is-climate-change/)

- **Environment:** RStudio with `rvest`, `dplyr`, `stringr`, `tidytext`, `stopwords`, `igraph` and `ggplot2`.
- **Extraction:** 22 non-empty paragraphs; 8 relevant explanatory paragraphs retained.
- **Preprocessing:** 255 cleaned word tokens.
- **Summarisation:** 15 sentences assessed; four selected by each method.
- **Methods:** Frequency-based sentence scoring and TextRank using cosine similarity and graph centrality.
- **Comparison:** Three shared selected sentences, or **75% overlap**.
- **Visualizations:** Word-frequency bar chart and TextRank sentence-importance chart.

The project is a URL-driven text-processing **proof of concept**, not a deployed REST API. The scraping and filtering rules depend on the webpage's HTML structure.

## Question 4: NASA blogs ETL and PostgreSQL

**Objective:** Extract NASA blog archive records, clean them, load them into a relational database and analyse their publication dates and content categories.

**Sources:** [NASA Blogs](https://www.nasa.gov/blogs/) and [archive page 2](https://www.nasa.gov/blogs/page/2/)

- **Environment:** RStudio, PostgreSQL 18 and pgAdmin 4.
- **Extraction:** 20 blog entries from two archive pages, with text fields, article links and regex-based excerpt word counts.
- **Transformation:** Whitespace cleanup, date conversion, duplicate checks and conditional missing-excerpt replacement.
- **Quality checks:** 20 cleaned rows, no missing values, no duplicate article URLs, no invalid dates and **no imputation actually required**.
- **Load:** The cleaned CSV was imported into `itbda_project2.public.nasa_blog_articles`; SQL verified 20 records.
- **SQL investigation 1:** Publishing activity and excerpt-length summaries by date.
- **SQL investigation 2:** Regex-based title categorisation and comparison of average excerpt lengths.

Observed category results:

| Inferred category | Articles | Share | Mean excerpt words |
|---|---:|---:|---:|
| Crew and Spacewalks | 11 | 55% | 36.55 |
| Space Missions | 4 | 20% | 57.50 |
| Science and Research | 3 | 15% | 45.67 |
| Other NASA News | 2 | 10% | 56.50 |

These are **rule-based categories inferred from article titles**, not official NASA tags. Counts and word lengths describe the collected 20-entry sample, not all NASA publications.

### Reproducing the database work

1. Run the Question 4 R ETL script in RStudio to produce raw and cleaned CSVs. Confirm that the NASA archive HTML structure has not changed.
2. Create or connect to the `itbda_project2` PostgreSQL database.
3. Create the `public.nasa_blog_articles` table using the schema in the SQL source or assignment documentation.
4. Import the cleaned CSV using pgAdmin 4, including the header row.
5. Run the saved SQL investigation scripts. Check `SELECT COUNT(*) FROM public.nasa_blog_articles;` for 20 rows before interpreting the original results.

Do not commit database passwords, connection strings containing credentials or local PostgreSQL data directories.

## Reproducibility and evidence

The source code, datasets, outputs, figures and assignment documentation are intended to be preserved in their corresponding question folders. Review the committed file tree to ensure all required materials are present. Windows/Hadoop runtime folders and local caches are intentionally excluded by `.gitignore`.

The notebooks/scripts may use paths specific to the original Windows environment. Adjust paths and install the required dependencies before rerunning the work. The screenshots and report capture the original practical results.

## Academic use and attribution

This repository documents an educational assignment. Consult the included assignment report for implementation details, methodology, limitations, references and screenshots. The NASA material remains attributable to NASA, and software libraries retain their own licences.
