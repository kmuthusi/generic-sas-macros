# Place holder for Repository Name
This repository was created for use by CDC programs to collaborate on public health surveillance related projects in support of the CDC Surveillance Strategy.  Github is not hosted by the CDC, but is used by CDC and its partners to share information and collaborate on software.

# Generic SAS macros for creating publication-quality tables
This repository contains a series of generic SAS macros for creating publication-quality tables. The final formatted output is exported into MS Word or Excel and can be incorporated directly into a manuscript or might require minimal edits to match journal specific publication requirements. They have been design to analysis data from both survey and non-survey settings. The macros have being developed to run on windows platform and might require appropriate adjustments to run on other operating systems platforms
## 1. %svy_logistic_regression macro
This is a generic SAS macro for creating publication-quality tables from simple and multiple logistic regression models. The macro uses both survey or non-survey data. It outputs a quality-publication table of Odds Ratio (95% CI) from simple (bi-variate) and multiple (multivariable) logistic regression in MS Word and Excel results. 

The macro is made up of several auxiliary sub-macros. The %svy_logitc sub-macro performs simple (bivariate) logistic regression model on categorical predictors. The %svy_logitn sub-macro performs simple (bivariate) logistic regression model on continuous predictors. The %svy_multilogit sub-macro performs multiple (multivariable) logistic regression on selected predictors. The %svy_printlogit sub-macro combines results from simple (bivariate) and multiple (multivariable) logistic regression and packages the output in a publication-quality table which is exported to MS Word and Excel. The %runquit sub-macro enforces in-built SAS validation checks on input parameters. 

A sample macro call program, "svy logistic regression anafile.sas", is also provided as part of this repository.

## 2. %svy_freq macro
This is a generic SAS macro for creating publication ready table of cross-tabulation between a factor and a by group variable given a third variable using survey/non-survey data. It also recodes factor variables with character values to numeric values. Depending on the user specification, the macro outputs Col% or Row% or Prevalence% and corresponding 95% confidence intervals for categorical variable. It also outputs Means (95% CI) or Median (IQR)	for continous variables. 

The macro is made up of several auxiliary sub-macros. The %svy_col sub-macro perform crosstabulation between a factorand by a group variable and output COL%. The %svy_row sub-macro performs crosstabulation between a factor and by a group variable and output ROW%. The %svy_prev sub-macro performs crosstabulation between a factor and by a group variable given a third variable and output (PREVALENCE%). The %svy_median sub-macro performs MEDIAN statistics for a continuous variable and a by group variable. The %svy_mean sub-macro performs MEAN statistics for a continuous variable and a by group variable. The %charvar sub-macro to recode variables with character values to numeric values whereas then %distcolval sub-macro is used to produce one instance of repeated values. The %runquit sub-macro enforces in-built SAS validation checks on input parameters.

A sample macro call program, "svy_freqs analysis file.sas", is also provided as part of this repository.

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

