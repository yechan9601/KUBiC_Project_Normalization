ALTER USER '21801073'@'%' IDENTIFIED BY 'team22dbms';

/*
  1. List all valid (non-null) topics and their counts in the document collection.
 Show the count and rank (from the most frequent to the least frequent) of each topic
 */

# speed) [2022-06-19 01:18:47] 7 rows retrieved starting from 1 in 69 ms (execution: 47 ms, fetching: 22 ms)
select topic, COUNT(topic) as CNT, RANK() OVER (ORDER BY COUNT(topic) DESC) AS topic_rank
FROM DocFilter
Where topic is not null
GROUP BY topic;
# indexed) [2022-06-19 01:26:24] 7 rows retrieved starting from 1 in 59 ms (execution: 28 ms, fetching: 31 ms)

# [2022-06-19 00:22:22] 7 rows retrieved starting from 1 in 97 ms (execution: 78 ms, fetching: 19 ms)
select topic, COUNT(topic) as CNT, RANK() OVER (ORDER BY COUNT(topic) DESC) AS topic_rank
FROM Document2
Where topic is not null
GROUP BY topic;

/*
 2. How many distinct documents published between year 2019 and 2022 are stored in the database?
 */

 # speed) [2022-06-19 01:19:08] 1 row retrieved starting from 1 in 62 ms (execution: 30 ms, fetching: 32 ms)
SELECT COUNT(DISTINCT hash_key)
FROM Document
WHERE SUBSTR(post_date, 1, 4) BETWEEN 2019 AND 2022;
# indexed) [2022-06-19 01:27:55] 1 row retrieved starting from 1 in 61 ms (execution: 40 ms, fetching: 21 ms)

/*
 3. Among the users who are using the “My Documents” function, find the email address of the user
 who has stored the most documents in year 2022 and how many documents the user has in “My Documents”
 */

 # speed) [2022-06-19 01:19:20] 1 row retrieved starting from 1 in 115 ms (execution: 87 ms, fetching: 28 ms)
SELECT u._id, email, COUNT(*) as cnt
FROM SavedDoc s JOIN User u ON s._id = u._id
WHERE SUBSTR(savedDate, 1, 4) = 2022
GROUP BY _id, email
ORDER BY cnt DESC LIMIT 1;
# indexed) [2022-06-19 01:35:33] 1 row retrieved starting from 1 in 210 ms (execution: 199 ms, fetching: 11 ms)

# denormalized speed) [2022-06-19 00:14:11] 1 row retrieved starting from 1 in 101 ms (execution: 89 ms, fetching: 12 ms)
SELECT u._id, email, COUNT(*) as cnt
FROM SavedDoc s JOIN User u ON s._id = u._id
WHERE SUBSTR(savedDate, 1, 4) = 2022
GROUP BY _id, email
ORDER BY cnt DESC LIMIT 1;


/*
 4. For the user in the answer to the previous question, list the 5 most frequent keywords found in his/her “My Document”
 620b9e51c5c17884d0961a19
 */

# modified)
SELECT keyword, COUNT(*) as cnt
FROM SavedDoc
WHERE _id = (
   SELECT User._id
   FROM SavedDoc JOIN User ON SavedDoc._id=User._id
   WHERE SUBSTR(savedDate, 1, 4) = 2022
   GROUP BY User._id
   ORDER BY COUNT(*) DESC
   LIMIT 1
)
GROUP BY keyword
ORDER BY cnt DESC LIMIT 5;

 # speed) [2022-06-19 01:19:31] 5 rows retrieved starting from 1 in 55 ms (execution: 32 ms, fetching: 23 ms)
SELECT keyword, COUNT(*) as cnt
FROM SavedDoc
WHERE _id = '620b9e51c5c17884d0961a19'
GROUP BY keyword
ORDER BY cnt DESC LIMIT 5;
# indexed) [2022-06-19 01:36:22] 5 rows retrieved starting from 1 in 46 ms (execution: 28 ms, fetching: 18 ms)

# denormalized speed) [2022-06-19 00:15:57] 5 rows retrieved starting from 1 in 114 ms (execution: 98 ms, fetching: 16 ms)
SELECT keyword, COUNT(*) as cnt
FROM SavedDoc2
WHERE _id = '620b9e51c5c17884d0961a19'
GROUP BY keyword
ORDER BY cnt DESC LIMIT 5;

/*
 5. Find the titles (post_title) and authors (post_writer) of the three most similar documents (regardless of the published year)
to the one with the longest title among those are published in 2014
Hint: Use the similarity table
 */

# modified)
SELECT DISTINCT post_title, post_writer, Score
FROM similarity JOIN Document ON hash_key = docID
WHERE rcmdDocID = (select hash_key
    from `2022_ece30030_1_2`.Document
    where SUBSTR(post_date,1,4) = '2014'
    order by LENGTH(post_title) DESC
    limit 1) AND docId <> rcmdDocID
order by Score DESC
LIMIT 3;

# speed) [2022-06-19 01:19:44] 3 rows retrieved starting from 1 in 686 ms (execution: 666 ms, fetching: 20 ms)
SELECT DISTINCT post_title, post_writer, Score
FROM similarity JOIN Document ON hash_key = docID
WHERE rcmdDocID = (select hash_key
    from `2022_ece30030_1_2`.Document
    where SUBSTR(post_date,1,4) = '2014'
    order by LENGTH(post_title) DESC
    limit 1) AND Score < 1
order by Score DESC
LIMIT 3;
# indexed) [2022-06-19 01:36:38] 3 rows retrieved starting from 1 in 118 ms (execution: 98 ms, fetching: 20 ms)

/*
 6. Find the names, affiliations (inst), email addresses, and position (status) of the
 registered users whose position is unique in the database
 */

# speed) [2022-06-19 01:19:58] 4 rows retrieved starting from 1 in 79 ms (execution: 39 ms, fetching: 40 ms)
SELECT name, inst, email, User.status
FROM (SELECT User.status, count(User.status)
FROM User
GROUP BY User.status
HAVING count(*) = 1) as uniq_user JOIN User ON uniq_user.status=User.status;
# indexed) [2022-06-19 01:37:17] 4 rows retrieved starting from 1 in 27 ms (execution: 16 ms, fetching: 11 ms)

/*
 7. What are the five most representative words for the articles written by “송인호”?
Hint: Use the frequency table
 */
# speed) [2022-06-19 01:20:09] 5 rows retrieved starting from 1 in 790 ms (execution: 773 ms, fetching: 17 ms)
SELECT tfidfWord
FROM Document JOIN frequency ON hash_key = docID AND post_writer LIKE '%송인호%'
ORDER BY Score DESC
LIMIT 5;
# indexed) [2022-06-19 01:38:13] 5 rows retrieved starting from 1 in 74 ms (execution: 59 ms, fetching: 15 ms)

SELECT tfidfWord
FROM Document JOIN frequency ON hash_key = docID;

/*
 8. Find the five most similar documents to those of the author who holds the most representative document for keyword “국민”
Hint: Use both the frequency and similarity tables
 */

# answer)
# speed) [2022-06-19 01:20:21] 500 rows retrieved starting from 1 in 1 s 96 ms (execution: 1 s 69 ms, fetching: 27 ms)

select post_title, post_writer, post_date, Score
from `2022_ece30030_1_2`.similarity JOIN `2022_ece30030_1_2`.Document ON docID = hash_key
where rcmdDocID IN (
   select hash_key
    from `2022_ece30030_1_2`.Document
    where post_writer = (
        select post_writer
        from `2022_ece30030_1_2`.frequency JOIN `2022_ece30030_1_2`.Document ON docID = hash_key
        where tfidfWord = '국민'
        order by Score DESC
        limit 1
    )
) AND rcmdDocID <> similarity.docID
order by Score desc;
# [2022-06-19 01:44:14] 500 rows retrieved starting from 1 in 1 s 349 ms (execution: 1 s 335 ms, fetching: 14 ms)


/*
 9. Compare the distribution of topics (count per topic) in the documents published in 2015 and that of 2020
 */

# speed) [2022-06-19 01:21:02] 7 rows retrieved starting from 1 in 210 ms (execution: 95 ms, fetching: 115 ms)
select topic, COUNT((case when SUBSTR(post_date, 1, 4) = '2015' then 1 end)) AS CNT2015, COUNT((case when SUBSTR(post_date, 1, 4) = '2020' then 1 end)) AS CNT2020
from `2022_ece30030_1_2`.Document JOIN `2022_ece30030_1_2`.DocFilter ON hash_key = hashKey
where topic is not null
group by topic
order by CNT2020 DESC;
# [2022-06-19 01:40:50] 7 rows retrieved starting from 1 in 161 ms (execution: 151 ms, fetching: 10 ms)

# [2022-06-19 00:23:24] 7 rows retrieved starting from 1 in 74 ms (execution: 44 ms, fetching: 30 ms)
select topic, COUNT((case when SUBSTR(post_date, 1, 4) = '2015' then 1 end)) AS CNT2015, COUNT((case when SUBSTR(post_date, 1, 4) = '2020' then 1 end)) AS CNT2020
from Document2
where topic is not null
group by topic
order by CNT2020 DESC;


/*
 10. For all words that are used in the frequency analysis,
 show how many times each word has been used in the analysis
 (how many times each words has been used in the frequency table)
 */

# speed) [2022-06-19 01:21:21] 500 rows retrieved starting from 1 in 3 s 767 ms (execution: 3 s 750 ms, fetching: 17 ms)
select tfidfWord, COUNT(tfidfWord) AS word_count, RANK() over (ORDER BY COUNT(tfidfWord) DESC ) word_rank
from `2022_ece30030_1_2`.frequency
group by tfidfWord;
# [2022-06-19 01:41:16] 500 rows retrieved starting from 1 in 3 s 635 ms (execution: 3 s 606 ms, fetching: 29 ms)

# helping queries:
select count(*)
from Document; # 14826 rows.

select count(*)
from similarity; # 1435077

select count(*)
from Document join similarity on hash_key=docID;

select post_title, post_writer, top_category, hash_key, docID, rcmdDocID, Score
from Document Join similarity on hash_key = docID;


# ---------------------------
# 2022 6 18

create table SavedDoc2 (
    SELECT *
    from User natural join SavedDoc
);

create table Document2 (
    SELECT *
    FROM Document join DocFilter on hashKey = hash_key
);

create table Document2 (SELECT * FROM Document left join DocFilter on hashKey = hash_key);


# index!
show index from Document;
show index from User;
show index from SavedDoc;
show index from DocFilter;
show index from frequency;
show index from similarity;


SELECT TABLE_SCHEMA, TABLE_NAME,
    ROUND(DATA_LENGTH/1024, 1) AS 'data(KB)',
    ROUND(INDEX_LENGTH/(1024), 1) AS 'idx(KB)'
FROM information_schema.tables
WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_SCHEMA='2022_ece30030_1_2';


select count(*) from frequency; # 877490
select count(*) from SavedDoc; # 109413
select count(*) from Document; # 14826








