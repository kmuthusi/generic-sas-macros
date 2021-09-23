# `%svy_freqs`: A generic SAS macro for three-way crosstabulations
This repository was created for use by CDC programs to collaborate on public health surveillance related projects in support of the CDC Surveillance Strategy.  Github is not hosted by the CDC, but is used by CDC and its partners to share information and collaborate on software.

## Macro description
`%svy_freqs` is a SAS macro for creating publication ready table of threw-way cross-tabulation using survey/non-survey data. It also recodes factor variables with character values to numeric values. Depending on the user specification, the macro outputs Col% or Row% or Prevalence% and corresponding 95% confidence intervals for categorical variable. It also outputs Means (95% CI) or Median (IQR)	for continous variables.

The macro is made up of several auxiliary sub-macros. The `%svy_col` sub-macro perform crosstabulation between a factorand by a group variable and output COL%. The `%svy_row` sub-macro performs crosstabulation between a factor and by a group variable and output ROW%. The `%svy_prev` sub-macro performs crosstabulation between a factor and by a group variable given a third variable and output (PREVALENCE%). The `%svy_median` sub-macro performs MEDIAN statistics for a continuous variable and a by group variable. The `%svy_mean` sub-macro performs MEAN statistics for a continuous variable and a by group variable. The `%charvar` sub-macro to recode variables with character values to numeric values whereas then `%distcolval` sub-macro is used to produce one instance of repeated values. The `%runquit` sub-macro enforces in-built SAS validation checks on input parameters. The macro has been developed to run on windows platform and might require appropriate adjustments to run on other operating systems platforms.

In summary, the macro has been design to provide the user with the following benefits:

- Automated to shorten analysis time and eliminate error that arise during copy-pasting of analysis output.
- Promote principles of reproducible research i.e., transparency, reproducibility, reusability.
- Flexible to combine multiple analyses i.e., analyse either categorical variables or continous variables or both.
- Generic to perform multiple functions i.e., output column/row/prevalence percentages, and mean/median estimates.
- Provide options for dealing with missing data e.g., include in output or suppress.
- For survey data allow for specification for variance estimation methods e.g., Jackknife & Balanced Repeated Replication.
- Produce outputs with natural display of results useful in epidemiological and biomedical publications.

## How to use the Macro
The user should specify input parameters described in the table below unless the description is prefixed by (optional). The user, however, does not interact with the sub-macros. To achieve full potential of the SAS macro, the user must ensure that the analysis dataset is clean, analysis variables are well labelled, and values of variables have been converted into appropriate SAS formats before they can be input to the macro call.

|Parameter|Description|
|---------|-----------|
|_data	  |name of input dataset|
|_factors |list of categorical variables separated by space |
|_cat_type |type of analysis for categorical variables i.e., COL for column percentages, ROW for row percentages, PREV for prevalence percentages|
|_contvars	|list of continuous variables separated by space|
|_cont_type |type of analysis for continuous variables i.e., MEAN or MEDIAN|
|_byvar	|name of categorical by-group variable which can have any number of categories/levels|
|_outcome	|(optional) name of third variable for which cross tabulations are needed e.g., lbxha, for Hepatitis A, but must be specified if prevalence analysis is being performed|
|_outvalue	|(optional) value label of third variable to compute prevalence cross tabulation but must be specified if _outcome is specified e.g., Positive, in the case of prevalence of Hepatitis A.|
|_strata	|(optional) survey stratification variable|
|_cluster |(optional) survey clustering variable|
|_weight	|(optional) survey weighting variable|
|_domain	|(optional) domain variable for sub-population analysis|
|_domainvalue|	(optional) value of domain/sub-population of interest (should be numeric). Required if _domain is specified|
|_varmethod	|(optional) value for variance estimation method namely Taylor (the default) or replication-based variance estimation methods including JK or BRR|
|_varmethod¬_opts|	(optional) options for variance estimation method, e.g., jkcoef=1 df=25 for JK|
|_rep_weights_values|	(optional) values for REPWEIGHTS statement, but may be specified with replication-based variance estimation method is JK or BRR|
|_missval_lab|	(optional) value label for missing values. If missing data have a format, it should be provided, otherwise macro assumes the default format “.”|
|_missval_opts|	(optional) options for handling missing data within proc survey statement, e.g., “MISSING” or “NOMCAR”. If no option is specified all missing observations are excluded from the analysis|
|_idvar	|name of unique identifying variable|
|_condition	|(optional) any conditional statements to create and or fine-tune the final analysis dataset specified using one IF statement|
|_outdir	|path for directory/folder where output is saved|
|_tablename	|short name of output table|
|_tabletitle	|title of output table|
|_surveyname	|abbreviation for survey/study to be included in the output|
|_print	|variable for displaying/suppressing the output table on the output window which takes the values (NO=suppress output, YES=show output)|

A sample macro call program, "svy_freqs analysis file.sas", is also provided as part of this repository.

A manuscript describing more about the macro contents and usage is available online at: https://www.biorxiv.org/content/10.1101/771303v1

## Public Domain
This repository constitutes a work of the United States Government and is not
subject to domestic copyright protection under 17 USC § 105. This repository is in
the public domain within the United States, and copyright and related rights in
the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
All contributions to this repository will be released under the CC0 dedication. By
submitting a pull request you are agreeing to comply with this waiver of
copyright interest.

## License
The repository utilizes code licensed under the terms of the Apache Software
License and therefore is licensed under ASL v2 or later.

This source code in this repository is free: you can redistribute it and/or modify it under
the terms of the Apache Software License version 2, or (at your option) any
later version.

This source code in this repository is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the Apache Software License for more details.

You should have received a copy of the Apache Software License along with this
program. If not, see http://www.apache.org/licenses/LICENSE-2.0.html

The source code forked from other open source projects will inherit its license.

## Privacy
This repository contains only non-sensitive, publicly available data and
information. All material and community participation is covered by the
Surveillance Platform [Disclaimer](https://github.com/CDCgov/template/blob/master/DISCLAIMER.md)
and [Code of Conduct](https://github.com/CDCgov/template/blob/master/code-of-conduct.md).
For more information about CDC's privacy policy, please visit [http://www.cdc.gov/privacy.html](http://www.cdc.gov/privacy.html).

## Contributing
Anyone is encouraged to contribute to the repository by [forking](https://help.github.com/articles/fork-a-repo)
and submitting a pull request. (If you are new to GitHub, you might start with a
[basic tutorial](https://help.github.com/articles/set-up-git).) By contributing
to this project, you grant a world-wide, royalty-free, perpetual, irrevocable,
non-exclusive, transferable license to all users under the terms of the
[Apache Software License v2](http://www.apache.org/licenses/LICENSE-2.0.html) or
later.

All comments, messages, pull requests, and other submissions received through
CDC including this GitHub page are subject to the [Presidential Records Act](http://www.archives.gov/about/laws/presidential-records.html)
and may be archived. Learn more at [http://www.cdc.gov/other/privacy.html](http://www.cdc.gov/other/privacy.html).

## Records
This repository is not a source of government records, but is a copy to increase
collaboration and collaborative potential. All government records will be
published through the [CDC web site](http://www.cdc.gov).

## Notices
Please refer to [CDC's Template Repository](https://github.com/CDCgov/template)
for more information about [contributing to this repository](https://github.com/CDCgov/template/blob/master/CONTRIBUTING.md),
[public domain notices and disclaimers](https://github.com/CDCgov/template/blob/master/DISCLAIMER.md),
and [code of conduct](https://github.com/CDCgov/template/blob/master/code-of-conduct.md).

## ----- for use in template only -----
## Hat-tips
Thanks to [18F](https://18f.gsa.gov/)'s [open source policy](https://github.com/18F/open-source-policy)
and [code of conduct](https://github.com/CDCgov/code-of-conduct/blob/master/code-of-conduct.md)
that were very useful in setting up this GitHub organization. Thanks to CDC's
[Informatics Innovation Unit](https://www.phiresearchlab.org/index.php/code-of-conduct/)
that was helpful in modeling the code of conduct.

## ----- for use in template only -----

