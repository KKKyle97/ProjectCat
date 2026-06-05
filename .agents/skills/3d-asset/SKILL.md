---
name: 3d-asset
description: "Guided 3D asset production workflow — walks through modeling, UV unwrap, rig, weight paint, texture, and UE5 export for any asset type. Read docs/pipeline/3d-asset-workflow.md for the full reference."
argument-hint: "[asset name and type, e.g. 'hero character' or 'wooden crate prop']"
user-invocable: true
allowed-tools: Read, Write, Edit, Glob
---

When this skill is invoked:

## Step 1 — Gather Asset Info

Read the argument. If no argument was given, ask:
1. What is the asset? (name + brief description)
2. Static mesh or skeletal mesh? (does it animate with bones?)

If the user is unsure about static vs skeletal, use this rule:
- Characters, creatures, cloth, mechanical parts with joints → **Skeletal**
- Rocks, crates, buildings, vegetation, weapons held in hand → **Static**

## Step 2 — Read the Workflow Reference

Read `docs/pipeline/3d-asset-workflow.md` in full. This is your source of truth
for all specific settings, naming conventions, and UE5 import values. Do not
answer questions about tools or settings from memory — always defer to this file.

## Step 3 — Determine the Applicable Stages

Based on the asset type, determine which stages apply:

**Static Mesh:** Stages 1, 2, 3 (both UV channels), 6 (optional), 7, 8, 9
**Skeletal Mesh:** Stages 1, 2, 3 (UV channel 0 only), 4, 5, 6 (optional), 7, 8, 9

## Step 4 — Present the Asset Plan

Output a tailored production plan for this specific asset:

```
## Asset: [Name]
Type: [Static/Skeletal Mesh]
Target Polys: [from budget table]
Texture Resolution: [from table]
Stages: [list the applicable stages]

### Checklist
[ ] Stage 1: Planning — references gathered, budget confirmed
[ ] Stage 2: Modeling in Blender
[ ] Stage 3: UV Unwrap [+ Lightmap UV if static]
[ ] Stage 4: Rigging [skeletal only]
[ ] Stage 5: Weight Painting [skeletal only]
[ ] Stage 6: Baking [if high-poly exists]
[ ] Stage 7: Texturing
[ ] Stage 8: Export (Send to Unreal)
[ ] Stage 9: UE5 Import & Material Setup
```

## Step 5 — Walk Through Each Stage Interactively

Ask the user which stage they want help with now, or start from the beginning if they say so.

For each stage:
1. Explain what to do in plain language (assume programmer, not artist)
2. Give the exact Blender or UE5 steps — shortcuts, menu paths, settings
3. Highlight the **one most common mistake** for that stage and how to avoid it
4. Ask: "Done with this stage? Any issues?" before moving on

### Stage-Specific Guidance Notes

**Stage 2 (Modeling):**
- For a programmer first learning 3D: recommend starting with box modeling
- Reference the poly budget from the workflow doc
- Remind them to apply transforms before moving on (Ctrl+A → All Transforms)

**Stage 3 (UV Unwrap):**
- For hard-surface assets: Smart UV Project is fine
- For organic shapes: guide through manual seam placement
- Static meshes: always create the second UV channel for lightmap
- If they want UE5 to auto-generate lightmaps, note that option in import settings

**Stage 4 (Rigging):**
- Only for skeletal meshes
- Reference the UE5-compatible bone naming table from the workflow doc
- Emphasize: root bone at world origin, all bones named before export

**Stage 5 (Weight Painting):**
- Start with Automatic Weights, then fix problem areas
- Walk through how to identify unweighted verts
- Suggest test: rotate each major bone in Pose Mode, look for mesh tearing

**Stage 6 (Baking):**
- Ask first: did they sculpt a high-poly? If no, skip this stage
- If yes: walk through normal bake in Blender step by step
- **Always remind:** invert G channel for DirectX normal map before UE5 import

**Stage 7 (Texturing):**
- Ask: Quixel Mixer (easier, layer-based, photorealistic) or Blender (more control)?
- For beginners: recommend Quixel Mixer for first few assets
- Reference the ORM pack format and naming conventions from the workflow doc

**Stage 8 (Export):**
- Default recommendation: Send to Unreal addon
- If they don't have it set up, walk through the install process
- Fallback to FBX with exact settings from the workflow doc

**Stage 9 (UE5 Import):**
- Walk through import dialog settings for their asset type
- Material setup: explain how to wire BaseColor, Normal, ORM into a UE5 material
- Texture compression settings: sRGB vs linear — this is a common silent mistake

## Step 6 — Production Gate Check

When all stages are marked done, run through the full production checklist from the
workflow doc. Flag any item the user hasn't confirmed.

Output a final summary:
```
## Asset Complete: [Name]
Location: [where the asset was exported to in UE5 content browser]
Files:
  - Blender source: assets/source/[name].blend
  - Textures: assets/textures/[name]/
  - UE5 asset: [content browser path]

Outstanding issues (if any):
  - [list anything flagged in checklist]
```

## Handling Questions Mid-Workflow

If the user asks a question not covered by the checklist (e.g. "how do I fix
clipping"), answer it directly using knowledge from the workflow doc, then offer
to return to where they were in the workflow.

If the answer isn't in the workflow doc, say so clearly and give your best
guidance, noting it isn't part of the established pipeline.
