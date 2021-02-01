.. _execution:

.. title:: Running micapipe: overview

Micapipe usage overview
============================================================

But how exactly does one run micapipe? 

.. admonition:: Help! 🥺

	A list and brief descripton of each argument and flag can be displayed using the command : ``mica-pipe -help`` or ``mica-pipe -h``

Running micapipe
--------------------------------------------------------
Basic usage of micapipe, with no options specified, will look like:

    .. parsed-literal:: 
        $ mica-pipe **-sub** <subject_id> **-out** <outputDirectory> **-bids** <BIDS-directory> -<module-flag>

Let's break this down:

	- **-sub**: Corresponds to subject ID. Even if your data is in BIDS, we exclude the "sub-" substring from the ID code (e.g. sub-HC001 is entered as -sub HC001).
	- **-out**: Output directory path. Following BIDS, this corresponds to the "derivatives" directory associated with your dataset.
	- **-bids**: Path to rawdata BIDS directory. 
	- -<module-flag>: Specifies which submodule(s) to run (see next section).

Module flags
--------------------------------------------------------
The processing modules composing micapipe can be run individually or bundled using specific flags.

Processing modules for :ref:`T1-weighted structural imaging<structproc>`_ consist of:

	- **-proc_structural**: Basic volumetric processing on T1-weighted data.
	- **-proc_freesurfer**: Run freesurfer's recon-all pipeline on T1-weighted data. 
	- **-post-structural**: Further structural processing relying on qualtiy-controlled cortical surface segmentations.
	- **-GD**: Generate geodesic distance matrices from participant's native midsurface mesh.
	- **-Morphology**: Registration and smoothing of surface-based morphological features of the cortex.

Processing module for :ref:`quantitative T1 imaging<microstructproc>`_:

	- **-MPC**: Equivolumetric surface mapping and generate microstructural profile covariance matrices `(Paquola et al., 2019) <https://journals.plos.org/plosbiology/article?id=10.1371/journal.pbio.3000284>`_.

Flags for :ref:`diffusion-weighted imaging<dwiproc>`_ processing steps:

	- **-proc_dwi**: Basic diffusion-weighted imaging processing.
	- **-SC**: Diffusion tractography and generate structural connectomes.

Flag to process :ref:`resting-state functional MRI data<restingstateproc>`_:

	- **-proc_rsfmri**: Resting-state functional processing and generate functional connectomes.

Lastly, to run all processing steps while making sure module interdependencies are respected:

	- **-all**: Run all the modules! This could take a while...

.. admonition:: But wait... there's more! 🙀

	Optional arguments can be specified for some modules. See the ``Usage`` tab of each module's dedicated section for details! 

More options
--------------------------------------------------------
You can specify additional options when running micapipe:

	- **-force**: Overwrite existing data in the subject directory.
	- **-quiet**: Do not print comments and warnings.
	- **-nocleanup**: Prevent deletion of temporary directory created for the module.
	- **-threads** <#>: Change number of threads (default = 6).
	- **-tmpDir** </path>: Specify custom location in with temporary directory will be created (default = /tmp).
	- **-version**: Print your currently installed software version.
	- **-slim**: Keep only crucial outputs and erase all the intermediary files
 
.. admonition:: Slim run 👙

	Including the **-slim** flag will considerably reduce the number of outputs saved at the end of each module. This can be useful when storage is limited or when processing a very large number of subjects. Files affected by this flag are specified in each module's section.