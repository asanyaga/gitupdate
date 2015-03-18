create table parts
(
  part_id int,
  part_type varchar(1),
  product_id int
);

insert into parts values
(1,            'A',              1),
(2,            'B',              1),
(3,            'A',              2),
(4,            'B',              2),
(5,            'A',              3),
(6,            'B',              3)


SET @sql = NULL;
SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'max(case when part_type = ''',
      part_type,
      ''' then part_id end) AS part_',
      part_type, '_id'
    )
  ) INTO @sql
FROM
  parts;
SET @sql = CONCAT('SELECT product_id, ', @sql, ' 
                  FROM parts 
                   GROUP BY product_id');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;