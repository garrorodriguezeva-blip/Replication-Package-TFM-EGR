# Words After the Decision

**Does ECB Communication Sentiment Move Core and Periphery Sovereigns Differently?**

Replication package for the Master's thesis (TFM) of **Eva Garro Rodríguez**, Master's in Economics, Universitat de València. Supervisor: Prof. Carles Bretó.

---

## Overview

The thesis asks whether the *sentiment* of what the European Central Bank says at its post-meeting press conference moves euro-area sovereign yields over and above the policy decision already published in the press release, and whether that effect differs between **periphery** (Italy, Spain) and **core** (Germany, France) sovereigns.

It brings the text channel of Gorodnichenko, Pham & Talavera (2023), *"The Voice of Monetary Policy"* (AER), from the Fed to the ECB and adds a core–periphery split that the original paper does not have.

| Element | Choice |
|---|---|
| Sample | 104 ECB Governing Council press conferences, 2013–2024 |
| Corpus | 1,702 introductory-statement paragraphs, 3,223 Q&A answer paragraphs |
| Treatment | Text tone from a BERT + BiLSTM classifier: `(dovish − hawkish) / (dovish + hawkish)`, neutrals excluded |
| Outcome | ΔY = conference-window minus press-release-window yield change (bp), from the EA-MPD (Altavilla et al., 2019) |
| Maturities | 10Y (baseline), 5Y and 2Y (robustness) |
| Design | Difference-in-differences, TWFE: `ΔY_im = η_i + δ_m + β(D_i × Tone_m) + γ(D_i × F_target_m) + u_im` |
| Inference | Clustered by meeting; wild cluster bootstrap |

**Main result:** an informative null. The differential effect of tone on periphery vs. core yields (β ≈ 1.01 bp at 10Y) is not statistically different from zero, and stays so across maturities and under wild-cluster-bootstrap inference, while the predetermined Target factor control does move yields as expected.

---

## Repository structure

```
Replication-Package-TFM-EGR/
├── Python Codes/Big Data/        # Notebooks: corpus construction and tone measures
├── XLSX/                         # Main data files used in the thesis
├── CSV files/                    # CSV versions of key inputs/outputs
└── Big Data Checks/              # Outputs of the alternative tone measures (validation)
```

### `Python Codes/Big Data/`

| Notebook | What it does | Main output |
|---|---|---|
| `ECB DATABASE SCRIPT.ipynb` | Scrapes and parses the ECB press-conference transcripts (2013–2024). Splits the Q&A using the HTML structure (questions in italics, answers after a bold speaker tag) and paragraph-level text. | `ECB_TEXT (2013-2024)_v2.xlsx` |
| `Text_Model_ECB_Adapted.ipynb` | **Main tone measure.** BERT + BiLSTM classifier trained on Fed-labelled sentences (GPT, 2023) and applied to every ECB paragraph (hawkish / neutral / dovish). Runs in Google Colab (GPU). | `output_textmodel_ECB_v2.xlsx` |
| `Tone variable GPT.ipynb` | Aggregates paragraph labels to one tone score per conference: statement (`w_tone`), Q&A (`qa_tone`) and pooled (`all_tone`). | `output_textmodel_ECB_v2_conference.xlsx` |
| `Finbert_ECB.ipynb` | Validation: FinBERT (`ProsusAI/finbert`) positive / negative / neutral scores. | `output_finbert_ECB_v2*.xlsx` |
| `Search_and_count_ECB.ipynb` | Validation: dictionary-based hawkish / dovish search-and-count. | `output_search_count_ECB_v2.xlsx` |
| `sentiment intensity ECB.ipynb` | Validation: sentence-embedding (`all-mpnet-base-v2`) cosine similarity to a dovish–hawkish dimension. | `output_sentiment_intensity_ECB_v2.xlsx` |

### `XLSX/`

| File | Content |
|---|---|
| `ECB_TEXT (2013-2024)_v2.xlsx` | Corpus. Sheets: `remarks` (104 statements), `remarks_para` (1,702 paragraphs), `answers` (Q&A items), `answers_para` (3,223 paragraphs). |
| `output_textmodel_ECB_v2.xlsx` | Paragraph-level classifier output: label and `p_hawkish`, `p_neutral`, `p_dovish`. |
| `output_textmodel_ECB_v2_conference_final.xlsx` | Conference-level tone: `w_tone`, `qa_tone`, `all_tone` (104 rows). |
| `panel_final_all_maturities.xlsx` | **Estimation panel.** `combined` (all maturities, 1,248 rows) and one sheet per maturity (`panel_10Y`, `panel_5Y`, `panel_2Y`; 104 meetings × 4 countries). `Graphs` holds yield changes by country for figures. |
| `voicetone_ecb.xlsx` | Voice-tone pilot: emotion probabilities for the 13 Q&A answers of the 12 March 2020 press conference (thesis Appendix A). |

### `CSV files/`

| File | Content |
|---|---|
| `ecb_urls_master_2013_2024.csv` | URL of each of the 104 press conferences (`target_date`, `url`, `source`), input to the scraper. |
| `panel_final_all_maturities.csv` | CSV copy of the estimation panel. |
| `ecb_voicetone.csv` | Voice-tone pilot output, with standard deviations across windows. |

### `Big Data Checks/`

Outputs of the alternative tone measures (FinBERT, search-and-count, sentiment intensity) and a copy of the main classifier output, used to validate the BERT + BiLSTM tone.

---

## Panel variables

| Variable | Description |
|---|---|
| `date` | Governing Council meeting date |
| `maturity` | 2Y, 5Y or 10Y |
| `country` | DE, FR (core); IT, ES (periphery) |
| `D_i` | 1 = periphery, 0 = core |
| `dY` | Conference-window minus press-release-window yield change (bp) |
| `all_tone`, `qa_tone` | Conference tone: pooled statement + Q&A, Q&A only |
| `F_target` | EA-MPD Target factor (press-release window, predetermined) |
| `D_i_x_*` | Interactions with `D_i` |

---

## How to replicate

1. **Corpus.** Run `ECB DATABASE SCRIPT.ipynb` with `ecb_urls_master_2013_2024.csv` → `ECB_TEXT (2013-2024)_v2.xlsx`.
2. **Tone.** Run `Text_Model_ECB_Adapted.ipynb` in Google Colab (GPU) → paragraph labels. Then `Tone variable GPT.ipynb` → conference-level tone.
3. **Validation (optional).** Run the FinBERT, search-and-count and sentiment-intensity notebooks.
4. **Panel.** Merge conference tone with EA-MPD yield changes and the Target factor → `panel_final_all_maturities.xlsx` (already provided).
5. **Estimation.** Estimate the TWFE equation on each `panel_*Y` sheet with meeting fixed effects and errors clustered by meeting, plus a wild cluster bootstrap. The thesis uses Stata (`areg …, absorb(meeting_id) vce(cluster meeting_id)` and `boottest`).

> **Paths.** Some notebooks keep local (`C:/Users/...`) or Colab (`/content/drive/MyDrive/...`) paths. Change them to your own folders before running.

### Not included in this repository

- **EA-MPD** (Altavilla et al., 2019): public, download it from the ECB website.
- **Fed training data** for the classifier (`FED_classification.csv`) and the dovish/hawkish dictionary: from the replication package of Gorodnichenko, Pham & Talavera (2023), openICPSR project 178302.
- **Voice-tone audio data** (RAVDESS, TESS) and the ECB press-conference audio.

---

## Software

| Task | Tools |
|---|---|
| Scraping | Python: `requests`, `beautifulsoup4`, `pandas` |
| Text classifier | Google Colab (GPU), TensorFlow + `tf-keras`, `transformers==4.40.0`, `scikit-learn` |
| Validation | `torch`, `transformers` (FinBERT), `nltk`, `sentence-transformers` |
| Estimation | Stata (`areg`, `boottest`, `esttab`) |
| Thesis | R / knitr, LaTeX |

---

## References

- Altavilla, C., Brugnolini, L., Gürkaynak, R. S., Motto, R., & Ragusa, G. (2019). Measuring Euro Area Monetary Policy. *Journal of Monetary Economics*, 108, 162–179.
- Gorodnichenko, Y., Pham, T., & Talavera, O. (2023). The Voice of Monetary Policy. *American Economic Review*, 113(2), 548–584.
- de Chaisemartin, C., & D'Haultfœuille, X. (2020). Two-Way Fixed Effects Estimators with Heterogeneous Treatment Effects. *American Economic Review*, 110(9), 2964–2996.
- Roodman, D., MacKinnon, J. G., Nielsen, M. Ø., & Webb, M. D. (2019). Fast and Wild: Bootstrap Inference in Stata Using boottest. *The Stata Journal*, 19(1), 4–60.

---

## Citation

```
Garro Rodríguez, E. (2026). Words After the Decision: Does ECB Communication
Sentiment Move Core and Periphery Sovereigns Differently? Master's thesis,
Universitat de València.
```

## Contact

Eva Garro Rodríguez · garrorodriguezeva@gmail.com
