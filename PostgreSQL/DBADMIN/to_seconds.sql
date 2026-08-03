CREATE OR REPLACE FUNCTION to_seconds(t text)
  RETURNS integer AS
$BODY$ 
DECLARE 
    hs INTEGER;
    ms INTEGER;
    s INTEGER;
BEGIN
    SELECT (EXTRACT( HOUR FROM  t::time) * 60*60) INTO hs; 
    SELECT (EXTRACT (MINUTES FROM t::time) * 60) INTO ms;
    SELECT (EXTRACT (SECONDS from t::time)) INTO s;
    SELECT (hs + ms + s) INTO s;
    RETURN s;
END;
$BODY$
  LANGUAGE 'plpgsql';
  
  
select  'cnt_emprestimo'as tabela, 'semana passada' as periodo,
avg(to_seconds(time_running::text)::int) as media_segundos, query from tb_get_activity
where time_running::text not ilike '%23:59:59%'
and dt_log between '2024-08-15 22:00' and '2024-08-16 14:24'
and query ilike '%cnt_emprestimo%'
and query ilike '%insert%'
and query not ilike '%select%'
group by query
union 
select  'cnt_emprestimo'as tabela,'depois da gmud'as periodo,
avg(to_seconds(time_running::text)::int)as media_segundos , query from tb_get_activity
where time_running::text not ilike '%23:59:59%'
and dt_log between '2024-08-22 22:00' and '2024-08-23 14:24'
and query ilike '%cnt_emprestimo%'
and query ilike '%insert%'
and query not ilike '%select%'
group by query


