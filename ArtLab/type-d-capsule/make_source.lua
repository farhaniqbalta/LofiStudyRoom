-- Builds one .aseprite source from layer PNGs (one PNG per frame, all the same size). Used by build.py:
--   aseprite -b --script-param files=a.png,b.png --script-param tags=study:1:1,drink:2:2 \
--            --script-param out=X.aseprite --script make_source.lua
local files, tags = {}, {}
for f in app.params.files:gmatch("[^,]+") do files[#files + 1] = f end
for t in app.params.tags:gmatch("[^,]+") do tags[#tags + 1] = t end
local first = Image{ fromFile = files[1] }
local sprite = Sprite(first.width, first.height, ColorMode.RGB)
for i, file in ipairs(files) do
  if i > 1 then sprite:newEmptyFrame() end
  sprite:newCel(sprite.layers[1], i, Image{ fromFile = file }, Point(0, 0))
end
for _, t in ipairs(tags) do
  local name, from, to = t:match("([^:]+):(%d+):(%d+)")
  sprite:newTag(tonumber(from), tonumber(to)).name = name
end
sprite:saveAs(app.params.out)
