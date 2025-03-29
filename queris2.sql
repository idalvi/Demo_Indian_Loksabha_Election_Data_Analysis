#6.add new col field in table partywise_results to get the party akkianz as nda,india and other
alter table partywise_results add party_alliance varchar(50);
#I.N.D.I.A Allianz
update partywise_results
set party_alliance = 'I.N.D.I.A' where party in (
    'Indian National Congress - INC',
    'Aam Aadmi Party - AAAP',
    'All India Trinamool Congress - AITC',
    'Bharat Adivasi Party - BHRTADVSIP',
    'Communist Party of India  (Marxist) - CPI(M)',
    'Communist Party of India  (Marxist-Leninist)  (Liberation) - CPI(ML)(L)',
    'Communist Party of India - CPI',
    'Dravida Munnetra Kazhagam - DMK',	
    'Indian Union Muslim League - IUML',
    'Jammu & Kashmir National Conference - JKN',
    'Jharkhand Mukti Morcha - JMM',
    'Kerala Congress - KEC',
    'Marumalarchi Dravida Munnetra Kazhagam - MDMK',
    'Nationalist Congress Party Sharadchandra Pawar - NCPSP',
    'Rashtriya Janata Dal - RJD',
    'Rashtriya Loktantrik Party - RLTP',
    'Revolutionary Socialist Party - RSP',
    'Samajwadi Party - SP',
    'Shiv Sena (Uddhav Balasaheb Thackrey) - SHSUBT',
    'Viduthalai Chiruthaigal Katchi - VCK'
);

#NDA Allianz
update partywise_results
set party_alliance = 'NDA'
where party in (
    'Bharatiya Janata Party - BJP',
    'Telugu Desam - TDP',
    'Janata Dal  (United) - JD(U)',
    'Shiv Sena - SHS',
    'AJSU Party - AJSUP',
    'Apna Dal (Soneylal) - ADAL',
    'Asom Gana Parishad - AGP',
    'Hindustani Awam Morcha (Secular) - HAMS',
    'Janasena Party - JnP',
    'Janata Dal  (Secular) - JD(S)',
    'Lok Janshakti Party(Ram Vilas) - LJPRV',
    'Nationalist Congress Party - NCP',
    'Rashtriya Lok Dal - RLD',
    'Sikkim Krantikari Morcha - SKM'
);
#for other
update partywise_results set party_alliance ='other' where party_alliance is null;

select * from partywise_results;

#7. to write all above queries in one sing query
select party_alliance ,sum(won) from partywise_results group by party_alliance;

select party,won from partywise_results where party_alliance='I.N.D.I.A' order by won desc;
select party,won from partywise_results where party_alliance='NDA' order by won desc;

#8.wiining candidate name,their party name,total votes,and the margin of victory for specific state and constituency.
select constituencywise_results.WinningCandidate,
partywise_results.Party,
constituencywise_results.TotalVotes,
constituencywise_results.Margin,
states.State,
constituencywise_results.ConstituencyName
from constituencywise_results inner join partywise_results on constituencywise_results.PartyID=partywise_results.PartyID
inner join statewise_results on constituencywise_results.ParliamentConstituency=statewise_results.Parliament_Constituency
inner join states on statewise_results.State_ID=states.StateID 
where constituencywise_results.ConstituencyName='AGRA';

#9.what is the distribution of EVM votes vs postal votes for candidates in a specific constituency
select * from constituencywise_results;

SELECT
    cd.Candidate,
    cd.Party,
    cd.EVMVotes,
    cd.PostalVotes,
    cd.TotalVotes,
    cr.ConstituencyName
FROM 
    constituencywise_results cr
JOIN
    constituencywise_details cd ON cd.ConstituencyID = cr.ConstituencyID where cr.ConstituencyName='AMROHA';


#10. which parties won the most seats in s state ,and how many seats did each party win?
select pr.party,count(cr.ConstituencyID) as Seats_won from constituencywise_results cr join partywise_results pr on cr.PartyID=pr.PartyID
join statewise_results sr on cr.ParliamentConstituency=sr.Parliament_Constituency
join states s on sr.State_ID=s.StateID where s.State='Andhra Pradesh' group by pr.Party order by Seats_won desc limit 1;

#11.what is the total no of seats won by each party alliance in each state for election 2024?
select s.State,
sum(case when pr.party_alliance='NDA' then 1 else 0 end) as NDA_seats_won,
sum(case when pr.party_alliance='I.N.D.I.A' then 1 else 0 end) as INDIA_seats_won,
sum(case when pr.party_alliance='other' then 1 else 0 end)as Other_seats_won
from  constituencywise_results cr join partywise_results pr on cr.PartyID=pr.PartyID
join statewise_results sr on cr.ParliamentConstituency=sr.Parliament_Constituency
join states s on sr.State_ID=s.StateID
group by s.State;

#12. which candidate received the highest no of evm votes in each constituency top 10?
select
cr.ConstituencyName,cd.ConstituencyID,cd.Candidate,cd.EVMVotes
from constituencywise_details cd  join constituencywise_results cr on cd.ConstituencyID=cr.ConstituencyID
where cd.EVMVotes=(select max(cd1.EVMVotes)from constituencywise_details cd1 where cd1.ConstituencyID=cd.ConstituencyID)
order by cd.EVMVotes desc limit 10;

#13.which candidate won and which candidate was runner up in each constituency of state in 2024 election
WITH RankedCandidates AS (
    SELECT 
        cd.Constituency_ID,
        cd.Candidate,
        cd.Party,
        cd.EVM_Votes,
        cd.Postal_Votes,
        cd.EVM_Votes + cd.Postal_Votes AS Total_Votes,
        ROW_NUMBER() OVER (PARTITION BY cd.Constituency_ID ORDER BY cd.EVM_Votes + cd.Postal_Votes DESC) AS VoteRank
    FROM 
        constituencywise_details cd
    JOIN 
        constituencywise_results cr ON cd.Constituency_ID = cr.Constituency_ID
    JOIN 
        statewise_results sr ON cr.Parliament_Constituency = sr.Parliament_Constituency
    JOIN 
        states s ON sr.State_ID = s.State_ID
    WHERE 
        s.State = 'Maharashtra'
)

SELECT 
    cr.Constituency_Name,
    MAX(CASE WHEN rc.VoteRank = 1 THEN rc.Candidate END) AS Winning_Candidate,
    MAX(CASE WHEN rc.VoteRank = 2 THEN rc.Candidate END) AS Runnerup_Candidate
FROM 
    RankedCandidates rc
JOIN 
    constituencywise_results cr ON rc.Constituency_ID = cr.Constituency_ID
GROUP BY 
    cr.Constituency_Name
ORDER BY 
    cr.Constituency_Name;



#14.for the state of maharashtra ,what are the total no of seats,total no of candidates,total no of parties,
#total votes(including evm and postal),breakdown of evm and postal votes ?
SELECT 
    COUNT(cr.ConstituencyID) AS total_no_of_seats,
    COUNT(cd.Candidate) AS total_no_of_candidates,
    COUNT(pr.PartyID) AS total_no_of_parties,
    SUM(cd.TotalVotes) AS total_votes,
    SUM(cd.EVMVotes) AS evm_votes,
    SUM(cd.PostalVotes) AS postal_votes
FROM 
    constituencywise_details cd
JOIN 
    constituencywise_results cr ON cd.ConstituencyID = cr.ConstituencyID
JOIN 
    partywise_results pr ON pr.PartyID = cr.PartyID
WHERE 
    cr.ConstituencyName = 'Maharashtra';

