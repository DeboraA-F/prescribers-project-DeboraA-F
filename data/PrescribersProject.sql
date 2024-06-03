--Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims
SELECT npi, 
	   ROUND(AVG(total_claim_count),1)
FROM prescriber
	INNER JOIN prescription USING(npi)
GROUP BY npi, total_claim_count
ORDER BY total_claim_count DESC;

--Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT DISTINCT nppes_provider_first_name, 
				nppes_provider_last_org_name, 
				specialty_description, 
				total_claim_count
FROM prescriber
	INNER JOIN prescription USING(npi)
ORDER BY total_claim_count DESC;

--Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description, 
	   ROUND(AVG(total_claim_count),1)
FROM prescriber
	INNER JOIN prescription USING(npi)
GROUP BY specialty_description;

--Which specialty had the most total number of claims for opioids?
SELECT specialty_description, 
	   COUNT(opioid_drug_flag) AS number_of_opioid_drugs
FROM prescriber
	INNER JOIN prescription USING(npi)
	INNER JOIN drug USING(drug_name)
GROUP BY specialty_description;



--**Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?--

SELECT DISTINCT specialty_description, 
	   total_claim_count
FROM prescriber
FULL JOIN prescription USING(npi)
WHERE total_claim_count IS NULL;


--**Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?--
WITH total_claims AS
					(SELECT specialty_description,
	   					   SUM(total_claim_count)AS sum_total_claim_count
					FROM prescriber
							INNER JOIN prescription USING(npi)
							INNER JOIN drug USING(drug_name)
					WHERE opioid_drug_flag='Y'
					GROUP BY specialty_description)
SELECT specialty_description,
	   ROUND((total_claims.sum_total_claim_count/(SELECT COUNT(specialty_description) FROM 		prescriber))*100,2) AS percentage_of_opioid
FROM total_claims
ORDER BY percentage_of_opioid DESC;

;


--Which drug (generic_name) had the highest total drug cost?
SELECT generic_name, 
	   total_drug_cost
FROM prescription
	INNER JOIN drug USING(drug_name)
ORDER BY total_drug_cost DESC
LIMIT 10;

--Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT generic_name,
	   ROUND(MAX(total_drug_cost/total_day_supply),2) AS cost_per_day
FROM drug
	LEFT JOIN prescription USING(drug_name)
WHERE total_drug_cost IS NOT NULL
GROUP BY generic_name
ORDER BY cost_per_day DESC;


--For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/
SELECT drug_name,
	CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
		WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug;

--Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT drug_type, 
	   ROUND(AVG(total_drug_cost),1) AS MONEY 
FROM
	(SELECT drug_name,
		CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
		WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
	 FROM drug) AS drug_type
	LEFT JOIN prescription USING(drug_name) 
WHERE drug_type NOT LIKE 'neither'
GROUP BY drug_type;


--How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(cbsa)
FROM cbsa
WHERE cbsaname ILIKE '%TN%';

--Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsaname, 
	   SUM(population)
FROM cbsa
	INNER JOIN fips_county USING(fipscounty)
	INNER JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER BY sum DESC;

--What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT county, 
	   population
FROM population
	LEFT JOIN fips_county USING(fipscounty)
	LEFT JOIN cbsa USING(fipscounty)
WHERE cbsa IS NULL
ORDER BY population DESC;


--Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, 
	   total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

--For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name, 
	   total_claim_count,
	   opioid_drug_flag
FROM prescription
	INNER JOIN drug USING(drug_name)
WHERE total_claim_count >= 3000;

--Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT nppes_provider_first_name,
	   nppes_provider_last_org_name
	   drug_name, 
	   total_claim_count,
	   opioid_drug_flag
FROM prescription
	INNER JOIN drug USING(drug_name)
	LEFT JOIN prescriber USING(npi)
WHERE total_claim_count >= 3000;


--First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.	
SELECT npi,
	   drug_name
FROM prescriber
	CROSS JOIN drug 
WHERE nppes_provider_city = 'NASHVILLE' 
	AND opioid_drug_flag = 'Y'
	AND specialty_description = 'Pain Management';

--Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT prescriber.npi,
	   drug.drug_name,
		SUM(total_claim_count)
FROM prescriber
	CROSS JOIN drug
	LEFT JOIN prescription USING(drug_name)
WHERE nppes_provider_city = 'NASHVILLE' 
	AND opioid_drug_flag = 'Y'
	AND specialty_description = 'Pain Management'
GROUP BY prescriber.npi, drug.drug_name;

--Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT prescriber.npi,
	   drug.drug_name,
	   COALESCE(SUM(total_claim_count),0) AS total_claim_count
FROM prescriber
	CROSS JOIN drug
	LEFT JOIN prescription USING(drug_name)
WHERE nppes_provider_city = 'NASHVILLE' 
	AND opioid_drug_flag = 'Y'
	AND specialty_description = 'Pain Management'
GROUP BY prescriber.npi, drug.drug_name;


--GROUPING SETS--
--Write a query which returns the total number of claims for these two groups. Your output should look like this: 
specialty_description         |total_claims|
------------------------------|------------|
Interventional Pain Management|       55906|
Pain Management               |       70853|;

SELECT specialty_description,
	   SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription USING(npi)
WHERE specialty_description LIKE'%Pain Management%'
GROUP BY specialty_description;

--Now, let's say that we want our output to also include the total number of claims between these two groups. Combine two queries with the UNION keyword to accomplish this. Your output should look like this:

specialty_description         |total_claims|
------------------------------|------------|
                              |      126759|
Interventional Pain Management|       55906|
Pain Management               |       70853|;

(SELECT '' AS specialty_description, SUM(total_claims)
 FROM
	(SELECT specialty_description,
	   SUM(total_claim_count) AS total_claims
	 FROM prescriber
		INNER JOIN prescription USING(npi)
	 WHERE specialty_description LIKE'%Pain Management%'
	 GROUP BY specialty_description))
UNION
(SELECT specialty_description,
	   SUM(total_claim_count) AS total_claims
 FROM prescriber
	INNER JOIN prescription USING(npi)
 WHERE specialty_description LIKE'%Pain Management%'
 GROUP BY specialty_description);

--Now, instead of using UNION, make use of GROUPING SETS (https://www.postgresql.org/docs/10/queries-table-expressions.html#QUERIES-GROUPING-SETS) to achieve the same output.
SELECT specialty_description,
	   SUM(total_claim_count) AS total_claims
FROM prescriber
	INNER JOIN prescription USING(npi)
WHERE specialty_description LIKE'%Pain Management%'
GROUP BY GROUPING SETS(specialty_description, total_claim_count,());

--In addition to comparing the total number of prescriptions by specialty, let's also bring in information about the number of opioid vs. non-opioid claims by these two specialties. Modify your query (still making use of GROUPING SETS so that your output also shows the total number of opioid claims vs. non-opioid claims by these two specialites:

specialty_description         |opioid_drug_flag|total_claims|
------------------------------|----------------|------------|
                              |                |      129726|
                              |Y               |       76143|
                              |N               |       53583|
Pain Management               |                |       72487|
Interventional Pain Management|                |       57239|;

SELECT specialty_description,
	   opioid_drug_flag,
	   SUM(total_claim_count) AS total_claims
FROM prescriber
	INNER JOIN prescription USING(npi)
	INNER JOIN drug USING(drug_name)
WHERE specialty_description LIKE'%Pain Management%' 
GROUP BY GROUPING SETS(specialty_description, total_claim_count, opioid_drug_flag,());

--Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, specialty_description). How is the result different from the output from the previous query?
SELECT specialty_description,
	   opioid_drug_flag,
	   SUM(total_claim_count) AS total_claims
FROM prescriber
	INNER JOIN prescription USING(npi)
	INNER JOIN drug USING(drug_name)
WHERE specialty_description LIKE'%Pain Management%' 
GROUP BY ROLLUP(specialty_description, total_claim_count, opioid_drug_flag);