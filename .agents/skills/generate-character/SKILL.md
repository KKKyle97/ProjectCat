---
name: generate-character
description: Generate or design consistent cat characters for Cat & Hook using the mandatory master pixel-art visual language. Use whenever the user says "generate character", asks for a new cat character, requests a cat variant, character concept, character sprite, character reference, or character animation for this game.
---

# Generate Character

Create Cat & Hook character art while preserving the game's shared visual
identity across separate sessions and character variants.

## Workflow

1. Read `references/character-style-guide.md` in full. Treat it as mandatory.
2. Extract the individual character details from the user's prompt.
3. Combine the individual details with the master guide:
   - Allow fur color, fur pattern, breed features, accessories, costumes, and
     personality details to vary.
   - Preserve the shared proportions, face structure, perspective, outline
     thickness, pixel-art treatment, and animation language.
4. Do not invent unspecified individual traits unless they are required to
   complete the requested output. Keep unspecified traits neutral.
5. If an individual request conflicts with the master guide, preserve the master
   guide and briefly identify the conflict. Override it only when the user
   explicitly asks to revise or make an exception to the master style.
6. For image generation or image editing, use the available image-generation
   capability and include both the master guide and individual details in the
   generation prompt.
7. For text-only requests, produce the requested character prompt, specification,
   animation plan, or critique without generating an image.
8. For every animation request, follow the mandatory `Animation Pose
   Specification Structure` in the master guide. Apply the structure to every
   distinct pose or key frame, and use the canonical casting pose as the
   specificity benchmark.

## Output Checks

Before finishing, confirm that the result:

- Reads clearly as a Cat & Hook cat at small size.
- Uses the fixed 3/4 top-down view facing slightly right.
- Preserves the shared chubby body and minimal face.
- Uses clean pixel art with large pixels, a thick dark outline, no
  anti-aliasing, and no gradients.
- Distinguishes the character through permitted individual traits rather than
  altered anatomy or face structure.
- For animations, preserves idle-pose proportions and includes a clear pose,
  important constraints, silhouette goal, and output definition.
