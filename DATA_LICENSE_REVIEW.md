# TEMPO dataset licensing review

Checked: **31 October 2026**. Scope: **copyright and data-deposit licences only**;
this document makes no determination about other deployment requirements.

## Findings

| Study | Dataset | Verified dataset-level status | Action |
| --- | --- | --- | --- |
| MUSED | https://doi.org/10.11588/DATA/L9TEVQ | **CC BY 4.0**, shown in heiDATA's indexed metadata | Keep; attribute the dataset and indicate changes |
| MIDDEL | https://osf.io/tpdhu/overview | Public OSF project; OSF API `node_license: null` | Keep; no explicit prohibitive project licence identified |
| Finnerty & Trainor | https://osf.io/xuqb7/overview | Public OSF project; OSF API `node_license: null` | Keep; no explicit prohibitive project licence identified |
| Esteban-Cárdenas | https://osf.io/384fb/overview | Public OSF project; OSF API `node_license: null` | Keep; no explicit prohibitive project licence identified |
| Yu, Lee & Lu | https://data.mendeley.com/datasets/mcr7vd5f5d/3 | **CC BY 4.0**, shown on the Mendeley dataset page | Keep; attribute the dataset and indicate changes |

All five remain in TEMPO because **no actual licence forbidding the intended
research reuse was found**. For the OSF deposits, the absence of a chosen
project licence does *not* establish that all forms of redistribution are
unrestricted. Keep this distinction if you distribute copies of the original
OSF files rather than only analyses derived from them.

## OSF general terms and the missing licence field

OSF's [Terms of Use](https://osf.io/terms-of-use/) (sections 5 and 6) grant
the public rights to use material marked public, including certain copying,
distribution, modification and display, subject to copyright, specific
content restrictions and administrator-selected licences. The three projects
were all marked `public: true` when queried via the public OSF API:

- `https://api.osf.io/v2/nodes/tpdhu/`
- `https://api.osf.io/v2/nodes/xuqb7/`
- `https://api.osf.io/v2/nodes/384fb/`

Each API response had `attributes.node_license: null`. This means **no named
project-level licence is shown**; it is not proof of a restrictive licence.
The OSF documentation explains that project-level licences and file-specific
rights may differ. No separate project subcomponents were returned for these
three project IDs. This audit does not establish unrestricted rights over
every OSF file or any third-party material contained in a file.

## Source links and required attribution

- MUSED deposit metadata: https://b2find.eudat.eu/dataset/5c71ab69-2a96-5986-8a18-5dff9b9063ef
- Mendeley Data v3 (Yu, Lee & Lu): https://data.mendeley.com/datasets/mcr7vd5f5d/3
- CC BY 4.0 terms: https://creativecommons.org/licenses/by/4.0/
- OSF Terms of Use: https://osf.io/terms-of-use/
- OSF licensing help: https://help.osf.io/article/148-licensing

TEMPO supplies original study/dataset citations and direct links in the
Overview. It harmonizes outcome labels, computes group summaries and effect
contrasts, and fits exploratory models, so those are transformations of source
data. Credit the original data authors, identify adaptations and do not imply
that they endorse TEMPO. CC BY permission does not replace other rights that
might attach to third-party content.

## Practical bottom line

No study was removed **on licensing grounds**. The working analysis, model
files and user interactions were left untouched; the application only gained
visible dataset-level licensing and attribution information.
