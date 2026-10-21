extends RefCounted
class_name SeaLowAtlas
## Background-only atlas helper for backgrounds.png (3 x 2 grid). Characters
## and items use standalone PNGs (see EnemyData / ItemData) and are never
## cropped from an atlas.

const BACKGROUND_ATLAS: Texture2D = preload(
	"res://assets/characters/backgrounds.png"
)

const BACKGROUND_COLUMNS: int = 3
const BACKGROUND_ROWS: int = 2


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
