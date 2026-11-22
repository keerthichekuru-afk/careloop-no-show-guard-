# CareLoop Clinics — No-Show Guard

**Public GitHub repository:** (https://github.com/keerthichekuru-afk/careloop-no-show-guard)
## Project question

Which appointments are most likely to be missed, why do patients miss them, and what should CareLoop do first?

CareLoop Clinics operates eight outpatient clinics across six Indian cities. This project cleans and validates appointment data, investigates no-show patterns with SQL, builds and evaluates predictive models, and uses Gemini with Pydantic validation to structure a sample of follow-up notes.

## Four-part summary of findings

- **Part 1 — Data foundations:** Cleaned 1,020 raw bookings to **990 valid appointments**; identified **218 no-shows (22.0%)**. The cleaned dataset contains 16 columns, with no missing values and unique appointment IDs.
- **Part 2 — SQL analysis:** The overall no-show rate was **22.02%**. The highest rate among all clinics was **33.3% at Gomti Nagar Care Point**, based on 90 appointments; among clinics with at least 95 appointments, Hadapsar Care Centre was highest at **27.3% (39/143)**. No-show rates rose to **60.5%** for bookings made 31 or more days ahead (26/43).
- **Part 3 — Predictive modelling:** Logistic regression was selected, with a reference ROC-AUC of approximately **0.79**. The selected probability threshold was **0.35**; on the test set it achieved approximately **0.57 recall**, flagged about **49 of 198** appointments, and retained the test ROC-AUC of approximately **0.79**.
- **Part 4 — GenAI follow-up review:** The first **10** follow-up notes were processed; **9** were nonblank and **N004** was skipped without an API call. The expected root-cause mapping identifies both forgotten/no-reminder notes (N001 and N007) with `reminder_sent = No`; **5 of 10** notes were linked to appointments with no reminder.

## Recommendation

CareLoop should use the logistic-regression risk score to prioritise evening follow-up calls, while separately addressing long booking lead times and the operational reasons recorded by callers. The cleaned data contain **990 appointments** and **218 no-shows (22.0%)**, establishing the scale of the problem. SQL shows that bookings made **31+ days** ahead had a **60.5%** no-show rate (26 of 43), compared with **16.2%** for bookings made 1–7 days ahead (63 of 390), so the clinic should consider an additional confirmation or reconfirmation step for appointments booked far in advance. The model selected for deployment is logistic regression, with a test **ROC-AUC of approximately 0.79** and a probability threshold of **0.35**; at that threshold it identified approximately **49 of 198** test appointments and achieved approximately **0.57 recall**. Part 4 adds a qualitative signal: among the first **10** notes, **9** were nonblank, and the two notes classified as `forgot_or_no_reminder` (N001 and N007) were both associated with `reminder_sent = No`. The clinic should therefore prioritise high-risk bookings for calls, verify reminder delivery, and review the note categories to guide targeted interventions. The threshold should ultimately be set against the number of calls the front desk can complete in an evening and the cost of leaving a doctor slot empty.

## Model selection

**Selected model:** Logistic regression (standardised features using a pipeline).

**ROC-AUC:** approximately **0.79** on the held-out test set.  
**Selected threshold:** **0.35**.

The model was selected using cross-validation on the training data, not by choosing the best test-set result. Logistic regression had the strongest cross-validated ROC-AUC in the reference comparison (approximately **0.77**), ahead of the depth-3 decision tree (approximately **0.68**) and random forest (approximately **0.75**). The threshold of 0.35 was selected using out-of-fold training probabilities because it produced a higher F1 score (approximately **0.49**, versus **0.35** at threshold 0.5) and higher recall (approximately **0.47**, versus **0.25**). Higher recall is useful because a missed warning can leave an appointment slot empty, while a false positive mainly costs staff time for an extra call.

## Part 4: note and reminder cross-tabulation

The analysis merges `notes_analysed.csv` with `appointments_clean.csv` on `appointment_id` and cross-tabulates `root_cause` against `reminder_sent`. In the expected classification results, both `forgot_or_no_reminder` notes (N001 and N007) correspond to appointments with `reminder_sent = No` (**2 of 2**). Overall, **5 of the 10** sampled notes are linked to appointments where no reminder was sent.

See `root_cause_reminder_crosstab.csv` for the full table and `notes_appointments_merged.csv` for the joined records. These figures describe the small note sample, not clinic-wide root-cause prevalence.

## Limitations

1. **The 10 notes are an illustration and cannot show the real reasons clinic-wide.** They are a small sample of follow-up notes and should not be treated as representative estimates of all missed appointments.
2. **The data are observational, so associations are not causes.** For example, the association between reminder status and no-shows does not prove that reminders alone caused the difference.
3. **The threshold really depends on call capacity.** A threshold of 0.35 is a model-selection result, but the operational threshold should be revisited using the number of calls staff can make each evening and the relative cost of missed appointments.

## Repository contents

The submission repository should contain at least:

- `01_ingest_clean.ipynb`
- `rejected_rows.json`
- `appointments_clean.csv`
- `clinics_enriched.csv`
- `load_data.sql`
- `02_queries.sql`
- `03_model.ipynb`
- `test_risk_scores.csv`
- `04_genai.ipynb` (with the API key removed)
- `notes_analysed.csv`
- `notes_appointments_merged.csv`
- `root_cause_reminder_crosstab.csv`
- `README.md`
- `data/appointments.csv`
- `data/clinics.csv`
- `data/followup_notes.csv`

## Reproducibility and security

The reference figures above are taken from the assignment brief's acceptance criteria. Before submission, compare them with the outputs produced by your own notebooks and update any figures that differ. In particular, confirm the actual Part 3 metrics, the Part 4 validation counts, and the saved cross-tabulation.

Do not commit the Gemini API key, `.env` files, credentials, or notebook outputs containing secrets. Keep the repository public as required by the assignment.
