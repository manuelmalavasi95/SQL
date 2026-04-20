/*
The purpose of this project is to analyze a chemical dataset about Anabolic Steroids which includes 48 compounds. This analysis enables to explore their dual nature, i.e. both their therapeutic benefits and their misuse (and abuse) in sports and bodybuilding environments.
This dataset, in fact, represents a comprehensive view of them and offers opportunities both for exploratory analysis and domain-specific insights.

Exploratory Data Analysis (EDA):

- Analyze trends in medicinal vs. non-medicinal use;

- Study correlations between molecular mass and reported side effects;

Domain-Specific Insights:

- Investigate patterns in therapeutic uses versus abuse potential;

- Brief historical analysis about steroids development processes.
*/


-- Step 1: Exploration of the dataset
SELECT * FROM dbo.anabolic_steroids;

/*
As we can see, the dataset involves column descriptors which provide detailed information on steroids, in particular:

- Original Name: the scientific or chemical name of the steroid compound (e.g., Testosterone).
- Common Name: the popular or brand name under which the steroid is marketed (e.g., Testoviron).
- Medicinal Use: approved therapeutic applications of the steroid (e.g., treating anemia or hormone replacement therapy).
- Abused For: non-medical uses, often associated with performance enhancement or bodybuilding (e.g., bulking cycles, lean muscle retention).
- Side Effects: documented adverse effects resulting from steroid use or abuse (e.g., liver toxicity, gynecomastia).
- History: it is reported a brief historical context about the steroid's development or usage (e.g., year introduced, medical approval status).
- Relative Molecular Mass (g/mol): the molar mass of the steroid compound, useful for chemical analysis.

We can also see that in some cases information referring to all the indicated items is missing, in particular within the first ten rows (i.e., 'Unknown' or 'NULL' values): therefore, we decided not to consider them into the analysis, as their presence would not contribute anything to it in terms of informative insights. 
Other steroids for which only some information is not available are still considered in this work. 

Thus, the overall analysis actually focuses on 38 steroid compounds.
*/


-- Step 2: Removing rows with not informative entries (first ten rows)
WITH CTE AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as R_N
    FROM dbo.anabolic_steroids
)
DELETE FROM dbo.anabolic_steroids
WHERE 
    (Medicinal_Use = 'Unknown' OR Medicinal_Use IS NULL)
AND (Abused_For = 'Unknown' OR Abused_For IS NULL)
AND (Side_Effects = 'Unknown' OR Side_Effects IS NULL);

SELECT * FROM dbo.anabolic_steroids;


-- Step 3: EDA starting --> Medical vs. Non-Medical Use 
-- Searching duplicate values first
SELECT Original_Name, COUNT(*) as c
FROM dbo.anabolic_steroids
GROUP BY Original_Name
ORDER BY c DESC;

-- Remove the only duplicate value present
WITH CTE_2 AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY Original_Name ORDER BY Original_Name) as rn
    FROM dbo.anabolic_steroids
)
DELETE FROM CTE_2
WHERE rn > 1;

SELECT * FROM dbo.anabolic_steroids;
-- Now the overall analysis includes 37 steroid compounds. 

-- Medical Use distribution
SELECT 
    Medicinal_Use,
    COUNT(*) as Count
FROM dbo.anabolic_steroids
GROUP BY Medicinal_Use
ORDER BY Count DESC;

-- Non-Medical Use (or Abuse) distribution
SELECT 
    Abused_For,
    COUNT(*) as Count
FROM dbo.anabolic_steroids
GROUP BY Abused_For
ORDER BY Count DESC;

-- Side Effects distribution
SELECT 
    Side_Effects,
    COUNT(*) as Count
FROM dbo.anabolic_steroids
GROUP BY Side_Effects
ORDER BY Count DESC;

/*
We note from this first comparison of the different trends that the dataset contains more entries labeled for non-medical purposes, specifically for sports performance enhancement.
Among the side effects, most are unknown but other common ones concern acne, gynecomastia and mood changes, with an increased tendency towards an aggressive behavior. 
*/


-- Step 4: Exploratory grouping of molecular mass by side effect category

/*
Due to the categorical nature of side effects, correlation is explored just through grouping and comparison rather than formal statistical coefficients.
*/

-- Data cleaning
SELECT 
    Relative_Molecular_Mass_g_mol,
    Side_Effects
FROM dbo.anabolic_steroids
WHERE Relative_Molecular_Mass_g_mol IS NOT NULL
AND Side_Effects IS NOT NULL;

-- Analysis starts here
SELECT 
    Side_Effects,
    ROUND(AVG(Relative_Molecular_Mass_g_mol), 2) as avg_mm,
    COUNT(*) as n
FROM dbo.anabolic_steroids
WHERE Relative_Molecular_Mass_g_mol IS NOT NULL
AND Side_Effects IS NOT NULL
GROUP BY Side_Effects
ORDER BY avg_mm DESC;

-- General Distribution: the division in "low", "medium" and "high" is arbitrary in this case
SELECT 
    CASE 
        WHEN Relative_Molecular_Mass_g_mol < 28000 THEN 'Low'
        WHEN Relative_Molecular_Mass_g_mol BETWEEN 28000 AND 29000 THEN 'Medium'
        ELSE 'High'
    END as Mass_category,
    COUNT(*) as Count
FROM dbo.anabolic_steroids
WHERE Relative_Molecular_Mass_g_mol IS NOT NULL
GROUP BY 
    CASE 
        WHEN Relative_Molecular_Mass_g_mol < 28000 THEN 'Low'
        WHEN Relative_Molecular_Mass_g_mol BETWEEN 28000 AND 29000 THEN 'Medium'
        ELSE 'High'
    END;
-- Molecular mass values appear unusually high here and may reflect dataset-specific scaling.

-- Crossed Effects
SELECT 
    CASE 
        WHEN Relative_Molecular_Mass_g_mol < 28000 THEN 'Low'
        WHEN Relative_Molecular_Mass_g_mol BETWEEN 28000 AND 29000 THEN 'Medium'
        ELSE 'High'
    END as Mass_category,
    Side_Effects,
    COUNT(*) as Count
FROM dbo.anabolic_steroids
WHERE Relative_Molecular_Mass_g_mol IS NOT NULL
AND Side_Effects IS NOT NULL
GROUP BY 
    CASE 
        WHEN Relative_Molecular_Mass_g_mol < 28000 THEN 'Low'
        WHEN Relative_Molecular_Mass_g_mol BETWEEN 28000 AND 29000 THEN 'Medium'
        ELSE 'High'
    END,
    Side_Effects
ORDER BY Mass_category, Count DESC;

/*
Some side effects are reported as "unknown", but for the other ones it is possible to say that some higher molecular mass compounds appear associated with specific side effects, such as acne, gynecomastia, night sweats and aggressive behavior.
*/


-- Step 5: Domain-Specific Analysis --> Investigation of patterns in therapeutic uses versus abuse potential
-- Creation of a logic column
SELECT *,
    CASE 
    WHEN Medicinal_Use <> 'Unknown' AND Abused_For <> 'Unknown' THEN 'Dual-use'
    WHEN Medicinal_Use <> 'Unknown' AND Abused_For = 'Unknown' THEN 'Therapeutic-only'
    WHEN Medicinal_Use = 'Unknown' AND Abused_For <> 'Unknown' THEN 'Abuse-only'
    ELSE 'Unknown'
    END AS Patterns
INTO anabolic_steroids_patterns
FROM dbo.anabolic_steroids;

-- Types Distribution 
SELECT 
    Patterns,
    COUNT(*) as Count
FROM anabolic_steroids_patterns
GROUP BY Patterns;
-- All compounds in the dataset show abuse potential, while only a subset (28/37) also have recognized medicinal applications. Most of the abuse potential is associated with performance enhancement, suggesting a strong link between chemical development and sports misuse.

-- Distribution of side effects
SELECT 
    Patterns,
    COUNT(*) as Reported_side_effects
FROM anabolic_steroids_patterns
WHERE Side_Effects IS NOT NULL AND Side_Effects <> 'Unknown'
GROUP BY Patterns;
-- It is reported how many steroids have known side effects, divided by category.


-- Molecular Mass vs Use
SELECT 
    Patterns,
    ROUND(AVG(Relative_Molecular_Mass_g_mol), 2) as avg_mass
FROM anabolic_steroids_patterns
WHERE Relative_Molecular_Mass_g_mol IS NOT NULL
GROUP BY Patterns;

-- Abuse Distribution
SELECT 
    Abused_For,
    COUNT(*) as Count
FROM anabolic_steroids_patterns
WHERE Abused_For IS NOT NULL
GROUP BY Abused_For
ORDER BY Count DESC;

-- Use vs Abuse
SELECT 
    Patterns,
    Abused_For,
    COUNT(*) as Count
FROM anabolic_steroids_patterns
GROUP BY Patterns, Abused_For
ORDER BY Count DESC;


-- Average number of side effects per compound
SELECT 
    Patterns,
    AVG(LEN(Side_Effects) - LEN(REPLACE(Side_Effects, ',', '')) + 1) AS avg_Side_Effects
FROM anabolic_steroids_patterns
WHERE Side_Effects IS NOT NULL AND Side_Effects <> 'Unknown'
GROUP BY Patterns;
-- Compounds classified as ‘Dual-use’ tend to have a higher average number of reported side effects within this dataset.


-- Step 6: Brief historical analysis
SELECT History, COUNT(*) 
FROM dbo.anabolic_steroids
GROUP BY History
ORDER BY History;



-- Step 7: Limitations and Conclusions
/*
The dataset here considered is relatively small (i.e. only 48 compounds), some values are missing or labeled as "unknown" and, as said before, the correlation analysis is only exploratory: therefore, results should be interpreted as indicative patterns rather than general conclusions. 

With that being said, however, the analysis still allows to draw some conclusions: 
1. The dataset highlights the inherent dual-use nature of anabolic steroids: while many compounds have legitimate therapeutic applications, all of them are also associated with abuse contexts;
2. Compounds classified as abuse-only show a different side effects profile compared to dual-use ones;
3. No clear linear relationship between molecular mass and side effects is observed;
4. Brief historical analysis shows an increased development after mid-20th century.
*/