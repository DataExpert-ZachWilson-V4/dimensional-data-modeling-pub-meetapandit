INSERT INTO actors
-- Create CTE to read data from actors table for last year  
WITH
  last_year AS (
    SELECT *
    FROM actors
    WHERE
      current_year = 2018
  )
  -- CTE to read data from new incoming data which
  -- is not in actors table
  , this_year AS (
    SELECT *
    FROM bootcamp.actor_films
    WHERE year = 2019
  )
  , average_rating_ty AS (
  SELECT actor
       , actor_id
       , ARRAY_AGG(ROW(year, film, votes, rating, film_id)) AS films
       , AVG(rating) AS avg_rating
       , MAX(year) AS current_year
  FROM this_year
  GROUP BY actor
       , actor_id
  )

  SELECT COALESCE(ly.actor, ty.actor) AS actor
       , COALESCE(ly.actor_id, ty.actor_id) AS actor_id
       -- actor not present in new dataset
       , CASE WHEN ty.current_year IS NULL THEN ly.films
       -- new actor record
              WHEN ty.current_year IS NOT NULL AND ly.films IS NULL THEN ty.films
              -- present in both last year and this year       
              -- so append array
              WHEN ty.current_year IS NOT NULL AND ly.films IS NOT NULL THEN ty.films || ly.films 
         END AS films
       , CASE WHEN ty.avg_rating IS NULL THEN ly.quality_class 
       ELSE (
         CASE WHEN ty.avg_rating > 8 THEN 'star'
              WHEN ty.avg_rating > 7 AND ty.avg_rating <= 8  THEN 'good'
              WHEN ty.avg_rating > 6 AND ty.avg_rating <= 7  THEN 'average'
              WHEN ty.avg_rating <= 6 THEN 'bad'
          END)
          END AS quality_class
       , ty.current_year IS NOT NULL AS is_active
       , COALESCE(ty.current_year, ly.current_year + 1) AS current_year
  FROM last_year ly
  FULL OUTER JOIN average_rating_ty ty ON ly.actor_id = ty.actor_id