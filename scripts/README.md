# scripts

`make_word_figures.py` redraws Figs. 3-6 of the paper from a `run_all` results folder, in the style
of the MATLAB figures, as 600-dpi PNG and vector PDF.

```
python3 scripts/make_word_figures.py results <output_folder>
```

Requirements: Python 3 with numpy, scipy and matplotlib. Fig. 6 also reads
`receipt_1_intervals.csv` from the results folder; for a new run, create it in MATLAB with
`export_receipt_intervals('results/<timestamp>')` from the `src` folder.
