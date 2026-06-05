# Fishing Cat Game - Master Character Style Guide

This reference defines the universal visual language for every cat character in
Cat & Hook.

Generate only the character style and proportions described below. Do not define
fur color, breed, markings, clothing, accessories, or personality traits unless
explicitly provided by the individual character prompt.

## Art Style

- Cozy idle game character
- Cute Japanese indie game aesthetic
- Inspired by the facial simplicity of Neko Atsume
- Inspired by the readability of Cornerpond
- Clean pixel art
- Large visible pixels
- Strong silhouette
- Thick dark outline
- No anti-aliasing
- No gradients
- No painterly rendering
- Readable at small size
- Suitable for mobile idle game UI

## Perspective

- 3/4 top-down isometric view
- Character faces slightly toward the right
- Consistent facing direction across all animations
- Designed for an isometric fishing game
- Character remains readable from a top-down gameplay camera

## Proportions

- Large head
- Compact body
- Cute chubby proportions
- Short legs
- Small rounded paws
- Thick rounded tail
- Tail clearly visible
- Four paws visible whenever possible
- Body feels soft and rounded
- No realistic cat anatomy

Target feeling: cute, soft, friendly, approachable, and collectible.

## Face Design

- Extremely simple face
- Two black oval eyes
- Small nose
- Tiny "w"-shaped cat mouth
- No eye highlights
- No eyelashes
- No eyebrows
- No whiskers
- Minimal facial detail

The face remains almost identical across all cat characters.

## Animation Philosophy

- Semi-anthropomorphic
- Still clearly a cat
- Not human and does not stand like a person
- Uses front paws to interact with objects
- Rear paws remain grounded
- Short arms
- Cute, readable silhouette

Focus on charm and readability rather than realistic movement.

## Animation Proportion Rules

All animation poses must preserve the same proportions, perspective, silhouette,
face structure, pixel style, and animation style as the idle standing pose.
Motion must come from posing, weight shifts, prop direction, head direction, and
tail balance rather than changing the cat's anatomy.

For every animation pose:

- Keep the body compact, chubby, soft, and rounded
- Keep the head large relative to the body
- Keep all legs short and all paws small and rounded
- Keep front-paw interactions close to the body whenever possible
- Keep rear paws grounded unless the animation explicitly requires otherwise
- Keep the body in the fixed 3/4 top-down view facing slightly right
- Keep the tail thick, rounded, visible, and useful for balance or motion
- Preserve the shared minimal face structure
- Preserve a cute, readable silhouette at small size

Never:

- Stretch or lengthen the arms
- Elongate the body
- Make the cat look athletic or realistic
- Use human-like posture or gestures
- Sacrifice the shared proportions to make an action more dramatic
- Let a prop become visually confused with a limb

## Animation Pose Specification Structure

Every animation request and animation design must use the following structure.
This applies to single key poses and to every distinct pose in a multi-frame
animation.

### Animation

Name the action and state whether the output is a single pose, key pose, or
multi-frame animation.

### Shared Style

Explicitly require the pose to maintain all proportions, perspective,
silhouette, face structure, pixel style, and animation style defined in this
master guide.

### Pose

Describe the action through clear physical pose mechanics:

- Body rotation and facing direction
- Weight distribution and planted paws
- Front-paw action and any held prop
- Prop position, angle, and relationship to the paws
- Body lean without stretching or elongation
- Head tilt and gaze direction
- Ear direction
- Minimal facial expression
- Tail position and its role in balance or motion
- The intended feeling or moment communicated by the pose

### Important

List action-specific constraints and always reinforce the universal animation
proportion rules. At minimum, require:

- Keep the body compact and chubby
- Keep the paws short and rounded
- Do not stretch the arms
- Do not elongate the body
- Do not make the cat look athletic or realistic
- Keep the cat cute and soft
- Preserve the same proportions as the idle pose

### Silhouette Goal

State the exact action the silhouette must instantly communicate. Also list
nearby incorrect readings that the pose must avoid. The action must remain clear
without relying on facial detail.

### Output

State the required background, character count, props, and framing. Unless an
animation request says otherwise:

- Use a transparent background
- Show a single complete character only
- Include only props required by the action
- Leave enough transparent space for moving props, tails, or motion arcs
- Do not include scenery, ground, shadows, text, borders, or extra characters

## Canonical Animation Pose: Casting Fishing Rod

Use this as the reference for the level of specificity required by every
animation pose specification.

### Animation

Casting Fishing Rod. Single pose captured in the middle of a fishing cast.

### Shared Style

Maintain all proportions, perspective, silhouette, face structure, pixel style,
and animation style defined in this master guide.

### Pose

- Body rotated slightly toward the right
- Weight shifted onto the rear paws
- Rear legs firmly planted on the ground
- Front paws holding the fishing rod together
- Rod angled diagonally upward toward the upper-right corner
- Body leaning backward slightly
- Head tilted upward following the rod motion
- Ears alert and facing forward
- Eyes focused on the casting direction
- Mouth slightly open with an excited expression
- Tail raised slightly for balance
- Pose communicates anticipation and motion

### Important

- Keep the body compact and chubby
- Keep the paws short and rounded
- Do not stretch the arms
- Do not elongate the body
- Do not make the cat look athletic or realistic
- Keep the cat cute and soft
- Preserve the same proportions as the idle pose
- Keep both front paws visibly connected to the fishing rod
- Keep the rear paws visibly grounded

### Silhouette Goal

The character must instantly read as "cute cat casting a fishing rod."

It must not read as:

- Cat reaching upward
- Cat stretching
- Cat waving

### Output

- Transparent background
- Single complete character only
- One clearly readable fishing rod
- No scenery, ground, shadow, text, border, or extra characters

## Consistency Rules

Every cat character must share:

- Body proportions
- Face structure
- Outline thickness
- Perspective
- Animation style
- A clear sense that it belongs to the same species and world

Different cats should be distinguished primarily through:

- Fur colors
- Fur patterns
- Breed features
- Accessories
- Costumes
- Personality details

Do not distinguish cats through changes to body proportions or face structure.

## Avoid

- Realistic anatomy
- Long legs or arms
- Thin tails
- Sharp features
- Anime proportions
- Human body shapes
- Complex facial expressions
- Detailed fur rendering
- Front-facing mascot poses
- Overly dynamic action poses

## Desired Result

A highly recognizable, game-ready cat silhouette that can support dozens or
hundreds of unique cat variants while maintaining a consistent visual identity
across the entire game.
