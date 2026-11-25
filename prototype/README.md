# Clio-X interface prototype (Figs. 1 and 2)

Figs. 1 and 2 of the paper are screenshots of a prototype built on the Clio-X
portal. The portal is a separate code base (Next.js, Apache-2.0), so it is not
copied into this repository. This folder points to the exact version used for
the camera-ready paper and explains how to open the two screens.

| | |
|---|---|
| Code | [`nakamura196/ClioX-mvg-portal`, tag `cas2026-camera-ready`](https://github.com/nakamura196/ClioX-mvg-portal/tree/cas2026-camera-ready), a fork of [`ciferresearch/ClioX-mvg-portal`](https://github.com/ciferresearch/ClioX-mvg-portal) |
| Prototype code | `src/experiment/` in that tag (one folder per prototype; see its `README.md`) |
| Live trial site | <https://cliox.ldas.jp/experiment/> (Sepolia test network) |
| Licence | Apache-2.0 (the portal's licence), separate from the MIT licence of this repository |

## The two figures

| Figure | Screen | Open it |
|---|---|---|
| Fig. 1 | An asset page listing four compute environments with their estimated facility electricity and water per job | <https://cliox.ldas.jp/experiment/paper-fig/?env=a> (`env=a`, `b`, `c` or `d` selects the environment) |
| Fig. 2 | The transaction receipt, with the calculation shown step by step | <https://cliox.ldas.jp/experiment/two-condition/?view=receipt&sample=t4a&steps=1> |

Code for the two screens, inside the tag:

- `src/experiment/footprint/` — the footprint panel and comparison table (Fig. 1),
  and the calculation (`lib/computeFootprint.ts`, `lib/transactionFootprint.ts`)
- `src/experiment/two-condition/` — the receipt (Fig. 2) and the decision
  exercise it belongs to (`lib/receiptSteps.ts` builds the steps)
- `content/experiment/trials.json` — the providers and input values

## What is real and what is illustrative

**Real:** the page components, the calculation (IT electricity → facility
electricity with PUE → water with WUE → carbon), the published emission factors,
and the receipt fingerprint (SHA-256).

**Illustrative:** all providers and every input value in the two figures
(four fictional providers in `content/experiment/trials.json`, the same as task
t4 of the decision exercise), the transaction ID and times. Both screens carry
a yellow "Illustrative" banner. The numbers in the figures are not measurements
of real providers.

The same calculation is checked by unit tests in the portal
(`src/experiment/footprint/lib/*.test.ts`, `src/experiment/two-condition/lib/*.test.ts`)
and, for the simulation in this repository, by `src/cliox_selftest.m`, which
includes the paper's Granite Cloud example.

## Running it locally

Requires Node.js 22 and npm.

```sh
git clone --branch cas2026-camera-ready https://github.com/nakamura196/ClioX-mvg-portal.git
cd ClioX-mvg-portal
npm ci
NEXT_PUBLIC_METADATACACHE_URI=https://cliox-node.ldas.jp npm start
```

Then open <http://localhost:8000/experiment/paper-fig?env=a> (Fig. 1) and
<http://localhost:8000/experiment/two-condition?view=receipt&sample=t4a&steps=1> (Fig. 2).
`npm start` first generates some network metadata files, then starts the
development server on port 8000. No wallet is needed. On Node.js 25 or newer,
prefix the last command with
`NODE_OPTIONS=--no-experimental-webstorage`.

`/experiment` lists the other prototypes on the portal, each with a note on
what is real and what is illustrative.
