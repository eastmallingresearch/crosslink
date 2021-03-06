/* run using: sqlite3 scores.db '.read /home/vicker/git_repos/crosslink/test_scripts/crosslg.sql' */
/* Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details */

drop table if exists scores;
create table scores (min_count integer, min_lod real, max_lod real, treatment text, sample text, score real);
.separator " "
.import all_scores scores
select avg(score),count(score),treatment from scores group by treatment order by avg(score);
