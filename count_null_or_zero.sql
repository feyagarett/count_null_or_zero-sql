--drop FUNCTION count_null_or_zero(p_table_name TEXT);

CREATE OR REPLACE FUNCTION count_null_or_zero(p_table_name TEXT)
RETURNS TABLE(name_column TEXT, null_or_zero_count BIGINT) AS $$
DECLARE
    col_rec RECORD; -- результаты из information_schema.columns
    dynamic_query TEXT; -- динамически создаваемый запрос
BEGIN
    FOR col_rec IN
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_name = p_table_name AND table_schema = 'your schema' -- ввести название своей схемы
    LOOP
		-- Проверка на тип столбца: если числовой, то необходимо проверять поле на 0
        IF col_rec.data_type = 'integer' OR col_rec.data_type = 'bigint' OR col_rec.data_type = 'numeric' THEN
            dynamic_query := format(
                'SELECT %L::text AS column_name, COUNT(*) AS null_or_zero_count
                 FROM %I
                 WHERE COALESCE(%I, 0) = 0',
                col_rec.column_name, p_table_name, col_rec.column_name
            );
        ELSE
            dynamic_query := format(
			-- Все, что не числовой тип данных, конвертируется в text и проверяется на '' (пустоту)
                'SELECT %L::text AS column_name, COUNT(*) AS null_or_zero_count
                 FROM %I
                 WHERE COALESCE(%I::TEXT, '''') = ''''',
                col_rec.column_name, p_table_name, col_rec.column_name
            );
        END IF;
        RETURN QUERY EXECUTE dynamic_query;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT * from count_null_or_zero('cogs_second_cogs') AS answer;

