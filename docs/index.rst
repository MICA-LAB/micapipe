.. MICAPIPE documentation master file, created by
   sphinx-quickstart on Wed Jul 15 16:09:38 2020.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

**micapipe**
============================
*An open source repository about the micapipe, a preprocessing pipeline for structural, diffusion and resting state fMRI data.*

.. title:: micapipe

.. raw:: html

   <style type="text/css">
      hr {
      width: 100%;
      height: 1px;
      background-color: #261F4A;
      margin-top: 24px;
      }
   </style>  

.. toctree::
   :maxdepth: 1
   :hidden:
   :caption: Getting started

   pages/01.install/index
   pages/02.whatyouneed/index
   pages/03.execution/index
   pages/09.whatsnew/index

.. toctree::
   :maxdepth: 1
   :hidden:
   :caption: Processing steps

   pages/04.volumetric/index
   pages/05.freesurfer/index
   pages/06.dwi/index
   pages/07.restingstate/index
   pages/08.postmpc/index
   pages/17.geodesic/index

.. toctree::
   :maxdepth: 1
   :hidden:
   :caption: Additional tools

   pages/14.micapipe_anonymize/index
   pages/15.micapipe_cleanup/index
   pages/16.mic2bids/index

.. toctree::
   :maxdepth: 1
   :hidden:
   :caption: References & Acknowledgements

   pages/13.writeitdown/index
   pages/10.citingmicapipe/index
   pages/11.references/index
   pages/12.acknowledge/index


.. image:: ./figures/micapipe.png
   :scale: 50 %
   :alt: alternate text
   :align: center


**Welcome to the MICA lab pipeline**
==========================================

Getting started
--------------------------------------------------------
[`micapipe`](micapipe.readthedocs.io) is developed by [MICA-lab](https://mica-mni.github.io) at McGill University for use at [the Neuro](https://www.mcgill.ca/neuro/), McConnell Brain Imaging Center ([BIC](https://www.mcgill.ca/bic/)).  The main goal is to provide a robust framework to process multimodal MRI data for multiscale connectomics. `micapipe` utilizes a set of known software dependencies and different brain atlases. 
The pipelines integrates *T1 weighted images*, *resting state fMRI* and *Diffusion weighted images*.

.. raw:: html

   <br>


Core development team 🧠
-------------------------

- **Raúl Rodríguez-Cruces**, *MICA Lab - Montreal Neurological Institute*
- **Jessica Royer**, *MICA Lab - Montreal Neurological Institute*
- **Sara Larivière**, *MICA Lab - Montreal Neurological Institute*
- **Bo-yong Park**, *MICA Lab - Montreal Neurological Institute*
- **Reinder Vos de Wael**, *MICA Lab - Montreal Neurological Institute*
- **Casey Paquola**, *MICA Lab - Montreal Neurological Institute*
- **Oualid Benkarim**, *MICA Lab - Montreal Neurological Institute*
- **Boris Bernhardt**, *MICA Lab - Montreal Neurological Institute*
