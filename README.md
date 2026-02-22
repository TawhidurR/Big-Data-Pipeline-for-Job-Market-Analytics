# Big Data Pipeline for Job Market Analytics
### Skill Classification and Demand Prediction Using Hadoop & PySpark

---

## Overview

This project implements an end-to-end big data pipeline to analyze the [1.3M LinkedIn Jobs & Skills dataset](https://www.kaggle.com/datasets/asaniczka/1-3m-linkedin-jobs-and-skills-2024) from Kaggle. The pipeline spans two phases: distributed data ingestion and storage (Phase I), followed by machine learning implementation and analysis (Phase II).

---

## Dataset

- **Source:** Kaggle – "1.3M LinkedIn Jobs & Skills 2024" by A. Saniczka
- **Size:** ~1.3 million job postings, 673 MB
- **Files:**
  - `linkedin_job_postings.csv` – Job metadata (title, company, location, level, type)
  - `job_skills.csv` – Skills associated with each posting
  - `job_summary.csv` – Additional summary and NER data
- **Industries Covered:** Healthcare, IT, Retail, Education, Manufacturing, Finance, and more

---

## Phase I: Data Ingestion & Problem Formulation

### Stack
- **Storage:** Hadoop HDFS 3.2.1
- **Containerization:** Docker 28.5.1 with `bde2020/hadoop-namenode` and `bde2020/hadoop-datanode` images
- **Processing:** Python / Pandas (EDA and cleaning)

### What Was Done

**Hadoop Cluster Setup**
- Deployed a NameNode + DataNode cluster via Docker Compose
- NameNode web UI accessible at `http://localhost:9870`
- Configured capacity: 1006.85 GB

**Data Cleaning (Pandas)**
- Loaded and merged three CSV files
- Handled missing values (4% in `job_skills`); no duplicates found
- Normalized boolean flags, text columns, and skill strings
- Parsed skills into structured lists; computed `skill_count` per posting
- Output: `linkedin_jobs_cleaned.csv` (1,427 MB), 1,348,454 rows, 17 columns, 2,772,601 unique skills

**Data Ingestion**
- Custom bash script (`data_ingestion.sh`) streams data directly to HDFS
- Upload time: ~4.9 seconds for 673 MB
- Verified via HDFS file listing, size comparison, and data readability checks
- HDFS path: `/project/data/linkedin/raw/job_skills.csv`

**Exploratory Data Analysis (10 Steps)**
1. Dataset structure and schema inspection
2. Summary statistics for numeric columns
3. Missing value analysis
4. Skill count distribution
5. Top 50 most in-demand skills
6. Skills by job level (Associate vs. Mid-Senior)
7. Skills by job type (Onsite, Remote, Hybrid)
8. Job title length vs. skill count correlation
9. Top companies and locations by posting volume
10. Correlation heatmap of numeric metadata flags

---

## Phase II: Machine Learning Implementation

### Stack
- **Processing:** PySpark (local mode, `local[*]`)
- **ML Library:** PySpark MLlib
- **Visualization:** Matplotlib, Seaborn

### Data Cleaning (Reimplemented in PySpark)
- Processed 1,348,488 rows in **20 seconds**
- Removed 25 duplicate records; retained 1,348,463 rows
- Applied all Phase I cleaning steps via distributed DataFrame operations
- Added structured `skills_list` array column and `skill_count` integer column

### Machine Learning Problems

#### Problem 1 – Job Category Classification *(Multi-class Classification)*
- **Goal:** Automatically categorize postings into Tech, Healthcare, or Other
- **Features:** `skill_count`, `job_level` (indexed), `job_type` (indexed)
- **Model:** RandomForestClassifier (25 trees), trained on 2% sample (~26,900 instances)
- **Results:**

| Metric | Value |
|--------|-------|
| Accuracy | 0.6333 |
| Precision (weighted) | 0.6348 |
| Recall (weighted) | 0.6333 |
| F1-Score (weighted) | 0.6335 |

#### Problem 2 – Skill Demand Prediction *(Regression)*
- **Goal:** Predict how frequently a skill appears across job postings
- **Features:** Skill name length (`skill_len`)
- **Model:** LinearRegression (baseline)
- **Results:**

| Metric | Value |
|--------|-------|
| RMSE | 4433.42 |
| R² | 0.0006 |

> **Note:** Near-zero R² confirms that skill name length has no predictive value. Future work should use TF-IDF, word embeddings, and co-occurrence features.

#### Problem 3 – Skill Co-occurrence Clustering *(Unsupervised)*
- **Goal:** Identify natural skill groupings by frequency and name length
- **Features:** `freq` (occurrence count), `skill_len`
- **Model:** K-Means (K=5, selected via elbow/silhouette method)
- **Results:**

| Metric | Value |
|--------|-------|
| Silhouette Score | 0.9924 |

Five clusters identified: Universal Soft Skills → Core Technical → Common Professional → Emerging/Niche → Rare Specialized

#### Problem 4 – Rare Skill Detection *(Anomaly Detection / Binary Classification)*
- **Goal:** Identify skills appearing fewer than 10 times (rare/emerging)
- **Features:** `skill_len`, `freq`
- **Model:** RandomForestClassifier (20 trees)
- **Results:**

| Metric | Value |
|--------|-------|
| Precision | 1.0000 |
| Recall | 1.0000 |
| F1-Score | 1.0000 |

---

## Key Findings

- **Communication** is the most demanded skill, appearing in 27.4% of all job postings
- Soft skills dominate the top 10 (communication, customer service, teamwork, leadership)
- Average job posting requires **~20 skills** (median: 18, range: 0–463)
- **New York, NY** leads geographically with 13,435 postings; **London** ranks second
- **Health eCareers** and **TravelNurseSource** are the top posting companies, reflecting healthcare sector dominance
- 89.3% of postings are labeled Mid-Senior level
- Job title length has essentially zero correlation with skill complexity (r = –0.007)

---

## Recommendations

**Job Seekers:** Prioritize communication, teamwork, and customer service. Aim for 15–25 skills total. Target major metro areas or seek remote roles.

**Educational Institutions:** Allocate ~30–40% of curriculum to soft skills. Use the five-tier skill taxonomy for program structure. Track rare skills for emerging curriculum updates.

**Employers:** Cap required skill lists at 15–25 to avoid restricting candidate pools. Standardize skill naming in postings. Consider remote options to expand the talent pool.

---

## Project Structure

```
project/
├── phase1/
│   ├── data_ingestion.sh          # HDFS ingestion script
│   ├── cleaning_eda.ipynb         # Pandas cleaning and EDA
│   └── docker-compose.yml         # Hadoop cluster config
├── phase2/
│   ├── cleaning_pyspark.ipynb     # PySpark data cleaning
│   ├── eda_pyspark.ipynb          # PySpark EDA (10 steps)
│   ├── ml_classification.ipynb    # Problem 1: Classification
│   ├── ml_regression.ipynb        # Problem 2: Regression
│   ├── ml_clustering.ipynb        # Problem 3: Clustering
│   └── ml_anomaly.ipynb           # Problem 4: Rare skill detection
└── README.md
```

---

## Setup & Running

### Prerequisites
- Docker & Docker Compose
- Python 3.8+
- Java 11 (for PySpark)
- PySpark, Pandas, Matplotlib, Seaborn

### Phase I – Start Hadoop Cluster
```bash
docker-compose up -d
# Verify at http://localhost:9870
bash data_ingestion.sh ~/data/linkedin/job_skills.csv
```

### Phase II – Run PySpark Pipeline
```bash
pip install pyspark matplotlib seaborn
jupyter notebook phase2/cleaning_pyspark.ipynb
```

---

## References

1. A. Saniczka, "1.3M LinkedIn Jobs & Skills 2024," Kaggle, 2024.
2. Apache Spark – [SQL & DataFrame Guide](https://spark.apache.org/docs/latest/sql-programming-guide.html)
3. Apache Spark – [MLlib Guide](https://spark.apache.org/docs/latest/ml-guide.html)
4. Apache Hadoop – [Single Node Cluster Setup](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SingleCluster.html)
5. Docker – [Docker Compose Overview](https://docs.docker.com/compose/)

