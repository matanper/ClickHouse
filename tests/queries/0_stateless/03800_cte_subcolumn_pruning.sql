-- Test for CTE with SELECT * subcolumn pruning
-- https://github.com/ClickHouse/ClickHouse/issues/XXX

DROP TABLE IF EXISTS test_json_pruning;
DROP TABLE IF EXISTS test_tuple_pruning;

-- Test with JSON type
CREATE TABLE IF NOT EXISTS test_json_pruning
(
    id UInt64,
    event JSON(
        class_name String,
        category_name String,
        message String
    )
)
ENGINE = MergeTree()
ORDER BY (id);

INSERT INTO test_json_pruning VALUES (1, '{"class_name": "test", "category_name": "cat1", "message": "hello"}');

-- Without CTE: should show event.class_name in header
SELECT 'Without CTE (JSON):';
EXPLAIN header=1
SELECT event.class_name
FROM test_json_pruning;

-- With CTE: should now also show event.class_name in header (was showing full JSON before fix)
SELECT 'With CTE (JSON):';
EXPLAIN header=1
WITH foo AS (
    SELECT * FROM test_json_pruning
)
SELECT event.class_name
FROM foo;

-- Verify the actual query works
SELECT 'Query result (JSON):';
WITH foo AS (
    SELECT * FROM test_json_pruning
)
SELECT event.class_name
FROM foo;

DROP TABLE test_json_pruning;

-- Test with Tuple type (same issue exists for Tuple)
CREATE TABLE IF NOT EXISTS test_tuple_pruning
(
    id UInt64,
    event Tuple(
        class_name String,
        category_name String,
        message String
    )
)
ENGINE = MergeTree()
ORDER BY (id);

INSERT INTO test_tuple_pruning VALUES (1, ('test', 'cat1', 'hello'));

-- Without CTE: should show event.class_name in header
SELECT 'Without CTE (Tuple):';
EXPLAIN header=1
SELECT event.class_name
FROM test_tuple_pruning;

-- With CTE: should now also show event.class_name in header (was showing full Tuple before fix)
SELECT 'With CTE (Tuple):';
EXPLAIN header=1
WITH foo AS (
    SELECT * FROM test_tuple_pruning
)
SELECT event.class_name
FROM foo;

-- Verify the actual query works
SELECT 'Query result (Tuple):';
WITH foo AS (
    SELECT * FROM test_tuple_pruning
)
SELECT event.class_name
FROM foo;

DROP TABLE test_tuple_pruning;
