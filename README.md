# Soul Calibur 1 - Dreamcast & Arcade Import Scripts

These two Maxscripts allow you to import Soul Calibur 1 character models (Dreamcast and Arcade versions) into Autodesk 3ds Max. They handle model geometry, basic skeletons, and optional vertex weights.

## Overview

- **mxs_soul_calibur1_dreamcast.ms**  
  Imports the decrypted Dreamcast version of the Soul Calibur 1 character model (typically `.BIN` files).

- **mxs_soul_calibur1_arcade.ms**  
  Imports the decrypted Arcade version of the Soul Calibur 1 character model (also `.BIN` files).

Both scripts were written based on reverse-engineering efforts by the community—particularly with heavy research contributions from [spaztron64](https://github.com/spaztron64) (Dreamcast) and from [spaztron64](https://github.com/spaztron64) and [Spicyjpeg](https://github.com/spicyjpeg) (Arcade). The scripts parse each game’s unique data structures to reconstruct meshes, apply bones, and optionally build a skin modifier with weights.

## Table of Contents

1. [Features](#features)  
2. [Requirements](#requirements)  
3. [Installation](#installation)  
4. [Usage](#usage)  
   - [Dreamcast Script](#dreamcast-script)  
   - [Arcade Script](#arcade-script)  
5. [Script Options](#script-options)  
6. [Notes on File Formats](#notes-on-file-formats)  
   - [Dreamcast Format](#dreamcast-format)  
   - [Arcade Format](#arcade-format)  
7. [Credits](#credits)  
8. [Disclaimer](#disclaimer)  

## Features

- **Dreamcast:**
  - Reads header data to determine vertex pools, normal pools, triangles, sub-meshes, and bone structures.
  - Builds a skeleton in 3ds Max as separate dummies (when selected).
  - Optionally applies vertex weights via a Skin modifier for character rigging.
  - Preserves UV coordinates (including flipping V if necessary).
  - Optionally re-orients normals.

- **Arcade:**
  - Parses the SC1 Arcade format, which features separate tables for strips, geometry data (faces), bones, and names.
  - Detects and assembles triangles or quads by reading GPU-style polygon command data.
  - Creates a skeleton from the local-to-world bone transforms (optional).
  - Supports weighting by distributing vertices among bones in the Skin modifier.
  - Provides additional debug options to visualize faces, UVs, or skip certain transformations.

## Requirements

- **Autodesk 3ds Max** (tested on versions 2014+; generally works on most modern versions supporting Maxscript).
- Basic knowledge of running `.ms` scripts in 3ds Max.
- Sample `.BIN` files extracted from Soul Calibur 1 (Dreamcast or Arcade) for testing.

## Installation

1. **Download** the `.ms` files:
   - [`mxs_soul_calibur1_dreamcast.ms`](./mxs_soul_calibur1_dreamcast.ms)
   - [`mxs_soul_calibur1_arcade.ms`](./mxs_soul_calibur1_arcade.ms)

2. **Copy** or place them somewhere accessible from 3ds Max.

3. **Load** them into 3ds Max:
   - Go to **MaxScript > Run Script…**.
   - Select the script you want to use. This will open a small utility UI (rollout).

   Alternatively, you can drag and drop the `.ms` files directly into your 3ds Max viewport.

## Usage

### Dreamcast Script

1. **Run** `mxs_soul_calibur1_dreamcast.ms`.
2. A dialog labeled `SC2 DC Mesh` appears with the following options:
   - **Import Model**: Click to browse for a `.BIN` file.
   - **Clear Scene on Import**: Deletes all scene objects before importing.
   - **Weights**: Toggle on/off to apply bone weights (via a Skin modifier).
   - **Skeleton**: Toggle on/off to build dummies for the bone hierarchy.
   - **Apply Normals**: Toggle to read normal data from the file (if present) and apply an Edit Normals modifier.
3. Click **Import Model** and select your `.BIN` file. The script reads the data and builds:
   - A fully reconstructed mesh.
   - An optional skeleton (if **Skeleton** is checked).
   - Optional weights via a Skin modifier (if **Weights** is checked).

### Arcade Script

1. **Run** `mxs_soul_calibur1_arcade.ms`.
2. A rollout named `SC1 Mesh` opens. It provides more debug options:
   - **Import Model**: Click to choose your `.BIN` file.
   - **Clear Scene on Import**: Clears the 3ds Max scene before importing.
   - **Weights**: Applies a Skin modifier with bone weights (if available).
   - **Skeleton**: Builds a hierarchy of dummies for bones.
   - **Individual Faces** (Debug): Imports each face as a separate mesh. Useful for troubleshooting geometry issues.
   - **Build UV Mesh** (Debug): Replaces the main mesh with a UV-based “check” mesh (for debugging).
   - **Disable Transforms**: Skips applying bone transformations to the vertex data.
   - **Disable Transforms Fixes**: Prevents the script from applying certain manual rotation corrections.
   - **Apply Normals**: Reads and applies normal data if present.
3. After selecting a `.BIN` file, the script constructs:
   - Mesh geometry (triangles and/or quads).
   - Optional skeleton and weighting.

## Script Options

**Shared Options:**
- **Clear Scene on Import**: If enabled, the entire 3ds Max scene is cleared before new geometry is created.
- **Weights**: Attempts to build a Skin modifier linking vertices to corresponding bone dummies.
- **Skeleton**: Creates 3ds Max dummies representing the discovered bones.
- **Apply Normals**: Adds an Edit Normals modifier with the file’s normal data, if found.

**Arcade-Only Debug Options:**
- **Individual Faces**: Places each polygon in its own separate mesh object—useful for testing polygon commands.
- **Build UV Mesh**: Constructs geometry primarily for visualizing UV faces.
- **Disable Transforms**: Leaves the raw vertex data as-is, ignoring bone transformations.
- **Disable Transforms Fixes**: Skips a custom rotation fix (used for certain skeleton/character alignment issues).

## Notes on File Formats

### Dreamcast Format

- The Dreamcast model data typically includes:
  - **Header**: Describes vertex/normal pool counts, sub-mesh counts, and references to triangle strips.
  - **Sub-mesh Table**: Each entry describes local bone transforms, the number of vertices, and pointers to vertex arrays.
  - **Vertex Pool**: Stores positions and normal references.
  - **Triangle Strips**: Define how faces are formed and how UVs are mapped.

The script interprets each sub-mesh, constructs transform matrices for the bones, merges them into a single skeleton, and then accumulates geometry into a final model.

### Arcade Format

- The Arcade version splits the data into several “tables”:
  1. **Table1**: Also known as the “strip table,” describing bone transforms and vertex ranges.
  2. **Table2**: Raw vertex data, potentially interleaved with command flags.
  3. **Table3**: GPU-render polygon commands that distinguish between triangles and quads, with UV coordinates packed into 32-bit values.
  4. **Table4**: Names/bone indices (depending on the character).

The script decodes the packed data, reconstructs faces, and distributes the geometry among multiple bone transforms.

## Credits

- **Reverse Engineering & Research**:
  - [**spaztron64**](https://github.com/spaztron64) – Major contributions to the Dreamcast format specs.
  - [**Spicyjpeg**](https://github.com/spicyjpeg) – Analysis of GPU commands for the Arcade version.
- **Maxscripts**:
  - **mariokart64n** – Implementation of the parsing logic, 3ds Max mesh building, and optional weighting.

## Disclaimer

- **Legal**: This project is for **educational and archival** purposes. It is not affiliated with or endorsed by Namco or any of its trademarks. Use of extracted data falls under fair use in many regions, but please ensure you comply with local laws and licensing agreements.
- **Support**: These scripts are a work in progress. You may encounter bugs, missing features, or edge cases with certain `.BIN` files. Feel free to open an issue or submit a pull request with fixes.
- **Versions**: Tested mainly with 3ds Max 2020, but should work on older/newer versions (2014+).

---

Enjoy exploring Soul Calibur 1’s internals! If you have improvements or discoveries to share, please submit pull requests or file issues on this GitHub repository.
