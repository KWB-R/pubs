---
title: "Wrap Your Model In An R Package !"
date: 2016-01-01
publishDate: 2020-09-24T08:52:40Z
authors: [ "rustler", "sonnenberg" ]
publication_types: ["1"]
abstract: "The groundwater drawdown model WTAQ-2, provided by the United States Geological Survey for free, has been “wrapped” into an R package, which contains functions for writing input files, executing the model engine and reading output files. By calling the functions from the R package a sensitivity analysis, calibration or validation requiring multiple model runs can be performed in an automated way. Automation by means of programming improves and simplifies the modelling process by ensuring that the WTAQ-2 wrapper generates consistent model input files, runs the model engine and reads the output files without requiring the user to cope with the technical details of the communication with the model engine. In addition the WTAQ-2 wrapper automatically adapts cross-dependent input parameters correctly in case one is changed by the user. This assures the formal correctness of the input file and minimises the effort for the user, who normally has to consider all cross-dependencies for each input file modification manually by consulting the model documentation. Consequently the focus can be shifted on retrieving and preparing the data needed by the model. Modelling is described in the form of version controlled R scripts so that its methodology becomes transparent and modifications (e.g. error fixing) trackable. The code can be run repeatedly and will always produce the same results given the same inputs. The implementation in the form of program code further yields the advantage of inherently documenting the methodology. This leads to reproducible results which should be the basis for smart decision making."
featured: false
publication: " *In:* useR! 2016. Palo Alto,USA. 28.06 - 30.06. 2016"
projects: ["optiwells-2"]
---

