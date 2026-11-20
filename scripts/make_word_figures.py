"""Redraw Figs. 3-6 of the Word paper in the original MATLAB style, at print quality.

usage: python3 make_word_figures.py <results_dir> <out_dir>

Reads the MATLAB results of run_all (cliox_wue_trap_results.mat and the two sweep
.mat files). Fig. 6 additionally needs receipt_1_intervals.csv, written in MATLAB by
export_receipt_intervals (run it once in the CLIOX_Sim folder). Every number comes
from the MATLAB run; nothing is re-simulated here.

Style follows cliox_plots.m: same colours, markers, line styles, boxed axes with grid,
same panel content. Changes are for legibility only: figures are sized for the page
(Fig. 3: 6.0 in; Figs. 4-6: 5.4 in), fonts are set for print, titles and legends no
longer overlap the data, and output is 600-dpi PNG (for Word) plus vector PDF.
"""
import csv, os, sys
import numpy as np
import scipy.io as sio
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

RES, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------- MATLAB look
COND = np.array([[0.45, 0.45, 0.45], [0.90, 0.50, 0.10], [0.15, 0.45, 0.80], [0.20, 0.62, 0.30]])
IT_C, FAC_C, WAT_C = (0.62, 0.76, 0.92), (0.15, 0.45, 0.80), (0.10, 0.65, 0.70)
TRUTH_C = (0.1, 0.1, 0.1)
MARK = ['o', 's', '^', 'd', 'v']
plt.rcParams.update({
    'font.family': 'sans-serif',
    'font.sans-serif': ['Helvetica', 'Arial', 'Liberation Sans', 'DejaVu Sans'],
    'font.size': 7.5, 'axes.titlesize': 7.5, 'axes.titleweight': 'bold', 'axes.labelsize': 7.5,
    'xtick.labelsize': 7, 'ytick.labelsize': 7, 'legend.fontsize': 6.5,
    'axes.edgecolor': '0.15', 'axes.linewidth': 0.6, 'axes.grid': True,
    'grid.color': '0.85', 'grid.linewidth': 0.5, 'axes.axisbelow': True,
    'xtick.direction': 'in', 'ytick.direction': 'in', 'xtick.top': True, 'ytick.right': True,
    'xtick.major.size': 2.5, 'ytick.major.size': 2.5, 'xtick.major.width': 0.6, 'ytick.major.width': 0.6,
    'legend.frameon': True, 'legend.fancybox': False, 'legend.edgecolor': '0.15',
    'legend.framealpha': 1.0, 'legend.borderpad': 0.35, 'legend.handlelength': 2.4,
    'lines.linewidth': 1.2, 'lines.markersize': 3.6,
    'patch.edgecolor': '0.1', 'patch.linewidth': 0.5,
    'pdf.fonttype': 42, 'savefig.dpi': 600,
})

def load(name):
    return sio.loadmat(os.path.join(RES, name), squeeze_me=True, struct_as_record=False)

def save(fig, name):
    fig.savefig(os.path.join(OUT, name + '.png'), dpi=600, bbox_inches='tight', pad_inches=0.03)
    fig.savefig(os.path.join(OUT, name + '.pdf'), bbox_inches='tight', pad_inches=0.03)
    plt.close(fig)

def ptitle(ax, s):
    ax.set_title(s, pad=4)

# ================================================================ Fig. 3: WUE-trap overview
res = load('cliox_wue_trap_results.mat')['res']
est, n = res.est, np.atleast_1d(res.n)
names = [str(s).replace('Provider ', '') for s in np.atleast_1d(est.name)]
J = len(names); x = np.arange(J)
cond = [str(c) for c in np.atleast_1d(res.cfg.cond.name)]
inc = np.flatnonzero(np.atleast_1d(res.cfg.cond.include))

fig = plt.figure(figsize=(6.75, 4.1))
gs = fig.add_gridspec(2, 6, height_ratios=[1, 1.08], hspace=0.62, wspace=1.35)
axE, axW, axC = fig.add_subplot(gs[0, 0:2]), fig.add_subplot(gs[0, 2:4]), fig.add_subplot(gs[0, 4:6])
axS, axP = fig.add_subplot(gs[1, 0:3]), fig.add_subplot(gs[1, 3:6])

# (a) electricity
E, Ef = 1000 * np.atleast_1d(est.E), 1000 * np.atleast_1d(est.Ef)
bw = 0.36
axE.bar(x - bw / 2, E, bw, color=IT_C, label='IT')
axE.bar(x + bw / 2, Ef, bw, color=FAC_C, label='Facility')
for j in range(J):
    axE.text(x[j] + bw / 2, Ef[j] + 1.2, f'{Ef[j]:.1f}', ha='center', va='bottom', fontsize=6.5)
axE.set_xticks(x, names); axE.set_xlim(-0.6, J - 0.4); axE.set_ylim(0, Ef.max() * 1.3)
axE.set_xlabel('Provider'); axE.set_ylabel('Transaction electricity (Wh)')
axE.legend(loc='upper left', handlelength=1.2)
axE.grid(axis='x', visible=False)
ptitle(axE, 'Electricity: IT and facility')

# (b) water with rating
Wv = 1000 * np.atleast_1d(est.W); lab = [str(s) for s in np.atleast_1d(est.labels)]
axW.bar(x, Wv, 0.6, color=WAT_C)
for j in range(J):
    axW.text(x[j], Wv[j] + 0.4, f'{Wv[j]:.1f} mL\n({lab[j]})', ha='center', va='bottom', fontsize=6.5,
             linespacing=1.05)
axW.set_xticks(x, names); axW.set_xlim(-0.6, J - 0.4); axW.set_ylim(0, Wv.max() * 1.45)
axW.set_xlabel('Provider'); axW.set_ylabel('Transaction water (mL)')
axW.grid(axis='x', visible=False)
ptitle(axW, r'Water $W = E_{\mathrm{IT}}\times$WUE')

# (c) choice probability vs P(truly lowest)
P = np.atleast_2d(res.pChoice); truth = np.atleast_1d(res.truth.bestFreq)
series = [(P[c], COND[c], cond[c]) for c in inc] + [(truth, TRUTH_C, 'P(truly lowest)')]
k = len(series); w = 0.8 / k
for i, (v, col, nm) in enumerate(series):
    axC.bar(x - 0.4 + w * (i + 0.5), v, w, color=col, label=nm, linewidth=0.3)
axC.axhline(1 / J, color='k', ls=':', lw=0.8)
axC.set_xticks(x, names); axC.set_xlim(-0.6, J - 0.4); axC.set_ylim(0, 1.05)
axC.set_xlabel('Provider'); axC.set_ylabel('Probability')
axC.grid(axis='x', visible=False)
axC.legend(loc='upper right', handlelength=1.0, handleheight=0.7, borderpad=0.3, labelspacing=0.2,
           fontsize=5.8)
ptitle(axC, 'Choice probability')

# (d) selection accuracy with 95% single-study range (dotted)
for c in inc:
    col = COND[c]
    axS.plot(n, 100 * res.succMean[:, c], '-o', color=col, mfc=col, mec=col, label=cond[c])
    axS.plot(n, 100 * res.succLo[:, c], ':', color=col, lw=0.8)
    axS.plot(n, 100 * res.succHi[:, c], ':', color=col, lw=0.8)
axS.set_xlim(n.min(), n.max()); axS.set_ylim(10, 80)
axS.set_xlabel('Users per condition'); axS.set_ylabel('Chose truly lowest-resource\nprovider (%)')
axS.legend(loc='upper right', ncol=2, columnspacing=0.8, handlelength=2.0)
ptitle(axS, 'Selection accuracy (dotted: 95% range of one study)')

# (e) power
cmpA, cmpB = np.atleast_1d(res.cmp.a) - 1, np.atleast_1d(res.cmp.b) - 1
cmpN = [str(s) for s in np.atleast_1d(res.cmp.name)]
ctl = cond.index('Control')
for kk in range(len(cmpA)):
    col = COND[cmpA[kk]]; ls = '-' if cmpB[kk] == ctl else '--'
    axP.plot(n, res.power[:, kk], ls, marker=MARK[kk % 5], color=col, mfc=col, mec=col, label=cmpN[kk])
axP.axhline(0.9, color='0.25', ls='--', lw=0.7)
axP.axhline(0.05, color='0.25', ls=':', lw=0.7)
axP.text(560, 0.885, '90% power', ha='center', va='top', fontsize=6, color='0.25')
axP.set_xlim(n.min(), n.max()); axP.set_ylim(0, 1.02)
axP.set_xlabel('Users per condition'); axP.set_ylabel('Power')
axP.legend(loc='lower right', fontsize=6, labelspacing=0.25)
ptitle(axP, 'Power, two-sided, Holm (dashed: vs WUE only)')
save(fig, 'fig3_wue_trap_overview')

# ================================================================ Figs. 4-5: sweeps
def sweep(mat, xlabel, name, n_users=300):
    sw = load(mat)['sw']
    v = np.atleast_1d(sw.values)
    cn = [str(s) for s in np.atleast_1d(sw.condName)]
    a, b = np.atleast_1d(sw.cmpA) - 1, np.atleast_1d(sw.cmpB) - 1
    names_ = [str(s) for s in np.atleast_1d(sw.cmpName)]
    ctl_ = cn.index('Control')
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(6.2, 1.9), gridspec_kw={'wspace': 0.3})
    for k in range(len(a)):
        col = COND[a[k]]
        if b[k] == ctl_:
            ax1.plot(v, sw.power[:, k], '-o', color=col, mfc='white', mec=col, label=names_[k])
        else:
            ax1.plot(v, sw.power[:, k], '--s', color=col, mfc='white', mec=col, label=names_[k])
    ax1.set_xlim(v.min(), v.max()); ax1.set_ylim(0, 1.02)
    ax1.set_xlabel(xlabel); ax1.set_ylabel('Power')
    ax1.legend(loc='lower right', fontsize=5.8, labelspacing=0.2)
    ptitle(ax1, f'Power ({n_users} users per condition)')
    for c in range(len(cn)):
        col = COND[c]
        ax2.plot(v, 100 * sw.succ[:, c], '-o', color=col, mfc='white', mec=col, label=cn[c])
    ax2.plot(v, 100 * np.atleast_1d(sw.estimateAccuracy), 'k--', lw=1.0, label='Estimates pick true best')
    ax2.set_xlim(v.min(), v.max()); ax2.set_ylim(0, 102)
    ax2.set_xlabel(xlabel); ax2.set_ylabel('%')
    ax2.legend(loc='lower right', ncol=2, fontsize=5.6, labelspacing=0.15, columnspacing=0.6,
               handlelength=1.6, handletextpad=0.4, borderpad=0.3)
    ptitle(ax2, 'Selection and estimate accuracy')
    save(fig, name)
    return sw

sweep('cliox_wue_trap_sweep_cond_attention_4__results.mat',
      'Share of users acting on ratings (attention)', 'fig4_sweep_attention')
sweep('cliox_wue_trap_sweep_uncert_powercv_results.mat',
      'Coefficient of variation of IT-power estimates', 'fig5_sweep_powercv')

# ================================================================ Fig. 6: receipt
rpath = os.path.join(RES, 'receipt_1_intervals.csv')
if not os.path.exists(rpath):
    print('Fig. 6 skipped: receipt_1_intervals.csv not found (run export_receipt_intervals in MATLAB).')
else:
    with open(rpath, newline='') as f:
        rows = list(csv.DictReader(f))
    meta = {k: float(rows[0][k]) for k in ('Share', 'PUE', 'Epre_Wh', 'Efpre_Wh')}
    prov = rows[0]['Provider']
    t0 = np.array([float(r['tStart_s']) for r in rows]); t1 = np.array([float(r['tEnd_s']) for r in rows])
    Pk = np.array([float(r['Pk_kW']) for r in rows]); cumE = np.array([float(r['cumE_Wh']) for r in rows])
    s, pue = meta['Share'], meta['PUE']
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(6.2, 1.88), gridspec_kw={'wspace': 0.3})
    xs = np.r_[t0, t1[-1]]
    ax1.step(xs, np.r_[Pk, Pk[-1]], where='post', color=FAC_C, lw=1.2, label=r'Pool IT power $P_k$')
    ax1.step(xs, np.r_[Pk, Pk[-1]] * s, where='post', color=COND[1], lw=1.2, label=r'Allocated $P_k s_k$')
    ax1.set_xlim(0, 200); ax1.set_ylim(0, Pk.max() * 1.18)
    ax1.set_xlabel('Time (s)'); ax1.set_ylabel('kW')
    ax1.legend(loc='center right', bbox_to_anchor=(1.0, 0.36), fontsize=6)
    ptitle(ax1, f'{prov}: telemetry intervals')
    tt = np.r_[0, t1]
    ax2.plot(tt, np.r_[0, cumE], '-o', color=IT_C, mfc='white', mec=IT_C, ms=2.8, label='IT electricity')
    ax2.plot(tt, np.r_[0, cumE] * pue, '-s', color=FAC_C, mfc='white', mec=FAC_C, ms=2.8,
             label=r'Facility (IT $\times$ PUE)')
    ax2.axhline(meta['Epre_Wh'], color=IT_C, ls='--', lw=0.9)
    ax2.axhline(meta['Efpre_Wh'], color=FAC_C, ls='--', lw=0.9)
    ax2.set_xlim(0, 200); ax2.set_ylim(0, max(cumE[-1] * pue, meta['Efpre_Wh']) * 1.1)
    ax2.set_xlabel('Time (s)'); ax2.set_ylabel('Cumulative allocated\nelectricity (Wh)')
    ax2.legend(loc='lower right', fontsize=6)
    ptitle(ax2, 'Post- vs. pre-execution estimate (dashed)')
    save(fig, 'fig6_receipt')
print('figures written to', OUT)
