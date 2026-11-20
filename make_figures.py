"""Generate the paper's result figures (vector PDF) from a CLIOX_Sim results folder.

usage: python3 make_figures.py <results_dir> <out_dir>

Every panel is boxed (frame on all four sides) and legends are framed.
Figures are sized for IEEE two-column pages: single column 3.5 in, double 7.16 in.
Colors follow the condition, not the comparison: WUE only = orange, Numeric = blue,
Rating = aqua, Control = gray. Line style marks the reference (solid: vs Control,
dashed: vs WUE only). Markers repeat the identity so the figures survive grayscale.
"""
import csv, glob, os, sys
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

RES, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------- style
INK, INK2, MUTED, GRID = '#0b0b0b', '#52514e', '#8a8984', '#e4e3df'
BLUE, ORANGE, AQUA, GRAY = '#2a78d6', '#eb6834', '#1baf7a', '#9b9a94'
BLUE_LIGHT = '#86b6ef'
COND = {'WUE only': (ORANGE, '^'), 'Numeric': (BLUE, 's'), 'Rating': (AQUA, 'o')}
plt.rcParams.update({
    'font.family': 'sans-serif',
    'font.sans-serif': ['Liberation Sans', 'Arial', 'Helvetica', 'DejaVu Sans'],
    'font.size': 7.5, 'axes.titlesize': 7.5, 'axes.labelsize': 7.5,
    'xtick.labelsize': 7, 'ytick.labelsize': 7, 'legend.fontsize': 7,
    'axes.edgecolor': MUTED, 'axes.labelcolor': INK2, 'xtick.color': INK2, 'ytick.color': INK2,
    'text.color': INK, 'axes.linewidth': 0.6, 'xtick.major.width': 0.6, 'ytick.major.width': 0.6,
    'xtick.major.size': 2.5, 'ytick.major.size': 2.5,
    'axes.spines.top': True, 'axes.spines.right': True,
    'axes.grid': True, 'grid.color': GRID, 'grid.linewidth': 0.5,
    'axes.axisbelow': True, 'legend.frameon': True, 'legend.fancybox': False,
    'legend.edgecolor': MUTED, 'legend.framealpha': 1.0, 'patch.linewidth': 0.6,
    'pdf.fonttype': 42, 'ps.fonttype': 42, 'savefig.dpi': 600,
    'lines.linewidth': 1.3, 'lines.markersize': 3.6,
})
SINGLE, DOUBLE = 3.5, 7.16

def rcsv(path):
    with open(path, newline='', encoding='utf-8') as f:
        return list(csv.DictReader(f))
tag = lambda n: n.lower().replace(' ', '_').replace('-', '_')
def save(fig, name):
    fig.savefig(os.path.join(OUT, name + '.pdf'), bbox_inches='tight', pad_inches=0.02)
    fig.savefig(os.path.join(OUT, name + '.png'), bbox_inches='tight', pad_inches=0.02, dpi=300)
    plt.close(fig)

# ================================================================ Fig: traps
# Why partial displays mislead: the lowest bar moves when the boundary changes.
def providers(sc):
    return rcsv(f'{RES}/cliox_{tag(sc)}_providers.csv')

def bars(ax, vals, labels, title, unit, fmt):
    lo = min(range(len(vals)), key=lambda i: vals[i])
    cols = [BLUE if i == lo else '#d3d2cc' for i in range(len(vals))]
    ax.bar(range(len(vals)), vals, width=0.62, color=cols, edgecolor='white', linewidth=0.8, zorder=2)
    for i, v in enumerate(vals):
        ax.text(i, v, fmt(v), ha='center', va='bottom', fontsize=6.8,
                color=INK if i == lo else INK2, fontweight='bold' if i == lo else 'normal')
    ax.set_xticks(range(len(vals)), labels)
    ax.set_title(title, loc='left', pad=3)
    ax.set_ylabel(unit)
    ax.set_ylim(0, max(vals) * 1.22)
    ax.grid(axis='x', visible=False)
    ax.tick_params(axis='x', length=0)

wt = providers('WUE trap'); pt = providers('PUE trap')
lab = ['A', 'B', 'C']
num = lambda v: f'{v:.1f}'.rstrip('0').rstrip('.')
fig = plt.figure(figsize=(SINGLE, 2.75), layout='constrained')
top, bot = fig.subfigures(2, 1, hspace=0.04)
for sf, name in ((top, 'WUE trap: the lowest WUE is not the lowest water'),
                 (bot, 'PUE trap: the lowest IT electricity is not the lowest facility electricity')):
    sf.suptitle(name, fontsize=7.2, color=INK2, x=0.02, ha='left')
a_t = top.subplots(1, 2); a_b = bot.subplots(1, 2)
bars(a_t[0], [float(r['WUE_L_per_kWh']) for r in wt], lab, '(a) Annual WUE', 'L/kWh', lambda v: f'{v:.2f}')
bars(a_t[1], [float(r['W_mL']) for r in wt], lab, '(b) Transaction water', 'mL', num)
bars(a_b[0], [float(r['E_IT_Wh']) for r in pt], lab, '(c) IT electricity', 'Wh', num)
bars(a_b[1], [float(r['E_facility_Wh']) for r in pt], lab, '(d) Facility electricity', 'Wh', num)
for ax in a_b: ax.set_xlabel('Provider')
save(fig, 'fig3_traps')

# ================================================================ Fig: power curves
def power_rows(sc):
    return rcsv(f'{RES}/cliox_{tag(sc)}_power.csv')

COMPS = [('Rating L/M/H vs Control', 'Rating'), ('Numeric E & W vs Control', 'Numeric'),
         ('WUE only vs Control', 'WUE only')]
scen4 = ['WUE trap', 'PUE trap', 'Dominant', 'Shared GPU']
fig, axs = plt.subplots(1, 4, figsize=(DOUBLE, 1.85), sharey=True, constrained_layout=True)
for k, (ax, sc) in enumerate(zip(axs, scen4)):
    rows = power_rows(sc)
    for comp, cond in COMPS:
        rr = [r for r in rows if r['Comparison'] == comp]
        n = [int(r['UsersPerCondition']) for r in rr]
        p = [float(r['Power']) for r in rr]
        harm = sum(float(r['PowerHarm']) for r in rr) > sum(float(r['PowerBenefit']) for r in rr)
        col, mk = COND[cond]
        ax.plot(n, p, color=col, marker=mk, ls=':' if harm else '-',
                mfc='white' if harm else col, mec=col, mew=0.9, zorder=3)
        if harm:
            i3 = n.index(300)
            ax.annotate('WUE only: worse\nthan Control', xy=(n[i3], p[i3]), xytext=(470, 0.20),
                        fontsize=6.3, color=INK2, ha='left',
                        arrowprops=dict(arrowstyle='-', color=MUTED, lw=0.6, shrinkA=1, shrinkB=2))
    ax.axhline(0.9, color=INK2, lw=0.7, ls=(0, (4, 3)), zorder=1)
    ax.set_title(f'({chr(97 + k)}) {sc}', loc='left', pad=3)
    ax.set_xlim(0, 820); ax.set_ylim(0, 1.02)
    ax.set_xticks([0, 200, 400, 600, 800])
    ax.set_xlabel('Users per condition')
axs[0].set_ylabel('Power')
axs[2].text(810, 0.885, '90%', ha='right', va='top', fontsize=6.5, color=INK2)
for ax in axs: ax.set_yticks([0, 0.25, 0.5, 0.75, 1], ['0', '0.25', '0.5', '0.75', '1'])
handles = [Line2D([], [], color=COND[c][0], marker=COND[c][1], mfc=COND[c][0], mec=COND[c][0], label=f'{c} vs. Control')
           for _, c in COMPS]
handles.append(Line2D([], [], color=COND['WUE only'][0], marker='^', mfc='white', mec=COND['WUE only'][0], ls=':',
                      label='WUE only vs. Control, unfavorable'))
fig.legend(handles=handles, loc='outside upper center', ncol=4, handlelength=2.2, columnspacing=1.4)
save(fig, 'fig4_power')

# ================================================================ Fig: electricity boundary (dumbbells)
bnd = rcsv(f'{RES}/cliox_boundary.csv')
scen6 = ['WUE trap', 'PUE trap', 'Dominant', 'Shared GPU', 'Trade-off', 'Missing WUE']
def bv(sc, basis, key):
    return 100 * float([r for r in bnd if r['Scenario'] == sc and r['DisplayBasis'] == basis][0][key])
panels = [('EstimatesCorrect', '(a) Estimates correct (%)'), ('Success_Numeric', '(b) Numeric display (%)'),
          ('Success_Rating', '(c) Rating display (%)'), ('Power300_RatingVsControl', '(d) Rating vs. Control, power')]
fig, axs = plt.subplots(2, 2, figsize=(SINGLE, 3.15), sharey=True, constrained_layout=True)
axs = axs.ravel()
ys = list(range(len(scen6)))[::-1]
for ax, (key, title) in zip(axs, panels):
    power = key.startswith('Power')
    for y, sc in zip(ys, scen6):
        f, i = bv(sc, 'facility', key), bv(sc, 'IT', key)
        if power:
            f, i = f / 100, i / 100
        ax.plot([f, i], [y, y], color='#c9c8c2', lw=1.6, zorder=1, solid_capstyle='round')
        ax.plot(i, y, 'o', mfc='white', mec=ORANGE, mew=1.1, ms=4.2, zorder=3)
        ax.plot(f, y, 'o', color=BLUE, ms=4.2, zorder=4)
        if abs(f - i) >= (0.02 if power else 2):
            fmt = (lambda v: f'{v:.2f}'.lstrip('0')) if power else (lambda v: f'{v:.0f}')
            ax.text(i, y + 0.28, fmt(i), ha='center', va='bottom', fontsize=6.2, color=INK2)
            ax.text(f, y + 0.28, fmt(f), ha='center', va='bottom', fontsize=6.2, color=INK)
    if power:
        ax.axvline(0.9, color=INK2, lw=0.7, ls=(0, (4, 3)), zorder=0)
        ax.set_xlim(-0.05, 1.05); ax.set_xticks([0, 0.5, 0.9], ['0', '0.5', '0.9'])
    elif key != 'EstimatesCorrect':
        ax.axvline(100 / 3, color=INK2, lw=0.7, ls=(0, (4, 3)), zorder=0)
        ax.set_xlim(20, 55); ax.set_xticks([20, 33.3, 50], ['20', 'chance', '50'])
    else:
        ax.set_xlim(-5, 105); ax.set_xticks([0, 50, 100])
    ax.set_title(title, loc='left', pad=3)
    ax.grid(axis='y', visible=False)
    ax.set_ylim(-0.6, len(scen6) - 0.3)
for ax in (axs[0], axs[2]):
    ax.set_yticks(ys, scen6)
    ax.tick_params(axis='y', length=0)
handles = [Line2D([], [], ls='', marker='o', color=BLUE, ms=4.2, label='Facility electricity shown'),
           Line2D([], [], ls='', marker='o', mfc='white', mec=ORANGE, mew=1.1, ms=4.2, label='IT electricity only')]
fig.legend(handles=handles, loc='outside lower center', ncol=2, columnspacing=1.6, handletextpad=0.3)
save(fig, 'fig5_boundary')

# ================================================================ Fig: sensitivity
def sweep(name):
    rows = rcsv(glob.glob(f'{RES}/cliox_wue_trap_sweep_{name}_sweep.csv')[0])
    return [{k: float(v) for k, v in r.items()} for r in rows]
att, cv, wgt = sweep('cond_attention_4_'), sweep('uncert_powercv'), sweep('index_energyweight')
col = lambda rows, k: [r[k] for r in rows]
fig, axs = plt.subplots(1, 3, figsize=(DOUBLE, 1.85), constrained_layout=True)

ax = axs[0]
x = col(att, 'Value')
ax.plot(x, col(att, 'Power:Rating L/M/H vs Control'), color=AQUA, marker='o', label='Rating vs. Control')
ax.plot(x, col(att, 'Power:Rating L/M/H vs WUE only'), color=AQUA, marker='o', mfc='white', ls='--', label='Rating vs. WUE only')
ax.axvline(0.25, color=MUTED, lw=0.6, ls=':')
ax.text(0.255, 0.04, 'default', fontsize=6.3, color=INK2)
ax.set_xlabel('Share of users acting on ratings, $a_c$')
ax.set_title('(e) Behavioral response', loc='left', pad=3)

ax = axs[1]
x = col(cv, 'Value')
ax.plot(x, col(cv, 'Power:Rating L/M/H vs Control'), color=AQUA, marker='o', label='Rating vs. Control')
ax.plot(x, col(cv, 'Power:Numeric E & W vs Control'), color=BLUE, marker='s', label='Numeric vs. Control')
ax.plot(x, col(cv, 'EstimateAccuracy'), color=INK2, lw=1.1, ls=(0, (1.5, 1.5)), label='Estimates correct')
ax.axvline(0.10, color=MUTED, lw=0.6, ls=':')
ax.set_xlabel('CV of IT-power estimates')
ax.set_title('(f) Estimate error', loc='left', pad=3)

ax = axs[2]
x = col(wgt, 'Value')
ax.plot(x, col(wgt, 'Power:Rating L/M/H vs Control'), color=AQUA, marker='o', label='Rating vs. Control')
ax.plot(x, col(wgt, 'Power:Numeric E & W vs Control'), color=BLUE, marker='s', label='Numeric vs. Control')
ax.axvline(0.5, color=MUTED, lw=0.6, ls=':')
ax.set_xlabel('Electricity weight $w$ in (5)')
ax.set_title('(g) Index weighting', loc='left', pad=3)

for ax in axs:
    ax.set_ylim(0, 1.05)
    ax.set_yticks([0, 0.25, 0.5, 0.75, 1], ['0', '0.25', '0.5', '0.75', '1'])
    ax.axhline(0.9, color=INK2, lw=0.7, ls=(0, (4, 3)), zorder=1)
axs[0].set_ylabel('Power or proportion')
handles = [Line2D([], [], color=AQUA, marker='o', label='Rating vs. Control'),
           Line2D([], [], color=AQUA, marker='o', mfc='white', ls='--', label='Rating vs. WUE only'),
           Line2D([], [], color=BLUE, marker='s', label='Numeric vs. Control'),
           Line2D([], [], color=INK2, lw=1.1, ls=(0, (1.5, 1.5)), label='Estimates identify lowest provider'),
           Line2D([], [], color=INK2, lw=0.7, ls=(0, (4, 3)), label='90% power')]
fig.legend(handles=handles, loc='outside upper center', ncol=5, handlelength=2.2, columnspacing=1.2)
save(fig, 'fig4_sensitivity')
print('figures written to', OUT)
