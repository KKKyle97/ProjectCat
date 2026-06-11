---
name: generate-environment
description: Generate or design consistent Cat & Hook fishing environments, area backgrounds, biomes, widget backdrops, diorama scenes, or fishing spots using the mandatory master pixel-art environment style guide.
---

# Generate Environment

Create Cat & Hook environment art while preserving the game's shared cozy
desktop-widget visual identity across areas and biome variants.

## Workflow

1. Read `references/environment-style-guide.md` in full. Treat it as mandatory.
2. Extract the environment details from the user's prompt:
   - Area or biome name.
   - Primary identity.
   - Signature landmark, if provided.
   - Required fishing spots, props, palette, and output format.
3. Combine the individual details with the master guide:
   - Allow biome identity, landmarks, prop choices, season, and palette to vary.
   - Preserve the clean pixel art, toy-like diorama feel, 3/4 top-down view,
     thick dark outlines, readable water, low decoration density, and gameplay
     composition.
4. Do not invent extra landmarks or dense prop sets unless required to complete
   the requested output. Keep unspecified details simple and readable.
5. If a request conflicts with the master guide, preserve the master guide and
   briefly identify the conflict. Override it only when the user explicitly asks
   to revise or make an exception to the master environment style.
6. For image generation or image editing, use the available image-generation
   capability and include both the master guide and individual environment
   details in the generation prompt.
7. For text-only requests, produce the requested environment prompt,
   specification, biome sheet, asset brief, or critique without generating an
   image.

## Output Checks

Before finishing, confirm that the result:

- Makes water the first visual priority.
- Leaves clear places where cute chubby cats can sit and fish.
- Reads clearly at small desktop-widget size and at 25% scale.
- Uses clean pixel art with large visible pixels, thick dark outlines, flat
  colors, minimal shading, no anti-aliasing, and no gradients.
- Feels like a miniature handcrafted toy diorama rather than a realistic place.
- Uses low decoration density, with a single strong biome identity and at most
  one major landmark.
- Keeps sightlines to the water unobstructed and avoids clutter around natural
  fishing spots.
