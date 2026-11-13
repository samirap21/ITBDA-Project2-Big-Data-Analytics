
-- Question 4.3
-- Create a table for the cleaned NASA blog data

CREATE TABLE IF NOT EXISTS public.nasa_blog_articles (
    record_id INTEGER PRIMARY KEY,
    page_number INTEGER NOT NULL,
    title TEXT NOT NULL,
    publication_date DATE NOT NULL,
    excerpt TEXT NOT NULL,
    article_url TEXT NOT NULL UNIQUE,
    word_count INTEGER NOT NULL,
    excerpt_imputed BOOLEAN NOT NULL DEFAULT FALSE
);





-- Verify the table before importing data

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'nasa_blog_articles'
ORDER BY ordinal_position;




-- Verify imported NASA blog records

SELECT COUNT(*) AS total_records
FROM public.nasa_blog_articles;






-- Preview the imported data

SELECT
    record_id,
    title,
    publication_date,
    word_count
FROM public.nasa_blog_articles
ORDER BY record_id
LIMIT 10;




-- 4.3. SQL Investigation 1
-- NASA blog publishing activity by date

SELECT
    publication_date,
    COUNT(*) AS total_articles,
    ROUND(AVG(word_count), 2) AS avg_word_count,
    MIN(word_count) AS min_word_count,
    MAX(word_count) AS max_word_count
FROM public.nasa_blog_articles
GROUP BY publication_date
ORDER BY publication_date DESC;






-- 4.3. SQL Investigation 2
-- NASA blog content category analysis

WITH categorised_articles AS (
    SELECT
        record_id,
        title,
        word_count,
        CASE
            WHEN title ~* 
                '(spacewalk|astronaut|crew|spacesuit|cargo|dragon)'
                THEN 'Crew and Spacewalks'

            WHEN title ~*
                '(science|research|microbiolog|solar flare|tracers|algae|oyster)'
                THEN 'Science and Research'

            WHEN title ~*
                '(voyager|escapade|spacecraft|rocket|observatory|mission|funding)'
                THEN 'Space Missions'

            ELSE 'Other NASA News'
        END AS category
    FROM public.nasa_blog_articles
)

SELECT
    category,
    COUNT(*) AS total_articles,
    ROUND(AVG(word_count), 2) AS avg_word_count,
    MIN(word_count) AS shortest_excerpt,
    MAX(word_count) AS longest_excerpt
FROM categorised_articles
GROUP BY category
ORDER BY total_articles DESC, category;
