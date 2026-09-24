extends RefCounted
class_name SeaLowAtlas
## Centralized atlas-cropping helper for the two sprite sheets shipped with
## the game. Nothing else in the project should build its own Rect2 from raw
## pixel coordinates — always go through get_character_texture() /
## get_background_texture() so the grid math lives in exactly one place.

## R5C3 (0-based Vector2i(2, 4)), R5C4 (Vector2i(3, 4)), R5C5 (Vector2i(4, 4))
## are ITEM-only cells but are cropped through the same helper as characters.
const CHARACTER_ATLAS: Texture2D = preload(
	"res://assets/characters/charactersList.png"
)

const BACKGROUND_ATLAS: Texture2D = preload(
	"res://assets/characters/backgrounds.png"
)

const CHARACTER_COLUMNS: int = 5
const CHARACTER_ROWS: int = 6

const BACKGROUND_COLUMNS: int = 3
const BACKGROUND_ROWS: int = 2


## Returns an AtlasTexture cropped to `cell` (zero-based Vector2i(column, row))
## from charactersList.png. Cell size is derived from the source texture's
## actual dimensions so nothing here hardcodes raw pixel positions.
static func get_character_texture(cell: Vector2i) -> AtlasTexture:
	return _crop(
		CHARACTER_ATLAS,
		cell,
		CHARACTER_COLUMNS,
		CHARACTER_ROWS
	)


## Returns an AtlasTexture cropped to `cell` (zero-based Vector2i(column, row))
## from backgrounds.png.
static func get_background_texture(cell: Vector2i) -> AtlasTexture:
	return _crop(
		BACKGROUND_ATLAS,
		cell,
		BACKGROUND_COLUMNS,
		BACKGROUND_ROWS
	)


static func _crop(
	source: Texture2D,
	cell: Vector2i,
	columns: int,
	rows: int
) -> AtlasTexture:
	var cell_width: float = float(source.get_width()) / float(columns)
	var cell_height: float = float(source.get_height()) / float(rows)

	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = source

	atlas_texture.region = Rect2(
		cell.x * cell_width,
		cell.y * cell_height,
		cell_width,
		cell_height
	)

	return atlas_texture
