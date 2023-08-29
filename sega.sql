create database segagames;

use segagames;

select *
from sega
LIMIT 5000;

DESCRIBE sega;

# fix date format
SELECT DISTINCT date,
    DATE_FORMAT(STR_TO_DATE(date, '%b %d, %Y'), '%d-%m-%Y') AS formatted_date
FROM sega
ORDER BY formatted_date ASC;

# we found that null value is from date that fill with 'TBA'
SELECT *,
    DATE_FORMAT(STR_TO_DATE(date, '%b %d, %Y'), '%d-%m-%Y') AS formatted_date
FROM
    sega
WHERE date IN ('TBA');

# fix characters on developers and genres columns
SELECT DISTINCT developers, genres
FROM sega;

SELECT
	REPLACE(REPLACE(REPLACE(developers, '[', ''), "'", ''), ']', '') AS developer,
    REPLACE(REPLACE(REPLACE(genres, '[', ''), "'", ''), ']', '') AS genre
FROM sega;

# mix all values
SELECT *
FROM (
    SELECT title, platform,
        DATE_FORMAT(STR_TO_DATE(date, '%b %d, %Y'), '%d-%m-%Y') AS fix_date,
        REPLACE(REPLACE(REPLACE(developers, '[', ''), "'", ''), ']', '') AS developer,
		REPLACE(REPLACE(REPLACE(genres, '[', ''), "'", ''), ']', '') AS genre,
        user_score, meta_score,  esrb_rating, link
    FROM sega
) AS subquery
WHERE fix_date IS NOT NULL;

SELECT *
FROM (
    SELECT title, platform,
        DATE_FORMAT(STR_TO_DATE(date, '%b %d, %Y'), '%d-%m-%Y') AS fix_date,
        NULLIF(REPLACE(REPLACE(REPLACE(developers, '[', ''), "'", ''), ']', ''), '') AS developer,
        NULLIF(REPLACE(REPLACE(REPLACE(genres, '[', ''), "'", ''), ']', ''), '') AS genre,
        NULLIF(user_score, '') AS user_score,
        NULLIF(meta_score, '') AS meta_score,
        NULLIF(esrb_rating, '') AS esrb_rating,
        link
    FROM sega
) AS subquery
WHERE
	fix_date IS NOT NULL;

# make new view
CREATE VIEW sega_view AS
SELECT *
FROM (
   SELECT title, platform,
        DATE_FORMAT(STR_TO_DATE(date, '%b %d, %Y'), '%d-%m-%Y') AS fix_date,
        NULLIF(REPLACE(REPLACE(REPLACE(developers, '[', ''), "'", ''), ']', ''), '') AS developer,
        NULLIF(REPLACE(REPLACE(REPLACE(genres, '[', ''), "'", ''), ']', ''), '') AS genre,
        NULLIF(user_score, '') AS user_score,
        NULLIF(meta_score, '') AS meta_score,
        NULLIF(esrb_rating, '') AS esrb_rating,
        link
    FROM sega
) AS subquery
WHERE fix_date IS NOT NULL;

# change scores as DOUBLE
CREATE VIEW sega_view AS
SELECT *
FROM (
   SELECT title, platform,
        DATE_FORMAT(STR_TO_DATE(date, '%b %d, %Y'), '%d-%m-%Y') AS fix_date,
        NULLIF(REPLACE(REPLACE(REPLACE(developers, '[', ''), "'", ''), ']', ''), '') AS developer,
        NULLIF(REPLACE(REPLACE(REPLACE(genres, '[', ''), "'", ''), ']', ''), '') AS genre,
		CAST(NULLIF(user_score, '') AS DOUBLE) AS user_score,
		CAST(NULLIF(meta_score, '') AS DOUBLE) AS meta_score,
		NULLIF(esrb_rating, '') AS esrb_rating,
        link
    FROM sega
) AS subquery
WHERE fix_date IS NOT NULL;

# select all view
SELECT * FROM sega_view;

# knowing blank in fields
SELECT * FROM sega_view
WHERE
	developer IS NULL OR
    genre IS NULL OR
    user_score IS NULL OR
    meta_score IS NULL OR
    esrb_rating IS NULL;

SELECT COUNT(*) as Dev_blank
FROM sega_view
WHERE developer IS NULL;

SELECT COUNT(*) as score_blank
FROM sega_view
WHERE user_score IS NULL;

SELECT COUNT(*) as rating_blank
FROM sega_view
WHERE esrb_rating IS NULL;

SELECT COUNT(*) as meta_blank
FROM sega_view
WHERE meta_score IS NULL;

# fill null with AVG value and N/
SELECT
   title,
   platform,
   fix_date,
   developer,
   genre,
   ROUND(COALESCE(user_score, (SELECT AVG(user_score) FROM sega WHERE user_score IS NOT NULL)),1) AS user_score,
   ROUND(COALESCE(meta_score, (SELECT AVG(meta_score) FROM sega WHERE meta_score IS NOT NULL)),0) AS meta_score,
   IFNULL(esrb_rating, 'N/A') AS esrb_rating,
   link
   link
FROM sega_view;

# Make new view -- part 2
CREATE VIEW sega_new AS
SELECT
   title,
   platform,
   fix_date,
   developer,
   genre,
   ROUND(COALESCE(user_score, (SELECT AVG(user_score) FROM sega WHERE user_score IS NOT NULL)),1) AS user_score,
   ROUND(COALESCE(meta_score, (SELECT AVG(meta_score) FROM sega WHERE meta_score IS NOT NULL)),0) AS meta_score,
   IFNULL(esrb_rating, 'N/A') AS esrb_rating,
   link
   link
FROM sega_view;

SELECT *
FROM sega_new
LIMIT 5000;



-- ANSWERING QUESTION

# Top 10 Developers Who Produce the Most Games
SELECT developer, COUNT(developer) as dev_count
FROM sega_new
GROUP BY developer
ORDER BY dev_count DESC
LIMIT 10;

# What genres are in this Sega Games data?
SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(genre, ',', numbers.n), ',', -1)) AS genre
FROM sega_new
CROSS JOIN (
    SELECT 1 AS n UNION ALL
    SELECT 2 UNION ALL
    SELECT 3 UNION ALL
    SELECT 4 UNION ALL
    SELECT 5
) AS numbers
WHERE numbers.n <= 1 + LENGTH(genre) - LENGTH(REPLACE(genre, ',', '')) AND genre IS NOT NULL AND genre != '';

# What is the number of games with each genre
SELECT genre, COUNT(*) AS game_count
FROM (
    SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(genre, ',', numbers.n), ',', -1)) AS genre
    FROM sega_view
    CROSS JOIN (
        SELECT 1 AS n UNION ALL
        SELECT 2 UNION ALL
        SELECT 3 UNION ALL
        SELECT 4 UNION ALL
        SELECT 5
    ) AS numbers
    WHERE numbers.n <= 1 + LENGTH(genre) - LENGTH(REPLACE(genre, ',', '')) AND genre IS NOT NULL AND genre != ''
) AS genres
GROUP BY genre;

# Top 5 Most Produced Genres

SELECT genre, COUNT(*) AS game_count
FROM (
    SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(genre, ',', numbers.n), ',', -1)) AS genre
    FROM sega_new
    CROSS JOIN (
        SELECT 1 AS n UNION ALL
        SELECT 2 UNION ALL
        SELECT 3 UNION ALL
        SELECT 4 UNION ALL
        SELECT 5
    ) AS numbers
    WHERE numbers.n <= 1 + LENGTH(genre) - LENGTH(REPLACE(genre, ',', '')) AND genre IS NOT NULL AND genre != 'N/A'
) AS genres
GROUP BY genre
ORDER BY game_count DESC
LIMIT 5;

# TOP 10 Game with Most User Score in 2023
SELECT *
FROM sega_new
WHERE RIGHT(fix_date, 4) = '2023'
ORDER BY user_score DESC
LIMIT 10;

# Categorize user score
SELECT DISTINCT title, platform, fix_date, developer, genre, user_score,
	CASE
		WHEN user_score <= 4.0 THEN 'Bad'
        WHEN user_score <= 6.0 THEN 'Not Bad'
        WHEN user_score <= 8.0 THEN 'Good'
        ELSE 'Very Good'
	END AS category
FROM sega_new
WHERE
	user_score IS NOT NULL AND
	developer IS NOT NULL
ORDER BY category
LIMIT 2000;

# Find BAD game from user_score
SELECT title, user_score
FROM (
    SELECT title, user_score,
        CASE
            WHEN user_score <= 4.0 THEN 'Bad'
            WHEN user_score <= 6.0 THEN 'Not Bad'
            WHEN user_score <= 8.0 THEN 'Good'
            ELSE 'Very Good'
        END AS category
    FROM sega_new
) AS subquery
WHERE category = 'Bad'
	AND user_score IS NOT NULL
ORDER BY user_score ASC;

# Find VERY GOOD game from user_score
SELECT title, user_score
FROM (
    SELECT title, user_score,
        CASE
            WHEN user_score <= 4.0 THEN 'Bad'
            WHEN user_score <= 6.0 THEN 'Not Bad'
            WHEN user_score <= 8.0 THEN 'Good'
            ELSE 'Very Good'
        END AS category
    FROM sega_new
) AS subquery
WHERE category = 'Very Good'
	AND user_score IS NOT NULL
ORDER BY user_score ASC;

# What games release between 2022-2023?
SELECT DISTINCT title, fix_date, platform
FROM sega_new
WHERE RIGHT(fix_date, 4) BETWEEN '2022' AND '2023';

# How much PC game release between 2022 and 2023?
SELECT COUNT(*) AS total_games
FROM sega_new
WHERE RIGHT(fix_date, 4) BETWEEN '2022' AND '2023'
AND platform = 'PC';

# Most valuable game on PS4 2021
SELECT title, fix_date, platform, developer, user_score
FROM sega_new
ORDER BY user_score DESC
LIMIT 1;

# TOP 10 Platform
SELECT platform, Count(*) as Count_platform
FROM sega_new
GROUP BY platform
ORDER BY Count_platform DESC
LIMIT 10;